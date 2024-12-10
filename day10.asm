	.include "macros.inc"

	.globl	_start

	.set	SQUARE_HEIGHT, 0
	.set	SQUARE_VISITED, 1
	.set	QUEUE_COUNT, 32
	.set	QUEUE_SIZE, 8


	.bss
	.balign 8
queue:	.space 40 + (QUEUE_COUNT * QUEUE_SIZE)


	.section .rodata
filename:
	.string	"inputs/day10"
	.string	"inputs/day10-test2"
ansfmt:	.string	"Part %d: %d\n"
moves:	.byte	 0,  1
	.byte	 0, -1
	.byte	 1,  0
	.byte	-1,  0


	.text
	.balign 8



	func_begin _start
_start:
	la	a0, queue
	li	a1, QUEUE_COUNT
	li	a2, QUEUE_SIZE
	call	queue_init 

	la	a0, filename
	call	map_input_file
	mv	s10, a0
	add	s11, a0, a1

	slli	t0, a1, 1
	sub	sp, sp, t0
	li	t0, 0xF
	not	t0, t0
	and	sp, sp, t0
	add	s0, sp, 4

	mv	a0, s10
	call	line_length
	sw	a0, -4(s0)

	mv	s1, s0
	li	s2, '0'
	li	s3, '\n'

	dec	sp, 16
	li	t0, -1
	sw	t0, (sp)
	
	clr	s5
loop_copy_lines:
	clr	s4
loop_copy_chars:
	lb	t0, (s10)
	beq	t0, s3, loop_copy_chars_end
	sub	t0, t0, s2
	bnez	t0, skip_copy_coords
	dec	sp, 16
	sw	s4, 0(sp)
	sw	s5, 4(sp)
skip_copy_coords:
	sb	t0, SQUARE_HEIGHT(s1)
	sb	x0, SQUARE_VISITED(s1)
	inc	s1, 2
	inc	s10
	inc	s4
	j	loop_copy_chars
loop_copy_chars_end:
	inc	s5
	inc	s10
	bne	s10, s11, loop_copy_lines

	clr	s1
	clr	s2
loop_trailheads:
	mv	a0, s0
	lw	a1, 0(sp)
	bltz	a1, loop_trailheads_end
	lw	a2, 4(sp)
	li	a3, 1
	call	count_score
	add	s1, s1, a0

	mv	a0, s0
	call	reset_visited

	# spent hours trying to solve p2 using DFS :(
	# actual way: "One possible solution to find all paths 
	# [or all paths up to a certain length] from s to t is BFS,
	# without keeping a visited set"

	mv	a0, s0
	lw	a1, 0(sp)
	lw	a2, 4(sp)
	li	a3, 0		# don't mark visited
	call	count_score
	add	s2, s2, a0

	mv	a0, s0
	call	reset_visited
	inc	sp, 16
	j	loop_trailheads
loop_trailheads_end:


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


	# a0: map
	# a1: x
	# a2: y
	func_begin get_addr
get_addr:
	clr	t6
	bltz	a1, get_addr_ret
	bltz	a2, get_addr_ret
	lw	t0, -4(a0)
	bge	a1, t0, get_addr_ret
	bge	a2, t0, get_addr_ret

	mul	t6, a2, t0
	add	t6, t6, a1
	slli	t6, t6, 1
	add	t6, t6, a0
get_addr_ret:
	mv	a0, t6
	ret
	func_end get_addr


	# a0: map
	# a1: start coord x
	# a2: start coord y
	# a3: mark visited?
	func_begin count_score
count_score:
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
	clr	s3		# initialize counter
	mv	s9, a3

	call	get_addr
	sb	s9, SQUARE_VISITED(a0)

	la	a0, queue
	call	queue_push
	sw	s1, 0(a0)
	sw	s2, 4(a0)
loop_count_score:
	la	a0, queue
	call	queue_pop
	beqz	a0, loop_count_score_end
	lw	s1, 0(a0)
	lw	s2, 4(a0)
	mv	a0, s0
	mv	a1, s1
	mv	a2, s2
	call	get_addr
	lb	s8, SQUARE_HEIGHT(a0)
	li	t1, 9
	beq	s8, t1, summit 
	li	s4, 4
	la	s5, moves
loop_next_squares:
	lb	t1, 0(s5)
	lb	t2, 1(s5)
	inc	s5, 2
	add	s6, s1, t1
	add	s7, s2, t2
	mv	a0, s0
	mv	a1, s6
	mv	a2, s7
	call	get_addr
	beqz	a0, loop_next_squares_next	# square out of bounds
	lb	t0, SQUARE_HEIGHT(a0)
	dec	t0
	bne	t0, s8, loop_next_squares_next	# wrong height
	lb	t0, SQUARE_VISITED(a0)
	bnez	t0, loop_next_squares_next	# already visited
	sb	s9, SQUARE_VISITED(a0)
	la	a0, queue
	call	queue_push
	sw	s6, 0(a0)
	sw	s7, 4(a0)
loop_next_squares_next:
	dec	s4
	bnez	s4, loop_next_squares
	j	loop_count_score
summit:
	inc	s3
	j	loop_count_score
loop_count_score_end:
	mv	a0, s3
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
	func_end count_score


	# a0: map
	func_begin reset_visited
reset_visited:
	lw	t0, -4(a0)
	mul	t0, t0, t0
loop_reset_visited:
	sb	x0, SQUARE_VISITED(a0)
	inc	a0, 2
	dec	t0
	bnez	t0, loop_reset_visited
	ret
	func_end reset_visited


