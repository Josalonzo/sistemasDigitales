<div align="center">
  <img src="Demo/logoUNIS.png" alt="Logo UNIS" width="180"/>
  <h1>Cerradura Electrónica — STM32L053R8</h1>
  <p><em>Universidad del Istmo · Facultad de Ingeniería</em></p>
  <p><em>Ingeniería en Electrónica y Telecomunicaciones · 5to Año</em></p>
  <p><em>José Alonzo · Examen Final Sistemas Digitales · 2026</em></p>
</div>

---

## Tabla de Contenido

- [Descripción](#descripción)
- [Fotografías del Prototipo](#fotografías-del-prototipo)
- [Características](#características)
- [Hardware](#hardware)
- [Mapa de Pines](#mapa-de-pines)
- [Arquitectura de Software](#arquitectura-de-software)
- [Control WiFi](#control-wifi)
- [Configuración](#configuración)
- [Estructura del Repositorio](#estructura-del-repositorio)
- [Herramientas](#herramientas)
- [Autor](#autor)

---

## Descripción

Cerradura electrónica desarrollada para el **STM32L053R8** en bare metal (sin HAL). Permite el control de acceso mediante PIN ingresado por teclado matricial 4x4, con retroalimentación visual en LCD 16x2 y apertura remota vía WiFi desde el navegador del celular. El prototipo está montado en una **caja acrílica transparente** que contiene toda la circuitería y el mecanismo de apertura basado en un servo SG90.

---

## Fotografías del Prototipo

### Vista General — Prototipo acrílico

![Vista general](Demo/front.HEIC)

> Vista superior del prototipo: se aprecia el keypad 4x4 en la esquina superior derecha, la LCD azul al centro, los LEDs indicadores (verde = acceso concedido, rojo = acceso denegado), el servo SG90 como mecanismo de apertura y el STM32 Nucleo-64 en la base, todo contenido dentro de la caja acrílica transparente.

### Vista Lateral 1 — LEDs indicadores

![Side 1](Demo/side2.HEIC)

> Vista lateral izquierda del prototipo encendido. Se pueden apreciar claramente el LED verde y el LED rojo indicadores de estado (acceso concedido y denegado respectivamente) y el sistema de iluminación interna de la caja acrílica.

### Vista Lateral 2 — Componentes principales

![Side 2](Demo/side3.HEIC)

> Vista lateral derecha donde se distinguen el buzzer (cilindro azul), el keypad matricial 4x4 y los componentes en breadboard. El ESP32 NodeMCU se encuentra en la parte inferior izquierda conectado al STM32 vía UART.

### Vista Frontal — Mecanismo de apertura

![Frontal](Demo/Side1.HEIC)

> Vista frontal del prototipo. Se aprecia el servo SG90 asomando por la parte delantera de la caja acrílica, actuando como mecanismo de cerrojo. El cable USB conectado al STM32 Nucleo-64 proporciona alimentación al sistema.

---

## Características

- Ingreso de PIN de 4 dígitos mediante teclado matricial 4x4
- Control remoto vía WiFi desde el navegador del celular
- Display LCD 16x2 con mensajes de estado
- Servo SG90 como mecanismo de apertura
- LEDs indicadores (verde = acceso concedido, rojo = denegado)
- Buzzer con feedback sonoro
- Bloqueo automático tras 3 intentos fallidos (30 segundos)
- Cierre automático tras 5 segundos de apertura

---

## Hardware

| Componente | Descripción |
|---|---|
| STM32L053R8 Nucleo-64 | Microcontrolador principal |
| LCD 16x2 HD44780 | Display en modo 4 bits |
| Keypad 4x4 membrana | Entrada de PIN |
| Servo SG90 180° | Mecanismo de apertura |
| ESP32 NodeMCU-32S | Módulo WiFi (servidor web) |
| Buzzer activo 5V | Feedback sonoro |
| LED verde | Acceso concedido |
| LED rojo | Acceso denegado |

---

## Mapa de Pines

### LCD HD44780 (modo 4 bits)
| Pin LCD | Pin STM32 |
|---|---|
| RS | PB15 |
| EN | PC0 |
| D4 | PC9 |
| D5 | PB12 |
| D6 | PC1 |
| D7 | PB14 |
| RW | GND |

### Keypad 4x4
| Pin Keypad | Pin STM32 |
|---|---|
| R1 | PB2 |
| R2 | PB3 |
| R3 | PB4 |
| R4 | PB6 |
| C1 | PB7 |
| C2 | PB8 |
| C3 | PB9 |
| C4 | PB10 |

### Periféricos
| Componente | Pin STM32 |
|---|---|
| Servo SG90 (señal) | PA0 (TIM2 CH1 AF2) |
| ESP32 RX | PA9 (USART1 TX AF4) |
| ESP32 TX | PA10 (USART1 RX AF4) |
| Buzzer | PC3 |
| LED verde | PC4 |
| LED rojo | PC5 |

---

## Arquitectura de Software

```
main.c
├── lcd.c       — Driver LCD HD44780 modo 4 bits (no bloqueante)
├── keypad.c    — Escaneo matricial 4x4 con debounce
├── buzzer.c    — Beeps y tono de alarma (TIM22)
├── servo.c     — PWM 50Hz para SG90 (TIM2 CH1)
├── wifi.c      — Comunicación UART con ESP32 (USART1)
├── led.c       — LEDs indicadores PC4/PC5
└── lock.c      — Lógica principal: PIN, estados, timeouts
```

### Mapa de Interrupciones

| Interrupción | Frecuencia | Función |
|---|---|---|
| SysTick | 1s | Timeouts de cerradura |
| TIM21 | ~6ms | Escaneo keypad |
| TIM22 | 0.5ms | Buzzer + LCD no bloqueante |
| USART1 | Por byte | Recepción comandos ESP32 |

### Máquina de Estados

```
IDLE ──(PIN correcto)──────────> OPEN ──(5s timeout)──> IDLE
     ──(PIN incorrecto, <3)────> IDLE
     ──(PIN incorrecto, ==3)───> BLOCKED ──(30s)──────> IDLE
```

---

## Control WiFi

El ESP32 NodeMCU actúa como servidor web. Al conectarse a la misma red WiFi, se abre la IP en el navegador y aparece una interfaz con botones para abrir y cerrar.

### Protocolo UART (ESP32 → STM32)
```
"OPEN\n"  — abrir cerradura
"CLOSE\n" — cerrar cerradura
```

### Pasos para usar
1. Conectar el celular a la misma red WiFi que el ESP32
2. Ver la IP en el monitor serial (115200 baud)
3. Abrir `http://<IP>` en el navegador
4. Presionar el botón **Abrir** o **Cerrar**

---

## Configuración

### Cambiar el PIN
En `lock.c`, modificar:
```c
static const char LOCK_PIN[LOCK_PIN_LEN] = {'5', '5', '5', '5'};
```

### Ajustar posición del servo
En `servo.h`, modificar los valores de CCR1:
```c
#define SERVO_CLOSE  50u   // 0°  — cerrado
#define SERVO_OPEN   75u   // 90° — abierto
```

---

## Estructura del Repositorio

```
Examen Final/
│
├── README.md                  — Este archivo
│
├── STM32/                     — Proyecto STM32CubeIDE (bare metal)
│   ├── Inc/
│   │   ├── buzzer.h           — Interface del módulo buzzer (PC3)
│   │   ├── keypad.h           — Interface del teclado matricial 4x4
│   │   ├── lcd.h              — Interface del driver LCD HD44780
│   │   ├── led.h              — Interface de LEDs indicadores
│   │   ├── lock.h             — Interface de lógica principal
│   │   ├── servo.h            — Interface del servo SG90
│   │   └── wifi.h             — Interface de comunicación UART
│   ├── Src/
│   │   ├── main.c             — Punto de entrada, timers e interrupciones
│   │   ├── buzzer.c           — Beeps y tono de alarma (TIM22)
│   │   ├── keypad.c           — Escaneo matricial con debounce (TIM21)
│   │   ├── lcd.c              — Driver LCD modo 4 bits no bloqueante
│   │   ├── led.c              — LEDs verde (PC4) y rojo (PC5)
│   │   ├── lock.c             — Máquina de estados de la cerradura
│   │   ├── servo.c            — PWM 50Hz para SG90 (TIM2 CH1)
│   │   ├── wifi.c             — Recepción UART desde ESP32 (USART1)
│   │   ├── syscalls.c         — Syscalls mínimas para newlib
│   │   └── sysmem.c           — Gestión de heap
│   └── Startup/
│       └── startup_stm32l053r8tx.s
│
├── ESP32/                     — Código del módulo WiFi
│   └── cerradura_esp32.cpp    — Servidor web + comunicación UART al STM32
│
└── Demo/                      — Evidencia del funcionamiento
    ├── fotos/                 — Fotografías del circuito armado
    │   ├── logoUNIS.png       — Logo de la Universidad del Istmo
    │   ├── top.HEIC           — Vista general del prototipo
    │   ├── Side1.HEIC         — Vista lateral 1 (LEDs indicadores)
    │   ├── side2.HEIC         — Vista lateral 2 (keypad y buzzer)
    │   ├── front.HEIC         — Vista frontal (servo / mecanismo)
    │   └── side3.HEIC         — Vista lateral 3
    └── videos/                — Video de demostración del proyecto
```

---

## Herramientas

- **STM32CubeIDE** — Programación del STM32 (bare metal, sin HAL)
- **STM32L053R8** — Microcontrolador Cortex-M0+, 16MHz HSI
- **Arduino IDE / PlatformIO** — Programación del ESP32

---

## Autor

**José Alonzo**  
Universidad del Istmo — UNIS/FING  
Ingeniería en Electrónica y Telecomunicaciones · 5to Año  
Examen Final Sistemas Digitales — 2026
