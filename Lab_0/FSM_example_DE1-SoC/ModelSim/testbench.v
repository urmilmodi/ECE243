`timescale 1ns / 1ps

module testbench ( );

	parameter CLOCK_PERIOD = 20;

	reg [9:0] SW;
	reg [1:0] KEY;
	wire [9:0] LEDR;

	initial begin
		KEY[1] <= 1'b0;
	end // initial
	always @ (*)
	begin : Clock_Generator
		#((CLOCK_PERIOD) / 2) KEY[1] <= ~KEY[1];
	end
	
	initial begin
		KEY[0] <= 1'b0;
		#20 KEY[0] <= 1'b1;
	end // initial

	initial begin
		SW <= 10'h0;
		#40 SW	<= 10'b1000000001;
		#20 SW	<= 10'b0000000001;
		#120 SW	<= 10'b1000000101;
		#20 SW	<= 10'b0000000101;
	end // initial

	FSM_control U1 (SW, KEY, LEDR);

endmodule
