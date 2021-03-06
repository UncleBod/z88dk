
INCLUDE "config_private.inc"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
IF __CLIB_OPT_ERROR
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   ; verbose mode

   SECTION code_clib
   SECTION code_error
   
   PUBLIC error_erange_mc
   
   EXTERN __ERANGE, errno_mc
   
      pop hl
   
   error_erange_mc:
   
      ; set hl = -1
      ; set carry flag
      ; set errno = ERANGE
      
      ld l,__ERANGE
      jp errno_mc
   
   
   SECTION rodata_clib
   SECTION rodata_error_strings

   IF __CLIB_OPT_ERROR & $02

      defb __ERANGE
      defm "ERANGE - Result too large"
      defb 0

   ELSE
   
      defb __ERANGE
      defm "ERANGE"
      defb 0
   
   ENDIF
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ELSE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   SECTION code_clib
   SECTION code_error
   
   PUBLIC error_erange_mc
   
   EXTERN errno_mc
   
   defc error_erange_mc = errno_mc - 2

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ENDIF
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
