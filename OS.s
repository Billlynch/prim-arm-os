;-------------------------------------------------------------------------------
;			Primitive OS  
;			Bill Lynch
;			Version: 0.4
;			15th Feb 2017
;
; This is a simple OS which provides functions to write to the LCD and read
; the button state. This is done by the included libraries in Peripheral.s.
; This returns values of interest in the registers to the user.
;
; Note: To use: Import at the top of the user file and label the start of your
;		code as 'USR_start'		
;
; Last modified: 10/05/2017 (BL)
;
; Know bugs: Inherited bugs from LCD.s and Buttons.s
;
; TODO: Change size of the stacks for each mode and return the size to the user
;		Write an SVC to change the items in the 'interrupt_code_table'. This
;		will allow for the user to change the functionality of the button press
;		at runtime. 
;
;-------------------------------------------------------------------------------

;|=========================VECTOR TABLE MAPPING================================|	
					B 		sys_init			;Branch to the system setup.
Undefined_instr		B 		.					;for now just loop to it's self.
					B 		SVC_start			;Branch to the SVC handler.
Pre_abort			B 		.					;for now just loop to it's self.
Abort_data			B 		.					;
Terminate			SVC 	6					;Stop the process
IRQ					B 		IRQ_start			;Go to the interrupt handler.
FIQ					B 		FIQ_start			;						   
;|================================END==========================================|

;|=========================System Initialisation================================|
;In this function we set up the stacks for the operating modes that ARM has.
;We will initialise the state of the LCD to be clear with the backlight on.
;Then we will set the Mode to user and start the user code.

sys_init			BL 		init_disp				;init the display -
													;We know we are in supervisor
					;SET the interrupt mask
					;Set the bit pattern.
					MOV		R1, #(TIMER_CMP_INT)
					STR		R1, [R4, #Interrupt_msk_port]	;Store the bit 
												;pattern at the memory location
					STR		R2, [R4, #Interrupt_data_port]	;clear out any other interrupts
															;that are set.

														

stack_setup			ADRl 	R3,	mode_table			;load in the tables for 
					ADRl 	R4,	mode_stacks			;the setup loop below
					ADRl 	R5,	mode_start_pos		;
					
;Post increment - USING R2 AS A SCRATCH REG			
stack_setup_loop	LDRB	R2, [R3], #&1			;Get the mode from the table
					;if we are about to go to system mode then enable interrupts
					CMP		R2, #SYS_mode
					ORR		R2,R2,#FIQ_CPSR_BIT
					ORREQ   R2, R2, #IRQ_CPSR_BIT  	;enable interrupts - NOT FIQ
					MSR		CPSR_c, R2				;switch to that mode
				
					CMP		R2, #(USR_mode or FIQ_CPSR_BIT)	;Are in user mode?
					BEQ		usr_reg_setup			;Y -Setup Registers and continue
					LDR		LR, [R5], #&4			;ELSE - Get the start_pos in LR
					LDR		R2, [R4], #&4			;Get the stack_pos 
					ADD		SP, R2, #stacklength	;Setup the SP
					B 		stack_setup_loop		;repeat until in user mode

;Clean / Give info to the user about the System - So far only returns the stack 
;size of the stacks
usr_reg_setup		;SVC call to enable interrupts
					MOV		R0,	 #0					;cleared
					MOV 	R1,  #0					;
					MOV 	R2,  #0					;
					MOV	 	R3,  #0					;
					MOV 	R4,  #0					;
					MOV 	R5,  #0					;
					MOV		R6,  #0					;
					MOV 	R7,  #0					;
					MOV		R8,  #0					;
					MOV 	R9,  #0					;
					MOV 	R10, #0					;
					MOV 	R11, #stacklength		;The size of the stacks
					MOV 	R12, #0					;
					MOV		PC, LR					;Go to USR_start
							   
;|================================END==========================================|
					Include Definition.s
;-------------------------------SVC ENTRY --------------------------------------
					Include SVC.s
;-------------------------------------------------------------------------------

;-----------------------------------FIQ ENTRY-----------------------------------
FIQ_start          	B		.
;-------------------------------------------------------------------------------

;-----------------------------------IRQ ENTRY-----------------------------------
					Include IRQ.s
;-------------------------------------------------------------------------------

;-------------------------------ABT ENTRY--------------------------------------
ABT_start          	B		.						;Not yet used
;-------------------------------------------------------------------------------

;-------------------------------UND ENTRY --------------------------------------
UND_start          	B		.						;Not yet used
;-------------------------------------------------------------------------------

;----------------------------library Includes ----------------------------------
                    Include Peripheral.s
;-------------------------------------------------------------------------------

;-------------------------------------HALT -------------------------------------
HALT				STR		R1, [R4, #Halt_Address]	;Write a value to the
													;memory location to halt the PC
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
;This table holds the hex values for the modes for systematic use in setup
mode_table			DEFB	SVC_mode, FIQ_mode, IRQ_mode, UND_mode
					DEFB	ABT_mode, SYS_mode, USR_mode, &00
;This table holds the stack sizes for the modes for systematic use in setup
mode_stacks			DEFW	_SVC_STACK, _FIQ_STACK, _IRQ_STACK, _UND_STACK
					DEFW	_ABT_STACK, _USR_STACK, &00, &00
;This table holds the SP start values for the modes for systematic use in setup
mode_start_pos		DEFW	SVC_start, FIQ_start, IRQ_start, UND_start
					DEFW	ABT_start,  USR_start, &00, &00
					ALIGN

;-------------------------------------------------------------------------------
;stack setup - TODO change the size of some of them, they don't all need to be
;this big.
stacklength 		EQU 	256					;Room for 64 Registers
_USR_STACK			DEFS	stacklength			;Defining room for the stack
_FIQ_STACK			DEFS	stacklength			;
_IRQ_STACK			DEFS	stacklength			;
_SVC_STACK			DEFS	stacklength			;
_ABT_STACK			DEFS	stacklength			;
_UND_STACK 			DEFS	stacklength			;
;Note the system mode shares the user stack