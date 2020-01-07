`timescale 1ns / 1ps

module testbench ( );

	reg [15:0] A, B, C, D;
	reg [1:0] S;
	wire [15:0] M;

	initial begin
		A <= 0; B <= 1; C <= 2; D <= 3; S = 0;
		#20 S = 1;
		#20 S = 2;
		#20 S = 3;
		#20 A <= 16'hfff0; B <= 16'hfff1; C <= 16'hfff2; D <= 16'hfff3; S = 3;
		#20 S = 2;
		#20 S = 1;
		#20 S = 0;
	end // initial

	nbit_4to1_mux U1 (A, B, C, D, S, M);

endmodule
