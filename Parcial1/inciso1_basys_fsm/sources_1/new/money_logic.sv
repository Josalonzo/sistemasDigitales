
module money_logic (
    input  logic clk,
    input  logic rst,  

    // Inputs
    input  logic A,
    input  logic C0,
    input  logic C1,   
    input  logic M,

    // Outputs 
    output logic ok,
    output logic NOMONEY,
    output logic Q100,
    output logic Q200,
    output logic Q300,
    output logic Q400,

    output logic [1:0] state_dbg
);

    typedef enum logic [1:0] {
        waits = 2'b00,
        amount = 2'b01,
        cash = 2'b10

    } state_t;

    state_t state, next_state;

    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            state <= waits;     
        else
            state <= next_state;
    end

    assign state_dbg = state;

    always_comb begin

        next_state = state;

        ok = 1'b0;
        NOMONEY  = 1'b0;
        Q100  = 1'b0;
        Q200  = 1'b0;
        Q300  = 1'b0;
        Q400 = 1'b0;

        case (state)

            // Estado 00
            waits: begin
                if (A == 1'b0) begin
                    next_state = waits;
                end else begin
                    next_state = amount;
                end
            end

            // Estado 01
            amount: begin
                    if (M == 1'b0) begin
                        next_state = waits;
                        NOMONEY = 1'b1;
                    end else begin
                        // M == 1 
                        next_state = cash;
                        unique case ({C0, C1})
                            2'b00: Q100  = 1'b1;
                            2'b01: Q200  = 1'b1;
                            2'b10: Q300  = 1'b1;
                            2'b11: Q400 = 1'b1;
                            default: ;
                        endcase
                    end
                end
            // Estado 10
            cash: begin
                if (M == 1'b1) begin
                    next_state = waits;
                    ok = 1'b1;
                end
            end

            default: begin
                next_state = waits;
            end

        endcase
    end

endmodule
