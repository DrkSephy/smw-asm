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

    
