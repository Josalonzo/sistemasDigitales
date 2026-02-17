`timescale 1ns / 1ps

module complete #(
    parameter int INIT_HOUR  = 7,
    parameter int INIT_MIN   = 29,
    parameter int ALARM_HOUR = 7,
    parameter int ALARM_MIN  = 30
)(
    input  logic clk,
    input  logic btnC,
    input  logic btnU,
    output logic [1:0] led,
    output logic [6:0] seg,
    output logic       dp,
    output logic [3:0] an
);

    logic rst;
    logic tick_1hz;

    logic [4:0] hour;
    logic [5:0] min;

    logic [3:0] Ht, Hu, Mt, Mu;

    logic H_pulse;
    logic alarm_on;
    logic [1:0] fsm_state;

    // Power-On Reset
    logic [23:0] por_cnt = 24'd0;
    logic por_rst;

    // LED visible de "segundos" (toggle cada 1s)
    logic led_sec;

    always_ff @(posedge clk) begin
        if (por_cnt != 24'hFFFFFF)
            por_cnt <= por_cnt + 1'b1;
    end

    assign por_rst = (por_cnt != 24'hFFFFFF);
    assign rst = por_rst | btnC;

    clck_psc #(
        .CLK_FREQ(100_000_000),
        .OUT_FREQ(1)
    ) u_tick (
        .clk (clk),
        .rst (rst),
        .tick(tick_1hz)
    );

    // Toggle del LED cada segundo (VISIBLE)
    always_ff @(posedge clk) begin
        if (rst) begin
            led_sec <= 1'b0;
        end else if (tick_1hz) begin
            led_sec <= ~led_sec;
        end
    end

    time_mod #(
        .INIT_HOUR(INIT_HOUR),
        .INIT_MIN (INIT_MIN)
    ) u_time (
        .clk      (clk),
        .rst      (rst),
        .tick_1hz (tick_1hz),
        .hour     (hour),
        .min      (min),
        .Ht       (Ht),
        .Hu       (Hu),
        .Mt       (Mt),
        .Mu       (Mu)
    );

    compare #(
        .ALARM_HOUR(ALARM_HOUR),
        .ALARM_MIN (ALARM_MIN)
    ) u_cmp (
        .clk (clk),
        .rst (rst),
        .hour(hour),
        .min (min),
        .H   (H_pulse)
    );

    alarm_fsm u_fsm (
        .clk   (clk),
        .rst   (rst),
        .H     (H_pulse),
        .B     (btnU),
        .A     (alarm_on),
        .state (fsm_state)
    );

    seg7 u_7seg (
        .clk (clk),
        .rst (rst),
        .d3  (Ht),
        .d2  (Hu),
        .d1  (Mt),
        .d0  (Mu),
        .seg (seg),
        .dp  (dp),
        .an  (an)
    );

    always_comb begin
        led[0] = alarm_on;
        led[1] = led_sec;   // <-- ahora sí parpadea
    end

endmodule
