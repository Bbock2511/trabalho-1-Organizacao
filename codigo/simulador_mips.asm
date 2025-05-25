.data
ErroInstrucaoR: .asciiz "Falha em ler funct tipo R"
#Variaveis de leitura de instrução
PC: .word 0x00400000 #variável que capturará as instruções lidas
IR: .word 0 #endereço será sobrescrito pela instrução capturada por PC
#############################################
#Memória simulada do processador
reg:.space 128 #registradores do mips
mem_text:.space 2048
mem_data:.space 2048 
mem_stack:.space 1024 #Memória para a pilha $sp
#############################################

.text
inicializa:
	#inicializaReg(reg, mem_stack)
	#endereçando argumentos em $t0 e $t1
	la $t0, reg
	la $t1, mem_stack
	
	move $a0, $t0
	move $a1, $t1
	jal inicializaReg
	
main:
	#busca(PC, IR, mem_text)
	#endereçando argumentos em $t0, $t1 e $t2
	la $t0, PC
	la $t1, IR
	la $t2, mem_text
	
	move $a0, $t0
	move $a1, $t1
	move $a2, $t2
	jal busca
	
	j main #o loop é infinito, por enquanto
	j finaliza

#-------------Procedimento de Inicialização dos registradores-----------------------
#Inicializa os registradores virtuais de reg com 0 e coloca o endereço de mem_stack em $sp
#
#Registradores:
#$t2 -> indice do vetor de registradores
#$t1 -> operações ocasionais
#$t0 -> operações de deslocamento no vetor e endereço final da operação
#
#Argumentos:
#$a0 <- endereço de reg
#$a1 <- endereço de mem_stack
inicializaReg:
#---Prólogo---
#Nada para ver aqui.
#-------------
	li $t2, -1 #inicializa o índice de Reg em -1
	LoopForReg:
	addi $t2, $t2, 1
	
	sll $t0, $t2, 2 #$t0 = indice*4(transforma em deslocamento)
	add $t0, $t0, $a0 #desloca o endereço para o ponto do indice
	sw $zero, 0($t0) #reg[$s3] = 0
	
	bne $t2, 32, LoopForReg #volta o label até que $t2 chegue em 31
	
	#Inserindo endereço da pilha no registrador	
	#$t0 = b[29]
	li $t2, 29 #coloca o índice 29 em $t2
	sll $t0, $t2, 2 #transforma em deslocamento 
	add $t0, $t0, $a0 
	
	addi $t1, $a1, 1024 #coloca o endereço final de mem_stack em $t1
	sw $t1, 0($t0) #insere o endereço final de mem_stack em b[29]
	
	jr $ra
#------------------------Fim do Procedimento-----------------------------
	 
#--------------------Procedimento de Busca de Instrução-----------------
#Argumentos
#$a0 <- endereço de PC
#$a1 <- endereço de IR
#$a2 <- endereço de mem_text
#Registradores
#$s0 -> palavra de PC
#$s1 -> endereço de PC
busca:
#---Prólogo---
addi $sp, $sp, -4
sw $ra, 0($sp)

move $s1, $a0
#-------------
	lw $s0, 0($s1) #pega a palavra em PC
	li $t1, 0x00400000
	sub $t0, $s0, $t1 #subtrai o endereço base do endereço da próxima instrução para encontrar o offset necessário para pegar a instrução de mem_text
	add $t0, $t0, $a2 #soma o offset 
	
	lw $t1, 0($t0) #tira a instrução do endereço correspondente de mem_text
	sw $t1, 0($a1) #coloca a instrução em IR(instrução a ser executada)
	
	#decode(IR)
	move $a0, $a1 #coloca o endereço de IR em a0
	jal decode
	
	#passa para o próximo endereço
	addi $s0, $s0, 4 
	sw $s0, 0($s1) 
	
#---Epílogo---
lw $ra, 0($sp)
addi $sp, $sp, 4
jr $ra
#-------------
#------------------------Fim do Procedimento-----------------------------

#------------------Procedimento de Decodificação-----------------------
#Registradores:
#$s0 -> endereço de IR
#
#Argumentos:
#$a0 <- endereço de IR
decode:
#---Prólogo---
addi $sp, $sp, -12
sw $ra, 0($sp) #guarda endereço de retorno
sw $s0, 4($sp) #armazena $s0 da função anterior(palavra de PC)
sw $s1, 8($sp) #armazena $s1 da função anterior(endereço de PC)

move $t0, $a0 
#-------------
	lw $t0, 0($t0)
	srl $t1, $t0, 26 #desloca todos os bits para direita até que reste apenas o opcode
	
	#verifica se é uma instrução tipo R
	beq $zero, $t1, opcodeR
	#---------------------------------
	#verifica se é uma instrução tipo J
	li $t2, 0x02 #como a única instrução do tipo J a ser implementada é a instrução "j" com opcode 0x02, esse é o único caso onde teremos uma instrução J
	beq $t1, $t2, opcodeJ
	#---------------------------------
	#como não se enquadra nas outras instruções, obrigatoriamente é uma instrução do tipo I ou inexistente
	j opcodeI
	#---------------------------------
	
	#decodifica tipo R
	opcodeR:
		#Vai pra decodificação de funct.
		#R_decode(conteudo_IR)
		move $a0, $t0 
		jal R_decode
		j terminaDecodificacao
		
	#decodifica tipo J
	opcodeJ:
		andi $t0, $t0, 0x03ffffff #usa o número hexadecimal para zerar os bits do opcode e manter o endereço
		#executa_j(address)
		move $a0, $t0
		jal executa_j
		j terminaDecodificacao
	
	#decodifica tipo I
		#addi
		#andi
		#ori
		#lw
		#sw
		#beq
		#bne
		#syscall
	opcodeI:
		
terminaDecodificacao:
#---Epílogo---
lw $ra, 0($sp)
lw $s0, 4($sp)
lw $s1, 8($sp)
addi $sp, $sp, 12

jr $ra
#-------------
#------------------------Fim do Procedimento-----------------------------

#------------Procedimendo de Decodificação tipo R-----------------
#Registradores:
#$s0 -> Instrução a ser decodificada
R_decode:
#---Prólogo---
addi $sp, $sp, -4
sw $ra, 0($sp)

move $s0, $a0
#-------------
	andi $t0, $s0, 0x3f #usa o número 3f para zerar todos os bits após os 6 primeiros
	#Verifica qual a instrução correspondente ao funct
	beq $t0, $zero, sll
	beq $t0, 0x02, srl
	beq $t0, 0x20, add
	beq $t0, 0x22, sub
	beq $t0, 0x24, and
	beq $t0, 0x25, or
	
	li $v0, 4
	la $a0, ErroInstrucaoR
	syscall
	j finaliza
	
	sll:
		#decodifica os dados
		andi $t0, $s0, 0x7c0 #usa o número 7c0 para zerar todos os bits, exceto os de shamt(bits que serão deslocados)
		andi $t1, $s0, 0x7c00 #usa o número 7c00 para zerar todos os bits, exceto os de rd(numero do registrador que receberá o resultado)
		andi $t2, $s0, 0xf8000 #usa o número f8000 para zerar todos os bits, exceto os de rt(numero do registrador que sofrerá a operação)
		
		#executa_sll(shamt, rd, rt)
		move $a0, $t0
		move $a1, $t1
		move $a2, $t2
		jal executa_sll
		j terminaDecodeR
		
	srl:
		#decodifica os dados
		andi $t0, $s0, 0x7c0 #usa o número 7c0 para zerar todos os bits, exceto os de shamt(bits que serão deslocados)
		andi $t1, $s0, 0x7c00 #usa o número 7c00 para zerar todos os bits, exceto os de rd(numero do registrador que receberá o resultado)
		andi $t2, $s0, 0xf8000 #usa o número f8000 para zerar todos os bits, exceto os de rt(numero do registrador que sofrerá a operação)
		
		#executa_sll(shamt, rd, rt)
		move $a0, $t0
		move $a1, $t1
		move $a2, $t2
		jal executa_srl
		j terminaDecodeR
	add:
		#decodifica os dados
		andi $t0, $s0, 0x7c00 #usa o número 0x7c00 para zerar todos os bits, exceto os de rd(número do registrador que receberá o resultado
		andi $t1, $s0, 0xf8000 #usa o número 0xf8000 para zerar todos os bits, exceto os de rt(número de um dos registradores operadores)
		andi $t2, $s0, 0x01f00000 #usa o número 0x01f00000 para zerar todos os bits, exceto os de rs(número do outro registrador operador)
		
		#executa_add(rd, rt, rs)
		move $a0, $t0
		move $a1, $t1 
		move $a2, $t2
		jal executa_add
		j terminaDecodeR
	sub:
		#decodifica os dados
		andi $t0, $s0, 0x7c00 #usa o número 0x7c00 para zerar todos os bits, exceto os de rd(número do registrador que receberá o resultado
		andi $t1, $s0, 0xf8000 #usa o número 0xf8000 para zerar todos os bits, exceto os de rt(número de um dos registradores operadores)
		andi $t2, $s0, 0x01f00000 #usa o número 0x01f00000 para zerar todos os bits, exceto os de rs(número do outro registrador operador)
		
		#executa_sub(rd, rt, rs)
		move $a0, $t0
		move $a1, $t1 
		move $a2, $t2
		jal executa_sub
		j terminaDecodeR
	and:
		#decodifica os dados
		andi $t0, $s0, 0x7c00 #usa o número 0x7c00 para zerar todos os bits, exceto os de rd(número do registrador que receberá o resultado
		andi $t1, $s0, 0xf8000 #usa o número 0xf8000 para zerar todos os bits, exceto os de rt(número de um dos registradores operadores)
		andi $t2, $s0, 0x01f00000 #usa o número 0x01f00000 para zerar todos os bits, exceto os de rs(número do outro registrador operador)
		
		#executa_and(rd, rt, rs)
		move $a0, $t0
		move $a1, $t1 
		move $a2, $t2
		jal executa_and
		j terminaDecodeR
		
	or:
		#decodifica os dados
		andi $t0, $s0, 0x7c00 #usa o número 0x7c00 para zerar todos os bits, exceto os de rd(número do registrador que receberá o resultado
		andi $t1, $s0, 0xf8000 #usa o número 0xf8000 para zerar todos os bits, exceto os de rt(número de um dos registradores operadores)
		andi $t2, $s0, 0x01f00000 #usa o número 0x01f00000 para zerar todos os bits, exceto os de rs(número do outro registrador operador)
		
		#executa_or(rd, rt, rs)
		move $a0, $t0
		move $a1, $t1 
		move $a2, $t2
		jal executa_or
		j terminaDecodeR
	
terminaDecodeR:
#---Epílogo---
lw $ra, 0($sp)
addi $sp, $sp, 4
jr $ra
#-------------
#------------------------Fim do Procedimento------------------------------

#-----------------Procedimento de Execução de j---------------------------
#Registradores
#$s0 -> endereço para ser pulado
#
#Argumentos
#$a0 -> endereço para ser pulado
executa_j:
#---Prólogo---
addi $sp, $sp, -8
sw $ra, 0($sp)
sw $s0, 4($sp)

move $s0, $a0
#-------------
	#Pega o endereço de PC
	la $t0, PC
	addi $s0, $s0, -4 #subtrai 4 do endereço para que o incremento de busca não altere o endereço
	sw $s0, 0($t0)
#---Epílogo---
lw $ra, 0($sp)
lw $s0, 4($sp)
addi $sp, $sp, 8
jr $ra
#-------------
#------------------------Fim do Procedimento------------------------------

#-----------------Procedimento de Execução de or---------------------------
#Registradores
#$s0 -> rd (registrador onde o resultado vai ser armazenado)
#$s1 -> rt (registrador operador 1)
#$s2 -> rs (registrador operador 2)
#(todos são indices para o vetor de registradores)
#
#Argumentos
#$a0 -> rd
#$a1 -> rt
#$a2 -> rs
executa_or:
#---Pŕologo---
addi $sp, $sp, -8
sw $ra, 0($sp)
sw $s0, 4($sp)

move $s0, $a0
move $s1, $a1
move $s2, $a2
#-------------
	la $t0, reg
	
	#pegar o endereço de rd e colocar em $t1
	sll $t1, $s0, 2 #transforma indice de $s0 em offset
	add $t1, $t1, $t0 #soma o offset no vetor de registradores
	#$t1 tem o endereço de rd
	
	#pegar o endereço de rt e colocar em $t2
	sll $t2, $s1, 2 #transforma indice de $s1 em offset
	add $t2, $t2, $t0
	#$t2 tem o endereço de rt
	
	#pegar o endereço de rs e colocar em $t3
	sll $t3, $s2, 2 #transforma o indice de $s2 em offset
	add $t3, $t3, $t0 
	#$t3 tem o endereço de rs
	
	#captura os valores dos endereços e realiza a operação
	lw $t2, 0($t2)
	lw $t3, 0($t3)
	or $t4, $t3, $t2
	
	#guarda o resultado em rd
	sw $t4, 0($t1)
	
#---Epílogo---
lw $ra, 0($sp)
lw $s0, 4($sp)
addi $sp, $sp, 8
jr $ra
#-------------
#------------------------Fim do Procedimento-----------------------------

#-----------------Procedimento de Execução de and---------------------------
#Registradores
#$s0 -> rd (registrador onde o resultado vai ser armazenado)
#$s1 -> rt (registrador operador 1)
#$s2 -> rs (registrador operador 2)
#(todos são indices para o vetor de registradores)
#
#Argumentos
#$a0 -> rd
#$a1 -> rt
#$a2 -> rs
executa_and:
#---Pŕologo---
addi $sp, $sp, -8
sw $ra, 0($sp)
sw $s0, 4($sp)

move $s0, $a0
move $s1, $a1
move $s2, $a2
#-------------
	la $t0, reg
	
	#pegar o endereço de rd e colocar em $t1
	sll $t1, $s0, 2 #transforma indice de $s0 em offset
	add $t1, $t1, $t0 #soma o offset no vetor de registradores
	#$t1 tem o endereço de rd
	
	#pegar o endereço de rt e colocar em $t2
	sll $t2, $s1, 2 #transforma indice de $s1 em offset
	add $t2, $t2, $t0
	#$t2 tem o endereço de rt
	
	#pegar o endereço de rs e colocar em $t3
	sll $t3, $s2, 2 #transforma o indice de $s2 em offset
	add $t3, $t3, $t0 
	#$t3 tem o endereço de rs
	
	#captura os valores dos endereços e realiza a operação
	lw $t2, 0($t2)
	lw $t3, 0($t3)
	and $t4, $t3, $t2
	
	#guarda o resultado em rd
	sw $t4, 0($t1)
	
#---Epílogo---
lw $ra, 0($sp)
lw $s0, 4($sp)
addi $sp, $sp, 8
jr $ra
#-------------
#------------------------Fim do Procedimento-----------------------------

#-----------------Procedimento de Execução de sub---------------------------
#Registradores
#$s0 -> rd (registrador onde o resultado vai ser armazenado)
#$s1 -> rt (registrador operador 1)
#$s2 -> rs (registrador operador 2)
#(todos são indices para o vetor de registradores)
#
#Argumentos
#$a0 -> rd
#$a1 -> rt
#$a2 -> rs
executa_sub:
#---Pŕologo---
addi $sp, $sp, -8
sw $ra, 0($sp)
sw $s0, 4($sp)

move $s0, $a0
move $s1, $a1
move $s2, $a2
#-------------
	la $t0, reg
	
	#pegar o endereço de rd e colocar em $t1
	sll $t1, $s0, 2 #transforma indice de $s0 em offset
	add $t1, $t1, $t0 #soma o offset no vetor de registradores
	#$t1 tem o endereço de rd
	
	#pegar o endereço de rt e colocar em $t2
	sll $t2, $s1, 2 #transforma indice de $s1 em offset
	add $t2, $t2, $t0
	#$t2 tem o endereço de rt
	
	#pegar o endereço de rs e colocar em $t3
	sll $t3, $s2, 2 #transforma o indice de $s2 em offset
	add $t3, $t3, $t0 
	#$t3 tem o endereço de rs
	
	#captura os valores dos endereços e realiza a operação
	lw $t2, 0($t2)
	lw $t3, 0($t3)
	sub $t4, $t3, $t2
	
	#guarda o resultado em rd
	sw $t4, 0($t1)
	
#---Epílogo---
lw $ra, 0($sp)
lw $s0, 4($sp)
addi $sp, $sp, 8
jr $ra
#-------------
#------------------------Fim do Procedimento-----------------------------

#-----------------Procedimento de Execução de add---------------------------
#Registradores
#$s0 -> rd (registrador onde o resultado vai ser armazenado)
#$s1 -> rt (registrador operador 1)
#$s2 -> rs (registrador operador 2)
#(todos são indices para o vetor de registradores)
#
#Argumentos
#$a0 -> rd
#$a1 -> rt
#$a2 -> rs
executa_add:
#---Pŕologo---
addi $sp, $sp, -8
sw $ra, 0($sp)
sw $s0, 4($sp)

move $s0, $a0
move $s1, $a1
move $s2, $a2
#-------------
	la $t0, reg
	
	#pegar o endereço de rd e colocar em $t1
	sll $t1, $s0, 2 #transforma indice de $s0 em offset
	add $t1, $t1, $t0 #soma o offset no vetor de registradores
	#$t1 tem o endereço de rd
	
	#pegar o endereço de rt e colocar em $t2
	sll $t2, $s1, 2 #transforma indice de $s1 em offset
	add $t2, $t2, $t0
	#$t2 tem o endereço de rt
	
	#pegar o endereço de rs e colocar em $t3
	sll $t3, $s2, 2 #transforma o indice de $s2 em offset
	add $t3, $t3, $t0 
	#$t3 tem o endereço de rs
	
	#captura os valores dos endereços e realiza a operação
	lw $t2, 0($t2)
	lw $t3, 0($t3)
	add $t4, $t3, $t2
	
	#guarda o resultado em rd
	sw $t4, 0($t1)
	
#---Epílogo---
lw $ra, 0($sp)
lw $s0, 4($sp)
addi $sp, $sp, 8
jr $ra
#-------------
#------------------------Fim do Procedimento-----------------------------

#-----------------Procedimento de Execução de sll---------------------------
#Registradores
#$s0 -> shamt
#$s1 -> rd(indice do registrador destino)
#$s2 -> rt(indice do registrador operador)
#
#Argumentos
#$a0 -> shamt
#$a1 -> rd
#$a2 -> rt
executa_sll:
#---Prólogo---
addi $sp, $sp, -8
sw $ra, 0($sp)
sw $s0, 4($sp)

move $s0, $a0
move $s1, $a1
move $s2, $a2
#-------------
	la $t0, reg #pegando o vetor de registradores
	
	#pegar o endereço do registrador de rd
	sll $t1, $s1, 2 #transforma o indice do registrador em offset para somar no vetor
	add $t1, $t1, $t0 #$t1 = $t1(offset)+$t0(addr de reg)
	#$t1 tem o endereço do registrador destino
	
	
	#pegar o endereço do registrador de rt
	sll $t2, $s2, 2 #transforma o indice do registrador em offset para somar no vetor
	add $t2, $t2, $t0 #$t2 = $t2(offset)+$t0(addr de reg)
	#$t2 tem o endereço registrador que vai ter os bits deslocados
	
	lw $t2, 0($t2)
	
	#a partir daqui, $t0 vira o indice do loop
	move $t0, $zero
	loopDeslocamentosll:
		addi $t0, $t0, 1 #incrementa o indice
		mul $t2, $t2, 2 #multiplica por 2(cada bit deslocado é uma multiplicação)
		beq $t0, $s0, fimLoopsll #termina o loop se o indice for igual a shamt
		j loopDeslocamentosll
	
	fimLoopsll:
		sw $t2, 0($t1) #guarda o valor da operação em rd
	
#---Epílogo---
lw $ra 0($sp)
lw $s0, 4($sp)
addi $sp, $sp, 8
jr $ra
#-------------
#------------------------Fim do Procedimento-----------------------------

#-----------------Procedimento de Execução de srl---------------------------
#Registradores
#$s0 -> shamt
#$s1 -> rd(indice do registrador destino)
#$s2 -> rt(indice do registrador operador)
#
#Argumentos
#$a0 -> shamt
#$a1 -> rd
#$a2 -> rt
executa_srl:
#---Prólogo---
addi $sp, $sp, -8
sw $ra, 0($sp)
sw $s0, 4($sp)

move $s0, $a0
move $s1, $a1
move $s2, $a2
#-------------
	la $t0, reg #pegando o vetor de registradores
	
	#pegar o endereço do registrador de rd
	sll $t1, $s1, 2 #transforma o indice do registrador em offset para somar no vetor
	add $t1, $t1, $t0 #$t1 = $t1(offset)+$t0(addr de reg)
	#$t1 tem o endereço do registrador destino
	
	
	#pegar o endereço do registrador de rt
	sll $t2, $s2, 2 #transforma o indice do registrador em offset para somar no vetor
	add $t2, $t2, $t0 #$t2 = $t2(offset)+$t0(addr de reg)
	#$t2 tem o endereço registrador que vai ter os bits deslocados
	
	lw $t2, 0($t2)
	
	#a partir daqui, $t0 vira o indice do loop
	move $t0, $zero
	loopDeslocamentosrl:
		addi $t0, $t0, 1 #incrementa o indice
		div $t2, $t2, 2 #divide por 2(cada bit deslocado é uma divisão)
		beq $t0, $s0, fimLoopsrl #termina o loop se o indice for igual a shamt
		j loopDeslocamentosrl
	
	fimLoopsrl:
		sw $t2, 0($t1) #guarda o valor da operação em rd
	
#---Epílogo---
lw $ra 0($sp)
lw $s0, 4($sp)
addi $sp, $sp, 8
jr $ra
#-------------
#------------------------Fim do Procedimento-----------------------------


finaliza:
###fim do programa###
	li $v0, 10
	syscall
#####################
