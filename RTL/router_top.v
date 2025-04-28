module router_top(
	input clock, resetn, 
	input read_enb_0, read_enb_1, read_enb_2,
	input [7:0]data_in,
	input pkt_valid,
	output [7:0] data_out_0, data_out_1, data_out_2,
	output vld_out_0, vld_out_1, vld_out_2,
	output error, busy
	);
	
	
	//intermediate wire and reg connections
	//xilinx will create wires for each intermediate input or output which are 1 bit
	//so no need to mention all the wires seperately 
	//But if the value is more than 1-bit then it should be mentioned
	//Here in this case only write_enb from synchronizer 
	// and dout from register needs to be mentioned as wire.
	wire [2:0] write_enb;
	wire [7:0] d_out;
	
	//Instantiate all the submodules
	router_fsm FSM(clock, resetn, pkt_valid, parity_done, data_in[1:0], soft_reset_0, soft_reset_1, soft_reset_2, 
					fifo_full, low_pkt_valid, empty_0, empty_1, empty_2, busy, detect_add, 
					ld_state, laf_state, full_state, write_enb_reg, rst_int_reg, lfd_state);
	
	router_sync SYNCRONIZER(clock, resetn, detect_add, write_enb_reg, data_in[1:0], read_enb_0, read_enb_1, read_enb_2,
					empty_0, empty_1, empty_2, full_0, full_1, full_2, vld_out_0, vld_out_1, vld_out_2, 
					write_enb, fifo_full, soft_reset_0, soft_reset_1, soft_reset_2);
	
	router_reg REGISTER(clock, resetn, pkt_valid, data_in, fifo_full, rst_int_reg, 
					detect_add, ld_state, laf_state, full_state, lfd_state, parity_done, low_pkt_valid, error, d_out);
	
	router_fifo FIFO0(clock, resetn, write_enb[0], read_enb_0, soft_reset_0, d_out, lfd_state, empty_0, data_out_0, full_0);
	router_fifo FIFO1(clock, resetn, write_enb[1], read_enb_1, soft_reset_1, d_out, lfd_state, empty_1, data_out_1, full_1);
	router_fifo FIFO2(clock, resetn, write_enb[2], read_enb_2, soft_reset_2, d_out, lfd_state, empty_2, data_out_2, full_2);
	
endmodule
	
