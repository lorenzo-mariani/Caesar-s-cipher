		.data
msg1:			.asciiz "Enter a phrase to be encrypted (max 510 characters and only alphabetic characters):\n"
msg2:			.asciiz	"Indicate how many forward positions each letter must be translated to:\n"
msg_err:		.asciiz "Please use only the characters of the alphabet (a ... Z, A ... Z)!\n"
msg_err2:		.asciiz "Please enter a phrase\n"
msg_err3:		.asciiz	"Please enter a number between 1 and 26!\n"
a_capo:			.asciiz "\n"
accentate:		.byte	0xe0 0xe1 0xe8 0xe9 0xec 0xed 0xf2 0xf3	0xf9 0xfa 0xe0 0xe1 0xe8 0xe9 0xec 0xed 0xf2 0xf3 0xf9 0xfa 0xe0 0xe1 0xe8 0xe9	0xec 0xed
f_acc:
frase:			.space 	512
cifrata:		.space 	512
f_cifrata:

		.text

# $s0 pointer for loading data
# $s1 contains the first address where data can be written
# $s2 contains in number of forward movements that must be done for each letter
# $t0 used for loading characters
# $t8 contains the end address of the encrypted string
# $v1 used to report whether the character is lowercase (0) or uppercase (1)

start:			li $v0, 4					
			la $a0, msg1
			syscall
			li $v0, 8
			li $a1, 512
			la $a0, frase
			syscall
			lbu $t0, 0 ($a0)
			bne $t0, 0x0a, continue
			li $v0, 4
			la $a0, msg_err2
			syscall
			j reset
			
continue:		li $v0, 4
			la $a0, msg2
			syscall
			li $v0, 5
			syscall
			ble $v0, $zero, s_error
			bgt $v0, 26, s_error
			move $s2, $v0
			la $s0, frase
			la $s1, cifrata

cesare:			lbu $t0, 0 ($s0)			
			beq $t0, 0x0a, print
			beq $t0, 0x27, space
			beq $t0, 0x20, space
			move $a0, $t0
			jal accentate_c
			jal uptodown
			jal check
			move $t0, $a0
			li $t1, 0x7a
			subu $t1, $t1, $s2
			addiu $t1, $t1, 1
			blt $t0, $t1, stnd
			addiu $t0, $t0, -26
stnd:			addu $t0, $t0, $s2
			beq $v1, $zero, space
			move $a0, $t0
			jal downtoup
rit_acc:		move $t0, $a0
space:			sb $t0, 0 ($s1) 
			addiu $s0, $s0, 1
			addiu $s1, $s1, 1
			j cesare

check:			blt $a0, 0x61, error
			bgt $a0, 0x7a, error
			j $ra

uptodown:		move $v1, $zero
			blt $a0, 0x41, no_utd
			bgt $a0, 0x5a, no_utd
			addiu $a0, $a0, 32
			li $v1, 1
no_utd:			j $ra

downtoup:		addiu $a0, $a0, -32
			j $ra
		
print:			li $v0, 4
			la $a0, cifrata
			syscall
			la $a0, a_capo
			syscall
			j reset

error:			li $v0, 4
			la $a0, msg_err
			syscall
			j reset

s_error:		li $v0, 4
			la $a0, msg_err3
			syscall
			j reset
			
reset:			la $s0, frase
			la $s1, cifrata
ciclo_r_f:		sb $zero, 0 ($s0)
			addiu $s0, $s0, 1
			blt $s0, $s1, ciclo_r_f
			
			la $s1, cifrata
			la $t8, f_cifrata
ciclo_r_c:		sb $zero, 0 ($s1)
			addiu $s1, $s1, 1
			blt $s1, $t8, ciclo_r_c
			j start
			
accentate_c:		la $t7, accentate
			la $t6, f_acc
ciclo_acc:		lbu $t1, 0 ($t7)
			addiu $t2, $t1, -32
			beq $a0, $t1, trasla_acc
			beq $a0, $t2, tras_acc_m
			addiu $t7, $t7, 1
			beq $t7, $t6, exit_acc
			j ciclo_acc
exit_acc:		jal $ra

tras_acc_m:		addiu $a0, $t1, 32
			addiu $v1, $v1, 1
			j trasla_acc

trasla_acc:		addu $t7, $t7, $s2
			bgt $t7, $t6, st_acc
ret:			lbu $a0, 0 ($t7)
			bne $v0, $zero, rit_acc
			addu $a0, $a0, -32
			j rit_acc

st_acc:			subu $t6, $t6, $s2
			addiu $t6, $t6, 1
			blt $t7, $t6, stnd_2
			la $t7, accentate
stnd_2:			j ret