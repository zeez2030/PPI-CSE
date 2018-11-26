
  `timescale 1 ns / 1 ps
module PPI(PA,PB,PC,cs,a0,a1,rd,wr,D,reset);
		
		input rd,wr,a0,a1,reset;
		input cs; //cs is active low signal 
		input [7:0] D;
		inout [7:0] PA,PB,PC;
		wire outnotin;
		BSR c(PC,a0,a1,wr,D,outnotin);  
		

endmodule
module BSR(out,a0,a1,wr,D,outnotin);
	output wire[7:0] out;
	input  a0,a1,wr;
	input wire  outnotin ;
	input  [7:0] D;
	 wire [2:0] x;
	assign  x = D[3:1];
	assign outnotin = (a0 ==1 & a1==1  & ~wr==1 & D[7]==0)? 1:0;
	assign out=(outnotin)? D[0] : 3'bzzz;
endmodule

module test;
	reg[7:0] D;
	reg reset,a0,a1,wr;
	
	PPI A(PA,PB,PC,cs,a0,a1,rd,wr,D,reset);
	initial
	begin
		$monitor("%b %b  %b",A.PC ,D,reset);
		
		#10 D=8'b0xxx0011; reset=0;a1=1;a0=1;wr=0;
		
		#10 D=8'b0xxx0100; reset=0;a1=1;a0=1;wr=0;
		
		#10 D=8'b0xxx0011; reset=0;a1=1;a0=1;wr=0;
		
		#10 D=8'b0xxx1110; reset=0;a1=1;a0=1;wr=0;

		#10 D=8'b0xxx0011; reset=0;a1=1;a0=1;wr=0;
		
	end
	endmodule
	