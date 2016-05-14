.eqv 	KEY_CODE 0xFFFF0004 		# ASCII code from keyboard, 1 byte
.eqv 	KEY_READY 0xFFFF0000 		# =1 if has a new keycode ?
 					# Auto clear after lw
.eqv 	DISPLAY_CODE 0xFFFF000C 	# ASCII code to show, 1 byte
.eqv 	DISPLAY_READY 0xFFFF0008 	# =1 if the display has already to do
 					# Auto clear after sw
.eqv 	SEVENSEG_LEFT 0xFFFF0011 	# Dia chi cua den led 7 doan trai.
.eqv 	SEVENSEG_RIGHT 0xFFFF0010 	# Dia chi cua den led 7 doan phai
 				
.eqv 	MASK_CAUSE_KEYBOARD 0x0000034 # Keyboard Cause
.data	
	time: 		.word 0x2710	# 10s
	msg_dialog: 	.asciiz "Start"
	test:		.asciiz "Pham Ngoc Thach Bach Khoa Ha Noi"
	list:		.word 0,6,91,79,102,109,125,7,127,111	# de ve tren den lep 7 doan
.text
 	li $k0, KEY_CODE
 	li $k1, KEY_READY

 	li $s0, DISPLAY_CODE
 	li $s1, DISPLAY_READY
 	la $s6, test	# dia chi xau test
	
 	la $a0, msg_dialog
 	li $v0, 50
 	syscall
 	beq $a0, $zero, start
 	j end
start :
	add $s2, $zero, $zero	# bien dem so ki tu nhap dung
			
	li $v0, 30
	syscall
	move $s7, $a0		# thoi gian bat dau
	la $a0, time
	lw $t0, 0($a0)
	add $s7, $s7, $t0	# thoi gian ket thuc 
loop: 	nop
	WaitForKey: 
		li $v0, 30
		syscall
		slt $t0, $s7, $a0
		bne $t0, $zero, end 	# het thoi gian
	
		lw $t1, 0($k1) 		# $t1 = [$k1] = KEY_READY
 		beq $t1, $zero, WaitForKey # if $t1 == 0 then Polling
	MakeIntR: 
		teqi $t1, 1 		# if $t0 = 1 then raise an Interrupt
 	j loop
end:
	la $s3, list
 	move $a0, $s2
 	li $v0, 1
 	syscall
 	add $s1, $zero, $zero
 	slti $t0, $s2, 10
 	beq $t0, $zero, two
 	
 	mul $s2, $s2, 4
 	add $s2, $s2, $s3
 	lw $a0, 0($s2)
 	li $t0, SEVENSEG_RIGHT # assign port's address
 	sb $a0, 0($t0) # assign new value
 	j exit
 	two:	
 		addi $s1, $s1, 1
 		subi $s2, $s2, 10
 		slti $t0, $s2, 10
 		beq $t0, $zero, two
 		
		
 		mul $s1, $s1, 4
 		add $s1, $s1, $s3
 		lw $a0, 0($s1)
 		li $t0, SEVENSEG_LEFT # assign port's address
 		sb $a0, 0($t0) # assign new value
 		
 		mul $s2, $s2, 4
 		add $s2, $s2, $s3
 		lw $a0, 0($s2)
 		li $t0, SEVENSEG_RIGHT # assign port's address
 		sb $a0, 0($t0) # assign new value
 	exit:
 		li $v0, 10
 		syscall
#---------------------------------------------------------------
# Interrupt subroutine
#---------------------------------------------------------------
.ktext 0x80000180
get_caus: 
	mfc0 $t1, $13 			# $t1 = Coproc0.cause
IsCount: 
	li $t2, MASK_CAUSE_KEYBOARD	# if Cause value confirm Keyboard..
 	and $at, $t1,$t2
	beq $at,$t2, Counter_Keyboard
 	j end_process
Counter_Keyboard:
	ReadKey: 
		lw $t0, 0($k0) 		# $t0 = [$k0] = KEY_CODE
		
		lb $t1, 0($s6)		#
		bne $t0, $t1, WaitForDis# Kiem tra xem ki tu nhap vao co dung khong
		addi $s2, $s2, 1	#
	WaitForDis: 
		lw $t2, 0($s1) 		# $t2 = [$s1] = DISPLAY_READY
 		beq $t2, $zero, WaitForDis # if $t2 == 0 then Polling
	ShowKey: 
		sw $t0, 0($s0) 		# show key
 		nop	
end_process:
	addi $s6, $s6, 1
	next_pc: 
		mfc0 $at, $14 		# $at <= Coproc0.$14 = Coproc0.epc
 		addi $at, $at, 4 	# $at = $at + 4 (next instruction)
 		mtc0 $at, $14 		# Coproc0.$14 = Coproc0.epc <= $at
 		
	return: eret 			# Return from exception
