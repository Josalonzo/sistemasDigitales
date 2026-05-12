/*
 * keypad.c
 * Manejo del teclado matricial 4x4.
 *
 * Hardware:
 * - Filas (salidas): PB2, PB3, PB4, PB6
 * - Columnas (entradas con pull-up): PB7, PB8, PB9, PB10
 *
 * El escaneo se hace por TIM2 barriendo una fila por tick (~6ms).
 * Se usa kp_lock para evitar deteccion multiple de la misma tecla.
 *
 * Diferencia con proyecto anterior:
 * - Eliminada toda la logica del reloj (ui_state, st_digits, etc.)
 * - handle_key() ahora solo llama lock_key() de lock.c
 * - Agregado keypad_init() para configurar GPIO desde aqui
 */

#include "keypad.h"
#include "lock.h"

/* Mapa de teclas del teclado 4x4 */
static const char KP_MAP[4][4] = {
    {'1', '2', '3', 'A'},
    {'4', '5', '6', 'B'},
    {'7', '8', '9', 'C'},
    {'*', '0', '#', 'D'}
};

/* Fila actual siendo escaneada (0-3, cicla en keypad_tick) */
volatile uint8_t kp_row_seq    = 0;

/* Lock: 1=tecla detectada, espera a que se suelte antes de aceptar otra */
volatile uint8_t kp_lock       = 0;

/* Fila que estaba activa cuando se detecto la tecla */
volatile uint8_t kp_row_active = 0;

/* Ultima tecla decodificada como caracter ASCII */
volatile uint8_t kp_key        = 0xFF;

/* Flag: 1=hay tecla nueva disponible para leer */
volatile uint8_t kp_pressed    = 0;

/* Contador de debounce: espera N ticks antes de liberar el lock */
volatile uint8_t kp_debounce   = 0;
#define KP_DEBOUNCE_TICKS  8u   // 8 ticks x ~6ms = ~48ms

/*
 * keypad_init - configura los pines GPIO del keypad
 * Filas PB2,PB3,PB4,PB6 como salida
 * Columnas PB7,PB8,PB9,PB10 como entrada con pull-up
 * Llamar una vez en main() antes de habilitar interrupciones
 */
void keypad_init(void) {
    /* Habilitar clock GPIOB */
    RCC->IOPENR |= (1u << 1u);

    /* Filas: PB2,PB3,PB4,PB6 como salida (MODER = 01) */
    GPIOB->MODER &= ~((3u << (KP_ROW0_PIN * 2u)) |
                      (3u << (KP_ROW1_PIN * 2u)) |
                      (3u << (KP_ROW2_PIN * 2u)) |
                      (3u << (KP_ROW3_PIN * 2u)));
    GPIOB->MODER |=  ((1u << (KP_ROW0_PIN * 2u)) |
                      (1u << (KP_ROW1_PIN * 2u)) |
                      (1u << (KP_ROW2_PIN * 2u)) |
                      (1u << (KP_ROW3_PIN * 2u)));

    /* Columnas: PB7,PB8,PB9,PB10 como entrada (MODER = 00) */
    GPIOB->MODER &= ~((3u << (KP_COL0_PIN * 2u)) |
                      (3u << (KP_COL1_PIN * 2u)) |
                      (3u << (KP_COL2_PIN * 2u)) |
                      (3u << (KP_COL3_PIN * 2u)));

    /* Pull-up interno en columnas */
    GPIOB->PUPDR &= ~((3u << (KP_COL0_PIN * 2u)) |
                      (3u << (KP_COL1_PIN * 2u)) |
                      (3u << (KP_COL2_PIN * 2u)) |
                      (3u << (KP_COL3_PIN * 2u)));
    GPIOB->PUPDR |=  ((1u << (KP_COL0_PIN * 2u)) |
                      (1u << (KP_COL1_PIN * 2u)) |
                      (1u << (KP_COL2_PIN * 2u)) |
                      (1u << (KP_COL3_PIN * 2u)));

    /* Todas las filas en HIGH (reposo) */
    GPIOB->ODR |= KP_ROW_MASK;
}

/*
 * kp_cols_all_high - verifica si todas las columnas estan en HIGH
 * Retorna 1 si ninguna tecla esta presionada
 * Usado para detectar cuando se suelta una tecla y liberar kp_lock
 */
uint8_t kp_cols_all_high(void) {
    uint32_t idr = GPIOB->IDR;
    uint8_t c0 = (uint8_t)((idr >> KP_COL0_PIN) & 1u);
    uint8_t c1 = (uint8_t)((idr >> KP_COL1_PIN) & 1u);
    uint8_t c2 = (uint8_t)((idr >> KP_COL2_PIN) & 1u);
    uint8_t c3 = (uint8_t)((idr >> KP_COL3_PIN) & 1u);
    return (uint8_t)(c0 & c1 & c2 & c3);
}

/*
 * keypad_getkey - retorna la ultima tecla presionada
 * Retorna 0 si no hay tecla nueva disponible
 * Limpia el flag kp_pressed al leer
 */
uint8_t keypad_getkey(void) {
    if (!kp_pressed) return 0;
    kp_pressed = 0;
    return kp_key;
}

/*
 * handle_key - procesa la tecla presionada
 * Delega toda la logica a lock_key() en lock.c
 * El modulo keypad no toma decisiones — solo detecta y pasa la tecla
 */
void handle_key(char k) {
    if (k == 0) return;
    lock_key(k);
}

/*
 * keypad_tick - escanea una fila del teclado por llamada
 * Llamado desde TIM2_IRQHandler cada ~6ms.
 * Lee las columnas de la fila activa del tick anterior,
 * luego prepara la siguiente fila para el proximo tick.
 * Usa kp_lock para ignorar detecciones multiples de la misma tecla.
 */
void keypad_tick(void) {
    /* Leer columnas de la fila activa en el tick anterior */
    if (!kp_lock) {
        uint8_t col = 0xFF;
        if      (!(GPIOB->IDR & (1u << KP_COL0_PIN))) col = 0;
        else if (!(GPIOB->IDR & (1u << KP_COL1_PIN))) col = 1;
        else if (!(GPIOB->IDR & (1u << KP_COL2_PIN))) col = 2;
        else if (!(GPIOB->IDR & (1u << KP_COL3_PIN))) col = 3;

        if (col != 0xFF) {
            /* Tecla detectada: decodificar y procesar */
            kp_key     = (uint8_t)KP_MAP[kp_row_active][col];
            kp_pressed = 1;
            kp_lock    = 1;
            handle_key((char)kp_key);
        }
    }

    /* Desbloquear cuando todas las columnas vuelven a HIGH Y
     * el debounce counter llega a 0 — evita detecciones multiples */
    if (kp_lock) {
        if (kp_cols_all_high()) {
            if (kp_debounce > 0u) {
                kp_debounce--;
            } else {
                kp_lock = 0;
            }
        } else {
            kp_debounce = KP_DEBOUNCE_TICKS;  // reset si sigue presionada
        }
    }

    /* Preparar siguiente fila: poner HIGH todas y bajar solo la activa */
    kp_row_active = kp_row_seq;
    GPIOB->ODR |= KP_ROW_MASK;
    switch (kp_row_seq) {
        case 0:  GPIOB->ODR &= ~(1u << KP_ROW0_PIN); break;
        case 1:  GPIOB->ODR &= ~(1u << KP_ROW1_PIN); break;
        case 2:  GPIOB->ODR &= ~(1u << KP_ROW2_PIN); break;
        default: GPIOB->ODR &= ~(1u << KP_ROW3_PIN); break;
    }
    kp_row_seq++;
    if (kp_row_seq >= 4u) kp_row_seq = 0;
}
