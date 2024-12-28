	.include "macros.inc"
	.include "memory.inc"

	.globl	_start


	.set	COMPUTER_LINKS,	 0
	.set	COMPUTER_NAME, 	 8


	.section .rodata
filename:
	.string	"inputs/day23"
ansfmt:	.string	"Part %d answer: %d\n"


	.bss
	.balign 8
	.set	ARENA_SIZE, 1024*1024
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

	la	a0, arena
	li	a1, ARENA_SIZE
	call	arena_init

	la	a0, compar_name
	la	a1, alloc
	la	a2, free
	call	redblacktree_init
	mv	s0, a0

loop_read_connections:
	mv	a0, s10
	call	parse_connection
	mv	s10, a0

	mv	s8, a1
	mv	s9, a2

	mv	a0, s0
	mv	a1, s8
	mv	a2, s9
	call	insert_connection

	mv	a0, s0
	mv	a1, s9
	mv	a2, s8
	call	insert_connection

	blt	s10, s11, loop_read_connections

	la	a0, compar_direct
	la	a1, alloc
	la	a2, empty_function
	call	redblacktree_init
	mv	s1, a0

	mv	a0, s0
	la	a1, get_t_computers
	mv	a2, s1
	call	redblacktree_inorder

	mv	a0, s1
	call	redblacktree_count_nodes
	inc	a0
	slli	a0, a0, 4
	sub	sp, sp, s0
	li	t0, 0xF
	not	t0, t0
	and	sp, sp, t0
	mv	s2, sp
	mv	s9, s2
	
	
loop_copy_tcomps:
	mv	a0, s1
	call	redblacktree_pop_leftmost
	beqz	a0, loop_copy_tcomps_end
	sw	a0, (s9)
	inc	s9, 4
	j	loop_copy_tcomps
loop_copy_tcomps_end:
	sw	x0, (s9)


loop:
	lw	a0, (s2)
	beqz	a0, loop_end
	mv	a1, a0
	li	a2, 3
	mv	a3, s0
	mv	a4, s1
	clr	a5
	call	find_sets
	inc	s2, 4
	j	loop
loop_end:

	mv	a0, s1
	call	redblacktree_count_nodes

	mv	a2, a0
	li	a1, 1
	la	a0, ansfmt
	call	printf

	exit
	func_end _start



	# a0: current node
	# a1: target node
	# a2: countdown
	# a3: connections graph
	# a4: sets set
	# a5: computers
	func_begin find_sets
find_sets:
	dec	sp, 80
	sd	x0,  0(sp)
	sd	x0,  8(sp)
	sd	ra, 16(sp)
	sd	s0, 24(sp)
	sd	s1, 32(sp)
	sd	s2, 40(sp)
	sd	s3, 48(sp)
	sd	s4, 56(sp)
	sd	s5, 64(sp)
	sd	s6, 72(sp)

	mv	s0, a0
	mv	s1, a1
	mv	s2, a2
	mv	s3, a3
	mv	s4, a4
	mv	s5, a5

	bnez	a2, find_sets_cont
	clr	t6
	bne	a1, a0, find_sets_ret
	li	t6, 1
	dec	sp, 8
	dec	sp, 2
	sh	zero, (sp)
	.rept	3
	dec	sp, 2
	li	t1, 0xFFFF
	and	t0, s5, t1
	sh	t0, (sp)
	srli	s5, s5, 16
	.endr
	mv	a0, sp
	li	a1, 3
	li	a2, 2
	la	a3, compar_sort
	call	quicksort

	mv	a0, s4
	ld	a1, (sp)
	call	redblacktree_insert

	inc	sp, 16
	j	find_sets_ret
find_sets_cont:

	sw	s0, COMPUTER_NAME(sp)
	mv	a0, a3
	mv	a1, sp
	call	redblacktree_search
	ld	s0, COMPUTER_LINKS(a0)
	
	clr	s6
loop_find_sets:
	lw	a0, COMPUTER_NAME(s0)
	mv	a1, s1
	addi	a2, s2, -1
	mv	a3, s3
	mv	a4, s4
	slli	a5, s5, 16
	or	a5, a5, a0
	call	find_sets
	add	s6, s6, a0
	ld	s0, COMPUTER_LINKS(s0)
	bnez	s0, loop_find_sets
	mv	t6, s6
	
find_sets_ret:
	mv	a0, t6
	#ld	x0,  0(sp)
	#ld	x0,  8(sp)
	ld	ra, 16(sp)
	ld	s0, 24(sp)
	ld	s1, 32(sp)
	ld	s2, 40(sp)
	ld	s3, 48(sp)
	ld	s4, 56(sp)
	ld	s5, 64(sp)
	ld	s6, 72(sp)
	inc	sp, 80
	ret
	func_end find_sets



	func_begin insert_connection
insert_connection:
	dec	sp, 32
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s1, 16(sp)
	sd	s2, 24(sp)

	mv	s0, a0
	mv	s1, a1
	mv	s2, a2

	la	a0, 16
	call	alloc
	sw	s1, COMPUTER_NAME(a0)
	sd	x0, COMPUTER_LINKS(a0)

	mv	a1, a0
	mv	a0, s0
	call	redblacktree_insert_or_free

	mv	s0, a0

	la	a0, 16
	call	alloc
	
	ld	t0, COMPUTER_LINKS(s0)
	sd	a0, COMPUTER_LINKS(s0)
	sw	s2, COMPUTER_NAME(a0)
	sd	t0, COMPUTER_LINKS(a0)

	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	ld	s2, 24(sp)
	inc	sp, 32
	ret
	func_end insert_connection


	
	func_begin parse_connection
parse_connection:
	dec	sp, 16
	sd	ra,  0(sp)
	sd	s0,  8(sp)

	call	parse_label
	mv	s0, a1

	inc	a0
	call	parse_label

	mv	a2, a1
	inc	a0
	mv	a1, s0

	ld	ra,  0(sp)
	ld	s0,  8(sp)
	inc	sp, 16
	ret
	func_end parse_connection



	func_begin parse_label
parse_label:
	lb	t0, 0(a0)
	slli	t0, t0, 8
	lb	t1, 1(a0)
	or	a1, t0, t1
	inc	a0, 2
	ret
	func_end parse_label
	


	func_begin compar_name
compar_name:
	lw	t0, COMPUTER_NAME(a0)
	lw	t1, COMPUTER_NAME(a1)
	sub	a0, t0, t1
	ret
	func_end compar_name



	func_begin compar_direct
compar_direct:
	sub	a0, a0, a1
	ret
	func_end compar_direct



	func_begin get_t_computers
get_t_computers:
	dec	sp, 16
	sd	ra,  0(sp)

	mv	t2, a1

	lw	a1, COMPUTER_NAME(a0)
	srli	t0, a1, 8
	li	t1, 't'
	bne	t0, t1, get_t_computers_end

	mv	a0, t2
	call	redblacktree_insert

get_t_computers_end:
	ld	ra,  0(sp)
	inc	sp, 16
	ret
	func_end get_t_computers



	func_begin compar_sort
compar_sort:
	lh	t0, (a0)
	lh	t1, (a1)
	sub	a0, t0, t1
	ret
	func_end compar_sort



