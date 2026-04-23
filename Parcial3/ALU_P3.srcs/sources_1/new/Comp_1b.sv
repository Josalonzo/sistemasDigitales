`timescale 1ns / 1ps
// Módulo:      Comp_1b
// Descripción: Comparador de igualdad de 1 bit mediante suma de productos (XNOR)
 
module Comp_1b (
    input  logic bit_a,
    input  logic bit_b,
    output logic eq_out
);
 
    logic prod0, prod1; // términos producto
 
    assign prod0 = ~bit_a & ~bit_b; // caso: ambos en 0
    assign prod1 =  bit_a &  bit_b; // caso: ambos en 1
 
    assign eq_out = prod0 | prod1;  // iguales si algún término es válido
 
endmodule