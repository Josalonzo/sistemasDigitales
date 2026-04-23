`timescale 1ns / 1ps
// Módulo:      Mux_8
// Descripción: Multiplexor 8 a 1 de 4 bits

module Mux_8 (
    input  logic [3:0] in0, in1, in2, in3, in4, in5, in6, in7,
    input  logic [2:0] sel,
    output logic [3:0] data_out
);

    assign data_out = sel[2] ? (sel[1] ? (sel[0] ? in7 : in6)
                                       : (sel[0] ? in5 : in4))
                             : (sel[1] ? (sel[0] ? in3 : in2)
                                       : (sel[0] ? in1 : in0));

endmodule