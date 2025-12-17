	.include "macros.inc"
	.include "memory.inc"



	.section .rodata
filename:
	.string	"inputs/day19"
ansfmt:	.string	"Part %d answer: %d\n"
colors: .string  "wubrg"

        .set    CHUNKS_COUNT,   4096
        .set    CHUNKS_SIZE,    64
        .set    POOL_SIZE,      8 + (CHUNKS_COUNT * CHUNKS_SIZE)



	.bss
	.balign 8
pool:   .space  POOL_SIZE
        .size   pool, POOL_SIZE
ranks:  .space  128
        .size   ranks, 128
cache:  .space  64*8
        .size   cache, 64*8



	.text
	.balign 8



	.globl	_start
	func_begin _start
_start:
        la      a0, pool
        li      a1, CHUNKS_COUNT
        li      a2, CHUNKS_SIZE
        call    pool_init

        la      a0, colors
        la      a1, ranks
        la      a2, pool
        call    trie_init
        mv      s0, a0
        ld      s9, (a0)

	la	a0, filename
	call	map_input_file
	mv	s10, a0
	add	s11, a0, a1

loop_insert_patterns:
        mv      a0, s0
        mv      a1, s10
        call    trie_insert
        add     s10, a0, 2
        lb      t0, (a0)
        li      t1, ','
        beq     t0, t1, loop_insert_patterns
        
        clr     s1
        clr     s2
loop:
        mv      a0, s10
        call    count_ways
        beqz    a0, impossible
        inc     s1
        add     s2, s2, a0
impossible:

        # skip to next input line
        li      t1, '\n'
loop_skip:
        lb      t0, (s10)
        beq     t0, t1, loop_skip_end
        inc     s10
        j       loop_skip
loop_skip_end:
        inc     s10
        blt     s10, s11, loop

        la      a0, ansfmt
        li      a1, 1
        mv      a2, s1
        call    printf

        la      a0, ansfmt
        li      a1, 2
        mv      a2, s2
        call    printf

	exit
	func_end _start



        # a0: string
        func_begin count_ways
count_ways:
        dec     sp, 16
        sd      ra,  0(sp)

        mv      t0, a0
        la      t1, cache
        li      t2, '\n'
        li      t4, -1
loop_init_cache:
        sd      t4, (t1)
        inc     t0
        inc     t1, 8
        lb      t3, (t0)
        bne     t3, t2, loop_init_cache

        # hardcode termination condition in cache:
        # one way found if end of design reached
        li      t4, 1
        sd      t4, (t1)

        la      a1, cache
        call    count_ways_rec

        ld      ra,  0(sp)
        inc     sp, 16
        ret
        func_end count_ways



        # a0: string
        # a1: cache
        func_begin count_ways_rec
count_ways_rec:
        dec     sp, 64
        #sd      x0,  0(sp)
        sd      ra,  8(sp)
        sd      s0, 16(sp)
        sd      s1, 24(sp)
        sd      s2, 32(sp)
        sd      s3, 40(sp)
        sd      s4, 48(sp)

        ld      s2, (a1)
        bltz    s2, not_in_cache
        j       count_ways_rec_ret
not_in_cache:

        mv      s0, a0
        mv      s1, a1
        mv      s4, sp

        mv      a1, sp
        call    count_matches
        mv      s3, a0

        clr     s2
loop_count_ways_rec:
        beqz    s3, loop_count_ways_rec_end
        lb      t0, (s4)
        add     a0, s0, t0
        mul8    t0
        add     a1, s1, t0
        call    count_ways_rec
        add     s2, s2, a0
        dec     s3
        inc     s4
        j       loop_count_ways_rec
loop_count_ways_rec_end:
        sd      s2, (s1)
count_ways_rec_ret:
        mv      a0, s2
        ld      ra,  8(sp)
        ld      s0, 16(sp)
        ld      s1, 24(sp)
        ld      s2, 32(sp)
        ld      s3, 40(sp)
        ld      s4, 48(sp)
        inc     sp, 64
        ret
        func_end count_ways_rec



        # a0: string
        # a1: array pointer
        func_begin count_matches
count_matches:
        clr     t0              # matches counter
        clr     t1              # string index
        la      a3, ranks
        mv      t3, s9
loop_count_matches:
        add     t2, a0, t1      
        lb      t2, (t2)        # load character
        add     t2, t2, a3
        lb      t2, (t2)        # load rank
        bltz    t2, count_matches_end
        inc     t2              # trie pointers start at 1
        mul8    t2
        add     t2, t2, t3
        ld      t3, (t2)        # load next node pointer
        beqz    t3, count_matches_end
        ld      t2, (t3)        # load end-of-word flag
        beqz    t2, not_eow
        inc     t0              # increment counter
        addi    t2, t1, 1
        sb      t2, (a1)        # save match length
        inc     a1
not_eow:
        inc     t1
        j       loop_count_matches
count_matches_end:
        mv      a0, t0
        ret
        func_end count_matches


