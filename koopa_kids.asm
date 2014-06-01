;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; David Leonard
;
; Super Mario World Koopa Kids 
;
; This file contains an implementation which can be 
; shared across all of the koopa kid boss fights in
; super mario world. 
;
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

HEALTHY
        
            PHX
            LDA #$01
            JSL RANDOM2
            TAX
            LDA NEXT_STATE2a, x     ; set sprite number for new sprite
            PLX
            STA SPRITE_STATE, x

FINISH_STATE STZ $1504, x           ; reset timer
             RTS                    ; return

IncreaseBolt: 
            INC $1504, x            ; increase timer

RETURN5     RTS

RANDOM2     PHX
            PHP
            SEP #$30
            PHA
            JSL $01ACF9             ; random number generation routine
            PLX
            CPX #$FF                ;\ if max is FF, handle the exception
            BNE NORMALRT2           ;|
            LDA $148B               ;|
            BRA ENDRANDOM2          ;/

NORMALRT2   INX                     ; amount plus 1
            LDA $148B               ;\
            STA $4202               ;| multiple with hardware registers
            STX $4203               ;|
            NOP                     ;|
            NOP                     ;|
            NOP                     ;|
            NOP                     ;/
            LDA $4217 

ENDRANDOM2  PLP
            PLX
            RTL

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                           State 4                       ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WAITING     LDA #$00
            STA SPRITE_Y_SPEED, x   ; set intial speed
            JSR Wait                ; jump to custom code
            JSL #01801A             ; apply speed
            LDA SPRITE_Y_SPEED, x   ; increase speed if below the max
            CMP #MAX_Y_SPEED
            BCS DONT_INC_SPEED2
            ADC #SPRITE_GRAVITY2
            STA SPRITE_Y_SPEED, x

DONT_INC_SPEED2
        
            JSL $019138             ; interact with objects
            LDA $1564, x            ; return if sprite is invulnerable
            CMP #$00
            BNE RETURN5

Wait:

            LDA #$A0                ; if timer isn't A0
            CMP $1528, x 
            BNE IncreaseWait        ; increase the timer
            STZ $1528, x            ; reset the timer
            JSR SUB_HAMMER_THROW
            DEC SPRITE_STATE, x     ; decrease sprite state to 1
            RTS                     ; return

IncreaseWait:
            INC $1528, x            ; increase timer

RETURN5 
            RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                           State 5                       ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DROPPING    JSL $01801A                ; apply speed
            LDA SPRITE_Y_SPEED, x      ; increase speed if below the max
            CMP #MAX_Y_SPEED
            BCS DONT_INC_SPEED
            ADC #SPRITE_GRAVITY2
            STA SPRITE_Y_SPEED, x

DONT_INC_SPEED

            JSL $019138                 ; interact with objects
            LDA $1588, x                ; return if not on the ground
            AND #IS_ON_GROUND
            BEQ RETURN6 
            JSR SUB_HORZ_POS            ;\ always face Mario
            TYA                         ;|
            STA $157C, x                ;/

            LDA #TIME_ON_GROUND         ; set time to stay on ground
            STA FREEZE_TIMER, x
            STZ SPRITE_STATE, x

RETURN6     RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                           State 6                       ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SPINNING

NOSPRC      JSR SUB_HORZ_POS
            TYA
            LDA XMAX, y
            CMP $B6, x
            BEQ SETSPD
            LDA $86, x
            CLC
            ADC XACCEL, y
            STA $B6, x

SETSPD      LDA $1588, x
            AND #$04
            BEQ NOWALLS
            STZ $AA, x

NOWALLS     LDA $1588, x
            AND #$03
            BEQ INAIR
            LDA $B6, x
            EOR #$FF
            INC A
            STA $B6, x

NOSMASH     LDA $77
            AND #$04
            BEQ INITALIZE
            LDA #$20
            STA $18BD

INITALIZE
            
            STZ $1504, x            ; reset timer
            LDA #$02
            STA SPRITE_STATE, x

INAIR
            
            JSL $01802A

RETURN7     
            
            RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                           State 7                       ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NOW_FIRE    LDA #$00
            STA SPRITE_Y_SPEED      ; set initial speed
            JSR Fire                ; jump to custom code
            JSL $01801A             ; apply speed
            LDA SPRITE_Y_SPEED, x   ; increase speed if below the max
            CMP #MAX_Y_SPEED
            BCS DONT_INC_SPEEDF
            ADC #SPRITE_GRAVITY2
            STA SPRITE_Y_SPEED, x

DONT_INC_SPEEDF
            
            JSL $019138             ; interact with objects
            LDA $1564, x            ; return if sprite is invulnerable
            CMP #$00
            BNE RETURN7

Fire:
        
            LDA #$A0                ; if timer isn't A0
            CMP $1504, x            
            BNE IncreaseFire        ; increase it
            STZ $1504, x            ; reset timer
            LDA #$03
            STA SPRITE_STATE, x
            RTS                     ; return

IncreaseFire:

            LDA $1504, x            ; check if the timer is greater than $60
            CMP #$20
            BNE ONE_SHOT
            JSR SUB_FIRE_THROW
            BRA INC_TIME2

ONE_SHOT    CMP #$40
            BNE TWO_SHOTS
            JSR SUB_FIRE_THROW
            BRA INC_TIME2

TWO_SHOTS   CMP #$60
            BNE THREE_SHOTS
            JSR SUB_FIRE_THROW
            BRA INC_TIME2

THREE_SHOTS CMP #$80
            BNE FOUR_SHOTS
            JSR SUB_FIRE_THROW
            BRA INC_TIME2

FOUR_SHOTS  CMP #$A0
            BRE NO_FIRE
            JSR SUB_FIRE_THROW

NO_FIRE     
INC_TIME2   INC $1504, x             ; increase timer

RETURN7     RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                           State 8                       ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DEAD        LDA FREEZE_TIMER, x
            BNE RETURN8
            STZ SPRITE_X_SPEED, x
            LDA $0F30
            AND $01
            BNE RETURN8
            INC SMASH_STATUS, x
            LDA SMASH_STATUS, x
            CMP #$02
            BNE RETURN8
            INC SPRITE_STATE, x         ; change state to falling

RETURN8     RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                           State 9                       ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

COUNTDOWN

            LDA $1588, x                ;\ if sprite is in contact with an object
            AND #$03                    ;|
            BEQ NO_OBJ_CONTACT1         ;|
            LDA #$04                    ;/ kill object
            STA $14C8, x
            JSL $07FC3B                 ; show star animation
            LDA #$08                    ;\ play sound effect
            STA $1DF9                   ;/ 

            LDA EXTRA_BITS, x
            AND #$04
            BEQ CLEAR_END

GOAL        
            
            DEC $13C6                   ; prevent mario from walking at the level end
            LDA #$FF                    ;\ set goal
            STA $1493                   ;/
            LDA #$0B                    ;\ set ending music
            STA $1DFB                   ;/
            RTS                         ; return
            BRA CONTINUE_END

CLEAR_END
CONTINUE_END

NO_OBJ_CONTACT1
            
            LDY $157C, x                ;\ set x speed based on direction
            LDA X_SPEED2, y             ;| set y speed based on direction
            STA $B6, x                  ;/

RETURN9     JSL $01802A                 ; apply speed
            RTS                         ; return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                       Hammer Routine                    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

X_OFFSET     dcb $06, $FA
X_OFFSET2    dcb $00, $FF

SUB_HAMMER_THROW

            JSL $02A9DE                 ;\ get an index to an unused sprite slot, return if all slots are full
            BMI RETURN10                ;/ after: Y has index of sprite being generated
            PHX
            TYX
            LDA #$20                    ; play hammer sound effect
            STA $1DF9
            LDA #$08
            STA $14C8, x
            LDA #SPRITE_TO_GEN
            STA $7FAB9E, x
            JSL $07F7D2
            JSL $0187A7
            LDA #$08
            STA $7FAB10, x
            PLX

            PHY
            LDA $157C, x
            TAY
            LDA $E4, x                  ; set x-low position for new sprite
            CLC
            ADC X_OFFSET, y

            PHY
            LDA $157C, x
            TAY
            LDA $14E0, x                ; set x-high position for new sprite
            ADC X_OFFSET2, y
            PLY
           
            LDA $D8, x                  ;\ set y position for new sprite
            SEC                         ;|
            SBC #$0E                    ;|
            STA $00D8, y                ;|
            LDA $14D4, x                ;|
            SBC #$00                    ;|
            STA $14D4, y                ;/

            PHX                         ;\ before: X must have index of sprite being generated
            TYX                         ;| routine clears all old sprite values
            JSL $07F7D2                 ;| and loads in new values for the 6 main sprite tables
            JSL $0187A7                 ;| get table values for custom sprite
            LDA #$88
            STA EXTRA_BITS, x
            PLX                         ;/

            LDA $157C, x 
            STA $157C, y

RETURN10    RTS                         ; return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                       Aiming Routine                    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CODE_01BF6A:
        
            STA $01 
            PHX                         ;\ preserve sprite indexes of Magickoopa and magic
            PHY                         ;/
            JSR SUB_VERT_POS            ; $0E = vertical distance to mario
            STY $02                     ; $02 = vertical distance to mario
            LDA $0E                     ;\ $0C = vertical distance to mario, positive
            BPL CODE_01BF7C             ;|
            EOR #$FF                    ;|
            CLC                         ;|
            ADC #$01                    ;/

CODE_01BF7C:    

            STA $0C                     ;/
            JSR SUB_HORZ_POS            ;| $0F = horizontal distance to mario
            STY $03                     ;| $03 = horizontal distance to mario
            LDA $0F                     ;\ $0D = horizontal distance to mario, positive
            BPL CODE_01BF8C 
            EOR #$FF
            CLC
            ADC #$01

CODE_01BF8C: 

            STA $0D                     ;\
            LDY #$00                    ;|
            LDA $0D                     ;| if vertical distance less than horizontal distance
            CMP $0C                     ;|
            BCS CODE_01BF9F             ;/ branch
            INY                         ;| set y register
            PHA                         ;| switch $0C and $0D
            LDA $0C                     ;|
            STA $0D                     ;|
            PLA                         ;|
            STA $0C                     ;/

CODE_01BF9F:
        
            LDA #$00                    ;\ zero out $00 and $0B
            STA $0B                     ;|
            STA $00                     ;|
            LDX $01                     ;/ divide $0C by $0D

CODE_01BFA7: 

            LDA $0B                     ;\ if $0C + loop counter is < $0D
            CLC                         ;|
            ADC $0C                     ;|
            CMP $0D                     ;|
            BCC CODE_01BFB4             ;| branch
            SBC $0D                     ;| else, subtract $0D
            INC $00                     ;/ and increase $00

CODE_01BFB4: 

            STA $0B                     ;\
            DEX                         ;| if cycles left to run,
            BNE CODE_01BFA7             ;/ go to start of loop
            TYA                         ;\ if $0C and $0D was not switched,
            BEQ CODE_01BFC6             ;| branch
            LDA $00                     ;/ else, switch $00 and $01 
            PHA     
            LDA $01 
            STA $00
            PLA
            STA $01 

CODE_01BFC6:        

            LDA $00                     ;\ if horizontal distance was inverted,
            LDY $02                     ; | invert $00
            BEQ CODE_01BFD3             ; |
            EOR #$FF                    ; |
            CLC                         ; |
            ADC #$01                    ; |
            STA $00                     ;/

CODE_01BFD3:        

            LDA $01                     ;\ if vertical distance was inverted,
            LDY $03                     ;| invert $01
            BEQ CODE_01BFE0             ; |
            EOR #$FF                    ; |
            CLC                         ; |
            ADC #$01                    ; |
            STA $01                     ;/

CODE_01BFE0:        

            PLY                         ;\ retrieve Magikoopa and magic sprite indexes
            PLX                         ;/
            RTS                         ; return


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                   Projectile Routine                    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

X_SPEED_HAMMERa     dcb $10, $F0
Y_SPEED_HAMMERa     dcb $07, $07

SUB_FIRE_THROW
                    LDY #$E8                ;A:0218 X:0009 Y:0009 D:0000 DB:03 S:01E8 P:envMXdizcHC:0522 VC:104 00 FL:19452
                    LDA $157C,x             ;A:0218 X:0009 Y:00E8 D:0000 DB:03 S:01E8 P:eNvMXdizcHC:0538 VC:104 00 FL:19452
                    BNE LABEL9a             ;A:0201 X:0009 Y:00E8 D:0000 DB:03 S:01E8 P:envMXdizcHC:0570 VC:104 00 FL:19452
                    LDY #$18                ;A:0200 X:0009 Y:00E8 D:0000 DB:03 S:01E8 P:envMXdiZcHC:0210 VC:098 00 FL:21239

LABEL9a             STY $00                 ;A:0201 X:0009 Y:00E8 D:0000 DB:03 S:01E8 P:envMXdizcHC:0592 VC:104 00 FL:19452
                    LDY #$07                ;A:0201 X:0009 Y:00E8 D:0000 DB:03 S:01E8 P:envMXdizcHC:0616 VC:104 00 FL:19452

LABEL8a             LDA $170B,y             ;A:0201 X:0009 Y:0007 D:0000 DB:03 S:01E8 P:envMXdizcHC:0632 VC:104 00 FL:19452
                    BEQ LABEL7a             ;A:0200 X:0009 Y:0007 D:0000 DB:03 S:01E8 P:envMXdiZcHC:0664 VC:104 00 FL:19452
                    DEY                     ;A:0204 X:0009 Y:0007 D:0000 DB:03 S:01E8 P:envMXdizcHC:0088 VC:103 00 FL:19638
                    BPL LABEL8a             ;A:0204 X:0009 Y:0006 D:0000 DB:03 S:01E8 P:envMXdizcHC:0102 VC:103 00 FL:19638
                    RTS                     ; return

LABEL7a             LDA #$02                ; \ projectile is a fireball
                    STA $170B,y             ; /

                    LDA $E4,x               ; \ set x position
                    CLC                     ;  |
                    ADC #$05                ;  |
                    STA $171F,y             ;  |
                    LDA $14E0,x             ;  |
                    ADC #$00                ;  |
                    STA $1733,y             ; /
                    
                    LDA $D8,x               ; \ set y position
                    CLC                     ;  |
                    ADC #$00                ;  |
                    STA $1715,y             ;  |
                    LDA $14D4,x             ;  |
                    ADC #$00                ;  |
                    STA $1729,y             ; /

                    LDA #$50
                    JSR CODE_01BF6A
                    LDX $15E9
                    LDA $00
                    STA $173D,y
                    LDA $01
                    STA $1747,y

LABEL6a             RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                     Graphics Routine                    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PROPERTIES: db $7F,$3F

;The tables must now have 16 bytes.
;THE LAST 8 ARE ONLY CREATED BECAUSE OF XDISP.

;0-4 BYTE   - FRAME 1 RIGHT
;4-8 BYTE   - FRAME 2 RIGHT
;8-12 BYTE  - FRAME 1 LEFT
;12-16 BYTE - FRAME 2 LEFT

TILEMAP:
    db $00,$02,$20,$22,$40,$42,$60,$62 ; WALKING 1 ;\ RIGHT
    db $00,$02,$24,$26,$44,$46,$64,$66 ; WALKING 2 ;\ RIGHT
    db $00,$02,$28,$2A,$48,$4A,$68,$6A ; WALKING 3 ;\ RIGHT
    db $00,$02,$24,$26,$44,$46,$64,$66 ; WALKING 4 ;\ RIGHT
    db $00,$02,$A0,$A2,$C0,$C2,$E0,$E2 ; WALKING 1 ;\ RIGHT
    db $00,$02,$A0,$A2,$C0,$C2,$E0,$E2 ; WALKING 2 ;\ RIGHT
    db $00,$02,$A8,$AA,$C8,$CA,$E8,$EA ; WALKING 3 ;\ RIGHT
    db $00,$02,$A8,$AA,$C8,$CA,$E8,$EA ; WALKING 4 ;\ RIGHT
    db $00,$02,$A4,$A6,$C4,$C6,$E4,$E6 ; WALKING 1 ;\ RIGHT
    db $00,$02,$A4,$A6,$C4,$C6,$E4,$E6 ; WALKING 2 ;\ RIGHT
    db $00,$02,$A4,$A6,$C4,$C6,$E4,$E6 ; WALKING 3 ;\ RIGHT
    db $00,$02,$A4,$A6,$C4,$C6,$E4,$E6 ; WALKING 4 ;\ RIGHT
    db $00,$02,$2C,$2E,$4C,$4E,$6C,$6E
    db $00,$02,$2C,$2E,$4C,$4E,$6C,$6E
    db $00,$02,$2C,$2E,$4C,$4E,$6C,$6E
    db $00,$02,$2C,$2E,$4C,$4E,$6C,$6E

    db $00,$02,$20,$22,$40,$42,$60,$62 ; WALKING 1 ;\ LEFT
    db $00,$02,$24,$26,$44,$46,$64,$66 ; WALKING 2 ;\ LEFT
    db $00,$02,$28,$2A,$48,$4A,$68,$6A ; WALKING 3 ;\ LEFT
    db $00,$02,$24,$26,$44,$46,$64,$66 ; WALKING 4 ;\ LEFT
    db $00,$02,$A0,$A2,$C0,$C2,$E0,$E2 ; WALKING 1 ;\ LEFT
    db $00,$02,$A0,$A2,$C0,$C2,$E0,$E2 ; WALKING 2 ;\ LEFT
    db $00,$02,$A8,$AA,$C8,$CA,$E8,$EA ; WALKING 3 ;\ LEFT
    db $00,$02,$A8,$AA,$C8,$CA,$E8,$EA ; WALKING 4 ;\ LEFT
    db $00,$02,$A4,$A6,$C4,$C6,$E4,$E6 ; WALKING 1 ;\ LEFT
    db $00,$02,$A4,$A6,$C4,$C6,$E4,$E6 ; WALKING 2 ;\ LEFT
    db $00,$02,$A4,$A6,$C4,$C6,$E4,$E6 ; WALKING 3 ;\ LEFT
    db $00,$02,$A4,$A6,$C4,$C6,$E4,$E6 ; WALKING 4 ;\ LEFT
    db $00,$02,$2C,$2E,$4C,$4E,$6C,$6E
    db $00,$02,$2C,$2E,$4C,$4E,$6C,$6E
    db $00,$02,$2C,$2E,$4C,$4E,$6C,$6E
    db $00,$02,$2C,$2E,$4C,$4E,$6C,$6E

YDISP:
    db $D0,$D0,$E0,$E0,$F0,$F0,$00,$00 ; WALKING 1 ;\ RIGHT
    db $D0,$D0,$E0,$E0,$F0,$F0,$00,$00 ; WALKING 2 ;\ RIGHT
    db $D0,$D0,$E0,$E0,$F0,$F0,$00,$00 ; WALKING 3 ;\ RIGHT
    db $D0,$D0,$E0,$E0,$F0,$F0,$00,$00 ; WALKING 4 ;\ RIGHT
    db $D0,$D0,$E0,$E0,$F0,$F0,$00,$00 ; WALKING 1 ;\ RIGHT
    db $D0,$D0,$E0,$E0,$F0,$F0,$00,$00 ; WALKING 2 ;\ RIGHT
    db $D0,$D0,$E0,$E0,$F0,$F0,$00,$00 ; WALKING 3 ;\ RIGHT
    db $D0,$D0,$E0,$E0,$F0,$F0,$00,$00 ; WALKING 4 ;\ RIGHT
    db $D0,$D0,$E0,$E0,$F0,$F0,$00,$00 ; WALKING 1 ;\ RIGHT
    db $D0,$D0,$E0,$E0,$F0,$F0,$00,$00 ; WALKING 2 ;\ RIGHT
    db $D0,$D0,$E0,$E0,$F0,$F0,$00,$00 ; WALKING 3 ;\ RIGHT
    db $D0,$D0,$E0,$E0,$F0,$F0,$00,$00 ; WALKING 4 ;\ RIGHT
    db $D0,$D0,$E0,$E0,$F0,$F0,$00,$00 ; WALKING 1 ;\ RIGHT
    db $D0,$D0,$E0,$E0,$F0,$F0,$00,$00 ; WALKING 2 ;\ RIGHT
    db $D0,$D0,$E0,$E0,$F0,$F0,$00,$00 ; WALKING 3 ;\ RIGHT
    db $D0,$D0,$E0,$E0,$F0,$F0,$00,$00 ; WALKING 4 ;\ RIGHT

    db $D0,$D0,$E0,$E0,$F0,$F0,$00,$00 ; WALKING 1 ;\ LEFT
    db $D0,$D0,$E0,$E0,$F0,$F0,$00,$00 ; WALKING 2 ;\ LEFT
    db $D0,$D0,$E0,$E0,$F0,$F0,$00,$00 ; WALKING 3 ;\ LEFT
    db $D0,$D0,$E0,$E0,$F0,$F0,$00,$00 ; WALKING 4 ;\ LEFT
    db $D0,$D0,$E0,$E0,$F0,$F0,$00,$00 ; WALKING 1 ;\ LEFT
    db $D0,$D0,$E0,$E0,$F0,$F0,$00,$00 ; WALKING 2 ;\ LEFT
    db $D0,$D0,$E0,$E0,$F0,$F0,$00,$00 ; WALKING 3 ;\ LEFT
    db $D0,$D0,$E0,$E0,$F0,$F0,$00,$00 ; WALKING 4 ;\ LEFT
    db $D0,$D0,$E0,$E0,$F0,$F0,$00,$00 ; WALKING 1 ;\ LEFT
    db $D0,$D0,$E0,$E0,$F0,$F0,$00,$00 ; WALKING 2 ;\ LEFT
    db $D0,$D0,$E0,$E0,$F0,$F0,$00,$00 ; WALKING 3 ;\ LEFT
    db $D0,$D0,$E0,$E0,$F0,$F0,$00,$00 ; WALKING 4 ;\ LEFT
    db $D0,$D0,$E0,$E0,$F0,$F0,$00,$00 ; WALKING 1 ;\ LEFT
    db $D0,$D0,$E0,$E0,$F0,$F0,$00,$00 ; WALKING 2 ;\ LEFT
    db $D0,$D0,$E0,$E0,$F0,$F0,$00,$00 ; WALKING 3 ;\ LEFT
    db $D0,$D0,$E0,$E0,$F0,$F0,$00,$00 ; WALKING 4 ;\ LEFT
 
XDISP:
    db $00,$10,$00,$10,$00,$10,$00,$10 ; WALKING 1 ;\ RIGHT
    db $00,$10,$00,$10,$00,$10,$00,$10 ; WALKING 2 ;\ RIGHT
    db $00,$10,$00,$10,$00,$10,$00,$10 ; WALKING 3 ;\ RIGHT
    db $00,$10,$00,$10,$00,$10,$00,$10 ; WALKING 4 ;\ RIGHT
    db $00,$10,$00,$10,$00,$10,$00,$10 ; WALKING 1 ;\ RIGHT
    db $00,$10,$00,$10,$00,$10,$00,$10 ; WALKING 2 ;\ RIGHT
    db $00,$10,$00,$10,$00,$10,$00,$10 ; WALKING 3 ;\ RIGHT
    db $00,$10,$00,$10,$00,$10,$00,$10 ; WALKING 4 ;\ RIGHT
    db $00,$10,$00,$10,$00,$10,$00,$10 ; WALKING 1 ;\ RIGHT
    db $00,$10,$00,$10,$00,$10,$00,$10 ; WALKING 2 ;\ RIGHT
    db $00,$10,$00,$10,$00,$10,$00,$10 ; WALKING 3 ;\ RIGHT
    db $00,$10,$00,$10,$00,$10,$00,$10 ; WALKING 4 ;\ RIGHT
    db $00,$10,$00,$10,$00,$10,$00,$10 ; WALKING 1 ;\ RIGHT
    db $00,$10,$00,$10,$00,$10,$00,$10 ; WALKING 2 ;\ RIGHT
    db $00,$10,$00,$10,$00,$10,$00,$10 ; WALKING 3 ;\ RIGHT
    db $00,$10,$00,$10,$00,$10,$00,$10 ; WALKING 4 ;\ RIGHT

    db $10,$00,$10,$00,$10,$00,$10,$00 ; WALKING 1 ;\ LEFT
    db $10,$00,$10,$00,$10,$00,$10,$00 ; WALKING 2 ;/ LEFT
    db $10,$00,$10,$00,$10,$00,$10,$00 ; WALKING 3 ;\ LEFT
    db $10,$00,$10,$00,$10,$00,$10,$00 ; WALKING 4 ;/ LEFT
    db $10,$00,$10,$00,$10,$00,$10,$00 ; WALKING 1 ;\ LEFT
    db $10,$00,$10,$00,$10,$00,$10,$00 ; WALKING 2 ;/ LEFT
    db $10,$00,$10,$00,$10,$00,$10,$00 ; WALKING 3 ;\ LEFT
    db $10,$00,$10,$00,$10,$00,$10,$00 ; WALKING 4 ;/ LEFT
    db $10,$00,$10,$00,$10,$00,$10,$00 ; WALKING 1 ;\ LEFT
    db $10,$00,$10,$00,$10,$00,$10,$00 ; WALKING 2 ;/ LEFT
    db $10,$00,$10,$00,$10,$00,$10,$00 ; WALKING 3 ;\ LEFT
    db $10,$00,$10,$00,$10,$00,$10,$00 ; WALKING 4 ;/ LEFT
    db $10,$00,$10,$00,$10,$00,$10,$00 ; WALKING 1 ;\ LEFT
    db $10,$00,$10,$00,$10,$00,$10,$00 ; WALKING 2 ;/ LEFT
    db $10,$00,$10,$00,$10,$00,$10,$00 ; WALKING 3 ;\ LEFT
    db $10,$00,$10,$00,$10,$00,$10,$00 ; WALKING 4 ;/ LEFT


SUB_GFX:

        JSR GET_DRAW_INFO
        LDA $14                     ;\  frame counter ..
        LSR A                       ; |
        LSR A                       ; | add in frame animation rate; More LSRs for slower animation.
        LSR A
        AND #$03                    ; | 01 means we animate between 2 frames (00 and 01).
        ASL A                       ; | 
        ASL A                       ; | ASL x2 (0-4) makes it switch between the first byte and fifth byte
        ASL A
        STA $03                     ;/ i.e. first animation and second animation. The result is stored into $03.

SPIKES_UP:

        LDA $1528, x                ; check if the timer is greater than $60
        CMP #$80 
        BCC PREPARE_FIRE
        LDA $03
        CLC
        ADC #$50                    ; use stun frames
        STA #03 
        BRA DONE_WALKING

PREPARE_FIRE:
    
        LDA SPRITE_STATE, x         ; if yelling at mario
        CMP #$01                    
        BNE WHEN_DROPPING           ;\
        LDA $03                     ;|
        CLC                         ;|
        ADC #$20                    ;| use stun frames
        STA $03                     ;/
        BRA DONE_WALKING

WHEN_DROPPING:
        
        LDA SPRITE_STATE, x
        CMP #$05
        BNE DONE_WALKING
        LDA $03
        CLC
        ADC #$60
        STA $03

DONE_WALKING:

        LDA $157C, x
        STA $02                     ; store direction to $02 for use with property routine later
        BNE NoAdd
        LDA $03                     ;\
        CLC                         ;| if sprite is facing left
        ADC #$80                    ;| add 8 more bytes to the table
        STA $03                     ;/ so we can invert XDISP and not mess up the sprite's appearance

NoAdd:

        PHX                         ;\ push sprite index
        LDX #$07                    ;/ and load X with number of tiles to loop through

Loop:
        
        PHX                         ; Push number of tiles to loop through.
        TXA                         ;\
        ORA $03                     ;/ Transfer it to X and add in the "left displacement" if necessary.
        TAX                         ;\ Get it back into X for an index.

        LDA $00                     ;\
        CLC                         ; | Apply X displacement of the sprite.
        ADC XDISP,x                 ; |
        STA $0300,y                 ;/ 

        LDA $01                     ;\
        CLC                         ; | Y displacement is added for the Y position, so one tile is higher than the other.
        ADC YDISP,x                 ; | Otherwise, both tiles would have been drawn to the same position!
        STA $0301,y                 ; | If X is 00, i.e. first tile, then load the first value from the table and apply that
                                    ;/ as the displacement. For the second tile, F0 is added to make it higher than the first.

        LDA TILEMAP,x
        STA $0302,y

        PHX                         ; Push number of times to go through loop + "left" displacement if necessary.
        LDX $02                     ;\
        LDA PROPERTIES,x            ; | Set properties based on direction.
        STA $0303,y                 ;/
        PLX                         ; Pull number of times to go through loop.

        INY                         ;\
        INY                         ; | The OAM is 8x8, but our sprite is 16x16 ..
        INY                         ; | So increment it 4 times.
        INY                         ;/
            
        PLX                         ; Pull current tile back.
        DEX                         ; After drawing this tile, decrease number of tiles to go through loop. If the second tile
                                    ; is drawn, then loop again to draw the first tile.

        BPL Loop                    ; Loop until X becomes negative (FF).
        
        PLX                         ; Pull back the sprite index! We pushed it at the beginning of the routine.

        LDY #$02                    ; Y ends with the tile size .. 02 means it's 16x16
        LDA #$07                    ; A -> number of tiles drawn - 1.
                                    ; I drew 2 tiles, so 2-1 = 1. A = 01.

        JSL $01B7B3                 ; Call the routine that draws the sprite.
        RTS                         ; Never forget this!

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                  Universal Graphics Routine             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PROPERTIESU: db $FF,$BF

;The tables must now have 16 bytes.
;THE LAST 8 ARE ONLY CREATED BECAUSE OF XDISP.

;0-4 BYTE   - FRAME 1 RIGHT
;4-8 BYTE   - FRAME 2 RIGHT
;8-12 BYTE  - FRAME 1 LEFT
;12-16 BYTE - FRAME 2 LEFT

TILEMAPU:
    db $00,$02,$20,$22,$40,$42,$60,$62 ; WALKING 1 ;\ RIGHT
    db $00,$02,$24,$26,$44,$46,$64,$66 ; WALKING 2 ;\ RIGHT
    db $00,$02,$28,$2A,$48,$4A,$68,$6A ; WALKING 3 ;\ RIGHT
    db $00,$02,$24,$26,$44,$46,$64,$66 ; WALKING 4 ;\ RIGHT
    db $00,$02,$A0,$A2,$C0,$C2,$E0,$E2 ; WALKING 1 ;\ RIGHT
    db $00,$02,$A0,$A2,$C0,$C2,$E0,$E2 ; WALKING 2 ;\ RIGHT
    db $00,$02,$A8,$AA,$C8,$CA,$E8,$EA ; WALKING 3 ;\ RIGHT
    db $00,$02,$A8,$AA,$C8,$CA,$E8,$EA ; WALKING 4 ;\ RIGHT
    db $00,$02,$A4,$A6,$C4,$C6,$E4,$E6 ; WALKING 1 ;\ RIGHT
    db $00,$02,$A4,$A6,$C4,$C6,$E4,$E6 ; WALKING 2 ;\ RIGHT
    db $00,$02,$A4,$A6,$C4,$C6,$E4,$E6 ; WALKING 3 ;\ RIGHT
    db $00,$02,$A4,$A6,$C4,$C6,$E4,$E6 ; WALKING 4 ;\ RIGHT
    db $00,$02,$2C,$2E,$4C,$4E,$6C,$6E
    db $00,$02,$2C,$2E,$4C,$4E,$6C,$6E
    db $00,$02,$2C,$2E,$4C,$4E,$6C,$6E
    db $00,$02,$2C,$2E,$4C,$4E,$6C,$6E

    db $00,$02,$20,$22,$40,$42,$60,$62 ; WALKING 1 ;\ LEFT
    db $00,$02,$24,$26,$44,$46,$64,$66 ; WALKING 2 ;\ LEFT
    db $00,$02,$28,$2A,$48,$4A,$68,$6A ; WALKING 3 ;\ LEFT
    db $00,$02,$24,$26,$44,$46,$64,$66 ; WALKING 4 ;\ LEFT
    db $00,$02,$A0,$A2,$C0,$C2,$E0,$E2 ; WALKING 1 ;\ LEFT
    db $00,$02,$A0,$A2,$C0,$C2,$E0,$E2 ; WALKING 2 ;\ LEFT
    db $00,$02,$A8,$AA,$C8,$CA,$E8,$EA ; WALKING 3 ;\ LEFT
    db $00,$02,$A8,$AA,$C8,$CA,$E8,$EA ; WALKING 4 ;\ LEFT
    db $00,$02,$A4,$A6,$C4,$C6,$E4,$E6 ; WALKING 1 ;\ LEFT
    db $00,$02,$A4,$A6,$C4,$C6,$E4,$E6 ; WALKING 2 ;\ LEFT
    db $00,$02,$A4,$A6,$C4,$C6,$E4,$E6 ; WALKING 3 ;\ LEFT
    db $00,$02,$A4,$A6,$C4,$C6,$E4,$E6 ; WALKING 4 ;\ LEFT
    db $00,$02,$2C,$2E,$4C,$4E,$6C,$6E
    db $00,$02,$2C,$2E,$4C,$4E,$6C,$6E
    db $00,$02,$2C,$2E,$4C,$4E,$6C,$6E
    db $00,$02,$2C,$2E,$4C,$4E,$6C,$6E

YDISPU:
    db $0D,$0D,$FD,$FD,$ED,$ED,$DD,$DD ; WALKING 1 ;\ RIGHT
    db $0D,$0D,$FD,$FD,$ED,$ED,$DD,$DD ; WALKING 2 ;\ RIGHT
    db $0D,$0D,$FD,$FD,$ED,$ED,$DD,$DD ; WALKING 3 ;\ RIGHT
    db $0D,$0D,$FD,$FD,$ED,$ED,$DD,$DD ; WALKING 4 ;\ RIGHT
    db $0D,$0D,$FD,$FD,$ED,$ED,$DD,$DD ; WALKING 1 ;\ RIGHT
    db $0D,$0D,$FD,$FD,$ED,$ED,$DD,$DD ; WALKING 2 ;\ RIGHT
    db $0D,$0D,$FD,$FD,$ED,$ED,$DD,$DD ; WALKING 3 ;\ RIGHT
    db $0D,$0D,$FD,$FD,$ED,$ED,$DD,$DD ; WALKING 4 ;\ RIGHT
    db $0D,$0D,$FD,$FD,$ED,$ED,$DD,$DD ; WALKING 1 ;\ RIGHT
    db $0D,$0D,$FD,$FD,$ED,$ED,$DD,$DD ; WALKING 2 ;\ RIGHT
    db $0D,$0D,$FD,$FD,$ED,$ED,$DD,$DD ; WALKING 3 ;\ RIGHT
    db $0D,$0D,$FD,$FD,$ED,$ED,$DD,$DD ; WALKING 4 ;\ RIGHT
    db $0D,$0D,$FD,$FD,$ED,$ED,$DD,$DD ; WALKING 1 ;\ RIGHT
    db $0D,$0D,$FD,$FD,$ED,$ED,$DD,$DD ; WALKING 2 ;\ RIGHT
    db $0D,$0D,$FD,$FD,$ED,$ED,$DD,$DD ; WALKING 3 ;\ RIGHT
    db $0D,$0D,$FD,$FD,$ED,$ED,$DD,$DD ; WALKING 4 ;\ RIGHT

    db $0D,$0D,$FD,$FD,$ED,$ED,$DD,$DD ; WALKING 1 ;\ LEFT
    db $0D,$0D,$FD,$FD,$ED,$ED,$DD,$DD ; WALKING 2 ;\ LEFT
    db $0D,$0D,$FD,$FD,$ED,$ED,$DD,$DD ; WALKING 3 ;\ LEFT
    db $0D,$0D,$FD,$FD,$ED,$ED,$DD,$DD ; WALKING 4 ;\ LEFT
    db $0D,$0D,$FD,$FD,$ED,$ED,$DD,$DD ; WALKING 1 ;\ LEFT
    db $0D,$0D,$FD,$FD,$ED,$ED,$DD,$DD ; WALKING 2 ;\ LEFT
    db $0D,$0D,$FD,$FD,$ED,$ED,$DD,$DD ; WALKING 3 ;\ LEFT
    db $0D,$0D,$FD,$FD,$ED,$ED,$DD,$DD ; WALKING 4 ;\ LEFT
    db $0D,$0D,$FD,$FD,$ED,$ED,$DD,$DD ; WALKING 1 ;\ LEFT
    db $0D,$0D,$FD,$FD,$ED,$ED,$DD,$DD ; WALKING 2 ;\ LEFT
    db $0D,$0D,$FD,$FD,$ED,$ED,$DD,$DD ; WALKING 3 ;\ LEFT
    db $0D,$0D,$FD,$FD,$ED,$ED,$DD,$DD ; WALKING 4 ;\ LEFT
    db $0D,$0D,$FD,$FD,$ED,$ED,$DD,$DD ; WALKING 1 ;\ LEFT
    db $0D,$0D,$FD,$FD,$ED,$ED,$DD,$DD ; WALKING 2 ;\ LEFT
    db $0D,$0D,$FD,$FD,$ED,$ED,$DD,$DD ; WALKING 3 ;\ LEFT
    db $0D,$0D,$FD,$FD,$ED,$ED,$DD,$DD ; WALKING 4 ;\ LEFT
 
XDISPU:
    db $00,$10,$00,$10,$00,$10,$00,$10 ; WALKING 1 ;\ RIGHT
    db $00,$10,$00,$10,$00,$10,$00,$10 ; WALKING 2 ;\ RIGHT
    db $00,$10,$00,$10,$00,$10,$00,$10 ; WALKING 3 ;\ RIGHT
    db $00,$10,$00,$10,$00,$10,$00,$10 ; WALKING 4 ;\ RIGHT
    db $00,$10,$00,$10,$00,$10,$00,$10 ; WALKING 1 ;\ RIGHT
    db $00,$10,$00,$10,$00,$10,$00,$10 ; WALKING 2 ;\ RIGHT
    db $00,$10,$00,$10,$00,$10,$00,$10 ; WALKING 3 ;\ RIGHT
    db $00,$10,$00,$10,$00,$10,$00,$10 ; WALKING 4 ;\ RIGHT
    db $00,$10,$00,$10,$00,$10,$00,$10 ; WALKING 1 ;\ RIGHT
    db $00,$10,$00,$10,$00,$10,$00,$10 ; WALKING 2 ;\ RIGHT
    db $00,$10,$00,$10,$00,$10,$00,$10 ; WALKING 3 ;\ RIGHT
    db $00,$10,$00,$10,$00,$10,$00,$10 ; WALKING 4 ;\ RIGHT
    db $00,$10,$00,$10,$00,$10,$00,$10 ; WALKING 1 ;\ RIGHT
    db $00,$10,$00,$10,$00,$10,$00,$10 ; WALKING 2 ;\ RIGHT
    db $00,$10,$00,$10,$00,$10,$00,$10 ; WALKING 3 ;\ RIGHT
    db $00,$10,$00,$10,$00,$10,$00,$10 ; WALKING 4 ;\ RIGHT

    db $10,$00,$10,$00,$10,$00,$10,$00 ; WALKING 1 ;\ LEFT
    db $10,$00,$10,$00,$10,$00,$10,$00 ; WALKING 2 ;/ LEFT
    db $10,$00,$10,$00,$10,$00,$10,$00 ; WALKING 3 ;\ LEFT
    db $10,$00,$10,$00,$10,$00,$10,$00 ; WALKING 4 ;/ LEFT
    db $10,$00,$10,$00,$10,$00,$10,$00 ; WALKING 1 ;\ LEFT
    db $10,$00,$10,$00,$10,$00,$10,$00 ; WALKING 2 ;/ LEFT
    db $10,$00,$10,$00,$10,$00,$10,$00 ; WALKING 3 ;\ LEFT
    db $10,$00,$10,$00,$10,$00,$10,$00 ; WALKING 4 ;/ LEFT
    db $10,$00,$10,$00,$10,$00,$10,$00 ; WALKING 1 ;\ LEFT
    db $10,$00,$10,$00,$10,$00,$10,$00 ; WALKING 2 ;/ LEFT
    db $10,$00,$10,$00,$10,$00,$10,$00 ; WALKING 3 ;\ LEFT
    db $10,$00,$10,$00,$10,$00,$10,$00 ; WALKING 4 ;/ LEFT
    db $10,$00,$10,$00,$10,$00,$10,$00 ; WALKING 1 ;\ LEFT
    db $10,$00,$10,$00,$10,$00,$10,$00 ; WALKING 2 ;/ LEFT
    db $10,$00,$10,$00,$10,$00,$10,$00 ; WALKING 3 ;\ LEFT
    db $10,$00,$10,$00,$10,$00,$10,$00 ; WALKING 4 ;/ LEFT

UPSIDE_GFX:
        
        JSR GET_DRAW_INFO

        LDA $14                 ;\ Frame counter ..
        LSR A                   ; |
        LSR A                   ; | Add in frame animation rate; More LSRs for slower animation.
        LSR A
        AND #$03                ; | 01 means we animate between 2 frames (00 and 01).
        ASL A                   ; | 
        ASL A                   ; | ASL x2 (0-4) makes it switch between the first byte and fifth byte
        ASL A
        STA $03                 ;/ i.e. first animation and second animation. The result is stored into $03.

SPIKES_UPU:

        LDA $1528,x             ; Check if the timer is greater than $60
        CMP #$80
        BCC PREPARE_FIREU
        LDA $03
        CLC
        ADC #$40                ; | ...use stun frames.
        STA $03                 ; /
        BRA DONE_WALKINGU

PREPARE_FIREU:

        LDA SPRITE_STATE,x      ; if yelling at Mario
        CMP #$04
        BNE WHEN_RISING         ; |
        LDA $03                 ; |
        CLC                     ; |
        ADC #$20                ; | ...use stun frames.
        STA $03                 ; /
        BRA DONE_WALKINGU

WHEN_RISING

        LDA SPRITE_STATE,x
        CMP #$02
        BNE DONE_WALKINGU
        LDA $03
        CLC
        ADC #$60
        STA $03
    
DONE_WALKINGU

        LDA $157C,x
        STA $02                 ; Store direction to $02 for use with property routine later.
        BNE NoAddU
        LDA $03                 ;\
        CLC                     ; | If sprite faces left ..
        ADC #$80                ; | Adding 8 more bytes to the table.
        STA $03                 ;/ So we can invert XDISP to not mess up the sprite's appearance.

NoAddU:
        PHX                     ;\ Push sprite index ..
        LDX #$07                ;/ And load X with number of tiles to loop through.

LoopU:
        PHX                     ; Push number of tiles to loop through.
        TXA                     ;\
        ORA $03                 ;/ Transfer it to X and add in the "left displacement" if necessary.
        TAX                     ;\ Get it back into X for an index.

        LDA $00                 ;\
        CLC                     ; | Apply X displacement of the sprite.
        ADC XDISPU,x            ; |
        STA $0300,y             ;/ 

        LDA $01                 ;\
        CLC                     ; | Y displacement is added for the Y position, so one tile is higher than the other.
        ADC YDISPU,x            ; | Otherwise, both tiles would have been drawn to the same position!
        STA $0301,y             ; | If X is 00, i.e. first tile, then load the first value from the table and apply that
                                ;/ as the displacement. For the second tile, F0 is added to make it higher than the first.

        LDA TILEMAPU,x
        STA $0302,y

        PHX                     ; Push number of times to go through loop + "left" displacement if necessary.
        LDX $02                 ;\
        LDA PROPERTIESU,x       ; | Set properties based on direction.
        STA $0303,y             ;/
        PLX                     ; Pull number of times to go through loop.

        INY                     ;\
        INY                     ; | The OAM is 8x8, but our sprite is 16x16 ..
        INY                     ; | So increment it 4 times.
        INY                     ;/
            
        PLX                     ; Pull current tile back.
        DEX                     ; After drawing this tile, decrease number of tiles to go through loop. If the second tile
                                ; is drawn, then loop again to draw the first tile.

        BPL LoopU               ; Loop until X becomes negative (FF).
        
        PLX                     ; Pull back the sprite index! We pushed it at the beginning of the routine.

        LDY #$02                ; Y ends with the tile size .. 02 means it's 16x16
        LDA #$07                ; A -> number of tiles drawn - 1.
                                ; I drew 2 tiles, so 2-1 = 1. A = 01.

        JSL $01B7B3             ; Call the routine that draws the sprite.
        RTS                     ; Never forget this!

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                  Shell Graphics Routine                 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;The tables must now have 16 bytes.
;THE LAST 8 ARE ONLY CREATED BECAUSE OF XDISP.

;0-4 BYTE   - FRAME 1 RIGHT
;4-8 BYTE   - FRAME 2 RIGHT
;8-12 BYTE  - FRAME 1 LEFT
;12-16 BYTE - FRAME 2 LEFT

SHELL_TILEMAP:

        dcb $84,$86,$88,$8A ; SPINNING 1    ;\ RIGHT
        dcb $CC,$CE,$EC,$EE ; SPINNING 2    ; | RIGHT
        dcb $84,$86,$88,$8A ; SPINNING 3    ; | RIGHT
        dcb $CC,$CE,$EC,$EE ; SPINNING 4    ;/ RIGHT
        dcb $84,$86,$88,$8A ; FIRING 1      ;\ RIGHT
        dcb $CC,$CE,$EC,$EE ; FIRING 2      ; | RIGHT
        dcb $84,$86,$88,$8A ; FIRING 3      ; | RIGHT
        dcb $CC,$CE,$EC,$EE ; FIRING 4      ;/ RIGHT

        dcb $84,$86,$88,$8A ; SPINNIN       ;\ RIGHT
        dcb $CC,$CE,$EC,$EE ; SPINNING 2    ; | RIGHT
        dcb $84,$86,$88,$8A ; SPINNING 3    ; | RIGHT
        dcb $CC,$CE,$EC,$EE ; SPINNING 4    ;/ RIGHT
        dcb $84,$86,$88,$8A ; FIRING 1      ;\ RIGHT
        dcb $CC,$CE,$EC,$EE ; FIRING 2      ; | RIGHT
        dcb $84,$86,$88,$8A ; FIRING 3      ; | RIGHT
        dcb $CC,$CE,$EC,$EE ; FIRING 4      ;/ RIGHT

VERT_DISP:  
        dcb $F0,$F0,$00,$00 ; SPINNING 1    ;\ RIGHT
        dcb $F0,$F0,$00,$00 ; SPINNING 2    ; | RIGHT
        dcb $F0,$F0,$00,$00 ; SPINNING 3    ; | RIGHT
        dcb $F0,$F0,$00,$00 ; SPINNING 4    ;/ RIGHT
        dcb $ED,$ED,$DD,$DD ; FIRING 1      ;\ RIGHT
        dcb $ED,$ED,$DD,$DD ; FIRING 2      ; | RIGHT
        dcb $ED,$ED,$DD,$DD ; FIRING 3      ; | RIGHT
        dcb $ED,$ED,$DD,$DD ; FIRING 4      ;/ RIGHT

        dcb $F0,$F0,$00,$00 ; SPINNIN       ;\ LEFT
        dcb $F0,$F0,$00,$00 ; SPINNING 2    ; | LEFT
        dcb $F0,$F0,$00,$00 ; SPINNING 3    ; | LEFT
        dcb $F0,$F0,$00,$00 ; SPINNING 4    ;/ LEFT
        dcb $ED,$ED,$DD,$DD ; FIRING 1      ;\ LEFT
        dcb $ED,$ED,$DD,$DD ; FIRING 2      ; | LEFT
        dcb $ED,$ED,$DD,$DD ; FIRING 3      ; | LEFT
        dcb $ED,$ED,$DD,$DD ; FIRING 4      ;/ LEFT

HORZ_DISP:  

        dcb $00,$10,$00,$10 ; SPINNING 1    ;\ RIGHT
        dcb $00,$10,$00,$10 ; SPINNING 2    ; | RIGHT
        dcb $10,$00,$10,$00 ; SPINNING 3    ; | RIGHT
        dcb $10,$00,$10,$00 ; SPINNING 4    ;/ RIGHT
        dcb $00,$10,$00,$10 ; FIRING 1      ;\ RIGHT
        dcb $00,$10,$00,$10 ; FIRING 2      ; | RIGHT
        dcb $10,$00,$10,$00 ; FIRING 3      ; | RIGHT
        dcb $10,$00,$10,$00 ; FIRING 4      ;/ RIGHT

        dcb $10,$00,$10,$00 ; SPINNING 1    ;\ LEFT
        dcb $10,$00,$10,$00 ; SPINNING 2    ; | LEFT
        dcb $00,$10,$00,$10 ; SPINNING 3    ; | LEFT
        dcb $00,$10,$00,$10 ; SPINNING 4    ;/ LEFT
        dcb $10,$00,$10,$00 ; FIRING 1      ;\ LEFT
        dcb $10,$00,$10,$00 ; FIRING 2      ; | LEFT
        dcb $00,$10,$00,$10 ; FIRING 3      ; | LEFT
        dcb $00,$10,$00,$10 ; FIRING 4      ;/ LEFT

SHELL_PROP

        dcb $3F,$3F,$3F,$3F ; SPINNING 1    ;\ RIGHT
        dcb $3F,$3F,$3F,$3F ; SPINNING 2    ; | RIGHT
        dcb $7F,$7F,$7F,$7F ; SPINNING 3    ; | RIGHT
        dcb $7F,$7F,$7F,$7F ; SPINNING 4    ;/ RIGHT
        dcb $BF,$BF,$BF,$BF ; FIRING 1      ;\ RIGHT
        dcb $BF,$BF,$BF,$BF ; FIRING 2      ; | RIGHT
        dcb $FF,$FF,$FF,$FF ; FIRING 3      ; | RIGHT
        dcb $FF,$FF,$FF,$FF ; FIRING 4      ;/ RIGHT

        dcb $7F,$7F,$7F,$7F ; SPINNING 1    ;\ LEFT
        dcb $7F,$7F,$7F,$7F ; SPINNING 2    ; | LEFT
        dcb $3F,$3F,$3F,$3F ; SPINNING 3    ; | LEFT 
        dcb $3F,$3F,$3F,$3F ; SPINNING 4    ;/ LEFT
        dcb $FF,$FF,$FF,$FF ; FIRING 1      ;\ LEFT
        dcb $FF,$FF,$FF,$FF ; FIRING 2      ; | LEFT
        dcb $BF,$BF,$BF,$BF ; FIRING 3      ; | LEFT 
        dcb $BF,$BF,$BF,$BF ; FIRING 4      ;/ LEFT

SHELL_GFX:

        JSR GET_DRAW_INFO

        LDA $14                             ;\ Frame counter ..
        LSR                                 ; |
        LSR                                 ; | Add in frame animation rate; More LSRs for slower animation.
        LSR                                 ; |
        AND #$03                            ; | 01 means we animate between 2 frames (00 and 01).
        ASL A                               ; | 
        ASL A                               ; | ASL x2 (0-4) makes it switch between the first byte and fifth byte,
        STA $03                             ;/ i.e. first animation and second animation. The result is stored into $03.

IN_SHELL:

        LDA SPRITE_STATE,x                  ; if hit
        CMP #$07
        BNE DONE_WALKING3                   ; |
        LDA $03                             ; |
        CLC                                 ; |
        ADC #$10                            ; | ...use stun frames.
        STA $03                             ; /
    ;   BRA DONE_WALKING3

DONE_WALKING3:

        LDA $157C,x
        STA $02         ; Store direction to $02 for use with property routine later.
        BNE LOOP_START
        LDA $03         ;\
        CLC         ; | If sprite faces left ..
        ADC #$20        ; | Adding 16 more bytes to the table.
        STA $03         ;/ So we can invert XDISP to not mess up the sprite's appearance.

LOOP_START:

        PHX                     ; push sprite index
        LDX #$03                ; loop counter = (number of tiles per frame) - 1

LOOP_START_2:

        PHX                     ; push current tile number
        
        TXA                     ; \ X = index of frame start + current tile
        CLC                     ;  |
        ADC $03                 ;  |
        TAX                     ; /
        
        PHY                     ; \
        TYA                     ; |
        LSR A                   ; |
        LSR A                   ; |
        TAY                     ; | Set tile to be 16x16 ($02)
        LDA #$02                ; |
        STA $0460,y             ; |
        PLY                     ; /
        
        LDA $00                 ; \ tile x position = sprite x location ($00)
        CLC                     ;  |
        ADC HORZ_DISP,x         ;  |
        STA $0300,y             ; /
        
        LDA $01                 ; \ tile y position = sprite y location ($01) + tile displacement
        CLC                     ;  |
        ADC VERT_DISP,x         ;  |
        STA $0301,y             ; /
        
        LDA SHELL_TILEMAP,x           ; \ store tile
        STA $0302,y             ; / 
        
        PHX
        LDX $15E9
        LDA $15F6,x             ; get palette info
        PLX
        ORA SHELL_PROP,x        ; flip tile if necessary
        ORA $64                 ; add in tile priority of level
        STA $0303,y             ; store tile properties
        
        PLX                     ; \ pull, X = current tile of the frame we're drawing
        INY                     ;  | increase index to sprite tile map ($300)...
        INY                     ;  |    ...we wrote 1 16x16 tile...
        INY                     ;  |    ...sprite OAM is 8x8...
        INY                     ;  |    ...so increment 4 times
        DEX                     ;  | go to next tile of frame and loop
        BPL LOOP_START_2        ; / 

        PLX                     ; pull, X = sprite index
        LDY #$FF                ; \ We've already set 460, so use FF!
        LDA #$03                ; | A = number of tiles drawn - 1
        JSL $01B7B3             ; / don't draw if offscreen
        RTS                     ; return