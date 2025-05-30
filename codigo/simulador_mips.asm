.data
ErroInstrucaoR: .asciiz "Falha em ler funct tipo R"
#Nome dos arquivos
nomeArquivoBin: .asciiz "ex-000-073.bin"
nomeArquivoDat: .asciiz "ex-000-073.dat"
#Variaveis de leitura de instrução
PC: .word 0x00400000 #variável que capturará as instruções lidas
IR: .word 0 #endereço será sobrescrito pela instrução capturada por PC
#############################################
#Memória simulada do processador
reg:.space 128 #registradores do mips
mem_text:.space 2048
mem_data:.space 5120 
mem_stack:.space 1024 #Memória para a pilha $sp
#############################################

.text
inicializa:
	jal leArquivoBin
	jal leArquivoDat
	
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
	
	#inicia a execução
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
	
	bne $t2, 31, LoopForReg #volta o label até que $t2 chegue em 31
	
	#Inserindo endereço da pilha no registrador	
	#$t0 = b[29]
	li $t2, 29 #coloca o índice 29 em $t2
	sll $t0, $t2, 2 #transforma em deslocamento 
	add $t0, $t0, $a0 
	
	addi $t1, $a1, 1024 #coloca o endereço final de mem_stack em $t1
	sw $t1, 0($t0) #insere o endereço final de mem_stack em b[29]
#---Epílogo---	
jr $ra
#-------------
#------------------------Fim do Procedimento----------------------------

#----------------Procedimento de Leitura de Arquivo Dat-----------------
#Registradores:
#
#Argumentos: 
#
leArquivoDat:
#---Prólogo---
#Nada para ver aqui.
#-------------
	li $v0, 13 # syscall: open
	la $a0, nomeArquivoDat # nome do arquivo
	li $a1, 0 # modo leitura (O_RDONLY)
	li $a2, 0 # permissão (não importa aqui)
	syscall
	move $t0, $v0 # salva o file descriptor
	
	li $v0, 14 # syscall: read
	move $a0, $t0 # file descriptor
	la $a1, mem_data # onde salvar
	li $a2, 5120 # quantos bytes ler
	syscall
	
	 #Fecha o arquivo
	li $v0, 16
	move $a0, $t0
	syscall
#---Epílogo---
jr $ra
#-------------
#------------------------Fim do Procedimento----------------------------

#----------------Procedimento de Leitura de Arquivo Bin-----------------
#Registradores:
#
#Argumentos: 
#
leArquivoBin:
#---Prólogo---
#Nada para ver aqui.
#-------------
	li $v0, 13 # syscall: open
	la $a0, nomeArquivoBin # nome do arquivo
	li $a1, 0 # modo leitura (O_RDONLY)
	li $a2, 0 # permissão (não importa aqui)
	syscall
	move $t0, $v0 # salva o file descriptor
	
	li $v0, 14 # syscall: read
	move $a0, $t0 # file descriptor
	la $a1, mem_text # onde salvar
	li $a2, 5120 # quantos bytes ler
	syscall
	
	beqz $v0, finaliza
	
	 #Fecha o arquivo
	li $v0, 16
	move $a0, $t0
	syscall
	
	
#---Epílogo---
jr $ra
#-------------
#------------------------Fim do Procedimento----------------------------

#--------------------Procedimento de Busca de Instrução-----------------
#Argumentos
#$a0 <- endereço de PC
#$a1 <- endereço de IR
#$a2 <- endereço de mem_text
#Registradores
#$s0 <- endereço de PC
#$s1 -> endereço de IR
#$s2 <- endereço de mem_text
#$s3 -> palavra de PC
busca:
#---Prólogo---
addi $sp, $sp, -4
sw $ra, 0($sp)

move $s0, $a0
move $s1, $a1
move $s2, $a2
#-------------
	lw $s3, 0($s0) #pega a palavra em PC
	li $t1, 0x00400000
	sub $t0, $s3, $t1 #subtrai o endereço base do endereço da próxima instrução para encontrar o offset necessário para pegar a instrução de mem_text
	add $t0, $t0, $s2 #soma o offset 
	
	lw $t1, 0($t0) #tira a instrução do endereço correspondente de mem_text
	sw $t1, 0($s1) #coloca a instrução em IR(instrução a ser executada)
	
	#decode(IR)
	move $a0, $s1 #coloca o endereço de IR em a0
	jal decode
	lw $s3, 0($s0) #pega o possivelmente novo endereço após a execução de decode
	
	#passa para o próximo endereço
	addi $s3, $s3, 4 
	sw $s3, 0($s0) 
	
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
addi $sp, $sp, -20
sw $ra, 0($sp) #guarda endereço de retorno
sw $s0, 4($sp) #armazena $s0 da função anterior
sw $s1, 8($sp) #armazena $s1 da função anterior
sw $s2, 12($sp)

move $t0, $a0 
#-------------
	lw $t0, 0($t0)
	beqz $t0, terminaDecodificacao #finaliza a decodificação caso a instrução seja nula
	
	srl $t1, $t0, 26 #desloca todos os bits para direita até que reste apenas o opcode
	
	#verifica se é uma instrução tipo R
	beq $zero, $t1, opcodeR
	#---------------------------------
	#verifica se é uma instrução tipo J
	li $t2, 0x02 
	beq $t1, $t2, opcodeJ
	li $t2, 0x03
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
		# $t0 já contém o campo target (26 bits)
		sll $t0, $t0, 2 #transforma os 26 bits em 28(endereço válido)
		
		#salta para a execução de j
		li $t2, 0x02 
		beq $t1, $t2, j
		#salta para a execução de jal
		li $t2, 0x03
		beq $t1, $t2, jal
		
		j:
		#executa_j(address)
		move $a0, $t0
		jal executa_j
		j terminaDecodificacao
		
		jal:
		#executa_jal(address)
		move $a0, $t0
		jal executa_jal
		j terminaDecodificacao
	
	#decodifica tipo I
	opcodeI:
		#I_decode(conteudo_IR)
		move $a0, $t0
		jal I_decode
		j terminaDecodificacao
		
terminaDecodificacao:
#---Epílogo---
lw $ra, 0($sp)
lw $s0, 4($sp)
lw $s1, 8($sp)
lw $s2, 12($sp)
addi $sp, $sp, 20

jr $ra
#-------------
#------------------------Fim do Procedimento-----------------------------

#------------Procedimendo de Decodificação tipo I-----------------
#Registradores:
#$s0 -> Instrução a ser decodificada
#
#Argumentos: 
#$a0 -> Instrução que está em IR
I_decode:
#---Prólogo---
addi $sp, $sp, -4
sw $ra, 0($sp)

move $s0, $a0
#-------------
	srl $t1, $s0, 26 #extrai o opcode deslocando todos os bits para a direita excetos os do opcode
	
	andi $a0, $s0, 0xffff #utiliza o número 0xffff para zerar os bits exceto aqueles do valor imediato e insere como primeiro argumento do procedimento a ser chamado
	
	andi $a1, $s0, 0x1f0000 #utiliza o número 0x1f0000 para zerar os bits exceto aqueles do rt e insere como terceiro argumento do procedimento a ser chamado
	srl $a1, $a1, 16
	
	andi $a2, $s0, 0x03e00000 #utiliza o número 0x03e00000 para zerar os bits exceto aqueles do rs e insere como segundo argumento do procedimento a ser chamado
	srl $a2, $a2, 21
	
	#verifica qual a instrução pelo opcode e salta para sua execução
	li $t2, 0x04
	beq $t1, $t2, I_beq
	
	li $t2, 0x05
	beq $t1, $t2, I_bne
		
	li $t2, 0x09
	beq $t1, $t2, I_addiu
		
	li $t2, 0x0d
	beq $t1, $t2,I_ori
		
	li $t2, 0x0f
	beq $t1, $t2, I_lui
		
	li $t2, 0x23
	beq $t1, $t2, I_lw
		
	li $t2, 0x2b
	beq $t1, $t2, I_sw
		
	li $t2, 0x28
	beq $t1, $t2, I_sb
		
	li $t2, 0x24
	beq $t1, $t2, I_lbu
		
	I_beq:
		#executa_beq(Immediate, rt, rs)
		jal executa_beq
		j terminaDecodeI
	I_bne:
		#executa_bne(Immediate, rt, rs)
		jal executa_bne
		j terminaDecodeI
	I_addiu:
		#executa_addiu(Immediate, rt, rs)
		jal executa_addiu
		j terminaDecodeI
	I_ori:
		#executa_ori(Immediate, rt, rs)
		jal executa_ori
		j terminaDecodeI
	I_lui:
		#executa_lui(Immediate, rt, rs)
		jal executa_lui
		j terminaDecodeI
	I_lw:
		#executa_lw(Immediate, rt, rs)
		jal executa_lw
		j terminaDecodeI
	I_sw:
		#executa_sw(Immediate, rt, rs)
		jal executa_sw
		j terminaDecodeI
	I_sb:
		#executa_sb(Immediate, rt, rs)
		jal executa_sb
		j terminaDecodeI
	I_lbu:
		jal executa_lbu
		j terminaDecodeI

terminaDecodeI:
#---Epílogo---
lw $ra, 0($sp)
addi $sp, $sp, 4
jr $ra
#-------------
#------------------------Fim do Procedimento------------------------------

#------------Procedimendo de Decodificação tipo R-----------------
#Registradores:
#$s0 -> Instrução a ser decodificada
#
#Argumentos: 
#$a0 -> Instrução que está em IR
R_decode:
#---Prólogo---
addi $sp, $sp, -4
sw $ra, 0($sp)

move $s0, $a0
#-------------
	andi $t0, $s0, 0x3f #usa o número 3f para zerar todos os bits após os 6 primeiros
	
	#decodifica os dados
	andi $t1, $s0, 0x7c0 #usa o número 7c0 para zerar todos os bits, exceto os de shamt(bits que serão deslocados)
	srl $t1, $t1, 6
	andi $t2, $s0, 0xf800 #usa o número f800 para zerar todos os bits, exceto os de rd(numero do registrador que receberá o resultado)
	srl $t2, $t2, 11
	andi $t3, $s0, 0x1f0000 #usa o número 1f0000 para zerar todos os bits, exceto os de rt(numero do registrador que sofrerá a operação)
	srl $t3, $t3, 16
	andi $t4, $s0, 0x03e00000 #usa o número 03e00000 para zerar todos os bits, exceto os de rs(numero do registrador fonte da operação)
	srl $t4, $t4, 21
	
	#Verifica qual a instrução correspondente ao funct
	beq $t0, $zero, sll
	beq $t0, 0x02, srl
	beq $t0, 0x08, jr
	beq $t0, 0xc, syscall
	beq $t0, 0x20, add
	beq $t0, 0x21, addu
	beq $t0, 0x22, sub
	beq $t0, 0x23, subu
	beq $t0, 0x24, and
	beq $t0, 0x25, or
	
	li $v0, 4
	la $a0, ErroInstrucaoR
	syscall
	j finaliza
	
	sll:	
		#executa_sll(shamt, rd, rt)
		move $a0, $t1
		move $a1, $t2
		move $a2, $t3
		jal executa_sll
		j terminaDecodeR
		
	srl:
		#executa_srl(shamt, rt, rs)
		move $a0, $t1
		move $a1, $t2
		move $a2, $t3
		jal executa_srl
		j terminaDecodeR
		
	jr: 
		#executa_jr(rs)
		move $a0, $t4
		jal executa_jr
		j terminaDecodeR
	
	syscall:
		#executa_syscall
		jal executa_syscall
		j terminaDecodeR
		
	add:
		#executa_add(rd, rt, rs)
		move $a0, $t2
		move $a1, $t3
		move $a2, $t4
		jal executa_add
		j terminaDecodeR
		
	addu:
		#executa_add(rd, rt, rs)
		move $a0, $t2
		move $a1, $t3
		move $a2, $t4
		jal executa_addu
		j terminaDecodeR
		
	sub:
		#executa_sub(rd, rt, rs)
		move $a0, $t2
		move $a1, $t3
		move $a2, $t4
		jal executa_sub
		j terminaDecodeR
		
	subu:
		#executa_subu(rd, rt, rs)
		move $a0, $t2
		move $a1, $t3
		move $a2, $t4
		jal executa_subu
		j terminaDecodeR
	and:
		#executa_and(rd, rt, rs)
		move $a0, $t2
		move $a1, $t3
		move $a2, $t4
		jal executa_and
		j terminaDecodeR
		
	or:
		#executa_or(rd, rt, rs)
		move $a0, $t2
		move $a1, $t3
		move $a2, $t4
		jal executa_or
		j terminaDecodeR
	
terminaDecodeR:
#---Epílogo---
lw $ra, 0($sp)
addi $sp, $sp, 4
jr $ra
#-------------
#------------------------Fim do Procedimento------------------------------

#-----------------Procedimento de Execução de lbu-------------------------
#Registradores:
#$s0 -> Valor imediato da operação
#$s1 -> Indice de rt(registrador destino)
#$s2 -> Indice de rs(registrador operador)
#$s3 -> Endereço do vetor de registradores simulados
#
#Argumentos:
#$a0 -> Valor imediato da operação
#$a1 -> Indice de rt(registrador destino ou segundo operador)
#$a2 -> Indice de rs(registrador operador)
executa_lbu:
#---Prólogo---
addi $sp, $sp, -4
sw $ra, 0($sp)

move $s0, $a0
move $s1, $a1
move $s2, $a2
#------------
	la $t0, reg
	la $t1, mem_data
	
	#pegando o conteudo do registrador rs
	sll $t2, $s2, 2
	add $t2, $t2, $t0
	lw $t2, 0($t2)
	
	#pegando o endereço do registrador rt
	sll $t3, $s1, 2
	add $t3, $t3, $t0
	
	#soma o offset(valor imediato) ao endereço contido no registrador rs
	add $t2, $t2, $s0
	
	#subtrai o endereço base de mem_data do endereço adquirido do registrador rs a fim de descobrir o deslocamento para alcançar o endereço correto em mem_data
	li $t4, 0x10010000
	sub $t2, $t2, $t4
	
	#adiciona o offset
	add $t2, $t2, $t1
	lbu $t4, 0($t2) 
	
	#coloca o conteudo no registrador rt(destino)
	sw $t4, 0($t3)

terminaExecucaoLbu:
#---Epílogo---
lw $ra, 0($sp)
addi $sp, $sp, 4
jr $ra
#-------------
#------------------------Fim do Procedimento------------------------------


#-----------------Procedimento de Execução de sb-------------------------
#Registradores:
#$s0 -> Valor imediato da operação
#$s1 -> Indice de rt(registrador destino)
#$s2 -> Indice de rs(registrador operador)
#$s3 -> Endereço do vetor de registradores simulados
#
#Argumentos:
#$a0 -> Valor imediato da operação
#$a1 -> Indice de rt(registrador destino ou segundo operador)
#$a2 -> Indice de rs(registrador operador)
executa_sb:
#---Prólogo---
addi $sp, $sp, -4
sw $ra, 0($sp)

move $s0, $a0
move $s1, $a1
move $s2, $a2
#------------
	la $t0, reg
	la $t1, mem_data
	
	#pegando o conteudo do registrador rs
	sll $t2, $s2, 2
	add $t2, $t2, $t0
	lw $t2, 0($t2)
	
	#pegando o endereço do registrador rt
	sll $t3, $s1, 2
	add $t3, $t3, $t0
	
	#soma o offset(valor imediato) ao endereço contido no registrador rs
	add $t2, $t2, $s0
	
	#subtrai o endereço base de mem_data do endereço adquirido do registrador rs a fim de descobrir o deslocamento para alcançar o endereço correto em mem_data
	li $t4, 0x10010000
	sub $t2, $t2, $t4
	
	#adiciona o offset para percorrer mem_data
	add $t2, $t2, $t1
	
	#pega o conteúdo de rt
	lb $t3, 0($t3)
	sb $t3, 0($t2)

terminaExecucaoSb:
#---Epílogo---
lw $ra, 0($sp)
addi $sp, $sp, 4
jr $ra
#-------------
#------------------------Fim do Procedimento------------------------------

#-----------------Procedimento de Execução de sw-------------------------
#Registradores:
#$s0 -> Valor imediato da operação
#$s1 -> Indice de rt(registrador destino)
#$s2 -> Indice de rs(registrador operador)
#$s3 -> Endereço do vetor de registradores simulados
#
#Argumentos:
#$a0 -> Valor imediato da operação
#$a1 -> Indice de rt(registrador destino ou segundo operador)
#$a2 -> Indice de rs(registrador operador)
executa_sw:
#---Prólogo---
addi $sp, $sp, -4
sw $ra, 0($sp)

move $s0, $a0
move $s1, $a1
move $s2, $a2
#------------
	la $t0, reg
	la $t1, mem_data
	
	#pegando o conteudo do registrador rs
	sll $t2, $s2, 2
	add $t2, $t2, $t0
	lw $t2, 0($t2)
	
	#pegando o endereço do registrador rt
	sll $t3, $s1, 2
	add $t3, $t3, $t0
	
	#soma o offset(valor imediato) ao endereço contido no registrador rs
	add $t2, $t2, $s0
	
	#subtrai o endereço base de mem_data do endereço adquirido do registrador rs a fim de descobrir o deslocamento para alcançar o endereço correto em mem_data
	li $t4, 0x10010000
	sub $t2, $t2, $t4
	
	#adiciona o offset para percorrer mem_data
	add $t2, $t2, $t1
	
	#pega o conteúdo de rt
	lw $t3, 0($t3)
	sw $t3, 0($t2)

terminaExecucaoSw:
#---Epílogo---
lw $ra, 0($sp)
addi $sp, $sp, 4
jr $ra
#-------------
#------------------------Fim do Procedimento------------------------------

#-----------------Procedimento de Execução de lw-------------------------
#Registradores:
#$s0 -> Valor imediato da operação
#$s1 -> Indice de rt(registrador destino)
#$s2 -> Indice de rs(registrador operador)
#$s3 -> Endereço do vetor de registradores simulados
#
#Argumentos:
#$a0 -> Valor imediato da operação
#$a1 -> Indice de rt(registrador destino ou segundo operador)
#$a2 -> Indice de rs(registrador operador)
executa_lw:
#---Prólogo---
addi $sp, $sp, -4
sw $ra, 0($sp)

move $s0, $a0
move $s1, $a1
move $s2, $a2
#------------
	la $t0, reg
	la $t1, mem_data
	
	#pegando o conteudo do registrador rs
	sll $t2, $s2, 2
	add $t2, $t2, $t0
	lw $t2, 0($t2)
	
	#pegando o endereço do registrador rt
	sll $t3, $s1, 2
	add $t3, $t3, $t0
	
	#soma o offset(valor imediato) ao endereço contido no registrador rs
	add $t2, $t2, $s0
	
	#subtrai o endereço base de mem_data do endereço adquirido do registrador rs a fim de descobrir o deslocamento para alcançar o endereço correto em mem_data
	li $t4, 0x10010000
	sub $t2, $t2, $t4
	
	#adiciona o offset
	add $t2, $t2, $t1
	lw $t4, 0($t2) 
	
	#coloca o conteudo no registrador rt(destino)
	sw $t4, 0($t3)

terminaExecucaoLw:
#---Epílogo---
lw $ra, 0($sp)
addi $sp, $sp, 4
jr $ra
#-------------
#------------------------Fim do Procedimento------------------------------

#-----------------Procedimento de Execução de lui-------------------------
#Registradores:
#$s0 -> Valor imediato da operação
#$s1 -> Indice de rt(registrador destino)
#$s2 -> Indice de rs(registrador operador)
#$s3 -> Endereço do vetor de registradores simulados
#
#Argumentos:
#$a0 -> Valor imediato da operação
#$a1 -> Indice de rt(registrador destino ou segundo operador)
#$a2 -> Indice de rs(registrador operador)
executa_lui:
#---Prólogo---
addi $sp, $sp, -4
sw $ra, 0($sp)

move $s0, $a0
move $s1, $a1
move $s2, $a2
#------------
	la $t0, reg
	
	#pegando o endereço de rt
	sll $t1, $s1, 2
	add $t1, $t1, $t0
	
	sll $s0, $s0, 16 #desloca o imediato para os bits mais significativos do registrador
	
	sw $s0, 0($t1) #armazena o valor da instrução no registrador ordenado

terminaExecucaoLui:
#---Epílogo---
lw $ra, 0($sp)
addi $sp, $sp, 4
jr $ra
#-------------
#------------------------Fim do Procedimento------------------------------

#-----------------Procedimento de Execução de ori-------------------------
#Registradores:
#$s0 -> Valor imediato da operação
#$s1 -> Indice de rt(registrador destino)
#$s2 -> Indice de rs(registrador operador)
#$s3 -> Endereço do vetor de registradores simulados
#
#Argumentos:
#$a0 -> Valor imediato da operação
#$a1 -> Indice de rt(registrador destino ou segundo operador)
#$a2 -> Indice de rs(registrador operador)
executa_ori:
#---Prólogo---
addi $sp, $sp, -4
sw $ra, 0($sp)

move $s0, $a0
move $s1, $a1
move $s2, $a2
#------------
	la $t0, reg
	
	#pegando o endereço de rs
	sll $t1, $s2, 2
	add $t1, $t1, $t0
	lw $t1, 0($t1) #colocando o conteúdo de reg[rs] em $t1
	
	or $t2, $t1, $s0 #realiza a operação
	
	#pegando o endereço de rt
	sll $t1, $s1, 2
	add $t1, $t1, $t0
	
	sw $t2, 0($t1) #coloca o resultado da operação or em reg[rt]($t1)

terminaExecucaoOri:
#---Epílogo---
lw $ra, 0($sp)
addi $sp, $sp, 4
jr $ra
#-------------
#------------------------Fim do Procedimento------------------------------

#-----------------Procedimento de Execução de addiu--------------------------
#Registradores:
#$s0 -> Valor imediato da operação
#$s1 -> Indice de rt(registrador destino)
#$s2 -> Indice de rs(registrador operador)
#$s3 -> Endereço do vetor de registradores simulados
#
#Argumentos:
#$a0 -> Valor imediato da operação
#$a1 -> Indice de rt(registrador destino ou segundo operador)
#$a2 -> Indice de rs(registrador operador)
executa_addiu:
#---Prólogo---
addi $sp, $sp, -4
sw $ra, 0($sp)

move $s0, $a0
move $s1, $a1
move $s2, $a2
#------------
	la $t0, reg

	# Extensão de sinal do imediato (16 bits para 32 bits)
	andi $t1, $s0, 0x8000           # Pega o bit mais significativo (bit 15) do imediato
	beq $t1, $zero, imediato_positivo_addiu # Se o bit 15 é 0, o imediato é positivo

	ori $s0, $s0, 0xffff0000        # Se o bit 15 é 1, estende o sinal preenchendo os bits superiores com 1s

imediato_positivo_addiu:	# Label renomeado para maior clareza
	
	# Carrega o VALOR de rs em $t2
	sll $t1, $s2, 2 #Trasforma  o índice de $s2 em offset
	add $t1, $t1, $t0 #Soma o offset ao endereço base do vetor de registradores
	lw $t2, 0($t1) #Pega o valor de rs e coloca em $t2
	
	addu $t3, $t2, $s0 # $t3 = rs + (imediato_estendido_por_sinal)
	
	# Salva o valor no registrador rt
	
	#$t2 <- endereço de reg[rt]
	sll $t1, $s1, 2 #Transforma o indice de $s1 em offset
	add $t2, $t1, $t0 #Soma o offset ao endereço base do vetor de registradores
	
	sw $t3, 0($t2)

terminaExecucaoAddiu:
#---Epílogo---
lw $ra, 0($sp)
addi $sp, $sp, 4
jr $ra
#-------------
#------------------------Fim do Procedimento------------------------------

#-----------------Procedimento de Execução de bne---------------------------
#Registradores:
#$s0 -> Valor imediato da operação
#$s1 -> Indice de rt(registrador destino)
#$s2 -> Indice de rs(registrador operador)
#$s3 -> Endereço do vetor de registradores simulados
#
#Argumentos:
#$a0 -> Valor imediato da operação
#$a1 -> Indice de rt(registrador destino ou segundo operador)
#$a2 -> Indice de rs(registrador operador)
executa_bne:
#---Prólogo---
addi $sp, $sp, -4
sw $ra, 0($sp)

move $s0, $a0
move $s1, $a1
move $s2, $a2
#-------------
	la $t2, PC #pega o endereço de PC para alterá-lo futuramente
	la $s3, reg
	
	#pegando o valor de rt
	sll $t0, $s1, 2 #transforma o indice em offset
	add $t0, $t0, $s3 # soma o offset ao endereço original
	lw $t0, 0($t0) #coloca o conteúdo do registrador em $t0

	#pegando o valor de rs
	sll $t1, $s2, 2 #transforma o indice em offset
	add $t1, $t1, $s3 # soma o offset ao endereço original
	lw $t1, 0($t1) #coloca o conteúdo do registrador em $t1
	
	beq $t0, $t1, terminaExecucaoBne #caso sejam iguais, não realiza o desvio e finaliza o procedimento
	
	sll $s0, $s0, 2 #desloca o imediato em 2 bits
	lw $t0, 0($t2) #pega a palavra de pc
	add $t0, $t0, $s0 #soma o offset do brach com o pc atual
	sw $t0, 0($t2) #armazena em pc o endereço desviado
	
terminaExecucaoBne:
#---Epílogo---
lw $ra, 0($sp)
addi $sp, $sp, 4
jr $ra
#-------------
#------------------------Fim do Procedimento------------------------------

#-----------------Procedimento de Execução de beq---------------------------
#Registradores:
#$s0 -> Valor imediato da operação
#$s1 -> Indice de rt(registrador destino)
#$s2 -> Indice de rs(registrador operador)
#s3 -> Endereço do vetor de registradores simulados
#
#Argumentos:
#$a0 -> Valor imediato da operação
#$a1 -> Indice de rt(registrador destino ou segundo operador)
#$a2 -> Indice de rs(registrador operador)
executa_beq:
#---Prólogo---
addi $sp, $sp, -4
sw $ra, 0($sp)

move $s0, $a0
move $s1, $a1
move $s2, $a2
#-------------	
	la $t2, PC #pega o endereço de PC para alterá-lo futuramente
	la $s3, reg
	
	#pegando o valor de rt
	sll $t0, $s1, 2 #transforma o indice em offset
	add $t0, $t0, $s3 # soma o offset ao endereço original
	lw $t0, 0($t0) #coloca o conteúdo do registrador em $t0

	#pegando o valor de rs
	sll $t1, $s2, 2 #transforma o indice em offset
	add $t1, $t1, $s3 # soma o offset ao endereço original
	lw $t1, 0($t1) #coloca o conteúdo do registrador em $t1
	
	beq $t0, $t1, realiza_desvio_beq
	
	j terminaExecucaoBeq

realiza_desvio_beq:
	sll $s0, $s0, 2 #desloca o imediato em 2 bits
	lw $t0, 0($t2) #pega a palavra de pc
	add $t0, $t0, $s0 #soma o offset do brach com o pc atual
	sw $t0, 0($t2) #armazena em pc o endereço desviado
    
terminaExecucaoBeq:
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
	
	addi $s0, $s0, -4
	sw $s0, 0($t0)
#---Epílogo---
lw $ra, 0($sp)
lw $s0, 4($sp)
addi $sp, $sp, 8
jr $ra
#-------------
#------------------------Fim do Procedimento------------------------------

#-----------------Procedimento de Execução de jal---------------------------
#Registradores
#$s0 -> endereço para ser pulado
#
#Argumentos
#$a0 -> endereço para ser pulado
executa_jal:
#---Prólogo---
addi $sp, $sp, -8
sw $ra, 0($sp)
sw $s0, 4($sp)

move $s0, $a0
#-------------
	#Pega o endereço de PC
	la $t0, PC
	la $t1, reg
	
	#pega o endereço atual e soma +4 para que a instrução não caia no mesmo lugar da hora do jump
	lw $t2, 0($t0)
	addi $t2, $t2, 4
	
	#colocando o endereço de link no registrador $ra
	sw $t2, 124($t1)
	
	#dá o salto
	addi $s0, $s0, -4 #subtrai 4 do endereço para que o incremento de busca não altere o endereço
	sw $s0, 0($t0)
#---Epílogo---
lw $ra, 0($sp)
lw $s0, 4($sp)
addi $sp, $sp, 8
jr $ra
#-------------
#------------------------Fim do Procedimento------------------------------

#-----------------Procedimento de Execução de Syscall-----------------------
#Registradores
#
#Argumentos
executa_syscall:
#---Prólogo---
addi $sp, $sp, -4
sw $ra, 0($sp)
#-------------
	la $t0, reg
	lw $t1, 8($t0) #pega o conteúdo de $v0
	
	li $t2, 1
	beq $t1, $t2, pInt
	li $t2, 4
	beq $t1, $t2, pStr
	li $t2, 11
	beq $t1, $t2, pChar
	li $t2, 17
	beq $t1, $t2, exit2
	
	pInt:
		lw $t1, 16($t0) #pega o numero a se imprimido de $a0
		lw $v0, 8($t0) #coloca o valor de print int em $v0 
		move $a0, $t1
		syscall
		
		j terminaExecucaoSyscall
	
	pStr:
		lw $t1, 16($t0) #pega o endereço da string de $a0
		subi $t1, $t1, 0x10010000 #transforma o endereço em offset
		
		la $t2, mem_data #pega o endereço da memória simulada
		add $t2, $t2, $t1 #soma o offset ao endereço e encontra a string a ser impressa
		
		move $a0, $t2
		li $v0, 4
		syscall
		
		j terminaExecucaoSyscall
	pChar:
		lw $t1, 16($t0) #pega o caractere a se imprimido de $a0
		lw $v0, 8($t0) #coloca o valor de print char em $v0 
		move $a0, $t1
		syscall
		
		j terminaExecucaoSyscall
	exit2:
		lw $t1, 16($t0) #pega o resultado de finalização
		lw $v0, 8($t0) #coloca o valor de terminação em $v0
		move $a0, $t1
		syscall
		
terminaExecucaoSyscall:
#---Epílogo---
lw $ra, 0($sp)
addi $sp, $sp, 4
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

#-----------------Procedimento de Execução de subu---------------------------
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
executa_subu:
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
	subu $t4, $t3, $t2
	
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

#-----------------Procedimento de Execução de addu---------------------------
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
executa_addu:
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
	addu $t4, $t3, $t2
	
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

#-----------------Procedimento de Execução de jr---------------------------
#Registradores
#$s0 -> Indice de rs
#
#Argumentos
#$a0 -> Indice de rs(registrador com o endereço a ser pulado)
executa_jr:
#---Prólogo---
addi $sp, $sp, -4
sw $ra, 0($sp)

move $s0, $a0
#-------------
	la $t0, reg
	la $t1, PC
	
	#Pegando o endereço armazenado em rs
	sll $t2, $s0, 2 #transforma indice em offset
	add $t2, $t2, $t0 #soma offset
	lw $t2, 0($t2) #pega o endereço
	
	addi $t2, $t2, -4 #reduz o endereço em 4 para que o incremento não pule para o endereço seguinte
	sw $t2, 0($t1)

#---Epílogo---
sw $ra, 0($sp)
addi $sp, $sp, 4
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

#é usado em caso de erro na leitura de funct
finaliza:
###fim do programa###
	li $v0, 10
	syscall
#####################
