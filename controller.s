;-------------------------------------------------------------------------------
;			Fan Driver
;			Bill Lynch
;			Version: 0.1
;			1st May 2017
;
; This is the driver for the hardware designed in cadence. It implements two
; simple instructions. Set speed up one, and set speed down one. These cam be 
; run on any combination of selected fans and will work of the relative 'speed'
; of the individual fan at the time of the adjustment. 
;
; N.B. : The code for the button press will be run in SVC mode.
;        The word 'speed' in this context is implied speed from the value being
;        passed to the divider for the PWM control. Not direct speed. 
;
; Last modified: 10/4/2017 (BL)
;
; Know bugs: None
;
;-------------------------------------------------------------------------------

           
;===================================Set Speed===================================
;set speed - given direction in R0, and fan(s) in R2
set_speed			PUSH    {LR}                    ;Push the LR to keep the state
                    ADRL    R6, fan_speed_addr      ;Load in the address of the 
                    ADRL    R5, fan_sel_addr        ;Two ports used in this method
                    MOV     R1, #&01                ;This starts at fan0
speed_set_loop      TST     R2,R1                   ;test to see if the fan is selected
                    MOVNE   R3,R1                   ;If so store this fan in a temp reg.
                    BLNE    set_speed_single        ;Jump to the setting part of this code
                    MOV     R1,R1, LSL #1           ;Check the next fan
                    CMP     R1, #fan3               ;Have we already checked all the
                    BLE     speed_set_loop          ;fans? N - continue the loop
                    POP     {LR}                    ;Else - restore the LR
			        B       SVC_Complete            ;And return the to SVC cleanup code

                    ;read the selected fan's current speed by sending the read 
                    ;bit and the fan's selection code.
set_speed_single    ORR     R4, R3, #speed_read     ;set the read bit
                    STRB    R4, [R5]                ;store the fan and read bit
                    LDRB    R4, [R6]                ;Load he speed returned
                    STRB    R3, [R5]                ;store just fan code in write mode

                    ;cmp to see if we are increasing or decreasing the speed
                    CMP     R0, #speed_up           ;If we are setting the speed down
                    BNE     set_speed_down          ;Then jump over the speed up section.

                    ;sets the speed up one
set_speed_up        CMP     R4, #&00                ;Check to see if we are already at
                    MOVEQ   R4, #&01                ;the lowest speed. If we are
                    BEQ     done_setting            ;Ignore setting the speed.
                    CMP     R4, #&10                ;if it is not the max speed 
                    MOVLT   R4, R4, LSL #1          ;increment it
                    B       done_setting            ;skip to saving the speed
                    
                    ;sets the speed down one
set_speed_down      CMP     R4, #&00                ;Check to see if we are at the
                    MOVGT   R4, R4, LSR #1          ;lowest speed. If not decrement the speed.

                    ;Save the calculated speed into the hardware
done_setting        STRB    R4, [R6]                ;Store the new value of the speed for
                    MOV     R3, #&00                ;This fan, and then store 00 into the
                    STRB    R3, [R5]                ;hardware. Thus leaving it safe and 
                    MOV     PC, LR                  ;atomic. Return to the all fans loop


;=============================Get Char From Buffer==============================
;This needs to be in SVC mode to stop interrupts which may overwrite the buffer.
;SVC gets the next char input return in R1
next_char           MOV     R1, #IO_Location_keypad     ;Load in the keypad loc
                    ADRl    R4, char_buffer             ;Load the buffer
                    LDRB    R5, buffer_tail             ;load the buffer tail
                    LDRB    R6, buffer_head             ;Load the buffer head
                    CMP     R5,R6                       ;Head = Tail?
                    MOVEQ   R1, #&FF                    ;no button pressed
                    BEQ     SVC_Complete                ;Y? - return to the 
                                                        ;calling function without 
                                                        ;printing anything
                   ;Else
next_buffer_char    LDRB    R0, [R4,R5]     ;Read the char at the buffer tail
                    CMP     R0, #'#'        ;was it 'enter'
                    MOVNE   R1, R0          ;if not load the char into R1
                    MOVEQ   R1, #&FF        ;else load no button pressed
                    ADD     R5, R5, #&01    ;Increment the tail
                    CMP     R5,#BUFFER_SIZE ;Wrap around the buffer if needed 
                    MOVGT   R5,#&00         ;Wrapping to the start
                    STRB    R5 , buffer_tail ;store the tail 
                    B       SVC_Complete	;This method reads one char at a time
                                            ;and so returns now


;SVC - ADDRESS to READ in R0 - returns in R0
read_mem_address    LDRB    R0, [R0]
                    B       SVC_Complete 

;SVC - ADDRESS to READ in R1, data in R0 - returns in R0
write_mem_address   STRB    R0, [R1]
                    B       SVC_Complete



;==============================Speed States Table===============================
speed_states        DEFB    '&00','&02','&04','&08'     ;This is the states
                    DEFB    '&10','&00','&00','&00'     ;that the fans can 
                    ALIGN                               ;be in