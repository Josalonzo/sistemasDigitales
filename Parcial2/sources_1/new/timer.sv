`timescale 1ns / 1ps

// Modulo: timer
// Descripcion: temporizador de cuenta regresiva utilizado para controlar
// el tiempo de espera entre estados de la FSM del juego.
// Se usa en dos situaciones:
// 1. Cuando se pierde una pelota (estado s_new_ball)
// 2. Cuando termina el juego (estado s_over)
module timer (
    input  logic clk,      // reloj del sistema 100MHz
    input  logic rst,      // reset asincrono activo alto
    input  logic t_start,  // señal para reiniciar la cuenta regresiva
    input  logic t_tick,   // pulso de 60Hz que avanza el conteo (una vez por frame)
    output logic t_up      // se pone en 1 cuando el tiempo se agoto
);

    // valor maximo del contador, define la duracion del temporizador
    
    localparam count_max = 7'b1111111;

    // registro actual del contador y su siguiente valor combinacional
    logic [7:0] count, count_next;

    // registro que actualiza el contador en cada flanco positivo de reloj
    // si hay reset regresa al valor maximo para tener tiempo completo
    always_ff @(posedge clk or posedge rst)
        if (rst) count <= count_max;
        else     count <= count_next;

    // logica combinacional que calcula el siguiente valor del contador
    // si t_start esta activo reinicia la cuenta al valor maximo
    // si t_tick llega y el contador no es cero decrementa en 1
    // si ninguna condicion aplica mantiene el valor actual
    always_comb begin
        if (t_start)
            count_next = count_max;
        else if (t_tick && count != '0)
            count_next = count - 1'b1;
        else
            count_next = count;
    end

    // t_up se pone en alto cuando el contador llega a cero
    // la FSM usa esta señal para saber cuando cambiar de estado
    assign t_up = (count == '0);

endmodule