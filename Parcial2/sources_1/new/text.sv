`timescale 1ns / 1ps

// Modulo: text
// Descripcion: genera todas las regiones de texto que se muestran en pantalla.
// Maneja cuatro regiones: score, logo UNIS PONG, reglas y game over.
// Usa la ROM ascii para obtener el bitmap de cada caracter y decide
// que color mostrar segun los colores de la Universidad del Istmo.
module text (
    input  logic        clk,
    input  logic [1:0]  balls_left,  // numero de pelotas restantes para mostrar en pantalla
    input  logic [3:0]  units,       // digito de unidades del score
    input  logic [3:0]  tens,        // digito de decenas del score
    input  logic [9:0]  px_x,        // posicion horizontal del pixel actual
    input  logic [9:0]  px_y,        // posicion vertical del pixel actual
    output logic [3:0]  regions_on,  // indica que regiones de texto estan activas en el pixel actual
    output logic [11:0] txt_rgb      // color rgb de 12 bits para el pixel actual
);

    // rom_addr es la direccion que se envia a la ROM ascii, formada por caracter + fila
    logic [10:0] rom_addr;

    // ch_addr es el caracter seleccionado por el mux segun la region activa
    // cada ch_* almacena el codigo ascii del caracter para su region
    logic [6:0]  ch_addr, ch_score, ch_logo, ch_rules, ch_over;

    // row_sel es la fila del bitmap seleccionada por el mux
    // cada row_* extrae los bits de fila correspondientes a su region
    logic [3:0]  row_sel;
    logic [3:0]  row_score, row_logo, row_rules, row_over;

    // col_sel es la columna del bitmap seleccionada por el mux
    // cada col_* extrae los bits de columna correspondientes a su region
    logic [2:0]  col_sel;
    logic [2:0]  col_score, col_logo, col_rules, col_over;

    // ch_pixels contiene los 8 bits del bitmap del caracter actual de la ROM
    logic [7:0]  ch_pixels;

    // px_bit indica si el bit del pixel actual en el bitmap es 1 (parte del caracter)
    logic        px_bit;

    // señales que indican si el pixel actual esta dentro de cada region de texto
    logic        score_on, logo_on, rules_on, over_on;

    // rules_idx combina bits de px_y y px_x para indexar la tabla de caracteres de las reglas
    logic [7:0]  rules_idx;

    // instancia de la ROM ascii que devuelve el bitmap del caracter solicitado
    ascii_rom char_rom (
        .clk  (clk),
        .addr (rom_addr),
        .data (ch_pixels)
    );

    // region score en la parte superior izquierda de la pantalla
    // activa entre y=32 y y=64, escalada al doble con bits [4:1] y [3:1]
    // muestra "SCORE: dd BALL: d"
    assign score_on  = (px_y >= 32) && (px_y < 64) && (px_x[9:4] < 16);
    assign row_score = px_y[4:1];  // escala vertical x2
    assign col_score = px_x[3:1];  // escala horizontal x2

    // selecciona el codigo ascii de cada caracter del score segun la columna del pixel
    always_comb
        case (px_x[7:4])
            4'h0: ch_score = 7'h53; // S
            4'h1: ch_score = 7'h43; // C
            4'h2: ch_score = 7'h4f; // O
            4'h3: ch_score = 7'h52; // R
            4'h4: ch_score = 7'h45; // E
            4'h5: ch_score = 7'h3a; // :
            4'h6: ch_score = {3'b011, tens};    // digito de decenas, prefijo 011 = rango numeros ASCII
            4'h7: ch_score = {3'b011, units};   // digito de unidades
            4'h8: ch_score = 7'h00;
            4'h9: ch_score = 7'h00;
            4'ha: ch_score = 7'h42; // B
            4'hb: ch_score = 7'h41; // A
            4'hc: ch_score = 7'h4c; // L
            4'hd: ch_score = 7'h4c; // L
            4'he: ch_score = 7'h3a; // :
            4'hf: ch_score = {5'b01100, balls_left}; // numero de pelotas restantes en ASCII
        endcase

    // region del logo UNIS PONG en el centro inferior de la pantalla
    // px_y[9:6]==4 coloca el logo en y=256-319, escala x4 con bits [5:2] y [4:2]
    assign logo_on  = (px_y[9:6] == 4) && (6 <= px_x[9:5]) && (px_x[9:5] <= 14);
    assign row_logo = px_y[5:2];  // escala vertical x4
    assign col_logo = px_x[4:2];  // escala horizontal x4

    // selecciona el caracter del logo segun la posicion horizontal del pixel
    always_comb
        case (px_x[9:5])
            5'd6:    ch_logo = 7'h55; // U
            5'd7:    ch_logo = 7'h4e; // N
            5'd8:    ch_logo = 7'h49; // I
            5'd9:    ch_logo = 7'h53; // S
            5'd10:   ch_logo = 7'h00; // espacio
            5'd11:   ch_logo = 7'h50; // P
            5'd12:   ch_logo = 7'h4f; // O
            5'd13:   ch_logo = 7'h4e; // N
            5'd14:   ch_logo = 7'h47; // G
            default: ch_logo = 7'h00;
        endcase

    // region de reglas ubicada al centro de la pantalla
    // px_x[9:7]==2 y px_y[9:6]==2 la posicionan en x=256-383, y=128-191
    // escala x1 con bits [3:0] y [2:0]
    assign rules_on  = (px_x[9:7] == 2) && (px_y[9:6] == 2);
    assign row_rules = px_y[3:0];  // fila del bitmap sin escala
    assign col_rules = px_x[2:0];  // columna del bitmap sin escala

    // rules_idx combina bits de y y x para crear un indice unico por caracter
    // permite indexar una tabla 2D de 4 filas x 16 columnas de caracteres
    assign rules_idx = {px_y[5:4], px_x[6:3]};

    // tabla de caracteres de las reglas, indexada por rules_idx
    // muestra "RULE: USE TWO BUTTONS TO MOVE PADDLE UP AND DOWN."
    always_comb
        case (rules_idx)
            8'h00: ch_rules = 7'h52; // R
            8'h01: ch_rules = 7'h55; // U
            8'h02: ch_rules = 7'h4c; // L
            8'h03: ch_rules = 7'h45; // E
            8'h04: ch_rules = 7'h3a; // :
            8'h05: ch_rules = 7'h00;
            8'h06: ch_rules = 7'h00;
            8'h07: ch_rules = 7'h00;
            8'h08: ch_rules = 7'h00;
            8'h09: ch_rules = 7'h00;
            8'h0a: ch_rules = 7'h00;
            8'h0b: ch_rules = 7'h00;
            8'h0c: ch_rules = 7'h00;
            8'h0d: ch_rules = 7'h00;
            8'h0e: ch_rules = 7'h00;
            8'h0f: ch_rules = 7'h00;
            8'h10: ch_rules = 7'h55; // U
            8'h11: ch_rules = 7'h53; // S
            8'h12: ch_rules = 7'h45; // E
            8'h13: ch_rules = 7'h00;
            8'h14: ch_rules = 7'h54; // T
            8'h15: ch_rules = 7'h57; // W
            8'h16: ch_rules = 7'h4f; // O
            8'h17: ch_rules = 7'h00;
            8'h18: ch_rules = 7'h42; // B
            8'h19: ch_rules = 7'h55; // U
            8'h1a: ch_rules = 7'h54; // T
            8'h1b: ch_rules = 7'h54; // T
            8'h1c: ch_rules = 7'h4f; // O
            8'h1d: ch_rules = 7'h4e; // N
            8'h1e: ch_rules = 7'h53; // S
            8'h1f: ch_rules = 7'h00;
            8'h20: ch_rules = 7'h54; // T
            8'h21: ch_rules = 7'h4f; // O
            8'h22: ch_rules = 7'h00;
            8'h23: ch_rules = 7'h4d; // M
            8'h24: ch_rules = 7'h4f; // O
            8'h25: ch_rules = 7'h56; // V
            8'h26: ch_rules = 7'h45; // E
            8'h27: ch_rules = 7'h00;
            8'h28: ch_rules = 7'h50; // P
            8'h29: ch_rules = 7'h41; // A
            8'h2a: ch_rules = 7'h44; // D
            8'h2b: ch_rules = 7'h44; // D
            8'h2c: ch_rules = 7'h4c; // L
            8'h2d: ch_rules = 7'h45; // E
            8'h2e: ch_rules = 7'h00;
            8'h2f: ch_rules = 7'h00;
            8'h30: ch_rules = 7'h55; // U
            8'h31: ch_rules = 7'h50; // P
            8'h32: ch_rules = 7'h00;
            8'h33: ch_rules = 7'h41; // A
            8'h34: ch_rules = 7'h4e; // N
            8'h35: ch_rules = 7'h44; // D
            8'h36: ch_rules = 7'h00;
            8'h37: ch_rules = 7'h44; // D
            8'h38: ch_rules = 7'h4f; // O
            8'h39: ch_rules = 7'h57; // W
            8'h3a: ch_rules = 7'h4e; // N
            8'h3b: ch_rules = 7'h2e; // .
            8'h3c: ch_rules = 7'h00;
            8'h3d: ch_rules = 7'h00;
            8'h3e: ch_rules = 7'h00;
            8'h3f: ch_rules = 7'h00;
            default: ch_rules = 7'h00;
        endcase

    // region game over en el centro de la pantalla
    // px_y[9:6]==3 la coloca en y=192-255, misma posicion x que el logo
    // escala x4 con bits [5:2] y [4:2]
    assign over_on  = (px_y[9:6] == 3) && (6 <= px_x[9:5]) && (px_x[9:5] <= 14);
    assign row_over = px_y[5:2];  // escala vertical x4
    assign col_over = px_x[4:2];  // escala horizontal x4

    // selecciona el caracter de game over segun la posicion horizontal del pixel
    always_comb
        case (px_x[9:5])
            5'd6:    ch_over = 7'h47; // G
            5'd7:    ch_over = 7'h41; // A
            5'd8:    ch_over = 7'h4d; // M
            5'd9:    ch_over = 7'h45; // E
            5'd10:   ch_over = 7'h00; // espacio
            5'd11:   ch_over = 7'h4f; // O
            5'd12:   ch_over = 7'h56; // V
            5'd13:   ch_over = 7'h45; // E
            5'd14:   ch_over = 7'h52; // R
            default: ch_over = 7'h00;
        endcase

    // mux principal que decide que region se dibuja en el pixel actual
    // prioridad: score > reglas > logo > game over
    // los colores siguen la paleta de la Universidad del Istmo de Guatemala
    always_comb begin
        txt_rgb = 12'h722;  // color de fondo vino UNIS cuando no hay caracter

        if (score_on) begin
            ch_addr = ch_score;
            row_sel = row_score;
            col_sel = col_score;
            if (px_bit) txt_rgb = 12'hfff; // letras del score en blanco
        end
        else if (rules_on) begin
            ch_addr = ch_rules;
            row_sel = row_rules;
            col_sel = col_rules;
            if (px_bit) txt_rgb = 12'hda0; // letras de las reglas en dorado UNIS
        end
        else if (logo_on) begin
            ch_addr = ch_logo;
            row_sel = row_logo;
            col_sel = col_logo;
            if (px_bit) txt_rgb = 12'hda0; // letras del logo en dorado UNIS
        end
        else begin
            ch_addr = ch_over;
            row_sel = row_over;
            col_sel = col_over;
            if (px_bit) txt_rgb = 12'hfff; // letras de game over en blanco
        end
    end

    // regions_on indica al top level que regiones estan activas en el pixel actual
    // bit 3 = score, bit 2 = logo, bit 1 = reglas, bit 0 = game over
    assign regions_on = {score_on, logo_on, rules_on, over_on};

    // la direccion de la ROM se forma concatenando el codigo ascii del caracter y la fila
    assign rom_addr   = {ch_addr, row_sel};

    // px_bit extrae el bit del pixel actual del bitmap, invertido porque el MSB es la columna 0
    assign px_bit     = ch_pixels[~col_sel];

endmodule