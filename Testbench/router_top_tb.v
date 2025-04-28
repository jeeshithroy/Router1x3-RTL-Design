module router_top_tb();
	reg clock, resetn;
	reg	read_enb_0, read_enb_1, read_enb_2;
	reg [7:0]data_in;
	reg pkt_valid;
	wire [7:0] data_out_0, data_out_1, data_out_2;
	wire vld_out_0, vld_out_1, vld_out_2;
	wire error, busy;
	
	//Instantiate UUT
	router_top UUT(clock, resetn, read_enb_0, read_enb_1, read_enb_2, data_in, pkt_valid, data_out_0, data_out_1, data_out_2,
					vld_out_0, vld_out_1, vld_out_2, error, busy);
					
	// Clock generation
    initial begin
        clock = 0;
        forever #5 clock = ~clock; // 10 ns clock period
    end
	
	//Task to apply reset
	task reset;
		begin
			@(negedge clock)
			resetn =1'b0;
			@(negedge clock)
			resetn =1'b1;
		end
	endtask
	
	// Task to initialize signals
    task initialize;
        begin
			{read_enb_0,read_enb_1,read_enb_2} = 3'b0;
            data_in = 8'h0;
			pkt_valid = 0;			
			end
	endtask
	
	//Task for packet generation
	task pkt_gen(input [5:0]payload_len,  input [1:0] addr);
		reg [7:0] payload_data, parity, header;
		integer i;
		begin	
			wait(~busy)
			begin
				@(negedge clock)
				pkt_valid = 1'b1;
				header = {payload_len,addr};
				parity = 8'h0 ^ header;
				data_in = header;
			end
			
			@(negedge clock)
			for(i=0; i<payload_len; i=i+1)
				begin
					wait(~busy)
					begin
						@(negedge clock)
						payload_data = ($random)%256;
						data_in = payload_data;
						parity = parity ^ data_in;
					end
				end
				
			@(negedge clock);
			wait(~busy)
			pkt_valid = 0;
			data_in = parity;
		end
	endtask
	
	//Task for enabling read_enb
	task read(input [1:0] addr);
		@(negedge clock)
		begin
			case (addr)
				2'b00: 	begin
						read_enb_0 = 1'b1;  
						wait(~vld_out_0)   
						@(negedge clock)
						read_enb_0 = 1'b0;   
						end
				2'b01: 	begin
						read_enb_1 = 1'b1;  
						wait(~vld_out_1)   
						@(negedge clock)
						read_enb_1 = 1'b0;   
						end
				2'b10: 	begin
						read_enb_2 = 1'b1;   
						wait(~vld_out_2)    
						@(negedge clock)
						read_enb_2 = 1'b0;   
						end
				default: begin
					// Address 2'b11 is not used, so handle as no-op
					@(negedge clock);  // Optionally add a delay or log an error
				end
			endcase
		end
	endtask
	
	//Test Sequence
	initial
		begin
		    initialize;
			reset;
			#10;
			pkt_gen(6'd5,2'b10);
            #100;
			read(2'b10);
            reset;
			//pkt_gen(6'd14,2'b00);
			//#100;
			//read(2'b00);
			//reset;
			pkt_gen(6'd18,2'b01);
			//#200;
			read(2'b01);
			#200; 
			reset;
			//pkt_gen(6'd8,2'b11);
			#700;
			
			$finish;
		end

endmodule
	