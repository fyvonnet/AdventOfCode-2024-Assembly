	.include "macros.inc"
	.include "memory.inc"

	.set	NUMBER,	0
	.set	SCORE,	4

	.set	CHUNKS_SIZE,	64
	.set	CHUNKS_COUNT,	2048

	.section .rodata
file_name:
	.string	"inputs/day01"
ansfmt:
	.string "Part %d answer: %d\n"

	.bss
	.balign 8
pool:   .space  8 + (CHUNKS_SIZE * CHUNKS_COUNT)


	.text
	.balign 8

	.globl _start
	func_begin _start
_start:

	la	a0, file_name
	call	map_input_file
	mv	s10, a0
	add	s11, a0, a1


	# allocate vectors

	li 	t0, 4096
	sub	sp, sp, t0
	mv	s0, sp
	mv	s3, sp

	li 	t0, 4096
	sub	sp, sp, t0
	mv	s1, sp
	mv	s4, sp

	
	# read input in the stack

	clr	s2
	mv	a0, s10
loop_read:
	call	parse_integer
	sw	a1, 0(s3)
	call	skip_to_digit
	call	parse_integer
	sw	a1, 0(s4)
	inc	s2
	inc	a0			# skip \n
	inc	s3, 4
	inc	s4, 4
	blt	a0, s11, loop_read


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

	la	a0, pool
	li      a1, CHUNKS_COUNT
	li      a2, CHUNKS_SIZE
	call    pool_init

	la	a0, compar_tree
	la	a1, pool
	call	redblacktree_init
	mv	s3, a0


	# compute similarities 

	mv	s11, s1
	mv	s9, s2
loop_similarity:
	la	a0, pool
	call	pool_alloc
	lw	t0, (s11)
	sw	t0, NUMBER(a0)
	sw	x0, SCORE(a0)
	mv	a1, a0
	mv	a0, s3
	call	redblacktree_insert_or_free
	lw	t0, SCORE(a0)
	inc	t0
	sw	t0, SCORE(a0)
	inc	s11, 4
	dec	s9
	bnez	s9, loop_similarity


	# compute sum of similarities

	mv	s10, s0
	clr	s4
	dec	sp, 16
	mv	s5, sp
	mv	s6, s2
loop_compute2:
	lw	s7, (s10)
	sw	s7, NUMBER(s5)
	mv	a0, s3
	mv	a1, s5
	call	redblacktree_search
	beqz	a0, loop_compute2_skip
	lw	t0, SCORE(a0)
	mul	t0, t0, s7
	add	s4, s4, t0
loop_compute2_skip:
	inc	s10, 4
	dec	s6
	bnez	s6, loop_compute2
	
	
	la	a0, ansfmt
	li	a1, 2
	mv	a2, s4
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


	func_begin compar_tree
compar_tree:
	lw	a0, NUMBER(a0)
	lw	a1, NUMBER(a1)
	sub	a0, a0, a1
	ret
	func_end compar_tree


