	.include "macros.inc"

	.globl	_start

	.set	POINTER, 	0
	.set	COUNT, 		8

	.section .rodata
filename:
	.string	"inputs/day09"
ansfmt:	.string "Part %d: %d\n"


	.bss
	.balign 8

disk1:	.space	512*1024
disk2:	.space	512*1024
files:	.space 	256*1024
space:	.space 	256*1024


	.text
	.balign 8



	func_begin _start
_start:
	la	a0, filename
	call	map_input_file
	mv	s10, a0
	add	s11, a0, a1

	la	s0, disk1
	clr	s1			# counter
	la	s2, disk2
	la	s9, files
	sd	zero, POINTER(s9)
	inc	s9, 16
	la	s4, space
	li	t6, 2
	li	t5, '\n'
loop_read:
	rem	t1, s1, t6		# file/space selector
	li	t0, -1
	bnez	t1, skip_file_id
	div	t0, s1, t6		# file id
skip_file_id:
	lb	t2, (s10)
	beq	t2, t5, loop_read_end
	dec	t2, '0'
	mv	t3, t2			# save counter
	mv	t4, s2			# save disk 2 pointer
loop_write:
	beqz	t2, loop_write_end
	sw	t0, (s0)
	sw	t0, (s2)

	inc	s0,4
	inc	s2,4
	dec	t2
	j	loop_write
loop_write_end:
	bnez	t1, store_space
	sd	t4, POINTER(s9)
	sd	t3, COUNT(s9)
	inc	s9, 16
	j	loop_write_cont
store_space:
	sd	t4, POINTER(s4)
	sd	t3, COUNT(s4)
	inc	s4, 16
loop_write_cont:
	inc	s10
	inc	s1
	#bne	s10, s11, loop_read
	j	loop_read
loop_read_end:
	sd	zero, POINTER(s4)
	dec	s9, 16

	#inc	s0, 4
	#inc	s2, 4
	li	t0, -2
	sw	t0, (s0)
	sw	t0, (s2)


	##########
	# PART 1 #
	##########


	# initialize pointers
	mv	s1, s0
	la	a0, disk1
	call	move_to_next_free
	mv	s0, a0


	mv	a0, s1
	call	move_to_next_non_free
	mv	s1, a0
	#li	s2, -2
	li	s3, -1
loop_defrag:
	lw	t1, (s1)
	#beq	t1, s2, loop_defrag_end
	sw	s3, (s1)
	sw	t1, (s0)

	mv	a0, s1
	call	move_to_next_non_free
	mv	s1, a0

	mv	a0, s0
	call	move_to_next_free
	mv	s0, a0

	#inc	s1, 4
	#inc	s0, 4

	#j	loop_defrag
	blt	s0, s1, loop_defrag

loop_defrag_end:

	la	a0, disk1
	call	checksum
	
	mv	a2, a0
	la	a0, ansfmt
	li	a1, 1
	call	printf


	##########
	# PART 2 #
	##########


loop_part2:
	ld	s0, POINTER(s9)
	beqz	s0, loop_part2_end

	ld	s1, COUNT(s9)

	mv	a0, s1
	call	find_free_space
	beqz	a0, loop_part2_next

	mv	a1, a0
	mv	a0, s0
	mv	a2, s1
	call	move_file
loop_part2_next:
	dec	s9, 16
	j	loop_part2
loop_part2_end:

	la	a0, disk2
	call	checksum
	mv	a2, a0
	la	a0, ansfmt
	li	a1, 2
	call	printf

	exit
	func_end _start



	func_begin checksum
checksum:
	clr	t0		# position
	clr	t1		# checksum
	li	t2, -2	
loop_checksum:
	lw	t3, (a0)
	beq	t3, t2, loop_checksum_end
	bltz	t3, loop_checksum_next
	mul	t4, t0, t3
	add	t1, t1, t4
loop_checksum_next:
	inc	a0, 4
	inc	t0
	j	loop_checksum
loop_checksum_end:
	mv	a0, t1
	ret
	func_end checksum


	# a0: origin
	# a1: destination
	# a2: count
	func_begin move_file
move_file:
	blt	a0, a1, loop_move_file_end	# never move a file to the right!
	lw	t0, (a0)
	li	t1, -1
loop_move_file:
	beqz	a2, loop_move_file_end
	sw	t1, (a0)
	sw	t0, (a1)
	inc	a0, 4
	inc	a1, 4
	dec	a2
	j	loop_move_file
loop_move_file_end:
	ret
	func_end move_file


	func_begin find_free_space
find_free_space:
	la	t0, space
	clr	t6
loop_find_free_space:
	ld	t1, POINTER(t0)
	beqz	t1, find_free_space_ret
	ld	t2, COUNT(t0)
	bge	t2, a0, find_free_space_found
	addi	t0, t0, 16
	j	loop_find_free_space
find_free_space_found:
	mv	t6, t1
	sub	t2, t2, a0
	slli	a0, a0, 2
	add	t1, t1, a0
	sd	t1, POINTER(t0)
	sd	t2, COUNT(t0)
find_free_space_ret:
	mv	a0, t6
	ret
	func_end find_free_space


	func_begin move_to_next_free
move_to_next_free:
	li	t0, -1
loop_move_to_next_free:
	inc	a0, 4
	lw	t1, (a0)
	beq	t0, t1, move_to_next_free_ret
	j	loop_move_to_next_free
move_to_next_free_ret:
	ret
	func_end move_to_next_free

	func_begin move_to_next_non_free
move_to_next_non_free:
	li	t0, -1
loop_move_to_next_non_free:
	dec	a0, 4
	lw	t1, (a0)
	bne	t0, t1, move_to_next_non_free_ret
	j	loop_move_to_next_non_free
move_to_next_non_free_ret:
	ret
	func_end move_to_next_non_free





