`timescale 1ns / 1ps
// Módulo:      Alu
// Descripción: Unidad aritmético-lógica de 4 bits con flags de estado
//              y selección de tipo de sumador (ripple, CLA, prefijo)

module Alu (
    input  logic [3:0] in_a, in_b,
    input  logic [2:0] ctrl,        // operación: 000=suma, 001=resta, 010=AND, 011=OR, 100=SLL, 101=SRL
    input  logic [1:0] adder_sel,   // sumador: 00=ripple, 01=CLA, 10=prefijo
    output logic [3:0] result,
    output logic       carry,
    output logic       overflow,
    output logic       negative,
    output logic       zero
);

    logic [3:0] in_b_mod;               // B invertido para la resta
    logic [3:0] sum_rca, sum_cla, sum_prefix; // resultados de cada sumador
    logic       cout_rca, cout_cla, cout_prefix;
    logic [3:0] sum_out;                // resultado seleccionado
    logic       cout_sum;               // acarreo seleccionado
    logic [3:0] and_out, or_out, sll_out, srl_out;

    // Invertir B cuando es resta (complemento a 2)
    assign in_b_mod = ctrl[0] ? ~in_b : in_b;

    // Instancias de los tres sumadores operando en paralelo
    Adder_4b     rca (.in_a(in_a), .in_b(in_b_mod), .cin(ctrl[0]), .sum(sum_rca),    .cout(cout_rca));
    LookAhead_4b cla (.in_a(in_a), .in_b(in_b_mod), .cin(ctrl[0]), .sum(sum_cla),    .cout(cout_cla));
    Prefix_4b    pre (.in_a(in_a), .in_b(in_b_mod), .cin(ctrl[0]), .sum(sum_prefix), .cout(cout_prefix));

    // Selección del sumador activo
    always_comb begin
        case (adder_sel)
            2'b00:   begin sum_out = sum_rca;    cout_sum = cout_rca;    end // ripple-carry
            2'b01:   begin sum_out = sum_cla;    cout_sum = cout_cla;    end // CLA
            2'b10:   begin sum_out = sum_prefix; cout_sum = cout_prefix; end // prefijo
            default: begin sum_out = sum_rca;    cout_sum = cout_rca;    end
        endcase
    end

    // Operaciones lógicas y shifts
    assign and_out = in_a & in_b;
    assign or_out  = in_a | in_b;
    assign sll_out = in_a << 1;
    assign srl_out = in_a >> 1;

    // Selección de operación según ctrl
    always_comb begin
        case (ctrl)
            3'b000: result = sum_out; // suma
            3'b001: result = sum_out; // resta
            3'b010: result = and_out; // AND
            3'b011: result = or_out;  // OR
            3'b100: result = sll_out; // desplazamiento izquierda
            3'b101: result = srl_out; // desplazamiento derecha
            default: result = 4'b0000;
        endcase
    end

    // Flags
    assign carry    = (~ctrl[2] & ~ctrl[1]) ? cout_sum : 1'b0;
    assign overflow = (~ctrl[2] & ~ctrl[1]) ? (in_a[3] == in_b_mod[3]) && (result[3] != in_a[3]) : 1'b0;
    assign negative = result[3];
    assign zero     = (result == 4'b0000);

endmodule