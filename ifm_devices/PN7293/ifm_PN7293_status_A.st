FUNCTION "ifm_PN7293_sts_a" : VOID
TITLE =ifm PN7293 - Presure Sensor
//Analog Current pressure.
//Digital Out1 and Out2.
AUTHOR : Leonardo
FAMILY : ASSETMNG
NAME : PN7293A
VERSION : 1.0


VAR_INPUT
  IW_PS1 : WORD ;	//Process signal input
END_VAR
VAR_OUTPUT
  OR_PS1 : REAL ;	//Output Current Pressure
  O_OU1 : BOOL ;	//Current status of the digital signal [OUT1]
  O_OU2 : BOOL ;	//Current status of the digital signal [OUT2]
END_VAR
VAR_TEMP
  TW_Flag : WORD ;	
END_VAR
BEGIN
NETWORK
TITLE =Process signal 1
//Current pressure - default parameters:
//
//264 to 750 (OL)
//-10 to 263
//14 bit lenght
//Bitoffset = 2
//
//Gradient - 0.1
//Offset - 0
//Unit - psi
//
//PLC-In Word:
//|15|14|13|12|11|10|09|08| |07|06|05|04|03|02|01|00|
//|------------------PRESURE------------------|O2|O1|
//To read presure shift 2 bits to right.
// Process signal 1
      L     #IW_PS1; // Load process dada word
      T     #TW_Flag; // transfer to aux tag

      L     #TW_Flag; // load aux tag with data from process word
      L     1; 
      AW    ; 
      L     1; 
      ==I   ; 
      =     #O_OU1; // Digital signal 1

      L     #TW_Flag; // load aux tag with data from process word
      L     2; 
      AW    ; 
      L     2; 
      ==I   ; 
      =     #O_OU2; // Digital signal 2

      L     #TW_Flag; // load aux tag with data from process word
      SSI   2; // shift 2 bit to right
      ITD   ; // convert to DInt
      DTR   ; // convert to Real
      T     #OR_PS1; // transfer to process signal output 1

NETWORK
TITLE =END

      SET   ; 
      SAVE  ; 

END_FUNCTION
