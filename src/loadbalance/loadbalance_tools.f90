!==================================================================================================================================
! Copyright (c) 2010 - 2018 Prof. Claus-Dieter Munz and Prof. Stefanos Fasoulas
!
! This file is part of PICLas (gitlab.com/piclas/piclas). PICLas is free software: you can redistribute it and/or modify
! it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3
! of the License, or (at your option) any later version.
!
! PICLas is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty
! of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License v3.0 for more details.
!
! You should have received a copy of the GNU General Public License along with PICLas. If not, see <http://www.gnu.org/licenses/>.
!==================================================================================================================================
#include "piclas.h"

!===================================================================================================================================
!> Module contains the tools for load_balancing
!===================================================================================================================================
MODULE MOD_LoadBalance_Tools
!----------------------------------------------------------------------------------------------------------------------------------
! MODULES
IMPLICIT NONE
PRIVATE
!-----------------------------------------------------------------------------------------------------------------------------------
! GLOBAL VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! Public Part ----------------------------------------------------------------------------------------------------------------------
INTERFACE LBStartTime
  MODULE PROCEDURE LBStartTime
END INTERFACE

INTERFACE LBSplitTime
  MODULE PROCEDURE LBSplitTime
END INTERFACE

INTERFACE LBPauseTime
  MODULE PROCEDURE LBPauseTime
END INTERFACE

INTERFACE LBElemSplitTime
  MODULE PROCEDURE LBElemSplitTime
END INTERFACE

INTERFACE LBElemPauseTime
  MODULE PROCEDURE LBElemPauseTime
END INTERFACE

INTERFACE LBElemPauseTime_avg
  MODULE PROCEDURE LBElemPauseTime_avg
END INTERFACE

PUBLIC::LBStartTime
PUBLIC::LBSplitTime
PUBLIC::LBPauseTime
PUBLIC::LBElemSplitTime
PUBLIC::LBElemPauseTime
PUBLIC::LBElemPauseTime_avg

CONTAINS

SUBROUTINE LBStartTime(tLBStart)
!===================================================================================================================================
!> calculates and sets start time for Loadbalance.
!===================================================================================================================================
! MODULES                                                                                                                          !
!----------------------------------------------------------------------------------------------------------------------------------!
USE MOD_Globals          ,ONLY: LOCALTIME
USE MOD_LoadBalance_Vars ,ONLY: PerformLBSample
!----------------------------------------------------------------------------------------------------------------------------------!
IMPLICIT NONE
! INPUT / OUTPUT VARIABLES 
REAL,INTENT(INOUT)  :: tLBStart
!----------------------------------------------------------------------------------------------------------------------------------!
! OUTPUT VARIABLES
!----------------------------------------------------------------------------------------------------------------------------------!
! LOCAL VARIABLES
!===================================================================================================================================
IF(.NOT. PerformLBSample) RETURN
tLBStart = LOCALTIME() ! LB Time Start
END SUBROUTINE LBStartTime

SUBROUTINE LBSplitTime(LB_index,tLBStart)
!===================================================================================================================================
!> Splits the time and resets LB_start. Adds time to tcurrent(LB_index) for current proc
!===================================================================================================================================
! MODULES                                                                                                                          !
!----------------------------------------------------------------------------------------------------------------------------------!
USE MOD_Globals          ,ONLY: LOCALTIME
USE MOD_LoadBalance_Vars ,ONLY: PerformLBSample,tCurrent
!----------------------------------------------------------------------------------------------------------------------------------!
IMPLICIT NONE
! INPUT / OUTPUT VARIABLES 
INTEGER,INTENT(IN)  :: LB_index
REAL,INTENT(INOUT)  :: tLBStart
!----------------------------------------------------------------------------------------------------------------------------------!
! OUTPUT VARIABLES
!----------------------------------------------------------------------------------------------------------------------------------!
! LOCAL VARIABLES
REAL                :: tLBEnd
!===================================================================================================================================
IF(.NOT. PerformLBSample) RETURN
tLBEnd = LOCALTIME() ! LB Time End
tCurrent(LB_index)=tCurrent(LB_index)+tLBEnd-tLBStart
tLBStart = tLBEnd !LOCALTIME() ! LB Time Start
END SUBROUTINE LBSplitTime

SUBROUTINE LBPauseTime(LB_index,tLBStart)
!===================================================================================================================================
!> calculates end time and adds time to tcurrent(LB_index) for current proc
!> does not reset tLBstart
!===================================================================================================================================
! MODULES                                                                                                                          !
!----------------------------------------------------------------------------------------------------------------------------------!
USE MOD_Globals          ,ONLY: LOCALTIME
USE MOD_LoadBalance_Vars ,ONLY: PerformLBSample,tCurrent
!----------------------------------------------------------------------------------------------------------------------------------!
IMPLICIT NONE
! INPUT / OUTPUT VARIABLES 
INTEGER,INTENT(IN)  :: LB_index
REAL,INTENT(IN)     :: tLBStart
!----------------------------------------------------------------------------------------------------------------------------------!
! OUTPUT VARIABLES
!----------------------------------------------------------------------------------------------------------------------------------!
! LOCAL VARIABLES
REAL                :: tLBEnd
!===================================================================================================================================
IF(.NOT. PerformLBSample) RETURN
tLBEnd = LOCALTIME() ! LB Time End
tCurrent(LB_index)=tCurrent(LB_index)+tLBEnd-tLBStart
END SUBROUTINE LBPauseTime


SUBROUTINE LBElemSplitTime(ElemID,tLBStart)
!===================================================================================================================================
!> Splits the time and resets LB_start. Adds time to Elemtime(ElemID)
!===================================================================================================================================
! MODULES                                                                                                                          !
!----------------------------------------------------------------------------------------------------------------------------------!
USE MOD_Globals          ,ONLY: LOCALTIME
USE MOD_LoadBalance_Vars ,ONLY: ElemTime, PerformLBSample
!----------------------------------------------------------------------------------------------------------------------------------!
IMPLICIT NONE
! INPUT / OUTPUT VARIABLES 
INTEGER,INTENT(IN)  :: ElemID
REAL,INTENT(INOUT)  :: tLBStart
!----------------------------------------------------------------------------------------------------------------------------------!
! OUTPUT VARIABLES
!----------------------------------------------------------------------------------------------------------------------------------!
! LOCAL VARIABLES
REAL                :: tLBEnd
!===================================================================================================================================
IF(.NOT. PerformLBSample) RETURN
tLBEnd = LOCALTIME() ! LB Time End
ElemTime(ELemID)=ElemTime(ElemID)+tLBEnd-tLBStart
tLBStart = tLBEnd !LOCALTIME() ! LB Time Start
END SUBROUTINE LBElemSplitTime

SUBROUTINE LBElemPauseTime(ElemID,tLBStart)
!===================================================================================================================================
!> calculates end time and adds time to Elemtime(ElemID)
!> does not reset tLBstart
!===================================================================================================================================
! MODULES                                                                                                                          !
!----------------------------------------------------------------------------------------------------------------------------------!
USE MOD_Globals          ,ONLY: LOCALTIME
USE MOD_LoadBalance_Vars ,ONLY: ElemTime, PerformLBSample
!----------------------------------------------------------------------------------------------------------------------------------!
IMPLICIT NONE
! INPUT / OUTPUT VARIABLES 
INTEGER,INTENT(IN)  :: ElemID
REAL,INTENT(IN)     :: tLBStart
!----------------------------------------------------------------------------------------------------------------------------------!
! OUTPUT VARIABLES
!----------------------------------------------------------------------------------------------------------------------------------!
! LOCAL VARIABLES
REAL                :: tLBEnd
!===================================================================================================================================
IF(.NOT. PerformLBSample) RETURN
tLBEnd = LOCALTIME() ! LB Time End
ElemTime(ELemID)=ElemTime(ElemID)+tLBEnd-tLBStart
END SUBROUTINE LBElemPauseTime

SUBROUTINE LBElemPauseTime_avg(tLBStart)
!===================================================================================================================================
!> calculates end time and adds time to Elemtime(ElemID)
!> does not reset tLBstart
!===================================================================================================================================
! MODULES                                                                                                                          !
!----------------------------------------------------------------------------------------------------------------------------------!
USE MOD_Globals          ,ONLY: LOCALTIME
USE MOD_LoadBalance_Vars ,ONLY: ElemTime, PerformLBSample
USE MOD_Mesh_Vars        ,ONLY: nElems
!----------------------------------------------------------------------------------------------------------------------------------!
IMPLICIT NONE
! INPUT / OUTPUT VARIABLES 
REAL,INTENT(IN)     :: tLBStart
!----------------------------------------------------------------------------------------------------------------------------------!
! OUTPUT VARIABLES
!----------------------------------------------------------------------------------------------------------------------------------!
! LOCAL VARIABLES
REAL                :: tLBEnd
!===================================================================================================================================
IF(.NOT. PerformLBSample) RETURN
tLBEnd = LOCALTIME() ! LB Time End
ElemTime(:)=ElemTime(:)+(tLBEnd-tLBStart)/nElems
END SUBROUTINE LBElemPauseTime_avg



END MODULE MOD_LoadBalance_Tools
