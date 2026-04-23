`timescale 1ns / 1ps
// Módulo:      Comp_4b
// Descripción: Comparador de igualdad de 4 bits, instancia dos Comp_2b en paralelo

module Comp_4b (
    input  logic [3:0] in_a,
    input  logic [3:0] in_b,
    output logic       equal
);

    logic cmp_lo, cmp_hi; // resultado de cada mitad comparada

    Comp_2b cmp0 (.in_a(in_a[1:0]), .in_b(in_b[1:0]), .equal(cmp_lo));
    Comp_2b cmp1 (.in_a(in_a[3:2]), .in_b(in_b[3:2]), .equal(cmp_hi));

    assign equal = cmp_lo & cmp_hi; // iguales solo si ambas mitades coinciden

endmodule