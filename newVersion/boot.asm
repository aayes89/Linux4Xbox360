
.globl _start
_start:
    b start_from_rom

.globl start_from_rom
start_from_rom:
    bl init_regs
    
    # Deshabilitar interrupciones
    lis %r13, 0x200
    ori %r13, %r13, 0
    mtmsrd %r13, 1
    
    # Configurar LPCR y limpiar TLB
    li %r3, 2
    mtspr 319, %r3  # LPCR
    li %r3, 0x3FF
    rldicr %r3, %r3, 32, 31
    tlbie %r3  # Sustituye tlbiel por tlbie
    sync

    # Habilitar caché y prefetch
    mfspr %r10, 1009  # HID1
    li %r11, 3
    rldimi %r10, %r11, 58, 4  # Habilitar I-Cache
    rldimi %r10, %r11, 38, 25  # Habilitar prefetch
    mtspr 1009, %r10  # HID1
    sync

    # Configurar la pila
    lis %sp, 0x81E0

    # Verificar si es el CPU principal
    mfspr %r3, 1023  # PIR
    cmpwi %r3, 0
    bne other_threads_waiter

    # Cargar y saltar al kernel
    lis %r3, 0x8000
    ori %r3, %r3, _kstart@l
    ld %r2, 8(%r3)
    mtctr %r2
    bctr

other_threads_waiter:
    b .

init_regs:
    li %r3, 0
    mtspr 1008, %r3  # HID0
    sync
    blr
