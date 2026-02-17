`timescale 1ns / 1ps

module seg7 (
    input  logic clk,
    input  logic rst,

    // 4 dígitos BCD (0-9). d3 es el dígito más a la izquierda.
    input  logic [3:0] d3,
    input  logic [3:0] d2,
    input  logic [3:0] d1,
    input  logic [3:0] d0,

    output logic [6:0] seg,
    output logic       dp,
    output logic [3:0] an
);

    // Divider para multiplex (frecuencia de escaneo)
    logic [15:0] scan_div;
    always_ff @(posedge clk) begin
        if (rst) scan_div <= '0;
        else     scan_div <= scan_div + 16'd1;
    end

    // Selección del dígito activo
    logic [1:0] sel;
    assign sel = scan_div[15:14];

    // Encoder 7-seg (active-low)
    function automatic logic [6:0] enc(input logic [3:0] v);
        case (v)
            4'd0: enc = 7'b1000000;
            4'd1: enc = 7'b1111001;
            4'd2: enc = 7'b0100100;
            4'd3: enc = 7'b0110000;
            4'd4: enc = 7'b0011001;
            4'd5: enc = 7'b0010010;
            4'd6: enc = 7'b0000010;
            4'd7: enc = 7'b1111000;
            4'd8: enc = 7'b0000000;
            4'd9: enc = 7'b0010000;
            default: enc = 7'b1111111; // apagado
        endcase
    endfunction

    // Multiplex
    always_comb begin
        // defaults
        an  = 4'b1111;  // todos apagados (active-low)
        seg = 7'b1111111;
        dp  = 1'b1;     // dp apagado (active-low)

        case (sel)
            2'd0: begin an = 4'b1110; seg = enc(d0); end // derecha
            2'd1: begin an = 4'b1101; seg = enc(d1); end
            2'd2: begin an = 4'b1011; seg = enc(d2); end
            2'd3: begin an = 4'b0111; seg = enc(d3); end // izquierda
        endcase
    end

endmodule
