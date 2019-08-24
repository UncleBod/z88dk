SECTION code_driver

INCLUDE "config_private.inc"

EXTERN asm_i2c1_read_byte_get, asm_i2c2_read_byte_get

PUBLIC i2c_read_byte_get_callee

;------------------------------------------------------------------------------
;   Read from the I2C Interface, using Byte Mode transmission
;
;   extern uint8_t __LIB__ i2c_read_byte_get_callee(uint8_t device,uint8_t addr,uint8_t length) __smallc __z88dk_callee;
;
;   parameters passed in registers
;   B  = length of data sentence expected, uint8_t length
;   C  = address of slave device, uint8_t addr, Bit 0:[R=1,W=0]


.i2c_read_byte_get_callee
    pop af                              ;ret
    pop de                              ;length
    pop bc                              ;slave address
    ld b,e                              ;length
    pop de                              ;device
    push af                             ;ret

    ld a,e                              ;device address
    cp __IO_I2C2_PORT_MSB
    jp Z,asm_i2c2_read_byte_get
    cp __IO_I2C1_PORT_MSB
    jp Z,asm_i2c1_read_byte_get
    ld l,b                              ;return length in L
    ld h,0
    ret                                 ;no device address match, so exit

