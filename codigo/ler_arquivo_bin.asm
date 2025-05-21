.data
buffer: .space 4096       # Espaço para carregar o binário
mem_text: .space 4096       # Área de memória para instruções
filename: .asciiz "program.bin"
size: .word 0
regs: .space 128   # 32 registradores × 4 bytes

.text
.globl main
main:
    # === Abrir o arquivo binário ===
    li $v0, 13              # syscall: open
    la $a0, filename        # nome do arquivo
    li $a1, 0               # modo leitura (O_RDONLY)
    li $a2, 0               # permissão (não importa aqui)
    syscall
    move $s0, $v0             # salva o file descriptor

    # === Ler o conteúdo ===
    li $v0, 14              # syscall: read
    move $a0, $s0             # file descriptor
    la $a1, buffer          # onde salvar
    li $a2, 4096            # quantos bytes ler
    syscall
    sw $v0, size            # salva o tamanho lido

    # === Fechar o arquivo ===
    li $v0, 16
    move $a0, $s0
    syscall

    # === Copiar para mem_text ===
    li $t0, 0               # i = 0
copy_loop:
    lw $t1, size
    bge $t0, $t1, run_loop   # se i >= size, termina
    lb $t2, buffer($t0)
    sb $t2, mem_text($t0)
    addi $t0, $t0, 1
    j copy_loop

# === LOOP DE EXECUÇÃO ===
run_loop:
    li $t3, 0               # PC (program counter) = 0
exec_loop:
    li   $t0, 0            # PC offset
    la   $t1, mem_text     # base address
    addu $t2, $t1, $t0     # endereço da instrução atual

    # Carrega 4 bytes consecutivos
    lb   $t3, 0($t2)
    lb   $t4, 1($t2)
    lb   $t5, 2($t2)
    lb   $t6, 3($t2)

    # Concatena para formar palavra (big endian)
    sll  $t3, $t3, 24
    sll  $t4, $t4, 16
    sll  $t5, $t5, 8

    or   $t7, $t3, $t4
    or   $t7, $t7, $t5
    or   $t7, $t7, $t6    # $t7 = instrução completa

    # Extrai opcode (bits 31-26)
    srl  $t8, $t7, 26      # $t8 = opcode

    # Exemplo: verifica se é uma instrução R-type (opcode == 0)
    bne  $t8, $zero, next_instr

    # Instrução R-type -> extrai funct (bits 5-0)
    andi $t9, $t7, 0x3F    # $t9 = funct

    # Verificar se é ADD (funct = 0x20)
    li   $s1, 0x20
    bne  $t9, $s1, next_instr

    # Simula ADD: rd = rs + rt
    # extrai rs, rt, rd
    srl  $a0, $t7, 21      # rs
    andi $a0, $a0, 0x1F

    srl  $a1, $t7, 16      # rt
    andi $a1, $a1, 0x1F

    srl  $a2, $t7, 11      # rd
    andi $a2, $a2, 0x1F

    # Acessa os registradores
    la   $s0, regs
    sll  $a0, $a0, 2
    sll  $a1, $a1, 2
    sll  $a2, $a2, 2
    addu $a0, $a0, $s0
    addu $a1, $a1, $s0
    addu $a2, $a2, $s0

    lw   $t0, 0($a0)
    lw   $t1, 0($a1)
    add  $t2, $t0, $t1
    sw   $t2, 0($a2)

next_instr:
    addi $t0, $t0, 4       # PC += 4
    blt  $t0, 4096, exec_loop
    j    exit

exit:
    li $v0, 10
    syscall
