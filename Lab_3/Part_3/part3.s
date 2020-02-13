/* Program that finds the largest number in a list of integers	*/

            .text                   // executable code follows
            .global _start                  
_start:      
         MOV      R4, #RESULT   // R4 points to result location
         LDR      R0, [R4, #4]  // R0 holds number of elements in the list
         MOV      R1, #NUMBERS  // R1 points to the list of integers
         LDR      R0, [R1]      // R0 holds the largest number so far
         MOV      R2, #0
         MOV      R3, #0

/* Subroutine to find the largest integer in a list
 * Parameters: R0 has the number of elements in the lisst
 *             R1 has the address of the start of the list
 * Returns: R0 returns the largest item in the list
 */
LARGE:    SUBS     R0, #1        // decrement the loop counter
          BEQ      DONE          // if result is equal to 0, branch
          ADD      R1, #4
          LDR      R3, [R1]      // get the next number
          CMP      R2, R3        // check if larger number found
          BGE      LARGE
          MOV      R2, R3        // update the largest number
          B        LARGE
DONE:     STR      R2, [R4]      // store largest number into result location

END:     B        END

RESULT:     .word   0           
N:          .word   7           // number of entries in the list
NUMBERS:    .word   4, 5, 3, 6  // the data
            .word   1, 8, 2                 

            .end                            

