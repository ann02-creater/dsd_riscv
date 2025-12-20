#include <stdint.h>

#define UART_IO  (*(volatile uint32_t *)0x40000004)
#define LED_IO   (*(volatile uint32_t *)0x40000008)
#define SEG_IO   (*(volatile uint32_t *)0x40000018)

void uwrite(char c) {
    while(UART_IO & 1);
    UART_IO = c << 8;
}

void uprint(char *s) {
    while(*s) uwrite(*s++);
}

char uread() {
    while((UART_IO & 2) == 0);
    return (char)(UART_IO >> 8);
}

int main() {
    int num = 0;
    char c;

    uprint("\r\n");
    uprint("             vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv\r\n");
    uprint("\r\n");
    uprint("                  vvvvvvvvvvvvvvvvvvvvvvvvvvvv\r\n");
    uprint("\r\n");
    uprint("rrrrrrrrrrrrr       vvvvvvvvvvvvvvvvvvvvvvvvvv\r\n");
    uprint("\r\n");
    uprint("rrrrrrrrrrrrrrrr      vvvvvvvvvvvvvvvvvvvvvvvv\r\n");
    uprint("\r\n");
    uprint("rrrrrrrrrrrrrrrrrr    vvvvvvvvvvvvvvvvvvvvvvvv\r\n");
    uprint("\r\n");
    uprint("rrrrrrrrrrrrrrrrrr    vvvvvvvvvvvvvvvvvvvvvvvv\r\n");
    uprint("\r\n");
    uprint("rrrrrrrrrrrrrrrrrr    vvvvvvvvvvvvvvvvvvvvvvvv\r\n");
    uprint("\r\n");
    uprint("rrrrrrrrrrrrrrrr      vvvvvvvvvvvvvvvvvvvvvv\r\n");
    uprint("\r\n");
    uprint("rrrrrrrrrrrrr       vvvvvvvvvvvvvvvvvvvvvv\r\n");
    uprint("\r\n");
    uprint("rr                vvvvvvvvvvvvvvvvvvvvvv\r\n");
    uprint("\r\n");
    uprint("rr            vvvvvvvvvvvvvvvvvvvvvvvv      rr\r\n");
    uprint("\r\n");
    uprint("rrrr      vvvvvvvvvvvvvvvvvvvvvvvvvv      rrrr\r\n");
    uprint("\r\n");
    uprint("rrrrrr      vvvvvvvvvvvvvvvvvvvvvv      rrrrrr\r\n");
    uprint("\r\n");
    uprint("rrrrrrrr      vvvvvvvvvvvvvvvvvv      rrrrrrrr\r\n");
    uprint("\r\n");
    uprint("rrrrrrrrrr      vvvvvvvvvvvvvv      rrrrrrrrrr\r\n");
    uprint("\r\n");
    uprint("rrrrrrrrrrrr      vvvvvvvvvv      rrrrrrrrrrrr\r\n");
    uprint("\r\n");
    uprint("rrrrrrrrrrrrrr      vvvvvv      rrrrrrrrrrrrrr\r\n");
    uprint("\r\n");
    uprint("rrrrrrrrrrrrrrrr      vv      rrrrrrrrrrrrrrrr\r\n");
    uprint("\r\n");
    uprint("rrrrrrrrrrrrrrrrrr          rrrrrrrrrrrrrrrrrr\r\n");
    uprint("\r\n");
    uprint("rrrrrrrrrrrrrrrrrrrr      rrrrrrrrrrrrrrrrrrrr\r\n");
    uprint("\r\n");
    uprint("rrrrrrrrrrrrrrrrrrrrrr  rrrrrrrrrrrrrrrrrrrrrr\r\n");
    uprint("\r\n");
    uprint("\r\n");
    uprint("\r\n");
    uprint("       INSTRUCTION SETS WANT TO BE FREE\r\n");
    uprint("\r\n");
    uprint("\r\n");
    uprint("\r\n");
    uprint("\r\n");
    uprint("\r\n");
    uprint("=== Even/Odd Game Start! ===\r\n");
    uprint("\r\n");
    uprint("Type a number digits (0-9). Press Enter to check.\r\n");

    while(1) {
        c = uread();
        uwrite(c);

        if(c >= '0' && c <= '9') {
            num = num * 10 + (c - '0');
            SEG_IO = num;
        } else if(c == '\n' || c == '\r') {
            uprint("\r\n");
            if(num % 2 == 0) {
                uprint("Even!\r\n");
                LED_IO = 0xFFFF;
            } else {
                uprint("Odd!\r\n");
                LED_IO = 0;
            }
            num = 0;
            SEG_IO = 0;
            uprint("Type a number digits (0-9). Press Enter to check.\r\n");
        }
    }
    return 0;
}
