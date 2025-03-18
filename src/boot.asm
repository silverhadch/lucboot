[BITS 16] ; Starte in 16 Bit "Real Mode"
[ORG 0x7c00] ; Typische Startadresse für Legacy Bootloaders

start:
	cli ; Ignoriere CPU Interrupts
	mov ax, 0x00 ; Initialisiere
	mov ds, ax ; Bewege Datensegment zu 0x00
	mov es, ax ; Bewege Extrasegment zu 0x00
	mov ss, ax ; Bewege Stacksegment zu 0x00
	mov sp, 0x7c00 ; Bewege Stackpointer zu 0x7c00 also die Stackspitze
	mov si, msg ; Lade die Nachricht ins Quellen Index Register
	sti ; Erlaube CPU Interrupts

print:
	lodsb ; Lade Byte von DS mit Offest SI ins AL Register und erhöhe SI
	cmp al, 0 ; Vergleiche den Wert in AL mit Null-Stelle
	je done ; Springe zur done wenn wir Null erreichen also Ende der Nachricht
	mov ah, 0x0E ; Bewege AH Register zu BIOS Output
	int 0x10 ; Rufe BIOS Interrupt um Output zustarten
	jmp print ; Loope bis fertig


done:
	cli ; Ignoriere CPU Interrupts
	hlt ; Halte CPU an




msg: db 'Hello World!', 0 ; Nachricht mit Null-Stelle um es zubeenden

times 510 - ($ - $$) db 0 ; Fulle den Rest des Bootsektors bis byte 510 alles mit Nullen

dw 0xAA55 ; BIOS Bootsektor Signatur
