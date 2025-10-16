        ORG 4000H

;------------------------------------------------------------
; CONSTANTS
;------------------------------------------------------------

CTRL    EQU 1900H
DATA    EQU 1800H
DELAY   EQU 0620H

S_PAT   EQU 029H
I_PAT   EQU 09FH
C_PAT   EQU 06CH
O_PAT   EQU 00CH
M_PAT   EQU 0AEH
P_PAT   EQU 0C8H
r_PAT   EQU 0FAH ; 'r'
THREE   EQU 00BH
ZERO    EQU 00CH

;------------------------------------------------------------
; MAIN PROGRAM
;------------------------------------------------------------

START:
;        LXI  H,SICOMP    ; display "SICOMP"
;        CALL DFRAME
;
;        LXI  D,07FFFH    ; wait ~1 second
;        CALL DELAY
;
;        LXI  H,SICOMP    ; rotate backward -> "ICOMPS"
;        MVI  C,5         ; number of bytes - 1
;        CALL ROTMB
;
;        LXI  H,SICOMP
;        CALL DFRAME
;
;        LXI  D,07FFFH
;        CALL DELAY
;
;        LXI  H,SICOMP    ; rotate forward -> "SICOMP"
;        MVI  C,5
;        CALL ROTMF
;
;        LXI  H,SICOMP
;        CALL DFRAME
;
;        LXI  D,07FFFH
;        CALL DELAY
PROLOG:
        CALL PNON5F     ; play nonsense

        LXI  H,NONSNS+1 ; let 'I' appear
        MVI  B,I_PAT
        CALL REP5FP
        LXI  H,NONSNS+5 ; let 'P' appear
        MVI  B,P_PAT
        CALL REP5FP
        LXI  H,NONSNS+4 ; let 'M' appear
        MVI  B,M_PAT
        CALL REP5FP
        LXI  H,NONSNS+2 ; let 'C' appear
        MVI  B,C_PAT
        CALL REP5FP
        LXI  H,NONSNS+0 ; let 'S' appear
        MVI  B,S_PAT
        CALL REP5FP
        LXI  H,NONSNS+3 ; let 'O' appear
        MVI  B,O_PAT
        CALL REP5FP
LOOP:
        MVI  C,3
BLINK:
        LXI  H,EMPTYF ; clear display
        CALL DFRAME
        LXI  D,06000H ; wait
        CALL DELAY

        LXI  H,NONSNS+24 ; now "SICOMP"
        CALL DFRAME
        LXI  D,06000H ; wait
        CALL DELAY

        DCR  C
        JNZ  BLINK

        MVI  C,6
SHFTL:
        INX  H
        CALL DFRAME
        LXI  D,03000H
        CALL DELAY
        DCR  C
        JNZ  SHFTL

        LXI  H,R30+6
        MVI  C,6
SHFTR:
        DCX  H
        CALL DFRAME
        LXI  D,03000H
        CALL DELAY
        DCR  C
        JNZ  SHFTR

        MVI  C,2
WAIT:
        LXI  D,0FFFFH
        CALL DELAY
        DCR  C
        JNZ  WAIT

        JMP  LOOP

; REP5FP - replace byte in 5 frames at M
;
REP5FP:
        LXI  D,6
        MVI  C,5
        CALL REPINT
        CALL PNON5F

; PNON5F - play 5 frames of nonsense
;
PNON5F:
        LXI  H,NONSNS
        LXI  D,01800H
        MVI  C,5
        CALL PFRAMD

        RET

; REPINT - replace N bytes in M with interval size I.
;          byte in B, N in C, I in DE
;
REPINT:
        MOV  M,B
        DAD  D
        DCR  C
        JNZ  REPINT

        RET

; PFRAMD - play N frames at M with delay.
;          N in C, delay in DE
;
PFRAMD:
        CALL DFRAME
        PUSH D      ; save delay
        CALL DELAY
        PUSH B      ; save N on stack
        LXI  B,6    ; 6 bytes per frame
        DAD  B      ; advance M to next frame
        POP  B      ; restore N
        POP  D      ; restore delay
        DCR  C
        JNZ  PFRAMD

        RET

;------------------------------------------------------------
; ROTMF – rotate N bytes in memory at M forward. N-1 in C
;------------------------------------------------------------

ROTMF:
        MVI  B,0  ; prepare BC for DAD
        DAD  B
        PUSH H    ; HL -> last
        POP  D    ; DE = HL
        DCX  D    ; DE -> last-1
        MOV  B,M
        PUSH B    ; save last byte on stack
ROTMF2:
        XCHG
        MOV  B,M  ; previous byte in B...
        XCHG
        MOV  M,B  ; ...moved one forward
        DCX  D
        DCX  H
        DCR  C
        JP   ROTMF2

        INX  H    ; adjust
        POP  B    ; retrieve last
        MOV  M,B  ; store as first

        RET

;------------------------------------------------------------
; ROTMB – rotate N bytes at M backward. N-1 in C
;------------------------------------------------------------

ROTMB:
        PUSH H    ; HL -> first
        POP  D    ; DE = HL
        INX  D    ; DE -> first+1
        MOV  B,M
        PUSH B    ; save first byte on stack
ROTMB2:
        XCHG
        MOV  B,M  ; next byte in B...
        XCHG
        MOV  M,B  ; ...moved one backward
        INX  D
        INX  H
        DCR  C
        JP   ROTMB2

        DCX  H    ; adjust
        POP  B    ; retrieve first
        MOV  M,B  ; store as last

        RET

;------------------------------------------------------------
; DFRAME – display 6-byte frame (dcbapgfe) at M left to right
;------------------------------------------------------------

DFRAME:
        PUSH B
        PUSH H

        MVI  A,090H    ; address digits
        STA  CTRL
        MVI  C,4
DFRAM2:
        MOV  A,M
        STA  DATA
        INX  H
        DCR  C
        JNZ  DFRAM2

        MVI  A,094H    ; data digits
        STA  CTRL
        MVI  C,2
DFRAM3:
        MOV  A,M
        STA  DATA
        INX  H
        DCR  C
        JNZ  DFRAM3

        POP  H
        POP  B
        RET

;------------------------------------------------------------
; DATA TABLES
;------------------------------------------------------------

SICOMP: DB S_PAT,I_PAT,C_PAT,O_PAT,M_PAT,P_PAT ; "SICOMP"

EMPTYF: DB 0FFH, 0FFH, 0FFH, 0FFH, 0FFH, 0FFH  ; "      "

NONSNS: DB 0B6H, 02FH, 0DDH, 00DH, 038H, 081H ; 5 random frames
        DB 0C8H, 011H, 05EH, 04DH, 0F3H, 042H ; 6 bytes each
        DB 026H, 076H, 005H, 097H, 059H, 0E8H
        DB 0C1H, 00CH, 06CH, 002H, 0FFH, 0AEH
        DB 03DH, 08BH, 028H, 0D4H, 046H, 065H
        DB 09FH, 0FBH, 0FBH, 0FBH, 0FBH, 0FBH ; broom

R30:    DB 0FFH, 0FFH, 0FFH, r_PAT,THREE,ZERO ; "   r30"
        DB 09FH, 0FBH, 0FBH, 0FBH, 0FBH, 0FBH ; broom

        END
