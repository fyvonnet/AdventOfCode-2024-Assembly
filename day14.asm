	.include "macros.inc"

	.globl	_start


	#.set	GRID_WIDTH,	11
	#.set	GRID_HEIGHT,	 7
	.set	GRID_WIDTH,	101
	.set	GRID_HEIGHT,	103


	.section .rodata
filename:
	.string	"inputs/day14"
	.string	"inputs/day14-test"
ansfmt:	.string	"Part %d answer: %d\n"



	.text
	.balign 8



	func_begin _start
_start:
	la	a0, filename
	call	map_input_file
	mv	s10, a0
	add	s11, a0, a1

	# buffer
	dec	sp, 16

	# counters
	dec	sp, 16
	sw	x0,  0(sp)
	sw	x0,  4(sp)
	sw	x0,  8(sp)
	sw	x0, 12(sp)
	mv	s2, sp

	# list terminator
	dec	sp, 16
	li	t0, -1
	sd	t0, 0(sp)

	li	s3, GRID_WIDTH
	srli	s3, s3, 1
	li	s4, GRID_HEIGHT
	srli	s4, s4, 1
	
	clr	s1
loop_move_all_robots:
	inc	s1
	dec	sp, 16

	mv	a0, s10
	mv	a1, sp
	call	parse_input_line
	mv	s10, a0

	lw	a0,  0(sp)
	lw	a1,  4(sp)
	lw	a2,  8(sp)
	lw	a3, 12(sp)
	li	s9, 100
loop_move_robot:
	call	move_robot
	dec	s9
	bnez	s9, loop_move_robot
	sw	a0, 0(sp)
	sw	a1, 4(sp)

	beq	a0, s3, skip_count
	beq	a1, s4, skip_count

	sgt	t0, a0, s3
	sgt	t1, a1, s4
	slli	t0, t0, 1
	add	t0, t0, t1
	slli	t0, t0, 2
	add	t0, t0, s2
	lw	t1, (t0)
	inc	t1
	sw	t1, (t0)

skip_count:

	blt	s10, s11, loop_move_all_robots

	mv	s0, sp

	la	a0, ansfmt
	li	a1, 1

	li	a2, 1
	li	t0, 4
loop_multiply:
	lw	t1, (s2)
	mul	a2, a2, t1
	inc	s2, 4
	dec	t0
	bnez	t0, loop_multiply
	call	printf

	li	s2, 100

loop:
	mv	a0, s0
	mv	a1, s1
	li	a2, 16
	la	a3, compar_coords
	call	quicksort
	
	# check if all coordinates are different
	addi	t1, s1, -1
	mv	t2, s0
	addi	t3, s0, 16
loop_compar:
	ld	t4, (t2)
	ld	t5, (t3)
	beq	t4, t5, compar_fail
	mv	t2, t3
	inc	t3, 16
	dec	t1
	bnez	t1, loop_compar

	la	a0, ansfmt
	li	a1, 2
	mv	a2, s2
	call	printf

	exit


compar_fail:
	inc	s2
	mv	s3, s0
	mv	s4, s1

loop_move_all_robots2:
	lw	a0,  0(s3)
	lw	a1,  4(s3)
	lw	a2,  8(s3)
	lw	a3, 12(s3)
	call	move_robot
	sw	a0, 0(s3)
	sw	a1, 4(s3)
	inc	s3, 16
	dec	s4
	bnez	s4, loop_move_all_robots2
	j	loop

	exit
	func_end _start


	
	# a0: px
	# a1: py
	# a2: vx
	# a3: vy
	func_begin move_robot
move_robot:
	li	t0, GRID_WIDTH
	li	t1, GRID_HEIGHT

	add	a0, a0, a2
	add	a1, a1, a3

	bgez	a0, px_not_neg
	add	a0, t0, a0
px_not_neg:
	rem	a0, a0, t0

	bgez	a1, py_not_neg
	add 	a1, t1, a1
py_not_neg:

	rem	a0, a0, t0
	rem	a1, a1, t1

	ret
	func_end move_robot


	func_begin parse_input_line
parse_input_line:
	dec	sp, 16
	sd	ra,  0(sp)
	sd	s1,  8(sp)

	mv	s1, a1

	inc	a0, 2		# skip "p="
	call	parse_integer
	sw	a1, (s1)

	inc	a0		# skip ','
	call	parse_integer	
	sw	a1, 4(s1)

	inc	a0, 3		# skip " v="
	call	parse_integer	
	sw	a1, 8(s1)

	inc	a0		# skip ','
	call	parse_integer	
	sw	a1, 12(s1)

	inc	a0		# skip '\n'
	
	ld	ra,  0(sp)
	ld	s1,  8(sp)
	inc	sp, 16
	ret
	func_end parse_input_line


	func_begin compar_coords
compar_coords:
	ld	t0, (a0)
	ld	t1, (a1)
	sub	a0, t0, t1
	ret
	func_end compar_coords

