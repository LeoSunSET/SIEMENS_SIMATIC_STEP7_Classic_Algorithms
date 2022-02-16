FUNCTION "ifm_TP3233" : VOID
TITLE =IF 1 Wort ohne Bit Signale
//Current temperature.
//The real temperature shall be calculatedas follows:
//T_real = PDV1 * Gradient + Offset.
AUTHOR : Leonardo
FAMILY : ASSETMNG
NAME : TP3233
VERSION : 1.0


VAR_INPUT
  IW_PS : WORD ;	//Process signal input
  IR_Gradient : REAL ;	//Gradient
END_VAR
VAR_OUTPUT
  OR_PS : REAL ;	//Output process signal
END_VAR
BEGIN
NETWORK
TITLE =

// Process signal
      L     #IR_Gradient; 
      L     0.000000e+000; 
      ==R   ; 
      JCN   xxxx; 
      L     1.000000e+000; 
      T     #IR_Gradient; 
xxxx: NOP   0; 

      L     #IW_PS; 
      ITD   ; 
      DTR   ; 
      L     #IR_Gradient; 
      *R    ; 
      T     #OR_PS; 


      SET   ; 
      SAVE  ; 




END_FUNCTION
