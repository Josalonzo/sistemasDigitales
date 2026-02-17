
#include <stdint.h>

/* BASE ADDRESSES */
#define PERIPH_BASE           (0x40000000u)
#define AHB_BASE              (PERIPH_BASE + 0x20000u)
#define IOPORT_BASE           (PERIPH_BASE + 0x10000000u)
#define RCC_BASE              (AHB_BASE + 0x1000u)
#define GPIOA_BASE            (IOPORT_BASE + 0x0000u)

/* REGISTROS */
typedef struct {
    volatile uint32_t MODER;
    volatile uint32_t OTYPER;
    volatile uint32_t OSPEEDR;
    volatile uint32_t PUPDR;
    volatile uint32_t IDR;
    volatile uint32_t ODR;
    volatile uint32_t BSRR;
    volatile uint32_t LCKR;
    volatile uint32_t AFR[2];
    volatile uint32_t BRR;
} GPIO_TypeDef;

typedef struct {
    volatile uint32_t CR, ICSCR, CRRCR, CFGR, CIER, CIFR, CICR, IOPRSTR,
                      AHBRSTR, APB2RSTR, APB1RSTR, IOPENR, AHBENR, APB2ENR,
                      APB1ENR, IOPSMENR, AHBSMENR, APB2SMENR, APB1SMENR,
                      CCIPR, CSR;
} RCC_TypeDef;

#define GPIOA ((GPIO_TypeDef *) GPIOA_BASE)
#define RCC   ((RCC_TypeDef  *) RCC_BASE)

/* DELAY SIMPLE */
static void delay_ticks(int32_t ticks)
{
    for (int32_t t = 0; t < ticks; t++) {
        for (int32_t i = 0; i < 15; i++) {
            __asm__ __volatile__("nop");
        }
    }
}

/* CATODO COMUN*/
#define INVERT_SEGMENTS 0
#define INVERT_DIGITS   1

static const uint8_t SEG_FONT[10] = {
    0b00111111, // 0
    0b00000110, // 1
    0b01011011, // 2
    0b01001111, // 3
    0b01100110, // 4
    0b01101101, // 5
    0b01111101, // 6
    0b00000111, // 7
    0b01111111, // 8
    0b01101111  // 9
};

/* MÁSCARAS DE PINES */
#define SEG_PINS_MASK   ( (1u<<0) | (1u<<1) | (1u<<4) | (1u<<5) | (1u<<6) | (1u<<11) | (1u<<12) )
#define DIG_PINS_MASK   ( (1u<<7) | (1u<<8) | (1u<<9) | (1u<<10) )

static uint16_t seg_mask_from_digit(uint8_t digit)
{
    if (digit > 9) digit = 0;

    uint8_t pattern = SEG_FONT[digit];

#if INVERT_SEGMENTS
    pattern = (~pattern) & 0x7F;
#endif

    uint16_t mask = 0;
    if (pattern & (1u << 0)) mask |= (1u << 0);   // a -> PA0
    if (pattern & (1u << 1)) mask |= (1u << 1);   // b -> PA1
    if (pattern & (1u << 2)) mask |= (1u << 11);  // c -> PA11
    if (pattern & (1u << 3)) mask |= (1u << 12);  // d -> PA12
    if (pattern & (1u << 4)) mask |= (1u << 4);   // e -> PA4
    if (pattern & (1u << 5)) mask |= (1u << 5);   // f -> PA5
    if (pattern & (1u << 6)) mask |= (1u << 6);   // g -> PA6
    return mask;
}

static inline void display_clear_all(void)
{
    /* Apagar segmentos */
#if INVERT_SEGMENTS
    GPIOA->BSRR = SEG_PINS_MASK;
#else
    GPIOA->BSRR = (SEG_PINS_MASK << 16);
#endif

    /* Apagar dígitos */
#if INVERT_DIGITS
    GPIOA->BSRR = DIG_PINS_MASK;
#else
    GPIOA->BSRR = (DIG_PINS_MASK << 16);
#endif
}

/* HABILITAR UN DÍGITO */
static inline void enable_digit(uint8_t digit_index)
{
    uint32_t pin = 7u + (digit_index & 0x03u);

#if INVERT_DIGITS
    GPIOA->BSRR = (1u << (pin + 16u));
#else
    GPIOA->BSRR = (1u << pin);
#endif
}

/* PONER SEGMENTOS */
static inline void set_segments(uint16_t segmask)
{
#if INVERT_SEGMENTS
    GPIOA->BSRR = SEG_PINS_MASK;
    GPIOA->BSRR = ((uint32_t)segmask << 16);
#else
    GPIOA->BSRR = segmask;
#endif
}

/* INIT GPIOA */
static void display_init(void)
{
    RCC->IOPENR |= 0b001;


    GPIOA->MODER &= ~(0b1111u << 0);
    GPIOA->MODER |=  (0b0101u << 0);


    GPIOA->MODER &= ~(0b111111u << 8);
    GPIOA->MODER |=  (0b010101u << 8);


    GPIOA->MODER &= ~(0b11111111u << 14);
    GPIOA->MODER |=  (0b01010101u << 14);


    GPIOA->MODER &= ~(0b1111u << 22);
    GPIOA->MODER |=  (0b0101u << 22);

    display_clear_all();
}

static void display_refresh_4digits(const uint8_t digits[4])
{
    static uint8_t fsm = 0;

    display_clear_all();

    uint16_t segmask = seg_mask_from_digit(digits[fsm]);
    set_segments(segmask);
    enable_digit(fsm);

    fsm = (fsm + 1u) & 0x03u;
}

int main(void)
{
    display_init();


    uint8_t digits[4] = {2, 0, 0, 5};

    while (1)
    {
        display_refresh_4digits(digits);


        delay_ticks(2);
    }
}
