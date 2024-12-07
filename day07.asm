	.include "macros.inc"

	.globl	_start

	.set	SUM, -16
	.set	COUNT, -8
	.set	NINSTR, 3

	
	.section .rodata
	.balign 8


funcs:	.dword	add, mul, concatenate_digits

filename:
	.string	"inputs/day07"
	.string	"inputs/day07-test"
ansfmt:	.string "Part %d: %d\n"


	.text
	.balign 8


	func_begin _start
_start:
	la	a0, filename
	call	map_input_file
	mv	s10, a0
	add	s11, a0, a1

	addi	sp, sp, -64*4
	addi	s0, sp, 16

	clr	s1
	clr	s2

loop:
	mv	a0, s10
	mv	a1, s0
	call	parse_input_line
	mv	s10, a0

	mv	a0, s0
	li	a1, 2
	call	check_valid
	add	s1, s1, a0
	add	s2, s2, a0
	bnez	a0, skip	# a line valid with 2 operations is also valid for 3 operations

	mv	a0, s0
	li	a1, 3
	call	check_valid
	add	s2, s2, a0
skip:
	bne	s10, s11, loop


	la	a0, ansfmt
	li	a1, 1
	mv	a2, s1
	call	printf
	
	la	a0, ansfmt
	li	a1, 2
	mv	a2, s2
	call	printf
	

	exit
	func_end _start



add:
	add	a0, a0, a1
	ret

mul:
	mul	a0, a0, a1
	ret
	

	# a0: base
	# a1: exponent
power_of:
	li	t0, 1
loop_power_of:
	beqz	a1, loop_power_of_end
	mul	t0, t0, a0
	dec	a1
	j	loop_power_of
loop_power_of_end:	
	mv	a0, t0
	ret


	# a0: left digit
	# a1: right digit
concatenate_digits:
	dec	sp, 32
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s1, 16(sp)

	mv	s0, a0
	mv	s1, a1

	mv	t1, a1
	clr	t2
	li	t3, 10
loop_right_len:
	beqz	t1, loop_right_len_end
	inc	t2
	div	t1, t1, t3
	j	loop_right_len
loop_right_len_end:

	la	a0, 10
	mv	a1, t2
	call	power_of

	mul	s0, s0, a0
	add	a0, s0, s1

	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	inc	sp, 32
	ret
	


	# a0: array
	# a1: count
	# a2: operations
	# a3: target sum
	# a4: number of instructions
	func_begin apply_operations
apply_operations:
	dec	sp, 48
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s1, 16(sp)
	sd	s2, 24(sp)
	sd	s3, 32(sp)
	sd	s4, 40(sp)

	mv	s0, a0
	mv	s1, a1
	mv	s2, a2
	mv	s3, a3
	mv	s4, a4

	mul	s2, s2, s4	# add a 0 to force addition with the first number and null acumulator
	clr	s5		# accumulator
loop_apply:
	rem	t1, s2, s4	# extract instruction number
	div	s2, s2, s4

	mv	a0, s5
	lw	a1, (s0)	# load int from array
	slli	t1, t1, 3
	la	t0, funcs
	add	t1, t0, t1
	ld	t1, (t1)
	jalr	ra, t1
	ble	a0, s3, loop_apply_next
	clr	a0		# stop early if the computed sum grows too large
	j	apply_operations_end
loop_apply_next:
	mv	s5, a0

	inc	s0, 4
	dec	s1
	bnez	s1, loop_apply

	mv	a0, s5
apply_operations_end:
	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	ld	s2, 24(sp)
	ld	s3, 32(sp)
	ld	s4, 40(sp)
	inc	sp, 48
	ret
	func_end apply_operations




	func_begin check_valid
check_valid:
	dec	sp, 48
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s1, 16(sp)
	sd	s2, 24(sp)
	sd	s3, 32(sp)

	mv	s0, a0
	ld	s1, COUNT(a0)
	ld	s3, SUM(a0)
	mv	s4, a1
	mv	a0, s4
	mv	a1, s1
	call	power_of
	addi	s2, a0, -1

loop_check_valid:
	mv	a0, s0
	mv	a1, s1
	mv	a2, s2
	mv	a3, s3
	mv	a4, s4
	call	apply_operations
stop_here:
	beq	a0, s3, valid_ret

	dec	s2
	bltz	s2, valid_fail
	j	loop_check_valid
valid_fail:
	clr	s3
valid_ret:
	mv	a0, s3
	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	ld	s2, 24(sp)
	ld	s3, 32(sp)
	dec	sp, 48
	ret
	func_end check_valid


	func_begin parse_input_line
parse_input_line:
	dec	sp, 32
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s1, 16(sp)

	clr	s0
	mv	s1, a1

	call	parse_integer
	sd	a1, SUM(s1)

	inc	a0, 2		# skip ": "

loop_parse_input_line:
	call	parse_integer
	sw	a1, (s1)
	inc	s0
	inc	s1, 4
	lb	t0, (a0)
	inc	a0
	li	t1, '\n'
	bne	t0, t1, loop_parse_input_line

	slli	t0, s0, 2
	sub	t0, s1, t0
	sd	s0, COUNT(t0)

	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	inc	sp, 32
	ret
	func_end parse_input_line
