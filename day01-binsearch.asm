	.include "macros.inc"

	.set	NUMBER,	0
	.set	SCORE,	4

	.section .rodata
file_name:
	.string	"inputs/day01"
ansfmt:
	.string "Part %d answer: %d\n"


	.text
	.balign 8

	.globl _start
	func_begin _start
_start:
	la	a0, file_name
	call	map_input_file
	mv	s10, a0
	add	s11, a0, a1


	# read input in the stack

	clr	s2
	mv	a0, s10
loop_read:
	dec	sp, 8
	call	parse_integer
	sw	a1, 0(sp)
	call	skip_to_digit
	call	parse_integer
	sw	a1, 4(sp)
	inc	s2
	inc	a0			# skip \n
	blt	a0, s11, loop_read
	mv	s9, sp


	# allocate vectors

	li	t0, 4
	mul	s3, s2, t0

	sub	sp, sp, s3
	mv	s0, sp
	sub	sp, sp, s3
	mv	s1, sp

	li	t0, 15
	not	t0, t0
	and	sp, sp, t0
	
	# copy input from stack to vectors

	mv	s10, s0
	mv	s11, s1
	mv	t2,  s2
loop_copy:
	lw	t0, 0(s9)
	lw	t1, 4(s9)
	sw	t0, (s10)
	sw	t1, (s11)
	inc	s10, 4
	inc	s11, 4
	dec	t2
	inc	s9, 8
	bnez	t2, loop_copy


	# sort vectors

	mv	a0, s0
	mv	a1, s2
	li	a2, 4
	la	a3, compar_sort
	call	quicksort
	
	mv	a0, s1
	mv	a1, s2
	li	a2, 4
	la	a3, compar_sort
	call	quicksort


	##########
	# PART 1 #
	##########
	
	# compute sum of differences

	clr	s3
	mv	s10, s0
	mv	s11, s1
	mv	s4, s2
loop_compute:
	lw	t0, (s10)
	lw	t1, (s11)
	sub	a0, t0, t1
	call	abs
	add	s3, s3, a0
	inc	s10, 4
	inc	s11, 4
	dec	s4
	bnez	s4, loop_compute

	la	a0, ansfmt
	li	a1, 1
	mv	a2, s3
	call	printf



	##########
	# PART 2 #
	##########


	# create frequency table
	clr	s3
	mv	s4, s2
	mv	a0, s1
loop_freqs:
	inc	s3
	dec	sp, 16
	mv	a1, sp
	call	count_freq
	lw	t0, SCORE(sp)
	sub	s4, s4, t0
	bgtz	s4, loop_freqs
	mv	s4, sp

	dec	sp, 16
	mv	s5, sp			# temporary record for search
	clr	s6


loop_compute2:
	lw	s7, (s0)
	sw	s7, NUMBER(s5)

	mv	a0, s4
	mv	a1, s3
	li	a2, 16
	la	a3, compar_binsearch
	mv	a4, s5
	call	binsearch
	
	beqz	a0, loop_compute2_next
	lw	t0, SCORE(a0)
	mul	t0, t0, s7	
	add	s6, s6, t0
loop_compute2_next:
	inc	s0, 4
	dec	s2
	bnez	s2, loop_compute2
	

stop_here:

	la	a0, ansfmt
	li	a1, 2
	mv	a2, s6
	call	printf
	
	exit
	func_end _start



	func_begin compar_sort
compar_sort:
	lw	a0, (a0)
	lw	a1, (a1)
	sub	a0, a0, a1
	ret
	func_end compar_sort


	func_begin compar_binsearch
compar_binsearch:
	lw	a0, (a0)
	lw	a1, (a1)
	sub	a0, a1, a0
	ret
	func_end compar_binsearch


	# a0: vector
	# a1: destination pointer
	func_begin count_freq
count_freq:
	lw	t0, (a0)
	li	t1, 1
loop_count_freq:
	inc	a0, 4
	lw	t2, (a0)
	bne	t2, t0, loop_count_freq_end
	inc	t1
	j	loop_count_freq
loop_count_freq_end:
	sw	t0, NUMBER(a1)
	sw	t1, SCORE(a1)
	ret
	func_end count_freq
