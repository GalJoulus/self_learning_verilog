module debounce_button #(
    parameter DEBOUNCE_MAX = 22'd2_500_000  // ~50ms @ 50MHz
)(
    input  wire clk,
    input  wire rst,        // reset (synchronous)
    input  wire btn_raw,    // Raw button input
    output wire btn_pulse   // 1-clock clean pulse
);

    // -------------------------------------------------
    // Synchronizer
    // -------------------------------------------------
    reg btn_sync;
    always @(posedge clk) begin
        if (rst)
            btn_sync <= 1'b0;
        else
            btn_sync <= btn_raw;
    end

    // -------------------------------------------------
    // Debounce logic
    // -------------------------------------------------
    reg btn_clean;
    reg [21:0] cnt;

    always @(posedge clk) begin
        if (rst) begin
            btn_clean <= 1'b0;
            cnt       <= 22'd0;
        end else if (btn_sync == btn_clean) begin
            cnt <= 22'd0;
        end else begin
            cnt <= cnt + 1'b1;
            if (cnt >= DEBOUNCE_MAX) begin
                btn_clean <= btn_sync;
                cnt <= 22'd0;
            end
        end
    end

    // -------------------------------------------------
    // Edge detection
    // -------------------------------------------------
    reg btn_prev;
    always @(posedge clk) begin
        if (rst)
            btn_prev <= 1'b0;
        else
            btn_prev <= btn_clean;
    end

    // Rising-edge pulse
    assign btn_pulse = btn_clean & ~btn_prev;

endmodule
