[BITS 32]        ; Wir befinden uns im 32-Bit Protected Mode

	global _start    ; Definiert das globale Label _start, sodass der Linker es finden kann
	extern kernel_main  ; Deklariert eine externe Funktion kernel_main, die in C definiert ist

_start:
	    call kernel_main  ; Ruft die Hauptfunktion des Kernels auf
	    jmp $             ; Endlosschleife, um das System anzuhalten, falls kernel_main zurückkehrt

	times 512-($ - $$) db 0  ; Füllt die restlichen Bytes auf 512 mit Nullen, falls nötig
