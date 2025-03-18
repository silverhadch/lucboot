TS 16]        ; Starte in 16 Bit "Real Mode"
	[ORG 0x7c00]     ; Typische Startadresse für Legacy Bootloaders


	CODE_OFFSET equ 0x8   ; Setze Code Offset zu 0x8
	DATA_OFFSET equ 0x10  ; Setze Daten Offset zu 0x10

	KERNEL_LOAD_SEG equ 0x1000    ; Segment, in das der Kernel geladen wird
	KERNEL_START_ADDR equ 0x100000; Startadresse des Kernels im Speicher


start:
	    cli           ; Ignoriere CPU Interrupts
	    mov ax, 0x00  ; Initialisiere
	    mov ds, ax    ; Bewege Datensegment zu 0x00
	    mov es, ax    ; Bewege Extrasegment zu 0x00
	    mov ss, ax    ; Bewege Stacksegment zu 0x00
	    mov sp, 0x7c00; Bewege Stackpointer zu 0x7c00, also die Stackspitze
	    sti           ; Erlaube CPU Interrupts
	    

	; Lade den Kernel von der Festplatte ins RAM
	mov bx, KERNEL_LOAD_SEG ; Setze das Segment, in das der Kernel geladen wird
	mov dh, 0x00            ; Setze den Kopf auf 0
	mov dl, 0x80            ; Wähle die erste Festplatte (BIOS-Standard)
	mov cl, 0x02            ; Lese ab dem zweiten Sektor
	mov ch, 0x00            ; Zylinder 0
	mov ah, 0x02            ; BIOS-Funktion: Lese Sektoren von der Festplatte
	mov al, 8              ; Lese 8 Sektoren
	int 0x13               ; BIOS-Interrupt für Festplattenoperationen

	jc disk_read_error      ; Falls ein Fehler auftritt, springe zur Fehlerbehandlung


load_PM:
	    cli                 ; Ignoriere CPU Interrupts bevor wir 32-Bit Mode betreten
	    lgdt[gdt_descriptor]; Lade den Global Descriptor Table (GDT) durch seinen Beschreiber
	    mov eax, cr0        ; Bewege den Inhalt des Kontrollregisters CR0 ins EAX
	    or al, 1            ; Setze das niedrigste Bit von EAX auf 1, um den protected 32-Bit Mode zu starten
	    mov cr0, eax        ; Bewege den modifizierten Wert zurück ins Kontrollregister CR0, startet protected Mode
	    jmp CODE_OFFSET:PModeMain ; Weiterer Sprung, um zum neuen Code-Segment zu wechseln



disk_read_error:
	    hlt ; Halte die CPU an, falls ein Fehler beim Laden des Kernels auftritt


	; GDT (Global Descriptor Table) 

gdt_start:
	    dd 0x0           ; Null Eintrag
	    dd 0x0           ; -//-

	    ; Code Segment Beschreiber
	    dw 0xFFFF        ; Segment Limit (4 KB)
	    dw 0x0000        ; Base Adresse (niedrige 16 Bits)
	    db 0x00          ; Base Adresse (nächste 8 Bits)
	    db 10011010b     ; Zugriff-Byte: jetztige, Ring 0, ausführbar, lesbar
	    db 11001111b     ; Flags: 4 KB, 32-bit Segment
	    db 0x00          ; Base Adresse (hohe 8 Bits)

	    ; Daten Segment Beschreiber
	    dw 0xFFFF        ; Segment Limit
	    dw 0x0000        ; Base Adresse (niedrige 16 Bits)
	    db 0x00          ; Base Adresse (nächste 8 Bits)
	    db 10010010b     ; Zugriff-Byte: jetztige, Ring 0, schreibbar
	    db 11001111b     ; Flags: 4 KB, 32-bit Segment
	    db 0x00          ; Base Adresse (hohe 8 Bits)

gdt_end:

gdt_descriptor:
	    dw gdt_end - gdt_start - 1 ; Größe des GDT minus 1 (Größenfeld für LGDT)
	    dd gdt_start      ; Startadresse des GDT


	[BITS 32]  ; Wechsel zu 32-Bit (protected mode)
PModeMain:
	    mov ax, DATA_OFFSET ; Lade das Daten Segment Offset (0x10) ins AX
	    mov ds, ax          ; Setze DS (Daten Segment) zum neuen Daten Segment Auswähler
	    mov es, ax          ; Setze ES (Extra Segment) zum neuen Daten Segment Auswähler
	    mov fs, ax          ; Setze FS (Zusatz Segment) zum neuen Daten Segment Auswähler
	    mov ss, ax          ; Setze SS (Stack Segment) zum neuen Daten Segment Auswähler
	    mov gs, ax          ; Setze GS (Zusatz Segment) zum neuen Daten Segment Auswähler
	    mov ebp, 0x9C00     ; Setze Base Pointer (EBP) auf 0x9C00
	    mov esp, ebp        ; Setze Stack Pointer (ESP) auf den gleichen Wert wie EBP, initialisiere den Stack

	    in al, 0x92         ; Lese den Wert vom I/O-Port 0x92 (System-Kontrollport)
	    or al, 2            ; Setze Bit 1 von AL, um die A20-Linie zu aktivieren (nötig, um RAM über 1 MB zuzugreifen)
	    out 0x92, al        ; Schreibe den veränderten Wert zurück zum I/O-Port 0x92

	    jmp CODE_OFFSET:KERNEL_START_ADDR ; Springe zum Kernel-Startpunkt



	times 510 - ($ - $$) db 0   ; Fülle den Rest des Bootsektors bis Byte 510 mit Nullen

	dw 0xAA55   ; BIOS Bootsektor Signatur (Kennung für bootfähige Sektoren)
