module top_module_stopwatch (
    input clk,
    input reset,
    input enable,          // global enable for the whole chain
    output [6:0] q0,       // counter 0 value
    output [6:0] q1,       // counter 1 value
    output [6:0] q2,       // counter 2 value
    output [18:0] qarbage, // to connect clock divider overflow
    output overflow2       // overflow of the last counter
    
);

    wire ov0, ov1, ov_clockdevider;        // internal overflow wires

    basic_counter_module clock_devider (     //import the module called basic_counter_module and create an instance- (local var)- called c0
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .max_value(18'd500000),
        .q(qarbage),
        .overflow(ov_clockdevider)
    );
    // Counter 0: counts 0..100 
    basic_counter_module c0 (     //import the module called basic_counter_module and create an instance- (local var)- called c0
        .clk(clk),
        .reset(reset),
        .enable(ov_clockdevider),
        .max_value(7'd99),
        .q(q0),
        .overflow(ov0)
    );

    // Counter 1: counts 0..60, enabled when c0 overflows
    basic_counter_module c1 (
        .clk(clk),
        .reset(reset),
        .enable(ov0),
        .max_value(7'd59),
        .q(q1),
        .overflow(ov1)
    );

    // Counter 2: counts 0..100, *enabled when c1 overflows*q
    basic_counter_module c2 (
        .clk(clk),
        .reset(reset),
        .enable(ov1),
        .max_value(7'd59),
        .q(q2),
        .overflow(overflow2)
    );

endmodule
