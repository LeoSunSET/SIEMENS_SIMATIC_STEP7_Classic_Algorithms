FUNCTION "ifm_VVB020_sts_B" : VOID
TITLE =Reads VVB020 raw data and returns it cleaned
//Reads raw data from periphery input and transform to:
//- Process values: Fatigue (v-RMS), Impact (a-Peak), Friction (a-RMS), 
//Temperature and Crest.
//- Status.
//- Outputs 1 and 2.
AUTHOR : Leonardo
FAMILY : ASSETMNG
NAME : VVB020
VERSION : 1.0


VAR_INPUT
  I_InputAdress : BOOL ;	//Input address of VVB020 device
  OP_VVB020_DB_Area : POINTER ;	//Pointer to VVB020 struct DB
END_VAR
VAR_TEMP
  ProcessData : STRUCT 	//Process Data
   Value : REAL ;	//Process data cleaned
  END_STRUCT ;	
  OB_Status : BYTE ;	//device status (see IODD_description)
  O_OU1 : BOOL ;	//switch point 1
  O_OU2 : BOOL ;	//switch point 2
  Temp_PQI : "PQI_IF_UDT";	//PQI temp variables
  TD_Address : DINT ;	//Address with raw data for treatment
  TB_Loop : BYTE ;	//Total cycles of the loop
  DB_NO_TEMP : INT ;	//Temp DB Address
  TB_Address : BYTE ;	//Address with raw data for treatment
END_VAR
BEGIN
NETWORK
TITLE =Open DB and Load DB address to AR2

      L     P##OP_VVB020_DB_Area; // load field pointer
      LAR2  ; // load Poiter address to Address Register 2
      L     W [AR2,P#0.0]; // load DB number
      T     #DB_NO_TEMP; // move DB number to local tag
      OPN   DB [#DB_NO_TEMP]; // open DB
      L     D [AR2,P#2.0]; // load DB address
      LAR2  ; // load DB address to Address Register 2
NETWORK
TITLE =Load the periphery start address

      L     P##I_InputAdress; // Load the start address pointer
      LAR1  ; // to load the pointer
NETWORK
TITLE =Read all 5 Process values

      L     5; // 5 Double Words to be processed
NEXT: T     #TB_Loop; // Jump label = loop start / transfer ACCU 1-L to loop counter.

      L     D [AR1,P#0.0]; // Load Double Word from periphery
      T     #TD_Address; // Move Periphery Double Word to a temp variable

      CALL "ifm_PV_READ" (// Call function responsible to break raw data into its correct values. 
           ID_Interface             := #TD_Address,
           OR_PS                    := #ProcessData.Value,
           OB_Status                := #OB_Status,
           O_OU1                    := #O_OU1,
           O_OU2                    := #O_OU2);

      L     #ProcessData.Value; // Load process value
      T     DBD [AR2,P#0.0]; // Move process value to its correct position in DB

      +AR1  P#4.0; // Increment double word pointer
      +AR2  P#4.0; // Increment double word pointer

      L     #TB_Loop; // Load contents of loop counter into ACCU 1.
      LOOP  NEXT; // Decrement the contents of ACCU 1 and jump to the NEXT jump label if ACCU 1-L > 0.
NETWORK
TITLE =Status

      L     #OB_Status; 
      T     DBB [AR2,P#0.0]; 
NETWORK
TITLE =Outputs 1 and 2 - switch points

      A     #O_OU1; 
      =     DBX [AR2,P#1.0]; 
      A     #O_OU2; 
      =     DBX [AR2,P#1.1]; 
NETWORK
TITLE =PQI

      +AR2  P#2.0; 
      +AR1  P#12.0; 
      L     B [AR1,P#0.0]; // Load byte from periphery
      T     #TB_Address; // Move Periphery byte to a temp variable
      CALL "IFM_AL19XX_PQI" (
           IB_PQI                   := #TB_Address,
           O_DI4                    := #Temp_PQI.O_DI4,
           O_DI2                    := #Temp_PQI.O_DI2,
           O_DA                     := #Temp_PQI.O_DA,
           O_DE                     := #Temp_PQI.O_DE,
           O_PQ                     := #Temp_PQI.O_PQ);

      A     #Temp_PQI.O_DI4; 
      =     DBX [AR2,P#0.0]; 
      A     #Temp_PQI.O_DI2; 
      =     DBX [AR2,P#0.1]; 
      A     #Temp_PQI.O_DA; 
      =     DBX [AR2,P#0.2]; 
      A     #Temp_PQI.O_DE; 
      =     DBX [AR2,P#0.3]; 
      A     #Temp_PQI.O_PQ; 
      =     DBX [AR2,P#0.4]; 
NETWORK
TITLE =

      SET   ; 
      SAVE  ; 
END_FUNCTION


FUNCTION "ifm_PV_READ" : VOID
TITLE =function process falue smart sensor profile measure
//Reads raw data from periphery input and transform to:
//- Process value.
//- Status.
//- Outputs 1 and 2.
AUTHOR : Leonardo
FAMILY : ASSETMNG
NAME : VVBxxx
VERSION : 1.0


VAR_INPUT
  ID_Interface : DINT ;	//Interface to device address
END_VAR
VAR_OUTPUT
  OR_PS : REAL ;	//output process value (real)
  OB_Status : BYTE ;	//device status (see IODD-description)
  O_OU1 : BOOL ;	//switch point 1
  O_OU2 : BOOL ;	//switch point 2
END_VAR
VAR_TEMP
  TW_Scale : WORD ;	
  TB_Scale : BYTE ;	
  TR_Scale : REAL ;	
  TW_Status : WORD ;	
  TD_AR1_Memo : DINT ;	
END_VAR
BEGIN
NETWORK
TITLE =Load address to ACCU1

      TAR1  #TD_AR1_Memo; 
      L     P##ID_Interface; // Load the start address pointer
      LAR1  ; // to load the pointer
NETWORK
TITLE =Process signal value

// Load address from periphery input
      L     B [AR1,P#2.0]; // Read the value from periphery input
      T     #TB_Scale; // Transfer to local work tag

// Check if Scale value is negative and transform to a negative word value
      L     127; 
      L     #TB_Scale; // signed Byte
      <I    ; 
      JCN   _001; // check if negativ
      L     W#16#FF00; 
      OW    ; // set high byte to FF
_001: T     #TW_Scale; // containig value as signed INT

      L     #TW_Scale; 
      ITD   ; 
      DTR   ; 
      T     #TR_Scale; 

// Create the power of 10 to scale (10^x)
      CALL "POW" (
           x                        := 1.000000e+001,
           b                        := #TR_Scale,
           y                        := #TR_Scale);

// Transform integer process value to real and multiply by scale power of 10
      L     W [AR1,P#0.0]; // Read the value and transfer to periphery output
      ITD   ; 
      DTR   ; 
      L     #TR_Scale; 
      *R    ; 
      T     #OR_PS; 
NETWORK
TITLE =create outputs

// load aux byte from periphery input
      L     B [AR1,P#3.0]; 
      T     #TW_Status; 

// check Out_1 - switch point 1
      L     #TW_Status; 
      L     1; 
      AW    ; 
      L     1; 
      ==I   ; 
      =     #O_OU1; 

// check Out_2 - switch point 2
      L     #TW_Status; 
      L     2; 
      AW    ; 
      L     2; 
      ==I   ; 
      =     #O_OU2; 
NETWORK
TITLE =create status
//Value range (Integer type):
//0 (Device is OK)
//1 (Maintenance required)
//2 (Out of specification)
//3 (Functional check)
//4 (Failure)
// create status
      L     #TW_Status; 
      SSI   4; 
      T     #OB_Status; 

NETWORK
TITLE =The end!

      LAR1  #TD_AR1_Memo; 
      SET   ; 
      SAVE  ; 

END_FUNCTION

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
