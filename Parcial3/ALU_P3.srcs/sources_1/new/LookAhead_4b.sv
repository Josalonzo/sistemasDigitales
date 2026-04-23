`timescale 1ns / 1ps
// Módulo:      LookAhead_4b
// Descripción: Sumador carry lookahead de 4 bits
//              Calcula todos los acarreos en paralelo usando g y p por bit

module LookAhead_4b (
    input  logic [3:0] in_a, in_b,
    input  logic       cin,
    output logic [3:0] sum,
    output logic       cout
);

    logic [3:0] bit_gen;  // g[i] = a[i] & b[i]
    logic [3:0] bit_prop; // p[i] = a[i] ^ b[i]
    logic [4:0] c;        // acarreos: c[0]=cin, c[4]=cout

    assign bit_gen  = in_a & in_b;
    assign bit_prop = in_a ^ in_b;

    // Acarreos calculados en paralelo
    assign c[0] = cin;

    assign c[1] = bit_gen[0]
                | (bit_prop[0] & c[0]);

    assign c[2] = bit_gen[1]
                | (bit_prop[1] & bit_gen[0])
                | (bit_prop[1] & bit_prop[0] & c[0]);

    assign c[3] = bit_gen[2]
                | (bit_prop[2] & bit_gen[1])
                | (bit_prop[2] & bit_prop[1] & bit_gen[0])
                | (bit_prop[2] & bit_prop[1] & bit_prop[0] & c[0]);

    assign c[4] = bit_gen[3]
                | (bit_prop[3] & bit_gen[2])
                | (bit_prop[3] & bit_prop[2] & bit_gen[1])
                | (bit_prop[3] & bit_prop[2] & bit_prop[1] & bit_gen[0])
                | (bit_prop[3] & bit_prop[2] & bit_prop[1] & bit_prop[0] & c[0]);

    assign sum  = bit_prop ^ c[3:0];
    assign cout = c[4];

endmodule