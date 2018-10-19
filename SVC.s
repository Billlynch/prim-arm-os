;-------------------------------------------------------------------------------
;			SVC Call Handler  
;			Bill Lynch
;			Version: 0.4
;			10/05/2017 (BL)
;
; This is the function called that calculates what SVC call was made and jumps
; to that method in supervisor mode. This also includes a return place for SVC
; calls so they can be tidied up.
;
; Last modified: 12/05/2017 (BL)
;
; Know bugs: none
;
;-------------------------------------------------------------------------------
;The number of the SVC call is passed in R9 - change this to be the address.
SVC_start				PUSH	{R4-R11}					;Push registers that the SVC calls use as temp stores.
						LDR		R9, [LR, #-4]				;get the instruction before the LR (the SVC call)
						BIC		R9, R9, #&FF000000			;Mask of the instruction code to get just the value of the call (e.g. SVC 0 => 0)
						CMP     R9, #max_SVC                ;compare to see if the called SVC is within the range of available ones.
                        BHS     out_of_range                ;if it was greater (signed) then call the 'catch' to this 'try'
						ADR     R8, supervisor_call_table   ;load the address of the supervisor table
						MOV 	R4, #IO_BASEADDR			;set the IO address to R4 for the function
                        LDR     PC, [R8, R9, LSL #2]        ;map the parameter in R0 to a position in the table and set the PC to that position. 

SVC_Complete			POP		{R4-R11}					;pop back the registers for the user code
						MOVS 	PC,	LR						;return to the calling position 

;catch to out of bounds SVC call
out_of_range            B       out_of_range        ;for now just infinite loop


;-------------------------------Memory Definitions------------------------------
;This is a list of the SVCs in the System. 
;If you add one - remember to update the max.
supervisor_call_table   DEFW    write_char			;Write a char
                        DEFW    next_char	        ;read next char from buffer
                        DEFW    clear				;Clear the LCD
                        DEFW    move_cursor			;Move the cursor
                        DEFW    scroll_1			;Scroll the display
                        DEFW    set_LCD_POS     	;Move to LCD write position (DRAM)
						DEFW	HALT				;Halt the PC 
						DEFW	set_timer_cmp       ;set a number milliseconds 
                                                    ;for the timer compare.
						DEFW	set_CG              ;set the interrupt mask
                        DEFW    set_speed           ;Set the speed of a fan
                        DEFW    read_mem_address    ;Read from a memory address
                        DEFW    write_mem_address   ;Write to a memory address
