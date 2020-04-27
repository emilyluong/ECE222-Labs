##################################################
## Name:   	Lab2.s			  	##
## Purpose:	Morse Code Transmitter		##
## Author:	Emily & Siddharth 		##
##################################################

# Start of the data section
.data			
.align 4	# To make sure we start with 4 bytes aligned address (Not important for this one)

InputLUT:						
	# Use the following line only with the board
	.ascii "SOS"		# Put the 5 Letters here instead of ABCDE
	
	# Note: the memory is initialized to zero so as long as there are not 4*n characters there will be at least one zero (NULL) after the last character
	

.align 4	# To make sure we start with 4 bytes aligned address (This one is Important)
MorseLUT:
	.word 0xE800	# A
	.word 0xAB80	# B
	.word 0xBAE0	# C
	.word 0xAE00	# D
	.word 0x8000	# E
	.word 0xBA80	# F
	.word 0xBB80	# G
	.word 0xAA00	# H
	.word 0xA000	# I
	.word 0xEEE8	# J
	.word 0xEB80	# K
	.word 0xAE80	# L
	.word 0xEE00	# M
	.word 0xB800	# N
	.word 0xEEE0	# O
	.word 0xBBA0	# P
	.word 0xEBB8	# Q
	.word 0xBA00	# R
	.word 0xA800	# S
	.word 0xE000	# T
	.word 0xEA00	# U
	.word 0xEA80	# V
	.word 0xEE80	# W
	.word 0xEAE0	# X
	.word 0xEEB8	# Y
	.word 0xAEE0	# Z



# The main function must be initialized in that manner in order to compile properly on the board
.text
.globl	main
main:
	li s1, 0x7ff60000 				# assigns s1 with the LED base address (Could be replaced with lui s1, 0x7ff60)
	li s2, 0x01					# assigns s2 with the value 1 to turn on LEDs
	la s3, InputLUT					# assigns s3 with the InputLUT base address
	la s4, MorseLUT					# assigns s4 with the MorseLUT base address
	li t4, 1					# stores 1 into t4
	sw zero, 0(s1)					# Turn the LED off
	

	ResetLUT:
		mv s5, s3				# assigns s5 to the address of the first byte  in the InputLUT
				
	NextChar:	
		jal LED_OFF

		#delay 3 spaces between characters
		li a1, 3
		jal DELAY
		li s7, 16				# stores 16 into s7 to keep track of each character, which has 16 bits

		lbu a0, 0(s5)				# loads one byte from the InputLUT
		addi s5, s5, 1				# increases the index for the InputLUT (For future loads)
		bne a0, zero, ProcessChar		# if char is not NULL, jumps to ProcessChar
		
		# If we reached the end of the 5 letters, we start again
		li a1, 4 				# delay 4 extra spaces (7 total) between words to terminate
		jal DELAY				
		j ResetLUT				# start again

	ProcessChar:
		jal CHAR2MORSE				# convert ASCII to Morse pattern in a0	

	RemoveZeros:
		# removes trailling zeroes until you reach a one
		shift:
			srli t0, t0, 1			#shift Morse Pattern (t0) right by 1
			addi s7, s7, -1			#decrement bits in character
			and t2, t0, t4			#use and operation with t4 and t0 
			beq t2, t4, exit1		#if the and operation results in a 1, then that means that the least significant bit is 1
			j shift				#otherwise, if the operation results in a 0, then jump back to shift label
		exit1:
		
	Shift_and_display:
		# peels off one bit at a time and turn the light on or off as necessary
		andi t3, t0, 1				#and operation on the Morse Pattern with 1 
		beq t3, t4, LON 			#check if result is equal to 1, if it is, go to LON label

		shift_and:
			srli t0, t0, 1			#shift right by 1
			and t3, t0, t4			#and operation of Morse pattern with 1 

			addi s7, s7, -1			#decrement bits in character
			beq s7, zero, next_c		#checks if the character has any more bits, that is that all the bits have been shifted, if not, go to next label
			beq t3, t4, LON 		#check if result is equal to 1, if it is, go to LON label
			beq t3, zero, LOFF		#if result is equal to 0, go to LOFF label

		LON:
			jal LED_ON
			li a1, 1
			jal DELAY
			j shift_and

		LOFF:
			jal LED_OFF
			li a1, 1
			jal DELAY
			j shift_and
		
		# If we're done then branch back to get the next characters
		next_c:
			j NextChar		

# End of main function		
		

# Subroutines
LED_OFF:
	# turn LED off
	li s2, 0  
	sw s2, 0(s1) 

	jr ra
	
	
LED_ON:
	# turn LED on
	li s2, 1
	sw s2, 0(s1) 

	jr ra


DELAY:
	# delay 500ms
	li s6, 4166667
	mul t5, s6, a1

	counter:
        	addi t5, t5, -1
		beq t5, zero, exit2
		j counter
	exit2:
		jr ra


CHAR2MORSE:
	# convert the ASCII code to an index and lookup the Morse pattern in the Lookup Table
	addi t1, a0, -0x41				#adds a0 (ASCII value) to -0x41 to get index of character in LUT and stores in t1
	slli t1, t1, 2					#shift left by 2, which acts as a multipying the index by 4 to get the offset without the MorseLUT address
	add t0, t1, s4					#adds the byte addressable index with the MorseLUT address to get the actual offset
	lhu t0, 0(t0)					#loads actual offset of character location from base address (half word unsignned) into t0
	
	jr ra
