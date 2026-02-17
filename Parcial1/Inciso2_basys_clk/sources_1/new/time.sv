`timescale 1ns / 1ps

module time_mod #(
    parameter int INIT_HOUR = 0,   // 0..23
    parameter int INIT_MIN  = 0    // 0..59
)(
    input  logic clk,
    input  logic rst,
    input  logic tick_1hz,     // pulso 1 ciclo cada 1 segundo

    output logic [4:0] hour,   // 0..23
    output logic [5:0] min,    // 0..59

    output logic [3:0] Ht,
    output logic [3:0] Hu,
    output logic [3:0] Mt,
    output logic [3:0] Mu
);

    logic [5:0] sec; // 0..59

    always_ff @(posedge clk) begin
        if (rst) begin
            hour <= INIT_HOUR[4:0];
            min  <= INIT_MIN[5:0];
            sec  <= 6'd0;
        end else if (tick_1hz) begin
            if (sec == 6'd59) begin
                sec <= 6'd0;

                if (min == 6'd59) begin
                    min <= 6'd0;
                    if (hour == 5'd23) hour <= 5'd0;
                    else               hour <= hour + 5'd1;
                end else begin
                    min <= min + 6'd1;
                end

            end else begin
                sec <= sec + 6'd1;
            end
        end
    end

    // Binario -> BCD (manual)
    always_comb begin
        if (hour >= 5'd20) begin
            Ht = 4'd2; Hu = hour - 5'd20;
        end else if (hour >= 5'd10) begin
            Ht = 4'd1; Hu = hour - 5'd10;
        end else begin
            Ht = 4'd0; Hu = hour[3:0];
        end

        if (min >= 6'd50) begin
            Mt = 4'd5; Mu = min - 6'd50;
        end else if (min >= 6'd40) begin
            Mt = 4'd4; Mu = min - 6'd40;
        end else if (min >= 6'd30) begin
            Mt = 4'd3; Mu = min - 6'd30;
        end else if (min >= 6'd20) begin
            Mt = 4'd2; Mu = min - 6'd20;
        end else if (min >= 6'd10) begin
            Mt = 4'd1; Mu = min - 6'd10;
        end else begin
            Mt = 4'd0; Mu = min[3:0];
        end
    end

endmodule
