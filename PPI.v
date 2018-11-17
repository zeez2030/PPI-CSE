// Verilog Test Fixture Template

  `timescale 1 ns / 1 ps
module andd(x,y,z);

		input x,y;
		output z;
		
		assign z=x&y;

endmodule
