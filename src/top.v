module top_module(
    input  wire clk,

    // Hardware / power-on reset (direct to FSM)
    input  wire rst_hw,

    // Raw buttons
    input  wire reset_btn,
    input  wire start_btn,
    input  wire stop_btn,

    // Stopwatch outputs
    output wire [6:0] q0,
    output wire [6:0] q1,
    output wire [6:0] q2,
    output wire overflow
);

    // =====================================================
    // Debounce outputs (clean pulses)
    // =====================================================
    wire reset_pulse;
    wire start_pulse;
    wire stop_pulse;
    wire rst;
    assign rst = rst_hw;  // synchronous reset for debounce modules

    debounce_button  #(
        .DEBOUNCE_MAX(20)   // small for simulation
    ) db_reset (
        .clk       (clk),
        .rst       (rst),
        .btn_raw(reset_btn),
        .btn_pulse(reset_pulse)
    );

    debounce_button  #(
        .DEBOUNCE_MAX(20)   // small for simulation
    ) db_start (
        .clk       (clk),
        .rst       (rst),
        .btn_raw(start_btn),
        .btn_pulse(start_pulse)
    );


    debounce_button  #(
        .DEBOUNCE_MAX(20)   // small for simulation
    ) db_stop (
        .clk       (clk),
        .rst       (rst),
        .btn_raw(stop_btn),
        .btn_pulse(stop_pulse)
    );


    // =====================================================
    // FSM <-> Stopwatch control signals
    // =====================================================
    wire en_counter;
    wire rst_counter;
    wire max_reached;

    // =====================================================
    // FSM block
    // =====================================================
    fsm_controller fsm (
        .clk(clk),
        .rst_hw(rst_hw),

        .reset_pulse(reset_pulse),
        .start_pulse(start_pulse),
        .stop_pulse(stop_pulse),

        .max_reached(max_reached),

        .en_counter(en_counter),
        .rst_counter(rst_counter)
    );

    // =====================================================
    // Stopwatch block
    // =====================================================
    top_module_stopwatch stopwatch (
        .clk(clk),
        .reset(rst_counter),
        .enable(en_counter),

        .q0(q0),
        .q1(q1),
        .q2(q2),

        .overflow2(max_reached)
    );


endmodule
