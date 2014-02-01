    list p=16f877               ; list directive to define processor
    #include <p16f877.inc>      ; processor specific variable definitions
    __CONFIG _CP_OFF & _WDT_OFF & _BODEN_ON & _PWRTE_ON & _HS_OSC & _WRT_ENABLE_ON & _CPD_OFF & _LVP_OFF

    #include <lcd.inc>			   ;Import LCD control functions from lcd.asm

;Un-initialised data in RAM and shared across all RAM banks
;res means reserve x bytes of memory
    udata_shr
COUNTH	res 1
COUNTM	res	1
COUNTL	res	1
Table_Counter	res	1


    org     0x0000
    goto    Mainline

;    org 0x0004
;    ;store working and status reg
;	movwf 	temp_w
;	movf 	STATUS,w
;	movwf  	temp_status
;
;	;chcek if PORTB0 caused the interrupt
;   btfsc 	INTCON,INTF
;	call	ISR_Lit
;	bcf 	INTCON,INTF
;
;   ;restore regs
;	movf 	temp_status,w
;	movwf 	STATUS
;   movf    temp_w,w
;	retfie
;
;   ;defines byte 0x20 as temp_w and byte 0x21 as temp_status
;	cblock 0x20
;	temp_w
;	temp_status
;	endc

;Display Macro
Display macro	Message
	local	loop_           ;local variable
	local 	end_            ;local variable
	clrf	Table_Counter   ;letter counter
	clrw
loop_
	movf	Table_Counter,W ;counter into workng reg
	call 	Message
	xorlw	B'00000000'     ;check WORK reg to see if 0 is returned
	btfsc	STATUS,Z
	goto	end_
	call	WR_DATA         ;send data to LCD included in LCD.asm
	incf	Table_Counter,F ;get next letter
	goto	loop_
end_
	endm

;MAIN
Mainline
    call    Init            ;call Initial settings
    ;call    ISR_init
    call    LCD_Init        ;initializes LCD for 4-bit input
    Display MsgStart
    call    Line2
    Display MsgLogs

    ;poll until key press
Poll
    btfss   PORTB,1
    goto Poll

    swapf   PORTB,W         ;Puts PORTB7:4 into W3:0
    andlw   0x0F            ;W: 0000XXXX
    movwf   H'30'
    incf    H'30'
    decfsz  H'30', f        ;decrement working reg, skip next line if 0
    goto    Check
    goto    Operation
;Checks if 2 is pressed
Check
    decfsz  H'30', f
    goto    Release         ;If not 2, wait until button released
    goto    Logs            ;If 2, display Logs
;Wait until key is released, then return to Polling
Release
    btfsc   PORTB,1
    goto    $-1
    goto    Poll


;Start the Operation
Operation
    call    Clear_LCD
    call    Line1
    Display MsgOP
    call    Line2
    Display MsgRet
    goto    TIL


;Dispay Logs
Logs
    call Clear_LCD
    call Line1
    Display MsgLog
    call    Line2
    Display MsgRet
    goto    TIL

;TENTATIVE PLACEHOLDER
;Return to main menu if 1 is pressed
TIL
    btfss   PORTB,1
    goto    TIL
    swapf   PORTB,W         ;Puts PORTB7:4 into W3:0
    andlw   0x0F            ;W: 0000XXXX
    movwf   H'30'
    incf    H'30'
    decfsz  H'30', f        ;decrement working reg, skip next line if 0
    goto    TIL
    goto    Mainline

;Initializes PORTD2:7 as output
Init
    bsf     STATUS,RP0      ;swtich to bank 1
    clrf    TRISD           ;clears TRISD to set PORTD to output
    movlw   b'11111111'
    movwf   TRISB           ;set PORTB to input
    clrf    INTCON          ;removes interrupts
    bcf     STATUS,RP0      ;bank0
    return


;ISR
;ISR_init
;	bcf 	STATUS,RP0
;	bcf 	INTCON,INTF
;	bsf 	INTCON,GIE
;	bsf		INTCON,INTE
;	return
;
;ISR_Lit
;	call Line1
;    Display Msg1
;	return

;Switch to second line of LCD
Line2
    movlw   b'11000000'
    call    WR_INS
    return

Line1
    movlw   b'10000000'
    call    WR_INS
    return


;table
MsgStart
    addwf	PCL,F
	dt		"1: Start", 0
MsgLogs
	addwf	PCL,F
	dt		"2: Logs", 0
MsgOP
    addwf	PCL,F
	dt		"Running...", 0
MsgLog
    addwf	PCL,F
	dt		"Here be the logs", 0
MsgRet
    addwf	PCL,F
	dt		"1: Return", 0
    end