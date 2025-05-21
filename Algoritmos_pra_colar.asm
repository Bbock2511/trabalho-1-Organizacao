#Algoritmo pra inserir algo na pilha(trocar 255 pelo índice e 42 pelo item a ser inserido)
	li $t0, 255            # índice do topo da pilha (último elemento de mem_stack)
	li $t1, 42 
	sll $t3, $t0, 2        # $t3 = t0 * 4 (offset em bytes)
	sub $t3, $s1, $t3      # endereço = mem_stack + (t0 * -4)
	sw $t1, 0($t3)         # salva 42 na posição simulada da pilha
	sub $t0, $t0, 1        # "decrementa" ponteiro da pilha
#---------------------------------------------------------------------------------------