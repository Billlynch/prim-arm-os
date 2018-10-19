;-------------------------------------------------------------------------------
;			fan controller 
;			Bill Lynch
;			Version: 0.1
;			10th March 2017
;
; Program to change the speed of 4 connected fan individually. 
; Must be used with the correct .bit downloaded to the board. Use 0, 1, 2, 3
; on the keypad to select any subset of the fans. Then 5 to up the speed and 8
; to decrease the speed. 
;
; Last modified:	12/05/2017 (BL)
;
; Know bugs: Inherited bugs from OS.s
;
;-------------------------------------------------------------------------------
						INCLUDE OS.s
;|=============================================================================|
;|								MAIN PROGRAM								   |
;|=============================================================================|


;R2 = Fan(s) to select
;R3 = Speed to set to
USR_start   			
						;write the custom chars to the display
						MOV 	R1, #&00			;Set the CGRAM position 
						SVC 	8					;
						ADRL 	R1, speed_01		;Load the char to write
						BL 		write_char_CG		;write the char
						;Note the CGRAM position will auto increment so this is fine
						ADRL 	R1, speed_02		;Load the next char to write
						BL 		write_char_CG		;write the char
						ADRL 	R1, speed_04		;Load the next char to write
						BL 		write_char_CG		;write the char
						ADRL 	R1, speed_08		;Load the next char to write
						BL 		write_char_CG		;write the char
						ADRL 	R1, speed_10		;Load the next char to write
						BL 		write_char_CG		;write the char

						;This is the initial UI - prints the fan numbers in the 
						MOV 	R1, #&01			;correct position.
						SVC 	5					;Set the DRAM position to 01
						MOV 	R0, #'0'			;Print 0 - for fan 0
						SVC		0					;^
						MOV 	R1, #&08			;Set the DRAM position to 08
						SVC 	5					;^
						MOV 	R0, #'1'			;Print 1 - for fan 1
						SVC		0					;^
						MOV 	R1, #&41			;Set the DRAM position to 41
						SVC 	5					;^
						MOV 	R0, #'2'			;Print 2 - for fan 2
						SVC		0					;^
						MOV 	R1, #&48			;Set the DRAM position to 48
						SVC 	5					;^
						MOV 	R0, #'3'			;print 3 - for fan 3
						SVC		0					;^

						MOV 	R2, #&00			;Set the initial speed to 0

wait_for_input			BL 		getChars			;Wait for the input from the user

loop					SVC 	1					;read the next char from the buffer

						CMP 	R1, #'0' 			;set fan 0 on / off
						EOREQ	R2, R2, #fan0

						CMP 	R1, #'1' 			;set fan 1 on / off
						EOREQ	R2, R2, #fan1

						CMP 	R1, #'2' 			;set fan 2 on / off
						EOREQ	R2, R2, #fan2

						CMP 	R1, #'3' 			;set fan 3 on / off
						EOREQ	R2, R2, #fan3

						CMP 	R1, #'*' 			;set all fans on / off
						EOREQ	R2, R2, #fan_all

						CMP 	R1, #'5' 			;set speed +
						MOVEQ 	R0, #speed_up
						SVCEQ 	9					;set the speed of the selected fans up 1

						CMP 	R1, #'8' 			;set speed -
						MOVEQ 	R0, #speed_down
						SVCEQ 	9					;set the speed of the selected fans down 1

						CMP 	R1, #&FF 			;read chars again
						BEQ 	update_LCD

						B 		loop

update_LCD				;to start update the selection chars
						MOV		R1,#&00				;If 0 was pressed then print a >
						SVC 	5					;before it. Moving the DRAM to the 
						TST 	R2, #fan0			;Correct position
						MOVNE	R0, #'>'			;if it was selected print >
						MOVEQ	R0,#' '				;Else clear anything that was there
						SVC 	0 					;Print the char

						MOV		R1,#&07				;If 1 was pressed then print a >
						SVC 	5					;before it. Moving the DRAM to the 
						TST 	R2, #fan1			;Correct position
						MOVNE	R0, #'>'			;if it was selected print >
						MOVEQ	R0,#' '				;Else clear anything that was there
						SVC 	0 					;Print the char

						MOV		R1,#&40				;If 2 was pressed then print a >
						SVC 	5					;before it. Moving the DRAM to the 
						TST 	R2, #fan2			;Correct position
						MOVNE	R0, #'>'			;if it was selected print >
						MOVEQ	R0,#' '				;Else clear anything that was there
						SVC 	0 					;Print the char

						MOV		R1,#&47				;If 3 was pressed then print a >
						SVC 	5					;before it. Moving the DRAM to the 
						TST 	R2, #fan3			;Correct position
						MOVNE	R0, #'>'			;if it was selected print >
						MOVEQ	R0,#' '				;Else clear anything that was there
						SVC 	0 					;Print the char
						;selection chars updated

						;now update the speed readout
						MOV 	R9, #fan0			;Load in the fan 0 
fan_bar_loop			ORR 	R0, R9, #&10		;read the speed of fan 0
						ADRL 	R1,fan_sel_addr		;Load in the fan select address
						SVC 	&b					;write R0 to R1 position
						ADRL 	R0, fan_speed_addr	;Load in the speed address
						SVC 	&a					;read the speed
						MOV 	R6, R0				;store this speed in R6
						CMP 	R9, #fan0			;Compare the selected fan with fan0
						MOVEQ 	R1,#&02 			;If it was selected then move to the 
													;correct position
						CMP 	R9, #fan1			;Same for fan 1, 2 and 3
						MOVEQ 	R1,#&09 			;^
						CMP 	R9, #fan2			;^
						MOVEQ 	R1,#&42 			;^
						CMP 	R9, #fan3			;^
						MOVEQ 	R1,#&49 			;^

						;R1 is the char position
						MOV 	R4, #&01			;set R4 to be the first available speed
						MOV 	R7, #&00			;the char being printed 
bar_loop				CMP 	R6, R4				;compare the speed with the value of R4
						SVC 	5					;Set the DRAM position to R1
						MOVGE 	R0, R7				;move the correct bar into R0
						MOVLT 	R0, #&20			;or a space
						SVC 	0					;then print

						ADD 	R7, R7, #&01		;change the char being printed
						ADD 	R1,R1,#&01			;Move the char position
						MOV 	R4,R4, LSL #1		;Move the speed test reg up one
						CMP 	R7, #&04			;Compare against checked all fans
						BLE 	bar_loop			;Not done all speeds - loop round 

						MOV 	R9, R9, LSL #1		;Move the fan looking at up one
						CMP 	R9, #fan3			;see if all fans have been checked
						BLE 	fan_bar_loop		;If not loop round and look at all of them 

						B 		wait_for_input		;Done setting the UI look for more input

;---------------------------------Write to CGRAM---------------------------------
write_char_CG			MOV 	R2, #&00			;Set the position to write to
char_loop				LDRB 	R0, [R1, R2]		;load the byte in R0 from the mem address passed	
						SVC 	0					;'print' char to the CGRAM
						ADD 	R2, R2, #&01		;Move the position reading from
						CMP 	R2, #&07			;Check to see if 8 bytes done
						BLE		char_loop			;no loop back until all 8 are done
						MOV 	PC, LR				;return to calling function

;-------------------------------Memory Definitions-------------------------------

;The characters to display on the LCD - loaded in at the init of the program
speed_01                DEFB    &00,&00,&00,&00		;The 'speed' bar
                        DEFB    &00,&00,&1F,&1F		;for the lowest speed

speed_02                DEFB    &00,&00,&00,&00		;The 'speed' bar for the
                        DEFB    &1F,&1F,&1F,&1F		;next highest speed

speed_04                DEFB    &00,&00,&1F,&1F		;The 'speed' bar for the
                        DEFB    &1F,&1F,&1F,&1F		;next highest speed

speed_08                DEFB    &00,&1F,&1F,&1F		;The 'speed' bar for the
                        DEFB    &1F,&1F,&1F,&1F		;next highest speed

speed_10                DEFB    &1F,&1F,&1F,&1F		;The 'speed' bar for the
                        DEFB    &1F,&1F,&1F,&1F		;highest speed

                        
;|=============================================================================|
;|							  MAIN PROGRAM END 								   |
;|=============================================================================|
