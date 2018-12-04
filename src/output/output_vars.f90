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
MODULE MOD_Output_Vars
!===================================================================================================================================
! Contains global variables provided by the output routines
!===================================================================================================================================
! MODULES
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
PUBLIC
SAVE
!-----------------------------------------------------------------------------------------------------------------------------------
! GLOBAL VARIABLES 
!-----------------------------------------------------------------------------------------------------------------------------------
INTEGER                      :: NVisu                        ! number of visualisation points is NVisu+1
REAL,ALLOCATABLE             :: Vdm_GaussN_NVisu(:,:)        ! for direct interpolation from computation grid to visu grid
REAL,PARAMETER               :: FileVersion=0.1
CHARACTER(LEN=6),PARAMETER   :: ProgramName='PICLas'
INTEGER                      :: outputFormat=0           ! =0: visualization off, >0 visualize
LOGICAL                      :: OutputInitIsDone=.FALSE.
INTEGER                      :: userblock_len         !< length of userblock file in bytes
INTEGER                      :: userblock_total_len   !< length of userblock file + length of ini-file (with header) in bytes
CHARACTER(LEN=255)           :: UserBlockTmpFile='userblock.tmp' !< name of user block temp file
!===================================================================================================================================
END MODULE MOD_Output_Vars
