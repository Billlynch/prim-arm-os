;-------------------------------------------------------------------------------
;			Definitions
;			Bill Lynch
;			Version: 0.1
;			18th March 2017
;
; This provides an area to declare any tables or data which to be used by the OS
;
; Last modified: 12/05/2017 (BL)
;
;-------------------------------------------------------------------------------

;===============================Stack Definitions===============================
;This is the definitions for the bit code for the modes
USR_mode				EQU		&10					;Hex for the User Mode
FIQ_mode				EQU		&11					;Hex for the FIQ Mode
IRQ_mode				EQU		&12					;Hex for the IRQ Mode
SVC_mode				EQU		&13					;Hex for the SVC Mode
ABT_mode				EQU		&17					;Hex for the ABT Mode
UND_mode 				EQU		&1B					;Hex for the UND Mode
SYS_mode 				EQU		&1F					;Hex for the SYS Mode
;======================================END======================================

;================================SVC Definitions================================
max_SVC                 EQU     &C    			    ;Number of SVC calls
;======================================END======================================

;================================IRQ Definitions================================
;This is the definitions for the codes which are written in the table. 
;These are the bit codes which identify an interrupt for these devices:
timer_interrupt 		EQU	    &01                 ;The timer interrupt
spartan_interrupt		EQU	    &02                 ;Spartan FPGA
;vertex FPGA and Ethernet not fitted so left out
ser_RD_rdy_interrupt	EQU	    &10                 ;SERIAL RxD ready
ser_TD_avail_interrupt	EQU	    &20                 ;SERIAL TxD available
Upper_button_interrupt	EQU	    &40                 ;Upper button
lower_btn_interrupt		EQU	    &80                 ;Lower button

n_avail_interrupts		EQU	    &6                  ;This is the number of 
                                                    ;different interrupt devices

;======================================END======================================

;===============================Timer Definitions===============================
TIMER_CMP               EQU     &C                 ;Timer compare memory location offset.
;======================================END======================================

;==============================Keypad Definitions ==============================
IO_Location_keypad      EQU     &20000004          ;Memory location for the fans

BUFFER_SIZE             EQU     &0F                ;The size of the buffer in HEX
IO_Location             EQU     &20000000          ;Memory location for the fans

Bottom_line             EQU     &80                ;The top line of the Keypad
Middle_line             EQU     &40                ;The middle line of the keypad
Top_line                EQU     &20                ;The bottom line of the keypad
;The value the debouncing will be when the button is:
BTN_PRESSED             EQU     &FF                ;pressed
BTN_NOT_PRESSED         EQU     &00                ;not pressed
;======================================END======================================

;==============================Button Definitions ==============================
BUTTONS	        	    EQU	     &04			    ;memory offset for R0
BUT_TOP         	    EQU      &40				;Bit pattern for top button
BUT_BOTTOM      	    EQU      &80				;^ button button
BUT_EXTRA       	    EQU      &08				;^ extra button
;======================================END======================================

;=============================Peripheral Definitions============================          
IO_BASEADDR             EQU     &10000000           ;Base address for the IO
DATA                    EQU     &0                  ;Data offset  Port A
CONTROL                 EQU     &4                  ;Control offset Port B
TIMER                   EQU     &8                  ;Timer offset 

;This is the bit code for the interrupts - used for the mask and detection
TIMER_CMP_INT		    EQU 	&01                 ;Timer compare
SPARTAN_FPGA_INT		EQU 	&02                 ;Spartan FPGA
SERIAL_RD_RDY_INT	    EQU 	&10                 ;Serial RxD available
SERIAL_TD_AVAIL_INT	    EQU 	&20                 ;Serial TxD Ready
UPP_BUTTON_INT		    EQU 	&40                 ;Upper button
LOW_BUTTON_INT		    EQU 	&80                 ;Lower button
ALL_INT_EN              EQU     &FF                 ;Enable all interrupts

;Note the base address for these is in Peripheral.s
Interrupt_data_port		EQU		&18					;Offset for the interrupt 
                                                    ;port this will show what 
                                                    ;IRQs made the interrupt.
Interrupt_msk_port		EQU		&1C					;Offset for masking bits 
                                                    ;for the Interrupt 
IRQ_CPSR_BIT			EQU		&80                 ;Bit to enable/disable IRQ 
                                                    ;in the CPSR
FIQ_CPSR_BIT			EQU		&40                 ;Bit to enable/disable FIQ 
                                                    ;in the CPSR
;======================================END======================================

;===============================Halt definitions================================
Halt_Address			EQU		&20
;======================================END======================================


;================================Fan Definitions================================
fan0					EQU	    &01                 ;The binary code for fan0
fan1					EQU	    &02                 ;The binary code for fan1
fan2					EQU	    &04                 ;The binary code for fan2
fan3					EQU	    &08                 ;The binary code for fan3
fan_all					EQU	    &0F                 ;The binary code to select all fans
speed_up                EQU     &01                 ;The instruction to set 'speed' up
speed_down              EQU     &00                 ;The instruction to set 'speed' down
speed_read              EQU     &10                 ;The 'speed' read bit
fan_speed_addr			EQU     &20000000           ;The address of the fans
fan_sel_addr			EQU     &20000002           ;The fan selection address


