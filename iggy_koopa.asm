;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                    David Leonard                       ;
;                Description: Iggy Koopa                 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Uses first extra bit: NO
; Extra Property Byte 1
;   - bit 0: Enable Spin Killing
;   - bit 1: stay on ledges

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    SPRITE_X_SPEED = $B6
    SPRITE_Y_SPEED = $AA
    SPRITE_Y_POS   = $D8
    ORIG_Y_POS     = $151C
    MAX_Y_SPEED    = $3E
    EXTRA_BITS     = $7FAB10
    EXTRA_PROP_1   = $7FAB28
    HIT_POINTS     = $05        ;  being stomped by Mario
    H_OFFSCREEN    = $15A0
    V_OFFSCREEN    = $186C
    FREEZE_TIMER   = $1540
    SPR_OBJ_STATUS = $1588
    SMASH_STATUS   = $1602

    IS_ON_GROUND    = $04
    SPRITE_GRAVITY  = $20
    SPRITE_GRAVITY2 = $04
    RISE_SPEED      = $E0
    FALL_SPEED      = $10

    IME_TO_SHAKE   = $18
    SOUND_EFFECT    = $09 
    TIME_ON_GROUND  = $40

    SPRITE_TO_GEN   = $16

    NEXT_STATE  dcb $01,$02
    NEXT_STATE2a    dcb $04,$05
    NEXT_STATE2b    dcb $04,$05,$07
    X_SPEED2    dcb $40,$C0
    X_SPEED3    dcb $18,$E8
    KILLED_X_SPEED  dcb $F0,$10
    SPRITE_STATE    = $C2

    XMAX        dcb $20,$D0
    XACCEL      dcb $02,$FE

X_SPEED     dcb $08,$F8,$08,$F8,$0C,$F4,$10,$F0,$14,$EC

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                       Sprite init JSL                   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    dcb "INIT"
    PHY
    JSR SUB_HORZ_POS
    TYA
    STA $157C, x
    PLY
    LDA $1588, x    ; if on the ground, reset the turn counter
    ORA #$04        
    STA $1588, x    ; if on the ground, reset the turn counter

    RTL

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                       Sprite code JSL                   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    dcb "MAIN"
    PHB                     ; \
    PHK                     ; | main sprite function, simply calls subroutine
    subroutine              ; |
    PLB                     ; |
    JSR SPRITE_CODE_START   ; |
    PLB                     ; |
    RTL                     ; /


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                       Sprite main code                  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RETURN          RTS
SPRITE_CODE_START
    
    LDA SPRITE_STATE, x     ;\ check state of sprite
    CMP #$02                ;| compare values
    BNE ON_CEILING          ;| is the sprite on the ceiling? 
    JSR UPSIDE_GFX          ;| if true, play upside-down animation
    BRA CONTINUE

ON_CEILING LDA SPRITE_STATE, x ; rebuilding the sprite
    
    CMP #$03
    BNE UPSIDE_WAIT
    JSR UPSIDE_GFX          ; graphics routine when the extra bit is set
    BRA CONTINUE

UPSIDE_WAIT LDA SPRITE_STATE, x ; rebuilding the sprite
    CMP #$04
    BNE WHEN_SPINNING       ; is the sprite in the spinning state? 
    JSR UPSIDE_GFX          ; graphics routine when extra bit is set
    BRA CONTINUE

WHEN_SPINNING LDA SPRITE_STATE, x
    CMP #$06
    BNE WHEN_KILLED
    JSR SHELL_GFX
    BRA CONTINUE
    




