module alarm_fsm (
    input  logic clk,
    input  logic rst,         
    input  logic H,           
    input  logic B,           
    output logic A,           
    output logic [1:0] state  
);

    logic [1:0] next;

   
    always_ff @(posedge clk) begin
        if (rst)
            state <= 2'b00;     
        else
            state <= next;
    end

  
    always_comb begin
        next = state; 

        unique case (state)

            // S00
            2'b00: begin
                if (H)  next = 2'b01;  
                else    next = 2'b00;  
            end

            // S01
            2'b01: begin
                if (B)  next = 2'b10;  
                else    next = 2'b01;  
            end

            // S10
            2'b10: begin
                next = 2'b00;
            end

            // S11
            default: begin
                next = 2'b00;
            end

        endcase
    end

    always_comb begin
        unique case (state)
            2'b01: A = 1'b1; 
            default: A = 1'b0;
        endcase
    end

endmodule
