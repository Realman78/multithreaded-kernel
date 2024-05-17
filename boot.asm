ORG 0
BITS 16
_start:
    jmp short start
    nop

times 33 db 0

; ovo gore je potrebno jer BIOS ocekuje da ce prvih 33 bajta biti BPB
; https://wiki.osdev.org/FAT#BPB_.28BIOS_Parameter_Block.29

start:
    jmp 0x7C0:step2

handle_zero:
    mov ah, 0eh
    mov al, 'A'
    mov bx, 0x00 
    int 0x10
    iret

step2:
    cli ; ocisti interrupte
    mov ax, 0x7C0
    mov ds, ax
    mov es, ax
    mov ax, 0x00
    mov ss, ax
    mov sp, 0x7C00
    sti ; omoguci interrupte

    mov word[ss:0x00], handle_zero
    mov word[ss:0x02], 0x7C0

    int 0

    mov si, message
    call print

    jmp $

print:
    mov bx, 0
.loop:
    lodsb
    cmp al, 0
    je .done
    call print_char
    jmp .loop
.done:
    ret

print_char:
    mov ah, 0eh
    int 0x10
    ret

message: db 'Marin Parin', 0

times 510-($ - $$) db 0
dw 0xAA55
; ovo dolje se nece izvrsit jer BIOS ucitava samo prvih 512 bajtova
mov ah, 0eh
mov al, 'B'
int 0x10