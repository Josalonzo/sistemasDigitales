`timescale 1ns / 1ps

// Modulo: pong
// Descripcion: genera todos los elementos graficos del juego y maneja
// la logica de movimiento y colisiones. Dibuja las paredes, la paleta
// y la pelota, y detecta cuando la pelota golpea la paleta (hit) o
// sale de la pantalla (miss). Los colores siguen la paleta de la
module pong (
    input  logic        clk,        // reloj del sistema 100MHz
    input  logic        rst,        // reset asincrono activo alto
    input  logic [1:0]  btn,        // btn[0]=arriba btn[1]=abajo para mover la paleta
    input  logic        freeze,     // congela la pelota al centro durante estados de espera
    input  logic        vid_active, // indica si el pixel actual esta en el area visible
    input  logic [9:0]  px_x,       // posicion horizontal del pixel actual
    input  logic [9:0]  px_y,       // posicion vertical del pixel actual
    output logic        gfx_on,     // indica si hay un objeto grafico en el pixel actual
    output logic        hit,        // se activa cuando la pelota golpea la paleta
    output logic        miss,       // se activa cuando la pelota sale por la derecha
    output logic [11:0] gfx_rgb     // color rgb de 12 bits del pixel actual
);

    // limites de la pantalla VGA 640x480
    localparam x_max = 639;
    localparam y_max = 479;

    // limites de la pared izquierda en pixeles
    // la pared tiene 8 pixeles de ancho (32 a 39)
    localparam lw_l = 32;
    localparam lw_r = 39;

    // limites de la pared superior en pixeles
    // la pared tiene 8 pixeles de alto (64 a 71)
    localparam tw_t = 64;
    localparam tw_b = 71;

    // limites de la pared inferior en pixeles
    // la pared tiene 8 pixeles de alto (472 a 479)
    localparam bw_t = 472;
    localparam bw_b = 479;

    // limites horizontales fijos de la paleta, tiene 4 pixeles de ancho
    localparam pad_xl  = 600;
    localparam pad_xr  = 603;

    // altura de la paleta en pixeles y velocidad de movimiento por tick
    localparam pad_h   = 72;
    localparam pad_vel = 3;

    // registro de la posicion vertical superior de la paleta y su siguiente valor
    logic [9:0] pad_yt_reg, pad_yt_next;

    // borde inferior de la paleta calculado a partir del borde superior
    logic [9:0] pad_yb;

    // tamaño de la pelota en pixeles (cuadrado de 8x8)
    localparam ball_sz = 8;

    // velocidad de la pelota en pixeles por tick, positiva y negativa
    localparam vel_pos =  2;
    localparam vel_neg = -2;

    // registros de posicion de la pelota (borde superior izquierdo)
    logic [9:0] bx_reg,  by_reg;
    logic [9:0] bx_next, by_next;

    // registros de velocidad de la pelota en x e y
    logic [9:0] dx_reg,  dy_reg;
    logic [9:0] dx_next, dy_next;

    // bordes de la pelota calculados a partir de la posicion registrada
    logic [9:0] bx_l, bx_r, by_t, by_b;

    // señales para indexar la ROM circular de la pelota
    logic [2:0] rom_row, rom_col;
    logic [7:0] rom_out;  // fila del bitmap de la pelota
    logic       rom_bit;  // bit especifico del pixel dentro del bitmap

    // ref_tick se activa una vez por frame al inicio del periodo de blanking vertical
    // se usa para actualizar la posicion de la paleta y la pelota a 60Hz
    logic ref_tick;
    assign ref_tick = (px_y == 481) && (px_x == 0);

    // registro principal que actualiza todas las posiciones y velocidades
    // al reset coloca la paleta al centro y la pelota en el origen
    always_ff @(posedge clk or posedge rst)
        if (rst) begin
            pad_yt_reg <= 10'd204;   // posicion inicial de la paleta centrada verticalmente
            bx_reg     <= '0;
            by_reg     <= '0;
            dx_reg     <= 10'h002;   // velocidad inicial hacia la derecha
            dy_reg     <= 10'h002;   // velocidad inicial hacia abajo
        end else begin
            pad_yt_reg <= pad_yt_next;
            bx_reg     <= bx_next;
            by_reg     <= by_next;
            dx_reg     <= dx_next;
            dy_reg     <= dy_next;
        end

    // bitmap de la pelota circular almacenado como ROM combinacional
    // cada fila de 8 bits define que pixeles se dibujan para formar el circulo
    always_comb
        case (rom_row)
            3'd0: rom_out = 8'b00111100;
            3'd1: rom_out = 8'b01111110;
            3'd2: rom_out = 8'b11111111;
            3'd3: rom_out = 8'b11111111;
            3'd4: rom_out = 8'b11111111;
            3'd5: rom_out = 8'b11111111;
            3'd6: rom_out = 8'b01111110;
            3'd7: rom_out = 8'b00111100;
        endcase

    // señales que indican si el pixel actual esta dentro de cada objeto
    logic lw_on, tw_on, bw_on, pad_on, sq_ball_on, ball_on;

    // pared izquierda activa si px_x esta entre sus limites horizontales
    assign lw_on  = (lw_l <= px_x) && (px_x <= lw_r);

    // pared superior activa si px_y esta entre sus limites verticales
    assign tw_on  = (tw_t <= px_y) && (px_y <= tw_b);

    // pared inferior activa si px_y esta entre sus limites verticales
    assign bw_on  = (bw_t <= px_y) && (px_y <= bw_b);

    // borde inferior de la paleta calculado dinamicamente segun la posicion actual
    assign pad_yb = pad_yt_reg + pad_h - 1;

    // paleta activa si el pixel esta dentro de sus cuatro bordes
    assign pad_on = (pad_xl <= px_x) && (px_x <= pad_xr) &&
                    (pad_yt_reg <= px_y) && (px_y <= pad_yb);

    // bordes de la pelota calculados a partir de su posicion registrada
    assign bx_l = bx_reg;
    assign by_t = by_reg;
    assign bx_r = bx_l + ball_sz - 1;
    assign by_b = by_t + ball_sz - 1;

    // sq_ball_on indica si el pixel esta dentro del cuadrado que contiene la pelota
    assign sq_ball_on = (bx_l <= px_x) && (px_x <= bx_r) &&
                        (by_t <= px_y) && (px_y <= by_b);

    // rom_row y rom_col calculan la posicion relativa del pixel dentro del bitmap
    assign rom_row = px_y[2:0] - by_t[2:0];
    assign rom_col = px_x[2:0] - bx_l[2:0];

    // rom_bit extrae el bit especifico del bitmap para el pixel actual
    assign rom_bit = rom_out[rom_col];

    // ball_on es verdadero solo si el pixel esta en el cuadrado Y el bitmap marca ese pixel
    // esto convierte el cuadrado en una pelota circular
    assign ball_on = sq_ball_on & rom_bit;

    // colores de los objetos siguiendo la paleta de la Universidad del Istmo
    localparam wall_color = 12'hda0;  // dorado para las paredes
    localparam pad_color  = 12'hfff;  // blanco para la paleta
    localparam ball_color = 12'hfff;  // blanco para la pelota
    localparam bg_color   = 12'h722;  // vino UNIS para el fondo

    // logica de movimiento de la paleta, solo se actualiza en cada ref_tick (60Hz)
    // verifica que la paleta no salga de los limites de las paredes antes de moverla
    always_comb begin
        pad_yt_next = pad_yt_reg;
        if (ref_tick) begin
            if (btn[1] && (pad_yb < (bw_t - 1 - pad_vel)))
                pad_yt_next = pad_yt_reg + pad_vel;  // mueve hacia abajo
            else if (btn[0] && (pad_yt_reg > (tw_b - 1 - pad_vel)))
                pad_yt_next = pad_yt_reg - pad_vel;  // mueve hacia arriba
        end
    end

    // siguiente posicion de la pelota
    // si freeze esta activo la pelota se coloca al centro de la pantalla
    // si no, avanza una vez por ref_tick sumando la velocidad actual
    assign bx_next = freeze   ? x_max / 2 :
                     ref_tick ? bx_reg + dx_reg : bx_reg;
    assign by_next = freeze   ? y_max / 2 :
                     ref_tick ? by_reg + dy_reg : by_reg;

    // logica de colisiones que determina cuando rebotar o cambiar direccion
    // prioridad de deteccion: freeze > pared top > pared bottom > pared izq > paleta > miss
    always_comb begin
        hit     = 1'b0;
        miss    = 1'b0;
        dx_next = dx_reg;
        dy_next = dy_reg;

        if (freeze) begin
            // al salir del freeze la pelota parte hacia la izquierda y abajo
            dx_next = vel_neg;
            dy_next = vel_pos;
        end
        else if (by_t < tw_b)
            dy_next = vel_pos;   // rebote en pared superior, invierte direccion vertical
        else if (by_b > bw_t)
            dy_next = vel_neg;   // rebote en pared inferior, invierte direccion vertical
        else if (bx_l <= lw_r)
            dx_next = vel_pos;   // rebote en pared izquierda, invierte direccion horizontal
        else if ((pad_xl <= bx_r) && (bx_r <= pad_xr) &&
                 (pad_yt_reg <= by_b) && (by_t <= pad_yb)) begin
            dx_next = vel_neg;   // rebote en paleta, invierte direccion horizontal
            hit     = 1'b1;      // señal de golpe para incrementar el score
        end
        else if (bx_r > x_max)
            miss = 1'b1;         // la pelota salio por la derecha, se pierde una vida
    end

    // gfx_on es verdadero si cualquier objeto grafico esta presente en el pixel actual
    assign gfx_on = lw_on | tw_on | bw_on | pad_on | ball_on;

    // multiplexor de color con prioridad para decidir el color del pixel actual
    // si el video no esta activo se pone negro, luego se revisan los objetos en orden
    always_comb
        if (!vid_active)               
            gfx_rgb = 12'h000;          // negro fuera del area visible
        else if (lw_on | tw_on | bw_on)
            gfx_rgb = wall_color;       // dorado para las paredes
        else if (pad_on)
            gfx_rgb = pad_color;        // blanco para la paleta
        else if (ball_on)
            gfx_rgb = ball_color;       // blanco para la pelota
        else
            gfx_rgb = bg_color;         // vino UNIS para el fondo

endmodule