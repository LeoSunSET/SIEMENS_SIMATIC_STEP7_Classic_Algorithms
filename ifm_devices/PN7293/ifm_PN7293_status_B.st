FUNCTION "ifm_PN7293_sts_b" : VOID
TITLE =2 word 2 bit signals
//Current pressure.
//Current device status.
//(a copy of the parameter [Device Status, Index 36] in the process data channel)
AUTHOR : Leonardo
FAMILY : ASSETMNG
NAME : PN7293B
VERSION : 1.1


VAR_INPUT
  IW_PS1 : WORD ;	//Process signal input
  IW_PS2 : WORD ;	//Process signal input
END_VAR
VAR_OUTPUT
  OR_PS1 : REAL ;	//Output Current Pressure
  O_OU1 : BOOL ;	//Current status of the digital signal [OUT1]
  O_OU2 : BOOL ;	//Current status of the digital signal [OUT2]
  O_OK : BOOL ;	//Output Device is OK
  O_Maintenance_Required : BOOL ;	//Output Maintenance required
  O_Out_of_specification : BOOL ;	//Output Out of specification
  O_Functional_Check : BOOL ;	//Output Functional check
  O_Failure : BOOL ;	//Output Failure
END_VAR
VAR_TEMP
  TW_Flag : WORD ;	
  TB_State : BYTE ;	
END_VAR
BEGIN
NETWORK
TITLE =Process signal 1
//Current pressure.
//
//-1000 to 26250
//(32760) OL
//(32764) NoData
//
//Gradient - 0.01452
//Offset - 0
//Unit - psi
// Process signal 1
      L     #IW_PS1; // Load process dada 1
      ITD   ; // convert to DInt
      DTR   ; // convert to Real
      T     #OR_PS1; // transfer to process signal output 1
NETWORK
TITLE =Process signal 2
//Current device status.
//(a copy of the parameter [Device Status, Index 36] in the process data channel)
//
//PLC-In Word:
//|15|14|13|12|11|10|09|08| |07|06|05|04|03|02|01|00|
//|--------RESERVED-------| |--STATUS---|-N/A-|O2|O1|
//To read status shift 4 bits to right.
// Process signal 2

// Reads device's digital output
      L     #IW_PS2; // load process word 2
      T     #TW_Flag; // transfer to aux tag

      L     #TW_Flag; // load aux tag with data from process word 2
      L     1; 
      AW    ; 
      L     1; 
      ==I   ; 
      =     #O_OU1; // Digital signal 1

      L     #TW_Flag; 
      L     2; 
      AW    ; 
      L     2; 
      ==I   ; 
      =     #O_OU2; // Digital signal 2


// Reads device status
      L     #IW_PS2; // load process word 2
      SSI   4; // shift 4 bit to right
      T     #TB_State; // transfer to aux byte tag

NETWORK
TITLE =Device Status
//State of the object 
//(0) Device is OK
//(1) Maintenance required
//(2) Out of specification
//(3) Functional check
//(4) Failure
// 0: OK 
      L     #TB_State; 
      L     0; 
      ==I   ; 
      =     #O_OK; 

// 1: Maintenance required 
      L     #TB_State; 
      L     1; 
      ==I   ; 
      =     #O_Maintenance_Required; 

// 2: Out of specification
      L     #TB_State; 
      L     2; 
      ==I   ; 
      =     #O_Out_of_specification; 

// 3: Functional check
      L     #TB_State; 
      L     3; 
      ==I   ; 
      =     #O_Functional_Check; 

// 4: Failure
      L     #TB_State; 
      L     4; 
      ==I   ; 
      =     #O_Failure; 

      SET   ; 
      SAVE  ; 
END_FUNCTION
