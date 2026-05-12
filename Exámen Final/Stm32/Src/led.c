/*
 * led.c
 * Manejo de LEDs indicadores de estado de la cerradura.
 *
 * Hardware:
 * - LED Verde: PC4 -> resistencia 220Ω -> anodo LED -> catodo -> GND
 * - LED Rojo:  PC5 -> resistencia 220Ω -> anodo LED -> catodo -> GND
 *
 * Uso:
 * - led_green_on(): acceso concedido (PIN correcto o apertura por WiFi)
 * - led_red_on():   acceso denegado  (PIN incorrecto)
 * - Siempre llamar led_all_off() antes de encender el siguiente estado
 */

#include "led.h"

/*
 * led_init - configura PC4 y PC5 como salidas
 * Llamar una vez en main() durante la inicializacion de GPIO
 * Deja ambos LEDs apagados al inicio
 */
void led_init(void) {
    /* PC4 y PC5 como salida (MODER = 01) */
    GPIOC->MODER &= ~((3u << (LED_GREEN_PIN * 2u)) | (3u << (LED_RED_PIN * 2u)));
    GPIOC->MODER |=  ((1u << (LED_GREEN_PIN * 2u)) | (1u << (LED_RED_PIN * 2u)));

    /* Apagar ambos al inicio */
    led_all_off();
}

/*
 * led_green_on - enciende el LED verde
 * Usar cuando el acceso es concedido
 * Usa BSRR para escritura atomica sin afectar otros pines
 */
void led_green_on(void) {
    LED_GREEN_PORT->BSRR = (1u << LED_GREEN_PIN);
}

/*
 * led_green_off - apaga el LED verde
 */
void led_green_off(void) {
    LED_GREEN_PORT->BSRR = (1u << (LED_GREEN_PIN + 16u));
}

/*
 * led_red_on - enciende el LED rojo
 * Usar cuando el acceso es denegado
 */
void led_red_on(void) {
    LED_RED_PORT->BSRR = (1u << LED_RED_PIN);
}

/*
 * led_red_off - apaga el LED rojo
 */
void led_red_off(void) {
    LED_RED_PORT->BSRR = (1u << (LED_RED_PIN + 16u));
}

/*
 * led_all_off - apaga ambos LEDs
 * Llamar antes de cambiar de estado para evitar que
 * verde y rojo esten encendidos al mismo tiempo
 */
void led_all_off(void) {
    LED_GREEN_PORT->BSRR = (1u << (LED_GREEN_PIN + 16u));
    LED_RED_PORT->BSRR   = (1u << (LED_RED_PIN   + 16u));
}
