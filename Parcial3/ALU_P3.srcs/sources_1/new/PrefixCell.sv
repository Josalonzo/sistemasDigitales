`timescale 1ns / 1ps
// Módulo:      PrefixCell
// Descripción: Celda base del sumador de prefijo paralelo (Kogge-Stone)
//              Combina dos segmentos mediante el operador de prefijo

module PrefixCell (
    input  logic g_hi, p_hi,  // generación y propagación del segmento superior
    input  logic g_lo, p_lo,  // generación y propagación del segmento inferior
    output logic g_out,        // generación combinada
    output logic p_out         // propagación combinada
);

    assign g_out = g_hi | (p_hi & g_lo);
    assign p_out = p_hi & p_lo;

endmodule