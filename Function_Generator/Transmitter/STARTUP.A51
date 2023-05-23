ORG 00

	LCD_PORT  		 EQU  P2
	RS_PIN    		 EQU  P3.4
	EN_PIN  	     EQU  P3.5
	
	KEY_PAD_PORT     EQU  P1
	ROW_0            EQU  P1.0
	ROW_1            EQU  P1.1
	ROW_2            EQU  P1.2
	ROW_3            EQU  P1.3
	COLM_0           EQU  P1.4
	COLM_1           EQU  P1.5
	COLM_2           EQU  P1.6
	COLM_3           EQU  P1.7	
		
	OPERAND        EQU  R5

	
MAIN:

    ;INITIATE LCD AND KEYPAD
	LCALL LCD_INIT
	LCALL KEY_PAD_INIT
	LCALL SERIAL_INITIALIZATION

	
	MOV A,#0X80              ;SET CURSOR TO ROW 1, First COLUMN
	LCALL LCD_CMD 
	
AGAIN:	
	
	MOV DPTR,#MSG1
	ACALL LCD_STRING
	
	;------------------- New Line (second row) -----------------------------
	MOV A, #0C0H     // \n -> row 2 column 1
	ACALL LCD_CMD   
	;-----------------------------------------------------------------------
	
	MOV DPTR,#MSG2
	ACALL LCD_STRING
	
	
	MOV DPTR,#KEYS
	CLR A
	LCALL KEY_PAD_SCAN
	LCALL DELAY_HS			 ;TO MAKE SURE THAT THE USER PULL HIS FINGER

	;SEND DATA TO THE OTHER MICROCONTROLLER 
	ACALL SERIAL_SEND_BYTE

		
	;---------------LCD_SUBROUTINES---------------
	LCD_INIT:
				MOV A,#0X38     ;2-line/5*7
				LCALL LCD_CMD
				LCALL DELAY_MS
				MOV A,#0X0C     ;display on,cursor off
				LCALL LCD_CMD
				LCALL DELAY_MS
				MOV A,#0X06     ;shift cursor to right
				LCALL LCD_CMD
				LCALL DELAY_MS
				MOV A,#0X01     ;clear display screen 
				LCALL LCD_CMD
				LCALL DELAY_MS
				RET
				
	LCD_CMD:
			CLR RS_PIN
			SETB EN_PIN 
			lCALL  DELAY_MS
			MOV LCD_PORT,A
			CLR  EN_PIN
			RET
	LCD_CHAR:
			SETB RS_PIN
			SETB EN_PIN
			LCALL  DELAY_MS
			MOV LCD_PORT,A
			CLR  EN_PIN
			RET
			
	LCD_STRING:
			MOV A,#0
			MOVC A,@A+DPTR
			CJNE  A,#0,PRINT
			SJMP STRING_COMPLET
				PRINT:
					LCALL LCD_CHAR
					INC DPTR
					SJMP LCD_STRING
			STRING_COMPLET:
					RET
	;---------------KEY_PAD_SUBROUTINES---------------
	KEY_PAD_INIT:
			MOV KEY_PAD_PORT,#0XF0    ;initiate the rows as output & columns as input
			RET
	KEY_PAD_SCAN:
	        MOV KEY_PAD_PORT,#0XF0    ;INITAITE THE PORT VALUE
			
			MOV A,KEY_PAD_PORT        ; READ THE PORT VALUE
			
			CJNE A,#0XF0,GET_KEY      ;IF THE USER PRESS DOWN ANY BUTTON JUMP TO GET KEY SUBROUTINE
			SJMP KEY_PAD_SCAN         
				GET_KEY:
					MOV KEY_PAD_PORT,#0XFE  ;CLR THE FIRST ROW
					MOV R1,#0
					JNB COLM_0,NO_0
					JNB COLM_1,NO_1
					JNB COLM_2,NO_2
					JNB COLM_3,NO_3
					MOV KEY_PAD_PORT,#0XFD  ;CLR THE FIRST ROW
					MOV R1,#4
					JNB COLM_0,NO_0
					JNB COLM_1,NO_1
					JNB COLM_2,NO_2
					JNB COLM_3,NO_3
					MOV KEY_PAD_PORT,#0XFB  ;CLR THE FIRST ROW
					MOV R1,#8
					JNB COLM_0,NO_0
					JNB COLM_1,NO_1
					JNB COLM_2,NO_2
					JNB COLM_3,NO_3
					MOV KEY_PAD_PORT,#0XF7  ;CLR THE FIRST ROW
					MOV R1,#12
					JNB COLM_0,NO_0
					JNB COLM_1,NO_1
					JNB COLM_2,NO_2
					JNB COLM_3,NO_3
					SJMP KEY_PAD_FINISH
					     NO_0:
							MOV A,R1
							MOVC A,@A+DPTR
							SJMP KEY_PAD_FINISH
						 NO_1:
							MOV A,R1
							ADD A,#1
							MOVC A,@A+DPTR
							SJMP KEY_PAD_FINISH
						 NO_2:
						 MOV A,R1
							ADD A,#2
							MOVC A,@A+DPTR
							SJMP KEY_PAD_FINISH
						 NO_3:
						 MOV A,R1
							ADD A,#3
							MOVC A,@A+DPTR
							SJMP KEY_PAD_FINISH
			KEY_PAD_FINISH:
					RET
	;---------------DELAYS_SUBROUTINES---------------				
	DELAY_MS:
			MOV R0,#200
			LOOP_2:
				MOV R1,#200
			LOOP_1:
				DJNZ R1,LOOP_1
		        DJNZ R0,LOOP_2
				RET
	DELAY_HS:
			MOV R0,#10
			LOOP__3: MOV R1,#100
			LOOP__2: MOV R2,#200
			LOOP__1: DJNZ R2,LOOP__1
					 DJNZ R1,LOOP__2
					 DJNZ R0,LOOP__3
			RET
	;-----------------SERIAL_SUBROUTENS--------------
	SERIAL_INITIALIZATION:
	
		MOV TMOD,#0X20
		MOV TH1,#-3   ;9600 baud rate
		MOV SCON,#0X50
		SETB TR1
	RET
	
	SERIAL_SEND_BYTE:
		MOV SBUF,A
		TRANSMIT_LOOP:
		JNB TI,TRANSMIT_LOOP
		CLR TI
	RET
	
	SERIAL_RECEIVE_BYTE:
		RECEIVE_LOOP:
		JNB RI,RECEIVE_LOOP
		MOV A,SBUF
		CLR RI
	RET

	;---------------MEMORY-ASSIGNMENT---------------
	ORG 300H
	KEYS:   DB '7','8','9','/','4','5','6','*','1','2','3','-','C','0','=','+'

	MSG1:	DB "1: SIN   2: RMP",0 
	MSG2:	DB "3: S_TH  4: SQ",0
	FINISH:			
			END