	.include "macros.inc"

	.section .rodata
filename:.string 	"inputs/day02"
ansfmt:	.string		"Part %d answer: %d\n"


	.text
	.balign 8


	.globl _start
	func_begin _start
_start:
	la	a0, filename
	call	map_input_file
	mv	s10, a0
	add	s11, a0, a1

	# allocate stack space for full layer
	dec	sp, 16*4
	mv	s0, sp

	# allocate stack space for reduced layer
	dec	sp, 16*4
	mv	s1, sp


	clr	s2		# safe counter
	clr	s3		# safe-ish counter
loop_lines:
	mv	a0, s10
	mv	a1, s0
	call	parse_input_line
	mv	s10, a0
	mv	s4, a1

	mv	a0, s0
	mv	a1, s4
	call	is_safe
	add	s2, s2, a0
	add	s3, s3, a0

	bnez	a0, loop_lines_next

	clr	s5		# index excluded from copy
loop_dampen:
	mv	a0, s0
	mv	a1, s1
	mv	a2, s4
	mv	a3, s5
	call	copy_except

	mv	a0, s1
	addi	a1, s4, -1
	call	is_safe
	bnez	a0, loop_dampen_ok
	inc	s5
	beq	s5, s4, loop_lines_next		# no solution found
	j	loop_dampen
loop_dampen_ok:
	inc	s3
	
loop_lines_next:
	blt	s10, s11, loop_lines
	
	la	a0, ansfmt
	li	a1, 1
	mv	a2, s2
	call	printf

	la	a0, ansfmt
	li	a1, 2
	mv	a2, s3
	call	printf

     	exit
	func_end _start


	# a0: array pointer
	# a1: elements count
	func_begin is_safe
is_safe:
	dec	a1			# comparisons countdown
	li	t3, 3			# maximum difference
	li	t0, 1			# increasing flag
	li	t1, 1			# decreasing flag
	clr	t2
loop_compare:
	lw	t5, 0(a0)
	lw	t6, 4(a0)
	sub	t4, t6, t5
	bgtz	t4, increasing
	clr	t0
increasing:
	bltz	t4, decreasing
	clr	t1
decreasing:
	beqz	t4, compare_end
	bgez	t4, not_neg
	neg	t4, t4
not_neg:
	bgt	t4, t3, compare_end	# non-salvageable error
	dec	a1
	inc	a0, 4
	bgtz	a1, loop_compare
	or	t2, t0, t1
compare_end:
	mv	a0, t2
	ret
	func_end is_safe



	# a0: source
	# a1: destination
	# a2: elements count
	# a3: excluded index
	func_begin copy_except
copy_except:
	clr	t3		# index
loop_copy_except:
	beq	t3, a3, loop_copy_except_skip
	lw	t0, (a0)
	sw	t0, (a1)
	inc	a1, 4
loop_copy_except_skip:
	inc	a0, 4
	dec	a2
	inc	t3
	bnez	a2, loop_copy_except
	ret
	func_end copy_except



	# a0: input pointer
	# a1: destination array pointer
	func_begin parse_input_line
parse_input_line:
	dec	sp, 32
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s1, 16(sp)
	
	mv	s0, a1
	clr	s1
loop_parse_input_line:
	inc	s1
	call	parse_integer
	sw	a1, (s0)
	lb	t0, (a0)
	li	t1, '\n'
	inc	a0
	beq	t0, t1, loop_parse_input_line_end
	inc	s0, 4
	j	loop_parse_input_line
loop_parse_input_line_end:
	
	mv	a1, s1
	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	inc	sp, 32
	ret
	func_end parse_input_line
