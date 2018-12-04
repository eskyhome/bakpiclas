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

MODULE MOD_DSMC_Analyze
!===================================================================================================================================
! Module for DSMC Sampling and Output
!===================================================================================================================================
! MODULES
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
PRIVATE

INTERFACE WriteDSMCToHDF5
  MODULE PROCEDURE WriteDSMCToHDF5
END INTERFACE

INTERFACE WriteDSMCHOToHDF5
  MODULE PROCEDURE WriteDSMCHOToHDF5
END INTERFACE

INTERFACE CalcTVib
  MODULE PROCEDURE CalcTVib
END INTERFACE

INTERFACE CalcSurfaceValues
  MODULE PROCEDURE CalcSurfaceValues
END INTERFACE

INTERFACE CalcTelec
  MODULE PROCEDURE CalcTelec
END INTERFACE

INTERFACE CalcTVibPoly
  MODULE PROCEDURE CalcTVibPoly
END INTERFACE

INTERFACE CalcMeanFreePath
  MODULE PROCEDURE CalcMeanFreePath
END INTERFACE

INTERFACE CalcGammaVib
  MODULE PROCEDURE CalcGammaVib
END INTERFACE

INTERFACE CalcInstantTransTemp
  MODULE PROCEDURE CalcInstantTransTemp
END INTERFACE

!-----------------------------------------------------------------------------------------------------------------------------------
! GLOBAL VARIABLES 
!-----------------------------------------------------------------------------------------------------------------------------------
! Private Part ---------------------------------------------------------------------------------------------------------------------
! Public Part ----------------------------------------------------------------------------------------------------------------------
PUBLIC :: DSMCHO_data_sampling, CalcMeanFreePath,WriteDSMCToHDF5
PUBLIC :: CalcTVib, CalcSurfaceValues, CalcTelec, CalcTVibPoly, InitHODSMC, WriteDSMCHOToHDF5, CalcGammaVib
PUBLIC :: CalcInstantTransTemp, CalcWallSample
!===================================================================================================================================

CONTAINS


SUBROUTINE WriteDSMCToHDF5(MeshFileName,OutputTime)
!===================================================================================================================================
! Writes DSMC state values to HDF5
!===================================================================================================================================
! MODULES
USE MOD_Globals
USE MOD_PreProc
USE MOD_io_HDF5
USE MOD_HDF5_output   ,ONLY: WriteArrayToHDF5,WriteAttributeToHDF5,WriteHDF5Header
USE MOD_PARTICLE_Vars ,ONLY: nSpecies
USE MOD_Mesh_Vars     ,ONLY: offsetElem,nGlobalElems
USE MOD_DSMC_Vars     ,ONLY: MacroDSMC, CollisMode, DSMC
USE MOD_Globals_Vars  ,ONLY: ProjectName
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
CHARACTER(LEN=*),INTENT(IN)   :: MeshFileName
REAL,INTENT(IN)               :: OutputTime
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
CHARACTER(LEN=255)            :: FileName,FileString,Statedummy
INTEGER                       :: nVal
!===================================================================================================================================
SWRITE(*,*) ' WRITE DSMCSTATE TO HDF5 FILE...'
FileName=TIMESTAMP(TRIM(ProjectName)//'_DSMCState',OutputTime)
FileString=TRIM(FileName)//'.h5'
CALL OpenDataFile(FileString,create=.TRUE.,single=.FALSE.,readOnly=.FALSE.,communicatorOpt=MPI_COMM_WORLD)
Statedummy = 'DSMCState'
CALL WriteHDF5Header(Statedummy,File_ID)

nVal=nGlobalElems  ! For the MPI case this must be replaced by the global number of elements (sum over all procs)

CALL WriteArrayToHDF5(DataSetName='DSMC_velx', rank=2,&
                      nValGlobal=(/nGlobalElems, nSpecies+1/),&
                      nVal=      (/PP_nElems,    nSpecies+1/),&
                      offset=    (/offsetElem, 0  /),&
                      collective=.TRUE.,  RealArray=MacroDSMC(:,:)%PartV(1))

CALL WriteArrayToHDF5(DataSetName='DSMC_vely', rank=2,&
                      nValGlobal=(/nGlobalElems, nSpecies+1/),&
                      nVal=      (/PP_nElems,    nSpecies+1/),&
                      offset=    (/offsetElem, 0  /),&
                      collective=.TRUE.,  RealArray=MacroDSMC(:,:)%PartV(2))

CALL WriteArrayToHDF5(DataSetName='DSMC_velz', rank=2,&
                      nValGlobal=(/nGlobalElems, nSpecies+1/),&
                      nVal=      (/PP_nElems,    nSpecies+1/),&
                      offset=    (/offsetElem, 0  /),&
                      collective=.TRUE., RealArray=MacroDSMC(:,:)%PartV(3))

CALL WriteArrayToHDF5(DataSetName='DSMC_vel', rank=2,&
                      nValGlobal=(/nGlobalElems, nSpecies+1/),&
                      nVal=      (/PP_nElems,    nSpecies+1/),&
                      offset=    (/offsetElem, 0  /),&
                      collective=.TRUE., RealArray=MacroDSMC(:,:)%PartV(4))

CALL WriteArrayToHDF5(DataSetName='DSMC_velx2', rank=2,&
                      nValGlobal=(/nGlobalElems, nSpecies+1/),&
                      nVal=      (/PP_nElems,    nSpecies+1/),&
                      offset=    (/offsetElem, 0  /),&
                      collective=.TRUE., RealArray=MacroDSMC(:,:)%PartV2(1))

CALL WriteArrayToHDF5(DataSetName='DSMC_vely2', rank=2,&
                      nValGlobal=(/nGlobalElems, nSpecies+1/),&
                      nVal=      (/PP_nElems,    nSpecies+1/),&
                      offset=    (/offsetElem, 0  /),&
                      collective=.TRUE., RealArray=MacroDSMC(:,:)%PartV2(2))

CALL WriteArrayToHDF5(DataSetName='DSMC_velz2', rank=2,&
                      nValGlobal=(/nGlobalElems, nSpecies+1/),&
                      nVal=      (/PP_nElems,    nSpecies+1/),&
                      offset=    (/offsetElem, 0  /),&
                      collective=.TRUE., RealArray=MacroDSMC(:,:)%PartV2(3))

CALL WriteArrayToHDF5(DataSetName='DSMC_tempx', rank=2,&
                      nValGlobal=(/nGlobalElems, nSpecies+1/),&
                      nVal=      (/PP_nElems,    nSpecies+1/),&
                      offset=    (/offsetElem, 0  /),&
                      collective=.TRUE., RealArray=MacroDSMC(:,:)%Temp(1))

CALL WriteArrayToHDF5(DataSetName='DSMC_tempy', rank=2,&
                      nValGlobal=(/nGlobalElems, nSpecies+1/),&
                      nVal=      (/PP_nElems,    nSpecies+1/),&
                      offset=    (/offsetElem, 0  /),&
                      collective=.TRUE., RealArray=MacroDSMC(:,:)%Temp(2))

CALL WriteArrayToHDF5(DataSetName='DSMC_tempz', rank=2,&
                      nValGlobal=(/nGlobalElems, nSpecies+1/),&
                      nVal=      (/PP_nElems,    nSpecies+1/),&
                      offset=    (/offsetElem, 0  /),&
                      collective=.TRUE., RealArray=MacroDSMC(:,:)%Temp(3))

CALL WriteArrayToHDF5(DataSetName='DSMC_temp', rank=2,&
                      nValGlobal=(/nGlobalElems, nSpecies+1/),&
                      nVal=      (/PP_nElems,    nSpecies+1/),&
                      offset=    (/offsetElem, 0  /),&
                      collective=.TRUE., RealArray=MacroDSMC(:,:)%Temp(4))

CALL WriteArrayToHDF5(DataSetName='DSMC_dens', rank=2,&
                      nValGlobal=(/nGlobalElems, nSpecies+1/),&
                      nVal=      (/PP_nElems,    nSpecies+1/),&
                      offset=    (/offsetElem, 0  /),&
                      collective=.TRUE., RealArray=MacroDSMC(:,:)%NumDens)

CALL WriteArrayToHDF5(DataSetName='DSMC_partnum', rank=2,&
                      nValGlobal=(/nGlobalElems, nSpecies+1/),&
                      nVal=      (/PP_nElems,    nSpecies+1/),&
                      offset=    (/offsetElem, 0  /),&
                      collective=.TRUE., RealArray=MacroDSMC(:,:)%PartNum)

IF (DSMC%CalcQualityFactors) THEN
  CALL WriteArrayToHDF5(DataSetName='DSMC_quality', rank=2,&
                      nValGlobal=(/nGlobalElems, 3/),&
                      nVal=      (/PP_nElems,    3/),&
                      offset=    (/offsetElem, 0  /),&
                      collective=.TRUE., RealArray=DSMC%QualityFactors(:,:))
END IF

IF ((CollisMode.EQ.2).OR.(CollisMode.EQ.3)) THEN
  CALL WriteArrayToHDF5(DataSetName='DSMC_tvib', rank=2,&
                        nValGlobal=(/nGlobalElems, nSpecies+1/),&
                        nVal=      (/PP_nElems,    nSpecies+1/),&
                        offset=    (/offsetElem, 0  /),&
                        collective=.TRUE., RealArray=MacroDSMC(:,:)%Tvib)

  CALL WriteArrayToHDF5(DataSetName='DSMC_trot', rank=2,&
                        nValGlobal=(/nGlobalElems, nSpecies+1/),&
                        nVal=      (/PP_nElems,    nSpecies+1/),&
                        offset=    (/offsetElem, 0  /),&
                        collective=.TRUE., RealArray=MacroDSMC(:,:)%Trot)
END IF

IF (DSMC%ElectronicModel) THEN
  CALL WriteArrayToHDF5(DataSetName='DSMC_telec', rank=2,&
                        nValGlobal=(/nGlobalElems, nSpecies+1/),&
                        nVal=      (/PP_nElems,    nSpecies+1/),&
                        offset=    (/offsetElem, 0  /),&
                        collective=.TRUE., RealArray=MacroDSMC(:,:)%Telec)
END IF

CALL WriteAttributeToHDF5(File_ID,'DSMC_nSpecies',1,IntegerScalar=nSpecies)
CALL WriteAttributeToHDF5(File_ID,'DSMC_CollisMode',1,IntegerScalar=CollisMode)
CALL WriteAttributeToHDF5(File_ID,'MeshFile',1,StrScalar=(/TRIM(MeshFileName)/))
CALL WriteAttributeToHDF5(File_ID,'Time',1,RealScalar=OutputTime)

CALL CloseDataFile()

END SUBROUTINE WriteDSMCToHDF5


SUBROUTINE CalcWallSample(PartID,SurfSideID,p,q,Transarray,IntArray,PartTrajectory,alpha,IsSpeciesSwap,AdsorptionEnthalpie&
                          ,locBCID,emission_opt)
!===================================================================================================================================
!> Sample Wall values from Particle collisions
!===================================================================================================================================
! MODULES
USE MOD_Globals                ,ONLY: abort
USE MOD_Particle_Vars
USE MOD_DSMC_Vars              ,ONLY: SpecDSMC, useDSMC
USE MOD_DSMC_Vars              ,ONLY: CollisMode
USE MOD_Particle_Boundary_Vars ,ONLY: SampWall, CalcSurfCollis, AnalyzeSurfCollis
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES            
INTEGER,INTENT(IN)                 :: PartID,SurfSideID,p,q,locBCID
REAL,INTENT(IN)                    :: PartTrajectory(1:3), alpha
REAL,INTENT(IN)                    :: TransArray(1:6) !1-3 trans energies(old,wall,new), 4-6 diff. trans vel. (x,y,z)
REAL,INTENT(IN)                    :: IntArray(1:6) ! 1-6 internal energies (rot-old,rot-wall,rot-new,vib-old,vib-wall,vib-new)
LOGICAL,INTENT(IN)                 :: IsSpeciesSwap
REAL,INTENT(IN)                    :: AdsorptionEnthalpie
LOGICAL,INTENT(IN),OPTIONAL        :: emission_opt
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
!===================================================================================================================================

!----  Sampling for energy (translation) accommodation at walls
SampWall(SurfSideID)%State(1,p,q)= SampWall(SurfSideID)%State(1,p,q) &
                                + TransArray(1) * Species(PartSpecies(PartID))%MacroParticleFactor
SampWall(SurfSideID)%State(2,p,q)= SampWall(SurfSideID)%State(2,p,q) &
                                + TransArray(2) * Species(PartSpecies(PartID))%MacroParticleFactor
SampWall(SurfSideID)%State(3,p,q)= SampWall(SurfSideID)%State(3,p,q) &
                                + TransArray(3) * Species(PartSpecies(PartID))%MacroParticleFactor

!----  Sampling force at walls
SampWall(SurfSideID)%State(10,p,q)= SampWall(SurfSideID)%State(10,p,q) &
    + Species(PartSpecies(PartID))%MassIC * (TransArray(4)) * Species(PartSpecies(PartID))%MacroParticleFactor
SampWall(SurfSideID)%State(11,p,q)= SampWall(SurfSideID)%State(11,p,q) &
    + Species(PartSpecies(PartID))%MassIC * (TransArray(5)) * Species(PartSpecies(PartID))%MacroParticleFactor
SampWall(SurfSideID)%State(12,p,q)= SampWall(SurfSideID)%State(12,p,q) &
    + Species(PartSpecies(PartID))%MassIC * (TransArray(6)) * Species(PartSpecies(PartID))%MacroParticleFactor

IF (useDSMC) THEN
  IF (CollisMode.GT.1) THEN
    IF (PartSurfaceModel.GT.0) THEN
      SampWall(SurfSideID)%Adsorption(1,p,q) = SampWall(SurfSideID)%Adsorption(1,p,q) &
                                        + AdsorptionEnthalpie * Species(PartSpecies(PartID))%MacroParticleFactor
    END IF
    IF (SpecDSMC(PartSpecies(PartID))%InterID.EQ.2) THEN
      !----  Sampling for internal (rotational) energy accommodation at walls
      SampWall(SurfSideID)%State(4,p,q) = SampWall(SurfSideID)%State(4,p,q) &
                                        + IntArray(1) * Species(PartSpecies(PartID))%MacroParticleFactor
      SampWall(SurfSideID)%State(5,p,q) = SampWall(SurfSideID)%State(5,p,q) &
                                        + IntArray(2) * Species(PartSpecies(PartID))%MacroParticleFactor
      SampWall(SurfSideID)%State(6,p,q) = SampWall(SurfSideID)%State(6,p,q) &
                                        + IntArray(3) * Species(PartSpecies(PartID))%MacroParticleFactor

      !----  Sampling for internal (vibrational) energy accommodation at walls
      SampWall(SurfSideID)%State(7,p,q) = SampWall(SurfSideID)%State(7,p,q) &
                                        + IntArray(4) * Species(PartSpecies(PartID))%MacroParticleFactor
      SampWall(SurfSideID)%State(8,p,q) = SampWall(SurfSideID)%State(8,p,q) &
                                        + IntArray(5) * Species(PartSpecies(PartID))%MacroParticleFactor
      SampWall(SurfSideID)%State(9,p,q) = SampWall(SurfSideID)%State(9,p,q) &
                                        + IntArray(6) * Species(PartSpecies(PartID))%MacroParticleFactor
    END IF
  END IF
END IF

! if calcwalsample is called with emission_opt (from particle emission eg. evaporation, desorption) than collision counter are not
! added to sampwall and surfcollis analyzes
IF (PRESENT(emission_opt)) THEN
  IF (.NOT.emission_opt) THEN
    !---- Counter for collisions (normal wall collisions - not to count if only SpeciesSwaps to be counted)
    IF (.NOT.CalcSurfCollis%OnlySwaps .AND. .NOT.IsSpeciesSwap) THEN
      SampWall(SurfSideID)%State(12+PartSpecies(PartID),p,q)= SampWall(SurfSideID)%State(12+PartSpecies(PartID),p,q) + 1
      IF (CalcSurfCollis%AnalyzeSurfCollis .AND. (ANY(AnalyzeSurfCollis%BCs.EQ.0) .OR. ANY(AnalyzeSurfCollis%BCs.EQ.locBCID))) THEN
        AnalyzeSurfCollis%Number(PartSpecies(PartID)) = AnalyzeSurfCollis%Number(PartSpecies(PartID)) + 1
        AnalyzeSurfCollis%Number(nSpecies+1) = AnalyzeSurfCollis%Number(nSpecies+1) + 1
        IF (AnalyzeSurfCollis%Number(nSpecies+1) .GT. AnalyzeSurfCollis%maxPartNumber) THEN
          CALL abort(&
          __STAMP__&
          ,'maxSurfCollisNumber reached!')
        END IF
        AnalyzeSurfCollis%Data(AnalyzeSurfCollis%Number(nSpecies+1),1:3) &
          = LastPartPos(PartID,1:3) + alpha * PartTrajectory(1:3)
        AnalyzeSurfCollis%Data(AnalyzeSurfCollis%Number(nSpecies+1),4) &
          = PartState(PartID,4)
        AnalyzeSurfCollis%Data(AnalyzeSurfCollis%Number(nSpecies+1),5) &
          = PartState(PartID,5)
        AnalyzeSurfCollis%Data(AnalyzeSurfCollis%Number(nSpecies+1),6) &
          = PartState(PartID,6)
        AnalyzeSurfCollis%Data(AnalyzeSurfCollis%Number(nSpecies+1),7) &
          = LastPartPos(PartID,1)
        AnalyzeSurfCollis%Data(AnalyzeSurfCollis%Number(nSpecies+1),8) &
          = LastPartPos(PartID,2)
        AnalyzeSurfCollis%Data(AnalyzeSurfCollis%Number(nSpecies+1),9) &
          = LastPartPos(PartID,3)
        AnalyzeSurfCollis%Spec(AnalyzeSurfCollis%Number(nSpecies+1)) &
          = PartSpecies(PartID)
        AnalyzeSurfCollis%BCid(AnalyzeSurfCollis%Number(nSpecies+1)) &
          = locBCID
      END IF
    END IF
  END IF
ELSE ! no emission_opt present, so definitely not called from emission and counters are added
  !---- Counter for collisions (normal wall collisions - not to count if only SpeciesSwaps to be counted)
  IF (.NOT.CalcSurfCollis%OnlySwaps .AND. .NOT.IsSpeciesSwap) THEN
    SampWall(SurfSideID)%State(12+PartSpecies(PartID),p,q)= SampWall(SurfSideID)%State(12+PartSpecies(PartID),p,q) + 1
    IF (CalcSurfCollis%AnalyzeSurfCollis .AND. (ANY(AnalyzeSurfCollis%BCs.EQ.0) .OR. ANY(AnalyzeSurfCollis%BCs.EQ.locBCID))) THEN
      AnalyzeSurfCollis%Number(PartSpecies(PartID)) = AnalyzeSurfCollis%Number(PartSpecies(PartID)) + 1
      AnalyzeSurfCollis%Number(nSpecies+1) = AnalyzeSurfCollis%Number(nSpecies+1) + 1
      IF (AnalyzeSurfCollis%Number(nSpecies+1) .GT. AnalyzeSurfCollis%maxPartNumber) THEN
        CALL abort(&
        __STAMP__&
        ,'maxSurfCollisNumber reached!')
      END IF
      AnalyzeSurfCollis%Data(AnalyzeSurfCollis%Number(nSpecies+1),1:3) &
        = LastPartPos(PartID,1:3) + alpha * PartTrajectory(1:3)
      AnalyzeSurfCollis%Data(AnalyzeSurfCollis%Number(nSpecies+1),4) &
        = PartState(PartID,4)
      AnalyzeSurfCollis%Data(AnalyzeSurfCollis%Number(nSpecies+1),5) &
        = PartState(PartID,5)
      AnalyzeSurfCollis%Data(AnalyzeSurfCollis%Number(nSpecies+1),6) &
        = PartState(PartID,6)
      AnalyzeSurfCollis%Data(AnalyzeSurfCollis%Number(nSpecies+1),7) &
        = LastPartPos(PartID,1)
      AnalyzeSurfCollis%Data(AnalyzeSurfCollis%Number(nSpecies+1),8) &
        = LastPartPos(PartID,2)
      AnalyzeSurfCollis%Data(AnalyzeSurfCollis%Number(nSpecies+1),9) &
        = LastPartPos(PartID,3)
      AnalyzeSurfCollis%Spec(AnalyzeSurfCollis%Number(nSpecies+1)) &
        = PartSpecies(PartID)
      AnalyzeSurfCollis%BCid(AnalyzeSurfCollis%Number(nSpecies+1)) &
        = locBCID
    END IF
  END IF
END IF

END SUBROUTINE CalcWallSample


SUBROUTINE CalcSurfaceValues(during_dt_opt)
!===================================================================================================================================
!> Calculates macroscopic surface values from samples
!===================================================================================================================================
! MODULES
USE MOD_Globals
USE MOD_Timedisc_Vars              ,ONLY: time,dt
USE MOD_DSMC_Vars                  ,ONLY: MacroSurfaceVal, DSMC ,MacroSurfaceSpecVal
USE MOD_SurfaceModel_Vars          ,ONLY: Adsorption
USE MOD_Particle_Boundary_Vars     ,ONLY: SurfMesh,nSurfSample,SampWall,CalcSurfCollis
USE MOD_Particle_Boundary_Sampling ,ONLY: WriteSurfSampleToHDF5
#ifdef MPI
USE MOD_Particle_Boundary_Sampling ,ONLY: ExchangeSurfData
USE MOD_Particle_Boundary_Vars     ,ONLY: SurfCOMM
#endif
USE MOD_Particle_Vars              ,ONLY: WriteMacroSurfaceValues, nSpecies, MacroValSampTime, PartSurfaceModel
USE MOD_TimeDisc_Vars              ,ONLY: TEnd
USE MOD_Mesh_Vars                  ,ONLY: MeshFile
USE MOD_Restart_Vars               ,ONLY: RestartTime
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES            
LOGICAL, INTENT(IN), OPTIONAL      :: during_dt_opt !routine was called during timestep (i.e. before iter=iter+1, time=time+dt...)
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
INTEGER                            :: iSpec,iSurfSide,p,q, iReact
REAL                               :: TimeSample, ActualTime
INTEGER, ALLOCATABLE               :: CounterTotal(:), SumCounterTotal(:)              ! Total Wall-Collision counter
LOGICAL                            :: during_dt
!===================================================================================================================================

IF (PRESENT(during_dt_opt)) THEN
  during_dt=during_dt_opt
ELSE
  during_dt=.FALSE.
END IF
IF (during_dt) THEN
  ActualTime=time+dt
ELSE
  ActualTime=time
END IF

IF (WriteMacroSurfaceValues) THEN
  TimeSample = Time - MacroValSampTime !elapsed time since last sampling (variable dt's possible!)
  MacroValSampTime = Time
ELSE IF (RestartTime.GT.(1-DSMC%TimeFracSamp)*TEnd) THEN
  TimeSample = Time - RestartTime
ELSE
  TimeSample = (Time-(1-DSMC%TimeFracSamp)*TEnd)
END IF
IF(ALMOSTZERO(TimeSample)) RETURN

IF (CalcSurfCollis%AnalyzeSurfCollis) THEN
  CALL WriteAnalyzeSurfCollisToHDF5(ActualTime,TimeSample)
END IF

IF(.NOT.SurfMesh%SurfOnProc) RETURN

#ifdef MPI
CALL ExchangeSurfData()
#endif

IF (PartSurfaceModel.GT.0) THEN
  ALLOCATE(MacroSurfaceVal(6,1:nSurfSample,1:nSurfSample,SurfMesh%nSides))
  MacroSurfaceVal=0.
  ALLOCATE(MacroSurfaceSpecVal(4,1:nSurfSample,1:nSurfSample,SurfMesh%nSides,nSpecies))
  MacroSurfaceSpecVal=0.
ELSE
  ALLOCATE(MacroSurfaceVal(5,1:nSurfSample,1:nSurfSample,SurfMesh%nSides))
  MacroSurfaceVal=0.
  ALLOCATE(MacroSurfaceSpecVal(1,1:nSurfSample,1:nSurfSample,SurfMesh%nSides,nSpecies))
  MacroSurfaceSpecVal=0.
END IF
IF (CalcSurfCollis%Output) THEN
  ALLOCATE(CounterTotal(1:nSpecies))
  ALLOCATE(SumCounterTotal(1:nSpecies+1))
  CounterTotal(1:nSpecies)=0
  SumCounterTotal(1:nSpecies+1)=0
END IF

DO iSurfSide=1,SurfMesh%nSides
  DO q=1,nSurfSample
    DO p=1,nSurfSample
      MacroSurfaceVal(1,p,q,iSurfSide) = SampWall(iSurfSide)%State(10,p,q) /(SurfMesh%SurfaceArea(p,q,iSurfSide) * TimeSample)
      MacroSurfaceVal(2,p,q,iSurfSide) = SampWall(iSurfSide)%State(11,p,q) /(SurfMesh%SurfaceArea(p,q,iSurfSide) * TimeSample)
      MacroSurfaceVal(3,p,q,iSurfSide) = SampWall(iSurfSide)%State(12,p,q) /(SurfMesh%SurfaceArea(p,q,iSurfSide) * TimeSample)
      IF (PartSurfaceModel.GT.0) THEN
        MacroSurfaceVal(4,p,q,iSurfSide) = (SampWall(iSurfSide)%State(1,p,q) &
                                           +SampWall(iSurfSide)%State(4,p,q) &
                                           +SampWall(iSurfSide)%State(7,p,q) &
                                           -SampWall(iSurfSide)%State(3,p,q) &
                                           -SampWall(iSurfSide)%State(6,p,q) &
                                           -SampWall(iSurfSide)%State(9,p,q) &
                                           -SampWall(iSurfSide)%Adsorption(1,p,q))&
                                           /(SurfMesh%SurfaceArea(p,q,iSurfSide) * TimeSample)
        MacroSurfaceVal(6,p,q,iSurfSide) = (-SampWall(iSurfSide)%Adsorption(1,p,q))&
                                           /(SurfMesh%SurfaceArea(p,q,iSurfSide) * TimeSample)
      ELSE
        MacroSurfaceVal(4,p,q,iSurfSide) = (SampWall(iSurfSide)%State(1,p,q) &
                                           +SampWall(iSurfSide)%State(4,p,q) &
                                           +SampWall(iSurfSide)%State(7,p,q) &
                                           -SampWall(iSurfSide)%State(3,p,q) &
                                           -SampWall(iSurfSide)%State(6,p,q) &
                                           -SampWall(iSurfSide)%State(9,p,q)) &
                                           /(SurfMesh%SurfaceArea(p,q,iSurfSide) * TimeSample)
      END IF
      DO iSpec=1,nSpecies
        IF (CalcSurfCollis%Output) CounterTotal(iSpec) = CounterTotal(iSpec) + INT(SampWall(iSurfSide)%State(12+iSpec,p,q))
        IF (CalcSurfCollis%SpeciesFlags(iSpec)) THEN !Sum up all Collisions with SpeciesFlags for output
          MacroSurfaceVal(5,p,q,iSurfSide) = MacroSurfaceVal(5,p,q,iSurfSide) + SampWall(iSurfSide)%State(12+iSpec,p,q)/TimeSample
        END IF
        MacroSurfaceSpecVal(1,p,q,iSurfSide,iSpec) = SampWall(iSurfSide)%State(12+iSpec,p,q) / TimeSample
        IF (PartSurfaceModel.GT.0) THEN
          ! calculate accomodation coefficient
          IF (SampWall(iSurfSide)%State(12+iSpec,p,q).EQ.0) THEN
            MacroSurfaceSpecVal(2,p,q,iSurfSide,iSpec) = 0.
          ELSE
            MacroSurfaceSpecVal(2,p,q,iSurfSide,iSpec) = (SampWall(iSurfSide)%Accomodation(iSpec,p,q) &
                                                      / SampWall(iSurfSide)%State(12+iSpec,p,q))
          END IF
          ! calculate coverage
          MacroSurfaceSpecVal(3,p,q,iSurfSide,iSpec) = SampWall(iSurfSide)%Adsorption(1+iSpec,p,q) * dt / TimeSample
          ! calculate recombination coefficient
          DO iReact=1,Adsorption%RecombNum
            IF (SampWall(iSurfSide)%State(12+iSpec,p,q).EQ.0) THEN
              MacroSurfaceSpecVal(4,p,q,iSurfSide,iSpec) = MacroSurfaceSpecVal(4,p,q,iSurfSide,iSpec)
            ELSE
              MacroSurfaceSpecVal(4,p,q,iSurfSide,iSpec) = MacroSurfaceSpecVal(4,p,q,iSurfSide,iSpec) &
                  + SampWall(iSurfSide)%Reaction(iReact,iSpec,p,q) * 2. / SampWall(iSurfSide)%State(12+iSpec,p,q)
            END IF
          END DO
        END IF
      END DO ! iSpec=1,nSpecies
    END DO ! q=1,nSurfSample
  END DO ! p=1,nSurfSample 
END DO ! iSurfSide=1,SurfMesh%nSides

IF (CalcSurfCollis%Output) THEN
#ifdef MPI
  CALL MPI_REDUCE(CounterTotal,SumCounterTotal(1:nSpecies),nSpecies,MPI_INTEGER,MPI_SUM,0,SurfCOMM%COMM,iError)
#else
  SumCounterTotal(1:nSpecies)=CounterTotal
#endif
  DO iSpec=1,nSpecies
    IF (CalcSurfCollis%SpeciesFlags(iSpec)) THEN !Sum up all Collisions with SpeciesFlags for output
      SumCounterTotal(nSpecies+1) = SumCounterTotal(nSpecies+1) + SumCounterTotal(iSpec)
    END IF
  END DO
  SWRITE(UNIT_stdOut,'(A)') ' The following species swaps at walls have been sampled:'
  DO iSpec=1,nSpecies
    SWRITE(*,'(A9,I2,A2,E16.9,A6)') ' Species ',iSpec,': ',REAL(SumCounterTotal(iSpec)) / TimeSample,' MP/s;'
  END DO
  SWRITE(*,'(A23,E16.9,A6)') ' All with SpeciesFlag: ',REAL(SumCounterTotal(nSpecies+1)) / TimeSample,' MP/s.'
  DEALLOCATE(CounterTotal)
  DEALLOCATE(SumCounterTotal)
END IF

CALL WriteSurfSampleToHDF5(TRIM(MeshFile),ActualTime)

DEALLOCATE(MacroSurfaceVal,MacroSurfaceSpecVal)

END SUBROUTINE CalcSurfaceValues


REAL FUNCTION CalcTVib(ChaTVib,MeanEVib,nMax)
!===================================================================================================================================
!> Calculation of the vibrational temperature (zero-point search) for the TSHO (Truncated Simple Harmonic Oscillator)
!===================================================================================================================================
! MODULES
USE MOD_Globals       ,ONLY: abort
USE MOD_Globals_Vars  ,ONLY: BoltzmannConst
USE MOD_DSMC_Vars     ,ONLY: DSMC
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES            
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
REAL, INTENT(IN)                :: ChaTVib,MeanEVib  ! Charak TVib, mean vibrational Energy of all molecules
INTEGER, INTENT(IN)             :: nMax              ! INT(CharaTDisss/CharaTVib) + 1 
REAL(KIND=8)                    :: LowerVal, UpperVal, MiddleVal, MaxPosiVal  ! upper and lower value of zero point search 
REAl(KIND=8)                    :: eps_prec=1.0e-5   ! precision of zero point search
REAL(KIND=8)                    :: ZeroVal1, ZeroVal2 ! both fuction values to compare
!===================================================================================================================================

IF (MeanEVib.GT.0) THEN
  !.... Initial limits for a: lower limit = very small value
  !                           upper limit = max. value allowed by system
  !     zero point = CharaTVib / TVib
  LowerVal  = 1.0/(2.0*nMax)                                    ! Tvib is max for nMax => lower limit = 1.0/nMax
  UpperVal  = LOG(HUGE(MiddleVal*nMax))/nMax-1.0/(2.0 * nMax)   ! upper limit = for max possible EXP(nMax*MiddleVal)-value
  MaxPosiVal = LOG(HUGE(MaxPosiVal))  ! maximum value possible in system
  DO WHILE (ABS(LowerVal-UpperVal).GT.eps_prec)                      !  Let's search the zero point by bisection
    MiddleVal = 0.5*(LowerVal+UpperVal)

    IF ((LowerVal.GT.MaxPosiVal).OR.(MiddleVal.GT.MaxPosiVal)) THEN
       CALL Abort(&
__STAMP__&
,'Cannot find zero point in TVib Calculation Function! CharTVib:',RealInfoOpt=ChaTVib)
    END IF

    ! Calc of actual function values
    ZeroVal1 = DSMC%GammaQuant + 1/(EXP(LowerVal)-1) - nMax/(EXP(nMax*LowerVal)-1) - MeanEVib/(ChaTVib*BoltzmannConst)
    ZeroVal2 = DSMC%GammaQuant + 1/(EXP(MiddleVal)-1) - nMax/(EXP(nMax*MiddleVal)-1) - MeanEVib/(ChaTVib*BoltzmannConst)
    ! decision of direction of bisection
    IF (ZeroVal1*ZeroVal2.LT.0) THEN
      UpperVal = MiddleVal
    ELSE
      LowerVal = MiddleVal
    END IF
  END DO
  CalcTVib = ChaTVib/LowerVal ! LowerVal = CharaTVib / TVib
ELSE
  CalcTVib = 0
END IF

RETURN

END FUNCTION CalcTVib

!-----------------------------------------------------------------------------------------------------------------------------------

REAL FUNCTION CalcTelec(MeanEelec, iSpec)
!===================================================================================================================================
!> Calculation of the electronic temperature (zero-point search)
!===================================================================================================================================
! MODULES
USE MOD_Globals_Vars  ,ONLY: BoltzmannConst
USE MOD_DSMC_Vars     ,ONLY: SpecDSMC
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
REAL, INTENT(IN)                :: MeanEelec  ! Charak TVib, mean vibrational Energy of all molecules
INTEGER, INTENT(IN)             :: iSpec      ! Number of Species
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
INTEGER                         :: ii
REAL(KIND=8)                    :: LowerTemp, UpperTemp, MiddleTemp ! upper and lower value of modified zero point search
REAL(KIND=8)                    :: eps_prec=1.0e-5   ! precision of zero point search
REAL(KIND=8)                    :: SumOne, SumTwo    ! both summs
!===================================================================================================================================

! lower limit: very small value or lowest temperature if ionized
! upper limit: highest possible temperature
IF ( MeanEelec .GT. 0 ) THEN
  IF ( SpecDSMC(iSpec)%ElectronicState(2,0) .EQ. 0 ) THEN
    LowerTemp = 1.0
  ELSE
    LowerTemp = SpecDSMC(iSpec)%ElectronicState(2,0)
  END IF
  UpperTemp = SpecDSMC(iSpec)%ElectronicState(2,SpecDSMC(iSpec)%MaxElecQuant-1)
  DO WHILE ( ABS( UpperTemp - LowerTemp ) .GT. eps_prec )
    MiddleTemp = 0.5*( LowerTemp + UpperTemp)
    SumOne = 0.0
    SumTwo = 0.0
    DO ii = 0, SpecDSMC(iSpec)%MaxElecQuant-1
      SumOne = SumOne + SpecDSMC(iSpec)%ElectronicState(1,ii) * &
                exp( - SpecDSMC(iSpec)%ElectronicState(2,ii) / MiddleTemp )
      SumTwo = SumTwo + SpecDSMC(iSpec)%ElectronicState(1,ii) * SpecDSMC(iSpec)%ElectronicState(2,ii) * &
                exp( - SpecDSMC(iSpec)%ElectronicState(2,ii) / MiddleTemp )
    END DO
    IF ( SumTwo / SumOne .GT. MeanEelec / BoltzmannConst ) THEN
      UpperTemp = MiddleTemp
    ELSE
      LowerTemp = MiddleTemp
    END IF
  END DO
  CalcTelec = UpperTemp ! or 0.5*( Tmax + Tmin)
ELSE
  CalcTelec = 0. ! sup
END IF

RETURN

END FUNCTION CalcTelec


REAL FUNCTION CalcTVibPoly(MeanEVib, iSpec)
!===================================================================================================================================
!> Calculation of the vibrational temperature (zero-point search) for polyatomic molecules
!===================================================================================================================================
! MODULES
USE MOD_Globals_Vars  ,ONLY: BoltzmannConst, ElementaryCharge
USE MOD_DSMC_Vars     ,ONLY: SpecDSMC, PolyatomMolDSMC
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
REAL, INTENT(IN)                :: MeanEVib  ! Charak TVib, mean vibrational Energy of all molecules
INTEGER, INTENT(IN)             :: iSpec      ! Number of Species
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
INTEGER                         :: iDOF,iPolyatMole
REAL(KIND=8)                    :: LowerTemp, UpperTemp, MiddleTemp ! upper and lower value of modified zero point search
REAl(KIND=8)                    :: eps_prec=1.0E-5   ! precision of zero point search
REAL(KIND=8)                    :: SumOne    ! both summs
!===================================================================================================================================

! lower limit: very small value or lowest temperature if ionized
! upper limit: highest possible temperature
iPolyatMole = SpecDSMC(iSpec)%SpecToPolyArray
IF ( MeanEVib .GT. SpecDSMC(iSpec)%EZeroPoint) THEN
  LowerTemp = 1.0
  UpperTemp = 5.0*SpecDSMC(iSpec)%Ediss_eV*ElementaryCharge/BoltzmannConst
  DO WHILE ( ABS( UpperTemp - LowerTemp ) .GT. eps_prec )
    MiddleTemp = 0.5*( LowerTemp + UpperTemp)
    SumOne = 0.0
    DO iDOF = 1, PolyatomMolDSMC(iPolyatMole)%VibDOF
      SumOne = SumOne + 0.5*BoltzmannConst * PolyatomMolDSMC(iPolyatMole)%CharaTVibDOF(iDOF) &
            + BoltzmannConst * PolyatomMolDSMC(iPolyatMole)%CharaTVibDOF(iDOF) &
            / (EXP(PolyatomMolDSMC(iPolyatMole)%CharaTVibDOF(iDOF)/MiddleTemp) -1.0)
    END DO
    IF ( SumOne .GT. MeanEVib) THEN
      UpperTemp = MiddleTemp
    ELSE
      LowerTemp = MiddleTemp
    END IF
  END DO
  CalcTVibPoly = UpperTemp ! or 0.5*( Tmax + Tmin)
ELSE
  CalcTVibPoly = 0. ! sup
END IF
RETURN

END FUNCTION CalcTVibPoly


REAL FUNCTION CalcMeanFreePath(SpecPartNum, nPart, Volume, opt_omega, opt_temp)
!===================================================================================================================================
!> Calculation of the mean free path for the hard sphere and variable hard sphere (if omega and temperature are given)
!===================================================================================================================================
! MODULES
USE MOD_Globals
USE MOD_Globals_Vars  ,ONLY: Pi
USE MOD_Particle_Vars ,ONLY: Species, nSpecies
USE MOD_DSMC_Vars     ,ONLY: SpecDSMC
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
REAL, INTENT(IN)                :: Volume,SpecPartNum(:),nPart
REAL, OPTIONAL, INTENT(IN)      :: opt_omega, opt_temp
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
INTEGER                         :: iSpec, jSpec
REAL                            :: DrefMixture, omega, Temp, MFP_Tmp
!===================================================================================================================================
DrefMixture = 0.0
CalcMeanFreePath = 0.0

! Calculation of mixture reference diameter

DO iSpec = 1, nSpecies
  DrefMixture = DrefMixture + SpecPartNum(iSpec)*SpecDSMC(iSpec)%DrefVHS / nPart
END DO
! Calculation of mean free path for a gas mixture (Bird 1986, p. 96, Eq. 4.77)
! (only defined for a single weighting factor, if omega is present calculation of the mean free path with the VHS model)
IF(PRESENT(opt_omega).AND.PRESENT(opt_temp)) THEN
  omega = opt_omega
  Temp = opt_temp
    DO iSpec = 1, nSpecies
      MFP_Tmp = 0.0
      IF(SpecPartNum(iSpec).GT.0.0) THEN ! skipping species not present in the cell
        DO jSpec = 1, nSpecies
          IF(SpecPartNum(jSpec).GT.0.0) THEN ! skipping species not present in the cell
            MFP_Tmp = MFP_Tmp + (Pi*DrefMixture**2.*SpecPartNum(jSpec)*Species(jSpec)%MacroParticleFactor / Volume &
                                  * (SpecDSMC(iSpec)%TrefVHS/Temp)**(omega) &
                                  * SQRT(1+Species(iSpec)%MassIC/Species(jSpec)%MassIC))
          END IF
        END DO
        CalcMeanFreePath = CalcMeanFreePath + (SpecPartNum(iSpec) / nPart) / MFP_Tmp
      END IF
    END DO
ELSE
  DO iSpec = 1, nSpecies
    MFP_Tmp = 0.0
    IF(SpecPartNum(iSpec).GT.0.0) THEN ! skipping species not present in the cell
      DO jSpec = 1, nSpecies
        IF(SpecPartNum(jSpec).GT.0.0) THEN ! skipping species not present in the cell
          MFP_Tmp = MFP_Tmp + (Pi*DrefMixture**2.*SpecPartNum(jSpec)*Species(jSpec)%MacroParticleFactor / Volume &
                                * SQRT(1+Species(iSpec)%MassIC/Species(jSpec)%MassIC))
        END IF
      END DO
      CalcMeanFreePath = CalcMeanFreePath + (SpecPartNum(iSpec) / nPart) / MFP_Tmp
    END IF
  END DO
END IF
RETURN

END FUNCTION CalcMeanFreePath


SUBROUTINE CalcGammaVib()
!===================================================================================================================================
!> calculate Gamma_vib factor necessary for correction of vibrational relaxation according to Gimelshein et al.
!> -> 'Vibrational Relaxation Rates in the DSMC Method', Physics of Fluids V14 No12, 2002
!===================================================================================================================================
! MODULES
USE MOD_Globals
USE MOD_Particle_Vars ,ONLY: nSpecies
USE MOD_DSMC_Vars     ,ONLY: SpecDSMC, PolyatomMolDSMC, DSMC
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
INTEGER               :: iSpec, iDOF, iPolyatMole
!===================================================================================================================================

! Calculate GammaVib Factor  = Xi_Vib² * exp(CharaTVib/T_trans) / 2
DO iSpec = 1, nSpecies
  IF(SpecDSMC(iSpec)%InterID.EQ.2) THEN
    IF(SpecDSMC(iSpec)%PolyatomicMol) THEN
      iPolyatMole = SpecDSMC(iSpec)%SpecToPolyArray
      IF (DSMC%PolySingleMode) THEN
        DO iDOF = 1, PolyatomMolDSMC(iPolyatMole)%VibDOF
          PolyatomMolDSMC(iPolyatMole)%GammaVib(iDOF) =                                                        &
              (2.*PolyatomMolDSMC(iPolyatMole)%CharaTVibDOF(iDOF) / (DSMC%InstantTransTemp(iSpec)              &
              *(EXP(PolyatomMolDSMC(iPolyatMole)%CharaTVibDOF(iDOF) / DSMC%InstantTransTemp(iSpec))-1.)))**2.  &
              * EXP(PolyatomMolDSMC(iPolyatMole)%CharaTVibDOF(iDOF) / DSMC%InstantTransTemp(iSpec)) / 2.
        END DO
      ELSE
        SpecDSMC(iSpec)%GammaVib = 0.0
        DO iDOF = 1, PolyatomMolDSMC(iPolyatMole)%VibDOF
          SpecDSMC(iSpec)%GammaVib = SpecDSMC(iSpec)%GammaVib &
              + (2.*PolyatomMolDSMC(iPolyatMole)%CharaTVibDOF(iDOF) / (DSMC%InstantTransTemp(iSpec)            &
              *(EXP(PolyatomMolDSMC(iPolyatMole)%CharaTVibDOF(iDOF) / DSMC%InstantTransTemp(iSpec))-1.)))**2.  &
              * EXP(PolyatomMolDSMC(iPolyatMole)%CharaTVibDOF(iDOF) / DSMC%InstantTransTemp(iSpec)) / 2.
        END DO
      END IF
    ELSE
      SpecDSMC(iSpec)%GammaVib = (2.*SpecDSMC(iSpec)%CharaTVib / (DSMC%InstantTransTemp(iSpec)               &
                                  *(EXP(SpecDSMC(iSpec)%CharaTVib / DSMC%InstantTransTemp(iSpec))-1.)))**2.  &
                                  * EXP(SpecDSMC(iSpec)%CharaTVib / DSMC%InstantTransTemp(iSpec)) / 2.
    END IF
  END IF
END DO

END SUBROUTINE CalcGammaVib


SUBROUTINE CalcInstantTransTemp(iPartIndx,PartNum)
!===================================================================================================================================
!> Calculation of the instantaneous translational temperature for the cell
!===================================================================================================================================
! MODULES
USE MOD_Globals
USE MOD_Globals_Vars  ,ONLY: BoltzmannConst
USE MOD_Preproc
USE MOD_DSMC_Vars     ,ONLY: DSMC, CollInf
USE MOD_Particle_Vars ,ONLY: PartState, PartSpecies, Species, nSpecies, PartMPF, usevMPF
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
INTEGER, INTENT(IN)   :: PartNum
INTEGER, INTENT(IN)   :: iPartIndx(:)
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
INTEGER               :: iSpec, iPart
REAL                  :: PartV(nSpecies,3), PartV2(nSpecies,3)
REAL                  :: MeanPartV_2(nSpecies,3), Mean_PartV2(nSpecies,3), TempDirec(nSpecies,3)
!===================================================================================================================================

! Sum up velocity
PartV = 0
PartV2 = 0
DO iPart=1,PartNum
  IF (usevMPF) THEN
    PartV(PartSpecies(iPartIndx(iPart)),1:3) = PartV(PartSpecies(iPartIndx(iPart)),1:3)   &
                                                    + PartState(iPartIndx(iPart),4:6) * PartMPF(iPartIndx(iPart))
    PartV2(PartSpecies(iPartIndx(iPart)),1:3) = PartV2(PartSpecies(iPartIndx(iPart)),1:3) &
                                                    + PartState(iPartIndx(iPart),4:6)**2 * PartMPF(iPartIndx(iPart))
  ELSE
    PartV(PartSpecies(iPartIndx(iPart)),1:3) = PartV(PartSpecies(iPartIndx(iPart)),1:3)   &
                                                    + PartState(iPartIndx(iPart),4:6)
    PartV2(PartSpecies(iPartIndx(iPart)),1:3) = PartV2(PartSpecies(iPartIndx(iPart)),1:3) &
                                                    + PartState(iPartIndx(iPart),4:6)**2
  END IF
END DO
DO iSpec=1, nSpecies
  IF(CollInf%Coll_SpecPartNum(iSpec).NE.0) THEN
    ! Compute velocity averages
    MeanPartV_2(iSpec,1:3)  = (PartV(iSpec,1:3) / CollInf%Coll_SpecPartNum(iSpec))**2       ! < |v| >**2
    Mean_PartV2(iSpec,1:3)  = PartV2(iSpec,1:3) / CollInf%Coll_SpecPartNum(iSpec)           ! < |v|**2 >
  ELSE
    MeanPartV_2(iSpec,1:3) = 0.
    Mean_PartV2(iSpec,1:3) = 0.
  END IF
  ! Compute temperatures
  TempDirec(iSpec,1:3) = Species(iSpec)%MassIC * (Mean_PartV2(iSpec,1:3) - MeanPartV_2(iSpec,1:3)) &
                        / BoltzmannConst ! Temp calculation is limitedt to one species
  DSMC%InstantTransTemp(iSpec) = (TempDirec(iSpec,1) + TempDirec(iSpec,2) + TempDirec(iSpec,3)) / 3.
  DSMC%InstantTransTemp(nSpecies + 1) = DSMC%InstantTransTemp(nSpecies + 1)   &
                                        + DSMC%InstantTransTemp(iSpec)*CollInf%Coll_SpecPartNum(iSpec)
END DO
DSMC%InstantTransTemp(nSpecies+1) = DSMC%InstantTransTemp(nSpecies + 1) / SUM(CollInf%Coll_SpecPartNum)

END SUBROUTINE CalcInstantTransTemp

SUBROUTINE InitHODSMC()
!===================================================================================================================================
!> Calculates macroscopic surface values from samples
!> Call position: after FIBGM
!===================================================================================================================================
! MODULES
USE MOD_Mesh_Vars          ,ONLY: nElems, Elem_xGP, sJ, nBCSides, SideToElem
USE MOD_DSMC_Vars          ,ONLY: DSMCSampVolWe, HODSMC,DSMCSampNearInt, DSMCSampCellVolW
USE MOD_Globals
USE MOD_ReadInTools
USE MOD_Particle_Mesh_Vars ,ONLY: GEO
USE MOD_PreProc            ,ONLY: PP_N
USE MOD_ChangeBasis        ,ONLY: ChangeBasis3D
USE MOD_Basis              ,ONLY: LegendreGaussNodesAndWeights, LegGaussLobNodesAndWeights
USE MOD_Basis              ,ONLY: BarycentricWeights,InitializeVandermonde
USE MOD_Interpolation_Vars ,ONLY: xGP, wBary
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES            
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
REAL          :: xmin, ymin, zmin, xmax, ymax, zmax
INTEGER       :: iElem, i, ALLOCSTAT, j, k, m, l, iSide, jj,kk,mm
REAL,ALLOCATABLE                        :: Vdm_ElemxgpN_DSMCNOut(:,:)
REAL,ALLOCATABLE                        :: xGP_tmp(:)
REAL, ALLOCATABLE                       :: DetJacGauss_N(:,:,:,:), DetLocal(:,:,:,:)!, Volumes(:,:,:)
LOGICAL, ALLOCATABLE                    :: VolumeDone(:,:,:)
#ifndef MPI
INTEGER       :: k2,m2,l2
#endif /*NOT MPI*/
!===================================================================================================================================

SWRITE(UNIT_stdOut,'(A)') ' INIT High Order DSMC Sampling...'

ALLOCATE( Vdm_ElemxgpN_DSMCNOut(0:HODSMC%nOutputDSMC,0:PP_N) &
          , xGP_tmp(0:HODSMC%nOutputDSMC))
ALLOCATE(HODSMC%DSMC_wGP(0:HODSMC%nOutputDSMC))

HODSMC%NodeType = GETSTR('DSMC-HOSampling-NodeType','visu')
SELECT CASE(TRIM(HODSMC%NodeType))
CASE('visu')
  DO i=0,HODSMC%nOutputDSMC
    xGP_tmp(i) = 2./REAL(HODSMC%nOutputDSMC) * REAL(i) - 1.
    HODSMC%DSMC_wGP(i) = 2./REAL(HODSMC%nOutputDSMC)
  END DO
  HODSMC%DSMC_wGP(0) = HODSMC%DSMC_wGP(0) * 0.5
  HODSMC%DSMC_wGP(HODSMC%nOutputDSMC) = HODSMC%DSMC_wGP(HODSMC%nOutputDSMC) * 0.5
CASE('gauss')
  CALL LegendreGaussNodesAndWeights(HODSMC%nOutputDSMC,xGP_tmp,HODSMC%DSMC_wGP)
CASE('gauss-lobatto')
  CALL LegGaussLobNodesAndWeights(HODSMC%nOutputDSMC,xGP_tmp,HODSMC%DSMC_wGP)
CASE DEFAULT
  CALL abort(&
__STAMP__&
,'Unknown HODSMCNodeType in dsmc_analyze.f90')
END SELECT

CALL InitializeVandermonde(PP_N,HODSMC%nOutputDSMC,wBary,xGP,xGP_tmp,Vdm_ElemxgpN_DSMCNOut)

SELECT CASE(TRIM(HODSMC%SampleType))
CASE('cartmesh_volumeweighting')
  ! ChangeBasis3D to lower or higher polynomial degree
  ALLOCATE(HODSMC%DSMC_xGP(1:3,0:HODSMC%nOutputDSMC,0:HODSMC%nOutputDSMC,0:HODSMC%nOutputDSMC,1:nElems))
  DO iElem=1,nElems
    CALL ChangeBasis3D(3,PP_N, HODSMC%nOutputDSMC,Vdm_ElemxgpN_DSMCNOut, Elem_xGP(:,:,:,:,iElem),HODSMC%DSMC_xGP(:,:,:,:,iElem))
  END DO ! iElem
  ! read in background mesh size
  DSMCSampVolWe%BGMdeltas(1:3) = GETREALARRAY('DSMCSampVolWe-BGMdeltas',3,'0. , 0. , 0.')
  DSMCSampVolWe%FactorBGM(1:3) = GETREALARRAY('DSMCSampVolWe-FactorBGM',3,'1. , 1. , 1.')
  DSMCSampVolWe%BGMdeltas(1:3) = 1./DSMCSampVolWe%FactorBGM(1:3)*DSMCSampVolWe%BGMdeltas(1:3)
  IF (ANY(DSMCSampVolWe%BGMdeltas.EQ.0.0)) THEN
    CALL abort(&
__STAMP__&
,'ERROR: DSMCSampVolWe-BGMdeltas: No size for the cartesian background mesh definded.')
  END IF

  DSMCSampVolWe%OrderVolInt = GETINT('DSMCSampVolWe-VolIntOrd','50')
  ALLOCATE(DSMCSampVolWe%x_VolInt(0:DSMCSampVolWe%OrderVolInt),DSMCSampVolWe%w_VolInt(0:DSMCSampVolWe%OrderVolInt))
  CALL LegendreGaussNodesAndWeights(DSMCSampVolWe%OrderVolInt,DSMCSampVolWe%x_VolInt,DSMCSampVolWe%w_VolInt)

  ! reuse local min max coordinates of local mesh
  ! has to be called after InitFIBGM
  xmin = GEO%xmin
  ymin = GEO%ymin
  zmin = GEO%zmin
  xmax = GEO%xmax
  ymax = GEO%ymax
  zmax = GEO%zmax

  ! define minimum and maximum backgroundmesh index, compute volume
  DSMCSampVolWe%BGMVolume = DSMCSampVolWe%BGMdeltas(1)*DSMCSampVolWe%BGMdeltas(2)*DSMCSampVolWe%BGMdeltas(3)
  DSMCSampVolWe%BGMminX = FLOOR(xmin/DSMCSampVolWe%BGMdeltas(1)-0.0001)
  DSMCSampVolWe%BGMminY = FLOOR(ymin/DSMCSampVolWe%BGMdeltas(2)-0.0001)
  DSMCSampVolWe%BGMminZ = FLOOR(zmin/DSMCSampVolWe%BGMdeltas(3)-0.0001)
  DSMCSampVolWe%BGMmaxX = CEILING(xmax/DSMCSampVolWe%BGMdeltas(1)+0.0001)
  DSMCSampVolWe%BGMmaxY = CEILING(ymax/DSMCSampVolWe%BGMdeltas(2)+0.0001)
  DSMCSampVolWe%BGMmaxZ = CEILING(zmax/DSMCSampVolWe%BGMdeltas(3)+0.0001)

  ! mapping from gausspoints to BGM
  ALLOCATE(DSMCSampVolWe%GaussBGMIndex(1:3,0:HODSMC%nOutputDSMC,0:HODSMC%nOutputDSMC,0:HODSMC%nOutputDSMC,1:nElems),STAT=ALLOCSTAT)
  IF (ALLOCSTAT.NE.0) THEN
    CALL abort(&
__STAMP__&
,'ERROR in pic_depo.f90: Cannot allocate GaussBGMIndex!')
  END IF
  ALLOCATE(DSMCSampVolWe%GaussBGMFactor(1:3,0:HODSMC%nOutputDSMC,0:HODSMC%nOutputDSMC,0:HODSMC%nOutputDSMC,1:nElems),STAT=ALLOCSTAT)
  IF (ALLOCSTAT.NE.0) THEN
    CALL abort(&
__STAMP__&
,'ERROR in pic_depo.f90: Cannot allocate GaussBGMFactor!')
  END IF
  DO iElem = 1, nElems
    DO j = 0, HODSMC%nOutputDSMC
      DO k = 0, HODSMC%nOutputDSMC
        DO m = 0, HODSMC%nOutputDSMC
          DSMCSampVolWe%GaussBGMIndex(1,j,k,m,iElem) = FLOOR(HODSMC%DSMC_xGP(1,j,k,m,iElem)/DSMCSampVolWe%BGMdeltas(1))
          DSMCSampVolWe%GaussBGMIndex(2,j,k,m,iElem) = FLOOR(HODSMC%DSMC_xGP(2,j,k,m,iElem)/DSMCSampVolWe%BGMdeltas(2))
          DSMCSampVolWe%GaussBGMIndex(3,j,k,m,iElem) = FLOOR(HODSMC%DSMC_xGP(3,j,k,m,iElem)/DSMCSampVolWe%BGMdeltas(3))
          DSMCSampVolWe%GaussBGMFactor(1,j,k,m,iElem) = (HODSMC%DSMC_xGP(1,j,k,m,iElem)/DSMCSampVolWe%BGMdeltas(1)) &
              -REAL(DSMCSampVolWe%GaussBGMIndex(1,j,k,m,iElem))
          DSMCSampVolWe%GaussBGMFactor(2,j,k,m,iElem) = (HODSMC%DSMC_xGP(2,j,k,m,iElem)/DSMCSampVolWe%BGMdeltas(2)) &
              -REAL(DSMCSampVolWe%GaussBGMIndex(2,j,k,m,iElem))
          DSMCSampVolWe%GaussBGMFactor(3,j,k,m,iElem) = (HODSMC%DSMC_xGP(3,j,k,m,iElem)/DSMCSampVolWe%BGMdeltas(3)) &
              -REAL(DSMCSampVolWe%GaussBGMIndex(3,j,k,m,iElem))
        END DO
      END DO
    END DO
  END DO

  ALLOCATE(DSMCSampVolWe%isBoundBGCell(DSMCSampVolWe%BGMminX:DSMCSampVolWe%BGMmaxX,DSMCSampVolWe%BGMminY:DSMCSampVolWe%BGMmaxY, &
          DSMCSampVolWe%BGMminZ:DSMCSampVolWe%BGMmaxZ))
  DSMCSampVolWe%isBoundBGCell = .false.
  DO iSide = 1, nBCSides
    iElem = SideToElem(S2E_ELEM_ID, iSide)
    !IF (iElem.EQ.-1) iElem = SideToElem(S2E_NB_ELEM_ID, iSide)
    DO j = 0, HODSMC%nOutputDSMC
      DO k = 0, HODSMC%nOutputDSMC
        DO m = 0, HODSMC%nOutputDSMC
         DO jj=-1,1; DO kk=-1,1; DO mm=-1,1
           IF (.NOT.(DSMCSampVolWe%GaussBGMIndex(1,j,k,m,iElem)+jj.LT.DSMCSampVolWe%BGMminX &
                .OR.DSMCSampVolWe%GaussBGMIndex(2,j,k,m,iElem)+kk.LT.DSMCSampVolWe%BGMminY &
                .OR.DSMCSampVolWe%GaussBGMIndex(3,j,k,m,iElem)+mm.LT.DSMCSampVolWe%BGMminZ)) THEN
             DSMCSampVolWe%isBoundBGCell(DSMCSampVolWe%GaussBGMIndex(1,j,k,m,iElem)+jj, &
                DSMCSampVolWe%GaussBGMIndex(2,j,k,m,iElem)+kk, DSMCSampVolWe%GaussBGMIndex(3,j,k,m,iElem)+mm) = .true.
           END IF
          END DO; END DO; END DO
        END DO
      END DO
    END DO
  END DO

  ALLOCATE(DSMCSampVolWe%BGMVolumes(DSMCSampVolWe%BGMminX:DSMCSampVolWe%BGMmaxX,DSMCSampVolWe%BGMminY:DSMCSampVolWe%BGMmaxY, &
          DSMCSampVolWe%BGMminZ:DSMCSampVolWe%BGMmaxZ))
  ALLOCATE(VolumeDone(DSMCSampVolWe%BGMminX:DSMCSampVolWe%BGMmaxX,DSMCSampVolWe%BGMminY:DSMCSampVolWe%BGMmaxY, &
          DSMCSampVolWe%BGMminZ:DSMCSampVolWe%BGMmaxZ))
  ALLOCATE(DSMCSampVolWe%BGMVolumes2(DSMCSampVolWe%BGMminX:DSMCSampVolWe%BGMmaxX,DSMCSampVolWe%BGMminY:DSMCSampVolWe%BGMmaxY, &
          DSMCSampVolWe%BGMminZ:DSMCSampVolWe%BGMmaxZ))
  VolumeDone = .false.
  DSMCSampVolWe%BGMVolumes = DSMCSampVolWe%BGMVolume !0.0
  DSMCSampVolWe%BGMVolumes2  = 0.0

  DO j = DSMCSampVolWe%BGMminX, DSMCSampVolWe%BGMmaxX
    DO k = DSMCSampVolWe%BGMminY, DSMCSampVolWe%BGMmaxY
      DO m = DSMCSampVolWe%BGMminZ, DSMCSampVolWe%BGMmaxZ
        IF (DSMCSampVolWe%isBoundBGCell(j,k,m)) THEN
          CALL VolumeBoundBGMCInt(j, k, m, DSMCSampVolWe%BGMVolumes(j,k,m))
        END IF
      END DO
    END DO
  END DO

#ifdef MPI
  CALL MPIBackgroundMeshInitDSMCHO()
  CALL MPIVolumeExchangeBGMDSMCHO()
#else

  IF(GEO%nPeriodicVectors.GT.0)THEN
    ! Compute PeriodicBGMVectors (from PeriodicVectors and BGMdeltas)
    ALLOCATE(DSMCSampVolWe%PeriodicBGMVectors(1:3,1:GEO%nPeriodicVectors),STAT=allocStat)
    IF (allocStat .NE. 0) THEN
      CALL abort(&
__STAMP__&
,'ERROR in MPIBackgroundMeshInitDSMCHO: cannot allocate DSMCSampVolWe%PeriodicBGMVectors!')
    END IF
    DO i = 1, GEO%nPeriodicVectors
      DSMCSampVolWe%PeriodicBGMVectors(1,i) = NINT(GEO%PeriodicVectors(1,i)/DSMCSampVolWe%BGMdeltas(1))
      IF(ABS(GEO%PeriodicVectors(1,i)/DSMCSampVolWe%BGMdeltas(1)-REAL(DSMCSampVolWe%PeriodicBGMVectors(1,i))).GT.1E-10)THEN
        CALL abort(&
__STAMP__&
,'ERROR: Periodic Vector ist not multiple of background mesh delta')
      END IF
      DSMCSampVolWe%PeriodicBGMVectors(2,i) = NINT(GEO%PeriodicVectors(2,i)/DSMCSampVolWe%BGMdeltas(2))
      IF(ABS(GEO%PeriodicVectors(2,i)/DSMCSampVolWe%BGMdeltas(2)-REAL(DSMCSampVolWe%PeriodicBGMVectors(2,i))).GT.1E-10)THEN
        CALL abort(&
__STAMP__&
,'ERROR: Periodic Vector ist not multiple of background mesh delta')
      END IF
      DSMCSampVolWe%PeriodicBGMVectors(3,i) = NINT(GEO%PeriodicVectors(3,i)/DSMCSampVolWe%BGMdeltas(3))
      IF(ABS(GEO%PeriodicVectors(3,i)/DSMCSampVolWe%BGMdeltas(3)-REAL(DSMCSampVolWe%PeriodicBGMVectors(3,i))).GT.1E-10)THEN
        CALL abort(&
__STAMP__&
,'ERROR: Periodic Vector ist not multiple of background mesh delta')
      END IF
    END DO
  END IF
  DO i = 1,GEO%nPeriodicVectors
    DO k = DSMCSampVolWe%BGMminX, DSMCSampVolWe%BGMmaxX
      k2 = k + DSMCSampVolWe%PeriodicBGMVectors(1,i)
      DO l = DSMCSampVolWe%BGMminY, DSMCSampVolWe%BGMmaxY
        l2 = l + DSMCSampVolWe%PeriodicBGMVectors(2,i)
        DO m = DSMCSampVolWe%BGMminZ, DSMCSampVolWe%BGMmaxZ
          m2 = m + DSMCSampVolWe%PeriodicBGMVectors(3,i)
          IF ((k2.GE.DSMCSampVolWe%BGMminX).AND.(k2.LE.DSMCSampVolWe%BGMmaxX)) THEN
            IF ((l2.GE.DSMCSampVolWe%BGMminY).AND.(l2.LE.DSMCSampVolWe%BGMmaxY)) THEN
              IF ((m2.GE.DSMCSampVolWe%BGMminZ).AND.(m2.LE.DSMCSampVolWe%BGMmaxZ)) THEN
                DSMCSampVolWe%BGMVolumes(k,l,m) = DSMCSampVolWe%BGMVolumes(k,l,m) + DSMCSampVolWe%BGMVolumes(k2,l2,m2)
                DSMCSampVolWe%BGMVolumes(k2,l2,m2) = DSMCSampVolWe%BGMVolumes(k,l,m)
              END IF
            END IF
          END IF
        END DO
      END DO
    END DO
  END DO
#endif
  DEALLOCATE(HODSMC%DSMC_xGP,HODSMC%DSMC_wGP)
CASE('nearest_gausspoint')

  ALLOCATE(HODSMC%sJ(0:HODSMC%nOutputDSMC,0:HODSMC%nOutputDSMC,0:HODSMC%nOutputDSMC,1:nElems))
  ALLOCATE( DetJacGauss_N(1,0:HODSMC%nOutputDSMC,0:HODSMC%nOutputDSMC,0:HODSMC%nOutputDSMC) &
          , DetLocal(1,0:PP_N,0:PP_N,0:PP_N))
  DO iElem=1,nElems
    DO j=0, PP_N; DO k=0, PP_N; DO l=0, PP_N
      DetLocal(1,j,k,l)=1./sJ(j,k,l,iElem)
    END DO; END DO; END DO
    CALL ChangeBasis3D(1,PP_N, HODSMC%nOutputDSMC,Vdm_ElemxgpN_DSMCNOut, DetLocal(:,:,:,:),DetJacGauss_N(:,:,:,:))
    DO j=0, HODSMC%nOutputDSMC; DO k=0, HODSMC%nOutputDSMC; DO l=0, HODSMC%nOutputDSMC
      HODSMC%sJ(j,k,l,iElem)=1./DetJacGauss_N(1,j,k,l)
    END DO; END DO; END DO
  END DO ! iElem    
  ! compute the borders of the virtual volumes around the gauss points in -1|1 space
  ALLOCATE(DSMCSampNearInt%GaussBorder(1:HODSMC%nOutputDSMC),STAT=ALLOCSTAT)
  IF (ALLOCSTAT.NE.0) THEN
    CALL abort(&
__STAMP__&
,'ERROR in dsmc_analyze.f90: Cannot allocate Mapped Gauss Border Coords!')
  END IF
  DO i = 1,HODSMC%nOutputDSMC
    DSMCSampNearInt%GaussBorder(i) = (xGP_tmp(i) + xGP_tmp(i-1))/2
  END DO
CASE('cell_mean')
  DEALLOCATE(HODSMC%DSMC_wGP)
CASE('cell_volweight')
  ALLOCATE(DSMCSampCellVolW%xGP(0:HODSMC%nOutputDSMC))
  DSMCSampCellVolW%xGP(0:HODSMC%nOutputDSMC) = xGP_tmp(0:HODSMC%nOutputDSMC)
  DSMCSampCellVolW%xGP(0:HODSMC%nOutputDSMC) = (DSMCSampCellVolW%xGP(0:HODSMC%nOutputDSMC)+1.0)/2.0
  DEALLOCATE(HODSMC%DSMC_wGP)
CASE DEFAULT
  CALL abort(&
__STAMP__&
,'Unknown DSMCHOSampleType in dsmc_analyze.f90')
END SELECT

END SUBROUTINE InitHODSMC

SUBROUTINE DSMCHO_data_sampling()
!===================================================================================================================================
!> Sampling of variables velocity and energy for DSMC
!===================================================================================================================================
! MODULES
USE MOD_DSMC_Vars              ,ONLY: PartStateIntEn, DSMCSampVolWe, DSMC, CollisMode, SpecDSMC, HODSMC, DSMC_HOSolution
USE MOD_DSMC_Vars              ,ONLY: DSMCSampNearInt, DSMCSampCellVolW, useDSMC
USE MOD_Particle_Vars          ,ONLY: PartState, PDM, PartSpecies, Species, nSpecies, PEM,PartPosRef
USE MOD_Mesh_Vars              ,ONLY: nElems
USE MOD_Particle_Mesh_Vars     ,ONLY: Geo
USE MOD_Particle_Tracking_vars ,ONLY: DoRefMapping
USE MOD_Eval_xyz               ,ONLY: GetPositionInRefElem
!USE MOD_part_MPFtools,          ONLY:GeoCoordToMap
USE MOD_Globals
#if USE_LOADBALANCE
USE MOD_LoadBalance_tools      ,ONLY: LBStartTime, LBPauseTime
#endif /*USE_LOADBALANCE*/
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
INTEGER                       :: iPart, iElem, iLoopx, iLoopy, iLoopz, k, l, m, i, kk, ll, mm, iSpec, a, b, ii
REAL, ALLOCATABLE             :: BGMSource(:,:,:,:,:), alphaSum(:,:,:,:),BGMSourceCellVol(:,:,:,:,:,:)
REAL, ALLOCATABLE             :: alphaSumCellVol(:,:,:,:,:), Source(:,:,:,:,:,:)
REAL                          :: alpha1, alpha2, alpha3, TSource(1:11)
#if USE_LOADBALANCE
REAL                          :: tLBStart
#endif /*USE_LOADBALANCE*/
!===================================================================================================================================
DSMC%SampNum = DSMC%SampNum + 1
#if USE_LOADBALANCE
CALL LBStartTime(tLBStart)
#endif /*USE_LOADBALANCE*/
SELECT CASE(TRIM(HODSMC%SampleType))
 CASE('cartmesh_volumeweighting')
  ! Step 1: Deposition of all particles onto background mesh -> densities
  ALLOCATE(BGMSource(DSMCSampVolWe%BGMminX:DSMCSampVolWe%BGMmaxX,DSMCSampVolWe%BGMminY:DSMCSampVolWe%BGMmaxY, &
          DSMCSampVolWe%BGMminZ:DSMCSampVolWe%BGMmaxZ,1:11, 1:nSpecies), &
          alphaSum(DSMCSampVolWe%BGMminX:DSMCSampVolWe%BGMmaxX,DSMCSampVolWe%BGMminY:DSMCSampVolWe%BGMmaxY, &
          DSMCSampVolWe%BGMminZ:DSMCSampVolWe%BGMmaxZ, 1:nSpecies))

  BGMSource(:,:,:,:,:) = 0.0
  alphaSum(:,:,:,:) = 0.0
  DO i = 1, PDM%ParticleVecLength
    IF (PDM%ParticleInside(i)) THEN
      iSpec = PartSpecies(i)
      k = FLOOR(PartState(i,1)/DSMCSampVolWe%BGMdeltas(1))
      l = FLOOR(PartState(i,2)/DSMCSampVolWe%BGMdeltas(2))
      m = FLOOR(PartState(i,3)/DSMCSampVolWe%BGMdeltas(3))
      alpha1 = (PartState(i,1) / DSMCSampVolWe%BGMdeltas(1)) - k
      alpha2 = (PartState(i,2) / DSMCSampVolWe%BGMdeltas(2)) - l
      alpha3 = (PartState(i,3) / DSMCSampVolWe%BGMdeltas(3)) - m
      TSource(:) = 0.0
      TSource(1:3) = PartState(i,4:6)
      TSource(4:6) = PartState(i,4:6)**2
      TSource(7) = 1.0  !density
      IF(useDSMC)THEN
        IF ((CollisMode.EQ.2).OR.(CollisMode.EQ.3)) THEN
          IF (SpecDSMC(PartSpecies(i))%InterID.EQ.2) THEN
            TSource(8:9)      =  PartStateIntEn(i,1:2)
          ELSE
            TSource(8:9) = 0.0
          END IF
        ELSE
          TSource(8:9) = 0.0
        END IF
        IF (DSMC%ElectronicModel) THEN
          TSource(10)     =  PartStateIntEn(i,3)
        ELSE
          TSource(10) = 0.0
        END IF
      ELSE
        TSource(8:10)=0.
      END IF
      TSource(11) = 1.0

      BGMSource(k,l,m,1:11,iSpec)       = BGMSource(k,l,m,1:11,iSpec) + (TSource(1:11) * (1-alpha1)*(1-alpha2)*(1-alpha3))
      BGMSource(k,l,m+1,1:11,iSpec)     = BGMSource(k,l,m+1,1:11,iSpec) + (TSource(1:11) * (1-alpha1)*(1-alpha2)*(alpha3))
      BGMSource(k,l+1,m,1:11,iSpec)     = BGMSource(k,l+1,m,1:11,iSpec) + (TSource(1:11) * (1-alpha1)*(alpha2)*(1-alpha3))
      BGMSource(k,l+1,m+1,1:11,iSpec)   = BGMSource(k,l+1,m+1,1:11,iSpec) + (TSource(1:11) * (1-alpha1)*(alpha2)*(alpha3))
      BGMSource(k+1,l,m,1:11,iSpec)     = BGMSource(k+1,l,m,1:11,iSpec) + (TSource(1:11) * (alpha1)*(1-alpha2)*(1-alpha3))
      BGMSource(k+1,l,m+1,1:11,iSpec)   = BGMSource(k+1,l,m+1,1:11,iSpec) + (TSource(1:11) * (alpha1)*(1-alpha2)*(alpha3))
      BGMSource(k+1,l+1,m,1:11,iSpec)   = BGMSource(k+1,l+1,m,1:11,iSpec) + (TSource(1:11) * (alpha1)*(alpha2)*(1-alpha3))
      BGMSource(k+1,l+1,m+1,1:11,iSpec) = BGMSource(k+1,l+1,m+1,1:11,iSpec) + (TSource(1:11) * (alpha1)*(alpha2)*(alpha3))

      alphaSum(k,l,m,iSpec)       = alphaSum(k,l,m,iSpec) + (1-alpha1)*(1-alpha2)*(1-alpha3)
      alphaSum(k,l,m+1,iSpec)     = alphaSum(k,l,m+1,iSpec) + (1-alpha1)*(1-alpha2)*(alpha3)
      alphaSum(k,l+1,m,iSpec)     = alphaSum(k,l+1,m,iSpec) + (1-alpha1)*(alpha2)*(1-alpha3)
      alphaSum(k,l+1,m+1,iSpec)   = alphaSum(k,l+1,m+1,iSpec) + (1-alpha1)*(alpha2)*(alpha3)
      alphaSum(k+1,l,m,iSpec)     = alphaSum(k+1,l,m,iSpec) + (alpha1)*(1-alpha2)*(1-alpha3)
      alphaSum(k+1,l,m+1,iSpec)   = alphaSum(k+1,l,m+1,iSpec) + (alpha1)*(1-alpha2)*(alpha3)
      alphaSum(k+1,l+1,m,iSpec)   = alphaSum(k+1,l+1,m,iSpec) + (alpha1)*(alpha2)*(1-alpha3)
      alphaSum(k+1,l+1,m+1,iSpec) = alphaSum(k+1,l+1,m+1,iSpec) + (alpha1)*(alpha2)*(alpha3)
     END IF
  END DO

#ifdef MPI
  CALL MPISourceExchangeBGMDSMCHO(BGMSource, alphaSum)
#else
  IF (GEO%nPeriodicVectors.GT.0) CALL PeriodicSourceExchangeDSMCHO(BGMSource, alphaSum)
#endif

  DO iSpec = 1, nSpecies
    DO iLoopx = DSMCSampVolWe%BGMminX, DSMCSampVolWe%BGMmaxX
      DO iLoopy = DSMCSampVolWe%BGMminY, DSMCSampVolWe%BGMmaxY
        DO iLoopz = DSMCSampVolWe%BGMminZ, DSMCSampVolWe%BGMmaxZ
          IF (alphaSum(iLoopx, iLoopy, iLoopz,iSpec).GT.0.0) THEN
            BGMSource(iLoopx,iLoopy,iLoopz,1:6,iSpec) = BGMSource(iLoopx,iLoopy,iLoopz,1:6,iSpec) &
                    / alphaSum(iLoopx,iLoopy,iLoopz,iSpec)
            BGMSource(iLoopx,iLoopy,iLoopz,8:10,iSpec) = BGMSource(iLoopx,iLoopy,iLoopz,8:10,iSpec) &
                   / alphaSum(iLoopx,iLoopy,iLoopz,iSpec)
          ELSE
            BGMSource(iLoopx,iLoopy,iLoopz,1:6,iSpec) = 0.0
            BGMSource(iLoopx,iLoopy,iLoopz,8:10,iSpec) = 0.0
          END IF
          IF (DSMCSampVolWe%BGMVolumes(iLoopx,iLoopy,iLoopz).GT.0.0) THEN
              BGMSource(iLoopx,iLoopy,iLoopz,7,iSpec) = BGMSource(iLoopx,iLoopy,iLoopz,7,iSpec) &
                / DSMCSampVolWe%BGMVolumes(iLoopx,iLoopy,iLoopz)* Species(iSpec)%MacroParticleFactor
          ELSE
              BGMSource(iLoopx,iLoopy,iLoopz,7,iSpec) = 0.0
          END IF
        END DO
      END DO
    END DO
  END DO

  ! Step 2: Interpolation of densities onto grid
  DO iSpec = 1, nSpecies
    DO iElem = 1, nElems
      DO kk = 0, HODSMC%nOutputDSMC
        DO ll = 0, HODSMC%nOutputDSMC
          DO mm = 0, HODSMC%nOutputDSMC
           k = DSMCSampVolWe%GaussBGMIndex(1,kk,ll,mm,iElem)
           l = DSMCSampVolWe%GaussBGMIndex(2,kk,ll,mm,iElem)
           m = DSMCSampVolWe%GaussBGMIndex(3,kk,ll,mm,iElem)
           alpha1 = DSMCSampVolWe%GaussBGMFactor(1,kk,ll,mm,iElem)
           alpha2 = DSMCSampVolWe%GaussBGMFactor(2,kk,ll,mm,iElem)
           alpha3 = DSMCSampVolWe%GaussBGMFactor(3,kk,ll,mm,iElem)
           DSMC_HOSolution(:,kk,ll,mm,iElem,iSpec) = (DSMC_HOSolution(:,kk,ll,mm,iElem, iSpec) * (REAL(DSMC%SampNum) - 1.0) &
             +  (BGMSource(k,l,m,:,iSpec) * (1-alpha1) * (1-alpha2) * (1-alpha3) + &
                BGMSource(k,l,m+1,:,iSpec) * (1-alpha1) * (1-alpha2) * (alpha3) + &
                BGMSource(k,l+1,m,:,iSpec) * (1-alpha1) * (alpha2) * (1-alpha3) + &
                BGMSource(k,l+1,m+1,:,iSpec) * (1-alpha1) * (alpha2) * (alpha3) + &
                BGMSource(k+1,l,m,:,iSpec) * (alpha1) * (1-alpha2) * (1-alpha3) + &
                BGMSource(k+1,l,m+1,:,iSpec) * (alpha1) * (1-alpha2) * (alpha3) + &
                BGMSource(k+1,l+1,m,:,iSpec) * (alpha1) * (alpha2) * (1-alpha3) + &
                BGMSource(k+1,l+1,m+1,:,iSpec) * (alpha1) * (alpha2) * (alpha3))) / REAL(DSMC%SampNum)
         END DO !mm
       END DO !ll
     END DO !kk
   END DO !iElem
 END DO
 DEALLOCATE(BGMSource, alphasum)
CASE('nearest_gausspoint')
  ALLOCATE(Source(1:11,0:HODSMC%nOutputDSMC,0:HODSMC%nOutputDSMC, &
          0:HODSMC%nOutputDSMC,1:nElems, 1:nSpecies))
  IF(MOD(HODSMC%nOutputDSMC,2).EQ.0) THEN
    a = HODSMC%nOutputDSMC/2
    b = a
  ELSE
    a = (HODSMC%nOutputDSMC+1)/2
    b = a-1
  END IF
  Source=0.0
  DO i=1,PDM%ParticleVecLength
    IF (PDM%ParticleInside(i)) THEN
      iSpec = PartSpecies(i)
      iElem = PEM%Element(i)
      ! Map Particle to -1|1 space (re-used in interpolation)
      ! check with depositions and PartPosRef already mapped
      IF(.NOT.DoRefMapping)THEN
        CALL GetPositionInRefElem(PartState(i,1:3),PartPosRef(1:3,i),iElem)
      END IF
      !CALL GeoCoordToMap(PartState(i,1:3),PartPosRef(1:3),iElem)
      ! Find out which gausspoint is closest and add up charges and currents
      !! x-direction
      k = a
      DO ii = 0,b-1
        IF(ABS(PartPosRef(1,i)).GE.DSMCSampNearInt%GaussBorder(HODSMC%nOutputDSMC-ii))THEN
          k = HODSMC%nOutputDSMC-ii
          EXIT
        END IF
      END DO
      k = NINT((HODSMC%nOutputDSMC+SIGN(2.0*k-HODSMC%nOutputDSMC,PartPosRef(1,i)))/2)
      !! y-direction
      l = a
      DO ii = 0,b-1
        IF(ABS(PartPosRef(2,i)).GE.DSMCSampNearInt%GaussBorder(HODSMC%nOutputDSMC-ii))THEN
          l = HODSMC%nOutputDSMC-ii
          EXIT
        END IF
      END DO
      l = NINT((HODSMC%nOutputDSMC+SIGN(2.0*l-HODSMC%nOutputDSMC,PartPosRef(2,i)))/2)
      !! z-direction
      m = a
      DO ii = 0,b-1
        IF(ABS(PartPosRef(3,i)).GE.DSMCSampNearInt%GaussBorder(HODSMC%nOutputDSMC-ii))THEN
          m = HODSMC%nOutputDSMC-ii
          EXIT
        END IF
      END DO
      m = NINT((HODSMC%nOutputDSMC+SIGN(2.0*m-HODSMC%nOutputDSMC,PartPosRef(3,i)))/2)
      Source(1:3,k,l,m,iElem, iSpec) = Source(1:3,k,l,m,iElem, iSpec) + PartState(i,4:6)
      Source(4:6,k,l,m,iElem, iSpec) = Source(4:6,k,l,m,iElem, iSpec) + PartState(i,4:6)**2
      Source(7,k,l,m,iElem, iSpec) = Source(7,k,l,m,iElem, iSpec) + 1.0  !density
      IF(useDSMC)THEN
        IF ((CollisMode.EQ.2).OR.(CollisMode.EQ.3)) THEN
          IF (SpecDSMC(PartSpecies(i))%InterID.EQ.2) THEN
            Source(8:9,k,l,m,iElem, iSpec) = Source(8:9,k,l,m,iElem, iSpec) + PartStateIntEn(i,1:2)
          END IF
        END IF
        IF (DSMC%ElectronicModel) THEN
          Source(10,k,l,m,iElem, iSpec) = Source(10,k,l,m,iElem, iSpec) + PartStateIntEn(i,3)
        END IF
      END IF
      Source(11,k,l,m,iElem, iSpec) = Source(11,k,l,m,iElem, iSpec) + 1.0
    END IF
  END DO
  DSMC_HOSolution(:,:,:,:,:,:) = (DSMC_HOSolution(:,:,:,:,:,:) * (REAL(DSMC%SampNum) - 1.0) &
        + Source(:,:,:,:,:,:))/REAL(DSMC%SampNum)
CASE('cell_mean')
  kk = 1 ; ll = 1 ; mm = 1
  DO i=1,PDM%ParticleVecLength
    IF (PDM%ParticleInside(i)) THEN
      iSpec = PartSpecies(i)
      iElem = PEM%Element(i)
      DSMC_HOSolution(1:3,kk,ll,mm,iElem, iSpec) = DSMC_HOSolution(1:3,kk,ll,mm,iElem, iSpec) + PartState(i,4:6)
      DSMC_HOSolution(4:6,kk,ll,mm,iElem, iSpec) = DSMC_HOSolution(4:6,kk,ll,mm,iElem, iSpec) + PartState(i,4:6)**2
      DSMC_HOSolution(7,kk,ll,mm,iElem, iSpec) = DSMC_HOSolution(7,kk,ll,mm,iElem, iSpec) + 1.0  !density number
      IF(useDSMC)THEN
        IF ((CollisMode.EQ.2).OR.(CollisMode.EQ.3)) THEN
          IF (SpecDSMC(PartSpecies(i))%InterID.EQ.2) THEN
            DSMC_HOSolution(8:9,kk,ll,mm,iElem, iSpec) = DSMC_HOSolution(8:9,kk,ll,mm,iElem, iSpec) + PartStateIntEn(i,1:2)
          END IF
        END IF
        IF (DSMC%ElectronicModel) THEN
          DSMC_HOSolution(10,kk,ll,mm,iElem, iSpec) = DSMC_HOSolution(10,kk,ll,mm,iElem, iSpec) + PartStateIntEn(i,3)
        END IF
      END IF
      DSMC_HOSolution(11,kk,ll,mm,iElem, iSpec) = DSMC_HOSolution(11,kk,ll,mm,iElem, iSpec) + 1.0 !simpartnum
    END IF
  END DO
CASE('cell_volweight')
  ALLOCATE(BGMSourceCellVol(0:1,0:1,0:1,1:nElems,1:11, 1:nSpecies), &
          alphaSumCellVol(0:1,0:1,0:1,1:nElems, 1:nSpecies))
  BGMSourceCellVol(:,:,:,:,:,:) = 0.0
  alphaSumCellVol(:,:,:,:,:) = 0.0

  DO iPart=1,PDM%ParticleVecLength
  IF (PDM%ParticleInside(iPart)) THEN
    iElem = PEM%Element(iPart)
    iSpec = PartSpecies(iPart)
    IF(.NOT.DoRefMapping)THEN
      CALL GetPositionInRefElem(PartState(iPart,1:3),PartPosRef(1:3,iPart),iElem)
    END IF
    !CALL GeoCoordToMap(PartState(iPart,1:3), TempPartPos(1:3), iElem)
    TSource(:) = 0.0
    TSource(1:3) = PartState(iPart,4:6)
    TSource(4:6) = PartState(iPart,4:6)**2
    TSource(7) = 1.0  !density
    IF(useDSMC)THEN
      IF ((CollisMode.EQ.2).OR.(CollisMode.EQ.3)) THEN
        IF (SpecDSMC(PartSpecies(iPart))%InterID.EQ.2) THEN
          TSource(8:9)      =  PartStateIntEn(iPart,1:2)
        ELSE
          TSource(8:9) = 0.0
        END IF
      ELSE
        TSource(8:9) = 0.0
      END IF
      IF (DSMC%ElectronicModel) THEN
        TSource(10)     =  PartStateIntEn(iPart,3)
      ELSE
        TSource(10) = 0.0
      END IF
    ELSE
      TSource(8:10)=0.
    END IF
    TSource(11) = 1.0
    alpha1=(PartPosRef(1,iPart)+1.0)/2.0
    alpha2=(PartPosRef(2,iPart)+1.0)/2.0
    alpha3=(PartPosRef(3,iPart)+1.0)/2.0
    BGMSourceCellVol(0,0,0,iElem,1:11,iSpec) = BGMSourceCellVol(0,0,0,iElem,1:11,iSpec) &
            + (TSource(1:11) * (1-alpha1)*(1-alpha2)*(1-alpha3))
    BGMSourceCellVol(0,0,1,iElem,1:11,iSpec) = BGMSourceCellVol(0,0,1,iElem,1:11,iSpec) &
            + (TSource(1:11) * (1-alpha1)*(1-alpha2)*(alpha3))
    BGMSourceCellVol(0,1,0,iElem,1:11,iSpec) = BGMSourceCellVol(0,1,0,iElem,1:11,iSpec) &
            + (TSource(1:11) * (1-alpha1)*(alpha2)*(1-alpha3))
    BGMSourceCellVol(0,1,1,iElem,1:11,iSpec) = BGMSourceCellVol(0,1,1,iElem,1:11,iSpec) &
            + (TSource(1:11) * (1-alpha1)*(alpha2)*(alpha3))
    BGMSourceCellVol(1,0,0,iElem,1:11,iSpec) = BGMSourceCellVol(1,0,0,iElem,1:11,iSpec) &
            + (TSource(1:11) * (alpha1)*(1-alpha2)*(1-alpha3))
    BGMSourceCellVol(1,0,1,iElem,1:11,iSpec) = BGMSourceCellVol(1,0,1,iElem,1:11,iSpec) &
            + (TSource(1:11) * (alpha1)*(1-alpha2)*(alpha3))
    BGMSourceCellVol(1,1,0,iElem,1:11,iSpec) = BGMSourceCellVol(1,1,0,iElem,1:11,iSpec) &
            + (TSource(1:11) * (alpha1)*(alpha2)*(1-alpha3))
    BGMSourceCellVol(1,1,1,iElem,1:11,iSpec) = BGMSourceCellVol(1,1,1,iElem,1:11,iSpec) &
            + (TSource(1:11) * (alpha1)*(alpha2)*(alpha3))

    alphaSumCellVol(0,0,0,iElem,iSpec) = alphaSumCellVol(0,0,0,iElem,iSpec) + (1-alpha1)*(1-alpha2)*(1-alpha3)
    alphaSumCellVol(0,0,1,iElem,iSpec) = alphaSumCellVol(0,0,1,iElem,iSpec) + (1-alpha1)*(1-alpha2)*(alpha3)
    alphaSumCellVol(0,1,0,iElem,iSpec) = alphaSumCellVol(0,1,0,iElem,iSpec) + (1-alpha1)*(alpha2)*(1-alpha3)
    alphaSumCellVol(0,1,1,iElem,iSpec) = alphaSumCellVol(0,1,1,iElem,iSpec) + (1-alpha1)*(alpha2)*(alpha3)
    alphaSumCellVol(1,0,0,iElem,iSpec) = alphaSumCellVol(1,0,0,iElem,iSpec) + (alpha1)*(1-alpha2)*(1-alpha3)
    alphaSumCellVol(1,0,1,iElem,iSpec) = alphaSumCellVol(1,0,1,iElem,iSpec) + (alpha1)*(1-alpha2)*(alpha3)
    alphaSumCellVol(1,1,0,iElem,iSpec) = alphaSumCellVol(1,1,0,iElem,iSpec) + (alpha1)*(alpha2)*(1-alpha3)
    alphaSumCellVol(1,1,1,iElem,iSpec) = alphaSumCellVol(1,1,1,iElem,iSpec) + (alpha1)*(alpha2)*(alpha3)
  END IF
  END DO

  DO iSpec = 1, nSpecies
    DO iElem=1, nElems
      DO iLoopx = 0,1
        DO iLoopy = 0,1
          DO iLoopz = 0,1
            IF (alphaSumCellVol(iLoopx, iLoopy, iLoopz,iElem,iSpec).GT.0.0) THEN
              BGMSourceCellVol(iLoopx,iLoopy,iLoopz,iElem,1:6,iSpec) = BGMSourceCellVol(iLoopx,iLoopy,iLoopz,iElem,1:6,iSpec) &
                      / alphaSumCellVol(iLoopx,iLoopy,iLoopz,iElem,iSpec)
              BGMSourceCellVol(iLoopx,iLoopy,iLoopz,iElem,8:10,iSpec) = BGMSourceCellVol(iLoopx,iLoopy,iLoopz,iElem,8:10,iSpec) &
                     / alphaSumCellVol(iLoopx,iLoopy,iLoopz,iElem,iSpec)
            ELSE
              BGMSourceCellVol(iLoopx,iLoopy,iLoopz,iElem,1:6,iSpec) = 0.0
              BGMSourceCellVol(iLoopx,iLoopy,iLoopz,iElem,8:10,iSpec) = 0.0
            END IF
            BGMSourceCellVol(iLoopx,iLoopy,iLoopz,iElem,7,iSpec) = BGMSourceCellVol(iLoopx,iLoopy,iLoopz,iElem,7,iSpec) &
                / GEO%Volume(iElem) * Species(iSpec)%MacroParticleFactor
          END DO
        END DO
      END DO
    END DO
  END DO

  DO iSpec = 1, nSpecies
    DO iElem = 1, nElems
      DO kk = 0, HODSMC%nOutputDSMC
        DO ll = 0, HODSMC%nOutputDSMC
          DO mm = 0, HODSMC%nOutputDSMC
           alpha1 = DSMCSampCellVolW%xGP(kk)
           alpha2 = DSMCSampCellVolW%xGP(ll)
           alpha3 = DSMCSampCellVolW%xGP(mm)
           DSMC_HOSolution(:,kk,ll,mm,iElem,iSpec) = (DSMC_HOSolution(:,kk,ll,mm,iElem, iSpec) * (REAL(DSMC%SampNum) - 1.0) &
             +  (BGMSourceCellVol(0,0,0,iElem,:,iSpec) * (1-alpha1) * (1-alpha2) * (1-alpha3) + &
                BGMSourceCellVol(0,0,1,iElem,:,iSpec) * (1-alpha1) * (1-alpha2) * (alpha3) + &
                BGMSourceCellVol(0,1,0,iElem,:,iSpec) * (1-alpha1) * (alpha2) * (1-alpha3) + &
                BGMSourceCellVol(0,1,1,iElem,:,iSpec) * (1-alpha1) * (alpha2) * (alpha3) + &
                BGMSourceCellVol(1,0,0,iElem,:,iSpec) * (alpha1) * (1-alpha2) * (1-alpha3) + &
                BGMSourceCellVol(1,0,1,iElem,:,iSpec) * (alpha1) * (1-alpha2) * (alpha3) + &
                BGMSourceCellVol(1,1,0,iElem,:,iSpec) * (alpha1) * (alpha2) * (1-alpha3) + &
                BGMSourceCellVol(1,1,1,iElem,:,iSpec) * (alpha1) * (alpha2) * (alpha3))) / REAL(DSMC%SampNum)
         END DO !mm
       END DO !ll
     END DO !kk
   END DO !iElem
 END DO
 DEALLOCATE(BGMSourceCellVol, alphaSumCellVol)
CASE DEFAULT
 CALL abort(&
__STAMP__&
,'Unknown DepositionType in pic_depo.f90')
END SELECT
#if USE_LOADBALANCE
CALL LBPauseTime(LB_DSMC,tLBStart)
#endif /*USE_LOADBALANCE*/
END SUBROUTINE DSMCHO_data_sampling


SUBROUTINE DSMCHO_output_calc(nVar,nVar_quality,nVarloc,DSMC_MacroVal)
!===================================================================================================================================
!> Subroutine to calculate the solution U for writing into HDF5 format DSMC_output
!===================================================================================================================================
! MODULES
USE MOD_DSMC_Vars          ,ONLY: HODSMC, DSMC_HOSolution, CollisMode, SpecDSMC, DSMC,useDSMC
USE MOD_PreProc
USE MOD_Globals
USE MOD_Mesh_Vars          ,ONLY: nElems
USE MOD_Globals_Vars       ,ONLY: BoltzmannConst
USE MOD_Particle_Vars      ,ONLY: Species, nSpecies, WriteMacroVolumeValues
USE MOD_Particle_Mesh_Vars ,ONLY: GEO
USE MOD_TimeDisc_Vars      ,ONLY: time,TEnd,iter,dt
USE MOD_Restart_Vars       ,ONLY: RestartTime
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
INTEGER,INTENT(IN)      :: nVar,nVar_quality,nVarloc
REAL,INTENT(INOUT)      :: DSMC_MacroVal(1:nVar+nVar_quality,0:HODSMC%nOutputDSMC,0:HODSMC%nOutputDSMC,0:HODSMC%nOutputDSMC,nElems)
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
INTEGER                 :: iElem, kk , ll, mm, iSpec, nVarCount
REAL                    :: TVib_TempFac
REAL                    :: MolecPartNum, HeavyPartNum
!===================================================================================================================================
! nullify
DSMC_MacroVal = 0.0

! Write DG solution ----------------------------------------------------------------------------------------------------------------
IF (HODSMC%SampleType.EQ.'cell_mean') THEN
  nVarCount=0
  kk = 1 ; ll = 1 ; mm = 1
  DO iElem = 1, nElems ! element/cell main loop    
    !DO kk = 0, HODSMC%nOutputDSMC; DO ll = 0, HODSMC%nOutputDSMC; DO mm = 0, HODSMC%nOutputDSMC
    MolecPartNum = 0.0
    HeavyPartNum = 0.0
    ASSOCIATE ( Total_Velo     => DSMC_MacroVal(nVarLoc*nSpecies+1:nVarLoc*nSpecies+3,kk,ll,mm, iElem) ,&
                Total_Temp     => DSMC_MacroVal(nVarLoc*nSpecies+4:nVarLoc*nSpecies+6,kk,ll,mm, iElem) ,&
                Total_TempMean => DSMC_MacroVal(nVarLoc*nSpecies+12,kk,ll,mm, iElem)            ,&
                Total_Density  => DSMC_MacroVal(nVarLoc*nSpecies+7,kk,ll,mm, iElem)             ,&
                Total_TempVib  => DSMC_MacroVal(nVarLoc*nSpecies+8,kk,ll,mm, iElem)             ,&
                Total_TempRot  => DSMC_MacroVal(nVarLoc*nSpecies+9,kk,ll,mm, iElem)             ,&
                Total_Tempelec => DSMC_MacroVal(nVarLoc*nSpecies+10,kk,ll,mm, iElem)            ,&
                Total_PartNum  => DSMC_MacroVal(nVarLoc*nSpecies+11,kk,ll,mm, iElem)            &
                )
      DO iSpec = 1, nSpecies
        ASSOCIATE ( PartVelo   => DSMC_HOSolution(1:3,kk,ll,mm, iElem, iSpec) ,&
                    PartVelo2  => DSMC_HOSolution(4:6,kk,ll,mm, iElem, iSpec) ,&
                    PartNum    => DSMC_HOSolution(7,kk,ll,mm, iElem, iSpec)   ,&
                    PartEvib   => DSMC_HOSolution(8,kk,ll,mm, iElem, iSpec)   ,&
                    PartErot   => DSMC_HOSolution(9,kk,ll,mm, iElem, iSpec)   ,&
                    PartEelec  => DSMC_HOSolution(10,kk,ll,mm, iElem, iSpec)  ,&
                    SimPartNum => DSMC_HOSolution(11,kk,ll,mm, iElem, iSpec)  ,&
                    Macro_Velo     => DSMC_MacroVal(nVarLoc*(iSpec-1)+1:nVarLoc*(iSpec-1)+3,kk,ll,mm, iElem) ,&
                    Macro_Temp     => DSMC_MacroVal(nVarLoc*(iSpec-1)+4:nVarLoc*(iSpec-1)+6,kk,ll,mm, iElem) ,&
                    Macro_TempMean => DSMC_MacroVal(nVarLoc*(iSpec-1)+12,kk,ll,mm, iElem)                    ,&
                    Macro_Density  => DSMC_MacroVal(nVarLoc*(iSpec-1)+7,kk,ll,mm, iElem)                     ,&
                    Macro_TempVib  => DSMC_MacroVal(nVarLoc*(iSpec-1)+8,kk,ll,mm, iElem)                     ,&
                    Macro_TempRot  => DSMC_MacroVal(nVarLoc*(iSpec-1)+9,kk,ll,mm, iElem)                     ,&
                    Macro_Tempelec => DSMC_MacroVal(nVarLoc*(iSpec-1)+10,kk,ll,mm, iElem)                    ,&
                    Macro_PartNum  => DSMC_MacroVal(nVarLoc*(iSpec-1)+11,kk,ll,mm, iElem) &
                    )
          IF (PartNum.GT.0.0) THEN
            ! simulation particle number
            Macro_PartNum = PartNum / REAL(DSMC%SampNum)
            Total_PartNum = Total_PartNum + Macro_PartNum
            ! compute flow velocity
            Macro_Velo = PartVelo / PartNum
            Total_Velo = Total_Velo + Macro_Velo*Macro_PartNum
            ! compute flow Temperature
            Macro_Temp = Species(iSpec)%MassIC/BoltzmannConst * ( (PartVelo2/PartNum)- (PartVelo/PartNum)**2 )
            Total_Temp = Total_Temp + Macro_Temp*Macro_PartNum
            ! mean flow Temperature
            Macro_TempMean = (Macro_Temp(1) + Macro_Temp(2) + Macro_Temp(3)) / 3.
            Total_TempMean = Total_TempMean + Macro_TempMean*Macro_PartNum
            ! compute number density
            !IF (usevMPF) THEN ! if usevMPF MacroDSMC(iElem,iSpec)%PartNum == real number of particles
            !  Macro_Density = Macro_PartNum / GEO%Volume(iELem)
            !ELSE
              Macro_Density = Macro_PartNum*Species(iSpec)%MacroParticleFactor /GEO%Volume(iElem)
            !END IF
            Total_Density = Total_Density + Macro_Density
            ! compute internal energies / has to be changed for vfd 
            IF(useDSMC)THEN
              IF ((CollisMode.EQ.2).OR.(CollisMode.EQ.3))THEN
                IF ((SpecDSMC(iSpec)%InterID.EQ.2).OR.(SpecDSMC(iSpec)%InterID.EQ.20)) THEN
                  IF (DSMC%VibEnergyModel.EQ.0) THEN              ! SHO-model
                    IF(SpecDSMC(iSpec)%PolyatomicMol) THEN
                      IF( (PartEvib/PartNum) .GT. SpecDSMC(iSpec)%EZeroPoint ) THEN
                        Macro_TempVib = CalcTVibPoly(PartEvib/PartNum, iSpec)
                      ELSE
                        Macro_TempVib = 0.0
                      END IF
                    ELSE
                      TVib_TempFac = PartEvib / (PartNum * BoltzmannConst * SpecDSMC(iSpec)%CharaTVib)
                      IF (TVib_TempFac.LE.DSMC%GammaQuant) THEN
                        Macro_TempVib = 0.0
                      ELSE
                        Macro_TempVib = SpecDSMC(iSpec)%CharaTVib / LOG(1 + 1/(TVib_TempFac-DSMC%GammaQuant))
                      END IF
                    END IF
                  ELSE                                            ! TSHO-model
                    Macro_TempVib = CalcTVib(SpecDSMC(iSpec)%CharaTVib, PartEvib/PartNum, SpecDSMC(iSpec)%MaxVibQuant)
                  END IF
                  Macro_TempRot = PartERot / (PartNum*BoltzmannConst)
                  MolecPartNum = MolecPartNum + Macro_PartNum
                  IF (DSMC%ElectronicModel) THEN
                    IF (SpecDSMC(iSpec)%InterID.NE.4) THEN
                      Macro_TempElec = CalcTelec(PartEelec/PartNum, iSpec)
                      HeavyPartNum = HeavyPartNum + Macro_PartNum
                    END IF
                  END IF
                  Total_TempVib  = Total_TempVib  + Macro_TempVib*Macro_PartNum
                  Total_TempRot  = Total_TempRot  + Macro_TempRot*Macro_PartNum
                  Total_TempElec = Total_TempElec + Macro_TempElec*Macro_PartNum
                END IF
              END IF
            END IF
          END IF
        END ASSOCIATE
      END DO
      IF (Total_PartNum.GT.0.0) THEN
        Total_Velo = Total_Velo / Total_PartNum
        Total_Temp = Total_Temp / Total_PartNum
        Total_TempMean = Total_TempMean / Total_PartNum
        IF(useDSMC)THEN
          IF (((CollisMode.EQ.2).OR.(CollisMode.EQ.3)).AND.(MolecpartNum.GT.0))THEN
            Total_TempVib = Total_TempVib / MolecPartNum
            Total_TempRot = Total_TempRot / MolecPartNum
          END IF
          IF ( DSMC%ElectronicModel .AND.(HeavyPartNum.GT. 0)) THEN
            Total_TempElec = Total_TempElec / HeavyPartNum
          END IF
        END IF
      END IF
    END ASSOCIATE
  END DO

  ! write dsmc quality values
  IF (DSMC%CalcQualityFactors) THEN
    DO iElem=1,nElems
    !DO kk = 0, HODSMC%nOutputDSMC; DO ll = 0, HODSMC%nOutputDSMC; DO mm = 0, HODSMC%nOutputDSMC
      IF(WriteMacroVolumeValues) THEN
        DSMC_MacroVal(nVar+1,kk,ll,mm,iElem) = DSMC%QualityFacSamp(iElem,1) / REAL(DSMC%SampNum)
        DSMC_MacroVal(nVar+2,kk,ll,mm,iElem) = DSMC%QualityFacSamp(iElem,2) / REAL(DSMC%SampNum)
        DSMC_MacroVal(nVar+3,kk,ll,mm,iElem) = DSMC%QualityFacSamp(iElem,3) / REAL(DSMC%SampNum)
      ELSE
        IF (RestartTime.GT.(1-DSMC%TimeFracSamp)*TEnd) THEN
          DSMC_MacroVal(nVar+1,kk,ll,mm,iElem) = DSMC%QualityFacSamp(iElem,1) / REAL(iter)
          DSMC_MacroVal(nVar+2,kk,ll,mm,iElem) = DSMC%QualityFacSamp(iElem,2) / REAL(iter)
          DSMC_MacroVal(nVar+3,kk,ll,mm,iElem) = DSMC%QualityFacSamp(iElem,3) / REAL(iter)
        ELSE
          DSMC_MacroVal(nVar+1,kk,ll,mm,iElem) = DSMC%QualityFacSamp(iElem,1)*dt / (Time-(1-DSMC%TimeFracSamp)*TEnd)
          DSMC_MacroVal(nVar+2,kk,ll,mm,iElem) = DSMC%QualityFacSamp(iElem,2)*dt / (Time-(1-DSMC%TimeFracSamp)*TEnd)
          DSMC_MacroVal(nVar+3,kk,ll,mm,iElem) = DSMC%QualityFacSamp(iElem,3)*dt / (Time-(1-DSMC%TimeFracSamp)*TEnd)
        END IF
      END IF
    !END DO; END DO; END DO
    END DO
  END IF
  ! fill remaining node values with calculated values
  DO mm = 0, HODSMC%nOutputDSMC; DO ll = 0, HODSMC%nOutputDSMC; DO kk = 0, HODSMC%nOutputDSMC
    DSMC_MacroVal(:,kk,ll,mm,:) = DSMC_MacroVal(:,1,1,1,:)
  END DO; END DO; END DO
ELSE ! all other sampling types
  nVarCount=0
  DO iSpec = 1, nSpecies
    DO iElem = 1, nElems ! element/cell main loop    
      DO kk = 0, HODSMC%nOutputDSMC; DO ll = 0, HODSMC%nOutputDSMC; DO mm = 0, HODSMC%nOutputDSMC
        SELECT CASE(TRIM(HODSMC%SampleType))
        CASE('cartmesh_volumeweighting','cell_volweight')
          ! compute flow velocity
          DSMC_MacroVal(nVarCount+1:nVarCount+3,kk,ll,mm, iElem) = DSMC_HOSolution(1:3,kk,ll,mm, iElem, iSpec)
          ! compute flow Temperature
          DSMC_MacroVal(nVarCount+4:nVarCount+6,kk,ll,mm, iElem) = Species(iSpec)%MassIC/ BoltzmannConst &
                              * (DSMC_HOSolution(4:6,kk,ll,mm, iElem, iSpec)- DSMC_HOSolution(1:3,kk,ll,mm, iElem, iSpec)**2)
          ! compute density
          DSMC_MacroVal(nVarCount+7,kk,ll,mm, iElem) = DSMC_HOSolution(7,kk,ll,mm, iElem, iSpec)
            !       if usevMPF MacroDSMC(iElem,iSpec)%PartNum == real number of particles
          !      IF (usevMPF) THEN
          !        MacroDSMC(iElem,iSpec)%NumDens = MacroDSMC(iElem,iSpec)%PartNum / GEO%Volume(iElem)
          !      ELSE 
          !        MacroDSMC(iElem,iSpec)%NumDens = MacroDSMC(iElem,iSpec)%PartNum * &
          !         Species(iSpec)%MacroParticleFactor / GEO%Volume(iElem)
          !      END IF
          ! compute internal energies / has to be changed for vfd 
          IF(useDSMC)THEN
            IF ((CollisMode.EQ.2).OR.(CollisMode.EQ.3))THEN
              IF ((SpecDSMC(iSpec)%InterID.EQ.2).OR.(SpecDSMC(iSpec)%InterID.EQ.20)) THEN
                IF (DSMC%VibEnergyModel.EQ.0) THEN              ! SHO-model
                    IF(SpecDSMC(iSpec)%PolyatomicMol) THEN
                      IF( (DSMC_HOSolution(8,kk,ll,mm, iElem, iSpec)) &
                          .GT. SpecDSMC(iSpec)%EZeroPoint) THEN
                        DSMC_MacroVal(nVarCount+8,kk,ll,mm, iElem) = CalcTVibPoly(DSMC_HOSolution(8,kk,ll,mm,iElem,iSpec),iSpec)
                      ELSE
                        DSMC_MacroVal(nVarCount+8,kk,ll,mm, iElem) = 0.0
                      END IF
                    ELSE
                      TVib_TempFac=DSMC_HOSolution(8,kk,ll,mm, iElem, iSpec)/ (BoltzmannConst*SpecDSMC(iSpec)%CharaTVib)
                      IF (TVib_TempFac.LE.DSMC%GammaQuant) THEN
                        DSMC_MacroVal(nVarCount+8,kk,ll,mm, iElem) = 0.0
                      ELSE
                        DSMC_MacroVal(nVarCount+8,kk,ll,mm, iElem) = SpecDSMC(iSpec)%CharaTVib &
                                                                    / LOG(1 + 1/(TVib_TempFac-DSMC%GammaQuant))
                      END IF
                    END IF
                ELSE                                            ! TSHO-model
                  DSMC_MacroVal(nVarCount+8,kk,ll,mm, iElem)  = CalcTVib(SpecDSMC(iSpec)%CharaTVib &
                      , DSMC_HOSolution(8,kk,ll,mm, iElem, iSpec), SpecDSMC(iSpec)%MaxVibQuant)
                END IF
                DSMC_MacroVal(nVarCount+9,kk,ll,mm, iElem) = DSMC_HOSolution(9,kk,ll,mm, iElem, iSpec)/(BoltzmannConst)
                IF (DSMC%ElectronicModel) THEN
                  DSMC_MacroVal(nVarCount+10,kk,ll,mm, iElem)= CalcTelec( DSMC_HOSolution(10,kk,ll,mm, iElem, iSpec), iSpec)
                END IF
              END IF
            END IF
          END IF
          DSMC_MacroVal(nVarCount+11,kk,ll,mm, iElem) = DSMC_HOSolution(11,kk,ll,mm, iElem, iSpec)
        CASE('nearest_gausspoint')
          IF (DSMC_HOSolution(11,kk,ll,mm, iElem, iSpec).GT.0.0) THEN
            ! compute flow velocity
            DSMC_MacroVal(nVarCount+1:nVarCount+3,kk,ll,mm, iElem) = DSMC_HOSolution(1:3,kk,ll,mm, iElem, iSpec) &
                  /DSMC_HOSolution(11,kk,ll,mm, iElem, iSpec)
            ! compute flow Temperature
            DSMC_MacroVal(nVarCount+4:nVarCount+6,kk,ll,mm, iElem) = Species(iSpec)%MassIC/ BoltzmannConst &
                                * (DSMC_HOSolution(4:6,kk,ll,mm, iElem, iSpec) /DSMC_HOSolution(11,kk,ll,mm, iElem, iSpec) &
                              - (DSMC_HOSolution(1:3,kk,ll,mm, iElem, iSpec)/DSMC_HOSolution(11,kk,ll,mm, iElem, iSpec))**2)
            ! compute density
            DSMC_MacroVal(nVarCount+7,kk,ll,mm, iElem) = DSMC_HOSolution(7,kk,ll,mm, iElem, iSpec)*HODSMC%sJ(kk,ll,mm,iElem) &
              /(HODSMC%DSMC_wGP(kk)*HODSMC%DSMC_wGP(ll)*HODSMC%DSMC_wGP(mm))*Species(iSpec)%MacroParticleFactor
              !       if usevMPF MacroDSMC(iElem,iSpec)%PartNum == real number of particles
            !      IF (usevMPF) THEN
            !        MacroDSMC(iElem,iSpec)%NumDens = MacroDSMC(iElem,iSpec)%PartNum / GEO%Volume(iElem)
            !      ELSE 
            !        MacroDSMC(iElem,iSpec)%NumDens = MacroDSMC(iElem,iSpec)%PartNum * &
            !         Species(iSpec)%MacroParticleFactor / GEO%Volume(iElem)
            !      END IF
            ! compute internal energies / has to be changed for vfd 
            IF(useDSMC)THEN
              IF ((CollisMode.EQ.2).OR.(CollisMode.EQ.3))THEN
              IF ((SpecDSMC(iSpec)%InterID.EQ.2).OR.(SpecDSMC(iSpec)%InterID.EQ.20)) THEN
                  IF (DSMC%VibEnergyModel.EQ.0) THEN              ! SHO-model
                    IF(SpecDSMC(iSpec)%PolyatomicMol) THEN
                      IF( (DSMC_HOSolution(8,kk,ll,mm, iElem, iSpec)/DSMC_HOSolution(11,kk,ll,mm, iElem, iSpec)) &
                          .GT. SpecDSMC(iSpec)%EZeroPoint) THEN
                        DSMC_MacroVal(nVarCount+8,kk,ll,mm, iElem) = CalcTVibPoly(DSMC_HOSolution(8,kk,ll,mm,iElem,iSpec) &
                                                                                  / DSMC_HOSolution(11,kk,ll,mm,iElem,iSpec),iSpec)
                      ELSE
                        DSMC_MacroVal(nVarCount+8,kk,ll,mm, iElem) = 0.0
                      END IF
                    ELSE
                      TVib_TempFac=DSMC_HOSolution(8,kk,ll,mm, iElem, iSpec)/ (DSMC_HOSolution(11,kk,ll,mm, iElem, iSpec) &
                            *BoltzmannConst*SpecDSMC(iSpec)%CharaTVib)
                      IF (TVib_TempFac.LE.DSMC%GammaQuant) THEN
                        DSMC_MacroVal(nVarCount+8,kk,ll,mm, iElem) = 0.0
                      ELSE
                        DSMC_MacroVal(nVarCount+8,kk,ll,mm, iElem) = SpecDSMC(iSpec)%CharaTVib &
                                                                    / LOG(1 + 1/(TVib_TempFac-DSMC%GammaQuant))
                      END IF
                    END IF
                  ELSE                                            ! TSHO-model
                    DSMC_MacroVal(nVarCount+8,kk,ll,mm, iElem)  = CalcTVib(SpecDSMC(iSpec)%CharaTVib & 
                        , DSMC_HOSolution(8,kk,ll,mm, iElem, iSpec) &
                        /DSMC_HOSolution(11,kk,ll,mm, iElem, iSpec),SpecDSMC(iSpec)%MaxVibQuant)
                  END IF
                  DSMC_MacroVal(nVarCount+9,kk,ll,mm, iElem) = DSMC_HOSolution(9,kk,ll,mm, iElem, iSpec) &
                     /(DSMC_HOSolution(11,kk,ll,mm, iElem, iSpec)*BoltzmannConst)
                  IF (DSMC%ElectronicModel) THEN
                    DSMC_MacroVal(nVarCount+10,kk,ll,mm, iElem)= CalcTelec( DSMC_HOSolution(10,kk,ll,mm, iElem, iSpec)&
                        /DSMC_HOSolution(11,kk,ll,mm, iElem, iSpec), iSpec)
                  END IF
                END IF
              END IF
            END IF
          ELSE
            DSMC_MacroVal(nVarCount+1:nVarCount+10,kk,ll,mm, iElem) = 0.0
          END IF
          DSMC_MacroVal(nVarCount+11,kk,ll,mm, iElem) = DSMC_HOSolution(11,kk,ll,mm, iElem, iSpec)
        END SELECT
      END DO; END DO; END DO
    END DO
    ! set counter for species    
    nVarCount=nVarCount+nVarloc
  END DO

  ! write total values
  DO iElem = 1, nElems ! element/cell main loop    
    DO kk = 0, HODSMC%nOutputDSMC; DO ll = 0, HODSMC%nOutputDSMC; DO mm = 0, HODSMC%nOutputDSMC
      MolecPartNum = 0
      HeavyPartNum = 0
      DO iSpec = 1, nSpecies
        IF (DSMC_HOSolution(11,kk,ll,mm, iElem, iSpec).GT.0.0) THEN
          ! compute flow velocity
          DSMC_MacroVal(nVarCount+1:nVarCount+3,kk,ll,mm, iElem) = DSMC_MacroVal(nVarCount+1:nVarCount+3,kk,ll,mm, iElem) &
              + DSMC_HOSolution(1:3,kk,ll,mm, iElem, iSpec)
              !/ DSMC_HOSolution(11,kk,ll,mm, iElem, iSpec) * DSMC_HOSolution(11,kk,ll,mm, iElem, iSpec)
          ! compute flow Temperature
          DSMC_MacroVal(nVarCount+4:nVarCount+6,kk,ll,mm, iElem) = DSMC_MacroVal(nVarCount+4:nVarCount+6,kk,ll,mm, iElem) &
                              + Species(iSpec)%MassIC/ BoltzmannConst &
                              * (DSMC_HOSolution(4:6,kk,ll,mm, iElem, iSpec) /DSMC_HOSolution(11,kk,ll,mm, iElem, iSpec) &
                            - (DSMC_HOSolution(1:3,kk,ll,mm, iElem, iSpec)/DSMC_HOSolution(11,kk,ll,mm, iElem, iSpec))**2) &
                            * DSMC_HOSolution(11,kk,ll,mm, iElem, iSpec)
          IF(useDSMC)THEN
            IF ((CollisMode.EQ.2).OR.(CollisMode.EQ.3))THEN
              IF ((SpecDSMC(iSpec)%InterID.EQ.2).OR.(SpecDSMC(iSpec)%InterID.EQ.20)) THEN
                IF (DSMC%VibEnergyModel.EQ.0) THEN              ! SHO-model
                  IF(SpecDSMC(iSpec)%PolyatomicMol) THEN
                    IF( (DSMC_HOSolution(8,kk,ll,mm, iElem, iSpec)/DSMC_HOSolution(11,kk,ll,mm, iElem, iSpec)) &
                        .GT. SpecDSMC(iSpec)%EZeroPoint) THEN
                      DSMC_MacroVal(nVarCount+8,kk,ll,mm, iElem) = DSMC_MacroVal(nVarCount+8,kk,ll,mm, iElem) &
                          + CalcTVibPoly(DSMC_HOSolution(8,kk,ll,mm,iElem,iSpec) / DSMC_HOSolution(11,kk,ll,mm,iElem,iSpec),iSpec) &
                          * DSMC_HOSolution(11,kk,ll,mm,iElem,iSpec)
                    END IF
                  ELSE
                    TVib_TempFac=DSMC_HOSolution(8,kk,ll,mm, iElem, iSpec)/ (DSMC_HOSolution(11,kk,ll,mm, iElem, iSpec) &
                          *BoltzmannConst*SpecDSMC(iSpec)%CharaTVib)
                    IF (TVib_TempFac.GT.DSMC%GammaQuant) THEN
                      DSMC_MacroVal(nVarCount+8,kk,ll,mm, iElem) = DSMC_MacroVal(nVarCount+8,kk,ll,mm, iElem) &
                          + SpecDSMC(iSpec)%CharaTVib / LOG(1 + 1/(TVib_TempFac-DSMC%GammaQuant)) &
                          * DSMC_HOSolution(11,kk,ll,mm, iElem, iSpec)
                    END IF
                  END IF
                ELSE                                            ! TSHO-model
                  DSMC_MacroVal(nVarCount+8,kk,ll,mm, iElem)  = DSMC_MacroVal(nVarCount+8,kk,ll,mm, iElem) &
                      + CalcTVib(SpecDSMC(iSpec)%CharaTVib &
                      , DSMC_HOSolution(8,kk,ll,mm, iElem, iSpec)&
                      /DSMC_HOSolution(11,kk,ll,mm, iElem, iSpec),SpecDSMC(iSpec)%MaxVibQuant) &
                      * DSMC_HOSolution(11,kk,ll,mm, iElem, iSpec)
                END IF
                DSMC_MacroVal(nVarCount+9,kk,ll,mm, iElem) = DSMC_MacroVal(nVarCount+9,kk,ll,mm, iElem) &
                    + DSMC_HOSolution(9,kk,ll,mm, iElem, iSpec) / (DSMC_HOSolution(11,kk,ll,mm, iElem, iSpec)*BoltzmannConst) &
                    * DSMC_HOSolution(11,kk,ll,mm, iElem, iSpec)
                MolecPartNum = MolecPartNum + DSMC_HOSolution(11,kk,ll,mm, iElem, iSpec)
                IF (DSMC%ElectronicModel) THEN
                  IF (SpecDSMC(iSpec)%InterID.NE.4) THEN
                    DSMC_MacroVal(nVarCount+10,kk,ll,mm, iElem)= DSMC_MacroVal(nVarCount+10,kk,ll,mm, iElem) &
                        + CalcTelec( DSMC_HOSolution(10,kk,ll,mm, iElem, iSpec)&
                        /DSMC_HOSolution(11,kk,ll,mm, iElem, iSpec), iSpec) &
                        * DSMC_HOSolution(11,kk,ll,mm, iElem, iSpec)
                    HeavyPartNum = HeavyPartNum + DSMC_HOSolution(11,kk,ll,mm, iElem, iSpec)
                  END IF
                END IF
              END IF
            END IF
          END IF
        END IF
        ! compute total number of particles
        DSMC_MacroVal(nVarCount+11,kk,ll,mm, iElem) = DSMC_MacroVal(nVarCount+11,kk,ll,mm, iElem) &
            + DSMC_HOSolution(11,kk,ll,mm, iElem, iSpec)
      END DO
      IF (DSMC_Macroval(nVarCount+11,kk,ll,mm, iElem).GT.0) THEN
        ! compute flow velocity
        DSMC_MacroVal(nVarCount+1:nVarCount+3,kk,ll,mm, iElem) = DSMC_MacroVal(nVarCount+1:nVarCount+3,kk,ll,mm, iElem) &
            / DSMC_MacroVal(nVarCount+11,kk,ll,mm, iElem)
        ! compute flow Temperature
        DSMC_MacroVal(nVarCount+4:nVarCount+6,kk,ll,mm, iElem) = DSMC_MacroVal(nVarCount+4:nVarCount+6,kk,ll,mm, iElem) &
            / DSMC_MacroVal(nVarCount+11,kk,ll,mm, iElem)
        IF(useDSMC)THEN
          IF (((CollisMode.EQ.2).OR.(CollisMode.EQ.3)).AND.(MolecpartNum.GT.0))THEN
                  DSMC_MacroVal(nVarCount+8,kk,ll,mm, iElem)  = DSMC_MacroVal(nVarCount+8,kk,ll,mm, iElem) &
                      / MolecPartNum
                  DSMC_MacroVal(nVarCount+9,kk,ll,mm, iElem)  = DSMC_MacroVal(nVarCount+8,kk,ll,mm, iElem) &
                      / MolecPartNum
          END IF
          IF ( DSMC%ElectronicModel .AND.(HeavyPartNum.GT. 0)) THEN
            DSMC_MacroVal(nVarCount+10,kk,ll,mm, iElem) = DSMC_MacroVal(nVarCount+10,kk,ll,mm, iElem) / HeavyPartNum
          END IF
        END IF
      END IF
      ! compute density
      DSMC_MacroVal(nVarCount+7,kk,ll,mm, iElem) = DSMC_MacroVal(nVarCount+11,kk,ll,mm, iElem) &
                                                 / GEO%Volume(iElem) * Species(1)%MacroParticleFactor
      ! mean flow Temperature
      DSMC_MacroVal(nVarCount+12,kk,ll,mm, iElem) = (DSMC_MacroVal(nVarCount+4,kk,ll,mm, iElem) &
                                                  + DSMC_MacroVal(nVarCount+5,kk,ll,mm, iElem) &
                                                  + DSMC_MacroVal(nVarCount+6,kk,ll,mm, iElem)) / 3.
    END DO; END DO; END DO
  END DO
END IF


END SUBROUTINE DSMCHO_output_calc

SUBROUTINE WriteDSMCHOToHDF5(MeshFileName,OutputTime, FutureTime)
!===================================================================================================================================
!> Subroutine to write the solution U to HDF5 format
!> Is used for postprocessing and for restart
!===================================================================================================================================
! MODULES
USE MOD_DSMC_Vars     ,ONLY: HODSMC, DSMC
USE MOD_PreProc
USE MOD_Globals
USE MOD_Globals_Vars  ,ONLY: ProjectName
USE MOD_Mesh_Vars     ,ONLY: offsetElem,nGlobalElems, nElems
USE MOD_io_HDF5
USE MOD_HDF5_output   ,ONLY: WriteArrayToHDF5
USE MOD_Particle_Vars ,ONLY: nSpecies
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
CHARACTER(LEN=*),INTENT(IN)    :: MeshFileName
REAL,INTENT(IN)                :: OutputTime
REAL,INTENT(IN),OPTIONAL       :: FutureTime
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
CHARACTER(LEN=255)             :: FileName
CHARACTER(LEN=255)             :: SpecID
CHARACTER(LEN=255),ALLOCATABLE :: StrVarNames(:)
INTEGER                        :: nVar, nVar_quality, nVarloc, nVarCount, ALLOCSTAT, iSpec
REAL,ALLOCATABLE               :: DSMC_MacroVal(:,:,:,:,:)
REAL                           :: StartT,EndT
!===================================================================================================================================
  SWRITE(UNIT_stdOut,'(a)',ADVANCE='NO')' WRITE DSMC-HO TO HDF5 FILE...'
#ifdef MPI
  StartT=MPI_WTIME()
#else 
  StartT=LOCALTIME()
#endif

! Create dataset attribute "VarNames"
nVarloc=DSMC_NVARS
nVar=nVarloc*(nSpecies+1)
IF (DSMC%CalcQualityFactors) THEN
  nVar_quality=3
ELSE
  nVar_quality=0
END IF
ALLOCATE(StrVarNames(1:nVar+nVar_quality))
nVarCount=0
DO iSpec=1,nSpecies
  WRITE(SpecID,'(I3.3)') iSpec
  StrVarNames(nVarCount+DSMC_VELOX      )='Spec'//TRIM(SpecID)//'_VeloX'
  StrVarNames(nVarCount+DSMC_VELOY      )='Spec'//TRIM(SpecID)//'_VeloY'
  StrVarNames(nVarCount+DSMC_VELOZ      )='Spec'//TRIM(SpecID)//'_VeloZ'
  StrVarNames(nVarCount+DSMC_TEMPX      )='Spec'//TRIM(SpecID)//'_TempX'
  StrVarNames(nVarCount+DSMC_TEMPY      )='Spec'//TRIM(SpecID)//'_TempY'
  StrVarNames(nVarCount+DSMC_TEMPZ      )='Spec'//TRIM(SpecID)//'_TempZ'
  StrVarNames(nVarCount+DSMC_DENSITY    )='Spec'//TRIM(SpecID)//'_Density'
  StrVarNames(nVarCount+DSMC_TVIB       )='Spec'//TRIM(SpecID)//'_TVib'
  StrVarNames(nVarCount+DSMC_TROT       )='Spec'//TRIM(SpecID)//'_TRot'
  StrVarNames(nVarCount+DSMC_TELEC      )='Spec'//TRIM(SpecID)//'_TElec'
  StrVarNames(nVarCount+DSMC_POINTWEIGHT)='Spec'//TRIM(SpecID)//'_PointWeight'
  StrVarNames(nVarCount+DSMC_TEMPMEAN   )='Spec'//TRIM(SpecID)//'_TTransMean'
  nVarCount=nVarCount+nVarloc
END DO ! iSpec=1,nSpecies
! fill varnames for total values
StrVarNames(nVarCount+DSMC_VELOX      )='Total_VeloX'
StrVarNames(nVarCount+DSMC_VELOY      )='Total_VeloY'
StrVarNames(nVarCount+DSMC_VELOZ      )='Total_VeloZ'
StrVarNames(nVarCount+DSMC_TEMPX      )='Total_TempX'
StrVarNames(nVarCount+DSMC_TEMPY      )='Total_TempY'
StrVarNames(nVarCount+DSMC_TEMPZ      )='Total_TempZ'
StrVarNames(nVarCount+DSMC_DENSITY    )='Total_Density'
StrVarNames(nVarCount+DSMC_TVIB       )='Total_TVib'
StrVarNames(nVarCount+DSMC_TROT       )='Total_TRot'
StrVarNames(nVarCount+DSMC_TELEC      )='Total_TElec'
StrVarNames(nVarCount+DSMC_POINTWEIGHT)='Total_PointWeight'
StrVarNames(nVarCount+DSMC_TEMPMEAN   )='Total_TTransMean'
nVarCount=nVarCount+nVarloc
IF (DSMC%CalcQualityFactors) THEN
  StrVarNames(nVarCount+1) ='DSMC_MaxCollProb'
  StrVarNames(nVarCount+2) ='DSMC_MeanCollProb'
  StrVarNames(nVarCount+3) ='DSMC_MCS_over_MFP'
END IF

! Generate skeleton for the file with all relevant data on a single proc (MPIRoot)
FileName=TRIM(TIMESTAMP(TRIM(ProjectName)//'_DSMCHOState',OutputTime))//'.h5'
! PO:
! excahnge PP_N through Nout
IF(MPIRoot) CALL GenerateDSMCHOFileSkeleton('DSMCHOState',nVar+nVar_quality,StrVarNames,MeshFileName,OutputTime,FutureTime)
#ifdef MPI
CALL MPI_BARRIER(MPI_COMM_WORLD,iError)
#endif

CALL OpenDataFile(FileName,create=.false.,single=.FALSE.,readOnly=.FALSE.,communicatorOpt=MPI_COMM_WORLD)

ALLOCATE(DSMC_MacroVal(1:nVar+nVar_quality,0:HODSMC%nOutputDSMC,0:HODSMC%nOutputDSMC,0:HODSMC%nOutputDSMC,nElems), STAT=ALLOCSTAT)
IF (ALLOCSTAT.NE.0) THEN
  CALL abort(&
__STAMP__&
  ,' Cannot allocate output array DSMC_MacroVal array!')
END IF
CALL DSMCHO_output_calc(nVar,nVar_quality,nVarloc,DSMC_MacroVal)

IF (HODSMC%SampleType.EQ.'cell_mean') THEN
  CALL WriteArrayToHDF5(DataSetName='ElemData', rank=2,&
                    nValGlobal=(/nVar+nVar_quality,nGlobalElems/),&
                    nVal=      (/nVar+nVar_quality,PP_nElems/),&
                    offset=    (/0,     offsetElem/),&
                    collective=.false.,  RealArray=DSMC_MacroVal(:,1,1,1,:))
ELSE
  CALL WriteArrayToHDF5(DataSetName='DG_Solution', rank=5,&
                    nValGlobal=(/nVar+nVar_quality,HODSMC%nOutputDSMC+1,HODSMC%nOutputDSMC+1,HODSMC%nOutputDSMC+1,nGlobalElems/),&
                    nVal=      (/nVar+nVar_quality,HODSMC%nOutputDSMC+1,HODSMC%nOutputDSMC+1,HODSMC%nOutputDSMC+1,PP_nElems/),&
                    offset=    (/0,      0,     0,     0,     offsetElem/),&
                    collective=.false.,  RealArray=DSMC_MacroVal)
END IF
!IF (DSMC%CalcQualityFactors) THEN
!  CALL WriteArrayToHDF5(DataSetName='DG_Solution', rank=5,&
!                    nValGlobal=(/nVar_quality,HODSMC%nOutputDSMC+1,HODSMC%nOutputDSMC+1,HODSMC%nOutputDSMC+1,nGlobalElems/),&
!                    nVal=      (/nVar_quality,HODSMC%nOutputDSMC+1,HODSMC%nOutputDSMC+1,HODSMC%nOutputDSMC+1,PP_nElems/),&
!                    offset=    (/nVar,      0,     0,     0,     offsetElem/),&
!                        collective=.false.,RealArray=DSMC%QualityFactors(:,:,:,:,:))
!END IF

CALL CloseDataFile()

DEALLOCATE(StrVarNames)
DEALLOCATE(DSMC_MacroVal)
#ifdef MPI
IF(MPIROOT)THEN
  EndT=MPI_WTIME()
  SWRITE(UNIT_stdOut,'(A,F0.3,A)',ADVANCE='YES')'DONE  [',EndT-StartT,'s]'
END IF
#else
EndT=LOCALTIME()
SWRITE(UNIT_stdOut,'(A,F0.3,A)',ADVANCE='YES')'DONE  [',EndT-StartT,'s]'
#endif
END SUBROUTINE WriteDSMCHOToHDF5


SUBROUTINE GenerateDSMCHOFileSkeleton(TypeString,nVar,StrVarNames,MeshFileName,OutputTime,FutureTime)
!===================================================================================================================================
!> Subroutine that generates the output file on a single processor and writes all the necessary attributes (better MPI performance)
!===================================================================================================================================
! MODULES
USE MOD_PreProc
USE MOD_Globals
USE MOD_Globals_Vars  ,ONLY: ProjectName
!USE MOD_PreProcFlags
USE MOD_io_HDF5
USE MOD_DSMC_Vars     ,ONLY: HODSMC
USE MOD_HDF5_Output   ,ONLY: WriteAttributeToHDF5, WriteHDF5Header
USE MOD_Particle_Vars ,ONLY: nSpecies
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
CHARACTER(LEN=*),INTENT(IN)    :: TypeString
INTEGER,INTENT(IN)             :: nVar
CHARACTER(LEN=255)             :: StrVarNames(nVar)
CHARACTER(LEN=*),INTENT(IN)    :: MeshFileName
REAL,INTENT(IN)                :: OutputTime
REAL,INTENT(IN),OPTIONAL       :: FutureTime
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
CHARACTER(LEN=255)             :: FileName,MeshFile255
!CHARACTER(LEN=255),ALLOCATABLE :: params(:)
CHARACTER(LEN=255)             :: NodeTypeTemp
!===================================================================================================================================
! Create file
FileName=TRIM(TIMESTAMP(TRIM(ProjectName)//'_'//TRIM(TypeString),OutputTime))//'.h5'
CALL OpenDataFile(TRIM(FileName),create=.TRUE.,single=.TRUE.,readOnly=.FALSE.)

SELECT CASE(TRIM(HODSMC%NodeType))
CASE('visu')
  NodeTypeTemp = 'VISU'
CASE('gauss')
  NodeTypeTemp = 'GAUSS'
CASE('gauss-lobatto')
  NodeTypeTemp = 'GAUSS-LOBATTO'
CASE DEFAULT
  CALL abort(&
__STAMP__&
,'Unknown HODSMCNodeType in dsmc_analyze.f90')
END SELECT

CALL WriteHDF5Header(TRIM('DSMCHOState'),File_ID)

! Write dataset properties "Time","MeshFile","NextFile","NodeType","VarNames"
CALL WriteAttributeToHDF5(File_ID,'SampleType',1,StrScalar=(/TRIM(HODSMC%SampleType)/))
CALL WriteAttributeToHDF5(File_ID,'N',1,IntegerScalar=HODSMC%nOutputDSMC)
CALL WriteAttributeToHDF5(File_ID,'NodeType',1,StrScalar=(/NodeTypeTemp/))
CALL WriteAttributeToHDF5(File_ID,'Time',1,RealScalar=OutputTime)
CALL WriteAttributeToHDF5(File_ID,'MeshFile',1,StrScalar=(/TRIM(MeshFileName)/))
IF(PRESENT(FutureTime))THEN
  MeshFile255=TRIM(TIMESTAMP(TRIM(ProjectName)//'_'//TRIM(TypeString),FutureTime))//'.h5'
  CALL WriteAttributeToHDF5(File_ID,'NextFile',1,StrScalar=(/MeshFile255/))
END IF
IF (HODSMC%SampleType.EQ.'cell_mean') THEN
  CALL WriteAttributeToHDF5(File_ID,'VarNamesAdd',nVar,StrArray=StrVarNames)
ELSE
  CALL WriteAttributeToHDF5(File_ID,'VarNames',nVar,StrArray=StrVarNames)
END IF

CALL WriteAttributeToHDF5(File_ID,'NSpecies',1,IntegerScalar=nSpecies)

CALL CloseDataFile()
END SUBROUTINE GenerateDSMCHOFileSkeleton


#ifndef MPI
SUBROUTINE PeriodicSourceExchangeDSMCHO(BGMSource, alphasum)
!===================================================================================================================================
!> Exchange sources in periodic case
!===================================================================================================================================
! use MODULES                                                    
USE MOD_Particle_Mesh_Vars, ONLY:Geo
USE MOD_Particle_Vars
USE MOD_DSMC_Vars
!-----------------------------------------------------------------------------------------------------------------------------------
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
REAL,INTENT(INOUT)         :: BGMSource(DSMCSampVolWe%BGMminX:DSMCSampVolWe%BGMmaxX,DSMCSampVolWe%BGMminY &
                        :DSMCSampVolWe%BGMmaxY,DSMCSampVolWe%BGMminZ:DSMCSampVolWe%BGMmaxZ,1:11, 1:nSpecies)
REAL,INTENT(INOUT)         :: alphasum(DSMCSampVolWe%BGMminX:DSMCSampVolWe%BGMmaxX,DSMCSampVolWe%BGMminY &
                        :DSMCSampVolWe%BGMmaxY,DSMCSampVolWe%BGMminZ:DSMCSampVolWe%BGMmaxZ, 1:nSpecies)
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES                                                                           
INTEGER                     :: i,k,l,m,k2,l2,m2
!-----------------------------------------------------------------------------------------------------------------------------------

DO i = 1,GEO%nPeriodicVectors
  DO k = DSMCSampVolWe%BGMminX, DSMCSampVolWe%BGMmaxX
    k2 = k + DSMCSampVolWe%PeriodicBGMVectors(1,i)
    DO l = DSMCSampVolWe%BGMminY, DSMCSampVolWe%BGMmaxY
      l2 = l + DSMCSampVolWe%PeriodicBGMVectors(2,i)
      DO m = DSMCSampVolWe%BGMminZ, DSMCSampVolWe%BGMmaxZ
        m2 = m + DSMCSampVolWe%PeriodicBGMVectors(3,i)
        IF ((k2.GE.DSMCSampVolWe%BGMminX).AND.(k2.LE.DSMCSampVolWe%BGMmaxX)) THEN
          IF ((l2.GE.DSMCSampVolWe%BGMminY).AND.(l2.LE.DSMCSampVolWe%BGMmaxY)) THEN
            IF ((m2.GE.DSMCSampVolWe%BGMminZ).AND.(m2.LE.DSMCSampVolWe%BGMmaxZ)) THEN
              BGMSource(k,l,m,:,:) = BGMSource(k,l,m,:,:) + BGMSource(k2,l2,m2,:,:)
              BGMSource(k2,l2,m2,:,:) = BGMSource(k,l,m,:,:)
              alphasum(k,l,m,:) = alphasum(k,l,m,:) + alphasum(k2,l2,m2,:)
              alphasum(k2,l2,m2,:) = alphasum(k,l,m,:)
            END IF
          END IF
        END IF
      END DO
    END DO
  END DO
END DO
RETURN
END SUBROUTINE PeriodicSourceExchangeDSMCHO
#else /*MPI*/
SUBROUTINE MPISourceExchangeBGMDSMCHO(BGMSource, alphasum)
!===================================================================================================================================
!> Exchange sources in periodic case for MPI
!===================================================================================================================================
! use MODULES                                                         
USE MOD_Globals
USE MOD_Particle_Vars
USE MOD_Particle_Mesh_Vars ,ONLY: GEO
USE MOD_Particle_MPI_Vars  ,ONLY: PartMPI,tMPIMessage
USE MOD_DSMC_Vars          ,ONLY: DSMCSampVolWe
!-----------------------------------------------------------------------------------------------------------------------------------
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
REAL,INTENT(INOUT)         :: BGMSource(DSMCSampVolWe%BGMminX:DSMCSampVolWe%BGMmaxX,DSMCSampVolWe%BGMminY &
                                       :DSMCSampVolWe%BGMmaxY,DSMCSampVolWe%BGMminZ:DSMCSampVolWe%BGMmaxZ,1:11, 1:nSpecies)
REAL,INTENT(INOUT)         :: alphasum(DSMCSampVolWe%BGMminX:DSMCSampVolWe%BGMmaxX,DSMCSampVolWe%BGMminY &
                                       :DSMCSampVolWe%BGMmaxY,DSMCSampVolWe%BGMminZ:DSMCSampVolWe%BGMmaxZ, 1:nSpecies)
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES 
TYPE(tMPIMessage)          :: send_message(0:PartMPI%nProcs-1)
TYPE(tMPIMessage)          :: recv_message(0:PartMPI%nProcs-1)
INTEGER                    :: send_request(0:PartMPI%nProcs-1)
INTEGER                    :: recv_request(0:PartMPI%nProcs-1)
INTEGER                    :: send_status_list(1:MPI_STATUS_SIZE,0:PartMPI%nProcs-1)
INTEGER                    :: recv_status_list(1:MPI_STATUS_SIZE,0:PartMPI%nProcs-1)
INTEGER                    :: i,k,l,m,n, ppp, Counter
INTEGER                    :: SourceLength(0:PartMPI%nProcs-1)
INTEGER                    :: RecvLength(0:PartMPI%nProcs-1)
INTEGER                    :: allocStat, Counter2
INTEGER                    :: messageCounterS, messageCounterR
INTEGER                    :: myRealKind, k2,l2,m2, iSpec
REAL                       :: myRealTestValue
!-----------------------------------------------------------------------------------------------------------------------------------

myRealKind = KIND(myRealTestValue)
IF (myRealKind.EQ.4) THEN
 myRealKind = MPI_REAL
ELSE IF (myRealKind.EQ.8) THEN
 myRealKind = MPI_DOUBLE_PRECISION
ELSE
 myRealKind = MPI_REAL
END IF

!--- Assemble actual sources to send
DO i = 0,PartMPI%nProcs-1
  ! sourcelength muss noch für periodisch angepasst werden
  IF ((DSMCSampVolWe%MPIConnect(i)%isBGMNeighbor).OR.&
       (DSMCSampVolWe%MPIConnect(i)%isBGMPeriodicNeighbor)) THEN
     SourceLength(i)=(DSMCSampVolWe%MPIConnect(i)%BGMBorder(2,1) - DSMCSampVolWe%MPIConnect(i)%BGMBorder(1,1) + 1) &
       * (DSMCSampVolWe%MPIConnect(i)%BGMBorder(2,2) - DSMCSampVolWe%MPIConnect(i)%BGMBorder(1,2) + 1) &
       * (DSMCSampVolWe%MPIConnect(i)%BGMBorder(2,3) - DSMCSampVolWe%MPIConnect(i)%BGMBorder(1,3) + 1)
     IF(DSMCSampVolWe%MPIConnect(i)%isBGMPeriodicNeighbor) THEN
       DO k = 1, DSMCSampVolWe%MPIConnect(i)%BGMPeriodicBorderCount
         SourceLength(i) = SourceLength(i) + (DSMCSampVolWe%MPIConnect(i)%Periodic(k)%BGMPeriodicBorder(2,1) -&
              DSMCSampVolWe%MPIConnect(i)%Periodic(k)%BGMPeriodicBorder(1,1) + 1) * &
             (DSMCSampVolWe%MPIConnect(i)%Periodic(k)%BGMPeriodicBorder(2,2) -&
              DSMCSampVolWe%MPIConnect(i)%Periodic(k)%BGMPeriodicBorder(1,2) + 1) * &
             (DSMCSampVolWe%MPIConnect(i)%Periodic(k)%BGMPeriodicBorder(2,3) -&
              DSMCSampVolWe%MPIConnect(i)%Periodic(k)%BGMPeriodicBorder(1,3) + 1)
       END DO
     END IF
     ALLOCATE(send_message(i)%content(1:SourceLength(i)*12*nSpecies), STAT=allocStat)
     IF (allocStat .NE. 0) THEN
        CALL abort(&
__STAMP__&
,'ERROR in MPISourceExchangeBGM: cannot allocate send_message')
     END IF
  END IF
  Counter = 0
  Counter2 = 0
  IF (DSMCSampVolWe%MPIConnect(i)%isBGMNeighbor) THEN
     DO k = DSMCSampVolWe%MPIConnect(i)%BGMBorder(1,1), DSMCSampVolWe%MPIConnect(i)%BGMBorder(2,1)
     DO l = DSMCSampVolWe%MPIConnect(i)%BGMBorder(1,2), DSMCSampVolWe%MPIConnect(i)%BGMBorder(2,2)
     DO m = DSMCSampVolWe%MPIConnect(i)%BGMBorder(1,3), DSMCSampVolWe%MPIConnect(i)%BGMBorder(2,3)
       Counter2 = Counter2 + 1
       DO iSpec = 1, nSpecies
         DO n = 1,11
            send_message(i)%content((Counter2-1)*11*nSpecies +n + (iSpec-1)*11) = BGMSource(k,l,m,n,iSpec)
         END DO
         send_message(i)%content(SourceLength(i)*11*nSpecies + (Counter2-1)*nSpecies+iSpec) = alphasum(k,l,m,iSpec)
       END DO
     END DO
     END DO
     END DO
  END IF
  IF (DSMCSampVolWe%MPIConnect(i)%isBGMPeriodicNeighbor) THEN
     DO n = 1, DSMCSampVolWe%MPIConnect(i)%BGMPeriodicBorderCount
        DO k = DSMCSampVolWe%MPIConnect(i)%Periodic(n)%BGMPeriodicBorder(1,1),&
               DSMCSampVolWe%MPIConnect(i)%Periodic(n)%BGMPeriodicBorder(2,1)
        DO l = DSMCSampVolWe%MPIConnect(i)%Periodic(n)%BGMPeriodicBorder(1,2),&
               DSMCSampVolWe%MPIConnect(i)%Periodic(n)%BGMPeriodicBorder(2,2)
        DO m = DSMCSampVolWe%MPIConnect(i)%Periodic(n)%BGMPeriodicBorder(1,3),&
               DSMCSampVolWe%MPIConnect(i)%Periodic(n)%BGMPeriodicBorder(2,3)
          Counter2 = Counter2 + 1
          DO iSpec = 1, nSpecies
            DO ppp = 1,11
               send_message(i)%content((Counter2-1)*11*nSpecies +ppp +(iSpec-1)*11) = BGMSource(k,l,m,ppp,iSpec)
            END DO
            send_message(i)%content(SourceLength(i)*11*nSpecies + (Counter2-1)*nSpecies+iSpec) = alphasum(k,l,m,iSpec)
          END DO
        END DO
        END DO
        END DO
     END DO
  END IF
END DO

!--- allocate actual source receive buffer
DO i = 0,PartMPI%nProcs-1
   IF ((DSMCSampVolWe%MPIConnect(i)%isBGMNeighbor).OR.(DSMCSampVolWe%MPIConnect(i)%isBGMPeriodicNeighbor)) THEN
      Counter = SourceLength(i)
      RecvLength(i) = Counter
      ALLOCATE(recv_message(i)%content(1:Counter*12*nSpecies), STAT=allocStat)
      IF (allocStat .NE. 0) THEN
         CALL abort(&
__STAMP__&
,'ERROR in MPISourceExchangeBGM: cannot allocate recv_message')
      END IF
   END IF
END DO
!--- communicate
messageCounterS = 0
DO i = 0,PartMPI%nProcs-1
   IF ((DSMCSampVolWe%MPIConnect(i)%isBGMNeighbor).OR.&
        (DSMCSampVolWe%MPIConnect(i)%isBGMPeriodicNeighbor)) THEN
      ! MPI_ISEND true/false list for all border BGM points
      messageCounterS = messageCounterS + 1
      CALL MPI_ISEND(send_message(i)%content,SourceLength(i)*12*nSpecies,myRealKind,i,1,PartMPI%COMM, &
                     send_request(messageCounterS), IERROR)
   END IF
END DO
messageCounterR = 0
DO i = 0,PartMPI%nProcs-1
   IF ((DSMCSampVolWe%MPIConnect(i)%isBGMNeighbor).OR.&
        (DSMCSampVolWe%MPIConnect(i)%isBGMPeriodicNeighbor)) THEN
      ! MPI_IRECV true/false list for all border BGM points from neighbor CPUs
      messageCounterR = messageCounterR + 1
      CALL MPI_IRECV(recv_message(i)%content,RecvLength(i)*12*nSpecies,myRealKind,i,1,PartMPI%COMM, &
                     recv_request(messageCounterR), IERROR)
   END IF
END DO
! MPI_WAITALL for the non-blocking MPI-communication to be finished
IF (messageCounterS .GE. 1) THEN
   CALL MPI_WAITALL(messageCounterS,send_request(1:messageCounterS),send_status_list(:,1:messageCounterS),IERROR)
END IF
IF (messageCounterR .GE. 1) THEN
   CALL MPI_WAITALL(messageCounterR,recv_request(1:messageCounterR),recv_status_list(:,1:messageCounterR),IERROR)
END IF
!--- Deallocate Send Message Buffers
DO i = 0,PartMPI%nProcs-1
   IF ((DSMCSampVolWe%MPIConnect(i)%isBGMNeighbor).OR.(DSMCSampVolWe%MPIConnect(i)%isBGMPeriodicNeighbor)) THEN
       DEALLOCATE(send_message(i)%content, STAT=allocStat)
       IF (allocStat .NE. 0) THEN
          CALL abort(&
__STAMP__&
,'ERROR in MPISourceExchangeBGM: cannot deallocate send_message')
       END IF
   END IF
END DO

!--- add selfperiodic sources, if any (needs to be done after send message is compiled and before
!---           received sources have been added!
IF ((GEO%nPeriodicVectors.GT.0).AND.(DSMCSampVolWe%SelfPeriodic)) THEN
   DO i = 1, GEO%nPeriodicVectors
      DO k = DSMCSampVolWe%BGMminX, DSMCSampVolWe%BGMmaxX
         k2 = k + DSMCSampVolWe%PeriodicBGMVectors(1,i)
      DO l = DSMCSampVolWe%BGMminY, DSMCSampVolWe%BGMmaxY
         l2 = l + DSMCSampVolWe%PeriodicBGMVectors(2,i)
      DO m = DSMCSampVolWe%BGMminZ, DSMCSampVolWe%BGMmaxZ
         m2 = m + DSMCSampVolWe%PeriodicBGMVectors(3,i)
         IF ((k2.GE.DSMCSampVolWe%BGMminX).AND.(k2.LE.DSMCSampVolWe%BGMmaxX)) THEN
         IF ((l2.GE.DSMCSampVolWe%BGMminY).AND.(l2.LE.DSMCSampVolWe%BGMmaxY)) THEN
         IF ((m2.GE.DSMCSampVolWe%BGMminZ).AND.(m2.LE.DSMCSampVolWe%BGMmaxZ)) THEN
            BGMSource(k,l,m,:,:) = BGMSource(k,l,m,:,:) + BGMSource(k2,l2,m2,:,:)
            BGMSource(k2,l2,m2,:,:) = BGMSource(k,l,m,:,:)
            alphasum(k,l,m,:) = alphasum(k,l,m,:) + alphasum(k2,l2,m2,:)
            alphasum(k2,l2,m2,:) = alphasum(k,l,m,:)
         END IF
         END IF
         END IF
      END DO
      END DO
      END DO
   END DO
END IF

!--- Add Sources and Deallocate Receive Message Buffers
DO i = 0,PartMPI%nProcs-1
   IF (RecvLength(i).GT.0) THEN
      Counter = 0
      Counter2 = 0
      IF (DSMCSampVolWe%MPIConnect(i)%isBGMNeighbor) THEN
         DO k = DSMCSampVolWe%MPIConnect(i)%BGMBorder(1,1), DSMCSampVolWe%MPIConnect(i)%BGMBorder(2,1)
         DO l = DSMCSampVolWe%MPIConnect(i)%BGMBorder(1,2), DSMCSampVolWe%MPIConnect(i)%BGMBorder(2,2)
         DO m = DSMCSampVolWe%MPIConnect(i)%BGMBorder(1,3), DSMCSampVolWe%MPIConnect(i)%BGMBorder(2,3)
           Counter2 = Counter2 + 1
           DO iSpec =1, nSpecies
             DO n = 1,11
               BGMSource(k,l,m,n, iSpec) = BGMSource(k,l,m,n,iSpec)  &
                  + recv_message(i)%content((Counter2-1)*11*nSpecies+n +(iSpec-1)*11)
             END DO
             alphasum(k,l,m,iSpec) = alphasum(k,l,m,iSpec) &
                  + recv_message(i)%content(SourceLength(i)*11*nSpecies + (Counter2-1)*nSpecies+iSpec)
           END DO
         END DO
         END DO
         END DO
      END IF
      IF (DSMCSampVolWe%MPIConnect(i)%isBGMPeriodicNeighbor) THEN
         DO n = 1, DSMCSampVolWe%MPIConnect(i)%BGMPeriodicBorderCount
            DO k = DSMCSampVolWe%MPIConnect(i)%Periodic(n)%BGMPeriodicBorder(1,1),&
                   DSMCSampVolWe%MPIConnect(i)%Periodic(n)%BGMPeriodicBorder(2,1)
            DO l = DSMCSampVolWe%MPIConnect(i)%Periodic(n)%BGMPeriodicBorder(1,2),&
                   DSMCSampVolWe%MPIConnect(i)%Periodic(n)%BGMPeriodicBorder(2,2)
            DO m = DSMCSampVolWe%MPIConnect(i)%Periodic(n)%BGMPeriodicBorder(1,3),&
                   DSMCSampVolWe%MPIConnect(i)%Periodic(n)%BGMPeriodicBorder(2,3)
              Counter2 = Counter2 + 1
              DO iSpec = 1, nSpecies
                DO ppp = 1,11
                   BGMSource(k,l,m,ppp,iSpec) = BGMSource(k,l,m,ppp, iSpec) &
                      + recv_message(i)%content((Counter2-1)*11*nSpecies+ppp+(iSpec-1)*11)
                END DO
                alphasum(k,l,m,iSpec) = alphasum(k,l,m,iSpec) &
                  + recv_message(i)%content(SourceLength(i)*11*nSpecies + (Counter2-1)*nSpecies+iSpec)
              END DO
            END DO
            END DO
            END DO
         END DO
      END IF
      IF ((DSMCSampVolWe%MPIConnect(i)%isBGMPeriodicNeighbor).OR.(DSMCSampVolWe%MPIConnect(i)%isBGMNeighbor)) THEN
         DEALLOCATE(recv_message(i)%content, STAT=allocStat)
         IF (allocStat .NE. 0) THEN
            CALL abort(&
__STAMP__&
,'ERROR in MPISourceExchangeBGMDSMCHO: cannot deallocate recv_message')
         END IF
      END IF
   END IF
END DO
END SUBROUTINE MPISourceExchangeBGMDSMCHO


SUBROUTINE MPIVolumeExchangeBGMDSMCHO()
!===================================================================================================================================
!> Exchange sources in periodic case for MPI
!===================================================================================================================================
! MODULES                                                         
USE MOD_Particle_MPI_Vars  ,ONLY: PartMPI,tMPIMessage
USE MOD_Particle_Mesh_Vars ,ONLY: GEO
USE MOD_Globals
USE MOD_Particle_Vars
USE MOD_DSMC_Vars          ,ONLY: DSMCSampVolWe
!-----------------------------------------------------------------------------------------------------------------------------------
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES

!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES 
TYPE(tMPIMessage)           :: send_message(0:PartMPI%nProcs-1)
TYPE(tMPIMessage)           :: recv_message(0:PartMPI%nProcs-1)
INTEGER                     :: send_request(0:PartMPI%nProcs-1)
INTEGER                     :: recv_request(0:PartMPI%nProcs-1)
INTEGER                     :: send_status_list(1:MPI_STATUS_SIZE,0:PartMPI%nProcs-1)
INTEGER                     :: recv_status_list(1:MPI_STATUS_SIZE,0:PartMPI%nProcs-1)
INTEGER                     :: i,k,l,m,n, Counter
INTEGER                     :: SourceLength(0:PartMPI%nProcs-1)
INTEGER                     :: RecvLength(0:PartMPI%nProcs-1)
INTEGER                     :: allocStat, Counter2
INTEGER                     :: messageCounterS, messageCounterR
INTEGER                     :: myRealKind, k2,l2,m2
REAL                        :: myRealTestValue
!-----------------------------------------------------------------------------------------------------------------------------------

myRealKind = KIND(myRealTestValue)
IF (myRealKind.EQ.4) THEN
  myRealKind = MPI_REAL
ELSE IF (myRealKind.EQ.8) THEN
  myRealKind = MPI_DOUBLE_PRECISION
ELSE
  myRealKind = MPI_REAL
END IF

    !--- Assemble actual sources to send
DO i = 0,PartMPI%nProcs-1
  IF (DSMCSampVolWe%MPIConnect(i)%isBGMNeighbor.OR.DSMCSampVolWe%MPIConnect(i)%isBGMPeriodicNeighbor) THEN
    DO k = DSMCSampVolWe%MPIConnect(i)%BGMBorder(1,1), DSMCSampVolWe%MPIConnect(i)%BGMBorder(2,1)
    DO l = DSMCSampVolWe%MPIConnect(i)%BGMBorder(1,2), DSMCSampVolWe%MPIConnect(i)%BGMBorder(2,2)
    DO m = DSMCSampVolWe%MPIConnect(i)%BGMBorder(1,3), DSMCSampVolWe%MPIConnect(i)%BGMBorder(2,3)
      IF (.NOT.(DSMCSampVolWe%isBoundBGCell(k,l,m))) THEN
        CALL VolumeBoundBGMCInt(k, l, m, DSMCSampVolWe%BGMVolumes(k,l,m))
        DSMCSampVolWe%isBoundBGCell(k,l,m) = .true.
      END IF
    END DO
    END DO
    END DO
  END IF
END DO

!--- Assemble actual sources to send
DO i = 0,PartMPI%nProcs-1
  ! sourcelength muss noch für periodisch angepasst werden
  IF ((DSMCSampVolWe%MPIConnect(i)%isBGMNeighbor).OR.DSMCSampVolWe%MPIConnect(i)%isBGMPeriodicNeighbor) THEN
    SourceLength(i)=(DSMCSampVolWe%MPIConnect(i)%BGMBorder(2,1) - DSMCSampVolWe%MPIConnect(i)%BGMBorder(1,1) + 1) &
      * (DSMCSampVolWe%MPIConnect(i)%BGMBorder(2,2) - DSMCSampVolWe%MPIConnect(i)%BGMBorder(1,2) + 1) &
      * (DSMCSampVolWe%MPIConnect(i)%BGMBorder(2,3) - DSMCSampVolWe%MPIConnect(i)%BGMBorder(1,3) + 1)
    IF(DSMCSampVolWe%MPIConnect(i)%isBGMPeriodicNeighbor) THEN
      DO k = 1, DSMCSampVolWe%MPIConnect(i)%BGMPeriodicBorderCount
        SourceLength(i) = SourceLength(i) + (DSMCSampVolWe%MPIConnect(i)%Periodic(k)%BGMPeriodicBorder(2,1) -&
             DSMCSampVolWe%MPIConnect(i)%Periodic(k)%BGMPeriodicBorder(1,1) + 1) * &
            (DSMCSampVolWe%MPIConnect(i)%Periodic(k)%BGMPeriodicBorder(2,2) -&
             DSMCSampVolWe%MPIConnect(i)%Periodic(k)%BGMPeriodicBorder(1,2) + 1) * &
            (DSMCSampVolWe%MPIConnect(i)%Periodic(k)%BGMPeriodicBorder(2,3) -&
             DSMCSampVolWe%MPIConnect(i)%Periodic(k)%BGMPeriodicBorder(1,3) + 1)
      END DO
    END IF
    ALLOCATE(send_message(i)%content(1:SourceLength(i)), STAT=allocStat)
    IF (allocStat .NE. 0) THEN
       CALL abort(&
__STAMP__&
,'ERROR in MPISourceExchangeBGM: cannot allocate send_message')
    END IF
  END IF
  Counter = 0
  Counter2 = 0
  IF (DSMCSampVolWe%MPIConnect(i)%isBGMNeighbor) THEN
     DO k = DSMCSampVolWe%MPIConnect(i)%BGMBorder(1,1), DSMCSampVolWe%MPIConnect(i)%BGMBorder(2,1)
     DO l = DSMCSampVolWe%MPIConnect(i)%BGMBorder(1,2), DSMCSampVolWe%MPIConnect(i)%BGMBorder(2,2)
     DO m = DSMCSampVolWe%MPIConnect(i)%BGMBorder(1,3), DSMCSampVolWe%MPIConnect(i)%BGMBorder(2,3)
       Counter2 = Counter2 + 1
       send_message(i)%content(Counter2) = DSMCSampVolWe%BGMVolumes(k,l,m)
     END DO
     END DO
     END DO
  END IF
  IF (DSMCSampVolWe%MPIConnect(i)%isBGMPeriodicNeighbor) THEN
    DO n = 1, DSMCSampVolWe%MPIConnect(i)%BGMPeriodicBorderCount
      DO k = DSMCSampVolWe%MPIConnect(i)%Periodic(n)%BGMPeriodicBorder(1,1),&
             DSMCSampVolWe%MPIConnect(i)%Periodic(n)%BGMPeriodicBorder(2,1)
      DO l = DSMCSampVolWe%MPIConnect(i)%Periodic(n)%BGMPeriodicBorder(1,2),&
             DSMCSampVolWe%MPIConnect(i)%Periodic(n)%BGMPeriodicBorder(2,2)
      DO m = DSMCSampVolWe%MPIConnect(i)%Periodic(n)%BGMPeriodicBorder(1,3),&
             DSMCSampVolWe%MPIConnect(i)%Periodic(n)%BGMPeriodicBorder(2,3)
        Counter2 = Counter2 + 1
        send_message(i)%content(Counter2) = DSMCSampVolWe%BGMVolumes(k,l,m)
      END DO
      END DO
      END DO
    END DO
  END IF
END DO

!--- allocate actual source receive buffer
DO i = 0,PartMPI%nProcs-1
  IF ((DSMCSampVolWe%MPIConnect(i)%isBGMNeighbor).OR.(DSMCSampVolWe%MPIConnect(i)%isBGMPeriodicNeighbor)) THEN
    Counter = SourceLength(i)
    RecvLength(i) = Counter
    ALLOCATE(recv_message(i)%content(1:Counter), STAT=allocStat)
    IF (allocStat .NE. 0) THEN
      CALL abort(&
__STAMP__&
,'ERROR in MPISourceExchangeBGM: cannot allocate recv_message')
    END IF
  END IF
END DO
!--- communicate
messageCounterS = 0
DO i = 0,PartMPI%nProcs-1
  IF ((DSMCSampVolWe%MPIConnect(i)%isBGMNeighbor).OR.&
       (DSMCSampVolWe%MPIConnect(i)%isBGMPeriodicNeighbor)) THEN
     ! MPI_ISEND true/false list for all border BGM points
    messageCounterS = messageCounterS + 1
    CALL MPI_ISEND(send_message(i)%content,SourceLength(i),myRealKind,i,1,PartMPI%COMM, &
                   send_request(messageCounterS), IERROR)
  END IF
END DO
messageCounterR = 0
DO i = 0,PartMPI%nProcs-1
  IF ((DSMCSampVolWe%MPIConnect(i)%isBGMNeighbor).OR.&
      (DSMCSampVolWe%MPIConnect(i)%isBGMPeriodicNeighbor)) THEN
    ! MPI_IRECV true/false list for all border BGM points from neighbor CPUs
    messageCounterR = messageCounterR + 1
    CALL MPI_IRECV(recv_message(i)%content,RecvLength(i),myRealKind,i,1,PartMPI%COMM, &
                   recv_request(messageCounterR), IERROR)
  END IF
END DO
! MPI_WAITALL for the non-blocking MPI-communication to be finished
IF (messageCounterS .GE. 1) THEN
  CALL MPI_WAITALL(messageCounterS,send_request(1:messageCounterS),send_status_list(:,1:messageCounterS),IERROR)
END IF
IF (messageCounterR .GE. 1) THEN
  CALL MPI_WAITALL(messageCounterR,recv_request(1:messageCounterR),recv_status_list(:,1:messageCounterR),IERROR)
END IF
!--- Deallocate Send Message Buffers
DO i = 0,PartMPI%nProcs-1
  IF ((DSMCSampVolWe%MPIConnect(i)%isBGMNeighbor).OR.(DSMCSampVolWe%MPIConnect(i)%isBGMPeriodicNeighbor)) THEN
    DEALLOCATE(send_message(i)%content, STAT=allocStat)
    IF (allocStat .NE. 0) THEN
      CALL abort(&
__STAMP__&
,'ERROR in MPISourceExchangeBGM: cannot deallocate send_message')
    END IF
  END IF
END DO

!--- add selfperiodic sources, if any (needs to be done after send message is compiled and before
!---           received sources have been added!
IF ((GEO%nPeriodicVectors.GT.0).AND.(DSMCSampVolWe%SelfPeriodic)) THEN
  DO i = 1, GEO%nPeriodicVectors
    DO k = DSMCSampVolWe%BGMminX, DSMCSampVolWe%BGMmaxX
      k2 = k + DSMCSampVolWe%PeriodicBGMVectors(1,i)
    DO l = DSMCSampVolWe%BGMminY, DSMCSampVolWe%BGMmaxY
      l2 = l + DSMCSampVolWe%PeriodicBGMVectors(2,i)
    DO m = DSMCSampVolWe%BGMminZ, DSMCSampVolWe%BGMmaxZ
      m2 = m + DSMCSampVolWe%PeriodicBGMVectors(3,i)
      IF ((k2.GE.DSMCSampVolWe%BGMminX).AND.(k2.LE.DSMCSampVolWe%BGMmaxX)) THEN
      IF ((l2.GE.DSMCSampVolWe%BGMminY).AND.(l2.LE.DSMCSampVolWe%BGMmaxY)) THEN
      IF ((m2.GE.DSMCSampVolWe%BGMminZ).AND.(m2.LE.DSMCSampVolWe%BGMmaxZ)) THEN
        DSMCSampVolWe%BGMVolumes(k,l,m) = DSMCSampVolWe%BGMVolumes(k,l,m) + DSMCSampVolWe%BGMVolumes(k2,l2,m2)
        DSMCSampVolWe%BGMVolumes(k2,l2,m2) = DSMCSampVolWe%BGMVolumes(k,l,m)
      END IF
      END IF
      END IF
    END DO
    END DO
    END DO
  END DO
END IF

!--- Add Sources and Deallocate Receive Message Buffers
DO i = 0,PartMPI%nProcs-1
  IF (RecvLength(i).GT.0) THEN
    Counter = 0
    Counter2 = 0
    IF (DSMCSampVolWe%MPIConnect(i)%isBGMNeighbor) THEN
      DO k = DSMCSampVolWe%MPIConnect(i)%BGMBorder(1,1), DSMCSampVolWe%MPIConnect(i)%BGMBorder(2,1)
      DO l = DSMCSampVolWe%MPIConnect(i)%BGMBorder(1,2), DSMCSampVolWe%MPIConnect(i)%BGMBorder(2,2)
      DO m = DSMCSampVolWe%MPIConnect(i)%BGMBorder(1,3), DSMCSampVolWe%MPIConnect(i)%BGMBorder(2,3)
        Counter2 = Counter2 + 1
        DSMCSampVolWe%BGMVolumes(k,l,m) = DSMCSampVolWe%BGMVolumes(k,l,m)  &
            + recv_message(i)%content(Counter2)
      END DO
      END DO
      END DO
    END IF
    IF (DSMCSampVolWe%MPIConnect(i)%isBGMPeriodicNeighbor) THEN
      DO n = 1, DSMCSampVolWe%MPIConnect(i)%BGMPeriodicBorderCount
        DO k = DSMCSampVolWe%MPIConnect(i)%Periodic(n)%BGMPeriodicBorder(1,1),&
               DSMCSampVolWe%MPIConnect(i)%Periodic(n)%BGMPeriodicBorder(2,1)
        DO l = DSMCSampVolWe%MPIConnect(i)%Periodic(n)%BGMPeriodicBorder(1,2),&
               DSMCSampVolWe%MPIConnect(i)%Periodic(n)%BGMPeriodicBorder(2,2)
        DO m = DSMCSampVolWe%MPIConnect(i)%Periodic(n)%BGMPeriodicBorder(1,3),&
               DSMCSampVolWe%MPIConnect(i)%Periodic(n)%BGMPeriodicBorder(2,3)
          Counter2 = Counter2 + 1
          DSMCSampVolWe%BGMVolumes(k,l,m) = DSMCSampVolWe%BGMVolumes(k,l,m)  &
           + recv_message(i)%content(Counter2)
        END DO
        END DO
        END DO
      END DO
    END IF
    IF ((DSMCSampVolWe%MPIConnect(i)%isBGMPeriodicNeighbor)) THEN
       DEALLOCATE(recv_message(i)%content, STAT=allocStat)
       IF (allocStat .NE. 0) THEN
          CALL abort(&
__STAMP__&
,'ERROR in MPISourceExchangeBGMDSMCHO: cannot deallocate recv_message')
         END IF
      END IF
   END IF
END DO
END SUBROUTINE MPIVolumeExchangeBGMDSMCHO


SUBROUTINE MPIBackgroundMeshInitDSMCHO()
!===================================================================================================================================
!> initialize MPI background mesh
!===================================================================================================================================
! MODULES          
USE MOD_Particle_Vars
USE MOD_Globals
USE MOD_Particle_MPI_Vars  ,ONLY: PartMPI
USE MOD_DSMC_Vars          ,ONLY: DSMCSampVolWe
USE MOD_Particle_Mesh_Vars ,ONLY: GEO
!-----------------------------------------------------------------------------------------------------------------------------------
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
INTEGER                     :: i,k,m,n
INTEGER                     :: localminmax(6), maxofmin, minofmax
INTEGER                     :: completeminmax(6*PartMPI%nProcs)
INTEGER                     :: allocStat, NeighCount
INTEGER                     :: TempBorder(1:2,1:3)
INTEGER                     :: Periodicminmax(6), coord, PeriodicVec(1:3)
INTEGER                     :: TempPeriBord(1:26,1:2,1:3)
LOGICAL                     :: CHECKNEIGHBOR
!-----------------------------------------------------------------------------------------------------------------------------------
! Periodic Init stuff
IF(GEO%nPeriodicVectors.GT.0)THEN
  ! Compute PeriodicBGMVectors (from PeriodicVectors and BGMdeltas)
  ALLOCATE(DSMCSampVolWe%PeriodicBGMVectors(1:3,1:GEO%nPeriodicVectors),STAT=allocStat)
  IF (allocStat .NE. 0) THEN
    CALL abort(&
__STAMP__&
,'ERROR in MPIBackgroundMeshInitDSMCHO: cannot allocate DSMCSampVolWe%PeriodicBGMVectors!')
  END IF
  DO i = 1, GEO%nPeriodicVectors
    DSMCSampVolWe%PeriodicBGMVectors(1,i) = NINT(GEO%PeriodicVectors(1,i)/DSMCSampVolWe%BGMdeltas(1))
    IF(ABS(GEO%PeriodicVectors(1,i)/DSMCSampVolWe%BGMdeltas(1)-REAL(DSMCSampVolWe%PeriodicBGMVectors(1,i))).GT.1E-10)THEN
      CALL abort(&
__STAMP__&
,'ERROR: Periodic Vector ist not multiple of background mesh delta')
    END IF
    DSMCSampVolWe%PeriodicBGMVectors(2,i) = NINT(GEO%PeriodicVectors(2,i)/DSMCSampVolWe%BGMdeltas(2))
    IF(ABS(GEO%PeriodicVectors(2,i)/DSMCSampVolWe%BGMdeltas(2)-REAL(DSMCSampVolWe%PeriodicBGMVectors(2,i))).GT.1E-10)THEN
      CALL abort(&
__STAMP__&
,'ERROR: Periodic Vector ist not multiple of background mesh delta')
    END IF
    DSMCSampVolWe%PeriodicBGMVectors(3,i) = NINT(GEO%PeriodicVectors(3,i)/DSMCSampVolWe%BGMdeltas(3))
    IF(ABS(GEO%PeriodicVectors(3,i)/DSMCSampVolWe%BGMdeltas(3)-REAL(DSMCSampVolWe%PeriodicBGMVectors(3,i))).GT.1E-10)THEN
      CALL abort(&
__STAMP__&
,'ERROR: Periodic Vector ist not multiple of background mesh delta')
    END IF
  END DO
  ! Check whether process is periodic with itself
  DSMCSampVolWe%SelfPeriodic = .FALSE.
  !--- virtually move myself according to periodic vectors in order to find overlapping areas
  !--- 26 possibilities,
  localminmax(1) = DSMCSampVolWe%BGMminX
  localminmax(2) = DSMCSampVolWe%BGMminY
  localminmax(3) = DSMCSampVolWe%BGMminZ
  localminmax(4) = DSMCSampVolWe%BGMmaxX
  localminmax(5) = DSMCSampVolWe%BGMmaxY
  localminmax(6) = DSMCSampVolWe%BGMmaxZ
  DO k = -1,1
    DO m = -1,1
      DO n = -1,1
        PeriodicVec = k*DSMCSampVolWe%PeriodicBGMVectors(:,1) + m*DSMCSampVolWe%PeriodicBGMVectors(:,1) &
           + n*DSMCSampVolWe%PeriodicBGMVectors(:,1)
        IF (ALL(PeriodicVec(:).EQ.0)) CYCLE
        periodicminmax(1) = localminmax(1) + PeriodicVec(1)
        periodicminmax(2) = localminmax(2) + PeriodicVec(2)
        periodicminmax(3) = localminmax(3) + PeriodicVec(3)
        periodicminmax(4) = localminmax(4) + PeriodicVec(1)
        periodicminmax(5) = localminmax(5) + PeriodicVec(2)
        periodicminmax(6) = localminmax(6) + PeriodicVec(3)
        !--- find overlap
        DO coord = 1,3           ! x y z direction
          maxofmin = MAX(periodicminmax(coord),localminmax(coord))
          minofmax = MIN(periodicminmax(3+coord),localminmax(3+coord))
          IF (maxofmin.LE.minofmax) DSMCSampVolWe%SelfPeriodic = .TRUE.      ! overlapping
        END DO
      END DO
    END DO
  END DO
END IF

!--- send and receive min max indices to and from all processes

!--- enter local min max vector (xmin, ymin, zmin, xmax, ymax, zmax)
localminmax(1) = DSMCSampVolWe%BGMminX
localminmax(2) = DSMCSampVolWe%BGMminY
localminmax(3) = DSMCSampVolWe%BGMminZ
localminmax(4) = DSMCSampVolWe%BGMmaxX
localminmax(5) = DSMCSampVolWe%BGMmaxY
localminmax(6) = DSMCSampVolWe%BGMmaxZ
!--- do allgather into complete min max vector
CALL MPI_ALLGATHER(localminmax,6,MPI_INTEGER,completeminmax,6,MPI_INTEGER,PartMPI%COMM,IERROR)
! Allocate MPIConnect
SDEALLOCATE(DSMCSampVolWe%MPIConnect)
ALLOCATE(DSMCSampVolWe%MPIConnect(0:PartMPI%nProcs-1),STAT=allocStat)
IF (allocStat .NE. 0) THEN
  CALL abort(&
__STAMP__&
,'ERROR in MPIBackgroundMeshInit: cannot allocate DSMCSampVolWe%MPIConnect')
END IF

!--- determine borders indices (=overlapping BGM mesh points) with each process
DO i = 0,PartMPI%nProcs-1
  DSMCSampVolWe%MPIConnect(i)%isBGMPeriodicNeighbor = .FALSE.
  DSMCSampVolWe%MPIConnect(i)%BGMPeriodicBorderCount = 0
   IF (i.EQ.PartMPI%MyRank) THEN
      DSMCSampVolWe%MPIConnect(i)%isBGMNeighbor = .FALSE.
   ELSE
      DSMCSampVolWe%MPIConnect(i)%isBGMNeighbor = .TRUE.
      DO k = 1,3           ! x y z direction
         maxofmin = MAX(localminmax(k),completeminmax((i*6)+k))
         minofmax = MIN(localminmax(3+k),completeminmax((i*6)+3+k))
         IF (maxofmin.LE.minofmax) THEN           ! overlapping
            TempBorder(1,k) = maxofmin
            TempBorder(2,k) = minofmax
         ELSE
            DSMCSampVolWe%MPIConnect(i)%isBGMNeighbor = .FALSE.
         END IF
      END DO
   END IF
   IF(DSMCSampVolWe%MPIConnect(i)%isBGMNeighbor)THEN
      SDEALLOCATE(DSMCSampVolWe%MPIConnect(i)%BGMBorder)
      ALLOCATE(DSMCSampVolWe%MPIConnect(i)%BGMBorder(1:2,1:3),STAT=allocStat)
      IF (allocStat .NE. 0) THEN
         CALL abort(&
__STAMP__&
,'ERROR in MPIBackgroundMeshInit: cannot allocate DSMCSampVolWe%MPIConnect')
      END IF
      DSMCSampVolWe%MPIConnect(i)%BGMBorder(1:2,1:3) = TempBorder(1:2,1:3)
   END IF
END DO

!--- determine border indices for periodic meshes  
IF (GEO%nPeriodicVectors.GT.0) THEN
  DO i = 0,PartMPI%nProcs-1
    IF (i.EQ.PartMPI%MyRank) THEN
      DSMCSampVolWe%MPIConnect(i)%isBGMPeriodicNeighbor = .FALSE.
      DSMCSampVolWe%MPIConnect(i)%BGMPeriodicBorderCount = 0
    ELSE
      !--- virtually move myself according to periodic vectors in order to find overlapping areas
      !--- 26 possibilities, processes need to work through them in opposite direction in order
      !--- to get matching areas.
      !--- Example for 2D:  I am process #3, I compare myself with #7
      !--- Periodic Vectors are p1 and p2.
      !--- I check p1, p2, p1+p2, p1-p2, -p1+p2, -p1-p2, -p2, -p1
      !--- #7 has to check -p1, -p2, -p1-p2, -p1+p2, p1-p2, p1+p1, p2, p1
      !--- This is done by doing 3 loops from -1 to 1 (for the higher process number)
      !--- or 1 to -1 (for the lower process number) and multiplying
      !--- these numbers to the periodic vectors
      NeighCount = 0   !-- counter: how often is the process my periodic neighbor?
      DSMCSampVolWe%MPIConnect(i)%isBGMPeriodicNeighbor = .FALSE.
      DO k = -SIGN(1,PartMPI%MyRank-i),SIGN(1,PartMPI%MyRank-i),SIGN(1,PartMPI%MyRank-i)
        DO m = -SIGN(1,PartMPI%MyRank-i),SIGN(1,PartMPI%MyRank-i),SIGN(1,PartMPI%MyRank-i)
          DO n = -SIGN(1,PartMPI%MyRank-i),SIGN(1,PartMPI%MyRank-i),SIGN(1,PartMPI%MyRank-i)
            IF ((k.EQ.0).AND.(m.EQ.0).AND.(n.EQ.0)) CYCLE !this is not periodic and already done above
            CHECKNEIGHBOR = .TRUE.
            PeriodicVec = k*DSMCSampVolWe%PeriodicBGMVectors(:,1)
            IF (GEO%nPeriodicVectors.GT.1) THEN
              PeriodicVec = PeriodicVec + m*DSMCSampVolWe%PeriodicBGMVectors(:,2)
            END IF
            IF (GEO%nPeriodicVectors.GT.2) THEN
              PeriodicVec = PeriodicVec + n*DSMCSampVolWe%PeriodicBGMVectors(:,3)
            END IF
            periodicminmax(1) = localminmax(1) + PeriodicVec(1)
            periodicminmax(2) = localminmax(2) + PeriodicVec(2)
            periodicminmax(3) = localminmax(3) + PeriodicVec(3)
            periodicminmax(4) = localminmax(4) + PeriodicVec(1)
            periodicminmax(5) = localminmax(5) + PeriodicVec(2)
            periodicminmax(6) = localminmax(6) + PeriodicVec(3)
            !--- find overlap
            DO coord = 1,3           ! x y z direction
              maxofmin = MAX(periodicminmax(coord),completeminmax((i*6)+coord))
              minofmax = MIN(periodicminmax(3+coord),completeminmax((i*6)+3+coord))
              IF (maxofmin.LE.minofmax) THEN           ! overlapping
                TempBorder(1,coord) = maxofmin
                TempBorder(2,coord) = minofmax
              ELSE
                CHECKNEIGHBOR = .FALSE.
              END IF
            END DO
            IF(CHECKNEIGHBOR)THEN
              NeighCount = NeighCount + 1
              TempBorder(:,1) = TempBorder(:,1) - PeriodicVec(1)
              TempBorder(:,2) = TempBorder(:,2) - PeriodicVec(2)
              TempBorder(:,3) = TempBorder(:,3) - PeriodicVec(3)
              TempPeriBord(NeighCount,1:2,1:3) = TempBorder(1:2,1:3)
              DSMCSampVolWe%MPIConnect(i)%isBGMPeriodicNeighbor = .TRUE.
            END IF
          END DO
        END DO
      END DO
      DSMCSampVolWe%MPIConnect(i)%BGMPeriodicBorderCount = NeighCount
      ALLOCATE(DSMCSampVolWe%MPIConnect(i)%Periodic(1:DSMCSampVolWe%MPIConnect(i)%BGMPeriodicBorderCount),STAT=allocStat)
      IF (allocStat .NE. 0) THEN
        CALL abort(&
__STAMP__&
,'ERROR in MPIBackgroundMeshInit: cannot allocate DSMCSampVolWe%MPIConnect')
      END IF
      DO k = 1,NeighCount
        ALLOCATE(DSMCSampVolWe%MPIConnect(i)%Periodic(k)%BGMPeriodicBorder(1:2,1:3),STAT=allocStat)
        IF (allocStat .NE. 0) THEN
          CALL abort(&
__STAMP__&
,'ERROR in MPIBackgroundMeshInit: cannot allocate DSMCSampVolWe%MPIConnect')
        END IF
        DSMCSampVolWe%MPIConnect(i)%Periodic(k)%BGMPeriodicBorder(1:2,1:3) = TempPeriBord(k,1:2,1:3)
      END DO
    END IF
  END DO
ELSE
  !--- initialize to FALSE for completely non-periodic cases
  DO i = 0,PartMPI%nProcs-1
    DSMCSampVolWe%MPIConnect(i)%isBGMPeriodicNeighbor = .FALSE.
  END DO
END IF
RETURN
END SUBROUTINE MPIBackgroundMeshInitDSMCHO
#endif /*MPI*/

SUBROUTINE VolumeBoundBGMCInt(i, j, k, Volume)
!===================================================================================================================================
!> VolumeBoundBGMInt description
!===================================================================================================================================
! MODULES
USE MOD_Particle_Vars
USE MOD_Particle_Mesh_Vars,     ONLY:GEO,epsOneCell
USE MOD_DSMC_Vars,              ONLY:DSMCSampVolWe
USE MOD_Eval_xyz,               ONLY:GetPositionInRefElem
!-----------------------------------------------------------------------------------------------------------------------------------
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
INTEGER                          :: i,j, k
REAL                             :: Volume
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
INTEGER                          :: Element, CellX,CellY,CellZ, iElem
INTEGER                          :: stepx, stepy, stepz
REAL                             :: xi(3)
REAL                             :: GuessPos(3), Found
REAL                             :: alpha1, alpha2, alpha3
!-----------------------------------------------------------------------------------------------------------------------------------
!-----------------------------------------------------------------------------------------------------------------------------------
Found = 0

DO stepx=0, DSMCSampVolWe%OrderVolInt
DO stepy=0, DSMCSampVolWe%OrderVolInt
DO stepz=0, DSMCSampVolWe%OrderVolInt
  GuessPos(1) = DSMCSampVolWe%BGMdeltas(1)*(i) + DSMCSampVolWe%x_VolInt(stepx)*DSMCSampVolWe%BGMdeltas(1)
  GuessPos(2) = DSMCSampVolWe%BGMdeltas(2)*(j) + DSMCSampVolWe%x_VolInt(stepy)*DSMCSampVolWe%BGMdeltas(2)
  GuessPos(3) = DSMCSampVolWe%BGMdeltas(3)*(k) + DSMCSampVolWe%x_VolInt(stepz)*DSMCSampVolWe%BGMdeltas(3)
  IF ( (GuessPos(1).LT.GEO%xmin).OR.(GuessPos(1).GT.GEO%xmax).OR. &
      (GuessPos(2).LT.GEO%ymin).OR.(GuessPos(2).GT.GEO%ymax).OR. &
      (GuessPos(3).LT.GEO%zmin).OR.(GuessPos(3).GT.GEO%zmax)) THEN
    CYCLE
  END IF
  !--- get background mesh cell of particle
  CellX = CEILING((GuessPos(1)-GEO%xminglob)/GEO%FIBGMdeltas(1))
  CellX = MIN(GEO%FIBGMimax,CellX)
  CellY = CEILING((GuessPos(2)-GEO%yminglob)/GEO%FIBGMdeltas(2))
  CellY = MIN(GEO%FIBGMjmax,CellY)
  CellZ = CEILING((GuessPos(3)-GEO%zminglob)/GEO%FIBGMdeltas(3))
  CellZ = MIN(GEO%FIBGMkmax,CellZ)
  !--- check all cells associated with this beckground mesh cell
  DO iElem = 1, GEO%FIBGM(CellX,CellY,CellZ)%nElem
    Element = GEO%FIBGM(CellX,CellY,CellZ)%Element(iElem)
    CALL GetPositionInRefElem(GuessPos,Xi,Element)
    IF(MAXVAL(ABS(Xi)).GT.epsOneCell(Element))THEN ! particle outside
      alpha1 = (GuessPos(1) / DSMCSampVolWe%BGMdeltas(1)) - i
      alpha2 = (GuessPos(2) / DSMCSampVolWe%BGMdeltas(2)) - j
      alpha3 = (GuessPos(3) / DSMCSampVolWe%BGMdeltas(3)) - k
      Found = Found + (1.-ABS(alpha1))*(1.-ABS(alpha2))*(1.-ABS(alpha3)) &
           *DSMCSampVolWe%w_VolInt(stepx)*DSMCSampVolWe%w_VolInt(stepy)*DSMCSampVolWe%w_VolInt(stepz)
      EXIT
    END IF
  END DO
END DO; END DO; END DO;
Volume = REAL(Found)*DSMCSampVolWe%BGMVolume

END SUBROUTINE VolumeBoundBGMCInt


SUBROUTINE WriteAnalyzeSurfCollisToHDF5(OutputTime,TimeSample)
!===================================================================================================================================
!> Wrinting AnalyzeSurfCollis-Data to hdf5 file (based on WriteParticleToHDF5 and WriteDSMCHOToHDF5)
!===================================================================================================================================
! MODULES
USE MOD_Globals
USE MOD_Particle_Vars          ,ONLY: nSpecies
USE MOD_Globals_Vars           ,ONLY: ProjectName
USE MOD_io_HDF5
USE MOD_HDF5_Output            ,ONLY: WriteAttributeToHDF5, WriteHDF5Header, WriteArrayToHDF5
USE MOD_PICDepo_Vars           ,ONLY: SFResampleAnalyzeSurfCollis, LastAnalyzeSurfCollis, r_SF
USE MOD_Particle_Boundary_Vars ,ONLY: nPartBound, AnalyzeSurfCollis
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
REAL,INTENT(IN)                :: OutputTime, TimeSample
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
CHARACTER(LEN=255)             :: Filename, TypeString, H5_Name
INTEGER,ALLOCATABLE            :: SpeciesPositions(:,:)
CHARACTER(LEN=255),ALLOCATABLE :: StrVarNames(:)!,params(:)
#ifdef MPI
INTEGER,ALLOCATABLE            :: sendbuf(:),recvbuf(:)
REAL,ALLOCATABLE               :: sendbuf2(:),recvbuf2(:)
INTEGER                        :: iProc
INTEGER                        :: globalNum(0:nProcessors-1), Displace(0:nProcessors-1), RecCount(0:nProcessors-1)
#endif
INTEGER                        :: TotalNumberMPF, counter2, BCTotalNumberMPF
INTEGER,ALLOCATABLE            :: locnPart(:),offsetnPart(:),nPart_glob(:),minnParts(:), iPartCount(:)
INTEGER                        :: iPart, iSpec, counter
REAL,ALLOCATABLE               :: PartData(:,:)
INTEGER                        :: PartDataSize       !number of entries in each line of PartData
REAL                           :: TotalFlowrateMPF, RandVal, BCTotalFlowrateMPF
LOGICAL,ALLOCATABLE            :: PartDone(:)
!===================================================================================================================================
SWRITE(*,*) ' WRITE DSMCSurfCollis TO FILE...'

TypeString='DSMCSurfCollis'
FileName=TRIM(TIMESTAMP(TRIM(ProjectName)//'_'//TRIM(TypeString),OutputTime))//'.h5'
PartDataSize=10
ALLOCATE(StrVarNames(PartDataSize))
StrVarNames(1)='ParticlePositionX'
StrVarNames(2)='ParticlePositionY'
StrVarNames(3)='ParticlePositionZ'
StrVarNames(4)='VelocityX'
StrVarNames(5)='VelocityY'
StrVarNames(6)='VelocityZ'
StrVarNames(7)='OldParticlePositionX'
StrVarNames(8)='OldParticlePositionY'
StrVarNames(9)='OldParticlePositionZ'
StrVarNames(10)='BCid'
ALLOCATE(locnPart(1:nSpecies) &
        ,offsetnPart(1:nSpecies) &
        ,nPart_glob(1:nSpecies) &
        ,minnParts(1:nSpecies) &
        ,iPartCount(1:nSpecies) )
#ifdef MPI
ALLOCATE(sendbuf(1:nSpecies) &
        ,recvbuf(1:nSpecies) )
#endif
ALLOCATE(SpeciesPositions( 1:nSpecies,1:MAXVAL(AnalyzeSurfCollis%Number(1:nSpecies)) ))

iPartCount(:)=0
DO iPart=1,AnalyzeSurfCollis%Number(nSpecies+1)
  IF (AnalyzeSurfCollis%Spec(iPart).LT.1 .OR. AnalyzeSurfCollis%Spec(iPart).GT.nSpecies) THEN
    CALL Abort(&
      __STAMP__,&
      'Error 1 in AnalyzeSurfCollis!')
  ELSE
    iPartCount(AnalyzeSurfCollis%Spec(iPart))=iPartCount(AnalyzeSurfCollis%Spec(iPart))+1
    SpeciesPositions(AnalyzeSurfCollis%Spec(iPart),iPartCount(AnalyzeSurfCollis%Spec(iPart)))=iPart
  END IF
END DO
DO iSpec=1,nSpecies
  locnPart(iSpec) = AnalyzeSurfCollis%Number(iSpec)
  IF (iPartCount(iSpec).NE.locnPart(iSpec)) CALL Abort(&
    __STAMP__,&
    'Error 2 in AnalyzeSurfCollis!')
END DO

#ifdef MPI
sendbuf(:)=locnPart(:)
recvbuf(:)=0
CALL MPI_EXSCAN(sendbuf,recvbuf,nSpecies,MPI_INTEGER,MPI_SUM,MPI_COMM_WORLD,iError)
offsetnPart(:)=recvbuf(:)
sendbuf(:)=recvbuf(:)+locnPart(:)
CALL MPI_BCAST(sendbuf(:),nSpecies,MPI_INTEGER,nProcessors-1,MPI_COMM_WORLD,iError) !last proc knows global number
!global numbers
nPart_glob(:)=sendbuf(:)
DEALLOCATE(sendbuf &
          ,recvbuf )
!LOGWRITE(*,*)'offsetnPart,locnPart,nPart_glob',offsetnPart,locnPart,nPart_glob
CALL MPI_ALLREDUCE(locnPart(:),minnParts(:),nSpecies,MPI_INTEGER,MPI_MIN,MPI_COMM_WORLD,IERROR)
IF (SFResampleAnalyzeSurfCollis) THEN
  CALL MPI_ALLGATHER(AnalyzeSurfCollis%Number(nSpecies+1), 1, MPI_INTEGER, globalNum, 1, MPI_INTEGER, MPI_COMM_WORLD, IERROR)
  TotalNumberMPF = SUM(globalNum)
ELSE
  CALL MPI_ALLREDUCE(AnalyzeSurfCollis%Number(nSpecies+1),TotalNumberMPF,1,MPI_INTEGER,MPI_SUM,MPI_COMM_WORLD,IERROR)
END IF
#else
offsetnPart(:)=0
nPart_glob(:)=locnPart(:)
minnParts(:)=locnPart(:)
TotalNumberMPF=AnalyzeSurfCollis%Number(nSpecies+1)
#endif
! determine number of parts at BC of interest
BCTotalNumberMPF=0
IF (SFResampleAnalyzeSurfCollis) THEN
  DO iPart=1,AnalyzeSurfCollis%Number(nSpecies+1)
    IF (AnalyzeSurfCollis%BCid(iPart).LT.1 .OR. AnalyzeSurfCollis%BCid(iPart).GT.nPartBound) THEN
      CALL Abort(&
        __STAMP__,&
        'Error 3 in AnalyzeSurfCollis!')
    ELSE IF ( ANY(LastAnalyzeSurfCollis%BCs.EQ.0) .OR. ANY(LastAnalyzeSurfCollis%BCs.EQ.AnalyzeSurfCollis%BCid(iPart)) ) THEN
      BCTotalNumberMPF = BCTotalNumberMPF + 1
    END IF
  END DO
#ifdef MPI
  CALL MPI_ALLREDUCE(MPI_IN_PLACE,BCTotalNumberMPF,1,MPI_INTEGER,MPI_SUM,MPI_COMM_WORLD,iError)
#endif
  BCTotalFlowrateMPF=REAL(BCTotalNumberMPF)/TimeSample
END IF
TotalFlowrateMPF=REAL(TotalNumberMPF)/TimeSample

IF(MPIRoot) THEN !create File-Skeleton
  ! Create file
  CALL OpenDataFile(TRIM(FileName),create=.TRUE.,single=.TRUE.,readOnly=.FALSE.)

  ! Write file header
  CALL WriteHDF5Header(TRIM(TypeString),File_ID)

  ! Write dataset properties "Time","VarNames","nSpecies","TotalFlowrateMPF"
  CALL WriteAttributeToHDF5(File_ID,'Time',1,RealScalar=OutputTime)
  CALL WriteAttributeToHDF5(File_ID,'VarNames',PartDataSize,StrArray=StrVarNames)
  CALL WriteAttributeToHDF5(File_ID,'NSpecies',1,IntegerScalar=nSpecies)
  CALL WriteAttributeToHDF5(File_ID,'TotalFlowrateMPF',1,RealScalar=TotalFlowrateMPF)

  CALL CloseDataFile()
END IF

#ifdef MPI
CALL MPI_BARRIER(MPI_COMM_WORLD,iError)
#endif
CALL OpenDataFile(TRIM(FileName),create=.FALSE.,single=.FALSE.,readOnly=.FALSE.,communicatorOpt=MPI_COMM_WORLD)

IF (SFResampleAnalyzeSurfCollis) THEN
  IF (LastAnalyzeSurfCollis%ReducePartNumber) THEN !reduce saved number of parts to MaxPartNumber
    LastAnalyzeSurfCollis%PartNumberSamp=MIN(BCTotalNumberMPF,LastAnalyzeSurfCollis%PartNumberReduced)
    ALLOCATE(PartDone(1:TotalNumberMPF))
    PartDone(:)=.FALSE.
  ELSE
    LastAnalyzeSurfCollis%PartNumberSamp=BCTotalNumberMPF
  END IF
  SWRITE(*,*) 'Number of saved particles for SFResampleAnalyzeSurfCollis: ',LastAnalyzeSurfCollis%PartNumberSamp
  SDEALLOCATE(LastAnalyzeSurfCollis%WallState)
  SDEALLOCATE(LastAnalyzeSurfCollis%Species)
  ALLOCATE(LastAnalyzeSurfCollis%WallState(6,LastAnalyzeSurfCollis%PartNumberSamp))
  ALLOCATE(LastAnalyzeSurfCollis%Species(LastAnalyzeSurfCollis%PartNumberSamp))
  LastAnalyzeSurfCollis%pushTimeStep = HUGE(LastAnalyzeSurfCollis%pushTimeStep)
#ifdef MPI
  IF (BCTotalNumberMPF.GT.0) THEN
    ALLOCATE(sendbuf2(1:AnalyzeSurfCollis%Number(nSpecies+1)*8))
    ALLOCATE(recvbuf2(1:TotalNumberMPF*8))
    ! Fill sendbufer
    counter2 = 0
    DO iPart=1,AnalyzeSurfCollis%Number(nSpecies+1)
      sendbuf2(counter2+1:counter2+6) = AnalyzeSurfCollis%Data(iPart,1:6)
      sendbuf2(counter2+7)           = REAL(AnalyzeSurfCollis%Spec(iPart))
      sendbuf2(counter2+8)           = REAL(AnalyzeSurfCollis%BCid(iPart))
      counter2 = counter2 + 8
    END DO
    ! Distribute particles to all procs
    counter2 = 0
    DO iProc = 0, nProcessors-1
      RecCount(iProc) = globalNum(iProc) * 8
      Displace(iProc) = counter2
      counter2 = counter2 + globalNum(iProc)*8
    END DO
    CALL MPI_ALLGATHERV(sendbuf2, 8*globalNum(myRank), MPI_DOUBLE_PRECISION, &
      recvbuf2, RecCount, Displace, MPI_DOUBLE_PRECISION, MPI_COMM_WORLD, IERROR)
    ! Add them to particle list
    counter2 = -8 !moved increment before usage, thus: -8 instead of 0
    DO counter = 1, LastAnalyzeSurfCollis%PartNumberSamp
      IF (LastAnalyzeSurfCollis%ReducePartNumber) THEN !reduce saved number of parts (differently in each proc. Could be changed)
        DO !get random (equal!) position between 8*[0,TotalNumberMPF-1] and accept if .NOT.PartDone and with right BC
          CALL RANDOM_NUMBER(RandVal)
          counter2 = MIN(1+INT(RandVal*REAL(TotalNumberMPF)),TotalNumberMPF) !( MIN(1+INT(RandVal*REAL(TotalNumberMPF)),TotalNumberMPF) - 1) *8
          IF (.NOT.PartDone(counter2) .AND. &
            ( ANY(LastAnalyzeSurfCollis%BCs.EQ.0) .OR. ANY(LastAnalyzeSurfCollis%BCs.EQ.INT(recvbuf2(8*counter2))) )) THEN
            PartDone(counter2)=.TRUE.
            counter2 = 8*(counter2-1)
            EXIT
          END IF
        END DO
      ELSE
        counter2 = counter2 + 8
      END IF
      LastAnalyzeSurfCollis%WallState(:,counter) = recvbuf2(counter2+1:counter2+6)
      LastAnalyzeSurfCollis%Species(counter) = INT(recvbuf2(counter2+7))
      IF (ANY(LastAnalyzeSurfCollis%SpeciesForDtCalc.EQ.0) .OR. &
          ANY(LastAnalyzeSurfCollis%SpeciesForDtCalc.EQ.LastAnalyzeSurfCollis%Species(counter))) &
        LastAnalyzeSurfCollis%pushTimeStep = MIN( LastAnalyzeSurfCollis%pushTimeStep &
        , DOT_PRODUCT(LastAnalyzeSurfCollis%NormVecOfWall,LastAnalyzeSurfCollis%WallState(4:6,counter)) )
    END DO
    DEALLOCATE(sendbuf2 &
              ,recvbuf2 )
  END IF
#else
  ! Add particle to list
  counter2 = 0
  DO counter = 1, LastAnalyzeSurfCollis%PartNumberSamp
    IF (LastAnalyzeSurfCollis%ReducePartNumber) THEN !reduce saved number of parts (differently for each proc. Could be changed)
      DO !get random (equal!) position between [1,TotalNumberMPF] and accept if .NOT.PartDone and with right BC
        CALL RANDOM_NUMBER(RandVal)
        counter2 = MIN(1+INT(RandVal*REAL(TotalNumberMPF)),TotalNumberMPF)
        IF (.NOT.PartDone(counter2) .AND. &
          ( ANY(LastAnalyzeSurfCollis%BCs.EQ.0) .OR. ANY(LastAnalyzeSurfCollis%BCs.EQ.AnalyzeSurfCollis%BCid(counter2)) )) THEN
          PartDone(counter2)=.TRUE.
          EXIT
        END IF
      END DO
    ELSE
      counter2 = counter2 + 1
    END IF
    LastAnalyzeSurfCollis%WallState(:,counter) = AnalyzeSurfCollis%Data(counter2,1:6)
    LastAnalyzeSurfCollis%Species(counter) = AnalyzeSurfCollis%Spec(counter2)
    IF (ANY(LastAnalyzeSurfCollis%SpeciesForDtCalc.EQ.0) .OR. &
        ANY(LastAnalyzeSurfCollis%SpeciesForDtCalc.EQ.LastAnalyzeSurfCollis%Species(counter))) &
      LastAnalyzeSurfCollis%pushTimeStep = MIN( LastAnalyzeSurfCollis%pushTimeStep &
      , DOT_PRODUCT(LastAnalyzeSurfCollis%NormVecOfWall,LastAnalyzeSurfCollis%WallState(4:6,counter)) )
  END DO
#endif
  IF (LastAnalyzeSurfCollis%pushTimeStep .LE. 0.) THEN
    CALL Abort(&
      __STAMP__,&
      'Error with SFResampleAnalyzeSurfCollis. Something is wrong with velocities or NormVecOfWall!',&
      999,LastAnalyzeSurfCollis%pushTimeStep)
  ELSE
    LastAnalyzeSurfCollis%pushTimeStep = r_SF / LastAnalyzeSurfCollis%pushTimeStep !dt required for smallest projected velo to cross r_SF
    LastAnalyzeSurfCollis%PartNumberDepo = NINT(BCTotalFlowrateMPF * LastAnalyzeSurfCollis%pushTimeStep)
    SWRITE(*,'(A,E12.5,x,I0)') 'Total Flowrate and to be inserted number of MP for SFResampleAnalyzeSurfCollis: ' &
      ,BCTotalFlowrateMPF, LastAnalyzeSurfCollis%PartNumberDepo
    IF (LastAnalyzeSurfCollis%PartNumberDepo .GT. LastAnalyzeSurfCollis%PartNumberSamp) THEN
      SWRITE(*,*) 'WARNING: PartNumberDepo .GT. PartNumberSamp!'
    END IF
    IF (LastAnalyzeSurfCollis%PartNumberDepo .GT. LastAnalyzeSurfCollis%PartNumThreshold) THEN
      CALL Abort(&
        __STAMP__,&
        'Error with SFResampleAnalyzeSurfCollis: PartNumberDepo .gt. PartNumThreshold',&
        LastAnalyzeSurfCollis%PartNumberDepo,r_SF/LastAnalyzeSurfCollis%pushTimeStep)
    END IF
  END IF
END IF !SFResampleAnalyzeSurfCollis

DO iSpec=1,nSpecies
  ALLOCATE(PartData(offsetnPart(iSpec)+1:offsetnPart(iSpec)+locnPart(iSpec),PartDataSize))
  DO iPart=1,locnPart(iSpec)
    PartData(offsetnPart(iSpec)+iPart,1)=AnalyzeSurfCollis%Data(SpeciesPositions(iSpec,iPart),1)
    PartData(offsetnPart(iSpec)+iPart,2)=AnalyzeSurfCollis%Data(SpeciesPositions(iSpec,iPart),2)
    PartData(offsetnPart(iSpec)+iPart,3)=AnalyzeSurfCollis%Data(SpeciesPositions(iSpec,iPart),3)
    PartData(offsetnPart(iSpec)+iPart,4)=AnalyzeSurfCollis%Data(SpeciesPositions(iSpec,iPart),4)
    PartData(offsetnPart(iSpec)+iPart,5)=AnalyzeSurfCollis%Data(SpeciesPositions(iSpec,iPart),5)
    PartData(offsetnPart(iSpec)+iPart,6)=AnalyzeSurfCollis%Data(SpeciesPositions(iSpec,iPart),6)
    PartData(offsetnPart(iSpec)+iPart,7)=AnalyzeSurfCollis%Data(SpeciesPositions(iSpec,iPart),7)
    PartData(offsetnPart(iSpec)+iPart,8)=AnalyzeSurfCollis%Data(SpeciesPositions(iSpec,iPart),8)
    PartData(offsetnPart(iSpec)+iPart,9)=AnalyzeSurfCollis%Data(SpeciesPositions(iSpec,iPart),9)
    PartData(offsetnPart(iSpec)+iPart,10)=REAL(AnalyzeSurfCollis%BCid(SpeciesPositions(iSpec,iPart)))
  END DO
  WRITE(H5_Name,'(A,I3.3)') 'SurfCollisData_Spec',iSpec
  IF(minnParts(iSpec).EQ.0)THEN
    CALL WriteArrayToHDF5(DataSetName=TRIM(H5_Name), rank=2,&
                          nValGlobal=(/nPart_glob(iSpec),PartDataSize/),&
                          nVal=      (/locnPart(iSpec),PartDataSize  /),&
                          offset=    (/offsetnPart(iSpec) , 0  /),&
                          collective=.FALSE., RealArray=PartData)
  ELSE
    CALL WriteArrayToHDF5(DataSetName=TRIM(H5_Name), rank=2,&
                          nValGlobal=(/nPart_glob(iSpec),PartDataSize/),&
                          nVal=      (/locnPart(iSpec),PartDataSize  /),&
                          offset=    (/offsetnPart(iSpec) , 0  /),&
                          collective=.TRUE., RealArray=PartData)
  END IF
  DEALLOCATE(PartData)
END DO !iSpec

CALL CloseDataFile()
DEALLOCATE(locnPart &
          ,offsetnPart &
          ,nPart_glob &
          ,minnParts &
          ,iPartCount )
DEALLOCATE(SpeciesPositions)
DEALLOCATE(StrVarNames)

END SUBROUTINE WriteAnalyzeSurfCollisToHDF5


END MODULE MOD_DSMC_Analyze
