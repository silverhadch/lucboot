[BITS 16] ; Starte in 16 Bit "Real Mode"
[ORG 0x7c00] ; Typische Startadresse für Legacy Bootloaders


; Definiere Segment Offsets für Code und Datenteim
CODE_OFFSET equ 0x8   ; Setze Code Offset zu 0x8
DATA_OFFSET equ 0x10  ; Setze Daten Offset zu 0x10


start:
	cli ; Ignoriere CPU Interrupts
	mov ax, 0x00 ; Initialisiere
	mov ds, ax ; Bewege Datensegment zu 0x00
	mov es, ax ; Bewege Extrasegment zu 0x00
	mov ss, ax ; Bewege Stacksegment zu 0x00
	mov sp, 0x7c00 ; Bewege Stackpointer zu 0x7c00 also die Stackspitze
	sti ; Erlaube CPU Interrupts

load_PM:
	    cli              ; Ignoriere CPU Interrupts bevor wir 32 Bit Mode betreten
	    lgdt [gdt_descriptor] ; Lade den Global Descriptor Table (GDT) durch seinen Beschreiber
	    mov eax, cr0     ; Bewege den Inhalz des Kontroll Register CR0 ins EAX
	    or al, 1         ; Setze das niedrigste Bit von EAX zu 1 um protected 32 Bit Mode zustarten
	    mov cr0, eax     ; Bewege die Modifizierten Wert zurück ins Kontroll Register CR0, startet protected Mode
	    jmp CODE_OFFSET:PModeMain ; Weiter jump um zum neuen Code Segment was im GDT definiert ist zuspringen



; GDT (Global Descriptor Table) 

gdt_start:
	    dd 0x0           ; Null Eintrag
	    dd 0x0           ; -//-

	    ; Code Segment Beschreiber
	    dw 0xFFFF        ; Segment Limit (4 KB)
	    dw 0x0000        ; Base Addresse (niedrige 16 bits)
	    db 0x00          ; Base address (nächsten 8 bits)
	    db 10011010b     ; Zugriff byte: jetztige, ring 0, ausführbar, lessbar
	    db 11001111b     ; Flags: 4 KB, 32-bit Segment
	    db 0x00          ; Base Addresse (hoche 8 bits)

	    ; Daten Segment Beschreiber
	    dw 0xFFFF        ; Segment Limit
	    dw 0x0000        ; Base address (niedrige 16 bits)
	    db 0x00          ; Base address (nächste 8 bits)
	    db 10010010b     ; Zugriff byte: jetzige, ring 0, schreibbar
	    db 11001111b     ; Flags: 4 KB, 32-bit Segment
	    db 0x00          ; Base address (hoche 8 bits)

gdt_end:

gdt_descriptor:
	    dw gdt_end - gdt_start - 1 ; Größe des GDT minus 1 (Größenfeld für LGDT)
	    dd gdt_start      ; Startaddresse des GDT

	[BITS 32]  ; Wechsle zu 32 Bit (protected mode)
PModeMain:
	    mov ax, DATA_OFFSET ; Lade das Daten Segment Offset (0x10) ins AX
	    mov ds, ax          ; Setze DS (Daten Segment) zum neuen Daten Segment Auswähler
	    mov es, ax          ; Setze ES (Extra Segment) zum neuen Daten Segment Auswähler
	    mov fs, ax          ; Setze FS (Zustaz Segment) zum neuen Daten Segment Auswähler
	    mov ss, ax          ; Setze SS (Stack Segment) zum neuen Daten Segment Auswähler
	    mov gs, ax          ; Setze GS (Zustaz Segment) zum neuen Daten Segment Auswähler
	    mov ebp, 0x9C00     ; Setze base Pointer (EBP) zu 0x9C00
	    mov esp, ebp        ; Setze Stack Pointer (ESP) zum selben als EBP, initialisiere den Stack

	    in al, 0x92         ; Lese den Wert vom I/O port 0x92 (System Kontroll port)
	    or al, 2            ; Setze bit 1 des AL um A20 linie (nötig um Ram über 1 MB zuzugreifen) zustarten
	    out 0x92, al        ; Schreibe den veränderten Wert zurück zum I/O port 0x92

	    jmp $               ; Unendlicher Loop (um die CPU in diesem Zustand zufangen)



times 510 - ($ - $$) db 0 ; Fulle den Rest des Bootsektors bis byte 510 alles mit Nullen

dw 0xAA55 ; BIOS Bootsektor Signatur
