.data
# Espaço para 32 registradores (reg[0] até reg[31])
reg:    .space 128     # 32 * 4 bytes
text:   .word 0x20080005   # Exemplo: addi $t0, $zero, 5 (opcode 0x08, rs=0, rt=8, imm=5)
        .word 0x20090003   # addi $t1, $zero, 3
        .word 0x01095020   # add $t2, $t0, $t1 (rs=8, rt=9, rd=10, funct=0x20)
        .word 0x8D2B0000   # lw $t3, 0($t1)
        .word 0x0000000C   # syscall (encerrar)

mem_data: .word 0x000000A3   # dado estático (exemplo de valor na memória)

.text
.globl main
main:
    # Inicializa PC com endereço base do segmento .text
    la $s0, text        # $s0 = PC

loop:
    lw $t0, 0($s0)      # Carrega próxima instrução
    addi $s0, $s0, 4    # Incrementa PC

    # Salva a instrução em IR (poderia ser variável específica)
    move $t1, $t0

    # Extrai opcode (bits 31–26)
    srl $t2, $t0, 26
    li $t3, 0x00        # opcode 0 para R-type
    beq $t2, $t3, tipoR

    li $t3, 0x08        # opcode para addi
    beq $t2, $t3, addi_instr

    li $t3, 0x23        # opcode para lw
    beq $t2, $t3, lw_instr

    li $t3, 0x0C        # syscall
    beq $t0, $t3, exit

    j loop

# ----------------------------
# add rd, rs, rt
tipoR:
    # Extrai funct (bits 5–0)
    andi $t4, $t0, 0x3F
    li $t5, 0x20        # funct == 32 (add)
    beq $t4, $t5, add_instr
    j loop

# ----------------------------
# add rd, rs, rt
add_instr:
    srl $t6, $t0, 21        # rs
    andi $t6, $t6, 0x1F
    srl $t7, $t0, 16        # rt
    andi $t7, $t7, 0x1F
    srl $t8, $t0, 11        # rd
    andi $t8, $t8, 0x1F

    la $t9, reg             # base reg[]

    mul $t6, $t6, 4         # rs offset
    mul $t7, $t7, 4         # rt offset
    mul $t8, $t8, 4         # rd offset

    addu $s0, $t9, $t6      # endereço reg[rs]
    lw $a0, 0($s0)

    addu $s1, $t9, $t7      # endereço reg[rt]
    lw $a1, 0($s1)

    add $a2, $a0, $a1       # soma

    addu $s2, $t9, $t8      # endereço reg[rd]
    sw $a2, 0($s2)

    j loop

# ----------------------------
# addi rt, rs, imm
addi_instr:
    srl $t6, $t0, 21        # rs
    andi $t6, $t6, 0x1F
    srl $t7, $t0, 16        # rt
    andi $t7, $t7, 0x1F
    andi $t8, $t0, 0xFFFF   # imm (pode precisar sign-extend)

    la $t9, reg
    mul $t6, $t6, 4
    mul $t7, $t7, 4

    addu $s0, $t9, $t6
    lw $a0, 0($s0)          # reg[rs]

    addi $a2, $a0, 5        # usar $t8 no lugar de 5 se for usar valor real

    addu $s1, $t9, $t7
    sw $a2, 0($s1)

    j loop

# ----------------------------
# lw rt, offset(rs)
lw_instr:
    srl $t6, $t0, 21        # rs
    andi $t6, $t6, 0x1F
    srl $t7, $t0, 16        # rt
    andi $t7, $t7, 0x1F
    andi $t8, $t0, 0xFFFF   # offset (pode precisar sign-extend)

    la $t9, reg
    mul $t6, $t6, 4
    mul $t7, $t7, 4

    addu $s0, $t9, $t6
    lw $a0, 0($s0)          # reg[rs] → endereço base

    la $s1, mem_data
    add $s1, $s1, $t8       # endereço da memória: mem_data + offset

    lw $a2, 0($s1)          # valor da memória

    addu $s2, $t9, $t7
    sw $a2, 0($s2)          # armazena em reg[rt]

    j loop
# ----------------------------

sw_instr:
    srl $t6, $t0, 21        # rs
    andi $t6, $t6, 0x1F
    srl $t7, $t0, 16        # rt
    andi $t7, $t7, 0x1F
    andi $t8, $t0, 0xFFFF   # offset

    la $t9, reg
    mul $t6, $t6, 4         # rs offset
    mul $t7, $t7, 4         # rt offset

    addu $s0, $t9, $t6
    lw $a0, 0($s0)          # reg[rs] → endereço base

    addu $s1, $t9, $t7
    lw $a1, 0($s1)          # valor de reg[rt]

    la $s2, mem_data
    add $s2, $s2, $t8       # mem_data + offset
    sw $a1, 0($s2)

    j loop

beq_instr:
    srl $t6, $t0, 21
    andi $t6, $t6, 0x1F
    srl $t7, $t0, 16
    andi $t7, $t7, 0x1F
    andi $t8, $t0, 0xFFFF   # offset

    la $t9, reg
    mul $t6, $t6, 4
    mul $t7, $t7, 4

    addu $s0, $t9, $t6
    lw $a0, 0($s0)

    addu $s1, $t9, $t7
    lw $a1, 0($s1)

    bne $a0, $a1, beq_skip
    sll $t8, $t8, 2         # offset em bytes
    sub $s0, $s0, $s0       # limpa $s0
    lw $s0, PC
    add $s0, $s0, $t8
    sw $s0, PC

beq_skip:
    j loop

bne_instr:
    srl $t6, $t0, 21
    andi $t6, $t6, 0x1F
    srl $t7, $t0, 16
    andi $t7, $t7, 0x1F
    andi $t8, $t0, 0xFFFF   # offset

    la $t9, reg
    mul $t6, $t6, 4
    mul $t7, $t7, 4

    addu $s0, $t9, $t6
    lw $a0, 0($s0)

    addu $s1, $t9, $t7
    lw $a1, 0($s1)

    beq $a0, $a1, bne_skip
    sll $t8, $t8, 2         # offset em bytes
    lw $s0, PC
    add $s0, $s0, $t8
    sw $s0, PC

bne_skip:
    j loop

j_instr:
    andi $t8, $t0, 0x03FFFFFF  # extrai os 26 bits
    sll $t8, $t8, 2            # shift left 2
    li $t9, 0x00400000         # base do PC

    or $t8, $t8, $t9           # endereço absoluto = base | target
    sw $t8, PC

    j loop

sll_instr:
    srl $t7, $t0, 16        # rt
    andi $t7, $t7, 0x1F
    srl $t8, $t0, 11        # rd
    andi $t8, $t8, 0x1F
    srl $t6, $t0, 6         # shamt
    andi $t6, $t6, 0x1F

    la $t9, reg
    mul $t7, $t7, 4
    mul $t8, $t8, 4

    addu $s0, $t9, $t7
    lw $a0, 0($s0)

    sll $a1, $a0, $t6

    addu $s1, $t9, $t8
    sw $a1, 0($s1)

    j loop

srl_instr:
    srl $t7, $t0, 16        # rt
    andi $t7, $t7, 0x1F
    srl $t8, $t0, 11        # rd
    andi $t8, $t8, 0x1F
    srl $t6, $t0, 6         # shamt
    andi $t6, $t6, 0x1F

    la $t9, reg
    mul $t7, $t7, 4
    mul $t8, $t8, 4

    addu $s0, $t9, $t7
    lw $a0, 0($s0)

    srl $a1, $a0, $t6

    addu $s1, $t9, $t8
    sw $a1, 0($s1)

    j loop



# Encerramento
exit:
    li $v0, 10
    syscall
