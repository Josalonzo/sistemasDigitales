# ALU de 4 bits con selección de sumador

**Autor:** José Alonzo
**Carné:** 14958

Implementación en SystemVerilog de una ALU de 4 bits con soporte para 6 operaciones y selección entre 3 arquitecturas de sumador diferentes.

---

## Estructura del proyecto

```
├── Comp_1b.sv          # Comparador de igualdad de 1 bit
├── Comp_2b.sv          # Comparador de igualdad de 2 bits
├── Comp_4b.sv          # Comparador de igualdad de 4 bits
├── Comp_8b.sv          # Comparador de igualdad de 8 bits
├── Mux_2.sv            # Multiplexor 2 a 1 de 4 bits
├── Mux_4.sv            # Multiplexor 4 a 1 de 4 bits
├── Mux_8.sv            # Multiplexor 8 a 1 de 4 bits
├── Fa_1b.sv            # Full adder de 1 bit
├── Adder_2b.sv         # Sumador ripple-carry de 2 bits
├── Adder_4b.sv         # Sumador ripple-carry de 4 bits
├── LookAhead_4b.sv     # Sumador carry lookahead de 4 bits
├── PrefixCell.sv       # Celda base del sumador de prefijo
├── Prefix_4b.sv        # Sumador de prefijo paralelo de 4 bits (Kogge-Stone)
└── Alu.sv              # ALU principal
```

---

## Jerarquía de módulos

```
Alu
├── Adder_4b         (ripple-carry)
│   └── Adder_2b x2
│       └── Fa_1b x2
├── LookAhead_4b     (CLA)
├── Prefix_4b        (Kogge-Stone)
│   └── PrefixCell x4
├── Comp_8b
│   └── Comp_4b x2
│       └── Comp_2b x2
│           └── Comp_1b x2
└── Mux_2 / Mux_4 / Mux_8
```

---

## Interfaz de la ALU

```systemverilog
module Alu (
    input  logic [3:0] in_a, in_b,   // operandos de 4 bits
    input  logic [2:0] ctrl,          // selección de operación
    input  logic [1:0] adder_sel,     // selección de sumador
    output logic [3:0] result,        // resultado
    output logic       carry,         // acarreo de salida
    output logic       overflow,      // desbordamiento con signo
    output logic       negative,      // resultado negativo
    output logic       zero           // resultado igual a cero
);
```

---

## Tabla de operaciones (`ctrl`)

| `ctrl` | Operación | Descripción |
|--------|-----------|-------------|
| `000`  | Suma      | `in_a + in_b` |
| `001`  | Resta     | `in_a - in_b` |
| `010`  | AND       | `in_a & in_b` |
| `011`  | OR        | `in_a \| in_b` |
| `100`  | SLL       | `in_a << 1` |
| `101`  | SRL       | `in_a >> 1` |

---

## Selección de sumador (`adder_sel`)

| `adder_sel` | Sumador | Arquitectura |
|-------------|---------|--------------|
| `00` | `Adder_4b` | Ripple-carry |
| `01` | `LookAhead_4b` | Carry Lookahead (CLA) |
| `10` | `Prefix_4b` | Kogge-Stone |

> `adder_sel` solo tiene efecto cuando `ctrl = 000` (suma) o `ctrl = 001` (resta).

---

## Flags de estado

| Flag | Condición |
|------|-----------|
| `carry` | El resultado excede 4 bits sin signo |
| `overflow` | El resultado excede el rango con signo |
| `negative` | El bit más significativo del resultado es 1 |
| `zero` | El resultado es `0000` |

---

## Casos de prueba

Valores usados: `in_a = 0101` (5), `in_b = 0011` (3)

| Operación | `ctrl` | Resultado | Binario |
|-----------|--------|-----------|---------|
| Suma      | `000`  | 8         | `1000`  |
| Resta     | `001`  | 2         | `0010`  |
| AND       | `010`  | 1         | `0001`  |
| OR        | `011`  | 7         | `0111`  |
| SLL       | `100`  | 10        | `1010`  |
| SRL       | `101`  | 2         | `0010`  |

Verificación de sumadores con suma (5 + 3 = 8):

| `adder_sel` | Sumador | Resultado |
|-------------|---------|-----------|
| `00` | Ripple-carry | `1000` (8) |
| `01` | CLA | `1000` (8) |
| `10` | Kogge-Stone | `1000` (8) |

---

## Herramientas

- **Lenguaje:** SystemVerilog
- **Simulación:** Vivado
