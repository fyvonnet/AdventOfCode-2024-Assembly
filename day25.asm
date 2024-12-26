	.include "macros.inc"

	.globl	_start


	.section .rodata
filename:
	.string	"inputs/day25"
ansfmt:	.string	"Part %d answer: %d\n"



	.text
	.balign 8



	func_begin _start
_start:
	la	a0, filename
	call	map_input_file
	mv	s10, a0
	add	s11, a0, a1

	# allocate space for locks
	mv	s0, sp
	li	t0, 512*5
	sub	sp, sp, t0
	dec	s0, 4
	li	t0, -1
	sb	t0, (s0)

	# allocate space for keys
	mv	s1, sp
	li	t0, 512*5
	sub	sp, sp, t0
	dec	s1, 4
	li	t0, -1
	sb	t0, (s1)

	# allocate space for lock or key map
	dec	sp, 64
	mv	s2, sp

	# locks/keys arrays pointers
	dec	sp, 16
	mv	s3, sp
	sd	s0, 0(s3)
	sd	s1, 8(s3)

loop_parse_input:
	mv	a0, s10
	mv	a1, s2
	call	parse_to_map
	mv	s10, a0

	mv	a0, s2
	mv	a1, s3
	call	all_pin_heights

	blt	s10, s11, loop_parse_input
	ld	s0, 0(s3)
	ld	s1, 8(s3)
	mv	s2, s1
	clr	s3

loop_outer:
	mv	s1, s2
loop_inner:
	mv	a0, s0
	mv	a1, s1
	call	check_valid
	add	s3, s3, a0
	inc	s1, 5
	lb	t0, (s1)
	bgez	t0, loop_inner
	inc	s0, 5
	lb	t0, (s0)
	bgez	t0, loop_outer

	la	a0, ansfmt
	li	a1, 1
	mv	a2, s3
	call	printf

	exit
	func_end _start



	func_begin check_valid
check_valid:
	clr	t4
	li	t5, 5
	li	t6, 5
loop_check_valid:
	lb	t0, (a0)
	lb	t1, (a1)
	inc	a0
	inc	a1
	add	t0, t0, t1
	bgt	t0, t5, check_valid_ret
	dec	t6
	bnez	t6, loop_check_valid
	li	t4, 1
check_valid_ret:
	mv	a0, t4
	ret
	func_end check_valid



	# a0: map
	# a1: destinations
	func_begin all_pin_heights
all_pin_heights:
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

	mv	a0, s0
	li	a1, 0
	li	a2, 0
	call	get_char

	li	t0, '#'
	beq	a0, t0, lock_heights
key_heights:
	addi	s1, s1, 8
	li	s2, 0	# start at bottom
	li	s3, 1	# decrease Y coordinate
	j	all_pin_heights_endif
lock_heights:
	#addi	s1, s1, 0
	li	s2, 6	# start at bottom
	li	s3, -1	# decrease Y coordinate
all_pin_heights_endif:

	ld	s4, (s1)
	li	s5, 5
loop_all_pin_heights:
	mv	a0, s0
	addi	a1, s5, -1
	mv	a2, s2
	mv	a3, s3
	call	pin_height
	dec	s4
	sb	a0, (s4)
	dec	s5
	bnez	s5, loop_all_pin_heights
	sd	s4, (s1)
	
	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	ld	s2, 24(sp)
	ld	s3, 32(sp)
	ld	s4, 40(sp)
	ld	s5, 48(sp)
	inc	sp, 64
	ret
	func_end all_pin_heights



	# a0: map
	# a1: x
	# a2: y
	# a3: increment
	func_begin pin_height
pin_height:
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
	li	s4, 6
loop_pin_height:
	dec	s4
	add	s2, s2, s3
	mv	a0, s0
	mv	a1, s1
	mv	a2, s2
	call	get_char
	li	t0, '#'
	bne	a0, t0, loop_pin_height
	mv	a0, s4

	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	ld	s2, 24(sp)
	ld	s3, 32(sp)
	ld	s4, 40(sp)
	inc	sp, 48
	ret
	func_end pin_height
	


	# a0: map
	# a1: x
	# a2: y
	func_begin get_char
get_char:
	li	t0, 5
	mul	a2, a2, t0
	add	a1, a1, a2
	add	a0, a0, a1
	lb	a0, (a0)
	ret
	func_end get_char



	# a0: source
	# a1: destination
	func_begin parse_to_map
parse_to_map:
	li	t5, 35
	li	t6, '\n'
loop_parse_to_map:
	lb	t0, (a0)
	inc	a0
	beq	t0, t6, skip_nl
	sb	t0, (a1)
	inc	a1
	dec	t5
skip_nl:
	bnez	t5, loop_parse_to_map
	sb	zero, (a1)

	inc	a0, 2
	
	ret
	func_end parse_to_map



