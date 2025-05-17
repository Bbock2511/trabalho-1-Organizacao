.data
#Nome dos arquivos para a leitura
nomeArquivoBin: .asciiz "trabalho_01-2025_1.bin"
nomeArquivoDat: .asciiz "trabalho_01-2025_1.dat"
bufferArquivo: .space 4 
#############################################


.text
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
	move $a0, $t1 #insere o file descriptor como argumento do syscall($a0)
	la $a1, bufferArquivo #arquivo -> mem_data
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
