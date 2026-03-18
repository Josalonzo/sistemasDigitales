`timescale 1ns / 1ps

// Modulo: score_counter
// Descripcion: contador BCD de dos digitos que lleva el marcador del juego.
// Cuenta de 00 a 99 en formato decimal codificado en binario (BCD).
// El modulo text usa los digitos para mostrar el score en pantalla.
module score_counter (
    input  logic       clk,  // reloj del sistema 100MHz
    input  logic       rst,  // reset asincrono activo alto
    input  logic       inc,  // incrementa el score en 1, se activa cuando la pelota golpea la paleta
    input  logic       clr,  // limpia el score a 00, se activa al iniciar un nuevo juego
    output logic [3:0] units, // digito de unidades del score (0-9)
    output logic [3:0] tens   // digito de decenas del score (0-9)
);

    // registros que almacenan el valor actual de cada digito
    // y sus valores combinacionales para el siguiente ciclo
    logic [3:0] units_reg, units_next;
    logic [3:0] tens_reg,  tens_next;

    // registro que actualiza los digitos en cada flanco positivo del reloj
    // si hay reset ambos digitos vuelven a cero
    always_ff @(posedge clk or posedge rst)
        if (rst) begin
            units_reg <= '0;
            tens_reg  <= '0;
        end else begin
            units_reg <= units_next;
            tens_reg  <= tens_next;
        end

    // logica combinacional que calcula el siguiente valor de cada digito
    // prioridad:
    // 1. clr activo -> ambos digitos se ponen a cero
    // 2. inc activo -> se incrementa el contador BCD
    //    si las unidades llegan a 9 se reinician y se incrementan las decenas
    //    si las decenas tambien llegan a 9 se reinician (vuelta a 00)
    // 3. ninguna condicion -> se mantiene el valor actual
    always_comb begin
        units_next = units_reg;
        tens_next  = tens_reg;

        if (clr) begin
            units_next = '0;  // limpia unidades al iniciar nuevo juego
            tens_next  = '0;  // limpia decenas al iniciar nuevo juego
        end else if (inc) begin
            if (units_reg == 9) begin
                units_next = '0;  // las unidades dan vuelta de 9 a 0
                tens_next  = (tens_reg == 9) ? '0 : tens_reg + 1'b1; // incrementa decenas o reinicia si llego a 9
            end else begin
                units_next = units_reg + 1'b1; // incremento normal de unidades
            end
        end
    end

    // los digitos registrados se exponen como salidas hacia el modulo text
    assign units = units_reg;
    assign tens  = tens_reg;

endmodule