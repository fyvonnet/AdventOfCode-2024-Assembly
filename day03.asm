	.include "macros.inc"

	.globl	_start

	.set	MULTIPLY, 	0
	.set	ENABLE,		1
	.set	DISABLE, 	2

	.section .rodata
filename:
	.string	"inputs/day03"
ansfmt:	.string "Part %d answer: %d\n"

mulstr:	.string "mul("
dostr:	.string "do()"
dontstr:.string "don't()"
nullstr:.string ""

prefixes:
	.dword	mulstr,		MULTIPLY
	.dword	dostr, 		ENABLE
	.dword	dontstr,	DISABLE
	.dword	nullstr,	-1


	.section .text
	.balign 8

	func_begin _start
_start:

	la	a0, filename
	call	map_input_file
	mv	s10, a0
	add	s11, a0, a1

	clr	s0			# Part 1 answer
	clr	s1			# Part 2 answer
	li	s2, 1			# multiplication is enabled by default
	

	mv	a0, s10
loop:
	bge	s10, s11, loop_end

	la	a0, prefixes
	mv	a1, s10
	call	test_all_prefixes
	bltz	a0, loop_next
	li	t0, ENABLE
	beq	a0, t0, mul_enable
	li	t0, DISABLE
	beq	a0, t0, mul_disable
	inc	s10, 4
	mv	a0, s10
	call	parse_integer_maybe
	bltz	a1, multiply_end
	mv	s3, a1
	li	t0, ','
	lb	t1, (a0)
	bne	t0, t1, multiply_end
	inc	a0
	call	parse_integer_maybe
	bltz	a1, multiply_end
	mv	s4, a1
	li	t0, ')'
	lb	t1, (a0)
	bne	t0, t1, multiply_end
multiply:

	mul	s3, s3, s4
	add	s0, s0, s3

	beqz	s2, multiply_end
	add	s1, s1, s3


multiply_end:
	mv	s10, a0

	j	loop_next
mul_enable:
	li	s2, 1
	j	loop_next
mul_disable:
	clr	s2
loop_next:
	inc	s10
	j	loop
loop_end:

	la	a0, ansfmt
	li	a1, 1
	mv	a2, s0
	call	printf

	la	a0, ansfmt
	li	a1, 2
	mv	a2, s1
	call	printf

	exit
	func_end _start


	func_begin parse_integer_maybe
parse_integer_maybe:
	li	t2, -1
	lb	t0, (a0)
	li	t1, '0'
	blt	t0, t1, parse_integer_not
	li	t1, '9'
	bgt	t0, t1, parse_integer_not
	dec	sp, 16
	sd	ra, (sp)
	call	parse_integer
	mv	t2, a1
	ld	ra, (sp)
	inc	sp, 16
parse_integer_not:
	mv	a1, t2
	ret
	func_end parse_integer_maybe


	# a0: prefix
	# a1: string
	func_begin is_prefix
is_prefix:
	lb      t0, (a0)
	beqz    t0, is_prefix_succ
	lb      t1, (a1)
	bne     t0, t1, is_prefix_fail
	inc     a0
	inc     a1
	j       is_prefix
is_prefix_succ:
	la      a0, 1
	ret
is_prefix_fail:
	la      a0, 0
	ret
	func_end is_prefix



	# a0: prefixes array
	# a1: string
test_all_prefixes:
	dec	sp, 32
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s1, 16(sp)

	mv	s0, a0
	mv	s1, a1

loop_all_prefixes:
	ld	a0, 0(s0)
	mv	a1, s1
	call	is_prefix
	bnez	a0, loop_all_prefixes_end
	inc	s0, 16
	j	loop_all_prefixes
loop_all_prefixes_end:
	ld	a0, 8(s0)

	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	inc	sp, 32
	ret

