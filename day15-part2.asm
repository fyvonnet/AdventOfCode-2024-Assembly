	.include "macros.inc"
	.include "memory.inc"

	.globl	_start


	.set	WALL,		'#'
	.set	BOX,		'O'
	.set	EMPTY,		'.'
	.set	ROBOT,		'@'
	.set	BOX_LEFT,	'['
	.set	BOX_RIGHT,	']'
	.set	SYMB_LEFT,	'<'
	.set	SYMB_RIGHT, 	'>'
	.set	SYMB_UP,	'^'
	.set	SYMB_DOWN, 	'v'

	.set	QUEUE_SIZE,	  8
	.set	QUEUE_COUNT,	600
	.set	QUEUE_X,	  0
	.set	QUEUE_Y,	  4

	.set	CHUNKS_SIZE,	 40
	.set	CHUNKS_COUNT,	600


	.section .rodata

filename:
	.string	"inputs/day15"
	.string	"inputs/day15-mytest"
	.string	"inputs/day15-test3"
ansfmt:	.string	"Part %d answer: %d\n"

directions:
	.byte	'^',  0, -1
	.byte	'>',  1,  0
	.byte	'v',  0,  1
	.byte	'<', -1,  0

subst:	.byte	WALL
	.ascii	"##"
	.byte	BOX
	.ascii	"[]"
	.byte	EMPTY
	.ascii	".."
	.byte	ROBOT
	.ascii	"@."


	.bss
	.balign	8
queue:	.space	8 + (QUEUE_SIZE * QUEUE_COUNT)
pool:	.space	8 + (CHUNKS_SIZE * CHUNKS_COUNT)


	.text
	.balign 8

	create_alloc_func alloc, pool, pool
	create_free_func free, pool, pool


	func_begin _start
_start:
	la	a0, filename
	call	map_input_file
	mv	s10, a0
	add	s11, a0, a1

	slli	a1, a1, 1
	sub	sp, sp, a1
	addi	sp, sp, -4
	li	t0, 0b1111
	not	t0, t0
	and	sp, sp, t0
	addi	s0, sp, 4

	mv	a0, s10
	call	line_length
	mul	t3, a0, a0
	slli	a0, a0, 1
	sw	a0, -4(s0)

	mv	t0, s0
	li	t2, '\n'
loop_copy:
	lb	t1, (s10)
	la	t4, subst
	beq	t1, t2, skip_nl
loop_subst:
	lb	t5, (t4)
	beq	t1, t5, loop_subst_end
	inc	t4, 3
	j	loop_subst
loop_subst_end:
	lb	t5, 1(t4)
	lb	t6, 2(t4)
	sb	t5, 0(t0)
	sb	t6, 1(t0)
	inc	t0, 2
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

	mv	a0, s0
	mv	a1, s1
	mv	a2, s2
loop_skip_nl:
	inc	s10
	blt	s10, s11, loop
loop_end:

	mv	t0, s0
	li	t1, 100
	li	t2, BOX_LEFT
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
	dec	sp, 16
	sd	ra, (sp)

	li	t0, SYMB_LEFT
	beq	t0, a3, jump_left

	li	t0, SYMB_RIGHT
	beq	t0, a3, jump_right

	li	t0, SYMB_UP
	beq	t0, a3, jump_up

	li	t0, SYMB_DOWN
	beq	t0, a3, jump_down

jump_left:
	call	attempt_move_box_horiz
	j	attempt_move_box_ret

jump_right:
	call	attempt_move_box_horiz
	j	attempt_move_box_ret

jump_up:
	call	attempt_move_box_vert
	j	attempt_move_box_ret

jump_down:
	call	attempt_move_box_vert

attempt_move_box_ret:
	ld	ra, (sp)
	inc	sp, 16
	ret





	# a0: map
	# a1: x
	# a2: y
	# a3: direction_symbol
	func_begin attempt_move_box_vert
attempt_move_box_vert:
	dec	sp, 96
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s1, 16(sp)
	sd	s2, 24(sp)
	sd	s3, 32(sp)
	sd	s4, 40(sp)
	sd	s5, 48(sp)
	sd	s6, 56(sp)
	sd	s7, 64(sp)
	sd	s8, 72(sp)
	sd	s9, 80(sp)

	mv	s0, a0
	mv	s1, a1
	mv	s2, a2
	mv	s3, a3

	li	s6, 1
	li	t0, SYMB_UP
	bne	s3, t0, not_up
	li	s6, -1
not_up:

	mv	a0, s0
	mv	a1, s1
	mv	a2, s2
	call	box_left_coord
	mv	s1, a0
	mv	s2, a1

	la	a0, pool
	li	a1, CHUNKS_COUNT
	li	a2, CHUNKS_SIZE
	call	pool_init

	la	a0, compar_up
	li	t0, SYMB_UP
	beq	s3, t0, use_compar_up
	la	a0, compar_down
use_compar_up:
	la	a1, alloc
	la	a2, free
	call	redblacktree_init
	mv	s7, a0

	la	a0, queue
	li	a1, QUEUE_COUNT
	li	a2, QUEUE_SIZE
	call	queue_init

	mv	a0, s1
	mv	a1, s2
	call	coords_pack
	mv	s8, a0
	
	la	a0, queue
	call	queue_push
	sd	s8, (a0)

	mv	a0, s7
	mv	a1, s8
	call	redblacktree_insert

loop_crates_vert:
	la 	a0, queue
	call	queue_pop
	beqz	a0, loop_crates_vert_end
	ld	a0, (a0)
	call	coords_unpack
	mv	s1, a0
	add	s2, a1, s6

	li	s9, 2
loop_push:
	mv	a0, s0
	mv	a1, s1
	mv	a2, s2
	call	get_char

	li	t0, WALL
	clr	t6
	beq	a0, t0, move_box_vert_ret	# wall hit, no crate will move, exit the function
	li	t0, EMPTY
	beq	a0, t0, loop_push_next		# ignore empty space

	mv	a0, s0
	mv	a1, s1
	mv	a2, s2
	call	box_left_coord
	call	coords_pack
	mv	s8, a0

	mv	a0, s7
	mv	a1, s8
	call	redblacktree_insert
	bnez	a0, loop_push_next

	la	a0, queue
	call	queue_push
	sd	s8, (a0)
loop_push_next:
	inc	s1
	dec	s9
	bnez	s9, loop_push
	j	loop_crates_vert
loop_crates_vert_end:

	nop
loop_move_crates_on_map:
	mv	a0, s7
	call	redblacktree_pop_leftmost
	beqz	a0, loop_move_crates_on_map_end
	call	coords_unpack
	mv	s1, a0
	mv	s2, a1

	mv	a0, s0
	mv	a1, s1
	mv	a2, s2
	li	a3, EMPTY
	call	set_char

	mv	a0, s0
	addi	a1, s1, 1
	mv	a2, s2
	li	a3, EMPTY
	call	set_char

	mv	a0, s0
	mv	a1, s1
	add	a2, s2, s6
	li	a3, BOX_LEFT
	call	set_char

	mv	a0, s0
	addi	a1, s1, 1
	add	a2, s2, s6
	li	a3, BOX_RIGHT
	call	set_char
	j	loop_move_crates_on_map
loop_move_crates_on_map_end:
	set	t6
	

move_box_vert_ret:
	mv	a0, t6
	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	ld	s2, 24(sp)
	ld	s3, 32(sp)
	ld	s4, 40(sp)
	ld	s5, 48(sp)
	ld	s6, 56(sp)
	ld	s7, 64(sp)
	ld	s8, 72(sp)
	ld	s9, 80(sp)
	inc	sp, 96
	ret





	# a0: map
	# a1: x
	# a2: y
	# a3: direction_symbol
	func_begin attempt_move_box_horiz
attempt_move_box_horiz:
	dec	sp, 64
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s1, 16(sp)
	sd	s2, 24(sp)
	sd	s3, 32(sp)
	sd	s4, 40(sp)
	sd	s5, 48(sp)
	sd	s6, 56(sp)

	mv	s0, a0
	mv	s1, a1
	mv	s2, a2
	mv	s3, a3

	li	s6, 1
	li	t0, SYMB_LEFT
	bne	s3, t0, not_left
	li	s6, -1
not_left:

	mv	a0, s0
	mv	a1, s1
	mv	a2, s2
	call	get_char
	add	s4, s1, s6
	mv	s5, s2

	mv	a0, s0
	add	a1, s4, s6
	mv	a2, s5
	call	get_char

	li	t0, EMPTY
	beq	a0, t0, move_box_horiz_success

	li	t0, WALL
	beq	a0, t0, move_box_horiz_fail

	mv	a0, s0
	#addi	a1, s4, -1
	add	a1, s4, s6
	mv	a2, s5
	#mv	a1, s1
	#mv	a2, s2
	mv	a3, s3
	call	attempt_move_box_horiz
	beqz	a0, move_box_horiz_fail

move_box_horiz_success:
	mv	a0, s0
	mv	a1, s1
	mv	a2, s2
	la	a3, EMPTY
	call	set_char
	mv	a0, s0
	mv	a1, s4
	li	t0, SYMB_RIGHT
	bne	s3, t0, notright1
	inc	a1 # when right
notright1:
	mv	a2, s5
	la	a3, BOX_RIGHT
	call	set_char
	mv	a0, s0
	mv	a1, s4
	li	t0, SYMB_LEFT
	bne	s3, t0, notleft1
	dec	a1 # when left
notleft1:
	mv	a2, s5
	la	a3, BOX_LEFT
	call	set_char
	la	a0, 1
	j	move_box_horiz_ret
move_box_horiz_fail:
	clr	a0
move_box_horiz_ret:
	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	ld	s2, 24(sp)
	ld	s3, 32(sp)
	ld	s4, 40(sp)
	ld	s5, 48(sp)
	ld	s6, 56(sp)
	inc	sp, 64
	ret
	func_end attempt_move_box_horiz




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

	# a0: map
	# a1: x
	# a2: y
	func_begin box_left_coord	
box_left_coord:
	dec	sp, 64
	sd	ra,  0(sp)
	sd	s1,  8(sp)
	sd	s2, 16(sp)

	call	get_char
	li	t0, BOX_LEFT
	beq	a0, t0, coord_is_ok
	dec	s1
coord_is_ok:
	mv	a0, s1
	mv	a1, s2

	ld	ra,  0(sp)
	ld	s1,  8(sp)
	ld	s2, 16(sp)
	inc	sp, 64
	ret


	func_begin compar_up
compar_up:
	li	t6, 0xFFFFFFFF
	and	t0, a0, t6
	and	t1, a1, t6
	sub	t5, t0, t1
	bnez	t5, compar_up_ret
	srli	t0, a0, 32
	srli	t1, a1, 32
	sub	t5, t0, t1
compar_up_ret:
	mv	a0, t5
	ret
	func_end compar_up
	


	func_begin compar_down
compar_down:
	li	t6, 0xFFFFFFFF
	and	t0, a0, t6
	and	t1, a1, t6
	sub	t5, t1, t0
	bnez	t5, compar_down_ret
	srli	t0, a0, 32
	srli	t1, a1, 32
	sub	t5, t0, t1
compar_down_ret:
	mv	a0, t5
	ret
	func_end compar_down



	# a0: x
	# a1: y
	func_begin coords_pack
coords_pack:
	slli	a0, a0, 32
	or	a0, a0, a1
	ret
	func_end coords_pack
	

	# a0: packed coords
	func_begin coords_unpack
coords_unpack:
	li	t0, 0x00000000FFFFFFFF
	and	a1, a0, t0
	srli	a0, a0, 32
	ret
	func_end coords_unpack


	# a0: map
	func_begin print_map
print_map:
	dec	sp, 128
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s1, 16(sp)
	sd	s2, 24(sp)
	sd	s3, 32(sp)
	sd	s4, 40(sp)
	sd	s5, 48(sp)
	sd	s6, 56(sp)
	sd	s7, 64(sp)


	mv	s0, a0
	mv	s4, a1
	mv	s5, a2

	lw	s1, -4(s0)
	srli	s1, s1, 1
	mv	s3, s0

	clr	s7
loop_vert:
	lw	s2, -4(s0)
	clr	s6
loop_horiz:
	bne	s6, s4, not_robot
	bne	s7, s5, not_robot
	li	a0, '@'
	call	putc
	j	loop_horiz_next
not_robot:
	lb	a0, (s3)
	call	putc
loop_horiz_next:
	inc	s3
	dec	s2
	inc	s6
	bnez	s2, loop_horiz
	li	a0, '\n'
	call	putc
	dec	s1
	inc	s7
	bnez	s1, loop_vert

	li	a0, '\n'
	call	putc

	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	ld	s2, 24(sp)
	ld	s3, 32(sp)
	ld	s4, 40(sp)
	ld	s5, 48(sp)
	ld	s6, 56(sp)
	ld	s7, 64(sp)
	inc	sp, 128
	ret
	func_end print_map


