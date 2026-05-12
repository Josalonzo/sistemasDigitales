/*
 * wifi.c
 * Manejo de comunicacion UART con el ESP32 NodeMCU.
 *
 * Configuracion USART:
 * - PA9:  USART1 TX (AF4)
 * - PA10: USART1 RX (AF4)
 * - 9600 baud, 8N1
 * - Interrupcion RXNE
 *
 * NOTA: Se cambio de USART2 (PA2/PA3) a USART1 (PA9/PA10)
 * porque PA2/PA3 son usados por el ST-Link VCP del Nucleo
 * y compiten con USART2 cuando el USB esta conectado.
 */

#include "wifi.h"
#include "lock.h"

/* Buffer de recepcion - llenado byte a byte en la ISR */
volatile char    wifi_buf[WIFI_BUF_SIZE];

/* Cantidad de bytes recibidos en el buffer actual */
volatile uint8_t wifi_len = 0;

/* Flag: 1 cuando llego '\n' y el comando esta listo para procesar */
volatile uint8_t wifi_cmd_ready = 0;

/*
 * wifi_init - configura USART1 y los pines PA9/PA10
 */
void wifi_init(void) {
    /* Habilitar clocks */
    RCC->IOPENR  |= (1u << 0u);   // GPIOA
    RCC->APB2ENR |= (1u << 14u);  // USART1 esta en APB2

    /* PA9: modo alternativo (MODER = 10) */
    GPIOA->MODER &= ~(3u << (9u * 2u));
    GPIOA->MODER |=  (2u << (9u * 2u));

    /* PA10: modo alternativo (MODER = 10) */
    GPIOA->MODER &= ~(3u << (10u * 2u));
    GPIOA->MODER |=  (2u << (10u * 2u));

    /* PA9 y PA10: funcion alternativa AF4 (USART1) en AFR[1] */
    /* PA9:  bits [7:4]  de AFR[1] -> posicion (9-8)*4  = 4  */
    /* PA10: bits [11:8] de AFR[1] -> posicion (10-8)*4 = 8  */
    GPIOA->AFR[1] &= ~((0xFu << 4u) | (0xFu << 8u));
    GPIOA->AFR[1] |=  ((0x4u << 4u) | (0x4u << 8u));   // AF4

    /* USART1: 9600 baud a 16MHz -> BRR = 16000000/9600 = 1667 = 0x683 */
    USART1->BRR = 0x683u;

    /* Habilitar interrupcion RXNE (bit 5) */
    USART1->CR1 |= (1u << 5u);

    /* Habilitar TX (bit 3), RX (bit 2) y USART (bit 0) */
    USART1->CR1 |= (1u << 3u) | (1u << 2u) | (1u << 0u);

    /* Habilitar interrupcion USART1 en NVIC */
    NVIC_EnableIRQ(USART1_IRQn);
}

/*
 * wifi_match - compara el buffer con un comando esperado
 */
uint8_t wifi_match(const char *cmd) {
    uint8_t i = 0;
    while (cmd[i] != '\0') {
        if (i >= wifi_len)           return 0;
        if (wifi_buf[i] != cmd[i])   return 0;
        i++;
    }
    return 1;
}

/*
 * wifi_clear - limpia el buffer y resetea los flags
 */
void wifi_clear(void) {
    wifi_len       = 0;
    wifi_cmd_ready = 0;
    for (uint8_t i = 0; i < WIFI_BUF_SIZE; i++) wifi_buf[i] = 0;
}

/*
 * wifi_process - procesa el comando recibido en el main loop
 */
void wifi_process(void) {
    if (!wifi_cmd_ready) return;

    if (wifi_match(WIFI_CMD_OPEN)) {
        lock_wifi_open();
    } else if (wifi_match(WIFI_CMD_CLOSE)) {
        lock_wifi_close();
    }

    wifi_clear();
}

/*b
 * USART1_IRQHandler - recepcion byte a byte del ESP32
 */
void USART1_IRQHandler(void) {
    if (USART1->ISR & (1u << 5u)) {   // RXNE
        char c = (char)(USART1->RDR & 0xFFu);

        //GPIOC->ODR ^= (1u << 4u);     // toggle LED verde — debug

        if (c == '\n') {
            wifi_cmd_ready = 1;
        } else if (c != '\r') {
            if (wifi_len < WIFI_BUF_SIZE - 1u) {
                wifi_buf[wifi_len] = c;
                wifi_len++;
            }
        }
    }
}
