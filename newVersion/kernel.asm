.globl _kstart
_kstart:
    bl print_welcome_message
    bl dumpana
1:  b 1b  # Bucle infinito

print_welcome_message:
    lis   %r3, welcome_message@h
    ori   %r3, %r3, welcome_message@l
    bl    print_string
    blr

dumpana:
    li    %r29, 0
    lis   %r30, 0xEA00
    ori   %r30, %r30, 0x1000

1:  
    lwzx  %r31, %r30, %r29
    bl    print_hex_value
    addi  %r29, %r29, 4
    cmpwi %r29, 0x100
    blt   1b
    blr

print_string:
    lis   %r4, 0xC000
    ori   %r4, %r4, 0x0000  # Dirección base del framebuffer
1:
    lbz   %r5, 0(%r3)       # Cargar carácter de la cadena
    cmpwi %r5, 0            # Verificar si es el final de la cadena
    beq   2f
    stb   %r5, 0(%r4)       # Escribir en framebuffer
    addi  %r3, %r3, 1       # Avanzar en la cadena
    addi  %r4, %r4, 1       # Avanzar en framebuffer
    b     1b
2:  
    blr

print_hex_value:
    lis   %r4, 0xC000
    ori   %r4, %r4, 0x0000  # Dirección base del framebuffer
    stb   %r31, 0(%r4)      # Escribir valor en framebuffer
    blr

welcome_message:
    .asciz "Bienvenido a DumpANA para Xbox360\n"
