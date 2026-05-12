/*
 * main.c
 * Punto de entrada del sistema. Cerradura electronica con PIN y WiFi.
 * STM32L053R8 - Nucleo-64 - 16MHz HSI
 *
 * Modulos:
 * - lock.c:   logica principal de la cerradura (PIN, estados, timeouts)
 * - keypad.c: teclado matricial 4x4
 * - lcd.c:    display LCD 16x2 HD44780
 * - buzzer.c: beeps y tono de alarma
 * - servo.c:  control PWM del servo SG90 (TIM2 CH1, PA8)
 * - wifi.c:   comunicacion UART con ESP32 NodeMCU (USART2, PA2/PA3)
 * - led.c:    LEDs indicadores verde (PC4) y rojo (PC5)
 *
 * Mapa de interrupciones:
 * - SysTick      @1s:    timeouts de la cerradura (apertura, bloqueo)
 * - TIM21        @6ms:   escaneo keypad
 * - TIM22        @0.5ms: tono buzzer + envio LCD no bloqueante
 * - USART2:              recepcion de comandos del ESP32 (OPEN/CLOSE)
 *
 * Mapa de timers:
 * - TIM2  CH1: PWM servo SG90 en PA8 (50Hz, configurado en servo_init)
 * - TIM21:     escaneo keypad cada ~6ms (interrupcion de update)
 * - TIM22:     tick buzzer + LCD cada 0.5ms
 *
 * Pines utilizados:
 * - PA2:           USART2 TX -> ESP32 RX
 * - PA3:           USART2 RX <- ESP32 TX
 * - PA8:           TIM2 CH1 PWM -> Servo SG90
 * - PB2,3,4,6:     filas keypad (salidas)
 * - PB7,8,9,10:    columnas keypad (entradas pull-up)
 * - PB12,14,15:    LCD D5, D7, RS
 * - PC0,1,9:       LCD EN, D6, D4
 * - PC3:           buzzer activo
 * - PC4:           LED verde (acceso concedido)
 * - PC5:           LED rojo  (acceso denegado)
 */

#include <stdint.h>
#include "stm32l053xx.h"
#include "lcd.h"
#include "keypad.h"
#include "buzzer.h"
#include "servo.h"
#include "wifi.h"
#include "led.h"
#include "lock.h"

void delayMs(uint16_t n);

int main(void) {

    __disable_irq();

    /* Habilitar HSI 16MHz como SYSCLK */
    RCC->CR   |= (1u << 0u);
    RCC->CFGR |= (1u << 0u);

    /* Habilitar clocks de GPIOA, GPIOB, GPIOC */
    RCC->IOPENR |= (1u << 0u);   // GPIOA
    RCC->IOPENR |= (1u << 1u);   // GPIOB
    RCC->IOPENR |= (1u << 2u);   // GPIOC

    /* ── Buzzer: PC3 como salida ── */
    GPIOC->MODER &= ~(3u << (BUZZ_PIN * 2u));
    GPIOC->MODER |=  (1u << (BUZZ_PIN * 2u));
    buzzer_set(0);

    /* ── LCD: PB12, PB14, PB15 (D5, D7, RS) como salida ── */
    GPIOB->MODER &= ~((3u << 24u) | (3u << 28u) | (3u << 30u));
    GPIOB->MODER |=  ((1u << 24u) | (1u << 28u) | (1u << 30u));

    /* ── LCD: PC0, PC1, PC9 (EN, D6, D4) como salida ── */
    GPIOC->MODER &= ~((3u << 0u) | (3u << 2u) | (3u << 18u));
    GPIOC->MODER |=  ((1u << 0u) | (1u << 2u) | (1u << 18u));

    /* ── Inicializar modulos que configuran su propio GPIO ── */
    keypad_init();   // PB2,3,4,6 filas / PB7,8,9,10 columnas pull-up
    wifi_init();     // PA2/PA3 AF4 USART2 9600 baud
    led_init();      // PC4 verde, PC5 rojo como salida

    /* ── TIM21: escaneo keypad cada ~6ms ──
     * 16MHz / PSC(1000) = 16kHz -> ARR(96) -> ~6ms */
    RCC->APB2ENR |= (1u << 2u);
    TIM21->PSC    = 1000u - 1u;
    TIM21->ARR    = 96u - 1u;
    TIM21->CR1   |= (1u << 0u);
    TIM21->DIER  |= (1u << 0u);

    /* ── Servo: PA0 TIM2 CH1 AF2 — TIM2 exclusivo para PWM ──
     * servo_init() configura TIM2 completo: PSC=319, ARR=999, 50Hz */
    servo_init();    // PA0 AF2 TIM2 CH1 PWM 50Hz

    /* ── TIM22: tick buzzer y LCD cada ~0.5ms (PSC=16, ARR=499, @16MHz = 2000Hz) ── */
    RCC->APB2ENR |= (1u << 5u);
    TIM22->PSC    = 16u - 1u;
    TIM22->ARR    = 500u - 1u;
    TIM22->CR1   |= (1u << 0u);
    TIM22->DIER  |= (1u << 0u);

    /* ── SysTick: interrupcion cada 1 segundo a 16MHz ── */
    SysTick->LOAD = 16000000u - 1u;
    SysTick->VAL  = 0u;
    SysTick->CTRL = 7u;

    /* ── Habilitar interrupciones en NVIC ── */
    NVIC_EnableIRQ(TIM21_IRQn);
    NVIC_EnableIRQ(TIM22_IRQn);
    NVIC_EnableIRQ(USART1_IRQn);

    __enable_irq();

    /* ── Inicializar LCD despues de habilitar interrupciones ── */
    lcd_init();

    /* ── Estado inicial de la cerradura ── */
    lock_init();   // servo cerrado, LEDs apagados, LCD "Ingrese PIN:"

    /* Todo se maneja por interrupciones y wifi_process en el loop */
    while (1) {
        /* Procesar comando WiFi si llego uno completo por UART */
        wifi_process();
    }
}

/*
 * TIM21_IRQHandler - escaneo del keypad cada ~6ms
 * Llama keypad_tick() que escanea una fila del teclado por vez.
 * La logica de la tecla detectada se delega a lock_key() via handle_key().
 */
void TIM21_IRQHandler(void) {
    TIM21->SR = 0;
    keypad_tick();
}

/*
 * TIM22_IRQHandler - manejo del buzzer y envio no bloqueante al LCD
 * Dispara cada ~0.5ms (2000Hz).
 * Modo 2 (RING_1S): toggle del pin del buzzer cada 3 ticks (~667Hz)
 *                   durante 2000 ticks (1 segundo)
 * Modo 1 (BEEP_N):  toggle durante 300 ticks (150ms ON)
 *                   silencio durante 200 ticks (100ms OFF)
 *                   repite N veces
 * Al final llama lcd_tick() para enviar 1 caracter del buffer al LCD
 */
void TIM22_IRQHandler(void) {
    TIM22->SR = 0;

    if (buz_mode == 2) {
        /* Modo ring: tono continuo de 1 segundo */
        buz_div++;
        if (buz_div >= 3u) {
            buz_div = 0;
            BUZZ_PORT->ODR ^= (1u << BUZZ_PIN);   // toggle para generar tono
        }
        ring_cnt++;
        if (ring_cnt >= 2000u) {
            buzzer_stop();   // detener tras 1 segundo
        }
    } else if (buz_mode == 1) {
        /* Modo beep: N beeps cortos */
        beep_cnt++;
        if (beep_on) {
            buz_div++;
            if (buz_div >= 3u) {
                buz_div = 0;
                BUZZ_PORT->ODR ^= (1u << BUZZ_PIN);
            }
            if (beep_cnt >= 300u) {       // 150ms encendido
                beep_on  = 0;
                beep_cnt = 0;
                buzzer_set(0);
                beep_remaining--;
                if (beep_remaining == 0u) {
                    buzzer_stop();        // todos los beeps completados
                }
            }
        } else {
            if (beep_cnt >= 200u) {       // 100ms apagado
                beep_on  = 1;
                beep_cnt = 0;
            }
        }
    }

    /* Enviar un caracter del buffer al LCD */
    lcd_tick();
}

/*
 * SysTick_Handler - timeouts de la cerradura cada 1 segundo
 * Llama lock_tick() que maneja:
 * - Cierre automatico tras LOCK_OPEN_TIME segundos
 * - Desbloqueo tras LOCK_BLOCK_TIME segundos
 */
void SysTick_Handler(void) {
    lock_tick();
}

/*
 * USART2_IRQHandler - definido en wifi.c
 * Acumula bytes hasta '\n' y activa wifi_cmd_ready
 * para que wifi_process() lo procese en el main loop
 */

/*
 * delayMs - delay bloqueante en milisegundos
 * Usado SOLO durante lcd_init() antes de que el sistema este corriendo.
 * No usar en ISRs ni durante operacion normal del sistema.
 * Calibrado para 16MHz: ~3195 iteraciones = 1ms
 */
void delayMs(uint16_t n) {
    uint16_t i;
    for (; n > 0; n--)
        for (i = 0; i < 3195u; i++);
}
