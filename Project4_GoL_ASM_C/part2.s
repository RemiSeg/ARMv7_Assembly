.global _start
_start:
        bl      input_loop
end:
        b       end

@ VGA driver

// (int x, int y, short c)
// A1 = x, A2 = y, A3 = c
VGA_draw_point_ASM:
	PUSH {V1, V2, LR}

	// check that x and y are within pixel buffer bounds
	CMP A1, #0
	BLT finish_draw
	CMP A2, #0
	BLT finish_draw

	LDR V1, =319
	CMP A1, V1
	BGT finish_draw
	LDR V1, =239
	CMP A2, V1
	BGT finish_draw

	// compute pixel address: 0xC8000000 | (y << 10) | (x << 1)
	LSL V1, A1, #1
	LSL V2, A2, #10
	ORR V1, V1, V2
	LDR V2, =0xC8000000
	ORR V1, V1, V2

	// store the 16-bit color value
	STRH A3, [V1]

finish_draw:
	POP {V1, V2, LR}
	BX LR


// no input nor output
VGA_clear_pixelbuff_ASM:
	PUSH {V1, V2, LR}

	MOV A2, #0
	LDR V2, =239

	// loop through every row of the pixel buffer
loop_y:
	CMP A2, V2
	BGT end_loops

	MOV A1, #0
	LDR V1, =319

	// loop through every column and draw black pixels
loop_x:
	CMP A1, V1
	BGT next_row

	MOV A3, #0
	BL VGA_draw_point_ASM
	ADD A1, A1, #1
	B loop_x

	// move to the next row
next_row:
	ADD A2, A2, #1
	B loop_y

end_loops:
	POP {V1, V2, LR}
	BX LR


// (int x, int y, char c)
// A1 = x, A2 = y, A3 = c
VGA_write_char_ASM:
	PUSH {V1, V2, LR}

	// check that x and y are within character buffer bounds
	CMP A1, #0
	BLT finish_char
	CMP A2, #0
	BLT finish_char

	LDR V1, =79
	CMP A1, V1
	BGT finish_char
	LDR V1, =59
	CMP A2, V1
	BGT finish_char

	// compute character address: 0xC9000000 | (y << 7) | x
	LSL V1, A2, #7
	ORR V1, V1, A1
	LDR V2, =0xC9000000
	ORR V1, V1, V2

	// store the 8-bit ASCII value
	STRB A3, [V1]

finish_char:
	POP {V1, V2, LR}
	BX LR


// no input nor output
VGA_clear_charbuff_ASM:
	PUSH {V1, V2, LR}

	MOV A2, #0
	LDR V2, =59

	// loop through every row of the character buffer
loop_y_char:
	CMP A2, V2
	BGT end_loops_char

	MOV A1, #0
	LDR V1, =79

	// loop through every column and write null characters
loop_x_char:
	CMP A1, V1
	BGT next_row_char

	MOV A3, #0
	BL VGA_write_char_ASM
	ADD A1, A1, #1
	B loop_x_char

	// move to the next row
next_row_char:
	ADD A2, A2, #1
	B loop_y_char

end_loops_char:
	POP {V1, V2, LR}
	BX LR














@ PS/2 driver

// int read_PS2_data_ASM(char *data)
// A1 = address where byte should be stored
// return A1 = 1 if valid data was read, else 0
// read_PS2_data_ASM checks the RVALID bit in the PS/2 Data register
read_PS2_data_ASM:
	PUSH {V1, V2, LR}

	// keyboard device address
	LDR V1, =0xFF200100
	LDR V2, [V1]
	LSR V1, V2, #15
	AND V1, V1, #1
	CMP V1, #0
	BEQ no_data

	// extract low byte and store it
	AND V2, V2, #255
	STRB V2, [A1]
	MOV A1, #1
	B finish_ps2

no_data:
	// no valid PS/2 byte available
	MOV A1, #0

finish_ps2:
	POP {V1, V2, LR}
	BX LR

















write_hex_digit:
        push    {r4, lr}
        cmp     r2, #9
        addhi   r2, r2, #55
        addls   r2, r2, #48
        and     r2, r2, #255
        bl      VGA_write_char_ASM
        pop     {r4, pc}
write_byte:
        push    {r4, r5, r6, lr}
        mov     r5, r0
        mov     r6, r1
        mov     r4, r2
        lsr     r2, r2, #4
        bl      write_hex_digit
        and     r2, r4, #15
        mov     r1, r6
        add     r0, r5, #1
        bl      write_hex_digit
        pop     {r4, r5, r6, pc}
input_loop:
        push    {r4, r5, lr}
        sub     sp, sp, #12
        bl      VGA_clear_pixelbuff_ASM
        bl      VGA_clear_charbuff_ASM
        mov     r4, #0
        mov     r5, r4
        b       .input_loop_L9
.input_loop_L13:
        ldrb    r2, [sp, #7]
        mov     r1, r4
        mov     r0, r5
        bl      write_byte
        add     r5, r5, #3
        cmp     r5, #79
        addgt   r4, r4, #1
        movgt   r5, #0
.input_loop_L8:
        cmp     r4, #59
        bgt     .input_loop_L12
.input_loop_L9:
        add     r0, sp, #7
        bl      read_PS2_data_ASM
        cmp     r0, #0
        beq     .input_loop_L8
        b       .input_loop_L13
.input_loop_L12:
        add     sp, sp, #12
        pop     {r4, r5, pc}