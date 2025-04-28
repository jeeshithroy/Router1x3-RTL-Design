module router_reg(
	input clock, resetn, pkt_valid,
	input [7:0]data_in,
	input fifo_full, rst_int_reg, detect_add, 
	input ld_state, laf_state, full_state, lfd_state,
	output reg parity_done, low_pkt_valid,
	output reg error, 
	output reg [7:0]dout);
	
	reg [7:0] header_byte;
	reg [7:0] fifo_full_byte;
    reg [7:0] internal_parity;
    reg [7:0] packet_parity;
	
	//parity_done logic
	always@(posedge clock)
		begin
			if(!resetn || detect_add)
				parity_done <= 1'b0;
			else if(ld_state && !fifo_full && !pkt_valid)
				parity_done <= 1'b1;
			else if(laf_state && low_pkt_valid && !parity_done)
				parity_done <= 1'b1;
			else parity_done <= 1'b0;
		end
	
	//low packet valid logic
	always@(posedge clock)
		begin
			if(!resetn || rst_int_reg)
				low_pkt_valid <= 1'b0;
			else if(ld_state && !pkt_valid)
				low_pkt_valid <= 1'b1;
			else low_pkt_valid <= 1'b0;
		end
		

	always@(posedge clock)
		begin
			  if(!resetn)
				begin
					dout    		 <=0;
					header_byte  	 <=0;
					fifo_full_byte 	 <=0;
				end
			  else if(detect_add && pkt_valid && data_in[1:0]!=2'b11)
					header_byte <= data_in;
			  else if(lfd_state)
					dout <= header_byte;
			  else if(ld_state && !fifo_full)
					dout <= data_in;
			  else if(ld_state && fifo_full)
					fifo_full_byte <= data_in;
			  else if(laf_state)
					dout <= fifo_full_byte;
		end
	
	/*
	//data out register logic
	always@(posedge clock)
		begin	
			if(!resetn)
				dout <= 8'b0;
			else if(detect_add && pkt_valid && (data_in[1:0] != 2'b11))
				dout <= dout;
			else if(lfd_state)
				dout <= header_byte;
			else if(ld_state && !fifo_full)
				dout <= data_in;
			else if(ld_state && fifo_full)
				dout <= dout;
			else if(laf_state)
				dout <= full_state
				
				
				
				
	//header byte register logic			
	always@(posedge clock)
		begin	
			if(!resetn)
				header_byte <= 8'b0;
			else if(detect_add && pkt_valid && (data_in[1:0] != 2'b11))
				header_byte <= data_in;
			else header_byte <= 8'b0;
		end
		
		
		
	//fifo full state byte register logic	
	
	*/
	
		
	//internal parity register logic
	always@(posedge clock)
		begin
			if(!resetn || detect_add)
				internal_parity <= 8'b0;
			else if(lfd_state && pkt_valid)
				internal_parity <= internal_parity ^ header_byte;
			else if(pkt_valid && ld_state && !full_state)
				internal_parity <= internal_parity ^ data_in;
			else
				internal_parity <= internal_parity;
		end
		
	//packet parity register logic
	always@(posedge clock)
		begin	
			if(!resetn)
				packet_parity <= 8'b0;
			else if(detect_add)
				packet_parity <= 8'b0;
			else if(ld_state && !pkt_valid)
				packet_parity <= data_in;
			else	
				packet_parity <= packet_parity;
		end
	
	//error logic
	always@(posedge clock)
		begin
			if(!resetn)
	  			error<=0;
			else if(parity_done)
				begin
					if (internal_parity == packet_parity)
						error<=0;
					else 
						error<=1;
				end
			else
				error<=0;
		end

endmodule

				
				
				
			
	
	
	