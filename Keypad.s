;-------------------------------------------------------------------------------
;			Keypad Library 
;			Bill Lynch
;			Version: 0.5
;			12th March 2017
;
; Button Library provides functionality to read the input from a Keypad 
; connected via the Spartan-3 FPGA. The input from the keypad is added to a 
; buffer. This Library also provides a printing method from the buffer to the 
; LCD. The button must be held for 8ms minimum for it to register as a press.
; The character will only be added to the buffer on the press action. Not on 
; the hold action or the raise action of the button.
; To finish input press hash '#' on the keypad.
;
; N.B. : The majority of this code will be run in IRQ mode.
;
; Last modified: 10/05/2017 (BL)
;
; Know bugs: None
;
;-------------------------------------------------------------------------------

;==================================Terminology==================================
;                                                          Keypad Diagram
;                                                           _____________
; A line is vertical as the board is                        | 1 | 2 | 3 |
; position as shown to the right.                           |-----------|
;                                                           | 4 | 5 | 6 |
; A column is horizontal in the diagram,                    |-----------|
;                                                           | 7 | 8 | 9 |
;                                                           |-----------|
; Rising edge is when the button has been         column -> | * | 0 | # |
; pressed and the de-bouncing has determined                |-----------|
; it was an intentional press.                                ^  
;                                                             |
; Falling edge is when the button is raised                  line
;
;==================================Terminology==================================

;===============================Register Usages=================================

;R1 = the position for the button to the tables, 
;R2 = the button currently being look at
;R3 = line looking at (1 4 7 *)
;R4 = IO_Location_keypad
;R5 = the value of the buttons pressed on a line
;R6 = scratch
;R7 = current table pointer

;======================================END======================================
;Function to poll the keyboard, uses debouncing to determine if a btn is pressed
readChars           PUSH    {R0-R9}                 ;Push the registers which to be used
                    MOV     R4, #IO_Location_keypad ;Set the keyboard to listen
                    MOV     R2, #&1F            
                    STRB    R2, [R4,#&3]        

                    MOV     R3, #Bottom_line        ;Set in the line we are looking at 
line_loop           STRB    R3, [R4,#2]             ;set listening on this line
                    LDRB    R5, [R4,#2]             ;read the columns 
                    SUB     R5,R5,R3                ;Ignore the line we are looking at
                    MOV     R2,#&8                  ;look at the end of the line first
column_loop         BL      setDebounce
                    MOV     R2,R2,LSR #1            ;move to next button(Key)
                    ;This section decides to either look at the next column or line
                    CMP     R2,#0                   ;Checked all the button on this line
                    BNE     column_loop             ;if not the start of line continue
                    MOV     R3,R3,LSR #1            ;else change the line we are testing
                    CMP     R3,#&10                 ;Looked at all the lines?
                    BNE     line_loop               ;No? - move to the next line
                    ;Hash works like 'enter' - marking the end of the input
                    ;This will print out hash
                    LDRB    R0, buffer_head         ;Load in the buffer head
                    CMP     R0,#&00
                    SUBNE   R1,R0,#&01              ;Get the last char input
                    ADRl    R9, char_buffer         ;Load the table
                    LDRB    R0, [R9,R1]             ;Load up the last char input
                    CMP     R0,#'#'                 ;Was it the 'enter' key?                  
                    BEQ     return                  ;Yes - stop reading input

                    ;BL print_keypad_input          ;Yes? - Print out the buffer     
                    ;set the timer to wait for 1ms again 
                    MOV 	R4, #IO_BASEADDR        ;Load the base address
                    LDRB    R0, [R4, #TIMER]        ;Read the value from memory
                    ADD     R0,R0,#&1               ;Set the value to 1 ms later
                    STRB    R0, [R4, #TIMER_CMP]    ;Store the passed value in the port
                    POP     {R0-R9} 
                    B       IRQ_code_done           ;to the IRQ handler.   
                    ;This will now return to the IRQ handler
return              STRB    R1, buffer_head         ;move the head back to ignore the #
                    POP     {R0-R9}                 ;Checked all buttons - return 
                    MOV     R11, #&FF               ;Tell waiting function it's done
                    B       IRQ_code_done           ;to the IRQ handler.    
 

setDebounce         PUSH    {LR}                    ;Save the LR 
                    ;Get the mapping to the tables for the button pressed (R1)
                    MOV     R1, R2, LSR #1          ;Shift to get the column mapping
                    CMP     R1, #&4                 ;Due to shift this will not map 
                    MOVEQ   R1,#&3                  ;to the 3rd one so catch this.
                    ;Map the line we are on. Top is 0 mapping to 0 so isn't needed
                    CMP     R3,#Bottom_line         ;Bottom line?
                    ADDEQ   R1,R1,#&8               ;Set to hex 8
                    CMP     R3,#Middle_line         ;Middle line?
                    ADDEQ   R1,R1,#&4               ;Set to hex 4
                    ;This will now load in the debounce table at the position in R1
                    ADRl    R7, debounce_table      ;Get the memory address
                    LDRB    R6, [R7,R1]             ;Load the debounce byte
                    ;This will do the debounce algorithm 
                    MOV     R6,R6,LSL #1            ;Shift the debounce byte
                    TST     R5,R2                   ;if was pressed add one else ignore
                    ADDNE   R6,R6,#&01              ;If the btn was pressed set LSB to 1
                    ;if the btn was pressed. Decide if held or just pressed. 
                    CMP     R6,#BTN_PRESSED
                    BLEQ    edge_detect        
                    ;The button wasn't pressed so store the debounce byte
                    STRB    R6, [R7,R1]
                    ;If the button was not pressed then return to the loop
                    CMP     R6, #BTN_NOT_PRESSED    ;is it pressed?
                    POPNE   {PC}                    ;No? - return to calling function
                    ;Else reset the pressed table at the button position
                    ADRL    R7, pressed_table       ;Load the pressed table 
                    MOV     R8, #BTN_NOT_PRESSED    ;Set the button position in this
                    STRB    R8, [R7,R1]             ;table to not pressed.
                    POP     {PC}                    ;Return to the loop

;This will detect if the button is being held or was just pressed
edge_detect         ADRL    R7, pressed_table       ;Load the pressed table
                    LDRB    R8, [R7,R1]             ;Load the previous state of the btn
                    CMP     R8, #BTN_NOT_PRESSED    ;If it was not pressed before 
                    BEQ     add_to_buffer           ;add to the buffer
                    MOV     PC, LR                  ;Return to the debounce routine

;This will override the buffer if the head catches the tail
add_to_buffer       ADRl    R9, char_buffer         ;Load the char buffer table
                    ADRl    R8, CHAR_MAPPING        ;Load the char mapping table
                    LDRB    R0, [R8,R1]             ;Load the char to the button pressed
                    LDRB    R8, buffer_head         ;Load the head of the buffer
                    STRB    R0, [R9,R8]             ;Store the char at buffer's head
                    ADD     R8, R8, #&01            ;Increment the buffer head
                    CMP     R8, #BUFFER_SIZE        ;Wrap the head around if needed
                    MOVGT   R8, #&00                ;
                    STRB    R8, buffer_head         ;Save the new head
                    MOV     PC, LR                  ;Return the the debounce routine          
;======================================End======================================

;=================================Print Buffer==================================
;NOTE interrupts disabled here
print_keypad_input  PUSH    {LR,R0-R1,R4-R6}        ;Push registers used
                    MOV     R1, #IO_Location_keypad
                    ADRl    R4, char_buffer         ;Load the buffer
                    LDRB    R5, buffer_tail         ;load the buffer tail
                    LDRB    R6, buffer_head         ;Load the buffer head
                    CMP     R5,R6                   ;Head = Tail?
                    POPEQ   {PC,R0-R1,R4-R6}        ;Y? - return to the calling function
                                                    ;without printing anything
                                                    ;Else
next_buffer_item    LDRB    R0, [R4,R5]             ;Read the char at the buffer tail
                    SVC     0                       ;print the char read
                    ADD     R5, R5, #&01            ;Increment the tail
                    CMP     R5, #BUFFER_SIZE        ;Wrap around the buffer if needed 
                    MOVGT   R5, #&00         
                    CMP     R5,R6                   ;If tail = head. Buffer is empty.
                    BNE     next_buffer_item        ;Not empty - print the next char
                    STRB    R5 , buffer_tail        ;Empty - store the tail 
                    POP     {PC,R0-R1,R4-R6}        ;Return to the calling function 
                                                    ;and restore the registers
;======================================End======================================

;===================================Get Chars===================================
;For the purposes of this demo the timer interrupt will trigger another poll of
;the keypad. - This will be run in USR mode.
getChars            PUSH    {LR, R0, R11}
                    MOV     R0, #&01	            ;set timer to trigger an interrupt after 1ms
					SVC     7                       ;Set timer interrupt to 1ms polls the keypad
getCharsWait        CMP     R11, #&FF
                    BNE     getCharsWait
                    POP     {PC, R0, R11}           ;return to calling function
;======================================End======================================

;====================================Memory=====================================
;This is the buffer location for the keypad. It allows up to 16 chars to be
;held at any time. The table is wrapped around so the 17th character added to 
;the buffer will override the 1st char added. 
char_buffer         DEFB    '\0','\0','\0','\0'
                    DEFB    '\0','\0','\0','\0'
                    DEFB    '\0','\0','\0','\0'
                    DEFB    '\0','\0','\0','\0'
;This table will hold the live values for the de-bouncing.
debounce_table      DEFB    &00,&00,&00,&00         ;The position in the 
                    DEFB    &00,&00,&00,&00         ;table corresponds to the
                    DEFB    &00,&00,&00,&00         ;character.
                    DEFB    &00,&00,&00             ;three buttons on the board
;This is the table where the values are either &00 or &FF for not pressed and 
;pressed respectively. This is used for the detection of a button just being
;pressed or having been held.
pressed_table       DEFB    &00,&00,&00,&00         ;The position in the
                    DEFB    &00,&00,&00,&00         ;table corresponds to the 
                    DEFB    &00,&00,&00,&00         ;character.
                    DEFB    &00,&00,&00             ;three buttons on the board
                    ALIGN
;The mapping of the characters on the Keypad. 
CHAR_MAPPING        DEFB   '3','6','9','#'          ;Bottom line
                    DEFB   '2','5','8','0'          ;Middle line       
                    DEFB   '1','4','7','*'          ;Top line

buffer_head         DEFB    &00                     ;Head of the buffer (write pos)
buffer_tail         DEFB    &00                     ;Tail of the buffer (read pos)
                    ALIGN