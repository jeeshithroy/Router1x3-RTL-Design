module router_reg_tb();
	reg clk,rstn,pkt_valid;
	reg [7:0]data_in;
	reg fifo_full, rst_int_reg, detect_addr;
	reg ld_state, laf_state, full_state, lfd_state;
	wire parity_done, low_pkt_valid;
	wire err;
	wire [7:0]dout;
	
	//Instantiate UUT
	router_reg UUT(clk, rstn, pkt_valid, data_in,
					fifo_full, rst_int_reg, detect_addr, 
					ld_state, laf_state, full_state, lfd_state,
					parity_done, low_pkt_valid,
					err, dout);
					
	// Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10 ns clock period
    end
	
	// Task to initialize signals
    task initialize;
        begin
            pkt_valid = 0;
            data_in = 8'h0;
			fifo_full = 0;
			rst_int_reg = 0;
			detect_addr = 0;
			ld_state = 0;
			laf_state = 0;
			full_state = 0;
			lfd_state = 0;			
			end
		endtask
	
	//Task to apply reset
	task reset();
		begin
			@(negedge clk)
			rstn =1'b0;
			@(negedge clk)
			rstn =1'b1;
		end
	endtask
	
	//Good packet
	task packet_generation;
		reg [7:0] payload_data, parity, header;
		reg [5:0] payload_len;
		reg [1:0] addr;
		integer i;
		begin	
			@(negedge clk)
			payload_len = 6'd7;
			addr = 2'b10;
			pkt_valid = 1'b1;
			detect_addr = 1'b1;
			header = {payload_len,addr};
			parity = 8'h0 ^ header;
			data_in = header;
			@(negedge clk)
			detect_addr =1'b0;
			lfd_state =1'b1;
			full_state =0;
			fifo_full = 0;
			laf_state = 0;
			for(i=0; i<payload_len; i=i+1)
				begin
					@(negedge clk)
					lfd_state = 0;
					ld_state = 1;
					payload_data = ($random)%256;
					data_in = payload_data;
					parity = parity ^ data_in;
				end
			@(negedge clk)
			pkt_valid = 0;
			data_in = parity;
			@(negedge clk)
			ld_state =0;
		end
	endtask
	
	//Bad packet generation
	task bad_pkt_generation;

		reg[7:0]payload_data,parity,header;
		reg[5:0]payload_len;
		reg[1:0]addr;
		
		integer i;
		begin
			@(negedge clk)
			payload_len=6'd5;
			addr=2'b10;
			pkt_valid=1;
			detect_addr =1;
			header={payload_len,addr};
			parity=0^header;
			data_in=header;
			@(negedge clk);
			detect_addr=0;
			lfd_state=1;
			full_state=0;
			fifo_full=0;
			laf_state=0;
			for(i=0;i<payload_len;i=i+1)
			begin
			@(negedge clk);
				lfd_state=0;
				ld_state=1;
				payload_data={$random}%256;
				data_in=payload_data;
				parity=parity^data_in;
			end
			@(negedge clk);
			pkt_valid=0;
			data_in=51;
			@(negedge clk);
			ld_state=0;
		end
	endtask
	
	//Test sequence
	initial
		begin
		initialize;
		reset;
		packet_generation;
		reset;
		bad_pkt_generation;
		#20
		 
		$finish;
	end
	
endmodule

			