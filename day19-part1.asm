	.include "macros.inc"
	.include "memory.inc"

	.globl	_start


	.set	CHUNKS_SIZE,	  40
	.set	CHUNKS_COUNT,	1024


	.section .rodata
filename:
	.string	"inputs/day19"
ansfmt:	.string	"Part %d answer: %d\n"

	.bss
	.balign 8
pool:	.space	8 + (CHUNKS_SIZE * CHUNKS_COUNT)

	.text
	.balign 8

	create_alloc_func alloc, pool, pool
	create_free_func free, pool, pool

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
	
	li	s7, '\n'
	mv	s8, s0
loop_parse_patterns:
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
	
	clr	s2
loop:
	mv	a0, s0
	ld	a1, (s1)
	inc	s1, 8
	beqz	a1, loop_end
	call	is_possible
	beqz	a0, loop
	inc	s2
	j	loop
loop_end:

	la	a0, ansfmt
	li	a1, 1
	mv	a2, s2
	call	printf

	exit
	func_end _start


	# a0: patterns
	# a1: design
	func_begin is_possible
is_possible:
	dec	sp, 64
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s1, 16(sp)
	sd	s2, 24(sp)
	sd	s3, 32(sp)
	sd	s5, 40(sp)
	sd	s6, 48(sp)

	mv	s0, a0
	mv	s1, a1

	la	a0, pool
	la	a1, CHUNKS_COUNT
	la	a2, CHUNKS_SIZE
	call	pool_init

	la	a0, compar
	la	a1, alloc
	la	a2, free
	call	redblacktree_init
	mv	s6, a0

	mv	a0, s6
	mv	a1, s1
	call	redblacktree_insert

loop_is_possible:
	mv	a0, s6
	call	redblacktree_pop_leftmost
	beqz	a0, not_possible
	mv	s2, a0

	#la	a0, fmt
	#mv	a1, s2
	#call	printf

	lb	t0, (s2)
	beqz	t0, possible
	mv	s3, s0
loop_push:
	ld	s4, (s3)
	inc	s3, 8
	beqz	s4, loop_push_end
	mv	a0, s4
	mv	a1, s2
	call	is_prefix
	beqz	a0, loop_push
	add	s5, s2, a0
	mv	a0, s6
	mv	a1, s5
	call	redblacktree_insert
	j	loop_push
loop_push_end:
	j	loop_is_possible
possible:
	set	a0
	j	loop_push_ret
not_possible:
	clr	a0
loop_push_ret:
	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	ld	s2, 24(sp)
	ld	s3, 32(sp)
	ld	s5, 40(sp)
	ld	s6, 48(sp)
	inc	sp, 64
	ret
	func_end is_possible
	

	
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



	# a0: prefix
	# a1: string
	func_begin is_prefix
is_prefix:
	clr	t2
	clr	t6
loop_is_prefix:
	lb	t0, (a0)
	beqz	t0, is_prefix_succ
	inc	t2
	lb	t1, (a1)
	beqz	t1, is_prefix_ret
	bne	t0, t1, is_prefix_ret
	inc	a0
	inc	a1
	j	loop_is_prefix
is_prefix_succ:
	mv	t6, t2
is_prefix_ret:
	mv	a0, t6
	ret
	func_end is_prefix


	func_begin compar
compar:
	sub	a0, a1, a0
	ret
	func_end compar

