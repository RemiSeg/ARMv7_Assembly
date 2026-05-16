.global _start

N:			.word 20	// input parameter n
SEQ:		.space 21	// Recaman sequence of n+1 elements
			.space 3	// for correct alignment of instructions
			
_start:
// iterative now
	LDR A1, =N		// get the input parameter n
	LDR A1, [A1]
	LDR A2, =SEQ 	// get the address for results
	BL	recaman		// go!
	B stop
	
stop:
	B	stop
	
	
	
recaman:
	PUSH {V1, V2, V3, V4, LR}
	MOV V1, #0 // pointer index i, n
	MOV V2, #0 // prev value, easier then store and retrieving each time, a(n-1)
	MOV V3, #0 // current a(n-1) - n

loop: // for 0 to N times

	CMP V1, #0
	BEQ baseCase // if n = 0 then 0
	
	// else compute a(n-1) - n 
	SUB V3, V2, V1
	CMP V3, #0
	BLE else1 // else else a(n-1) + n 
	
	// if (in else) [a(n-1) - n] > 0 and not in the sequence (search)
	PUSH {V3, V2, V1, A2, A1, LR}
	MOV A3, V1
	MOV A1, V3
	BL search // will give the answer in A3
	MOV V4, A1
	POP {V3, V2, V1, A2, A1, LR}
	
	CMP V4, #0
	BGE else1 // else else a(n-1) + n 
	
	// then a(n-1) - n 
	MOV V2, V3
	ADD V4, A2, V1
	STRB V2, [V4]
	B loopNext

// if n = 0 then 0
baseCase:
	STRB V1, [A2]
	MOV V2, #0
	
loopNext:
	ADD V1, V1, #1
	CMP V1, A1
	BLE loop
	
	MOV A1, V2
	POP {V1, V2, V3, V4, LR}
	BX LR //done looping
	
	
// else a(n-1) + n 
else1:
	ADD V2, V2, V1
	ADD V4, A2, V1
	STRB V2, [V4]
	B loopNext
	
	
	
search:
	PUSH {V6, V7, V8, LR}
    MOV  V7, #-1
    MOV  V6, #0
loop2:
    CMP V6, A3
	BGE finishLoop2
	
    LDRB V8, [A2, V6]
    CMP V8, A1
    BNE skip
	
    MOV V7, V6
    B finishLoop2
skip:
    ADD V6, V6, #1
    B loop2
finishLoop2:
	MOV A1, V7
	POP {V6, V7, V8, LR}
	BX LR
	