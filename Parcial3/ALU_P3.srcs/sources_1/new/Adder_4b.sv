`timescale 1ns / 1ps
// Módulo:      Adder_4b
// Descripción: Sumador ripple-carry de 4 bits, instancia dos Adder_2b en cascada

module Adder_4b (
    input  logic [3:0] in_a, in_b,
    input  logic       cin,
    output logic [3:0] sum,
    output logic       cout
);

    logic carry_mid; // acarreo intermedio entre los dos sumadores de 2 bits

    Adder_2b add0 (.in_a(in_a[1:0]), .in_b(in_b[1:0]), .cin(cin),       .sum(sum[1:0]), .cout(carry_mid));
    Adder_2b add1 (.in_a(in_a[3:2]), .in_b(in_b[3:2]), .cin(carry_mid), .sum(sum[3:2]), .cout(cout));

endmodule