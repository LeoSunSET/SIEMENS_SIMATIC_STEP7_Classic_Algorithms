
FUNCTION "SYC_FC_ANA_IN" : VOID
TITLE =ANA.INPUT READING AND SCALING TO ENG.UNITS-REAL OUTPUT
//################################################################################
//#            ANA.INPUT READING AND SCALING TO ENG.UNITS-REAL OUTPUT            #
//################################################################################
//This software is sold with the expressed agreement that the information therein 
//contained is the property of DANIELI AUTOMATION s.p.a.It will not be 
//reproduced, 
//installed, copied or otherwise disposed or directly or indirectly for different 
//uses than the scope of this contract, and will not be used, in whole or in 
//part,to assist in making or to furnish information for the use of the software, 
//or other reproductions hereof, or for the making of software or parts thereof, 
//except upon written permission of DANIELI AUTOMATION s.p.a., obtained and 
//specific to each case. The acceptance of this software will be constructed as 
//an acceptance of the foregoing agreement.
//
//Function name    : SYC_FC_ANA_IN
//
//Revisions history
//
//+---+--------+-------------------------------+--------------+--------------!
//! 6 !05/04/02!Revision                       !D.Comar       !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 5 !10/01/02!Revision                       !L.Zuccolo     !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 4 !10/10/01!Revision                       !L.Zuccolo     !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 3 !14/02/01!Revision                       !L.Zuccolo     !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 2 !   11/00!Revision                       !L.Zuccolo     !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 1 !15/12/97!For issue step7                !G.Ceolin      !              !
//+---+--------+-------------------------------+--------------+--------------!
//!Rev!Date    !Description                    !Drawn         !Checked       !
//+--------------------------------------------------------------------------+
//
//Revision hystory : 
//1.0 Issue
//2.0 Use of FC105 from Siemens TI-S7 standard libraries.
//    All values moved to reals. 
//    Separated diagnostic bits for field and channel faults.
//    Safe value in case of fault.
//3.0 Latching and ack of alarms added
//4.0 #TMP_Field_Fault disabled because Siemens scaling function gives 
//    error also if AIN value exceeds the range (i.e. 21 mA). 
//5.0 Use of FC105 from Siemens TI-S7 standard libraries removed because
//    the problem described in rev.4
//    New alarm detection procedure for TMP_Field_Fault
//6.0 The system disables the analog input diagnostic in case of the analog input 
//    is not a IW or PIW variable type.See network 6.
//
//Function         : This block is used to read a scale an analog variable from
//                   the peripherical PLC area
//
//Parameters       : See header
//               
//Remarks          : 
//Based upon FC105 Siemens TI-S7 standard libraries.
//Differences between FC105 and this FC are:
//- ENO output is always set to 1 even in case of AI error. This to allow the 
//  block to be written in a cascade ladder (error does not lock the following 
//  cascaded instructions).
//- Error diagnostic considers the HW fault too and the fault infos are written 
//  in bool outputs.
//- Safe output input paramenter added. In case of a fault the function output is
//  set to the safe output value.
AUTHOR : DA_Lib
VERSION : 0.0


VAR_INPUT
  IN_PIW_Address : INT ;	//Analog input address
  IN_HI_LIM : REAL ;	//Output max value [engineering units]
  IN_LO_LIM : REAL ;	//Output min value [engineering units]
  IN_Safe_OUT : REAL ;	//Output safe value in case of any AI fault [engineering units]
  IN_BIPOLAR : BOOL ;	//AI type: 0 = 0..10V, 0..5V, 4..20mA  //  1 = +-10V, +-5V, +-20mA
  IN_ACK : BOOL ;	//Alarms acknowledge
END_VAR
VAR_OUTPUT
  OUT_Value : REAL ;	//Output [engineering units]
END_VAR
VAR_IN_OUT
  IN_OUT_Field_Fault : BOOL ;	//Field sensor fault or broken wire (latched)
  IN_OUT_AI_CH_Fault : BOOL ;	//Analog input channel fault (latched)
END_VAR
VAR_TEMP
  TMP_RET_VAL : WORD ;	//Return value from SCALE function
  TMP_OUT : REAL ;	//OUT value from SCALE function
  TMP_Field_Fault : BOOL ;	//Field sensor fault or broken wire
  TMP_AI_CH_Fault : BOOL ;	//Analog input channel fault
  TMP_RAW_AIN_VALUE : REAL ;	//Raw value from analog input
  TMP_K1 : REAL ;	//K1
  TMP_RAW_AIN_VALUE_DINT : DINT ;	//Raw value from analog input, DINT format
  TMP_PV_RANGE : REAL ;	//Process variable range [eng.units]
  TMP_CARD_RANGE : REAL ;	//Card range [ticks]
  TMP_PIW_PNT : DWORD ;	//Analog input pointer
  TMP_AUX_REAL : REAL ;	
END_VAR
BEGIN
NETWORK
TITLE =K1 AND CARD RANGE CHOICE
//IF +-10mA  OR +-10v  OR +-5V  range THEN card range = 27648*2 ticks, K1=-27648
//IF 4..20mA OR 0..10V OR 0..5V range THEN card range = 27648   ticks, K1=0
      A     #IN_BIPOLAR; 
      =     L     36.0; 
      A     L     36.0; 
      JNB   _001; 
      L     5.529600e+004; 
      T     #TMP_CARD_RANGE; 
_001: NOP   0; 
      A     L     36.0; 
      JNB   _002; 
      L     -2.764800e+004; 
      T     #TMP_K1; 
_002: NOP   0; 
      A     L     36.0; 
      NOT   ; 
      =     L     36.1; 
      A     L     36.1; 
      JNB   _003; 
      L     2.764800e+004; 
      T     #TMP_CARD_RANGE; 
_003: NOP   0; 
      A     L     36.1; 
      JNB   _004; 
      L     0.000000e+000; 
      T     #TMP_K1; 
_004: NOP   0; 
NETWORK
TITLE =PROCESS VARIABLE RANGE CALCULATION

      L     #IN_HI_LIM; 
      L     #IN_LO_LIM; 
      -R    ; 
      T     #TMP_PV_RANGE; 
      NOP   0; 
NETWORK
TITLE =ANALOG INPUT RAW VALUE
//Measure [ticks]
      A(    ; 
      L     #IN_PIW_Address; 
      ITD   ; 
      T     #TMP_RAW_AIN_VALUE_DINT; 
      SET   ; 
      SAVE  ; 
      CLR   ; 
      A     BR; 
      )     ; 
      JNB   _005; 
      L     #TMP_RAW_AIN_VALUE_DINT; 
      DTR   ; 
      T     #TMP_RAW_AIN_VALUE; 
_005: NOP   0; 
NETWORK
TITLE =SCALING
//Out[eng.units] =
//
// Process var.range[eng.units]
// ---------------------------- * (measure[ticks] - K1) + LO_LIM[eng.units]
//        Card range[ticks]
//
      A     "TRUE"; 
      =     L     36.0; 
      A     L     36.0; 
      JNB   _006; 
      L     #TMP_RAW_AIN_VALUE; 
      L     #TMP_K1; 
      -R    ; 
      T     #TMP_AUX_REAL; 
_006: NOP   0; 
      A     L     36.0; 
      JNB   _007; 
      L     #TMP_AUX_REAL; 
      L     #TMP_PV_RANGE; 
      *R    ; 
      T     #TMP_AUX_REAL; 
_007: NOP   0; 
      A     L     36.0; 
      JNB   _008; 
      L     #TMP_AUX_REAL; 
      L     #TMP_CARD_RANGE; 
      /R    ; 
      T     #TMP_AUX_REAL; 
_008: NOP   0; 
      A     L     36.0; 
      JNB   _009; 
      L     #TMP_AUX_REAL; 
      L     #IN_LO_LIM; 
      +R    ; 
      T     #TMP_OUT; 
_009: NOP   0; 
NETWORK
TITLE =OUT OF RANGE TEST
//32767 == positive overflow. Overflow detected if PV > of (range dependent):
// RANGES |  LIMIT
//--------+------------
// +- 5V  |  5.88V
// +-10V  |  11.76V
// 0-10V  |  11.76V
// +-20mA |  23.52 mA
// 0-20mA |  23.52 mA
// 4-20mA |  22.81 mA
//
//-32768 == negative overflow. Overflow detected if PV < of (range dependent):
// RANGES |  LIMIT
//--------+------------
// +- 5V  |  - 5.88 V
// +-10V  |  -11.76 V
// 0-10V  |  - 1.76 V
// +-20mA |  -23.52 mA
// 0-20mA |  - 3.52 mA
// 4-20mA |    1.19 mA
//REMARK: values referred to S300 AIN modules, S400 AIN modules have more or
//less the same thresholds (see manuals)
      O(    ; 
      L     #TMP_RAW_AIN_VALUE_DINT; 
      L     L#32767; 
      >=D   ; 
      )     ; 
      O(    ; 
      L     #TMP_RAW_AIN_VALUE_DINT; 
      L     L#-32768; 
      <=D   ; 
      )     ; 
      =     #TMP_Field_Fault; 
NETWORK
TITLE =AI CHANNEL DIAGNOSTIC
//The system disables the analog input diagnostic in case of the analog input is
//not a IW or PIW variable type.
      SET   ; // Initialization of channel fault flag
      R     #TMP_AI_CH_Fault; 
//Channel Diagnostic 
      OPN   "DIA_DB_HW_IN_Diag"; // Open analog input diagnostic memory area
      L     P##IN_PIW_Address; // Load input card address
      T     #TMP_PIW_PNT; // Save analog input address into local pointer
      SRD   24; // Move the variable area type into the ACCU1 LSB
      L     W#16#80; // IF variable area type is a PIW
      <I    ; 
      JC    COFF; 
      TAK   ; 
      L     W#16#81; // OR variable area type is a IW
      >I    ; 
      JC    COFF; // THEN the system enables the channel diagnostic
      L     #TMP_PIW_PNT; 
      L     2; // Get analog input diagnostic bit address
      /I    ; 
      SRD   3; 
      LAR1  ; // Point to analog input diagnostic bit
      A     DBX [AR1,P#0.0]; // 
      A     "FALSE"; 
      =     #TMP_AI_CH_Fault; // Analog input channel fault
COFF: NOP   0; 
NETWORK
TITLE =SAFE OUTPUT

      O     #TMP_Field_Fault; 
      O     #TMP_AI_CH_Fault; 
      =     L     36.0; 
      A     L     36.0; 
      JNB   _00a; 
      L     #IN_Safe_OUT; 
      T     #OUT_Value; 
_00a: NOP   0; 
      A     L     36.0; 
      NOT   ; 
      JNB   _00b; 
      L     #TMP_OUT; 
      T     #OUT_Value; 
_00b: NOP   0; 
NETWORK
TITLE =ALARMS LATCHING
//Field fault
      A     #IN_ACK; 
      R     #IN_OUT_Field_Fault; 
      A     #TMP_Field_Fault; 
      S     #IN_OUT_Field_Fault; 
      NOP   0; 
NETWORK
TITLE =ALARMS LATCHING
//Channel fault
      A     #IN_ACK; 
      R     #IN_OUT_AI_CH_Fault; 
      A     #TMP_AI_CH_Fault; 
      S     #IN_OUT_AI_CH_Fault; 
      NOP   0; 
NETWORK
TITLE =Set of ENO

      SET   ; 
      SAVE  ; 
END_FUNCTION

FUNCTION "SYC_FC_INT>REAL" : VOID
TITLE =MOVES AN INTEGER INTO A REAL
//################################################################################
//#                      MOVES AN INTEGER INTO A REAL                            #
//################################################################################
//This software is sold with the expressed agreement that the information therein 
//contained is the property of DANIELI AUTOMATION s.p.a.It will not be 
//reproduced, 
//installed, copied or otherwise disposed or directly or indirectly for different 
//uses than the scope of this contract, and will not be used, in whole or in 
//part,to assist in making or to furnish information for the use of the software, 
//or other reproductions hereof, or for the making of software or parts thereof, 
//except upon written permission of DANIELI AUTOMATION s.p.a., obtained and 
//specific to each case. The acceptance of this software will be constructed as 
//an acceptance of the foregoing agreement.
//
//Function name    : SYC_FC_INT>REAL
//
//Revisions history
//
//+--------------------------------------------------------------------------+
//! 5 !        !                               !              !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 4 !        !                               !              !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 3 !        !                               !              !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 2 !        !                               !              !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 1 !  /01/99!For issue step7                !L.Orsettig    !              !
//+---+--------+-------------------------------+--------------+--------------!
//!Rev!Date    !Description                    !Drawn         !Checked       !
//+--------------------------------------------------------------------------+
//
//Function         : This block moves one integer to a real
AUTHOR : DA_Lib
VERSION : 0.0


VAR_INPUT
  IN_Source_int : INT ;	
END_VAR
VAR_OUTPUT
  OUT_real : REAL ;	
END_VAR
BEGIN
NETWORK
TITLE =

      L     #IN_Source_int; 
      ITD   ; 
      DTR   ; 
      T     #OUT_real; 
NETWORK
TITLE =FUNCTION RETURN

      SET   ; 
      SAVE  ; 
END_FUNCTION

FUNCTION "SYC_FC_REALxREAL>INT" : VOID
TITLE =MULTIPLIES A REAL BY A REAL - RESULT IN AN INTEGER 
//################################################################################
//#             MULTIPLIES A REAL BY A REAL - RESULT IN AN INTEGER               #
//################################################################################
//This software is sold with the expressed agreement that the information therein 
//contained is the property of DANIELI AUTOMATION s.p.a.It will not be 
//reproduced, 
//installed, copied or otherwise disposed or directly or indirectly for different 
//uses than the scope of this contract, and will not be used, in whole or in 
//part,to assist in making or to furnish information for the use of the software, 
//or other reproductions hereof, or for the making of software or parts thereof, 
//except upon written permission of DANIELI AUTOMATION s.p.a., obtained and 
//specific to each case. The acceptance of this software will be constructed as 
//an acceptance of the foregoing agreement.
//
//Function name    : SYC_FC_REALxREAL>INT
//
//Revisions history
//
//+--------------------------------------------------------------------------+
//! 5 !        !                               !              !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 4 !        !                               !              !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 3 !        !                               !              !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 2 !        !                               !              !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 1 !  /05/00!For issue step7                !L.Zuccolo     !              !
//+---+--------+-------------------------------+--------------+--------------!
//!Rev!Date    !Description                    !Drawn         !Checked       !
//+--------------------------------------------------------------------------+
//
//Revision hystory : R 1.0 Issue
//
//Function         : 
//This block multiplys a real by a real and returns a 16 bit integer number 
//limited within +32767 and -32768 range. 
//Typical use in network interface to scale process variables.
//
//Parameters       : See vars allocation table
//
//ENO set to 0 in case of overflow
//
//
AUTHOR : DA_Lib
VERSION : 0.0


VAR_INPUT
  IN0 : REAL ;	
  IN1 : REAL ;	
END_VAR
VAR_OUTPUT
  OUT : INT ;	
END_VAR
VAR_TEMP
  limit_reached : BOOL ;	//limit reached
END_VAR
BEGIN
NETWORK
TITLE =CONVERSION AND LIMITING

      SET   ; 
      R     #limit_reached; // limit reached preset to 0
      L     #IN0; // input
      L     #IN1; // scaling factor
      *R    ; // multiply
      A     OV; 
      S     #limit_reached; // overflow bit conditioning
      RND   ; // real to dint conversion
      A     OV; 
      S     #limit_reached; // overflow bit conditioning
      L     L#32767; // max limit
      >D    ; 
      S     #limit_reached; // limit reached
      JC    SETO; 
      TAK   ; 
      L     L#-32767; // min limit
      <D    ; 
      S     #limit_reached; // limit reached
      JC    SETO; 
      TAK   ; 
SETO: T     #OUT; // result
      AN    #limit_reached; 
      SET   ; 
      SAVE  ; // limit not reached: "ENO" = 1
END_FUNCTION

FUNCTION "SYC_FC_INTxIN/IN>INT" : VOID
TITLE =MULTIPLIES AND DIVIDES INTEGERS - RESULT IN AN INTEGER
//################################################################################
//#            MULTIPLIES AND DIVIDES INTEGERS - RESULT IN AN INTEGER            #
//################################################################################
//This software is sold with the expressed agreement that the information therein 
//contained is the property of DANIELI AUTOMATION s.p.a.It will not be 
//reproduced, 
//installed, copied or otherwise disposed or directly or indirectly for different 
//uses than the scope of this contract, and will not be used, in whole or in 
//part,to assist in making or to furnish information for the use of the software, 
//or other reproductions hereof, or for the making of software or parts thereof, 
//except upon written permission of DANIELI AUTOMATION s.p.a., obtained and 
//specific to each case. The acceptance of this software will be constructed as 
//an acceptance of the foregoing agreement.
//
//Function name    : SYC_FC_INTxIN/IN>INT
//
//Revisions history
//
//+--------------------------------------------------------------------------+
//! 5 !        !                               !              !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 4 !        !                               !              !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 3 !        !                               !              !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 2 !16/12/02!For revision                   !L.Zuccolo     !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 1 !  /01/99!For issue step7                !L.Orsettig    !              !
//+---+--------+-------------------------------+--------------+--------------!
//!Rev!Date    !Description                    !Drawn         !Checked       !
//+--------------------------------------------------------------------------+
//
//Revision hystory : R 1.0 Issue
//                   R 2.0 Insert ITD instruction.
//                         Before revision was:
//                         L     #IN_Source1_int
//                         L     #IN_Source2_int
//                         *I    
//                         L     #IN_Source3_int
//                         /D    
//                         After revision is:
//                         L     #IN_Source1_int
//                         L     #IN_Source2_int
//                         *I    
//                         L     #IN_Source3_int
//                         ITD   
//                         /D    
//
//Function         : This block multiply and divied three integers
//
//Parameters       : See vars allocation table
//
//Used DB          : None
//
//Used Flags       : None
// 
//Used prog.block  : None
//
//Remarks          :
//
//
AUTHOR : DA_Lib
VERSION : 0.0


VAR_INPUT
  IN_Source1_int : INT ;	
  IN_Source2_int : INT ;	
  IN_Source3_int : INT ;	
END_VAR
VAR_OUTPUT
  OUT_int : INT ;	
END_VAR
BEGIN
NETWORK
TITLE =

      L     #IN_Source1_int; 
      L     #IN_Source2_int; 
      *I    ; 
      L     #IN_Source3_int; 
      ITD   ; 
      /D    ; 
      T     #OUT_int; 
      AN    OV; 
      SAVE  ; 
      CLR   ; 
END_FUNCTION

FUNCTION "SYC_FC_INTxIN/IN>REAL" : VOID
TITLE =MULTIPLIES AND DIVIDES INTEGERS - RESULT IN A REAL
//################################################################################
//#          MULTIPLIES AND DIVIDES INTEGERS - RESULT IN A REAL                  #
//################################################################################
//This software is sold with the expressed agreement that the information therein 
//contained is the property of DANIELI AUTOMATION s.p.a.It will not be 
//reproduced, 
//installed, copied or otherwise disposed or directly or indirectly for different 
//uses than the scope of this contract, and will not be used, in whole or in 
//part,to assist in making or to furnish information for the use of the software, 
//or other reproductions hereof, or for the making of software or parts thereof, 
//except upon written permission of DANIELI AUTOMATION s.p.a., obtained and 
//specific to each case. The acceptance of this software will be constructed as 
//an acceptance of the foregoing agreement.
//
//Function name    : SYC_FC_INTxIN/IN>REAL
//
//Revisions history
//
//+--------------------------------------------------------------------------+
//! 5 !        !                               !              !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 4 !        !                               !              !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 3 !        !                               !              !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 2 !        !                               !              !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 1 !  /01/99!For issue step7                !L.Orsettig    !              !
//+---+--------+-------------------------------+--------------+--------------!
//!Rev!Date    !Description                    !Drawn         !Checked       !
//+--------------------------------------------------------------------------+
//
//Revision hystory : R 1.0 Issue
//
//Function         : This block multiply and divied three integers, result is a 
//                   real number
//Parameters       : See vars allocation table
//
//Used DB          : None
//
//Used Flags       : None
// 
//Used prog.block  : None
//
//Remarks          :
//
//
AUTHOR : DA_Lib
VERSION : 0.0


VAR_INPUT
  IN_Source_int : INT ;	//Source
  IN_Multiplier_int : INT ;	//Multiplier
  IN_Divider_Int : INT ;	//Divider
END_VAR
VAR_OUTPUT
  OUT_Real : REAL ;	//Output
END_VAR
BEGIN
NETWORK
TITLE =

      L     #IN_Source_int; 
      L     #IN_Multiplier_int; 
      *I    ; 
      DTR   ; 
      L     #IN_Divider_Int; 
      ITD   ; 
      DTR   ; 
      /R    ; 
      T     #OUT_Real; 
      AN    OV; 
      SAVE  ; 
      CLR   ; 
END_FUNCTION

FUNCTION "SYC_FC_INTxREAL>INT" : VOID
TITLE =MULTIPLIES AN INTEGER BY A REAL - RESULT IN AN INTEGER
//################################################################################
//#           MULTIPLIES AN INTEGER BY A REAL - RESULT IN AN INTEGER             #
//################################################################################
//This software is sold with the expressed agreement that the information therein 
//contained is the property of DANIELI AUTOMATION s.p.a.It will not be 
//reproduced, 
//installed, copied or otherwise disposed or directly or indirectly for different 
//uses than the scope of this contract, and will not be used, in whole or in 
//part,to assist in making or to furnish information for the use of the software, 
//or other reproductions hereof, or for the making of software or parts thereof, 
//except upon written permission of DANIELI AUTOMATION s.p.a., obtained and 
//specific to each case. The acceptance of this software will be constructed as 
//an acceptance of the foregoing agreement.
//
//Function name    : SYC_FC_INTxREAL>INT
//
//Revisions history
//
//+--------------------------------------------------------------------------+
//! 5 !        !                               !              !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 4 !        !                               !              !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 3 !        !                               !              !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 2 !  /07/00!Updating                       !L.Orsettig    !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 1 !  /01/99!For issue step7                !L.Orsettig    !              !
//+---+--------+-------------------------------+--------------+--------------!
//!Rev!Date    !Description                    !Drawn         !Checked       !
//+--------------------------------------------------------------------------+
//
//Revision hystory : R 1.0 Issue
//                 : R 2.0 Updating in order to limit output to +32767/-32768
//
//Function         : This block multiply one integera by one floating point       
//             
//                   number and returns an integer number
//
//Parameters       : See vars allocation table
//
//Used DB          : None
//
//Used Flags       : None
// 
//Used prog.block  : None
//
//Remarks          :
//
//
AUTHOR : DA_Lib
VERSION : 0.0


VAR_INPUT
  IN_Source_int : INT ;	
  IN_Multiplier_real : REAL ;	
END_VAR
VAR_OUTPUT
  OUT_int : INT ;	
END_VAR
BEGIN
NETWORK
TITLE =

      L     #IN_Source_int; 
      ITD   ; 
      DTR   ; 
      L     #IN_Multiplier_real; 
      *R    ; 
      RND   ; 
      L     L#32767; 
      >D    ; 
      JC    lim; 
      INVD  ; 
      <D    ; 
      JC    lim; 
      TAK   ; 
lim:  NOP   0; 
      T     #OUT_int; 
      SET   ; 
      SAVE  ; 
      CLR   ; 
END_FUNCTION

FUNCTION "SYC_FC_INT/REAL>INT" : VOID
TITLE =DIVIDES AN INTEGER BY A REAL - RESULT IN A INTEGER
//################################################################################
//#              DIVIDES AN INTEGER BY A REAL - RESULT IN A REAL                 #
//################################################################################
//This software is sold with the expressed agreement that the information therein 
//contained is the property of DANIELI AUTOMATION s.p.a.It will not be 
//reproduced, 
//installed, copied or otherwise disposed or directly or indirectly for different 
//uses than the scope of this contract, and will not be used, in whole or in 
//part,to assist in making or to furnish information for the use of the software, 
//or other reproductions hereof, or for the making of software or parts thereof, 
//except upon written permission of DANIELI AUTOMATION s.p.a., obtained and 
//specific to each case. The acceptance of this software will be constructed as 
//an acceptance of the foregoing agreement.
//
//Function name    : SYC_FC_INT/REAL>INT
//
//Revisions history
//
//+--------------------------------------------------------------------------+
//! 5 !        !                               !              !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 4 !        !                               !              !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 3 !        !                               !              !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 2 !        !                               !              !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 1 !  /01/99!For issue step7                !L.Orsettig    !              !
//+---+--------+-------------------------------+--------------+--------------!
//!Rev!Date    !Description                    !Drawn         !Checked       !
//+--------------------------------------------------------------------------+
//
//Revision hystory : R 1.0 Issue
//
//Function         : This block multiply one integera by one floating point       
//             
//                   number and returns an integer number
//
//Parameters       : See vars allocation table
//
//Used DB          : None
//
//Used Flags       : None
// 
//Used prog.block  : None
//
//Remarks          :
//
//
AUTHOR : DA_Lib
VERSION : 0.0


VAR_INPUT
  IN_Source_int : INT ;	
  IN_Multiplier_real : REAL ;	
END_VAR
VAR_OUTPUT
  OUT_int : INT ;	
END_VAR
BEGIN
NETWORK
TITLE =

      L     #IN_Source_int; 
      ITD   ; 
      DTR   ; 
      L     #IN_Multiplier_real; 
      /R    ; 
      RND   ; 
      L     L#32767; 
      >D    ; 
      JC    lim; 
      INVD  ; 
      <D    ; 
      JC    lim; 
      TAK   ; 
lim:  NOP   0; 
      T     #OUT_int; 
      AN    OV; 
      SAVE  ; 
      CLR   ; 
END_FUNCTION

FUNCTION "SYC_FC_INTxREAL>REAL" : VOID
TITLE =MULTIPLIES AN INTEGER BY A REAL - RESULT IN A REAL 
//################################################################################
//#             MULTIPLIES AN INTEGER BY A REAL - RESULT IN A REAL               #
//################################################################################
//This software is sold with the expressed agreement that the information therein 
//contained is the property of DANIELI AUTOMATION s.p.a.It will not be 
//reproduced, 
//installed, copied or otherwise disposed or directly or indirectly for different 
//uses than the scope of this contract, and will not be used, in whole or in 
//part,to assist in making or to furnish information for the use of the software, 
//or other reproductions hereof, or for the making of software or parts thereof, 
//except upon written permission of DANIELI AUTOMATION s.p.a., obtained and 
//specific to each case. The acceptance of this software will be constructed as 
//an acceptance of the foregoing agreement.
//
//Function name    : SYC_FC_INTxREAL>REAL
//
//Revisions history
//
//+--------------------------------------------------------------------------+
//! 5 !        !                               !              !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 4 !        !                               !              !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 3 !        !                               !              !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 2 !        !                               !              !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 1 !  /05/00!For issue step7                !L.Zuccolo     !              !
//+---+--------+-------------------------------+--------------+--------------!
//!Rev!Date    !Description                    !Drawn         !Checked       !
//+--------------------------------------------------------------------------+
//
//Revision hystory : R 1.0 Issue
//
//Function         : This block multiply one integera by one floating point       
//             
//                   number and returns an integer number
//
//Parameters       : See vars allocation table
//
//Used DB          : None
//
//Used Flags       : None
// 
//Used prog.block  : None
//
//Remarks          :
//
//
AUTHOR : DA_Lib
VERSION : 0.0


VAR_INPUT
  IN_Source_Int : INT ;	
  IN_Source_Real : REAL ;	
END_VAR
VAR_OUTPUT
  OUT_Real : REAL ;	
END_VAR
BEGIN
NETWORK
TITLE =

      L     #IN_Source_Int; 
      ITD   ; 
      DTR   ; 
      L     #IN_Source_Real; 
      *R    ; 
      T     #OUT_Real; 
      AN    OV; 
      SAVE  ; 
      CLR   ; 
END_FUNCTION

FUNCTION "SYC_FC_INT/REAL>REAL" : VOID
TITLE =DIVIDES AN INTEGER BY A REAL - RESULT IN A REAL
//################################################################################
//#            DIVIDES AN INTEGER BY A REAL - RESULT IN A REAL                   #
//################################################################################
//This software is sold with the expressed agreement that the information therein 
//contained is the property of DANIELI AUTOMATION s.p.a.It will not be 
//reproduced, 
//installed, copied or otherwise disposed or directly or indirectly for different 
//uses than the scope of this contract, and will not be used, in whole or in 
//part,to assist in making or to furnish information for the use of the software, 
//or other reproductions hereof, or for the making of software or parts thereof, 
//except upon written permission of DANIELI AUTOMATION s.p.a., obtained and 
//specific to each case. The acceptance of this software will be constructed as 
//an acceptance of the foregoing agreement.
//
//Function name    : SYC_FC_INT/REAL>REAL
//
//Revisions history
//
//+--------------------------------------------------------------------------+
//! 5 !        !                               !              !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 4 !        !                               !              !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 3 !        !                               !              !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 2 !        !                               !              !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 1 !  /05/00!For issue step7                !L.Zuccolo     !              !
//+---+--------+-------------------------------+--------------+--------------!
//!Rev!Date    !Description                    !Drawn         !Checked       !
//+--------------------------------------------------------------------------+
//
//Revision hystory : R 1.0 Issue
//
//Function         : This block mdivides one integera by one floating point       
//             
//                   number and returns an integer number
//
//Parameters       : See vars allocation table
//
//Used DB          : None
//
//Used Flags       : None
// 
//Used prog.block  : None
//
//Remarks          :
//
//
AUTHOR : DA_Lib
VERSION : 0.0


VAR_INPUT
  IN_Source_Int : INT ;	
  IN_Source_Real : REAL ;	
END_VAR
VAR_OUTPUT
  OUT_Real : REAL ;	
END_VAR
BEGIN
NETWORK
TITLE =

      L     #IN_Source_Int; 
      ITD   ; 
      DTR   ; 
      L     #IN_Source_Real; 
      /R    ; 
      T     #OUT_Real; 
      AN    OV; 
      SAVE  ; 
      CLR   ; 
END_FUNCTION

FUNCTION "SYC_FC_LIM_R" : VOID
TITLE =LIMITING OF A REAL BETWEEN A MIN AND A MAX
//################################################################################
//#              LIMITING OF A REAL BETWEEN A MIN AND A MAX                      #
//################################################################################
//This software is sold with the expressed agreement that the information therein 
//contained is the property of DANIELI AUTOMATION s.p.a.It will not be 
//reproduced, 
//installed, copied or otherwise disposed or directly or indirectly for different 
//uses than the scope of this contract, and will not be used, in whole or in 
//part,to assist in making or to furnish information for the use of the software, 
//or other reproductions hereof, or for the making of software or parts thereof, 
//except upon written permission of DANIELI AUTOMATION s.p.a., obtained and 
//specific to each case. The acceptance of this software will be constructed as 
//an acceptance of the foregoing agreement.
//
//Function name    : SYC_FC_LIM_R
//
//Revisions history
//
//+--------------------------------------------------------------------------+
//! 5 !        !                               !              !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 4 !        !                               !              !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 3 !        !                               !              !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 2 !  /11/00!Revision                       !L.Zuccolo     !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 1 !  /01/99!For issue step7                !L.Orsettig    !              !
//+---+--------+-------------------------------+--------------+--------------!
//!Rev!Date    !Description                    !Drawn         !Checked       !
//+--------------------------------------------------------------------------+
//
//Function         : This block limit the input variable between MIN and MAX 
//                   parameters
//
//Revisions
//1 - Issue
//2 - ENO always set to 1, limiting action info available as separated output
AUTHOR : DA_Lib
VERSION : 0.0


VAR_INPUT
  Min : REAL ;	//Minimum
  Max : REAL ;	//Maximum
END_VAR
VAR_OUTPUT
  OUT_Limiting : BOOL ;	//Fuction is limiting the tested value 
END_VAR
VAR_IN_OUT
  Variable_to_limit : REAL ;	//Input
END_VAR
BEGIN
NETWORK
TITLE =Limit
//if overflow then output=min value
      O(    ; 
      A(    ; 
      O(    ; 
      L     #Variable_to_limit; 
      L     #Min; 
      <R    ; 
      )     ; 
      O     OV; 
      )     ; 
      JNB   _001; 
      L     #Min; 
      T     #Variable_to_limit; 
      SET   ; 
      SAVE  ; 
      CLR   ; 
_001: A     BR; 
      )     ; 
      O(    ; 
      A(    ; 
      L     #Variable_to_limit; 
      L     #Max; 
      >R    ; 
      )     ; 
      JNB   _002; 
      L     #Max; 
      T     #Variable_to_limit; 
      SET   ; 
      SAVE  ; 
      CLR   ; 
_002: A     BR; 
      )     ; 
      =     #OUT_Limiting; 
NETWORK
TITLE =ENO is always set to 1

      SET   ; 
      SAVE  ; 
END_FUNCTION

FUNCTION "SYC_FC_LIM_I" : VOID
TITLE =LIMITING OF AN INTEGER BETWEEN A MIN AND A MAX
//################################################################################
//#              LIMITING OF AN INTEGER BETWEEN A MIN AND A MAX                  #
//################################################################################
//This software is sold with the expressed agreement that the information therein 
//contained is the property of DANIELI AUTOMATION s.p.a.It will not be 
//reproduced, 
//installed, copied or otherwise disposed or directly or indirectly for different 
//uses than the scope of this contract, and will not be used, in whole or in 
//part,to assist in making or to furnish information for the use of the software, 
//or other reproductions hereof, or for the making of software or parts thereof, 
//except upon written permission of DANIELI AUTOMATION s.p.a., obtained and 
//specific to each case. The acceptance of this software will be constructed as 
//an acceptance of the foregoing agreement.
//
//Function name    : SYC_FC_LIM_I
//
//Revisions history
//
//+--------------------------------------------------------------------------+
//! 5 !        !                               !              !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 4 !        !                               !              !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 3 !        !                               !              !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 2 !  /11/00!Revision                       !L.Zuccolo     !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 1 !  /01/99!For issue step7                !L.Orsettig    !              !
//+---+--------+-------------------------------+--------------+--------------!
//!Rev!Date    !Description                    !Drawn         !Checked       !
//+--------------------------------------------------------------------------+
//
//Function         : This block limit the input variable between MIN and MAX 
//                   parameters
//
//Revisions
//1 - Issue
//2 - ENO always set to 1, limiting action info available as separated output
AUTHOR : DA_Lib
VERSION : 0.0


VAR_INPUT
  IN_Min : INT ;	//Minimum
  IN_Max : INT ;	//Maximum
END_VAR
VAR_OUTPUT
  OUT_Limiting : BOOL ;	//Fuction is limiting the tested value 
END_VAR
VAR_IN_OUT
  Variable_to_limit : INT ;	//Input
END_VAR
BEGIN
NETWORK
TITLE =Limit
//if overflow then output=min value
      O(    ; 
      A(    ; 
      O(    ; 
      L     #Variable_to_limit; 
      L     #IN_Min; 
      <I    ; 
      )     ; 
      O     OV; 
      )     ; 
      JNB   _001; 
      L     #IN_Min; 
      T     #Variable_to_limit; 
      SET   ; 
      SAVE  ; 
      CLR   ; 
_001: A     BR; 
      )     ; 
      O(    ; 
      A(    ; 
      L     #Variable_to_limit; 
      L     #IN_Max; 
      >I    ; 
      )     ; 
      JNB   _002; 
      L     #IN_Max; 
      T     #Variable_to_limit; 
      SET   ; 
      SAVE  ; 
      CLR   ; 
_002: A     BR; 
      )     ; 
      =     #OUT_Limiting; 
NETWORK
TITLE =ENO is always set to 1

      SET   ; 
      SAVE  ; 
END_FUNCTION

FUNCTION "SYC_FC_PERM7" : VOID
TITLE =LOGIC AND OF 7 INPUT BITS PASSED AS PERMISSIVES
//################################################################################
//#                 LOGIC OR OF 8 INPUT BITS PASSED AS INTERLOCK                 #
//################################################################################
//This software is sold with the expressed agreement that the information therein 
//contained is the property of DANIELI AUTOMATION s.p.a.It will not be 
//reproduced, 
//installed, copied or otherwise disposed or directly or indirectly for different 
//uses than the scope of this contract, and will not be used, in whole or in 
//part,to assist in making or to furnish information for the use of the software, 
//or other reproductions hereof, or for the making of software or parts thereof, 
//except upon written permission of DANIELI AUTOMATION s.p.a., obtained and 
//specific to each case. The acceptance of this software will be constructed as 
//an acceptance of the foregoing agreement.
//
//Function name    : SYC_FC_PERM7
//
//Revisions history
//
//+--------------------------------------------------------------------------+
//! 5 !        !                               !              !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 4 !        !                               !              !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 3 !18/09/08!Permissives                    !M.Orlando     !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 2 !16/01/03!For revision                   !D.Comar       !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 1 !20/07/01!For issue EZZ                  !L.Orsettig    !              !
//+---+--------+-------------------------------+--------------+--------------!
//!Rev!Date    !Description                    !Drawn         !Checked       !
//+--------------------------------------------------------------------------+
//
//Revision hystory : R 1.0 Issue
//                   
//Function         : This program performs the logic AND of 7 input bits 
//passed as permissives; the 1st bit of output byte is cumulative AND, the other 
//bits are the map of inputs.
//
//Calling block    : 
//
//Used DB          : 
//
//Used Flags       : None
// 
//Used prog.block  : None
//
//Remarks          :
//
AUTHOR : DA_Lib
VERSION : 0.2


VAR_INPUT
  IN_Permissive_01 : BOOL ;	//Permissive #01
  IN_Permissive_02 : BOOL ;	//Permissive #02
  IN_Permissive_03 : BOOL ;	//Permissive #03
  IN_Permissive_04 : BOOL ;	//Permissive #04
  IN_Permissive_05 : BOOL ;	//Permissive #05
  IN_Permissive_06 : BOOL ;	//Permissive #06
  IN_Permissive_07 : BOOL ;	//Permissive #07
END_VAR
VAR_OUTPUT
  Permissive_Status : POINTER ;	//Permissive status(word)
END_VAR
VAR_TEMP
  TMP_Permissive_Status : STRUCT 	//Permissive status
   Bit00 : BOOL ;	//Bit #00
   Bit01 : BOOL ;	//Bit #01
   Bit02 : BOOL ;	//Bit #02
   Bit03 : BOOL ;	//Bit #03
   Bit04 : BOOL ;	//Bit #04
   Bit05 : BOOL ;	//Bit #05
   Bit06 : BOOL ;	//Bit #06
   Bit07 : BOOL ;	//Bit #07
  END_STRUCT ;	
  TMP_Permissive_DB_TYPE : BOOL ;	//Output variable is a DB variable
  TMP_OUT_DB : WORD ;	//Output variable DB address
  TMP_OUT_ADDR : DWORD ;	//Output variable address
  TMP_Output : BOOL ;	//Temporary Out
END_VAR
BEGIN
NETWORK
TITLE =OUTPUT VARIABLE MEMORY AREA
// 
      L     P##Permissive_Status; // Load output variable pointer
      LAR1  ; // Load ind.register AR1
      L     W [AR1,P#0.0]; // Get  recipe order DB address
      T     #TMP_OUT_DB; 
      L     W#16#10; // Point to byte 2
      +AR1  ; 
      L     D [AR1,P#0.0]; // Load output variable address
      T     #TMP_OUT_ADDR; 

      A(    ; 
      L     B [AR1,P#0.0]; // Get  output variable memory area type
      L     B#16#85; // Load DI type code
      ==I   ; // IF memory area type is L [local order]
      )     ; 
      O(    ; 
      TAK   ; // Load memory area type
      L     B#16#84; // Load DB type code
      ==I   ; // IF memory area type is I or Q or M
      )     ; 
      =     #TMP_Permissive_DB_TYPE; 
NETWORK
TITLE =PERMISSIVES OUTPUT
//Copy Permissives to output status word
      A     #IN_Permissive_01; 
      =     #TMP_Permissive_Status.Bit01; 
      A     #TMP_Permissive_Status.Bit01; 
      O(    ; 
      A     #IN_Permissive_02; 
      =     #TMP_Permissive_Status.Bit02; 
      A     #TMP_Permissive_Status.Bit02; 
      )     ; 
      O(    ; 
      A     #IN_Permissive_03; 
      =     #TMP_Permissive_Status.Bit03; 
      A     #TMP_Permissive_Status.Bit03; 
      )     ; 
      O(    ; 
      A     #IN_Permissive_04; 
      =     #TMP_Permissive_Status.Bit04; 
      A     #TMP_Permissive_Status.Bit04; 
      )     ; 
      O(    ; 
      A     #IN_Permissive_05; 
      =     #TMP_Permissive_Status.Bit05; 
      A     #TMP_Permissive_Status.Bit05; 
      )     ; 
      O(    ; 
      A     #IN_Permissive_06; 
      =     #TMP_Permissive_Status.Bit06; 
      A     #TMP_Permissive_Status.Bit06; 
      )     ; 
      O(    ; 
      A     #IN_Permissive_07; 
      =     #TMP_Permissive_Status.Bit07; 
      A     #TMP_Permissive_Status.Bit07; 
      )     ; 
      =     #TMP_Output; 
NETWORK
TITLE =PERMISSIVES CUMULATIVE AND

      A     #IN_Permissive_01; 
      A     #IN_Permissive_02; 
      A     #IN_Permissive_03; 
      A     #IN_Permissive_04; 
      A     #IN_Permissive_05; 
      A     #IN_Permissive_06; 
      A     #IN_Permissive_07; 
      =     #TMP_Permissive_Status.Bit00; 

      A     #TMP_Permissive_Status.Bit00; 
      SAVE  ; 
NETWORK
TITLE =PERMISSIVE STATUS

      L     P##TMP_Permissive_Status; 
      LAR1  ; 
      L     LB [AR1,P#0.0]; 
      AN    #TMP_Permissive_DB_TYPE; 
      JC    N_DB; 
      OPN   DB [#TMP_OUT_DB]; 
N_DB: NOP   0; 
      L     #TMP_OUT_ADDR; 
      LAR1  ; 
      TAK   ; 
      T     B [AR1,P#1.0]; // Output variable updating
END_FUNCTION

FUNCTION "SYC_FC_PERM15" : VOID
TITLE =LOGIC AND OF 15 INPUT BITS PASSED AS PERMISSIVES
//################################################################################
//#                LOGIC OR OF 15 INPUT BITS PASSED AS PERMISSIVES               #
//################################################################################
//This software is sold with the expressed agreement that the information therein 
//contained is the property of DANIELI AUTOMATION s.p.a.It will not be 
//reproduced, 
//installed, copied or otherwise disposed or directly or indirectly for different 
//uses than the scope of this contract, and will not be used, in whole or in 
//part,to assist in making or to furnish information for the use of the software, 
//or other reproductions hereof, or for the making of software or parts thereof, 
//except upon written permission of DANIELI AUTOMATION s.p.a., obtained and 
//specific to each case. The acceptance of this software will be constructed as 
//an acceptance of the foregoing agreement.
//
//Function name    : SYC_FC_PERM15
//
//Revisions history
//
//+--------------------------------------------------------------------------+
//! 5 !        !                               !              !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 4 !        !                               !              !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 3 !18/09/08!Permissives                    !M.Orlando     !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 2 !16/01/03!For revision                   !D.Comar       !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 1 !20/07/01!For issue EZZ                  !L.Orsettig    !              !
//+---+--------+-------------------------------+--------------+--------------!
//!Rev!Date    !Description                    !Drawn         !Checked       !
//+--------------------------------------------------------------------------+
//
//Revision hystory : R 1.0 Issue
//                   
//Function         : This program performs the logic AND of 15 input bits 
//passed as permissives; the 1st bit of output byte is cumulative AND, the other 
//bits are the map of inputs.
//
//Calling block    : 
//
//Used DB          : 
//
//Used Flags       : None
// 
//Used prog.block  : None
//
//Remarks          :
//
AUTHOR : DA_Lib
VERSION : 0.2


VAR_INPUT
  IN_Permissive_01 : BOOL ;	//Permissive #01
  IN_Permissive_02 : BOOL ;	//Permissive #02
  IN_Permissive_03 : BOOL ;	//Permissive #03
  IN_Permissive_04 : BOOL ;	//Permissive #04
  IN_Permissive_05 : BOOL ;	//Permissive #05
  IN_Permissive_06 : BOOL ;	//Permissive #06
  IN_Permissive_07 : BOOL ;	//Permissive #07
  IN_Permissive_08 : BOOL ;	//Permissive #08
  IN_Permissive_09 : BOOL ;	//Permissive #09
  IN_Permissive_10 : BOOL ;	//Permissive #10
  IN_Permissive_11 : BOOL ;	//Permissive #11
  IN_Permissive_12 : BOOL ;	//Permissive #12
  IN_Permissive_13 : BOOL ;	//Permissive #13
  IN_Permissive_14 : BOOL ;	//Permissive #14
  IN_Permissive_15 : BOOL ;	//Permissive #15
END_VAR
VAR_OUTPUT
  Permissive_Status : POINTER ;	//Permissives status(word)
END_VAR
VAR_TEMP
  TMP_Permissive_Status : STRUCT 	//Permissive status
   Bit00 : BOOL ;	//Bit #00
   Bit01 : BOOL ;	//Bit #01
   Bit02 : BOOL ;	//Bit #02
   Bit03 : BOOL ;	//Bit #03
   Bit04 : BOOL ;	//Bit #04
   Bit05 : BOOL ;	//Bit #05
   Bit06 : BOOL ;	//Bit #06
   Bit07 : BOOL ;	//Bit #07
   Bit08 : BOOL ;	//Bit #08
   Bit09 : BOOL ;	//Bit #09
   Bit10 : BOOL ;	//Bit #10
   Bit11 : BOOL ;	//Bit #11
   Bit12 : BOOL ;	//Bit #12
   Bit13 : BOOL ;	//Bit #13
   Bit14 : BOOL ;	//Bit #14
   Bit15 : BOOL ;	//Bit #15
  END_STRUCT ;	
  TMP_Permissive_DB_TYPE : BOOL ;	//Output variable is a DB variable
  TMP_OUT_DB : WORD ;	//Output variable DB address
  TMP_OUT_ADDR : DWORD ;	//Output variable address
  TMP_Output : BOOL ;	//Temporary Out
END_VAR
BEGIN
NETWORK
TITLE =OUTPUT VARIABLE MEMORY AREA
// 
      L     P##Permissive_Status; // Load output variable pointer
      LAR1  ; // Load ind.register AR1
      L     W [AR1,P#0.0]; // Get  recipe order DB address
      T     #TMP_OUT_DB; 
      L     W#16#10; // Point to byte 2
      +AR1  ; 
      L     D [AR1,P#0.0]; // Load output variable address
      T     #TMP_OUT_ADDR; 

      A(    ; 
      L     B [AR1,P#0.0]; // Get  output variable memory area type
      L     B#16#85; // Load DI type code
      ==I   ; // IF memory area type is L [local order]
      )     ; 
      O(    ; 
      TAK   ; // Load memory area type
      L     B#16#84; // Load DB type code
      ==I   ; // IF memory area type is I or Q or M
      )     ; 
      =     #TMP_Permissive_DB_TYPE; 
NETWORK
TITLE =PERMISSIVES OUTPUT
//Copy Permissives to output status word
      A     #IN_Permissive_01; 
      =     #TMP_Permissive_Status.Bit01; 
      A     #TMP_Permissive_Status.Bit01; 
      O(    ; 
      A     #IN_Permissive_02; 
      =     #TMP_Permissive_Status.Bit02; 
      A     #TMP_Permissive_Status.Bit02; 
      )     ; 
      O(    ; 
      A     #IN_Permissive_03; 
      =     #TMP_Permissive_Status.Bit03; 
      A     #TMP_Permissive_Status.Bit03; 
      )     ; 
      O(    ; 
      A     #IN_Permissive_04; 
      =     #TMP_Permissive_Status.Bit04; 
      A     #TMP_Permissive_Status.Bit04; 
      )     ; 
      O(    ; 
      A     #IN_Permissive_05; 
      =     #TMP_Permissive_Status.Bit05; 
      A     #TMP_Permissive_Status.Bit05; 
      )     ; 
      O(    ; 
      A     #IN_Permissive_06; 
      =     #TMP_Permissive_Status.Bit06; 
      A     #TMP_Permissive_Status.Bit06; 
      )     ; 
      O(    ; 
      A     #IN_Permissive_07; 
      =     #TMP_Permissive_Status.Bit07; 
      A     #TMP_Permissive_Status.Bit07; 
      )     ; 
      O(    ; 
      A     #IN_Permissive_08; 
      =     #TMP_Permissive_Status.Bit08; 
      A     #TMP_Permissive_Status.Bit08; 
      )     ; 
      O(    ; 
      A     #IN_Permissive_09; 
      =     #TMP_Permissive_Status.Bit09; 
      A     #TMP_Permissive_Status.Bit09; 
      )     ; 
      O(    ; 
      A     #IN_Permissive_10; 
      =     #TMP_Permissive_Status.Bit10; 
      A     #TMP_Permissive_Status.Bit10; 
      )     ; 
      O(    ; 
      A     #IN_Permissive_11; 
      =     #TMP_Permissive_Status.Bit11; 
      A     #TMP_Permissive_Status.Bit11; 
      )     ; 
      O(    ; 
      A     #IN_Permissive_12; 
      =     #TMP_Permissive_Status.Bit12; 
      A     #TMP_Permissive_Status.Bit12; 
      )     ; 
      O(    ; 
      A     #IN_Permissive_13; 
      =     #TMP_Permissive_Status.Bit13; 
      A     #TMP_Permissive_Status.Bit13; 
      )     ; 
      O(    ; 
      A     #IN_Permissive_14; 
      =     #TMP_Permissive_Status.Bit14; 
      A     #TMP_Permissive_Status.Bit14; 
      )     ; 
      O(    ; 
      A     #IN_Permissive_15; 
      =     #TMP_Permissive_Status.Bit15; 
      A     #TMP_Permissive_Status.Bit15; 
      )     ; 
      =     #TMP_Output; 
NETWORK
TITLE =PERMISSIVES CUMULATIVE AND

      A     #IN_Permissive_01; 
      A     #IN_Permissive_02; 
      A     #IN_Permissive_03; 
      A     #IN_Permissive_04; 
      A     #IN_Permissive_05; 
      A     #IN_Permissive_06; 
      A     #IN_Permissive_07; 
      A     #IN_Permissive_08; 
      A     #IN_Permissive_09; 
      A     #IN_Permissive_10; 
      A     #IN_Permissive_11; 
      A     #IN_Permissive_12; 
      A     #IN_Permissive_13; 
      A     #IN_Permissive_14; 
      A     #IN_Permissive_15; 
      =     #TMP_Permissive_Status.Bit00; 
      A     #TMP_Permissive_Status.Bit00; 
      SAVE  ; 
NETWORK
TITLE =PERMISSIVE STATUS

      L     P##TMP_Permissive_Status; 
      LAR1  ; 
      L     LW [AR1,P#0.0]; 
      CAW   ; 
      AN    #TMP_Permissive_DB_TYPE; 
      JC    N_DB; 
      OPN   DB [#TMP_OUT_DB]; 
N_DB: NOP   0; 
      L     #TMP_OUT_ADDR; 
      LAR1  ; 
      TAK   ; 
      T     W [AR1,P#0.0]; // Output variable updating      
END_FUNCTION

FUNCTION "SYC_FC_PERM31" : VOID
TITLE =LOGIC AND OF 31 INPUT BITS PASSED AS PERMISSIVES
//################################################################################
//#              LOGIC OR OF 32 INPUT BITS PASSED AS PERMISSIVES                 #
//################################################################################
//This software is sold with the expressed agreement that the information therein 
//contained is the property of DANIELI AUTOMATION s.p.a.It will not be 
//reproduced, 
//installed, copied or otherwise disposed or directly or indirectly for different 
//uses than the scope of this contract, and will not be used, in whole or in 
//part,to assist in making or to furnish information for the use of the software, 
//or other reproductions hereof, or for the making of software or parts thereof, 
//except upon written permission of DANIELI AUTOMATION s.p.a., obtained and 
//specific to each case. The acceptance of this software will be constructed as 
//an acceptance of the foregoing agreement.
//
//Function name    : SYC_FC_PERM31
//
//Revisions history
//
//+--------------------------------------------------------------------------+
//! 5 !        !                               !              !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 4 !        !                               !              !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 3 !18/09/08!Permissives                    !M.Orlando     !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 2 !16/01/03!For revision                   !D.Comar       !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 1 !20/07/01!For issue EZZ                  !L.Orsettig    !              !
//+---+--------+-------------------------------+--------------+--------------!
//!Rev!Date    !Description                    !Drawn         !Checked       !
//+--------------------------------------------------------------------------+
//
//Revision hystory : R 1.0 Issue
//                   
//Function         : This program performs the logic AND of 31 input bits 
//passed as permissives; the 1st bit of output byte is cumulative AND, the other 
//bits are the map of inputs.
//
//Calling block    : 
//
//Used DB          : 
//
//Used Flags       : None
// 
//Used prog.block  : None
//
//Remarks          :
//
AUTHOR : DA_Lib
VERSION : 0.2


VAR_INPUT
  IN_Permissive_01 : BOOL ;	//Permissive #01
  IN_Permissive_02 : BOOL ;	//Permissive #02
  IN_Permissive_03 : BOOL ;	//Permissive #03
  IN_Permissive_04 : BOOL ;	//Permissive #04
  IN_Permissive_05 : BOOL ;	//Permissive #05
  IN_Permissive_06 : BOOL ;	//Permissive #06
  IN_Permissive_07 : BOOL ;	//Permissive #07
  IN_Permissive_08 : BOOL ;	//Permissive #08
  IN_Permissive_09 : BOOL ;	//Permissive #09
  IN_Permissive_10 : BOOL ;	//Permissive #10
  IN_Permissive_11 : BOOL ;	//Permissive #11
  IN_Permissive_12 : BOOL ;	//Permissive #12
  IN_Permissive_13 : BOOL ;	//Permissive #13
  IN_Permissive_14 : BOOL ;	//Permissive #14
  IN_Permissive_15 : BOOL ;	//Permissive #15
  IN_Permissive_16 : BOOL ;	//Permissive #16
  IN_Permissive_17 : BOOL ;	//Permissive #17
  IN_Permissive_18 : BOOL ;	//Permissive #18
  IN_Permissive_19 : BOOL ;	//Permissive #19
  IN_Permissive_20 : BOOL ;	//Permissive #20
  IN_Permissive_21 : BOOL ;	//Permissive #21
  IN_Permissive_22 : BOOL ;	//Permissive #22
  IN_Permissive_23 : BOOL ;	//Permissive #23
  IN_Permissive_24 : BOOL ;	//Permissive #24
  IN_Permissive_25 : BOOL ;	//Permissive #25
  IN_Permissive_26 : BOOL ;	//Permissive #26
  IN_Permissive_27 : BOOL ;	//Permissive #27
  IN_Permissive_28 : BOOL ;	//Permissive #28
  IN_Permissive_29 : BOOL ;	//Permissive #29
  IN_Permissive_30 : BOOL ;	//Permissive #30
  IN_Permissive_31 : BOOL ;	//Permissive #31
END_VAR
VAR_OUTPUT
  Permissives_Status : POINTER ;	//Permissives status(word)
END_VAR
VAR_TEMP
  TMP_Permissive_Status : STRUCT 	//Permissive status
   Bit00 : BOOL ;	//Bit #00
   Bit01 : BOOL ;	//Bit #01
   Bit02 : BOOL ;	//Bit #02
   Bit03 : BOOL ;	//Bit #03
   Bit04 : BOOL ;	//Bit #04
   Bit05 : BOOL ;	//Bit #05
   Bit06 : BOOL ;	//Bit #06
   Bit07 : BOOL ;	//Bit #07
   Bit08 : BOOL ;	//Bit #08
   Bit09 : BOOL ;	//Bit #09
   Bit10 : BOOL ;	//Bit #10
   Bit11 : BOOL ;	//Bit #11
   Bit12 : BOOL ;	//Bit #12
   Bit13 : BOOL ;	//Bit #13
   Bit14 : BOOL ;	//Bit #14
   Bit15 : BOOL ;	//Bit #15
   Bit16 : BOOL ;	//Bit #16
   Bit17 : BOOL ;	//Bit #17
   Bit18 : BOOL ;	//Bit #18
   Bit19 : BOOL ;	//Bit #19
   Bit20 : BOOL ;	//Bit #20
   Bit21 : BOOL ;	//Bit #21
   Bit22 : BOOL ;	//Bit #22
   Bit23 : BOOL ;	//Bit #23
   Bit24 : BOOL ;	//Bit #24
   Bit25 : BOOL ;	//Bit #25
   Bit26 : BOOL ;	//Bit #26
   Bit27 : BOOL ;	//Bit #27
   Bit28 : BOOL ;	//Bit #28
   Bit29 : BOOL ;	//Bit #29
   Bit30 : BOOL ;	//Bit #30
   Bit31 : BOOL ;	//Bit #31
  END_STRUCT ;	
  TMP_Permissive_DB_TYPE : BOOL ;	//Output variable is a DB variable
  TMP_OUT_DB : WORD ;	//Output variable DB address
  TMP_OUT_ADDR : DWORD ;	//Output variable address
  TMP_Output : BOOL ;	//Temporary Out
END_VAR
BEGIN
NETWORK
TITLE =OUTPUT VARIABLE MEMORY AREA
// 
      L     P##Permissives_Status; // Load output variable pointer
      LAR1  ; // Load ind.register AR1
      L     W [AR1,P#0.0]; // Get  recipe order DB address
      T     #TMP_OUT_DB; 
      L     W#16#10; // Point to byte 2
      +AR1  ; 
      L     D [AR1,P#0.0]; // Load output variable address
      T     #TMP_OUT_ADDR; 

      A(    ; 
      L     B [AR1,P#0.0]; // Get  output variable memory area type
      L     B#16#85; // Load DI type code
      ==I   ; // IF memory area type is L [local order]
      )     ; 
      O(    ; 
      TAK   ; // Load memory area type
      L     B#16#84; // Load DB type code
      ==I   ; // IF memory area type is I or Q or M
      )     ; 
      =     #TMP_Permissive_DB_TYPE; 
NETWORK
TITLE =PERMISSIVES OUTPUT
//Copy Permissives to output status word
      A     #IN_Permissive_01; 
      =     #TMP_Permissive_Status.Bit01; 
      A     #TMP_Permissive_Status.Bit01; 
      O(    ; 
      A     #IN_Permissive_02; 
      =     #TMP_Permissive_Status.Bit02; 
      A     #TMP_Permissive_Status.Bit02; 
      )     ; 
      O(    ; 
      A     #IN_Permissive_03; 
      =     #TMP_Permissive_Status.Bit03; 
      A     #TMP_Permissive_Status.Bit03; 
      )     ; 
      O(    ; 
      A     #IN_Permissive_04; 
      =     #TMP_Permissive_Status.Bit04; 
      A     #TMP_Permissive_Status.Bit04; 
      )     ; 
      O(    ; 
      A     #IN_Permissive_05; 
      =     #TMP_Permissive_Status.Bit05; 
      A     #TMP_Permissive_Status.Bit05; 
      )     ; 
      O(    ; 
      A     #IN_Permissive_06; 
      =     #TMP_Permissive_Status.Bit06; 
      A     #TMP_Permissive_Status.Bit06; 
      )     ; 
      O(    ; 
      A     #IN_Permissive_07; 
      =     #TMP_Permissive_Status.Bit07; 
      A     #TMP_Permissive_Status.Bit07; 
      )     ; 
      O(    ; 
      A     #IN_Permissive_08; 
      =     #TMP_Permissive_Status.Bit08; 
      A     #TMP_Permissive_Status.Bit08; 
      )     ; 
      O(    ; 
      A     #IN_Permissive_09; 
      =     #TMP_Permissive_Status.Bit09; 
      A     #TMP_Permissive_Status.Bit09; 
      )     ; 
      O(    ; 
      A     #IN_Permissive_10; 
      =     #TMP_Permissive_Status.Bit10; 
      A     #TMP_Permissive_Status.Bit10; 
      )     ; 
      O(    ; 
      A     #IN_Permissive_11; 
      =     #TMP_Permissive_Status.Bit11; 
      A     #TMP_Permissive_Status.Bit11; 
      )     ; 
      O(    ; 
      A     #IN_Permissive_12; 
      =     #TMP_Permissive_Status.Bit12; 
      A     #TMP_Permissive_Status.Bit12; 
      )     ; 
      O(    ; 
      A     #IN_Permissive_13; 
      =     #TMP_Permissive_Status.Bit13; 
      A     #TMP_Permissive_Status.Bit13; 
      )     ; 
      O(    ; 
      A     #IN_Permissive_14; 
      =     #TMP_Permissive_Status.Bit14; 
      A     #TMP_Permissive_Status.Bit14; 
      )     ; 
      O(    ; 
      A     #IN_Permissive_15; 
      =     #TMP_Permissive_Status.Bit15; 
      A     #TMP_Permissive_Status.Bit15; 
      )     ; 
      O(    ; 
      A     #IN_Permissive_16; 
      =     #TMP_Permissive_Status.Bit16; 
      A     #TMP_Permissive_Status.Bit16; 
      )     ; 
      O(    ; 
      A     #IN_Permissive_17; 
      =     #TMP_Permissive_Status.Bit17; 
      A     #TMP_Permissive_Status.Bit17; 
      )     ; 
      O(    ; 
      A     #IN_Permissive_18; 
      =     #TMP_Permissive_Status.Bit18; 
      A     #TMP_Permissive_Status.Bit18; 
      )     ; 
      O(    ; 
      A     #IN_Permissive_19; 
      =     #TMP_Permissive_Status.Bit19; 
      A     #TMP_Permissive_Status.Bit19; 
      )     ; 
      O(    ; 
      A     #IN_Permissive_20; 
      =     #TMP_Permissive_Status.Bit20; 
      A     #TMP_Permissive_Status.Bit20; 
      )     ; 
      O(    ; 
      A     #IN_Permissive_21; 
      =     #TMP_Permissive_Status.Bit21; 
      A     #TMP_Permissive_Status.Bit21; 
      )     ; 
      O(    ; 
      A     #IN_Permissive_22; 
      =     #TMP_Permissive_Status.Bit22; 
      A     #TMP_Permissive_Status.Bit22; 
      )     ; 
      O(    ; 
      A     #IN_Permissive_23; 
      =     #TMP_Permissive_Status.Bit23; 
      A     #TMP_Permissive_Status.Bit23; 
      )     ; 
      O(    ; 
      A     #IN_Permissive_24; 
      =     #TMP_Permissive_Status.Bit24; 
      A     #TMP_Permissive_Status.Bit24; 
      )     ; 
      O(    ; 
      A     #IN_Permissive_25; 
      =     #TMP_Permissive_Status.Bit25; 
      A     #TMP_Permissive_Status.Bit25; 
      )     ; 
      O(    ; 
      A     #IN_Permissive_26; 
      =     #TMP_Permissive_Status.Bit26; 
      A     #TMP_Permissive_Status.Bit26; 
      )     ; 
      O(    ; 
      A     #IN_Permissive_27; 
      =     #TMP_Permissive_Status.Bit27; 
      A     #TMP_Permissive_Status.Bit27; 
      )     ; 
      O(    ; 
      A     #IN_Permissive_28; 
      =     #TMP_Permissive_Status.Bit28; 
      A     #TMP_Permissive_Status.Bit28; 
      )     ; 
      O(    ; 
      A     #IN_Permissive_29; 
      =     #TMP_Permissive_Status.Bit29; 
      A     #TMP_Permissive_Status.Bit29; 
      )     ; 
      O(    ; 
      A     #IN_Permissive_30; 
      =     #TMP_Permissive_Status.Bit30; 
      A     #TMP_Permissive_Status.Bit30; 
      )     ; 
      O(    ; 
      A     #IN_Permissive_31; 
      =     #TMP_Permissive_Status.Bit31; 
      A     #TMP_Permissive_Status.Bit31; 
      )     ; 
      =     #TMP_Output; 
NETWORK
TITLE =PERMISSIVES CUMULATIVE AND

      A     #IN_Permissive_01; 
      A     #IN_Permissive_02; 
      A     #IN_Permissive_03; 
      A     #IN_Permissive_04; 
      A     #IN_Permissive_05; 
      A     #IN_Permissive_06; 
      A     #IN_Permissive_07; 
      A     #IN_Permissive_08; 
      A     #IN_Permissive_09; 
      A     #IN_Permissive_10; 
      A     #IN_Permissive_11; 
      A     #IN_Permissive_12; 
      A     #IN_Permissive_13; 
      A     #IN_Permissive_14; 
      A     #IN_Permissive_15; 
      A     #IN_Permissive_16; 
      A     #IN_Permissive_17; 
      A     #IN_Permissive_18; 
      A     #IN_Permissive_19; 
      A     #IN_Permissive_20; 
      A     #IN_Permissive_21; 
      A     #IN_Permissive_22; 
      A     #IN_Permissive_23; 
      A     #IN_Permissive_24; 
      A     #IN_Permissive_25; 
      A     #IN_Permissive_26; 
      A     #IN_Permissive_27; 
      A     #IN_Permissive_28; 
      A     #IN_Permissive_29; 
      A     #IN_Permissive_30; 
      A     #IN_Permissive_31; 
      =     #TMP_Permissive_Status.Bit00; 
      A     #TMP_Permissive_Status.Bit00; 
      SAVE  ; 
NETWORK
TITLE =PERMISSIVE STATUS

      L     P##TMP_Permissive_Status; 
      LAR1  ; 
      L     LD [AR1,P#0.0]; 
      CAD   ; 
      AN    #TMP_Permissive_DB_TYPE; 
      JC    N_DB; 
      OPN   DB [#TMP_OUT_DB]; 
N_DB: NOP   0; 
      L     #TMP_OUT_ADDR; 
      LAR1  ; 
      TAK   ; 
      T     D [AR1,P#0.0]; // Output variable updating
END_FUNCTION

FUNCTION "SYC_FC_LOW_PASS_FILTER" : VOID
TITLE =Real time low_band pass filter function
//################################################################################
//#                  Real time low_band pass filter function                     #
//################################################################################
//This software is sold with the expressed agreement that the information therein 
//contained is the property of DANIELI AUTOMATION S.p.A.  No part of this 
//software 
//may be duplicated, installed, copied or otherwise used directly or indirectly 
//for uses other than those stated in the contract. 
//This software may not be used in whole or in part to assist third parties in 
//developing new softwares or to supply information for developing new softwares, 
//or may not be duplicated or used to develop new softwares or parts thereof 
//without specific previous written authorization by DANIELI AUTOMATION S.p.A. 
//The acceptance of this software will be construed as an acceptance of the 
//foregoing agreement.
//
//Function name    : SYC_FC_LOW_PASS_FILTER
//
//Revisions history
//
//+--------------------------------------------------------------------------+
//! 5 !        !                               !              !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 4 !        !                               !              !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 3 !11/12/02!For revision                   !D.Comar       !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 2 !07/05/02!For revision                   !D.Comar       !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 1 !   02/99!For issue step7                !L.Orsettig    !              !
//+---+--------+-------------------------------+--------------+--------------!
//!Rev!Date    !Description                    !Drawn         !Checked       !
//+--------------------------------------------------------------------------+
//
//Revision hystory : R 1.0 Issue
//                   R 2.0 Code correction: 
//                   R 1.0 was:
//                   L     #TMP_Speed_Time     
//                   L     #IN_Clock 
//                   <=R   
//                   JC    LIM
//
//                   R 2.0 is:
//                   L     #TMP_Speed_Time
//                   L     #IN_Clock      
//                   ITD                  
//                   DTR                  
//                   <=R   
//                   JC    LIM
//                   The input parameter "IN_Clock" is now defined like INT 
//                   variable.
//                   R 3.0 The PLC real time clock "IN_Clock" variable 
//                         format is changed from INT to REAL.
//
//Function         : This block is used to filter the 'IN_Value' variable;
//                   result is the output structure:
//
//
//
//Parameters       : IN_Value           = Input variable to be filtered
//                   IN_Time_Constant   = Filter time constant
//                   IN_Clock           = PLC execution time
//                   OUT_Filter         = Output structure
//
//OUT_Filter structure
//STRUCT
//          value        INTFiltered value
//          value_realREALFiltered value real format
//END_STRUCT
//
//
//
//Used DB          : None
//
//
//Used Flags       : None
//
//Used prog.block  : None
//
//
//Remarks          :
//
AUTHOR : DA_Lib
VERSION : 0.0


VAR_INPUT
  IN_Value : REAL ;	//Input variable to be filtered
  IN_Time_Constant : REAL ;	//Filter time constant
  IN_Clock : REAL ;	//PLC execution time
END_VAR
VAR_OUTPUT
  OUT_value : INT ;	//Filtered value
END_VAR
VAR_IN_OUT
  IN_OUT_value_real : REAL ;	//Filtered value real format
END_VAR
VAR_TEMP
  TMP_Speed_Time : REAL ;	//Time constant * speed constant value
END_VAR
BEGIN
NETWORK
TITLE =FILTER  FUNCTION
//Filtering routine
//
      L     #IN_Time_Constant; // * Speed constant
      L     1.412538e+000; 
      /R    ; 
      T     #TMP_Speed_Time; 
//;                                     // ********************************
      L     #TMP_Speed_Time; // * Min filter constant limitation
      L     #IN_Clock; //   PLC execution time
      <=R   ; 
      JC    LIM; 
      TAK   ; 
LIM:  T     #TMP_Speed_Time; //   Filter constant
//;                                     // ********************************
      L     #IN_Value; //   Not filtered value
      L     #IN_OUT_value_real; //   Filtered value
      -R    ; 
      L     #IN_Clock; //   PLC execution time
      *R    ; 
      L     #TMP_Speed_Time; 
      /R    ; 
//;                                     // ********************************
      L     #IN_OUT_value_real; 
      +R    ; 
      JO    OVER; 
      T     #IN_OUT_value_real; 
      RND   ; //   Convert from REAL to DINT
      T     #OUT_value; //   Output updating
//;                                     // ********************************
      JU    END; 
//;                                     // ********************************
OVER: NOP   0; //   If Overflow than filter is bypassed
      L     #IN_Value; 
      T     #IN_OUT_value_real; 
END:  NOP   0; // ********************************
NETWORK
TITLE =FUNCTION RETURN
//  
      SET   ; 
      SAVE  ; 
END_FUNCTION

FUNCTION "SYC_FC_GET_DB_POINTER" : VOID
TITLE =GET DB MEMORY POINTER
//################################################################################
//#                     GET DB MEMORY POINTER                                    #
//################################################################################
//This software is sold with the expressed agreement that the information therein 
//contained is the property of DANIELI AUTOMATION s.p.a.It will not be 
//reproduced, 
//installed, copied or otherwise disposed or directly or indirectly for different 
//uses than the scope of this contract, and will not be used, in whole or in 
//part,to assist in making or to furnish information for the use of the software, 
//or other reproductions hereof, or for the making of software or parts thereof, 
//except upon written permission of DANIELI AUTOMATION s.p.a., obtained and 
//specific to each case. The acceptance of this software will be constructed as 
//an acceptance of the foregoing agreement.
//
//Function name    : SYC_FC_GET_DB_POINTER
//
//Revisions history
//
//+--------------------------------------------------------------------------+
//! 5 !        !                               !              !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 4 !        !                               !              !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 3 !        !                               !              !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 2 !19/12/03!For Revision                   !D.Comar       !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 1 !15/12/97!For issue step7                !D.Comar       !              !
//+---+--------+-------------------------------+--------------+--------------!
//!Rev!Date    !Description                    !Drawn         !Checked       !
//+--------------------------------------------------------------------------+
//
//Revision hystory : R 1.0 Issue
//                   R 2.0 With this revision the function can generate not
//                         only DB/DI pointers, but pointers also to    the
//                         peripheral area, input area and output area.
//
//Function         : 
//
//Parameters       : See vars allocation table
//
//Used DB          : None
//
//Used Flags       : None
// 
//Used prog.block  : None
//
//Remarks          :
//
//
AUTHOR : DA_Lib
VERSION : 0.1


VAR_INPUT
  IN_Source : POINTER ;	//Data in pointer format
END_VAR
VAR_OUTPUT
  OUT_DB_PNT : WORD ;	//DB pointer or variable pointer in 16 BITS format
  OUT_DB_ADDR_PNT : DWORD ;	//Variable pointer in 32 BITS format
END_VAR
VAR_TEMP
  TMP_TYPE : BYTE ;	//Area type [80= P-81= I-82= Q-83= M-84= DB-85= DI-86= L-87=stack]
  TMP_DB_Source : WORD ;	//Source DB memory area
  TMP_Source_Address : DWORD ;	//Source memory area address
END_VAR
BEGIN
NETWORK
TITLE =INITIALIZATION OF POINTERS
// 
      L     L#0; 
      T     #TMP_DB_Source; 
      T     #TMP_Source_Address; 
NETWORK
TITLE =GET VARIABLE POINTER
// 
      L     P##IN_Source; // Load source pointer
      LAR1  ; // Load ind.register AR1
      L     W [AR1,P#0.0]; // Get source DB address
      T     #TMP_DB_Source; 
      L     W#16#10; // Point to byte 2
      +AR1  ; 
      L     B [AR1,P#0.0]; // Get source memory area type
      L     B#16#85; // Load DI type code
      >I    ; // IF memory area type is P or I or Q or M or DB or DI
      JC    RES; // THEN continue
      TAK   ; // ELSE jump to exit
      L     B#16#80; 
      <I    ; 
      JC    RES; 
      L     D [AR1,P#0.0]; // Get    source memory area address
      T     #TMP_Source_Address; // Update source memory area address
NETWORK
TITLE =GET VARIABLE POINTER
// 
      L     B [AR1,P#0.0]; // Get source memory area type
      L     B#16#83; 
      >I    ; // IF memory area type is P or I or Q or M
      JC    BYPS; 
      L     D [AR1,P#0.0]; 
      SRD   3; 
      T     #TMP_DB_Source; // THEN DB pointer is used as variable pointer in 16 BITS format
BYPS: NOP   0; 
NETWORK
TITLE =TRANSFER DATA TO OUTPUT
//In case of successful the RLO is setted to 1 else it's ressetted
      L     #TMP_DB_Source; 
      T     #OUT_DB_PNT; 
      L     #TMP_Source_Address; 
      T     #OUT_DB_ADDR_PNT; 
NETWORK
TITLE =FUNCTION OUTPUT
// 
      SET   ; 
      JU    EXIT; 
RES:  CLR   ; 
EXIT: SAVE  ; 
END_FUNCTION

