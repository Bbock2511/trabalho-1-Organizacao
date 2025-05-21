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
	la $s0, reg
	la $s1, mem_stack
	la $s2, PC
	la $s3, IR
	la $s4, mem_text
	la $s5, mem_data
	
	jal inicializaReg
	
main:
	jal busca
	
	j main
	j finaliza

#-------------Procedimento de Inicialização dos registradores-----------------------
#Inicializa os registradores virtuais de reg com 0 e coloca o endereço de mem_stack em $sp
#
#Registradores:
#$t2 -> indice do vetor de registradores
#$t1 -> operações ocasionais
#$t0 -> operações de deslocamento no vetor e endereço final da operação
#$s0 -> endereço de reg
#$s1 -> endereço de mem_stack
inicializaReg:
	li $t2, -1 #inicializa o índice de Reg em -1
	LoopForReg:
	addi $t2, $t2, 1
	
	sll $t0, $t2, 2 #$t0 = indice*4(transforma em deslocamento)
	add $t0, $t0, $s0 #desloca o endereço para o ponto do indice
	sw $zero, 0($t0) #reg[$s3] = 0
	
	bne $t2, 32, LoopForReg #volta o label até que $t2 chegue em 31
	
	#Inserindo endereço da pilha no registrador	
	#$t0 = b[29]
	li $t2, 29 #coloca o índice 29 em $t2
	sll $t0, $t2, 2 #transforma em deslocamento 
	add $t0, $t0, $s0 
	
	addi $t1, $s1, 1024 #coloca o endereço final de mem_stack em $t1
	sw $t1, 0($t0) #insere o endereço final de mem_stack em b[29]
	
	jr $ra
#------------------------Fim do Procedimento-----------------------------
	 
#--------------------Procedimento de Busca de Instrução-----------------
#Registradores
#$s2 -> PC
#$s3 -> IR
#$s4 -> mem_text
busca:
#---Prólogo---
addi $sp, $sp, -12
sw $ra, 12($sp)
#-------------
	lw $t7, 0($s2) #pega a palavra em PC
	li $t1, 0x00400000
	sub $t0, $t7, $t1 #subtrai o endereço da próxima instrução com o endereço base para encontrar o offset necessário para pegar a instrução de mem_text
	add $t0, $t0, $s4 #soma o offset 
	
	lw $t1, 0($t0) #tira a instrução do endereço correspondente de mem_text
	sw $t1, 0($s3) #coloca a instrução em IR(instrução a ser executada)
	
	jal decode
	
	#passa para o próximo endereço
	addi $t7, $t7, 4 
	sw $t7, 0($s2) 
	j busca
#------------------Procedimento de Decodificação-----------------------
decode:

#-----------------Procedimento de Execução---------------------------
executa:
	
	
#####################################################
################Tipos de Instrucao######################
instrucaoR:
instrucaoI:
instrucaoJ:


finaliza:
###fim do programa###
	li $v0, 10
	syscall
#####################
