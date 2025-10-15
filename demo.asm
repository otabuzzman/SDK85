        ORG 2000H

CTRL    EQU 1900H       ; Control register
DATAREG EQU 1800H       ; Data register
DELAY   EQU 0620H       ; Delay subroutine (DE = time, FFFF = 1s)

; ------------------------------------------------------------
; Segment bit layout: d e f g p a b c  (bit7..0)
; Active-low (0 = segment ON) → we CMA before writing
; ------------------------------------------------------------

; ---------- segment patterns (active-low) ---------- 

;               d
;           dcbapgfe
ZERO    EQU 00001100B
ONE     EQU 10011111B
TWO     EQU 01001010B
THREE   EQU 00001011B
FOUR    EQU 10011001B
FIVE    EQU 00101001B
SIX     EQU 00101000B
SEVEN   EQU 10001111B
EIGHT   EQU 00001000B
NINE    EQU 00001001B
AHEX    EQU 10001000B
BHEX    EQU 00111000B
CHEX    EQU 01101100B
DHEX    EQU 00011010B
EHEX    EQU 01101000B
FHEX    EQU 11101000B
BLANK   EQU 11111111B

; ------------------------------------------------------------
; Output 4 address digits (HL → 4 bytes)
; ------------------------------------------------------------
OUTADDR:
        MVI  A,090H
        STA  CTRL
        MVI  B,4
OA1:    MOV  A,M
        STA  DATAREG
        INX  H
        DCR  B
        JNZ  OA1
        RET

; ------------------------------------------------------------
; Output 2 data digits (HL → 2 bytes)
; ------------------------------------------------------------
OUTDATA:
        MVI  A,094H
        STA  CTRL
        MVI  B,2
OD1:    MOV  A,M
        STA  DATAREG
        INX  H
        DCR  B
        JNZ  OD1
        RET

; ------------------------------------------------------------
; Short delay (~0.3 s)
; ------------------------------------------------------------
DELAY300:
        LXI  D,04C00H
        CALL DELAY
        RET

; ------------------------------------------------------------
; Self-test: all segments ON for ~0.5 s
; ------------------------------------------------------------
SELFTEST:
        LXI  H,TESTA
        CALL OUTADDR
        LXI  H,TESTD
        CALL OUTDATA
        LXI  D,07FFFH       ; ≈0.5 s
        CALL DELAY
        RET

; ------------------------------------------------------------
; Main loop
; ------------------------------------------------------------
MAIN:
        CALL SELFTEST

LOOP:
        ; ---- blank ----
        LXI  H,FRAME0A
        CALL OUTADDR
        LXI  H,FRAME0D
        CALL OUTDATA
        CALL DELAY300

        ; ---- C0FF  EE ----
        LXI  H,FRAME1A
        CALL OUTADDR
        LXI  H,FRAME1D
        CALL OUTDATA
        CALL DELAY300

        ; ---- DEAD  00 ----
        LXI  H,FRAME2A
        CALL OUTADDR
        LXI  H,FRAME2D
        CALL OUTDATA
        CALL DELAY300

        ; ---- C0DE  F0 ----
        LXI  H,FRAME3A
        CALL OUTADDR
        LXI  H,FRAME3D
        CALL OUTDATA
        CALL DELAY300

        JMP  LOOP

; ------------------------------------------------------------
; Frame data (4 + 2 bytes each)
; ------------------------------------------------------------
TESTA:   DB 00000000B,00000000B,00000000B,00000000B   ; all ON (active-low)
TESTD:   DB 00000000B,00000000B

FRAME0A: DB BLANK,BLANK,BLANK,BLANK
FRAME0D: DB BLANK,BLANK

FRAME1A: DB CHEX,ZERO,FHEX,FHEX         ; "C0FF"
FRAME1D: DB EHEX,EHEX                   ; "EE"

FRAME2A: DB DHEX,EHEX,AHEX,DHEX         ; "DEAD"
FRAME2D: DB BLANK,BLANK

FRAME3A: DB CHEX,ZERO,DHEX,EHEX         ; "C0DE"
FRAME3D: DB FOUR,TWO                    ; "42"

        END
