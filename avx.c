#include "stdio.h"

void main() {
    printf("This program will generate an \"Illegal instruction\" and \"trap invalid opcode\" on machines without avx.\n");
    asm ("VZEROALL"); // an AVX instruction, https://en.wikipedia.org/wiki/Advanced_Vector_Extensions
}
