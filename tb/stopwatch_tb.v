`timescale 1ns/1ps

module tb_top_module;

    reg clk;
    reg reset;
    reg enable;

    wire [6:0] q0;
    wire [6:0] q1;
    wire [6:0] q2;
    wire overflow2;

    // =========================
    // Instantiate the DUT
    // =========================
    top_module dut (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .q0(q0),
        .q1(q1),
        .q2(q2),
        .overflow2(overflow2)
    );

    // =========================
    // Clock generation: 10ns
    // =========================
    initial begin
        clk = 0;
        always #10 clk = ~clk; 

    end

    // =========================
    // Reset & Test sequence
    // =========================
    initial begin
        // Start with reset active
        reset = 1;
        enable = 0;
        #20;

        // Release reset and start counting
        reset = 0;
        enable = 1;

        // Allow enough time for counters to cascade
        #5000;

        // Disable counting for a moment
        enable = 0;
        #50;
   
        // Enable again
        enable = 1;
        #10000;

        $finish;
    end

    // =========================
    // Monitor
    // =========================
    initial begin
        $monitor("T=%0t | clk=%b | rst=%b | en=%b | q0=%0d | q1=%0d | q2=%0d | ov2=%b",
                 $time, clk, reset, enable, q0, q1, q2, overflow2);
    end

    // =========================
    // GTKWave dump
    // =========================
    initial begin
        $dumpfile("counters.vcd");
        $dumpvars(0, tb_top_module);
    end

endmodule
