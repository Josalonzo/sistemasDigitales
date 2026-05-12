/*
 * servo.c
 * Control del servo SG90 mediante PWM en PA8 (TIM2 CH1).
 *
 * El SG90 se controla con una señal PWM de 50Hz (periodo 20ms).
 * La posicion depende del ancho del pulso:
 *   - 1.0ms (SERVO_CLOSE = CCR1 50)  -> 0°   cerradura cerrada
 *   - 1.5ms (SERVO_OPEN  = CCR1 75)  -> 90°  cerradura abierta
 *
 * TIM2 CH1 usa funcion alternativa AF2 en PA8.
 * El timer genera el PWM por hardware sin necesidad de ISR.
 */

#include "servo.h"

/*
 * servo_init - configura PA8 como salida PWM y arranca TIM2 CH1
 *
 * Pasos:
 * 1. Habilitar clock de GPIOA y TIM2
 * 2. PA8 en modo AF2 (TIM2_CH1)
 * 3. Configurar TIM2: PSC=319, ARR=999 para 50Hz a 16MHz
 * 4. Modo PWM1 en CH1: CCR1 alto mientras CNT < CCR1
 * 5. Arrancar el timer en posicion cerrada
 */
void servo_init(void) {
    /* Habilitar clocks */
    RCC->IOPENR  |= (1u << 0);   // GPIOA
    RCC->APB1ENR |= (1u << 0);   // TIM2

    /* PA0: modo alternativo (MODER = 10) */
    GPIOA->MODER &= ~(3u << (0u * 2u));
    GPIOA->MODER |=  (2u << (0u * 2u));

    /* PA0: funcion alternativa AF2 (TIM2_CH1) en AFR[0] */
    /* PA0 esta en AFR[0] (pines 0-7), posicion = 0*4 = 0 */
    GPIOA->AFR[0] &= ~(0xFu << 0u);
    GPIOA->AFR[0] |=  (0x2u << 0u);   // AF2 = TIM2

    /* TIM2: PSC y ARR para 50Hz */
    TIM2->PSC = 319u;    // 16MHz / 320 = 50kHz -> tick = 20us
    TIM2->ARR = 999u;    // 1000 ticks x 20us  = 20ms = 50Hz

    /* CH1: modo PWM1 (OC1M = 110), preload habilitado */
    TIM2->CCMR1 &= ~(0x7u << 4u);
    TIM2->CCMR1 |=  (0x6u << 4u);   // PWM mode 1
    TIM2->CCMR1 |=  (1u   << 3u);   // OC1PE: preload enable

    /* Habilitar salida CH1 */
    TIM2->CCER |= (1u << 0u);   // CC1E

    /* Cargar ARR inmediatamente */
    TIM2->CR1 |= (1u << 7u);   // ARPE: auto-reload preload

    /* Posicion inicial: cerrado */
    TIM2->CCR1 = SERVO_CLOSE;

    /* Generar evento de update para cargar los registros de preload */
    TIM2->EGR |= (1u << 0u);

    /* Arrancar el timer */
    TIM2->CR1 |= (1u << 0u);   // CEN
}

/*
 * servo_open - mueve el servo a posicion abierta (90°)
 * Cambia CCR1 a 75 -> pulso de 1.5ms -> 90 grados
 * El SG90 tarda ~300ms en llegar a la posicion
 */
void servo_open(void) {
    TIM2->CCR1 = SERVO_OPEN;
}

/*
 * servo_close - mueve el servo a posicion cerrada (0°)
 * Cambia CCR1 a 50 -> pulso de 1.0ms -> 0 grados
 * El SG90 tarda ~300ms en llegar a la posicion
 */
void servo_close(void) {
    TIM2->CCR1 = SERVO_CLOSE;
}
