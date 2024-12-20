	.include "macros.inc"
	.include "memory.inc"

	.globl	_start

	.set	SQUARE_PLANT, 	 0
	.set	SQUARE_VISITED,  1

	.set	QUEUE_COUNT,	32
	.set	QUEUE_SIZE,	 8

	.set	EAST, 		 0
	.set	WEST,		 1
	.set	SOUTH,		 2
	.set	NORTH,		 3
	
	.set	ADJ_X,		 0
	.set	ADJ_Y,		 1
	.set	ADJ_POS,	 2
	.set	ADJ_CONT,	 3

	.section .rodata
filename:
	.string	"inputs/day12"
ansfmt:	.string	"Part %d answer: %d\n"
adjacents:
	.byte	 0, -1, 0b1000, 1	# north
	.byte	 1,  0, 0b0100, 1	# east
	.byte	 0,  1, 0b0010, 1	# south
	.byte	-1,  0, 0b0001, 0	# west

diag_nw:.byte	-1, -1
diag_ne:.byte	 1, -1
diag_sw:.byte	-1,  1
diag_se:.byte	 1,  1

	# number of angles as a function of the number of adjacent sides
angles:	.byte	0, 0, 1, 2, 4

	.balign 8
diagonals:
	# 0b0000
	.dword	diag_nw, diag_ne, diag_sw, diag_se
	.zero	8
	# 0b0001
	.dword	diag_ne, diag_se
	.zero	3*8
	# 0b0010
	.dword	diag_nw, diag_ne
	.zero	3*8
	# 0b0011
	.dword	diag_ne
	.zero	4*8
	# 0b0100
	.dword	diag_nw, diag_sw
	.zero	3*8
	# 0b0101
	.zero	5*8
	# 0b0110
	.dword	diag_nw
	.zero	4*8
	# 0b0111
	.zero	5*8
	# 0b1000
	.dword	diag_sw, diag_se
	.zero	3*8
	# 0b1001
	.dword	diag_se
	.zero	4*8
	# 0b1010
	.zero	5*8
	# 0b1011
	.zero	5*8
	# 0b1100
	.dword	diag_sw
	.zero	4*8
	# 0b1101
	.zero	5*8
	# 0b1110
	.zero	5*8
	# 0b1111
	.zero	5*8


left:	.byte	NORTH
	.byte	SOUTH
	.byte	EAST
	.byte	WEST

right:	.byte	SOUTH
	.byte	NORTH
	.byte	WEST
	.byte	EAST

back:	.byte	WEST
	.byte	EAST
	.byte	NORTH
	.byte	SOUTH


	.bss
	.balign 8
queue:	.space	40 + (QUEUE_COUNT * QUEUE_SIZE)


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

	slli	a1, a1, 1
	sub	sp, sp, a1
	li	t0, 0b1111
	not	t0, t0
	and	sp, sp, t0
	addi	s0, sp, 4

	mv	a0, s10
	call	line_length
	sw	a0, -4(s0)
	mv	s6, a0

	mv	s7, s0
	clr	s9
loop_load_rows:
	clr	s8
loop_load_chars:
	lb	t0, (s10)
	li	t1, '\n'
	beq	t0, t1, loop_load_chars_end
	sb	t0, SQUARE_PLANT(s7)
	sb	x0, SQUARE_VISITED(s7)
	inc	s7, 2
	inc	s8
	inc	s10
	j	loop_load_chars
loop_load_chars_end:
	inc	s9
	inc	s10
	bne	s10, s11, loop_load_rows
	li	t0, -1
	sb	t0, (s7)

	clr	s7
	clr	s9
	clr	s10
loop_rows:
	clr	s8
loop_chars:
	mv	a0, s0
	mv	a1, s8
	mv	a2, s9
	call	get_addr
	lb	t0, SQUARE_VISITED(a0)
	bnez	t0, loop_chars_next
	mv	a0, s0
	mv	a1, s8
	mv	a2, s9
	call	region_price
	add	s7, s7, a0
	add	s10, s10, a1

loop_chars_next:
	inc	s8
	bne	s8, s6, loop_chars
	inc	s9
	bne	s9, s6, loop_rows

	la	a0, ansfmt
	li	a1, 1
	mv	a2, s7
	call	printf

	la	a0, ansfmt
	li	a1, 2
	mv	a2, s10
	call	printf
	
	exit
	func_end _start



	# a0: map
	# a1: x
	# a2: y
	func_begin region_price
region_price:
	dec	sp, 128
	#sd	x0,    0(sp)
	#sd	x0,    8(sp)
	sd	ra,   16(sp)
	sd	s0,   24(sp)
	sd	s1,   32(sp)
	sd	s2,   40(sp)
	sd	s3,   48(sp)
	sd	s4,   56(sp)
	sd	s5,   64(sp)
	sd	s6,   72(sp)
	sd	s7,   80(sp)
	sd	s8,   88(sp)
	sd	s9,   96(sp)
	sd	s10, 104(sp)
	sd	s11, 112(sp)

	mv	s0, a0
	mv	s1, a1
	mv	s2, a2
	clr	s3		# area
	clr	s4		# perimeter
	clr	s5		# sides

	call	get_addr
	li	t1, -1		# marked as starting point
	sb	t1, SQUARE_VISITED(a0)

	la	a0, queue
	call	queue_push
	sw	s1, 0(a0)
	sw	s2, 4(a0)

loop_region_price:
	la	a0, queue
	call	queue_pop
	beqz	a0, loop_region_price_end

	lw	s1, 0(a0)
	lw	s2, 4(a0)
	inc	s3

	mv	a0, s0
	mv	a1, s1
	mv	a2, s2
	call	look_around
	add	s4, s4, a0
	add	s5, s5, a1

	j	loop_region_price
loop_region_price_end:

	mul	a0, s3, s4
	mul	a1, s3, s5

	#ld	x0,    0(sp)
	#ld	x0,    8(sp)
	ld	ra,   16(sp)
	ld	s0,   24(sp)
	ld	s1,   32(sp)
	ld	s2,   40(sp)
	ld	s3,   48(sp)
	ld	s4,   56(sp)
	ld	s5,   64(sp)
	ld	s6,   72(sp)
	ld	s7,   80(sp)
	ld	s8,   88(sp)
	ld	s9,   96(sp)
	ld	s10, 104(sp)
	inc	sp, 128
	ret
	func_end region_price



	# a0: map
	# a1: coord x
	# a2: coord y
	func_begin look_around
look_around:
	dec	sp, 80
	sd	ra,   0(sp)
	sd	s0,   8(sp)
	sd	s1,  16(sp)
	sd	s2,  24(sp)
	sd	s3,  32(sp)
	sd	s4,  40(sp)
	sd	s5,  48(sp)
	sd	s6,  56(sp)
	sd	s7,  64(sp)
	sd	s8,  72(sp)
	sd	s9,  80(sp)

	mv	s0, a0
	mv	s1, a1
	mv	s2, a2

	call	get_addr
	lb	s5, SQUARE_PLANT(a0)

	la	s6, adjacents
	clr	s3			# borders positions
	clr	s4			# number of borders for this square
loop_look_around:
	lb	t0, ADJ_X(s6)
	lb	t1, ADJ_Y(s6)
	add	s7, s1, t0
	add	s8, s2, t1

	mv	a0, s0
	mv	a1, s7
	mv	a2, s8
	mv	a3, s5
	call	check_coords

	bgez	a0, same_region
	inc	s4			# increment perimeter
	lb	t0, ADJ_POS(s6)
	or	s3, s3, t0
	j	loop_look_around_next
	
same_region:

	beqz	a0, loop_look_around_next

	li	t0, 1
	sb	t0, SQUARE_VISITED(a1)	# mark as visited
	la	a0, queue
	call	queue_push
	sw	s7, 0(a0)
	sw	s8, 4(a0)
loop_look_around_next:
	lb	t0, ADJ_CONT(s6)
	inc	s6, 4
	bnez	t0, loop_look_around

	# not in an angle if opposite borders
	clr	s9
	li	t0, 0b1010
	beq	s3, t0, look_around_ret
	li	t0, 0b0101
	beq	s3, t0, look_around_ret
	
	la	t0, angles
	add	t0, t0, s4
	lb	s9, (t0)

	mv	a0, s0
	mv	a1, s1
	mv	a2, s2
	mv	a3, s3
	mv	a4, s5
	call	diagonal_corners
	add	s9, s9, a0
	

look_around_ret:

	mv	a0, s4
	mv	a1, s9
	ld	ra,   0(sp)
	ld	s0,   8(sp)
	ld	s1,  16(sp)
	ld	s2,  24(sp)
	ld	s3,  32(sp)
	ld	s4,  40(sp)
	ld	s5,  48(sp)
	ld	s6,  56(sp)
	ld	s7,  64(sp)
	ld	s8,  72(sp)
	ld	s9,  80(sp)
	inc	sp, 80
	ret
	func_end look_around


	# a0: map
	# a1: coord x
	# a2: coord y
	# a3: border positions
	# a4: plant
	func_begin diagonal_corners
diagonal_corners:
	dec	sp, 64
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd 	s1, 16(sp)
	sd	s2, 24(sp)
	sd	s3, 32(sp)
	sd	s4, 40(sp)
	sd	s5, 48(sp)
	sd	s6, 56(sp)

	mv	s0, a0
	mv	s1, a1
	mv	s2, a2
	mv	s3, a3
	mv	s4, a4
	
	li	t0, 40
	mul	t0, t0, s3
	la	t1, diagonals
	add	s5, t0, t1
	clr	s6
loop_corners:
	ld	t0, (s5)
	inc	s5, 8
	beqz	t0, loop_corners_end
	lb	t1, 0(t0)
	lb	t2, 1(t0)
	mv	a0, s0
	add	a1, s1, t1
	add	a2, s2, t2
	mv	a3, s4
	call	check_coords
	bgez	a0, loop_corners
	inc	s6
	j	loop_corners
loop_corners_end:
	mv	a0, s6
	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld 	s1, 16(sp)
	ld	s2, 24(sp)
	ld	s3, 32(sp)
	ld	s4, 40(sp)
	ld	s5, 48(sp)
	ld	s6, 56(sp)
	inc	sp, 64
	ret
	func_end diagonal_corners



	# a0: map
	# a1: x
	# a2: y
	# a3: plant
	func_begin check_coords
check_coords:
	dec	sp, 16
	sd	ra, 0(sp)
	sd	s3, 8(sp)

	mv	s3, a3

	call	get_addr
	
	li	t6, -1	# different region or out of bounds
	beqz	a0, check_coords_ret
	lb	t0, SQUARE_PLANT(a0)
	bne	t0, s3, check_coords_ret

	li	t6, 0	# same region, visited
	lb	t0, SQUARE_VISITED(a0)
	bnez	t0, check_coords_ret

	li	t6, 1	# same region, not visited
	
check_coords_ret:
	mv	a1, a0
	mv	a0, t6
	ld	ra, 0(sp)
	ld	s3, 8(sp)
	inc	sp, 16
	ret
	func_end check_coords


	# a0: map
	# a1: x
	# a2: y
	func_begin get_char
get_char:
	dec	sp, 16
	sd	ra, (sp)
	call	get_addr
	lb	a0, SQUARE_PLANT(a0)
	ld	ra, (sp)
	inc	sp, 16
	ret
	func_end get_char



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
	

