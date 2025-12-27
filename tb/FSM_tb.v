`timescale 1ns/1ps

module tb_fsm_controller;

    // ================================
    // Signals
    // ================================
    reg clk;
    reg rst_hw;

    reg reset_pulse;
    reg start_pulse;
    reg stop_pulse;
    reg max_reached;

    wire en_counter;
    wire rst_counter;

    // ================================
    // Instantiate DUT
    // ================================
    fsm_controller dut (
        .clk(clk),
        .rst_hw(rst_hw),

        .reset_pulse(reset_pulse),
        .start_pulse(start_pulse),
        .stop_pulse(stop_pulse),
        .max_reached(max_reached),

        .en_counter(en_counter),
        .rst_counter(rst_counter)
    );

    // ================================
    // Clock generation: 50 MHz (20 ns)
    // ================================
    initial clk = 0;
    always #10 clk = ~clk;

    // ================================
    // Test sequence
    // ================================
    initial begin
        $dumpfile("gtk/fsm_tb.vcd");
        $dumpvars(0, tb_fsm_controller);

        // Default values
        rst_hw       = 1'b1;
        reset_pulse  = 1'b0;
        start_pulse  = 1'b0;
        stop_pulse   = 1'b0;
        max_reached  = 1'b0;

        // ----------------------------
        // Hardware reset
        // ----------------------------
        #30;
        rst_hw = 1'b0;

        // ----------------------------
        // IDLE -> RUN
        // ----------------------------
        pulse_start();

        // Let it run
        #100;

        // ----------------------------
        // RUN -> PAUSE
        // ----------------------------
        pulse_stop();
        #100;

        // ----------------------------
        // PAUSE -> RUN
        // ----------------------------
        pulse_start();
        #100;

        // ----------------------------
        // RUN -> LOCK (max reached)
        // ----------------------------
        max_reached = 1'b1;
        #20;
        max_reached = 1'b0;
        #100;

        // ----------------------------
        // User reset (LOCK -> IDLE)
        // ----------------------------
        pulse_reset();
        #100;

        $finish;
    end

    // ================================
    // Pulse tasks (1 clock wide)
    // ================================
    task pulse_start;
        begin
            start_pulse = 1'b1;
            #20;
            start_pulse = 1'b0;
        end
    endtask

    task pulse_stop;
        begin
            stop_pulse = 1'b1;
            #20;
            stop_pulse = 1'b0;
        end
    endtask

    task pulse_reset;
        begin
            reset_pulse = 1'b1;
            #20;
            reset_pulse = 1'b0;
        end
    endtask

endmodule
