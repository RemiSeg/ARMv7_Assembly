//vector table
.section .vectors, "ax"
B _start // reset vector
B SERVICE_UND // undefined instruction vector
B SERVICE_SVC // software interrupt vector
B SERVICE_ABT_INST // aborted prefetch vector
B SERVICE_ABT_DATA // aborted data vector
.word 0 // unused vector
B SERVICE_IRQ // IRQ interrupt vector
B SERVICE_FIQ // FIQ interrupt vector



/////////////////////////////////////////////////////////////////


tim_int_flag: .word 0
PB_int_flag: .word 0
PAUSED_FLAG: .word 0
DIR_FLAG: .word 0 // 0 left (normal), 1 right (inverse)
// for the speed lets do 5 possible state
// 1, 0.5, .25, .125, .0625
// hardcode the position of the LEDs to displayy too
SPEED_FLAG: .word 2 // normal ..25s


// now we have more message possible, still one hot encoded
// C0FFEE (00)
// CAFE5 (01)
// CAb5 (02)
// ACE (04)
// 70Ad570015 (08) -> loger than 6 characters
// CAFEbEEFC0FFEE (10) -> same
MES_SELECT: .word 0
MES_OFFSET: .word 0

SWITCH_LAST: .word 0

.equ ARM_TIM_BASE, 0xFFFEC600
.equ HEX0, 0xFF200020
.equ HEX4, 0xFF200030

.equ SW_ADDR, 0xFF200040
.equ LED_ADDR, 0xFF200000

.equ PB_BASE, 0xFF200050

HEX_CODES:
	.byte 0b00111111, 0b00000110, 0b01011011, 0b01001111 // 0, 1, 2, 3,
	.byte 0b01100110, 0b01101101, 0b01111101, 0b00000111 // 4, 5, 6, 7,
	.byte 0b01111111, 0b01101111, 0b01110111, 0b01111100 // 8, 9, A, b,
	.byte 0b00111001, 0b01011110, 0b01111001, 0b01110001 // C, d, E, F,


MES_C0FFEE: .byte 0x39, 0x3F, 0x71, 0x71, 0x79, 0x79
MES_CAFE5: .byte 0x39, 0x77, 0x71, 0x79, 0x6D, 0x00
MES_CAB5: .byte 0x39, 0x77, 0x7C, 0x6D, 0x00, 0x00
MES_ACE: .byte 0x77, 0x39, 0x79, 0x00, 0x00, 0x00
MES_70Ad570015: .byte 0x07, 0x3F, 0x77, 0x5E, 0x6D, 0x07, 0x3F, 0x3F, 0x06, 0x6D
MES_CAFE_bEEF_C0FFEE: .byte 0x39, 0x77, 0x71, 0x79, 0x00, 0x7C, 0x79, 0x79, 0x71, 0x00, 0x39, 0x3F, 0x71, 0x71, 0x79, 0x79

.align 2

MES_PTR: .word 0
MES_LEN: .word 6
MES_VALID: .word 1

/////////////////////////////////////////////////////////////////

.text

.global _start

.global ARM_TIM_config_ASM
.global ARM_TIM_read_INT_ASM
.global ARM_TIM_clear_INT_ASM

.global CONFIG_GIC
.global CONFIG_INTERRUPT
.global SERVICE_IRQ
.global KEY_ISR
.global ARM_TIM_ISR
.global enable_PB_INT_ASM



// map for myself
// When a pushbutton or timer event happens...
// - device raises IRQ 
// - GIC receives it 
// - CPU jumps to SERVICE_IRQ 
// - SERVICE_IRQ reads the interrupt ID, it calls the right ISR 
// - ISR sets a memory flag 
// - ISR clears device interrupt 
// - SERVICE_IRQ acknowledges the interrupt to the GIC 
// - CPU returns to IDLE

/////////////////////////////////////////////////////////////////









//from template lab code, mostly
_start:
	MOV A1, #0b11010010 // mode stack IRQ
	MSR CPSR_c, A1
	LDR SP, =0xFFFFFFFF - 3
	
	MOV A1, #0b11010011 // SVC mode stack
	MSR CPSR_c, A1
	LDR SP, =0x3FFFFFFF - 3

	BL CONFIG_GIC
	
	MOV A1, #0xF // enable PB inter. for PB3...PB0
	BL enable_PB_INT_ASM // modification 1
	
	LDR A1, =50000000 // 0.25s 
	MOV A2, #0b111
	BL ARM_TIM_config_ASM // modification 2
	BL ARM_TIM_clear_INT_ASM // modification 3
	BL change_speed_leds 
	
	LDR V2, =SWITCH_LAST
	MVN V1, #0 // V1 = 0xFFFFFFFF
	STR V1, [V2]
	BL update_message_from_switches

	MOV A1, #0b01010011
	MSR CPSR_c, A1
	
IDLE:
	BL update_message_from_switches
	BL handle_PB_event

	LDR V1, =tim_int_flag //determine whether the timer interrupt has occurred
	LDR V2, [V1]
	CMP V2, #0
	BEQ IDLE

	LDR V3, =PAUSED_FLAG
	LDR V4, [V3]
	CMP V4, #0
	BNE clear_timer_flag_done

	LDR V3, =MES_VALID
	LDR V4, [V3]
	CMP V4, #0
	BEQ clear_timer_flag_done

	LDR V3, =MES_OFFSET
	LDR V4, [V3]
	LDR V5, =MES_LEN
	LDR V5, [V5]
	LDR V6, =DIR_FLAG
	LDR A1, [V6]
	CMP A1, #0
	BEQ move_left_msg

	CMP V4, #0
	BNE right_not_zero
	SUB V4, V5, #1
	B store_msg_move

right_not_zero:
	SUB V4, V4, #1
	B store_msg_move

move_left_msg:
	ADD V4, V4, #1
	CMP V4, V5
	BLT store_msg_move
	MOV V4, #0

store_msg_move:
	STR V4, [V3]
	BL render_current_message

clear_timer_flag_done:
	MOV V2, #0
	STR V2, [V1]
	B IDLE


/////////////////////////////////////////////////////////////////

// from the NDC lab
CONFIG_GIC:
	PUSH {LR}
	MOV A1, #29 // id of the timer
	MOV A2, #1
	BL CONFIG_INTERRUPT

	MOV A1, #73 // id of the push button, PB
	MOV A2, #1
	BL CONFIG_INTERRUPT

	LDR A1, =0xFFFEC100
	LDR A2, =0xFFFF
	STR A2, [A1, #0x04]
	MOV A2, #1
	STR A2, [A1]
	LDR A1, =0xFFFED000
	STR A2, [A1]

	POP {LR}
	BX LR


/////////////////////////////////////////////////////////////////

// from the NDC lab
// A1 is the inter ID
// A2 is CPU target
CONFIG_INTERRUPT:
	PUSH {V1, V2, LR}
	LSR V1, A1, #3
	BIC V1, V1, #3
	LDR V2, =0xFFFED100
	ADD V1, V2, V1

	AND V2, A1, #0x1F
	MOV A3, #1
	LSL V2, A3, V2

	LDR A4, [V1]
	ORR A4, A4, V2
	STR A4, [V1]

	BIC V1, A1, #3
	LDR V2, =0xFFFED800
	ADD V1, V2, V1

	AND V2, A1, #0x3
	ADD V1, V1, V2
	STRB A2, [V1]
	POP {V1, V2, LR}
	BX LR

/////////////////////////////////////////////////////////////////

// from the NDC lab
SERVICE_UND:
	B SERVICE_UND
SERVICE_SVC:
	B SERVICE_SVC
SERVICE_ABT_DATA:
	B SERVICE_ABT_DATA
SERVICE_ABT_INST:
	B SERVICE_ABT_INST
SERVICE_FIQ:
	B SERVICE_FIQ

SERVICE_IRQ:
	PUSH {A1, A2, A3, A4, V1, V2, V3, LR}
	LDR V1, =0xFFFEC100
	LDR V2, [V1, #0x0C]
	CMP V2, #73
	BEQ HANDLE_KEY // check for the PB

	CMP V2, #29
	BEQ HANDLE_TIMER // check for the timer
UNEXPECTED:
	B UNEXPECTED
HANDLE_KEY:
	BL KEY_ISR // modifcation for the pushbutton
	B EXIT_IRQ
HANDLE_TIMER:
	BL ARM_TIM_ISR // modifcation for the the timer
	B EXIT_IRQ
EXIT_IRQ:
	STR V2, [V1, #0x10]
	POP {A1, A2, A3, A4, V1, V2, V3, LR}
	SUBS PC, LR, #4


/////////////////////////////////////////////////////////////////

// new but similar to the NDC lab 
// store the PB_int_flag
// and clr interrupt
KEY_ISR:
	 PUSH {V1, V2, V3, V4, LR}
	 LDR V1, =PB_BASE
	 LDR V2, [V1, #0xC]

	 LDR V3, =PB_int_flag // write the content of the pushbutton edgecapture register
	 LDR V4, [V3]
	 ORR V4, V4, V2 //accumulate the pending PB events
	 STR V4, [V3]

	 STR V2, [V1, #0xC]
	 POP {V1, V2, V3, V4, LR}
	 BX LR


//write 1 to the tim_int_flag
// and ofc clr interrupt
ARM_TIM_ISR:
	PUSH {V1, V2, LR}
	LDR V1, =tim_int_flag // writes the value '1' into the tim_int_flag memory when an interrupt is received
	MOV V2, #1
	STR V2, [V1]
	BL ARM_TIM_clear_INT_ASM // then it clears the interrupt

	POP {V1, V2, LR}
	BX LR

/////////////////////////////////////////////////////////////////

// routines for the PB enables/disable/read/clear will below
enable_PB_INT_ASM:
	PUSH {V1, V2, LR}

	LDR V1, =PB_BASE
	LDR V2, [V1, #0x8]
	ORR V2, V2, A1
	STR V2, [V1, #0x8]

	POP {V1, V2, LR}
	BX LR



/////////////////////////////////////////////////////////////////

// This subroutine is used to configure the timer
// input A1 loads the value and A2 conf bits
ARM_TIM_config_ASM:
	PUSH {V1, LR}
	LDR V1, =ARM_TIM_BASE
	STR A1, [V1]
	STR A2, [V1, #0x8] //Ctrl reg.
	POP {V1, LR}
	BX LR
	


/////////////////////////////////////////////////////////////////

// This subroutine returns the “F” value (0x00000000 or 0x00000001)
// from the ARM A9 private timer interrupt status register.

// return only in A1
ARM_TIM_read_INT_ASM: 
	PUSH {V1, LR}
	LDR V1, =ARM_TIM_BASE
	LDR A1, [V1, #0xC] // ISR
	AND A1, A1, #0x1 // keep only F bit (LSB)
	POP {V1, LR}
	BX LR

/////////////////////////////////////////////////////////////////

// This subroutine clears the “F” value in the ARM A9 private timer Interrupt status register. 
// The F bit can be cleared to 0 by writing a 0x00000001 to the interrupt
// status register.

// return only in A1
ARM_TIM_clear_INT_ASM:
	PUSH {V1, LR}
	LDR V1, =ARM_TIM_BASE
	MOV A1, #1
	STR A1, [V1, #0xC]
	POP {V1, LR}
	BX LR



/////////////////////////////////////////////////////////////////


// to change the timer speed
update_timer_speed:
	PUSH {V1, V2, LR}

	LDR V1, =SPEED_FLAG
	LDR V2, [V1]
	CMP V2, #0
	LDREQ A1, =12500000 // 1/16 of the 200 Mhz
	BEQ timer_cfg

	CMP V2, #1
	LDREQ A1, =25000000
	BEQ timer_cfg

	CMP V2, #2
	LDREQ A1, =50000000
	BEQ timer_cfg

	CMP V2, #3
	LDREQ A1, =100000000
	BEQ timer_cfg
	// else just 1s = 200Ms * 200Mhz
	LDR A1, =200000000
	
timer_cfg:
	MOV A2, #0b111
	BL ARM_TIM_config_ASM
	BL ARM_TIM_clear_INT_ASM
	POP {V1, V2, LR}
	BX LR


/////////////////////////////////////////////////////////////////

change_speed_leds:
	PUSH {V1, V2, LR}
	LDR V1, =PAUSED_FLAG
	LDR A1, [V1]
	CMP A1, #0
	BEQ speed_leds_running

	MOV A1, #0
	BL write_LEDs_ASM
	POP {V1, V2, LR}
	BX LR
	// small principle as above/previous routine
speed_leds_running:
	LDR V1, =SPEED_FLAG
	LDR A1, [V1] 
	// first 2 leds and add as go on
	CMP A1, #4
	MOVEQ A1, #0b0000000011 
	BEQ write_speed_leds

	CMP A1, #3
	MOVEQ A1, #0b0000001111
	BEQ write_speed_leds

	CMP A1, #2
	MOVEQ A1, #0b0000111111
	BEQ write_speed_leds

	CMP A1, #1
	MOVEQ A1, #0b0011111111
	BEQ write_speed_leds
	// full leds done
	LDR V2, =1023
	MOV A1, V2
write_speed_leds:
	BL write_LEDs_ASM
	POP {V1, V2, LR}
	BX LR


/////////////////////////////////////////////////////////////////

handle_PB_event:
	PUSH {V1, V2, V3, V4, V5, LR}
	LDR V1, =PB_int_flag
	LDR V2, [V1]
	CMP V2, #0
	BEQ pb_done

	LDR V3, =PAUSED_FLAG
	LDR V4, [V3]
	MOV V5, V4 // save old paused state

	TST V2, #0x8
	BEQ maybe_other_keys

	EOR V4, V4, #1
	STR V4, [V3]
	BL change_speed_leds
	BIC V2, V2, #0x8

maybe_other_keys:
	CMP V5, #0
	BEQ not_paused_before

	// if we were already paused before this batch,
	// PB0-PB2 must have no effect
	MOV V2, #0
	B store_remaining_pb

not_paused_before:
	TST V2, #0x4
	BEQ maybe_faster
	LDR V3, =DIR_FLAG
	LDR A1, [V3]
	EOR A1, A1, #1
	STR A1, [V3]
	BIC V2, V2, #0x4

maybe_faster:
	TST V2, #0x2
	BEQ maybe_slower
	LDR V3, =SPEED_FLAG
	LDR A1, [V3]
	CMP A1, #0
	BEQ clear_fast_bit
	SUB A1, A1, #1
	STR A1, [V3]
	BL update_timer_speed
	BL change_speed_leds
clear_fast_bit:
	BIC V2, V2, #0x2

maybe_slower:
	TST V2, #0x1
	BEQ store_remaining_pb
	LDR V3, =SPEED_FLAG
	LDR A1, [V3]
	CMP A1, #4
	BEQ clear_slow_bit
	ADD A1, A1, #1
	STR A1, [V3]
	BL update_timer_speed
	BL change_speed_leds
clear_slow_bit:
	BIC V2, V2, #0x1

store_remaining_pb:
	STR V2, [V1]

pb_done:
	POP {V1, V2, V3, V4, V5, LR}
	BX LR


/////////////////////////////////////////////////////////////////

// since now we can have blank in the showing
HEX_write_raw_ASM:
	PUSH {V1, V2, V3, V4, V5, LR}
	MOV V1, #1
	MOV V3, #0
raw_loop:
	CMP V1, #0x40
	BEQ raw_done
	TST A1, V1
	BEQ raw_next

	CMP V3, #4
	BLT raw_low

	LDR V4, =HEX4
	SUB V5, V3, #4
	STRB A2, [V4, V5]
	B raw_next
raw_low:
	LDR V4, =HEX0
	STRB A2, [V4, V3]
raw_next:
	ADD V3, V3, #1
	LSL V1, V1, #1
	B raw_loop
raw_done:
	POP {V1, V2, V3, V4, V5, LR}
	BX LR




/////////////////////////////////////////////////////////////////


// case basis
update_message_from_switches:
	PUSH {V1, V2, V3, LR}
	BL read_slider_switches_ASM
	MOV V1, A1
	LDR V2, =SWITCH_LAST
	LDR V3, [V2]
	CMP V1, V3
	BEQ msg_sw_done

	STR V1, [V2]
	LDR V2, =MES_SELECT
	STR V1, [V2]
	LDR V2, =MES_VALID
	MOV V3, #1
	STR V3, [V2]

	// all given combinaison
	CMP V1, #0x00
	BEQ sel_c0ffee
	CMP V1, #0x01
	BEQ sel_cafe5
	CMP V1, #0x02
	BEQ sel_cab5
	CMP V1, #0x04
	BEQ sel_ace
	CMP V1, #0x08
	BEQ sel_70ad
	CMP V1, #0x10
	BEQ sel_long

	// invalid switch combination, blank display only
	LDR V2, =MES_VALID
	MOV V3, #0
	STR V3, [V2]
	BL render_current_message
	B msg_sw_done

sel_c0ffee:
	LDR V2, =MES_PTR
	LDR V3, =MES_C0FFEE
	STR V3, [V2]
	LDR V2, =MES_LEN
	MOV V3, #6
	STR V3, [V2]
	B reset_offset
sel_cafe5:
	LDR V2, =MES_PTR
	LDR V3, =MES_CAFE5
	STR V3, [V2]
	LDR V2, =MES_LEN
	MOV V3, #6
	STR V3, [V2]
	B reset_offset
sel_cab5:
	LDR V2, =MES_PTR
	LDR V3, =MES_CAB5
	STR V3, [V2]
	LDR V2, =MES_LEN
	MOV V3, #6
	STR V3, [V2]
	B reset_offset
sel_ace:
	LDR V2, =MES_PTR
	LDR V3, =MES_ACE
	STR V3, [V2]
	LDR V2, =MES_LEN
	MOV V3, #6
	STR V3, [V2]
	B reset_offset
sel_70ad:
	LDR V2, =MES_PTR
	LDR V3, =MES_70Ad570015
	STR V3, [V2]
	LDR V2, =MES_LEN
	MOV V3, #10
	STR V3, [V2]
	B reset_offset
sel_long:
	LDR V2, =MES_PTR
	LDR V3, =MES_CAFE_bEEF_C0FFEE
	STR V3, [V2]
	LDR V2, =MES_LEN
	MOV V3, #16
	STR V3, [V2]

reset_offset:
	LDR V2, =MES_OFFSET
	MOV V3, #0
	STR V3, [V2]
	BL render_current_message
msg_sw_done:
	POP {V1, V2, V3, LR}
	BX LR


/////////////////////////////////////////////////////////////////


render_current_message:
	PUSH {V1, V2, V3, V4, V5, V6, LR}
	LDR V1, =MES_VALID
	LDR V2, [V1]
	CMP V2, #0
	BNE render_valid

	MOV A1, #0x3F
	BL HEX_clear_ASM
	B render_done

render_valid:
	LDR V1, =MES_PTR
	LDR V1, [V1]
	LDR V2, =MES_LEN
	LDR V2, [V2]
	LDR V3, =MES_OFFSET
	LDR V3, [V3]
	MOV V4, #0 // display position 0..5
	MOV V5, #32 // start at HEX5, then HEX4...HEX0

render_loop:
	CMP V4, #6
	BEQ render_done

	ADD V6, V3, V4
mod_loop:
	CMP V6, V2
	BLT mod_done
	SUB V6, V6, V2
	B mod_loop
mod_done:
	LDRB A2, [V1, V6]
	MOV A1, V5
	BL HEX_write_raw_ASM

	ADD V4, V4, #1
	LSR V5, V5, #1
	B render_loop
render_done:
	POP {V1, V2, V3, V4, V5, V6, LR}
	BX LR


























// form part 1
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////

// Slider Switches Driver
// returns the state of slider switches in A1
// post- A1: slide switch state
read_slider_switches_ASM:
	LDR A2, =SW_ADDR // load the address of slider switch state
	LDR A1, [A2] // read slider switch state
	BX LR

//////////////////////////////////////////////////////////////////////////////////


// LEDs Driver
// writes the state of LEDs (On/Off) in A1 to the LEDs' control register
// pre-- A1: data to write to LED state
write_LEDs_ASM: 
	LDR A2, =LED_ADDR // load the address of the LEDs' state
	STR A1, [A2] // update LED state with the contents of A1
	BX LR


//////////////////////////////////////////////////////////////////////////////////


// display corresponding hexadecimal digit on the display
// A1: HEX display indices (R0)!!!
// A2: integer value 0-15 to display (R1)!!!
HEX_write_ASM:
	PUSH {V1, V2, V3, V4, V5, LR}
	LDR V1, =HEX_CODES
	AND A2, A2, #0x0F
	LDRB V2, [V1, A2]

	MOV V1, #1
	MOV V3, #0
loop1:
	CMP V1, #0x40
	BEQ finish1
	TST A1, V1
	BEQ next1
	
	CMP V3, #4
	BLT hex_zero_to_three_WRITE

	LDR V4, =HEX4
	SUB V5, V3, #4
	STRB V2, [V4, V5]
	B next1
	
hex_zero_to_three_WRITE:
	LDR V4, =HEX0
	STRB V2, [V4, V3]
next1:
	ADD V3, V3, #1
	LSL V1, V1, #1
	B loop1
finish1:
	POP {V1, V2, V3, V4, V5, LR}
	BX LR

//////////////////////////////////////////////////////////////////////////////////


// Turn off all segment of the HEX seleted
// A1: HEX indices to clear again store in R0
HEX_clear_ASM:
	PUSH {V1, V2, V3, V4, V5, LR}
	MOV V1, #1
	MOV V2, #0
loop2:
	CMP V1, #0x40
	BEQ finish2

	TST A1, V1
	BEQ next2

	CMP V2, #4
	BLT hex_zero_to_three_CLR

	LDR V3, =HEX4
	SUB V4, V2, #4
	MOV V5, #0
	STRB V5, [V3, V4]
	B next2

hex_zero_to_three_CLR:
	LDR V3, =HEX0
	MOV V5, #0
	STRB V5, [V3, V2]
next2:
	ADD V2, V2, #1
	LSL V1, V1, #1
	B loop2
finish2:
	POP {V1, V2, V3, V4, V5, LR}
	BX LR
	
//////////////////////////////////////////////////////////////////////////////////

	
// Turn on all the display selected HEX
// A1: indicies of the HEX display to flood, 1 hot encoded indices
HEX_flood_ASM:
	PUSH {V1, V2, V3, V4, V5, LR}
	MOV V1, #1
	MOV V2, #0
loop3:
	CMP V1, #0x40
	BEQ finish3

	TST A1, V1
	BEQ next3

	CMP V2, #4
	BLT hex_zero_to_three_flood

	LDR V3, =HEX4
	SUB V4, V2, #4
	MOV V5, #0b01111111 // 8 value
	STRB V5, [V3, V4]
	B next3

hex_zero_to_three_flood:
	LDR V3, =HEX0
	MOV V5, #0b01111111 // 8 value again
	STRB V5, [V3, V2]
next3:
	ADD V2, V2, #1
	LSL V1, V1, #1
	B loop3
finish3:
	POP {V1, V2, V3, V4, V5, LR}
	BX LR
	

//////////////////////////////////////////////////////////////////////////////////











