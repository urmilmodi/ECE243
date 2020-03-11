
           .text               // executable code follows
           .global _start

_start:                             
          MOV     R0, #0          // Reset R0
          MOV     R1, #0          // Reset R1
          MOV     R2, #0          // Reset R2
          MOV     R3, #0          // Reset R3
          MOV     R4, #0          // Reset R4
          MOV     R5, #0          // Reset R5
          MOV     R6, #0          // Reset R6
          MOV     R7, #0          // Reset R7
          MOV     R8, #0          // Reset R8
          MOV     R9, #0          // Reset R9
          MOV     R10, #0          // Reset R10
          MOV     R11, #0          // Reset R11
          MOV     R12, #0          // Reset R12
          B       RUN

/* Subroutine to convert the digits from 0 to 9 to be shown on a HEX display.
 *    Parameters: R0 = the decimal value of the digit to be displayed
 *    Returns: R0 = bit patterm to be written to the HEX display
 */

SEG7_CODE:  MOV     R1, #BIT_CODES  
            ADD     R1, R0         // index into the BIT_CODES "array"
            LDRB    R0, [R1]       // load the bit pattern (to be returned)
            MOV     PC, LR              

BIT_CODES:  .byte   0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
            .byte   0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
            .skip   2      // pad with 2 bytes to maintain word alignment

RUN:        MOV   R2, #KEYS  // R2 will have the address of the keys 
            LDR   R2, [R2]
            B     INVALID
            
RUNLOOP:    LDR   R3, [R2]   // R3 will have the value of the Keys
            AND   R3, R3, #0b1
            CMP   R3, #0b1
            BEQ   RESET
            LDR   R3, [R2]   // R3 will have the value of the Keys
            AND   R3, R3, #0b10
            CMP   R3, #0b10
            BEQ   INCREMENT
            LDR   R3, [R2]   // R3 will have the value of the Keys
            AND   R3, R3, #0b100
            CMP   R3, #0b100
            BEQ   DECREMENT
            LDR   R3, [R2]   // R3 will have the value of the Keys
            AND   R3, R3, #0b1000
            CMP   R3, #0b1000
            BEQ   INVALID
            B     RUNLOOP

RELEASE:    LDR   R3, [R2]
            CMP   R3, #0
            MOVEQ PC, LR
            BNE   RELEASE

RESET:      MOV   R5, #0     // R5 is the hex display value
            BL    RELEASE
            BL    DISPLAY
            B     RUNLOOP

INCREMENT:  CMP   R5, #9
            ADDNE   R5, R5, #0b1
            MOVEQ   R5, #0
            BL    RELEASE
            BL    DISPLAY
            B     RUNLOOP

DECREMENT:  CMP   R5, #0
            SUBNE   R5, R5, #0b1
            MOVEQ   R5, #0
            BL    RELEASE
            BL    DISPLAY
            B     RUNLOOP

INVALID:    LDR   R8, =0xFF200020
            BL    RELEASE
            MOV   R5, #0
            MOV   R0, #0
            STR   R0, [R8]
NOTYET:     LDR   R3, [R2]
            CMP   R3, #0
            BNE   RESET
            BEQ   NOTYET
            B     RUNLOOP 


/* Display R5 on HEX1-0, R6 on HEX3-2 and R7 on HEX5-4 */
DISPLAY:    LDR     R8, =0xFF200020 // base address of HEX3-HEX0
            MOV     R0, R5          // display R5 on HEX1-0
            
            PUSH    {R1, LR}
            BL      SEG7_CODE       
            POP     {R1, LR}
            STR     R0, [R8]        // display the numbers from R6 and R5
            
            LDR     R8, =0xFF200030 // base address of HEX5-HEX4
            MOV     R0, #0          // clear HEX5-HEX4
            STR     R0, [R8]        // display the number from R4

            MOV     PC, LR

KEYS:       .word 0xFF200050
            .end