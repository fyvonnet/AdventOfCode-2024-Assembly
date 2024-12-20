	.include "macros.inc"

	.globl	_start


	.set	STATE_REG_A,	 0
	.set	STATE_REG_B,	 8
	.set	STATE_REG_C,	16
	.set	STATE_IP,	24


	.section .rodata
	.balign 8

opcodes:
	.dword	op_adv
	.dword	op_bxl
	.dword	op_bst
	.dword	op_jnz
	.dword	op_bxc
	.dword	op_out
	.dword	op_bdv
	.dword	op_cdv

filename:
	.string	"inputs/day17"
ansfmt:	.string	"Part %d answer: %d\n"
outfmt:	.string	"%d,"
endfmt:	.byte	8
	.string	" \n"
fmtrega:.string "%d: "


	.text
	.balign 8



	func_begin _start
_start:
	la	a0, filename
	call	map_input_file
	mv	s10, a0
	add	s11, a0, a1

	# allocate space for program state
	dec	sp, 32
	mv	s0, sp

	dec	sp, 32
	addi	s1, sp, 1

	mv	s8, s0
	li	s9, 3
	mv	a0, s10
loop_read_regs:
	inc	a0, 12
	call	parse_integer
	sd	a1, (s8)
	inc	a0
	dec	s9
	inc	s8, 8
	bnez	s9, loop_read_regs
	sd	zero, (s8)
	inc	a0, 10
	mv	s10, a0

	

	li	s7, '\n'
	mv	s8, s1
	clr	s2
loop_read_prog:
	inc	s2
	call	parse_integer
	sb	a1, (s8)
	inc	s8
	lb	t0, (a0)
	inc	a0
	bne	t0, s7, loop_read_prog
	sb	s2, -1(s1)

loop:
	ld	t0, STATE_IP(s0)
	bge	t0, s2, loop_end
	add	s9, t0, s1
	mv	a0, s0
	lb	a1, 1(s9)
	lb	t1, 0(s9)
	slli	t1, t1, 3
	lga	t2, opcodes
	add	t1, t1, t2
	ld	t1, (t1)
	mv	a0, s0
	jalr	ra, t1
	beqz	a0, loop
	ld	t0, STATE_IP(s0)
	inc	t0, 2
	sd	t0, STATE_IP(s0)
	
	j	loop
loop_end:
	la	a0, endfmt
	call	printf


	exit
	func_end _start


	func_begin op_xdv
op_xdv:
	dec	sp, 32
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s1, 16(sp)
	sd	s2, 24(sp)

	mv	s0, a0
	mv	s2, a2

	call	get_combo_value

	ld	t0, STATE_REG_A(s0)
	srl	t0, t0, a0
	sd	t0, (s2)

	set	a0
	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	ld	s2, 24(sp)
	inc	sp, 32
	ret
	func_end op_xdv


	# opcode 0
	func_begin op_adv
op_adv:
	dec	sp, 16
	sd	ra,  0(sp)
	addi	a2, s0, STATE_REG_A
	call	op_xdv
	ld	ra,  0(sp)
	inc	sp, 16
	ret
	func_end op_adv

	# opcode 6
	func_begin op_bdv
op_bdv:
	dec	sp, 16
	sd	ra,  0(sp)
	addi	a2, s0, STATE_REG_B
	call	op_xdv
	ld	ra,  0(sp)
	inc	sp, 16
	ret
	func_end op_bdv

	# opcode 7
	func_begin op_cdv
op_cdv:
	dec	sp, 16
	sd	ra,  0(sp)
	addi	a2, s0, STATE_REG_C
	call	op_xdv
	ld	ra,  0(sp)
	inc	sp, 16
	ret
	func_end op_cdv


	# opcode 1
	func_begin op_bxl
op_bxl:
	ld	t0, STATE_REG_B(a0)
	xor	t0, t0, a1
	sd	t0, STATE_REG_B(a0)

	set	a0
	ret
	func_end op_bxl



	# opcode 2
	func_begin op_bst
op_bst:
	dec	sp, 16
	sd	ra,  0(sp)
	sd	s0,  8(sp)

	mv	s0, a0

	call	get_combo_value
	
	andi	a0, a0, 0b111
	sd	a0, STATE_REG_B(s0)
	li	a0, 1

	ld	ra,  0(sp)
	ld	s0,  8(sp)
	inc	sp, 16
	ret
	func_end op_bst


	# opcode 3
	func_begin op_jnz
op_jnz:
	set	t6
	ld	t0, STATE_REG_A(a0)
	beqz	t0, op_jnz_ret
	sd	a1, STATE_IP(a0)
	clr	t6
op_jnz_ret:
	mv	a0, t6
	ret
	func_end op_jnz


	# opcode 4
	func_begin op_bxc
op_bxc:
	ld	t0, STATE_REG_B(a0)
	ld	a1, STATE_REG_C(a0)
	xor	t0, t0, a1
	sd	t0, STATE_REG_B(a0)

	set	a0
	ret
	func_end op_bxc



	# opcode 5
	func_begin op_out
op_out:
	dec	sp, 16
	sd	ra,  0(sp)

	call	get_combo_value

	andi	a1, a0, 0b111
	la	a0, outfmt
	call	printf

	li	a0, 1
	ld	ra,  0(sp)
	inc	sp, 16
	ret
	func_end op_out


	# a0: state
	# a1: combo
	func_begin get_combo_value
get_combo_value:
	li	t0, 4
	blt	a1, t0,litteral_value
	dec	a1, 4
	slli	a1, a1, 3
	add	a1, a1, a0
	ld	a1, (a1)
litteral_value:
	mv	a0, a1
	ret
	func_end get_combo_value

