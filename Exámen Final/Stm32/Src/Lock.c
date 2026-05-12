/*
 * lock.c
 * Logica principal de la cerradura electronica.
 *
 * Maneja la maquina de estados de la cerradura:
 *
 *   IDLE ──(primer digito)──> INPUT ──(PIN correcto)──> OPEN ──(timeout)──> IDLE
 *                                    └──(PIN incorrecto, <3)──> IDLE
 *                                    └──(PIN incorrecto, ==3)──> BLOCKED ──(timeout)──> IDLE
 *
 * Tambien responde a comandos WiFi desde wifi.c:
 *   lock_wifi_open()  -> abre directo sin PIN (si no esta bloqueada)
 *   lock_wifi_close() -> cierra manualmente
 */

#include "lock.h"
#include "lcd.h"
#include "servo.h"
#include "buzzer.h"
#include "led.h"

/* PIN correcto - modificar aqui para cambiar la clave */
static const char LOCK_PIN[LOCK_PIN_LEN] = {'5', '5', '5', '5'};

/* Estado actual de la cerradura */
volatile lock_state_t lock_state = LOCK_IDLE;

/* Contador de tiempo para timeouts (decrementado en lock_tick) */
volatile uint8_t lock_timer = 0;

/* Intentos fallidos acumulados */
volatile uint8_t lock_attempts = 0;

/* Buffer del PIN ingresado por el usuario */
static char input_buf[LOCK_PIN_LEN];

/* Cantidad de digitos ingresados */
static uint8_t input_len = 0;

/* ── Funciones privadas ── */

/*
 * input_reset - limpia el buffer de entrada
 */
static void input_reset(void) {
    input_len = 0;
    for (uint8_t i = 0; i < LOCK_PIN_LEN; i++) input_buf[i] = 0;
}

/*
 * input_check - compara el PIN ingresado con el correcto
 * Retorna 1 si coincide, 0 si no
 */
static uint8_t input_check(void) {
    for (uint8_t i = 0; i < LOCK_PIN_LEN; i++) {
        if (input_buf[i] != LOCK_PIN[i]) return 0;
    }
    return 1;
}

/*
 * do_open - ejecuta la secuencia de apertura
 * Mueve servo, enciende LED verde, beep, actualiza LCD
 */
static void do_open(void) {
    lock_state  = LOCK_OPEN;
    lock_timer  = LOCK_OPEN_TIME;
    lock_attempts = 0;

    servo_open();
    led_all_off();
    led_green_on();
    buzzer_beep_n(2);
    lcd_queue_update("  Bienvenido!   ", "Cerradura Abierta");
}

/*
 * do_close - ejecuta la secuencia de cierre
 * Mueve servo, apaga LEDs, actualiza LCD
 */
static void do_close(void) {
    lock_state = LOCK_IDLE;
    lock_timer = 0;

    servo_close();
    led_all_off();
    input_reset();
    lcd_queue_update(" Ingrese PIN:   ", "                ");
}

/*
 * do_denied - ejecuta la secuencia de acceso denegado
 * Enciende LED rojo, beep largo, actualiza LCD
 */
static void do_denied(void) {
    led_all_off();
    led_red_on();
    buzzer_beep_n(3);
    input_reset();

    if (lock_attempts >= LOCK_MAX_ATTEMPTS) {
        /* Bloquear cerradura */
        lock_state = LOCK_BLOCKED;
        lock_timer = LOCK_BLOCK_TIME;
        buzzer_ring_1s();
        lcd_queue_update(" BLOQUEADA      ", "Espere 30 seg   ");
    } else {
        /* Volver a IDLE mostrando intentos restantes */
        lock_state = LOCK_IDLE;
        char line2[16] = "Intentos:       ";
        uint8_t restantes = LOCK_MAX_ATTEMPTS - lock_attempts;
        line2[10] = (char)('0' + restantes);
        lcd_queue_update("PIN incorrecto  ", line2);
    }
}

/* ── Funciones publicas ── */

/*
 * lock_init - inicializar estado de la cerradura
 * Llamar una vez en main() despues de inicializar todos los modulos
 */
void lock_init(void) {
    input_reset();
    lock_state    = LOCK_IDLE;
    lock_timer    = 0;
    lock_attempts = 0;

    servo_close();
    led_all_off();
    lcd_queue_update(" Ingrese PIN:   ", "                ");
}

/*
 * lock_tick - manejo de timeouts, llamar desde SysTick cada 1 segundo
 * Cierra la cerradura automaticamente tras LOCK_OPEN_TIME segundos
 * Desbloquea tras LOCK_BLOCK_TIME segundos
 */
void lock_tick(void) {
    if (lock_timer == 0) return;

    lock_timer--;

    if (lock_timer == 0) {
        if (lock_state == LOCK_OPEN) {
            do_close();   // cerrar automaticamente
        } else if (lock_state == LOCK_BLOCKED) {
            lock_attempts = 0;
            do_close();   // desbloquear
        }
    }
}

/*
 * lock_key - procesar tecla recibida del keypad
 * Llamar desde handle_key() en keypad.c
 *
 * Logica:
 * - Si BLOCKED: ignorar todo
 * - Si OPEN: '*' cierra manualmente
 * - Digitos 0-9: acumular en buffer
 * - '#' o 'D': confirmar PIN si hay 4 digitos
 * - '*': borrar ultimo digito
 * - 'C': cancelar entrada
 */
void lock_key(char k) {
    if (lock_state == LOCK_BLOCKED) return;

    /* Si esta abierta, solo permitir cerrar con '*' */
    if (lock_state == LOCK_OPEN) {
        if (k == '*') do_close();
        return;
    }

    /* Digitos: acumular en buffer */
    if (k >= '0' && k <= '9') {
        if (input_len < LOCK_PIN_LEN) {
            input_buf[input_len] = k;
            input_len++;
            buzzer_beep_n(1);

            /* Mostrar asteriscos en LCD segun digitos ingresados */
            char line2[16] = "                ";
            for (uint8_t i = 0; i < input_len; i++) line2[i] = '*';
            lcd_queue_update(" Ingrese PIN:   ", line2);

            /* Auto-validar cuando se completan los 4 digitos */
            if (input_len == LOCK_PIN_LEN) {
                if (input_check()) {
                    do_open();
                } else {
                    lock_attempts++;
                    do_denied();
                }
            }
        }
        return;
    }

    /* '#' o 'D': confirmar PIN manualmente */
    if (k == '#' || k == 'D') {
        if (input_len == LOCK_PIN_LEN) {
            if (input_check()) {
                do_open();
            } else {
                lock_attempts++;
                do_denied();
            }
        }
        return;
    }

    /* '*': borrar ultimo digito */
    if (k == '*') {
        if (input_len > 0) {
            input_len--;
            input_buf[input_len] = 0;
            buzzer_beep_n(1);

            char line2[16] = "                ";
            for (uint8_t i = 0; i < input_len; i++) line2[i] = '*';
            lcd_queue_update(" Ingrese PIN:   ", line2);
        }
        return;
    }

    /* 'C': cancelar entrada */
    if (k == 'C') {
        input_reset();
        buzzer_beep_n(1);
        lcd_queue_update(" Ingrese PIN:   ", "                ");
        return;
    }
}

/*
 * lock_wifi_open - abrir cerradura desde comando WiFi
 * Ignorar si esta bloqueada
 */
void lock_wifi_open(void) {
    if (lock_state == LOCK_BLOCKED) return;
    do_open();
}

/*
 * lock_wifi_close - cerrar cerradura desde comando WiFi
 */
void lock_wifi_close(void) {
    if (lock_state == LOCK_OPEN) {
        do_close();
    }
}

/*
 * lock_update_lcd - refrescar LCD segun estado actual
 * Llamar si se necesita redibujar la pantalla
 */
void lock_update_lcd(void) {
    switch (lock_state) {
        case LOCK_IDLE:
            lcd_queue_update(" Ingrese PIN:   ", "                ");
            break;
        case LOCK_OPEN:
            lcd_queue_update("  Bienvenido!   ", "Cerradura Abierta");
            break;
        case LOCK_BLOCKED:
            lcd_queue_update(" BLOQUEADA      ", "Espere 30 seg   ");
            break;
        default:
            break;
    }
}
