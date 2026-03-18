`timescale 1ns / 1ps

// Modulo: vga
// Descripcion: controlador VGA para resolucion 640x480 a 60Hz.
// Genera las señales de sincronizacion horizontal y vertical,
// el pixel clock de 25MHz a partir del reloj de 100MHz de la Basys 3,
// y las coordenadas del pixel actual para los demas modulos.
module vga (
    input  logic        clk,        // reloj del sistema 100MHz de la Basys 3
    input  logic        rst,        // reset asincrono activo alto
    output logic        vid_active, // alto cuando el pixel esta dentro del area visible 640x480
    output logic        hs,         // señal de sincronizacion horizontal para el monitor
    output logic        vs,         // señal de sincronizacion vertical para el monitor
    output logic        px_clk,     // tick de 25MHz que indica cuando procesar un nuevo pixel
    output logic [9:0]  px_x,       // coordenada horizontal del pixel actual (0-799)
    output logic [9:0]  px_y        // coordenada vertical del pixel actual (0-524)
);

    // parametros del estandar VGA 640x480 a 60Hz segun especificaciones VESA
    // cada linea horizontal tiene 800 pixeles en total divididos en 4 regiones
    // cada frame vertical tiene 525 lineas en total divididas en 4 regiones
    localparam h_display = 640;  // pixeles visibles por linea horizontal
    localparam h_front   = 48;   // porche delantero horizontal antes del sync
    localparam h_back    = 16;   // porche trasero horizontal despues del sync
    localparam h_sync    = 96;   // duracion del pulso de sync horizontal
    localparam h_total   = h_display + h_front + h_back + h_sync - 1; // 799 pixeles por linea

    localparam v_display = 480;  // lineas visibles por frame
    localparam v_front   = 10;   // porche delantero vertical antes del sync
    localparam v_back    = 33;   // porche trasero vertical despues del sync
    localparam v_sync    = 2;    // duracion del pulso de sync vertical
    localparam v_total   = v_display + v_front + v_back + v_sync - 1; // 524 lineas por frame

    // divisor de frecuencia para generar 25MHz a partir de 100MHz
    // clk_div cuenta de 0 a 3 y se reinicia, generando un tick cada 4 ciclos
    logic [1:0] clk_div;

    always_ff @(posedge clk or posedge rst)
        if (rst) clk_div <= 2'b00;
        else     clk_div <= clk_div + 1'b1;

    // px_clk es alto solo cuando clk_div es 0, es decir una vez cada 4 ciclos
    // esto equivale a 100MHz / 4 = 25MHz requeridos por el estandar VGA
    assign px_clk = (clk_div == 2'b00);

    // contadores de posicion del pixel actual
    logic [9:0] h_cnt, v_cnt;

    // contador horizontal avanza en cada tick de px_clk
    // cuando llega al total de pixeles por linea se reinicia a cero
    always_ff @(posedge clk or posedge rst)
        if (rst)
            h_cnt <= '0;
        else if (px_clk) begin
            if (h_cnt == h_total) h_cnt <= '0;
            else                  h_cnt <= h_cnt + 1'b1;
        end

    // contador vertical avanza cuando el contador horizontal completa una linea
    // cuando llega al total de lineas por frame se reinicia a cero
    always_ff @(posedge clk or posedge rst)
        if (rst)
            v_cnt <= '0;
        else if (px_clk && h_cnt == h_total) begin
            if (v_cnt == v_total) v_cnt <= '0;
            else                  v_cnt <= v_cnt + 1'b1;
        end

    // hs_next y vs_next calculan combinacionalmente cuando debe activarse cada sync
    // el sync horizontal se activa cuando h_cnt entra en la zona de retrace
    // el sync vertical se activa cuando v_cnt entra en la zona de retrace
    // se registran para evitar glitches en las señales de salida
    logic hs_next, vs_next;

    always_comb begin
        hs_next = (h_cnt >= (h_display + h_back)) &&
                  (h_cnt <= (h_display + h_back + h_sync - 1));
        vs_next = (v_cnt >= (v_display + v_back)) &&
                  (v_cnt <= (v_display + v_back + v_sync - 1));
    end

    // registro de las señales de sync para eliminar glitches
    always_ff @(posedge clk or posedge rst)
        if (rst) begin
            hs <= 1'b0;
            vs <= 1'b0;
        end else begin
            hs <= hs_next;
            vs <= vs_next;
        end

    // vid_active indica si el pixel actual esta dentro del area visible de 640x480
    // los modulos pong y text usan esta señal para no dibujar fuera del area visible
    assign vid_active = (h_cnt < h_display) && (v_cnt < v_display);

    // px_x y px_y exponen los contadores como coordenadas del pixel actual
    // todos los modulos del juego los usan para saber en que pixel estan dibujando
    assign px_x = h_cnt;
    assign px_y = v_cnt;

endmodule