/*
 * buzzer.h
 * Interface del modulo buzzer para STM32L053R8
 *
 * Hardware:
 * - Pin: PC3 (cambiado de PB5 del proyecto anterior)
 *
 * Modos de operacion:
 * - Modo 0: OFF
 * - Modo 1 (BEEP_N):  N beeps cortos de 150ms ON / 100ms OFF
 * - Modo 2 (RING_1S): tono continuo de 1 segundo
 *
 * La generacion del tono se hace en TIM22_IRQHandler (main.c)
 * toggleando el pin cada tick a ~667Hz.
 */

#ifndef BUZZER_H
#define BUZZER_H

#include <stdint.h>
#include "stm32l053xx.h"

/* Pin del buzzer */
#define BUZZ_PORT  GPIOC
#define BUZZ_PIN   3u   // PC3

/* Variables de estado - modificadas en TIM22_IRQHandler */
extern volatile uint8_t  buz_mode;        // 0=OFF, 1=BEEP_N, 2=RING_1S
extern volatile uint16_t buz_div;         // divisor de frecuencia del tono
extern volatile uint8_t  beep_remaining;  // beeps pendientes
extern volatile uint8_t  beep_on;         // 1=fase ON, 0=fase OFF
extern volatile uint16_t beep_cnt;        // contador de ticks del beep
extern volatile uint16_t ring_cnt;        // contador de ticks del ring

/* Funciones publicas */
void buzzer_set(uint8_t on);    // encender/apagar directo
void buzzer_stop(void);         // detener inmediatamente
void buzzer_beep_n(uint8_t n);  // N beeps cortos (feedback de teclas)
void buzzer_ring_1s(void);      // tono continuo 1 segundo (alarma)

#endif
