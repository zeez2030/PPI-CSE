`timescale 1 ns / 1 ps
module PPI(PA,PB,PC,rdb,a0,a1,wrb,data,reset);
		
		input rdb,wrb,a0,a1,reset; 
		inout [7:0] PA,PB,PC,data;
		
		//Control word register
		reg [7:0] CWR;
		
		//address bus
		
		wire [2:0] address;
		
		assign address = {a1,a0};
		
		//Control signals 
		reg portAenable , portBenable;
		reg[7:0] portCenable;
		
		// tri-state output bus for data
		
		reg[7:0] out_data;
		
		assign data=out_data;
		
		//declaration for tristate output bus 
		//for PA,PB,PC
		
		reg[7:0] out_portA , out_portB,out_portC;
		assign PA=out_portA;
		assign PB=out_portB;
		assign PC=out_portC;
		
		// internal latching of data
		
		reg[7:0] latch_data;
		
		//latching PA,PB and PC
		
		reg[7:0] latch_portA , latch_portB,latch_portC;
		
		// write control signals , read control signals
		
		wire wrb_portA,wrb_portB;
		wire rdb_portA,rdbportB;
		
		always@(posedge reset or posedge wrb)
		begin
			if(reset)
				begin
					//during reset CWR is set to mode 0 with portA, Port B and portc as input
					CWR<= 8'b10011110;
				end
			else
			//rising edge of wrb
			begin
				if(address == 3'b011)
				begin
					CWR[7:0] <= data[7:0];
				end
			end
		end
		
		//for latching in of data when wrb is at falling 
		//edge for mode 0 port 
		
		always @(posedge reset or negedge wrb)
		begin
			if(reset)
				latch_data[7:0] <= 8'h00;
			else //falling edge of wrb
				latch_data[7:0] <= data[7:0];
		end
		
		/*
			latching in data when rdb is at falling edge for mode 0 port
			input , latch in portA input and portB ,portC
				
		*/
		always @(negedge rdb or posedge reset)
		begin
			if(reset)
				begin
					latch_portA[7:0] <= 8'h00;
					latch_portB[7:0] <= 8'h00;
					latch_portC[7:0] <= 8'h00;
				end
			else
				begin
					latch_portA[7:0] <= PA[7:0];
					latch_portB[7:0] <= PB[7:0];
					latch_portC[7:0] <= PC[7:0];
				end
		end
		
		// for driving of out_data which is a tristate bus
		// for data inout
		// out_data is driven when in read mode for mode 0
		
		always @(reset or rdb or CWR or portAenable or address or latch_portA or
					latch_portB or portBenable or portCenable or latch_portC)
		begin
			
			if(reset)
				out_data[7:0] = 8'hzz;
				
			else if(~rdb & (address == 2'b11))
				out_data[7:0] = CWR[7:0];
			
			else if(~rdb & (CWR[6:5] == 2'b00) & ~portAenable
						&(address == 2'b00))
						out_data = latch_portA; //portA mode0 input
			else if(~rdb & (CWR[6:5] == 2'b00) & ~portBenable
						&(address == 2'b01))
						out_data = latch_portB; //portB mode0 input
			else if(~rdb & (CWR[6:5] == 2'b00) & (portCenable==8'h00)
						&(address == 2'b10))
						out_data = latch_portC; //portC mode0 input
			else if(~rdb & (CWR[6:5] == 2'b00) & (portCenable==8'h0f)
						&(address == 2'b10))
						out_data = {latch_portC[7:4] ,4'hz}; //portC mode0 input
																		//Cupper input
			else if(~rdb & (CWR[6:5] == 2'b00) & (portCenable==8'hf0)
						&(address == 2'b10))
						out_data = { 4'hz,latch_portC[3:0]}; //portC mode0 input
																		//Clower input
			else 
				out_data=8'hzz;
		end
		
		//generation of PA,PB,PC enable signals
		
		always @(CWR or reset)
		begin
			if(reset)
				begin
					//during reset ports A,B and C are inputs
					portAenable=0;
					portBenable=0;
					portCenable=8'h00;
				end
			else
				begin
						if (CWR[6:5] == 2'b00)
							begin
								// this is mode 0
								if (~CWR[4])
									portCenable [7:4] = 4'hf; // port C upper
								// is output
								else
									portCenable [7:4] = 4'h0; // port C upper
								// is input
								if (~CWR[3])
									portCenable [3:0] = 4'hf; // port C lower
								// is output
								else
									portCenable [3:0] = 4'h0; // port C lower
								// is input
								if (~CWR[2])
									portBenable = 1; // port B is output
								else
									portBenable = 0; // port B is input
								if (~CWR[1])
									portAenable = 1; // port C is output
								else
									portAenable = 0; // port C is input
						end	
				end
			end
				
			// writing to portA
			always @ (reset or wrb or address or CWR or
							portAenable or portBenable or portCenable  or latch_data)
				begin
					if (reset)
						begin
							out_portA [7:0] = 8'bzzzzzzzz;
							out_portB [7:0] = 8'bzzzzzzzz;
							out_portC [7:0] = 8'bzzzzzzzz;
						end
					else if (~wrb & (address == 2'b00) & (CWR[6:5] ==
								2'b00) & portAenable) // mode 0
						out_portA [7:0] = latch_data [7:0]; // writing
																		// to portA
					else if (~wrb & (address == 2'b01) & (CWR[6:5] ==
								2'b00) & portBenable) // mode 0
						out_portB [7:0] = latch_data [7:0]; // writing
																		// to portB
					else if (~wrb & (address == 2'b10) & (CWR[6:5] ==
								2'b00))
							begin
								if(portCenable==8'hff)
									out_portC [7:0] = latch_data [7:0]; 
								else if(portCenable == 8'h0f)
									out_portC[7:0]={4'bzzz ,latch_data[3:0]};
								
								else if(portCenable == 8'hf0)
									out_portC[7:0]={latch_data[7:4] ,4'bzzzz};
									
								else
									out_portC [7:0] = 8'bzzzzzzzz;		
							end
					else
						begin
							out_portA [7:0] = 8'bzzzzzzzz;
							out_portB [7:0] = 8'bzzzzzzzz;
							out_portC [7:0] = 8'bzzzzzzzz;	
						end
				end
	endmodule
	