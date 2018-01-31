MODULE MOD_LoadBalance_Vars
!===================================================================================================================================
! Variables needed for the evaluation of the record points
!===================================================================================================================================
! MODULES
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
PUBLIC
SAVE
!-----------------------------------------------------------------------------------------------------------------------------------
! GLOBAL VARIABLES 
!-----------------------------------------------------------------------------------------------------------------------------------
LOGICAL                             :: DoLoadBalance                              ! DoLoadBalance
LOGICAL                             :: InitLoadBalanceIsDone                      ! switch for checking

! time measurement
REAL,ALLOCATABLE                    :: tTotal(:)                                  ! time measurement over whole dt_analyze 
REAL,ALLOCATABLE                    :: LoadSum(:)                                 ! sum of load per step over whole dt_analyze 
REAL,ALLOCATABLE                    :: tCurrent(:)                                ! time measurement over one step
                                                                                  !  1 -tDG
                                                                                  !  2 -tDGComm
                                                                                  !  3 -tPML
                                                                                  !  4 -tEmission
                                                                                  !  5 -tTrack
                                                                                  !  6 -tInterpolation
                                                                                  !  7 -tDeposition
                                                                                  !  8 -tDSMC
                                                                                  !  9 -tPush
                                                                                  ! 10 -tPartComm
                                                                                  ! 11 -tSplit&Merge
                                                                                  ! 12 -UNFP
                                                                                  ! 13 -DGAnalyze
                                                                                  ! 14 -PartAnalyze

! counter
REAL(KIND=8)                        :: nTotalParts                                ! number of particles in time of tTotal
INTEGER                             :: nLoadIter                                  ! number of load iter 
!INTEGER                             :: nCurrentParts                              ! number of current particles
INTEGER                             :: nLoadBalance                               ! number of load balances
INTEGER                             :: nLoadBalanceSteps                          ! number of performed  load balances steps
REAL,ALLOCATABLE                    :: LoadDistri(:)                              ! Weighted load distribution of all procs
INTEGER,ALLOCATABLE                 :: PartDistri(:)                              ! Part distribution of all procs
INTEGER                             :: PartWeightMethod                           ! method to compute the particle weight
INTEGER                             :: WeightAverageMethod                        ! method to average the particle weight
                                                                                  ! (1: iter, 2: dt_Analyze)
                                                                                  ! nSkipAnalyze is greater than 1
REAL                                :: MaxWeight                                  ! Maximum Weight of proc on domain
REAL                                :: MinWeight                                  ! Minimum Weight of proc on domain
REAL                                :: CurrentImbalance
REAL                                :: NewImbalance                               ! Imbalance after rebalance step
!-----------------------------------------------------------------------------------------------------------------------------------
! particle load balancing
!-----------------------------------------------------------------------------------------------------------------------------------
INTEGER                             :: nSkipAnalyze                               ! Skip Analyze-Dt
REAL                                :: ParticleMPIWeight
REAL                                :: DeviationThreshold                         ! threshold for load-balancing
LOGICAL                             :: writePartitionInfo                         ! write partitioninfo file
REAL                                :: WeightSum                                  ! global sum of all weights
REAL                                :: targetWeight                               ! optimal weight for each proc
!-----------------------------------------------------------------------------------------------------------------------------------
! Element Local measurement
!-----------------------------------------------------------------------------------------------------------------------------------
REAL                                :: tCartMesh                                  ! time for CartMesh deposition
REAL                                :: tTracking                                  ! time for relocation of particles
REAL,ALLOCATABLE                    :: ElemTime(:)
REAL,ALLOCATABLE                    :: ElemGlobalTime(:)
INTEGER(KIND=8),ALLOCATABLE         :: nPartsPerElem(:)
INTEGER(KIND=8),ALLOCATABLE         :: nDeposPerElem(:)
INTEGER(KIND=8),ALLOCATABLE         :: nTracksPerElem(:)


END MODULE MOD_LoadBalance_Vars
