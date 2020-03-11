/* Program that counts consecutive 1's */

          .text                   // executable code follows
          .global _start                  
_start:                             
          MOV     R3, #TEST_NUM   // load the data word ...
          LDR     R1, [R3]        // into R1
          MOV     R0, #0          // Reset R0
          MOV     R5, #0          // Reset R5

RUN:      MOV     R5, R0
RUNLOOP:  
          LDR      R1, [R3]      // get the next number
          CMP      R1, #0
          BEQ      END
          BL       ONES
NEXTRUN:  ADD      R3, #4
          CMP      R5, R0
          BLT      RUN
          B RUNLOOP

ONES:     MOV     R0, #0          // R0 will hold the result
ONESLOOP: 
          CMP     R1, #0          // loop until the data contains no more 1's
          BEQ     NEXTRUN
          LSR     R2, R1, #1      // perform SHIFT, followed by AND
          AND     R1, R1, R2      
          ADD     R0, #1          // count the string length so far
          B       ONESLOOP            

END:      B       END             

TEST_NUM: .word   0x103fe00f, 0xfff, 0x0, 0xffff, 0x1e4541f, 0x1e45445
          .word   0x7e4541f, 0xc, 0xa, 0x27072000

          .end                            
