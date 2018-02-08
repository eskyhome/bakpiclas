MODULE MOD_Restart_Vars
!===================================================================================================================================
! Contains global variables used by the restart module
!===================================================================================================================================
! MODULES
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
PUBLIC
SAVE
!-----------------------------------------------------------------------------------------------------------------------------------
! GLOBAL VARIABLES 
!-----------------------------------------------------------------------------------------------------------------------------------
REAL,ALLOCATABLE   :: Vdm_GaussNRestart_GaussN(:,:)! for interpolation from restart grid to computation grid
INTEGER            :: nVar_Restart
INTEGER            :: N_Restart = 0
INTEGER            :: nElems_Restart
LOGICAl            :: RestartInitIsDone   = .FALSE.
LOGICAl            :: DoRestart           = .FALSE.
LOGICAl            :: BuildNewMesh        = .TRUE.
LOGICAl            :: WriteNewMesh        = .TRUE.
LOGICAL            :: InterpolateSolution =.FALSE.
CHARACTER(LEN=300) :: RestartFile
CHARACTER(LEN=255) :: NodeType_Restart
REAL               :: RestartTime
!===================================================================================================================================
END MODULE MOD_Restart_Vars
