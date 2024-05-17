ORG 0x7C00
BITS 16

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

_start:
    jmp short start
    nop

times 33 db 0

; ovo gore je potrebno jer BIOS ocekuje da ce prvih 33 bajta biti BPB
; https://wiki.osdev.org/FAT#BPB_.28BIOS_Parameter_Block.29

start:
    jmp 0:step2

step2:
    cli ; ocisti interrupte
    mov ax, 0x00
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti ; omoguci interrupte

.load_protected:
    cli
    lgdt[gdt_descriptor]
    mov eax, cr0
    or eax, 0x1
    mov cr0, eax
    jmp CODE_SEG:load32

; GDT
gdt_start:
gdt_null:
    dd 0x0
    dd 0x0

;offset 0x8
gdt_code:       ; CS bi trbal pointat na ovo
    dw 0xffff   ; segment limit prvih 16 bita
    dw 0        ; base first 0-15 bits
    db 0        ; base 16-23 bits
    db 0x9a     ; access byte
    db 11001111b; high 4 bit flags i low 4 bit flags
    db 0        ; base 24-31 bits

; offset 0x10
gdt_data:       ; DS, SS, ES, FS, GS
    dw 0xffff   ; segment limit prvih 16 bita
    dw 0        ; base first 0-15 bits
    db 0        ; base 16-23 bits
    db 0x92     ; access byte
    db 11001111b; high 4 bit flags i low 4 bit flags
    db 0        ; base 24-31 bits

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start -1
    dd gdt_start

[BITS 32]
load32:
    mov eax, 1 ; pocetni sektor od koga zelimo ucitat - on je 1 jer je 0 boot sektor
    mov ecx, 100 ; koliko sektora zelimo ucitat
    mov edi, 0x0100000 ; RAM adresa u koju zelimo ucitat sektore
    call ata_lba_read
    jmp CODE_SEG:0x0100000

ata_lba_read:
    mov ebx, eax ; backup LBA - to je zapravo sektor od kog citamo
    ; posalji najvisih 8 bitova od LBA na Hard disk kontroler
    shr eax, 24 
    or eax, 0xE0
    mov dx, 0x1F6
    out dx, al ; out instrukcija je pricanje sa busom na maticnoj ploci
    ; poslano najvisih 8 bita od LBA

    ; posalji sveukupne sektore za procitat
    mov eax, ecx
    mov dx, 0x1F2
    out dx, al
    ; finished

    ; posalji jos bitova od LBA
    mov eax, ebx ; restore the backup LBA
    mov dx, 0x1F3
    out dx, al
    ; finished sending more bit of the LBA

    ; posalji jos bitova od LBA
    mov dx, 0x1F4
    mov eax, ebx
    shr eax, 8
    out dx, al
    ; finished sending more bit of the LBA

    ;send upper 16 bits of the LBA
    mov dx, 0x1F5
    mov eax, ebx
    shr eax, 16
    out dx, al
    ; finish

    mov dx, 0x1F7
    mov al, 0x20
    out dx, al

    ; read all sectors into memory
.next_sector:
    push ecx

; check if we need to read
.try_again:
    mov dx, 0x1F7
    in al, dx
    test al, 8
    jz .try_again

    ; we need to read 256 words at a time
    mov ecx, 256
    mov dx, 0x1F0
    rep insw
    pop ecx
    loop .next_sector
    ; end of reading sectors into memory
    ret


times 510-($ - $$) db 0
dw 0xAA55