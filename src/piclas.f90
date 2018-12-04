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

PROGRAM Piclas
!===================================================================================================================================
! Control program of the Piclas code. Initialization of the computation
!===================================================================================================================================
! MODULES
USE MOD_Globals_vars     ,ONLY: InitializationWallTime
USE MOD_Globals
USE MOD_Globals_Vars           ,ONLY: ParameterFile,ParameterDSMCFile
USE MOD_Commandline_Arguments
USE MOD_ReadInTools            ,ONLY: prms,PrintDefaultparameterFile,ExtractparameterFile
USE MOD_Piclas_Init        ,ONLY: InitPiclas,FinalizePiclas
USE MOD_Restart_Vars           ,ONLY: RestartFile
USE MOD_Restart                ,ONLY: Restart
USE MOD_Interpolation          ,ONLY: InitInterpolation
USE MOD_IO_HDF5                ,ONLY: InitIO
USE MOD_TimeDisc               ,ONLY: InitTimeDisc,FinalizeTimeDisc,TimeDisc
USE MOD_MPI                    ,ONLY: InitMPI
USE MOD_RecordPoints_Vars      ,ONLY: RP_Data
USE MOD_Mesh_Vars              ,ONLY: DoSwapMesh
USE MOD_Mesh                   ,ONLY: SwapMesh
#ifdef MPI
USE MOD_LoadBalance            ,ONLY: InitLoadBalance,FinalizeLoadBalance
USE MOD_MPI                    ,ONLY: FinalizeMPI
#endif /*MPI*/
USE MOD_Output                 ,ONLY: InitOutput
USE MOD_Define_Parameters_Init ,ONLY: InitDefineParameters
USE MOD_StringTools            ,ONLY:STRICMP, GetFileExtension
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES 
REAL                    :: Time
LOGICAL                 :: userblockFound
!===================================================================================================================================

CALL InitMPI()

SWRITE(UNIT_stdOut,'(132("="))')
SWRITE(UNIT_stdOut,'(A)')"                                        _______ _________ _______  _        _______  _______ "
SWRITE(UNIT_stdOut,'(A)')"                                       (  ____ )\__   __/(  ____ \( \      (  ___  )(  ____ \"
SWRITE(UNIT_stdOut,'(A)')"                                       | (    )|   ) (   | (    \/| (      | (   ) || (    \/"
SWRITE(UNIT_stdOut,'(A)')"                                       | (____)|   | |   | |      | |      | (___) || (_____ "
SWRITE(UNIT_stdOut,'(A)')"                                       |  _____)   | |   | |      | |      |  ___  |(_____  )"
SWRITE(UNIT_stdOut,'(A)')"                                       | (         | |   | |      | |      | (   ) |      ) |"
SWRITE(UNIT_stdOut,'(A)')"                                       | )      ___) (___| (____/\| (____/\| )   ( |/\____) |"
SWRITE(UNIT_stdOut,'(A)')"                                       |/       \_______/(_______/(_______/|/     \|\_______)"
SWRITE(UNIT_stdOut,'(132(" "))')
SWRITE(UNIT_stdOut,'(A)')"piclas version 1.0.0"
SWRITE(UNIT_stdOut,'(132("="))')

CALL ParseCommandlineArguments()

! Check if the number of arguments is correct
IF ((nArgs.GT.3) .OR. ((nArgs.EQ.0).AND.(doPrintHelp.EQ.0)) ) THEN
  ! Print out error message containing valid syntax
  CALL CollectiveStop(__STAMP__,'ERROR - Invalid syntax. Please use: piclas parameter.ini [DSMC.ini] [restart.h5]'// &
    'or piclas --help [option/section name] to print help for a single parameter, parameter sections or all parameters.')
END IF

CALL InitDefineParameters()

! check for command line argument --help or --markdown
IF (doPrintHelp.GT.0) THEN
  CALL PrintDefaultParameterFile(doPrintHelp.EQ.2, Args(1))
  STOP
END IF

ParameterFile = Args(1)
IF (nArgs.EQ.2) THEN
  ParameterDSMCFile = Args(2)
  IF (STRICMP(GetFileExtension(ParameterFile), "h5")) THEN
    ! Print out error message containing valid syntax
    CALL CollectiveStop(__STAMP__,'ERROR - Invalid syntax. Please use: piclas parameter.ini [DSMC.ini] [restart.h5]'// &
      'or piclas --help [option/section name] to print help for a single parameter, parameter sections or all parameters.')
  END IF
  IF(STRICMP(GetFileExtension(ParameterDSMCFile), "h5")) THEN
    RestartFile = ParameterDSMCFile
    ParameterDSMCFile = '' !'no file found'
  END IF
ELSE IF (nArgs.GT.2) THEN
  ParameterDSMCFile = Args(2)
  RestartFile = Args(3)
  IF (STRICMP(GetFileExtension(ParameterDSMCFile), "h5").OR.STRICMP(GetFileExtension(ParameterFile), "h5")) THEN
    ! Print out error message containing valid syntax
    CALL CollectiveStop(__STAMP__,'ERROR - Invalid syntax. Please use: piclas parameter.ini [DSMC.ini] [restart.h5]'// &
      'or piclas --help [option/section name] to print help for a single parameter, parameter sections or all parameters.')
  END IF
ELSE IF (STRICMP(GetFileExtension(ParameterFile), "h5")) THEN
  ! Print out error message containing valid syntax
  !CALL CollectiveStop(__STAMP__,'ERROR - Invalid syntax. Please use: piclas parameter.ini [DSMC.ini] [restart.h5]'// &
  !  'or piclas --help [option/section name] to print help for a single parameter, parameter sections or all parameters.')
  ParameterFile = ".piclas.ini" 
  CALL ExtractParameterFile(Args(1), ParameterFile, userblockFound)
  IF (.NOT.userblockFound) THEN
    CALL CollectiveStop(__STAMP__, "No userblock found in state file '"//TRIM(Args(1))//"'")
  END IF
  RestartFile = Args(1)
END IF

StartTime=PICLASTIME()
CALL prms%read_options(ParameterFile)
! Measure init duration
Time=PICLASTIME()
SWRITE(UNIT_stdOut,'(132("="))')
SWRITE(UNIT_stdOut,'(A,F14.2,A,I0,A)') ' READING INI DONE! [',Time-StartTime,' sec ] NOW '&
,prms%count_setentries(),' PARAMETERS ARE SET'
SWRITE(UNIT_stdOut,'(132("="))')
! Check if we want to read in DSMC.ini
IF(nArgs.GE.2)THEN
  IF(STRICMP(GetFileExtension(ParameterDSMCFile), "ini")) THEN
    CALL prms%read_options(ParameterDSMCFile,furtherini=.TRUE.)
    ! Measure init duration
    Time=PICLASTIME()
    SWRITE(UNIT_stdOut,'(132("="))')
    SWRITE(UNIT_stdOut,'(A,F14.2,A,I0,A)') ' READING FURTHER INI DONE! [',Time-StartTime,' sec ] NOW '&
    ,prms%count_setentries(),' PARAMETERS ARE SET'
    SWRITE(UNIT_stdOut,'(132("="))')
  END IF
END IF

CALL InitOutput()
CALL InitIO()

CALL InitGlobals()
#ifdef MPI
CALL InitLoadBalance()
#endif /*MPI*/
! call init routines
! Measure init duration
!StartTime=PICLASTIME()

! Initialization
CALL InitInterpolation()
CALL InitTimeDisc()

CALL InitPiclas(IsLoadBalance=.FALSE.)

! Do SwapMesh
IF(DoSwapMesh)THEN
  ! Measure init duration
  Time=PICLASTIME()
  IF(MPIroot)THEN
    Call SwapMesh()
    SWRITE(UNIT_stdOut,'(132("="))')
    SWRITE(UNIT_stdOut,'(A,F14.2,A)') ' SWAPMESH DONE! PICLAS DONE! [',Time-StartTime,' sec ]'
    SWRITE(UNIT_stdOut,'(132("="))')
    STOP
  ELSE
  CALL abort(&
  __STAMP__&
  ,'DO NOT CALL SWAPMESH WITH MORE THAN 1 Procs!',iError,999.)
  END IF
END IF

! RESTART
CALL Restart()

! Measure init duration
Time=PICLASTIME()
InitializationWallTime=Time-StartTime
SWRITE(UNIT_stdOut,'(132("="))')
SWRITE(UNIT_stdOut,'(A,F14.2,A)') ' INITIALIZATION DONE! [',InitializationWallTime,' sec ]'
SWRITE(UNIT_stdOut,'(132("="))')

! Run Simulation
CALL TimeDisc()


!Finalize
CALL FinalizePiclas(IsLoadBalance=.FALSE.)

CALL FinalizeTimeDisc()
! mssing arrays to deallocate
SDEALLOCATE(RP_Data)

!Measure simulation duration
Time=PICLASTIME()

#ifdef MPI
!! and additional required for restart with load balance
!ReadInDone=.FALSE.
!ParticleMPIInitIsDone=.FALSE.
!ParticlesInitIsDone=.FALSE.
CALL FinalizeLoadBalance()
CALL MPI_FINALIZE(iError)
IF(iError .NE. 0) &
  CALL abort(&
  __STAMP__&
  ,'MPI finalize error',iError,999.)
#endif
SWRITE(UNIT_stdOut,'(132("="))')
SWRITE(UNIT_stdOut,'(A,F14.2,A)')  ' PICLAS FINISHED! [',Time-StartTime,' sec ]'
SWRITE(UNIT_stdOut,'(132("="))')

END PROGRAM Piclas

