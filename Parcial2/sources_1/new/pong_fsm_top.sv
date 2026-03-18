`timescale 1ns / 1ps

// Modulo: pong_fsm_top
// Descripcion: modulo top level del juego UNIS PONG para la Basys 3.
// Conecta todos los submodulos y contiene la FSM principal que controla
// los estados del juego. Tambien maneja el multiplexor de color RGB
// para decidir que se muestra en pantalla en cada momento.
module pong_fsm_top (
    input  logic        clk,       // reloj del sistema 100MHz de la Basys 3
    input  logic        btnR,      // boton derecho usado como reset del juego
    input  logic        btnU,      // boton arriba para mover la paleta hacia arriba
    input  logic        btnD,      // boton abajo para mover la paleta hacia abajo
    output logic        Hsync,     // señal de sincronizacion horizontal para VGA
    output logic        Vsync,     // señal de sincronizacion vertical para VGA
    output logic [3:0]  vgaRed,    // canal rojo de 4 bits hacia el conector VGA
    output logic [3:0]  vgaGreen,  // canal verde de 4 bits hacia el conector VGA
    output logic [3:0]  vgaBlue    // canal azul de 4 bits hacia el conector VGA
);

    // mapeo de entradas fisicas a señales internas
    // se agrupan los botones en un bus de 2 bits para pasarlos al modulo pong
    logic        rst;
    logic [1:0]  btn;
    logic [11:0] pixel_out;

    assign rst    = btnR;   // btnR actua como reset asincrono
    assign btn[0] = btnU;   // btn[0] mueve la paleta hacia arriba
    assign btn[1] = btnD;   // btn[1] mueve la paleta hacia abajo

    // definicion de los 4 estados de la FSM del juego
    // s_new_game: pantalla de inicio, espera que el jugador presione un boton
    // s_play:     juego activo, la pelota se mueve y el jugador controla la paleta
    // s_new_ball: se perdio una pelota, espera el timer y que el jugador presione un boton
    // s_over:     se acabaron las pelotas, muestra game over y espera el timer
    typedef enum logic [1:0] {
        s_new_game = 2'b00,
        s_play     = 2'b01,
        s_new_ball = 2'b10,
        s_over     = 2'b11
    } state_t;

    state_t state_reg, state_next;

    // px_x y px_y son las coordenadas del pixel actual generadas por el modulo vga
    logic [9:0]  px_x, px_y;

    // vid_active indica si el pixel actual esta dentro del area visible de la pantalla
    // px_clk es el tick de 25MHz que sincroniza la actualizacion del buffer de color
    logic        vid_active, px_clk;

    // gfx_on indica si hay un objeto grafico en el pixel actual (pared, paleta o pelota)
    // hit indica que la pelota golpeo la paleta, incrementa el score
    // miss indica que la pelota salio por la derecha, se pierde una pelota
    logic        gfx_on, hit, miss;

    // regions_on indica que regiones de texto estan activas en el pixel actual
    // bit 3=score, bit 2=logo, bit 1=reglas, bit 0=game over
    logic [3:0]  regions_on;

    // gfx_rgb es el color del objeto grafico del modulo pong
    // txt_rgb es el color del texto del modulo text
    logic [11:0] gfx_rgb, txt_rgb;

    // px_buf_reg almacena el color final del pixel para sincronizarlo con px_clk
    // px_buf_next es el valor combinacional antes de registrarse
    logic [11:0] px_buf_reg, px_buf_next;

    // score_units y score_tens son los digitos del marcador enviados al modulo text
    logic [3:0]  score_units, score_tens;

    // freeze detiene la animacion de la pelota en estados que no son s_play
    // inc_score incrementa el contador de score cuando la pelota golpea la paleta
    // clr_score reinicia el score al comenzar un nuevo juego
    // tmr_start arranca el temporizador al perder una pelota o terminar el juego
    logic        freeze, inc_score, clr_score, tmr_start;

    // tmr_tick es el pulso de 60Hz que avanza el temporizador una vez por frame
    // tmr_up indica que el temporizador llego a cero
    logic        tmr_tick, tmr_up;

    // balls_reg almacena el numero de pelotas restantes
    // balls_next es el valor combinacional del siguiente estado de balls_reg
    logic [1:0]  balls_reg, balls_next;

    // modulo vga genera las señales de sincronizacion y las coordenadas del pixel actual
    vga vga_unit (
        .clk        (clk),
        .rst        (rst),
        .vid_active (vid_active),
        .hs         (Hsync),
        .vs         (Vsync),
        .px_clk     (px_clk),
        .px_x       (px_x),
        .px_y       (px_y)
    );

    // modulo text genera el color de las regiones de texto en pantalla
    text text_unit (
        .clk        (clk),
        .balls_left (balls_reg),
        .units      (score_units),
        .tens       (score_tens),
        .px_x       (px_x),
        .px_y       (px_y),
        .regions_on (regions_on),
        .txt_rgb    (txt_rgb)
    );

    // modulo pong genera los graficos del juego: paredes, paleta y pelota
    // tambien maneja el movimiento de la pelota y las colisiones
    pong pong_unit (
        .clk        (clk),
        .rst        (rst),
        .btn        (btn),
        .freeze     (freeze),
        .vid_active (vid_active),
        .px_x       (px_x),
        .px_y       (px_y),
        .gfx_on     (gfx_on),
        .hit        (hit),
        .miss       (miss),
        .gfx_rgb    (gfx_rgb)
    );

    // tmr_tick se genera una vez por frame cuando el pixel esta en la posicion 0,0
    // esto garantiza exactamente 60 ticks por segundo para el temporizador
    assign tmr_tick = (px_x == 0) && (px_y == 0);

    // modulo timer cuenta regresivamente a 60Hz para controlar tiempos de espera
    timer timer_unit (
        .clk     (clk),
        .rst     (rst),
        .t_start (tmr_start),
        .t_tick  (tmr_tick),
        .t_up    (tmr_up)
    );

    // modulo score_counter lleva el marcador en BCD de dos digitos
    score_counter score_unit (
        .clk   (clk),
        .rst   (rst),
        .inc   (inc_score),
        .clr   (clr_score),
        .units (score_units),
        .tens  (score_tens)
    );

    // registro principal que actualiza el estado de la FSM, las pelotas restantes
    // y el buffer de color en cada flanco positivo del reloj
    // el buffer de color solo se actualiza cuando px_clk esta activo (25MHz)
    always_ff @(posedge clk or posedge rst)
        if (rst) begin
            state_reg  <= s_new_game;
            balls_reg  <= '0;
            px_buf_reg <= '0;
        end else begin
            state_reg  <= state_next;
            balls_reg  <= balls_next;
            if (px_clk)
                px_buf_reg <= px_buf_next;
        end

    // logica combinacional de la FSM que decide el siguiente estado y las señales de control
    always_comb begin
        // valores por defecto para evitar latches
        freeze     = 1'b1;   // por defecto la pelota esta congelada
        tmr_start  = 1'b0;
        inc_score  = 1'b0;
        clr_score  = 1'b0;
        state_next = state_reg;
        balls_next = balls_reg;

        unique case (state_reg)
            s_new_game: begin
                balls_next = 2'b11;  // se inicia con 3 pelotas
                clr_score  = 1'b1;   // se limpia el marcador
                if (btn != 2'b00) begin
                    state_next = s_play;
                    balls_next = balls_reg - 1'b1; // se descuenta la primera pelota
                end
            end

            s_play: begin
                freeze = 1'b0;  // se activa el movimiento de la pelota
                if (hit)
                    inc_score = 1'b1;  // la pelota golpeo la paleta, suma un punto
                else if (miss) begin
                    tmr_start  = 1'b1;             // arranca el temporizador de espera
                    balls_next = balls_reg - 1'b1; // se pierde una pelota
                    if (balls_reg == '0)
                        state_next = s_over;     // no quedan pelotas, juego terminado
                    else
                        state_next = s_new_ball; // quedan pelotas, espera nueva ronda
                end
            end

            s_new_ball:
                // espera que el timer termine y el jugador presione un boton para continuar
                if (tmr_up && (btn != 2'b00))
                    state_next = s_play;

            s_over:
                // espera que el timer termine para volver a la pantalla de inicio
                if (tmr_up)
                    state_next = s_new_game;
        endcase
    end

    // multiplexor de color que decide que se muestra en cada pixel
    // prioridad de mayor a menor:
    // 1. fuera del area visible -> negro
    // 2. texto activo en estados especificos (score, reglas, game over)
    // 3. objeto grafico (pared, paleta, pelota)
    // 4. logo UNIS PONG si no es game over
    // 5. fondo vino UNIS
    always_comb
        if (!vid_active)
            px_buf_next = 12'h000;          // negro fuera del area visible
        else if (regions_on[3] ||
                ((state_reg == s_new_game) && regions_on[1]) ||
                ((state_reg == s_over)     && regions_on[0]))
            px_buf_next = txt_rgb;          // score siempre visible, reglas en new_game, game over en s_over
        else if (gfx_on)
            px_buf_next = gfx_rgb;          // objeto grafico del juego
        else if (regions_on[2] && (state_reg != s_over))
            px_buf_next = txt_rgb;          // logo UNIS PONG visible excepto en game over
        else
            px_buf_next = 12'h722;          // fondo vino Universidad del Istmo

    // el color final se toma del buffer registrado y se separa en los tres canales RGB
    // cada canal tiene 4 bits para el conector VGA de la Basys 3
    assign pixel_out = px_buf_reg;
    assign vgaRed    = pixel_out[11:8];
    assign vgaGreen  = pixel_out[7:4];
    assign vgaBlue   = pixel_out[3:0];

endmodule