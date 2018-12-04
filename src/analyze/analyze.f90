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

MODULE MOD_Analyze
!===================================================================================================================================
! Contains DG analyze 
!===================================================================================================================================
! MODULES
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
PRIVATE
!===================================================================================================================================
! GLOBAL VARIABLES 
!-----------------------------------------------------------------------------------------------------------------------------------
! Private Part ---------------------------------------------------------------------------------------------------------------------
! Public Part ----------------------------------------------------------------------------------------------------------------------
!===================================================================================================================================

! GLOBAL VARIABLES 
INTERFACE InitAnalyze
  MODULE PROCEDURE InitAnalyze
END INTERFACE

INTERFACE FinalizeAnalyze
  MODULE PROCEDURE FinalizeAnalyze
END INTERFACE

INTERFACE CalcError
  MODULE PROCEDURE CalcError
END INTERFACE

INTERFACE AnalyzeToFile
  MODULE PROCEDURE AnalyzeToFile
END INTERFACE

INTERFACE PerformAnalyze
  MODULE PROCEDURE PerformAnalyze
END INTERFACE

!===================================================================================================================================
PUBLIC:: InitAnalyze, FinalizeAnalyze, PerformAnalyze 
!===================================================================================================================================
PUBLIC::DefineParametersAnalyze

CONTAINS

!==================================================================================================================================
!> Define parameters 
!==================================================================================================================================
SUBROUTINE DefineParametersAnalyze()
! MODULES
USE MOD_ReadInTools ,ONLY: prms
!USE MOD_AnalyzeEquation ,ONLY: DefineParametersAnalyzeEquation
IMPLICIT NONE
!==================================================================================================================================
CALL prms%SetSection("Analyze")
CALL prms%CreateLogicalOption('DoCalcErrorNorms' , 'Set true to compute L2 and LInf error norms at analyze step.','.FALSE.')
CALL prms%CreateRealOption(   'Analyze_dt'       , 'Specifies time intervall at which analysis routines are called.','0.')
CALL prms%CreateIntOption(    'NAnalyze'         , 'Polynomial degree at which analysis is performed (e.g. for L2 errors).\n'//&
                                                   'Default: 2*N.')
CALL prms%CreateRealOption(   'OutputTimeFixed'  , 'fixed time for writing state to .h5','-1.0')
CALL prms%CreateIntOption(    'nSkipAnalyze'     , '(Skip Analyze-Dt)')
CALL prms%CreateLogicalOption('CalcTimeAverage'  , 'Flag if time averaging should be performed')
CALL prms%CreateStringOption( 'VarNameAvg'       , 'Count of time average variables',multiple=.TRUE.)
CALL prms%CreateStringOption( 'VarNameFluc'      , 'Count of fluctuation variables',multiple=.TRUE.)
CALL prms%CreateIntOption(    'nSkipAvg'         , 'Iter every which CalcTimeAverage is performed')
!CALL prms%CreateLogicalOption('AnalyzeToFile',   "Set true to output result of error norms to a file (DoCalcErrorNorms=T)",&
                                                 !'.FALSE.')
!CALL prms%CreateIntOption(    'nWriteData' ,     "Intervall as multiple of Analyze_dt at which HDF5 files "//&
                                                 !"(e.g. State,TimeAvg,Fluc) are written.",&
                                                 !'1')
!CALL prms%CreateIntOption(    'AnalyzeExactFunc',"Define exact function used for analyze (e.g. for computing L2 errors). "//&
                                                 !"Default: Same as IniExactFunc")
!CALL prms%CreateIntOption(    'AnalyzeRefState' ,"Define state used for analyze (e.g. for computing L2 errors). "//&
                                                 !"Default: Same as IniRefState")
!CALL prms%CreateLogicalOption('doMeasureFlops',  "Set true to measure flop count, if compiled with PAPI.",&
                                                 !'.TRUE.')
!CALL DefineParametersAnalyzeEquation()
#ifdef CODE_ANALYZE
CALL prms%CreateLogicalOption( 'DoCodeAnalyzeOutput' , 'print code analyze info to CodeAnalyze.csv','.TRUE.')
#endif /* CODE_ANALYZE */
CALL prms%CreateIntOption(      'Field-AnalyzeStep'   , 'Analyze is performed each Nth time step','1') 
CALL prms%CreateLogicalOption(  'CalcPotentialEnergy', 'Calculate Potential Energy. Output file is Database.csv','.FALSE.')
CALL prms%CreateLogicalOption(  'CalcPointsPerWavelength', 'Flag to compute the points per wavelength in each cell','.FALSE.')

CALL prms%SetSection("Analyzefield")
CALL prms%CreateIntOption(    'PoyntingVecInt-Planes', 'Total number of Poynting vector integral planes for measuring the '//&
                                                       'directed power flow (energy flux density: Density and direction of an '//&
                                                       'electromagnetic field.', '0')
CALL prms%CreateRealOption(   'Plane-Tolerance'      , 'Absolute tolerance for checking the Poynting vector integral plane '//&
                                                       'coordinates and normal vectors of the corresponding sides for selecting '//&
                                                       'relevant sides', '1E-5')
CALL prms%CreateRealOption(   'Plane-[$]-x-coord'      , 'TODO-DEFINE-PARAMETER', '0.', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(   'Plane-[$]-y-coord'      , 'TODO-DEFINE-PARAMETER', '0.', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(   'Plane-[$]-z-coord'      , 'TODO-DEFINE-PARAMETER', '0.', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(   'Plane-[$]-factor'       , 'TODO-DEFINE-PARAMETER', '1.', numberedmulti=.TRUE.)
CALL prms%CreateIntOption(    'PoyntingMainDir'        , 'Direction in which the Poynting vector integral is to be measured. '//& 
                                                         '\n1: x \n2: y \n3: z (default)')

END SUBROUTINE DefineParametersAnalyze

SUBROUTINE InitAnalyze()
!===================================================================================================================================
! Initializes variables necessary for analyse subroutines
!===================================================================================================================================
! MODULES
USE MOD_Globals
USE MOD_Preproc
USE MOD_Interpolation_Vars    ,ONLY: xGP,wBary,InterpolationInitIsDone
USE MOD_Analyze_Vars          ,ONLY: Nanalyze,AnalyzeInitIsDone,Analyze_dt,DoCalcErrorNorms,CalcPoyntingInt
USE MOD_Analyze_Vars          ,ONLY: CalcPointsPerWavelength,PPWCell,OutputTimeFixed,FieldAnalyzeStep
USE MOD_Analyze_Vars          ,ONLY: AnalyzeCount,AnalyzeTime
USE MOD_ReadInTools           ,ONLY: GETINT,GETREAL
USE MOD_AnalyzeField          ,ONLY: GetPoyntingIntPlane
USE MOD_ReadInTools           ,ONLY: GETLOGICAL
USE MOD_Analyze_Vars          ,ONLY: doFieldAnalyze,CalcEpot
USE MOD_LoadBalance_Vars      ,ONLY: nSkipAnalyze
USE MOD_TimeAverage_Vars      ,ONLY: doCalcTimeAverage
USE MOD_TimeAverage           ,ONLY: InitTimeAverage
USE MOD_IO_HDF5               ,ONLY: AddToElemData,ElementOut
USE MOD_Mesh_Vars             ,ONLY: nElems
USE MOD_Particle_Mesh_Vars    ,ONLY: GEO
#ifdef maxwell
USE MOD_Equation_vars         ,ONLY: Wavelength
#endif /* maxwell */
USE MOD_TimeDisc_Vars         ,ONLY: TEnd
USE MOD_ReadInTools           ,ONLY: PrintOption
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
CHARACTER(LEN=40)   :: DefStr
INTEGER             :: iElem
REAL                :: PPWCellMax,PPWCellMin
!===================================================================================================================================
IF ((.NOT.InterpolationInitIsDone).OR.AnalyzeInitIsDone) THEN
  CALL abort(&
      __STAMP__&
      ,'InitAnalyse not ready to be called or already called.',999,999.)
  RETURN
END IF
SWRITE(UNIT_StdOut,'(132("-"))')
SWRITE(UNIT_stdOut,'(A)') ' INIT ANALYZE...'

! Get logical for calculating the error norms L2 and LInf
DoCalcErrorNorms = GETLOGICAL('DoCalcErrorNorms' ,'.FALSE.')

! Set the default analyze polynomial degree NAnalyze to 2*(N+1) 
WRITE(DefStr,'(i4)') 2*(PP_N+1)
NAnalyze = GETINT('NAnalyze',DefStr) 
CALL InitAnalyzeBasis(PP_N,NAnalyze,xGP,wBary)

! Get the time step for performing analyzes and integer for skipping certain steps
WRITE(DefStr,WRITEFORMAT) TEnd
Analyze_dt        = GETREAL('Analyze_dt',DefStr)
nSkipAnalyze      = GETINT('nSkipAnalyze','1')
OutputTimeFixed   = GETREAL('OutputTimeFixed','-1.0')
doCalcTimeAverage = GETLOGICAL('CalcTimeAverage'  ,'.FALSE.')
IF(doCalcTimeAverage)  CALL InitTimeAverage()

FieldAnalyzeStep  = GETINT('Field-AnalyzeStep','1') 
IF (FieldAnalyzeStep.EQ.0) FieldAnalyzeStep = HUGE(FieldAnalyzeStep) 
DoFieldAnalyze    = .FALSE. 
CalcEpot          = GETLOGICAL('CalcPotentialEnergy','.FALSE.') 
IF(CalcEpot)        DoFieldAnalyze = .TRUE. 
IF(CalcPoyntingInt) DoFieldAnalyze = .TRUE.

! initialize time and counter for analyze measurement
AnalyzeCount = 0
AnalyzeTime  = 0.0

AnalyzeInitIsDone = .TRUE.
SWRITE(UNIT_stdOut,'(A)')' INIT ANALYZE DONE!'
SWRITE(UNIT_StdOut,'(132("-"))')

! init Poynting-Integral
IF(CalcPoyntingInt) CALL GetPoyntingIntPlane()

! Points Per Wavelength
CalcPointsPerWavelength = GETLOGICAL('CalcPointsPerWavelength'  ,'.FALSE.')
IF(CalcPointsPerWavelength)THEN
  ! calculate cell local number excluding neighbor DOFs
  ALLOCATE( PPWCell(1:PP_nElems) )
  PPWCell=0.0
  CALL AddToElemData(ElementOut,'PPWCell',RealArray=PPWCell(1:PP_nElems))
  ! Calculate PPW for each cell
#ifdef maxwell
  CALL PrintOption('Wavelength for PPWCell','OUTPUT',RealOpt=Wavelength)
#else
  CALL PrintOption('Wavelength for PPWCell (fixed to 1.0)','OUTPUT',RealOpt=1.0)
#endif /* maxwell */
  PPWCellMin=HUGE(1.)
  PPWCellMax=-HUGE(1.)
  DO iElem = 1, nElems
#ifdef maxwell
    PPWCell(iElem)     = (REAL(PP_N)+1.)*Wavelength/GEO%CharLength(iElem)
#else
    PPWCell(iElem)     = (REAL(PP_N)+1.)/GEO%CharLength(iElem)
#endif /* maxwell */
    PPWCellMin=MIN(PPWCellMin,PPWCell(iElem))
    PPWCellMax=MAX(PPWCellMax,PPWCell(iElem))
  END DO ! iElem = 1, nElems
#ifdef MPI
  IF(MPIroot)THEN
    CALL MPI_REDUCE(MPI_IN_PLACE , PPWCellMin , 1 , MPI_DOUBLE_PRECISION , MPI_MIN , 0 , MPI_COMM_WORLD , iError)
    CALL MPI_REDUCE(MPI_IN_PLACE , PPWCellMax , 1 , MPI_DOUBLE_PRECISION , MPI_MAX , 0 , MPI_COMM_WORLD , iError)
  ELSE
    CALL MPI_REDUCE(PPWCellMin   , 0          , 1 , MPI_DOUBLE_PRECISION , MPI_MIN , 0 , MPI_COMM_WORLD , iError)
    CALL MPI_REDUCE(PPWCellMax   , 0          , 1 , MPI_DOUBLE_PRECISION , MPI_MAX , 0 , MPI_COMM_WORLD , iError)
    ! in this case the receive value is not relevant. 
  END IF
#endif /*MPI*/
  CALL PrintOption('MIN(PPWCell)','CALCUL.',RealOpt=PPWCellMin)
  CALL PrintOption('MAX(PPWCell)','CALCUL.',RealOpt=PPWCellMax)
END IF
END SUBROUTINE InitAnalyze


SUBROUTINE InitAnalyzeBasis(N_in,Nanalyze_in,xGP,wBary)
!===================================================================================================================================
! Initializes variables necessary for analyse subroutines
!===================================================================================================================================
! MODULES
USE MOD_Analyze_Vars, ONLY:wAnalyze,Vdm_GaussN_NAnalyze
USE MOD_Basis,        ONLY: LegendreGaussNodesAndWeights,LegGaussLobNodesAndWeights,BarycentricWeights,InitializeVandermonde
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
INTEGER,INTENT(IN)                         :: N_in,Nanalyze_in
REAL,INTENT(IN),DIMENSION(0:N_in)          :: xGP,wBary
!----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
REAL ,DIMENSION(0:Nanalyze_in) :: XiAnalyze
!===================================================================================================================================
  ALLOCATE(wAnalyze(0:NAnalyze_in),Vdm_GaussN_NAnalyze(0:NAnalyze_in,0:N_in))
  CALL LegGaussLobNodesAndWeights(NAnalyze_in,XiAnalyze,wAnalyze)
  CALL InitializeVandermonde(N_in,NAnalyze_in,wBary,xGP,XiAnalyze,Vdm_GaussN_NAnalyze)
END SUBROUTINE InitAnalyzeBasis


SUBROUTINE CalcError(time,L_2_Error,L_Inf_Error)
!===================================================================================================================================
! Calculates L_infinfity and L_2 norms of state variables using the Analyze Framework (GL points+weights)
!===================================================================================================================================
! MODULES
USE MOD_Globals
USE MOD_PreProc
USE MOD_Mesh_Vars          ,ONLY: Elem_xGP,sJ
USE MOD_Equation_Vars      ,ONLY: IniExactFunc
USE MOD_Analyze_Vars       ,ONLY: NAnalyze,Vdm_GaussN_NAnalyze,wAnalyze
USE MOD_DG_Vars            ,ONLY: U
USE MOD_Equation           ,ONLY: ExactFunc
USE MOD_ChangeBasis        ,ONLY: ChangeBasis3D
USE MOD_Particle_Mesh_Vars ,ONLY: GEO
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
REAL,INTENT(IN)               :: time
!----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
REAL,INTENT(OUT)              :: L_2_Error(PP_nVar)   !< L2 error of the solution
REAL,INTENT(OUT)              :: L_Inf_Error(PP_nVar) !< LInf error of the solution
!----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES 
INTEGER                       :: iElem,k,l,m
REAL                          :: U_exact(PP_nVar)
REAL                          :: U_NAnalyze(1:PP_nVar,0:NAnalyze,0:NAnalyze,0:NAnalyze)
REAL                          :: Coords_NAnalyze(3,0:NAnalyze,0:NAnalyze,0:NAnalyze)
REAL                          :: J_NAnalyze(1,0:NAnalyze,0:NAnalyze,0:NAnalyze)
REAL                          :: J_N(1,0:PP_N,0:PP_N,0:PP_N)
REAL                          :: IntegrationWeight
!===================================================================================================================================
L_Inf_Error(:)=-1.E10
L_2_Error(:)=0.
! Interpolate values of Error-Grid from GP's
DO iElem=1,PP_nElems
   ! Interpolate the physical position Elem_xGP to the analyze position, needed for exact function
   CALL ChangeBasis3D(3,PP_N,NAnalyze,Vdm_GaussN_NAnalyze,Elem_xGP(1:3,:,:,:,iElem),Coords_NAnalyze(1:3,:,:,:))
   ! Interpolate the Jacobian to the analyze grid: be carefull we interpolate the inverse of the inverse of the jacobian ;-)
   J_N(1,0:PP_N,0:PP_N,0:PP_N)=1./sJ(:,:,:,iElem)
   CALL ChangeBasis3D(1,PP_N,NAnalyze,Vdm_GaussN_NAnalyze,J_N(1:1,0:PP_N,0:PP_N,0:PP_N),J_NAnalyze(1:1,:,:,:))
   ! Interpolate the solution to the analyze grid
   CALL ChangeBasis3D(PP_nVar,PP_N,NAnalyze,Vdm_GaussN_NAnalyze,U(1:PP_nVar,:,:,:,iElem),U_NAnalyze(1:PP_nVar,:,:,:))
   DO m=0,NAnalyze
     DO l=0,NAnalyze
       DO k=0,NAnalyze
#ifdef PP_HDG
         CALL ExactFunc(IniExactFunc,Coords_NAnalyze(1:3,k,l,m),U_exact,ElemID=iElem)
#else
         CALL ExactFunc(IniExactFunc,time,0,Coords_NAnalyze(1:3,k,l,m),U_exact)
#endif
         L_Inf_Error = MAX(L_Inf_Error,abs(U_NAnalyze(:,k,l,m) - U_exact))
         IntegrationWeight = wAnalyze(k)*wAnalyze(l)*wAnalyze(m)*J_NAnalyze(1,k,l,m)
         ! To sum over the elements, We compute here the square of the L_2 error
         L_2_Error = L_2_Error+(U_NAnalyze(:,k,l,m) - U_exact)*(U_NAnalyze(:,k,l,m) - U_exact)*IntegrationWeight
       END DO ! k
     END DO ! l
   END DO ! m
END DO ! iElem=1,PP_nElems
#ifdef MPI
  IF(MPIroot)THEN
    CALL MPI_REDUCE(MPI_IN_PLACE , L_2_Error   , PP_nVar , MPI_DOUBLE_PRECISION , MPI_SUM , 0 , MPI_COMM_WORLD , iError)
    CALL MPI_REDUCE(MPI_IN_PLACE , L_Inf_Error , PP_nVar , MPI_DOUBLE_PRECISION , MPI_MAX , 0 , MPI_COMM_WORLD , iError)
  ELSE
    CALL MPI_REDUCE(L_2_Error   , 0            , PP_nVar , MPI_DOUBLE_PRECISION , MPI_SUM , 0 , MPI_COMM_WORLD , iError)
    CALL MPI_REDUCE(L_Inf_Error , 0            , PP_nVar , MPI_DOUBLE_PRECISION , MPI_MAX , 0 , MPI_COMM_WORLD , iError)
    ! in this case the receive value is not relevant. 
  END IF
#endif /*MPI*/

! We normalize the L_2 Error with the Volume of the domain and take into account that we have to use the square root
L_2_Error = SQRT(L_2_Error/GEO%MeshVolume)

END SUBROUTINE CalcError

SUBROUTINE AnalyzeToFile(time,CalcTime,L_2_Error)
!===================================================================================================================================
! Writes the L2-error norms to file.
!===================================================================================================================================
! MODULES
USE MOD_Globals
USE MOD_Preproc
USE MOD_Analyze_Vars
USE MOD_TimeDisc_Vars ,ONLY:iter
USE MOD_Globals_Vars  ,ONLY:ProjectName
USE MOD_Mesh_Vars    ,ONLY:nGlobalElems
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
REAL,INTENT(IN)                :: time                         ! physical time
REAL,INTENT(IN)                :: CalcTime                     ! computational time
REAL,INTENT(IN)                :: L_2_Error(PP_nVar)           ! L2 error norms
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES 
!REAL                           :: Dummyreal(PP_nVar+1),Dummytime  ! Dummy values for file handling
INTEGER                        :: openStat! File IO status
CHARACTER(LEN=50)              :: formatStr                    ! format string for the output and Tecplot header
CHARACTER(LEN=30)              :: L2name(PP_nVar)              ! variable name for the Tecplot header
CHARACTER(LEN=300)             :: Filename                     ! Output filename,
!LOGICAL                        :: fileExists                   ! Error handler for file
INTEGER                        :: ioUnit
!===================================================================================================================================
Filename = 'out.'//TRIM(ProjectName)//'.dat'
! Check for file
! INQUIRE(FILE = Filename, EXIST = fileExists) ! now -> FILEEXISTS(Filename)
! FILEEXISTS(Filename)
!! File processing starts here open old and extract information or create new file.
ioUnit=1746 ! This number must be fixed?
  OPEN(UNIT   = ioUnit       ,&
       FILE   = Filename     ,&
       STATUS = 'Unknown'    ,&
       ACCESS = 'SEQUENTIAL' ,&
       IOSTAT = openStat                 )
  IF (openStat.NE.0) THEN
     WRITE(*,*)'ERROR: cannot open Outfile'
  END IF
  ! Create a new file with the Tecplot (ASCII file, not binary) header etc.
  WRITE(ioUnit,*)'TITLE="Analysis,'//TRIM(ProjectName)//'"'
  WRITE(ioUnit,'(A12)')'VARIABLES ='
  ! Fill the formatStr and L2name strings
  CALL getVARformatStr(formatStr,L2name)
  WRITE(ioUnit,formatStr)'"timesteps"',L2name,' "t_sim" "t_CPU" "DOF" "Ncells" "nProcs"'
  WRITE(ioUnit,*) 'ZONE T="Analysis,'//TRIM(ProjectName)//'"'

! Create format string for the variable output
WRITE(formatStr,'(A10,I1,A37)')'(E23.14E5,',PP_nVar,'(1X,E23.14E5),4(1X,E23.14E5),2X,I6.6)'
WRITE(ioUnit,formatstr) REAL(iter),L_2_Error(:),TIME,CalcTime-StartTime, &
                 REAL(nGlobalElems*(PP_N+1)**3),REAL(nGlobalElems),nProcessors

CLOSE(ioUnit) ! outputfile
END SUBROUTINE AnalyzeToFile

SUBROUTINE getVARformatStr(VARformatStr,L2name)
!===================================================================================================================================
! This creates the format string for writeAnalyse2file
!===================================================================================================================================
! MODULES
  USE MOD_Globals
  USE MOD_Equation_Vars,ONLY:StrVarNames
! IMPLICIT VARIABLE HANDLING
  IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
  ! CALC%varName: Name of conservative variables
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
  CHARACTER(LEN=30) :: L2name(PP_nVar) ! The name of the Tecplot variables
  CHARACTER(LEN=50) :: VARformatStr ! L2name format string
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES 
  INTEGER           :: i ! counter
!===================================================================================================================================
DO i=1,PP_nVar
  WRITE(L2name(i),'(A5,A,A2)')' "L2_',TRIM(StrVarNames(i)),'" '
END DO
WRITE(VARformatStr,'(A3)')'(A,'
DO i=1,PP_nVar
  WRITE(VARformatStr,'(A,A1,I2,A1)')TRIM(VARformatStr),'A',LEN_TRIM(L2name(i)),','
END DO
WRITE(VARformatStr,'(A,A2)')TRIM(VARformatStr),'A)'
END SUBROUTINE getVARformatStr

SUBROUTINE FinalizeAnalyze()
!===================================================================================================================================
! Finalizes variables necessary for analyse subroutines
!===================================================================================================================================
! MODULES
USE MOD_Analyze_Vars
USE MOD_AnalyzeField,     ONLY:FinalizePoyntingInt
USE MOD_TimeAverage_Vars, ONLY:doCalcTimeAverage
USE MOD_TimeAverage,      ONLY:FinalizeTimeAverage
! IMPLICIT VARIABLE HANDLINGDGInitIsDone
IMPLICIT NONE
!----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
!===================================================================================================================================
SDEALLOCATE(Vdm_GaussN_NAnalyze)
SDEALLOCATE(wAnalyze)
IF(CalcPoyntingInt) CALL FinalizePoyntingInt()
IF(doCalcTimeAverage) CALL FinalizeTimeAverage
AnalyzeInitIsDone = .FALSE.
END SUBROUTINE FinalizeAnalyze


SUBROUTINE PerformAnalyze(OutputTime,FirstOrLastIter,OutPutHDF5)
!===================================================================================================================================
! Check if the analyze subroutines are called depending on the input parameters
! Input parameters
! 1) OutputTime
!    * current time of analyze analze
! 2) FirstOrLastIter
!    * logical flag for first or last iteration
!      This step is required for the correct opening and closing of a *.csv Database. Furthermore it is needed to prevent
!      duplicates from the *.csv Database file
! 3) OutPutHDF5
!    * OutputHDF5 is ture if a state file is written
! The perform-analyze routine is called four times within the timedisc 
! 1) initialize before the first iteration. call is performed for an initial computation and a restart
! 2) after the time update
! 3) during an analyze step and writing of a state file
! 4) during a load-balance step
! This routine calls all other analyze-subroutines, which write data to a csv file 
! Currently this are:
! I)    AnalyzeField             ->  FieldAnalyze.csv
! II)   AnalyzeParticles         ->  PartAnalyze.csv
! III)  AnalyzeSurface           ->  SurfaceDatabase.csv
! IV)   TrackParticlePosition    ->  ParticlePosition.csv
! V)    AnalyticParticleMovement ->  ParticlePositionAnalytic.csv
!===================================================================================================================================
! MODULES
USE MOD_Globals
USE MOD_Preproc
USE MOD_Analyze_Vars           ,ONLY: CalcPoyntingInt,DoFieldAnalyze,DoCalcErrorNorms,OutputErrorNorms,FieldAnalyzeStep
USE MOD_Analyze_Vars           ,ONLY: AnalyzeCount,AnalyzeTime
USE MOD_Restart_Vars           ,ONLY: DoRestart
USE MOD_TimeDisc_Vars          ,ONLY: iter,tEnd
USE MOD_RecordPoints           ,ONLY: RecordPoints
USE MOD_LoadDistribution       ,ONLY: WriteElemTimeStatistics
USE MOD_Globals_Vars           ,ONLY: ProjectName
USE MOD_AnalyzeField           ,ONLY: AnalyzeField
#ifdef PARTICLES
USE MOD_Mesh_Vars              ,ONLY: MeshFile
USE MOD_TimeDisc_Vars          ,ONLY: dt
USE MOD_Particle_Vars          ,ONLY: WriteMacroVolumeValues,WriteMacroSurfaceValues,MacroValSamplIterNum,PartSurfaceModel
USE MOD_Analyze_Vars           ,ONLY: DoSurfModelAnalyze
USE MOD_Particle_Analyze       ,ONLY: AnalyzeParticles,CalculatePartElemData,WriteParticleTrackingData
USE MOD_Particle_Analyze_Vars  ,ONLY: PartAnalyzeStep,DoPartAnalyze,TrackParticlePosition
USE MOD_SurfaceModel_Analyze_Vars,ONLY: SurfaceAnalyzeStep
USE MOD_SurfaceModel_Analyze   ,ONLY: AnalyzeSurface
USE MOD_DSMC_Vars              ,ONLY: DSMC, iter_macvalout,iter_macsurfvalout
USE MOD_DSMC_Vars              ,ONLY: DSMC_HOSolution
USE MOD_Particle_Tracking_vars ,ONLY: ntracks,tTracking,tLocalization,MeasureTrackTime
USE MOD_LD_Analyze             ,ONLY: LD_data_sampling, LD_output_calc
USE MOD_Particle_Analyze_Vars  ,ONLY: PartAnalyzeStep
#if !defined(LSERK)
USE MOD_DSMC_Vars              ,ONLY: useDSMC
#endif
#if (PP_TimeDiscMethod!=1000) && (PP_TimeDiscMethod!=1001)
USE MOD_Particle_Vars          ,ONLY: PartSurfaceModel
USE MOD_Particle_Boundary_Vars ,ONLY: AnalyzeSurfCollis, CalcSurfCollis
USE MOD_Particle_Boundary_Vars ,ONLY: SurfMesh, SampWall
USE MOD_DSMC_Analyze           ,ONLY: DSMCHO_data_sampling, WriteDSMCHOToHDF5
USE MOD_DSMC_Analyze           ,ONLY: CalcSurfaceValues
#endif
#if (PP_TimeDiscMethod!=42) && !defined(LSERK)
USE MOD_LD_Vars                ,ONLY: useLD
USE MOD_Particle_Vars          ,ONLY: DelayTime
#endif /*PP_TimeDiscMethod!=42 && !defined(LSERK)*/
#endif /*PARTICLES*/
#if (PP_nVar>=6)
USE MOD_AnalyzeField           ,ONLY: CalcPoyntingIntegral
#endif /*PP_nVar>=6*/
#if defined(LSERK) ||  defined(IMPA) || defined(ROS)
USE MOD_RecordPoints_Vars      ,ONLY: RP_onProc
#endif /*defined(LSERK) ||  defined(IMPA) || defined(ROS)*/
#ifdef CODE_ANALYZE
USE MOD_Particle_Surfaces_Vars ,ONLY: rTotalBBChecks,rTotalBezierClips,SideBoundingBoxVolume,rTotalBezierNewton
USE MOD_Particle_Analyze       ,ONLY: AnalyticParticleMovement
USE MOD_PICInterpolation_Vars  ,ONLY: DoInterpolationAnalytic
#endif /*CODE_ANALYZE*/
#if USE_LOADBALANCE
USE MOD_LoadBalance_tools      ,ONLY: LBStartTime,LBPauseTime
#endif /*USE_LOADBALANCE*/
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
REAL,INTENT(IN)               :: OutputTime
LOGICAL,INTENT(IN)            :: FirstOrLastIter
LOGICAL,INTENT(IN)            :: OutputHDF5
!----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
#ifdef maxwell
LOGICAL                       :: ProlongToFaceNeeded
#endif /*Maxwell*/
#ifdef PARTICLES
#if (PP_TimeDiscMethod!=1000) && (PP_TimeDiscMethod!=1001)
INTEGER                       :: iSide
#endif
#ifdef MPI
INTEGER                       :: RECI
REAL                          :: RECR
#endif /*MPI*/
#endif /*PARTICLES*/
#ifdef CODE_ANALYZE
REAL                          :: TotalSideBoundingBoxVolume,rDummy
#ifdef PARTICLES
REAL                          :: PartStateAnalytic(1:6)        !< analytic position and velocity in three dimensions
#endif /*PARTICLES*/
#endif /*CODE_ANALYZE*/
LOGICAL                       :: LastIter
REAL                          :: L_2_Error(PP_nVar)
REAL                          :: L_Inf_Error(PP_nVar)
#if USE_LOADBALANCE
REAL                          :: tLBStart ! load balance
#endif /*USE_LOADBALANCE*/
REAL                          :: StartAnalyzeTime,EndAnalyzeTime
CHARACTER(LEN=40)             :: formatStr
LOGICAL                       :: DoPerformFieldAnalyze
LOGICAL                       :: DoPerformPartAnalyze
LOGICAL                       :: DoPerformSurfaceAnalyze
LOGICAL                       :: DoPerformErrorCalc
!===================================================================================================================================

! Create .csv file for performance analysis and load balance: write header line
CALL WriteElemTimeStatistics(WriteHeader=.TRUE.,iter=iter)

StartAnalyzeTime=PICLASTIME()
AnalyzeCount = AnalyzeCount + 1

! check if final/last iteration iteration
LastIter=.FALSE.
IF(OutputHDF5 .AND. FirstOrLastIter) LastIter=.TRUE.

!----------------------------------------------------------------------------------------------------------------------------------
! Determine if an analyze step has to be performed
! selection is identical with/without particles
!----------------------------------------------------------------------------------------------------------------------------------
! The initial selection is performed for DoPerformAnalyze and copied to the other analyzes. 
! The iteration dependent steps are performed later

! Prolongtoface in CalcPoyntingIntegral is always needed, because analyze is not any more performed within the first
! RK stage
#ifdef maxwell
ProlongToFaceNeeded=.TRUE.
#endif /*maxwell*/

! 1)
! Initial start of computation before the first iteration
! this check is identical for all time integration methods
! analyze routines are not called for a restart
! PO: not sure if it this check is any longer needed
IF(FirstOrLastIter)THEN
  DoPerformFieldAnalyze   =.TRUE.
  DoPerformPartAnalyze    =.TRUE.
  DoPerformSurfaceAnalyze =.TRUE.
ELSE
  ! nullify
  DoPerformFieldAnalyze   =.FALSE.
  DoPerformPartAnalyze    =.FALSE.
  DoPerformSurfaceAnalyze =.FALSE.
END IF


! 2) check analyze with respect to iteration counter
! selection criterion depending on iteration counter
! * full stage Runge-Kutta schemes
! * LSERK schemes (because analyze is not hidden in RK stage)
! * DSMC

! FieldAnalyzeStep
! 2) normal analyze at analyze step 
IF(MOD(iter,FieldAnalyzeStep).EQ.0 .AND. .NOT. OutPutHDF5) DoPerformFieldAnalyze=.TRUE.
! 3) + 4) force analyze during a write-state information and prevent duplicates
IF(MOD(iter,FieldAnalyzeStep).NE.0 .AND. OutPutHDF5)       DoPerformFieldAnalyze=.TRUE.
! Remove analyze during restart or load-balance step 
IF(DoRestart .AND. iter.EQ.0) DoPerformFieldAnalyze=.FALSE.
! Finally, remove duplicates for last iteration
! This step is needed, because PerformAnalyze is called twice within the iterations
IF(FirstOrLastIter .AND. .NOT.OutPutHDF5 .AND.iter.NE.0) DoPerformFieldAnalyze=.FALSE.

#ifdef PARTICLES
! PartAnalyzeStep
! 2) normal analyze at analyze step 
IF(MOD(iter,PartAnalyzeStep).EQ.0 .AND. .NOT. OutPutHDF5) DoPerformPartAnalyze=.TRUE.
! 3) + 4) force analyze during a write-state information and prevent duplicates
IF(MOD(iter,PartAnalyzeStep).NE.0 .AND. OutPutHDF5)       DoPerformPartAnalyze=.TRUE.
! Remove analyze during restart or load-balance step 
IF(DoRestart .AND. iter.EQ.0) DoPerformPartAnalyze=.FALSE.
! Finally, remove duplicates for last iteration
! This step is needed, because PerformAnalyze is called twice within the iterations
IF(FirstOrLastIter .AND. .NOT.OutPutHDF5 .AND.iter.NE.0) DoPerformPartAnalyze=.FALSE.

! SurfaceAnalyzeStep
! 2) normal analyze at analyze step 
IF(MOD(iter,SurfaceAnalyzeStep).EQ.0 .AND. .NOT. OutPutHDF5) DoPerformSurfaceAnalyze=.TRUE.
! 3) + 4) force analyze during a write-state information and prevent duplicates
IF(MOD(iter,SurfaceAnalyzeStep).NE.0 .AND. OutPutHDF5)       DoPerformSurfaceAnalyze=.TRUE.
! Remove analyze during restart or load-balance step 
IF(DoRestart .AND. iter.EQ.0) DoPerformSurfaceAnalyze=.FALSE.
! Finally, remove duplicates for last iteration
! This step is needed, because PerformAnalyze is called twice within the iterations
IF(FirstOrLastIter .AND. .NOT.OutPutHDF5 .AND.iter.NE.0) DoPerformSurfaceAnalyze=.FALSE.
#endif /*PARTICLES*/

! selection of error calculation for first iteration, output time but not lastiteration
DoPerformErrorCalc=.FALSE.
IF(FirstOrLastIter.OR.OutputHDF5)THEN
  IF(.NOT.LastIter) DoPerformErrorCalc=.TRUE.
END IF

!----------------------------------------------------------------------------------------------------------------------------------
! DG-Solver
!----------------------------------------------------------------------------------------------------------------------------------
! Calculate error norms
! This computes the error analysis during each dt_Analysis step
IF(DoCalcErrorNorms) THEN
  IF(DoPerformErrorCalc)THEN
    OutputErrorNorms=.TRUE.
    CALL CalcError(OutputTime,L_2_Error,L_Inf_Error)
    IF (OutputTime.GE.tEnd) CALL AnalyzeToFile(OutputTime,StartAnalyzeTime,L_2_Error)
  END IF
END IF

! the following analysis are restricted to Runge-Kutta based time-discs and temporal varying electrodynamic fields
#if defined(LSERK) || defined(IMPA) || defined(ROS)

!----------------------------------------------------------------------------------------------------------------------------------
! Maxwell's equation: Compute Poynting Vector and field energies
!----------------------------------------------------------------------------------------------------------------------------------
IF (DoFieldAnalyze) THEN
  IF(DoPerformFieldAnalyze) CALL AnalyzeField(OutputTime)
END IF

!----------------------------------------------------------------------------------------------------------------------------------
! Recordpoints buffer
! Only usable with 
! maxwell or poissan in combination with HDG
!----------------------------------------------------------------------------------------------------------------------------------
! remove duplicate analysis  due to double call of PerformAnalysis
IF(RP_onProc) THEN
  ! for a restart, an initial analysis at t=tRestart is necessary to
  ! compute fill the HDF5 file correctly 
  ! Information to time in HDF5-Format:
  ! file1: 0 :t1
  ! file2: t1:tend
  ! Hence, t1 and the fields are stored in both files
  IF(DoPerformFieldAnalyze.OR.iter.EQ.0)THEN
#if USE_LOADBALANCE
    CALL LBStartTime(tLBStart) ! Start time measurement
#endif /*USE_LOADBALANCE*/
    CALL RecordPoints(OutputTime,OutputHDF5)
#if USE_LOADBALANCE
    CALL LBPauseTime(LB_DGANALYZE,tLBStart)
#endif /*USE_LOADBALANCE*/
  END IF
END IF

! end the analyzes for  all Runge-Kutta besed time-discs
#endif /* LSERK && IMPA && ROS */

!----------------------------------------------------------------------------------------------------------------------------------
! PIC, DSMC and other Particle-based Solvers
!----------------------------------------------------------------------------------------------------------------------------------
#ifdef PARTICLES
IF (DoPartAnalyze) THEN
  IF(DoPerformPartAnalyze)    CALL AnalyzeParticles(OutputTime)
END IF
IF (DoSurfModelAnalyze) THEN
  IF(DoPerformSurfaceAnalyze) CALL AnalyzeSurface(OutputTime)
END IF
IF(TrackParticlePosition) THEN
  IF(DoPerformPartAnalyze) CALL WriteParticleTrackingData(OutputTime,iter) ! new function
END IF
#ifdef CODE_ANALYZE
IF(DoInterpolationAnalytic)THEN
  IF(DoPerformPartAnalyze) CALL AnalyticParticleMovement(OutputTime,iter)
END IF
#endif /*CODE_ANALYZE*/
#endif /*PARTICLES*/

#ifdef PARTICLES
! OutPutHDF5 should be sufficient here
IF(OutPutHDF5 .OR. FirstOrLastIter) CALL CalculatePartElemData()
#endif /*PARTICLES*/

!----------------------------------------------------------------------------------------------------------------------------------
! DSMC & LD 
!----------------------------------------------------------------------------------------------------------------------------------
! update of time here
#ifdef PARTICLES
#if USE_LOADBALANCE
CALL LBStartTime(tLBStart) ! Start time measurement
#endif /*USE_LOADBALANCE*/

! write volume data for DSMC macroscopic values 
IF ((WriteMacroVolumeValues).AND.(.NOT.OutputHDF5))THEN
#if (PP_TimeDiscMethod==1000)
  CALL LD_data_sampling()  ! Data sampling for output
#elif(PP_TimeDiscMethod==1001)
  CALL LD_DSMC_data_sampling()
#else
  CALL DSMCHO_data_sampling()
#endif
  IF (iter.GT.0) iter_macvalout = iter_macvalout + 1
  IF (MacroValSamplIterNum.LE.iter_macvalout) THEN
#if (PP_TimeDiscMethod==1000)
    CALL LD_output_calc()  ! Data sampling for output
#elif(PP_TimeDiscMethod==1001)
    CALL LD_DSMC_output_calc()
#else
    CALL WriteDSMCHOToHDF5(TRIM(MeshFile),OutputTime)
#endif
    iter_macvalout = 0
    DSMC%SampNum = 0
    DSMC_HOSolution = 0.0
    IF(DSMC%CalcQualityFactors) THEN
      DSMC%QualityFacSamp(:,:) = 0.
    END IF
  END IF
END IF

! write surface data for DSMC macroscopic values 
IF ((WriteMacroSurfaceValues).AND.(.NOT.OutputHDF5))THEN
  IF (iter.GT.0) iter_macsurfvalout = iter_macsurfvalout + 1
  IF (MacroValSamplIterNum.LE.iter_macsurfvalout) THEN
#if (PP_TimeDiscMethod!=1000) && (PP_TimeDiscMethod!=1001)
    CALL CalcSurfaceValues
    DO iSide=1,SurfMesh%nTotalSides 
      SampWall(iSide)%State=0.
      IF (PartSurfaceModel.GT.0) THEN
        SampWall(iSide)%Adsorption=0.
        SampWall(iSide)%Accomodation=0.
        SampWall(iSide)%Reaction=0.
      END IF
    END DO
    IF (CalcSurfCollis%AnalyzeSurfCollis) THEN
      AnalyzeSurfCollis%Data=0.
      AnalyzeSurfCollis%Spec=0
      AnalyzeSurfCollis%BCid=0
      AnalyzeSurfCollis%Number=0
      !AnalyzeSurfCollis%Rate=0.
    END IF
#endif
    iter_macsurfvalout = 0
  END IF
END IF

IF(OutPutHDF5)THEN
#if (PP_TimeDiscMethod==42)
  IF((LastIter).AND.(useDSMC).AND.(.NOT.DSMC%ReservoirSimu)) THEN
    IF (DSMC%NumOutput.GT.0) THEN
      CALL WriteDSMCHOToHDF5(TRIM(MeshFile),OutputTime)
      IF(DSMC%CalcSurfaceVal) CALL CalcSurfaceValues
    END IF
  END IF
#elif defined(LSERK) 
  !additional output after push of final dt (for LSERK output is normally before first stage-push, i.e. actually for previous dt)
  IF(LastIter)THEN
    ! volume data
    IF(WriteMacroVolumeValues)THEN
      iter_macvalout = iter_macvalout + 1
      IF (MacroValSamplIterNum.LE.iter_macvalout) THEN
        CALL WriteDSMCHOToHDF5(TRIM(MeshFile),OutputTime)
        iter_macvalout = 0
        DSMC%SampNum = 0
        DSMC_HOSolution = 0.0
      END IF
    END IF
    ! surface data
    IF (WriteMacroSurfaceValues) THEN
      iter_macsurfvalout = iter_macsurfvalout + 1
      IF (MacroValSamplIterNum.LE.iter_macsurfvalout) THEN
        CALL CalcSurfaceValues
        DO iSide=1,SurfMesh%nTotalSides
          SampWall(iSide)%State=0.
        END DO
        IF (CalcSurfCollis%AnalyzeSurfCollis) THEN
          AnalyzeSurfCollis%Data=0.
          AnalyzeSurfCollis%Spec=0
          AnalyzeSurfCollis%BCid=0
          AnalyzeSurfCollis%Number=0
          !AnalyzeSurfCollis%Rate=0.
        END IF
        iter_macsurfvalout = 0
      END IF
    END IF
  END IF
#else
  IF((LastIter).AND.(useDSMC).AND.(.NOT.WriteMacroVolumeValues).AND.(.NOT.WriteMacroSurfaceValues)) THEN
    IF ((.NOT. useLD).AND.(DSMC%NumOutput.GT.0)) THEN
      CALL WriteDSMCHOToHDF5(TRIM(MeshFile),OutputTime)
    END IF
    IF ((OutputTime.GE.DelayTime).AND.(DSMC%NumOutput.GT.0)) THEN
      IF(DSMC%CalcSurfaceVal) CALL CalcSurfaceValues
    END IF
  END IF
#endif
END IF

! Measure tracking time for particles // no MPI barrier MPI Wall-time but local CPU time
! Allows non-synchronous measurement of particle tracking
IF(OutPutHDF5 .AND. MeasureTrackTime)THEN
#ifdef MPI
  IF(MPIRoot) THEN
    CALL MPI_REDUCE(MPI_IN_PLACE,nTracks      , 1 ,MPI_INTEGER         ,MPI_SUM,0,MPI_COMM_WORLD,IERROR)
    CALL MPI_REDUCE(MPI_IN_PLACE,tTracking    , 1 ,MPI_DOUBLE_PRECISION,MPI_SUM,0,MPI_COMM_WORLD,IERROR)
    CALL MPI_REDUCE(MPI_IN_PLACE,tLocalization, 1 ,MPI_DOUBLE_PRECISION,MPI_SUM,0,MPI_COMM_WORLD,IERROR)
  ELSE ! no Root
    CALL MPI_REDUCE(nTracks      ,RECI,1,MPI_INTEGER         ,MPI_SUM,0,MPI_COMM_WORLD,IERROR)
    CALL MPI_REDUCE(tTracking    ,RECR,1,MPI_DOUBLE_PRECISION,MPI_SUM,0,MPI_COMM_WORLD,IERROR)
    CALL MPI_REDUCE(tLocalization,RECR,1,MPI_DOUBLE_PRECISION,MPI_SUM,0,MPI_COMM_WORLD,IERROR)
  END IF
#endif /*MPI*/
  SWRITE(UNIT_StdOut,'(132("-"))')
  SWRITE(UNIT_stdOut,'(A,I15)')   ' Number of trackings:   ',nTracks
  SWRITE(UNIT_stdOut,'(A,F15.6)') ' Tracking time:         ',tTracking
  SWRITE(UNIT_stdOut,'(A,F15.8)') ' Average Tracking time: ',tTracking/REAL(nTracks)
  SWRITE(UNIT_stdOut,'(A,F15.6)') ' Localization time:     ',tLocalization
  SWRITE(UNIT_StdOut,'(132("-"))')
  nTracks=0
  tTracking=0.
  tLocalization=0.
END IF ! only during output like Doftime
#if USE_LOADBALANCE
CALL LBPauseTime(LB_PARTANALYZE,tLBStart)
#endif /*USE_LOADBALANCE*/
#endif /*PARTICLES*/

!----------------------------------------------------------------------------------------------------------------------------------
! Code Analyze
!----------------------------------------------------------------------------------------------------------------------------------

#ifdef CODE_ANALYZE
! particle analyze
IF (DoPartAnalyze)  THEN
  IF(DoPerformPartAnalyze) CALL CodeAnalyzeOutput(OutputTime) 
  IF(LastIter)THEN
    CALL CodeAnalyzeOutput(OutputTime) 
    SWRITE(UNIT_stdOut,'(A51)') 'CODE_ANALYZE: Following output has been accumulated'
    SWRITE(UNIT_stdOut,'(A35,E15.7)') ' rTotalBBChecks    : ' , rTotalBBChecks
    SWRITE(UNIT_stdOut,'(A35,E15.7)') ' rTotalBezierClips : ' , rTotalBezierClips
    SWRITE(UNIT_stdOut,'(A35,E15.7)') ' rTotalBezierNewton: ' , rTotalBezierNewton
    TotalSideBoundingBoxVolume=SUM(SideBoundingBoxVolume)
#ifdef MPI
    IF(MPIRoot) THEN
      CALL MPI_REDUCE(MPI_IN_PLACE,TotalSideBoundingBoxVolume , 1 , MPI_DOUBLE_PRECISION, MPI_SUM,0, MPI_COMM_WORLD, IERROR)
    ELSE ! no Root
      CALL MPI_REDUCE(TotalSideBoundingBoxVolume,rDummy  ,1,MPI_DOUBLE_PRECISION,MPI_SUM,0,MPI_COMM_WORLD, IERROR)
    END IF
#endif /* MPI */
    SWRITE(UNIT_stdOut,'(A35,E15.7)') ' Total Volume of SideBoundingBox: ' , TotalSideBoundingBoxVolume
  END IF
END IF
#endif /*CODE_ANALYZE*/

! Time for analysis
EndAnalyzeTime=PICLASTIME()
AnalyzeTime = AnalyzeTime + EndAnalyzeTime-StartAnalyzeTime

!----------------------------------------------------------------------------------------------------------------------------------
! Output info
!----------------------------------------------------------------------------------------------------------------------------------
IF(DoPerformErrorCalc)THEN
  IF(DoCalcErrorNorms) THEN
    ! Graphical output
    IF(MPIroot) THEN
      WRITE(formatStr,'(A5,I1,A7)')'(A13,',PP_nVar,'ES16.7)'
      WRITE(UNIT_StdOut,formatStr)' L_2       : ',L_2_Error
      WRITE(UNIT_StdOut,formatStr)' L_inf     : ',L_Inf_Error
    END IF
  END IF
  IF(MPIroot) THEN
    ! write out has to be "Sim time" due to analyzes in reggie. Reggie searches for exactly this tag
    WRITE(UNIT_StdOut,'(A17,ES16.7)')        ' Sim time      : ',OutputTime
    WRITE(UNIT_StdOut,'(A17,ES16.7,A9,I5,A)')' Analyze time  : ',AnalyzeTime, ' (called ',AnalyzeCount,' times)'
    AnalyzeCount = 0
    AnalyzeTime  = 0.0
    IF (OutputTime.GT.0.) THEN
      WRITE(UNIT_StdOut,'(132("."))')
      WRITE(UNIT_stdOut,'(A,A,A,F14.2,A)') ' PICLAS RUNNING ',TRIM(ProjectName),'... [',StartAnalyzeTime-StartTime,' sec ]'
      WRITE(UNIT_StdOut,'(132("-"))')
    ELSE
      WRITE(UNIT_StdOut,'(132("="))')
    END IF
  END IF
END IF

END SUBROUTINE PerformAnalyze

#ifdef CODE_ANALYZE
SUBROUTINE CodeAnalyzeOutput(TIME)
!===================================================================================================================================
! output of code_analyze stuff: costly analyze routines for sanity checks and debugging
!===================================================================================================================================
! MODULES
USE MOD_Globals
USE MOD_Preproc
USE MOD_Analyze_Vars            ,ONLY:DoCodeAnalyzeOutput
USE MOD_Particle_Analyze_Vars   ,ONLY:IsRestart,DoPartAnalyze
USE MOD_Restart_Vars            ,ONLY:DoRestart
USE MOD_Particle_Surfaces_Vars  ,ONLY:rBoundingBoxChecks,rPerformBezierClip,rTotalBBChecks,rTotalBezierClips,rPerformBezierNewton
USE MOD_Particle_Surfaces_Vars  ,ONLY:rTotalBezierNewton
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
REAL,INTENT(IN)     :: Time
!----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
REAL                :: rDummy
LOGICAL             :: isOpen
CHARACTER(LEN=350)  :: outfile
INTEGER             :: unit_index, OutputCounter
!===================================================================================================================================
IF(.NOT.DoCodeAnalyzeOutput) RETURN ! check if the output is to be skipped and return if true

IF ( DoRestart ) THEN
  isRestart = .true.
END IF
IF (DoPartAnalyze) THEN
  !SWRITE(UNIT_StdOut,'(132("-"))')
  !SWRITE(UNIT_stdOut,'(A)') ' PERFORMING PARTICLE ANALYZE...'
  OutputCounter = 2
  unit_index = 555
#ifdef MPI
  IF(MPIROOT)THEN
#endif    /* MPI */
   INQUIRE(UNIT   = unit_index , OPENED = isOpen)
   IF (.NOT.isOpen) THEN
     outfile = 'CodeAnalyze.csv'
     IF (isRestart .and. FILEEXISTS(outfile)) THEN
        OPEN(unit_index,file=TRIM(outfile),position="APPEND",status="OLD")
        !CALL FLUSH (unit_index)
     ELSE
        OPEN(unit_index,file=TRIM(outfile))
        !CALL FLUSH (unit_index)
        !--- insert header
      
        WRITE(unit_index,'(A6,A5)',ADVANCE='NO') 'TIME', ' '
        WRITE(unit_index,'(A1)',ADVANCE='NO') ','
        WRITE(unit_index,'(I3.3,A11)',ADVANCE='NO') OutputCounter,'-nBBChecks     '
          OutputCounter = OutputCounter + 1
        WRITE(unit_index,'(A1)',ADVANCE='NO') ','
        WRITE(unit_index,'(I3.3,A12)',ADVANCE='NO') OutputCounter,'-nBezierClips   '
          OutputCounter = OutputCounter + 1
        WRITE(unit_index,'(A14)') ' ' 
     END IF
   END IF
#ifdef MPI
  END IF
#endif    /* MPI */
  
 ! MPI Communication
#ifdef MPI
  IF(MPIRoot) THEN
    CALL MPI_REDUCE(MPI_IN_PLACE,rBoundingBoxChecks , 1 , MPI_DOUBLE_PRECISION, MPI_SUM,0, MPI_COMM_WORLD, IERROR)
    CALL MPI_REDUCE(MPI_IN_PLACE,rPerformBezierClip, 1 , MPI_DOUBLE_PRECISION, MPI_SUM,0, MPI_COMM_WORLD, IERROR)
    CALL MPI_REDUCE(MPI_IN_PLACE,rPerformBezierNewton, 1 , MPI_DOUBLE_PRECISION, MPI_SUM,0, MPI_COMM_WORLD, IERROR)
  ELSE ! no Root
    CALL MPI_REDUCE(rBoundingBoxChecks,rDummy  ,1,MPI_DOUBLE_PRECISION,MPI_SUM,0,MPI_COMM_WORLD, IERROR)
    CALL MPI_REDUCE(rPerformBezierClip,rDummy,1,MPI_DOUBLE_PRECISION,MPI_SUM,0,MPI_COMM_WORLD, IERROR)
    CALL MPI_REDUCE(rPerformBezierNewton,rDummy,1,MPI_DOUBLE_PRECISION,MPI_SUM,0,MPI_COMM_WORLD, IERROR)
  END IF
#endif /* MPI */
  
#ifdef MPI
   IF(MPIROOT)THEN
#endif    /* MPI */
     WRITE(unit_index,104,ADVANCE='NO') Time
     WRITE(unit_index,'(A1)',ADVANCE='NO') ','
     WRITE(unit_index,104,ADVANCE='NO') rBoundingBoxChecks
     WRITE(unit_index,'(A1)',ADVANCE='NO') ','
     WRITE(unit_index,104,ADVANCE='NO') rPerformBezierClip
     WRITE(unit_index,'(A1)',ADVANCE='NO') ',' 
     WRITE(unit_index,104,ADVANCE='NO') rPerformBezierNewton
     WRITE(unit_index,'(A1)') ' ' 
#ifdef MPI
   END IF
#endif    /* MPI */
  
104    FORMAT (e25.14)

!SWRITE(UNIT_stdOut,'(A)')' PARTCILE ANALYZE DONE!'
!SWRITE(UNIT_StdOut,'(132("-"))')
ELSE
!SWRITE(UNIT_stdOut,'(A)')' NO PARTCILE ANALYZE TO DO!'
!SWRITE(UNIT_StdOut,'(132("-"))')
END IF ! DoPartAnalyze

! nullify and save total number
rTotalBBChecks=rTotalBBChecks+REAL(rBoundingBoxChecks,16)
rBoundingBoxChecks=0.
rTotalBezierClips=rTotalBezierClips+REAL(rPerformBezierClip,16)
rPerformBezierClip=0.
rTotalBezierNewton=rTotalBezierNewton+REAL(rPerformBezierNewton,16)
rPerformBezierNewton=0.

END SUBROUTINE CodeAnalyzeOutput
#endif /*CODE_ANALYZE*/

END MODULE MOD_Analyze
