##################################################
## Name:    Lab3.s  							##
## Purpose:	Reaction Time Measurement	 		##
## Author:	Emily & Siddharth  					##
##################################################

# Start of the data section
.data			
.align 4						# To make sure we start with 4 bytes aligned address (Not important for this one)
SEED:
	.word 0x1234				# Put any non zero seed
	
# The main function must be initialized in that manner in order to compile properly on the board
.text
.globl	main
main:
	# Put your initializations here
	li s1, 0x7ff60000 					# assigns s1 with the LED base address (Could be replaced with lui s1, 0x7ff60)
	li s2, 0x7ff70000 					# assigns s2 with the push buttons base address (Could be replaced with lui s2, 0x7ff70)
	li s3, 0x341 						# (25 000 000/3)/10000 = 833 = 0x341 --> 0.1 ms
	li s4, 100000 						# store max delay
	li s5, 20000 						# store min delay
	li s6, 0x1							# loads value 1 into s6

	j SIMPLE_COUNTER

	RANDOM_SCALE:
		li t0, 0xFF						# used for turning all LEDs on
		sw t0, 0(s1)					# turns all LEDs on to indicate restart of the game
		li a0, 1000						# function argument to delay one 100 ms
		jal DELAY						# jumps to DELAY subroutine

		sw zero, 0(s1) 					# turn LEDs OFF
		jal RANDOM_NUM 					# calls pseudorandom number generator
		slli a0, a0, 1 					# scale x2
		blt a0, s5, RANDOM_SCALE 		# if out of range, generate new random number
		bge a0, s4, RANDOM_SCALE 		# if out of range, generate new random number

	jal DELAY 							# calls delay with the a0 generated and scaled
	sw s6, 0(s1) 						# turn an LED ON

	li s7, 0							# initialization counter for reaction loop
	
	REACTION_LOOP:
		li a0, 1 						# DELAY argument to delay 0.1 ms
		jal DELAY						# jump to DELAY subroutine

		addi s7, s7, 1					# increment reaction time counter by 1 (32-bits)

		lw s8, 0(s2)					# loads the value of the push button base address
		andi s8, s8, 0xF				# bit masking because only care about bottom 4 bits, as those are the bits for the push buttons

		li t2, 0xE						# value of the push button if the right most push button is pressed

		beq s8, t2, RESTART_GET_8BITS	# if right most push button is pressed, go to GET_8BITS
		j REACTION_LOOP					# else, countine looping

		RESTART_GET_8BITS:
			addi t0, s7, 0				# stores the 32 bit value into t0 so that when relooping the LED flashing, the original 32-bit register containing the reflex counter time doesnt get modified
			li t1, 32 					# keeps track of 32 bits

		GET_8BITS:
			lw s8, 0(s2)				# loads the value of the push button base address
			andi s8, s8, 0xF			# bit masking because only care about bottom 4 bits, as those are the bits for the push buttons

			li t2, 0xD					# load immediate to check if second right most push button is pressed
			beq s8, t2, RANDOM_SCALE	# if second button from the right most push button is press (reset button), jump back to RANDOM_SCALE and restart game. Otherwise, continue displaying 32 bits

			andi a1, t0, 0xFF			# used to determine which LEDs to turn on per byte, stores the 8 bits to a1 (function argument of DISPLAY_NUM)
			addi t1, t1, -8				# keeps track of bits left
			srli t0, t0, 8				# shift 8 to get next byte
			jal DISPLAY_NUM				# sends 8 bits to DISPLAY_NUM
			
			beq t1, zero, NO_BITS		# if no more bits left, go to subroutine NO_BITS
			j GET_8BITS					# else, repeat sending 8 bits to DISPLAY_NUM

		NO_BITS:
			lw s8, 0(s2)				# loads the value of the push button base address
			andi s8, s8, 0xF

			li t2, 0xD					# load immediate to check if second right most push button is pressed
			beq s8, t2, RANDOM_SCALE	# if second button from the right most push button is press (reset button), jump back to RANDOM_SCALE and restart game. Otherwise, continue displaying 32 bits

			li a0, 50000				# function argument used to delay the last byte by 5 seconds
			jal DELAY					# jumps to DELAY
			j RESTART_GET_8BITS			# after last byte, go back to GET_8BITS and restart the LED flashing of 32 bits

# End of main function		
		

# Subroutines	
SIMPLE_COUNTER:							# subroutine used to verify LED functionality
	li t0, 0x00							# base to increment 
	li t2, 0xFF							# max to increment

	COUNT_UP:
		addi t0, t0, 1					# increments counter by 1
		sw t0, 0(s1) 					# turns on the LEDs to verify functionality
		li a0, 1000						# DELAY function argument for 100ms delay

		jal DELAY

		lw s8, 0(s2)					# loads the value of the push button base address
		andi s8, s8, 0xF				# bit masking because only care about bottom 4 bits, as those are the bits for the push buttons
		li t1, 0xE						# used to check if the right most push button is pressed

		beq t1, s8, RANDOM_SCALE
		beq t0, t2, SIMPLE_COUNTER		# if number incremented is at its max, restart counter
		j COUNT_UP						# else restart loop


DELAY:
	# Insert your code here to make a delay of a0 * 0.1 ms
	mul t4, s3, a0

	COUNTER:
		addi t4, t4, -1
		beq t4, zero, EXIT1
		j COUNTER

	EXIT1:
		jr ra
	


DISPLAY_NUM:
	# Insert your code here to display the 32 bits in a0 on the LEDs byte by byte (Least isgnificant byte first) with 2 seconds delay for each byte and 5 seconds for the last
	sw a1, 0(s1) 						# displays 8 bit number on LEDs
	li a0, 20000						# DELAY function argument used to delay 2 seconds 

	addi sp, sp, -4						# push a value to stack
	sw ra, 0(sp)						# store the current return address to stack pointer with offset 0

	jal DELAY							# jumps to DELAY subroutine (this will overwrite the current return address)
	
	lw ra, 0(sp)						# load the return address back into the return address register 
	addi sp, sp, 4						# restore stack pointer

	jr ra


RANDOM_NUM:
	# This is a provided pseudorandom number generator no need to modify it, just call it using JAL (the random number is saved at a0)
	addi sp, sp, -4				# push ra to the stack
	sw ra, 0(sp)
	la gp, SEED					# load address of the random number in memory
	
	lw t0, 0(gp)				# load the seed or the last previously generated number from the data memory to t0
	li t1, 0x8000
	and t2, t0, t1				# mask bit 16 from the seed
	li t1, 0x2000
	and t3, t0, t1				# mask bit 14 from the seed
	slli t3, t3, 2				# allign bit 14 to be at the position of bit 16
	xor t2, t2, t3				# xor bit 14 with bit 16
	li t1, 0x1000		
	and t3, t0, t1				# mask bit 13 from the seed
	slli t3, t3, 3				# allign bit 13 to be at the position of bit 16
	xor t2, t2, t3				# xor bit 13 with bit 14 and bit 16
	andi t3, t0, 0x400			# mask bit 11 from the seed
	slli t3, t3, 5				# allign bit 14 to be at the position of bit 16
	xor t2, t2, t3				# xor bit 11 with bit 13, bit 14 and bit 16
	srli t2, t2, 15				# shift the xoe result to the right to be the LSB
	slli t0, t0, 1				# shift the seed to the left by 1
	or t0, t0, t2				# add the XOR result to the shifted seed 
	li t1, 0xFFFF				
	and t0, t0, t1				# clean the upper 16 bits to stay 0
	sw t0, 0(gp)				# store the generated number to the data memory to be the new seed
	mv a0, t0					# copy t0 to a0 as a0 is always the return value of any function
	
	lw ra, 0(sp)				# pop ra from the stack
	addi sp, sp, 4
	jr ra

	

	#Lab Report

	# 1 . Highest hexadecimal time that could be stored is
	#		8 bits -> 0XFF = (11111111)2 = 255 = 25.5 milliseconds
	#		16 bits -> 0XFFFF = (1111111111111111)2 = 65535 = 6553.5 milliseconds = ~6.6 seconds
	#		24bits -> 0XFFFFFF = (11111111111111111111) 2 = 16,777,216 = ~27.96 minutes
	#		32bits -> 0XFFFFFFFF = (111111111111111111111111) 2 = 4,294,967,295 = 4.97 days

 	#		The best size for this task should be 16 bits