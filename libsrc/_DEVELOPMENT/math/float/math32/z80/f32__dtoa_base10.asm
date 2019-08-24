
SECTION code_clib
SECTION code_fp_math32

EXTERN m32_float8, _m32_exp10f, m32_fsmul_callee

PUBLIC m32__dtoa_base10

.m32__dtoa_base10

    ; convert float from standard form "a * 2^n"
    ; to a form multiplied by power of 10 "b * 10^e"
    ; where 1 <= b < 10 with b in double format
    ;
    ; rewritten from math48 code and code by Alwin Henseler
    ;
    ; enter : DEHL'= double x, x positive
    ;
    ; exit  : DEHL'= b where 1 <= b < 10 all mantissa bits only
    ;          C   = max number of significant decimal digits (7)
    ;          D   = base 10 exponent e
    ;
    ; uses  : af, bc, de, hl, bc', de', hl'

    ; x = a * 2^n = b * 10^e
    ; e = n * log(2) = n * 0.301.. = n * 0.01001101...(base 2) = INT((n*77 + 5)/256)

    exx
    sla e                       ; move mantissa to capture exponent
    rl d
    ld a,d                      ; get exponent in a
    rr d
    rr e                        ; |x|

    exx                         ;  EHL'= x mantissa bits
                                ;  A = n (binary exponent)

    sub $7e                     ; subtract (bias - 1)
    ld l,a
    sbc a,a
    ld h,a                      ; hl = signed n

    push hl                     ; save n
    add hl,hl
    add hl,hl
    push hl                     ; save 4*n
    add hl,hl
    ld c,l
    ld b,h                      ; bc = 8*n
    add hl,hl
    add hl,hl
    add hl,hl                   ; hl = 64*n
    add hl,bc
    pop bc
    add hl,bc
    pop bc
    add hl,bc                   ; hl = 77*n
    ld bc,5
    add hl,bc                   ; rounding fudge factor

    ld a,h                      ; a = INT((77*n+5)/256)
    push af                     ; save decimal exponent e

    neg                         ; negated exponent e
    ld l,a
    call m32_float8             ; convert l to float in dehl
    call _m32_exp10f            ; make 10^-e
    push de
    push hl

    exx
    call m32_fsmul_callee       ; mantissa b = a * 2^n * 10^-e

    set 7,e                     ; set implicit 1 for mantissa bits b in ehl

    call bin2bcd

    pop bc                      ; decimal exponent e in bc
    ld c,7                      ; maximum sigificant digits

    ld a,d                      ; check for a leading significant digit
    and 0f0h
    jr NZ,finish

    add hl,hl                   ; shift left one BCD digit
    rl e
    rl d
    add hl,hl
    rl e
    rl d
    add hl,hl
    rl e
    rl d
    add hl,hl
    rl e
    rl d

    dec b                       ; reduce decimal exponent e
    dec c                       ; reduce significant digits

.finish
    push bc

    exx
    pop de                      ; decimal exponent e in d
    ld c,e                      ; significant digits in c
    ret


; Routine for converting a 24-bit binary number to decimal
; In: E:HL = 24-bit binary number (0-16777215)
; Out: DE:HL = 8 digit decimal form (packed BCD)
; Changes: AF, BC, DE, HL
;
; by Alwin Henseler

.bin2bcd
    push iy                     ; preserve IY
    ld c,e
    push hl
    pop iy                      ; input value in C:IY
    ld hl,1
    ld d,h
    ld e,h                      ; start value corresponding with 1st 1-bit
    ld b,24                     ; bitnr. being processed + 1

.find1
    add iy,iy
    rl c                        ; shift bit 23-0 from C:IY into carry
    jr C,nextbit
    djnz find1                  ; find highest 1-bit

; all bits 0:
    res 0,l                     ; least significant bit not 1
    pop iy                      ; restore IY
    ret

.dblloop
    ld a,l
    add a,a
    daa
    ld l,a
    ld a,h
    adc a,a
    daa
    ld h,a
    ld a,e
    adc a,a
    daa
    ld e,a
    ld a,d
    adc a,a
    daa
    ld d,a                      ; double the value found so far
    add iy,iy
    rl c                        ; shift next bit from C:IY into carry
    jr NC,nextbit               ; bit = 0 -> don't add 1 to the number
    set 0,l                     ; bit = 1 -> add 1 to the number
.nextbit
    djnz dblloop

    pop iy                      ; restore IY
    ret

