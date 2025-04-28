module router_fsm_tb();
	reg clk, rstn, pkt_valid, parity_done;
	reg [1:0] data_in;
	reg soft_reset_0, soft_reset_1, soft_reset_2;
	reg fifo_full, low_pkt_valid;
	reg fifo_empty_0, fifo_empty_1, fifo_empty_2;
	wire busy;
	wire detect_addr, ld_state, laf_state, full_state, write_enb_reg;
	wire rst_int_reg, lfd_state;
	
	// Instantiate DUT
	router_fsm UUT(clk, rstn, pkt_valid, parity_done,
					data_in,
					soft_reset_0, soft_reset_1, soft_reset_2,
					fifo_full, low_pkt_valid, 
					fifo_empty_0, fifo_empty_1, fifo_empty_2,
					busy,
					detect_addr, ld_state, laf_state, full_state, write_enb_reg,
					rst_int_reg, lfd_state);
					
	// Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10 ns clock period
    end
	
	// Task to initialize signals
    task initialize;
        begin
            pkt_valid = 0;
            parity_done = 0;
            //data_in[1:0] = 2'b00;
			fifo_full = 0;
			low_pkt_valid = 0;
			fifo_empty_0 = 0;
			fifo_empty_1 = 0;
			fifo_empty_2 = 0;
			
        end
    endtask
	
	// Task to apply reset
    task reset;
        begin
            @(negedge clk)
                rstn = 0;
            @(negedge clk)
                rstn = 1;
				
        end
    endtask
	
	//detect_addr - load_first_data - load_Data - load_parity - check parity error - Detect address
	task t1(); 
		begin	
			@(negedge clk) //lfd_state
			pkt_valid = 1'b1;
			data_in[1:0] = 2'b01;
			fifo_empty_1 = 1'b1;
			@(negedge clk) //ld_state
			@(negedge clk) //load_parity
			fifo_full = 1'b0;
			pkt_valid = 1'b0;
			@(negedge clk) //cpe
			@(negedge clk) //detect_addr
			fifo_full = 1'b0;
			
			//@(negedge clk)
            //fifo_empty_1 = 1'b0; // Reset signals
		end
	endtask
	
	//detect_addr - load_first_data - load_Data - fifo_full_state - LAF - load_parity - check parity error - Detect address
	task t2(); 
		begin
			@(negedge clk) //lfd_state
			pkt_valid = 1'b1;
			data_in[1:0] = 2'b10;
			fifo_empty_2 = 1'b1;
			@(negedge clk) //ld_state
			@(negedge clk) //ffs
			fifo_full = 1'b1;
			@(negedge clk) //laf_state
			fifo_full =1'b0;
			@(negedge clk) //load_parity
			parity_done = 1'b0;
			low_pkt_valid = 1'b1;
			//pkt_valid = 1'b0;
			@(negedge clk) //cpe
			@(negedge clk) //detect_addr
			fifo_full = 1'b0;
			
			//@(negedge clk)
            //fifo_empty_2 = 1'b0; // Reset signals
		end
	endtask
	
	//detect_addr - load_first_data - load_Data - fifo_full_state - LAF - load_Data - load_parity - check parity error - -Detect address
	task t3(); 
		begin		
			@(negedge clk) //lfd_state
			pkt_valid = 1'b1;
			data_in[1:0] = 2'b00;
			fifo_empty_0 = 1'b1;
			@(negedge clk) //ld_state
			@(negedge clk) //ffs
			fifo_full = 1'b1;
			@(negedge clk) //laf_state
			fifo_full =1'b0;
			@(negedge clk) //ld_state
			parity_done = 1'b0;
			low_pkt_valid = 1'b0;
			@(negedge clk) //load_parity
			fifo_full = 1'b0;
			pkt_valid = 1'b0;
			@(negedge clk) //cpe
			@(negedge clk) //detect_addr
			fifo_full = 1'b0;
			
			//@(negedge clk)
            //fifo_empty_0 = 1'b0; // Reset signals
		end
	endtask
	
	//detect_addr - load_first_data - load_Data - load_parity - check parity error - fifo_full_state - LAF - Detect address
	task t4(); 
		begin
			@(negedge clk) //lfd_state
			pkt_valid = 1'b1;
			data_in[1:0] = 2'b01;
			fifo_empty_1 = 1'b1;
			@(negedge clk) //load_Data
			@(negedge clk) //load_parity
			fifo_full = 1'b0;
			pkt_valid = 1'b0;
			@(negedge clk) //cpe
			@(negedge clk) //ffs
			fifo_full = 1'b1;
			@(negedge clk) //LAF
			fifo_full = 1'b0;
			@(negedge clk) //detect_addr
			parity_done = 1'b1;
			
			//@(negedge clk)
            //fifo_empty_1 = 1'b0; // Reset signals
		end
	endtask
	
	//Test sequence
	initial begin	
		initialize;
		reset;
		t1;
		reset;
		#30;
		
		t2;
		reset;
		#30;
		
		t3;
		reset;
		#30;
		
		t4;
		reset;
		#30
		$stop;
		end
	
	initial begin
        $monitor("Time=%0t | State=%b | busy=%b | detect_addr=%b | ld_state=%b | laf_state=%b | full_state=%b | write_enb_reg=%b | rst_int_reg=%b",
                 $time, UUT.present_state, busy, detect_addr, ld_state, laf_state, full_state, write_enb_reg, rst_int_reg);
    end
		
endmodule
