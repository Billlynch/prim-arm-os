;-------------------------------------------------------------------------------
;			LCD function 
;			Bill Lynch
;			Version: 0.3
;			7th Feb 2017
;
;This function provides methods to print a string to the LCD (HD44780), Also
;provides functions for moving to the second line of input, scrolling the
;display, writing a character, shifting the cursor clearing the display, 
;changing the back light. As well as a delay for the scroll of the LCD. This is
;now done using SVC calls. See the OS.s file to see the call numbers
;
; Last modified: 10/05/2017 (BL)
;
; Know bugs: Modifies the bits used for the LCD
;			 Cannot print string longer than the LCD (both lines)
;
; TODO: Make shift move from bottom to top line	
;
;-------------------------------------------------------------------------------

;This will print the value of R0 onto the display in HEX
PrintHex8			PUSH	{LR}						;store the LR
					MOV 	R0, R0, ROR #4				;rotate the value right 4
					BL		PrintHex4					;print out this
					MOV 	R0, R0, ROR #28				;rotate the value back (left 4 = right 28)
					BL		PrintHex4					;print out this 
					POP 	{PC}						;return to calling function

;Converts the Hex to a char to print
PrintHex4			PUSH	{R0}						;store R0
					AND		R0, R0, #mask_but_LSb		;Mask of the rest
					CMP		R0, #max_digit				;See if letter or Digit
					ADDGT	R0, R0, #letter_offset 		;Set to Letter ASCII
					ADDLE	R0,	R0,	#number_offset		;Set to Digit ASCII 
					SVC		0							;Write the char
					POP		{R0}						;restore R0
					MOV		PC,LR						;return to the calling function

;This function writes a string which is pointed to in R1 puts the char in R1
write_str			LDRB 	R0, [R1], #&1				;Read  next char in the string
					CMP 	R0, #'\0'					;Check not end of the string
					MOVEQ 	PC, LR						;If it is return to caller
					CMP		R0, #'\n'					;Check if char is new-line
					PUSH 	{LR, R1}					;store the LR and R2 - which holds the string
					SVCEQ 	6							;move to the second line - SVC will save the flags so this is safe						
					SVCNE 	0							;write that char if it wasn't the end
					POP 	{LR, R1}					;put the stored values back
					B 		write_str					;loop round



;This will set the input to be on the second line.  Position in R1
set_CG				PUSH 	{LR}						;No need to push R5 gets overridden anyway
					BL 		ready						;Wait for the display to be ready
					ORR 	R5, R1, #LCD_DB6			;set R5 to the correct Data
					STRB 	R5, [R4, #DATA]				;store the data in R5
					LDRB 	R5, [R4, #CONTROL]			;load in the current control signal
					BIC 	R5, R5, #(LCD_RS OR LCD_RW)	;load 0 0 into the RS and RW reg
					BL 		strobe_en					;strobe the enable	
					POP 	{LR}						;restore the LR
					B		SVC_Complete				;return to the SVC cleanup function

;This will set the input to be on the second line.  Position in R1
set_LCD_POS			PUSH 	{LR}						;No need to push R5 gets overridden anyway
					BL 		ready						;Wait for the display to be ready
					ORR 	R5, R1, #LCD_DB7			;set R5 to the correct Data
					STRB 	R5, [R4, #DATA]				;store the data in R5
					LDRB 	R5, [R4, #CONTROL]			;load in the current control signal
					BIC 	R5, R5, #(LCD_RS OR LCD_RW)	;load 0 0 into the RS and RW reg
					BL 		strobe_en					;strobe the enable	
					POP 	{LR}						;restore the LR
					B		SVC_Complete				;return to the SVC cleanup function

;This will set the input to be on the second line. 
move_second_line	PUSH 	{LR}						;No need to push R5 gets overridden anyway
					BL 		ready						;Wait for the display to be ready
					MOV 	R5, #(scnd_ln_strt OR LCD_DB7)	;set R5 to the correct Data
					STRB 	R5, [R4, #DATA]				;store the data in R5
					LDRB 	R5, [R4, #CONTROL]			;load in the current control signal
					BIC 	R5, R5, #(LCD_RS OR LCD_RW)	;load 0 0 into the RS and RW reg
					BL 		strobe_en					;strobe the enable	
					POP 	{LR}						;restore the LR
					B		SVC_Complete				;return to the SVC cleanup function

;Writes a char to the LCD 
write_char			PUSH 	{LR}						;No need to push R5 gets overridden anyway
					BL 		ready						;wait until the LCD is ready
					STRB 	R0, [R4, #DATA]				;else set the data on the bus to the char
					LDRB 	R5, [R4, #CONTROL]			;load the current control sequence
					AND 	R5, R5, #LCD_BG				;clear the control apart from the BG light
					ORR 	R5, R5, #(LCD_RS OR LCD_E)	;set write to data and set enable high
					BL		strobe_en_e_set				;strobe the enable
					POP 	{LR}						;restore the LR
					B		SVC_Complete				;return to the SVC cleanup function

;This clears the screen
clear 				PUSH 	{LR}						;store the LR
					BL 		ready						;wait till the LCD is ready
					MOV 	R5,	#Clear					;load the Clear sequence into the data reg
					STRB 	R5, [R4, #DATA]				;store the clear code to the data reg
					LDRB 	R5, [R4, #CONTROL]			;load in the current control signal
					BIC 	R5, R5, #(LCD_RS OR LCD_RW)	;load 0 0 into the RS and RW reg
					BL		strobe_en					;strobe the enable
					POP		{LR}						;restore the LR
					B		SVC_Complete				;return to the SVC cleanup function


;This clears the screen
init_disp			MOV 	R4, #IO_BASEADDR		
					MOV 	R5,	#Clear					;load the Clear sequence into the data reg
					STRB 	R5, [R4, #DATA]				;store the clear code to the data reg
					MOV 	R5, #(LCD_E or LCD_BG)		;set enable high
					STRB 	R5, [R4, #CONTROL]			;store to the LCD - jump to here if LCD_E can be set in the calling function
					BIC 	R5, R5, #LCD_E				;Clear the enable bit of the control - Stack not setup yet so can't use it.
					STRB 	R5, [R4, #CONTROL]			;done strobing
					MOV		PC, LR						;return to calling function

;Move the cursor with the dir set in R0
move_cursor			PUSH 	{LR}						;No need to push R5 gets overridden anyway
					BL 		ready						;wait until the LCD is ready
					STRB 	R0, [R4, #DATA]				;store the direction in the data reg
					LDRB 	R5, [R4, #CONTROL]			;load in the current control signal
					BIC 	R5, R5, #(LCD_RS OR LCD_RW)	;load 0 0 into the RS and RW reg
					BL		strobe_en					;strobe the enable
					POP 	{PC}						;return to calling function

;This turns on the BG light of the LCD
backlight_toggle	LDRB 	R5,	[R4, #CONTROL]			;read the current control as to not override
					EOR 	R5,	R5, #LCD_BG				;toggle the bit on/off - so if it is already on it's
					STRB 	R5,	[R4, #CONTROL]			;fine. - Store the control on the LCD
					B		SVC_Complete				;return to the SVC cleanup function

;This checks if the LCD is ready for input or not
ready				LDRB 	R5,	[R4, #CONTROL]			;load the control
					AND 	R5,	R5, #LCD_BG				;Set BG bit high
					ORR 	R5, R5, #(LCD_RW OR LCD_E)	;set read to control dir - data
					STRB 	R5, [R4, #CONTROL]			;send the control signal to the bus
					LDRB 	R6,	[R4, #DATA]				;read the LCD status - check in one command?
					BIC 	R5,	R5, #LCD_E				;disable LCD_E
					STRB 	R5,	[R4, #CONTROL]			;send to the bus
					TST 	R6, #LCD_BUSY				;test to see if the LCD is ready
					BNE 	ready						;if the LCD was busy wait
					MOV 	PC,	LR						;return to calling function

;Pass the direction in R1
;This scroll only gives the required effect if the printed line only spans one line of the display
scroll_1			PUSH 	{LR}
					BL 		ready						;wait until the LCD is ready
					STRB 	R1, [R4, #DATA]				;store the direction in the data reg
					LDRB 	R5, [R4, #CONTROL]			;load in the current control signal
					BIC 	R5, R5, #(LCD_RS OR LCD_RW)	;load 0 0 into the RS and RW reg
					BL 		strobe_en					;strobe enable
					POP 	{LR}						;pop the LR 
					B		SVC_Complete				;return to the SVC cleanup function

;TODO make this use the timer - will do once using interrupts 
LCD_wait			PUSH 	{R4}						;Keep R1 value
                	MOV 	R4, #LCD_wait_amount		;set the counter
inner_delay_LCD		SUB 	R4 , R4, #1					;loop for the counter amount
					CMP		R4, #0						;
					BNE 	inner_delay_LCD				;
					POP 	{R4}						;Return R1 value
					MOV 	PC, LR						;Go back to calling function

;Function to strobe the enable then return to the calling function
;R5 must be used to hold the data to go in and out of the control register
strobe_en			ORR 	R5, R5, #LCD_E				;strobe the enable
strobe_en_e_set		STRB 	R5, [R4, #CONTROL]			;store to the LCD - jump to here if LCD_E can be set in the calling function
					BIC 	R5, R5, #LCD_E				;Clear the enable bit of the control
					STRB 	R5, [R4, #CONTROL]			;done strobing
					MOV		PC, LR						;return to calling function


LCD_wait_amount		EQU &B000							;An arbitrary amount of time to wait for the scroll...

LCD_E				EQU	&1								;The LCD enable bit
LCD_RS				EQU	&2								;The R/S bit for the LCD
LCD_BG				EQU	&20								;The backlight bit for the LCD
LCD_RW				EQU	&4								;The R/notW bit for the LCD
LCD_BUSY			EQU &80								;The LCD is busy reply
LCD_DB7				EQU &80								;The 7th bit for the data bus in the LCD 
LCD_DB6				EQU	&40
LCD_SHIFT_CTRL		EQU &10								;The code to give to make the LCD shift
LCD_SHIFT			EQU &8								;The bit to enable to set shift						

Clear				EQU	&1								;Bit to clear the LCD
CRight				EQU	&14								;Pattern to move cursor right
CLeft				EQU	&10								;Pattern to move cursor left 
SRight				EQU	&1C								;Pattern to shift LCD right
SLeft				EQU	&18								;Pattern to shift LCD left

frst_ln_strt		EQU	&0								;The start of the first line on the LCD
frst_ln_end			EQU	&10								;The end of the first line on the LCD
scnd_ln_strt		EQU &40								;The start of the second line on the LCD
scnd_ln_end			EQU &50								;The end of the second line on the LCD

number_offset 		EQU	&30							;The offset to change from hex val to ASCII val (digit)
letter_offset 		EQU	&37							;The offset to change from hex val to ASCII val (letter)
max_digit			EQU	9								;The max digit for a decimal number

mask_but_LSb	 	EQU	&000F 							;Mask code for all but the least significant bit