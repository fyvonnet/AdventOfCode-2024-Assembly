	.include "macros.inc"

	.globl	_start


	.section .rodata
filename:
	.string	"inputs/day22"
ansfmt:	.string	"Part %d answer: %d\n"



	.text
	.balign 8



	func_begin _start
_start:
	la	a0, filename
	call	map_input_file
	mv	s10, a0
	add	s11, a0, a1

	clr	s0
loop:
	mv	a0, s10
	call	parse_integer
	addi	s10, a0, 1
	mv	a0, a1
	call	secret
	add	s0, s0, a0
	blt	s10, s11, loop

	la	a0, ansfmt
	li	a1, 1
	mv	a2, s0
	call	printf
	

	exit
	func_end _start


	func_begin secret
secret:
	li	t0, 16777216
	li	t1, 2000


loop_secret:
	slli	a1, a0, 6	# *64
	xor	a0, a0, a1
	rem	a0, a0, t0

	srli	a1, a0, 5	# /32
	xor	a0, a0, a1
	rem	a0, a0, t0

	slli	a1, a0, 11	# *2048
	xor	a0, a0, a1
	rem	a0, a0, t0

	dec	t1
	bnez	t1, loop_secret

	ret
	func_end secret






