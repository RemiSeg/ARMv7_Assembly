.global _start
_start:
        bl      draw_test_screen
end:
        b       end
@ TODO: Insert VGA driver functions here.

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












draw_test_screen:
        push    {r4, r5, r6, r7, r8, r9, r10, lr}
        bl      VGA_clear_pixelbuff_ASM
        bl      VGA_clear_charbuff_ASM
        mov     r6, #0
        ldr     r10, .draw_test_screen_L8
        ldr     r9, .draw_test_screen_L8+4
        ldr     r8, .draw_test_screen_L8+8
        b       .draw_test_screen_L2
.draw_test_screen_L7:
        add     r6, r6, #1
        cmp     r6, #320
        beq     .draw_test_screen_L4
.draw_test_screen_L2:
        smull   r3, r7, r10, r6
        asr     r3, r6, #31
        rsb     r7, r3, r7, asr #2
        lsl     r7, r7, #5
        lsl     r5, r6, #5
        mov     r4, #0
.draw_test_screen_L3:
        smull   r3, r2, r9, r5
        add     r3, r2, r5
        asr     r2, r5, #31
        rsb     r2, r2, r3, asr #9
        orr     r2, r7, r2, lsl #11
        lsl     r3, r4, #5
        smull   r0, r1, r8, r3
        add     r1, r1, r3
        asr     r3, r3, #31
        rsb     r3, r3, r1, asr #7
        orr     r2, r2, r3
        mov     r1, r4
        mov     r0, r6
        bl      VGA_draw_point_ASM
        add     r4, r4, #1
        add     r5, r5, #32
        cmp     r4, #240
        bne     .draw_test_screen_L3
        b       .draw_test_screen_L7
.draw_test_screen_L4:
        mov     r2, #72
        mov     r1, #5
        mov     r0, #20
        bl      VGA_write_char_ASM
        mov     r2, #101
        mov     r1, #5
        mov     r0, #21
        bl      VGA_write_char_ASM
        mov     r2, #108
        mov     r1, #5
        mov     r0, #22
        bl      VGA_write_char_ASM
        mov     r2, #108
        mov     r1, #5
        mov     r0, #23
        bl      VGA_write_char_ASM
        mov     r2, #111
        mov     r1, #5
        mov     r0, #24
        bl      VGA_write_char_ASM
        mov     r2, #32
        mov     r1, #5
        mov     r0, #25
        bl      VGA_write_char_ASM
        mov     r2, #87
        mov     r1, #5
        mov     r0, #26
        bl      VGA_write_char_ASM
        mov     r2, #111
        mov     r1, #5
        mov     r0, #27
        bl      VGA_write_char_ASM
        mov     r2, #114
        mov     r1, #5
        mov     r0, #28
        bl      VGA_write_char_ASM
        mov     r2, #108
        mov     r1, #5
        mov     r0, #29
        bl      VGA_write_char_ASM
        mov     r2, #100
        mov     r1, #5
        mov     r0, #30
        bl      VGA_write_char_ASM
        mov     r2, #33
        mov     r1, #5
        mov     r0, #31
        bl      VGA_write_char_ASM
        pop     {r4, r5, r6, r7, r8, r9, r10, pc}
.draw_test_screen_L8:
        .word   1717986919
        .word   -368140053
        .word   -2004318071