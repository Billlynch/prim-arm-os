;-------------------------------------------------------------------------------
;			Button Library 
;			Bill Lynch
;			Version: 0.5
;			7th Feb 2017
;
; Button Library includes an SVC call to get the button state. As well as code
; which will be run when an interrupt for the corresponding button is produced.
;
; N.B. : The code for the button press will be run in IRQ mode.
;
; Last modified: 14/2/2017 (BL)
;
; Know bugs: None
;
;-------------------------------------------------------------------------------

;=================================SVC Mode Code=================================
;This returns the value of the button memory location in R0
chk_buttons			LDRB 	R0, [R4, #BUTTONS]	;load the value into R0
					B 		SVC_Complete		;Return to SVC cleanup function 
;======================================END======================================

;=================================IRQ MODE CODE=================================

;---------------------------------Lower Button----------------------------------
lower_button_code	B .	
;-------------------------------------------------------------------------------

;----------------------------------Upper Button---------------------------------
upper_button_code	B .
;-------------------------------------------------------------------------------

;======================================END======================================
