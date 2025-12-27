`timescale 1ns / 1ps

module tb_top_module;

    // =====================================================
    // Signal Declarations
    // =====================================================
    reg clk;
    reg rst_hw;
    reg reset_btn;
    reg start_btn;
    reg stop_btn;

    // Outputs from the DUT
    wire [6:0] q0;
    wire [6:0] q1;
    wire [6:0] q2;
    wire overflow;

    // =====================================================
    // Unit Under Test (DUT) Instantiation
    // =====================================================
    top_module dut (
        .clk(clk),
        .rst_hw(rst_hw),
        .reset_btn(reset_btn),
        .start_btn(start_btn),
        .stop_btn(stop_btn),
        .q0(q0),
        .q1(q1),
        .q2(q2),
        .overflow(overflow)
    );

    // =====================================================
    // Clock Generation (50 MHz -> 20ns period)
    // =====================================================
    initial clk = 0;
    always #10 clk = ~clk;

    // =====================================================
    // Helper Tasks for Button Interactions
    // =====================================================
    // These tasks hold the button long enough to satisfy the 
    // reduced DEBOUNCE_MAX(20) parameter in top.v
    
    task press_start;
        begin
            $display("[%0t] Action: Pressing START", $time);
            start_btn = 1;
            repeat (40) @(posedge clk); // Hold > 20 cycles
            start_btn = 0;
            repeat (10) @(posedge clk); // Release gap
        end
    endtask

    task press_stop;
        begin
            $display("[%0t] Action: Pressing STOP", $time);
            stop_btn = 1;
            repeat (40) @(posedge clk);
            stop_btn = 0;
            repeat (10) @(posedge clk);
        end
    endtask

    task press_reset;
        begin
            $display("[%0t] Action: Pressing RESET (User Button)", $time);
            reset_btn = 1;
            repeat (40) @(posedge clk);
            reset_btn = 0;
            repeat (10) @(posedge clk);
        end
    endtask

    // =====================================================
    // Main Test Stimulus
    // =====================================================
    initial begin

        $dumpfile("gtk/ido_my_top.vcd");
        $dumpvars(0, tb_top_module);
        
        // 1. Initialize Inputs
        rst_hw = 1;
        reset_btn = 0;
        start_btn = 0;
        stop_btn = 0;

        // -----------------------------------------------------------------------
        // SMART TB SECTION: SIMULATION SPEED UP
        // -----------------------------------------------------------------------
        // The real design has a clock divider counting to 250,000.
        // Waiting for this in simulation would take forever to see q1 or q2 move.
        // We use hierarchical 'force' to override the internal 'max_value' input
        // of the divider to a small number (4).
        //
        // NOTE: Path is: dut -> stopwatch -> clock_devider -> max_value
        // -----------------------------------------------------------------------
        $display("[%0t] Applying FORCE to speed up simulation clock divider...", $time);
        force dut.stopwatch.clock_devider.max_value = 18'd4; 
        
        // Wait for global reset
        #100;
        rst_hw = 0;
        $display("[%0t] Hardware Reset Released", $time);
        #100;

        // -------------------------------------------------------
        // Test Case 1: Start and Basic Counting
        // -------------------------------------------------------
        press_start();
        
        $display("[%0t] Waiting for counters to increment...", $time);
        // Wait enough time for q0 to move a few times (divider is now only 5 cycles)
        repeat (200) @(posedge clk); 

        if (q0 > 0 || q1 > 0)
            $display("PASS: Counters are moving! q0=%d", q0);
        else
            $error("FAIL: Counters did not move after Start.");

        // -------------------------------------------------------
        // Test Case 2: Pause Functionality
        // -------------------------------------------------------
        press_stop();
        
        // Capture value and wait to see if it stays stable
        #1; 
        begin : check_pause
            reg [6:0] captured_q0;
            captured_q0 = q0;
            repeat (100) @(posedge clk);
            if (q0 == captured_q0) 
                $display("PASS: Stopwatch Paused correctly at %d.", q0);
            else 
                $error("FAIL: Stopwatch kept counting after Stop! (%d -> %d)", captured_q0, q0);
        end

        // -------------------------------------------------------
        // Test Case 3: Resume Functionality
        // -------------------------------------------------------
        press_start();
        repeat (100) @(posedge clk);
        if (q0 > 0) $display("PASS: Resumed counting.");

        // -------------------------------------------------------
        // Test Case 4: Verify Counter Cascading (q0 -> q1 -> q2)
        // -------------------------------------------------------
        $display("[%0t] speeding up internal counters to check cascading...", $time);
        
        // Force the max values of the inner counters to be small so we see wrap-around quickly
        // q0 normally counts to 100, we force it to wrap at 5
        force dut.stopwatch.c0.max_value = 7'd5;
        // q1 normally counts to 60, we force it to wrap at 5
        force dut.stopwatch.c1.max_value = 7'd5;

        // Wait for q2 to increment (Minutes/Hours counter)
        wait(q2 > 0);
        $display("PASS: q2 incremented! Cascade logic (q0->q1->q2) works.");

        // Release forces to return to "normal" (but fast divider) mode
        release dut.stopwatch.c0.max_value;
        release dut.stopwatch.c1.max_value;

        // -------------------------------------------------------
        // Test Case 5: User Reset
        // -------------------------------------------------------
        press_reset();
        repeat (20) @(posedge clk); // Wait for FSM to react
        
        if (q0 == 0 && q1 == 0 && q2 == 0)
            $display("PASS: User Reset cleared all counters to 0.");
        else
            $error("FAIL: Reset did not clear counters. q0=%d, q1=%d", q0, q1);

        // -------------------------------------------------------
        // Test Case 6: Max Reached (Lock State)
        // -------------------------------------------------------
        // To test the final overflow (stopping the watch automatically),
        // we force the counters to their final values and enable counting.
        
        $display("[%0t] Testing Max Reached / Lock State...", $time);
        
        // Ensure we are in RUN state
        press_start();

        // Force values to Max-1
        // Note: Logic is 'if (q == max_value) overflow'. 
        force dut.stopwatch.c0.q = 95;
        force dut.stopwatch.c1.q = 59;
        force dut.stopwatch.c2.q = 59; 
        release dut.stopwatch.c0.q;
        release dut.stopwatch.c1.q;
        release dut.stopwatch.c2.q;

        // Wait a few cycles for the overflow signal to propagate to FSM
        repeat (40) @(posedge clk);

        // Check FSM state. State 3 is S_LOCK (2'b11)
        if (dut.fsm.state == 2'b11)
            $display("PASS: FSM entered LOCK state (2'b11) upon max count.");
        else
            $error("FAIL: FSM did not lock. State is %b", dut.fsm.state);

        $display("---------------------------------------------------");
        $display("All Tests Complete.");
        $finish;
    end

endmodule