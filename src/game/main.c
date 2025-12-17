#include <stdint.h>

// darkriscv standard IO addresses
// UART: 0x40000004
// LED:  0x40000008
// OPORT: 0x40000018 (Offset 0x18 = 24 decimal, check darkio.v "5'b110xx" -> 24 is 11000)
#define UART_REG    (*(volatile uint32_t *)0x40000004)
#define LED_REG     (*(volatile uint32_t *)0x40000008)
#define OPORT_REG   (*(volatile uint32_t *)0x40000018)

void putc(char c) {
    // Bit 0 is TX Busy (1 = busy)
    // Wait until TX is idle
    while (UART_REG & 1);
    
    // Write data to bits [15:8]
    UART_REG = c << 8;
}

void print(const char *str) {
    while (*str) putc(*str++);
}

char getc() {
    uint32_t data;
    // Bit 1 is RX Valid/Ready.
    while ((UART_REG & 2) == 0);
    
    data = UART_REG;
    // Data is in bits [15:8]
    return (char)((data >> 8) & 0xFF);
}

int main() {
    char c;
    int num_acc = 0; // Accumulate digits for multi-digit numbers

    print("\n\r=== Even/Odd Game Start! ===\r\n");
    print("Type a number digits (0-9). Press Enter to check.\r\n");

    while (1) {
        c = getc(); // Wait for input
        putc(c);    // Echo back

        if (c >= '0' && c <= '9') {
            num_acc = (num_acc * 10) + (c - '0');
            OPORT_REG = num_acc; // Display accumulated number on 7-Seg immediately
        } else if (c == '\n' || c == '\r') {
            print("\r\nChecking: ");
            // Print accumulated number (simple decimal print logic needed, or just status)
            // Simplified: just check even/odd of accumulator
            if (num_acc % 2 == 0) {
                print("Even!\r\n");
                LED_REG = 0xFFFF; // Even: LED ON
            } else {
                print("Odd!\r\n");
                LED_REG = 0x0000; // Odd: LED OFF
            }
            num_acc = 0; // Reset
            OPORT_REG = 0; // Clear display
            print("Type a number digits (0-9). Press Enter to check.\r\n");
        } else {
            // Reset on invalid input or just ignore?
            // Let's just ignore non-digits
        }
    }
    return 0;
}
