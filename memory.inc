.macro create_alloc_func func, area, type
        .type   \func, @function
\func:
        addi    sp, sp, -16
        sd      ra,  0(sp)

        mv      a1, a0
        lga      a0, \area
        call    \type\()_alloc

        ld      ra,  0(sp)
        addi    sp, sp, 16
        ret
        .size   \func, .-\func
.endm

.macro create_free_func func, area, type
        .type   \func, @function
\func:
        addi    sp, sp, -16
        sd      ra,  0(sp)

        mv      a1, a0
        lga      a0, \area
        call    \type\()_free

        ld      ra,  0(sp)
        addi    sp, sp, 16
        ret
        .size   \func, .-\func
.endm

