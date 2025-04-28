module router_sync_tb();
    reg clk, rstn, detect_addr, wt_en_reg;
    reg [1:0] data_in;
    reg read_enb_0, read_enb_1, read_enb_2; // Individual read enable signals
    reg empty_0, empty_1, empty_2;          // Individual empty signals
    reg full_0, full_1, full_2;             // Individual full signals
    wire vld_out_0, vld_out_1, vld_out_2;   // Individual valid output signals
    wire [2:0]write_enb; // Individual write enable signals
    wire fifo_full;
    wire soft_reset_0, soft_reset_1, soft_reset_2; // Individual soft reset signals

    // Instantiate DUT
    router_sync UUT (
        .clock(clk),
        .resetn(rstn),
        .detect_add(detect_addr),
        .write_enb_reg(wt_en_reg),
        .data_in(data_in),
        .read_enb_0(read_enb_0),
        .read_enb_1(read_enb_1),
        .read_enb_2(read_enb_2),
        .empty_0(empty_0),
        .empty_1(empty_1),
        .empty_2(empty_2),
        .full_0(full_0),
        .full_1(full_1),
        .full_2(full_2),
        .vld_out_0(vld_out_0),
        .vld_out_1(vld_out_1),
        .vld_out_2(vld_out_2),
        .write_enb(write_enb),
        .fifo_full(fifo_full),
        .soft_reset_0(soft_reset_0),
        .soft_reset_1(soft_reset_1),
        .soft_reset_2(soft_reset_2)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10 ns clock period
    end

    // Task to initialize signals
    task initialize;
        begin
            detect_addr = 0;
            wt_en_reg = 0;
            data_in[1:0] = 2'b00;
            read_enb_0 = 0; read_enb_1 = 0; read_enb_2 = 0;
            empty_0 = 0; empty_1 = 0; empty_2 = 0; // Initially all FIFOs are empty
            full_0 = 0; full_1 = 0; full_2 = 0;    // Initially no FIFOs are full
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

    // Task to detect an address
    task detect_address(input [1:0] addr);
        begin
            @(negedge clk)
                detect_addr = 1;
            data_in[1:0] = addr;
            @(negedge clk)
                detect_addr = 0;
        end
    endtask

    // Task to enable write
    task enable_write(input enable);
        begin
            @(negedge clk)
                wt_en_reg = enable;
            @(negedge clk)
                wt_en_reg = 0;
        end
    endtask

    // Task to enable read
    task enable_read(input read_0, input read_1, input read_2);
        begin
            @(negedge clk);
            read_enb_0 = read_0;
            read_enb_1 = read_1;
            read_enb_2 = read_2;
            @(negedge clk);
            read_enb_0 = 0;
            read_enb_1 = 0;
            read_enb_2 = 0;
        end
    endtask

    // Task to set FIFO flags
    task set_fifo_flags(input e0, input e1, input e2, input f0, input f1, input f2);
        begin
            @(negedge clk);
            empty_0 = e0;
            empty_1 = e1;
            empty_2 = e2;
            full_0 = f0;
            full_1 = f1;
            full_2 = f2;
        end
    endtask

    // Test sequence
    initial begin

        // Step 1: Initialize signals
        initialize;
        reset;

        // Step 2: Test FIFO 0
        detect_address(2'b00);
        enable_write(1);
        set_fifo_flags(0, 1, 1, 1, 0, 0); // FIFO 0 is full, others are not
        enable_read(1, 0, 0); // Enable read for FIFO 0
        #300;

        // Step 3: Test FIFO 1
        detect_address(2'b01);
        enable_write(1);
        set_fifo_flags(1, 0, 1, 0, 1, 0); // FIFO 1 is full, others are not
        enable_read(0, 1, 0); // Enable read for FIFO 1
        #300;

        // Step 4: Test FIFO 2
        detect_address(2'b10);
        enable_write(1);
        set_fifo_flags(1, 1, 0, 0, 0, 1); // FIFO 2 is full, others are not
        enable_read(0, 0, 1); // Enable read for FIFO 2
        #200;

    end
	
	initial begin
    // Other testbench tasks and sequences...
    #5000;  // Extend simulation time by 5000 ns
    $finish;
end
endmodule
