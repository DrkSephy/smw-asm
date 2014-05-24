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

    TIME_TO_SHAKE   = $18
    SOUND_EFFECT    = $09 
    TIME_ON_GROUND  = $40

    SPRITE_TO_GEN   = $16

    NEXT_STATE      dcb $01,$02
    NEXT_STATE2a    dcb $04,$05
    NEXT_STATE2b    dcb $04,$05,$07
    X_SPEED2        dcb $40,$C0
    X_SPEED3        dcb $18,$E8
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
    BNE WHEN_KILLED         ; is the sprite being killed? 
    JSR SHELL_GFX           ; if not, play shell graphics routine
    BRA CONTINUE

WHEN_KILLED LDA SPRITE_STATE, x
    
    CMP #$09
    BNE TOSS_FIREBALLS      ; did the sprite get hit by fireballs?
    JSR SHELL_GFX           ; if so, play shell graphics routine
    BRA CONTINUE    

TOSS_FIREBALLS

    LDA SPRITE_STATE, x
    CMP $#07
    BNE CLEAR
    JSR SHELL_GFX
    BRA CONTINUE


CLEAR JSR, SUB_GFX          ; graphics routine when extra bit is clear

CONTINUE 

    LDA $14C8, x            ; return if sprite status != 8

ALIVE   CMP #$08              ;\ if status != 8, return
        BNE RETURN            ;| 
        LDA $9D               ;| return if sprite is locked
        BNE RETURN            ;/

NO_JUMP JSR SUB_OFF_SCREEN_X0 ; only process sprite while on screen
    
        JSL $018032            ; interact with sprites
        JSL $01A7DC            ; interact with mario
        BCC NO_CONTACT         ; return if no contact
        LDA $154C, x           ;\ if sprite invincibility timer > 0....
        BNE NO_CONTACT         ;/ go to NO_CONTACT
        LDA #$08               ;\ sprite invincibility timer = $08
        STA $154C, x           ;/
        LDA $7D                ;\ if mario's y speed < 10
        CMP #$10               ;| sprite will hurt mario
        BMI SPRITE_WINS        ;/ 



MARIO_WINS

        JSL $01AA33            ; set mario's speed
        JSL $01AB99            ; display contact graphic
        
        LDA SPRITE_STATE, x    ; return if sprite is invulnerable
        CMP #$00               
        BNE SPRITE_WINS

        JSR SUB_STOMP_PTS       ; give mario points after stomping on enemy
        LDA #$28                ;\ stomp sound effect
        STA $1DFC               ;/
        LDA #$A0                ;\ set THROW_FIRE timer
        STA $1564, x            ;/
        INC $1534, x            ; increment sprite hit counter
        LDA $1534, x            ;\ if sprite hit counter === 3
        CMP #HIT_POINTS         ;|
        BEQ SPRITE_DEAD         ;/

        LDA $#06
        STA SPRITE_STATE. x
        BRA NEW_RETURN

SPRITE_DEAD LDA #$09 
    
        STA SPRITE_STATE, x

NO_COUNT
        
        LDA #$02                ;\ sound effect
        STA $1DF9               ;/

NEW_RETURN RTS                  ; return

SPRITE_WINS LDA $1497           ;\ if mario is invincible
            ORA $187A           ;| or mario is on yoshi
            BNE NO_CONTACT      ;/ return
            JSR SUB_HORZ_POS    ;\ set new sprite direction
            TYA                 ;|
            STA $157C, x        ;/
            JSL $00F5B7         ; hurt mario

NO_CONTACT  LDA SPRITE_STATE,x
        CMP 8#$00
        BEQ WALKING
        CMP #$01
        BEQ RETREATING0
        CMP #$02
        BEQ RISING0
        CMP #$03
        BEQ FLYING0
        CMP #$04
        BEQ WAITING0
        CMP #$05
        BEQ DROPPING0
        CMP #$06
        BEQ SPINNING0
        CMP #$07
        BEQ NOW_FIRE0
        CMP #$08
        BEQ DEAD0
        CMP #$09
        BEQ COUNTDOWN0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                          State 01                       ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RETREATING0 JMP RETREATING
RISING0     JMP RISING
FLYING0     JMP FLYING
WAITING0    JMP WAITING
DROPPING0   JMP DROPPING
SPINNING0   JMP SPINNING
NOW_FIRE0   JMP NOW_FIRE
DEAD0       JMP DEAD
COUNTDOWN0  JMP COUNTDOWN

WALKING

    LDA $1588, x                ;\ if sprite collides with an object
    AND #$03                    ;|
    BEQ NO_OBJ_CONTACT          ;|
    LDA $157C, x                ;| flip the direction status
    EOR #$01                    ;|
    STA $157C, x                ;/

NO_OBJ_CONTACT

    LDA EXTRA_BITS, x
    AND #$04
    BEQ FALLING

    LDA $1588, x                ; run the subroutine if the sprite is in the air
    ORA $151C, x                ; and if it isn't turning
    BNE ON_GROUND
    JSR SUB_CHANGE_DIR
    LDA #$01                    ; set that the sprite is turning
    STA $151C, x 

ON_GROUND LDA $1588, x          ; if on the ground, reset the turn counter
        AND #$04
        BEQ IN_AIR
        STZ $151C, x
        STZ $AA, x
        BRA X_TIME

FALLING LDA $1588, x            ; if on the ground, reset the turn counter
        AND #$04 
        BEQ IN_AIR
        LDA #$10                ;\ y speed = 10
        STA $AA, x              ;/

X_TIME  LDA $1534, x            ;\ set x speed based on total HP
        ASL
        CLC
        ADC $157C, x            ; and set direction
        LDA X_SPEED, y
        STA $86, x
        JSR Hop                 ; jump to custom subroutine

Hop: 
        LDA #$D0                ; if the time isn't D0,
        CMP $1504, x            ;
        BNE IncreaseHop         ; increase it
        STZ $1504, x            ; reset timer.

        PHX
        LDA #$01
        JSL RANDOM
        TAX
        LDA NEXT_STATE, x       ;\ set sprite number for new sprite
        PLX
        STA SPRITE_STATE, x
        RTS                     ; return

IncreaseHop:

        INC $1504, x            ; increase timer 

RETURN2 RTS

RANDOM  PHX
        PHP
        SEP #$30
        PHA
        JSL $01ACF9             ; random number generation routine
        PLX
        CPX #$FF                ;\ if max is FF, handle this exception
        BNE NORMALRT            ;|
        LDA #$148B              ;|
        BRA ENDRANDOM           ;/

NORMALRT INX                    ; increase by plus 1
        LDA #$148B              ;\
        STA $4204               ;| Multiply with hardware registers
        STX $4203               ;|
        NOP                     ;|
        NOP                     ;|
        NOP                     ;|
        NOP                     ;/
        LDA $4217

ENDRANDOM PLP
        PLX
        RTL

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                           State 1                       ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RETREATING LDA #$00
           STA SPRITE_Y_SPEED, x    ; set initial speed
           JSR Hop2                 ; jump to custom code
           JSL $01801A              ; apply speed
           LDA SPRITE_Y_SPEEd, x    ; if speed below max, increase it
           CMP #MAX_Y_SPEED
           BCS DONT_INC_SPEED
           ADC #SPRITE_GRAVITY2
           STA SPRITE_Y_SPEED, x

DONT_INC_SPEED
            JSL #019138             ; interact with objects
            LDA $1564, x            ; return if sprite is invulnerable
            CMP #$00
            BNE RETURN3

Hop2: 

            LDA #$A0                ; if timer isn't A0,
            CMP $1528, x            
            BNE IncreaseHop2        ; increase the timer
            STZ $1528, x            ; reset timer
            JSR SUB_HAMMER_THROW
            DEC SPRITE_STATE, x     ; decrease sprite state to 1 
            RTS                     ; return

IncreaseHop2: 

            INC $1528, x            ; increase timer

RETURN3     RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                           State 2                       ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RISING
            JSR SUB_HORZ_POS        ; determine if mario is close and act accordingly
            TYA
            STA $157C, x
            LDA FREEZE_TIMER, x     ; if sprite is still waiting on ground, return
            BNE RETURN4
            LDA SPRITE_Y_POS, x     ; check if the sprite is in original position
            CMP ORIG_Y_POS, x
            BNE RISE
            INC SPRITE_STATE, x
            RTS

RISE        LDA #RISE_SPEED         ; set rising speed and apply it
            STA SPRITE_Y_SPEED, x
            JSL $01801A

RETURN4     RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                           State 3                       ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FLYING 
    
            LDA H_OFFSCREEN, x      ; return if offscreen horizontally
            BNE RETURN5
            STZ SPRITE_Y_SPEED, x
            LDA $1588, x            ;\ if sprite collides with an object
            AND #$03                ;|
            BEQ NO_OBJ_CONTACT3     ;|
            LDA $157C, x            ;| flip the direction flag
            EOR #$01                ;|
            STA $157C, x            ;/
            STZ $AA, x

NO_OBJ_CONTACT3
            LDY $157C, x            ;\ set x speed based on direction
            LDA X_SPEED3, y         ;| set y speed based on direction
            STA $B6, x              ;/

            JSR Bolt
            JSL $01802A             ; update position based on speed values

Bolt: 
            LDA #$D0                ; if timer isn't C0
            CMP $1504, x 
            BNE IncreaseBolt        ; increase it

            LDA $1534, x
            CMP #$02
            BCC HEALTHY

            PHX
            LDA #$02
            JSL RANDOM2
            TAX
            LDA NEXT_STATE2b, x     ; set sprite number for new sprite
            PLX

            STA SPRITE_STATE, x
            BRA FINISH_STATE

