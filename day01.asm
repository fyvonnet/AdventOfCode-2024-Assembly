	.include "macros.inc"
	.include "memory.inc"

	.set	NUMBER,	0
	.set	SCORE,	4

	.section .rodata
file_name:
	.string	"inputs/day01"
ansfmt:
	.string "Part %d answer: %d\n"

	.bss
	.balign 8
	.set 	ARENA_SIZE,	64*1024
arena:
	.space	ARENA_SIZE


	.text
	.balign 8

	create_alloc_func 	alloc, arena, arena
	create_free_func 	free, arena, arena

	.globl _start
	func_begin _start
_start:
	la	a0, arena
	li	a1, ARENA_SIZE
	call	arena_init

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


	# allocate vectors

	li	t0, 4
	mul	s3, s2, t0

	mv	a0, s3
	call	alloc
	mv	s0, a0

	mv	a0, s3
	call	alloc
	mv	s1, a0

	
	# copy input from stack to vectors

	mv	s10, s0
	mv	s11, s1
	mv	t2,  s2
loop_copy:
	lw	t0, 0(sp)
	lw	t1, 4(sp)
	sw	t0, (s10)
	sw	t1, (s11)
	inc	s10, 4
	inc	s11, 4
	dec	t2
	inc	sp, 8
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

	la	a0, compar_tree
	la	a1, alloc
	la	a2, free
	call	redblacktree_init
	mv	s3, a0


	# compute similarities 

	mv	s11, s1
	mv	s9, s2
loop_similarity:
	li	a0, 8
	call	alloc
	mv	s4, a0
	lw	t0, (s11)
	li	t1, 1
	sw	t0, NUMBER(s4)
	sw	t1, SCORE(s4)
	mv	a0, s3
	mv	a1, s4
	call	redblacktree_insert
	beqz	a0, loop_similarity_next
	lw	t0, SCORE(a0)
	inc	t0
	sw	t0, SCORE(a0)
	mv	a0, s4
	call	free
loop_similarity_next:
	inc	s11, 4
	dec	s9
	bnez	s9, loop_similarity


	# compute sum of similarities

	mv	s10, s0
	clr	s4
	la	a0, 8
	call	alloc
	mv	s5, a0
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


