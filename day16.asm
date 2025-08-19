	.include "macros.inc"
	.include "memory.inc"

	.globl	_start

	.set	SQUARE_SCORE,	 0
	.set	SQUARE_CHAR,	 4

	.set	MOVE_X,		 0
	.set	MOVE_Y,		 1

	.set	GLOBAL_MAP, 	 0
	.set	GLOBAL_VISITED,	 8

	.set	QUEUE_SCORE,	 0
	.set	QUEUE_COORDS,	 8
	.set	QUEUE_COORD_X,	 8
	.set	QUEUE_COORD_Y,	12
	.set	QUEUE_DIR,	16
	.set	QUEUE_SIZE, 	24

	.set	VISITED_SCORE,	 0
	.set	VISITED_COORDS,	 8
	.set	VISITED_COORD_X, 8
	.set	VISITED_COORD_Y,12
	.set	VISITED_DIR,	16
	.set	VISITED_SIZE,	24

	.set	NORTH,		 0
	.set	EAST,		 1
	.set	SOUTH,		 2
	.set	WEST,		 3

	.set	EMPTY,		'.'
	.set	WALL,		'#'
	.set	EXIT,		'E'

	.section .rodata

moves:
	.byte	 0, -1	# north
	.byte	 1,  0	# east
	.byte	 0,  1	# south
	.byte	-1,  0	# west

	.balign 8
new_dirs:
	.dword	fronts, 1, 1
	.dword	lefts, 1001, 1
	.dword	rights, 1001, 0

lefts:	.byte	WEST, NORTH, EAST, SOUTH
fronts:	.byte	NORTH, EAST, SOUTH, WEST
rights:	.byte	EAST, SOUTH, WEST, NORTH

filename:
	.string	"inputs/day16"
ansfmt:	.string	"Part %d answer: %d\n"



	.bss
	.balign	8
	.set	CHUNKS_SIZE, 40
	.set	CHUNKS_COUNT, 4*512*1024
pool:	.space	8 + (CHUNKS_SIZE * CHUNKS_COUNT)
global_values:	
	.space	64



	.text
	.balign 8


	func_begin _start
_start:
	lga	a0, pool
	li	a1, CHUNKS_COUNT
	li	a2, CHUNKS_SIZE
	call	pool_init

	lga	a0, queue_compar
	lga	a1, pool
	call	redblacktree_init
	mv	s1, a0
	
	lga	a0, visited_compar
	lga	a1, pool
	call	redblacktree_init
	mv	s2, a0
	
	la	a0, filename
	call	map_input_file
	mv	s10, a0
	add	s11, a0, a1

	slli	a1, a1, 3
	sub	sp, sp, a1
	dec	sp, 4
	li	t0, 0b1111
	not	t0, t0
	and	sp, sp, t0
	add	s0, sp, 4

	mv	a0, s10
	call	line_length
	sd	a0, -4(s0)

	mv	t0, s0
	li	t1, '\n'
loop_read_input:
	lb	t2, (s10)
	beq	t2, t1, skip_nl
	sb	t2, SQUARE_CHAR(t0)
	li	t6, -1
	sw	t6, SQUARE_SCORE(t0)
	
	inc	t0, 8
skip_nl:
	inc	s10
	blt	s10, s11, loop_read_input
	sb	zero, SQUARE_CHAR(t0)

	mv	t0, s0
	li	t2, 'S'
loop_search_start:
	lb	t1, SQUARE_CHAR(t0)
	beq	t1, t2, loop_search_start_end
	inc	t0, 8
	j	loop_search_start
loop_search_start_end:
	li	t6, EMPTY
	sb	t6, (t0)
	sub	t0, t0, s0
	srli	t0, t0, 3
	lw	t1, -4(s0)

	lga	s11, global_values
	sd	s0, GLOBAL_MAP(s11)
	sd	s2, GLOBAL_VISITED(s11)
	#mv	s11, s0

	rem	a0, t0, t1
	div	a1, t0, t1
	li	a2, EAST
	clr	a3
	li	a4, 1000
	#clr	a4
	call	run_maze
	mv	s3, a0

	mv	a2, s3
	la	a0, ansfmt
	li	a1, 1
	call	printf

	clr	s4
loop_count:
	lb	t0, SQUARE_CHAR(s0)
	beqz	t0, loop_count_end
	lw	t0, SQUARE_SCORE(s0)
stop_here:
	bne	t0, s3, skip_count
	inc	s4
skip_count:
	inc	s0, 8
	j	loop_count
loop_count_end:
	inc	s4
	
	mv	a2, s4
	la	a0, ansfmt
	li	a1, 2
	call	printf

	exit
	

	# a0: x
	# a1: y
	# a2: direction
	# a3: score
	func_begin run_maze
run_maze:
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
	sd	s10, 88(sp)

	dec	sp, 16
	beqz	a4, run_maze_fail
	
	mv	s0, a0
	mv	s1, a1
	mv	s2, a2
	mv	s3, a3

	dec	a4
	sd	a4, (sp)

	ld	a0, GLOBAL_MAP(s11)
	mv	a1, s0
	mv	a2, s1
	call	get_char
	li	t0, EXIT
	beq	a0, t0, exit_found

	lga	s4, new_dirs
	li	s9, -1
	clr	s10
loop_new_dirs:
	# new score
	ld	t0, 8(s4)
	add	s8, s3, t0

	# new direction
	ld	t0, 0(s4)
	add	t0, t0, s2
	lb	s7, (t0)

	# new coordinates
	slli	t0, s7, 1
	lga	t1, moves
	add	t0, t0, t1
	lb	t1, MOVE_X(t0)
	lb	t2, MOVE_Y(t0)
	add	s5, s0, t1
	add	s6, s1, t2
	
	ld	a0, GLOBAL_MAP(s11)
	mv	a1, s5
	mv	a2, s6
	call	get_char
	#li	t0, EXIT
	#beq	t0, a0, exit_found
	li	t0, WALL
	beq	t0, a0, loop_new_dirs_next

	ld	a0, GLOBAL_VISITED(s11)
	mv	a1, s5
	mv	a2, s6
	mv	a3, s7
	mv	a4, s8
	call	is_visited
	bnez	a0, loop_new_dirs_next

	inc	s10

	mv	a0, s5
	mv	a1, s6
	mv	a2, s7
	mv	a3, s8
	ld	a4, (sp)
	call	run_maze
	mv	a1, s9
	call	minu
	mv	s9, a0

loop_new_dirs_next:
	ld	t0, 16(s4)
	inc	s4, 24
	bnez    t0, loop_new_dirs

	beqz	s10, run_maze_fail

	ld	a0, GLOBAL_MAP(s11)
	mv	a1, s0
	mv	a2, s1
	call	get_addr
	mv	s3, a0

	lw	a0, SQUARE_SCORE(s3)
	mv	a1, s9
	call	minu
	sw	a0, SQUARE_SCORE(s3)
	
	
	mv	a0, s9
	j	run_maze_ret

run_maze_fail:
	li	a0, -1
	j	run_maze_ret
exit_found:
	mv	a0, s3
run_maze_ret:
	inc	sp, 16
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
	ld	s10, 88(sp)
	inc	sp, 96
	ret
	func_end run_maze


	# a0: set
	# a1: x
	# a2: y	
	# a3: direction
	# a4: score
	func_begin is_visited
is_visited:
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
	mv	s4, a4

	la	a0, pool
	call	pool_alloc
	mv	s5, a0

	sw	s1, VISITED_COORD_X(s5)
	sw	s2, VISITED_COORD_Y(s5)
	sb	s3, VISITED_DIR(s5)
	sd	s4, VISITED_SCORE(s5)

	mv	a0, s0
	mv	a1, s5
	call	redblacktree_insert

	clr	t6
	beqz	a0, is_visited_ret

	mv	s0, a0
	la	a0, pool
	mv	a1, s5
	call	pool_free

	li	t6, 1
	ld	t0, VISITED_SCORE(s0)
	blt	t0, s4, is_visited_ret
	sd	s4, VISITED_SCORE(s0)
	clr	t6

is_visited_ret:
	mv	a0, t6
	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	ld	s2, 24(sp)
	ld	s3, 32(sp)
	ld	s4, 40(sp)
	ld	s5, 48(sp)
	inc	sp, 64
	ret
	func_end is_visited



	# a0: map
	# a1: x
	# a2: y
	func_begin is_wall
is_wall:
	dec	sp, 16
	sd	ra, (sp)
	call	get_char
	li	t0, '#'
	li	t1, 1
	beq	t0, a0, is_wall_ret
	clr	t1
is_wall_ret:
	mv	a0, t1
	ld	ra, (sp)
	inc	sp, 16
	ret
	func_end is_wall

	



	# a0: map
	# a1: x
	# a2: y
	func_begin get_char
get_char:
	dec	sp, 16
	sd	ra, (sp)
	call	get_addr
	lb	a0, SQUARE_CHAR(a0)
	ld	ra, (sp)
	inc	sp, 16
	ret
	func_end get_char


	#a0: queue
	# a0: map
	# a1: x
	# a2: y
	func_begin get_addr
get_addr:
	lw	t0, -4(a0)
	mul	t0, t0, a2
	add	t0, t0, a1
	slli	t0, t0, 3
	add	a0, t0, a0
	ret
	func_end get_addr


	#a0: queue
	func_begin queue_pop
queue_pop:
	dec	sp, 16
	sd	ra, (sp)
	call	redblacktree_pop_leftmost
	ld	ra, (sp)
	inc	sp, 16
	ret
	func_end queue_pop



	# a0: queue
	# a1: x
	# a2: y	
	# a3: direction
	# a4: score
	func_begin queue_push
queue_push:
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

	la	a0, pool
	call	pool_alloc

	sw	s1, QUEUE_COORD_X(a0)
	sw	s2, QUEUE_COORD_Y(a0)
	sb	s3, QUEUE_DIR(a0)
	sd	s4, QUEUE_SCORE(a0)

	mv	a1, a0
	mv	a0, s0
	call	redblacktree_insert

	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	ld	s2, 24(sp)
	ld	s3, 32(sp)
	ld	s4, 40(sp)
	inc	sp, 48
	ret
	func_end queue_push


	func_begin visited_compar
visited_compar:
	ld	t0, VISITED_COORDS(a0)
	ld	t1, VISITED_COORDS(a1)
	sub	t0, t0, t1
	bnez	t0, visited_compar_ret
	lb	t0, VISITED_DIR(a0)
	lb	t1, VISITED_DIR(a1)
	sub	t0, t0, t1
visited_compar_ret:
	mv	a0, t0
	ret
	func_end visited_compar


	func_begin queue_compar
queue_compar:
	ld	t0, QUEUE_SCORE(a0)
	ld	t1, QUEUE_SCORE(a1)
	sub	t0, t0, t1
	bnez	t0, queue_compar_ret
	sub	t0, a0, a1
queue_compar_ret:
	mv	a0, t0
	ret
	func_end queue_compar



