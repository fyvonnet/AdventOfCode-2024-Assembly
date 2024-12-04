
	.include "macros.inc"

	.section .rodata
filename:
	.string	"inputs/day04"
	.string	"inputs/day04-test"
fmtans:	.string "Part %d answer: %d\n"
strmas:	.string "MAS"
moves:
	.byte	-1, -1,   0, -1,   1, -1
	.byte	-1,  0,            1,  0
	.byte	-1,  1,   0,  1,   1,  1



	.section .text
	.balign 8

	.globl	_start
	func_begin _start
_start:
	la	a0, filename
	call	map_input_file
	mv	s10, a0
	add	s11, a0, a1
	sub	sp, sp, a1
	
	# stack alignment
	li	t0, 16-1
	not	t0, t0
	and	sp, sp, t0

	mv	s0, sp
	#dec	sp, 16

	mv	a0, s10
	call	line_length
	mv	s1, a0

	mv	t0, s10
	mv	t1, s0
	li	t2, '\n'
loop_copy:
	lb	t3, (t0)
	beq	t3, t2, loop_copy_skip
	sb	t3, (t1)
	inc	t1
loop_copy_skip:
	inc	t0
	bne	t0, s11, loop_copy

	clr	s4	# count
	clr	s3
loop_y:
	clr	s2
loop_x:
	mv	a0, s0
	mv	a1, s1
	mv	a2, s2
	mv	a3, s3
	call	load_byte
	li	t0, 'X'
	bne	t0, a0, skip

	mv	a0, s0
	mv	a1, s1
	mv	a2, s2
	mv	a3, s3
	call	check_all_dirs
	add	s4, s4, a0
skip:
	inc	s2
	bne	s2, s1, loop_x

	inc	s3
	bne	s3, s1, loop_y

	la	a0, fmtans
	li	a1, 1
	mv	a2, s4
	call	printf

stop_here:

	exit
	func_end _start



	# a0: map
	# a1: side
	# a2: X
	# a3: Y
	func_begin check_all_dirs
check_all_dirs:
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

	la	s4, moves
	li	s5, 8
	clr	s6
loop_all_dirs:
	mv	a0, s0
	mv	a1, s1
	mv	a2, s2
	mv	a3, s3
	lb	a4, 0(s4)
	lb	a5, 1(s4)
	call	check_bytes
	add	s6, s6, a0
	#bnez	a0, all_dirs_end
	inc	s4, 2
	dec	s5
	bnez	s5, loop_all_dirs

#all_dirs_end:

	mv	a0, s6
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
	func_end check_all_dirs



	# a0: map
	# a1: side
	# a2: X
	# a3: Y
	# a4: move-X
	# a5: move-Y
	func_begin check_bytes
check_bytes:
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
	mv	s4, a4
	mv	s5, a5
	la	s6, strmas
loop_check_bytes:
	add	s2, s2, s4
	add	s3, s3, s5
	mv	a0, s0
	mv	a1, s1
	mv	a2, s2
	mv	a3, s3
	call	load_byte
	lb	t0, (s6)
	beqz	t0, check_succ
	bne	a0, t0, check_fail
	inc	s6
	j	loop_check_bytes
check_succ:
	li	a0, 1
	j	check_ret
check_fail:
	clr	a0
check_ret:
	
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
	func_end check_bytes

	# a0: map
	# a1: side
	# a2: X
	# a3: Y
	func_begin load_byte
load_byte:
	clr	t0
	bltz	a2, load_byte_ret
	bltz	a3, load_byte_ret
	bge	a2, a1, load_byte_ret
	bge	a3, a1, load_byte_ret
	mul	a3, a3, a1
	add	a3, a3, a2
	add	a3, a3, a0
	lb	t0, (a3)
load_byte_ret:
	mv	a0, t0
	ret
	func_end load_byte
