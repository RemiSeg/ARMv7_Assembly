.global _start

N:			.word 20	// input parameter n
SEQ:		.space 21	// Recaman sequence of n+1 elements
			.space 3	// for correct alignment of instructions
			
_start:
	LDR A1, =N		// get the input parameter n
	LDR A1, [A1]
	LDR A2, =SEQ 	// get the address for results
	BL	recaman		// go!
	B stop
	
stop:
	B	stop
	
	
	
recaman:
	// base case
	CMP A1, #0
	BEQ baseCase
	
	PUSH {V1, V2, V3, V4}

	MOV V1, #0 //prev
	MOV V2, #0 // r_nums
	MOV V3, #0 // r_numa
	
	PUSH {A1, LR}
	SUB A1, A1, #1
	BL recaman
	MOV V1, A1
	POP {A1, LR}
	
	SUB V2, V1, A1
	ADD V3, V1, A1
	
	CMP V2, #0
	BLE else 
	
	// seraching time
	PUSH {A2, A1, LR}
	SUB V4, A1, #1
	MOV A1, V2 
	MOV A3, V4
	BL search
	MOV V4, A1
	POP {A2, A1, LR}
	
	CMP  V4, #0 
	BGE else
	
	ADD V4, A2, A1
	STRB V2, [V4]
	LDRB A1, [V4]
	POP  {V1, V2, V3, V4}
	BX LR

else: 
	ADD V4, A2, A1
	STRB V3, [V4]
	LDRB A1, [V4]
	POP  {V1, V2, V3, V4}
	BX LR


baseCase:
	MOV V4, #0
	STRB V4, [A2]
	MOV A1, #0
	BX LR
	
	
search:
    PUSH {V6, V7, V8,LR}
    MOV  V7, #-1
    MOV  V6, #0
loop:
    CMP V6, A3
	BGE finishLoop
    LDRB V8, [A2, V6]
	
	CMP V8, A1
    BNE skip
	
    MOV V7, V6
    B finishLoop

skip:
    ADD V6, V6, #1
    B loop

finishLoop:
	MOV A1, V7
	POP {V7,V6, V8, LR}
	BX LR