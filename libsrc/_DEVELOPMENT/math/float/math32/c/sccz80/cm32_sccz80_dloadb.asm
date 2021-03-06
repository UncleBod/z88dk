
SECTION code_clib
SECTION code_fp_math32

PUBLIC cm32_sccz80_dloadb

cm32_sccz80_dloadb:

    ; sccz80 float primitive
    ; Load float given pointer in HL pointing to last byte into DEHL'.
    ;
    ; enter : HL = double * (sccz80 format) + 5 bytes
    ;
    ; exit  : DEHL'= double (math32 format)
    ;         (exx set is swapped)
    ;
    ; uses  : bc, de, hl

    ld d,(hl)
    dec hl
    ld e,(hl)
    dec hl
    ld b,(hl)
    dec hl
    ld c,(hl)
    ld h,b
    ld c,l

    exx
    ret
