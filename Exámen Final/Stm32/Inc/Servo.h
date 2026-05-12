/*
 * servo.h
 * Interface del modulo servo SG90 para STM32L053R8
 *
 * Hardware:
 * - Señal PWM: PA0 (TIM2 CH1, AF2)  <-- cambiado de PA8
 * - VCC:       5V del Nucleo
 * - GND:       GND del Nucleo
 *
 * Configuracion PWM:
 * - Reloj:    16MHz HSI
 * - PSC:      319  -> tick = 320/16MHz = 20us
 * - ARR:      999  -> periodo = 1000 x 20us = 20ms = 50Hz
 * - CCR1 posiciones:
 *     0°   = 50  (50  x 20us = 1.0ms)
 *     90°  = 75  (75  x 20us = 1.5ms)
 *     180° = 100 (100 x 20us = 2.0ms)
 *
 * NOTA sobre TIM2 compartido:
 * TIM2 se usa tambien para el escaneo del keypad (interrupcion de update).
 * El PWM en CH1 y la interrupcion de update coexisten sin conflicto:
 * - CH1 genera PWM por hardware (no necesita ISR)
 * - La ISR de update solo escanea el keypad
 * servo_init() debe llamarse DESPUES de configurar el keypad en main.c
 */

#ifndef SERVO_H
#define SERVO_H

#include <stdint.h>
#include "stm32l053xx.h"

/* Valores CCR1 para cada posicion */
#define SERVO_CLOSE  50u   // 0°   - cerradura cerrada
#define SERVO_OPEN   75u   // 90°  - cerradura abierta

/* Funciones publicas */
void servo_init(void);   // configurar TIM2 CH1 en PA8
void servo_open(void);   // mover a posicion abierta
void servo_close(void);  // mover a posicion cerrada

#endif
