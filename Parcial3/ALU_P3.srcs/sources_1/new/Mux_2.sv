`timescale 1ns / 1ps
// Módulo:      Mux_2
// Descripción: Multiplexor 2 a 1 de 4 bits

module Mux_2 (
    input  logic [3:0] in0, in1,
    input  logic       sel,
    output logic [3:0] data_out
);

    assign data_out = sel ? in1 : in0;

endmodule