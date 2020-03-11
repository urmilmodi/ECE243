// Data written to registers R0 to R5 are sent to the H digits
module seg7 (Data, Addr, Sel, Resetn, Clock, H5, H4, H3, H2, H1, H0);
    input [6:0] Data;
    input [2:0] Addr;
    input Sel, Resetn, Clock;
    output [6:0] H5, H4, H3, H2, H1, H0;
    wire [6:0] R0, R1, R2, R3, R4, R5;	
    wire [6:0] nData;
    assign nData = ~Data;

    regne reg_R0 (nData, Clock, Resetn, Sel & (Addr == 3'b000), H0);
	 // ... add code here
    regne reg_R1 (nData, Clock, Resetn, Sel & (Addr == 3'b001), R1);
    regne reg_R2 (nData, Clock, Resetn, Sel & (Addr == 3'b010), R2);
    regne reg_R3 (nData, Clock, Resetn, Sel & (Addr == 3'b011), R3);
    regne reg_R4 (nData, Clock, Resetn, Sel & (Addr == 3'b100), R4); 
    regne reg_R5 (nData, Clock, Resetn, Sel & (Addr == 3'b101), R5);
	
    assign H5 = R5; 
    assign H4 = R4; 
    assign H3 = R3; 
    assign H2 = R2; 
    assign H1 = R1; 
    assign H0 = R0;
endmodule

module regne (R, Clock, Resetn, E, Q);
    parameter n = 7;
    input [n-1:0] R;
    input Clock, Resetn, E;
    output [n-1:0] Q;
    reg [n-1:0] Q;	
	
    always @(posedge Clock)
        if (Resetn == 0)
            Q <= {n{1'b0}};  // turn OFF all segments on reset
        else if (E)
            Q <= R;
endmodule
