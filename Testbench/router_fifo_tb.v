module tb_router_fifo();
	reg clk, rstn, wt_en, rd_en, soft_rst, lfd_state;
	reg [7:0]data_in;
	wire empty, full;
	wire [7:0]d_out;
	
	router_fifo UUT(clk, rstn, wt_en, rd_en, soft_rst, data_in, lfd_state, empty, d_out, full);
	
	//Clock generation
    initial 
		begin
			clk = 0;
			forever #5 clk = ~clk; // 10 ns clock period
    end
   
	// Task to initialize signals
	task initialise;
		begin
			//clk = 1'b0;
			rstn = 1'b1;
			wt_en = 1'b0;
			rd_en = 1'b0;
			data_in = 8'b0;
			soft_rst = 1'b0;
			lfd_state = 1'b0;
		end
	endtask
	
	//always #5 clk = ~clk;
    
	// Task for reset
 	task reset;
		begin
		@(negedge clk)
			rstn = 0;
		@(negedge clk)
			rstn = 1;
		end
	endtask
	
	// Task for soft_reset
	task soft_reset;
		begin
		@(negedge clk)
			soft_rst = 1;
		@(negedge clk)
			soft_rst = 0;
		end
	endtask
	
	
	// Task to write data to the FIFO
	task write(input [5:0] payload_len, input [1:0] address);
		reg [7:0] payload_data, parity, header;
		integer k;
			begin
				// Write header
				@(negedge clk);
				header = {payload_len, address};
				data_in = header;
				lfd_state = 1'b1;
				wt_en = 1'b1;
				
				// Write payload
				for(k=0; k<payload_len; k=k+1)
					begin	
						@(negedge clk)
						lfd_state = 0;
						payload_data = ($random)%256;
						data_in = payload_data;
					end
					
				// Write parity
				@(negedge clk)
				parity = ($random)%256;
				data_in = parity;
				
				// End write
				@(negedge clk)
				wt_en = 0;
			end
	endtask
	
	// Task to read data from the FIFO
    task read;
        begin
            while (!empty) begin
                @(negedge clk);
                rd_en = 1;
            end
            @(negedge clk);
            rd_en = 0;
        end
    endtask
	
	// Test procedure
	initial 
		begin
		initialise;
	
		// Test 1: Reset functionality
        $display("Test 1: Reset functionality");
        reset;
        #10;
		
		// Test 2: Soft Reset functionality
        $display("Test 2: Soft_Reset functionality");
        soft_reset;
        #10;
		
		// Test 3: Write and read operations
        $display("Test 3: Write and read operations");
        write(6'd8, 2'b01); // Write 8 payloads
        read;               // Read all data
        #10;
		
		// Test 4: FIFO full condition
        $display("Test 4: FIFO full condition");
        write(6'd16, 2'b10); // Write maximum entries
        write(6'd4, 2'b11);  // Attempt to write beyond capacity
        #10;
		
		// Test 5: FIFO empty condition
        $display("Test 5: FIFO empty condition");
        read;               // Read all data
        read;               // Attempt to read from empty FIFO
        #10;
		
		
		// Test 6: Simultaneous read and write
        /*$display("Test 6: Simultaneous read and write");
        fork
            write(6'd10, 2'b01); // Write while reading
            read;
        join
        #10;
		*/

        // Test 7: Soft reset functionality
        $display("Test 7: Soft reset functionality");
        soft_reset;
        write(6'd6, 2'b00);
        read;
        #10;

        $stop;

		end
		
	
	initial
		begin	
		repeat(10) @(negedge clk);
		rd_en = 1;
		//repeat(25) @(negedge clk);
		//rd_en = 1;
		//#250 $stop;
		end
	
endmodule
		
