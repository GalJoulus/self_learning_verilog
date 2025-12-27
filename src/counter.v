module basic_counter_module (
    input clk,
    input reset,               // Synchronous reset
    input enable,              // Enable counting
    input [18:0] max_value,    // Maximum count value (0..500,000)
    output reg [18:0] q,       // Counter
    output reg overflow        // Goes high when wrapping to 0
);

always @(posedge clk) begin
    
    if (reset) begin
        q <= 19'd0;
        overflow <= 1'b0;
    end
    
    else if (enable) begin
        
        if (q >= max_value) begin
            q <= 19'd0;        // Wrap back to 0
            overflow <= 1'b1;  // Pulse on wrap
        end
        else begin
            q <= q + 19'd1;    // Count up
            overflow <= 1'b0;
        end
    end

    else begin
        overflow <= 1'b0;
    end

end

endmodule


