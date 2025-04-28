module router_sync(
    input clock, resetn, detect_add, write_enb_reg,
    input [1:0] data_in, 
    input read_enb_0, read_enb_1, read_enb_2,   // Individual read enables
    input empty_0, empty_1, empty_2,            // Individual empty flags
    input full_0, full_1, full_2,               // Individual full flags
    output reg vld_out_0, vld_out_1, vld_out_2, // Individual valid out signals
    output reg [2:0]write_enb,
    output reg fifo_full,
    output reg soft_reset_0, soft_reset_1, soft_reset_2 // Individual soft resets
	);
    reg [1:0] temp;
    reg [4:0] count_0, count_1, count_2; // Individual counters for each FIFO

    // Generate valid out signals
    always @(*) 
		begin
			vld_out_0 = ~empty_0;
			vld_out_1 = ~empty_1;
			vld_out_2 = ~empty_2;
		end
	
	//assign vld_out_0 = ~empty_0;
	//assign vld_out_1 = ~empty_1;
	//assign vld_out_2 = ~empty_2;

    // Storing address in temporary variable
    always @(posedge clock) 
		begin
			if (!resetn)
				temp <= 2'b11;
			else if (detect_add)
				temp <= data_in;
		end

    // FIFO full signal
    always @(*) 
		begin    
			case (temp)
				2'b00: fifo_full = full_0;
				2'b01: fifo_full = full_1;
				2'b10: fifo_full = full_2;
				default: fifo_full = 0;
			endcase
		end

    // Write enable signal using one-hot encoding
    always @(*) 
		begin
			if (write_enb_reg) 
				begin    
					case (temp)
						2'b00: write_enb = 3'b001;
						2'b01: write_enb = 3'b010;
						2'b10: write_enb = 3'b100;
						default: write_enb = 3'b000;
					endcase
				end
			else 
				begin
					write_enb = 3'b000;
				end
		end
		
	//declare wires for count_0, count_1, count_2
	//becaue in the same if block only it is incrementing and checking at the same time
	//so it throwing error in lint
	//so add flag for count
	wire flag0,flag1,flag2;
	assign flag0 = (count_0 == 5'd29);
	assign flag1 = (count_1 == 5'd29);
	assign flag2 = (count_2 == 5'd29);
    // Soft reset and counter logic
    always @(posedge clock)
		begin    
			if (!resetn) 
				begin
					count_0 <= 5'b0;
					count_1 <= 5'b0;
					count_2 <= 5'b0;
					soft_reset_0 <= 1'b0;
					soft_reset_1 <= 1'b0;
					soft_reset_2 <= 1'b0;
				end 
			else 
				begin
					// FIFO 0
					if (vld_out_0) 
						begin
						if (!read_enb_0) 
							begin
							if (flag0) 
								begin
								soft_reset_0 <= 1'b1;
								count_0 <= 5'd0;
								end 
							else 
								begin
								count_0 <= count_0 + 1'b1;
								soft_reset_0 <= 1'b0;
								end
							end 
						else 
							begin
							count_0 <= 5'b0;
							soft_reset_0 <= 1'b0;
							end
						end 
						
					else 
						begin
						count_0 <= 5'b0;
						soft_reset_0 <= 1'b0;
						end

					// FIFO 1
					if (vld_out_1) 
						begin
							if (!read_enb_1) 
								begin
									if (flag1) 
										begin
										soft_reset_1 <= 1'b1;
										count_1 <= 5'd0;
										end 
									else 
										begin
										count_1 <= count_1 + 1'b1;
										soft_reset_1 <= 1'b0;
										end
								end 
							else 
								begin
								count_1 <= 5'b0;
								soft_reset_1 <= 1'b0;
								end
						end 
					else 
						begin
						count_1 <= 5'b0;
						soft_reset_1 <= 1'b0;
						end

					// FIFO 2
					if (vld_out_2) 
						begin
							if (!read_enb_2) 
								begin
									if (flag2) 
										begin
										soft_reset_2 <= 1'b1;
										count_2 <= 5'd0;
										end 
									else 
										begin
										count_2 <= count_2 + 1'b1;
										soft_reset_2 <= 1'b0;
										end
								end 
							else 
								begin
								count_2 <= 5'b0;
								soft_reset_2 <= 1'b0;
								end
						end 
					else 
						begin
						count_2 <= 5'b0;
						soft_reset_2 <= 1'b0;
						end
				end
		end

endmodule
