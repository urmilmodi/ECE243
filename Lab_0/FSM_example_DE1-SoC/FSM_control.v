// An FSM that controls the cookie machine
// KEY0 is the active low synchronous reset, KEY1 is the clock
// SW9 is Run, SW0 is Sensor[0], SW1 is Sensor[1], SW2 is Sensor[2]
// The z output appears on LEDR9, and the state FFs appear on LEDR1..0
module FSM_control (SW, KEY, LEDR);
	input [9:0] SW;
	input [1:0] KEY;
	output [9:0] LEDR;

	wire Clock, Resetn, Run, R;
	reg New, Wrap, Done;
	wire [2:0] Sensor;								// the three sensors
	wire [1:0] Sum;
	reg [2:0] y_Q, Y_D;

	assign Resetn = KEY[0];
	assign Clock = KEY[1];
	assign Run = SW[9];
	assign Sensor = SW[2:0];

	parameter T0 = 3'b000, T1 = 3'b001, T2 = 3'b010, T3 = 3'b011, T4 = 3'b100;
		
	// Control FSM state table
	always @(Run, Done, y_Q)
	begin: state_table
		case (y_Q)
			T0:
				if (!Run) Y_D = T0;
			 	else Y_D = T1;
			T1:
 				Y_D = T2;
			T2:
				if (Done) Y_D = T0;
				else Y_D = T3;
			T3:
 				Y_D = T4;
			T4:
				Y_D = T0;
			default:
				Y_D = 3'bxxx;
		endcase
	end // state_table

	// Control FSM outputs
	always @(*)
	begin: FSM_outputs
		Done = 1'b0; New = 1'b0; Wrap = 1'b0; 	// all signals need a default value
		case (y_Q)
			T0:
				New = Run;			// get a new cracker when Run is asserted
			T1:
				;				   	// wait cycle for sensors to evaluate
			T2:
				if (R)				// check cookie quality
					Done = 1'b1;	// bad cookie, don't wrap
			T3:
				Wrap = 1'b1;		// start wrapping
			T4:						
			begin
			 	Wrap = 1'b1;		// finish wrapping
	 			Done = 1'b1;
			end
			default:
				;
		endcase
	end // FSM_outputs	

	always @(posedge Clock)
		if (Resetn  == 1'b0)		// synchronous clear
			y_Q <= T0;
		else
			y_Q <= Y_D;

 	assign Sum = Sensor[0] + Sensor[1] + Sensor[2];
	assign R = Sum[1];			// R is equivalent to the carry-out

	assign LEDR[9] = Run;
	assign LEDR[8] = New;
	assign LEDR[7] = Wrap;
	assign LEDR[6] = Done;
	assign LEDR[5:3] = y_Q;
	assign LEDR[2:0] = Sensor;
endmodule
