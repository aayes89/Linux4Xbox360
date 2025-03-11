.globl _start
// .globl dumpana
// .globl print_string
_start:
    b   start_from_rom
    b   start_from_libxenon
    b   .  // Reservado para uso futuro
    b   .
    b   .
    b   .
    b   .
    b   .

.globl start_from_rom
start_from_rom:
    bl  init_regs

    // Deshabilitar interrupciones
    lis %r13, 0x200
    mtmsrd %r13, 1

    // Configurar registros de control
    li  %r3, 2
    mtspr lpcr, %r3
    li  %r3, 0x3FF
    rldicr %r3, %r3, 32, 31
    tlbiel %r3, 1
    sync

    // Habilitar caché y prefetch
    mfspr %r10, hid1
    li  %r11, 3
    rldimi %r10, %r11, 58, 4  // Habilitar caché de instrucciones
    rldimi %r10, %r11, 38, 25 // Prefetch de instrucciones
    mtspr hid1, %r10
    sync

    // Configurar la pila
    lis %sp, 0x8000
    rldicr %sp, %sp, 32, 31
    oris %sp, %sp, 0x1e00

    mfspr %r3, pir
    slwi %r4, %r3, 16  // 64k de pila por hilo
    sub %sp, %sp, %r4
    subi %sp, %sp, 0x80

    cmpwi %r3, 0
    bne other_threads_waiter

    // Mostrar mensaje en pantalla
    bl  print_welcome_message

    // Llamar a la función dumpana
    bl  dumpana

    // Bucle infinito
1:  b 1b

print_welcome_message:
    // Cargar la dirección del mensaje en %r3
    lis %r3, welcome_message@h
    ori %r3, %r3, welcome_message@l

    // Llamar a la función print_string
    bl  print_string

    // Cargar la dirección del mensaje "Hecho por Slam 2025"
    lis %r3, author_message@h
    ori %r3, %r3, author_message@l

    // Llamar a la función print_string
    bl  print_string

    blr

// Función para mostrar una cadena en pantalla

print_string:
    // Guardar registros no volátiles
    stwu %r1, -32(%r1)  // Reservar espacio en la pila
    mflr %r0            // Guardar el registro de enlace (LR)
    stw %r0, 36(%r1)    // Guardar LR en la pila
    stw %r31, 28(%r1)   // Guardar %r31 en la pila
    stw %r30, 24(%r1)   // Guardar %r30 en la pila

    // Inicializar variables
    lis %r30, 0xC000    // %r30 = Dirección base del framebuffer (ajusta según tu sistema)
    ori %r30, %r30, 0x0000
    lis %r31, 0x0000    // %r31 = Posición actual en el framebuffer (x, y)
    ori %r31, %r31, 0x0000

print_string_loop:
    // Cargar el siguiente carácter de la cadena
    lbz %r4, 0(%r3)     // %r4 = *%r3 (cargar un byte de la cadena)
    cmpwi %r4, 0        // Verificar si es el final de la cadena (carácter nulo)
    beq print_string_end

    // Escribir el carácter en el framebuffer
    stb %r4, 0(%r30)    // Escribir el carácter en el framebuffer
    addi %r30, %r30, 1  // Mover al siguiente byte en el framebuffer
    addi %r3, %r3, 1    // Mover al siguiente carácter en la cadena

    // Verificar si es el final de la línea (ajusta según el ancho del framebuffer)
    andi. %r0, %r30, 0x7F  // Supongamos que el ancho del framebuffer es 128 bytes
    bne print_string_loop

    // Mover a la siguiente línea
    addi %r31, %r31, 1  // Incrementar la posición Y
    lis %r30, 0xC000    // Reiniciar la posición X
    ori %r30, %r30, 0x0000
    b print_string_loop

print_string_end:
    // Restaurar registros no volátiles
    lwz %r31, 28(%r1)   // Restaurar %r31
    lwz %r30, 24(%r1)   // Restaurar %r30
    lwz %r0, 36(%r1)    // Restaurar LR
    mtlr %r0            // Restaurar el registro de enlace
    addi %r1, %r1, 32   // Liberar espacio en la pila
    blr                 // Retornar

// Función dumpana (implementación en ensamblador o llamada a C)

dumpana:
    // Guardar registros no volátiles
    stwu %r1, -32(%r1)  // Reservar espacio en la pila
    mflr %r0            // Guardar el registro de enlace (LR)
    stw %r0, 36(%r1)    // Guardar LR en la pila
    stw %r31, 28(%r1)   // Guardar %r31 en la pila
    stw %r30, 24(%r1)   // Guardar %r30 en la pila
    stw %r29, 20(%r1)   // Guardar %r29 en la pila

    // Inicializar variables
    li %r29, 0          // %r29 = i = 0
    lis %r30, 0xEA00     // %r30 = Dirección base del chip ANA (0xEA001000)
    ori %r30, %r30, 0x1000

dumpana_loop:
    // Leer el valor del chip ANA en la posición i
    lwzx %r31, %r30, %r29  // %r31 = *(0xEA001000 + i)

    // Imprimir el valor en formato hexadecimal
    bl print_hex_value

    // Imprimir un espacio después del valor
    lis %r3, space@h
    ori %r3, %r3, space@l
    bl print_string

    // Verificar si es el final de la línea (cada 8 valores)
    addi %r29, %r29, 4   // i += 4 (cada valor es de 32 bits)
    andi. %r0, %r29, 0x1F // Verificar si i % 32 == 0 (8 valores de 4 bytes)
    bne dumpana_loop

    // Imprimir un salto de línea
    lis %r3, newline@h
    ori %r3, %r3, newline@l
    bl print_string

    // Continuar el bucle hasta que se lean 0x100 bytes
    cmpwi %r29, 0x100
    blt dumpana_loop

    // Restaurar registros no volátiles
    lwz %r29, 20(%r1)   // Restaurar %r29
    lwz %r30, 24(%r1)   // Restaurar %r30
    lwz %r31, 28(%r1)   // Restaurar %r31
    lwz %r0, 36(%r1)    // Restaurar LR
    mtlr %r0            // Restaurar el registro de enlace
    addi %r1, %r1, 32   // Liberar espacio en la pila
    blr                 // Retornar

// Función para imprimir un valor hexadecimal
print_hex_value:
    // %r31 contiene el valor a imprimir
    stwu %r1, -16(%r1)  // Reservar espacio en la pila
    mflr %r0            // Guardar el registro de enlace (LR)
    stw %r0, 20(%r1)    // Guardar LR en la pila

    // Convertir el valor en %r31 a una cadena hexadecimal
    lis %r3, hex_buffer@h
    ori %r3, %r3, hex_buffer@l
    mr %r4, %r31
    bl uint32_to_hex

    // Imprimir la cadena hexadecimal
    lis %r3, hex_buffer@h
    ori %r3, %r3, hex_buffer@l
    bl print_string

    // Restaurar registros
    lwz %r0, 20(%r1)    // Restaurar LR
    mtlr %r0            // Restaurar el registro de enlace
    addi %r1, %r1, 16   // Liberar espacio en la pila
    blr                 // Retornar

// Función para convertir un valor de 32 bits a una cadena hexadecimal
uint32_to_hex:
    // %r3 = dirección del buffer
    // %r4 = valor a convertir
    li %r5, 8           // 8 caracteres hexadecimales
    mtctr %r5           // Configurar el contador de bucle
    addi %r3, %r3, 7    // Empezar desde el final del buffer

uint32_to_hex_loop:
    rlwinm %r6, %r4, 28, 0xF  // Extraer el nibble superior
    cmpwi %r6, 9
    ble uint32_to_hex_digit
    addi %r6, %r6, 7    // Convertir a letra (A-F)
uint32_to_hex_digit:
    addi %r6, %r6, '0'  // Convertir a ASCII
    stb %r6, 0(%r3)     // Almacenar el carácter en el buffer
    subi %r3, %r3, 1    // Mover el puntero del buffer
    rlwinm %r4, %r4, 4, 0, 31 // Desplazar el valor 4 bits a la izquierda
    bdnz uint32_to_hex_loop  // Repetir el bucle

    blr                 // Retornar

// Datos
welcome_message:
    .asciz "Welcome to Xbox360 DumpANA\n"
author_message:
    .asciz "Made by Slam 2025\n"
hex_buffer:
    .space 9            // Buffer para almacenar la cadena hexadecimal
space:
    .asciz " "          // Espacio en blanco
newline:
    .asciz "\n"         // Salto de línea
