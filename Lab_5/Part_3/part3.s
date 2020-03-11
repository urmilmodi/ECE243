
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
            BL    RESET_DISPLAY
            
RUNLOOP:    LDR   R3, [R2]   // R3 will have the value of the Keys
            STR   R3, [R2]
            CMP   R3, #0b0
            MVNNE   R6, R6
            CMP   R6, #0b0
            BLEQ   INCREMENT
            BL    DO_DELAY
            B     RUNLOOP
            
DO_DELAY:  LDR   R7, =50000000// delay counter
           MOV   R9, #CONTROL
           LDR   R9, [R9]
           MOV   R0, #0b0
           STR   R0, [R9]
           MOV   R8, #LOAD
           LDR   R8, [R8]
           STR   R7, [R8]
           MOV   R0, #0b1
           STR   R0, [R9]
           MOV   R10, #INTERRUPT
           LDR   R10, [R10]
SUB_LOOP:  LDR   R0, [R10]
           CMP   R0, #0
           STRNE   R0, [R10]
           MOVNE   R0, #0
           STRNE R0, [R9]
           MOVNE PC, LR
           BEQ   SUB_LOOP

INCREMENT:  CMP   R5, #99
            ADDNE   R5, R5, #0b1
            MOVEQ   R5, #0
            PUSH   {LR}
            BL    DISPLAY
            POP    {LR}
            MOV     PC, LR

DIVIDE:     MOV    R2, #0
CONT:       CMP    R0, #10
            BLT    DIV_END
            SUB    R0, #10
            ADD    R2, #1
            B      CONT
DIV_END:    MOV    R1, R2     // quotient in R1 (remainder in R0)
            MOV    PC, LR

RESET_DISPLAY:
            LDR   R8, =0xFF200020
            MOV   R5, #0
            STR   R5, [R8]
            LDR   R8, =0xFF200030 // base address of HEX5-HEX4
            STR   R5, [R8]        // display the number from R4
            MOV   PC, LR

/* Display R5 on HEX1-0, R6 on HEX3-2 and R7 on HEX5-4 */
DISPLAY:    LDR     R8, =0xFF200020 // base address of HEX3-HEX0
            MOV     R0, R5          // display R5 on HEX1-0

            PUSH    {R2, LR}
            BL      DIVIDE          // ones digit will be in R0; tens
                                    // digit in R1
            POP     {R2, LR}

            PUSH    {R1, LR}
            BL      SEG7_CODE       
            POP     {R1, LR}              

            MOV     R4, R0          // save bit code
            MOV     R0, R1          // retrieve the tens digit, get bit
                                    // code
            PUSH    {R1, LR}
            BL      SEG7_CODE       
            POP     {R1, LR}       
            LSL     R0, #8
            ORR     R4, R0
            
            
            STR     R4, [R8]        // display the numbers from R6 and R5
            
            LDR     R8, =0xFF200030 // base address of HEX5-HEX4
            MOV     R4, #0          // clear HEX5-HEX4
            STR     R4, [R8]        // display the number from R4

            MOV     PC, LR

KEYS:       .word 0xFF20005C
LOAD:       .word 0xFFFEC600
CONTROL:    .word 0xFFFEC608
INTERRUPT:  .word 0xFFFEC60C
            .end