FUNCTION "ifm_SA5000" : VOID
TITLE =2 word 2 bit signals
//Current flow.
//Current temperature:
//The real temperature shall be calculated as follows:
//T_real = PDV1 * Gradient + Offset.
AUTHOR : Leonardo
FAMILY : ASSETMNG
NAME : SA5000
VERSION : 1.0


VAR_INPUT
  IW_PS1 : WORD ;	//Process signal input
  IW_PS2 : WORD ;	//Process signal input
  IR_Gradient : REAL ;	
END_VAR
VAR_OUTPUT
  OR_PS1 : REAL ;	//Output process signal
  OR_PS2 : REAL ;	//Output process signal
  O_OU1 : BOOL ;	//Signal 1
  O_OU2 : BOOL ;	//Signal 2
END_VAR
VAR_TEMP
  TW_Flag : WORD ;	
END_VAR
BEGIN
NETWORK
TITLE =Process signal 2
//Current flow.
// Process signal 1
      L     #IW_PS1; 
      ITD   ; 
      DTR   ; 
      T     #OR_PS1; 
NETWORK
TITLE =Process signal 2
//Current temperature:
//The real temperature shall be calculated as follows:
//T_real = PDV1 * Gradient + Offset.
//
//PLC-In Word:
//|15|14|13|12|11|10|09|08| |07|06|05|04|03|02|01|00|
//|-------------------TEMERATURE--------------|O2|O1|
//To read temperature shift 2 bits to right.
// Process signal 2

      L     #IW_PS2; 
      T     #TW_Flag; 

      L     #TW_Flag; 
      L     1; 
      AW    ; 
      L     1; 
      ==I   ; 
      =     #O_OU1; // Digital 1

      L     #TW_Flag; 
      L     2; 
      AW    ; 
      L     2; 
      ==I   ; 
      =     #O_OU2; // Digital 2



      L     #IW_PS2; 
      SSI   2; 
      T     #TW_Flag; 

      L     #IR_Gradient; // If no Gradient value set
      L     0.000000e+000; // .
      ==R   ; // .
      JCN   xxxx; // .
      L     1.000000e+000; // load 1.0 as gradient.
      T     #IR_Gradient; 
xxxx: NOP   0; 


      L     #TW_Flag; // Convert Word to
      ITD   ; // Decimal and then convert to 
      DTR   ; // Raal
      L     #IR_Gradient; 
      *R    ; // Gradient * Temp(received)
      T     #OR_PS2; 


      SET   ; 
      SAVE  ; 

END_FUNCTION
