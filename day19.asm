	.include "macros.inc"
	.include "memory.inc"

	.globl	_start


	.set	CACHE_STRING,	   0
	.set	CACHE_COUNT,	   8
	.set	CACHE_SIZE,	  16


	.section .rodata
filename:
	.string	"inputs/day19"
ansfmt:	.string	"Part %d answer: %d\n"

	.bss
	.balign 8
	.set	ARENA_SIZE, 4*1024
arena:	.space	ARENA_SIZE

	.text
	.balign 8

	create_alloc_func alloc, arena, arena
	create_free_func free, arena, arena

	func_begin _start
_start:

	la	a0, filename
	call	map_input_file
	mv	s10, a0
	add	s11, a0, a1

	# allocate space for strings
	sub	sp, sp, a1
	li	t0, 0b1111
	not	t0, t0
	and	sp, sp, t0
	mv	s9, sp

	# allocate space for 512 pattern pointers
	li	t0, 8*512
	sub	sp, sp, t0
	mv	s0, sp
	
	# allocate space for 512 design pointers
	sub	sp, sp, t0
	mv	s1, sp
	
	clr	s6
	li	s7, '\n'
	mv	s8, s0
loop_parse_patterns:
	inc	s6
	mv	a0, s10
	mv	a1, s9
	call	parse_string
	sd	s9, (s8)
	inc	s8, 8
	mv	s10, a0
	mv	s9, a1
	lb	t0, (s10)
	beq	t0, s7, loop_parse_patterns_end
	inc	s10, 2
	j	loop_parse_patterns
loop_parse_patterns_end:
	sd	zero, (s8)
	nop

	inc	s10, 2

	mv	s8, s1
loop_parse_designs:
	mv	a0, s10
	mv	a1, s9
	call	parse_string
	sd	s9, (s8)
	inc	s8, 8
	addi	s10, a0, 1
	mv	s9, a1
	blt	s10, s11, loop_parse_designs
	sd	zero, (s8)

	mv	s10, s0
	mv	s11, s6

	mv	a0, s10
	mv	a1, s11
	li	a2, 8
	la	a3, compar_strings
	call	quicksort

	clr	s2
loop:
	la	a0, arena
	li	a1, ARENA_SIZE
	call	arena_init

	la	a0, compar_tree
	la	a1, alloc
	clr	a2
	call	redblacktree_init
	mv	s9, a0

	ld	a0, (s1)
	inc	s1, 8
	beqz	a0, loop_end
	call	count_ways
	add	s2, s2, a0
	j	loop
loop_end:	
	
	la	a0, ansfmt
	li	a1, 2
	mv	a2, s2
	call	printf

	exit
	func_end _start



	# a0: design
	func_end count_ways
count_ways:
	dec	sp, 80
	sd	x0,  0(sp)
	sd	x0,  8(sp)
	sd	x0, 16(sp)
	sd	sp, 24(sp)
	sd	ra, 32(sp)
	sd	s0, 40(sp)
	sd	s1, 48(sp)
	sd	s2, 56(sp)
	sd	s3, 64(sp)

	mv	s0, a0

	lb	t0, (s0)
	beqz	t0, count_ways_found

	la	a0, CACHE_SIZE
	call	alloc
	mv	s3, a0
	sd	s0, CACHE_STRING(s3)
	mv	a0, s9
	mv	a1, s3
	call	redblacktree_insert

	beqz	a0, cache_fail

	ld	s2, CACHE_COUNT(a0)
	mv	a0, s3
	call	free
	mv	a0, s2
	j	count_ways_ret

cache_fail:

	clr	s1
	clr	s2
loop_search_prefs:

	add	t1, s0, s1
	lb	t2, (t1)
	beqz	t2, loop_search_prefs_end
	add	t1, sp, s1
	sb	t2, (t1)

	mv	a0, s10
	mv	a1, s11
	li	a2, 8
	la	a3, compar_strings
	addi	a4, sp, 24
	call	binsearch
	beqz	a0, loop_search_prefs_next

	addi	t0, s1, 1
	add	a0, s0, t0
	call	count_ways
	add	s2, s2, a0

loop_search_prefs_next:
	inc	s1
	li	t0, 9
	blt	s1, t0, loop_search_prefs
loop_search_prefs_end:
	sd	s2, CACHE_COUNT(s3)
	mv	a0, s2
	j	count_ways_ret
count_ways_found:
	li	a0, 1
count_ways_ret:
	ld	ra, 32(sp)
	ld	s0, 40(sp)
	ld	s1, 48(sp)
	ld	s2, 56(sp)
	ld	s3, 64(sp)
	inc	sp, 80
	ret
	func_end count_ways
	


	# a0: source
	# a1: destination
	func_begin parse_string
parse_string:
	li	t0, 'a'
	li	t1, 'z'
loop_parse_string:
	lb	t2, (a0)
	blt	t2, t0, loop_parse_string_end
	bgt	t2, t1, loop_parse_string_end
	inc	a0
	sb	t2, (a1)
	inc	a1
	j	loop_parse_string
loop_parse_string_end:
	sb	zero, (a1)
	inc	a1
	ret
	func_end parse_string



	func_begin compar_strings
compar_strings:
	dec	sp, 16
	sd	ra,  0(sp)
	ld	a0, (a0)
	ld	a1, (a1)
	call	strcmp
	ld	ra,  0(sp)
	inc	sp, 16
	ret
	func_end compar_strings



	func_begin compar_tree
compar_tree:
	ld	a0, CACHE_STRING(a0)
	ld	a1, CACHE_STRING(a1)
	sub	a0, a0, a1
	ret
	func_end compar_tree




