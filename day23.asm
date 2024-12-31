	.include "macros.inc"
	.include "memory.inc"

	.globl	_start


	.set	COMPUTER_LINKS,	 0
	.set	COMPUTER_NAME, 	 8


	.section .rodata
filename:
	.string	"inputs/day23"
ansfmt:	.string	"Part %d answer: %d\n"
p2fmt:	.string	"Part 2 answer: "
endfmt:	.string	"\008 \n"


	.bss
	.balign 8
	.set	ARENA_SIZE, 256*1024
arena:	.space	ARENA_SIZE
	.set	CHUNKS_COUNT,	256*1024
	.set	CHUNKS_SIZE,	  40
pool:	.space	8 + (CHUNKS_SIZE * CHUNKS_COUNT)

	.text
	.balign 8

	create_alloc_func graph_alloc, arena, arena
	create_free_func graph_free, arena, arena

	create_alloc_func set_alloc, pool, pool
	create_free_func set_free, pool, pool

	func_begin _start
_start:
	la	a0, filename
	call	map_input_file
	mv	s10, a0
	add	s11, a0, a1

	la	a0, arena
	li	a1, ARENA_SIZE
	call	arena_init

	la	a0, pool
	li	a1, CHUNKS_COUNT
	li	a2, CHUNKS_SIZE
	call	pool_init

	la	a0, compar_name
	la	a1, graph_alloc
	la	a2, graph_free
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

	call	create_empty_set
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
	sw	zero, (s9)

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

	mv	a0, s1
	la	a1, empty_function
	call	redblacktree_kill

	mv	s11, s0

	# initial largest clique (null set)
	call	create_empty_set
	mv	s10, a0
	clr	s9

	call	create_empty_set
	mv	s0, a0

	call	create_empty_set
	mv	s1, a0
	mv	a0, s11
	la	a1, init_set
	mv	a2, s1
	call	redblacktree_inorder

	call	create_empty_set
	mv	s2, a0

	mv	a0, s0
	mv	a1, s1
	mv	a2, s2
	call	bron_kerbosh

	la	a0, p2fmt
	call	printf
	mv	a0, s10
	la	a1, print_vertex
	clr	a2
	call	redblacktree_inorder
	la	a0, endfmt
	call	printf

	exit
	func_end _start



	# a0: computer
	# a1: set
	func_begin init_set
init_set:
	dec	sp, 16
	sd	ra,  0(sp)
	lw	t0, COMPUTER_NAME(a0)
	mv	a0, a1
	mv	a1, t0
	call	redblacktree_insert
	ld	ra,  0(sp)
	inc	sp, 16
	ret
	func_end init_set



	# a0: vertex
	# a1: pointer
	func_begin store_to_stack
store_to_stack:
	ld	t0, (a1)
	sw	a0, (t0)
	inc	t0, 16
	sd	t0, (a1)
	ret
	func_end store_to_stack



	# https://iq.opengenus.org/bron-kerbosch-algorithm/
	# a0: R set
	# a1: P set
	# a2: X set
	func_begin bron_kerbosh
bron_kerbosh:
	dec	sp, 80
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s1, 16(sp)
	sd	s2, 24(sp)
	sd	s3, 32(sp)
	sd	s4, 40(sp)
	sd	s5, 48(sp)
	sd	s6, 56(sp)
	sd	s7, 64(sp)
	sd	s8, 72(sp)

	mv	s0, a0
	mv	s1, a1
	mv	s2, a2

	mv	a0, s1
	call	redblacktree_is_empty
	beqz	a0, bron_kerbosh_cont

	mv	a0, s2
	call	redblacktree_is_empty
	beqz	a0, bron_kerbosh_cont

	# clique found
	mv	a0, s0
	call	redblacktree_count_nodes
	ble	a0, s9, bron_kerbosh_ret

	# largest clique found
	mv	s9, a0
	mv	a0, s10
	la	a1, empty_function
	call	redblacktree_kill
	mv	a0, s0
	call	create_set_copy
	mv	s10, a0

	j	bron_kerbosh_ret

bron_kerbosh_cont:
	# allocate stack space for P vertices
	mv	a0, s1
	call	redblacktree_count_nodes
	mv	s3, a0
	li	t1, 16
	mul	t0, s3, t1
	sub	sp, sp, t0
	mv	t0, sp
	dec	sp, 16
	sd	t0, (sp)

	mv	a0, s1
	la	a1, store_to_stack
	mv	a2, sp
	call	redblacktree_inorder

	inc	sp, 16

loop_bron_kerbosh:
	beqz	s3, loop_bron_kerbosh_end
	lw	s4, (sp)

	# load vertex neighbors list
	sw	s4, COMPUTER_NAME(sp)
	mv	a0, s11
	mv	a1, sp
	call	redblacktree_search
	ld	s5, COMPUTER_LINKS(a0)

	# new R (R union {v})
	mv	a0, s0
	call	create_set_copy
	mv	s6, a0
	mv	a1, s4
	call	redblacktree_insert

	# new P (P intersection N(v))
	mv	a0, s1
	mv	a1, s5
	call	create_intersection
	mv	s7, a0

	# new X (X intersection N(v))
	mv	a0, s2
	mv	a1, s5
	call	create_intersection
	mv	s8, a0

	mv	a0, s6
	mv	a1, s7
	mv	a2, s8
	call	bron_kerbosh

	mv	a0, s6
	la	a1, empty_function
	call	redblacktree_kill

	mv	a0, s7
	la	a1, empty_function
	call	redblacktree_kill

	mv	a0, s8
	la	a1, empty_function
	call	redblacktree_kill

	mv	a0, s1
	mv	a1, s4
	call	redblacktree_delete

	mv	a0, s2
	mv	a1, s4
	call	redblacktree_insert

	inc	sp, 16
	dec	s3
	j	loop_bron_kerbosh
loop_bron_kerbosh_end:
	nop
bron_kerbosh_ret:
	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	ld	s2, 24(sp)
	ld	s3, 32(sp)
	ld	s4, 40(sp)
	ld	s5, 48(sp)
	ld	s6, 56(sp)
	ld	s7, 64(sp)
	ld	s8, 72(sp)
	inc	sp, 80
	ret
	func_end bron_kerbosh



	# a0: set
	# a1: list
	func_begin create_intersection
create_intersection:
	dec	sp, 48
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s1, 16(sp)
	sd	s2, 24(sp)
	sd	s3, 32(sp)

	mv	s0, a0
	mv	s1, a1
	
	call	create_empty_set
	mv	s2, a0

loop_create_intersection:
	beqz	s1, loop_create_intersection_end
	ld	s3, COMPUTER_NAME(s1)
	mv	a0, s0
	mv	a1, s3
	call	redblacktree_search
	beqz	a0, skip_insert
	mv	a0, s2
	mv	a1, s3
	call	redblacktree_insert
skip_insert:
	ld	s1, COMPUTER_LINKS(s1)
	j	loop_create_intersection
loop_create_intersection_end:

	mv	a0, s2
	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	ld	s2, 24(sp)
	ld	s3, 32(sp)
	inc	sp, 48
	ret
	func_end create_intersection



	func_begin create_empty_set
create_empty_set:
	dec	sp, 16
	sd	ra,  (sp)
	la	a0, compar_direct
	la	a1, set_alloc
	la	a2, set_free
	call	redblacktree_init
	ld	ra,  (sp)
	inc	sp, 16
	ret
	func_end create_empty_set



	# a0: vertex
	# a1: destination set
	func_begin insert_vertex
insert_vertex:
	dec	sp, 16
	sd	ra,  0(sp)

	mv	t0, a0
	mv	a0, a1
	mv	a1, t0
	call	redblacktree_insert
	
	ld	ra,  0(sp)
	inc	sp, 16
	ret
	func_end insert_vertex



	# a0: set to be copied
	func_begin create_set_copy
create_set_copy:
	dec	sp, 32
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s1, 16(sp)

	mv	s0, a0

	call	create_empty_set
	mv	s1, a0

	mv	a0, s0
	la	a1, insert_vertex
	mv	a2, s1
	call	redblacktree_inorder

	mv	a0, s1

	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	inc	sp, 32
	ret
	func_end create_set_copy



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
	call	graph_alloc
	sw	s1, COMPUTER_NAME(a0)
	sd	x0, COMPUTER_LINKS(a0)

	mv	a1, a0
	mv	a0, s0
	call	redblacktree_insert_or_free

	mv	s0, a0

	la	a0, 16
	call	graph_alloc
	
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



	func_begin print_vertex
print_vertex:
	dec	sp, 16
	sd	ra,  0(sp)
	sd	s0,  8(sp)

	mv	s0, a0

	srli	a0, s0, 8
	call	putc

	andi	a0, s0, 0xFF
	call	putc

	la	a0, ','
	call	putc

	ld	ra,  0(sp)
	ld	s0,  8(sp)
	inc	sp, 16
	ret
	func_end print_vertex



