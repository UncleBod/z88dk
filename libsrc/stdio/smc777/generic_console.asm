;
;


		SECTION		code_clib

		PUBLIC		generic_console_cls
		PUBLIC		generic_console_vpeek
		PUBLIC		generic_console_scrollup
		PUBLIC		generic_console_printc
                PUBLIC          generic_console_set_ink
                PUBLIC          generic_console_set_paper
                PUBLIC          generic_console_set_inverse

		EXTERN		generic_console_flags
		EXTERN		__smc777_mode

		EXTERN		CONSOLE_COLUMNS
		EXTERN		CONSOLE_ROWS

generic_console_set_inverse:
	ld	a,(generic_console_flags)
	rrca
	rrca
	and	@00100000
	ld	c,a
	ld	a,(__smc777_attr)
	and	@11011111
set_attr:
	or	c
	ld	(__smc777_attr),a
	ret

generic_console_set_ink:
	and	7
	ld	c,a
	ld	a,(__smc777_attr)
	and	@11111000
	jr	set_attr

	
generic_console_set_paper:
	ret

generic_console_cls:
	ld	hl, +(CONSOLE_ROWS * CONSOLE_COLUMNS)
	ld	bc, 0
continue:
	ld	a,' '
	out	(c),a
	set	3,c
	ld	a,(__smc777_attr)
	out	(c),a
	res	3,c
	inc	b
	jr	nz,loop
	inc	c
loop:	dec	hl
	ld	a,h
	or	l
	jr	nz,continue
	ret

; c = x
; b = y
; a = character to print
; e = raw
generic_console_printc:
	call	xypos
	out	(c),a
	set	3,c
	ld	a,(__smc777_attr)
	out	(c),a
	ret


;Entry: c = x,
;       b = y
;Exit:  nc = success
;        a = character,
;        c = failure
generic_console_vpeek:
        call    xypos
	in	a,(c)
        and     a
        ret


xypos:
	ld	hl,-CONSOLE_COLUMNS
	ld	de,CONSOLE_COLUMNS
	inc	b
generic_console_printc_1:
	add	hl,de
	djnz	generic_console_printc_1
generic_console_printc_3:
	add	hl,bc			;hl now points to address in display
	ex	af,af
	ld	a,(__smc777_mode)
	and	a
	jr	z,is_80_col
	add	hl,bc
is_80_col:
	ex	af,af
	ld	c,h			;And swap round
	ld	b,l
	ret


generic_console_scrollup:
	push	de
	push	bc
	ld	bc, +(CONSOLE_COLUMNS * 256)
	ld	hl,+((CONSOLE_ROWS -1)* CONSOLE_COLUMNS)
scroll_loop:
	push	hl
	push	bc
	in	e,(c)
	set	3,c
	in	d,(c)
	ld	l,b
	ld	h,c
	ld	bc,-CONSOLE_COLUMNS
	add	hl,bc
	ld	c,h
	ld	b,l
	out	(c),d
	res	3,c
	out	(c),e
	pop	bc
	inc	b
	jr	nz,scroll_continue
	inc	c
scroll_continue:
	pop	hl
	dec	hl
	ld	a,h
	or	l
	jr	nz,scroll_loop


	ld	bc,$8007		;Row 25, column 0
	ld	e,CONSOLE_COLUMNS
	ld	d,' '
	ld	a,(__smc777_attr)
scroll_loop_2:
	out	(c),d
	set	3,c
	out	(c),a
	res	3,c
	inc	b
	jr	nz,clear_continue
	inc	c
clear_continue:
	dec	e
	jr	nz,scroll_loop_2
	pop	bc
	pop	de
	ret


	SECTION	data_clib

__smc777_attr:	defb	7

	SECTION	code_crt_init

        EXTERN  asm_set_cursor_state
	EXTERN	copy_font_8x8
	EXTERN	CRT_FONT

        ld      l,$20
        call    asm_set_cursor_state
	ld	bc,$1000 + (32 * 8)
	ld	e,96
	ld	hl,CRT_FONT
	ld	a,h
	or	l
	call	nz,copy_font_8x8
