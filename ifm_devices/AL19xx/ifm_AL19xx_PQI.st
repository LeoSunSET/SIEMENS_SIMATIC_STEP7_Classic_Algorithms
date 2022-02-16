TYPE "PQI_IF_UDT"
AUTHOR : Leonardo
FAMILY : ASSETMNG
NAME : AL19_PQI
VERSION : 1.0


  STRUCT 	
   O_DI4 : BOOL ;	//Output signal status Pin 4
   O_DI2 : BOOL ;	//Output signal status Pin 2
   O_DA : BOOL ;	//Output device recognized
   O_DE : BOOL ;	//Output device error event has appeared
   O_PQ : BOOL ;	//Output port qualifer process data valid
  END_STRUCT ;	
END_TYPE

FUNCTION "IFM_AL19XX_PQI" : VOID
TITLE =control PQI-byte
//Operand - Description 
//IB_PQI  - Input PQI-Byte from the IO-Link Master submodule. 
//O_DI4   - Digital input from Pin4 when the master port is on mode digital 
//input. 
//Not available in mode IO-Link. 
//O_DI2   - Digital input from Pin2 
//O_DA    - Communication active 
//O_DE    - Event from the device is available 
//O_PQ    - The connected device is according to the port settings, the process 
//value is valid. 
AUTHOR : Leonardo
FAMILY : ASSETMNG
NAME : AL19_PQI
VERSION : 1.0


VAR_INPUT
  IB_PQI : BYTE ;	//Input PQI-byte
END_VAR
VAR_OUTPUT
  O_DI4 : BOOL ;	//Output signal status Pin 4
  O_DI2 : BOOL ;	//Output signal status Pin 2
  O_DA : BOOL ;	//Output device recognized
  O_DE : BOOL ;	//Output device error event has appeared
  O_PQ : BOOL ;	//Output port qualifer process data valid
END_VAR
VAR_TEMP
  TW_Flag : WORD ;	
END_VAR
BEGIN
NETWORK
TITLE =


      L     #IB_PQI; 
      T     #TW_Flag; 

      L     #TW_Flag; 
      L     1; 
      AW    ; 
      L     1; 
      ==I   ; 
      =     #O_DI4; 



      L     #TW_Flag; 
      L     2; 
      AW    ; 
      L     2; 
      ==I   ; 
      =     #O_DI2; 

      L     #TW_Flag; 
      L     32; 
      AW    ; 
      L     32; 
      ==I   ; 
      =     #O_DA; 

      L     #TW_Flag; 
      L     64; 
      AW    ; 
      L     64; 
      ==I   ; 
      =     #O_DE; 


      L     #TW_Flag; 
      L     128; 
      AW    ; 
      L     128; 
      ==I   ; 
      =     #O_PQ; 

      SET   ; 
      SAVE  ; 

END_FUNCTION
