.data

msg_plaintext:  .asciiz "Enter the plaintext message to be encrypted (max 510 characters and only alphabetic characters):\n"
msg_key:        .asciiz	"Indicate how many forward positions each letter must be moved:\n"

err_plaintext:  .asciiz "Error! You must use only the alphabetic characters (a ... Z, A ... Z)!\n"
err_empty:      .asciiz "Error! You must enter a plaintext message\n"
err_key:        .asciiz	"Error! You must enter a number between 1 and 26!\n"

newline:        .asciiz "\n"

accent:         .byte	0xe0 0xe1 0xe8 0xe9 0xec 0xed 0xf2 0xf3	0xf9 0xfa 0xe0 0xe1 0xe8 0xe9 0xec 0xed 0xf2 0xf3 0xf9 0xfa 0xe0 0xe1 0xe8 0xe9	0xec 0xed
f_acc:
plaintext:      .space 	512
ciphertext:     .space 	512
f_ciphertext:

.text

# ask the user for the plaintext message
set_plaintext:
    li $v0, 4					
    la $a0, msg_plaintext
    syscall
    li $v0, 8
    li $a1, 512
    la $a0, plaintext
    syscall
    lbu $t0, 0($a0)
    bne $t0, 0x0a, set_key
    li $v0, 4
    la $a0, err_empty
    syscall
    j init_to_reset

# ask the user for the key
set_key:	
    li $v0, 4
    la $a0, msg_key
    syscall
    li $v0, 5
    syscall
    ble $v0, $zero, print_err_key
    bgt $v0, 26, print_err_key
    move $s2, $v0
    la $s0, plaintext
    la $s1, ciphertext

# do the encryption
encryption:		
    lbu $t0, 0($s0)			
    beq $t0, 0x0a, print_ciphertext
    beq $t0, 0x27, store_ciphertext_char
    beq $t0, 0x20, store_ciphertext_char
    move $a0, $t0
    jal init_to_check_accent
    jal from_upper_to_lower
    jal check_plaintext_char
    move $t0, $a0
    li $t1, 0x7a
    subu $t1, $t1, $s2
    addiu $t1, $t1, 1
    blt $t0, $t1, move_character
    addiu $t0, $t0, -26

# move character based on the key value
move_character:
    addu $t0, $t0, $s2
    beq $v1, $zero, store_ciphertext_char
    move $a0, $t0
    jal from_lower_to_upper

# return after working on accents
return_from_accent:
    move $t0, $a0

# store the encrypted character into the ciphertext
store_ciphertext_char:
    sb $t0, 0($s1) 
    addiu $s0, $s0, 1
    addiu $s1, $s1, 1
    j encryption

# check if the current character of the plaintext is valid
check_plaintext_char:
    blt $a0, 0x61, print_err_plaintext
    bgt $a0, 0x7a, print_err_plaintext
    j $ra

# convert a character from uppercase to lowercase
from_upper_to_lower:
    move $v1, $zero
    blt $a0, 0x41, return
    bgt $a0, 0x5a, return
    addiu $a0, $a0, 32
    li $v1, 1

# return to $ra
return:
    j $ra

# convert a character from lowercase to uppercase
from_lower_to_upper:
    addiu $a0, $a0, -32
	j $ra

# print ciphertext
print_ciphertext:
    li $v0, 4
    la $a0, ciphertext
    syscall
    la $a0, newline
    syscall
    j init_to_reset

# print an error message when an invalid plaintext is entered
print_err_plaintext:
    li $v0, 4
    la $a0, err_plaintext
    syscall
    j init_to_reset

# print an error message when an invalid key is entered
print_err_key:
    li $v0, 4
    la $a0, err_key
    syscall
    j init_to_reset

# initialize the regiters to start resetting plaintext and ciphertext
init_to_reset:
    la $s0, plaintext
    la $s1, ciphertext

# reset the plaintext
reset_plaintext:
    sb $zero, 0($s0)
    addiu $s0, $s0, 1
    blt $s0, $s1, reset_plaintext	
    la $s1, ciphertext
    la $t8, f_ciphertext

# reset the ciphertext
reset_ciphertext:
    sb $zero, 0($s1)
    addiu $s1, $s1, 1
    blt $s1, $t8, reset_ciphertext
    j set_plaintext

# initialize the regiters to start checking if the plaintext
# character has an accent
init_to_check_accent:
    la $t7, accent
	la $t6, f_acc

# scan all the possible accented characters to check if the
# current plaintext character is part of them 
check_accent_loop:
    lbu $t1, 0($t7)
    addiu $t2, $t1, -32
    beq $a0, $t1, move_lowercase_accent
    beq $a0, $t2, move_uppercase_accent
    addiu $t7, $t7, 1
    beq $t7, $t6, exit_acccent_loop
    j check_accent_loop

# exit the loop where the accented characters are scanned
exit_acccent_loop:
    jal $ra

# move the uppercase accented character
move_uppercase_accent:
    addiu $a0, $t1, 32
	addiu $v1, $v1, 1

# move the lowercase accented character
move_lowercase_accent:
    addu $t7, $t7, $s2
	bgt $t7, $t6, init_to_store_accent

# initialize registers to prepare to return
init_to_return:
    lbu $a0, 0($t7)
    bne $v0, $zero, return_from_accent
    addu $a0, $a0, -32
    j return_from_accent

# initialize registers to start storing the accented character
init_to_store_accent:
    subu $t6, $t6, $s2
    addiu $t6, $t6, 1
    blt $t7, $t6, init_to_return
    la $t7, accent
    j init_to_return