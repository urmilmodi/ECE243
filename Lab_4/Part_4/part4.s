
           .text               // executable code follows
           .global _start

_start:                             
          MOV     R3, #TEST_NUM   // load the data word ...
          LDR     R1, [R3]        // into R1
          MOV     R0, #0          // Reset R0
          MOV     R1, #0
          MOV     R2, #0
          MOV     R3, #0
          MOV     R4, #0
          MOV     R5, #0          // Reset R5
          MOV     R6, #0          // Reset R6
          MOV     R7, #0          // Reset R7
          MOV     R8, #0          // Reset R8
          MOV     R9, #0          // Reset R9
          B       RUNLOOP

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

RUNLOOP:  
          LDR      R1, [R3]      // get the next number
          CMP      R1, #0        // exit case
          BEQ      DISPLAY
          BL       ONES          
DONEONES:
          CMP      R5, R0        // Replace if R5 < R0
          MOVLT    R5, R0
          LDR      R1, [R3]      // Reload R1
          BL       ZEROS
DONEZEROS:
          CMP      R6, R0        // Replace if R6 < R0
          MOVLT    R6, R0
          LDR      R1, [R3]      // Reload R1
          BL       ALTERNATE
DONEALTERNATE:
          CMP      R7, R0        // Replace if R7 < R0
          MOVLT    R7, R0
          ADD      R3, #4        // Increment to Next Digit
          B RUNLOOP

ONES:     MOV     R0, #0          // R0 will hold the result
ONESLOOP: 
          CMP     R1, #0          // loop until the data contains no more 1's
          BEQ     DONEONES
          LSR     R2, R1, #1      // perform SHIFT, followed by AND
          AND     R1, R1, R2      
          ADD     R0, #1          // count the string length so far
          B       ONESLOOP            

ZEROS:    MOV     R0, #0
          MVN     R1, R1
ZEROSLOOP:
          CMP     R1, #0          // loop until the data contains no more 1's
          BEQ     DONEZEROS
          LSR     R2, R1, #1      // perform SHIFT, followed by AND
          AND     R1, R1, R2      
          ADD     R0, #1          // count the string length so far
          B       ZEROSLOOP            

ALTERNATE:
          MOV     R0, #0
          EORS    R1, R1, #PATTERN
ALTERNATELOOP:
          CMP     R1, #0          // loop until the data contains no more 1's
          BEQ     DONEALTERNATE
          LSR     R2, R1, #1      // perform SHIFT, followed by AND
          AND     R1, R1, R2      
          ADD     R0, #1          // count the string length so far
          B       ALTERNATELOOP            

END:        B      END

PATTERN:  .word    0x55555555

TEST_NUM: .word   0x103fe00f, 0xffffffff, 0x0, 0xffff, 0x1e4541f, 0x1e45445
          .word   0x7e4541f, 0xc, 0xa, 0x27072000

/* Subroutine to perform the integer division R0 / R1.
 * Returns: quotient in R1, and remainder in R0
 * 
*/
DIVIDE:     MOV    R2, #0
CONT:       CMP    R0, #10
            BLT    DIV_END
            SUB    R0, #10
            ADD    R2, #1
            B      CONT
DIV_END:    MOV    R1, R2     // quotient in R1 (remainder in R0)
            MOV    PC, LR

/* Display R5 on HEX1-0, R6 on HEX3-2 and R7 on HEX5-4 */
DISPLAY:    LDR     R8, =0xFF200020 // base address of HEX3-HEX0
            MOV     R0, R5          // display R5 on HEX1-0
            BL      DIVIDE          // ones digit will be in R0; tens
                                    // digit in R1
            MOV     R9, R1          // save the tens digit
            BL      SEG7_CODE       
            MOV     R4, R0          // save bit code
            MOV     R0, R9          // retrieve the tens digit, get bit
                                    // code
            BL      SEG7_CODE       
            LSL     R0, #8
            ORR     R4, R0
            

            MOV     R0, R6          // display R6 on HEX2-3
            BL      DIVIDE          // ones digit will be in R0; tens
                                    // digit in R1
            MOV     R9, R1          // save the tens digit
            BL      SEG7_CODE       
            LSL     R0, #16
            ORR     R4, R0          // save bit code
            MOV     R0, R9          // retrieve the tens digit, get bit
                                    // code
            BL      SEG7_CODE       
            LSL     R0, #24
            ORR     R4, R0

            STR     R4, [R8]        // display the numbers from R6 and R5
            

            LDR     R8, =0xFF200030 // base address of HEX5-HEX4
            MOV     R0, R7          // display R6 on HEX2-3
            BL      DIVIDE          // ones digit will be in R0; tens
                                    // digit in R1
            MOV     R9, R1          // save the tens digit
            BL      SEG7_CODE
            MOV     R4, R0          // save bit code
            MOV     R0, R9          // retrieve the tens digit, get bit
                                    // code
            BL      SEG7_CODE       
            LSL     R0, #8
            ORR     R4, R0
            
            STR     R4, [R8]        // display the number from R7

            B       END


            .end