;--------------------------------------------------------------------
; В исходном состоянии – автоматическое прибавление 1 каждые 0,5 сек.
; При нажатии на кнопку (с кликом) показания индикаторов
; умножаются на 2 (без переноса и по модулю 10).
; При отпускании кнопки счет продолжается.
;--------------------------------------------------------------------
#INCLUDE "P16F877A.INC"           ;Подключаем файл с символьными обозначениями
                                  ; специальных регистров и их битов
__CONFIG(0x3972)

#DEFINE SET_BANK0 BCF STATUS,RP0  ; Making page0 active.
#DEFINE SET_BANK1 BSF STATUS,RP0  ; Making page1 active.

REG_1       equ 31h
REG_2       equ 32h
REG_3       equ 33h
YOUNG       equ 34h; Младший индикатор
OLD         equ 35h; Старший индикатор
OLD_PORT    equ 37h
YOUNG_PORT  equ 38h
TMP         equ 3Ch
STATUS      equ 03h
BUFFER_W    equ 26h
BUFFER_S    equ 27h
CHANGER     equ 28h
TMP_LEFT    equ 29h
TMP_RIGHT   equ 2Ah
TMP2        equ 2Bh

org 0               ;Текущий адрес в ПЗУ - 0

BSF  INTCON, GIE ;Флаг разрешения прерываний
BSF  INTCON, T0IE ;Разрешить прерывания от TMR0
GOTO MAIN ;Переход на метку ON

org 4         ;Текущий адрес в ПЗУ = 4

MOVWF BUFFER_W ;Занести значение из АКК
MOVFW STATUS ;Запомнить значение регистра STATUS
MOVWF BUFFER_S ;Занести значение из АКК

BTFSS CHANGER,0 ;пропустить команду если бит = 1
MOVFW OLD_PORT ;Занести значение в АКК
BTFSC CHANGER,0 ;пропустить команду если бит = 0
MOVFW YOUNG_PORT ;Занести значение в АКК
MOVWF PORTC ;Заслать значение из АКК в РЕГ
MOVFW CHANGER ;Запись в АКК
XORLW 0x1 ;Обратить значение флага
MOVWF CHANGER ;Заслать из АКК в РЕГ

BCF   INTCON,2 ;Выдать лог. 0 на INTCON,2
MOVFW BUFFER_S ;Занести значение в АКК
MOVWF STATUS ;Восстановить значение регистра STATUS
MOVFW BUFFER_W  ;Занести значение в АКК

RETFIE ;Возврат из прерывания

MAIN  
    SET_BANK1
    CLRF TRISB
    CLRF TRISC
    BCF OPTION_REG, T0CS ; Внутренний ТГ
    BCF OPTION_REG, PSA ; Вкл. прескалера
    BCF OPTION_REG, PS0 ; параметры делителя прескалера
    BSF OPTION_REG, PS1 ; -//-
    BSF OPTION_REG, PS2 ; -//-
    SET_BANK0

    MOVLW .0
    MOVWF REG_1
    MOVWF REG_2
    MOVWF REG_3
    MOVWF YOUNG
    MOVWF OLD
    BCF PORTB,7


START  
    BSF PORTB, 6 ;лог. 1 на упр. кнопки // удваивает скорость
    BCF PORTB, 3

    MOVF YOUNG,0; Какое значение в севенапе, на ту строчку в tablica и будет совершен переход
    CALL ARRAY_YOUNG; Таблица с цифрами, которые отображает индикатор
    MOVWF YOUNG_PORT; Соответствующую цифру помещаем на порт, подключенный ко входам АBCDEFQ

    MOVF OLD,0;
    CALL ARRAY_OLD
    MOVWF OLD_PORT
    CALL DELAY

    BTFSC PORTB, 6
    BCF PORTB,7

    BTFSC PORTB, 7
    GOTO START

    BTFSS PORTB, 6
    CALL SOUND
    BTFSS PORTB, 6 ; BTFSC
    CALL MUL_AND_MOD_YOUNG ; «да» - вызов процедуры MUL_AND_MOD_YOUNG
    BTFSS PORTB, 6 ;
    CALL MUL_AND_MOD_OLD ; «да» - вызов процедуры MUL_AND_MOD_OLD
    

    INCF YOUNG,1
    BCF STATUS,2
    MOVLW .10
    SUBWF YOUNG,0
    BTFSC STATUS,2
    GOTO ZERO_YOUNG
    GOTO START


MUL_AND_MOD_YOUNG
    BCF STATUS,0
    MOVFW YOUNG
    ADDWF YOUNG,1
    MOVLW .10
    MOVWF TMP2
    MOVFW YOUNG
    SUBWF TMP2,0
    BTFSS STATUS,0
    CALL MODULATE_YOUNG
    RETURN


MODULATE_YOUNG
    MOVLW .10
    SUBWF YOUNG,1
    RETURN

MUL_AND_MOD_OLD
    BCF STATUS,0
    MOVFW OLD
    ADDWF OLD,1
    MOVLW .10
    MOVWF TMP2
    MOVFW OLD
    SUBWF TMP2,0
    BTFSS STATUS,0
    CALL MODULATE_OLD
    BSF PORTB,7
    GOTO START

MODULATE_OLD
    MOVLW .10
    SUBWF OLD,1
    RETURN

SOUND  
    MOVLW       .20 ;
    MOVWF       REG_1
SND:    
    BSF PORTB,3
    CALL DEL
    BCF PORTB,3
    CALL DEL
    BSF PORTB,3
    CALL DEL
    BCF PORTB,3
    CALL DEL
    BSF PORTB,3
    CALL DEL
    BCF PORTB,3
    CALL DEL
    BSF PORTB,3
    CALL DEL
    BCF PORTB,3
    CALL DEL
    DECFSZ REG_1,1
    GOTO SND
    RETURN

DEL:    
    MOVLW .256
    MOVWF TMP
    DECFSZ TMP,1
    GOTO $-1
    RETURN


DELAY
     MOVLW       .89 ; 0,25с задержка
     MOVWF       REG_1
     MOVLW       .88
     MOVWF       REG_2
     MOVLW       .7
     MOVWF       REG_3
     DECFSZ      REG_1,F
     GOTO        $-1
     DECFSZ      REG_2,F
     GOTO        $-3
     DECFSZ      REG_3,F
     GOTO        $-5
     NOP
     NOP
     RETURN

ARRAY_YOUNG
      ADDWF       PCL,1 

      RETLW 0x10 ; 0  
      RETLW 0x5b ; 1
      RETLW 0xc ; 2
      RETLW 0x9 ; 3
      RETLW 0x43 ; 4
      RETLW 0x21 ; 5
      RETLW 0x20 ; 6
      RETLW 0x1b ; 7
      RETLW 0x0 ; 8
      RETLW 0x1 ; 9

ARRAY_OLD     
      ADDWF       PCL,1
      RETLW 0x90 ; 0
      RETLW 0xdb ; 1
      RETLW 0x8c ; 2
      RETLW 0x89 ; 3
      RETLW 0xc3 ; 4
      RETLW 0xa1 ; 5
      RETLW 0xa0 ; 6
      RETLW 0x9b ; 7
      RETLW 0x80 ; 8
      RETLW 0x81 ; 9

ZERO_YOUNG  
      CLRF YOUNG

      INCF OLD,1
      BCF STATUS,2
      MOVLW .10
      SUBWF OLD,0
      BTFSC STATUS,2
      GOTO ZERO_OLD
      GOTO START

ZERO_OLD  
      CLRF OLD
      GOTO START

end
