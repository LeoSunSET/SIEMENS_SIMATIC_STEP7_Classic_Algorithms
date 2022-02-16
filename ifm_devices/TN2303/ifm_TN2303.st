FUNCTION "ifm_TN2303" : VOID
TITLE =2 word 2 bit signals
//Current temperature:
//The real temperature shall be calculated as follows:
//T_real = PDV1 * Gradient + Offset.
//
//PLC-In Word:
//|15|14|13|12|11|10|09|08| |07|06|05|04|03|02|01|00|
//|-------------------TEMERATURE--------------|O2|O1|
//To read temperature shift 2 bits to right.
AUTHOR : Leonardo
FAMILY : ASSETMNG
NAME : TN2303
VERSION : 1.0


VAR_INPUT
  IW_PS : WORD ;	//Process signal input
  IR_Gradient : REAL ;	//Gradient
END_VAR
VAR_OUTPUT
  OR_PS : REAL ;	//Output process signal
  O_OU1 : BOOL ;	//Signal 1
  O_OU2 : BOOL ;	//Signal 2
END_VAR
VAR_TEMP
  TW_Flag : WORD ;	
END_VAR
BEGIN
NETWORK
TITLE =


      L     #IW_PS; 
      T     #TW_Flag; 

      L     #TW_Flag; 
      L     1; 
      AW    ; 
      L     1; 
      ==I   ; 
      =     #O_OU1; 

      L     #TW_Flag; 
      L     2; 
      AW    ; 
      L     2; 
      ==I   ; 
      =     #O_OU2; 



      L     #IW_PS; 
      SSI   2; 
      T     #TW_Flag; 

      L     #IR_Gradient; 
      L     0.000000e+000; 
      ==R   ; 
      JCN   xxxx; 
      L     1.000000e+000; 
      T     #IR_Gradient; 
xxxx: NOP   0; 


      L     #TW_Flag; 
      ITD   ; 
      DTR   ; 
      L     #IR_Gradient; 
      *R    ; 
      T     #OR_PS; 


      SET   ; 
      SAVE  ; 

END_FUNCTION
