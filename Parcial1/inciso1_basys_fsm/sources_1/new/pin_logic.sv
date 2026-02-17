module pin_logic (
    input  logic clk,
    input  logic rst,    

    input  logic A0,
    input  logic A1,
    input  logic B0,
    input  logic B1,
    input  logic C0,
    input  logic C1,

    output logic P,
    output logic [1:0] state_dbg
);

    typedef enum logic [1:0] {
        S00 = 2'b00,
        S01 = 2'b01,
        S10 = 2'b10,
        S11 = 2'b11
    } state_t;

    state_t state, next_state;

    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            state <= S00;
        else
            state <= next_state;
    end

    assign state_dbg = state;


    always_comb begin
        next_state = state;

        
        P = (state == S11);

        case (state)

            // 00 
            S00: begin
                if ((A0 == 1'b0) && (A1 == 1'b0))
                    next_state = S01;
            end

            // 01
            S01: begin
                if ((B0 == 1'b1) && (B1 == 1'b0))
                    next_state = S10;
            end

            // 10 
            S10: begin
                if ((C0 == 1'b0) && (C1 == 1'b1))
                    next_state = S11;
            end

            // 11
            S11: begin
                next_state = S00;
            end

            default: next_state = S00;
        endcase
    end

endmodule
