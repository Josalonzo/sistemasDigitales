`timescale 1ns / 1ps
// Módulo:      Prefix_4b
// Descripción: Sumador de prefijo paralelo de 4 bits (Kogge-Stone)
//              Etapa 1: combina pares a distancia 1
//              Etapa 2: combina pares a distancia 2 (cubre los 4 bits)

module Prefix_4b (
    input  logic [3:0] in_a, in_b,
    input  logic       cin,
    output logic [3:0] sum,
    output logic       cout
);

    // Pre-proceso: generación y propagación bit a bit
    logic [3:0] g0, p0;

    assign g0 = in_a & in_b;
    assign p0 = in_a ^ in_b;

    // Incorporar cin al bit 0
    logic g0_cin, p0_cin;
    assign g0_cin = g0[0] | (p0[0] & cin);
    assign p0_cin = p0[0];

    // Etapa 1: distancia 1
    logic [3:0] g1, p1;

    assign g1[0] = g0_cin;
    assign p1[0] = p0_cin;

    PrefixCell u_e1_b1 (.g_hi(g0[1]),  .p_hi(p0[1]),  .g_lo(g0_cin), .p_lo(p0_cin), .g_out(g1[1]), .p_out(p1[1]));
    PrefixCell u_e1_b2 (.g_hi(g0[2]),  .p_hi(p0[2]),  .g_lo(g0[1]),  .p_lo(p0[1]),  .g_out(g1[2]), .p_out(p1[2]));
    PrefixCell u_e1_b3 (.g_hi(g0[3]),  .p_hi(p0[3]),  .g_lo(g0[2]),  .p_lo(p0[2]),  .g_out(g1[3]), .p_out(p1[3]));

    // Etapa 2: distancia 2
    logic [3:0] g2, p2;

    assign g2[0] = g1[0];
    assign p2[0] = p1[0];
    assign g2[1] = g1[1];
    assign p2[1] = p1[1];

    PrefixCell u_e2_b2 (.g_hi(g1[2]), .p_hi(p1[2]), .g_lo(g1[0]), .p_lo(p1[0]), .g_out(g2[2]), .p_out(p2[2]));
    PrefixCell u_e2_b3 (.g_hi(g1[3]), .p_hi(p1[3]), .g_lo(g1[1]), .p_lo(p1[1]), .g_out(g2[3]), .p_out(p2[3]));

    // Post-proceso: acarreos finales y suma
    logic [3:0] carry;

    assign carry[0] = cin;
    assign carry[1] = g2[0];
    assign carry[2] = g2[1];
    assign carry[3] = g2[2];

    assign sum  = p0 ^ carry;
    assign cout = g2[3];

endmodule