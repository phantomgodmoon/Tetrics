.data
# player instruction
input_key:	.word 0 # input key from the player

#game setting
game_status:	.word 0 #the status of the game
game_pause: 	.word 0 #the state of game pause
auto_down_count:	.word 0 #the index to indicate whether auto down

#Block properties
current_block_id: 	.word 0 #the id of current block
block_x_loc:		.word 0 #the current x_loc of current block's typical location 
block_y_loc:		.word 0 #the current y_loc of current block's typical location 
block_mode:		.word 0 #the current mode of current block
inital_x_loc: 		.word 4 5 4 4 5 5 6 #the intial x_loc of all 7 types of block
inital_y_loc: 		.word 1:7 #the intial y_loc of all 7 types of block
mode_x_loc: 		.byte  #the x_loc of all 4 modes for all 7 types of block
-1 0 1 2 0 0 0 0 -1 0 1 2 0 0 0 0
-1 -1 0 1 -1 0 0 0 -1 0 1 1 0 0 0 1
-1 0 1 1 -1 0 0 0 -1 -1 0 1 0 0 0 1
0 0 1 1 0 0 1 1 0 0 1 1 0 0 1 1
-1 0 0 1 -1 -1 0 0 -1 0 0 1 -1 -1 0 0
-1 0 0 1 -1 0 0 0 -1 0 1 0 0 0 0 1
-1 0 0 1 1 1 0 0 -1 0 0 1 1 1 0 0
mode_y_loc: .byte  #the y_loc of all 4 modes for all 7 types of block
0 0 0 0 1 0 -1 -2 0 0 0 0 1 0 -1 -2
-1 0 0 0 0 0 -1 -2 -1 -1 -1 0 -2 -1 0 -2
0 0 0 -1 -2 -2 -1 0 -1 0 -1 -1 -2 -1 0 0
-1 0 -1 0 -1 0 -1 0 -1 0 -1 0 -1 0 -1 0
0 0 -1 -1 -2 -1 -1 0 0 0 -1 -1 -2 -1 -1 0
0 -1 0 0 -1 -2 -1 0 -1 -1 -1 0 -2 -1 0 -1
-1 -1 0 0 -2 -1 -1 0 -1 -1 0 0 -2 -1 -1 0

#Basic matrix
matrix_size:		.word 10 23 # width and height of the matrix
basic_matrix_bitmap: .byte 0:220
		     .byte 1:10



.text

main:
# Initialize the game
init_game:
	li $v0, 100 #syscall 100: create the game
	syscall
	
	la $s0,current_block_id #load the address of current_block_id
	sw $v0,0($s0) #load the id of the current block
	
	sll $v0,$v0,2
	la $t0,inital_x_loc # load the x_loc of current block
	add $t0,$t0,$v0
	lw $t1,0($t0) 
	la $s1,block_x_loc #load the address of x_loc of current block
	sw $t1,0($s1)
	
	la $t0,inital_y_loc # load the y_loc of current block
	add $t0,$t0,$v0
	lw $t1,0($t0)
	la $s2,block_y_loc #load the address of y_loc of current block
	sw $t1,0($s2)
	
	la $s3,block_mode #load the address of block_mode
	la $s4,basic_matrix_bitmap #load the address of basic_matrix_bitmap
	
	#syscall 102: turn on the background music
	li $a0, 0 
	li $a1, 1
	li $v0, 102
	syscall
	
game_loop:
	jal get_time 
	add $s6, $v0, $zero # $s6: starting time of the game

check_game_status:
	la $t0,game_status
	lw $t0,0($t0)
	bne $t0,$zero,game_over	#whether game over
	
game_player_instruction:
	jal get_keyboard_input
	jal process_player_input
	
auto_down:
	jal check_auto_down 

	
game_refresh: #refresh game	
	li $v0, 101 # Refresh the screen
	syscall
	add $a0, $s6, $zero
	addi $a1, $zero, 50 # iteration gap: 100 milliseconds
	jal have_a_nap
	j game_loop


game_over:
	# Update the game status
	li $v0,106
	syscall
	# Refresh the screen
	li $v0, 101
	syscall
	#syscall 102: play the sound of lose
	li $a0, 3 
	li $a1, 0
	li $v0, 102
	syscall	
	#syscall 102: turn off the background music
	li $a0, 0 
	li $a1, 2
	li $v0, 102
	syscall	
	# Terminate the program
	li $v0, 10
	syscall

#--------------------------------------------------------------------
# procedure: get_time
# Get the current time
# $v0 = current time
#--------------------------------------------------------------------
get_time:	li $v0, 30
		syscall # this syscall also changes the value of $a1
		andi $v0, $a0, 0x3FFFFFFF # truncated to milliseconds from some years ago
		jr $ra

#--------------------------------------------------------------------
# procedure: have_a_nap(last_iteration_time, nap_time)
#--------------------------------------------------------------------
have_a_nap:
	addi $sp, $sp, -8
	sw $ra, 4($sp)
	sw $s0, 0($sp)

	add $s0, $a0, $a1
	jal get_time
	sub $a0, $s0, $v0
	slt $t0, $zero, $a0 
	bne $t0, $zero, han_p
	li $a0, 1 # sleep for at least 1ms
	
han_p:	li $v0, 32 # syscall: let mars java thread sleep $a0 milliseconds
	syscall

	lw $ra, 4($sp)
	lw $s0, 0($sp)
	addi $sp, $sp, 8
	jr $ra

get_keyboard_input:
	add $t2, $zero, $zero
	lui $t0, 0xFFFF
	lw $t1, 0($t0)
	andi $t1, $t1, 1
	beq $t1, $zero, gki_exit
	lw $t2, 4($t0)

gki_exit:	
	la $t0, input_key 
	sw $t2, 0($t0) # save input key
	jr $ra
	
process_player_input:
	addi $sp, $sp, -4
	sw $ra, 0($sp)	
	
	la $t0, input_key
	lw $t1, 0($t0) # new input key

	li $t0, 119 # corresponds to key 'w'
	beq $t1, $t0, ppi_move_up  
	li $t0, 115 # corresponds to key 's'
	beq $t1, $t0, ppi_move_down
	li $t0, 97 # corresponds to key 'a'
	beq $t1, $t0, ppi_move_left
	li $t0, 100 # corresponds to key 'd'
	beq $t1, $t0, ppi_move_right
	li $t0, 112 # corresponds to key 'p'
	beq $t1, $t0, ppi_pause
	j ppi_exit

ppi_move_left:
	#syscall 102: play sound of action
	li $a0, 1 
	li $a1, 0
	li $v0, 102
	syscall
	jal block_move_left
	j ppi_exit

ppi_move_right:
	#syscall 102: play sound of action
	li $a0, 1 
	li $a1, 0
	li $v0, 102
	syscall
	jal block_move_right
	j ppi_exit
	
ppi_move_up: 
	#syscall 102: play sound of action
	li $a0, 1 
	li $a1, 0
	li $v0, 102
	syscall
	jal block_rotate
	j ppi_exit

ppi_move_down:
	#syscall 102: play sound of action
	li $a0, 1 
	li $a1, 0
	li $v0, 102
	syscall
	jal block_move_down
	j ppi_exit

ppi_pause:
	#syscall 102: play sound of action
	li $a0, 1 
	li $a1, 0
	li $v0, 102
	syscall	
	jal set_game_pause
	j ppi_exit				

ppi_exit: 
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
#--------------------------------------------------------------------
# procedure: block_move_left
# Move the block leftward by one step.
# Move the object only when the object will not overlap with a wall or already fixed blocks.
#--------------------------------------------------------------------	
block_move_left:
	addi $sp, $sp, -20
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)

	lw $t0,0($s1) #load the x_loc of the current block
	addi $a0,$t0,-1 #assume block moving left is valid
	
	lw $a1,0($s2) #load the y_loc of the current block
	lw $a2,0($s3) #load the mode of the current block
	lw $a3,0($s0) #load the id of the current block
	
	jal check_movement_valid
	
	beq $v0,$zero,bml_exit
	
bml_after_move:
	sw $a0,0($s1) #update the x_loc of the current block
	
	lw $a0,0($s1) #load the x_loc of the current block
	lw $a1,0($s2) #load the y_loc of the current block
	lw $a2,0($s3) #load the mode of the current block
	li $v0,104
	syscall
	
bml_exit:
	li $v0,101 #refresh the screen
	syscall
			
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	lw $s3, 16($sp)
	addi $sp, $sp, 20
	jr $ra	

block_move_right:
	addi $sp, $sp, -20
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)
	
	lw $t0,0($s1) #load the x_loc of the current block

	addi $a0,$t0,1 #assume block moving left is valid
	
	lw $a1,0($s2) #load the y_loc of the current block
	lw $a2,0($s3) #load the mode of the current block
	lw $a3,0($s0) #load the id of the current bloc
	
	jal check_movement_valid
	
	beq $v0,$zero,bml_exit # invalid
	
	j bml_after_move
	 	
# I add this function
bml_after_rotate:

	sw $a2,0($s3) #update the mode of the current block
	
	lw $a0,0($s1) #load the x_loc of the current block
	lw $a1,0($s2) #load the y_loc of the current block
	lw $a2,0($s3) #load the mode of the current block
	
	li $v0,104
	syscall
	j bml_exit
	
block_rotate:
# *****Task2: you need to complete this procedure block_rotate to perform its operations as described in comments above. 
# Calculate new mode of the current block.
# Check whether this rotation is valid (using procedure check_movement_valid),
#		If it is invalid, don't update new mode of the current block.
#		If it is valid, then save the new mode for the current block and update this movement to the GUI in java code.
# Lastly, pop and restore values in $ra, $s0, $s1, $s2, $s3  and return
# Hint: you can refer to block_move_left to get some clues and pause "p" is very useful to debug.
# *****Your codes start here
	addi $sp, $sp, -20
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)
	 
	lw $t0,0($s3)
	addi $t0,$t0,1
	slti $t1,$t0,4  # $t1 = true if $t0<4 
	beq $t1,1,DUN_CHANGE
	addi $t0,$zero,0
	DUN_CHANGE:
	
	lw $a0,0($s1) #load the x_loc of the current block		# $a0: potential x_loc 
	lw $a1,0($s2) #load the y_loc of the current block 		#$a1: potential y_loc
	add $a2,$t0,$zero #Asuume the mode is correct		#$a2: potential block_mode
	lw $a3,0($s0) #load the id of the current block			# $a3: current block id
	
	jal check_movement_valid 

	beq $v0,$zero,bml_exit # invalid
	
	j bml_after_rotate				
# *****Your codes end here	
			
#--------------------------------------------------------------------
# procedure: block_move_down
# Move the block downward by one step.
# Move the object only when the object will not overlap with a wall or already fixed blocks.
# If this downward movement is invalid, it indicates the block gets the bottom of game space.
# If so, this block becomes fixed and update the basic matrix. 
# Then, check whether the game is over.
# Next, check whether this block leads to a new full row.
# At Last, use syscall 103 to create a new block.
# This function has no return value
#--------------------------------------------------------------------	
block_move_down:
	addi $sp, $sp, -20
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)

	lw $a0,0($s1) #load the x_loc of the current block
	
	lw $t0,0($s2) #load the y_loc of the current block
	addi $a1,$t0,1 #assume block moving down is valid
	
	lw $a2,0($s3) #load the mode of the current block
	lw $a3,0($s0) #load the id of the current block
	
	jal check_movement_valid
	bne $v0,$zero,bmd_after_move

bmd_get_bottom:
	addi $a1,$a1,-1 #block moving down is invalid
	lw $a0,0($s1) #load the x_loc of the current block
	lw $a1,0($s2) #load the y_loc of the current block
	lw $a2,0($s3) #load the mode of the current block
	lw $a3,0($s0) #load the id of the current block
	jal update_basic_matrix
	
	# check_game_over
	addi $a0,$zero,2 
	la $t0,matrix_size
	lw $a1,0($t0)
	jal check_game_over
	bne $v0,$zero,bmd_update_status
	
	#check_full_row
	la $t0,matrix_size
	lw $a0,4($t0) #the height of basic_matrix
	lw $a1,0($t0) #the width of basic_matrix
	jal check_full_row
	

bmd_create_new_block:
	li $v0,103 # create new block
	syscall
	
	sw $v0,0($s0) #load the id of the current block
	
	sll $v0,$v0,2
	la $t0,inital_x_loc # load the x_loc of current block
	add $t0,$t0,$v0
	lw $t1,0($t0) 
	sw $t1,0($s1) #update the current x_loc of new block
	
	la $t0,inital_y_loc # load the y_loc of current block
	add $t0,$t0,$v0
	lw $t1,0($t0)
	sw $t1,0($s2) #update the current y_loc of new block	

	sw $zero,0($s3) #reset the block_mode of new block
	j bmd_exit

bmd_update_status:
	la $t0,game_status
	sw $v0,0($t0)
	j bmd_exit

bmd_after_move:
	sw $a1,0($s2) #update the y_loc of the current block
		
bmd_exit:
	lw $a0,0($s1) #load the x_loc of the current block
	lw $a1,0($s2) #load the y_loc of the current block
	lw $a2,0($s3) #load the mode of the current block
	li $v0,104
	syscall	
	li $v0,101 #refresh the screen
	syscall	
		
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	lw $s3, 16($sp)
	addi $sp, $sp, 20
	jr $ra			
	
#--------------------------------------------------------------------
# Procedure: check_movement_valid
# Input parameter: $a0: potential x_loc 
#		   $a1: potential y_loc
#		   $a2: potential block_mode
#		   $a3: current block id
# Output: $v0,1 means the movement is valid, 0 means the movement is invalid
#--------------------------------------------------------------------
check_movement_valid:
#*****Task3: you need to complete this procedure check_movement_valid to perform its operations as described in comments above. 
# Firstly, preserve values $ra, $s4 with stack
# Then, use the registers as described below:
# 		The base address of basic_matrix_bitmap is in $s4
# Secondly, use the these four input parameters, mode_x_loc and mode_y_loc to calculate the absolute corrdinate of every 4 squares in a block.
# Thirdly, check whether the corrdinate of all four squares is valid with loop.
# Note that this procedure is used to check the validity of all types of actions, so it have to consider all situations.
# All situations includes crossing horizontal_boundary, crossing vertical_boundary and overlapping with fixed squares.
# At last, set the value of $v0 based on the check result ,and pop and restore values in $ra, $s4  and return.
#*****Your codes start here

	addi $sp, $sp, -24
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)
	sw $s4, 20($sp)
	
	# Get the Absolute corrdinate, Note 16 個=1 type , 4個=1 mode   (第一個x or y)
	sll $s0,$a3,4		# type =$s0
	sll $s1,$a2,2		# mode =$s1
	
	add $s0,$s0,$s1		# First Index of mode_x/y_loc
	addi $s1,$s0,1		#Second Index mode_x/y_loc
	addi $s2,$s0,2		# Thrid Inex mode_x/y_loc
	addi $s3,$s0,3		# Forth Index mode_x/y_loc
	
	la $t0,mode_x_loc
	la $t1,mode_y_loc
	
	# Calculate the x coordinate
	add $t2,$s0,$t0		
	lb $t2,0($t2)		#add how much x_1
	add $t2,$t2,$a0		#x_1
	
	add $t3,$s1,$t0
	lb $t3,0($t3)		#add how much x_2
	add $t3,$t3,$a0		#x_2
	
	add $t4,$s2,$t0			
	lb $t4,0($t4)		#add how much x_3
	add $t4,$t4,$a0		#x_3
	
	add $t5,$s3,$t0		
	lb $t5,0($t5)		#add how much x_4
	add $t5,$t5,$a0		#x_4
	
	# Calculate the y coordinate
	add $t6,$s0,$t1		
	lb $t6,0($t6)		#add how much y_1
	add $t6,$t6,$a1		#y_1
	
	add $t7,$s1,$t1
	lb $t7,0($t7)		#add how much y_2
	add $t7,$t7,$a1		#y_2
	
	add $t8,$s2,$t1			
	lb $t8,0($t8)		#add how much y_3
	add $t8,$t8,$a1		#y_3
	
	add $t9,$s3,$t1		
	lb $t9,0($t9)		#add how much y_4
	add $t9,$t9,$a1		#y_4
	
	#Release $t0,$t1 and change to variable of loop

Check_horizontal_boundary:
	# If smaller than 0
	slti $t0,$t2,0
	beq $t0,1,False_Condition
	slti $t0,$t3,0
	beq $t0,1,False_Condition
	slti $t0,$t4,0
	beq $t0,1,False_Condition
	slti $t0,$t5,0
	beq $t0,1,False_Condition
	# If Larger than 9
	
	slti $t0,$t2,10
	beq $t0,0,False_Condition
	slti $t0,$t3,10
	beq $t0,0,False_Condition
	slti $t0,$t4,10
	beq $t0,0,False_Condition
	slti $t0,$t5,10
	beq $t0,0,False_Condition

Check_vertical_boundary:
	#If smaller than 0
	slti $t0,$t6,0
	beq $t0,1,False_Condition
	slti $t0,$t7,0
	beq $t0,1,False_Condition
	slti $t0,$t8,0
	beq $t0,1,False_Condition
	slti $t0,$t9,0
	beq $t0,1,False_Condition
	
	# If Larger than 21
	
	slti $t0,$t6,22
	beq $t0,0,False_Condition
	slti $t0,$t7,22
	beq $t0,0,False_Condition
	slti $t0,$t8,22
	beq $t0,0,False_Condition
	slti $t0,$t9,22
	beq $t0,0,False_Condition
#Newly added
Pre_Check_overlapping:
	
Check_overlapping:
	#Check x_1, y_1 (t2,t6)
	addi $t0,$zero,10
	la $t1 basic_matrix_bitmap
	mult $t6,$t0		#y_1*10
	mflo $t6,
	add $t6,$t6,$t2		#y_1+x_1
	add $t6,$t6,$t1		# get the address of (X_1,Y_1)
	lb $t6,0($t6)		# get the value
	bne $t6,0,False_Condition
	#Check Second one 
	mult $t7,$t0		
	mflo $t7
	add $t7,$t7,$t3
	add $t7,$t7,$t1
	lb $t7,0($t7)		
	bne $t7,0,False_Condition
	#Check Third One
	mult $t8,$t0		
	mflo $t8
	add $t8,$t8,$t4
	add $t8,$t8,$t1
	lb $t8,0($t8)		
	bne $t8,0,False_Condition
	
	# Check Forth One 
	mult $t9,$t0		
	mflo $t9
	add $t9,$t9,$t4
	add $t9,$t9,$t1
	lb $t9,0($t9)		
	bne $t9,0,False_Condition
True:
	li $v0, 1
	
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	lw $s3, 16($sp)
	lw $s4, 20($sp)
	addi $sp, $sp, 24
	jr $ra	
	
 False_Condition:	
 	li $v0,0
 	
 	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	lw $s3, 16($sp)
	lw $s4, 20($sp)
	addi $sp, $sp, 24
	jr $ra	

				
#--------------------------------------------------------------------
# Procedure: update_basic_matrix
# Update data of the basic matrix when a block is going to be fixed
# Input parameter: $a0: x_loc of block to be fixed 
#		   $a1: y_loc of block to be fixed  
#		   $a2: mode of block to be fixed 
#		   $a3: id of block to be fixed
update_basic_matrix:
# Firstly, preserve values $ra, $s4 with stack
# Secondly, use the these four input parameters, mode_x_loc and mode_y_loc to calculate the absolute corrdinate of every 4 squares in a block.
# Thirdly, increment the corresponding coordinate in basic_matrix_bitmap by 1.
# At last, pop and restore values in $ra, $s4  and return.
#*****Your codes start here
	addi $sp, $sp, -24
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)
	sw $s4, 20($sp)
	
	# Get the Absolute corrdinate, Note 16 個=1 type , 4個=1 mode   (第一個x or y)
	sll $s0,$a3,4		# type =$s0
	sll $s1,$a2,2		# mode =$s1
	add $s0,$s0,$s1		# First Index of mode_x/y_loc
	addi $s1,$s0,1		#Second Index mode_x/y_loc
	addi $s2,$s0,2		# Thrid Inex mode_x/y_loc
	addi $s3,$s0,3		# Forth Index mode_x/y_loc
	
	la $t0,mode_x_loc
	la $t1,mode_y_loc
	
	# Calculate the x coordinate
	add $t2,$s0,$t0		
	lb $t2,0($t2)		#add how much x_1
	add $t2,$t2,$a0		#x_1
	
	add $t3,$s1,$t0
	lb $t3,0($t3)		#add how much x_2
	add $t3,$t3,$a0		#x_2
	
	add $t4,$s2,$t0			
	lb $t4,0($t4)		#add how much x_3
	add $t4,$t4,$a0		#x_3
	
	add $t5,$s3,$t0		
	lb $t5,0($t5)		#add how much x_4
	add $t5,$t5,$a0		#x_4
	
	# Calculate the y coordinate
	add $t6,$s0,$t1		
	lb $t6,0($t6)		#add how much y_1
	add $t6,$t6,$a1		#y_1
	
	add $t7,$s1,$t1
	lb $t7,0($t7)		#add how much y_2
	add $t7,$t7,$a1		#y_2
	
	add $t8,$s2,$t1			
	lb $t8,0($t8)		#add how much y_3
	add $t8,$t8,$a1		#y_3
	
	add $t9,$s3,$t1		
	lb $t9,0($t9)		#add how much y_4
	add $t9,$t9,$a1		#y_4
	
	# t0 and t1 is free to use
	addi $t0,$zero,10
	mult $t6, $t0   	#y_1 *10
	mflo $t1
	add $t1,$t1,$t2		#y_1 *10 +x_1
	add $t1,$s4,$t1		#base address + y_1*10 _+x_1
	
	lb $t0, 0($t1)
	addi $t0,$t0,1
	sb $t0, 0($t1)
	
	addi $t0,$zero,10
	mult $t7, $t0   	#y_2 *10
	mflo $t1
	add $t1,$t1,$t3		#y_2 *10 +x_2
	add $t1,$s4,$t1		#base address + y_2*10 _+x_2
	
	lb $t0, 0($t1)
	addi $t0,$t0,1
	sb $t0, 0($t1)
	
	addi $t0,$zero,10
	mult $t8, $t0   	#y_3 *10
	mflo $t1
	add $t1,$t1,$t4		#y_3 *10 +x_3
	add $t1,$s4,$t1		#base address + y_3*10 _+x_3
	
	lb $t0, 0($t1)
	addi $t0,$t0,1
	sb $t0, 0($t1)
	
	addi $t0,$zero,10
	mult $t9, $t0   	#y_4 *10
	mflo $t1
	add $t1,$t1,$t5		#y_4 *10 +x_4
	add $t1,$s4,$t1		#base address + y_4*10 _+x_4
	
	lb $t0, 0($t1)
	addi $t0,$t0,1
	sb $t0, 0($t1)
	
	li $v0, 105
	syscall
	
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	lw $s3, 16($sp)
	lw $s4, 20($sp)
	addi $sp, $sp, 24
        jr $ra
		
		
# *****Your codes end here


	
#--------------------------------------------------------------------
# Procedure: check_game_over
# Check whether the fixed blocks prevent the arrival of a new block
# The logic is that If a value in the first two row of basic matrix is larger than 1,
# then game over.
# Input parameter: $a0: 2, $a1: the width of matrix
# Output: $v0,0 means the game is still going, 1 means game over
#--------------------------------------------------------------------
check_game_over:
	addi $sp, $sp, -8
	sw $ra, 0($sp)
	sw $s4, 4($sp)
	
	move $v0,$zero
	
	addi $t0,$zero,0 #$t0 = 0, iterator i
	addi $t1,$zero,0 #$t1 = 0, iterator j
	
cgo_loop1:	
	slt $t2,$t0,$a0
	beq $t2,$zero,cgo_exit
	addi $t1,$zero,0
	
	mul $t3,$t0,$a1 #$t3 = i times the width of matrix
cgo_loop2:
	slt $t2,$t1,$a1
	beq $t2,$zero,cgo_loop2_exit
	
	add $t4,$t3,$t1 #$t4 = i times the width of matrix + j
	add $t4,$t4,$s4 #$t4 = i times the width of matrix + j + base address of of basic matrix
	
	lb $t5,0($t4)
	addi $t6,$zero,1
	slt $t7,$t6,$t5 # if basicmatrix[i][j] > 1
	bne $t7,$zero,cgo_game_over
	
	
	addi $t1,$t1,1	
	j cgo_loop2
	
cgo_loop2_exit:
	addi $t0,$t0,1
	j cgo_loop1

cgo_game_over:
	addi $v0,$v0,1	
	
cgo_exit:	
	lw $ra, 0($sp)
	lw $s4, 4($sp)
	addi $sp, $sp, 8
	jr $ra	

#--------------------------------------------------------------------
# Procedure: check_full_row
# Check whether there is full row in current basic matrix.
# If so, for each full row, let it disappear and the blocks placed above fall one rank.
# input parameter: $a0: the height of matrix, $a1: the width of matrix
# This function has no return value.
#--------------------------------------------------------------------
check_full_row:
	addi $sp, $sp, -8
	sw $ra, 0($sp)
	sw $s4, 4($sp)

	addi $t0,$zero,0 #$t0 = 0, iterator i
	addi $t1,$zero,0 #$t1 = 0, iterator j 
	
	addi $a0,$a0,-1 #the height of matrix - 1
	
cfr_loop1:
	slt $t3,$t0,$a0
	beq $t3,$zero,cfr_exit
	
	addi $t1,$zero,0 #reset iterator j 
	addi $t2,$zero,1 #boolean(true) indicates whether there is a full row	
	
	mul $t4,$t0,$a1 #$t4 = i times the width of matrix
cfr_loop2:
	slt $t3,$t1,$a1
	beq $t3,$zero,cfr_loop2_exit
	
	add $t5,$t4,$t1 #$t5 = i times the width of matrix + j
	add $t5,$t5,$s4 #$t5 = i times the width of matrix + j + base address of of basic matrix
	
	lb $t5,0($t5)
	beq $t5,$zero,cfr_not_full_row # this row can't be a full row
	
	
	addi $t1,$t1,1	
	j cfr_loop2
	
cfr_not_full_row:
	move $t2,$zero # boolean = false

cfr_loop2_exit:
	bne $t2,$zero,cfr_process_full_row
	
	addi $t0,$t0,1 # i = i + 1
	j cfr_loop1
	
cfr_process_full_row:
	addi $sp, $sp, -20
	sw $ra, 0($sp)
	sw $a0, 4($sp)
	sw $a1, 8($sp)
	sw $t0, 12($sp)
	sw $t1, 16($sp)

	move $a0,$t0
	la $t2,matrix_size
	lw $a1,0($t2)
	jal process_full_row
	
	lw $ra, 0($sp)
	lw $a0, 4($sp)
	lw $a1, 8($sp)
	lw $t0, 12($sp)
	lw $t1, 16($sp)
	addi $sp, $sp, 20
	
	j cfr_loop1
	
cfr_exit:	
	lw $ra, 0($sp)
	lw $s4, 4($sp)
	addi $sp, $sp, 8
	jr $ra
	

#--------------------------------------------------------------------
# Procedure: process_full_row
# Remove the specific row and let the blocks placed above fall one rank.
# input parameter: $a0: the full row number
#		   $a1: the width of matrix
# This function has no return value.
#--------------------------------------------------------------------
process_full_row:
#*****Task5: you need to complete this procedure process_full_row to perform its operations as described in comments above. 
# Secondly, delete row $a0 and use loop to move all rows above $a0 downside by one row.
# 	Logic for reference:  for all k (rows above row $a0 and row $a0), for all l (elements in this row), let basicMatrix[k][l][0] = basicMatrix[k - 1][l][0];
# Thirdly, let the first row of basic matrix equal to zero.
# At last, use syscall 107 and 102, then pop and restore values in $ra, $s4  and return.
#*****Your codes start here
	addi $sp, $sp, -24
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)
	sw $s4, 20($sp)
	
	
	li $s0,10		#$s0=10
	add $s1,$a1,$zero	#$s1=column (9)
	mult $a0,$s0		# full row number
	mflo $t2		#$s2=10*row number
	
	add $t4,$a1,$zero	#$ current column
Delete_row:
	add $t0,$t2,$t4		#$t0=10*rownumber+maxcolumn
	add $t1,$t0,$s4		#base address+10*row_num+column
	li $t3,0
	sb $t3,0($t1)
	addi $t4,$t4,-1		#t4--
	slti $t5,$t4,0
	beq $t5,0,Delete_row
	
	
	
	addi $t0,$a0,0		# $t0 = row
Move_Whole_Row_Downward_loop:
	addi $t0,$t0,-1		#rows that need to move
	add $t1,$a1,$zero	#number of column, i.e. 9
	beq $t0,-1,Leave_Move_Whole_Row_Downward
	
Move_this_cells_Downward: #$t0=row, $t1=column
	mult $s0,$t0		# 10*row
	mflo $t2
	add $t2,$t2,$t1		#10* row +column
	add $t2,$s4,$t2		# base address+ $t2
	lb $t3, 0($t2)
	addi $t3,$t3,0
	addi $t2,$t2,10
	sb $t3, 0($t2)		# Swap
	
	addi $t1,$t1,-1
	beq $t1,-1,Move_Whole_Row_Downward_loop
	j Move_this_cells_Downward


Leave_Move_Whole_Row_Downward:

        li $v0, 107
        syscall
        
        li $v0, 102
        syscall
		
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	lw $s3, 16($sp)
	lw $s4, 20($sp)
	addi $sp, $sp, 24
	
        jr $ra	
		
		
		
		
		
		
# *****Your codes end here


#--------------------------------------------------------------------
# Procedure: check_auto_down
# Check whether the game pauses, If not,then 
# Check whether the block needs to go downside by one step automatically in this game iteration.
# If so, the block go down one step.
# This function has no input parameters and return value.
#--------------------------------------------------------------------
check_auto_down:
	addi $sp, $sp, -4
	sw $ra, 0($sp)	
	
cad_check_pause:
	la $t0,game_pause
	lw $t1,0($t0)
	bne $t1,$zero,cad_exit	

cad_check_autodown_count:	
	la $t0,auto_down_count
	lw $t1,0($t0)
	addi $t1,$t1,1
	sw $t1,0($t0)
	addi $t2,$zero,20
	
	slt $t3,$t1,$t2
	bne $t3,$zero,cad_exit

cad_auto_down:

	jal block_move_down
	la $t0,auto_down_count
	sw $zero,0($t0)

cad_exit:
	#sw $t1,0($t0) 
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

#--------------------------------------------------------------------
# Procedure: set_game_pause
# Switch the state of game_pause.
# This function has no input parameters and return value.
#--------------------------------------------------------------------
set_game_pause:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $t0,game_pause
	lw $t1,0($t0)
	addi $t1,$t1,1
	
	addi $t2,$zero,2
	slt $t3,$t1,$t2
	bne $t3,$zero,sgp_exit
	
spg_mod2:
	move $t1,$zero
	
sgp_exit:
	sw $t1,0($t0)
    
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
