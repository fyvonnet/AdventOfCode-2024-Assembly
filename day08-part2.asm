	.include "macros.inc"
	.include "memory.inc"

	.globl	_start

	.set	COUNT, 		-4
	.set	COORD_X, 	 0
	.set	COORD_Y, 	 4
	.set	FLAG, 		 8

	.set	DATA_SET, 	 0
	.set	DATA_LIMIT, 	 8

	.set	ENTRY_LST, 	 0
	.set	ENTRY_COUNT, 	 8
	.set	ENTRY_FREQ, 	12
	.set	ENTRY_SIZE, 	16

	.set	NODE_COORDS, 	 0
	.set	NODE_COORD_X, 	 0
	.set	NODE_COORD_Y, 	 4
	.set	NODE_NEXT, 	 8
	.set	NODE_SIZE, 	16


	.section .rodata
filename:
	.string	"inputs/day08"
ansfmt:	.string	"Part %d: %d\n"



	.bss
	.balign 8
        .set    CHUNKS_SIZE,    64
        .set    CHUNKS_COUNT,   2 * 1024
pool:   .space  8 + (CHUNKS_SIZE * CHUNKS_COUNT)



	.text
	.balign 8


	func_begin _start
_start:
	la	a0, filename
	call	open_input_file
	mv	s10, a0

	la	a0, pool
	li	a1, CHUNKS_COUNT
	li	a2, CHUNKS_SIZE
	call	pool_init

	# set of antinode coordinates
	la	a0, compar_coords
	la	a1, pool
	call	redblacktree_init
	mv	s3, a0

	# frequencies catalog
	la	a0, compar_entries
	la	a1, pool
	call	redblacktree_init
	mv	s4, a0

	# line buffer
	#la	a0, pool
	#call	pool_alloc
	#mv	s2, a0
	dec	sp, 64
	mv	s2, sp

	mv	a0, s10
	mv	a1, s2
	call	read_input_line
	mv	s0, a0

	li	s11, '.'
	clr	s9			# row number
loop_rows:
	clr	s8			# column number
	mv	s7, s2
loop_chars:
	lb	t0, (s7)
	beqz	t0, loop_chars_end
	beq	t0, s11, skip_char
	mv	a0, s4
	mv	a1, s8
	mv	a2, s9
	mv	a3, t0
	call	catalog_insert
skip_char:
	inc	s7
	inc	s8
	j	loop_chars
loop_chars_end:
	inc	s9
	mv	a0, s10
	mv	a1, s2
	call	read_input_line
	bgtz	a0, loop_rows
	
	dec	sp, 16
	sd	s3, DATA_SET(sp)
	sd	s0, DATA_LIMIT(sp)

	mv	a0, s4
	la	a1, process_entry
	mv	a2, sp
	call	redblacktree_inorder
	
	
	
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
	li	a1, 2
	la	a0, ansfmt
	call	printf

	exit
	func_end _start


	# a0: entry
	# a1: data
	func_begin process_entry
process_entry:
	dec	sp, 64
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s1, 16(sp)

	mv	s0, a0
	mv	s1, a1

	lw	t1, ENTRY_COUNT(s0)
	li	t0, 1
	beq	t1, t0, process_entry_end
	dec	sp, 16
	sb	x0, FLAG(sp)
	ld	t0, ENTRY_LST(s0)
	li	t1, 1
	ld	s0, DATA_LIMIT(s1)
	ld	s1, DATA_SET(s1)
loop_copy_coords:
	dec	sp, 16
	ld	t2, NODE_COORDS(t0)
	sd	t2, 0(sp)
	sb	t1, 8(sp)
	ld	t0, NODE_NEXT(t0)
	bnez	t0, loop_copy_coords

	mv	a0, s0
	mv	a1, s1
	mv	a2, sp
	call	antinode_same_freq

loop_add_antennas:
	mv	a0, s0
	mv	a1, s1
	lw	a2, 0(sp)
	lw	a3, 4(sp)
	call	set_insert
	inc	sp, 16
	lb	t0, 8(sp)
	bnez	t0, loop_add_antennas
	inc	sp, 16
process_entry_end:
	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	inc	sp, 64
	ret
	func_end process_entry


	# a0: catalog
	# a1: x
	# a2: y
	# a3: freq
	func_begin catalog_insert
catalog_insert:
	dec	sp, 48
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s1, 16(sp)
	sd	s2, 24(sp)
	sd	s3, 32(sp)

	mv	s0, a0
	mv	s1, a1
	mv	s2, a2
	mv	s3, a3

	la	a0, pool
	call	pool_alloc
	sb	a3, ENTRY_FREQ(a0)
	sd	x0, ENTRY_LST(a0)
	sw	x0, ENTRY_COUNT(a0)

	mv	a1, a0
	mv	a0, s0
	call	redblacktree_insert_or_free
	mv	s0, a0

	lw	t0, ENTRY_COUNT(s0)
	inc	t0
	sw	t0, ENTRY_COUNT(s0)

	la	a0, pool
	call	pool_alloc

	sw	s1, NODE_COORD_X(a0)
	sw	s2, NODE_COORD_Y(a0)

	ld	t0, ENTRY_LST(s0)
	sd	t0, NODE_NEXT(a0)
	sd	a0, ENTRY_LST(s0)
	
	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	ld	s2, 24(sp)
	ld	s3, 32(sp)
	inc	sp, 48
	ret
	func_end catalog_insert



	# a0: coordinates limit
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


	# a0: coordinates limit
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



	# a0: coordinates limit
	# a1: set
	# a2: antenna x
	# a3: antenna y
	func_begin set_insert
set_insert:
	dec	sp, 16
	sd	ra,  0(sp)
	sd	s0,  8(sp)

	clr	s0

	bltz	a2, set_insert_ret
	bltz	a3, set_insert_ret
	bge	a2, a0, set_insert_ret
	bge	a3, a0, set_insert_ret

	mv	a0, a1
	slli	a1, a2, 32
	or	a1, a1, a3
	call	redblacktree_insert

	la	s0, 1

set_insert_ret:
	mv	a0, s0
	ld	ra,  0(sp)
	ld	s0,  8(sp)
	inc	sp, 16
	ret
	func_end set_insert


	# a0: map
	# a1: set
	# a2: antenna X
	# a3: antenna Y
	# a4: move X
	# a5: move Y
	func_begin many_antinodes
many_antinodes:
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
	mv	s5, a5

loop_many_antinodes:
	add	s2, s2, s4
	add	s3, s3, s5
	mv	a0, s0
	mv	a1, s1
	mv	a2, s2
	mv	a3, s3
	call	set_insert
	bnez	a0, loop_many_antinodes

	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	ld	s2, 24(sp)
	ld	s3, 32(sp)
	ld	s4, 40(sp)
	ld	s5, 48(sp)
	inc	sp, 64
	ret
	func_end many_antinodes



	# a0: map
	# a1: set
	# a2: first antenna
	# a3: second antenna
	func_begin antinode
antinode:
	dec	sp, 64
	sd	s2,  0(sp)
	sd	s3,  8(sp)
	sd	ra, 16(sp)
	sd	s0, 24(sp)
	sd	s1, 32(sp)
	sd	s4, 40(sp)
	sd	s5, 48(sp)

	mv	s0, a0
	mv	s1, a1
	mv	s2, a2
	mv	s3, a3

	lw	t0, 0(s2)
	lw	t1, 4(s2)
	lw	t2, 0(s3)
	lw	t3, 4(s3)

	sub	s4, t0, t2
	sub	s5, t1, t3

	mv	a0, s0
	mv	a1, s1
	mv	a2, t0
	mv	a3, t1
	mv	a4, s4
	mv	a5, s5
	call	many_antinodes

	mv	a0, s0
	mv	a1, s1
	lw	a2, 0(s3)
	lw	a3, 4(s3)
	neg	a4, s4
	neg	a5, s5
	call	many_antinodes

	ld	s2,  0(sp)
	ld	s3,  8(sp)
	ld	ra, 16(sp)
	ld	s0, 24(sp)
	ld	s1, 32(sp)
	ld	s4, 40(sp)
	ld	s5, 48(sp)
	inc	sp, 64
	ret
	func_end antinode


	
	func_begin compar_entries
compar_entries:	
	lb	t0, ENTRY_FREQ(a0)
	lb	t1, ENTRY_FREQ(a1)
	sub	a0, t0, t1
	ret
	func_end compar_entries



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


