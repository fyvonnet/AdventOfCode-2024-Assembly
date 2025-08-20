	.include "macros.inc"
	.include "memory.inc"

	.globl	_start


	.set	CONNECT_OPER,	 0
	.set	CONNECT_RD,	 4
	.set	CONNECT_RS1,	 8
	.set	CONNECT_RS2,	12

	.set	AND,		 0
	.set	OR,		 8
	.set	XOR,		16


	.section .rodata
	.balign	8
functions:
	.dword run_and, run_or, run_xor

filename:
	.string	"inputs/day24"
ansfmt:	.string	"Part %d answer: %d\n"
wirefmt:.string "%s: %d\n"


	.bss
	.balign 8
	.set	CHUNKS_COUNT, 1024*1024
	.set	CHUNKS_SIZE, 64
pool:	.zero	8 + (CHUNKS_COUNT * CHUNKS_SIZE)
	

	.text
	.balign 8

	func_begin _start
_start:
	la	a0, filename
	call	map_input_file
	mv	s10, a0
	add	s11, a0, a1

	la	a0, pool
	li	a1, CHUNKS_COUNT
	li	a2, CHUNKS_SIZE
	call	pool_init
	
	la	a0, compar_wires
	la	a1, pool
	call	redblacktree_init
	mv	s0, a0

loop_read_wires:

	mv	a0, s10
	call	parse_wire
	slli	s1, a1, 8
	inc	a0, 2
	call	parse_integer
	or	a1, s1, a1
	addi	s10, a0, 1

	mv	a0, s0
	call	redblacktree_insert

	lb	t0, (s10)
	li	t1, '\n'
	bne	t0, t1, loop_read_wires

	inc	s10

	clr	s2
	mv	a0, s10
loop_read_connections:
	inc	s2
	dec	sp, 16
	mv	a1, sp
	call	parse_connection
	blt	a0, s11, loop_read_connections
	mv	s1, sp

	mv	a0, s1
	mv	a1, s2
	li	a2, 16
	la	a3, compar_connections
	call	quicksort

	# point at the last connexion
	addi	t0, s2, -1
	slli	t0, t0, 4
	add	s3, s1, t0

	clr	s4
	li	t1, 'z'
loop_find_first_z:
	lw	t0, CONNECT_RD(s3)
	srli	t0, t0, 16
	bne	t0, t1, loop_find_first_z_end
	dec	s3, 16
	inc	s4
	j	loop_find_first_z
loop_find_first_z_end:
	inc	s3, 16

	clr	s5
	li	s6, 1
loop_build_result:
	mv	a0, s0
	mv	a1, s1
	mv	a2, s2
	lw	a3, CONNECT_RD(s3)
	call	get_wire
	mul	t0, s6, a0
	or	s5, s5, t0
	inc	s3, 16
	dec	s4
	slli	s6, s6, 1
	bnez	s4, loop_build_result

	la	a0, ansfmt
	li	a1, 1
	mv	a2, s5
	call	printf

	exit
	func_end _start



	# a0: wires
	# a1: connections
	# a2: connections count
	# a3: wire
	func_begin get_wire
get_wire:
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

	mv	s0, a0
	mv	s1, a1
	mv	s2, a2
	mv	s3, a3

	mv	a0, s0
	slli	a1, s3, 8
	call	redblacktree_search
	bnez	a0, wire_found

	sw	s3, CONNECT_RD(sp)

	mv	a0, s1
	mv	a1, s2
	li	a2, 16
	la	a3, compar_connections
	mv	a4, sp
	call	binsearch
	mv	s4, a0

	mv	a0, s0
	mv	a1, s1
	mv	a2, s2
	lw	a3, CONNECT_RS1(s4)
	call	get_wire
	mv	s5, a0

	mv	a0, s0
	mv	a1, s1
	mv	a2, s2
	lw	a3, CONNECT_RS2(s4)
	call	get_wire

	lw	t0, CONNECT_OPER(s4)
	la	t1, functions
	add	t0, t0, t1
	ld	t0, (t0)
	jr	t0

run_and:
	and	a0, a0, s5
	j	run_next
run_or:
	or	a0, a0, s5
	j	run_next
run_xor:
	xor	a0, a0, s5

run_next:
	slli	a1, s3, 8
	add	a1, a1, a0
	mv	s5, a0
	mv	a0, s0
	call	redblacktree_insert

	mv	a0, s5
	j	get_wire_ret
wire_found:
	andi	a0, a0, 0xFF

get_wire_ret:
	ld	ra, 16(sp)
	ld	s0, 24(sp)
	ld	s1, 32(sp)
	ld	s2, 40(sp)
	ld	s3, 48(sp)
	ld	s4, 56(sp)
	ld	s5, 64(sp)
	inc	sp, 80
	ret
	func_end get_wire



	# a0: input pointer
	# a1: destination pointer
	func_begin parse_connection
parse_connection:
	dec	sp, 16
	sd	ra,  0(sp)
	sd	s0,  8(sp)

	mv	s0, a1
	call	parse_wire
	sw	a1, CONNECT_RS1(s0)
	inc	a0

	lb	t0, (a0)
	li	t1, 'A'
	beq	t0, t1, OPER_AND
	li	t1, 'O'
	beq	t0, t1, OPER_OR
	li	t1, 'X'
	beq	t0, t1, OPER_XOR

	# should not reach here
	exit	1

OPER_AND:
	li	t0, AND
	inc	a0, 4
	j	parse_connection_next

OPER_OR:
	li	t0, OR
	inc	a0, 3
	j	parse_connection_next

OPER_XOR:
	li	t0, XOR
	inc	a0, 4

parse_connection_next:
	sw	t0, CONNECT_OPER(s0)

	call	parse_wire
	inc	a0, 4
	sw	a1, CONNECT_RS2(s0)

	call	parse_wire
	inc	a0
	sw	a1, CONNECT_RD(s0)

	ld	ra,  0(sp)
	ld	s0,  8(sp)
	inc	sp, 16
	ret
	func_end parse_connection



	func_begin parse_wire
parse_wire:
	clr	a1
	li	t3, 3
loop_parse_wire:
	slli	a1, a1, 8
	lb	t0, (a0)
	or	a1, a1, t0
	inc	a0
	dec	t3
	bnez	t3, loop_parse_wire
	ret
	func_end parse_wire



	func_begin compar_connections
compar_connections:
	lw	t0, CONNECT_RD(a0)
	lw	t1, CONNECT_RD(a1)
	sub	a0, t0, t1
	ret
	func_end compar_connections



	func_begin compar_wires
compar_wires:
	srli	t0, a0, 8
	srli	t1, a1, 8
	sub	a0, t0, t1
	ret
	func_end compar_wires



