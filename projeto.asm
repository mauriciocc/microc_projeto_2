
; PIC16F877A Configuration Bit Settings

; ASM source line config statements

#include "p16F877A.inc"

#define BANCO0 BCF STATUS, RP0
#define BANCO1 BSF STATUS, RP0


; CONFIG
; __config 0xFFBA
 __CONFIG _FOSC_HS & _WDTE_OFF & _PWRTE_OFF & _BOREN_OFF & _LVP_ON & _CPD_OFF & _WRT_OFF & _CP_OFF

    CBLOCK 20h                  ;Criação dos registradores (nossos) a partir da posição 20h da memória
    contador
    contador2
    contador_segundo
    leitura_analogica    
    VALOR_DEBITO
    ENDC


    ORG 0

    BANCO1

    movlw b'11111110' ;  Habilita saida no pino RB0
    movwf TRISB
    
    MOVLW 0
    MOVWF TRISD             ;PORTA D É SAÍDA

    MOVLW b'11101100'       ;Quarto bit é configurado como 0 para não estragar a porta D (I/O)
    MOVWF TRISE             ;Bits 0 e 1 da porta E são saídas
    
    MOVLW b'00001110'       ;Pinos configurados como digitais
    MOVWF ADCON1

    BANCO0

    ; Configura timer para uso em funcao de 1s de atraso
    movlw b'00110001' ; Timer 1 com clock interno e prescaler 8
    movwf T1CON
      
    CALL    inicia_lcd
    
    ;FIM DA CONFIGURACAO
    
    
    
    
    REINICIA_CANCELA
    
    call REINICIA
    
    ; AGUARDA ATÉ VEICULO ATIVAR O PRIMEIRO SENSOR E SALVA VALOR DA PORTA NO ACUMULADOR
    CALL ESPERA_POR_VEICULO
    
    ; Aguarda alguns segundos até o "veiculo" se acomodar ^^
    movlw 8
    call espera_w_x_500ms
    
    ; PEGA VALOR DEVIDO E COLOCA NA VARIAVEL "VALOR_DEBITO"
    CALL PEGA_VALOR_DEBITO
    
    
    
    goto REINICIA_CANCELA

;-------------------------------------------------------------------------------
    
    REINICIA
    return

    ESPERA_POR_VEICULO
    	EPV_LOOP
	    call le_sinal_analogico	
	    
	    ; Compara valor lido = 0, fica em loop ate valor mudar
	    movlw 0
	    subwf leitura_analogica, w
	    btfsc STATUS,Z
	    goto EPV_LOOP
	    		
    return
    
    
    PEGA_VALOR_DEBITO
	
	btfss leitura_analogica, 7
	goto PULA_VALOR_4_EIXOS
	    ; Caso valor esteja setado
	    movlw .10
	    movwf VALOR_DEBITO
	    ; ver esquema das mensagens
	    MOVLW   'A'
	    CALL escreve_dado_lcd  
	    goto PULA_FIM_VALOR_DEBITO
	PULA_VALOR_4_EIXOS
	
	btfss leitura_analogica, 6
	goto PULA_VALOR_3_EIXOS
	    ; Caso valor esteja setado
	    movlw 7
	    movwf VALOR_DEBITO
	    ; ver esquema das mensagens
	    MOVLW   'B'
	    CALL escreve_dado_lcd
	    goto PULA_FIM_VALOR_DEBITO
	PULA_VALOR_3_EIXOS
	
	btfss leitura_analogica, 5
	goto PULA_VALOR_CARRO
	    ; Caso valor esteja setado
	    movlw 5
	    movwf VALOR_DEBITO
	    ; ver esquema das mensagens
	    MOVLW   'C'
	    CALL escreve_dado_lcd
	    goto PULA_FIM_VALOR_DEBITO
	PULA_VALOR_CARRO
	
	    movlw 0
	    movwf VALOR_DEBITO
	    ; ver esquema das mensagens
	    MOVLW   'D'
	    CALL escreve_dado_lcd
		
	PULA_FIM_VALOR_DEBITO
	;CALL LCD_LIMPA_TELA
	;CALL LCD_ENVIA_FRASE
    return

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
    
 
 
 
espera_w_x_500ms    
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
    
    
limpa_lcd
    MOVLW   01h
    CALL escreve_comando_lcd
    CALL atrasa_limpa_lcd
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
    
 END
    
    
    ; PROGRAMA TESTE
    ;init
;    bcf PORTB, RB0
;loop_leitura
;	call le_sinal_analogico
;	btfss leitura_analogica, 7
;    goto init
;
;    bsf PORTB, RB0
;    call espera_1s
;    bcf PORTB, RB0
;    call espera_1s
;
;    MOVLW   'A'
;    CALL escreve_dado_lcd
;    
;    goto loop_leitura