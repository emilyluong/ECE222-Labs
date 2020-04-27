##################################################
## Name:    	Lab1.s 				##
## Purpose:	A Template for flashing LED 	##
## Author:	Emily & Siddharth		##
##################################################

# The main function must be initialized in that manner in order to compile properly on the board
.text
.globl	main
main:
	lui s1, 0x7ff60 		# assigns s1 with the LED base address (Could be replaced with lui s1, 0x7ff60)
	addi s2, zero, 0x0		# assigns zero to s2 --> initialized all LEDs to zero 
	sw s2, 0(s1)			# stores value of s2 in s1, which is where the base address is --> turns all LEDs off
	li s3, 4166667			# loads the 500ms intermediate to s3 --> determined by taking the CPU clock frequency of RISC-V and dividing by the number of excecutions. As well as dividing that number by 2 to get 500ms delay.
					# (25 000 000/3)/2 = 4166667
					
	# reset label allows to reset counter to original value and toggle on the LED by storing xor value to the base address
    	reset:
		li s3, 4166667
		xori s2, s2, 1
		sw s2, 0(s1)
		
	# counter label decreases clock frequency by 1, and compares the frequency to zero. If frequency is zero, then jump to the reset and proceed with that code. Otherwise, jump back to the counter label.
	counter:
		addi s3, s3, -1
		beq s3, zero, reset
		j counter	
