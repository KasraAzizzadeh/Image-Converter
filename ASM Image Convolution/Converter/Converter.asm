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
	KERNEL: TIMES 28 dd 0
	INVERS: TIMES 28 dd 0
	PIXELS: TIMES 1000000 dd 0
	RESULT: TIMES 1000000 dd 0
	;;-- Messages
	matrix_one: db "--kernel matrix--", 0
	matrix_two: db "--pixels matrix--", 0
	matrix_res: db "--result matrix--", 0
	dimensions: db "--pixels rows and columns--", 0
	;;-- variables
	numsq: dq 0
	num4n: dq 0
	vmul_count: dq 0
	sum: dd 0.0

	rows: dq 0
	columns: dq 0
	allPixels: dq 0

segment .bss
	num: resq 1
	iPixels: resq 1
	jPixels: resq 1
	iIndex: resq 1
	jIndex: resq 1

segment .text

global asm_main

get_kernel:

	sub rsp, 8	
	
	mov r12, qword [numsq] 	;put loop count in r12
	mov rbp, 0		;set rbp as index for matrix

	loopK:
		sub r12, 1
		call read_float		;read float
		mov [KERNEL + rbp], eax ;put input in index + offset
		add rbp, 4		;update index
		cmp r12, 0		;loop condition
		jg  loopK

	call print_nl
	
	mov rax, qword [numsq]
	mov rbx, 4
	div rbx				;;put n^2/4 in vmul_count
	inc rax				;;as number of times we need
	mov qword [vmul_count], rax		;;vector mul for 2 matrixes
	
	mov rax, qword [num]
	dec rax
	mov rbx, 4			;;put 4n in num4n
	mul rbx				;;for later putting pixels
	mov qword [num4n], rax		;;in inverse matrix backwards
	
	add rsp, 8
	ret
		
get_pixels:

	sub rsp, 8
	
	mov r12, qword [allPixels]		;;set loop count as total number of pixels
	mov rbp, 0			;;set index
	
	loopP:
		sub r12, 1
		call read_float		;input float
		mov [PIXELS + rbp], eax ;put float in offset + index
		add rbp, 4		;update index
		cmp r12, 0		;loop condition
		jg  loopP

	call print_nl
	
	add rsp, 8
	ret	

multiply_packed:

	sub rsp, 8

	mov rcx, qword [vmul_count]		    ;;loop counter for multiplication = n^2/4
	mov rsi, 0			    ;;index for matrix iteration
	
	loopX:
		sub rcx, 1		    ;;update loop counter
		movups xmm0, [KERNEL + rsi] ;;put first 4 floats from offset kernel into xmm0
		movups xmm1, [INVERS + rsi] ;;put first 4 floats from offset inverse into xmm1
		dpps xmm0, xmm1, 0xF1 	    ;;get dot product of 8 floats
		add rsi, 16		    ;;update index from offset
		addss xmm0, [sum]
		movss [sum], xmm0 	    ;;get sum of all n^2 dot products
		cmp rcx, 0		    ;;loop condition
		jg  loopX

	add rsp, 8
	ret

get_index:			;;get correct edge index
	sub rsp, 8
	
	mov rax, qword [rows]
	dec rax
	mov rbx, qword [columns]
	dec rbx
	
	mov rcx, qword [iIndex]		;;if i index > rows then i index = rows
	cmp rcx, rax
	jle xSmaller
	mov qword [iIndex], rax
	jmp yStart
	
	xSmaller:
		cmp rcx, 0			;;if j index < then i index = 0
		jge yStart
		mov rdx, 0
		mov qword [iIndex], rdx
	yStart:
		mov rcx, qword [jIndex]		;;if j index > columns then j index = columns
		cmp rcx, rbx
		jle ySmaller
		mov qword [jIndex], rbx
		jmp finish
	ySmaller:
		cmp rcx, 0			;;if j index < 0 then j index = 0
		jge finish
		mov rdx, 0
		mov qword [jIndex], rdx
	finish:
	
	add rsp, 8
	ret


convolution:
    sub rsp, 8

    mov rax, qword [num]
    mov rbx, 2
    div rbx

    mov r15, rax    ; put n/2 in r15

    mov r12, [allPixels]      ; define counter, main counter for going through pixels
    sub r12, 1

    loopC:
        mov rax, r12
        xor rdx, rdx
        mov rbx, qword [rows]
        idiv rbx
        mov qword [iPixels], rax	;;put current row in iPIxels
        mov qword [jPixels], rdx	;;put current column in jIxels

        mov r13, 0  ; counter for x for going through pixel rows
	mov rbp, 0  ; index for putting in inverse

        row_loop:
            mov rax, qword [iPixels]
            add rax, r13
            sub rax, r15
            mov qword [iIndex], rax		;;get which row element we should put in in inverse matrix

            
            mov r14, 0  ; counter for y for pixel columns

            column_loop:
                mov rax, qword [jPixels]
                add rax, r14
                sub rax, r15
                mov qword [jIndex], rax		;;get which column element we should put in in inverse matrix

                call get_index			;;get current index for edge elements


                mov rax, qword [iIndex]
                mov rbx, qword [rows]
		mul rbx
		add rax, qword [jIndex]
                mov rsi, rax     

                mov ebx, [PIXELS + rsi * 4]   	;;copy element from pixels to inverse for multiplication

                mov [INVERS + rbp], ebx


                add rbp, 4

                inc r14				;;go to next column around current pixel
                cmp r14, qword [num]
                jl column_loop

            inc r13				;;go to next row around current pixel
            cmp r13, qword [num]
            jl row_loop

        mov eax, 0
        mov [sum], eax				;;erase garbage from sum
        call multiply_packed			;;multiply
	mov eax, [sum]
	mov [RESULT + r12 * 4], eax		;;put convolution product in result

        pxor xmm0, xmm0
        movss xmm0, [sum]

	cvtss2si edi, xmm0			;;turn float into int for pixel
	
        cmp rdi, 256				;;pixel should be between 0 to 255
        jl print_value
        mov rdi, 0

    print_value:
	call print_int
        call print_nl

        add r12, 1				;;update loop counter
        cmp r12, [allPixels]			;;loop condition
        jl loopC

    add rsp,8
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
	mov qword [num], rax 	;;save n
	
	mul eax
	mov qword [numsq], rax
	
	call get_kernel
	
	xor rax, rax
	call read_int
	mov qword [rows], rax
	call read_int
	mov qword [columns], rax
	mov rbx, qword [rows]
	mul rbx
	mov qword [allPixels], rax
	
	call get_pixels

	mov rdi, qword [rows]
	call print_int
	call print_nl
	mov rdi, qword [columns]
	call print_int
	call print_nl
	call convolution

	;;--------------------------
    add rsp, 8

	pop r15
	pop r14
	pop r13
	pop r12
    pop rbx
    pop rbp

	ret
