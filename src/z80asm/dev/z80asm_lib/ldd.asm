; Substitute for the z80 ldd instruction
; Doesn't emulate the flags correctly


SECTION code_crt0_sccz80
PUBLIC __z80asm__ldd

.__z80asm__ldd
	push	af		;Save incoming flags
	ld	a,(hl)
	ld	(de),a
	dec	hl
	dec	de
	dec	bc
	ex	(sp),hl		;incoming af in hl, outgoing hl on stack
	push	bc		;Save bc, we need a temporary
	ld	a,b
	or	c
	ld	c,4
	jr	nz,set_pv
	ld	c,0
set_pv:
	ld	a,l
	and	@11101001	;Knock out H + N flags as well
	or	c		;Add in PV flag required
	ld	l,a
	pop	bc
	ex	(sp),hl		;Get hl back
	pop	af		;And restore our modified af
	ret

