				.section .vectors, "ax"

				B 			_start						// reset vector
				.word 	0								// undefined instruction vector
				.word 	0								// software interrrupt vector
				.word		0								// aborted prefetch vector
				.word 	0								// aborted data vector
				.word 	0								// unused vector
				B			IRQ_HANDLER					// IRQ interrupt vector
				.word		0 								// FIQ interrupt vector

/* ********************************************************************************
 * This program demonstrates use of interrupts with assembly language code. 
 * The program responds to interrupts from the pushbutton KEY port in the FPGA.
 ********************************************************************************/
            .text
				.global	_start
_start:		
				/* Set up stack pointers for IRQ and SVC processor modes */
				MOV		R1, #0b11010010					// interrupts masked, MODE = IRQ
				MSR		CPSR_c, R1							// change to IRQ mode
				LDR		SP, =0x20000           			// set IRQ stack pointer
				/* Change to SVC (supervisor) mode with interrupts disabled */
				MOV		R1, #0b11010011					// interrupts masked, MODE = SVC
				MSR		CPSR, R1								// change to supervisor mode
				LDR		SP, =0x40000					   // set SVC stack 

				BL			CONFIG_GIC							// configure the ARM generic interrupt controller

				// write to the pushbutton KEY interrupt mask register
				LDR		R0, =0xFF200050					// pushbutton KEY base address
				MOV		R1, #0xF								// set interrupt mask bits
				STR		R1, [R0, #0x8]						// interrupt mask register is (base + 8)

				// enable IRQ interrupts in the processor
				MOV		R0, #0b01010011					// IRQ unmasked, MODE = SVC
				MSR		CPSR, R0
MAIN_LOOP:
				AND		R0, R1, R2                    // code doesn't do anything useful
				EOR		R3, R4, R5
				ORR		R6, R7, R8
				AND		R8, R7, R6
				EOR		R5, R4, R3
				ORR		R2, R1, R0

				B 			MAIN_LOOP							// main program simply repeats the loop

				.text
IRQ_HANDLER:
    			PUSH		{R0-R5, LR}
    
    			/* Read the ICCIAR from the CPU interface */
    			LDR		R4, =0xFFFEC100
    			LDR		R5, [R4, #0xC]		      		// read from ICCIAR

CHECK_KEYS: CMP		R5, #73
UNEXPECTED:	BNE		UNEXPECTED    			     		// if not recognized, stop here
    
    			BL			KEY_ISR	// pass R0 as a parameter to KEY_ISR
EXIT_IRQ:
    			/* Write to the End of Interrupt Register (ICCEOIR) */
    			STR		R5, [R4, #0x10]      			// write to ICCEOIR
    
    			POP		{R0-R5, LR}
    			SUBS		PC, LR, #4

				.global	KEY_ISR
KEY_ISR:		LDR		R0, =0xFF200050		// base address of pushbutton KEY port
				MOV		R2, #0xF
				STR		R2, [R0, #0xC]			// clear the interrupt

				MOV		PC, LR					// return

/*
 * Configure the Generic Interrupt Controller (GIC)
*/
            /* Interrupt controller (GIC) CPU interface(s) */
            .equ   MPCORE_GIC_CPUIF,     0xFFFEC100   /* PERIPH_BASE + 0x100 */
            .equ   ICCICR,               0x00         /* CPU interface control register */
            .equ   ICCPMR,               0x04         /* interrupt priority mask register */
            .equ   ICCIAR,               0x0C         /* interrupt acknowledge register */
            .equ   ICCEOIR,              0x10         /* end of interrupt register */
            /* Interrupt controller (GIC) distributor interface(s) */
            .equ   MPCORE_GIC_DIST,      0xFFFED000   /* PERIPH_BASE + 0x1000 */
            .equ   ICDDCR,               0x00         /* distributor control register */
            .equ   ICDISER,              0x100        /* interrupt set-enable registers */
            .equ   ICDICER,              0x180        /* interrupt clear-enable registers */
            .equ   ICDIPTR,              0x800        /* interrupt processor targets registers */
            .equ   ICDICFR,              0xC00        /* interrupt configuration registers */

				.global	CONFIG_GIC
CONFIG_GIC:
				PUSH		{LR}
    			/* To configure the FPGA KEYS interrupt (ID 73):
				 *	1. set the target to cpu0 in the ICDIPTRn register
				 *	2. enable the interrupt in the ICDISERn register */
				/* CONFIG_INTERRUPT (int_ID (R0), CPU_target (R1)); */
    			MOV		R0, #73					// KEY port (interrupt ID = 73)
    			MOV		R1, #1					// this field is a bit-mask; bit 0 targets cpu0
    			BL			CONFIG_INTERRUPT

				/* configure the GIC CPU interface */
    			LDR		R0, =MPCORE_GIC_CPUIF	// base address of CPU interface
    			/* Set Interrupt Priority Mask Register (ICCPMR) */
    			LDR		R1, =0xFFFF 			// enable interrupts of all priorities levels
    			STR		R1, [R0, #ICCPMR]
    			/* Set the enable bit in the CPU Interface Control Register (ICCICR). This bit
				 * allows interrupts to be forwarded to the CPU(s) */
    			MOV		R1, #1
    			STR		R1, [R0]
    
    			/* Set the enable bit in the Distributor Control Register (ICDDCR). This bit
				 * allows the distributor to forward interrupts to the CPU interface(s) */
    			LDR		R0, =MPCORE_GIC_DIST
    			STR		R1, [R0]    
    
    			POP     	{PC}

/* 
 * Configure registers in the GIC for an individual interrupt ID
 * We configure only the Interrupt Set Enable Registers (ICDISERn) and Interrupt 
 * Processor Target Registers (ICDIPTRn). The default (reset) values are used for 
 * other registers in the GIC
 * Arguments: R0 = interrupt ID, N
 *            R1 = CPU target
*/
CONFIG_INTERRUPT:
    			PUSH		{R4-R5, LR}
    
    			/* Configure Interrupt Set-Enable Registers (ICDISERn). 
				 * reg_offset = (integer_div(N / 32) * 4
				 * value = 1 << (N mod 32) */
    			LSR		R4, R0, #3							// calculate reg_offset
    			BIC		R4, R4, #3							// R4 = reg_offset
				LDR		R2, =MPCORE_GIC_DIST+ICDISER
				ADD		R4, R2, R4							// R4 = address of ICDISER
    
    			AND		R2, R0, #0x1F   					// N mod 32
				MOV		R5, #1								// enable
    			LSL		R2, R5, R2							// R2 = value

				/* now that we have the register address (R4) and value (R2), we need to set the
				 * correct bit in the GIC register */
    			LDR		R3, [R4]								// read current register value
    			ORR		R3, R3, R2							// set the enable bit
    			STR		R3, [R4]								// store the new register value

    			/* Configure Interrupt Processor Targets Register (ICDIPTRn)
     			 * reg_offset = integer_div(N / 4) * 4
     			 * index = N mod 4 */
    			BIC		R4, R0, #3							// R4 = reg_offset
				LDR		R2, =MPCORE_GIC_DIST+ICDIPTR
				ADD		R4, R2, R4							// R4 = word address of ICDIPTR
    			AND		R2, R0, #0x3						// N mod 4
				ADD		R4, R2, R4							// R4 = byte address in ICDIPTR

				/* now that we have the register address (R4) and value (R2), write to (only)
				 * the appropriate byte */
				STRB		R1, [R4]
    
    			POP		{R4-R5, PC}

            .end

