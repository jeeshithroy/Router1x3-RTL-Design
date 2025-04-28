module router_fsm(
	input clock, resetn, pkt_valid, parity_done,
	input [1:0] data_in,
	input soft_reset_0, soft_reset_1, soft_reset_2,
	input fifo_full, low_pkt_valid, 
	input fifo_empty_0, fifo_empty_1, fifo_empty_2,
	output busy,
	output detect_add, ld_state, laf_state, full_state, write_enb_reg,
	output rst_int_reg, lfd_state);
	
	parameter 
			decode_address = 3'b000,
			load_first_data = 3'b001,
			wait_till_empty = 3'b010,
			load_data = 3'b011,
			fifo_full_state = 3'b100,
			load_after_full = 3'b101,
			load_parity = 3'b110,
			check_pairty_error = 3'b111;
			
	reg [2:0] next_state, present_state;
	reg [1:0]address;
	
	always@(posedge clock)
		begin
			if(!resetn)
				address <= 2'b0;
			else if(detect_add)
				address <= data_in;
		end
	
	//present state logic
	always@(posedge clock)
		begin
			if(!resetn)
				present_state <= decode_address;
			else if(((soft_reset_0) && (data_in[1:0]==2'b00)) || ((soft_reset_1) && (data_in[1:0]==2'b01)) || ((soft_reset_2) && (data_in[1:0]==2'b10)))
				present_state <= decode_address;
			else
				present_state <= next_state;
		end
	
	//next_state logic
	always@(*)
		begin
			case(present_state)
				decode_address: begin	
								if((pkt_valid && (data_in[1:0]==0) && fifo_empty_0) ||
									(pkt_valid && (data_in[1:0]==1) && fifo_empty_1)||
									(pkt_valid && (data_in[1:0]==2) && fifo_empty_2))
											next_state = load_first_data; 						//lfd state
								
								else if((pkt_valid && (data_in[1:0]==0) && (~fifo_empty_0)) ||
										(pkt_valid && (data_in[1:0]==1) && (~fifo_empty_1)) ||
										(pkt_valid && (data_in[1:0]==2) && (~fifo_empty_2)))
											next_state = wait_till_empty; 						//wait till empty state
											
								else 
									next_state = decode_address; 								//decode address state(same state)
								end
										
				load_first_data: begin	
									next_state = load_data;										//load data
								end
									
				wait_till_empty: begin
										if((fifo_empty_0 && (address==2'b00)) ||
											(fifo_empty_1 && (address==2'b01))||
											(fifo_empty_2 && (address==2'b10)))
												next_state = load_first_data;						//load first data state
										else
												next_state = wait_till_empty;						//wait till empty state
									end
				
				load_data: begin
							if(fifo_full)
								next_state = fifo_full_state;
							else if(!fifo_full && !pkt_valid)
								next_state = load_parity;
							else
								next_state = load_data;
							end
							
				fifo_full_state: begin
									if(!fifo_full)
										next_state = load_after_full;
									else if(fifo_full)
										next_state = fifo_full_state;
								end
								
				load_after_full: begin
									if(!parity_done && !low_pkt_valid)
										next_state = load_data;
									else if (!parity_done && low_pkt_valid)
										next_state = load_parity;
									else if(parity_done)
										next_state = decode_address;
								end
								
				load_parity: begin
								next_state = check_pairty_error;
							end
							
				check_pairty_error: begin
										if(fifo_full)
											next_state = fifo_full_state;
										else
											next_state = decode_address;
									end
									
				default: next_state = decode_address;
				
			endcase
		end
			
		//output logic
		assign busy = ((present_state == load_first_data) || (present_state == load_parity) ||
						(present_state == fifo_full_state) || (present_state == load_after_full) || 
						(present_state == wait_till_empty) || (present_state == check_pairty_error)) ? 1: 0;
		assign detect_add = ((present_state == decode_address) ? 1:0);
		assign lfd_state = (present_state == load_first_data) ? 1:0;
		assign ld_state = (present_state == load_data) ? 1:0;
		assign write_enb_reg = ((present_state == load_data) || (present_state == load_after_full) || (present_state == load_parity)) ? 1:0;
		assign full_state = (present_state == fifo_full_state)? 1:0;
		assign laf_state = (present_state == load_after_full)? 1:0;
		assign rst_int_reg = (present_state == check_pairty_error)?1:0;
		
endmodule
							
									
			