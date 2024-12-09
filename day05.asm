	.include "macros.inc"

	.set	BEFORE,		-1
	.set	IGNORE, 	 0
	.set	AFTER, 		 1
	.set	COUNT, 		-4

	.section .rodata
filename:
	.string	"inputs/day05"
	.string	"inputs/day05-test"
ansfmt:	.string "Part %d: %d\n"


	.bss
	.balign 8

rulesptr:
	.space	8



	.text
	.balign 8
	
	

	.globl	_start


	func_begin _start
_start:
	la	a0, filename
	call	map_input_file
	mv	s10, a0
	add	s11, a0, a1

	clr	s1			# rules counter

	li	s9, '\n'
loop_read_rules:
	dec	sp, 32

	inc	s1, 2			# each input line adds 2 rules

	mv	a0, s10
	mv	a1, sp
	call	parse_input_line
	mv	s10, a0

	lb	t0, (s10)
	bne	t0, s9, loop_read_rules

	mv	s0, sp
	dec	sp, 16
	sw	s1, COUNT(s0)

	la	t0, rulesptr
	sd	s0, (t0)

	mv	a0, s0
	mv	a1, s1
	li	a2, 16
	la	a3, compar_rules
	call	quicksort

	inc	s10			# skip '\n'

	dec	sp, 32*4
	addi	s1, sp, 4

	clr	s2
	clr	s3

loop_read_updates:
	mv	a0, s10
	mv	a1, s1
	call	parse_update
	mv	s10, a0

	mv	a0, s0
	mv	a1, s1
	call	check_update
	add	s2, s2, a0
	bnez	a0, skip_sort

	mv	a0, s1
	lw	a1, -4(s1)
	li	a2, 4
	la	a3, compar_pages
	call	quicksort

	mv	a0, s1
	call	get_middle_page
	add	s3, s3, a0
skip_sort:
	blt	s10, s11, loop_read_updates

	la	a0, ansfmt
	li	a1, 1
	mv	a2, s2
	call printf

	la	a0, ansfmt
	li	a1, 2
	mv	a2, s3
	call printf

	exit
	func_end _start



	func_begin get_middle_page
get_middle_page:
	lw	t0, -4(a0)
	srli	t0, t0, 1
	slli	t0, t0, 2
	add	t0, t0, a0
	lw	a0, (t0)
	ret
	func_end get_middle_page


	# a0: rules
	# a1: other page
	# a2: reference page
	# returns whether the other page is before or after the reference page
	func_begin check_rule
check_rule:
	dec	sp, 16
	sd	ra,  8(sp)

	sw	a2, 0(sp)
	sw	a1, 4(sp)

	lw	a1, COUNT(a0)
	li	a2, 16
	la	a3, compar_rules
	mv	a4, sp
	call	binsearch
	beqz	a0, check_rule_ret
	lb	a0, 8(a0)
check_rule_ret:
	
	ld	ra,  8(sp)
	inc	sp, 16
	ret
	func_end check_rule



	# a0: rules
	# a1: next pages
	# a2: reference page
	func_begin check_next_pages
check_next_pages:
	dec	sp, 32
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s1, 16(sp)
	sd	s2, 24(sp)

	mv	s0, a0
	mv	s1, a1
	mv	s2, a2

check_next_pages_loop:
	mv	a0, s0
	lw	a1, (s1)
	bltz	a1, check_next_pages_succ
	mv	a2, s2
	call	check_rule
	bltz	a0, check_next_pages_fail
	inc	s1, 4
	j	check_next_pages_loop

check_next_pages_succ:
	la	a0, 1
	j	check_next_pages_ret
check_next_pages_fail:
	clr	a0

check_next_pages_ret:
	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	ld	s2, 24(sp)
	inc	sp, 32
	ret
	func_end check_next_pages



	# a0: rules
	# a1: update array
	func_begin check_update
check_update:
	dec	sp, 48
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s1, 16(sp)
	sd	s2, 24(sp)
	sd	s3, 32(sp)
	sd	s4, 40(sp)

	mv	s0, a0
	mv	s1, a1
	clr	s3
	mv	s4, a1
	
loop_check_update:
	lw	s2, (s1)
	bltz	s2, check_update_succ

	inc	s1, 4

	mv	a0, s0
	mv	a1, s1
	mv	a2, s2
	call	check_next_pages
	beqz	a0, check_update_end

	j	loop_check_update

check_update_succ:
	# return middle page number
	lw	t0, COUNT(s4)
	srli	t0, t0, 1
	slli	t0, t0, 2
	add	t0, t0, s4
	lw	s3, (t0)

check_update_end:
	mv	a0, s3
	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	ld	s2, 24(sp)
	ld	s3, 32(sp)
	ld	s4, 40(sp)
	inc	sp, 48
	ret
	func_end check_update


	# a0: input pointer
	# a1: destination array
	# ret: input pointer / pages count
	func_begin parse_update
parse_update:
	dec	sp, 32
	sd	ra,  0(sp)
	sd	s1,  8(sp)
	sd	s2, 16(sp)
	sd	s3, 24(sp)

	mv	s1, a1
	clr	s2
	mv	s3, a1
loop_parse_update:
	inc	s2
	call	parse_integer
	sw	a1, (s1)
	lb	t0, (a0)
	inc	a0
	inc	s1, 4
	li	t1, ','
	beq	t0, t1, loop_parse_update
	li	t0, -1
	sw	t0, (s1)

	sw	s2, COUNT(s3)

	ld	ra,  0(sp)
	ld	s1,  8(sp)
	ld	s2, 16(sp)
	ld	s3, 24(sp)
	inc	sp, 32
	ret
	func_end parse_update



	func_begin parse_input_line
parse_input_line:
	dec	sp, 32
	sd	ra,  0(sp)
	sd	s1,  8(sp)

	mv	s1, a1

	call	parse_integer
	sw	a1,  0(s1)
	#sw	a1, 20(s1)
	sw	a1, 20(s1)

	inc	a0		# skip '|'

	call	parse_integer
	sw	a1,  4(s1)
	#sw	a1, 16(s1)
	sw	a1, 16(s1)

	li	t0, AFTER
	sb	t0, 8(s1)
	li	t0, BEFORE
	sb	t0, 24(s1)

	inc	a0		# skip '\n'

	ld	ra,  0(sp)
	ld	s1,  8(sp)
	inc	sp, 32
	ret
	func_end parse_input_line



	func_begin compar_rules
compar_rules:
	ld	t0, (a0)
	ld	t1, (a1)
	sub	a0, t0, t1
	ret
	func_end compar_rules

compar_pages:
	dec	sp, 16
	sd	ra, 8(sp)

	lw	t0, (a0)
	lw	t1, (a1)
	sw	t0, 0(sp)
	sw	t1, 4(sp)

	la	t0, rulesptr
	ld	a0, (t0)
	lw	a1, -4(a0)
	li	a2, 16
	la	a3, compar_rules
	mv	a4, sp
	call	binsearch
	lb	a0, 8(a0)
	neg	a0, a0

	ld	ra, 8(sp)
	inc	sp, 16
	ret

