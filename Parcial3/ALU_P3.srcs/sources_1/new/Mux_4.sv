`timescale 1ns / 1ps
// Módulo:      Mux_4
// Descripción: Multiplexor 4 a 1 de 4 bits

module Mux_4 (
    input  logic [3:0] in0, in1, in2, in3,
    input  logic [1:0] sel,
    output logic [3:0] data_out
);

    assign data_out = sel[1] ? (sel[0] ? in3 : in2)
                             : (sel[0] ? in1 : in0);

endmodule