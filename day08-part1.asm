	.include "macros.inc"
	.include "memory.inc"

	.globl	_start


	.section .rodata
filename:
	.string	"inputs/day08"
ansfmt:	.string	"Part %d: %d\n"



	.bss
	.balign 8
	.set	ARENA_SIZE, 32*1024
arena:	.space	ARENA_SIZE



	.text
	.balign 8


	create_alloc_func alloc, arena, arena


	func_begin _start
_start:
	la	a0, filename
	call	map_input_file
	mv	s10, a0
	add	s11, a0, a1

	sub	sp, sp, a1
	li	t0, 0b1111
	not	t0, t0
	and	sp, sp, t0
	add	s0, sp, 4

	la	a0, arena
	li	a1, ARENA_SIZE
	call	arena_init

	la	a0, compar_coords
	la	a1, alloc
	clr	a2
	call	redblacktree_init
	mv	s3, a0


	# copy map to memory
	mv	a0, s10
	call	line_length
	sw	a0, -4(s0)
	li	t0, '\n'
	mv	t2, s0
loop_read_map:
	lb	t1, (s10)
	inc	s10
	beq	t0, t1, skip_nl
	sb	t1, (t2)
	inc	t2
skip_nl:
	bne	s10, s11, loop_read_map
	sb	zero, (t2)

	# antennas list terminator
	dec	sp, 16
	sb	x0, 8(sp)

	# load antennas
	mv	t0, s0
	clr	t1
	li	t2, '.'
	lw	t3, -4(s0)
	clr	s1
loop_get_antennas:
	lb	t4, (t0)
	beqz	t4, loop_get_antennas_end
	beq	t4, t2, skip_ant
	inc	s1
	dec	sp, 16
	rem	t5, t1, t3
	sw	t5, 0(sp)
	div	t5, t1, t3
	sw	t5, 4(sp)
	sb	t4, 8(sp)
skip_ant:
	inc	t1
	inc	t0
	j	loop_get_antennas
loop_get_antennas_end:
	mv	s2, sp

	mv	a0, s2
	mv	a1, s1
	li	a2, 16
	la	a3, compar_antennas
	call	quicksort


loop:
	mv	a0, s0
	mv	a1, s3
	mv	a2, s2
	call	antinode_same_freq
	mv	s2, a0
	lb	t0, 8(s2)
	bnez	t0, loop

	mv	a0, s3
	call	redblacktree_count_nodes
	mv	a2, a0
	li	a1, 1
	la	a0, ansfmt
	call	printf

	exit
	func_end _start



	# a0: map
	# a1: set
	# a2: antennas
	func_begin antinode_same_freq
antinode_same_freq:
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
	lb	s3, 8(s2)
loop_antinode_same_freq: 
	mv	a0, s0
	mv	a1, s1
	mv	a2, s2
	add	a3, s2, 16
	call	antinode_followings
	inc	s2, 16
	lb	t0, 8(s2)
	beq	t0, s3, loop_antinode_same_freq
antinode_same_freq_end:
	mv	a0, s2
	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	ld	s2, 24(sp)
	ld	s3, 32(sp)
	ld	s4, 40(sp)
	inc	sp, 48
	ret
	func_end antinode_same_freq


	# a0: map
	# a1: set
	# a2: current antenna
	# a3: following antennas
	func_begin antinode_followings
antinode_followings:
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
	lb	s4, 8(s2)
loop_antinode_followings:
	lb	t0, 8(s3)
	bne	t0, s4, loop_antinode_followings_end
	mv	a0, s0
	mv	a1, s1
	mv	a2, s2
	mv	a3, s3
	call	antinode
	addi	s3, s3, 16
	j	loop_antinode_followings

loop_antinode_followings_end:
	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	ld	s2, 24(sp)
	ld	s3, 32(sp)
	ld	s4, 40(sp)
	inc	sp, 48
	ret
	func_end antinode_followings



	func_begin set_insert
set_insert:
	dec	sp, 16
	sd	ra,  0(sp)

	lw	t0, 0(a2)
	lw	t1, 4(a2)

	bltz	t0, set_insert_ret
	bltz	t1, set_insert_ret

	lw	t2, -4(a0)

	bge	t0, t2, set_insert_ret
	bge	t1, t2, set_insert_ret

	mv	a0, a1
	ld	a1, (a2)
	call	redblacktree_insert

set_insert_ret:
	ld	ra,  0(sp)
	inc	sp, 16
	ret
	func_end set_insert


	# a0: map
	# a1: set
	# a2: first antenna
	# a3: second antenna
	func_begin antinode
antinode:
	dec	sp, 48
	sd	ra, 16(sp)
	sd	s0, 24(sp)
	sd	s1, 32(sp)

	mv	s0, a0
	mv	s1, a1

	lw	t0, 0(a2)
	lw	t1, 4(a2)
	lw	t2, 0(a3)
	lw	t3, 4(a3)

	sub	t4, t0, t2
	sub	t5, t1, t3

	add	t6, t0, t4
	sw	t6,  0(sp)
	add	t6, t1, t5
	sw	t6,  4(sp)
	sub	t6, t2, t4
	sw	t6,  8(sp)
	sub	t6, t3, t5
	sw	t6, 12(sp)

	mv	a0, s0
	mv	a1, s1
	mv	a2, sp
	call	set_insert
	
	mv	a0, s0
	mv	a1, s1
	add	a2, sp, 8
	call	set_insert
	
	ld	ra, 16(sp)
	ld	s0, 24(sp)
	ld	s1, 32(sp)
	inc	sp, 48
	ret
	func_end antinode


	
	func_begin compar_antennas
compar_antennas:	
	lb	t0, 8(a0)
	lb	t1, 8(a1)
	sub	a0, t0, t1
	ret
	func_end compar_antennas


	func_begin compar_coords
compar_coords:
	sub	a0, a0, a1
	ret
	func_end compar_coords


