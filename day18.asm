	.include "macros.inc"

	.globl	_start

	.set	MAP_SIDE,	71

	.set	BLOCKED,	 1
	.set	FREE,		 0
	.set	VISITED,	-1

	.set	QUEUE_X, 	 0
	.set	QUEUE_Y,	 4
	.set	QUEUE_STEPS, 	 8

	.set	MOVE_X,		 0
	.set	MOVE_Y,		 1
	.set	MOVE_CONTINUE,	 2

	.section .rodata
filename:
	.string	"inputs/day18"
ansfmt:	.string	"Part %d answer: %d\n"
pt2fmt:	.string "Part 2 answer: %d,%d\n"
moves:	
	.byte	 0, -1,  1,  0
	.byte	 0,  1,  1,  0
	.byte	 1,  0,  1,  0
	.byte	-1,  0,  0,  0


	.bss
	.balign 8
	.set	QUEUE_SIZE,	16
	.set	QUEUE_COUNT,	100
queue:	.space 8 + (QUEUE_SIZE * QUEUE_COUNT)


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

	li	t0, MAP_SIDE * MAP_SIDE
	sub	sp, sp, t0
	li	t0, 0b1111
	not 	t0, t0
	and	sp, sp, t0
	mv	s0, sp

	mv	t0, s0
	li	t1, MAP_SIDE * MAP_SIDE
loop_clear:
	sb	zero, (t0)
	inc	t0
	dec	t1
	bnez	t1, loop_clear


	dec	sp, 16
	li	s9, 1024
loop_read_bytes:
	mv	a0, s10
	mv	a1, sp
	call	parse_input
	mv	s10, a0

	mv	a0, s0
	lw	a1, 0(sp)
	lw	a2, 4(sp)
	call	get_addr
	li	t0, BLOCKED
	sb	t0, (a0)

	dec	s9
	bnez	s9, loop_read_bytes
	inc	sp, 16

	mv	a0, s0
	call	cross_map

	mv	a2, a0
	li	a1, 1
	la	a0, ansfmt
	call	printf

loop_part2:

	la	a0, queue
	li	a1, QUEUE_COUNT
	li	a2, QUEUE_SIZE
	call	queue_init
	
	mv	t0, s0
	li	t1, MAP_SIDE * MAP_SIDE
	li	t2, VISITED
	li	t3, FREE
loop_reset_map:
	lb	t4, (t0)
	bne	t4, t2, skip_reset
	sb	t3, (t0)
skip_reset:
	inc	t0
	dec	t1
	bnez	t1, loop_reset_map

	dec	sp, 16
	mv	a0, s10
	mv	a1, sp
	call	parse_input
	mv	s10, a0
	lw	s1, 0(sp)
	lw	s2, 4(sp)
	inc	sp, 16

	mv	a0, s0
	mv	a1, s1
	mv	a2, s2
	call	get_addr
	li	t0, BLOCKED
	sb	t0, (a0)

	mv	a0, s0
	call	cross_map
	bgez	a0, loop_part2

	la	a0, pt2fmt
	mv	a1, s1
	mv	a2, s2
	call	printf


	exit
	func_end _start



	# a0: map
	func_begin cross_map
cross_map:
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

	la	a0, queue
	call	queue_push
	sw	zero, QUEUE_X(a0)
	sw	zero, QUEUE_Y(a0)
	sw	zero, QUEUE_STEPS(a0)

	mv	a0, s0
	mv	a1, zero
	mv	a2, zero
	call	get_addr
	li	t0, VISITED
	sb	t0, (a0)

loop_cross_map:
	
	la	a0, queue
	call	queue_pop
	bnez	a0, pop_ok
	la	a0, -1
	j	cross_map_ret
pop_ok:

	lw	s1, QUEUE_X(a0)
	lw	s2, QUEUE_Y(a0)
	lw	s3, QUEUE_STEPS(a0)

	li	t0, 70
	bne	s1, t0, not_there_yet
	bne	s2, t0, not_there_yet

	mv	a0, s3
	j	cross_map_ret

not_there_yet:
	inc	s3
	la	s4, moves
loop_push:
	lb	t1, MOVE_X(s4)
	lb	t2, MOVE_Y(s4)
	add	s5, s1, t1
	add	s6, s2, t2

	mv	a0, s0
	mv	a1, s5
	mv	a2, s6
	call	square_get
	bnez	a0, loop_push_next

	mv	a0, s0
	mv	a1, s5
	mv	a2, s6
	call	get_addr
	li	t0, VISITED
	sb	t0, (a0)

	la	a0, queue
	call	queue_push
	sw	s5, QUEUE_X(a0)
	sw	s6, QUEUE_Y(a0)
	sw	s3, QUEUE_STEPS(a0)
loop_push_next:
	lb	t0, MOVE_CONTINUE(s4)
	inc	s4, 4
	bnez	t0, loop_push

	j	loop_cross_map
cross_map_ret:
	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	ld	s2, 24(sp)
	ld	s3, 32(sp)
	ld	s4, 40(sp)
	ld	s5, 48(sp)
	ld	s6, 56(sp)
	dec	sp, 64
	ret
	func_end cross_map
	



	# a0: input pointer
	# a1: destination pointer
	func_begin parse_input
parse_input:
	dec	sp, 16
	sd	ra,  0(sp)
	sd	s1,  8(sp)

	mv	s1, a1

	call	parse_integer
	sw	a1, 0(s1)
	inc	a0
	call	parse_integer
	sw	a1, 4(s1)
	inc	a0

	ld	ra,  0(sp)
	ld	s1,  8(sp)
	inc	sp, 16
	ret
	func_end parse_input


	func_begin square_get
square_get:
	dec	sp, 16
	sd	ra, (sp)
	call	get_addr
	li	t6, BLOCKED
	beqz	a0, square_get_ret
	lb	t6, (a0)
square_get_ret:
	mv	a0, t6
	ld	ra, (sp)
	inc	sp, 16
	ret
	func_end square_get


	# a0: map
	# a1: x
	# a2: y
	func_begin get_addr
get_addr:
	clr	t6
	bltz	a1, get_addr_ret
	bltz	a2, get_addr_ret
	li	t0, MAP_SIDE
	bge	a1, t0, get_addr_ret
	bge	a2, t0, get_addr_ret

	mul	t6, a2, t0
	add	t6, t6, a1
	add	t6, t6, a0

get_addr_ret:	
	mv	a0, t6
	ret
	func_end get_addr
	

