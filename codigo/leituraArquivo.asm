.data
#Nome dos arquivos para a leitura
filenameBin:  .asciiz "arquivo.bin"
nomeArquivoDat: .asciiz "arquivo.dat"
mem_text:  .space 4096       # 1KB de espaço para instruções
bufferArquivo: .space 4
#############################################


.text
############Funcoes de Leitura de arquivo###############
leDat:
	#abre o arquivo .dat com syscall 13
	li $v0, 13
	la $a0, nomeArquivoDat
	li $a1, 0
	li $a2, 0
	syscall
	
	#$v0 = file descriptor
	move $t1, $v0
	
	#lê o arquivo aberto
	li $v0, 14
	move $a0, $t1 #insere o file descriptor como argumento do syscall($a0)
	la $a1, bufferArquivo #arquivo -> mem_data
	li $a2, 361
	syscall
	

leBin:
	# Abrir arquivo
	li   $v0, 13           # syscall: open
	la   $a0, filenameBin     # nome do arquivo
	li   $a1, 0            # modo: leitura
	li   $a2, 0            # permissão (ignorado aqui)
	syscall
	
	move $s0, $v0          # salva o descritor em $s0

	# Ler conteúdo
	li   $v0, 14           # syscall: read
	move $a0, $s0          # descritor
	la   $a1, mem_text     # buffer destino
	li   $a2, 1024         # número de bytes a ler
	syscall

	# Fechar arquivo
	li   $v0, 16
	move $a0, $s0
	syscall

#####################################################
