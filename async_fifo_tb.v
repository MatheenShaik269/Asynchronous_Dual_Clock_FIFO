`timescale 1ns/1ps

module async_fifo_tb;

    // ================= PARAMETERS =================
    parameter DATA_WIDTH = 8;
    parameter ADDR_WIDTH = 2;

    // ================= INPUTS =================
    reg clk_w, clk_r;
    reg rst_w, rst_r;
    reg wr_en, rd_en;
    reg [DATA_WIDTH-1:0] data_in;

    // ================= OUTPUTS =================
    wire [DATA_WIDTH-1:0] data_out;
    wire full, empty;

    // ================= DUT =================
    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .clk_w(clk_w),
        .rst_w(rst_w),
        .wr_en(wr_en),
        .data_in(data_in),
        .full(full),

        .clk_r(clk_r),
        .rst_r(rst_r),
        .rd_en(rd_en),
        .data_out(data_out),
        .empty(empty)
    );

    // ================= CLOCK GENERATION =================
    // Write clock (fast)
    always #5 clk_w = ~clk_w;

    // Read clock (slow)
    always #7 clk_r = ~clk_r;

    // ================= TASKS =================

    // Reset
    task reset_fifo;
    begin
        rst_w = 1; rst_r = 1;
        #20;
        rst_w = 0; rst_r = 0;
    end
    endtask

    // Write task
    task write_data(input [DATA_WIDTH-1:0] data);
    begin
        @(posedge clk_w);
        if (!full) begin
            wr_en = 1;
            data_in = data;
        end
        @(posedge clk_w);
        wr_en = 0;
    end
    endtask

    // Read task
    task read_data;
    begin
        @(posedge clk_r);
        if (!empty) begin
            rd_en = 1;
        end
        @(posedge clk_r);
        rd_en = 0;
    end
    endtask

    // ================= MONITOR =================
    always @(posedge clk_w) begin
        $display("WCLK Time=%0t | WR=%b FULL=%b DATA_IN=%h",
                  $time, wr_en, full, data_in);
    end

    always @(posedge clk_r) begin
        $display("RCLK Time=%0t | RD=%b EMPTY=%b DATA_OUT=%h",
                  $time, rd_en, empty, data_out);
    end

    // ================= STIMULUS =================
    integer i;

    initial begin
        // INIT
        clk_w = 0;
        clk_r = 0;
        rst_w = 0;
        rst_r = 0;
        wr_en = 0;
        rd_en = 0;
        data_in = 0;

        // RESET
        reset_fifo();

        // =====================================================
        // TEST 1: WRITE DATA
        // =====================================================
        $display("===== TEST 1: WRITE =====");
        for (i = 0; i < 4; i = i + 1) begin
            write_data(i);
        end

        #50;

        // =====================================================
        // TEST 2: READ DATA
        // =====================================================
        $display("===== TEST 2: READ =====");
        for (i = 0; i < 4; i = i + 1) begin
            read_data();
        end

        #50;
        reset_fifo();

        // =====================================================
        // TEST 3: OVERFLOW CHECK
        // =====================================================
        $display("===== TEST 3: OVERFLOW =====");
        for (i = 0; i < 6; i = i + 1) begin
            write_data(i);
        end

        #100;
        
        reset_fifo();

        // =====================================================
        // TEST 4: UNDERFLOW CHECK
        // =====================================================
        $display("===== TEST 4: UNDERFLOW =====");
        for (i = 0; i < 5; i = i + 1) begin
            read_data();
        end

        #50
        reset_fifo();

        // =====================================================
        // TEST 5: SIMULTANEOUS READ/WRITE
        // =====================================================
        $display("===== TEST 5: SIMULTANEOUS RW =====");

        fork
            begin
                for (i = 0; i < 100; i = i + 1)
                    write_data(i);
            end

            begin
                #20;
                for (i = 0; i < 100; i = i + 1)
                    read_data();
            end
        join

        #200

        // END
        $finish;
    end

endmodule