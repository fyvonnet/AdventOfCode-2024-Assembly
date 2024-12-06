	.include "macros.inc"
	.include "memory.inc"

	.globl	_start


	.set	UP,	0
	.set	RIGHT,	1
	.set	DOWN,	2
	.set	LEFT,	3


	.section .rodata

filename:
	.string	"inputs/day06"
ansfmt:	.string	"Part %d: %d\n"
turns:	.byte	RIGHT, DOWN, LEFT, UP
moves:	.byte	 0, -1	# up
	.byte	 1,  0	# right
	.byte	 0,  1	# down
	.byte	-1,  0	# left



	.bss
	.balign 8


	.set	ARENA_SIZE,	256*1024
arena:	.space	ARENA_SIZE



	.text
	.balign 8

	create_alloc_func	alloc, arena, arena
	create_free_func	free, arena, arena

	
	func_begin _start
_start:
	la	a0, arena
	li	a1, ARENA_SIZE
	call	arena_init

	la	a0, filename
	call	map_input_file
	mv	s10, a0
	add	s11, a0, a1

	#mv	a0, a1
	#call	alloc
	#addi	s0, a0, 4

	sub	sp, sp, a1
	
	# stack alignment
	li	t0, 0b1111
	not	t0, t0
	and	sp, sp, t0

	addi	s0, sp, 4

	la	a0, compar_tree
	la	a1, alloc
	la	a2, free
	call	redblacktree_init
	mv	s1, a0

	mv	a0, s10
	call	line_length
	sw	a0, -4(s0)

	mv	a0, s10
	mv	a1, s0
	mv	a2, s11
	call	map_copy
	mv	s2, a0
	mv	s3, a1

	mv	a0, s0
	mv	a1, s1
	mv	a2, s2
	mv	a3, s3
	call	run_circuit

	mv	a2, a0
	la	a0, ansfmt
	li	a1, 1
	call	printf

	dec	sp, 8
	li	t0, -1
	sw	t0, 0(sp)
	sw	t0, 4(sp)

loop_pop_coords:
	mv	a0, s1
	mv	a1, sp
	call	set_pop
	bltz	a0, loop_pop_coords_end
	dec	sp, 8
	sw	a0, 0(sp)
	sw	a1, 4(sp)
	j	loop_pop_coords
loop_pop_coords_end:

	nop

	clr	s6
loop:
	lw	s4, 0(sp)
	lw	s5, 4(sp)
	inc	sp, 8
	bltz	s4, loop_end

	la	a0, arena
	li	a1, ARENA_SIZE
	call	arena_init

	la	a0, compar_tree
	la	a1, alloc
	la	a2, free
	call	redblacktree_init
	mv	s1, a0

	mv	a0 ,s0
	mv	a1, s4
	mv	a2, s5
	call	get_addr
	mv	s7, a0
	li	t0, '#'
	sb	t0, (s7)

	mv	a0, s0
	mv	a1, s1
	mv	a2, s2
	mv	a3, s3
	call	run_circuit
	bgez	a0, skip_count
	inc	s6
skip_count:

	li	t0, '.'
	sb	t0, (s7)
	j	loop
loop_end:

	la	a0, ansfmt
	li	a1, 1
	mv	a2, s6
	call	printf

stop_here:

	exit
	func_end _start


	func_begin set_pop
set_pop:
	dec	sp, 16
	sd	ra,  0(sp)


	call redblacktree_pop_leftmost
	bnez	a0, set_pop_notempty
	
	li	a0, -1
	li	a1, -1
	j	set_pop_ret

set_pop_notempty:
	li	t2, 0xFFFFFFFF
	and	a1, a0, t2
	srli	a0, a0, 32

	dec	a0
	dec	a1

set_pop_ret:

	ld	ra,  0(sp)
	inc	sp, 16
	ret
	func_end set_pop


	func_begin run_circuit
run_circuit:
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

	li	s4, UP
	clr	s5
	li	s8, '#'
	li	s9, 25000	# max steps

loop_run_circuit:
	dec	s9
	beqz	s9, run_circuit_fail

	mv	a0, s1
	mv	a1, s2
	mv	a2, s3
	call	set_insert
	add	s5, s5, a0
loop_noinsert:

	slli	t0, s4, 1
	la	t1, moves
	add	t0, t0, t1
	lb	t2, 0(t0)
	lb	t3, 1(t0)
	add	s6, s2, t2
	add	s7, s3, t3

	mv	a0, s0
	mv	a1, s6
	mv	a2, s7
	call	get_addr
	beqz	a0, loop_run_circuit_end
	lb	a0, (a0)
	beq	a0, s8, obstacle
	mv	s2, s6
	mv	s3, s7
	j	loop_run_circuit
obstacle:
	la	t0, turns
	add	t0, t0, s4
	lb	s4, (t0)
	j	loop_noinsert
run_circuit_fail:
	li	s5, -1
	
loop_run_circuit_end:
	mv	a0, s5
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
	func_end run_circuit


	# a0: map
	# a1: x
	# a2: y
	func_begin get_addr
get_addr:
	clr	t0
	bltz	a1, get_addr_ret
	bltz	a2, get_addr_ret
	lw	t1, -4(a0)
	bge	a1, t1, get_addr_ret
	bge	a2, t1, get_addr_ret
	mul	t1, t1, a2
	add	t1, t1, a1
	add	t0, t1, a0
get_addr_ret:
	mv	a0, t0
	ret
	func_end get_addr


	# a0: set
	# a1: X
	# a2: Y
	func_begin set_insert
set_insert:
	dec	sp, 16
	sd	ra, 0(sp)
	sd	s0, 8(sp)

	inc	a1
	inc	a2
	clr	s0

	slli	a1, a1, 32
	or	a1, a1, a2

	call	redblacktree_insert
	bnez	a0, set_insert_ret
	li	s0, 1
set_insert_ret:
	mv	a0, s0
	ld	ra, 0(sp)
	ld	s0, 8(sp)
	inc	sp, 16
	ret
	func_end set_insert


	# a0: origin
	# a1: destination
	# a2: origin end
	func_begin map_copy
map_copy:
	li	t0, '^'
	li	t1, '\n'
	clr	t3
	lw	t6, -4(a1)
loop_map_copy:
	lb	t2, (a0)
	beq	t2, t1, skip_char
	bne	t2, t0, not_origin
	li	t2, '.'
	rem	t4, t3, t6
	div	t5, t3, t6
not_origin:
	sb	t2, (a1)
	inc	a1
	inc	t3
skip_char:
	inc	a0
	bne	a0, a2, loop_map_copy
	mv	a0, t4
	mv	a1, t5
	ret
	func_end map_copy


	func_begin compar_tree
compar_tree:
	sub	a0, a0, a1
	ret
	func_end compar_tree



