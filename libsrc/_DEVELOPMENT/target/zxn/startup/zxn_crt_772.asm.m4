include(`z88dk.m4')

dnl############################################################
dnl##       ZXN_CRT_772.M4 - RAM MODEL DOTN COMMAND          ##
dnl############################################################
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;          zx spectrum nextos extended dot command          ;;
;;       generated by target/zxn/startup/zxn_crt_772.m4      ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; GLOBAL SYMBOLS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

divert(-1)
include(`config_zxn_private.inc')
divert

include "config_zxn_public.inc"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CRT AND CLIB CONFIGURATION ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

include "../crt_defaults.inc"
include "crt_config.inc"
include(`../crt_rules.inc')
include(`zxn_rules.inc')

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; SET UP MEMORY MODEL ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

include(`crt_memory_map.inc')

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; INSTANTIATE DRIVERS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ifndef CRT_OTERM_FONT_4X8

   PUBLIC CRT_OTERM_FONT_4X8
   EXTERN _font_4x8_default
   defc CRT_OTERM_FONT_4X8 = _font_4x8_default

endif

include(`../clib_instantiate_begin.m4')

ifelse(eval(M4__CRT_INCLUDE_DRIVER_INSTANTIATION == 0), 1,
`
   include(`driver/terminal/zx_01_input_kbd_inkey.m4')dnl
   m4_zx_01_input_kbd_inkey(_stdin, __i_fcntl_fdstruct_1, CRT_ITERM_TERMINAL_FLAGS, M4__CRT_ITERM_EDIT_BUFFER_SIZE, CRT_ITERM_INKEY_DEBOUNCE, CRT_ITERM_INKEY_REPEAT_START, CRT_ITERM_INKEY_REPEAT_RATE)dnl

   include(`driver/terminal/zx_01_output_char_64.m4')dnl
   m4_zx_01_output_char_64(_stdout, CRT_OTERM_TERMINAL_FLAGS, 0, 0, CRT_OTERM_WINDOW_X*2, CRT_OTERM_WINDOW_WIDTH*2, CRT_OTERM_WINDOW_Y, CRT_OTERM_WINDOW_HEIGHT, 0, CRT_OTERM_FONT_4X8, CRT_OTERM_TEXT_COLOR, CRT_OTERM_TEXT_COLOR_MASK, CRT_OTERM_BACKGROUND_COLOR)dnl

   include(`../m4_file_dup.m4')dnl
   m4_file_dup(_stderr, 0x80, __i_fcntl_fdstruct_1)dnl
',
`
   include(`crt_driver_instantiation.asm.m4')
')

include(`../clib_instantiate_end.m4')

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; STARTUP ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SECTION CODE

PUBLIC __Start, __Exit

EXTERN _main

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CRT INIT ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

__Start:

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; returning to basic
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   IF __DOTN_ENABLE_ALTERNATE

      ld (__command_line_alt_bc),bc
      ld (__command_line_alt_hl),hl

   ENDIF

   IF __crt_enable_commandline >= 2
   
      IF __crt_enable_commandline_ex & 0x80

         ld (__command_line),bc
      
      ELSE
      
         ld (__command_line),hl
      
      ENDIF
      
   ENDIF
   
   push iy
   exx
   push hl

   ld (__sp),sp

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; check for nextos
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   rst __ESX_RST_SYS
   defb __ESX_M_DOSVERSION

   ;; return status statically initialized to this
   ;;
   ;; ld hl,error_msg_nextos
   ;; ld (__return_status),hl

   jp c, error_crt          ; if esxdos present
   
   or a

IF __DOTN_ENABLE_ALTERNATE

   jp nz, load_alternate    ; if nextos is in 48k mode, try to load an alternate

ELSE

   jp nz, error_crt         ; if nextos is in 48k mode

ENDIF
   
   IF __NEXTOS_VERSION > 0

      ld hl,+(((__NEXTOS_VERSION / 1000) % 10) << 12) + (((__NEXTOS_VERSION / 100) % 10) << 8) + (((__NEXTOS_VERSION / 10) % 10) << 4) + (__NEXTOS_VERSION % 10)
         
      ex de,hl
      sbc hl,de

      jp c, error_crt       ; if nextos version not met

   ENDIF

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; core version check
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   IF __CRT_CORE_VERSION
   
      ;; set up error

      ld hl,error_msg_core_version
      ld (__return_status),hl

      ;; check for emulator
      
      ld bc,__IO_NEXTREG_REG
      
      ld a,__REG_MACHINE_ID
      out (c),a
      
      inc b
      in a,(c)
      
      cp __RMI_EMULATORS
      jr z, core_pass
      
      ;; check core version

      dec b
      
      ld e,__REG_VERSION
      out (c),e
      
      inc b
      in e,(c)                 ; e = core version major minor
      
      ld a,+(((__CRT_CORE_VERSION / 100000) & 0xf) << 4) + (((__CRT_CORE_VERSION / 1000) % 100) & 0xf)
      
      cp e
      jr c, core_pass          ; if minimum < core version
      jp nz, error_crt         ; if minimum > core version
   
      ;; core version = minimum
      
      dec b
      
      ld a,__REG_SUB_VERSION
      out (c),a
      
      inc b
      in a,(c)                 ; a = core sub version
      
      cp __CRT_CORE_VERSION % 1000
      jp c, error_crt          ; if core sub version < minimum

   core_pass:
   
   ENDIF

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; reserve space for divmmc loader
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   IF __DOTN_LAST_DIVMMC >= 0

      defc DIVMMC_BUFSZ = 64
      
      ld bc,load_divmmc_end - load_divmmc_begin + DIVMMC_BUFSZ
      
      rst __ESX_RST_ROM
      defw __ROM3_BC_SPACES

      ld hl,load_divmmc_begin
      ld bc,load_divmmc_end - load_divmmc_begin

      ld (__load_divmmc),de    ; address of divmmc load function

      ldir                     ; copy load function to final location
      
      ld (__load_buffer),de    ; address of load buffer

      in a,(__IO_DIVIDE_CONTROL)
      ld (__divide_control),a  ; save esxdos divmmc control

   ENDIF

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; speed up the load process
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   call turbo_save             ; save current z80 speed
   call turbo_14               ; speed up to 14MHz

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; save current mmu state
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   
   ld hl,__z_saved_mmu_state
   
   EXTERN asm_zxn_read_mmu_state
   call   asm_zxn_read_mmu_state

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; save basic bank state
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   
   EXTERN asm_zxn_read_sysvar_bank_state
   call   asm_zxn_read_sysvar_bank_state
   
   ld (__z_saved_bank_state),hl

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; get handle to load rest of dot command
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   
   rst __ESX_RST_SYS
   defb __ESX_M_GETHANDLE

   ld c,a                      ; c = file handle

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; select mmu for loading
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   ld ix,load_using_mmu7
   
   ld a,(__sp + 1)
   
   cp 0xe0
   jr c, end_select

   ld ix,load_using_mmu3

end_select:

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; allocate and load pages
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   
   ld hl,(__z_page_sz)         ; num pages and num extra
   
   ld a,l
   add a,h
   ld b,a                      ; b = total number of pages
   
   jr z, alloc_cancel          ; if no pages are being allocated

   ld hl,__z_page_alloc_table
   ld de,__z_page_table
   
alloc_loop:

   ;  b = num pages
   ;  c = file handle
   ; de = logical table position
   ; hl = alloc table position
   ; ix = mmu function

   ld a,(hl)

   cp 0xff
   jr z, alloc_not_used        ; 0xff indicates page not used

   cp 0xfc                     ; alloc flag < 0xfc is undefined
   jr nc, alloc_continue

alloc_error:

   ld hl,error_msg_malformed_alloc
   jp terminate

alloc_continue:

   push de                     ; save logical table position

   bit 0,a
   jr nz, alloc_load           ; if allocation not requested

   ;; allocate

   push ix                     ; save mmu function
   push bc                     ; save num pages, file handle
   push hl                     ; save allocation table position

   ld hl,__nextos_rc_bank_alloc + (__nextos_rc_banktype_zx * 256)

   exx

   ld de,__NEXTOS_IDE_BANK
   ld c,7
   
   rst __ESX_RST_SYS
   defb __ESX_M_P3DOS

   ld hl,error_msg_out_of_memory
   jp nc, terminate
   
   pop hl                      ; hl = allocation table position
   pop bc                      ; b = num pages, c = file handle
   pop ix                      ; ix = mmu function
   
   ld a,(hl)                   ; a = allocation flag
   ld (hl),e                   ; write allocated bank into allocation table
   
   ex (sp),hl
   ld (hl),e                   ; write allocated bank into logical table
   ex (sp),hl

alloc_load:

   ;; load

   ;  a = alloc flag
   ;  b = num pages
   ;  c = file handle
   ; hl = alloc table position
   ; ix = mmu function
   ; stack = logical table position

   and 0x02
   jr nz, alloc_no_load        ; if load not requested

   EXTERN l_call_ix

   pop de
   push de                     ; de = logical table position
   
   push bc                     ; save num pages, file handle
   push hl                     ; save alloc table
   push ix                     ; save mmu function

   ld a,(de)                   ; a = destination physical page
   call l_call_ix              ; carry is reset to page in target page

   ld a,c                      ; file handle
   ld bc,0x2000                ; page size
   
   rst __ESX_RST_SYS
   defb __ESX_F_READ
   
   ld l,a
   ld h,0   

   jp c, terminate             ; if read error
   
   ld hl,0x2000
   sbc hl,bc
   
   ld hl,__ESX_EIO
   jp nz, terminate            ; if did not read 0x2000 bytes

   pop ix                      ; restore mmu function
   pop hl                      ; hl = alloc table
   pop bc                      ; b = num pages, c = handle

   scf
   call l_call_ix              ; carry is set to restore target page

alloc_no_load:

   pop de

alloc_not_used:

   ;  b = num pages
   ;  c = file handle
   ; de = logical table position
   ; hl = alloc table position
   ; ix = mmu function

   inc hl
   inc de

   djnz alloc_loop

alloc_cancel:

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; allocate and load divmmc pages
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   IF __DOTN_LAST_DIVMMC >= 0

      ld a,(__z_div_sz)        ; num divmmc pages
      
      or a
      jr z, div_alloc_cancel
      
      ld b,a
      
      ld hl,__z_div_alloc_table
      ld de,__z_div_table
      
   div_alloc_loop:
   
      ;  b = num pages
      ;  c = file handle
      ; de = div logical table position
      ; hl = div alloc table position
   
      ld a,(hl)
      
      cp 0xff
      jr z, div_alloc_not_used ; 0xff indicates page not used
      
      cp 0xfc                  ; alloc flag < 0xfc is undefined
      jr c, alloc_error
      
   div_alloc_continue:
   
      push de                  ; save logical table position
      
      bit 0,a
      jr nz, div_alloc_load    ; if allocation not requested
      
      ;; allocate
      
      push bc                  ; save num pages, file handle
      push hl                  ; save allocation table position
      
      ld hl,__nextos_rc_bank_alloc + (__nextos_rc_banktype_mmc * 256)
      
      exx
      
      ld de,__NEXTOS_IDE_BANK
      ld c,7
      
      rst __ESX_RST_SYS
      defb __ESX_M_P3DOS
      
      ld hl,error_msg_divmmc_out_of_memory
      jp nc, terminate
      
      pop hl                   ; hl = allocation table position
      pop bc                   ; b = num pages, c = file handle
      
      ld a,(hl)                ; a = allocation flag
      ld (hl),e                ; write allocated bank into allocation table
      
      ex (sp),hl
      ld (hl),e                ; write allocated bank into logical table
      ex (sp),hl
      
   div_alloc_load:
   
      ;; load
      
      ;  a = alloc flag
      ;  b = num pages
      ;  c = file handle
      ; hl = alloc table position
      ; stack = logical table position
      
      and 0x02
      jr nc, div_alloc_no_load ; if load not requested
      
      EXTERN l_jphl
   
      pop de
      push de                  ; de = logical table position
      
      push bc                  ; save num pages, file handle
      push hl                  ; save alloc table

      ld a,(de)                ; physical divmmc page to load into      
      ld hl,(__load_divmmc)    ; address of divmmc loader on stack

      call l_jphl
      jp c, terminate          ; if read error

      pop hl                   ; hl = alloc table
      pop bc                   ; b = num pages, c = file handle
      
   div_alloc_no_load:
   
      pop de
   
   div_alloc_not_used:
   
      ;  b = num pages
      ;  c = file handle
      ; de = logical table position
      ; hl = alloc table position
      
      inc hl
      inc de
      
      djnz div_alloc_loop
      
   div_alloc_cancel:

   ENDIF

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; parse command line to divmmc memory
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   ld sp,DOTN_REGISTER_SP       ; move stack to divmmc memory

   IF __crt_enable_commandline >= 2

      ld hl,(__command_line)

   ENDIF

   include "crt_cmdline_esxdos.inc"
   
   IF __crt_enable_commandline >= 1

      ; stack: argv/cmdline, argc/len
   
      pop bc
      pop de
   
   ENDIF

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; page main bank into memory
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   ld hl,(__z_page_table+10)
   
   ld a,l
   mmu2 a

   ld a,h
   mmu3 a

   ld hl,(__z_page_table+4)
   
   ld a,l
   mmu4 a

   ld a,h
   mmu5 a

   ld hl,(__z_page_table+0)
   
   ld a,l
   mmu6 a

   ld a,h
   mmu7 a

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; move stack to main bank
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   
   IF __register_sp != -1

      include "../crt_init_sp.inc"

   ENDIF

   IF __crt_enable_commandline >= 1

      ; de = argv / unprocessed zero terminated command line
      ; bc = argc / command line length
      
      push de
      push bc
      
   ENDIF

   ; stack: argv/cmdline, argc/len

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; register basic error intercept
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   
   EXTERN _esx_errh
   
   ld hl,__basic_error_intercept
   ld (_esx_errh),hl

   rst __ESX_RST_SYS
   defb __ESX_M_ERRH
   
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; ram initialization
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   ; initialize data section

   include "../clib_init_data.inc"

   ; initialize bss section

   include "../clib_init_bss.inc"

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; interrupt mode
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   ; interrupt mode
   
   include "../crt_start_di.inc"

   include "../crt_set_interrupt_mode.inc"

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; restore original cpu speed
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   call turbo_restore

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; main
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SECTION code_crt_init          ; user and library initialization
SECTION code_crt_main

   include "../crt_start_ei.inc"

   ; call user program

IF __crt_enable_commandline >= 1

   pop bc                      ; bc = argc / length
   pop hl                      ; hl = argv / command line
   
   push hl
   push bc

ENDIF

   call _main                  ; hl = return status

error_basic:

   ; run exit stack

   IF __clib_exit_stack_size > 0
   
      EXTERN asm_exit
      jp     asm_exit          ; exit function jumps to __Exit
   
   ENDIF

__Exit:

   push hl                     ; save return status

SECTION code_crt_exit          ; user and library cleanup
SECTION code_crt_return

   ; close files
   
   include "../clib_close.inc"
   
   pop hl                      ; hl = return status

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; terminate
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   inc h
   dec h
   
   jr z, terminate             ; if there is no custom error message
   
   ;; must copy the error message to divmmc memory
   
   ld de,DOTN_REGISTER_SP - 128 - 10
   ld bc,128

custom_loop:
   
   ld a,(hl)
   and 0x80
   
   ldi
   
   jr nz, custom_done
   jp pe, custom_loop

   dec de
   
   ex de,hl
   set 7,(hl)

custom_done:

   ld hl,DOTN_REGISTER_SP - 128 - 10

terminate:

   call turbo_14               ; speed up to 14MHz

   ld (__return_status),hl
   ld sp,DOTN_REGISTER_SP      ; stack to divmmc memory
   
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; restore banked state
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   ;; unlock port 7ffd
   
   ld bc,__IO_NEXTREG_REG
   
   ld a,__REG_PERIPHERAL_3
   out (c),a
   
   inc b
   
   in a,(c)
   or __RP3_UNLOCK_7FFD
   
   out (c),a
   
   ;; restore sys vars area
   
   ld iy,__SYS_IY              ; expected by rom isr  
   im 1                        ; rom isr will not run until the stack is moved out of divmmc
   
   ld a,(__z_saved_mmu_state + 2)
   mmu2 a
   
   ;; restore bank state

   ld hl,(__z_saved_bank_state)

   EXTERN asm_zxn_write_sysvar_bank_state
   EXTERN asm_zxn_write_bank_state
   
   call   asm_zxn_write_sysvar_bank_state
   call   asm_zxn_write_bank_state  ; 1ffd, 7ffd, dffd=0

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; restore mmu state
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   
   ld hl,__z_saved_mmu_state
   
   EXTERN asm_zxn_write_mmu_state
   call   asm_zxn_write_mmu_state
   
   ld sp,(__sp)                ; back to basic's stack

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; deallocate pages
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   
   ld hl,(__z_page_sz)         ; pages and extra
   
   ld a,l
   add a,h
   ld b,a                      ; b = total number of pages
   
   jr z, dealloc_cancel

   ld hl,__z_page_alloc_table
   
dealloc_loop:

   ld a,(hl)
   
   cp __ZXNEXT_LAST_PAGE + 1
   jr nc, dealloc_not_used

   push bc
   push hl
   
   ld e,a
   ld hl,__nextos_rc_bank_free + (__nextos_rc_banktype_zx * 256)

   exx

   ld de,__NEXTOS_IDE_BANK
   ld c,7
   
   rst __ESX_RST_SYS
   defb __ESX_M_P3DOS
   
   pop hl
   pop bc
   
dealloc_not_used:

   inc hl
   djnz dealloc_loop

dealloc_cancel:

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; deallocate divmmc pages
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   IF __DOTN_LAST_DIVMMC >= 0

      ld a,(__z_div_sz)        ; divmmc pages
      
      or a
      jr z, div_dealloc_cancel
      
      ld b,a                   ; b = total number of pages
      
      ld hl,__z_div_alloc_table
   
   div_dealloc_loop:
   
      ld a,(hl)
      
      cp __ZXNEXT_LAST_DIVMMC + 1
      jr nc, div_dealloc_not_used
      
      push bc
      push hl
      
      ld e,a
      ld hl,__nextos_rc_bank_free + (__nextos_rc_banktype_mmc * 256)
   
      exx

      ld de,__NEXTOS_IDE_BANK
      ld c,7
   
      rst __ESX_RST_SYS
      defb __ESX_M_P3DOS
   
      pop hl
      pop bc
   
   div_dealloc_not_used:

      inc hl
      djnz div_dealloc_loop

   div_dealloc_cancel:

   ENDIF

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; return to basic
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   include "../crt_exit_eidi.inc"

   call turbo_restore          ; restore original z80 speed

error_crt:

   ; direct jumps here have not saved original z80 speed

   ld sp,(__sp)
   
   pop hl
   exx
   pop iy
   
   ld hl,(__return_status)

   ; If you exit with carry set and A<>0, the corresponding error code will be printed in BASIC.
   ; If carry set and A=0, HL should be pointing to a custom error message (with last char +$80 as END marker).
   ; If carry reset, exit cleanly to BASIC
      
   ld a,h
   or l
   ret z                       ; status == 0, no error
      
   scf
   ld a,l
      
   inc h
   dec h
      
   ret z                       ; status < 256, basic error code in status&0xff
      
   ld a,0                      ; status = & custom error message
   ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; BASIC ERROR ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

__basic_error_intercept:

   ; basic error has occurred during a rst $10 or rst $18
   ; must free allocated pages and close open files
   
   ; enter :  a = basic error code - 1
   ;         de = return address to restart
   ;         (you can resume the program if you jump to this address)

   ld hl,error_msg_d_break
   
   cp __ERRB_D_BREAK_CONT_REPEATS - 1
   jp z, error_basic
   
   ld hl,__ESX_ENONSENSE
   jp error_basic

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; TURBO MODE ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; speed up the whole load process by going 14MHz

; must restore the speed set by the user before starting the
; program and before returning

turbo_save:

   ld bc,__IO_NEXTREG_REG
   
   ld a,__REG_TURBO_MODE
   out (c),a
   
   inc b
   
   in a,(c)
   ld (__turbo_save),a
   
   ret

turbo_restore:

   ld a,(__turbo_save)

   nextreg __REG_TURBO_MODE,a
   ret

turbo_14:

   nextreg __REG_TURBO_MODE,__RTM_14MHZ
   ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ALLOCATION UTILITIES ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; load using mmu3

load_using_mmu3:

   jr c, load_restore_mmu3     ; carry set indicates restore page

load_set_mmu3:

   ld hl,0x6000                ; start of mmu3
   
   mmu3 a
   ret

load_restore_mmu3:

   ld a,(__z_saved_mmu_state + 3)
   mmu3 a
   
   ret

;; load using mmu7

load_using_mmu7:

   jr c, load_restore_mmu7     ; carry set indicates restore page

load_set_mmu7:

   ld hl,0xe000                ; start of mmu7
   
   mmu7 a
   ret

load_restore_mmu7:

   ld a,(__z_saved_mmu_state + 7)
   mmu7 a
   
   ret

;; divmmc loader

IF __DOTN_LAST_DIVMMC >= 0

   EXTERN l_ret

load_divmmc_begin:

   or __IDC_CONMEM
   
   ld b,8192 / DIVMMC_BUFSZ
   
   ld de,0x2000

__load_divmmc_loop:

   ;  a = target divmmc page
   ;  b = loop count
   ;  c = file handle
   ; de = destination address in divmmc
   
   push af
   push bc

   push af
   push de

   ;; load fragment into buffer

   ld a,c                      ; file handle
   
   ld hl,__load_buffer
   ld bc,DIVMMC_BUFSZ

   rst __ESX_RST_SYS
   defb __ESX_F_READ

   pop de
   
   ld l,a
   ld h,0
   
   jp c, l_ret - 3             ; if read error

   ld hl,DIVMMC_BUFSZ
   sbc hl,bc
   
   ld hl,__ESX_EIO
   scf
   jp nz, l_ret - 3            ; if full amount not read

   pop af
   
   ;; copy to destination divmmc page

   out (__IO_DIVIDE_CONTROL),a ; map destination divmmc page
   
   ld hl,__load_buffer
   ld bc,DIVMMC_BUFSZ
   
   ldir
   
   ld a,(__divide_control)
   out (__IO_DIVIDE_CONTROL),a ; restore esxdos divmmc page
   
   ;; loop until done
   
   pop bc
   pop af

   djnz __load_divmmc_loop
   ret

load_divmmc_end:

ENDIF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; error messages
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IF __CRT_CORE_VERSION

   error_msg_core_version:
   
      defm "Requires Core v"

      IF ((__CRT_CORE_VERSION / 1000000) % 10)
         defb (__CRT_CORE_VERSION / 1000000) % 10 + '0'
      ENDIF
      
         defb (__CRT_CORE_VERSION / 100000) % 10 + '0'
         defb '.'
      
      IF ((__CRT_CORE_VERSION / 10000) % 10)
         defb (__CRT_CORE_VERSION / 10000) % 10 + '0'
      ENDIF
      
         defb (__CRT_CORE_VERSION / 1000) % 10 + '0'
         defb '.'
      
      IF ((__CRT_CORE_VERSION / 100) % 10)
         defb (__CRT_CORE_VERSION / 100) % 10 + '0'
      ENDIF
      
      IF ((__CRT_CORE_VERSION / 100) % 10) || ((__CRT_CORE_VERSION / 10) % 10)
         defb (__CRT_CORE_VERSION / 10) % 10 + '0'
      ENDIF
      
      defb __CRT_CORE_VERSION % 10 + '0' + 0x80

ENDIF

IF __NEXTOS_VERSION > 0

   error_msg_nextos:
      
      defm "Requires NextZXOS 128k "
      
      IF ((__NEXTOS_VERSION / 1000) % 10)
         defb (__NEXTOS_VERSION / 1000) % 10 + '0'
      ENDIF
      
      defb (__NEXTOS_VERSION / 100) % 10 + '0'
      defb '.'
      defb (__NEXTOS_VERSION / 10) % 10 + '0'
      defb __NEXTOS_VERSION % 10 + '0' + 0x80
   
ELSE
   
   error_msg_nextos:

      defm "Requires NextZXOS 128", 'k'+0x80

ENDIF

error_msg_out_of_memory:

   defm "4 Out of page memor", 'y'+0x80

error_msg_malformed_alloc:

   defm "Alloc table malforme", 'd'+0x80

error_msg_d_break:

   defm "D BREAK - no repea", 't'+0x80

IF __DOTN_LAST_DIVMMC >= 0

   error_msg_divmmc_out_of_memory:
   
      defm "4 Out of divmmc memor", 'y' + 0x80

ENDIF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; LOAD ALTERNATE IMPLEMENTATION ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IF __NEXTOS_DOT_COMMAND && __DOTN_ENABLE_ALTERNATE

;; Decided not to use M_EXECCMD so that the command line can
;; be reused without modification.
;;
;; Consequence is that M_GETHANDLE cannot be used to get a
;; handle to the dot command file.  So dotn commands cannot
;; be used as the alternate.  Which is fine since we're only
;; getting an alternate if in 48k mode.

   PUBLIC __z_alt_filename

load_alternate:

   ;; copy loader to stack
   
   ld hl,load_alternate_begin - load_alternate_end
   
   add hl,sp
   ld sp,hl
   
   ex de,hl                    ; de = loader start address
   
   ld hl,(__sp)
   push hl                     ; save original stack location
   
   push de                     ; loader start on stack
   
   ld hl,load_alternate_begin
   ld bc,load_alternate_end - load_alternate_begin
   
   ldir

   ;; open alternate file
   
   ld a,'*'
   
   ld b,__esx_mode_open_exist | __esx_mode_read
   ld hl,alternate_filename
   
   rst __ESX_RST_SYS
   defb __ESX_F_OPEN
   
   jp c, error_crt
   
   ld bc,(__command_line_alt_bc)
   ld hl,(__command_line_alt_hl)

   ret                         ; run loader

load_alternate_begin:

   ;;  a = file handle
   ;; bc = command line
   ;; hl = command line
   ;; stack = original sp
   
   push bc                     ; save full command line location
   push hl                     ; save esxdos command line location
   push af                     ; save handle
   
   ld hl,0x2000                ; overlay this dot command
   ld bc,0x2000                ; at most 8k
   
   rst __ESX_RST_SYS
   defb __ESX_F_READ
   
   pop af                      ; a = file handle
   
   rst __ESX_RST_SYS
   defb __ESX_F_CLOSE
   
   pop de                      ; command line pointers
   pop bc
   
   pop hl                      ; hl = original sp
   
   di
   
   ld sp,hl                    ; restore stack location
   ex de,hl                    ; hl = original command line
   
   exx
   pop hl
   exx
   pop iy
   
   ei                          ; enabled after jp
   jp 0x2000

load_alternate_end:

alternate_filename:

   defm "__ENV_BINDIR/extra/"

__z_alt_filename:

   defs 9                      ; filled in by appmake

ENDIF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; RUNTIME VARS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

__command_line:   defw 0

IF __DOTN_ENABLE_ALTERNATE

   __command_line_alt_bc:  defw 0
   __command_line_alt_hl:  defw 0

ENDIF

__sp:             defw 0

__turbo_save:     defb 0

IF __DOTN_LAST_DIVMMC >= 0

   __load_divmmc:     defw 0
   __load_buffer:     defw 0
   __divide_control:  defb 0

ENDIF

__return_status:  defw error_msg_nextos

PUBLIC __z_saved_bank_state
PUBLIC __z_saved_mmu_state

__z_saved_bank_state:  defw 0
__z_saved_mmu_state:   defs 8

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; allocation variables filled in by appmake

include(`crt_allocation_dotn.m4')

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

include "../clib_variables.inc"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CLIB STUBS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

include "../clib_stubs.inc"
