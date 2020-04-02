.section .vectors, "ax"
        B      _start                // Reset vector
        B      SERVICE_UND           // Undefined Instruction Vector
        B      SERVICE_SVC           // Software Interrupt
        B      SERVICE_ABT_INST      // Aborted Prefetch
        b      SERVICE_ABT_DATA      // Aborted Data
        .word   0            
        B      SERVICE_IRQ           // IRQ interrupt
        B      SERVICE_FIQ           // FIQ interrupt

        .text
        .global   _start

        .equ EDGEBITS, 0xFF20005C

_start:

        // Set up stack pointers for IRQ and SVC modes
        MOV     R0, #0b10010             // IRQ mode
        MSR     CPSR, R0                 // Change to IRQ mode
        LDR     SP, =0x2000              // SP Set Up
                
        // Enable SVC mode Interrupt
        
        MOV     R0, #0b1010011
        MSR     CPSR, R0                // Change to SVC mode
        LDR     SP, =0x3FFFFFFC         // SP Set Up
        

        BL       CONFIG_GIC             // Configure the ARM generic interrupt controller
        BL       CONFIG_TIMER           // Configure the Interval Timer
        BL       CONFIG_KEYS            // Configure the pushbutton KEYs port

        LDR      R5, =0xFF200000        // LEDR base address

LOOP:
        LDR      R3, COUNT            // global variable
        STR      R3, [R5]             // write to the LEDR lights
        B        LOOP 

// Exception service routines

SERVICE_IRQ:

        PUSH     {R0-R7, LR}
        LDR      R4, =0xFFFEC100    // GIC CPU interface base address
        LDR      R5, [R4, #0x0C]    // read the ICCIAR in the CPU interface

HANDLER:
        CMP      R5, #73            // check the interrupt ID
        BNE      TIMER_HANDLER_CHECK
        BL       KEY_ISR

        B        EXIT_IRQ

TIMER_HANDLER_CHECK:

        CMP      R5, #72

UNEXPECTED:     

        BNE      UNEXPECTED         // stop here if something is weird
        BL       TIMER_ISR

EXIT_IRQ:       

        STR      R5, [R4, #0x10]    // write to the End of Interrupt Register (ICCEOIR)
        POP      {R0-R7, LR}
        SUBS     PC, LR, #4         // return from exception

KEY_ISR:

        LDR     R0, =EDGEBITS
        LDR     R0, [R0]

        // Check KEYS and Call Respective Handler
        CMP     R0, #0b0001
        BEQ     KEY_0

        CMP     R0, #0b0010
        BEQ     KEY_1

        CMP     R0, #0b0100
        BEQ     KEY_2

EXIT_KEY_ISR:
      
        // Reset edge capture bits
        LDR      R0, =KEY_BASE
        LDR      R1, [R0,#0xC]
        STR      R1, [R0,#0xC]

        BX       LR

KEY_0:
        // Toggle RUN on KEY0 press
        LDR     R0, RUN
        EOR     R0, #1
        STR     R0, RUN

        B       EXIT_KEY_ISR

KEY_1: 
      // Double Speed -> half the timer value 

      LDR     R0, =TIMER_BASE
      LDR     R1, [R0, #0x8]    // get the lower count
      LDR     R2, [R0,#0xC]     // get the upper count

      // add them into one number
      LSL     R2, #16
      ORR     R2, R1

      // divide by 2
      LSR     R2, #1

      // store the number back into the timer
      STR     R2, [R0, #0x8]      //lower part

      LSR     R2, #16
      STR     R2, [R0,#0xC]       //upper part

      MOV     R1, #0b0101
      STR     R1, [R0, #0x4]

      B EXIT_KEY_ISR

KEY_2:
      // Half Speed -> double the timer value 

      LDR     R0, =TIMER_BASE
      LDR     R1, [R0, #0x8]    // get the lower count
      LDR     R2, [R0,#0xC]     // get the upper count

      // add them into one number
      LSL     R2, #16
      ORR     R2, R1

      // multiply by 2
      LSL       R2, #1

      STR       R2, [R0, #0x8]      //lower part

      LSR       R2, #16
      STR       R2, [R0,#0xC]       //upper part

      MOV       R1, #0b0101
      STR       R1, [R0, #0x4]

      B         EXIT_KEY_ISR


TIMER_ISR:  

      // Add the value of RUN to COUNT
      LDR       R0, RUN
      LDR       R1, COUNT

      ADD       R1, R0
      STR       R1, COUNT

      // Restart timer
      LDR       R0, =TIMER_BASE

      MOV       R1, #0
      STR       R1, [R0]

      MOV       R1, #0b0101
      STR       R1, [R0, #0x4]

      BX        LR

// Configure the Interval Timer to create interrupts at 0.25 second intervals
CONFIG_TIMER:    
      
      // Load Number to result in 0.25 intervals
      LDR       R0, =TIMER_BASE
      
      LDR       R1, =0x7840
      STR       R1, [R0, #0x8]

      LDR       R1, = 0x17D
      STR       R1, [R0,#0xC]

      MOV       R1, #0b0101
      STR       R1, [R0, #0x4]

      BX        LR

// Generate KEY Interrupts
CONFIG_KEYS:

      LDR       R0, =0xFF200058
      MOV       R1, #0b1111     // Enable interrupt bits
      STR       R1, [R0]           
      BX        LR                  


// Global variables
                  .global  COUNT                           
COUNT:            .word    0x0              // used by timer
                  .global  RUN              // used by pushbutton KEYs
RUN:              .word    0x1              // initial value to increment
                                            // COUNT


//===================================================================================
// Including all code from other files


SERVICE_UND:   
                B      SERVICE_UND
                
SERVICE_SVC:   
                B      SERVICE_SVC
                
SERVICE_ABT_DATA:
                B      SERVICE_ABT_DATA
                
SERVICE_ABT_INST:
                B      SERVICE_ABT_INST
                
SERVICE_FIQ:   
                B      SERVICE_FIQ

/* 
 * Configure the Generic Interrupt Controller (GIC)
*/
                .global   CONFIG_GIC
CONFIG_GIC:
                PUSH      {LR}
                /* Configure the A9 Private Timer interrupt, FPGA KEYs, and FPGA Timer
                /* CONFIG_INTERRUPT (int_ID (R0), CPU_target (R1)); */
                MOV      R0, #MPCORE_PRIV_TIMER_IRQ
                MOV      R1, #CPU0
                BL         CONFIG_INTERRUPT
                MOV      R0, #INTERVAL_TIMER_IRQ
                MOV      R1, #CPU0
                BL         CONFIG_INTERRUPT
                MOV      R0, #KEYS_IRQ
                MOV      R1, #CPU0
                BL         CONFIG_INTERRUPT

                /* configure the GIC CPU interface */
                LDR      R0, =0xFFFEC100      // base address of CPU interface
                /* Set Interrupt Priority Mask Register (ICCPMR) */
                LDR      R1, =0xFFFF          // enable interrupts of all priorities levels
                STR      R1, [R0, #0x04]
                /* Set the enable bit in the CPU Interface Control Register (ICCICR). This bit
                 * allows interrupts to be forwarded to the CPU(s) */
                MOV      R1, #1
                STR      R1, [R0]
    
                /* Set the enable bit in the Distributor Control Register (ICDDCR). This bit
                 * allows the distributor to forward interrupts to the CPU interface(s) */
                LDR      R0, =0xFFFED000
                STR      R1, [R0]    
    
                POP        {PC}
/* 
 * Configure registers in the GIC for an individual interrupt ID
 * We configure only the Interrupt Set Enable Registers (ICDISERn) and Interrupt 
 * Processor Target Registers (ICDIPTRn). The default (reset) values are used for 
 * other registers in the GIC
 * Arguments: R0 = interrupt ID, N
 *            R1 = CPU target
*/
CONFIG_INTERRUPT:
                PUSH      {R4-R5, LR}
    
                /* Configure Interrupt Set-Enable Registers (ICDISERn). 
                 * reg_offset = (integer_div(N / 32) * 4
                 * value = 1 << (N mod 32) */
                LSR      R4, R0, #3                     // calculate reg_offset
                BIC      R4, R4, #3                     // R4 = reg_offset
                LDR      R2, =0xFFFED100
                ADD      R4, R2, R4                     // R4 = address of ICDISER
    
                AND      R2, R0, #0x1F                  // N mod 32
                MOV      R5, #1                        // enable
                LSL      R2, R5, R2                     // R2 = value

                /* now that we have the register address (R4) and value (R2), we need to set the
                 * correct bit in the GIC register */
                LDR      R3, [R4]                        // read current register value
                ORR      R3, R3, R2                     // set the enable bit
                STR      R3, [R4]                        // store the new register value

                /* Configure Interrupt Processor Targets Register (ICDIPTRn)
                  * reg_offset = integer_div(N / 4) * 4
                  * index = N mod 4 */
                BIC      R4, R0, #3                     // R4 = reg_offset
                LDR      R2, =0xFFFED800
                ADD      R4, R2, R4                     // R4 = word address of ICDIPTR
                AND      R2, R0, #0x3                  // N mod 4
                ADD      R4, R2, R4                     // R4 = byte address in ICDIPTR

                /* now that we have the register address (R4) and value (R2), write to (only)
                 * the appropriate byte */
                STRB      R1, [R4]
    
                POP      {R4-R5, PC}
                
/* This files provides address values that exist in the system */

/* Memory */
        .equ  DDR_BASE,               0x00000000
        .equ  DDR_END,              0x3FFFFFFF
        .equ  A9_ONCHIP_BASE,         0xFFFF0000
        .equ  A9_ONCHIP_END,        0xFFFFFFFF
        .equ  SDRAM_BASE,             0xC0000000
        .equ  SDRAM_END,            0xC3FFFFFF
        .equ  FPGA_ONCHIP_BASE,      0xC8000000
        .equ  FPGA_ONCHIP_END,      0xC803FFFF
        .equ  FPGA_CHAR_BASE,         0xC9000000
        .equ  FPGA_CHAR_END,        0xC9001FFF

/* Cyclone V FPGA devices */
        .equ  LEDR_BASE,             0xFF200000
        .equ  HEX3_HEX0_BASE,        0xFF200020
        .equ  HEX5_HEX4_BASE,        0xFF200030
        .equ  SW_BASE,               0xFF200040
        .equ  KEY_BASE,              0xFF200050
        .equ  JP1_BASE,              0xFF200060
        .equ  JP2_BASE,              0xFF200070
        .equ  PS2_BASE,              0xFF200100
        .equ  PS2_DUAL_BASE,         0xFF200108
        .equ  JTAG_UART_BASE,        0xFF201000
        .equ  JTAG_UART_2_BASE,      0xFF201008
        .equ  IrDA_BASE,             0xFF201020
        .equ  TIMER_BASE,            0xFF202000
        .equ  AV_CONFIG_BASE,        0xFF203000
        .equ  PIXEL_BUF_CTRL_BASE,   0xFF203020
        .equ  CHAR_BUF_CTRL_BASE,    0xFF203030
        .equ  AUDIO_BASE,            0xFF203040
        .equ  VIDEO_IN_BASE,         0xFF203060
        .equ  ADC_BASE,              0xFF204000

/* Cyclone V HPS devices */
        .equ   HPS_GPIO1_BASE,       0xFF709000
        .equ   HPS_TIMER0_BASE,      0xFFC08000
        .equ   HPS_TIMER1_BASE,      0xFFC09000
        .equ   HPS_TIMER2_BASE,      0xFFD00000
        .equ   HPS_TIMER3_BASE,      0xFFD01000
        .equ   FPGA_BRIDGE,          0xFFD0501C

/* ARM A9 MPCORE devices */
        .equ   PERIPH_BASE,          0xFFFEC000   /* base address of peripheral devices */
        .equ   MPCORE_PRIV_TIMER,    0xFFFEC600   /* PERIPH_BASE + 0x0600 */

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

            .equ      EDGE_TRIGGERED,         0x1
            .equ      LEVEL_SENSITIVE,        0x0
            .equ      CPU0,                     0x01   // bit-mask; bit 0 represents cpu0
            .equ      ENABLE,                   0x1

            .equ      KEY0,                   0b0001
            .equ      KEY1,                   0b0010
            .equ      KEY2,                     0b0100
            .equ      KEY3,                     0b1000

            .equ      RIGHT,                  1
            .equ      LEFT,                     2

            .equ      USER_MODE,               0b10000
            .equ      FIQ_MODE,               0b10001
            .equ      IRQ_MODE,               0b10010
            .equ      SVC_MODE,               0b10011
            .equ      ABORT_MODE,               0b10111
            .equ      UNDEF_MODE,               0b11011
            .equ      SYS_MODE,               0b11111

            .equ      INT_ENABLE,               0b01000000
            .equ      INT_DISABLE,            0b11000000
/* This files provides interrupt IDs */

/* FPGA interrupts (there are 64 in total; only a few are defined below) */
            .equ   INTERVAL_TIMER_IRQ,          72
            .equ   KEYS_IRQ,                   73
            .equ   FPGA_IRQ2,                   74
            .equ   FPGA_IRQ3,                   75
            .equ   FPGA_IRQ4,                   76
            .equ   FPGA_IRQ5,                   77
            .equ   AUDIO_IRQ,                   78
            .equ   PS2_IRQ,                   79
            .equ   JTAG_IRQ,                   80
            .equ   IrDA_IRQ,                   81
            .equ   FPGA_IRQ10,                  82
            .equ   JP1_IRQ,                     83
            .equ   JP2_IRQ,                     84
            .equ   FPGA_IRQ13,                  85
            .equ   FPGA_IRQ14,                  86
            .equ   FPGA_IRQ15,                  87
            .equ   FPGA_IRQ16,                  88
            .equ   PS2_DUAL_IRQ,               89
            .equ   FPGA_IRQ18,                  90
            .equ   FPGA_IRQ19,                  91

/* ARM A9 MPCORE devices (there are many; only a few are defined below) */
            .equ   MPCORE_GLOBAL_TIMER_IRQ,   27
            .equ   MPCORE_PRIV_TIMER_IRQ,      29
            .equ   MPCORE_WATCHDOG_IRQ,         30

/* HPS devices (there are many; only a few are defined below) */
            .equ   HPS_UART0_IRQ,               194
            .equ   HPS_UART1_IRQ,               195
            .equ   HPS_GPIO0_IRQ,             196
            .equ   HPS_GPIO1_IRQ,             197
            .equ   HPS_GPIO2_IRQ,             198
            .equ   HPS_TIMER0_IRQ,            199
            .equ   HPS_TIMER1_IRQ,            200
            .equ   HPS_TIMER2_IRQ,            201
            .equ   HPS_TIMER3_IRQ,            202
            .equ   HPS_WATCHDOG0_IRQ,           203
            .equ   HPS_WATCHDOG1_IRQ,           204

                .end