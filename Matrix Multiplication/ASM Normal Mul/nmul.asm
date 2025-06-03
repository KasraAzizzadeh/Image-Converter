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
	;;-- sum
	sum: dd 0.0
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

get_matrixA:	;;input first matrix

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

multiply:

	sub rsp, 8

		call ready_registers
		mov r15, 0
		mov rdx, 0
		
		loop_out:
			cmp rsi, r14	;;if all elements in first row are full go to next row and reset pointers
			jl loopX	;;else go to loopX
			add r13, 32
			xor rdx, rdx
			xor r15, r15
			xor rsi, rsi

			loopX:
				pxor xmm0, xmm0
				movss xmm0, [MATRIX_A + r13 + r15]	;;get first matrix element
				mulss xmm0, [MATRIX_B + rdx + rbp]	;;mul in second matrix element
				addss xmm0, [sum]
				movss [sum], xmm0			;;add to sum
			
				add rbp, 4				;;go to next column in matrixes
				add r15, 4
				cmp rbp, r14				;;if we have not reached last column repeat
				jl loopX

			mov eax, [sum]
			mov [MATRIX_R + r13 + rsi], eax			;;put sum in result
			mov eax, 0
			mov [sum], eax					;;reset sum
			add rsi, 4					;;go to next column in result
			mov rbp, 0					
			add rdx, 32					;;go to first element of next row in second matrix
			xor r15, r15					;;come back to first element in current row of first matrix
			sub r12, 1					;;update loop counter
			cmp r12, 0					;;loop condition
			jg loop_out
	
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
	
	
	mov rbx, 100000000
	loop:
		call multiply
		dec rbx
		cmp rbx, 0
		jge loop
	
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
