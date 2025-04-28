module router_fifo(clock, resetn, write_enb, read_enb, soft_reset, data_in, lfd_state, empty, data_out, full);

	input clock, resetn, write_enb, read_enb, soft_reset, lfd_state;
	input [7:0]data_in;
	output wire empty, full;
	output reg [7:0]data_out;
	
	reg [4:0]rd_ptr;
	reg [4:0]wt_ptr;
	reg [8:0] mem[15:0];
	reg [5:0]counter;
	
	reg temp;
	integer i;
	
	//fifo full and empty logic
	assign empty = (wt_ptr ==  rd_ptr)? 1'b1: 1'b0;
	assign full = ((wt_ptr[4] != rd_ptr[4]) && (wt_ptr[3:0] ==  rd_ptr[3:0]))? 1'b1: 1'b0;
	
	always@(posedge clock)
		begin
			if(!resetn)
				temp <= 0;
			else
				temp <= lfd_state;  //delaying the lfd_state by 1 clock to latch the header byte
		end
		
	
	//counter logic
	always@(posedge clock)
		begin
			if(!resetn)
				counter <= 0;
			else if(soft_reset)
				counter <= 0;
			else if(write_enb && !full && mem[rd_ptr[3:0]][8] == 1'b1)
				counter <= mem[rd_ptr[3:0]][7:2] + 1'b1;
			else if(read_enb && !empty)
				counter <= counter - 1'b1;
			else
				counter <= counter;		
		end
		
	//write logic
	always@(posedge clock)
		begin
			if(!resetn)
				begin	
					for(i=0; i<16; i=i+1)
						mem[i] <= 0;
					wt_ptr <= 0;
				end
			else if(soft_reset)
				begin	
					for(i=0; i<16; i=i+1)
						mem[i] <= 0;
					wt_ptr <= 0;
				end
			else if(write_enb && !full)
				begin	
					{mem[wt_ptr[3:0]][8],mem[wt_ptr[3:0]][7:0]} <= {temp,data_in};
					wt_ptr <= wt_ptr + 1'b1;
				end
		end
	

	//there should be no high impedace state in synthesizable code	
	//read logic
	always@(posedge clock)
		begin	
			if(!resetn)
				begin
					data_out <= 0;
					rd_ptr <= 0;
				end
			else if(soft_reset)
				data_out <= 8'b0;
			else if(counter == 0 && data_out != 0)
				data_out <= 8'b0;
			else if(read_enb && !empty)
				begin
					data_out <= mem[rd_ptr[3:0]][7:0];
					rd_ptr <= rd_ptr + 1'b1;
				end
			else
				data_out <= 8'b0;
		end

endmodule