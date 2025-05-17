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
main:
	la $s0, reg
	la $s1, mem_stack
	
	jal inicializaReg
	
	
	j finaliza

#-------------Procedimento de Inicialização dos registradores-----------------------
#Inicializa os registradores virtuais de reg com 0 e coloca o endereço de mem_stack em $sp
#
#Registradores:
#$t2 -> indice do vetor de registradores
#$t1 ->
#$t0 -> operações de deslocamento no vetor e endereço final da operação
#
#Argumentos:
#$a0 -> endereço de reg($s0)
#$a1 -> endereço de mem_stack($s1)
inicializaReg:
move $a0, $s0 #$a0 = $s0
move $a1, $s1 #$a1 = $s1
#-----------------------
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
	
	la $a1, 1024($a1) #coloca o final de mem_stack em $a1
	sw $a1, ($t0) #insere o endereço no vetor
	
	jr $ra
#------------------------Fim do Procedimento-----------------------------


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
