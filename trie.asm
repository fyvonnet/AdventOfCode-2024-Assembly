        .include "macros.inc"
        .include "memory.inc"


        .set    TRIE_ROOT,               0
        .set    TRIE_RANKS,              8
        .set    TRIE_ALPHSZ,            16
        .set    TRIE_POOL,              24
        .set    TRIE_ALPHABET,          32



        # a0: alphabet
        # a1: ranks
        # a2: pool
        .globl  trie_init
        func_begin trie_init
trie_init:
        dec     sp, 40
        sd      ra,  0(sp)
        sd      s0,  8(sp)
        sd      s1, 16(sp)
        sd      s2, 24(sp)
        sd      s3, 32(sp)

        mv      s0, a0
        mv      s1, a1
        mv      s2, a2
        mv      s3, a3

        mv      a0, s2
        call    pool_alloc
        mv      s3, a0

        sd      a0, TRIE_ROOT(s3)
        sd      s0, TRIE_ALPHABET(s3)
        sd      s1, TRIE_RANKS(s3)
        sd      s2, TRIE_POOL(s3)

        mv      t1, s1
        li      t2, 128
        li      t3, -1
loop_init_ranks:
        sb      t3, (t1)
        inc     t1
        dec     t2
        bnez    t2, loop_init_ranks

        clr     t1
loop_store_ranks:
        lb      t0, (s0)
        beqz    t0, loop_store_ranks_end
        add     t0, t0, s1
        sb      t1, (t0)
        inc     t1
        inc     s0
        j       loop_store_ranks
loop_store_ranks_end:
        sd      t1, TRIE_ALPHSZ(s3)

        mv      a0, s2
        mv      a1, t1
        call    trie_create_node
        sd      a0, TRIE_ROOT(s3)
        
        mv      a0, s3
        ld      ra,  0(sp)
        ld      s0,  8(sp)
        ld      s1, 16(sp)
        ld      s2, 24(sp)
        ld      s3, 32(sp)
        inc     sp, 40
        ret
        func_end trie_init




        # a0: pool
        # a1: alphabet size
        func_begin trie_create_node
trie_create_node:
        dec     sp, 16
        sd      ra,  0(sp)
        sd      s0,  8(sp)

        addi    s0, a1, 1
        call    pool_alloc
        mv      t0, a0
loop_create_node:
        sd      zero, (t0)
        inc     t0, 8
        dec     s0
        bnez    s0, loop_create_node
        
        ld      ra,  0(sp)
        ld      s0,  8(sp)
        inc     sp, 16
        ret
        func_end trie_create_node



        # a0: trie
        # a1: string
        .globl  trie_insert
        func_begin trie_insert
trie_insert:
        dec     sp, 40
        sd      ra,  0(sp)
        sd      s0,  8(sp)
        sd      s1, 16(sp)
        sd      s2, 24(sp)
        sd      s3, 32(sp)

        mv      s0, a0
        mv      s1, a1
        ld      s2, TRIE_ROOT(s0)

trie_insert_loop:
        lb      t0, (s1)
        ld      t1, TRIE_RANKS(s0)
        add     t0, t0, t1
        lb      t0, (t0)
        bltz    t0, trie_insert_end
        inc     t0
        mul8    t0  
        add     s3, t0, s2
        ld      a0, (s3)
        bnez    a0, node_exists
        ld      a0, TRIE_POOL(s0)
        ld      a1, TRIE_ALPHSZ(s0)
        call    trie_create_node
        sd      a0, (s3)
node_exists:
        mv      s2, a0
        inc     s1  
        j       trie_insert_loop

trie_insert_end:
        li      t0, 1
        sd      t0, (s2)

        mv      a0, s1

        ld      ra,  0(sp)
        ld      s0,  8(sp)
        ld      s1, 16(sp)
        ld      s2, 24(sp)
        ld      s3, 32(sp)
        inc     sp, 40
        ret
        func_end trie_insert



        # a0: trie
        .globl trie_dump
        func_begin trie_dump
trie_dump:
        dec     sp, 256
        sd      ra,  0(sp)

        ld      a4, TRIE_ALPHSZ(a0)
        ld      a3, TRIE_ALPHABET(a0)
        addi    a2, sp, 8
        clr     a1
        ld      a0, TRIE_ROOT(a0)
        call    trie_dump_rec

        ld      ra,  0(sp)
        inc     sp, 256
        ret
        func_end trie_dump



        # a0: node
        # a1: depth
        # a2: string
        # a3: alphabet
        # a4: alphabet size
        func_begin trie_dump_rec
trie_dump_rec:
        dec     sp, 64
        sd      ra,  0(sp)
        sd      s0,  8(sp)
        sd      s1, 16(sp)
        sd      s2, 24(sp)
        sd      s3, 32(sp)
        sd      s4, 40(sp)
        sd      s5, 48(sp)
        sd      s5, 56(sp)


        mv      s0, a0
        mv      s1, a1
        mv      s2, a2
        mv      s5, a3
        mv      s6, a4

        ld      t0, (s0)
        beqz    t0, trie_dump_noprint
        add     a0, s2, s1
        li      t1, '\n'
        sb      t1, 0(a0)
        sb      x0, 1(a0)
        mv      a0, s2
        call    printf
trie_dump_noprint:
        mv      s3, s6
        clr     s4  
trie_dump_loop:
        mv      t0, s4
        inc     t0  
        mul8    t0  
        add     a0, t0, s0
        ld      t0, (a0)
        beqz    t0, trie_dump_loop_skip
        mv      t6, s5
        add     t6, t6, s4
        lb      t6, (t6)
        add     t1, s2, s1
        sb      t6, (t1)
        mv      a0, t0
        addi    a1, s1, 1
        mv      a2, s2
        call    trie_dump_rec

trie_dump_loop_skip:
        inc     s4
        dec     s3
        bnez    s3, trie_dump_loop

trie_dump_ret:
        ld      ra,  0(sp)
        ld      s0,  8(sp)
        ld      s1, 16(sp)
        ld      s2, 24(sp)
        ld      s3, 32(sp)
        ld      s4, 40(sp)
        ld      s5, 48(sp)
        ld      s5, 56(sp)
        inc     sp, 64
        ret
        func_end trie_dump_rec

