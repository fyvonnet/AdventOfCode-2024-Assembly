	.include "macros.inc"	


	.section .rodata
hex_chars: .string "0123456789ABCDEF"
wrong_fmt: .string "Wrong format character: %c\n"


	.text
	.balign 8


	.globl	putc
	.type	putc, @function
putc:
	dec	sp
	sb	a0, (sp)
	li	a0, 1		# stdout
	mv	a1, sp
	li	a2, 1
	li	a7, 64		# write
	ecall
	inc	sp
	ret
	.size	putc, .-putc


	.globl	puts
	.type	puts, @function
puts:
	mv	a1, a0
	mv	t0, a0
	li	a0, 1
	li	a7, 64

	li	a2, 0
loop_strlen:
	lb	t1, (t0)
	beqz	t1, loop_strlen_end
	inc	a2
	inc	t0
	j	loop_strlen

loop_strlen_end:
	ecall

	ret
	.size	puts, .-puts


	# a0: number
	# a1: radix
	.type	print_number, @function
print_number:
	dec	sp, 144
	sd	ra,  128(sp)


	addi	t0, sp, 128

	addi	t0, t0, -1
	sb	zero, (t0)

	la	t6, hex_chars
print_number_loop:
	remu	t1, a0, a1
	add	t1, t1, t6
	lb	t1, (t1)
	addi	t0, t0, -1
	sb	t1, (t0)
	divu	a0, a0, a1
	bnez	a0, print_number_loop


	mv	a0, t0
	call	puts

	ld	ra, 128(sp)
	addi	sp, sp, 144
	

	ret
	.size	print_number, .-print_number



	.globl	printf
	.type	printf, @function
printf:
	mv	t0, sp

	addi	sp, sp, -96
	sd	ra,  8(sp)
	sd	s0, 16(sp)
	sd	s1, 24(sp)
	sd	s2, 32(sp)
	sd	a1, 40(sp)
	sd	a2, 48(sp)
	sd	a3, 56(sp)
	sd	a4, 64(sp)
	sd	a5, 72(sp)
	sd	a6, 80(sp)
	sd	a7, 88(sp)

	mv	s0, a0
	mv	s1, t0
	add	s1, sp, 40

printf_loop:
	lb	t0, (s0)
	beqz	t0, printf_loop_end
	li	t1, '%'
	beq	t0, t1, print_arg
	mv	a0, t0
	call	putc
	j	print_arg_next
print_arg_ret:
	inc	s1, 8
	nop
print_arg_next:
	inc	s0
	j	printf_loop
printf_loop_end:

	ld	ra,  8(sp)
	ld	s0, 16(sp)
	ld	s1, 24(sp)
	ld	s2, 32(sp)
	addi	sp, sp, 96
	ret

print_arg:
	inc	s0
	lb	t0, (s0)
	li	a0, '%'
	bne	t0, a0, not_percentage
	call	putc
	dec	s1, 8
	j	print_arg_ret

not_percentage:

	li	t1, 'c'
	bne	t0, t1, not_char
	lb	a0, (s1)
	call	putc
	j	print_arg_ret
not_char:

	li	t1, 's'
	bne	t0, t1, not_str
	ld	a0, (s1)
	call	puts
	j	print_arg_ret

not_str:

	ld	s2, (s1)

	li      t1, 'u'
	beq     t0, t1, skip_neg

	li	t1, 'd'
	bne	t0, t1, not_int
	bgez	s2, skip_neg
	li	a0, '-'
	call	putc
	neg 	s2, s2
skip_neg:
	mv	a0, s2
	li	a1, 10
	call	print_number
	j	print_arg_ret

not_int:

	mv	a0, s2
	
	li	t1, 'x'
	bne     t0, t1, not_hex
	li	a1, 16
	call	print_number
	j	print_arg_ret

not_hex:

	li	t1, 'b'
	bne     t0, t1, not_bin
	li	a1, 2
	call	print_number
	j	print_arg_ret

not_bin:

	li	t1, 'o'
	bne     t0, t1, not_oct
	li	a1, 8
	call	print_number
	j	print_arg_ret

not_oct:

	dec	s1, 8
	mv	s2, t0
	li	a0, '%'
	call	putc
	mv	a0, s2
	call	putc
	la	a0, wrong_fmt
	mv	a1, t0
	j	print_arg_ret
	
	li	a0, 1
	li	a7, 93
	ecall
	

	

	.size	printf, .-printf

