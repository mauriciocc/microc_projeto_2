
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
    tmp_var
    VALOR_DEBITO    
    TEMPO_LUZ_ALERTA
    TEMPO_SOM_ALERTA
    ENDC


    ORG 0

    BANCO1
    
    ; Habilitado R1 para output para simular BUZZER
    movlw b'11111100' ;  Habilita saida no pino RB0
    movwf TRISB
    
    movlw b'11100111' ;  Habilita saida no pino RC3 e RC4
    movwf TRISC
    
    ;MOVLW b'00000011'
    movlw 0
    MOVWF TRISD             ;PORTA D É SAÍDA

    MOVLW b'11101000'       ;Quarto bit é configurado como 0 para não estragar a porta D (I/O)
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
	
	; Lê novamente o sinal analogico (apos o sinal estabilizar, pois serao colocados pesos)
	call le_sinal_analogico
	
	; PEGA VALOR DEVIDO E COLOCA NA VARIAVEL "VALOR_DEBITO"
	CALL PEGA_VALOR_DEBITO
	;movlw .0
	;movwf VALOR_DEBITO
	
	; AGUARDA PELO PAGAMENTO DO DEBITO
	CALL AGUARDA_PAGAMENTO
	
	
	movlw 4
	call espera_w_x_500ms
	
	; Abre cancela	    
	bsf PORTE, RE2
	; Fim
	
	aguarda_passagem_carro
	    movlw 2
	    call espera_w_x_500ms
	    
	    ; DEBUG
	    MOVLW   'Z'
	    CALL escreve_dado_lcd
	    
	    call le_sinal_analogico
	    ; fica em loop ate valor voltar para 0
	    movlw 0
	    subwf leitura_analogica, 1
	    btfss STATUS,Z
	    goto APC_INC_ALERTAS
	    goto APC_PULA
	
	    APC_INC_ALERTAS
	    call ALERTAS_STEP
	    goto aguarda_passagem_carro
	
	APC_PULA
	
	call RESETA_ALERTAS
	
	; Aguarda 4s
	movlw 8
	call espera_w_x_500ms
	    
    goto REINICIA_CANCELA

;-------------------------------------------------------------------------------
    
    REINICIA
	call RESETA_ALERTAS
    return

    ESPERA_POR_VEICULO
    	EPV_LOOP
	    call le_sinal_analogico	
	    
	    ; Compara valor lido = 0, fica em loop ate valor mudar
	    movlw 0
	    subwf leitura_analogica, 1
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
	    MOVLW   '4'
	    CALL escreve_dado_lcd  
	    goto PULA_FIM_VALOR_DEBITO
	PULA_VALOR_4_EIXOS
	
	btfss leitura_analogica, 6
	goto PULA_VALOR_3_EIXOS
	    ; Caso valor esteja setado
	    movlw 7
	    movwf VALOR_DEBITO
	    ; ver esquema das mensagens
	    MOVLW   '3'
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
	    MOVLW   'M'
	    CALL escreve_dado_lcd
		
	PULA_FIM_VALOR_DEBITO
	;CALL LCD_LIMPA_TELA
	;CALL LCD_ENVIA_FRASE
    return
    
    RESETA_ALERTAS
	movlw .30
	movwf TEMPO_LUZ_ALERTA
	movlw .20
	movwf TEMPO_SOM_ALERTA
	bcf PORTB, RB0	
	; ??? aonde esta ligado o som de alerta ???
	bcf PORTB, RB1
    return
    
    ALERTAS_STEP
    
	; Checa se TEMPO_LUZ_ALERTA = 0
	movlw 0
	subwf TEMPO_LUZ_ALERTA, 1
	
	btfsc STATUS,Z
	goto TOGGLE_LUZ_ALERTA ; Se for "toggleia" luz
	
	DECF TEMPO_LUZ_ALERTA ; Senão decrementa variavel retorna (som só liga 20s apos luz ligar)
	return

	TOGGLE_LUZ_ALERTA
	    btfsc PORTB, RB0
	    goto DESLIGA_LUZ_ALERTA ; Caso luz esteja liga, pula para desligar luz
	    
	    bsf PORTB, RB0 ; Liga luz
	    goto PULA_LUZ_ALERTA
	    
	    DESLIGA_LUZ_ALERTA
	    bcf PORTB, RB0 ; Liga luz
	
	PULA_LUZ_ALERTA
	
	; Checa se TEMPO_SOM_ALERTA = 0
	movlw 0
	subwf TEMPO_SOM_ALERTA, 1
	
	btfsc STATUS,Z
	goto TOGGLE_SOM_ALERTA ; Se for "toggleia" som
	
	DECF TEMPO_SOM_ALERTA ; Senão decrementa variavel e pula
	goto PULA_SOM_ALERTA

	TOGGLE_SOM_ALERTA
	    btfss PORTB, RB1
	    bsf PORTB, RB1 ; Liga som :D    
	PULA_SOM_ALERTA
	
    return 
    
    ;------------------------------------------------------
    ; AGUARDA PAGAMENTO DO DEBITO
    AGUARDA_PAGAMENTO
    
	    ; SE VALOR_DEBITO FOR 0 RETORNA IMEDIATAMENTE
	    movlw 0
	    subwf VALOR_DEBITO, 1
	    btfsc STATUS,Z
	    return
	    
	    ; Habilita RN (Recebimento de notas) - Isso é utilizado ?
	    ;SETB P1.6
	    
	    CALL RESETA_ALERTAS
	    AP_LOOP
		
		; 1s entre as operações
		movlw 2
		call espera_w_x_500ms
		
		; AQUI PRECISA ENVIAR MENSAGEM
		
		
		; Limpa flags
		bcf STATUS, C
		bcf STATUS, Z
		
		
		MOVLW   'W'
		CALL escreve_dado_lcd
		
		;Habilita leitura nos pinos necessarios da porta d
		BANCO1
		    movlw b'00000011'
		    MOVWF TRISD
		BANCO0
		
		; Checa input de nota de R$ 2
		btfss PORTD, RD0
		goto AP_PULA_NOTA_2

		    movlw 2
		    subwf VALOR_DEBITO, 1
		    
		    goto AP_FORA_NOTA
		
		AP_PULA_NOTA_2
		
		; Checa input de nota de R$ 5
		btfss PORTD, RD1
		goto AP_PULA_NOTA_5

		    movlw 5
		    subwf VALOR_DEBITO, 1
		    
		    goto AP_FORA_NOTA
		
		AP_PULA_NOTA_5
		
		; Retorna porta D para o estado padrao
		BANCO1
		    movlw 0
		    MOVWF TRISD
		BANCO0
		
		; Usuario não interagiu com o sistema
		call ALERTAS_STEP		
		
		; DEBUG
		MOVLW   'X'
		CALL escreve_dado_lcd
		goto AP_LOOP
		
		; Usuario interagiu com o sistema
		AP_FORA_NOTA		
	
		; Retorna porta D para o estado padrao
		BANCO1
		    movlw 0
		    MOVWF TRISD
		BANCO0
		
		call RESETA_ALERTAS
		
		MOVLW   'Y'
		CALL escreve_dado_lcd
		
		
		    MOVLW   'Q'
		CALL escreve_dado_lcd
		; ORDEM DAS INSTRUÇÕES É IMPORTANTE
		; NUMERO NEGATIVO seta tanto o C como o Z
		
		; Caso resultado o resultado de negativo, precisamos dar
		; troco para o motorista
		btfsc STATUS,C
		goto AP_TROCO
		
		MOVLW   'T'
		CALL escreve_dado_lcd
		
		; Caso resultado da subtração seja 0, retorna normalmente
		btfsc STATUS,Z
		return
		
		MOVLW   'R'
		CALL escreve_dado_lcd

	    
	    goto AP_LOOP
	    			    
	    AP_TROCO
	    
	    ;CONVERTE PARA VALOR ABSOLUTO
	    movfw VALOR_DEBITO
	    movwf tmp_var
	    movlw .255
	    
	    movwf VALOR_DEBITO
	    movfw tmp_var
	    subwf VALOR_DEBITO, 1
	    incf VALOR_DEBITO, 1
	    ; FIM 
	    
	    APT_LOOP
	    
	    ; REPOEM MOEDA
		bsf PORTC, RC3	   
		movlw 2
		call espera_w_x_500ms

		; FECHA SM
		bcf PORTC, RC3	   
		movlw 2
		call espera_w_x_500ms	    
	    ; FIM
	    
	    ; LIBERA MOEDA
		bsf PORTC, RC4	   
		movlw 2
		call espera_w_x_500ms

		; FECHA SM
		bcf PORTC, RC4	   
		movlw 2
		call espera_w_x_500ms	    
	    ; FIM
	    
	    
	    movlw 1
	    subwf VALOR_DEBITO, 1
	    
	    ; Checa se o troco ja foi dado (VALOR_DEBITO = 0)	    
	    btfss STATUS,Z
	    goto APT_LOOP
	    
	    
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