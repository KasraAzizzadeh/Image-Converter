%include "asm_io.inc"

%macro before_align 0
    push rbp
    mov rbp, rsp
    mov rax, rsp
    and rax, 15
    sub rsp, rax
%endmacro

%macro after_align 0
    mov rsp, rbp
    pop rbp
%endmacro


segment .data
	;;-- Matrixes
	MATRIX_A: TIMES 64 dd 0
	MATRIX_B: TIMES 64 dd 0
	MATRIX_R: TIMES 64 dd 0
	;;-- Messages
	matrix_one: db "--first matrix--", 0
	matrix_two: db "--second matrix--", 0
	matrix_res: db "--result matrix--", 0
segment .bss
	num: resb 1

segment .text

global asm_main

ready_registers:
	
	sub rsp, 8
	
	mov rax, [num]
	mul rax
	mov r12, rax	;;set loop count equal to n^2
	mov r13, 0	;;set array index for rows, will update in loop to the next matrix row
	mov rax, [num]
	mov r15, 4
	mul r15
	mov r14, rax	;;set index limit for columns = 4n
	mov rbp, 0 	;;set array index for columns will update to go to next row element
	mov rsi, 0	;;set array index for result for going to next element in result matrix

	add rsp, 8
	ret

ready_registerB:

	sub rsp, 8

	mov rax, [num]
	mul rax
	mov r12, rax	;;set loop count equal to n^2
	mov r13, 0	;;set array index for rows, will update in loop to next matrix row
	mov rax, [num]
	mov r15, 32
	mul r15
	mov r14, rax	;;set index limit for rows = 32n
	mov rbp, 0 	;;set array index for columns, will update to go to next row element
	
	add rsp, 8
	ret

get_matrixA:		;;input first matrix

	sub rsp, 8	

		call ready_registers	
		jmp loopA
	
	pre_loopA:
		add r13, 32	;;go to next row
		mov rbp, 0	;;come back to first column

	loopA:
		cmp rbp, r14
		je  pre_loopA	;;if reached last column go to next row
		sub r12, 1	;;update loop counter
		call read_float
		mov [MATRIX_A + r13  + rbp], eax	;;enter float into matrix
		add rbp, 4	;;go to next column
		cmp r12, 0	;;loop condition
		jg  loopA

	call print_nl
	
	add rsp, 8
	ret
		
get_matrixB:		;;input second matrix

	sub rsp, 8

		call ready_registerB
		jmp loopB		;;because matrix is put transposed  we put floats in columns and if they are full we go to next one
	
	pre_loopB:
		add rbp, 4		;;all rows in current columnfull, go to next column
		mov r13, 0		;;come back to first row

	loopB:
		cmp r13, r14		;;if reached last row in current column
		je  pre_loopB		;; go to pre_loopB
		sub r12, 1
		call read_float
		mov [MATRIX_B + r13  + rbp], eax	;;put element transposed
		add r13, 32		;;go to next row
		cmp r12, 0		;;loop condition
		jg  loopB

	call print_nl
	
	add rsp, 8
	ret	

multiply:		;;multiply 2 matrixes based on their n
	
	sub rsp, 8
	
	mov rcx, 100000000		;;loop for finding out time
	loop:
		mov eax, [num]		;;if n < 5 we use one vector multiplication
		cmp eax, 4		;;else if n >= 5 we need to use it twice
		jle small
		jmp big
	
		small: 
			call multiply_small
			jmp out
	
		big:
			call multiply_big
		
		out:
		
		dec rcx
		cmp rcx, 0
		jge loop
		
	add rsp, 8
	ret

multiply_small:

	sub rsp, 8

		call ready_registers
		jmp loopX
	
	pre_loopX:
		add r13, 32		;;go to next row in first matrix and result matrix
		mov rbp, 0		;;back to first element in second  matrix
		mov rsi, 0		;;back to first column in next row of result matrix

	loopX:
		cmp rsi, r14		;;if all columns in row full go to pre_loopX
		je  pre_loopX
		sub r12, 1		;;update loop counter
		movups xmm0, [MATRIX_A + r13]	;;put first 4 numbers of each row
		movups xmm1, [MATRIX_B + rbp]	
		dpps xmm0, xmm1, 0xF1		;;get dot product of floats
		add rbp, 32			;;go to next row in second matrix
		movss [MATRIX_R + r13 + rsi], xmm0	;;put dot product in result matrix
		add rsi, 4		;;go to next column in result matrix
		cmp r12, 0		;;loop condition
		jg  loopX

	add rsp, 8
	ret

multiply_big:

	sub rsp, 8

		call ready_registers
		jmp loopY
	
	pre_loopY:
		add r13, 32		;;go to next row in first matrix and result matrix
		mov rbp, 0		;;back to first element in second  matrix
		mov rsi, 0		;;back to first column in next row of result matrix

	loopY:
		cmp rsi, r14		;;if all columns in row full go to pre_loopY
		je  pre_loopY
		sub r12, 1		;;update loop counter
		movups xmm0, [MATRIX_A + r13]	;;put first 4 numbers of each row
		movups xmm1, [MATRIX_B + rbp]
		dpps xmm0, xmm1, 0xF1	;;dot product of first 4 elements
		add rbp, 16		;;go to next first elements
		movups xmm2, [MATRIX_A + r13 + 16]	;;put second 4 numbers of each row
		movups xmm3, [MATRIX_B + rbp]		;;if matrix was not 8x8 they unneeded elements are zero and do not count
		dpps xmm2, xmm3, 0xF1	;;dor product of second 4 elements
		add rbp, 16		;;go to next row
		addss xmm0, xmm2	;;sum of dot products
		movss [MATRIX_R + r13 + rsi], xmm0	;;put sum in result
		add rsi, 4		;;go to next column in result
		cmp r12, 0		;;loop condition
		jg  loopY

	add rsp, 8
	ret
		
print_result:

	sub rsp, 8

		call ready_registers
		jmp loopR
	
	pre_loopR:
		call print_nl
		add r13, 32	;;go to next row
		mov rbp, 0	;;come back to first column
	loopR:
		cmp rbp, r14	;;if reached last column go to pre_loopR
		je  pre_loopR
		sub r12, 1	;;update loop counter
		mov edi, [MATRIX_R + r13  + rbp]	;;get element in result 
		call print_float	;;print result
		mov edi, 32	
		call print_char		;;print space
		add rbp, 4	;;go to next column in result
		cmp r12, 0	;;loop condition
		jg  loopR

	add rsp, 8
	ret

asm_main:
	push rbp
    push rbx
    push r12
    push r13
    push r14
    push r15

    sub rsp, 8

	;;--------------------------
	
	call read_int 	;;n=3 or n=5
	mov [num], eax 	;;save n

	mov rdi, matrix_one
	call print_string
	call get_matrixA
	
	mov rdi, matrix_two
	call print_string
	call get_matrixB
	
	call multiply
	
	mov rdi, matrix_res
	call print_string
	call print_result
	call print_nl

	;;--------------------------
    add rsp, 8

	pop r15
	pop r14
	pop r13
	pop r12
    pop rbx
    pop rbp

	ret
