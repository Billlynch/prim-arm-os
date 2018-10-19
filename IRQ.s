;-------------------------------------------------------------------------------
;			IRQ handler 
;			Bill Lynch
;			Version: 0.1
;			10th March 2017 
;
; The holds the function that is called on an interrupt. This works out what 
; the interrupt was, and calls the corresponding method. Also provides a return 
; point to tidy up after. 
;
; Last modified: 10/05/2017 (BL)
;
; Know bugs: none
;
;-------------------------------------------------------------------------------
;This function will be called when an interrupt happens. It will use the data 
; port to decide which interrupt to jump to.
IRQ_start          		SUB		LR,LR,#4					 ;Get the return address
						PUSH	{R0-R4,LR}					 ;Push the registers to be used here to the stack
						;read the interrupt Line
						MOV		R3,	#IO_BASEADDR			 ;Load the base address for the IO
						LDR  	R0,	[R3,#Interrupt_data_port];Get the data that caused the interrupt

						ADR		R4, interrupt_table			;load the interrupt table
						MOV		R2,	#&00					;initialise the offset
;This loop goes though the interrupt table and look at all possible interrupts to run the code for it
interrupt_loop			LDRB 	R1, [R4,R2]					;load the current interrupt to look at
						TST 	R0,R1						;Test to see if this interrupt was one that caused it
						BNE		run_usr_code				;If it was run the code defined for it
next_interrupt			ADD		R2,R2,#&01					;increment the offset
						CMP		R2,#n_avail_interrupts		;Check to see if all have been looked at
						BLT		interrupt_loop				;Not all looked at - go round again
						;If all the interrupts have been looked at then clear the interrupt data port and return
						;clear the interrupt port and finish up
						MOV 	R0, #&00					;Load no interrupts
						STR 	R0, [R3,#Interrupt_data_port];Store this in port
						POP		{R0-R4,PC}^					;Return to the 
															;interrupted line 
															

run_usr_code			PUSH	{R0-R4}						;Push the state of the interrupt routine
						ADR		R4,interrupt_code_table		;Load the table of where to jump to
						LDR		PC, [R4,R2, LSL #2]			;Move the PC to the code to run for this interrupt
IRQ_code_done			POP		{R0-R4}						;This will be the return of the code - restore the state
						B		next_interrupt				;Look at the next interrupt

;-------------------------------Memory Definitions------------------------------

;This is the table which holds the bit codes for each of the interrupt types.
interrupt_table			DEFB	TIMER_CMP_INT,SPARTAN_FPGA_INT
                        DEFB    SERIAL_RD_RDY_INT, SERIAL_TD_AVAIL_INT
						DEFB	UPP_BUTTON_INT, LOW_BUTTON_INT
						ALIGN
;The position of the code to jump to for each interrupt type:
interrupt_code_table	DEFW	timer_cmp_code              ;Timer
						DEFW	spartan_int_code            ;Spartan FPGA
						DEFW	ser_RD_rdy_int_code         ;SERIAL RxD ready 
						DEFW	ser_TD_avail_in_code        ;SERIALTxD available
						DEFW	upper_button_code           ;Upper button 
						DEFW	lower_button_code           ;Lower button
