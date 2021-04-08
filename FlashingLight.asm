#INCLUDE <P16F877.INC>

COUNT1 	equ 20h             ; Задаем символьное обозначение ячеек памяти, 
COUNT2 	equ 21h             ; расположенных по адресам 20h, 21h, 22h
COUNT3 	equ 22h

ORG 0

START: 	BSF STATUS,RP0  	; Делаем активной страницу 1
        CLRF TRISD     		; Устанавливаем все выводы порта D на вывод
        BCF STATUS,RP0  	; Возвращаемся на страницу 0
        CLRF PORTD       	; Устанавливаем все выводы порта D на вывод

LOOP: 	
CLEAR_D:
        CLRW
        XORWF PORTD,W
        BTFSS STATUS,Z
        GOTO CLEAR_D
        BCF STATUS,Z
        BSF PORTD,0

        CALL DELAY
        CLRF PORTD

        CALL DELAY
        GOTO LOOP           ; Endless loop.

; Beginning of the DELAY-program.
DELAY: 	MOVLW 1A
        MOVWF COUNT1
LOOPZ1:	CALL DELAY2
        DECFSZ COUNT1,F
        GOTO LOOPZ1
        RETURN

DELAY2: MOVLW 0FF
        MOVWF COUNT2
LOOPZ2: CALL DELAY3
        DECFSZ COUNT2,F
        GOTO LOOPZ2
        RETURN

DELAY3:	MOVLW 0FF
        MOVWF COUNT3
LOOPZ3: DECFSZ COUNT3,F
        GOTO LOOPZ3
        RETURN
; Ending of the DELAY-program.

END
