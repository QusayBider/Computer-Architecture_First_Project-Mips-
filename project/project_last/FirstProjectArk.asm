#Qusay Bider 1220649 sec:2
#Omar Hamayle 1220356 sec:2
.data  
file_output:  	  .asciiz "output_project.txt"
equation :    	  .space 1024
equation1:    	  .space 1024            # Allocate 1024 bytes for writable space
equation2:    	  .space 1024
equation3:    	  .space 1024
buffer:       	  .space 1
line:         	  .space 1024
input_file:        .space 100
print_option: 	  .word 0 
count:        	  .word 0                     # Counter to store the equation count
De_count:     	  .word 0
max_count:    	  .word 4
#save equation1 coffictiont
x1:           	  .word 0
y1:           	  .word 0
z1:            	  .word 0
constant1:    	  .word 0
x2:           	  .word 0
y2:           	  .word 0
z2:           	  .word 0
constant2:    	  .word 0
x3:           	  .word 0
y3:           	  .word 0
z3:           	  .word 0
constant3:    	  .word 0
input_file_descriptor:  .word 0
output_file_descriptor:  .word 0
#///////////////////////////////////////////
Result_x:         .word 0
Result_y:         .word 0
Result_z:         .word 0
#////////////////////////////////////////
newline:   	  .asciiz "\n"
result_x:         .asciiz "X = "
result_y:         .asciiz "Y = "
result_z:         .asciiz "Z = "
#//////////////////////////////////////////////
invalid_choice:   .asciiz "\nInvalid choice. Please enter 's' or 'f'.\n"
prompt_output:    .asciiz "\nDisplay output on screen (s) or file (f)? "
prompt_Exit:      .asciiz "\nIf want to Exit from program(e) or(E) . continue(c): "
prompt_filename:  .asciiz "\nEnter the filename: "
no_solution_msg:  .asciiz "No unique solution (D is zero)\n"
error_file: 	  .asciiz "\nerror in open file.\n"
error_message:    .asciiz "\nError: Invalid equation format. Please enter an equation with exactly 2 or 3 variables (x, y, and optionally z) only.\n"
Another_system:   .asciiz "\nNext system solution:\n"
#///////////////////////////////////////////////////////////////////////////////////////
buffer_of_convert:   .space 24       # Buffer for storing the string
Ten:                 .float 10.0     # Constant 10.0

#-------------------------
.macro pushFourRegisterOnTheStack(%reg1,%reg2,%reg3,%reg4)
	addiu $sp,$sp, -16	#Allocate 16 bytes on the stack frame
	sw %reg1, 0($sp)	#Save reg1 on the stack
	sw %reg2, 4($sp)	#Save reg2 on the stack
	sw %reg3, 8($sp)	#Save reg3 on the stack
	sw %reg4, 12($sp)	#Save reg4 on the stack
.end_macro
#--------------------------
.macro popFourRegisterFromTheStack(%reg1,%reg2,%reg3,%reg4)
	lw %reg1, 0($sp)	#Retrieve reg1 from the stack
	lw %reg2, 4($sp)	#Retrieve reg2 from the stack
	lw %reg3, 8($sp)	#Retrieve reg3 from the stack
	lw %reg4, 12($sp)	#Retrieve reg4 from the stack
	addiu $sp,$sp, 16	#Free the stack frame
.end_macro
#--------------------------
#--------------------------
.macro pushThreeRegisterOnTheStack(%reg1,%reg2,%reg3)
	addiu $sp,$sp, -12	#Allocate 12 bytes on the stack frame
	sw %reg1, 0($sp)	#Save reg1 on the stack
	sw %reg2, 4($sp)	#Save reg2 on the stack
	sw %reg3, 8($sp)	#Save reg3 on the stack
.end_macro
#--------------------------
.macro popThreeRegisterFromTheStack(%reg1,%reg2,%reg3)
	lw %reg1, 0($sp)	#Retrieve reg1 from the stack
	lw %reg2, 4($sp)	#Retrieve reg2 from the stack
	lw %reg3, 8($sp)	#Retrieve reg3 from the stack
	addiu $sp,$sp, 12	#Free the stack frame
.end_macro
#--------------------------

.globl main
.text

main:

loop:
#//////////////////////////////Enter the name of file 
# Prompt for input file
    li $v0, 4                    # Print string syscall
    la $a0, prompt_filename          # Load prompt message
    syscall

    # Get user input for file name or exit command
    li $v0, 8                    # Read string syscall
    la $a0, input_file           # Input file location
    li $a1, 100                  # Max length of file path
    syscall
    
     la $t0, input_file               # load address of filename buffer
remove_newline:
    lb $t1, 0($t0)               # load a byte from the filename buffer
    beqz $t1, continue_open      # if we reach null terminator, we're done
    li $t2, 10                   # ASCII code for newline '\n'
    beq $t1, $t2, replace_null   # if character is newline, replace it
    addi $t0, $t0, 1             # move to the next character
    j remove_newline             # repeat loop

replace_null:
    sb $zero, 0($t0)             # replace newline with null terminator

continue_open:

output_results:
    # Prompt for output choice
    li $v0, 4
    la $a0, prompt_output
    syscall
    li $v0, 8
    la $a0, buffer
    li $a1, 2
    syscall

    # Check output choice
    lb $t1, buffer
    #///////////////////////////check s,f
    li $t2, 's'
    li $t3, 'f'
    beq $t1, $t2, print_screen_op
    beq $t1, $t3, save_to_file
    #////////////////////////// check S,F
    li $t2, 'S'
    li $t3, 'F'
    beq $t1, $t2, print_screen_op
    beq $t1, $t3, save_to_file
    #///////////////////////////invalid
    li $v0, 4
    la $a0, invalid_choice
    syscall
    j output_results
    
    save_to_file: 
    li $t3, 1
    sw $t3 ,print_option
    j pass_to_program
    
    print_screen_op:
    li $t2, 0 
    sw $t2 ,print_option
    j pass_to_program
    
    
#////////////////////////////////////////////////////////////////////
    
pass_to_program:
    la $k1, buffer
    la $k0, line
    li $s3, 0           	  # current line length
# open inputfile
    li $v0, 13            	  # syscall for open file
    la $a0, input_file         	  # input file name
    li $a1, 0            	  # read flag
    li $a2, 0          	  	  # ignore mode 
    syscall             	  # open file 
    move $s0, $v0       	  # save the file descriptor 
    bltz $s0,error_in             # If file open fails, show error
    sw $s0 ,input_file_descriptor
    
#open outputfile 
    # Open the file for writing (appending mode)
    li   $v0, 13             # Syscall for opening file
    la   $a0, file_output    # Load address of the file name
    li   $a1, 1              # Flags (append mode)
    li   $a2, 0              # Permissions(read/write for owner/group/other)
    syscall                  # Open the file
    move $t0, $v0            # Save file descriptor (returned in $v0)
    
    sw $t0 ,output_file_descriptor
    
read_loop:
    lw $s0 ,input_file_descriptor
    # read byte from file
    li $v0, 14                    # syscall for read file
    move $a0, $s0                 # file descriptor 
    move $a1, $k1       	  # address of dest buffer
    li $a2, 1          		  # buffer length
    syscall             # read byte from file

# keep reading until bytes read <= 0
    blez $v0, read_done

# naively handle exceeding line size by exiting
    slti $t0, $s3, 1024
    beqz $t0, read_done

# load current byte into $s4
    lb $s4, ($k1)
    li $t0, 10                    # ASCII newline character

# Check for newline character
    sw $s0 ,input_file_descriptor
    beq $s4, $t0, handle_newline

# otherwise, append byte to line
    add $s5, $s3, $k0
    sb $s4, ($s5)

# increment line length
    addi $s3, $s3, 1

# Continue reading
    b read_loop

handle_newline:
# Check if line is empty
    beq $s3,1, newline_msg # If line length is 0, print newline_msg

# increment equation count
     lw $t1, max_count           # Load max count value into $t1
     lw $t2, count               # Load address of counter into $t2# Increment
     addi $t2, $t2, 1            # Increment $t0 by 1
# Store updated counter value back in global memory
     sw $t2, count
     beq $t1, $t2, print_error_format    # If counter ($t0) > max_count ($t1), exit loop
     
# Process non-empty line
    add $s5, $s3, $k0
    sb $zero, ($s5)              # Null terminate line
    
    li $t4, 1                    # Load immediate value 1 into $t3
    li $t5, 2
    li $t6, 3
    beq $t2, $t4, copy_Equation1 
    beq $t2, $t5, copy_Equation2 
    beq $t2, $t6, copy_Equation3 
 
copy_Equation1:
# Copy line to equation1 (writable space)
    la $t1, equation1            # Load the address of equation_in into $t1
    la $t2, line                 # Load the address of 'line' into $t2
    j copy_line
copy_Equation2:
# Copy line to equation2 (writable space)
    la $t1, equation2            # Load the address of equation_in into $t1
    la $t2, line                 # Load the address of 'line' into $t2
    j copy_line
copy_Equation3:
# Copy line to equation3 (writable space)
    la $t1, equation3            # Load the address of equation_in into $t1
    la $t2, line                 # Load the address of 'line' into $t2
    j copy_line
copy_line:
    lb $t3, ($t2)                # Load byte from line
    sb $t3, ($t1)                # Store byte in equation_in
    beq $t3, $zero, end_copy     # Exit loop when null terminator is reached
    addi $t1, $t1, 1             # Move to the next byte in equation_in
    addi $t2, $t2, 1             # Move to the next byte in line
    j copy_line

newline_msg:
     lw $t1, max_count           # Load max count value into $t1
     lw $t2, count               # Load address of counter into $t2
     lw $t3,De_count
     move $t3, $t2
     beq $t1, $t2, read_loop     # If counter ($t0) > max_count ($t1), exit loop
     sw $t2, De_count
     
#///////////////////////////////////////////////////////////////////////////////////////////////
# Initialize registers for variable counting
    la $t0, equation1            # Pointer to current position in buffer
    li $t9, 0                    # Variable counter
    li $t8, 0                    # Invalid variable flag
#//////////////////////////////////////////////////
 la $t0, equation1               # $t0 will hold the address of source
 la $t1, equation                # $t1 will hold the address of destination   
 li $t2, 1024                    # $t2 will count the remaining bytes to copy
copy_loop:
    blez $t2, count_variabl      # If $t2 <= 0, end copying
    lb $t3, 0($t0)               # Load byte from address in $t0 (source) into $t3
    sb $t3, 0($t1)               # Store byte from $t3 into address in $t1 (destination)
    addi $t0, $t0, 1             # Increment source address by 1
    addi $t1, $t1, 1             # Increment destination address by 1
    addi $t2, $t2, -1            # Decrement the counter
    j copy_loop
#//////////////////////////////////////////////////////////////  
 Initialize_eqution2:
    la $t0, equation2            # Pointer to current position in buffer
    li $t9, 0                    # Variable counter
    li $t8, 0                    # Invalid variable flagv
 #/////////////////////////////////////////////////////////////////////////////////////
    la $t0, equation2            # $t0 will hold the address of source
    la $t1, equation             # $t1 will hold the address of destination   
    li $t2, 1024                 # $t2 will count the remaining bytes to copy
    j copy_loop
 #///////////////////////////////////////////////////////////////////////////////////
    Initialize_eqution3:
    la $t0, equation3    	 # Pointer to current position in buffer
    li $t9, 0         		 # Variable counter
    li $t8, 0         		 # Invalid variable flagv
 #//////////////////////////////////////////////////
    la $t0, equation3            # $t0 will hold the address of source
    la $t1, equation             # $t1 will hold the address of destination   
    li $t2, 1024                 # $t2 will count the remaining bytes to copy
    j copy_loop
#//////////////////////////////////////////////////////////////  
count_variabl:
    la $t0, equation    	 # Pointer to current position in buffer
    li $t9, 0         		 # Variable counter
    li $t8, 0         		 # Invalid variable flagv
count_variables:
    
    lb $t6, 0($t0)               # Load current character from buffer
    beqz $t6, check_count        # End of string, go to count check

# Check if the character is 'x', 'y', or 'z'
    li $t7, 'x'
    beq $t6, $t7, increment_counter
    li $t7, 'y'
    beq $t6, $t7, increment_counter
    li $t7, 'z'
    beq $t6, $t7, increment_counter

# Check if it's an invalid variable (any letter other than 'x', 'y', or 'z')
    li $t7, 'a'
    blt $t6, $t7, next_char_count  # Ignore non-letter characters
    li $t7, 'z'
    bgt $t6, $t7, next_char_count
    li $t8, 1                      # Set flag if an invalid variable is found
    j next_char_count

increment_counter:
    addi $t9, $t9, 1          	   # Increment variable counter
    j next_char_count

next_char_count:
    addi $t0, $t0, 1          	   # Move to the next character
    j count_variables

check_count:
# Check if there were invalid variables or incorrect variable count (2 or 3)
    bne $t8, $zero, print_error_format   # If invalid variable found, print error
    li $t7, 2
    bne $t9, $t7, check_three_vars
    j continue_parsing

check_three_vars:
    li $t7, 3
    bne $t9, $t7, print_error_format     # If not 2 or 3 variables, print error

continue_parsing:
# Reset pointer for parsing after counting
    la $t0, equation
    
#///////////////////////////////////////////////////////////////////////////////////////////    
Initialize:
# Initialize parsing registers
    li $t1, 0         # Accumulated coefficient
    li $t2, 1         # Sign (1 for positive, -1 for negative)
    li $s1, 0         # Coefficient of x
    li $s2, 0         # Coefficient of y
    li $s3, 0         # Coefficient of z
    li $s4, 0         # Result (RHS)
    li $t5, 0         # Result flag (0 = LHS, 1 = RHS)

parse_loop:
    lb $t6, 0($t0)    # Load current character from buffer
    beqz $t6, end_parse     # End if null character is found

# Check for '=' to switch to result side
    beq $t6, '=', switch_to_result

# If on RHS, parse RHS value
    beq $t5, 1, parse_rhs   # If on RHS, parse the RHS result

# Check for signs (+ or -)
    beq $t6, '+', set_positive
    beq $t6, '-', set_negative

# Check if the current character is a digit (0-9)
    li $t7, '0'
    sub $t7, $t6, $t7
    bltz $t7, check_var        # Not a digit, check if it's a variable
    li $t8, 9
    bgt $t7, $t8, check_var    # If greater than 9, not a digit

# Process digit, update accumulated coefficient
    sub $t7, $t6, '0'         # Convert ASCII to integer
    mul $t1, $t1, 10          # Shift left by one decimal place
    add $t1, $t1, $t7         # Add the new digit
    j next_char

check_var:
# Check if the character is 'x', 'y', or 'z'
    li $t7, 'x'
    beq $t6, $t7, store_x
    li $t7, 'y'
    beq $t6, $t7, store_y
    li $t7, 'z'
    beq $t6, $t7, store_z
    j next_char               # Skip other characters

store_x:
    beqz $t1, set_default_x   # If coefficient is zero, set to 1
    j store_x_normal

set_default_x:
    li $t1, 1                 # Set default to 1
    j store_x_normal

store_x_normal:
    mul $t1, $t1, $t2         # Apply sign
    add $s1, $s1, $t1         # Update coefficient for x
    j reset_coeff

store_y:
    beqz $t1, set_default_y   # If coefficient is zero, set to 1
    j store_y_normal

set_default_y:
    li $t1, 1                 # Set default to 1
    j store_y_normal

store_y_normal:
    mul $t1, $t1, $t2         # Apply sign
    add $s2, $s2, $t1         # Update coefficient for y
    j reset_coeff

store_z:
    beqz $t1, set_default_z   # If coefficient is zero, set to 1
    j store_z_normal

set_default_z:
    li $t1, 1                 # Set default to 1
    j store_z_normal

store_z_normal:
    mul $t1, $t1, $t2         # Apply sign
    add $s3, $s3, $t1         # Update coefficient for z
    j reset_coeff

reset_coeff:
    li $t1, 0                 # Reset coefficient accumulator
    li $t2, 1                 # Reset sign to positive
    j next_char

set_positive:
    li $t2, 1                 # Set sign to positive
    j next_char

set_negative:
    li $t2, -1                # Set sign to negative
    j next_char

switch_to_result:
    li $t5, 1                 # Set flag to indicate parsing RHS
    addi $t0, $t0, 1          # Move past the '='
    j parse_loop

parse_rhs:
    # Parse digits for RHS result
    li $t7, '0'
    sub $t7, $t6, $t7
    bltz $t7, next_char       # Skip if not a digit
    li $t8, 9
    bgt $t7, $t8, next_char   # Skip if greater than 9

    sub $t7, $t6, '0'         # Convert ASCII to integer
    mul $s4, $s4, 10          # Shift left by one decimal place
    add $s4, $s4, $t7         # Add the new digit
    j next_char

next_char:
    addi $t0, $t0, 1          # Move to the next character
    j parse_loop
#///////////////////////////////////////////////////////////////////////////////////////////////
end_parse:
#store the coefficient 

#equation1:
     li $t1, 1                          # Load immediate value 1 into $t3
     li $t2, 2
     lw $t4, De_count
     beq $t4,$t2, svae_eqution3
     beq $t4,$t1, svae_eqution2  
     
#///////////////////////////////////////////////////////////
     lw $t4, x1           # Load address of counter into $t2
     lw $t5, y1           # Load address of counter into $t2
     lw $t6, z1           # Load address of counter into $t2
     lw $t7, constant1           # Load address of counter into $t2
     sw $s1 ,x1
     sw $s2 ,y1
     sw $s3 ,z1
     sw $s4 ,constant1
     j contune_save
#//////////////////////////////////////////////////////////////////////////   
     svae_eqution3:
     lw $t4, x3           # Load address of counter into $t2
     lw $t5, y3           # Load address of counter into $t2
     lw $t6, z3           # Load address of counter into $t2
     lw $t7, constant3           # Load address of counter into $t2
     sw $s1 ,x3
     sw $s2 ,y3
     sw $s3 ,z3
     sw $s4 ,constant3
     j contune_save
     
     svae_eqution2:
     lw $t4, x2           # Load address of counter into $t2
     lw $t5, y2           # Load address of counter into $t2
     lw $t6, z2           # Load address of counter into $t2
     lw $t7, constant2           # Load address of counter into $t2
     sw $s1 ,x2
     sw $s2 ,y2
     sw $s3 ,z2
     sw $s4 ,constant2
     j contune_save
     
 #//////////////////////////////////////////////////////////////////////////   
contune_save:
     li $t4, 1                          # Load immediate value 1 into $t3
     li $t5, 2
     li $t6, 3
     lw $t2, De_count           # Load address of counter into $t2
     lw $t7,count
     addi $t2,$t2,-1
    
     sw $t2, De_count
     
     beq $t2,$t5, Initialize_eqution3
     beq $t2,$t4, Initialize_eqution2
 
     beq $t7,$t5,solve_2x2
     beq $t7,$t6,solve_3x3
     j Reset_space

#///////////////////////////////////////////////////////////////////////////////////////////////
solve_2x2:
    # Read coefficients for 2x2 system
    # Equation 1
    
    lw $t0, x3  # x1
    lw $t1, y3  # y1
    
    lw $t6, z3  #z1
    bnez $t6 ,print_error_format
    lw $t2, constant3  # c1
  #/////////////////////////
    lw $t3, x2  # x2
    lw $t4, y2  # y2
    lw $t6, z2  #z2
    bnez $t6 ,print_error_format
    lw $t6 ,z1  #z11
    bnez $t6 ,print_error_format
    lw $t5, constant2  # c2
     
     # Calculate determinant D = x1*y2 - x2*y1
    mul $s2, $t0, $t4      # s2 = x1 * y2
    mul $s3, $t3, $t1      # s3 = x2 * y1
    sub $s2, $s2, $s3      # D = a1 * b2 - a2 * b1
    beqz $s2, no_solution   # If D == 0, no unique solution

    # Convert D to float and store in $f4
    mtc1 $s2, $f4
    cvt.s.w $f4, $f4

    # Calculate Dx = c1*y2 - c2*y1
    mul $s1, $t2, $t4      # s1 = c1 * y2
    mul $s3, $t1, $t5      # s3 = c2 * y1
    sub $s1, $s1, $s3      # Dx = c1 * b2 - c2 * b1

    # Convert Dx to float and divide by D for x
    mtc1 $s1, $f6
    cvt.s.w $f6, $f6
    div.s $f6, $f6, $f4    # x = Dx / D
    s.s $f6, Result_x      # Store result in memory

    # Calculate Dy = c2*x1 - c1*x2
    mul $s3, $t0, $t5      # s3 = c2 * x1
    mul $s4, $t2, $t3      # s4 = c1 * x2
    sub $s3, $s3, $s4      # Dy = c2 * x1 - c1 * x2

    # Convert Dy to float and divide by D for y
    mtc1 $s3, $f6
    cvt.s.w $f6, $f6
    div.s $f6, $f6, $f4    # y = Dy / D
    s.s $f6, Result_y      # Store result in memory


    
    j print_result_system
#//////////////////////////////////////////////////////////////////////////////
solve_3x3:
 
    # Equation 1
    lw $t0 ,x1         # x1
    lw $t1 ,y1         # y1
    lw $t2 ,z1         # z1
    lw $t3 ,constant1  # c1
    beqz $t2 ,print_error_format
    
    # Equation 2
    lw $t4 ,x2         # x2
    lw $t5 ,y2         # y2
    lw $t6 ,z2         # z2
    lw $t7 ,constant2  # c2
    beqz $t6 ,print_error_format
    
    # Equation 3
    lw $t8 ,x3         # x3
    lw $t9, y3         # y3
    lw $s0, z3         # z3
    lw $s1, constant3  # c3
    beqz $s0 ,print_error_format
    
        # Calculate D (determinant)
    mul $s2, $t5, $s0          # y2 * z3
    mul $s3, $t9, $t6          # y3 * z2
    sub $s4, $s2, $s3          # y2 * z3 - y3 * z2
    mul $s5, $t0, $s4          # x1 * (y2 * z3 - y3 * z2)

    mul $s2, $t4, $s0          # x2 * z3
    mul $s3, $t8, $t6          # x3 * z2
    sub $s4, $s2, $s3          # x2 * z3 - x3 * z2
    mul $s2, $t1, $s4          # y1 * (x2 * z3 - x3 * z2)
    sub $s5, $s5, $s2          # D = x1 * (...) - y1 * (...)

    mul $s2, $t4, $t9          # x2 * y3
    mul $s3, $t8, $t5          # x3 * y2
    sub $s4, $s2, $s3          # x2 * y3 - x3 * y2
    mul $s2, $t2, $s4          # z1 * (x2 * y3 - x3 * y2)
    add $s5, $s5, $s2          # Final D value in $s5
    mtc1 $s5, $f4              # Move integer from $s5 to $f4
    cvt.s.w $f4, $f4           # Convert the integer in $f4 to a float
    
    # Check if D == 0 (no unique solution)
    beqz $s5, no_solution

    # Calculate D_x
    mul $s2, $t5, $s0   # s2 = y2 * z3 
    mul $s3, $t9, $t6   # s3 = y3 * z2
    sub $s2, $s2, $s3   # s2 = s2 - s3
    mul $s2, $s2, $t3   # s2 = s2 * t3
    
    mul $s4, $t7, $s0   # s4 = c2 * z3
    mul $s3, $s1, $t6   # s3 = c3 * z2
    sub $s4, $s4, $s3   # s4 = s4 - s5
    mul $s4, $s4, $t1   # s4 = s4 * t1
    
    mul $s6, $t7, $t9   # s6 = c2 * y3
    mul $s7, $t5, $s1   # s7 = y2 * c3
    sub $s6, $s6, $s7   # s6 = s6 - s7
    mul $s6, $s6, $t2   # s6 = s6 * t2
    
    sub $s2, $s2, $s4
    add $s6, $s2, $s6
    
    mtc1 $s6, $f6        # Move integer from $s6 to $f6
    cvt.s.w $f6, $f6     # Convert the integer in $f6 to a float

    div.s $f6, $f6, $f4
    s.s $f6 ,Result_x
    
    # Calculate D_y
    mul $s2, $t7, $s0   # s2 = c2 * z3 
    mul $s3, $t6, $s1   # s3 = z2 * c3
    sub $s2, $s2, $s3   # s2 = s2 - s3
    mul $s2, $s2, $t0   # s2 = s2 * x1
    
    mul $s4, $t4, $s0   # s4 = x2 * z3
    mul $s3, $t8, $t6   # s3 = x3 * z2
    sub $s4, $s4, $s3   # s4 = s4 - s5
    mul $s4, $s4, $t3   # s4 = s4 * c1
    
    mul $s6, $t4, $s1   # s6 = c3 * x2
    mul $s7, $t7, $t8   # s7 = x3 * c2
    sub $s6, $s6, $s7   # s6 = s6 - s7
    mul $s6, $s6, $t2   # s6 = s6 * z1
    
    sub $s2, $s2, $s4
    add $s6, $s2, $s6
    
    mtc1 $s6, $f7        # Move integer from $s6 to $f6
    cvt.s.w $f7, $f7     # Convert the integer in $f6 to a float

    div.s $f7, $f7, $f4
    s.s $f7 ,Result_y

    # Calculate D_z
    mul $s2, $t5, $s1   # s2 = c3 * y2 
    mul $s3, $t9, $t7   # s3 = y3 * c2
    sub $s2, $s2, $s3   # s2 = s2 - s3
    mul $s2, $s2, $t0   # s2 = s2 * x1
    
    mul $s4, $t4, $s1   # s4 = x2 * c3
    mul $s3, $t8, $t7   # s3 = x3 * c2
    sub $s4, $s4, $s3   # s4 = s4 - s5
    mul $s4, $s4, $t1   # s4 = s4 * y1
    
    mul $s6, $t4, $t9   # s6 = y3 * x2
    mul $s7, $t5, $t8   # s7 = x3 * y2
    sub $s6, $s6, $s7   # s6 = s6 - s7
    mul $s6, $s6, $t3   # s6 = s6 * c1
    
    sub $s2, $s2, $s4
    add $s6, $s2, $s6
    
    mtc1 $s6, $f8        # Move integer from $s6 to $f6
    cvt.s.w $f8, $f8     # Convert the integer in $f6 to a float

    div.s $f8, $f8, $f4
    s.s $f8 ,Result_z
    
    j print_result_system

#//////////////////////////////////////////////////////////////////////////////
Reset_space:
    la   $a0, equation            # Load address of equation space into $a0
    li   $a1, 1024                # Load size (1024 bytes) into $a1
    jal  reset_space              # Call reset function

    la   $a0, equation1           # Load address of equation1 space into $a0
    li   $a1, 1024                # Load size (1024 bytes) into $a1
    jal  reset_space              # Call reset function

    la   $a0, equation2           # Load address of equation2 space into $a0
    li   $a1, 1024                # Load size (1024 bytes) into $a1
    jal  reset_space              # Call reset function

    la   $a0, equation3           # Load address of equation3 space into $a0
    li   $a1, 1024                # Load size (1024 bytes) into $a1
    jal  reset_space              # Call reset function
    
     sw $t2, count                # Store zero back into count
     sw $t2, De_count             # Store zero back into De_count
     sw $t2, x1                   # Store zero back into x1
     sw $t2, x2                   # Store zero back into x2
     sw $t2, x3                   # Store zero back into x3
     sw $t2, y1                   # Store zero back into y1
     sw $t2, y2                   # Store zero back into y2
     sw $t2, y3                   # Store zero back into y3
     sw $t2, z1			  # Store zero back into z1
     sw $t2, z2                   # Store zero back into z2
     sw $t2, z3                   # Store zero back into z3
     sw $t2, constant1            # Store zero back into constant1
     sw $t2, constant2            # Store zero back into constant2
     sw $t2, constant3            # Store zero back into constant3
     sw $t2, Result_x
     sw $t2, Result_y
     sw $t2, Result_z
     
     li $s3, 0 
    j read_loop  
 
#////////////////////////////////////////////////////////////////////////////////////////
# Function to reset memory space (clear it by writing 0s)
reset_space:
    # $a0 = address, $a1 = size
    li   $t0, 0                    # Set $t0 to 0 (value to store in memory)
    move $t2, $a1                  # Copy size into $t2 (byte counter)
    
reset_loop:
    sb   $t0, 0($a0)               # Store byte 0 at address in $a0
    addi $a0, $a0, 1               # Increment address by 1 byte
    addi $t2, $t2, -1              # Decrement byte counter
    bgtz $t2, reset_loop           # Loop if counter > 0
    
    jr   $ra                       # Return from function
           
            
 #///////////////////////////////////////////////////////////////////////////             
error_format:    
    # Reset line length
     li $s3, 0 
     li $t2, 0                       # Load zero into $t2
     sw $t2, count                   # Store zero back into count
     li $t2, 0                       # Load zero into $t2
     sw $t2, De_count                   # Store zero back into count  
     b read_loop            # Go back to reading the next line
#/////////////////////////////////////////////////////////////////////////////////
end_copy:
    # Reset line length and continue reading
    li $s3, 0
    b read_loop
#//////////////////////////////////////////////////////////////////////////////////        

print_result_system:  
    li $t7, 0
    lw $t6, print_option
    beq $t6, $t7, print_screen
    la $t7,1
    beq $t6, $t7, print_file
   
print_screen:
    li   $v0, 4             # Syscall for printing string
    la   $a0, Another_system       # Load address of newline string into $a0
    syscall                 # Print newlin
    
    li $v0, 4                    # Print "X = "
    la $a0, result_x
    syscall
    la $t7,Result_x
    l.s $f12,0($t7)                    # Print integer
    li $v0,2                         #  X result
    syscall
 
    # Print something before the newline
    li   $v0, 4             # Syscall for printing string
    la   $a0, newline       # Load address of newline string into $a0
    syscall 
                            # Print newlin
    li $v0, 4               # Print "Y = "
    la $a0, result_y
    syscall
    la $t7,Result_y
    l.s $f12,0($t7)         # Print integer
    li $v0,2                #  y result
    syscall
# check the system if its 3 variable 
     li $t6, 3
     lw $t7,count
     beq $t7,$t6, print_Z
     j complete_print
print_Z:
    li   $v0, 4             # Syscall for printing string
    la   $a0, newline       # Load address of newline string into $a0
    syscall                 # Print newlin
    
    li $v0, 4               # Print "z = "
    la $a0, result_z
    syscall
    
    la $t7,Result_z
    l.s $f12,0($t7)         # Print integer
    li $v0,2                #  z result
    syscall
    
 complete_print:
    li   $v0, 4             # Syscall for printing string
    la   $a0, newline       # Load address of newline string into $a0
    syscall   
    li   $v0, 4             # Syscall for printing string
    la   $a0, newline       # Load address of newline string into $a0
    syscall 
     
  j Reset_space
  
 print_file:
    
    #bltz $t0, error          # Check for error if $t0 is negative (failure)
    lw $t0 ,output_file_descriptor
    # Print "X = "
    li   $v0, 15             # Syscall for writing to file
    move $a0, $t0            # File descriptor
    la   $a1, result_x       # Load address of result_x
    li   $a2, 4              # Length of the string "X = "
    syscall
    
    # Print the value of X (result_x value)
    la   $t7, Result_x       # Load address of the float Result_x
    l.s  $f1, 0($t7)        # Load the float value into $f12
    
    la $a0, buffer_of_convert       # Address of buffer
    li $a1, 24                     # Buffer size
    jal float_to_string            # Call conversion function
   
    lw $t0 ,output_file_descriptor
    # Print the value "X = "
    li   $v0, 15             # Syscall for writing to file
    move $a0, $t0            # File descriptor
    la   $a1, buffer_of_convert       # Load address of result_x
    li   $a2, 4              # Length of the string "X = "
    syscall

    # Print newline after X
    li   $v0, 15             # Syscall for writing to file
    move $a0, $t0            # File descriptor
    la   $a1, newline        # Load address of newline
    li   $a2, 1              # Length of newline
    syscall

    # Print "Y = "
    li   $v0, 15             # Syscall for writing to file
    move $a0, $t0            # File descriptor
    la   $a1, result_y       # Load address of result_y
    li   $a2, 4              # Length of "Y = "
    syscall

    # Print the value of Y (result_y value)
    la   $t7, Result_y       # Load address of the float Result_y
    l.s  $f1, 0($t7)        # Load the float value into $f12

    la $a0, buffer_of_convert       # Address of buffer
    li $a1, 24                      # Buffer size
    jal float_to_string  # Call conversion function
    
    lw $t0 ,output_file_descriptor
    
    li   $v0, 15             # Syscall for writing to file
    move $a0, $t0            # File descriptor
    la   $a1, buffer_of_convert       # Load address of result_x
    li   $a2, 4              # Length of the string "X = "
    syscall
    
    li   $v0, 15             # Syscall for writing to file
    move $a0, $t0            # File descriptor
    la   $a1, newline        # Load address of newline
    li   $a2, 1              # Length of newline
    syscall
    
    # Check if we need to print the third variable (Z)
    li   $t6, 3              # Set $t6 to 3
    lw   $t7, count          # Load the count value into $t7
    beq  $t7, $t6, print_Z2  # If count == 3, jump to print_Z2
    j    complete_print2     # Jump to complete_print2 if count is not 3

print_Z2:
    # Print "Z = "
    li   $v0, 15             # Syscall for writing to file
    move $a0, $t0            # File descriptor
    la   $a1, result_z       # Load address of result_z
    li   $a2, 4              # Length of "Z = "
    syscall

    # Print the value of Z (result_z value)
    la   $t7, Result_z       # Load address of the float Result_z
    l.s  $f1, 0($t7)        # Load the float value into $f12
    
    la $a0, buffer_of_convert       # Address of buffer
    li $a1, 24                      # Buffer size
    jal float_to_string             # Call conversion function
    
    lw $t0 ,output_file_descriptor
    
    li   $v0, 15             # Syscall for writing to file
    move $a0, $t0            # File descriptor
    la   $a1, buffer_of_convert       # Load address of result_x
    li   $a2, 4              # Length of the string "X = "
    syscall
    
    li   $v0, 15             # Syscall for writing to file
    move $a0, $t0            # File descriptor
    la   $a1, newline        # Load address of newline
    li   $a2, 1              # Length of newline
    syscall
    
complete_print2:
    lw $t0 ,output_file_descriptor
    # Print "System complete."
    li   $v0, 15             # Syscall for writing to file
    move $a0, $t0            # File descriptor
    la   $a1, Another_system # Load address of Another_system
    li   $a2, 23             # Length of the string "System complete."
    syscall

    li   $v0, 15             # Syscall for writing to file
    move $a0, $t0            # File descriptor
    la   $a1, newline        # Load address of newline
    li   $a2, 1              # Length of newline
    syscall


    j Reset_space


#///////////////////////////////////////////////////////////////////////////////////
print_error_format :
    li $t7, 0
    lw $t6, print_option
    beq $t6, $t7, screen_print2
    la $t7,1
    beq $t6, $t7, file_print2

screen_print2:
    la $a0, error_message         
    li $v0, 4                    # Syscall for printing string
    syscall     
    j error_format
    
file_print2:
 # Open the file for writing (appending mode)
     lw $t0 ,output_file_descriptor
    
    li   $v0, 15             # Syscall for writing to file
    move $a0, $t0            # File descriptor
    la   $a1, error_message       # Load address of result_x
    li   $a2, 120              # Length of the string "X = "
    syscall
    li   $v0, 15             # Syscall for writing to file
    move $a0, $t0            # File descriptor
    la   $a1, newline       # Load address of result_x
    li   $a2, 1              # Length of the string "X = "
    syscall
    j error_format
#///////////////////////////////////////////////////////////////////////////////////  
error:
    li   $v0, 4              # Print string syscall
    la   $a0, error_file    # Load address of the error message
    syscall
    
    j Reset_space
#//////////////////////////////////////////////////////////////////////////////////////
no_solution:                   # its use to print the no solution error on screen
    li $t7, 0
    lw $t6, print_option
    beq $t6, $t7, screen_print
    la $t7,1
    beq $t6, $t7, file_print
    
screen_print:                 # its use to print the no solution error on file 
    li $v0, 4
    la $a0, no_solution_msg
    syscall
 j Reset_space
 
file_print:                  # its use to print the error of the file 
 # Open the file for writing (appending mode)
    lw $t0 ,output_file_descriptor
    
    li   $v0, 15             # Syscall for writing to file
    move $a0, $t0            # File descriptor
    la   $a1, no_solution_msg       # Load address of result_x
    li   $a2, 30              # Length of the string "X = "
    syscall
    li   $v0, 15             # Syscall for writing to file
    move $a0, $t0            # File descriptor
    la   $a1, newline       # Load address of result_x
    li   $a2, 1              # Length of the string "X = "
    syscall
    
 j Reset_space
#----------------------------------------------------------------------------------------------
error_in :
    li $v0, 4
    la $a0, error_file
    syscall
#-------------------------------------------------------------------------------------------- 
read_done:
  # Prompt for filename
        li $v0, 4
        la $a0, prompt_Exit
        syscall

        # Read filename input
        li $v0, 8
        la $a0, buffer
        li $a1, 256
        syscall

    # Check for exit condition
        lb $t1, buffer         # Load first character of buffer
        li $t2, 'e'
        li $t3, 'E'
        beq $t1, $t2, exit
        beq $t1, $t3, exit

       lw $t0 ,input_file_descriptor
       # close file
       li $v0, 16           # syscall for close file
       move $a0, $s0        # file descriptor to close
       syscall              # close file
    
    
       lw $t0 ,output_file_descriptor
       # close file
       li $v0, 16           # syscall for close file
       move $a0, $s0        # file descriptor to close
       syscall  
       
       j loop
#----------------------------------------------------------------------------------------------------
float_to_string:
    # Save registers on the stack
    pushFourRegisterOnTheStack($ra, $a0, $a1, $s1)
    
    # Separate integer and fractional parts
    mov.s $f3, $f1                # Copy the float to $f3
    cvt.w.s $f3, $f3              # Convert to integer
    mfc1 $s0, $f3                 # $s0 = integer part
    
    li $t0, 100                   # Multiplier for fractional calculation
    mul $t0, $t0, $s0             # $t0 = integer part * 100
    
    # Calculate fractional part
    l.s $f7, Ten                  # Load constant 10.0
    mul.s $f1, $f1, $f7           # Scale by 10
    mul.s $f1, $f1, $f7           # Scale again by 10 (100x)
    cvt.w.s $f1, $f1              # Convert scaled float to integer
    mfc1 $s1, $f1                 # $t0 = scaled float as integer
    mul $t1, $s0, 100             # $t1 = integer part * 100
    sub $s1, $s1, $t0             # $s1 = fractional part (2 digits)


    # Convert integer part to string
    move $a0, $s0                 # Input integer part
    la $a1, buffer_of_convert                # Buffer address
    li $a2, 24                    # Buffer size
    jal int_to_string             # Call integer-to-string converter

    # Restore registers
    popFourRegisterFromTheStack($ra, $a0, $a1, $s1)
    
    # Store integer part in the output buffer
storeIntegerPart:
        lb $t0, 0($v0)            # Load first digit of integer part
        beqz $t0, storeFloatingPoint # If null, proceed to fractional part
        sb $t0, 0($a0)            # Store digit
        addiu $v0, $v0, 1         # Increment source pointer
        addiu $a0, $a0, 1         # Increment destination pointer
        j storeIntegerPart        # Repeat

    # Add decimal point
storeFloatingPoint:
        li $t0, 46                # ASCII '.' = 46
        sb $t0, 0($a0)            # Store '.'
        addiu $a0, $a0, 1         # Increment destination pointer
    
    # Convert fractional part to string
  
    pushThreeRegisterOnTheStack($ra, $a0, $a1)
    move $a0, $s1                 # Input fractional part
    la $a1, buffer_of_convert                # Buffer address
    li $a2, 24                    # Buffer size
    addiu $a0, $a0, -1
    
    bge $a0 ,0 ,convert_to_string    # check if the number is less than 0 to sit it to zero 
    li $a0 , 0
    
convert_to_string:       
    jal int_to_string             # Call integer-to-string converter
    popThreeRegisterFromTheStack($ra, $a0, $a1)
    
    # Store fractional part in the output buffer
    storeFractionalPart:
        lb $t0, 0($v0)            # Load first digit of fractional part
        beqz $t0, finishConvertingFloatToString # Exit if null
        sb $t0, 0($a0)            # Store digit
        addiu $v0, $v0, 1         # Increment source pointer
        addiu $a0, $a0, 1         # Increment destination pointer
        j storeFractionalPart     # Repeat
    
    # Null-terminate the string
    finishConvertingFloatToString:
        sb $zero, 0($a0)          # Null character at the end
        jr $ra                    # Return

#---------------------------------------------------
int_to_string:
    li $t0, 10                   # $t0 = divisor = 10
    addiu $t2, $a2, -1          # Calculate buffer end
    addu $v0, $a1, $t2          # $v0 = end of buffer
    sb $zero, 0($v0)            # Null-terminate the string
L_int2str:
    beqz $a2, return_int_to_string    # If no more bytes remain, end conversion
    divu $a0, $t0                     # LO = value / 10, HI = value % 10
    mflo $a0                          # $a0 = value / 10
    mfhi $t1                          # $t1 = value % 10
    addiu $t1, $t1, 48                # Convert digit to ASCII
    addiu $v0, $v0, -1                # Move to previous byte in buffer
    sb $t1, 0($v0)                    # Store ASCII character
    addiu $a2, $a2, -1                # Decrement remaining buffer size
    bnez $a0, L_int2str               # Loop if value is not zero
return_int_to_string: 
    jr $ra                            # Return to caller

#---------------------------------------------------   
exit:

    lw $t0 ,input_file_descriptor
    # close file
    li $v0, 16           # syscall for close file
    move $a0, $s0        # file descriptor to close
    syscall              # close file
    
    
    lw $t0 ,output_file_descriptor
    # close file
    li $v0, 16           # syscall for close file
    move $a0, $s0        # file descriptor to close
    syscall  
    
        
    # exit the program
    li $v0, 10
    syscall
