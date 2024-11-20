
.data
buffer: .space 64       # Buffer for storing the string
bufferrr: .float 12.24
Ten:    .float 10.0     # Constant 10.0


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

.text
main:

    la $a0, bufferrr       # Address of buffer
    li $a1, 64           # Buffer size
    jal float_to_string  # Call conversion function
    
    # Print the resulting string (for debugging)
    la $a0, bufferrr       # Load buffer address
    li $v0, 4            # Syscall: print_string
    syscall
    
    li $v0, 10           # Exit program
    syscall

float_to_string:
    # Save registers on the stack
    pushFourRegisterOnTheStack($ra, $a0, $a1, $s1)
    
    # Separate integer and fractional parts of the float
    mov.s $f3, $f1                # Copy the float to $f3
    cvt.w.s $f3, $f3              # Convert to integer
    mfc1 $s0, $f3                 # $s0 = integer part
    
    li $t0, 100                   # Multiplier for fractional calculation
    mul $t0, $t0, $s0             # $t0 = integer part * 100
    
    l.s $f7, Ten                  # $f7 = 10.0 (constant value)
    mul.s $f1, $f1, $f7           # Scale floating point by 10
    mul.s $f1, $f1, $f7           # Scale again by 10 (to get 100x)
    cvt.w.s $f1, $f1              # Convert to integer
    mfc1 $s1, $f1                 # $s1 = scaled integer
    
    subu $s1, $s1, $t0            # $s1 = fractional part (2 digits)
    
    # Convert integer part to string
    move $a0, $s0                 # Input integer part
    la $a1, buffer                # Buffer address
    li $a2, 20                    # Buffer size
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
    la $a1, buffer                # Buffer address
    li $a2, 20                    # Buffer size
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


int_to_string:
    li $t0, 10  # $t0 = divisor = 10
    addiu $t2, $a2, -1
    addu $v0, $a1, $t2
    sb $zero, 0($v0)
    L_int2str:
        beqz $a2, return_int_to_string    #if there is no more bytes remaining in the buffer, end the conversion
        divu $a0, $t0   # LO  = value/10, HI = value%10
        mflo $a0  # $a0 = value/10
        mfhi $t1  # $t1 = value%10
        addiu $t1,$t1,48 # convert digit into ASCII
        addiu $v0, $v0, -1    #point to previous byte
        sb $t1, 0($v0) # store character in memory
        addiu $a2, $a2, -1 #decrement remaining size
        bnez $a0, L_int2str  # loop if value is not 0
        return_int_to_string: 
        jr $ra # return to caller
#---------------------------------------------------