/*
 * wifi.h
 * Interface del modulo WiFi para STM32L053R8
 *
 * Hardware:
 * - TX: PA9  (USART1_TX, AF4) -> RX del ESP32 NodeMCU (GPIO16)
 * - RX: PA10 (USART1_RX, AF4) -> TX del ESP32 NodeMCU (GPIO17)
 * - VCC: 3.3V del Nucleo
 * - GND: GND del Nucleo
 *
 * NOTA: Se usa USART1 en vez de USART2 porque PA2/PA3
 * son usados por el ST-Link VCP y no estan disponibles.
 */

#ifndef WIFI_H
#define WIFI_H

#include <stdint.h>
#include "stm32l053xx.h"

#define WIFI_BUF_SIZE  16u

#define WIFI_CMD_OPEN   "OPEN"
#define WIFI_CMD_CLOSE  "CLOSE"

extern volatile char    wifi_buf[WIFI_BUF_SIZE];
extern volatile uint8_t wifi_len;
extern volatile uint8_t wifi_cmd_ready;

void    wifi_init(void);
void    wifi_process(void);
uint8_t wifi_match(const char *cmd);
void    wifi_clear(void);

#endif
