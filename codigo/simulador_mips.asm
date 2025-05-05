.data
#Nome dos arquivos para a leitura
nomeArquivoBin: .asciiz "trabalho_01-2025_1.bin"
nomeArquivoDat: .asciiz "trabalho_01-2025_1.dat"
#############################################
#Variaveis de leitura de instrução
PC: .word 0x00400000 #variável que capturará as instruções lidas
IR: .word 0 #endereço será sobrescrito pela instrução capturada por PC
#############################################
#Memória simulada do processador
reg:.space 1024 #registradores do mips
mem_text:.space 4
mem_data:.space 4
mem_stack:.space 4
#############################################

.text
main:
	jal leDat
	jal leBin
	
	###fim do programa###
	li $v0, 10
	syscall
	#####################
	
inicializaReg:
	

################Tipos de Instrucao######################
instrucaoR:
instrucaoI:
instrucaoJ:

############Funcoes de Leitura de arquivo###############
leDat:
	#abre o arquivo.bin com syscall 13
	li $v0, 13
	la $a0, nomeArquivoDat
	li $a1, 0
	li $a2, 0
	syscall
	move $t1, $v0 
	
	#lê o arquivo aberto
	li $v0, 14
	move $a0, $t1
	la $a1, mem_data #arquivo -> mem_data
	li $a2, 4
	syscall
	jr $ra

leBin:
	#abre o arquivo.bin com syscall 13
	li $v0, 13
	la $a0, nomeArquivoBin
	li $a1, 0
	li $a2, 0
	syscall
	move $t1, $v0 
	
	#lê o arquivo aberto
	li $v0, 14
	move $a0, $t1
	la $a1, mem_text #arquivo -> mem_text
	li $a2, 4
	syscall
	jr $ra
#####################################################