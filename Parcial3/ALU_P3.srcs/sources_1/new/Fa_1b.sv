`timescale 1ns / 1ps
// Módulo:      Fa_1b
// Descripción: Full adder de 1 bit con acarreo de entrada y salida

module Fa_1b (
    input  logic bit_a, bit_b, cin,
    output logic sum, cout
);

    logic prop, gen; // propagación y generación de acarreo

    assign prop = bit_a ^ bit_b;    // propagación: diferente en ambas entradas
    assign gen  = bit_a & bit_b;    // generación: ambas entradas en 1

    assign sum  = prop ^ cin;
    assign cout = gen | (prop & cin);

endmodule