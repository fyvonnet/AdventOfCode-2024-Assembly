	.include "macros.inc"

	.globl	_start


	.set	WALL,	'#'
	.set	BOX,	'O'
	.set	EMPTY,	'.'
	.set	ROBOT,	'@'


	.section .rodata

filename:
	.string	"inputs/day15"
ansfmt:	.string	"Part %d answer: %d\n"

directions:
	.byte	'^',  0, -1
	.byte	'>',  1,  0
	.byte	'v',  0,  1
	.byte	'<', -1,  0


	.text
	.balign 8



	func_begin _start
_start:
	la	a0, filename
	call	map_input_file
	mv	s10, a0
	add	s11, a0, a1

	sub	sp, sp, a1
	addi	sp, sp, -4
	li	t0, 0b1111
	not	t0, t0
	and	sp, sp, t0
	addi	s0, sp, 4

	mv	a0, s10
	call	line_length
	sw	a0, -4(s0)
	mul	t3, a0, a0

	mv	t0, s0
	li	t2, '\n'
loop_copy:
	lb	t1, (s10)
	beq	t1, t2, skip_nl
	sb	t1, (t0)
	inc	t0
	dec	t3
skip_nl:
	inc	s10
	bnez	t3, loop_copy
	sb	zero, (t0)
	inc 	s10, 2

	mv	t0, s0
	li	t1, ROBOT
loop_search_start:
	lb	t2, (t0)
	beq	t2, t1, loop_search_start_end
	inc	t0
	j	loop_search_start
loop_search_start_end:
	li	t1, EMPTY
	sb	t1, (t0)

	sub	t3, t0, s0
	lw	t4, -4(s0)
	rem	s1, t3, t4
	div	s2, t3, t4
	

	li	s5, '\n'
loop:
	lb	a3, (s10)
	beq	a3, s5, loop_skip_nl
	mv	a0, s0
	mv	a1, s1
	mv	a2, s2
	call	attempt_move
	mv	s1, a0
	mv	s2, a1
loop_skip_nl:
	inc	s10
	blt	s10, s11, loop
loop_end:


	mv	t0, s0
	li	t1, 100
	li	t2, BOX
	lw	t6, -4(s0)
	clr	a2
loop_find_boxes:
	lb	t3, (t0)
	beqz	t3, loop_find_boxes_end
	bne	t3, t2, box_not_found
	sub	t4, t0, s0
	div	t5, t4, t6
	mul	t5, t5, t1
	add	a2, a2, t5
	rem	t5, t4, t6
	add	a2, a2, t5
box_not_found:
	inc	t0
	j	loop_find_boxes
loop_find_boxes_end:

	la	a0, ansfmt
	li	a1, 1
	call	printf

	exit
	func_end _start


	# a0: map
	# a1: x
	# a2: y
	# a3: direction_symbol
	func_begin attempt_move
attempt_move:
	dec	sp, 64
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s1, 16(sp)
	sd	s2, 24(sp)
	sd	s3, 32(sp)
	sd	s4, 40(sp)
	sd	s5, 48(sp)

	mv	s0, a0
	mv	s1, a1
	mv	s2, a2
	mv	s3, a3

	mv	a0, a3
	mv	a1, s1
	mv	a2, s2
	call	get_next_coord
	mv	s4, a0
	mv	s5, a1

	mv	a0, s0
	mv	a1, s4
	mv	a2, s5
	call	get_char

	li	t0, EMPTY
	beq	a0, t0, move_success

	li	t0, WALL
	beq	a0, t0, move_fail

	mv	a0, s0
	mv	a1, s4
	mv	a2, s5
	mv	a3, s3
	call	attempt_move_box
	beqz	a0, move_fail

move_success:
	mv	a0, s4
	mv	a1, s5
	j	attempt_move_ret
	
move_fail:
	mv	a0, s1
	mv	a1, s2

attempt_move_ret:
	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	ld	s2, 24(sp)
	ld	s3, 32(sp)
	ld	s4, 40(sp)
	ld	s5, 48(sp)
	inc	sp, 64
	ret
	func_end attempt_move




	# a0: map
	# a1: x
	# a2: y
	# a3: direction_symbol
	func_begin attempt_move_box
attempt_move_box:
	dec	sp, 64
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s1, 16(sp)
	sd	s2, 24(sp)
	sd	s3, 32(sp)
	sd	s4, 40(sp)
	sd	s5, 48(sp)

	mv	s0, a0
	mv	s1, a1
	mv	s2, a2
	mv	s3, a3

	mv	a0, a3
	mv	a1, s1
	mv	a2, s2
	call	get_next_coord
	mv	s4, a0
	mv	s5, a1

	mv	a0, s0
	mv	a1, s4
	mv	a2, s5
	call	get_char

	li	t0, EMPTY
	beq	a0, t0, move_box_success

	li	t0, WALL
	beq	a0, t0, move_box_fail

	mv	a0, s0
	mv	a1, s4
	mv	a2, s5
	mv	a3, s3
	call	attempt_move_box
	beqz	a0, move_box_fail

move_box_success:
	mv	a0, s0
	mv	a1, s1
	mv	a2, s2
	la	a3, EMPTY
	call	set_char
	mv	a0, s0
	mv	a1, s4
	mv	a2, s5
	la	a3, BOX
	call	set_char
	la	a0, 1
	j	move_box_ret
move_box_fail:
	clr	a0
move_box_ret:
	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	ld	s2, 24(sp)
	ld	s3, 32(sp)
	ld	s4, 40(sp)
	ld	s5, 48(sp)
	inc	sp, 64
	ret




	# a0: map
	# a1: x
	# a2: y
	# a3: char
	func_begin set_char
set_char:
	dec	sp, 16
	sd	ra, (sp)
	sd	s3, 8(sp)
	mv	s3, a3
	call	get_addr
	sb	s3, (a0)
	ld	ra, (sp)
	ld	s3, 8(sp)
	inc	sp, 16
	ret
	func_end set_char


	# a0: map
	# a1: x
	# a2: y
	func_begin get_char
get_char:
	dec	sp, 16
	sd	ra, (sp)
	call	get_addr
	lb	a0, (a0)
	ld	ra, (sp)
	inc	sp, 16
	ret
	func_end get_char



	# a0: map
	# a1: x
	# a2: y
	func_begin get_addr
get_addr:
	lw	t0, -4(a0)
	mul	t0, t0, a2
	add	t0, t0, a1
	add	a0, a0, t0
	ret
	func_begin get_addr


	# a0: direction symbol
	# a1: x
	# a2: y
get_next_coord:
	dec	sp, 32
	sd	ra,  0(sp)
	sd	s1,  8(sp)
	sd	s2, 16(sp)

	mv	s1, a1
	mv	s2, a2
	call	get_move
	add	a0, s1, a0
	add	a1, s2, a1

	ld	ra,  0(sp)
	ld	s1,  8(sp)
	ld	s2, 16(sp)
	inc	sp, 32
	ret


	# a0: symbol
	func_begin get_move
get_move:
	la	t0, directions
get_move_loop:
	lb	t1, (t0)
	beq	t1, a0, get_move_loop_end
	inc	t0, 3
	j	get_move_loop
get_move_loop_end:
	lb	a0, 1(t0)
	lb	a1, 2(t0)
	ret
	func_end get_move


