/*
 * buzzer.c
 * Manejo del buzzer activo conectado en PC3.
 *
 * Soporta dos modos:
 *   - Modo 1 (BEEP_N):  N beeps cortos de 150ms ON / 100ms OFF
 *   - Modo 2 (RING_1S): tono continuo de 1 segundo
 *
 * La generacion del tono se hace en TIM22_IRQHandler (main.c)
 * toggleando el pin cada 3 ticks a ~667Hz (TIM22 @ 2000Hz).
 *
 * Diferencia con proyecto anterior:
 * - Pin cambiado de PB5 a PC3
 * - Puerto cambiado de GPIOB a GPIOC
 */

#include "buzzer.h"

/* Modo actual del buzzer: 0=OFF, 1=BEEP_N, 2=RING_1S */
volatile uint8_t  buz_mode = 0;

/* Divisor para controlar la frecuencia del tono */
volatile uint16_t buz_div = 0;

/* Cantidad de beeps que faltan por ejecutar */
volatile uint8_t  beep_remaining = 0;

/* Flag: 1=buzzer encendido en este ciclo, 0=apagado */
volatile uint8_t  beep_on = 0;

/* Contador de ticks del beep actual */
volatile uint16_t beep_cnt = 0;

/* Contador de ticks del ring (maximo 2000 = 1 segundo) */
volatile uint16_t ring_cnt = 0;

/*
 * buzzer_set - enciende o apaga el buzzer directamente
 * on: 1 = encender, 0 = apagar
 * Usa BSRR para escritura atomica sin afectar otros pines de GPIOC
 */
void buzzer_set(uint8_t on) {
    if (on) BUZZ_PORT->BSRR = (1u << BUZZ_PIN);
    else    BUZZ_PORT->BSRR = (1u << (BUZZ_PIN + 16u));
}

/*
 * buzzer_stop - detiene el buzzer inmediatamente
 * Resetea todas las variables de estado y apaga el pin
 */
void buzzer_stop(void) {
    buz_mode       = 0;
    beep_remaining = 0;
    beep_on        = 0;
    beep_cnt       = 0;
    ring_cnt       = 0;
    buzzer_set(0);
}

/*
 * buzzer_beep_n - inicia una secuencia de N beeps cortos
 * n: cantidad de beeps a ejecutar
 * Cada beep dura 150ms ON y 100ms OFF (controlado por TIM22)
 * Usado para feedback de teclas y confirmaciones
 */
void buzzer_beep_n(uint8_t n) {
    if (n == 0) return;
    buz_mode       = 1;
    beep_remaining = n;
    beep_on        = 1;
    beep_cnt       = 0;
    buz_div        = 0;
}

/*
 * buzzer_ring_1s - inicia un tono continuo de 1 segundo
 * Usado para alarma de acceso denegado (3 intentos fallidos)
 * TIM22 lo detiene automaticamente cuando ring_cnt llega a 2000
 */
void buzzer_ring_1s(void) {
    buz_mode = 2;
    ring_cnt = 0;
    buz_div  = 0;
}
