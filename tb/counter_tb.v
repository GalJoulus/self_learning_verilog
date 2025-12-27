`timescale 1ns/1ps

module tb_counter;

    reg clk;
    reg reset;
    reg enable;
    reg [6:0] max_value;   // NEW: max_value input to DUT
    wire [6:0] q;
    wire overflow;

    // =========================
    // Instantiate the DUT
    // =========================
    top_module dut (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .max_value(max_value),   // NEW!
        .q(q),
        .overflow(overflow)
    );

    // =========================
    // Clock generation: 10ns
    // =========================
    initial begin
        clk = 0;
        forever #5 clk = ~clk;   // Clock period = 10ns
    end

    // =========================
    // Reset & Test sequence
    // =========================
    initial begin
        
        // ---------- Initial state ----------
        reset = 1;
        enable = 0;
        max_value = 7'd100;   // Set initial limit to 100
        #20;

        // ---------- Start Counter ----------
        reset = 0;
        enable = 1;

        // Let counter run long enough to overflow
        #1200;

        // ---------- Disable counting ----------
        enable = 0;
        #50;

        // ---------- Re-enable ----------
        enable = 1;
        #200;

        // ---------- Change max_value during run ----------
        max_value = 7'd60;   // Now counter wraps at 60 instead of 100
        #500;

        // ---------- Apply reset again ----------
        reset = 1;
        #20;
        reset = 0;

        #200;

        $finish;
    end

    // =========================
    // Monitor
    // =========================
    initial begin
        $monitor("Time=%0t | clk=%b | rst=%b | en=%b | max=%0d | q=%0d | ovf=%b",
                  $time, clk, reset, enable, max_value, q, overflow);
    end

    // =========================
    // Dump for GTKWave
    // =========================
    initial begin
        $dumpfile("counter.vcd");
        $dumpvars(0, tb_counter);
    end

endmodule
