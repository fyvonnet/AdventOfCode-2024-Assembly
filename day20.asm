	.include "macros.inc"

	.globl	_start

	.set	WALL,		'#'
	.set	EMPTY,		'.'
	.set	VISITED,	'O'
	.set	START,		'S'
	.set	END,		'E'

	.set	SQUARE_TIME,	0
	.set	SQUARE_SYM,	8

	.set	MOVES_X,	0
	.set	MOVES_Y,	1
	.set	MOVES_END,	2


	.section .rodata
filename:
	.string	"inputs/day20"
	.string	"inputs/day20-test"
ansfmt:	.string	"Part %d answer: %d\n"

moves:
	.byte	 1,  0,  0
	.byte	-1,  0,  0
	.byte	 0,  1,  0
	.byte	 0, -1, -1




	.text
	.balign 8



	func_begin _start
_start:
	la	a0, filename
	call	map_input_file
	mv	s10, a0
	add	s11, a0, a1

	slli	t0, a1, 4
	sub	sp, sp, t0
	addi	s0, sp, 16

	mv	s1, sp
	mv	s9, sp
	li	t0, 128*1024
	sub	sp, sp, t0

	mv	a0, s10
	call	line_length
	sw	a0, -4(s0)

	mv	t0, s0
	li	t1, '\n'
loop_read_map:
	lb	t2, (s10)
	inc	s10
	beq	t2, t1, skip_nl
	sd	x0, SQUARE_TIME(t0)
	sb	t2, SQUARE_SYM(t0)
	inc	t0, 16
skip_nl:
	bne	s10, s11, loop_read_map

	mv	a0, s0
	li	a1, START
	call	search_sym
	mv	s2, a0
	mv	s3, a1

	mv	a0, s0
	mv	a1, s2
	mv	a2, s3
	clr	a3
	call	set_visited

	mv	a0, s0
	li	a1, END
	call	search_sym
	mv	s4, a0
	mv	s5, a1

	dec	sp, 16
	clr	s10

loop_travel_circuit:
	mv	a0, s0
	mv	a1, s2
	mv	a2, s3
	mv	a3, s10
	call	set_visited

	inc	s10

	la	s6, moves
loop_moves:
	lb	t0, MOVES_X(s6)
	lb	t1, MOVES_Y(s6)
	add	s7, s2, t0
	add	s8, s3, t1

	mv	a0, s0
	mv	a1, s7
	mv	a2, s8
	call	get_sym
	li	t0, EMPTY
	bne	a0, t0, not_empty
	sw	s7, 0(sp)
	sw	s8, 4(sp)
not_empty:

	li	t0, WALL
	bne	a0, t0, not_wall
	sw	s7,  8(sp)
	sw	s8, 12(sp)

	lb	t0, MOVES_X(s6)
	lb	t1, MOVES_Y(s6)
	add	s7, s7, t0
	add	s8, s8, t1
	mv	a0, s0
	mv	a1, s7
	mv	a2, s8
	call	get_sym
	li	t0, EMPTY
	bne	a0, t0, not_cheat

	dec	s9, 16
	sw	s2,  0(s9)
	sw	s3,  4(s9)
	sw	s7,  8(s9)
	sw	s8, 12(s9)
not_cheat:
	lw	s7,  8(sp)
	lw	s8, 12(sp)
not_wall:

	lb	t0, MOVES_END(s6)
	addi	s6, s6, 3
	beqz	t0, loop_moves

	lw	s2, 0(sp)
	lw	s3, 4(sp)

	bne	s2, s4, loop_travel_circuit
	bne	s3, s5, loop_travel_circuit

	mv	a0, s0
	mv	a1, s2
	mv	a2, s3
	mv	a3, s10
	call	set_visited

	li	s5, 100
	clr	s6

loop_cheats:
	beq	s9, s1, loop_cheats_end
	mv	a0, s0
	lw	a1,  0(s9)
	lw	a2,  4(s9)
	call	get_time
	mv	s4, a0
	inc	s9, 8

	mv	a0, s0
	lw	a1,  0(s9)
	lw	a2,  4(s9)
	call	get_time
	sub	s4, a0, s4
	inc	s9, 8

	dec	s4, 2

	blt	s4, s5, loop_cheats
	inc	s6
	j	loop_cheats
loop_cheats_end:
	
	la	a0, ansfmt
	li	a1, 1
	mv	a2, s6
	call	printf

	exit
	func_end _start




	# a0: map
	# a1: x
	# a2: y
	# a3: time
	func_begin set_visited
set_visited:
	dec	sp, 16
	sd	ra,  0(sp)
	sd	s0,  8(sp)

	mv	s0, a3
	call	get_addr
	li	t0, VISITED
	sb	t0, SQUARE_SYM(a0)
	sd	s0, SQUARE_TIME(a0)

	ld	ra,  0(sp)
	ld	s0,  8(sp)
	inc	sp, 16
	ret
	func_end set_visited
	
	

	# a0: map
	# a1: x
	# a2: y
	func_begin get_time
get_time:
	dec	sp, 16
	sd	ra,  0(sp)
	call	get_addr
	ld	a0, SQUARE_TIME(a0)
	ld	ra,  0(sp)
	inc	sp, 16
	ret
	func_end get_time
	
	

	# a0: map
	# a1: x
	# a2: y
	func_begin get_sym
get_sym:
	dec	sp, 16
	sd	ra,  0(sp)

	call	get_addr
	li	t6, WALL
	beqz	a0, get_sym_ret
	lb	t6, SQUARE_SYM(a0)

get_sym_ret:	
	mv	a0, t6
	ld	ra,  0(sp)
	inc	sp, 16
	ret
	func_end get_sym


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

	mul	a2, a2, t0
	add	a2, a2, a1
	slli	a2, a2, 4
	add	t6, a0, a2
get_addr_ret:
	mv	a0, t6
	ret
	


	func_begin search_sym
search_sym:
	mv	t0, a0
loop_search_start:
	lb	t3, SQUARE_SYM(t0)
	beq	t3, a1, loop_search_start_end
	inc	t0, 16
	j	loop_search_start
loop_search_start_end:
	li	t1, EMPTY
	sb	t1, SQUARE_SYM(t0)
	sub	t0, t0, a0
	srli	t0, t0, 4
	lw	t1, -4(a0)
	rem	a0, t0, t1
	div	a1, t0, t1
	ret
	func_end search_sym


