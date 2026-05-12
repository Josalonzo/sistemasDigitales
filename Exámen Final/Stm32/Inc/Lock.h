/*
 * lock.h
 * Interface del modulo de logica principal de la cerradura.
 *
 * Responsabilidades:
 * - Validar el PIN ingresado por teclado
 * - Controlar apertura/cierre del servo
 * - Manejar intentos fallidos (bloqueo tras 3 intentos)
 * - Coordinar LCD, LEDs, buzzer y servo en cada evento
 * - Recibir comandos de apertura desde WiFi
 *
 * Estados de la cerradura:
 * - LOCK_IDLE:    esperando PIN, mostrando pantalla principal
 * - LOCK_INPUT:   usuario ingresando PIN (teclas 0-9)
 * - LOCK_OPEN:    cerradura abierta (servo en posicion abierta)
 * - LOCK_BLOCKED: bloqueada por 3 intentos fallidos
 *
 * PIN por defecto: 1234
 * Se puede cambiar modificando LOCK_PIN en lock.c
 */

#ifndef LOCK_H
#define LOCK_H

#include <stdint.h>
#include "stm32l053xx.h"

/* Longitud del PIN */
#define LOCK_PIN_LEN     4u

/* Maximos intentos antes de bloquear */
#define LOCK_MAX_ATTEMPTS 3u

/* Tiempo de apertura en ticks de SysTick (1 tick = 1s) */
#define LOCK_OPEN_TIME   5u   // 5 segundos abierto

/* Tiempo de bloqueo en ticks de SysTick */
#define LOCK_BLOCK_TIME  30u  // 30 segundos bloqueado

/* Estados de la cerradura */
typedef enum {
    LOCK_IDLE    = 0,   // esperando ingreso de PIN
    LOCK_INPUT   = 1,   // usuario ingresando PIN
    LOCK_OPEN    = 2,   // cerradura abierta
    LOCK_BLOCKED = 3    // bloqueada por intentos fallidos
} lock_state_t;

/* Estado actual - modificado en ISRs y main loop */
extern volatile lock_state_t lock_state;

/* Contador de tiempo para estados con timeout */
extern volatile uint8_t lock_timer;

/* Intentos fallidos acumulados */
extern volatile uint8_t lock_attempts;

/* Funciones publicas */
void lock_init(void);           // inicializar estado inicial
void lock_tick(void);           // llamar desde SysTick cada 1 segundo
void lock_key(char k);          // procesar tecla del keypad
void lock_wifi_open(void);      // abrir desde WiFi
void lock_wifi_close(void);     // cerrar desde WiFi
void lock_update_lcd(void);     // actualizar LCD segun estado actual

#endif
