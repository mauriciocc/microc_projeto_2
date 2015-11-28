
; PIC16F877A Configuration Bit Settings

; ASM source line config statements

#include "p16F877A.inc"

#define BANCO0 BCF STATUS, RP0
#define BANCO1 BSF STATUS, RP0


; CONFIG
; __config 0xFFBA
 __CONFIG _FOSC_HS & _WDTE_OFF & _PWRTE_OFF & _BOREN_OFF & _LVP_ON & _CPD_OFF & _WRT_OFF & _CP_OFF

    CBLOCK 20h                  ;Cria��o dos registradores (nossos) a partir da posi��o 20h da mem�ria
    contador
    contador2
        contador_segundo
    leitura_analogica
    ENDC


    ORG 0

    BANCO1

    movlw b'11111110' ;  Habilita saida no pino RB0
    movwf TRISB
    
    MOVLW 0
    MOVWF TRISD             ;PORTA D � SA�DA

    MOVLW b'11101100'       ;Quarto bit � configurado como 0 para n�o estragar a porta D (I/O)
    MOVWF TRISE             ;Bits 0 e 1 da porta E s�o sa�das
    
    MOVLW b'00001110'       ;Pinos configurados como digitais
    MOVWF ADCON1

    BANCO0

    ; Configura timer para uso em funcao de 1s de atraso
    movlw b'00110001' ; Timer 1 com clock interno e prescaler 8
    movwf T1CON
    
    CALL    inicia_lcd
    
init
    bcf PORTB, RB0
loop_leitura
	call le_sinal_analogico
	btfss leitura_analogica, 7
    goto init

    bsf PORTB, RB0
    call espera_1s
    bcf PORTB, RB0
    call espera_1s

    MOVLW   'A'
    CALL escreve_dado_lcd
    
    goto loop_leitura
    

        


    GOTO $                       ;Trava programa

le_sinal_analogico
    BANCO1
    MOVLW b'00000000'       ;Pinos configurados como digitais
    MOVWF ADCON1
    BANCO0
    MOVLW b'00001101'       ;Configura adcon0
    movwf ADCON0

aguarda_conversao
        btfsc  ADCON0, 2
    goto aguarda_conversao

    movfw ADRESH
    movwf leitura_analogica
    
    ;Restaura valor (conflito LCD)
    BANCO1
    MOVLW b'00001110'       ;Pinos configurados como digitais
    MOVWF ADCON1
    BANCO0
    MOVLW b'00000000'
    movwf ADCON0
 return
    
espera_1s
    movlw 2
    movwf contador_segundo

    movlw 0Bh   ; Valor para 62500 contagens (500ms)
    movwf TMR1L ; 2^16 - 62500
    movlw 0DCh
    movwf TMR1H

aguarda_estouro
       btfss PIR1, TMR1IF ; Espera timer0 estourar
       goto aguarda_estouro
       movlw 0Bh   ; Valor para 62500 contagens (500ms)
       movwf TMR1L ; 2^16 - 62500
       movlw 0DCh
       movwf TMR1H
       bcf PIR1, TMR1IF ; Limpa flag de estouro
       decfsz contador_segundo ; Aguarda 20 ocorrencias
       goto aguarda_estouro
 return
    
inicia_lcd
    MOVLW   38h
    CALL escreve_comando_lcd

    MOVLW   38h
    CALL escreve_comando_lcd

    MOVLW   38h
    CALL escreve_comando_lcd

    MOVLW   06h
    CALL escreve_comando_lcd

    MOVLW   0Ch
    CALL escreve_comando_lcd

    MOVLW   01h
    CALL escreve_comando_lcd
    CALL atrasa_limpa_lcd

    RETURN

escreve_dado_lcd
    BSF     PORTE, RE0          ;Define dado no LCD (RS=1)
    MOVWF   PORTD
    BSF     PORTE, RE1          ;Ativa ENABLE do LCD
    BCF     PORTE, RE1          ;Destativa ENABLE do LCD
    CALL    atrasa_lcd
    RETURN

escreve_comando_lcd
    BCF     PORTE, RE0          ;Define dado no LCD (RS=0)
    MOVWF   PORTD
    BSF     PORTE, RE1          ;Ativa ENABLE do LCD
    BCF     PORTE, RE1          ;Destativa ENABLE do LCD
    CALL    atrasa_lcd
    RETURN

atrasa_lcd
    MOVLW 26                     ; 8 clocks ( pipe-line nova)
    MOVWF contador               ; 4 clocks
ret_atrasa_lcd
    DECFSZ contador              ; 8 clocks (pipe-line nova)
    GOTO ret_atrasa_lcd          ; 4 clocks
    RETURN


atrasa_limpa_lcd
    MOVLW 40
    MOVWF contador2
ret_atrasa_limpa_lcd
    CALL atrasa_lcd
    DECFSZ contador2
    GOTO ret_atrasa_limpa_lcd
    RETURN
    END