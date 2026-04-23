`timescale 1ns / 1ps
// Módulo:      Adder_2b
// Descripción: Sumador ripple-carry de 2 bits, instancia dos Fa_1b en cascada

module Adder_2b (
    input  logic [1:0] in_a, in_b,
    input  logic       cin,
    output logic [1:0] sum,
    output logic       cout
);

    logic carry_mid; // acarreo intermedio entre los dos full adders

    Fa_1b fa0 (.bit_a(in_a[0]), .bit_b(in_b[0]), .cin(cin),       .sum(sum[0]), .cout(carry_mid));
    Fa_1b fa1 (.bit_a(in_a[1]), .bit_b(in_b[1]), .cin(carry_mid), .sum(sum[1]), .cout(cout));

endmodule