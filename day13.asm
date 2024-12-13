	.include "macros.inc"
	.include "memory.inc"

	.globl	_start


	.set	GAME_CACHE,		  0
	.set	GAME_BTN_A_X,	 	  8
	.set	GAME_BTN_A_Y, 		 12
	.set	GAME_BTN_B_X, 		 16
	.set	GAME_BTN_B_Y, 		 20
	.set	GAME_MIN_COST,		 24

	.set	COST_A,			  3
	.set	COST_B,			  1
	.set	MAX_PRESS,		100


	.section .rodata
filename:
	.string	"inputs/day13"
	#.string	"inputs/day13-test"
ansfmt:	.string	"Part %d answer: %d\n"
	#.space 	4


	.bss
	.balign 8
game_data:
	.space	64
	.set	ARENA_SIZE, 512*1024
arena:	.space 	ARENA_SIZE


	.text
	.balign 8

	create_alloc_func alloc, arena, arena


	func_begin _start
_start:
	la	s9, game_data

	la	a0, filename
	call	map_input_file
	mv	s10, a0
	add	s11, a0, a1

	clr	s0
	dec	sp, 16
loop:
	lga	a0, arena
	li	a1, ARENA_SIZE
	call	arena_init

	la	a0, compar_cache
	la	a1, alloc	
	clr	a2
	call	redblacktree_init
	sd	a0, GAME_CACHE(s9)

	mv	a0, s10
	mv	a1, sp
	call	parse_configuration
	mv	s10, a0

	li	t1, -1
	sw	t1, GAME_MIN_COST(s9)

	clr	a0
	clr	a3
	clr	a4
	call	run_machine
	lw	s1, GAME_MIN_COST(s9)

	bltz	s1, skip_add
	add	s0, s0, s1
skip_add:
	blt	s10, s11, loop

	la	a0, ansfmt
	li	a1, 1
	mv	a2, s0
	call	printf

	exit
	func_end _start


	# a0: total cost
	# a1: pos x
	# a2: pos y
	# a3: count a
	# a4: count b
	func_begin run_machine
run_machine:
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

	slli	a1, s3, 32
	or	a1, a1, s4
	ld	a0, GAME_CACHE(s9)
	call	redblacktree_insert
	beqz	a0, not_in_cache
	li	a0, -1
	j	run_machine_ret
not_in_cache:

	la	a0, -1

	# cost exceeded minimal cost
	lw	t0, GAME_MIN_COST(s9)
	bgtu	s0, t0, run_machine_ret

	# claw overshoot the prize
	bltz	s1, run_machine_ret
	bltz	s2, run_machine_ret

	# max presses reached
	li	t1, MAX_PRESS
	bgt	s3, t1, run_machine_ret
	bgt	s4, t1, run_machine_ret

	bnez	s1, prize_not_reached
	bnez	s2, prize_not_reached

reached:
	sw	s0, GAME_MIN_COST(s9)
	j	run_machine_ret

prize_not_reached:
	li	s5, 2

	lw	t1, GAME_BTN_A_X(s9)
	lw	t2, GAME_BTN_A_Y(s9)
	addi	a0, s0, COST_A
	sub	a1, s1, t1
	sub	a2, s2, t2
	addi	a3, s3, 1
	mv	a4, s4
	call	run_machine
	add	s5, s5, a0
	
	lw	t1, GAME_BTN_B_X(s9)
	lw	t2, GAME_BTN_B_Y(s9)
	addi	a0, s0, COST_B
	sub	a1, s1, t1
	sub	a2, s2, t2
	mv	a3, s3
	addi	a4, s4, 1
	call	run_machine
	add	s5, s5, a0

	la	a0, -1
	beqz	s5, run_machine_ret
	clr	a0

run_machine_ret:
	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	ld	s2, 24(sp)
	ld	s3, 32(sp)
	ld	s4, 40(sp)
	ld	s5, 48(sp)
	inc	sp, 64
	ret
	func_end run_machine


	func_begin parse_configuration
parse_configuration:
	dec	sp, 32
	sd	ra,  0(sp)
	sd	s1,  8(sp)
	sd	s2, 16(sp)

	mv	s1, a1
	la	s2, game_data

	mv	a0, s10
	addi	a1, s2, 8
	call	parse_button
	addi	a1, s2, 16
	call	parse_button

	inc	a0, 9
	call	parse_integer
	mv	s2, a1
	inc	a0, 4
	call	parse_integer
	sw	a1, 20(s1)

	mv	a2, a1
	mv	a1, s2
	inc	a0, 2

	ld	ra,  0(sp)
	ld	s1,  8(sp)
	ld	s2, 16(sp)
	inc	sp, 32
	ret
	func_end parse_configuration


	func_begin parse_button
parse_button:
	dec	sp, 16
	sd	ra,  0(sp)
	sd	s1,  8(sp)

	mv	s1, a1

	inc	a0, 12
	call	parse_integer
	sw	a1, 0(s1)

	inc	a0, 4
	call	parse_integer
	sw	a1, 4(s1)

	inc	a0

	ld	ra,  0(sp)
	ld	s1,  8(sp)
	inc	sp, 16
	ret
	func_end parse_button


	func_begin compar_cache
compar_cache:
	sub	a0, a0, a1
	ret
	func_end compar_cache



