.define LED_ADDRESS 0x1000
.define SW_ADDRESS 0x3000

	//Counter = 0
	mvt r0, #0xFF00 

	//Initialise ports
	mvt r3, #LED_ADDRESS 
	mvt r4, #SW_ADDRESS


		 //Counter +1 
MAIN: 	add r2, #1 
		st r2, [r3] //Send value of r2 to LED
		mv pc, #SWITCH

		//Load switch into r0 
SWITCH: ld r0, [r4] 
		//Add 1 if rate is 0 
		add r0, #1
		mv pc, #DELAY
		
DELAY: mvt r6, #0xFF00
	   add r6, #0xFF
	
	
		//r6 -1, loop while r6 !=0 
LOOP:	sub r6, #1 
		bne #LOOP
		//r0 -1, delay rate, loop while r0 != 0
		sub r0, #1
		bne #DELAY
		mv pc, #MAIN