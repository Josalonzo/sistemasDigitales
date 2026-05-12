/*
 * led.h
 * Interface del modulo de LEDs indicadores para STM32L053R8
 *
 * Hardware:
 * - LED Verde (acceso concedido): PC4 -> resistencia 220Ω -> LED -> GND
 * - LED Rojo  (acceso denegado):  PC5 -> resistencia 220Ω -> LED -> GND
 */

#ifndef LED_H
#define LED_H

#include <stdint.h>
#include "stm32l053xx.h"

/* Pines de los LEDs */
#define LED_GREEN_PORT  GPIOC
#define LED_GREEN_PIN   4u   // PC4 - acceso concedido

#define LED_RED_PORT    GPIOC
#define LED_RED_PIN     5u   // PC5 - acceso denegado

/* Funciones publicas */
void led_init(void);         // configurar pines como salida
void led_green_on(void);     // encender verde
void led_green_off(void);    // apagar verde
void led_red_on(void);       // encender rojo
void led_red_off(void);      // apagar rojo
void led_all_off(void);      // apagar ambos

#endif
