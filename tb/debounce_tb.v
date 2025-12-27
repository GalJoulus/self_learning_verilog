`timescale 1ns/1ps

module debounce_tb;

    // =====================================================
    // DUT interface signals
    // =====================================================
    reg  clk;
    reg  rst;
    reg  btn_raw;
    wire btn_pulse;

    
    // DUT instantiation (MATCHES SOURCE EXACTLY)
    // =====================================================
    debounce_button #(
        .DEBOUNCE_MAX(10)   // small for simulation
    ) dut (
        .clk       (clk),
        .rst       (rst),
        .btn_raw   (btn_raw),
        .btn_pulse (btn_pulse)
    );


    // =====================================================
    // Clock generation (100 MHz)
    // =====================================================
    initial clk = 0;
    always #5 clk = ~clk;

    // =====================================================
    // Test sequence: reset + two presses with bounce
    // =====================================================
    initial begin
        $dumpfile("gtk/debounce_tb.vcd");
        $dumpvars(0, debounce_tb);
        rst     = 1;
        btn_raw = 0;

        #50;
        rst = 0;

        // -------------------------------------------------
        // First press (with bounce)
        // -------------------------------------------------
        #100;
        btn_raw = 1; #10;
        btn_raw = 0; #10;
        btn_raw = 1; #10;
        btn_raw = 0; #10;
        btn_raw = 1;              // stable press

        #300;
        btn_raw = 0;              // release
      #400;
        // -------------------------------------------------
        // Second press (with bounce)
        // -------------------------------------------------
      
        btn_raw = 1; #5;
        btn_raw = 0; #5;
        btn_raw = 1; #5;
        btn_raw = 0; #5;
        btn_raw = 1;              // stable press

        #300;
        btn_raw = 0;

        #200;
        $finish;
    end

    // =====================================================
    // SMART MONITORS (hierarchical access)
    // =====================================================

    // ------------------------------
    // Monitor 1: pulse detection
    // ------------------------------
    always @(posedge clk) begin
        if (btn_pulse)
            $display("[%0t] BTN_PULSE detected", $time);
    end

    // ------------------------------
    // Monitor 2: single pulse per press
    // ------------------------------
    integer pulse_count;

    always @(posedge clk or posedge rst) begin
        if (rst)
            pulse_count <= 0;
        else if (btn_pulse)
            pulse_count <= pulse_count + 1;
    end

    always @(negedge btn_raw) begin
        if (pulse_count > 1)
            $error("[%0t] ERROR: More than one pulse per press!", $time);
        if (pulse_count == 0)
            $error("[%0t] ERROR: No pulse detected for this press!", $time);
        else
            $display("[%0t] OK: Single pulse for this press", $time);

        pulse_count = 0;
    end

    // ------------------------------
    // Monitor 3: debounce correctness
    // btn_clean must NOT change immediately
    // ------------------------------
    always @(posedge btn_raw) begin
        if (dut.btn_clean)
            $error("[%0t] ERROR: btn_clean changed too early!", $time);
    end

    // ------------------------------
    // Monitor 4: live signal log
    // ------------------------------
    initial begin
        $display(" time | raw sync clean pulse cnt ");
        $monitor("%4t |  %b    %b     %b     %b   %0d",
                 $time,
                 btn_raw,
                 dut.btn_sync,
                 dut.btn_clean,
                 btn_pulse,
                 dut.cnt);
    end

endmodule
