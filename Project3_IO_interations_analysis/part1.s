.equ PUSH0, 0xff200050 //IRQ 73 ff200050
.equ PUSH_INTER, 0xff200058
.equ PUSH_EDGECP, 0xff20005c

.equ HEX0, 0xFF200020
.equ HEX4, 0xFF200030

.equ SW_ADDR, 0xFF200040
.equ LED_ADDR, 0xFF200000

HEX_CODES:
	.byte 0b00111111, 0b00000110, 0b01011011, 0b01001111 // 0, 1, 2, 3
	.byte 0b01100110, 0b01101101, 0b01111101, 0b00000111 // 4, 5, 6, 7
	.byte 0b01111111, 0b01101111, 0b01110111, 0b01111100 // 8, 9, A, b
	.byte 0b00111001, 0b01011110, 0b01111001, 0b01110001 // C, d, E, F

MES_C0FFEE: .byte 12, 0, 15, 15, 14, 14 // C, 0, F, F, E, E
MES_CAFE5: .byte 12, 10, 15, 14, 5, 0xFF // C, A, F, E, 5, blank
MES_CAB5: .byte 12, 10, 11, 5, 0xFF, 0xFF // C, A, b, 5, blank, blank
MES_ACE: .byte 10, 12, 14, 0xFF, 0xFF, 0xFF // A, C, E, blank, blank, blank
MES_BLANK: .byte 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF // blank, blank, blank, blank, blank, blank

MES_CURR: .space 6
DIRECTION_ROT: .word 0 // 0 for normal, left and 1 for inverse, right
COUNT_ROT: .word 0 // maximum of 1023
VALID_FLAG: .word 1 // here 1 will be valide and 0 will be invalid

LAST_SW: .word 0xFFFFFFFF

POS_HEX: .byte 0x20, 0x10, 0x08, 0x04, 0x02, 0x1 // as HEX 5-4-3-2-1-0

.align 2
//////////////////////////////////////////////////////////////////////////////////


.global _start

.global HEX_write_ASM
.global HEX_clear_ASM
.global HEX_flood_ASM

.global read_slider_switches_ASM
.global write_LEDs_ASM

.global read_PB_data_ASM
.global PB_data_is_pressed_ASM
.global read_PB_edgecp_ASM
.global PB_edgecp_is_pressed_ASM
.global PB_clear_edgecp_ASM
.global enable_PB_INT_ASM
.global disable_PB_INT_ASM


//////////////////////////////////////////////////////////////////////////////////




_start:
	BL PB_clear_edgecp_ASM // nothing pushed yet, so lets reset
polling_loop:
	BL read_slider_switches_ASM // read the switches for the patterns, in the A1
	// returns the state of slider switches in A1
	LDR V4, =0x3FF // 0b111 1111 1111
	AND A1, A1, V4 // so lets check which are pressed
	LDR V1, =LAST_SW
	LDR V2, [V1]
	CMP A1, V2 // see the difference pressed
	BEQ check_buttons
	
	STR A1, [V1] // just to keep the switch state, from last switch same since not changed
	BL complete_msg_load // loads the current message
	// and since we sitched of messages then must reset leds and count
	BL reset_counter_and_leds
	
	BL display_current_msg
	
check_buttons:
	BL read_PB_edgecp_ASM // check the pressed/release PB, only for PB3-2
	AND V1, A1, #0xC // remember the one PB pressed
	CMP V1, #0
	BEQ polling_loop // if none
	
	TST V1, #0x4
	BEQ check_PB3 // if PB2 pressed stay
	
	LDR V2, =DIRECTION_ROT
	LDR V3, [V2] // chech the direction of the display
	EOR V3, V3, #1 // XOR with 1, since PB2 is the only other option
	STR V3, [V2]
check_PB3:
	TST V1, #0x8
	BEQ done_buttons_safe // if PB3 not pressed go back
	
	LDR V2, =VALID_FLAG
	LDR V3, [V2]
	CMP V3, #0
	BEQ done_buttons_safe // invalid message: no rotate, but event was handled
	
	LDR V2, =DIRECTION_ROT
	LDR V3, [V2]
	CMP V3, #0
	BEQ rotate_left // do the left rotation

	BL make_rot_right // do the right rotation
	B after_rotate
rotate_left:	
	BL make_rot_left
after_rotate:
	BL increment_rotation_cnt
	BL display_current_msg
	
done_buttons_safe:
	BL PB_clear_edgecp_ASM // catch and clear
	B polling_loop



//////////////////////////////////////////////////////////////////////////////////	


increment_rotation_cnt:
	PUSH {V1, V2, V3, LR}
	LDR V1, =COUNT_ROT
	LDR V2, [V1]
	LDR V3, =1023
	CMP V2, V3
	BGE already_max_cnt
	
	ADD V2, V2, #1
	STR V2, [V1]
already_max_cnt:
	MOV A1, V2
	BL write_LEDs_ASM // displays all leds displays still until we reset
	
	POP {V1, V2, V3, LR}
	BX LR


//////////////////////////////////////////////////////////////////////////////////

// to reset the counter
reset_counter_and_leds:
	PUSH {V1, LR}
	LDR v1, =COUNT_ROT
	MOV A1, #0
	STR A1, [V1]
	
	BL write_LEDs_ASM // should be displayed nothing in leds, since reset
	POP {V1, LR}
	BX LR
	
	
//////////////////////////////////////////////////////////////////////////////////


make_rot_right:
	PUSH {V1, V2, V3, LR}
	LDR V1, =MES_CURR
	LDRB V2, [V1, #5] // f in
	// a b c d e f -> f a b c d e
	LDRB V3, [V1, #4]
	STRB V3, [V1, #5]

	LDRB V3, [V1, #3]
	STRB V3, [V1, #4]

	LDRB V3, [V1, #2]
	STRB V3, [V1, #3]

	LDRB V3, [V1, #1]
	STRB V3, [V1, #2]

	LDRB V3, [V1, #0]
	STRB V3, [V1, #1]

	// place back f into a place
	STRB V2, [V1, #0]
	POP {V1, V2, V3, LR}
	BX LR


//////////////////////////////////////////////////////////////////////////////////

make_rot_left:
	PUSH {V1, V2, V3, LR}
	LDR V1, =MES_CURR
	LDRB V2, [V1] // a in
	// a b c d e f -> b c d e f a
	// same principle as above now
	LDRB V3, [V1, #1]
	STRB V3, [V1, #0]
	LDRB V3, [V1, #2]
	STRB V3, [V1, #1]
	LDRB V3, [V1, #3]
	STRB V3, [V1, #2]
	LDRB V3, [V1, #4]
	STRB V3, [V1, #3]
	LDRB V3, [V1, #5]
	STRB V3, [V1, #4]
	// then place back a into the end
	STRB V2, [V1, #5]
	POP {V1, V2, V3, LR}
	BX LR
//////////////////////////////////////////////////////////////////////////////////

display_current_msg:
	PUSH {V1, V2, V3, V4, LR}
	LDR V1, =MES_CURR
	LDR V2, =POS_HEX
	MOV V3, #6 // counter of how many to display
loop_dis_msg:
	LDRB V4, [V1], #1
	LDRB A1, [V2], #1
	CMP V4, #0XFF // if blanck
	BNE loop_display_sgl // then display the appropriate single digit hex, not blanck
	BL HEX_clear_ASM
	B next_display

loop_display_sgl:
	MOV A2, V4
	BL HEX_write_ASM
next_display:
	SUBS V3, V3, #1
	BNE loop_dis_msg
	POP {V1, V2, V3, V4, LR}
	BX LR


//////////////////////////////////////////////////////////////////////////////////


// assuming that A1 has the address of the message to copy into the current one, -> MES_CURR
copy_msg_in_curr:
	PUSH {V1, V2, V3, V4, LR}
	MOV V1, A1
	LDR V2, =MES_CURR
	MOV V3, #6
loop_coying:
	LDRB V4, [V1], #1
	STRB V4, [V2], #1
	SUBS V3, V3, #1
	BNE loop_coying
	POP {V1, V2, V3, V4, LR}
	BX LR

//////////////////////////////////////////////////////////////////////////////////


// from the input values of the switch in A1
// lets load new MES_CURR
complete_msg_load:
	PUSH {V1, V2, LR}
	CMP A1, #0
	BEQ load_msg_coffee
	CMP A1, #1
	BEQ load_msg_cafe5
	CMP A1, #2
	BEQ load_msg_cab5
	CMP A1, #4 // since 0x04
	BEQ load_msg_ace
	// if the any other = consider invalid = blank
	LDR A1, =MES_BLANK
	BL copy_msg_in_curr
	LDR V1, =VALID_FLAG // place the invalid flag for the next ones
	MOV V2, #0
	STR V2, [V1]
	POP {V1, V2, LR}
	BX LR
load_msg_coffee:
	LDR A1, =MES_C0FFEE
	BL copy_msg_in_curr
	LDR V1, =VALID_FLAG // replace the valid flag for next time since now valid
	MOV V2, #1
	STR V2, [V1]
	POP {V1, V2, LR}
	BX LR
load_msg_cafe5:
	LDR A1, =MES_CAFE5
	BL copy_msg_in_curr
	LDR V1, =VALID_FLAG // same principle of validity
	MOV V2, #1
	STR V2, [V1]
	POP {V1, V2, LR}
	BX LR
load_msg_cab5:
	LDR A1, =MES_CAB5
	BL copy_msg_in_curr
	LDR V1, =VALID_FLAG
	MOV V2, #1
	STR V2, [V1]
	POP {V1, V2, LR}
	BX LR
load_msg_ace:
	LDR A1, =MES_ACE
	BL copy_msg_in_curr
	LDR V1, =VALID_FLAG
	MOV V2, #1
	STR V2, [V1]
	POP {V1, V2, LR}
	BX LR
	



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

	MOV V1, #1 // code HEX
	MOV V3, #0 // offset equivalent
loop1:
	CMP V1, #0x40 // since the last HEX5 is coded in 0x0000 0020
	BEQ finish1
	TST A1, V1 // and op, compare with HEX0 to HEX5 codes, see which are in given indices
	BEQ next1
	
	CMP V3, #4 // since the 0-3 HEX are on the same word ff200020
	BLT hex_zero_to_three_WRITE

	LDR V4, =HEX4 // but if we are at 4-5 HEX then switch word ff200030
	SUB V5, V3, #4 // offset v3 to much 
	STRB V2, [V4, V5]
	B next1
	
hex_zero_to_three_WRITE:
	LDR V4, =HEX0
	STRB V2, [V4, V3]
next1:
	ADD V3, V3, #1
	LSL V1, V1, #1 // next HEX to compare
	B loop1
finish1:
	POP {V1, V2, V3, V4, V5, LR}
	BX LR

//////////////////////////////////////////////////////////////////////////////////


// Turn off all segment of the HEX seleted
// A1: HEX indices to clear again store in R0
HEX_clear_ASM:
	PUSH {V1, V2, V3, V4, V5, LR}
	MOV V1, #1 // so smae principle as above write_ASM func. this is the HEX 
	MOV V2, #0 // and this is the offset to switch word at 4-5 HEX
loop2:
	CMP V1, #0x40 // stop after HEX5, or at 'HEX6'
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
	MOV V5, #0 // same principle as above but we don't place the value but 0
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
	MOV V1, #1 // 3rd time we use the same principle this is the HEX
	MOV V2, #0 // and this is the offset to signal HEX4-5
loop3:
	CMP V1, #0x40 // stop
	BEQ finish3

	TST A1, V1
	BEQ next3

	CMP V2, #4
	BLT hex_zero_to_three_flood

	LDR V3, =HEX4
	SUB V4, V2, #4
	MOV V5, #0b01111111 // difference place 8 display to the switches
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

	
// Returns the indices of the pressed buttons
// One hot encoded
// No input needed
// output on A1 the one hot encoding of PB0-3
read_PB_data_ASM:
	PUSH {V1, LR}
	LDR V1, =PUSH0 // 0xff20 0050
	LDR A1, [V1]
	AND A1, A1, #0xF
	POP {V1, LR}
	BX LR

//////////////////////////////////////////////////////////////////////////////////

// Check if the given index is pressed (as one hot encoded)
// A1 input of the PB wanted to check
// Returns A1 if pressed (0x00000001)
PB_data_is_pressed_ASM:
	PUSH {V1, LR}
	MOV V1, A1 // to not overwrite the input
	BL read_PB_data_ASM
	TST A1, V1 // compare the those pressed with the ones wanted
	MOVNE A1, #1
	MOVEQ A1, #0
	POP {V1, LR}
	BX LR
	
//////////////////////////////////////////////////////////////////////////////////


// A1 returns indices of the pushbuttons
// which have been pressed and released
read_PB_edgecp_ASM:
	PUSH {V1, LR}
	LDR V1, =PUSH_EDGECP // 0xff20 005c, since we do not care about the PB0, nor PB1
	LDR A1, [V1] // load the 4B but onlt needs the LSB byte thus, and it with 0xF
	AND A1, A1, #0x0F
	POP {V1, LR}
	BX LR

//////////////////////////////////////////////////////////////////////////////////	

// Input A1 index of a button 
// Returns 0x00000001 if have been pressed and released
PB_edgecp_is_pressed_ASM:
	PUSH {V1, V2, LR}
	MOV V1, A1 // save combination inputs to check, cause A1 will be overwritten
	BL read_PB_edgecp_ASM
	TST A1, V1 // compare those wanted with those actually pressed/released
	MOVEQ V2, #0
	MOVNE V2, #1
	MOV A1, V2
	POP {V1, V2, LR}
	BX LR
	
//////////////////////////////////////////////////////////////////////////////////

// Clears the byte of the Edgecapture register
PB_clear_edgecp_ASM:
	PUSH {V1, V2,LR}
	LDR V1, =PUSH_EDGECP // 0xff20 005c
	LDR V2, [V1] // from the notes, load and store back to clear
	STR V2, [V1]
	POP {V1, V2,LR}
	BX LR

//////////////////////////////////////////////////////////////////////////////////


// Input A1 index of a button
// Enables its interrupts signal, with 1
enable_PB_INT_ASM:
	PUSH {V1, V2, LR}
	LDR V1, =PUSH_INTER // 0xff200058, where the register is the enable the interrupt for the wanted PB
	LDR V2, [V1]
	ORR V2, V2, A1
	STR V2, [V1]
	POP {V1, V2, LR}
	BX LR
	
//////////////////////////////////////////////////////////////////////////////////

// Input A1 index of a button
// Enables its interrupts signal, with 0
disable_PB_INT_ASM:
	PUSH {V1, V2, V3, LR}
	LDR V1, =PUSH_INTER // 0xff200058, same principle take existing register and change only the wanted PB
	LDR V2, [V1]
	MVN V3, A1 // take inverse of A1, indice to change, to have a AND and killing the wanted PB indices
	AND V2, V2, V3
	STR V2, [V1]
	POP {V1, V2, V3, LR}
	BX LR

//////////////////////////////////////////////////////////////////////////////////





