
module auth_logic (
    input  logic clk,
    input  logic rst,   
    input  logic T,
    input  logic P,
    output logic A,
    output logic E,
    output logic F,
    output logic [2:0] state_dbg 
);

    typedef enum logic [2:0] {
        waits = 3'b000,
        lecture = 3'b001,
        pin = 3'b010,
        okay = 3'b011,
        ejection = 3'b100,
        fail = 3'b101
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

        A = 1'b0;
        E = 1'b0;
        F = 1'b0;

        case (state)
            ejection: begin
                A = 1'b1;
                E = 1'b1;
                F = 1'b0;
            end

            fail: begin
                A = 1'b0;
                E = 1'b1;
                F = 1'b1;
            end

            default: begin

            end
        endcase

        case (state)

            // Estado 000
            waits: begin
                if (T == 1'b0)
                    next_state = waits;
                else
                    next_state = lecture;   
            end

            // Estado 001
            lecture: begin
                if (T == 1'b1)
                    next_state = pin;  
            end

            // Estado 010
            pin: begin
                if (T == 1'b1) begin
                    if (P == 1'b0)
                        next_state = fail;
                    else
                        next_state = okay;
                end
            end

            // Estado 011
            okay: begin
                if (T == 1'b1 && P == 1'b1)
                    next_state = ejection;
            end

            // Estado 100
            ejection: begin
                if (T == 1'b1 && P == 1'b1)
                    next_state = waits;
            end

            // Estado 101
            fail: begin
                if (T == 1'b1)
                    next_state = waits;  
            end

            default: begin
                next_state = waits;
            end
        endcase
    end

endmodule
