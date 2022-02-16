FUNCTION "IFM_VSE_STATE" : VOID
TITLE =ifm VSE150 State-byte

//################################################################################
//#                        ifm DEVICE VSE150 - READ STATE                        #
//################################################################################
//
//Revisions history
//+--------------------------------------------------------------------------+
//! 2 !        !                               !              !              !
//+---+--------+-------------------------------+--------------+--------------!
//! 1 !16/02/22!ISSUE                          ! Leonardo     !              !
//+---+--------+-------------------------------+--------------+--------------!
//!Rev!Date    !Description                    !Drawn         !Checked       !
//+--------------------------------------------------------------------------+
//
//Function         : This block reads the state of the VSE150 device. 
//                      (Alarm) state of the object 
//                      0: OK 
//                      1: warning alarm 
//                      2: damage alarm 
//                      3: inactive 
//                      4: error
//
//Calling block    : ANY
//
//Used DB          : 
//                     
//Used Flags       : 
// 
//Used prog.block  : 
//
//Remarks          :


AUTHOR : Leonardo
FAMILY : ASSETMNG
NAME : VSE_ST
VERSION : 1.0


VAR_INPUT
  IB_State : BYTE ;	//Input State-byte
END_VAR
VAR_OUTPUT
  O_OK : BOOL ;	//Output signal status OK
  O_Warning_Alarm : BOOL ;	
  O_Damage_Alarm : BOOL ;	//Output signal status damage alarm
  O_Inactive : BOOL ;	//Output device inactive
  O_Error : BOOL ;	//Output device error event has appeared
END_VAR
VAR_TEMP
  TW_Flag : WORD ;	
END_VAR
BEGIN
NETWORK
TITLE =

      L     #IB_State; 
      T     #TW_Flag; 

// 0: OK 
      L     #TW_Flag; 
      L     0; 
      ==I   ; 
      =     #O_OK; 

// 1: warning alarm 
      L     #TW_Flag; 
      L     1; 
      ==I   ; 
      =     #O_Warning_Alarm; 

// 2: damage alarm 
      L     #TW_Flag; 
      L     2; 
      ==I   ; 
      =     #O_Damage_Alarm; 

      L     #TW_Flag; 

// 3: inactive
      L     3; 
      ==I   ; 
      =     #O_Inactive; 

// 4: error
      L     #TW_Flag; 
      L     4; 
      ==I   ; 
      =     #O_Error; 

      SET   ; 
      SAVE  ; 
END_FUNCTION

