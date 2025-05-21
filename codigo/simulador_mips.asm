.data
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
		#R_decode(conteúdo_IR)
		move $a0, $t0
		j R_decode
		
	#decodifica tipo J
	opcodeJ:
	
	#decodifica tipo I
	opcodeI:
		
#---Epílogo---
lw $ra, 0($sp)
lw $s0, 4($sp)
lw $s1, 8($sp)
addi $sp, $sp, 12

jr $ra
#-------------

#------------Procedimendo de Decodificação tipo R-----------------
#
R_decode:
		#sll = 0x00
		#srl = 0x02
		#add = 0x20
		#sub = 0x22
		#and = 0x24
		#or = 0x25
		#shamt é o número de bits deslocados em sll e srl
#---Prólogo---
addi $sp, $sp, -4
sw $ra, 0($sp)
#-------------
	
#---Epílogo---
lw $ra, 0($sp)
addi $sp, $sp, 4
jr $ra
#-------------
#-----------------------------------------------------------------

#-----------------Procedimento de Execução---------------------------
#Argumentos
executa:

	
	
#####################################################
################Tipos de Instrucao######################


finaliza:
###fim do programa###
	li $v0, 10
	syscall
#####################
