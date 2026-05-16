// implemented so far:
// -> VGA driver in inline assembly
// -> PS/2 driver in inline assembly
// -> VGA_draw_line in inline assembly
// -> GoL_draw_grid in C
// -> VGA_draw_rect in inline assembly
// -> GoL_fill_gridxy in C
// -> GoLBoard in C
// -> GoL_draw_board in C
// -> cursor movement with w a s d
// -> space toggles current cell
// -> n advances one Game of Life generation




// Function prototypes for VGA operations
// so that they can be called from C code
// pretty much just take the previous ARM assembly code and adapt it for C usage
void VGA_draw_point_ASM(int x, int y, short c);
void VGA_clear_pixelbuff_ASM(void);
void VGA_write_char_ASM(int x, int y, char c);
void VGA_clear_charbuff_ASM(void);
void VGA_draw_line(int x1, int y1, int x2, int y2, short c);
void VGA_draw_rect(int x1, int y1, int x2, int y2, short c);
int read_PS2_data_ASM(char *data);

__asm__(
".global VGA_draw_point_ASM\n"
"VGA_draw_point_ASM:\n"
"	PUSH {r4, r5, lr}\n"

"	CMP r0, #0\n"
"	BLT finish_draw\n"
"	CMP r1, #0\n"
"	BLT finish_draw\n"

"	LDR r4, =319\n"
"	CMP r0, r4\n"
"	BGT finish_draw\n"
"	LDR r4, =239\n"
"	CMP r1, r4\n"
"	BGT finish_draw\n"

"	LSL r4, r0, #1\n"
"	LSL r5, r1, #10\n"
"	ORR r4, r4, r5\n"
"	LDR r5, =0xC8000000\n"
"	ORR r4, r4, r5\n"
"	STRH r2, [r4]\n"

"finish_draw:\n"
"	POP {r4, r5, lr}\n"
"	BX lr\n"
);

__asm__(
".global VGA_clear_pixelbuff_ASM\n"
"VGA_clear_pixelbuff_ASM:\n"
"	PUSH {r4, r5, lr}\n"
"	MOV r1, #0\n"
"	LDR r5, =239\n"

"loop_y_pix:\n"
"	CMP r1, r5\n"
"	BGT end_loops_pix\n"

"	MOV r0, #0\n"
"	LDR r4, =319\n"

"loop_x_pix:\n"
"	CMP r0, r4\n"
"	BGT next_row_pix\n"

"	MOV r2, #0\n"
"	BL VGA_draw_point_ASM\n"
"	ADD r0, r0, #1\n"
"	B loop_x_pix\n"

"next_row_pix:\n"
"	ADD r1, r1, #1\n"
"	B loop_y_pix\n"

"end_loops_pix:\n"
"	POP {r4, r5, lr}\n"
"	BX lr\n"
);

__asm__(
".global VGA_write_char_ASM\n"
"VGA_write_char_ASM:\n"
"	PUSH {r4, r5, lr}\n"
"	CMP r0, #0\n"
"	BLT finish_char\n"
"	CMP r1, #0\n"
"	BLT finish_char\n"

"	LDR r4, =79\n"
"	CMP r0, r4\n"
"	BGT finish_char\n"
"	LDR r4, =59\n"
"	CMP r1, r4\n"
"	BGT finish_char\n"

"	LSL r4, r1, #7\n"
"	ORR r4, r4, r0\n"
"	LDR r5, =0xC9000000\n"
"	ORR r4, r4, r5\n"
"	STRB r2, [r4]\n"

"finish_char:\n"
"	POP {r4, r5, lr}\n"
"	BX lr\n"
);

__asm__(
".global VGA_clear_charbuff_ASM\n"
"VGA_clear_charbuff_ASM:\n"
"	PUSH {r4, r5, lr}\n"
"	MOV r1, #0\n"
"	LDR r5, =59\n"

"loop_y_char:\n"
"	CMP r1, r5\n"
"	BGT end_loops_char\n"

"	MOV r0, #0\n"
"	LDR r4, =79\n"

"loop_x_char:\n"
"	CMP r0, r4\n"
"	BGT next_row_char\n"

"	MOV r2, #0\n"
"	BL VGA_write_char_ASM\n"
"	ADD r0, r0, #1\n"
"	B loop_x_char\n"

"next_row_char:\n"
"	ADD r1, r1, #1\n"
"	B loop_y_char\n"

"end_loops_char:\n"
"	POP {r4, r5, lr}\n"
"	BX lr\n"
);

__asm__(
".global read_PS2_data_ASM\n"
"read_PS2_data_ASM:\n"
"	PUSH {r4, r5, lr}\n"

"	LDR r4, =0xFF200100\n"
"	LDR r5, [r4]\n"

"	LSR r4, r5, #15\n"
"	AND r4, r4, #1\n"
"	CMP r4, #0\n"
"	BEQ no_ps2_data\n"

"	AND r5, r5, #255\n"
"	STRB r5, [r0]\n"
"	MOV r0, #1\n"
"	B finish_ps2\n"

"no_ps2_data:\n"
"	MOV r0, #0\n"

"finish_ps2:\n"
"	POP {r4, r5, lr}\n"
"	BX lr\n"
);

__asm__(
".global VGA_draw_line\n"
"VGA_draw_line:\n"
"	PUSH {r4, r5, r6, r7, lr}\n"
"	LDR r6, [sp, #20]\n"

"	CMP r0, r2\n"
"	BEQ vertical_line\n"

"	CMP r1, r3\n"
"	BEQ horizontal_line\n"

"	B end_line\n"

"vertical_line:\n"
"	MOV r4, r1\n"
"	MOV r5, r3\n"
"	CMP r4, r5\n"
"	BLE v_loop_start\n"
"	MOV r4, r3\n"
"	MOV r5, r1\n"

"v_loop_start:\n"
"	CMP r4, r5\n"
"	BGT end_line\n"

"v_loop:\n"
"	MOV r1, r4\n"
"	MOV r2, r6\n"
"	BL VGA_draw_point_ASM\n"
"	ADD r4, r4, #1\n"
"	CMP r4, r5\n"
"	BLE v_loop\n"
"	B end_line\n"

"horizontal_line:\n"
"	MOV r4, r0\n"
"	MOV r5, r2\n"
"	CMP r4, r5\n"
"	BLE h_loop_start\n"
"	MOV r4, r2\n"
"	MOV r5, r0\n"

"h_loop_start:\n"
"	CMP r4, r5\n"
"	BGT end_line\n"

"h_loop:\n"
"	MOV r0, r4\n"
"	MOV r2, r6\n"
"	BL VGA_draw_point_ASM\n"
"	ADD r4, r4, #1\n"
"	CMP r4, r5\n"
"	BLE h_loop\n"

"end_line:\n"
"	POP {r4, r5, r6, r7, lr}\n"
"	BX lr\n"
);

__asm__(
".global VGA_draw_rect\n"
"VGA_draw_rect:\n"
"	PUSH {r4, r5, r6, r7, r8, lr}\n"
"	LDR r8, [sp, #24]\n"

"	MOV r4, r0\n"
"	MOV r5, r2\n"
"	CMP r4, r5\n"
"	BLE rect_x_ok\n"
"	MOV r4, r2\n"
"	MOV r5, r0\n"

"rect_x_ok:\n"
"	MOV r6, r1\n"
"	MOV r7, r3\n"
"	CMP r6, r7\n"
"	BLE rect_y_ok\n"
"	MOV r6, r3\n"
"	MOV r7, r1\n"

"rect_y_ok:\n"
"rect_loop_y:\n"
"	CMP r6, r7\n"
"	BGT rect_done\n"

"	MOV r0, r4\n"
"	MOV r1, r6\n"
"	MOV r2, r5\n"
"	MOV r3, r6\n"
"	SUB sp, sp, #4\n"
"	STR r8, [sp]\n"
"	BL VGA_draw_line\n"
"	ADD sp, sp, #4\n"

"	ADD r6, r6, #1\n"
"	B rect_loop_y\n"

"rect_done:\n"
"	POP {r4, r5, r6, r7, r8, lr}\n"
"	BX lr\n"
);


// initial Game of Life board
// given in the lab
int GoLBoard[12][16] = {
	// x 0 1 2 3 4 5 6 7 8 9 a b c d e f y
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, // 0
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, // 1
	{0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0}, // 2
	{0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0}, // 3
	{0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0}, // 4
	{0,0,0,0,0,0,0,1,1,1,1,1,0,0,0,0}, // 5
	{0,0,0,0,1,1,1,1,1,0,0,0,0,0,0,0}, // 6
	{0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0}, // 7
	{0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0}, // 8
	{0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0}, // 9
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, // a
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0} // b
};

int NextBoard[12][16];

// cursor position
int CursorX = 0;
int CursorY = 0;


// draws a 16x12 grid over the full 320x240 screen
void GoL_draw_grid(short c)
{
	for (int x = 0; x <= 320; x += 20) {
		int draw_x = (x == 320) ? 319 : x;
		VGA_draw_line(draw_x, 0, draw_x, 239, c);
	}

	for (int y = 0; y <= 240; y += 20) {
		int draw_y = (y == 240) ? 239 : y;
		VGA_draw_line(0, draw_y, 319, draw_y, c);
	}
}


// fills one Game of Life cell (grid x,y) using a 20x20 pixel square
void GoL_fill_gridxy(int x, int y, short c)
{

	int x1 = x * 20 + 1;
	int y1 = y * 20 + 1;
	int x2 = x * 20 + 18;
	int y2 = y * 20 + 18;

	VGA_draw_rect(x1, y1, x2, y2, c);
}


// draws all alive cells stored in GoLBoard
void GoL_draw_board(short c)
{
	for (int y = 0; y < 12; y++) {

		for (int x = 0; x < 16; x++) {

			if (GoLBoard[y][x] == 1) {
				GoL_fill_gridxy(x, y, c);
			}

		}
	}
}


// draws the cursor over the current cell
void GoL_draw_cursor(void)
{

	if (GoLBoard[CursorY][CursorX] == 1) {
		GoL_fill_gridxy(CursorX, CursorY, (short)0xFFE0);
	}

	else {
		GoL_fill_gridxy(CursorX, CursorY, (short)0xF800);
	}

}


// redraws the whole visible game state
void GoL_redraw(void)
{
	VGA_clear_pixelbuff_ASM();

	GoL_draw_grid((short)0xFFFF);
	GoL_draw_board((short)0x07E0);

	GoL_draw_cursor();
}


// counts alive neighbors around one cell
int GoL_count_neighbors(int x, int y)
{
	int count = 0;

	for (int dy = -1; dy <= 1; dy++) {


		// check all 8 neighbors cases
		for (int dx = -1; dx <= 1; dx++) {
			if (dx == 0 && dy == 0) {

				continue;
			}


			int nx = x + dx;
			int ny = y + dy;


			if (nx >= 0 && nx < 16 && ny >= 0 && ny < 12) {
				if (GoLBoard[ny][nx] == 1) {
					count++;
				}
			}
		}
	}

	return count;
}


// computes one next generation and copies it back to GoLBoard
void GoL_next_generation(void)
{
	for (int y = 0; y < 12; y++) {

		for (int x = 0; x < 16; x++) {

			int neighbors = GoL_count_neighbors(x, y);

			if (GoLBoard[y][x] == 1) {
				if (neighbors == 2 || neighbors == 3) {
					NextBoard[y][x] = 1;

				}
				else {
					NextBoard[y][x] = 0;
				}
			}
			else {
				if (neighbors == 3) {
					NextBoard[y][x] = 1;
				}

				else {
					NextBoard[y][x] = 0;
				}

			}

		}
	}

	for (int y = 0; y < 12; y++) {
		for (int x = 0; x < 16; x++) {
			GoLBoard[y][x] = NextBoard[y][x];
		}
	}
}
	
// check a key press
// thus must check all possible key presses (conditonal below)
int main(void)
{
	char ps2_byte;
	int break_code = 0;

	VGA_clear_pixelbuff_ASM();
	VGA_clear_charbuff_ASM();
	GoL_redraw();

	while (1) {
		if (read_PS2_data_ASM(&ps2_byte)) {

			if ((unsigned char)ps2_byte == 0xF0) {
				break_code = 1;
			}
			else if (break_code) {
				break_code = 0;

			}
			else {
				if ((unsigned char)ps2_byte == 0x1D) {
					if (CursorY > 0) {
						CursorY--;

						GoL_redraw();
					}
				}
				else if ((unsigned char)ps2_byte == 0x1C) {
					if (CursorX > 0) {

						CursorX--;
						GoL_redraw();

					}
				}
				else if ((unsigned char)ps2_byte == 0x1B) {
					if (CursorY < 11) {
						
						CursorY++;
						GoL_redraw();
					}
				}
				else if ((unsigned char)ps2_byte == 0x23) {
					if (CursorX < 15) {

						CursorX++;
						GoL_redraw();

					}
				}
				else if ((unsigned char)ps2_byte == 0x29) {
					if (GoLBoard[CursorY][CursorX] == 1) {
						GoLBoard[CursorY][CursorX] = 0;

					}

					else {
						GoLBoard[CursorY][CursorX] = 1;
					}
					GoL_redraw();

				}
				else if ((unsigned char)ps2_byte == 0x31) {
					GoL_next_generation();

					GoL_redraw();

				}
			}
		}
	}

	return 0;
}