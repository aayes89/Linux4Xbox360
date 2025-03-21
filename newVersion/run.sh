#!/bin/sh
# Assembly boot.asm
powerpc-linux-gnu-as -mppc64 boot.asm -o boot.o
# Assembly kernel.asm
powerpc-linux-gnu-as -mppc64 kernel.asm -o kernel.o
# Linking all into kernel.elf
powerpc-linux-gnu-ld -Ttext 0x80000000 boot.o kernel.o -o kernel.elf
