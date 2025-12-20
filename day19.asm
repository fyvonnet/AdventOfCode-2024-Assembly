	.include "macros.inc"
	.include "memory.inc"



        .set    CHUNKS_COUNT,   4096
        .set    CHUNKS_SIZE,    64
        .set    POOL_SIZE,      8 + (CHUNKS_COUNT * CHUNKS_SIZE)
        .set    CACHE_LENGTH,   64
        .set    CACHE_SIZE,     CACHE_LENGTH * 8



	.section .rodata
filename:
	.string	"inputs/day19"
ansfmt:	.string	"Part %d answer: %d\n"
colors: .string  "wubrg"



	.bss
	.balign 8
ranks:  .space  128
        .size   ranks, 128
cache:  .space  CACHE_SIZE
        .size   cache, CACHE_SIZE
pool:   .space  POOL_SIZE
        .size   pool, POOL_SIZE



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
loop_main:
        clr     s3      # design length
        # initialize cache
        mv      t0, s10
        la      t1, cache
        li      t2, '\n'
        li      t4, -1
loop_init_cache:
        inc     s3
        sd      t4, (t1)
        inc     t0
        inc     t1, 8
        lb      t3, (t0)
        bne     t3, t2, loop_init_cache
        # hardcode termination condition in cache:
        # one way found if end of design reached
        li      t4, 1
        sd      t4, (t1)

        mv      a0, s10
        la      a1, cache
        call    count_ways
        beqz    a0, impossible
        inc     s1
        add     s2, s2, a0
impossible:

        add     s10, s10, s3    # skip to end of design
        inc     s10             # skip \n

        blt     s10, s11, loop_main

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
        # a1: cache
        func_begin count_ways
count_ways:
        dec     sp, 48
        sd      ra,  0(sp)
        sd      s0,  8(sp)
        sd      s1, 16(sp)
        sd      s2, 24(sp)
        sd      s3, 32(sp)
        sd      s4, 40(sp)

        ld      s2, (a1)
        bgez    s2, count_ways_ret

        mv      s0, a0
        mv      s1, a1
        clr     s2
        mv      s3, s9
        mv      s4, a1

loop_trie:
        lb      t0, (s0)                # load character
        la      t1, ranks
        add     t1, t1, t0
        lb      t0, (t1)                # load rank
        bltz    t0, loop_count_ways_end
        inc     t0                      # pointers array index starts at 1
        mul8    t0
        add     t0, t0, s3
        ld      s3, (t0)                # load pointer to new trie node
        beqz    s3, loop_count_ways_end  # dead-end reached
        ld      t0, (s3)                # load end-of-word flag
        inc     s0
        inc     s1, 8
        beqz    t0, loop_trie
        mv      a0, s0
        mv      a1, s1
        call    count_ways
        add     s2, s2, a0
        j       loop_trie

loop_count_ways_end:
        sd      s2, (s4)
count_ways_ret:
        mv      a0, s2
        ld      ra,  0(sp)
        ld      s0,  8(sp)
        ld      s1, 16(sp)
        ld      s2, 24(sp)
        ld      s3, 32(sp)
        ld      s4, 40(sp)
        inc     sp, 48
        ret
        func_end count_ways

