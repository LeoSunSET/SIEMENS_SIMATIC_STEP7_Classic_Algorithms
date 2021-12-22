From Siemens Forum: https://support.industry.siemens.com/tf/ww/en/posts/hysteresis-deadband-block/184198

Alarm if the process value deviates from the defined limits.

Inputs:

I_TIMER : Time // timer used by the block

I_TIME : S5Time // Timer Setpoint

I_VALUE : Real; // Value. Change data type as required

I_MIN : Real; // Low Limit. Change data type as required

I_MAX : Real; // High Limit. Change data type as required

I_RESET : Bool; // Alarm Reset

IQ_ALARM : Bool; // Latched Alarm.

TEMP:

BTmp : Bool; // Bool Temp Variable

Ret_Val : Bool; // indicator of over limit [before debounce]

// NW1 - detect out of range
                        BTmp   Ret_Val        I_TIMER
---------| GT R |-------(#)-----(#)------------(SD)
 I_VALUE-|      |  |
   I_MAX-|------|  |
                   |
---------| LT R |--|
 I_VALUE-|      |
   I_MIN-|------|

// NW2 - Alarm Reset
     I_RESET                               IQ_ALARM
-------||-------------------------------------(R)

// NW3 - Alarm Set

     I_TIMER                                IQ_ALARM
-------||--------------------------------------(S)

// NW4 - issue ENO wnen in limits
      BTmp
-------|/|-----------------------------------(SAVE)