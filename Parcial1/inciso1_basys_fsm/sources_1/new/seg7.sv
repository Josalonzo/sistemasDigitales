`timescale 1ns / 1ps

module seg7 (
    input  logic clk,
    input  logic rst,

    input  logic Q100,
    input  logic Q200,
    input  logic Q300,
    input  logic Q400,

    output logic [6:0] seg,
    output logic dp,
    output logic [3:0] an
);

    // Clock divider for multiplex
    logic [15:0] scan_div;
    always_ff @(posedge clk) begin
        if (rst) scan_div <= '0;
        else     scan_div <= scan_div + 1'b1;
    end


    logic [1:0] sel = scan_div[15:14];

    // Digits
    logic [3:0] d3, d2, d1, d0;

    always_comb begin
        d3 = 4'hF; d2 = 4'hF; d1 = 4'hF; d0 = 4'hF;

        if (Q100)      begin d3=0; d2=1; d1=0; d0=0; end
        else if (Q200) begin d3=0; d2=2; d1=0; d0=0; end
        else if (Q300) begin d3=0; d2=3; d1=0; d0=0; end
        else if (Q400) begin d3=0; d2=4; d1=0; d0=0; end
    end

    // 7-seg encoder (active-low)
    function automatic logic [6:0] enc(input logic [3:0] v);
        case (v)
            0: enc=7'b1000000;
            1: enc=7'b1111001;
            2: enc=7'b0100100;
            3: enc=7'b0110000;
            4: enc=7'b0011001;
            5: enc=7'b0010010;
            6: enc=7'b0000010;
            7: enc=7'b1111000;
            8: enc=7'b0000000;
            9: enc=7'b0010000;
            default: enc=7'b1111111;
        endcase
    endfunction

    // Multiplex
    always_comb begin
        an = 4'b1111;
        dp = 1'b1;

        case (sel)
            2'd0: begin an=4'b1110; seg=enc(d0); end
            2'd1: begin an=4'b1101; seg=enc(d1); end
            2'd2: begin an=4'b1011; seg=enc(d2); end
            2'd3: begin an=4'b0111; seg=enc(d3); end
        endcase
    end

endmodule
