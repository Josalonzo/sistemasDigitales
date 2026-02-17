`timescale 1ns / 1ps

module clck_psc #(
    parameter int CLK_FREQ = 100_000_000,
    parameter int OUT_FREQ = 1
)(
    input  logic clk,
    input  logic rst,
    output logic tick
);

    localparam int COUNT_MAX = CLK_FREQ / OUT_FREQ;

    logic [$clog2(COUNT_MAX)-1:0] counter;

    always_ff @(posedge clk) begin
        if (rst) begin
            counter <= '0;
            tick    <= 1'b0;
        end else begin
            if (counter == COUNT_MAX-1) begin
                counter <= '0;
                tick    <= 1'b1;  // pulso 1 ciclo
            end else begin
                counter <= counter + 1'b1;
                tick    <= 1'b0;
            end
        end
    end

endmodule
