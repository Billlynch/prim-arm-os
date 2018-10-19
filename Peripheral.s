;-------------------------------------------------------------------------------
;			Peripherals for the OS 
;			Bill Lynch
;			Version: 0.1
;			24th Feb 2017
;
; This links in all the written Peripheral libraries.
;
; Last modified: 10/05/2017 (BL)
;
; Know bugs: None
;
;-------------------------------------------------------------------------------
                        include     LCD.s           ;library for the LCD
                        include     Timer.s         ;library for the timer
                        include     Buttons.s       ;library for the buttons
                        include     Keypad.s        ;library for the keypad
                        include     controller.s    ;library for the fan controller

;===============================Set interrupt SVC===============================
;sets the interrupts - push value in R0 
set_interrupts          STR		    R0, [R4, #Interrupt_msk_port]
                        B           SVC_Complete
;======================================END======================================


;=================================Write to port=================================
;Write data in R0 to the port addressed in R1 - SVC call
set_port_data           STR		    R0, [R1]
                        B           SVC_Complete
;======================================END======================================

;=========================Unimplemented interrupt code==========================
spartan_int_code        B           .           ;Spartan FPGA    
ser_RD_rdy_int_code     B           .           ;Serial RxD ready
ser_TD_avail_in_code    B           .           ;Serial TxD available
;======================================END======================================
