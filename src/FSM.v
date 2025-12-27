module fsm_controller (
    input  wire clk,

    // Hardware / power-on reset
    input  wire rst_hw,          // active high, async

    // User buttons after debounce (1-clock pulses)
    input  wire reset_pulse,
    input  wire start_pulse,
    input  wire stop_pulse,
    input  wire max_reached,

    output reg  en_counter,
    
    output reg  rst_counter
);

    // =====================================================
    // FSM state definitions (Verilog style)
    // =====================================================
    localparam S_IDLE  = 2'b00;
    localparam S_RUN   = 2'b01;
    localparam S_PAUSE = 2'b10;
    localparam S_LOCK  = 2'b11;

    reg [1:0] state;
    reg [1:0] next_state;

    // =====================================================
    // State register
    // =====================================================
    always @(posedge clk or posedge rst_hw) begin
        if (rst_hw)
            state <= S_IDLE;
        else
            state <= next_state;
    end

    // =====================================================
    // Combined next-state + output logic
    // =====================================================
    always @(*) begin
        // defaults
        next_state  = state;
        en_counter  = 1'b0;
        rst_counter = 1'b0;

        // user reset has highest priority
        if (reset_pulse) begin
            next_state  = S_IDLE;
            rst_counter = 1'b1;
        end else begin
            case (state)

                S_IDLE: begin
                    rst_counter = 1'b1;
                    if (start_pulse)
                        next_state = S_RUN;
                end

                S_RUN: begin
                    en_counter = 1'b1;
                    if (max_reached)
                        next_state = S_LOCK;
                    else if (stop_pulse)
                        next_state = S_PAUSE;
                end

                S_PAUSE: begin
                    if (start_pulse)
                        next_state = S_RUN;
                end

                S_LOCK: begin
                    en_counter = 1'b0;
                    next_state = S_LOCK;
                end

            endcase
        end
    end

endmodule
