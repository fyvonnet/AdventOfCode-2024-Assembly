	.include "macros.inc"
	.include "memory.inc"

	.globl	_start


	.set	CACHE_NUMBER,	 0
	.set	CACHE_REMAIN,	 8
	.set	CACHE_COUNT,	16


	.section .rodata
filename:
	.string	"inputs/day11"
ansfmt:	.string	"Part %d: %d\n"



	.bss
	.balign 8
	.set	ARENA_SIZE,	16*1024*1024
arena:	.space	ARENA_SIZE


	.text
	.balign 8


	create_alloc_func alloc, arena, arena
	create_free_func free, arena, arena


	func_begin _start
_start:
	la	a0, arena
	li	a1, ARENA_SIZE
	call	arena_init

	la	a0, compar_cache
	la	a1, alloc
	la	a2, free
	call	redblacktree_init
	mv	s2, a0

	dec	sp, 16
	li	t0, -1
	sd	t0, (sp)

	la	a0, filename
	call	map_input_file
loop_read_input:
	dec	sp, 16
	call	parse_integer
	sd	a1, (sp)
	li	t0, '\n'
	lb	t1, (a0)
	beq	t1, t0, loop_read_input_end
	inc	a0
	j	loop_read_input
loop_read_input_end:

	mv	a0, sp
	li	a1, 25
	mv	a2, s2
	call	count_stones

	mv	a2, a0
	li	a1, 1
	la	a0, ansfmt
	call	printf
	
	mv	a0, sp
	li	a1, 75
	mv	a2, s2
	call	count_stones

	mv	a2, a0
	li	a1, 2
	la	a0, ansfmt
	call	printf
	
	exit
	func_end _start



	# a0: numbers
	# a1: blinks count
	# a2: cache
	func_begin count_stones
count_stones:
	dec	sp, 48
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd 	s1, 16(sp)
	sd	s2, 24(sp)
	sd	s3, 32(sp)

	mv	s0, a0
	mv	s1, a1
	mv	s2, a2
	clr	s3

loop_count_stones:
	ld	a0, (s0)
	bltz	a0, loop_count_stones_end
	mv	a1, s1
	mv	a2, s2
	call	blink
	add	s3, s3, a0
	inc	s0, 16
	j	loop_count_stones	
loop_count_stones_end:
	mv	a0, s3
	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld 	s1, 16(sp)
	ld	s2, 24(sp)
	ld	s3, 32(sp)
	inc	sp, 48
	ret
	func_end count_stones


	# a0: cache
	# a1: number
	# a2: remain
	func_begin check_cache
check_cache:
	dec	sp, 64
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s1, 16(sp)
	sd	s2, 24(sp)

	mv	s0, a0
	mv	s1, a1
	mv	s2, a2

	li	a0, 24
	call	alloc
	sd	s1, CACHE_NUMBER(a0)
	sd	s2, CACHE_REMAIN(a0)
	mv	s1, a0

	mv	a0, s0
	mv	a1, s1
	call	redblacktree_insert
	beqz	a0, cache_not_found
cache_found:
	mv	s2, a0
	mv	a0, s1
	call	free
	li	a0, 1
	ld	a1, CACHE_COUNT(s2)
	j	cache_ret
cache_not_found:
	li	a0, 0
	addi	a1, s1, CACHE_COUNT
cache_ret:
	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	ld	s2, 24(sp)
	inc	sp, 64
	ret
	func_end check_cache


	# a0: numbers
	# a1: remaining blinks
	# a2: cache
	func_begin blink
blink:
	dec	sp, 64
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s1, 16(sp)
	sd	s2, 24(sp)
	sd	s3, 32(sp)
	sd	s4, 40(sp)
	sd	s5, 48(sp)

	clr	s4
	bltz	a0, blink_ret
	li	s4, 1
	beqz	a1, blink_ret

	mv	s0, a0
	mv	s1, a1
	mv	s2, a2

	mv	a0, s2
	mv	a1, s0
	mv	a2, s1
	call	check_cache
	mv	s4, a1
	bnez	a0, blink_ret
	mv	s5, a1

	clr	s4
	dec	s1

	mv	a0, s0
	call	evolve_number
	mv	s3, a1

	mv	a1, s1
	mv	a2, s2
	call	blink
	add	s4, s4, a0

	mv	a0, s3
	mv	a1, s1
	mv	a2, s2
	call	blink
	add	s4, s4, a0

	sd	s4, (s5)
blink_ret:
	mv	a0, s4

	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	ld	s2, 24(sp)
	ld	s3, 32(sp)
	ld	s4, 40(sp)
	ld	s5, 48(sp)
	inc	sp, 64
	ret
	li	a0, 1
	ret
	clr	a0
	ret
	func_end blink
	


	# a0: number
	func_begin evolve_number
evolve_number:
	dec	sp, 32
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	beqz	a0, evolve_zero
	mv	s0, a0
	call	count_digits
	andi	t0, a0, 1
	beqz	t0, even_number
	la	a1, -1
	li	t0, 2024
	mul	a0, s0, t0
	j	evolve_number_ret
even_number:
	mv	a1, a0
	mv	a0, s0
	call	cut_number
	j	evolve_number_ret
evolve_zero:
	li	a0,  1
	li	a1, -1
evolve_number_ret:
	ld	ra,  0(sp)
	ld	s0,  8(sp)
	inc	sp, 32
	ret
	func_end evolve_number


	# a0: number
	# a1: digits count
	func_begin cut_number
cut_number:
	dec	sp, 32
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s1, 16(sp)

	mv	s0, a0

	li	a0, 10
	srli	a1, a1, 1
	call	power_of

	div	t0, s0, a0
	rem	t1, s0, a0

	mv	a0, t0
	mv	a1, t1

	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	inc	sp, 32
	ret
	func_end cut_number


	func_begin count_digits
count_digits:
	clr	t0
	li	t1,10
loop_count_digits:
	beqz	a0, count_digits_ret
	inc	t0
	div	a0, a0, t1
	j	loop_count_digits
count_digits_ret:
	mv	a0, t0
	ret
	func_end count_digits


	func_begin compar_cache
compar_cache:
	ld	t0, CACHE_NUMBER(a0)
	ld	t1, CACHE_NUMBER(a1)
	sub	t0, t0, t1
	bnez	t0, compar_cache_ret
	ld	t0, CACHE_REMAIN(a0)
	ld	t1, CACHE_REMAIN(a1)
	sub	t0, t0, t1
compar_cache_ret:
	mv	a0, t0
	ret
	func_end compar_cache


