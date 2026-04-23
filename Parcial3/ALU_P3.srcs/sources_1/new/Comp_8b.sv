`timescale 1ns / 1ps
// Módulo:      Comp_8b
// Descripción: Comparador de igualdad de 8 bits, instancia dos Comp_4b en paralelo

module Comp_8b (
    input  logic [7:0] in_a,
    input  logic [7:0] in_b,
    output logic       equal
);

    logic cmp_lo, cmp_hi; // resultado de cada mitad comparada

    Comp_4b cmp0 (.in_a(in_a[3:0]), .in_b(in_b[3:0]), .equal(cmp_lo));
    Comp_4b cmp1 (.in_a(in_a[7:4]), .in_b(in_b[7:4]), .equal(cmp_hi));

    assign equal = cmp_lo & cmp_hi; // iguales solo si ambas mitades coinciden

endmodule