.data
	mem_stack: .space 1024

.text
.globl main

main:
    li $t0, 255            # índice do topo da pilha (último elemento de mem_stack)

    # Exemplo de PUSH: armazenar valor 42
    li $t1, 42
    la $t2, mem_stack      # endereço base da pilha
    sll $t3, $t0, 2        # $t3 = t0 * 4 (offset em bytes)
    sub $t3, $t2, $t3      # endereço = mem_stack + (t0 * -4)
    sw $t1, 0($t3)         # salva 42 na posição simulada da pilha
    sub $t0, $t0, 1        # "decrementa" ponteiro da pilha