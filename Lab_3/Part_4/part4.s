/* Program that converts a binary number to decimal */
           .text               // executable code follows
           .global _start
_start:
            MOV    R4, #N
            MOV    R5, #Digits  // R5 points to the decimal digits storage location
            LDR    R4, [R4]     // R4 holds N
            MOV    R0, R4       // parameter for DIVIDE goes in R0

LOOP:       MOV    R1, #10      // Divide By ten
            BL     DIVIDE
            STRB   R0, [R5], #1
            MOV    R0, R1
            CMP    R0, #0
            BGT    LOOP
            MOV    R0, #Digits
            LDR    R0, [R0]
END:        B      END

/* Subroutine to perform the integer division R0 / R1.
 * Returns: quotient in R1, and remainder in R0
 * 
*/
DIVIDE:     MOV    R2, #0
CONT:       CMP    R0, R1
            BLT    DIV_END
            SUB    R0, R1
            ADD    R2, #1
            B      CONT
DIV_END:    MOV    R1, R2     // quotient in R1 (remainder in R0)
            MOV    PC, LR

N:          .word  7645         // the decimal number to be converted
Digits:     .space 4          // storage space for the decimal digits

            .end
