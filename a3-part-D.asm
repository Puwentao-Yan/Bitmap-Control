# This code assumes the use of the "Bitmap Display" tool.
#
# Tool settings must be:
#   Unit Width in Pixels: 32
#   Unit Height in Pixels: 32
#   Display Width in Pixels: 512
#   Display Height in Pixels: 512
#   Based Address for display: 0x10010000 (static data)
#
# In effect, this produces a bitmap display of 16x16 pixels.


	.include "bitmap-routines.asm"

	.data
TELL_TALE:
	.word 0x12345678 0x9abcdef0	# Helps us visually detect where our part starts in .data section
KEYBOARD_EVENT_PENDING:
	.word	0x0
KEYBOARD_EVENT:
	.word   0x0
BOX_ROW:
	.word	0x0
BOX_COLUMN:
	.word	0x0

	.eqv LETTER_a 97
	.eqv LETTER_d 100
	.eqv LETTER_w 119
	.eqv LETTER_x 120
	.eqv BOX_COLOUR 0x0099ff33
	
	.globl main
	
	.text	
main:
# STUDENTS MAY MODIFY CODE BELOW
# vvvvvvvvvvvvvvvvvvvvvvvvvvvvvv

	# initialize variables
	add $s0, $zero, $zero
	add $s1, $zero, $zero
	add $s2, $zero, $zero
	add $s3, $zero, $zero
	add $a0, $zero, $zero
	add $a1, $zero, $zero
	# enable the keyboard device
	la $s0, 0xffff0000
	lb $s1, 0($s0)
	ori $s1, $s1, 0x02
	sb $s1, 0($s0)
	# draw stating box
	addi $a2, $zero, BOX_COLOUR
	jal draw_bitmap_box
	
check_for_event:
	la $s0, KEYBOARD_EVENT_PENDING
	lw $s1, 0($s0)
	beq $s1, 1, control_box # if KEYBOARD_EVENT_PENDING is 1, move to control_box branch
	beq $zero, $zero, check_for_event
	
	
	# Should never, *ever* arrive at this point
	# in the code.	

	addi $v0, $zero, 10

.data
    .eqv BOX_COLOUR_BLACK 0x00000000
.text

	addi $v0, $zero, BOX_COLOUR_BLACK
	syscall



# Draws a 4x4 pixel box in the "Bitmap Display" tool
# $a0: row of box's upper-left corner
# $a1: column of box's upper-left corner
# $a2: colour of box

draw_bitmap_box:
#
# You can copy-and-paste some of your code from part (c)
# to provide the procedure body.
#
	addi $sp, $sp, -16
	sw $s0, 12($sp)
	sw $s1, 8($sp)
	sw $s2, 4($sp)
	sw $ra, 0($sp)
	# initialize variables
	add $s0, $zero, $zero # $s0 is a counter for row_loop
	add $s1, $zero, $zero # $s1 is a counter for col_loop
	add $s2, $zero, $a0   # save $a0
	subi $a0, $a0, 1      # minus 1 first because we will add 1 in the following loop and we want $a0 remains same
	# in the row_loop, we iterate 4 times. In each iteration we color one pixel vertically (Y axis)
row_loop:
	beq $s0, 4, col_loop
	addi $a0, $a0, 1      # increase Y axis position
	jal set_pixel
	addi $s0, $s0, 1
	b row_loop
col_loop:
	beq $s1, 3, exit      # loop 3 times since we already finished one row_loop.
	add $s0, $zero, $zero # clear $s0, because we will loop through row_loop again
	addi $s1, $s1, 1      
	add $a0, $zero, $s2   # restore $a0 (Y axis position), because we will move to the next column
	subi $a0, $a0, 1      # minus 1 because we will add 1 in the following row_loop and we want $a0 remains same
	addi $a1, $a1, 1      # move to the next column
	b row_loop
exit:
	lw $a0, BOX_ROW       # restore values for $a0 and $a1 because we changed
	lw $a1, BOX_COLUMN    # them during the row_loop and col_loop.
	
	lw $ra, 0($sp)
	sw $s2, 4($sp)
	sw $s1, 8($sp)
	sw $s0, 12($sp)
	addi $sp, $sp, 16
	jr $ra
	
	# control_box decides how the box is showed and moved.
control_box:
	addi $sp, $sp, -12
	sw $s0, 8($sp)
	sw $s1, 4($sp)
	sw $ra, 0($sp)

	addi $a2, $zero, BOX_COLOUR_BLACK # clear previous box
	jal draw_bitmap_box
	jal check_key   # move to check_key to update box's coordinate
	addi $a2, $zero, BOX_COLOUR       # draw the new box
	jal draw_bitmap_box

	la $s0, KEYBOARD_EVENT_PENDING    # set KEYBOARD_EVENT_PENDING back to 0
	add $s1, $zero, $zero
	sw $s1, 0($s0)
	
	lw $ra, 0($sp)
	lw $s1, 4($sp)
	lw $s0, 8($sp)
	addi $sp, $sp, 12
	jr $ra

	# check_key checks which key just been pressed and then updates box's coordinate 
check_key:
	addi $sp, $sp, -12
	sw $s2, 8($sp)
	sw $s3, 4($sp)
	sw $ra, 0($sp)
	
	la $s2, KEYBOARD_EVENT
	lw $s3, 0($s2) # $s3 now contains key just pressed
	# key 'w' and 'x' correspond to Y axis which is $a0: row of box
	# key 'a' and 'd' correspond to X axis which is $a1: column of box
letter_w:
	bne $s3, LETTER_w, letter_x
	lw $a0, BOX_ROW
	subi $a0, $a0, 1 # minus 1 since we are moving upwards
	sw $a0, BOX_ROW
	b exit_check_key
letter_x:
	bne $s3, LETTER_x, letter_a
	lw $a0, BOX_ROW
	addi $a0, $a0, 1 # plus 1 since we are moving downwards
	sw $a0, BOX_ROW
	b exit_check_key
letter_a:
	bne $s3, LETTER_a, letter_d
	lw $a1, BOX_COLUMN
	subi $a1, $a1, 1 # minus 1 since we are moving leftwards
	sw $a1, BOX_COLUMN
	b exit_check_key
letter_d:
	bne $s3, LETTER_d, wrong_key
	lw $a1, BOX_COLUMN
	addi $a1, $a1, 1 # plus 1 since we are moving rightwards
	sw $a1, BOX_COLUMN
	b exit_check_key
	
	# end up to wrong_key because we pressed keys that are not 'w', 'a', 'x', 'd'
wrong_key:
	addi $a2, $zero, BOX_COLOUR # color box again since we clear the box at the beginning
	jal draw_bitmap_box
	la $s0, KEYBOARD_EVENT_PENDING
	add $s1, $zero, $zero
	sw $s1, 0($s0)
	b check_for_event
	
exit_check_key:
	lw $ra, 0($sp)
	lw $s3, 4($sp)
	lw $s2, 8($sp)
	addi $sp, $sp, 12
	jr $ra


	.kdata

	.ktext 0x80000180
#
# You can copy-and-paste some of your code from part (a)
# to provide elements of the interrupt handler.
#
__kernel_entry:
	mfc0 $k0, $13		# $13 is the cause register in Coproc0
	andi $k1, $k0, 0x7c	# mask bits 2 to 6 to check exception code
	srl  $k1, $k1, 2	# shift ExcCode bits for easier comparison
	beq $zero, $k1, __is_interrupt
	
__is_exception:
	beq $zero, $zero, __exit_exception
	
__is_interrupt:
	andi $k1, $k0, 0x0100	# check bit 8
	bne $k1, $zero, __is_keyboard_interrupt	 # if bit 8 set, then we have a keyboard interrupt.
	beq $zero, $zero, __exit_exception
	
__is_keyboard_interrupt:
	la $k0, 0xffff0004   # 0xffff0004 is address for keyboard
	lw $k1, 0($k0)
	la $k0, KEYBOARD_EVENT
	sw $k1, 0($k0)
	la $k0, KEYBOARD_EVENT_PENDING	
	lw $k1, 0($k0)
	addi $k1, $k1, 1     # set a ketboard event is pending
	sw $k1, 0($k0)
	
__exit_exception:
	eret


.data

# Any additional .text area "variables" that you need can
# be added in this spot. The assembler will ensure that whatever
# directives appear here will be placed in memory following the
# data items at the top of this file.

	
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
# STUDENTS MAY MODIFY CODE ABOVE


.eqv BOX_COLOUR_WHITE 0x00FFFFFF
	
