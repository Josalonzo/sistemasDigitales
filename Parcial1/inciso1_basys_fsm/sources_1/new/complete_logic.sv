`timescale 1ns / 1ps

module complete (
    input  logic clk,          // CLK100MHZ
    input  logic btnC,          // reset (botón central)

    input  logic [4:0] sw,

    output logic [4:0] led,

    output logic [6:0] seg,
    output logic dp,
    output logic [3:0] an
);

    // Reset
    logic rst;
    assign rst = btnC;

    // Switch mapping
    logic T, P, C0_m, C1_m, M;
    assign T    = sw[0];
    assign P    = sw[1];
    assign C0_m = sw[2];
    assign C1_m = sw[3];
    assign M    = sw[4];

    // Internal signals
    logic A, E, F;
    logic ok, NOMONEY, Q100, Q200, Q300, Q400;

    // LEDs
    always_comb begin
        led[0] = A;
        led[1] = E;
        led[2] = F;
        led[3] = ok;
        led[4] = NOMONEY;
    end

    // Prescaler
    logic int_clk;
    clck_psc u_clk_psc (
        .clk     (clk),
        .clk_out (int_clk)
    );

    // Auth FSM
    auth_logic u_auth (
        .clk       (int_clk),
        .rst       (rst),
        .T         (T),
        .P         (P),
        .A         (A),
        .E         (E),
        .F         (F),
        .state_dbg (auth_state_dbg)
    );

    // Money FSM
    money_logic u_money (
        .clk       (int_clk),
        .rst       (rst),
        .A         (A),
        .C0        (C0_m),
        .C1        (C1_m),
        .M         (M),
        .ok        (ok),
        .NOMONEY   (NOMONEY),
        .Q100      (Q100),
        .Q200      (Q200),
        .Q300      (Q300),
        .Q400      (Q400),
        .state_dbg (money_state_dbg)
    );

    // 7-seg driver
    seg7 u_seg7 (
        .clk  (clk),
        .rst  (rst),
        .Q100 (Q100),
        .Q200 (Q200),
        .Q300 (Q300),
        .Q400 (Q400),
        .seg  (seg),
        .dp   (dp),
        .an   (an)
    );

endmodule
