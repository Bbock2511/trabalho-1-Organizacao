opBeq:
    la $t1, PC
    lw $t0, 0($a0)
    # Não é necessário carregar $a1 se for $zero, mas para uma implementação genérica de beq:
    lw $t3, 0($a1)

    beq $t0, $t3, realiza_desvio_beq

    jr $ra

realiza_desvio_beq:
    lw $t2, 0($t1)
    sll $a2, $a2, 2
    add $t2, $t2, $a2
    sw $t2, 0($t1)

    jr $ra
 
opAddiu:
    # Extensão de sinal do imediato (16 bits para 32 bits)
    andi $t0, $a2, 0x8000           # Pega o bit mais significativo (bit 15) do imediato
    beq $t0, $zero, imediato_positivo_addiu # Se o bit 15 é 0, o imediato é positivo

    ori $a2, $a2, 0xFFFF0000        # Se o bit 15 é 1, estende o sinal preenchendo os bits superiores com 1s

imediato_positivo_addiu:           # Label renomeado para maior clareza

    lw $t0, 0($a0)                  # Carrega o VALOR de rs em $t0 (assim como sugerido para addi, evite usar $a0 aqui)

    addu $t1, $t0, $a2              # $t1 = rs + (imediato_estendido_por_sinal)
    sw $t1, 0($a1)                  # Salva o valor no registrador rt

    jr $ra
    
opOri:
	lw $t0, 0($a0) # Carrega o VALOR do registrador virtual rs em $t0. (rs_address em $a0)
	
	# O imediato ($a2) para ORI é zero-extended.
	# A instrução 'ori' do MIPS (que seu simulador usa) já faz isso.
	# Então, se $a2 contiver o imediato de 16 bits, está correto.

	or $t1, $t0, $a2 # $t1 recebe rs (valor em $t0) OR imm (valor em $a2)
	sw $t1, 0($a1)   # Salva o valor em $t1 no registrador rt (endereço em $a1)
	
	jr $ra

opLui:
	sll $t1, $a2, 16       							#move os 16 bits menos significativos para a esquerda
   	sw $t1, 0($a1)           						#salva o valor no registrador rt
	
	jr $ra

opLw:
    bne $a3, 1, n_reg_pilha_lw
    lw $t0, 0($a0)            # Carrega o VALOR do registrador virtual $sp em $t0
    j continua_lw
n_reg_pilha_lw:
    lw $t0, 0($a0)            # Carrega o VALOR do registrador virtual rs (cujo ENDEREÇO está em $a0) em $t0

continua_lw:
    add $t0, $t0, $a2         # $t0 = VALOR_DO_RS (ou $sp) + offset. Agora $t0 contém o endereço REAL na memória virtual.

    lw $t1, 0($t0)            # Carrega o word do endereço REAL na memória virtual ($t0)
    sw $t1, 0($a1)            # Salva o word carregado no registrador de destino (endereço em $a1)
    jr $ra
    
opSw:
    bne $a3, 1, n_reg_pilha_sw				
    lw $t0, 0($a0)            # Carrega o VALOR do registrador virtual $sp em $t0
    j continua_sw
n_reg_pilha_sw:
    lw $t0, 0($a0)            # Carrega o VALOR do registrador virtual rs (cujo ENDEREÇO está em $a0) em $t0

continua_sw:
    add $t0, $t0, $a2         # $t0 = VALOR_DO_RS (ou $sp) + offset. Agora $t0 contém o endereço REAL na memória virtual.

    lw $t1, 0($a1)            # Carrega o VALOR do registrador virtual rt (o dado a ser salvo) em $t1
    sw $t1, 0($t0)            # Salva o word de $t1 no endereço REAL na memória virtual ($t0)
    
    jr $ra
 
opLbu:
    bne $a3, 1, n_reg_pilha_lbu
    lw $t0, 0($a0)            # Carrega o VALOR do registrador virtual $sp em $t0
    j continua_lbu
n_reg_pilha_lbu:
    lw $t0, 0($a0)            # Carrega o VALOR do registrador virtual rs (que está no endereço $a0) em $t0

continua_lbu:
    add $t0, $t0, $a2         # $t0 = VALOR_DO_RS (ou $sp) + offset

    lbu $t1, 0($t0)           # Carrega byte unsigned da memória no endereço $t0
    sw $t1, 0($a1)            # Armazena byte carregado no registrador de destino ($a1 é o endereço do registrador rt)
    jr $ra	    
    
opSb:
    bne $a3, 1, n_reg_pilha_sb
    lw $t0, 0($a0)            # Carrega o VALOR do registrador virtual $sp em $t0
    j continua_sb
n_reg_pilha_sb:
    lw $t0, 0($a0)            # Carrega o VALOR do registrador virtual rs (que está no endereço $a0) em $t0

continua_sb:
    add $t0, $t0, $a2         # $t0 = VALOR_DO_RS (ou $sp) + offset

    lw $t1, 0($a1)            # Carrega o VALOR do registrador virtual rt ($a1 é o endereço)
    sb $t1, 0($t0)            # Armazena apenas o byte menos significativo de $t1 no endereço $t0
    jr $ra
    
