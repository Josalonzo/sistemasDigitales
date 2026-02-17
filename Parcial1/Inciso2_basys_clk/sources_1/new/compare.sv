`timescale 1ns / 1ps

// Compara hora actual con hora de alarma
// Genera pulso H (1 ciclo) cuando coincide
module compare #(
    parameter int ALARM_HOUR = 7,   // hora alarma
    parameter int ALARM_MIN  = 30   // minuto alarma
)(
    input  logic clk,
    input  logic rst,

    input  logic [4:0] hour,   // 0..23
    input  logic [5:0] min,    // 0..59

    output logic H             // pulso cuando coincide
);

    logic match_now;
    logic match_prev;

    // Detecta coincidencia nivel
    assign match_now = (hour == ALARM_HOUR) && (min == ALARM_MIN);

    always_ff @(posedge clk) begin
        if (rst) begin
            match_prev <= 1'b0;
            H          <= 1'b0;
        end else begin
            match_prev <= match_now;

            H <= match_now & ~match_prev;
        end
    end

endmodule
