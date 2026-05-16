N: .word 4
matrix: .short 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15
vector: .space 32



.global _start


_start:
	
	LDR A1, =matrix
	LDR A2, =N
	LDR A2, [A2]
	LDR A3, =vector
	
	// all actions to be done before the looping start
	MOV V1, #0 // row pointer
	MOV V2, #0 // col pointer
	MOV V3, #0 // seq pointer, element of the output vector
	MOV V4, #1 // dir 1 -> up/right and -1 -> down/left
	
	MOV V5, #0 //dummy values for if/else
	MOV V6, #0 //second dummy
	MUL V7, A2, A2 // n*n computed once top

Loop:
	MUL V5, V1, A2
	ADD V5, V5, V2
	LSL V5, V5, #1
	ADD V5, A1, V5
	LDRSH A4, [V5] // A4 is again a dummy here to be loaded then stored later lines
	
	LSL V6, V3, #1
	STRH A4, [A3, V6] // vector[seq] = matrix[row][col];
	
	// come back to loop later
	ADD V3, V3, #1
	
	// or end
	CMP V3, V7
	BEQ finishedLooping
	
	CMP V4, #1 // dir = 1
	BEQ moveUpRight
	B   moveDownLeft


// first part of the big if-else
moveUpRight:
	SUB V5, A2, #1
	SUBS V5, V2, V5
	BEQ rightDownTurn
	
	CMP V1, #0
	BEQ topRightTurn
	
	B middle
		
rightDownTurn:
	// we're at the right edge, down and turn
	ADD V1, V1, #1
	MOV V4, #-1
	B finishConditional

topRightTurn:
	// we're along the top, right and turn
	ADD V2, V2, #1
	MOV V4, #-1
	B finishConditional
	
middle:
	// we are in the middle thus continue
	ADD V2, V2, #1
	SUB V1, V1, #1
	B finishConditional




// second big part if-else
moveDownLeft:
	SUB V5, A2, #1
	SUBS V5, V1, V5
	BEQ bottomRightTurn
	
	CMP V2, #0
	BEQ leftDownTurn
	
	B middle2
	

bottomRightTurn: 
	// we're at the bottom, right and turn
	ADD V2, V2, #1
	MOV V4, #1
	B finishConditional
	
leftDownTurn: 
	// we're at the left edge, down and turn
	ADD V1, V1, #1
	MOV V4, #1
	B finishConditional

middle2:
	SUB V2, V2, #1
	ADD V1, V1, #1
	B finishConditional
	
finishConditional:
	B Loop
finishedLooping:	
	B stop

stop: 
	B stop