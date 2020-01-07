// An n-bit 4-1to-1 multiplexer
module nbit_4to1_mux (A, B, C, D, S, M);
	parameter n = 16;
	input [n-1:0] A, B, C, D;
	input [1:0] S;
	output reg [n-1:0] M;

	always @ (*)
	begin
		if (S == 0) M = A;
		else if (S == 1) M = B;
		else if (S == 2) M = C;
		else M = D;
	end
endmodule
