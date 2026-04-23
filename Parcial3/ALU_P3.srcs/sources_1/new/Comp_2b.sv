`timescale 1ns / 1ps
// Módulo:      Comp_2b
// Descripción: Comparador de igualdad de 2 bits, instancia dos Comp_1b en paralelo
 
module Comp_2b (
    input  logic [1:0] in_a,
    input  logic [1:0] in_b,
    output logic       equal
);
 
    logic cmp_lo, cmp_hi; // resultado de cada bit comparado
 
    Comp_1b cmp0 (.bit_a(in_a[0]), .bit_b(in_b[0]), .eq_out(cmp_lo));
    Comp_1b cmp1 (.bit_a(in_a[1]), .bit_b(in_b[1]), .eq_out(cmp_hi));
 
    assign equal = cmp_lo & cmp_hi; // iguales solo si ambos bits coinciden
 
endmodule
 