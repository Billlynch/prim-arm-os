;-------------------------------------------------------------------------------
;			Timer Library 
;			Bill Lynch
;			Version: 0.1
;			24th Feb 2017
;
;This function provides methods to use the free running timer on the board.
;This file provides system calls, so these functions must be added to the SVC
;entry. The SVC call just returns the value of the register.
;
; Last modified: 02/03/2017 (BL)
;
; Know bugs: none
;
;-------------------------------------------------------------------------------

;==============Code To be Run when timer compare interrupt happens==============
timer_cmp_code      b  readChars   
;======================================END======================================

;======================================SVC======================================
;This will set the compare value for the timer to the value passed in R0. In ms
set_timer_cmp       LDRB    R1, [R4, #TIMER]    ;Read the value from memory
                    ADD     R1, R1, R0
                    STRB    R1, [R4, #TIMER_CMP];Store the new value
                    B       SVC_Complete        ;return to the clean up function
;======================================END======================================