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

MODULE MOD_part_emission
!===================================================================================================================================
! module for particle emission
!===================================================================================================================================
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
PRIVATE
!-----------------------------------------------------------------------------------------------------------------------------------
! GLOBAL VARIABLES 
!-----------------------------------------------------------------------------------------------------------------------------------
! Private Part ---------------------------------------------------------------------------------------------------------------------
! Public Part ----------------------------------------------------------------------------------------------------------------------

INTERFACE InitializeParticleEmission
  MODULE PROCEDURE InitializeParticleEmission
END INTERFACE

INTERFACE ParticleInserting
  MODULE PROCEDURE ParticleInserting
END INTERFACE

INTERFACE SetParticleChargeAndMass
  MODULE PROCEDURE SetParticleChargeAndMass
END INTERFACE

INTERFACE SetParticleVelocity
  MODULE PROCEDURE SetParticleVelocity
END INTERFACE

INTERFACE SetParticleMPF
  MODULE PROCEDURE SetParticleMPF
END INTERFACE

INTERFACE InitializeParticleSurfaceflux
  MODULE PROCEDURE InitializeParticleSurfaceflux
END INTERFACE

INTERFACE ParticleSurfaceflux
  MODULE PROCEDURE ParticleSurfaceflux
END INTERFACE

INTERFACE CalcVelocity_maxwell_lpn
  MODULE PROCEDURE CalcVelocity_maxwell_lpn
END INTERFACE

INTERFACE AdaptiveBCAnalyze
  MODULE PROCEDURE AdaptiveBCAnalyze
END INTERFACE

!----------------------------------------------------------------------------------------------------------------------------------

PUBLIC         :: InitializeParticleEmission, InitializeParticleSurfaceflux, ParticleSurfaceflux, ParticleInserting &
                , SetParticleChargeAndMass, SetParticleVelocity, SetParticleMPF &
                , AdaptiveBCAnalyze, CalcVelocity_maxwell_lpn
!===================================================================================================================================
PUBLIC::DefineParametersParticleEmission
CONTAINS

!==================================================================================================================================
!> Define parameters for particle emission (surface flux)
!==================================================================================================================================
SUBROUTINE DefineParametersParticleEmission()
! MODULES
USE MOD_Globals
USE MOD_ReadInTools ,ONLY: prms
IMPLICIT NONE
!==================================================================================================================================
CALL prms%SetSection("Particle Emission")

CALL prms%CreateIntOption(      'Part-Species[$]-nSurfacefluxBCs'&
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Number of SF emissions', '0', numberedmulti=.TRUE.)
CALL prms%CreateIntOption(      'Part-Species[$]-Surfaceflux[$]-BC' &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'PartBound to be emitted from', '0', numberedmulti=.TRUE.)
CALL prms%CreateStringOption(   'Part-Species[$]-Surfaceflux[$]-velocityDistribution' &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Specifying keyword for velocity distribution' , 'constant'&
, numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-Surfaceflux[$]-VeloIC' &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Velocity for inital Data', '0.', numberedmulti=.TRUE.)
CALL prms%CreateLogicalOption(  'Part-Species[$]-Surfaceflux[$]-VeloIsNormal' &
                                , 'TODO-DEFINE-PARAMETER VeloIC is in Surf-Normal instead of VeloVecIC' &
                                , '.FALSE.', numberedmulti=.TRUE.)
CALL prms%CreateRealArrayOption('Part-Species[$]-Surfaceflux[$]-VeloVecIC' &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Normalized velocity vector' , '0.0 , 0.0 , 0.0', numberedmulti=.TRUE.)
CALL prms%CreateLogicalOption(  'Part-Species[$]-Surfaceflux[$]-SimpleRadialVeloFit' &
                                      , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Fit of veloR/veloTot=-r*(A*exp(B*r)+C)', '.FALSE.', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-Surfaceflux[$]-preFac' &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'A , see SimpleRadialVeloFit' &
                                , '0.', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-Surfaceflux[$]-powerFac' &
                                      , 'TODO-DEFINE-PARAMETER\n'//&
                                  'B , see SimpleRadialVeloFit' &
                                , '0.', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-Surfaceflux[$]-shiftFac' &
                                      , 'TODO-DEFINE-PARAMETER\n'//&
                                  'C , see SimpleRadialVeloFit' &
                                , '0.', numberedmulti=.TRUE.)
CALL prms%CreateIntOption(      'Part-Species[$]-Surfaceflux[$]-axialDir' &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Axial direction of coordinates in polar system', '1', numberedmulti=.TRUE.)
CALL prms%CreateRealArrayOption('Part-Species[$]-Surfaceflux[$]-origin' &
                                , 'TODO-DEFINE-PARAMETER Origin in orth(ogonal?) coordinates of polar system' , '0.0 , 0.0'&
                                ,  numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-Surfaceflux[$]-rmax' &
                                , 'TODO-DEFINE-PARAMETER Max radius of to-be inserted particles', '1e21', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-Surfaceflux[$]-rmin' &
                                , 'TODO-DEFINE-PARAMETER Min radius of to-be inserted particles', '0.', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-Surfaceflux[$]-MWTemperatureIC' &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Temperature for Maxwell Distribution', '0.', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-Surfaceflux[$]-PartDensity' &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'PartDensity (real particles per m^3) for LD_insert or  (vpi_)cub./cyl. as alternative  to'//&
                                  ' Part.Emis. in Type1'  , '0.', numberedmulti=.TRUE.)
CALL prms%CreateLogicalOption(  'Part-Species[$]-Surfaceflux[$]-ReduceNoise' &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Reduce stat. noise by global calc. of PartIns', '.FALSE.', numberedmulti=.TRUE.)
CALL prms%CreateLogicalOption(  'Part-Species[$]-Surfaceflux[$]-AcceptReject' &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  ' Perform ARM for skewness of RefMap-positioning', '.TRUE.', numberedmulti=.TRUE.)
CALL prms%CreateIntOption(      'Part-Species[$]-Surfaceflux[$]-ARM_DmaxSampleN' &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Number of sample intervals in xi/eta for Dmax-calc.', '1', numberedmulti=.TRUE.)
CALL prms%CreateLogicalOption(  'DoForceFreeSurfaceFlux' &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Flag if the stage reconstruction uses a force' , '.FALSE.')

CALL prms%CreateLogicalOption(  'OutputSurfaceFluxLinked' &
                                , 'Flag to print the SurfaceFlux-linked Info' , '.FALSE.')


END SUBROUTINE DefineParametersParticleEmission
                                                                                                   
SUBROUTINE InitializeParticleEmission()
!===================================================================================================================================
! Initialize particles / Insert initial particles
!===================================================================================================================================
! MODULES
#ifdef MPI
USE MOD_Particle_MPI_Vars,     ONLY : PartMPI
#endif /* MPI*/
USE MOD_Globals
USE MOD_Restart_Vars,   ONLY : DoRestart
USE MOD_Particle_Vars,  ONLY : Species,nSpecies,PDM,PEM, usevMPF, SpecReset
USE MOD_part_tools,     ONLY : UpdateNextFreePosition
USE MOD_ReadInTools
USE MOD_DSMC_Vars,      ONLY : useDSMC, DSMC
USE MOD_part_pressure,  ONLY : ParticleInsideCheck
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
!----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
INTEGER               :: i, NbrOfParticle,iInit,iPart,PositionNbr
INTEGER               :: nPartInside
INTEGER(KIND=8)       :: insertParticles
REAL                  :: EInside,TempInside
LOGICAL               :: EmType6
!===================================================================================================================================

SWRITE(UNIT_stdOut,'(A)') ' Initial particle inserting... '

CALL UpdateNextFreePosition()
EmType6=.false.
DO i=1, nSpecies
  DO iInit = Species(i)%StartnumberOfInits, Species(i)%NumberOfInits
    IF ((Species(i)%Init(iInit)%ParticleEmissionType.EQ.6)) THEN
      EmType6=.true.
      EXIT
    END IF
  END DO
  IF (EmType6) EXIT
END DO
IF (.NOT.EmType6) DSMC%OutputMeshSamp=.false.
!   CALL Deposition()
!   IF (MESH%t.GE.PIC%DelayTime) PIC%ParticleTreatmentMethod='standard'
  ! for the case of particle insertion per time, the inserted particle number for the current time must
  ! be updated. Otherwise, at the first timestep after restart, these particles will be inserted again
!  DO i=1,nSpecies
!    Species(i)%InsertedParticle = INT(Species(i)%ParticleEmission * Time)
!  END DO
!ELSE
! Do insanity check of max. particle number compared to the number that is to be inserted for certain insertion types
insertParticles = 0
DO i=1,nSpecies
  IF (DoRestart .AND. .NOT.SpecReset(i)) CYCLE
  DO iInit = Species(i)%StartnumberOfInits, Species(i)%NumberOfInits
    IF (TRIM(Species(i)%Init(iInit)%SpaceIC).EQ.'cell_local') THEN
      IF (Species(i)%Init(iInit)%PartDensity.EQ.0) THEN
#ifdef MPI
        insertParticles = insertParticles + INT(REAL(Species(i)%Init(iInit)%initialParticleNumber)/PartMPI%nProcs,8)
#else
        insertParticles = insertParticles + INT(Species(i)%Init(iInit)%initialParticleNumber,8)
#endif
      ELSE
        insertParticles = insertParticles + INT(Species(i)%Init(iInit)%initialParticleNumber,8)
      END IF
    ELSE IF ((TRIM(Species(i)%Init(iInit)%SpaceIC).EQ.'cuboid') &
         .OR.(TRIM(Species(i)%Init(iInit)%SpaceIC).EQ.'cylinder')) THEN
#ifdef MPI
      insertParticles = insertParticles + INT(REAL(Species(i)%Init(iInit)%initialParticleNumber)/PartMPI%nProcs)
#else
      insertParticles = insertParticles + INT(Species(i)%Init(iInit)%initialParticleNumber,8)
#endif
    END IF
  END DO
END DO
IF (insertParticles.GT.PDM%maxParticleNumber) THEN
#ifdef MPI
  WRITE(UNIT_stdOut,'(I0,A40,I0)')PartMPI%MyRank,' Maximum particle number : ',PDM%maxParticleNumber
  WRITE(UNIT_stdOut,'(I0,A40,I0)')PartMPI%MyRank,' To be inserted particles: ',insertParticles
#else
  WRITE(UNIT_stdOut,'(A40,I0)')' Maximum particle number : ',PDM%maxParticleNumber
  WRITE(UNIT_stdOut,'(A40,I0)')' To be inserted particles: ',insertParticles
#endif
  CALL abort(&
__STAMP__&
,'Number of to be inserted particles per init-proc exceeds max. particle number! ')
END IF
DO i = 1,nSpecies
  IF (DoRestart .AND. .NOT.SpecReset(i)) CYCLE
  DO iInit = Species(i)%StartnumberOfInits, Species(i)%NumberOfInits
    ! check whether initial particles are defined twice (old and new method) to prevent erroneous doubling
    ! of particles
    !!!Here could be added a check for geometrically overlapping Inits and same Usefor-Flags!!!
    !IF ((Species(i)%initialParticleNumber.NE.0).AND.(Species(i)%NumberOfInits.NE.0)) THEN
    !  WRITE(*,*) 'ERROR in ParticleEmission: Initial emission may only be defined in additional *Init#* blocks'
    !  WRITE(*,*) 'OR the standard initialisation, not both!'
    !  STOP
    !END IF
    IF (((Species(i)%Init(iInit)%ParticleEmissionType .EQ. 4).OR.(Species(i)%Init(iInit)%ParticleEmissionType .EQ. 6)) .AND. &
         (Species(i)%Init(iInit)%UseForInit)) THEN ! Special emission type: constant density in cell, + to be used for init
      CALL abort(&
__STAMP__&
,' particle pressure not moved to picasso!')
      IF (Species(i)%Init(iInit)%ParticleEmissionType .EQ. 4) THEN
        CALL ParticleInsertingCellPressure(i,iInit,NbrofParticle)
        CALL SetParticleVelocity(i,iInit,NbrOfParticle,1)
      ELSE !emission type 6 (constant pressure outflow)
        CALL ParticleInsertingPressureOut(i,iInit,NbrofParticle)
      END IF
      CALL SetParticleChargeAndMass(i,NbrOfParticle)
      IF (usevMPF) CALL SetParticleMPF(i,NbrOfParticle)
      IF (useDSMC) THEN
        IF(NbrOfParticle.gt.PDM%maxParticleNumber)THEN
          NbrOfParticle = PDM%maxParticleNumber
        END IF
        iPart = 1
        DO WHILE (iPart .le. NbrOfParticle)
          PositionNbr = PDM%nextFreePosition(iPart+PDM%CurrentNextFreePosition)
          IF (PositionNbr .ne. 0) THEN
            PDM%PartInit(PositionNbr) = iInit
          END IF
          iPart = iPart + 1
        END DO
      END IF
      !IF (useDSMC) CALL SetParticleIntEnergy(i,NbrOfParticle)
      PDM%ParticleVecLength = PDM%ParticleVecLength + NbrOfParticle
      CALL UpdateNextFreePosition()
    ELSE IF (Species(i)%Init(iInit)%UseForInit) THEN ! no special emissiontype to be used
      IF(Species(i)%Init(iInit)%initialParticleNumber.GT.HUGE(1)) CALL abort(&
__STAMP__&
,' Integer of initial particle number larger than max integer size: ',HUGE(1))
      NbrOfParticle = INT(Species(i)%Init(iInit)%initialParticleNumber,4)
      SWRITE(UNIT_stdOut,'(A,I0,A)') ' Set particle position for species ',i,' ... '
#ifdef MPI
      CALL SetParticlePosition(i,iInit,NbrOfParticle,1)
      CALL SetParticlePosition(i,iInit,NbrOfParticle,2)
#else
      CALL SetParticlePosition(i,iInit,NbrOfParticle)
#endif /*MPI*/
      SWRITE(UNIT_stdOut,'(A,I0,A)') ' Set particle velocities for species ',i,' ... '
      CALL SetParticleVelocity(i,iInit,NbrOfParticle,1)
      SWRITE(UNIT_stdOut,'(A,I0,A)') ' Set particle charge and mass for species ',i,' ... '
      CALL SetParticleChargeAndMass(i,NbrOfParticle)
      IF (usevMPF) CALL SetParticleMPF(i,NbrOfParticle)
      IF (useDSMC) THEN
        IF(NbrOfParticle.gt.PDM%maxParticleNumber)THEN
          NbrOfParticle = PDM%maxParticleNumber
        END IF
        iPart = 1
        DO WHILE (iPart .le. NbrOfParticle)
          PositionNbr = PDM%nextFreePosition(iPart+PDM%CurrentNextFreePosition)
          IF (PositionNbr .ne. 0) THEN
            PDM%PartInit(PositionNbr) = iInit
          END IF
          iPart = iPart + 1
        END DO
      END IF
      !IF (useDSMC) CALL SetParticleIntEnergy(i,NbrOfParticle)
      PDM%ParticleVecLength = PDM%ParticleVecLength + NbrOfParticle
      CALL UpdateNextFreePosition()
      ! constant pressure condition
      IF ((Species(i)%Init(iInit)%ParticleEmissionType .EQ. 3).OR.(Species(i)%Init(iInit)%ParticleEmissionType .EQ. 5)) THEN
        CALL abort(&
__STAMP__&
,' particle pressure not moved in picasso!')
        CALL ParticleInsideCheck(i, iInit, nPartInside, TempInside, EInside)
        IF (Species(i)%Init(iInit)%ParticleEmission .GT. nPartInside) THEN
          NbrOfParticle = INT(Species(i)%Init(iInit)%ParticleEmission) - nPartInside
          IPWRITE(UNIT_stdOut,*) 'Emission PartNum (Spec ',i,')', NbrOfParticle
#ifdef MPI
          CALL SetParticlePosition(i,iInit,NbrOfParticle,1)
          CALL SetParticlePosition(i,iInit,NbrOfParticle,2)
#else
          CALL SetParticlePosition(i,iInit,NbrOfParticle)
#endif
          CALL SetParticleVelocity(i,iInit,NbrOfParticle,1)
          CALL SetParticleChargeAndMass(i,NbrOfParticle)
          IF (usevMPF) CALL SetParticleMPF(i,NbrOfParticle)
          !IF (useDSMC) CALL SetParticleIntEnergy(i,NbrOfParticle)
          PDM%ParticleVecLength = PDM%ParticleVecLength + NbrOfParticle
          CALL UpdateNextFreePosition()
        END IF
      END IF
    END IF ! not Emissiontype 4
  END DO !inits
END DO ! species

!--- set last element to current element (needed when ParticlePush is not executed, e.g. "delay")
DO i = 1,PDM%ParticleVecLength
  PEM%lastElement(i) = PEM%Element(i)
END DO

SWRITE(UNIT_stdOut,'(A)') ' ...DONE '

END SUBROUTINE InitializeParticleEmission

#ifdef MPI
SUBROUTINE ParticleInserting(mode_opt)                                                             
#else
SUBROUTINE ParticleInserting()                                                                     
#endif
!===================================================================================================================================
! Particle Inserting
!===================================================================================================================================
! Modules
#ifdef MPI
USE MOD_Particle_MPI_Vars,     ONLY : PartMPI
#endif /* MPI*/
USE MOD_Globals
USE MOD_Timedisc_Vars         , ONLY : dt,time
USE MOD_Timedisc_Vars          ,ONLY: RKdtFrac,RKdtFracTotal
USE MOD_Particle_Vars
USE MOD_PIC_Vars
USE MOD_part_tools             ,ONLY : UpdateNextFreePosition  
USE MOD_DSMC_Vars              ,ONLY : useDSMC, CollisMode, SpecDSMC
USE MOD_DSMC_Init              ,ONLY : DSMC_SetInternalEnr_LauxVFD
USE MOD_DSMC_PolyAtomicModel   ,ONLY : DSMC_SetInternalEnr_Poly
#if (PP_TimeDiscMethod==300)
!USE MOD_FPFlow_Init,   ONLY : SetInternalEnr_InitFP
#endif
#if (PP_TimeDiscMethod==1000) || (PP_TimeDiscMethod==1001)
USE MOD_LD_Init                ,ONLY : CalcDegreeOfFreedom
USE MOD_LD_Vars
#endif
USE MOD_Particle_Analyze_Vars  ,ONLY: CalcPartBalance,nPartIn,PartEkinIn
USE MOD_Particle_Analyze       ,ONLY: CalcEkinPart
USE MOD_part_pressure          ,ONLY: ParticlePressure, ParticlePressureRem
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
#ifdef MPI
INTEGER, OPTIONAL                :: mode_opt
#endif
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
! Local variable declaration                                                                       
INTEGER                          :: i , iPart, PositionNbr, iInit, IntSample
INTEGER                , SAVE    :: NbrOfParticle=0                                             
INTEGER(KIND=8)                  :: inserted_Particle_iter,inserted_Particle_time               
INTEGER(KIND=8)                  :: inserted_Particle_diff  
REAL                             :: PartIns, RandVal1
REAL                             :: RiseFactor, RiseTime
#ifdef MPI
INTEGER                          :: mode                                            
INTEGER                          :: InitGroup
#endif
!===================================================================================================================================

!----------------------------------------------------------------------------------------------------------------------------------
!!! VORSICHT: FUNKTIONIERT SO MOMENTAN NUR MIT 1 SPEZIES!!!!
! --- fuer mehr als eine Spezies gibt es bei der Benutzung des
!     mode_opt Flags Probleme mit den non-blocking communications.
!     Es koennte dann passieren, dass Nachrichten falsch zugeordnet werden.
!     Sicherheitshalber sollte man kein mode_opt Argument bei mehrern
!     Spezies uebergeben.
#ifdef MPI
IF (PRESENT(mode_opt)) THEN
  mode=mode_opt
ELSE
  mode=0
END IF
#endif
!---  Emission at time step (initial emission see particle_init.f90: InitializeParticleEmission)
DO i=1,nSpecies
  DO iInit = Species(i)%StartnumberOfInits, Species(i)%NumberOfInits
    IF (((Species(i)%Init(iInit)%ParticleEmissionType .NE. 4).AND.(Species(i)%Init(iInit)%ParticleEmissionType .NE. 6)) .AND. &
         (Species(i)%Init(iInit)%UseForEmission)) THEN ! no constant density in cell type, + to be used for init
#ifdef MPI
      IF (mode.NE.2) THEN
#endif
        SELECT CASE(Species(i)%Init(iInit)%ParticleEmissionType)
        CASE(1) ! Emission Type: Particles per !!!!!SECOND!!!!!!!! (not per ns)
          IF (Species(i)%Init(iInit)%VirtPreInsert .AND. Species(i)%Init(iInit)%PartDensity.GT.0.) THEN
            PartIns=Species(i)%Init(iInit)%ParticleEmission * dt*RKdtFrac  ! emitted particles during time-slab
            NbrOfParticle = 0 ! calculated within SetParticlePosition itself!
          ELSE IF (.NOT.DoPoissonRounding .AND. .NOT.DoTimeDepInflow) THEN
            PartIns=Species(i)%Init(iInit)%ParticleEmission * dt*RKdtFrac  ! emitted particles during time-slab
            inserted_Particle_iter = INT(PartIns,8)                                     ! number of particles to be inserted
            PartIns=Species(i)%Init(iInit)%ParticleEmission * (Time + dt*RKdtFracTotal) ! total number of emitted particle over 
                                                                                        ! simulation
            CALL RANDOM_NUMBER(RandVal1)
            !-- random-round the inserted_Particle_time for preventing periodicity 
            ! PO & SC: why, sometimes we do not want this add, TB is bad!
            IF (inserted_Particle_iter.GE.1) THEN
              CALL RANDOM_NUMBER(RandVal1)
              inserted_Particle_time = INT(PartIns + RandVal1,8) ! adds up to ONE 
            ELSE IF((inserted_Particle_iter.GE.0).AND.(inserted_Particle_iter.LT.1)) THEN 
                                                       !needed, since InsertedParticleSurplus can increase
                                                       !and _iter>1 needs to be possible for preventing periodicity
              IF (ALMOSTEQUAL(PartIns,0.)) THEN !dummy
                inserted_Particle_time = INT(PartIns,8)
              ELSE !poisson-distri of PartIns-INT(PartIns)
                CALL SamplePoissonDistri( PartIns-INT(PartIns) , IntSample )
                inserted_Particle_time = INT(INT(PartIns)+IntSample,8) !INT(PartIns) + POISDISTRI( PartIns-INT(PartIns) )
              END IF
            ELSE !dummy
              inserted_Particle_time = INT(PartIns,8)
            END IF
            !-- evaluate inserted_Particle_time and inserted_Particle_iter
            inserted_Particle_diff = inserted_Particle_time - Species(i)%Init(iInit)%InsertedParticle &
              - inserted_Particle_iter - Species(i)%Init(iInit)%InsertedParticleSurplus &
              + Species(i)%Init(iInit)%InsertedParticleMisMatch
            Species(i)%Init(iInit)%InsertedParticleSurplus = ABS(MIN(inserted_Particle_iter + inserted_Particle_diff,0))
            NbrOfParticle = MAX(INT(inserted_Particle_iter + inserted_Particle_diff,4),0)
            !-- if maxwell velo dist and less than 5 parts: skip (to ensure maxwell dist)
            IF (TRIM(Species(i)%Init(iInit)%velocityDistribution).EQ.'maxwell') THEN
              IF (NbrOfParticle.LT.5) NbrOfParticle=0
            END IF
          ELSE IF (DoPoissonRounding .AND. .NOT.DoTimeDepInflow) THEN
            ! linear rise of inflow
            RiseTime=Species(i)%Init(iInit)%InflowRiseTime
            IF(RiseTime.GT.0.)THEN
              IF(Time-DelayTime.LT.RiseTime)THEN
                RiseFactor=(time-DelayTime)/RiseTime
              ELSE 
                RiseFactor=1.
              END IF
            ELSE
              RiseFactor=1.
            EnD IF
            PartIns=Species(i)%Init(iInit)%ParticleEmission * dt*RKdtFrac * RiseFactor  ! emitted particles during time-slab
            CALL RANDOM_NUMBER(RandVal1)
            IF (EXP(-PartIns).LE.TINY(PartIns)) THEN
              IPWRITE(*,*)'WARNING: target is too large for poisson sampling: switching now to Random rounding...'
              NbrOfParticle = INT(PartIns + RandVal1)
              DoPoissonRounding = .FALSE.
            ELSE !poisson-sampling instead of random rounding (reduces numerical non-equlibrium effects [Tysanner and Garcia 2004]
              CALL SamplePoissonDistri( PartIns , NbrOfParticle , DoPoissonRounding)
            END IF
          ELSE ! DoTimeDepInflow
            ! linear rise of inflow
            RiseTime=Species(i)%Init(iInit)%InflowRiseTime
            IF(RiseTime.GT.0.)THEN
              IF(Time-DelayTime.LT.RiseTime)THEN
                RiseFactor=(time-DelayTime)/RiseTime
              ELSE 
                RiseFactor=1.
              END IF
            ELSE
              RiseFactor=1.
            EnD IF
            ! emitted particles during time-slab
            PartIns=Species(i)%Init(iInit)%ParticleEmission * dt*RKdtFrac * RiseFactor &
                   + Species(i)%Init(iInit)%InsertedParticleMisMatch
            CALL RANDOM_NUMBER(RandVal1)
            NbrOfParticle = INT(PartIns + RandVal1)
          END IF
#ifdef MPI
          InitGroup=Species(i)%Init(iInit)%InitCOMM
          IF(PartMPI%InitGroup(InitGroup)%COMM.NE.MPI_COMM_NULL) THEN
            ! only procs which are part of group take part in the communication
             !NbrOfParticle based on RandVals!
            CALL MPI_BCAST(NbrOfParticle, 1, MPI_INTEGER,0,PartMPI%InitGroup(InitGroup)%COMM,IERROR) 
          ELSE
            NbrOfParticle=0
          END IF
          !CALL MPI_BCAST(NbrOfParticle, 1, MPI_INTEGER,0,PartMPI%COMM,IERROR) !NbrOfParticle based on RandVals!
#endif
          Species(i)%Init(iInit)%InsertedParticle = Species(i)%Init(iInit)%InsertedParticle + INT(NbrOfParticle,8)
        CASE(2)    ! Emission Type: Particles per Iteration
          IF (RKdtFracTotal .EQ. 1.) THEN !insert in last stage only, so that no reconstruction is nec. and number/iter matches
            NbrOfParticle = INT(Species(i)%Init(iInit)%ParticleEmission)
          ELSE
            NbrOfParticle = 0
          END IF
        CASE(3)
          CALL abort(&
__STAMP__&
,' particle pressure not moved in picasso!')
          CALL ParticlePressure (i, iInit, NbrOfParticle)
          ! if maxwell velo dist and less than 5 parts: skip (to ensure maxwell dist)
          IF (TRIM(Species(i)%Init(iInit)%velocityDistribution).EQ.'maxwell') THEN
            IF (NbrOfParticle.LT.5) NbrOfParticle=0
          END IF
        CASE(5) ! removal of all parts in pressure area and re-insertion
          CALL abort(&
__STAMP__&
,' particle pressure not moved in picasso!')
          CALL ParticlePressureRem (i, iInit, NbrOfParticle)
        CASE DEFAULT
          NbrOfParticle = 0
        END SELECT
#ifdef MPI
        CALL SetParticlePosition(i,iInit,NbrOfParticle,1)
      END IF
      IF (mode.NE.1) THEN
        CALL SetParticlePosition(i,iInit,NbrOfParticle,2)
#else
        CALL SetParticlePosition(i,iInit,NbrOfParticle)
#endif
       CALL SetParticleVelocity(i,iInit,NbrOfParticle,1)
       CALL SetParticleChargeAndMass(i,NbrOfParticle)
       IF (usevMPF) CALL SetParticleMPF(i,NbrOfParticle)
       ! define molecule stuff
       IF (useDSMC.AND.(CollisMode.GT.1)) THEN
         iPart = 1
         DO WHILE (iPart .le. NbrOfParticle)
           PositionNbr = PDM%nextFreePosition(iPart+PDM%CurrentNextFreePosition)
           IF (PositionNbr .ne. 0) THEN
             IF (SpecDSMC(i)%PolyatomicMol) THEN
#if (PP_TimeDiscMethod==300)
!               CALL SetInternalEnr_InitFP(i,iInit,PositionNbr,1)
#else
               CALL DSMC_SetInternalEnr_Poly(i,iInit,PositionNbr,1)
#endif
             ELSE
#if (PP_TimeDiscMethod==300)
!               CALL SetInternalEnr_InitFP(i,iInit,PositionNbr,1)
#else
               CALL DSMC_SetInternalEnr_LauxVFD(i,iInit,PositionNbr,1)
#endif
             END IF
           END IF
           iPart = iPart + 1
         END DO
       END IF
!#if (PP_TimeDiscMethod==1000) || (PP_TimeDiscMethod==1001)
!       iPart = 1
!       DO WHILE (iPart .le. NbrOfParticle)
!         PositionNbr = PDM%nextFreePosition(iPart+PDM%CurrentNextFreePosition)
!         IF (PositionNbr .ne. 0) THEN
!           PartStateBulkValues(PositionNbr,1) = Species(i)%Init(iInit)%VeloVecIC(1) * Species(i)%Init(iInit)%VeloIC
!           PartStateBulkValues(PositionNbr,2) = Species(i)%Init(iInit)%VeloVecIC(2) * Species(i)%Init(iInit)%VeloIC
!           PartStateBulkValues(PositionNbr,3) = Species(i)%Init(iInit)%VeloVecIC(3) * Species(i)%Init(iInit)%VeloIC
!           PartStateBulkValues(PositionNbr,4) = Species(i)%Init(iInit)%MWTemperatureIC
!           PartStateBulkValues(PositionNbr,5) = CalcDegreeOfFreedom(PositionNbr)
!         END IF
!         iPart = iPart + 1
!       END DO
!#endif
       ! instead of UpdateNextfreePosition we update the
       ! particleVecLength only.
       ! and doing it later, after calcpartbalance
       PDM%CurrentNextFreePosition = PDM%CurrentNextFreePosition + NbrOfParticle
       PDM%ParticleVecLength = PDM%ParticleVecLength + NbrOfParticle
       !CALL UpdateNextFreePosition()
#ifdef MPI
      END IF
#endif
    ELSE IF (Species(i)%Init(iInit)%UseForEmission) THEN ! Constant Pressure in Cell Emission (type 4 or 6)
      IF (Species(i)%Init(iInit)%ParticleEmissionType .EQ. 4) THEN
        CALL ParticleInsertingCellPressure(i,iInit,NbrofParticle)
        CALL SetParticleVelocity(i,iInit,NbrOfParticle,1)
      ELSE !emission type 6 (constant pressure outflow)
        CALL abort(&
__STAMP__&
,' particle pressure not moved in picasso!')
        CALL ParticleInsertingPressureOut(i,iInit,NbrofParticle)
      END IF
      CALL SetParticleChargeAndMass(i,NbrOfParticle)
      IF (usevMPF) CALL SetParticleMPF(i,NbrOfParticle)
      ! define molecule stuff
      IF (useDSMC.AND.(CollisMode.GT.1)) THEN
        iPart = 1
        DO WHILE (iPart .le. NbrOfParticle)
          PositionNbr = PDM%nextFreePosition(iPart+PDM%CurrentNextFreePosition)
          IF (PositionNbr .ne. 0) THEN
            IF (SpecDSMC(i)%PolyatomicMol) THEN
#if (PP_TimeDiscMethod==300)
!               CALL SetInternalEnr_InitFP(i,iInit,PositionNbr,1)
#else
              CALL DSMC_SetInternalEnr_Poly(i,iInit,PositionNbr,1)
#endif
            ELSE
#if (PP_TimeDiscMethod==300)
!               CALL SetInternalEnr_InitFP(i,iInit,PositionNbr,1)
#else
               CALL DSMC_SetInternalEnr_LauxVFD(i,iInit,PositionNbr,1)
#endif
            END IF
        END IF
          iPart = iPart + 1
        END DO
      END IF
!#if (PP_TimeDiscMethod==1000) || (PP_TimeDiscMethod==1001) !      iPart = 1 !      DO WHILE (iPart .le. NbrOfParticle)
!        PositionNbr = PDM%nextFreePosition(iPart+PDM%CurrentNextFreePosition)
!        IF (PositionNbr .ne. 0) THEN
!          PartStateBulkValues(PositionNbr,1) = Species(i)%Init(iInit)%VeloVecIC(1) * Species(i)%Init(iInit)%VeloIC
!          PartStateBulkValues(PositionNbr,2) = Species(i)%Init(iInit)%VeloVecIC(2) * Species(i)%Init(iInit)%VeloIC
!          PartStateBulkValues(PositionNbr,3) = Species(i)%Init(iInit)%VeloVecIC(3) * Species(i)%Init(iInit)%VeloIC
!          PartStateBulkValues(PositionNbr,4) = Species(i)%Init(iInit)%MWTemperatureIC
!          PartStateBulkValues(PositionNbr,5) = CalcDegreeOfFreedom(PositionNbr)
!        END IF
!        iPart = iPart + 1
!      END DO
!#endif
      ! instead of UpdateNextfreePosition we update the
      ! particleVecLength only.
      ! and doing it after calcpartbalance
      PDM%CurrentNextFreePosition = PDM%CurrentNextFreePosition + NbrOfParticle
      PDM%ParticleVecLength = PDM%ParticleVecLength + NbrOfParticle
      !CALL UpdateNextFreePosition()
    END IF
    ! compute number of input particles and energy
    IF(CalcPartBalance) THEN
      ! alter history, dirty hack for balance calculation
      PDM%CurrentNextFreePosition = PDM%CurrentNextFreePosition - NbrOfParticle
      IF(NbrOfParticle.GT.0)THEN
#if defined(LSERK) || defined(ROS) || defined(IMPA)
        ! IF((MOD(iter+1,PartAnalyzeStep).EQ.0).AND.(iter.GT.0))THEN ! caution if correct
        !   nPartInTmp(i)=nPartInTmp(i) + NBrofParticle
        !   DO iPart=1,NbrOfparticle
        !     PositionNbr = PDM%nextFreePosition(iPart+PDM%CurrentNextFreePosition)
        !     IF (PositionNbr .ne. 0) PartEkinInTmp(PartSpecies(PositionNbr)) = &
        !                             PartEkinInTmp(PartSpecies(PositionNbr))+CalcEkinPart(PositionNbr)
        !   END DO ! iPart
        ! ELSE
          nPartIn(i)=nPartIn(i) + NBrofParticle
          DO iPart=1,NbrOfparticle
            PositionNbr = PDM%nextFreePosition(iPart+PDM%CurrentNextFreePosition)
            IF (PositionNbr .ne. 0) PartEkinIn(PartSpecies(PositionNbr)) = &
                                    PartEkinIn(PartSpecies(PositionNbr))+CalcEkinPart(PositionNbr)
          END DO ! iPart
        ! END IF
#else
        nPartIn(i)=nPartIn(i) + NBrofParticle
        DO iPart=1,NbrOfparticle
          PositionNbr = PDM%nextFreePosition(iPart+PDM%CurrentNextFreePosition)
          IF (PositionNbr .ne. 0) PartEkinIn(PartSpecies(PositionNbr)) = &
                                  PartEkinIn(PartSpecies(PositionNbr))+CalcEkinPart(PositionNbr)
        END DO ! iPart
#endif
      END IF
      ! alter history, dirty hack for balance calculation
      PDM%CurrentNextFreePosition = PDM%CurrentNextFreePosition + NbrOfParticle
    END IF ! CalcPartBalance
    ! instead of UpdateNextfreePosition we update the
    ! particleVecLength only.
    !PDM%CurrentNextFreePosition = PDM%CurrentNextFreePosition + NbrOfParticle
    !PDM%ParticleVecLength = PDM%ParticleVecLength + NbrOfParticle
    !CALL UpdateNextFreePosition()
  END DO
END DO

END SUBROUTINE ParticleInserting
                                                                                                   
#ifdef MPI
SUBROUTINE SetParticlePosition(FractNbr,iInit,NbrOfParticle,mode)
#else
SUBROUTINE SetParticlePosition(FractNbr,iInit,NbrOfParticle)                                             
#endif /* MPI*/
!===================================================================================================================================
! Set particle position
!===================================================================================================================================
! modules
#ifdef MPI
USE MOD_Particle_MPI_Vars      ,ONLY: PartMPI,PartMPIInsert
#endif /* MPI*/
USE MOD_Globals
USE MOD_Globals_Vars           ,ONLY: BoltzmannConst
USE MOD_Particle_Vars          ,ONLY: IMDTimeScale,IMDLengthScale,IMDNumber,IMDCutOff,IMDCutOffxValue,IMDAtomFile
USE MOD_Particle_Vars          ,ONLY: DoPoissonRounding,DoTimeDepInflow
USE MOD_PIC_Vars
USE MOD_Particle_Vars          ,ONLY: Species,PDM,PartState,OutputVpiWarnings
USE MOD_Particle_Mesh_Vars     ,ONLY: GEO
USE MOD_Globals_Vars           ,ONLY: PI, TwoepsMach
USE MOD_Timedisc_Vars          ,ONLY: dt
USE MOD_Timedisc_Vars          ,ONLY: RKdtFrac
USE MOD_Particle_Mesh          ,ONLY: SingleParticleToExactElement,SingleParticleToExactElementNoMap
USE MOD_Particle_Tracking_Vars ,ONLY: DoRefMapping, TriaTracking
USE MOD_PICInterpolation       ,ONLY: InterpolateVariableExternalField
USE MOD_PICInterpolation_Vars  ,ONLY: VariableExternalField
USE MOD_PICInterpolation_vars  ,ONLY: useVariableExternalField
USE MOD_Equation_vars          ,ONLY: c_inv
USE MOD_LD                     ,ONLY: LD_SetParticlePosition
#if (PP_TimeDiscMethod==1000) || (PP_TimeDiscMethod==1001)
USE MOD_Timedisc_Vars          ,ONLY: DoDisplayIter, iter, IterDisplayStep
#endif
USE MOD_ReadInTools            ,ONLY: PrintOption
!#ifdef MPI
!! PilleO: to change into use MPi_2003 or so
!INCLUDE 'mpif.h'                                                                               
!#endif
!----------------------------------------------------------------------------------------------------------------------------------
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
INTEGER,INTENT(IN)                       :: FractNbr, iInit
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
INTEGER,INTENT(INOUT)                    :: NbrOfParticle
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
#ifdef MPI
INTEGER                                  :: mode
INTEGER                                  :: iProc,tProc, CellX, CellY, CellZ
INTEGER                                  :: msg_status(1:MPI_STATUS_SIZE)
INTEGER                                  :: MessageSize
LOGICAL                                  :: InsideMyBGM
#endif
REAL,ALLOCATABLE                         :: particle_positions(:)
INTEGER                                  :: allocStat
INTEGER                                  :: i,j,k,ParticleIndexNbr
INTEGER                                  :: mySumOfMatchedParticles, sumOfMatchedParticles              
INTEGER                                  :: nChunks, chunkSize, chunkSize2
REAL                                     :: lineVector(3),VectorGap(3)         
REAL                                     :: RandVal(3), Particle_pos(3),lineVector2(3)                  
REAL                                     :: n(3) , radius_vec(3)
REAL                                     :: II(3,3),JJ(3,3),NN(3,3)
REAL                                     :: RandVal1
REAL                                     :: radius, argumentTheta                    
REAL                                     :: rgyrate, Bintpol, pilen                    
REAL                                     :: x_step, y_step, z_step,  x_pos , y_pos
REAL                                     :: xlen, ylen, zlen
REAL                                     :: IMD_array(12),xMin,xMax,yMin,yMax,zMin,zMax
INTEGER                                  :: Nshift,ioUnit,io_error,IndNum
CHARACTER(LEN=255)                       :: StrTmp
INTEGER                                  :: iPart
REAL,ALLOCATABLE                         :: particle_positions_Temp(:) 
REAL                                     :: Vec3D(3), l_ins, v_line, delta_l, v_drift_line, A_ins, PartIns
REAL                                     :: v_drift_BV(2), lrel_ins_BV(4), BV_lengths(2), v_BV(2), delta_lBV(2)
REAL                                     :: intersecPoint(3), orifice_delta, lPeri, ParaCheck(3)
INTEGER                                  :: DimSend, orificePeriodic
LOGICAL                                  :: orificePeriodicLog(2), insideExcludeRegion
LOGICAL                                  :: DoExactPartNumInsert
#ifdef MPI
INTEGER                                  :: InitGroup,nChunksTemp,mySumOfRemovedParticles
INTEGER,ALLOCATABLE                      :: PartFoundInProc(:,:) ! 1 proc id, 2 local part id
REAL,ALLOCATABLE                         :: ProcMeshVol(:)
INTEGER,ALLOCATABLE                      :: ProcNbrOfParticle(:)
#endif                        
!===================================================================================================================================
! emission group communicator
#ifdef MPI
InitGroup=Species(FractNbr)%Init(iInit)%InitCOMM
IF(PartMPI%InitGroup(InitGroup)%COMM.EQ.MPI_COMM_NULL) THEN
  NbrofParticle=0
  RETURN
END IF
#endif /*MPI*/

IF (TRIM(Species(FractNbr)%Init(iInit)%SpaceIC).EQ.'cell_local') THEN
  DoExactPartNumInsert =  .FALSE.
  ! check if particle inserting during simulation or initial inserting and also if via partdensity or exact particle number
  ! nbrOfParticles is set for initial inserting if initialPartNum or partdensity is set in ini
  ! ParticleEmission and Partdensity not working together
  IF (NbrofParticle.EQ.0.AND.(Species(FractNbr)%Init(iInit)%ParticleEmission.EQ.0)) RETURN
  IF ((NbrofParticle.GT.0).AND.(Species(FractNbr)%Init(iInit)%PartDensity.LE.0.)) DoExactPartNumInsert = .TRUE.
  !IF ((Species(FractNbr)%Init(iInit)%ParticleEmission.GT.0).AND.(Species(FractNbr)%Init(iInit)%PartDensity.GT.0.)) CALL abort(&
!__STAMP__&
!,'ParticleEmission>0 and PartDensity>0. Can not be set at the same time for cell_local inserting. Set both for species: ',FractNbr)
  chunksize = 0
#ifdef MPI
  IF (mode.EQ.2) RETURN
  IF (PartMPI%InitGroup(InitGroup)%nProcs.GT.1 .AND. Species(FractNbr)%Init(iInit)%ElemPartDensityFileID.EQ.0) THEN
    IF (DoExactPartNumInsert) THEN
      IF (PartMPI%InitGroup(InitGroup)%MPIROOT) THEN
        ALLOCATE(ProcMeshVol(0:PartMPI%InitGroup(InitGroup)%nProcs-1))
        ALLOCATE(ProcNbrOfParticle(0:PartMPI%InitGroup(InitGroup)%nProcs-1))
        ProcMeshVol=0.
        ProcNbrOfParticle=0
      ELSE ! to reduce global memory allocation if a lot of procs are used
        ALLOCATE(ProcMeshVol(1))
        ALLOCATE(ProcNbrOfParticle(1))
        ProcMeshVol=0.
        ProcNbrOfParticle=0
      END IF !InitGroup%MPIroot
      CALL MPI_GATHER(GEO%LocalVolume,1,MPI_DOUBLE_PRECISION &
                     ,ProcMeshVol,1,MPI_DOUBLE_PRECISION,0,PartMPI%InitGroup(InitGroup)%COMM,iError)
      IF (PartMPI%InitGroup(InitGroup)%MPIROOT) THEN
        CALL IntegerDivide(NbrOfParticle,PartMPI%InitGroup(InitGroup)%nProcs,ProcMeshVol,ProcNbrOfParticle)
      END IF
      CALL MPI_SCATTER(ProcNbrOfParticle, 1, MPI_INTEGER, chunksize, 1, MPI_INTEGER, 0, PartMPI%InitGroup(InitGroup)%COMM, IERROR)
      SDEALLOCATE(ProcMeshVol)
      SDEALLOCATE(ProcNbrOfParticle)
    END IF
  ELSE
    chunksize = NbrOfParticle
  END IF
#else
  IF (DoExactPartNumInsert) chunksize = NbrOfParticle
#endif /*MPI*/
  !------------------SpaceIC-case: cell_local-------------------------------------------------------------------------------------
  IF ((chunksize.GT.0).OR.(Species(FractNbr)%Init(iInit)%PartDensity.GT.0.)) THEN
    CALL SetCellLocalParticlePosition(chunkSize,FractNbr,iInit,DoExactPartNumInsert)
  END IF
  NbrOfParticle = chunksize
  RETURN
END IF


PartIns=0.
lineVector = 0.0
A_ins = 0.0
l_ins = 0.0
lrel_ins_BV = 0.0
BV_lengths = 0.0
Particle_pos = 0.0
orificePeriodic = 0
orificePeriodicLog = .FALSE.
IF(Species(FractNbr)%Init(iInit)%VirtPreInsert) THEN ! (SpaceIC.EQ.'cuboid_vpi').OR.(SpaceIC.EQ.'cylinder_vpi')
  DimSend=6 !save (and send) velocities and positions
  ! the following is here, and not inside the select case, as it is needed to be excecuted just once and, most importantly, it
  ! calculates the virt. insertion height defining the virt. NbrOfParticle (which is chunked next) when PartDensity is used
  ! (-> could also be moved to particle_init?)
  lineVector(1) = Species(FractNbr)%Init(iInit)%BaseVector1IC(2) * Species(FractNbr)%Init(iInit)%BaseVector2IC(3) - &
    Species(FractNbr)%Init(iInit)%BaseVector1IC(3) * Species(FractNbr)%Init(iInit)%BaseVector2IC(2)
  lineVector(2) = Species(FractNbr)%Init(iInit)%BaseVector1IC(3) * Species(FractNbr)%Init(iInit)%BaseVector2IC(1) - &
    Species(FractNbr)%Init(iInit)%BaseVector1IC(1) * Species(FractNbr)%Init(iInit)%BaseVector2IC(3)
  lineVector(3) = Species(FractNbr)%Init(iInit)%BaseVector1IC(1) * Species(FractNbr)%Init(iInit)%BaseVector2IC(2) - &
    Species(FractNbr)%Init(iInit)%BaseVector1IC(2) * Species(FractNbr)%Init(iInit)%BaseVector2IC(1)
  IF ((lineVector(1).eq.0).AND.(lineVector(2).eq.0).AND.(lineVector(3).eq.0)) THEN
    CALL abort(&
__STAMP__&
,'BaseVectors are parallel!')
  ELSE
    A_ins = SQRT(lineVector(1) * lineVector(1) + lineVector(2) * lineVector(2) + lineVector(3) * lineVector(3))
    lineVector = lineVector / A_ins
  END IF
  v_drift_line = Species(FractNbr)%Init(iInit)%VeloIC * &
    ( Species(FractNbr)%Init(iInit)%VeloVecIC(1)*lineVector(1) + Species(FractNbr)%Init(iInit)%VeloVecIC(2)*lineVector(2) &
    + Species(FractNbr)%Init(iInit)%VeloVecIC(3)*lineVector(3) ) !lineVector component of drift-velocity
  l_ins=dt*RKdtFrac * ( v_drift_line + Species(FractNbr)%Init(iInit)%NSigma & !virt. insertion height
    * SQRT(BoltzmannConst*Species(FractNbr)%Init(iInit)%MWTemperatureIC/Species(FractNbr)%MassIC) )
  IF( (TRIM(Species(FractNbr)%Init(iInit)%vpiDomainType).EQ.'freestream') .OR. &
      (TRIM(Species(FractNbr)%Init(iInit)%vpiDomainType).EQ.'orifice') ) THEN
    BV_lengths(1) = SQRT(Species(FractNbr)%Init(iInit)%BaseVector1IC(1)**2 + &
                         Species(FractNbr)%Init(iInit)%BaseVector1IC(2)**2 + &
                         Species(FractNbr)%Init(iInit)%BaseVector1IC(3)**2)
    v_drift_BV(1) = Species(FractNbr)%Init(iInit)%VeloIC / BV_lengths(1) * &
      ( Species(FractNbr)%Init(iInit)%VeloVecIC(1)*Species(FractNbr)%Init(iInit)%BaseVector1IC(1) &
      + Species(FractNbr)%Init(iInit)%VeloVecIC(2)*Species(FractNbr)%Init(iInit)%BaseVector1IC(2) &
      + Species(FractNbr)%Init(iInit)%VeloVecIC(3)*Species(FractNbr)%Init(iInit)%BaseVector1IC(3) ) !BV1 component of drift-velocity
    BV_lengths(2) = SQRT(Species(FractNbr)%Init(iInit)%BaseVector2IC(1)**2 + &
                         Species(FractNbr)%Init(iInit)%BaseVector2IC(2)**2 + &
                         Species(FractNbr)%Init(iInit)%BaseVector2IC(3)**2)
    v_drift_BV(2) = Species(FractNbr)%Init(iInit)%VeloIC / BV_lengths(2) * &
      ( Species(FractNbr)%Init(iInit)%VeloVecIC(1)*Species(FractNbr)%Init(iInit)%BaseVector2IC(1) &
      + Species(FractNbr)%Init(iInit)%VeloVecIC(2)*Species(FractNbr)%Init(iInit)%BaseVector2IC(2) &
      + Species(FractNbr)%Init(iInit)%VeloVecIC(3)*Species(FractNbr)%Init(iInit)%BaseVector2IC(3) ) !BV2 component of drift-velocity
    IF ( .NOT.ALMOSTEQUAL(A_ins,BV_lengths(1)*BV_lengths(2)) ) THEN
      SWRITE(*,'(A72,2(x,I0),A1)') 'cross product and product of theirs lenghts for BaseVectors of Spec/Init',&
        FractNbr, iInit, ':'
      SWRITE(*,*) A_ins, BV_lengths(1)*BV_lengths(2)
      CALL abort(&
__STAMP__&
,' BaseVectors of the current SpaceIC are not parallel?')
    END IF
    IF ( .NOT.ALMOSTEQUAL(SQRT(v_drift_BV(1)**2+v_drift_BV(2)**2+v_drift_line**2),ABS(Species(FractNbr)%Init(iInit)%VeloIC)) ) THEN
      SWRITE(*,'(A60,2(x,I0),A1)') 'v_drift_BV1, v_drift_BV2, v_drift_line, VeloIC for Spec/Init',&
        FractNbr, iInit, ':'
      SWRITE(*,*) v_drift_BV(1),v_drift_BV(2),v_drift_line,Species(FractNbr)%Init(iInit)%VeloIC
      CALL abort(&
__STAMP__&
,' Something is wrong with the Basis of the current SpaceIC!')
    END IF
    IF ( TRIM(Species(FractNbr)%Init(iInit)%SpaceIC) .EQ. 'cuboid_vpi' ) THEN
      lrel_ins_BV=dt*RKdtFrac*( (/v_drift_BV(1),-v_drift_BV(1),v_drift_BV(2),-v_drift_BV(2)/)+Species(FractNbr)%Init(iInit)%NSigma &
        * SQRT(BoltzmannConst*Species(FractNbr)%Init(iInit)%MWTemperatureIC/Species(FractNbr)%MassIC) )!rel. virt. insertion height:
      lrel_ins_BV(1:2)=lrel_ins_BV(1:2)/BV_lengths(1)                                                        !... in -BV1/+BV1 dir.
      lrel_ins_BV(3:4)=lrel_ins_BV(3:4)/BV_lengths(2)                                                        !... in -BV2/+BV2 dir.
      DO i=1,4
        IF (.NOT.Species(FractNbr)%Init(iInit)%vpiBVBuffer(i)) lrel_ins_BV(i)=0.
      END DO
    ELSE IF ( TRIM(Species(FractNbr)%Init(iInit)%SpaceIC) .EQ. 'orifice' ) THEN !cylinder-orifice
      lrel_ins_BV(1:4)=dt*RKdtFrac * ( SQRT(v_drift_BV(1)**2+v_drift_BV(2)**2) + Species(FractNbr)%Init(iInit)%NSigma &
        * SQRT(BoltzmannConst*Species(FractNbr)%Init(iInit)%MWTemperatureIC/Species(FractNbr)%MassIC) ) &
        / Species(FractNbr)%Init(iInit)%RadiusIC !rel. virt. insertion height is a single, maximum value for whole circumference
    END IF
    IF( (TRIM(Species(FractNbr)%Init(iInit)%vpiDomainType).EQ.'orifice') .AND. &
        (TRIM(Species(FractNbr)%Init(iInit)%SpaceIC) .EQ. 'cuboid_vpi') ) THEN !needs further devel.!
      SELECT CASE (GEO%nPeriodicVectors)
      CASE (0)
      CASE (1)
        ParaCheck(1) = Species(FractNbr)%Init(iInit)%BaseVector1IC(2) * GEO%PeriodicVectors(3,1) - &
          Species(FractNbr)%Init(iInit)%BaseVector1IC(3) * GEO%PeriodicVectors(2,1)
        ParaCheck(2) = Species(FractNbr)%Init(iInit)%BaseVector1IC(3) * GEO%PeriodicVectors(1,1) - &
          Species(FractNbr)%Init(iInit)%BaseVector1IC(1) * GEO%PeriodicVectors(3,1)
        ParaCheck(3) = Species(FractNbr)%Init(iInit)%BaseVector1IC(1) * GEO%PeriodicVectors(2,1) - &
          Species(FractNbr)%Init(iInit)%BaseVector1IC(2) * GEO%PeriodicVectors(1,1)
        IF ( .NOT.(SQRT(ParaCheck(1)**2+ParaCheck(2)**2+ParaCheck(3)**2).GT.TwoepsMach) ) orificePeriodic=1 !parallel with BV1
        IF (orificePeriodic .EQ. 0) THEN
          ParaCheck(1) = Species(FractNbr)%Init(iInit)%BaseVector2IC(2) * GEO%PeriodicVectors(3,1) - &
            Species(FractNbr)%Init(iInit)%BaseVector2IC(3) * GEO%PeriodicVectors(2,1)
          ParaCheck(2) = Species(FractNbr)%Init(iInit)%BaseVector2IC(3) * GEO%PeriodicVectors(1,1) - &
            Species(FractNbr)%Init(iInit)%BaseVector2IC(1) * GEO%PeriodicVectors(3,1)
          ParaCheck(3) = Species(FractNbr)%Init(iInit)%BaseVector2IC(1) * GEO%PeriodicVectors(2,1) - &
            Species(FractNbr)%Init(iInit)%BaseVector2IC(2) * GEO%PeriodicVectors(1,1)
          IF ( .NOT.(SQRT(ParaCheck(1)**2+ParaCheck(2)**2+ParaCheck(3)**2).GT.TwoepsMach) ) THEN
            orificePeriodic=2 !parallel with BV2
          ELSE
            CALL abort(&
__STAMP__&
,' PeriodicVector is not parallel to any orifice BV -> not implemented yet!')
          END IF
        ELSE IF (orificePeriodic .EQ. 1) THEN
          !PerVec cannot be parallel with BV2, as BV1 already is
        ELSE
          CALL abort(&
__STAMP__&
,' Something is wrong with the PeriodicVector and the orifice BV!')
        END IF
        lPeri=SQRT(GEO%PeriodicVectors(1,1)**2+GEO%PeriodicVectors(2,1)**2+GEO%PeriodicVectors(3,1)**2)
        IF ( .NOT.ALMOSTEQUAL(lPeri,BV_lengths(orificePeriodic)) ) THEN
          SWRITE(*,'(A22,I1,x,A1)') 'lPeri and length of BV',orificePeriodic,':'
          SWRITE(*,'(G0,x,G0)') lPeri,BV_lengths(orificePeriodic)
          CALL abort(&
__STAMP__&
,' PeriodicVector and its parallel BV ar not of same length! ')
        END IF
        orificePeriodicLog(1)=(orificePeriodic.EQ.1)
        orificePeriodicLog(2)=(orificePeriodic.EQ.2)
      CASE DEFAULT
        CALL abort(&
__STAMP__&
,' orifice region only implemented for 0 or 1 PeriodicVector!')
      END SELECT
    END IF !cuboid-orifice
  END IF !freestream or orifice
  !--calculation of (virtual) NbrOfParticle from virt. insertion height
  IF(Species(FractNbr)%Init(iInit)%PartDensity .GT. 0.) THEN
    SELECT CASE(TRIM(Species(FractNbr)%Init(iInit)%SpaceIC))
    CASE ('cylinder_vpi')
      IF( TRIM(Species(FractNbr)%Init(iInit)%vpiDomainType) .EQ. 'orifice' ) THEN
        A_ins = PI * ( Species(FractNbr)%Init(iInit)%RadiusIC*(1.+lrel_ins_BV(1)) )**2
      ELSE
        A_ins = PI * ( Species(FractNbr)%Init(iInit)%RadiusIC**2 - Species(FractNbr)%Init(iInit)%Radius2IC**2 )
      END IF
    CASE ('cuboid_vpi')
      IF( (TRIM(Species(FractNbr)%Init(iInit)%vpiDomainType).EQ.'freestream') .OR. &
          (TRIM(Species(FractNbr)%Init(iInit)%vpiDomainType).EQ.'orifice') ) THEN
        A_ins = BV_lengths(1)*(lrel_ins_BV(1)+1.0+lrel_ins_BV(2)) * BV_lengths(2)*(lrel_ins_BV(3)+1.0+lrel_ins_BV(4))
      END IF
    CASE DEFAULT
      CALL abort(&
__STAMP__&
,'wrong SpaceIC for virtual Pre-Inserting region!')
    END SELECT
    PartIns = Species(FractNbr)%Init(iInit)%PartDensity * l_ins * A_ins / (Species(FractNbr)%MacroParticleFactor)
    IF(PartIns.GT.0.) THEN
      NbrOfParticle = INT(PartIns)
    ELSE
      NbrOfParticle = 0
    END IF
  END IF
ELSE
  DimSend=3 !save (and send) only positions
END IF

IF ( (NbrOfParticle .LE. 0).AND.(PartIns .LE. 0.).AND. (ABS(Species(FractNbr)%Init(iInit)%PartDensity).LE.0.) ) &
  RETURN !0<Partins<1: statistical handling of exact REAL-INT-conv. below!

nChunks = 1                   ! Standard: Nicht-MPI
sumOfMatchedParticles = 0
mySumOfMatchedParticles = 0

chunkSize = nbrOfParticle

! process myRank=0 generates the complete list of random positions for all emitted particles
#ifdef MPI
IF(( (nbrOfParticle.GT.PartMPI%InitGroup(InitGroup)%nProcs*10                             ) .AND.  &
     (TRIM(Species(FractNbr)%Init(iInit)%SpaceIC).NE.'circle_equidistant'                 ) .AND.  &
     (TRIM(Species(FractNbr)%Init(iInit)%SpaceIC).NE.'sin_deviation'                      ) .AND.  &
     (TRIM(Species(FractNbr)%Init(iInit)%SpaceIC).NE.'cuboid_with_equidistant_distribution').AND.  &
     (TRIM(Species(FractNbr)%Init(iInit)%SpaceIC).NE.'line_with_equidistant_distribution' )).OR.   &
     (TRIM(Species(FractNbr)%Init(iInit)%SpaceIC).EQ.'LD_insert'                          ) )THEN
   nChunks = PartMPI%InitGroup(InitGroup)%nProcs
ELSE
   nChunks = 1
END IF

! communication
IF(TRIM(Species(FractNbr)%Init(iInit)%SpaceIC).EQ.'circle') nChunks=1

IF (mode.EQ.1) THEN
  chunkSize = INT(nbrOfParticle/nChunks)
  IF (PartMPI%InitGroup(InitGroup)%MPIROOT) THEN
    IF( Species(FractNbr)%Init(iInit)%VirtPreInsert .AND. (Species(FractNbr)%Init(iInit)%PartDensity .GT. 0.) ) THEN
      ! statistical handling of exact REAL-INT-conversion -> values in send(1)- and receive(2)-mode might differ for VPI+PartDens
      ! (NbrOf Particle can differ from root to other procs and, thus, need to be communicated of calculated later again)
      CALL RANDOM_NUMBER(RandVal1)
      IF (.NOT.DoPoissonRounding .AND. .NOT.DoTimeDepInflow) THEN
        NbrOfParticle = INT(PartIns + RandVal1)
      ELSE IF (EXP(-PartIns).LE.TINY(PartIns) .AND.DoPoissonRounding) THEN
        IPWRITE(*,*)'WARNING: target is too large for poisson sampling: switching now to Random rounding...'
        NbrOfParticle = INT(PartIns + RandVal1)
        DoPoissonRounding = .FALSE.
      ELSE IF (DoPoissonRounding) THEN 
        !poisson-sampling instead of random rounding (reduces numerical non-equlibrium effects [Tysanner and Garcia 2004]
        CALL SamplePoissonDistri( PartIns , NbrOfParticle , DoPoissonRounding)
      ELSE ! DoTimeDepInflow
        NbrOfParticle = INT(PartIns + RandVal1)
      END IF
    END IF
    chunkSize = chunkSize + ( nbrOfParticle - (nChunks*chunkSize) )
  END IF
  IF (PartMPI%InitGroup(InitGroup)%MPIROOT .OR. nChunks.GT.1) THEN
#endif
    ALLOCATE( particle_positions(1:chunkSize*DimSend), STAT=allocStat )
    IF (allocStat .NE. 0) THEN
      CALL abort(&
__STAMP__&
,'ERROR in SetParticlePosition: cannot allocate particle_positions!')
    END IF

    chunkSize2=chunkSize !will be changed during insertion for:
                         !  1.: vpi with PartDensity (orig. chunksize is for buffer region)
                         !  2.: excludeRegions (orig. chunksize is for SpaceIC without taking excludeRegions into account)
    !------------------SpaceIC-cases: start-----------------------------------------------------------!
    SELECT CASE(TRIM(Species(FractNbr)%Init(iInit)%SpaceIC))
    !------------------SpaceIC-case: point------------------------------------------------------------------------------------------
    CASE ('point')
       Particle_pos = Species(FractNbr)%Init(iInit)%BasePointIC
       DO i=1,chunkSize
          particle_positions(i*3-2) = Particle_pos(1)
          particle_positions(i*3-1) = Particle_pos(2)
          particle_positions(i*3  ) = Particle_pos(3)
       END DO
    !------------------SpaceIC-case: line_with_equidistant_distribution-------------------------------------------------------------
    CASE ('line_with_equidistant_distribution')
      IF(NbrOfParticle.EQ.1)THEN
         Particle_pos = Species(FractNbr)%Init(iInit)%BasePointIC + 0.5 * Species(FractNbr)%Init(iInit)%BaseVector1IC
      ELSE
        VectorGap = Species(FractNbr)%Init(iInit)%BaseVector1IC/(NbrOfParticle-1)
        DO i=1,chunkSize
          Particle_pos = Species(FractNbr)%Init(iInit)%BasePointIC + (i-1)*VectorGap
          particle_positions(i*3-2) = Particle_pos(1)
          particle_positions(i*3-1) = Particle_pos(2)
          particle_positions(i*3  ) = Particle_pos(3)
        END DO
      END IF
    !------------------SpaceIC-case: line-------------------------------------------------------------------------------------------
    CASE ('line')
      DO i=1,chunkSize
        CALL RANDOM_NUMBER(RandVal1)
        Particle_pos = Species(FractNbr)%Init(iInit)%BasePointIC + Species(FractNbr)%Init(iInit)%BaseVector1IC*RandVal1
        particle_positions(i*3-2) = Particle_pos(1)
        particle_positions(i*3-1) = Particle_pos(2)
        particle_positions(i*3  ) = Particle_pos(3)
      END DO
    !------------------SpaceIC-case: disc-------------------------------------------------------------------------------------------
    CASE('disc')
      IF (Species(FractNbr)%Init(iInit)%NormalIC(3).NE.0) THEN
        lineVector(1) = 1.0
        lineVector(2) = 1.0
        lineVector(3) = -(Species(FractNbr)%Init(iInit)%NormalIC(1)+Species(FractNbr)%Init(iInit)%NormalIC(2))/ &
                         Species(FractNbr)%Init(iInit)%NormalIC(3)
      ELSE
        IF (Species(FractNbr)%Init(iInit)%NormalIC(2).NE.0) THEN
          lineVector(1) = 1.0
          lineVector(3) = 1.0
          lineVector(2) = -(Species(FractNbr)%Init(iInit)%NormalIC(1)+Species(FractNbr)%Init(iInit)%NormalIC(3))/ &
                            Species(FractNbr)%Init(iInit)%NormalIC(2)
        ELSE
          IF (Species(FractNbr)%Init(iInit)%NormalIC(1).NE.0) THEN
            lineVector(2) = 1.0
            lineVector(3) = 1.0
            lineVector(1) = -(Species(FractNbr)%Init(iInit)%NormalIC(2)+Species(FractNbr)%Init(iInit)%NormalIC(3))/ &
                 Species(FractNbr)%Init(iInit)%NormalIC(1)
          ELSE
            CALL abort(&
__STAMP__&
,'Error in SetParticlePosition, NormalIC Vektor darf nicht Nullvektor sein')
          END IF
        END IF
      END IF
      
      lineVector = lineVector / SQRT(lineVector(1) * lineVector(1) + lineVector(2) * &
           lineVector(2) + lineVector(3) * lineVector(3))
      
      lineVector2(1) = Species(FractNbr)%Init(iInit)%NormalIC(2) * lineVector(3) - &
           Species(FractNbr)%Init(iInit)%NormalIC(3) * lineVector(2)
      lineVector2(2) = Species(FractNbr)%Init(iInit)%NormalIC(3) * lineVector(1) - &
           Species(FractNbr)%Init(iInit)%NormalIC(1) * lineVector(3)
      lineVector2(3) = Species(FractNbr)%Init(iInit)%NormalIC(1) * lineVector(2) - &
           Species(FractNbr)%Init(iInit)%NormalIC(2) * lineVector(1)
      
      lineVector2 = lineVector2 / SQRT(lineVector2(1) * lineVector2(1) + lineVector2(2) * &
           lineVector2(2) + lineVector2(3) * lineVector2(3))

      DO i=1,chunkSize
         radius = Species(FractNbr)%Init(iInit)%RadiusIC + 1
         DO WHILE(radius.GT.Species(FractNbr)%Init(iInit)%RadiusIC)
            CALL RANDOM_NUMBER(RandVal)
            RandVal = RandVal * 2. - 1.
            Particle_pos = Species(FractNbr)%Init(iInit)%BasePointIC + Species(FractNbr)%Init(iInit)%RadiusIC * &
                     (RandVal(1) * lineVector + RandVal(2) *lineVector2)

            radius = SQRT( (Particle_pos(1)-Species(FractNbr)%Init(iInit)%BasePointIC(1)) * &
                           (Particle_pos(1)-Species(FractNbr)%Init(iInit)%BasePointIC(1)) + &
                           (Particle_pos(2)-Species(FractNbr)%Init(iInit)%BasePointIC(2)) * &
                           (Particle_pos(2)-Species(FractNbr)%Init(iInit)%BasePointIC(2)) + &
                           (Particle_pos(3)-Species(FractNbr)%Init(iInit)%BasePointIC(3)) * &
                           (Particle_pos(3)-Species(FractNbr)%Init(iInit)%BasePointIC(3)) )
         END DO
         particle_positions(i*3-2) = Particle_pos(1)
         particle_positions(i*3-1) = Particle_pos(2)
         particle_positions(i*3  ) = Particle_pos(3)
      END DO
    CASE('circle')
      IF (Species(FractNbr)%Init(iInit)%NormalIC(3).NE.0) THEN
         lineVector(1) = 1.0
         lineVector(2) = 1.0
         lineVector(3) = -(Species(FractNbr)%Init(iInit)%NormalIC(1)+Species(FractNbr)%Init(iInit)%NormalIC(2))/ &
                           Species(FractNbr)%Init(iInit)%NormalIC(3)
      ELSE
         IF (Species(FractNbr)%Init(iInit)%NormalIC(2).NE.0) THEN
            lineVector(1) = 1.0
            lineVector(3) = 1.0
            lineVector(2) = -(Species(FractNbr)%Init(iInit)%NormalIC(1)+Species(FractNbr)%Init(iInit)%NormalIC(3))/ &
                              Species(FractNbr)%Init(iInit)%NormalIC(2)
         ELSE
            IF (Species(FractNbr)%Init(iInit)%NormalIC(1).NE.0) THEN
               lineVector(2) = 1.0
               lineVector(3) = 1.0
               lineVector(1) = -(Species(FractNbr)%Init(iInit)%NormalIC(2)+Species(FractNbr)%Init(iInit)%NormalIC(3))/ &
                                 Species(FractNbr)%Init(iInit)%NormalIC(1)
            ELSE
              CALL abort(&
__STAMP__&
,'Error in SetParticlePosition, NormalIC should not be zero')
            END IF
         END IF
      END IF
      
      lineVector = lineVector / SQRT(lineVector(1) * lineVector(1) + lineVector(2) * &
           lineVector(2) + lineVector(3) * lineVector(3))
      
      lineVector2(1) = Species(FractNbr)%Init(iInit)%NormalIC(2) * lineVector(3) - &
           Species(FractNbr)%Init(iInit)%NormalIC(3) * lineVector(2)
      lineVector2(2) = Species(FractNbr)%Init(iInit)%NormalIC(3) * lineVector(1) - &
           Species(FractNbr)%Init(iInit)%NormalIC(1) * lineVector(3)
      lineVector2(3) = Species(FractNbr)%Init(iInit)%NormalIC(1) * lineVector(2) - &
           Species(FractNbr)%Init(iInit)%NormalIC(2) * lineVector(1)
      
      lineVector2 = lineVector2 / SQRT(lineVector2(1) * lineVector2(1) + lineVector2(2) * &
           lineVector2(2) + lineVector2(3) * lineVector2(3))

      radius = Species(FractNbr)%Init(iInit)%RadiusIC
      DO i=1,chunkSize
         CALL RANDOM_NUMBER(RandVal1)
         argumentTheta = 2.*pi*RandVal1
         Particle_pos = Species(FractNbr)%Init(iInit)%BasePointIC +        &
                        linevector * cos(argumentTheta) * radius +  &
                        linevector2 * sin(argumentTheta) * radius
         particle_positions(i*3-2) = Particle_pos(1)
         particle_positions(i*3-1) = Particle_pos(2)
         particle_positions(i*3  ) = Particle_pos(3)
      END DO
    !------------------SpaceIC-case: gyrotron_circle--------------------------------------------------------------------------------
    CASE('gyrotron_circle')
      IF (Species(FractNbr)%Init(iInit)%NormalIC(3).NE.0) THEN
         lineVector(1) = 1.0
         lineVector(2) = 1.0
         lineVector(3) = -(Species(FractNbr)%Init(iInit)%NormalIC(1)+Species(FractNbr)%Init(iInit)%NormalIC(2))/ &
                           Species(FractNbr)%Init(iInit)%NormalIC(3)
      ELSE
         IF (Species(FractNbr)%Init(iInit)%NormalIC(2).NE.0) THEN
            lineVector(1) = 1.0
            lineVector(3) = 1.0
            lineVector(2) = -(Species(FractNbr)%Init(iInit)%NormalIC(1)+Species(FractNbr)%Init(iInit)%NormalIC(3))/ &
                              Species(FractNbr)%Init(iInit)%NormalIC(2)
         ELSE
            IF (Species(FractNbr)%Init(iInit)%NormalIC(1).NE.0) THEN
               lineVector(2) = 1.0
               lineVector(3) = 1.0
               lineVector(1) = -(Species(FractNbr)%Init(iInit)%NormalIC(2)+Species(FractNbr)%Init(iInit)%NormalIC(3))/ &
                                 Species(FractNbr)%Init(iInit)%NormalIC(1)
            ELSE
              CALL abort(&
__STAMP__&
,'Error in SetParticlePosition, NormalIC should not be zero')
            END IF
         END IF
      END IF
      
      lineVector = lineVector / SQRT(lineVector(1) * lineVector(1) + lineVector(2) * &
           lineVector(2) + lineVector(3) * lineVector(3))
      
      lineVector2(1) = Species(FractNbr)%Init(iInit)%NormalIC(2) * lineVector(3) - &
           Species(FractNbr)%Init(iInit)%NormalIC(3) * lineVector(2)
      lineVector2(2) = Species(FractNbr)%Init(iInit)%NormalIC(3) * lineVector(1) - &
           Species(FractNbr)%Init(iInit)%NormalIC(1) * lineVector(3)
      lineVector2(3) = Species(FractNbr)%Init(iInit)%NormalIC(1) * lineVector(2) - &
           Species(FractNbr)%Init(iInit)%NormalIC(2) * lineVector(1)
      
      lineVector2 = lineVector2 / SQRT(lineVector2(1) * lineVector2(1) + lineVector2(2) * &
           lineVector2(2) + lineVector2(3) * lineVector2(3))

      radius = Species(FractNbr)%Init(iInit)%RadiusIC
      DO i=1,chunkSize
         CALL RANDOM_NUMBER(RandVal1)
         argumentTheta = 2.*pi*RandVal1
         Particle_pos = Species(FractNbr)%Init(iInit)%BasePointIC +        &
                        linevector * cos(argumentTheta) * radius +  &
                        linevector2 * sin(argumentTheta) * radius
         ! Change position of particle on the small gyro circle
         ! take normal vecotr of the circle
         n(1:3) = Species(FractNbr)%Init(iInit)%NormalIC(1:3)
         ! generate radius vector (later it will be multiplied by the length of the
         ! gyro circles. For now we just need the vector)
         radius_vec(1) = Particle_pos(1) - Species(FractNbr)%Init(iInit)%BasePointIC(1)
         radius_vec(2) = Particle_pos(2) - Species(FractNbr)%Init(iInit)%BasePointIC(2)
         radius_vec(3) = Particle_pos(3) - Species(FractNbr)%Init(iInit)%BasePointIC(3)
         !rotate radius vector with random angle
         CALL RANDOM_NUMBER(RandVal1)
         argumentTheta=2.*pi*RandVal1
         JJ(1,1:3) = (/   0.,-n(3), n(2)/)
         JJ(2,1:3) = (/ n(3),   0.,-n(1)/)
         JJ(3,1:3) = (/-n(2), n(1),   0./)
         II(1,1:3) = (/1.,0.,0./)
         II(2,1:3) = (/0.,1.,0./)
         II(3,1:3) = (/0.,0.,1./)
         forall(j=1:3) NN(:,j) = n(:)*n(j)

!        1. determine the z-position in order to get the interpolated curved B-field
         CALL RANDOM_NUMBER(RandVal1)
         IF (NbrOfParticle.EQ.Species(FractNbr)%Init(iInit)%initialParticleNumber) THEN
           particle_positions(i*3  ) = Species(FractNbr)%Init(iInit)%BasePointIC(3) &
                                           + RandVal1 * Species(FractNbr)%Init(iInit)%CuboidHeightIC
         ELSE
           particle_positions(i*3  ) = Species(FractNbr)%Init(iInit)%BasePointIC(3) &
                                           + RandVal1 * dt*RKdtFrac & 
                                           * Species(FractNbr)%Init(iInit)%VeloIC/Species(FractNbr)%Init(iInit)%alpha 
         END IF

!        2. calculate curved B-field at z-position in order to determine size of gyro radius
         IF (useVariableExternalField) THEN
            IF(particle_positions(i*3).LT.VariableExternalField(1,1))THEN ! assume particles travel in positive z-direction
              CALL abort(&
__STAMP__&
,'SetParticlePosition: particle_positions(i*3) cannot be smaller than VariableExternalField(1,1). Fix *.csv data or emission!')
            END IF
            Bintpol = InterpolateVariableExternalField(particle_positions(i*3))
            rgyrate = 1./ SQRT ( 1 - (Species(FractNbr)%Init(iInit)%VeloIC**2 * (1 + 1./Species(FractNbr)%Init(iInit)%alpha**2)) &
                                * c_inv * c_inv ) * Species(FractNbr)%MassIC * Species(FractNbr)%Init(iInit)%VeloIC / &
                      ( Bintpol * abs( Species(FractNbr)%ChargeIC) )
         ELSE
           rgyrate =  Species(FractNbr)%Init(iInit)%RadiusICGyro
         END IF

         radius_vec = MATMUL( NN+cos(argumentTheta)*(II-NN)+sin(argumentTheta)*JJ , radius_vec ) 
         radius_vec(1:3) = radius_vec(1:3) / SQRT(radius_vec(1)**2+radius_vec(2)**2+radius_vec(3)**2) &
                       * rgyrate !Species(1)%RadiusICGyro
         ! Set new particles position:
         particle_positions(i*3-2) = Particle_pos(1) + radius_vec(1)
         particle_positions(i*3-1) = Particle_pos(2) + radius_vec(2)
         !particle_positions(i*3  )=0.
      END DO
    !------------------SpaceIC-case: circle_equidistant-----------------------------------------------------------------------------
    CASE('circle_equidistant')
      IF (Species(FractNbr)%Init(iInit)%NormalIC(3).NE.0) THEN
         lineVector(1) = 1.0
         lineVector(2) = 1.0
         lineVector(3) = -(Species(FractNbr)%Init(iInit)%NormalIC(1)+Species(FractNbr)%Init(iInit)%NormalIC(2))/ &
                           Species(FractNbr)%Init(iInit)%NormalIC(3)
      ELSE
         IF (Species(FractNbr)%Init(iInit)%NormalIC(2).NE.0) THEN
            lineVector(1) = 1.0
            lineVector(3) = 1.0
            lineVector(2) = -(Species(FractNbr)%Init(iInit)%NormalIC(1)+Species(FractNbr)%Init(iInit)%NormalIC(3))/ &
                              Species(FractNbr)%Init(iInit)%NormalIC(2)
         ELSE
            IF (Species(FractNbr)%Init(iInit)%NormalIC(1).NE.0) THEN
               lineVector(2) = 1.0
               lineVector(3) = 1.0
               lineVector(1) = -(Species(FractNbr)%Init(iInit)%NormalIC(2)+Species(FractNbr)%Init(iInit)%NormalIC(3))/ &
                                 Species(FractNbr)%Init(iInit)%NormalIC(1)
            ELSE
              CALL abort(&
__STAMP__&
,'Error in SetParticlePosition, NormalIC should not be zero')
            END IF
         END IF
      END IF
                 
      lineVector2(1) = Species(FractNbr)%Init(iInit)%NormalIC(2) * lineVector(3) - &
           Species(FractNbr)%Init(iInit)%NormalIC(3) * lineVector(2)
      lineVector2(2) = Species(FractNbr)%Init(iInit)%NormalIC(3) * lineVector(1) - &
           Species(FractNbr)%Init(iInit)%NormalIC(1) * lineVector(3)
      lineVector2(3) = Species(FractNbr)%Init(iInit)%NormalIC(1) * lineVector(2) - &
           Species(FractNbr)%Init(iInit)%NormalIC(2) * lineVector(1)

      lineVector = lineVector / SQRT(lineVector(1) * lineVector(1) + lineVector(2) * &
           lineVector(2) + lineVector(3) * lineVector(3))

      lineVector2 = lineVector2 / SQRT(lineVector2(1) * lineVector2(1) + lineVector2(2) * &
           lineVector2(2) + lineVector2(3) * lineVector2(3))

      radius = Species(FractNbr)%Init(iInit)%RadiusIC
      DO i=1,chunkSize
         argumentTheta = 2.*pi*i/chunkSize
         Particle_pos = Species(FractNbr)%Init(iInit)%BasePointIC +        &
                        linevector * cos(argumentTheta) * radius +  &
                        linevector2 * sin(argumentTheta) * radius
         particle_positions(i*3-2) = Particle_pos(1)
         particle_positions(i*3-1) = Particle_pos(2)
         particle_positions(i*3  ) = Particle_pos(3)
      END DO
    !------------------SpaceIC-case: cuboid-----------------------------------------------------------------------------------------
    CASE('cuboid')
      lineVector(1) = Species(FractNbr)%Init(iInit)%BaseVector1IC(2) * Species(FractNbr)%Init(iInit)%BaseVector2IC(3) - &
        Species(FractNbr)%Init(iInit)%BaseVector1IC(3) * Species(FractNbr)%Init(iInit)%BaseVector2IC(2)
      lineVector(2) = Species(FractNbr)%Init(iInit)%BaseVector1IC(3) * Species(FractNbr)%Init(iInit)%BaseVector2IC(1) - &
        Species(FractNbr)%Init(iInit)%BaseVector1IC(1) * Species(FractNbr)%Init(iInit)%BaseVector2IC(3)
      lineVector(3) = Species(FractNbr)%Init(iInit)%BaseVector1IC(1) * Species(FractNbr)%Init(iInit)%BaseVector2IC(2) - &
        Species(FractNbr)%Init(iInit)%BaseVector1IC(2) * Species(FractNbr)%Init(iInit)%BaseVector2IC(1)
      IF ((lineVector(1).eq.0).AND.(lineVector(2).eq.0).AND.(lineVector(3).eq.0)) THEN
        CALL abort(&
__STAMP__&
,'BaseVectors are parallel!')
      ELSE
        lineVector = lineVector / SQRT(lineVector(1) * lineVector(1) + lineVector(2) * lineVector(2) + &
          lineVector(3) * lineVector(3))
      END IF
      i=1
      chunkSize2=0
      DO WHILE (i .LE. chunkSize)
         CALL RANDOM_NUMBER(RandVal)
         Particle_pos = Species(FractNbr)%Init(iInit)%BasePointIC + Species(FractNbr)%Init(iInit)%BaseVector1IC * RandVal(1)
         Particle_pos = Particle_pos + Species(FractNbr)%Init(iInit)%BaseVector2IC * RandVal(2)
         IF (Species(FractNbr)%Init(iInit)%CalcHeightFromDt) THEN !directly calculated by timestep
           Particle_pos = Particle_pos + lineVector * Species(FractNbr)%Init(iInit)%VeloIC * dt*RKdtFrac * RandVal(3)
         ELSE
#if (PP_TimeDiscMethod==201)
!           !scaling due to variable time step (for inlet-condition, but already fixed when %CalcHeightFromDt is used!!!)
!           IF (iter.GT.0) THEN
!             Particle_pos = Particle_pos + lineVector * Species(FractNbr)%Init(iInit)%CuboidHeightIC * dt / dt_maxwell * RandVal(3)
!           ELSE
             Particle_pos = Particle_pos + lineVector * Species(FractNbr)%Init(iInit)%CuboidHeightIC * RandVal(3) 
!           END IF
#else
           Particle_pos = Particle_pos + lineVector * Species(FractNbr)%Init(iInit)%CuboidHeightIC * RandVal(3) 
#endif
         END IF
         IF (Species(FractNbr)%Init(iInit)%NumberOfExcludeRegions.GT.0) THEN
           CALL InsideExcludeRegionCheck(FractNbr, iInit, Particle_pos, insideExcludeRegion)
           IF (insideExcludeRegion) THEN
             i=i+1
             CYCLE !particle is in excluded region
           END IF
         END IF
         particle_positions((chunkSize2+1)*3-2) = Particle_pos(1)
         particle_positions((chunkSize2+1)*3-1) = Particle_pos(2)
         particle_positions((chunkSize2+1)*3  ) = Particle_pos(3)
         i=i+1
         chunkSize2=chunkSize2+1
      END DO
    !------------------SpaceIC-case: cylinder---------------------------------------------------------------------------------------
    CASE('cylinder')
      lineVector(1) = Species(FractNbr)%Init(iInit)%BaseVector1IC(2) * Species(FractNbr)%Init(iInit)%BaseVector2IC(3) - &
        Species(FractNbr)%Init(iInit)%BaseVector1IC(3) * Species(FractNbr)%Init(iInit)%BaseVector2IC(2)
      lineVector(2) = Species(FractNbr)%Init(iInit)%BaseVector1IC(3) * Species(FractNbr)%Init(iInit)%BaseVector2IC(1) - &
        Species(FractNbr)%Init(iInit)%BaseVector1IC(1) * Species(FractNbr)%Init(iInit)%BaseVector2IC(3)
      lineVector(3) = Species(FractNbr)%Init(iInit)%BaseVector1IC(1) * Species(FractNbr)%Init(iInit)%BaseVector2IC(2) - &
        Species(FractNbr)%Init(iInit)%BaseVector1IC(2) * Species(FractNbr)%Init(iInit)%BaseVector2IC(1)
      IF ((lineVector(1).eq.0).AND.(lineVector(2).eq.0).AND.(lineVector(3).eq.0)) THEN
        CALL abort(&
__STAMP__&
,'BaseVectors are parallel!')
      ELSE
        lineVector = lineVector / SQRT(lineVector(1) * lineVector(1) + lineVector(2) * lineVector(2) + &
          lineVector(3) * lineVector(3))
      END IF
      i=1
      chunkSize2=0
      DO WHILE (i .LE. chunkSize)
         radius = Species(FractNbr)%Init(iInit)%RadiusIC + 1.
         DO WHILE((radius.GT.Species(FractNbr)%Init(iInit)%RadiusIC) .OR.(radius.LT.Species(FractNbr)%Init(iInit)%Radius2IC))
            CALL RANDOM_NUMBER(RandVal)
            Particle_pos = Species(FractNbr)%Init(iInit)%BaseVector1IC * (RandVal(1)*2-1) &
                         + Species(FractNbr)%Init(iInit)%BaseVector2IC * (RandVal(2)*2-1)
            radius = SQRT( Particle_pos(1) * Particle_pos(1) + &
                           Particle_pos(2) * Particle_pos(2) + &
                           Particle_pos(3) * Particle_pos(3) )
         END DO
         Particle_pos = Particle_pos + Species(FractNbr)%Init(iInit)%BasePointIC
         IF (Species(FractNbr)%Init(iInit)%CalcHeightFromDt) THEN !directly calculated by timestep
           Particle_pos = Particle_pos + lineVector * Species(FractNbr)%Init(iInit)%VeloIC * dt*RKdtFrac * RandVal(3)
         ELSE
#if (PP_TimeDiscMethod==201)
!           !scaling due to variable time step (for inlet-condition, but already fixed when %CalcHeightFromDt is used!!!)
!           IF (iter.GT.0) THEN
!             Particle_pos = Particle_pos + lineVector * Species(FractNbr)%Init(iInit)%CylinderHeightIC * dt/dt_maxwell * RandVal(3)
!           ELSE
             Particle_pos = Particle_pos + lineVector * Species(FractNbr)%Init(iInit)%CylinderHeightIC * RandVal(3)
!           END IF          
#else
           Particle_pos = Particle_pos + lineVector * Species(FractNbr)%Init(iInit)%CylinderHeightIC * RandVal(3)
#endif
         END IF
         IF (Species(FractNbr)%Init(iInit)%NumberOfExcludeRegions.GT.0) THEN
           CALL InsideExcludeRegionCheck(FractNbr, iInit, Particle_pos, insideExcludeRegion)
           IF (insideExcludeRegion) THEN
             i=i+1
             CYCLE !particle is in excluded region
           END IF
         END IF
         particle_positions((chunkSize2+1)*3-2) = Particle_pos(1)
         particle_positions((chunkSize2+1)*3-1) = Particle_pos(2)
         particle_positions((chunkSize2+1)*3  ) = Particle_pos(3)
         i=i+1
         chunkSize2=chunkSize2+1
      END DO
    !------------------SpaceIC-case: cuboid_vpi-------------------------------------------------------------------------------------
    CASE('cuboid_vpi')
      i=1
      chunkSize2=0
      DO WHILE (i .LE. chunkSize)          
        ! Check if particle would reach comp. domain in one timestep
        CALL CalcVelocity_maxwell_lpn(FractNbr, Vec3D, iInit=iInit)
        CALL RANDOM_NUMBER(RandVal)
        v_line = Vec3D(1)*lineVector(1) + Vec3D(2)*lineVector(2) + Vec3D(3)*lineVector(3) !lineVector component of velocity
        delta_l = dt*RKdtFrac * v_line - l_ins * RandVal(3)
        IF (delta_l .LT. 0.) THEN
          IF (Species(FractNbr)%Init(iInit)%PartDensity .GT. 0.) i=i+1
          CYCLE !particle would not reach comp. domain -> try new velo
        END IF
        SELECT CASE(TRIM(Species(FractNbr)%Init(iInit)%vpiDomainType)) 
        CASE('perpendicular_extrusion')
          ! set particle positions depending on SpaceIC
          Particle_pos = Species(FractNbr)%Init(iInit)%BasePointIC + Species(FractNbr)%Init(iInit)%BaseVector1IC * RandVal(1) &
                                                                   + Species(FractNbr)%Init(iInit)%BaseVector2IC * RandVal(2) &
                                                                   + lineVector * delta_l
        CASE('freestream')
          v_BV(1) = Vec3D(1)*Species(FractNbr)%Init(iInit)%BaseVector1IC(1) &
                  + Vec3D(2)*Species(FractNbr)%Init(iInit)%BaseVector1IC(2) &
                  + Vec3D(3)*Species(FractNbr)%Init(iInit)%BaseVector1IC(3)
          v_BV(1) = v_BV(1) / BV_lengths(1) !BV1 component of velocity
          v_BV(2) = Vec3D(1)*Species(FractNbr)%Init(iInit)%BaseVector2IC(1) &
                  + Vec3D(2)*Species(FractNbr)%Init(iInit)%BaseVector2IC(2) &
                  + Vec3D(3)*Species(FractNbr)%Init(iInit)%BaseVector2IC(3)
          v_BV(2) = v_BV(2) / BV_lengths(2) !BV2 component of velocity
          delta_lBV = dt*RKdtFrac * v_BV
          delta_lBV(1) = delta_lBV(1) + BV_lengths(1) * ( RandVal(1)*(lrel_ins_BV(1)+1.0+lrel_ins_BV(2)) - lrel_ins_BV(1) )
          delta_lBV(2) = delta_lBV(2) + BV_lengths(2) * ( RandVal(2)*(lrel_ins_BV(3)+1.0+lrel_ins_BV(4)) - lrel_ins_BV(3) )
          IF ( (delta_lBV(1).LT.0.) .OR. (delta_lBV(1).GT.BV_lengths(1)) ) THEN
            IF (Species(FractNbr)%Init(iInit)%PartDensity .GT. 0.) i=i+1
            CYCLE !particle would not reach comp. domain in direction of BaseVector1 -> try new velo
          END IF
          IF ( (delta_lBV(2).LT.0.) .OR. (delta_lBV(2).GT.BV_lengths(2)) ) THEN
            IF (Species(FractNbr)%Init(iInit)%PartDensity .GT. 0.) i=i+1
            CYCLE !particle would not reach comp. domain in direction of BaseVector2 -> try new velo
          END IF
          ! set particle positions depending on SpaceIC
          Particle_pos = Species(FractNbr)%Init(iInit)%BasePointIC &
                       + Species(FractNbr)%Init(iInit)%BaseVector1IC/BV_lengths(1) * delta_lBV(1) &
                       + Species(FractNbr)%Init(iInit)%BaseVector2IC/BV_lengths(2) * delta_lBV(2) &
                       + lineVector * delta_l 
        CASE('orifice')
          ! set particle position (to be tried) depending on SpaceIC
          v_BV(1) = Vec3D(1)*Species(FractNbr)%Init(iInit)%BaseVector1IC(1) &
                  + Vec3D(2)*Species(FractNbr)%Init(iInit)%BaseVector1IC(2) &
                  + Vec3D(3)*Species(FractNbr)%Init(iInit)%BaseVector1IC(3)
          v_BV(1) = v_BV(1) / BV_lengths(1) !BV1 component of velocity
          v_BV(2) = Vec3D(1)*Species(FractNbr)%Init(iInit)%BaseVector2IC(1) &
                  + Vec3D(2)*Species(FractNbr)%Init(iInit)%BaseVector2IC(2) &
                  + Vec3D(3)*Species(FractNbr)%Init(iInit)%BaseVector2IC(3)
          v_BV(2) = v_BV(2) / BV_lengths(2) !BV2 component of velocity
          delta_lBV = dt*RKdtFrac * v_BV
          delta_lBV(1) = delta_lBV(1) + BV_lengths(1) * ( RandVal(1)*(lrel_ins_BV(1)+1.0+lrel_ins_BV(2)) - lrel_ins_BV(1) )
          delta_lBV(2) = delta_lBV(2) + BV_lengths(2) * ( RandVal(2)*(lrel_ins_BV(3)+1.0+lrel_ins_BV(4)) - lrel_ins_BV(3) )
          Particle_pos = Species(FractNbr)%Init(iInit)%BaseVector1IC/BV_lengths(1) * delta_lBV(1) &
                       + Species(FractNbr)%Init(iInit)%BaseVector2IC/BV_lengths(2) * delta_lBV(2) &
                       + lineVector * delta_l 
          IntersecPoint = Particle_pos - Vec3D * delta_l/v_line !Vector from BP to Intersec point of virt. path with orifice plane
          orifice_delta = (IntersecPoint(1)*Species(FractNbr)%Init(iInit)%BaseVector1IC(1) &
                         + IntersecPoint(2)*Species(FractNbr)%Init(iInit)%BaseVector1IC(2) &
                         + IntersecPoint(3)*Species(FractNbr)%Init(iInit)%BaseVector1IC(3))/BV_lengths(1)
          IF ( orificePeriodicLog(1) ) THEN
            IF ( (delta_lBV(1).LT.0.) .OR. (delta_lBV(1).GT.BV_lengths(1)) ) THEN
              IF (Species(FractNbr)%Init(iInit)%PartDensity .GT. 0.) i=i+1
              CYCLE !particle would not reach comp. domain in direction of BaseVector1 -> try new velo
            END IF
          ELSE
            IF ( (orifice_delta.GT.BV_lengths(1)) .OR. (orifice_delta.LT.0.) ) THEN
              IF (Species(FractNbr)%Init(iInit)%PartDensity .GT. 0.) i=i+1
              CYCLE !particle would not reach comp. through orifice -> try new velo
            END IF
          END IF
          orifice_delta = (IntersecPoint(1)*Species(FractNbr)%Init(iInit)%BaseVector2IC(1) &
                         + IntersecPoint(2)*Species(FractNbr)%Init(iInit)%BaseVector2IC(2) &
                         + IntersecPoint(3)*Species(FractNbr)%Init(iInit)%BaseVector2IC(3))/BV_lengths(2)
          IF ( orificePeriodicLog(2) ) THEN
            IF ( (delta_lBV(2).LT.0.) .OR. (delta_lBV(2).GT.BV_lengths(2)) ) THEN
              IF (Species(FractNbr)%Init(iInit)%PartDensity .GT. 0.) i=i+1
              CYCLE !particle would not reach comp. domain in direction of BaseVector2 -> try new velo
            END IF
          ELSE
            IF ( (orifice_delta.GT.BV_lengths(2)) .OR. (orifice_delta.LT.0.) ) THEN
              IF (Species(FractNbr)%Init(iInit)%PartDensity .GT. 0.) i=i+1
              CYCLE !particle would not reach comp. through orifice -> try new velo
            END IF
          END IF
          Particle_pos = Particle_pos + Species(FractNbr)%Init(iInit)%BasePointIC
        CASE DEFAULT
          CALL abort(&
__STAMP__&
,'wrong vpiDomainType for virtual Pre-Inserting region!')
        END SELECT
        IF (Species(FractNbr)%Init(iInit)%NumberOfExcludeRegions.GT.0) THEN
          CALL InsideExcludeRegionCheck(FractNbr, iInit, Particle_pos, insideExcludeRegion)
          IF (insideExcludeRegion) THEN
            i=i+1
            CYCLE !particle is in excluded region
          END IF
        END IF
        !store determined values or go to next particle
        particle_positions((chunkSize2+1)*6-5) = Particle_pos(1)
        particle_positions((chunkSize2+1)*6-4) = Particle_pos(2)
        particle_positions((chunkSize2+1)*6-3) = Particle_pos(3)
        particle_positions((chunkSize2+1)*6-2) = Vec3D(1)
        particle_positions((chunkSize2+1)*6-1) = Vec3D(2)
        particle_positions((chunkSize2+1)*6  ) = Vec3D(3)
        i=i+1
        chunkSize2=chunkSize2+1
      END DO
    !------------------SpaceIC-case: cylinder_vpi-----------------------------------------------------------------------------------
    CASE('cylinder_vpi')
      i=1
      chunkSize2=0
      DO WHILE (i .LE. chunkSize)        
        ! Check if particle would reach comp. domain in one timestep
        CALL CalcVelocity_maxwell_lpn(FractNbr, Vec3D, iInit=iInit)
        CALL RANDOM_NUMBER(RandVal)
        v_line = Vec3D(1)*lineVector(1) + Vec3D(2)*lineVector(2) + Vec3D(3)*lineVector(3) !lineVector component of velocity
        delta_l = dt*RKdtFrac * v_line - l_ins * RandVal(3)
        IF (delta_l .LT. 0.) THEN
          IF (Species(FractNbr)%Init(iInit)%PartDensity .GT. 0.) i=i+1
          CYCLE !particle would not reach comp. domain -> try new velo
        END IF
        SELECT CASE(TRIM(Species(FractNbr)%Init(iInit)%vpiDomainType)) 
        CASE('perpendicular_extrusion')
          ! set particle positions depending on SpaceIC
          radius = Species(FractNbr)%Init(iInit)%RadiusIC + 1.
          DO WHILE((radius.GT.Species(FractNbr)%Init(iInit)%RadiusIC) .OR.(radius.LT.Species(FractNbr)%Init(iInit)%Radius2IC))
            CALL RANDOM_NUMBER(RandVal)
            Particle_pos = Species(FractNbr)%Init(iInit)%BaseVector1IC * (RandVal(1)*2-1) &
                         + Species(FractNbr)%Init(iInit)%BaseVector2IC * (RandVal(2)*2-1)
            radius = SQRT( Particle_pos(1) * Particle_pos(1) + &
                           Particle_pos(2) * Particle_pos(2) + &
                           Particle_pos(3) * Particle_pos(3) )
          END DO
          Particle_pos = Particle_pos + Species(FractNbr)%Init(iInit)%BasePointIC + lineVector * delta_l
        CASE('orifice')
          ! set particle position (to be tried) depending on SpaceIC
          radius = Species(FractNbr)%Init(iInit)%RadiusIC * (1.+lrel_ins_BV(1)) + 1. !lrel_ins_BV(1)=lrel_ins_BV(2)=...
          DO WHILE ( radius .GT. Species(FractNbr)%Init(iInit)%RadiusIC * (1.+lrel_ins_BV(1)) )
            CALL RANDOM_NUMBER(RandVal)
            Particle_pos = Species(FractNbr)%Init(iInit)%BaseVector1IC*(1.+lrel_ins_BV(1)) * (RandVal(1)*2-1) &
                         + Species(FractNbr)%Init(iInit)%BaseVector2IC*(1.+lrel_ins_BV(2)) * (RandVal(2)*2-1) !BV_lengths(:)=R
            radius = SQRT( Particle_pos(1) * Particle_pos(1) + &
                           Particle_pos(2) * Particle_pos(2) + &
                           Particle_pos(3) * Particle_pos(3) )
          END DO
          Particle_pos = Particle_pos + dt*RKdtFrac*Vec3D - lineVector*(dt*RKdtFrac*v_line-delta_l) !get old RandVal(3) for l_ins*R3
          
          IntersecPoint = Particle_pos - Vec3D * delta_l/v_line !Vector from BP to Intersec point of virt. path with orifice plane
          orifice_delta = (IntersecPoint(1)*Species(FractNbr)%Init(iInit)%BaseVector1IC(1) &
                         + IntersecPoint(2)*Species(FractNbr)%Init(iInit)%BaseVector1IC(2) &
                         + IntersecPoint(3)*Species(FractNbr)%Init(iInit)%BaseVector1IC(3))/BV_lengths(1)
          radius = (IntersecPoint(1)*Species(FractNbr)%Init(iInit)%BaseVector2IC(1) &
                  + IntersecPoint(2)*Species(FractNbr)%Init(iInit)%BaseVector2IC(2) &
                  + IntersecPoint(3)*Species(FractNbr)%Init(iInit)%BaseVector2IC(3))/BV_lengths(2)
          radius = SQRT( orifice_delta*orifice_delta + radius*radius )
            IF ( radius.GT.BV_lengths(1) ) THEN
              IF (Species(FractNbr)%Init(iInit)%PartDensity .GT. 0.) i=i+1
              CYCLE !particle would not reach comp. through orifice -> try new velo
            END IF
          Particle_pos = Particle_pos + Species(FractNbr)%Init(iInit)%BasePointIC
        CASE DEFAULT
          CALL abort(&
__STAMP__&
,'wrong vpiDomainType for virtual Pre-Inserting region!')
        END SELECT
        IF (Species(FractNbr)%Init(iInit)%NumberOfExcludeRegions.GT.0) THEN
          CALL InsideExcludeRegionCheck(FractNbr, iInit, Particle_pos, insideExcludeRegion)
          IF (insideExcludeRegion) THEN
            i=i+1
            CYCLE !particle is in excluded region
          END IF
        END IF
        !store determined values or go to next particle
        particle_positions((chunkSize2+1)*6-5) = Particle_pos(1)
        particle_positions((chunkSize2+1)*6-4) = Particle_pos(2)
        particle_positions((chunkSize2+1)*6-3) = Particle_pos(3)
        particle_positions((chunkSize2+1)*6-2) = Vec3D(1)
        particle_positions((chunkSize2+1)*6-1) = Vec3D(2)
        particle_positions((chunkSize2+1)*6  ) = Vec3D(3)
        i=i+1
        chunkSize2=chunkSize2+1
      END DO
    !------------------SpaceIC-case: LD_insert--------------------------------------------------------------------------------------
    CASE('LD_insert')
      CALL LD_SetParticlePosition(chunkSize2,particle_positions_Temp,FractNbr,iInit)
      DEALLOCATE( particle_positions, STAT=allocStat )
      IF (allocStat .NE. 0) THEN
        CALL abort(&
__STAMP__&
,'ERROR in ParticleEmission_parallel: cannot deallocate particle_positions!')
      END IF
      NbrOfParticle=chunkSize2
      ALLOCATE(particle_positions(3*chunkSize2))
      particle_positions(1:3*chunkSize2) = particle_positions_Temp(1:3*chunkSize2)
      DEALLOCATE( particle_positions_Temp, STAT=allocStat )
      IF (allocStat .NE. 0) THEN
        CALL abort(__STAMP__,&
          'ERROR in ParticleEmission_parallel: cannot deallocate particle_positions!')
      END IF
    !------------------SpaceIC-case: cuboid_equal-----------------------------------------------------------------------------------
    CASE('cuboid_equal')
#ifdef MPI
      IF (PartMPI%InitGroup(InitGroup)%nProcs.GT. 1) THEN
        SWRITE(UNIT_stdOut,*)'WARNING in SetParticlePosition:'
        SWRITE(UNIT_stdOut,*)'cannot fully handle Particle Initial Condition \"cuboid equal\"'
        SWRITE(UNIT_stdOut,*)'in parallel mode (with more than one CPU)!'
        SWRITE(UNIT_stdOut,*)'USE WITH CARE!!!'
      END IF
      j=0
      mySumOfMatchedParticles = 0
      DO i=1,PDM%ParticleVecLength
         j=j+1
         ParticleIndexNbr = PDM%nextFreePosition(i+PDM%CurrentNextFreePosition)
         IF (ParticleIndexNbr .ne. 0) THEN
            PartState(ParticleIndexNbr,1:3) = PartState(j,1:3)
            PDM%ParticleInside(ParticleIndexNbr) = .TRUE.
            IF(DoRefMapping.OR.TriaTracking)THEN
              CALL SingleParticleToExactElement(ParticleIndexNbr,doHALO=.FALSE.,initFix=.TRUE.,doRelocate=.FALSE.)
            ELSE
              CALL SingleParticleToExactElementNoMap(ParticleIndexNbr,doHALO=.FALSE.,doRelocate=.FALSE.)
            END IF
            IF (PDM%ParticleInside(ParticleIndexNbr)) THEN
               mySumOfMatchedParticles = mySumOfMatchedParticles + 1
            ELSE
               PDM%ParticleInside(ParticleIndexNbr) = .FALSE.
            END IF
            IF (PDM%ParticleInside(ParticleIndexNbr)) THEN
              PDM%IsNewPart(ParticleIndexNbr)=.TRUE.
              PDM%dtFracPush(ParticleIndexNbr) = .FALSE.
            END IF
         ELSE
           CALL abort(&
__STAMP__&
,'ERROR in SetParticlePosition: ParticleIndexNbr.EQ.0 - maximum nbr of particles reached?')
         END IF
      END DO
      CALL MPI_ALLREDUCE(mySumOfMatchedParticles, sumOfMatchedParticles, 1, MPI_INTEGER &
          , MPI_SUM, PartMPI%InitGroup(InitGroup)%COMM, IERROR)
      nbrOfParticle = NbrOfParticle - sumOfMatchedParticles
      IF (nbrOfParticle .NE. 0) THEN
        IPWRITE(UNIT_stdOut,*)'ERROR in ParticleEmission_parallel:'
        IPWRITE(UNIT_stdOut,'(I4,A,I8,A)')'matched ', sumOfMatchedParticles, ' particles'
        IPWRITE(UNIT_stdOut,'(I4,A,I8,A)')'when ', NbrOfParticle+sumOfMatchedParticles, ' particles were required!'
        CALL abort(&
__STAMP__&
,'ERROR in ParticleEmission_parallel')
      END IF
      NbrOfParticle = mySumOfMatchedParticles
      DEALLOCATE( particle_positions, STAT=allocStat )
      IF (allocStat .NE. 0) THEN
        CALL abort(&
__STAMP__&
,'ERROR in ParticleEmission_parallel: cannot deallocate particle_positions!')
      END IF
      RETURN
#else
      DO i=1,chunkSize
        ParticleIndexNbr = PDM%nextFreePosition(i+PDM%CurrentNextFreePosition)
        particle_positions(i*3-2 : i*3) = PartState(ParticleIndexNbr-Species(FractNbr)%Init(iInit)%initialParticleNumber,1:3)
      END DO
#endif
    !------------------SpaceIC-case: cuboid_with_equidistant_distribution-----------------------------------------------------------
    CASE ('cuboid_with_equidistant_distribution') 
       IF(Species(FractNbr)%Init(iInit)%initialParticleNumber.NE. &
            (Species(FractNbr)%Init(iInit)%maxParticleNumberX * Species(FractNbr)%Init(iInit)%maxParticleNumberY &
            * Species(FractNbr)%Init(iInit)%maxParticleNumberZ)) THEN
         SWRITE(*,*) 'for species ',FractNbr,' does not match number of particles in each direction!'
         CALL abort(&
__STAMP__&
,'ERROR: Number of particles in init / emission region',iInit)
       END IF
       xlen = SQRT(Species(FractNbr)%Init(iInit)%BaseVector1IC(1)**2 &
            + Species(FractNbr)%Init(iInit)%BaseVector1IC(2)**2 &
            + Species(FractNbr)%Init(iInit)%BaseVector1IC(3)**2 )
       ylen = SQRT(Species(FractNbr)%Init(iInit)%BaseVector2IC(1)**2 &
            + Species(FractNbr)%Init(iInit)%BaseVector2IC(2)**2 &
            + Species(FractNbr)%Init(iInit)%BaseVector2IC(3)**2 )
       zlen = ABS(Species(FractNbr)%Init(iInit)%CuboidHeightIC)

       ! make sure the vectors correspond to x,y,z-dir
       IF ((xlen.NE.Species(FractNbr)%Init(iInit)%BaseVector1IC(1)).OR. &
          (ylen.NE.Species(FractNbr)%Init(iInit)%BaseVector2IC(2)).OR. &
          (zlen.NE.Species(FractNbr)%Init(iInit)%CuboidHeightIC)) THEN
         CALL abort(&
__STAMP__&
,'Basevectors1IC,-2IC and CuboidHeightIC have to be in x,y,z-direction, respectively for emission condition')
        END IF
       x_step = xlen/Species(FractNbr)%Init(iInit)%maxParticleNumberX
       y_step = ylen/Species(FractNbr)%Init(iInit)%maxParticleNumberY
       z_step = zlen/Species(FractNbr)%Init(iInit)%maxParticleNumberZ
       iPart = 1
       DO i=1,Species(FractNbr)%Init(iInit)%maxParticleNumberX
         x_pos = (i-0.5) * x_step + Species(FractNbr)%Init(iInit)%BasePointIC(1)
         DO j=1,Species(FractNbr)%Init(iInit)%maxParticleNumberY
           y_pos =  Species(FractNbr)%Init(iInit)%BasePointIC(2) + (j-0.5) * y_step
           DO k=1,Species(FractNbr)%Init(iInit)%maxParticleNumberZ
             particle_positions(iPart*3-2) = x_pos
             particle_positions(iPart*3-1) = y_pos
             particle_positions(iPart*3  ) = Species(FractNbr)%Init(iInit)%BasePointIC(3) &
                  + (k-0.5) * z_step
             iPart = iPart + 1
           END DO
         END DO
       END DO
    !------------------SpaceIC-case: sin_deviation----------------------------------------------------------------------------------
    CASE('sin_deviation')
       IF(Species(FractNbr)%Init(iInit)%initialParticleNumber.NE. &
            (Species(FractNbr)%Init(iInit)%maxParticleNumberX * Species(FractNbr)%Init(iInit)%maxParticleNumberY &
            * Species(FractNbr)%Init(iInit)%maxParticleNumberZ)) THEN
         SWRITE(*,*) 'for species ',FractNbr,' does not match number of particles in each direction!'
         CALL abort(&
         __STAMP__&
         ,'ERROR: Number of particles in init / emission region',iInit)
       END IF
       xlen = abs(GEO%xmaxglob  - GEO%xminglob)  
       ylen = abs(GEO%ymaxglob  - GEO%yminglob)
       zlen = abs(GEO%zmaxglob  - GEO%zminglob)
       pilen=2.0*PI/xlen
       x_step = xlen/Species(FractNbr)%Init(iInit)%maxParticleNumberX
       y_step = ylen/Species(FractNbr)%Init(iInit)%maxParticleNumberY
       z_step = zlen/Species(FractNbr)%Init(iInit)%maxParticleNumberZ
       iPart = 1
       DO i=1,Species(FractNbr)%Init(iInit)%maxParticleNumberX
          x_pos = (i * x_step - x_step*0.5)
          x_pos = GEO%xminglob + x_pos + Species(FractNbr)%Init(iInit)%Amplitude &
                  * sin(Species(FractNbr)%Init(iInit)%WaveNumber * pilen * x_pos)
          DO j=1,Species(FractNbr)%Init(iInit)%maxParticleNumberY
            y_pos =  GEO%yminglob + j * y_step - y_step * 0.5
            DO k=1,Species(FractNbr)%Init(iInit)%maxParticleNumberZ
              particle_positions(iPart*3-2) = x_pos                                
              particle_positions(iPart*3-1) = y_pos
              particle_positions(iPart*3  ) = GEO%zminglob &
                                        + k * z_step - z_step * 0.5
              iPart = iPart + 1
            END DO
          END DO
       END DO
    !------------------SpaceIC-case: IMD--------------------------------------------------------------------------------------------
    CASE('IMD') ! read IMD particle position from *.chkpt file
      ! set velocity distribution to read external data
      SWRITE(UNIT_stdOut,'(A,A)') " Reading IMD atom data from file (IMDAtomFile): ",TRIM(IMDAtomFile)
      IF(TRIM(IMDAtomFile).NE.'no file found')THEN
        Species(FractNbr)%Init(iInit)%velocityDistribution='IMD'
#ifdef MPI
        IF(.NOT.PartMPI%InitGroup(InitGroup)%MPIROOT)THEN
          CALL abort(__STAMP__&
          ,'ERROR: Cannot SetParticlePosition in multi-core environment for SpaceIC=IMD!')
        END IF
#endif /*MPI*/
        ! Read particle data from file
        ioUnit=GETFREEUNIT()
        OPEN(UNIT=ioUnit,FILE=TRIM(IMDAtomFile),STATUS='OLD',ACTION='READ',IOSTAT=io_error)
        IF(io_error.NE.0)THEN
          CALL abort(__STAMP__&
          ,'ERROR in particle_emission.f90: Cannot open specified File (particle position) for SpaceIC=IMD!')
        END IF
        ! IMD Data Format (ASCII)
        !   1      2    3         4           5         6         7         8         9         10       11     12
        !#C number type mass      x           y         z         vx        vy        vz        Epot     Z      eam_rho
        !   2294   0    26.981538 3589.254381 46.066405 91.985804 -1.576543 -0.168184 -0.163417 0.000000 2.4332 0.000000
        IndNum=INDEX(IMDAtomFile, '/',BACK = .TRUE.)
        IF(IndNum.GT.0)THEN
          !IndNum=INDEX(IMDAtomFile,'/',BACK = .TRUE.) ! get path without binary
          StrTmp=TRIM(IMDAtomFile(IndNum+1:LEN(IMDAtomFile)))
          IndNum=INDEX(StrTmp,'.',BACK = .TRUE.)
          IF(IndNum.GT.0)THEN
            StrTmp=StrTmp(1:IndNum-1)
            IndNum=INDEX(StrTmp,'.')
            IF(IndNum.GT.0)THEN
              StrTmp=StrTmp(IndNum+1:LEN(StrTmp))
            END IF
          END IF
        END IF
        read(StrTmp,*,iostat=io_error)  IMDNumber
        CALL PrintOption('IMD *.chkpt file','OUTPUT',StrOpt=StrTmp)
        CALL PrintOption('IMDNumber','OUTPUT',IntOpt=IMDNumber)
        Nshift=0
        xMin=HUGE(1.)
        yMin=HUGE(1.)
        zMin=HUGE(1.)
        xMax=-HUGE(1.)
        yMax=-HUGE(1.)
        zMax=-HUGE(1.)
        DO i=1,9
          READ(ioUnit,'(A)',IOSTAT=io_error)StrTmp
          IF(io_error.NE.0)THEN
             SWRITE(UNIT_stdOut,'(A,I5,A3,A)') 'Error in line ',i,' : ',TRIM(StrTmp)
          END IF
        END DO
        DO i=1,chunkSize
          READ(ioUnit,*,IOSTAT=io_error) IMD_array(1:12)
          IF(io_error>0)THEN
            CALL abort(__STAMP__&
            ,'ERROR in particle_emission.f90: Error reading specified File (particle position) for SpaceIC=IMD!')
          ELSE IF(io_error<0)THEN
            EXIT
          ELSE
            IF(1.EQ.2)THEN ! transformation
              ! 0.) multiply by unit system factor (1e-10)
              ! 1.) switch X and Z axis and invert Z
              ! 2.) shift origin in X- and Y-direction by -10nm
              Particle_pos = (/  IMD_array(6)       *1.E-10-10.13E-9,&
                                 IMD_array(5)       *1.E-10-10.13E-9,&
                               -(IMD_array(4)-10500)*1.E-10/)
            ELSE ! no transformation
              Particle_pos = (/  IMD_array(4)*IMDLengthScale,&
                                 IMD_array(5)*IMDLengthScale,&
                                 IMD_array(6)*IMDLengthScale/)
            END IF
            particle_positions((i-Nshift)*3-2) = Particle_pos(1)
            particle_positions((i-Nshift)*3-1) = Particle_pos(2)
            particle_positions((i-Nshift)*3  ) = Particle_pos(3)

            PartState(i-Nshift,4:6) =&
            (/IMD_array(7)*IMDLengthScale/IMDTimeScale,&
              IMD_array(8)*IMDLengthScale/IMDTimeScale,&
              IMD_array(9)*IMDLengthScale/IMDTimeScale/)

            xMin=MIN(Particle_pos(1),xMin)
            yMin=MIN(Particle_pos(2),yMin)
            zMin=MIN(Particle_pos(3),zMin)
            xMax=MAX(Particle_pos(1),xMax)
            yMax=MAX(Particle_pos(2),yMax)
            zMax=MAX(Particle_pos(3),zMax)
            ! check cutoff
            SELECT CASE(TRIM(IMDCutOff))
            CASE('no_cutoff') ! nothing to do
            CASE('Epot') ! kill particles that have Epot (i.e. they are in the solid body)
              IF(ABS(IMD_array(10)).GT.0.0)THEN ! IMD_array(10) is Epot
                Nshift=Nshift+1
              END IF
            CASE('coordinates') ! kill particles that are below a certain threshold in z-direction
              IF(IMD_array(4)*IMDLengthScale.GT.IMDCutOffxValue)THEN
                Nshift=Nshift+1
              END IF
            CASE('velocity') ! kill particles that are below a certain velocity threshold
              CALL abort(__STAMP__&
              ,'ERROR in particle_emission.f90: Error reading specified File (particle position) for SpaceIC=IMD!')
            END SELECT
          END IF
        END DO
        CLOSE(ioUnit)
        SWRITE(UNIT_stdOut,'(A,I15)')  "Particles Read: chunkSize = NbrOfParticle = ",(i-Nshift)-1
        chunkSize     = (i-Nshift)-1 ! don't change here, change at velocity
        NbrOfParticle = (i-Nshift)-1 ! don't change here, change at velocity
        SWRITE(UNIT_stdOut,'(A)') 'Min-Max particle positions from IMD source file:'
        SWRITE(UNIT_stdOut,'(A25,A25)')  "x-Min [nm]","x-Max [nm]"
        SWRITE(UNIT_stdOut,'(E25.14E3,E25.14E3)') xMin*1.e9,xMax*1.e9
        SWRITE(UNIT_stdOut,'(A25,A25)')  "y-Min [nm]","y-Max [nm]"
        SWRITE(UNIT_stdOut,'(E25.14E3,E25.14E3)') yMin*1.e9,yMax*1.e9
        SWRITE(UNIT_stdOut,'(A25,A25)')  "z-Min [nm]","z-Max [nm]"
        SWRITE(UNIT_stdOut,'(E25.14E3,E25.14E3)') zMin*1.e9,zMax*1.e9
        CALL PrintOption('IMD Particles Found','OUTPUT',IntOpt=(i-Nshift)-1)
      ELSE ! TRIM(IMDAtomFile) = 'no file found' -> exit
        Species(FractNbr)%Init(iInit)%velocityDistribution=''
      END IF
    END SELECT
    !------------------SpaceIC-cases: end-------------------------------------------------------------------------------------------
    chunkSize=chunkSize2

#ifdef MPI
 ELSE !no mpi root, nchunks=1
   chunkSize=0
 END IF
 IF(nChunks.GT.1) THEN
   ALLOCATE( PartMPIInsert%nPartsSend  (0:PartMPI%InitGroup(InitGroup)%nProcs-1), STAT=allocStat )
   ALLOCATE( PartMPIInsert%nPartsRecv  (0:PartMPI%InitGroup(InitGroup)%nProcs-1), STAT=allocStat )
   ALLOCATE( PartMPIInsert%SendRequest (0:PartMPI%InitGroup(InitGroup)%nProcs-1,1:2), STAT=allocStat )
   ALLOCATE( PartMPIInsert%RecvRequest (0:PartMPI%InitGroup(InitGroup)%nProcs-1,1:2), STAT=allocStat )
   ALLOCATE( PartMPIInsert%send_message(0:PartMPI%InitGroup(InitGroup)%nProcs-1), STAT=allocStat )
   PartMPIInsert%nPartsSend(:)=0
   DO i=1,chunkSize
     CellX = INT((particle_positions(DimSend*(i-1)+1)-GEO%xminglob)/GEO%FIBGMdeltas(1))+1
     CellY = INT((particle_positions(DimSend*(i-1)+2)-GEO%yminglob)/GEO%FIBGMdeltas(2))+1
     CellZ = INT((particle_positions(DimSend*(i-1)+3)-GEO%zminglob)/GEO%FIBGMdeltas(3))+1
     InsideMyBGM=.TRUE.
     IF ((CellX.GT.GEO%FIBGMimax).OR.(CellX.LT.GEO%FIBGMimin) .OR. &
         (CellY.GT.GEO%FIBGMjmax).OR.(CellY.LT.GEO%FIBGMjmin) .OR. &
         (CellZ.GT.GEO%FIBGMkmax).OR.(CellZ.LT.GEO%FIBGMkmin)) THEN
       InsideMyBGM=.FALSE.
     END If
     IF (InsideMyBGM) THEN
       IF (.NOT.ALLOCATED(GEO%FIBGM(CellX,CellY,CellZ)%ShapeProcs)) InsideMyBGM=.FALSE.
     END IF
     IF (InsideMyBGM) THEN
       DO j=2,GEO%FIBGM(CellX,CellY,CellZ)%ShapeProcs(1)+1
         iProc=GEO%FIBGM(CellX,CellY,CellZ)%ShapeProcs(j)
         tProc=PartMPI%InitGroup(InitGroup)%CommToGroup(iProc)
         IF(tProc.EQ.-1)CYCLE
         !IF(PartMPI%InitGroup(InitGroup)%COMM.EQ.MPI_COMM_NULL) THEN
         PartMPIInsert%nPartsSend(tProc)=PartMPIInsert%nPartsSend(tProc)+1
       END DO
       PartMPIInsert%nPartsSend(PartMPI%InitGroup(InitGroup)%MyRank)=&
              PartMPIInsert%nPartsSend(PartMPI%InitGroup(InitGroup)%MyRank)+1
     ELSE
       DO iProc=0,PartMPI%InitGroup(InitGroup)%nProcs-1
!         IF (iProc.EQ.PartMPI%iProc) CYCLE
         PartMPIInsert%nPartsSend(iProc)=PartMPIInsert%nPartsSend(iProc)+1
       END DO
     END IF
   END DO   
 ELSE
    IF(PartMPI%InitGroup(InitGroup)%MPIRoot) THEN
      ALLOCATE( PartMPIInsert%send_message(0:0), STAT=allocStat )
      MessageSize=DimSend*chunkSize
      ALLOCATE( PartMPIInsert%send_message(0)%content(1:MessageSize), STAT=allocStat )
      PartMPIInsert%send_message(0)%content(:)=particle_positions(1:DimSend*chunkSize)
      DEALLOCATE(particle_positions, STAT=allocStat)
    END IF
 END IF
 IF (nChunks.GT.1) THEN
    DO iProc=0,PartMPI%InitGroup(InitGroup)%nProcs-1
      ! sent particles
      !--- MPI_ISEND lengths of lists of particles leaving local mesh
      CALL MPI_ISEND(PartMPIInsert%nPartsSend(iProc), 1, MPI_INTEGER, iProc, 1011+FractNbr, PartMPI%InitGroup(InitGroup)%COMM, &
                     PartMPIInsert%SendRequest(iProc,1), IERROR)
      !--- MPI_IRECV lengths of lists of particles entering local mesh
      CALL MPI_IRECV(PartMPIInsert%nPartsRecv(iProc), 1, MPI_INTEGER, iProc, 1011+FractNbr, PartMPI%InitGroup(InitGroup)%COMM, &
                     PartMPIInsert%RecvRequest(iProc,1), IERROR)
      IF (PartMPIInsert%nPartsSend(iProc).GT.0) THEN
        ALLOCATE( PartMPIInsert%send_message(iProc)%content(1:DimSend*PartMPIInsert%nPartsSend(iProc)), STAT=allocStat )
      END IF
    END DO
    PartMPIInsert%nPartsSend(:)=0
    DO i=1,chunkSize
      CellX = INT((particle_positions(DimSend*(i-1)+1)-GEO%xminglob)/GEO%FIBGMdeltas(1))+1
      CellY = INT((particle_positions(DimSend*(i-1)+2)-GEO%yminglob)/GEO%FIBGMdeltas(2))+1
      CellZ = INT((particle_positions(DimSend*(i-1)+3)-GEO%zminglob)/GEO%FIBGMdeltas(3))+1
      InsideMyBGM=.TRUE.
      IF ((CellX.GT.GEO%FIBGMimax).OR.(CellX.LT.GEO%FIBGMimin) .OR. &
          (CellY.GT.GEO%FIBGMjmax).OR.(CellY.LT.GEO%FIBGMjmin) .OR. &
          (CellZ.GT.GEO%FIBGMkmax).OR.(CellZ.LT.GEO%FIBGMkmin)) THEN
        InsideMyBGM=.FALSE.
      END If
      IF (InsideMyBGM) THEN
        IF (.NOT.ALLOCATED(GEO%FIBGM(CellX,CellY,CellZ)%ShapeProcs)) InsideMyBGM=.FALSE.
      END IF
      IF (InsideMyBGM) THEN
        DO j=2,GEO%FIBGM(CellX,CellY,CellZ)%ShapeProcs(1)+1
          iProc=GEO%FIBGM(CellX,CellY,CellZ)%ShapeProcs(j)
          tProc=PartMPI%InitGroup(InitGroup)%CommToGroup(iProc)
          IF(tProc.EQ.-1)CYCLE
          PartMPIInsert%nPartsSend(tProc)=PartMPIInsert%nPartsSend(tProc)+1
          k=PartMPIInsert%nPartsSend(tProc)
          PartMPIInsert%send_message(tProc)%content(DimSend*(k-1)+1:DimSend*k)=particle_positions(DimSend*(i-1)+1:DimSend*i)
        END DO
        PartMPIInsert%nPartsSend(PartMPI%InitGroup(InitGroup)%MyRank)= &
            PartMPIInsert%nPartsSend(PartMPI%InitGroup(InitGroup)%MyRank)+1
        k=PartMPIInsert%nPartsSend(PartMPI%InitGroup(InitGroup)%MyRank)
        PartMPIInsert%send_message(PartMPI%InitGroup(InitGroup)%MyRank)%content(DimSend*(k-1)+1:DimSend*k)=&
                                                                          particle_positions(DimSend*(i-1)+1:DimSend*i)
      ELSE
        DO iProc=0,PartMPI%InitGroup(InitGroup)%nProcs-1
 !         IF (iProc.EQ.PartMPI%iProc) CYCLE
          PartMPIInsert%nPartsSend(iProc)=PartMPIInsert%nPartsSend(iProc)+1
          k=PartMPIInsert%nPartsSend(iProc)
          PartMPIInsert%send_message(iProc)%content(DimSend*(k-1)+1:DimSend*k)=particle_positions(DimSend*(i-1)+1:DimSend*i)
        END DO
      END IF
    END DO
    DEALLOCATE(particle_positions, STAT=allocStat)
    DO iProc=0,PartMPI%InitGroup(InitGroup)%nProcs-1
      !--- (non-blocking:) send messages to all procs receiving particles from myself
      IF (PartMPIInsert%nPartsSend(iProc).GT.0) THEN
        CALL MPI_ISEND(PartMPIInsert%send_message(iProc)%content, DimSend*PartMPIInsert%nPartsSend(iProc),& 
         MPI_DOUBLE_PRECISION, iProc, 1022+FractNbr, PartMPI%InitGroup(InitGroup)%COMM, PartMPIInsert%SendRequest(iProc,2), IERROR)
      END IF
    END DO
  END IF
ELSE ! mode.NE.1:
!--- RECEIVE:
  nChunksTemp=0
  IF(nChunks.EQ.1) THEN
    IF(PartMPI%InitGroup(InitGroup)%MPIRoot) THEN !chunkSize can be 1 higher than NbrOfParticle for VPI+PartDens
       chunkSize=INT( REAL(SIZE(PartMPIInsert%send_message(0)%content)) / REAL(DimSend) )
       ALLOCATE(particle_positions(1:chunkSize*DimSend), STAT=allocStat)
       particle_positions(:)=PartMPIInsert%send_message(0)%content(:)
       DEALLOCATE( PartMPIInsert%send_message(0)%content )      
       DEALLOCATE( PartMPIInsert%send_message )
    END IF
    IF( Species(FractNbr)%Init(iInit)%VirtPreInsert .AND. (Species(FractNbr)%Init(iInit)%PartDensity .GT. 0.) ) THEN
      CALL MPI_BCAST(chunkSize, 1, MPI_INTEGER,0,PartMPI%InitGroup(InitGroup)%COMM,IERROR)
    ELSE
      chunkSize=NbrOfParticle
    END IF
    IF(.NOT.PartMPI%InitGroup(InitGroup)%MPIROOT) THEN
      ALLOCATE(particle_positions(1:chunkSize*DimSend), STAT=allocStat)
    END IF
    CALL MPI_BCAST(particle_positions, chunkSize*DimSend, MPI_DOUBLE_PRECISION,0,PartMPI%InitGroup(InitGroup)%COMM,IERROR)
    nChunksTemp=1
  ELSE   
    DO iProc=0,PartMPI%InitGroup(InitGroup)%nProcs-1
      CALL MPI_WAIT(PartMPIInsert%RecvRequest(iProc,1),msg_status(:),IERROR)
    END DO
    k=SUM(PartMPIInsert%nPartsRecv)
    ALLOCATE(particle_positions(1:k*DimSend), STAT=allocStat)
    k=0
    DO iProc=0,PartMPI%InitGroup(InitGroup)%nProcs-1
      IF (PartMPIInsert%nPartsRecv(iProc).GT.0) THEN
      !--- MPI_IRECV lengths of lists of particles entering local mesh
        CALL MPI_IRECV(particle_positions(k*DimSend+1), DimSend*PartMPIInsert%nPartsRecv(iProc),&
                                                  MPI_DOUBLE_PRECISION, iProc, 1022+FractNbr,   &
                                                  PartMPI%InitGroup(InitGroup)%COMM, PartMPIInsert%RecvRequest(iProc,2), IERROR)
        CALL MPI_WAIT(PartMPIInsert%RecvRequest(iProc,2),msg_status(:),IERROR)
        k=k+PartMPIInsert%nPartsRecv(iProc)
      END IF
    END DO
    DEALLOCATE( PartMPIInsert%nPartsRecv )
    DEALLOCATE( PartMPIInsert%RecvRequest )
    DO iProc=0,PartMPI%InitGroup(InitGroup)%nProcs-1
      CALL MPI_WAIT(PartMPIInsert%SendRequest(iProc,1),msg_status(:),IERROR)
      IF (PartMPIInsert%nPartsSend(iProc).GT.0) THEN
        CALL MPI_WAIT(PartMPIInsert%SendRequest(iProc,2),msg_status(:),IERROR)
        DEALLOCATE( PartMPIInsert%send_message(iProc)%content )
      END IF
    END DO
    DEALLOCATE( PartMPIInsert%nPartsSend )
    DEALLOCATE( PartMPIInsert%send_message )
    DEALLOCATE( PartMPIInsert%SendRequest )
    chunkSize=k
    nChunks=1
  END IF
#endif
   ! each process checks which particle can be matched to its elements, counting the elements inside (local particles)
!   WRITE(*,*)'locating',chunkSize,'*',nChunks,' particles...'
!   WRITE(UNIT=debugFileName,FMT='(A,I2.2)')'prtcls_',PartMPI%iProc
!   OPEN(UNIT=130+PartMPI%iProc,FILE=debugFileName)
!   DO i=1,chunkSize*nChunks
!      WRITE(130+PartMPI%iProc,'(3(ES15.8))')particle_positions(i*3-2:i*3)
!   END DO
!   CLOSE(130+PartMPI%iProc)

#ifdef MPI
  ! in order to remove duplicated particles
  IF(nChunksTemp.EQ.1) THEN
    ALLOCATE(PartFoundInProc(1:2,1:ChunkSize),STAT=ALLOCSTAT)
      IF (ALLOCSTAT.NE.0) THEN
        CALL abort(&
__STAMP__,&
"abort: Error during emission in PartFoundInProc allocation")
      END IF
    PartFoundInProc=-1
  END IF
#endif /*MPI*/

  mySumOfMatchedParticles=0
  ParticleIndexNbr = 1
  DO i=1,chunkSize*nChunks
    IF ((i.EQ.1).OR.PDM%ParticleInside(ParticleIndexNbr)) THEN
       ParticleIndexNbr = PDM%nextFreePosition(mySumOfMatchedParticles + 1 &
                                             + PDM%CurrentNextFreePosition)
    END IF
    IF (ParticleIndexNbr .ne. 0) THEN
       PartState(ParticleIndexNbr,1:DimSend) = particle_positions(DimSend*(i-1)+1:DimSend*(i-1)+DimSend)
       PDM%ParticleInside(ParticleIndexNbr) = .TRUE.
       IF(DoRefMapping.OR.TriaTracking)THEN
         CALL SingleParticleToExactElement(ParticleIndexNbr,doHALO=.FALSE.,InitFix=.TRUE.,doRelocate=.FALSE.)
       ELSE
         CALL SingleParticleToExactElementNoMap(ParticleIndexNbr,doHALO=.FALSE.,doRelocate=.FALSE.)
       END IF
       IF (PDM%ParticleInside(ParticleIndexNbr)) THEN
          mySumOfMatchedParticles = mySumOfMatchedParticles + 1
#ifdef MPI
          IF(nChunksTemp.EQ.1) THEN
            ! mark elements with Rank and local found particle index
            PartFoundInProc(1,i)=MyRank
            PartFoundInProc(2,i)=mySumOfMatchedParticles
          END IF ! nChunks.EQ.1
#endif /*MPI*/
       ELSE
          PDM%ParticleInside(ParticleIndexNbr) = .FALSE.
       END IF
       IF (PDM%ParticleInside(ParticleIndexNbr)) THEN
         PDM%IsNewPart(ParticleIndexNbr)=.TRUE.
         PDM%dtFracPush(ParticleIndexNbr) = .FALSE.
       END IF
    ELSE
      CALL abort(&
__STAMP__&
,'ERROR in SetParticlePosition:ParticleIndexNbr.EQ.0 - maximum nbr of particles reached?')
    END IF
  END DO
 
! we want always warnings to know if the emission has failed. if a timedisc does not require this, this
! timedisc has to be handled separately
#ifdef MPI
  mySumOfRemovedParticles=0
  IF(nChunksTemp.EQ.1) THEN
    CALL MPI_ALLREDUCE(MPI_IN_PLACE,PartfoundInProc(1,:), ChunkSize, MPI_INTEGER, MPI_MAX &
                                                        , PartMPI%InitGroup(InitGroup)%COMM, IERROR)
    ! loop over all particles and check, if particle is found in my proc
    ! proc with LARGES id gets the particle, all other procs remove the duplicated
    ! particle from their list
    DO i=1,chunkSize
      IF(PartFoundInProc(2,i).GT.-1)THEN ! particle has been previously found by MyRank
        IF(PartFoundInProc(1,i).NE.MyRank)THEN ! particle should not be found by MyRank 
          !ParticleIndexNbr = PartFoundInProc(2,i)
          ParticleIndexNbr = PDM%nextFreePosition(PartFoundInProc(2,i) + PDM%CurrentNextFreePosition)
          IF(.NOT.PDM%ParticleInside(ParticleIndexNbr)) WRITE(UNIT_stdOut,*) ' Error in emission in parallel!!'
          PDM%ParticleInside(ParticleIndexNbr) = .FALSE.
          PDM%IsNewPart(ParticleIndexNbr)=.FALSE.
          ! correct number of found particles
          mySumOfRemovedParticles = mySumOfRemovedParticles +1
          ! set update next free position to zero for removed particle
          PDM%nextFreePosition(PartFoundInProc(2,i) + PDM%CurrentNextFreePosition) = 0
          !mySumOfMatchedParticles = mySumOfMatchedParticles -1
        END IF 
      END IF
    END DO ! i=1,chunkSize
    DEALLOCATE(PartFoundInProc)
    mySumOfMatchedParticles = mySumOfMatchedParticles - mySumOfRemovedParticles
  END IF

  ! check the sum of the matched particles: did each particle find its "home"-CPU?
  CALL MPI_ALLREDUCE(mySumOfMatchedParticles, sumOfMatchedParticles, 1, MPI_INTEGER, MPI_SUM &
                                           , PartMPI%InitGroup(InitGroup)%COMM, IERROR)
#else
  ! im seriellen Fall kommen alle Partikel auf einen CPU,
  ! daher ist PIC%maxParticleNumber die harte Grenze
  sumOfMatchedParticles = mySumOfMatchedParticles
#endif

#ifdef MPI
  IF(PartMPI%InitGroup(InitGroup)%MPIRoot) THEN
#endif
    IF( Species(FractNbr)%Init(iInit)%VirtPreInsert .AND. (Species(FractNbr)%Init(iInit)%PartDensity .GT. 0.) ) THEN
      IF ((nbrOfParticle .NE. sumOfMatchedParticles).AND.OutputVpiWarnings) THEN
        SWRITE(UNIT_StdOut,'(A)')'WARNING in ParticleEmission_parallel:'
        SWRITE(UNIT_StdOut,'(A,I0)')'Fraction Nbr: ', FractNbr
        SWRITE(UNIT_StdOut,'(I0,A)') sumOfMatchedParticles, ' particles reached the domain when'
        SWRITE(UNIT_StdOut,'(I0,A)') NbrOfParticle, '(+1) velocities were calculated with vpi+PartDens'
      END IF
    ELSE
      ! add number of matching error to particle emission to fit 
      ! number of added particles
      Species(FractNbr)%Init(iInit)%InsertedParticleMisMatch = nbrOfParticle  - sumOfMatchedParticles
      IF (nbrOfParticle .GT. sumOfMatchedParticles) THEN
        SWRITE(UNIT_StdOut,'(A)')'WARNING in ParticleEmission_parallel:'
        SWRITE(UNIT_StdOut,'(A,I0)')'Fraction Nbr: ', FractNbr
        SWRITE(UNIT_StdOut,'(A,I0,A)')'matched only ', sumOfMatchedParticles, ' particles'
        SWRITE(UNIT_StdOut,'(A,I0,A)')'when ', NbrOfParticle, ' particles were required!'
      ELSE IF (nbrOfParticle .LT. sumOfMatchedParticles) THEN
#if (PP_TimeDiscMethod==1000) || (PP_TimeDiscMethod==1001)
       IF(DoDisplayIter)THEN
         IF(MOD(iter,IterDisplayStep).EQ.0) THEN
#endif
            SWRITE(UNIT_StdOut,'(A)')'ERROR in ParticleEmission_parallel:'
            SWRITE(UNIT_StdOut,'(A,I0)')'Fraction Nbr: ', FractNbr
            SWRITE(UNIT_StdOut,'(A,I0,A)')'matched ', sumOfMatchedParticles, ' particles'
            SWRITE(UNIT_StdOut,'(A,I0,A)')'when ', NbrOfParticle, ' particles were required!'
#if (PP_TimeDiscMethod==1000) || (PP_TimeDiscMethod==1001)
         END IF
       END IF
#endif
#if (PP_TimeDiscMethod!=1000) && (PP_TimeDiscMethod!=1001)
!        CALL abort(__STAMP__&
!          'selected timedisk does not allow num of inserted part .gt. required')
#endif
      ELSE IF (nbrOfParticle .EQ. sumOfMatchedParticles) THEN
      !  WRITE(UNIT_stdOut,'(A,I0)')'Fraction Nbr: ', FractNbr
      !  WRITE(UNIT_stdOut,'(A,I0,A)')'ParticleEmission_parallel: matched all (',NbrOfParticle,') particles!'
      END IF
    END IF
#ifdef MPI
  END IF ! PartMPI%iProc.EQ.0
#endif

  ! Return the *local* NbrOfParticle so that the following Routines only fill in
  ! the values for the local particles
#ifdef MPI
  NbrOfParticle = mySumOfMatchedParticles + mySumOfRemovedParticles
#else
  NbrOfParticle = mySumOfMatchedParticles
#endif

  DEALLOCATE( particle_positions, STAT=allocStat )
  IF (allocStat .NE. 0) THEN
    CALL abort(&
__STAMP__&
,'ERROR in ParticleEmission_parallel: cannot deallocate particle_positions!')
  END IF
#ifdef MPI
END IF ! mode 1/2
#endif

END SUBROUTINE SetParticlePosition

SUBROUTINE SetParticleVelocity(FractNbr,iInit,NbrOfParticle,init_or_sf)
!===================================================================================================================================
! Determine the particle velocity of each inserted particle
!===================================================================================================================================
! MODULES
USE MOD_Globals
USE MOD_Globals_Vars,           ONLY : BoltzmannConst
USE MOD_Particle_Vars
USE MOD_Timedisc_Vars,         ONLY:dt
USE MOD_Equation_Vars,         ONLY:c,c2
USE MOD_PICInterpolation_vars, ONLY:externalField
USE MOD_PIC_Vars
!USE Ziggurat,          ONLY : rnor
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
INTEGER,INTENT(IN)               :: FractNbr,iInit,init_or_sf                                                  
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
INTEGER,INTENT(INOUT)            :: NbrOfParticle            
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
INTEGER                          :: i,j,PositionNbr        
REAL                             :: Radius(3), n_vec(3), tan_vec(3), Velo1, Angle, Velo2, f
REAL                             :: Vec3D(3), RandVal(3), Vec1D
REAL                             :: II(3,3),JJ(3,3),NN(3,3)
INTEGER                          :: distnum,Rotation
REAL                             :: r1,r2,x_1,x_2,y_1,y_2,a,b,e,g,x_01,x_02,y_01,y_02, RandVal1
REAL                             :: Velosq, v_sum(3), v2_sum, maxwellfac
LOGICAL                          :: Is_ElemMacro
REAL                             :: sigma(3), ftl, PartVelo 
REAL                             :: RandN_save
LOGICAL                          :: RandN_in_Mem
CHARACTER(30)                    :: velocityDistribution             ! specifying keyword for velocity distribution
REAL                             :: RadiusIC                         ! Radius for IC circle
REAL                             :: RadiusICGyro                     ! Radius for Gyrotron gyro radius
REAL                             :: NormalIC(3)                      ! Normal / Orientation of circle
REAL                             :: BasePointIC(3)                   ! base point for IC cuboid and IC sphere
REAL                             :: VeloIC                           ! velocity for inital Data
REAL                             :: VeloIC2                          ! square of velocity for inital Data
REAL                             :: VeloVecIC(3)                     ! normalized velocity vector
REAL                             :: WeibelVeloPar                    ! Parrallel velocity component for Weibel
REAL                             :: WeibelVeloPer                    ! Perpendicular velocity component for Weibel
REAL                             :: OneDTwoStreamVelo                ! Stream Velocity for the Two Stream Instability
REAL                             :: OneDTwoStreamTransRatio          ! Ratio between perpendicular and parallel velocity
REAL                             :: Alpha                            ! WaveNumber for sin-deviation initiation.
REAL                             :: MWTemperatureIC                  ! Temperature for Maxwell Distribution
REAL                             :: MJRatio(3)                       ! momentum to temperature ratio
! Maxwell-Juettner
REAL                             :: eps, anta, BesselK2,  gamm_k, max_val, qq, u_max, value, velabs, xixi, f_gamm
REAL                             :: VelocitySpread                         ! widening of init velocity
REAL                             :: vMag2                                  ! magnitude of velocity
!===================================================================================================================================

IF(NbrOfParticle.lt.1) RETURN
   IF(NbrOfParticle.gt.PDM%maxParticleNumber)THEN
     CALL abort(&
__STAMP__&
,'NbrOfParticle > PIC%maxParticleNumber!')
   END IF
RandN_in_Mem=.FALSE.
Is_ElemMacro = .FALSE.
SELECT CASE (init_or_sf)
CASE(1) !iInit
  IF (Species(FractNbr)%Init(iInit)%ElemVelocityICFileID.GT.0 .OR. Species(FractNbr)%Init(iInit)%ElemTemperatureFileID.GT.0) THEN
    Is_ElemMacro = .TRUE.
  END IF
  IF(Species(FractNbr)%Init(iInit)%VirtPreInsert) RETURN !velocities already set in SetParticlePosition!

  velocityDistribution=Species(FractNbr)%Init(iInit)%velocityDistribution
  VeloVecIC=Species(FractNbr)%Init(iInit)%VeloVecIC(1:3)
  VeloIC=Species(FractNbr)%Init(iInit)%VeloIC
  BasePointIC=Species(FractNbr)%Init(iInit)%BasePointIC(1:3)
  NormalIC=Species(FractNbr)%Init(iInit)%NormalIC(1:3)
  RadiusIC=Species(FractNbr)%Init(iInit)%RadiusIC
  Alpha=Species(FractNbr)%Init(iInit)%alpha
  RadiusICGyro=Species(FractNbr)%Init(iInit)%RadiusICGyro
  MWTemperatureIC=Species(FractNbr)%Init(iInit)%MWTemperatureIC
  WeibelVeloPar=Species(FractNbr)%Init(iInit)%WeibelVeloPar
  WeibelVeloPer=Species(FractNbr)%Init(iInit)%WeibelVeloPer
  OneDTwoStreamVelo=Species(FractNbr)%Init(iInit)%OneDTwoStreamVelo
  OneDTwoStreamTransRatio=Species(FractNbr)%Init(iInit)%OneDTwoStreamTransRatio
  MJRatio(1)=Species(FractNbr)%Init(iInit)%MJxRatio
  MJRatio(2)=Species(FractNbr)%Init(iInit)%MJyRatio
  MJRatio(3)=Species(FractNbr)%Init(iInit)%MJzRatio
  SELECT CASE(TRIM(velocityDistribution))
  CASE('tangential_constant')
    Rotation       = Species(FractNbr)%Init(iInit)%Rotation
    VelocitySpread = Species(FractNbr)%Init(iInit)%VelocitySpread
    IF(VelocitySpread.GT.0)THEN
      IF(Species(FractNbr)%Init(iInit)%VelocitySpreadMethod.EQ.0)THEN
        ! sigma of normal Distribution, Kostas proposal
        VelocitySpread = VelocitySpread * VeloIC   !/(2.*SQRT(2.*LOG(10.)))
      ELSE IF(Species(FractNbr)%Init(iInit)%VelocitySpreadMethod.EQ.1)THEN
        ! sigma is defined by changing the width of the distribution function at 10% of its maxima
        ! the input value is the spread in percent, hence, 5% => v = v +- 0.05*v at 10% of maximum value
        ! width of the velocity spread, deltaV:
        VelocitySpread = 2.0*VelocitySpread * VeloIC
        ! computing the corresponding sigma 
        VelocitySpread = VelocitySpread / (2.*SQRT(2.*LOG(10.)))
      ELSE
     CALL abort(&
__STAMP__&
,' This method for the velocity spread is not implemented.')
      END IF
      IF(alpha.GT.0) THEN 
        vMag2 = (1.0+1./(alpha*alpha)) * VeloIC*VeloIC
      ELSE
        vMag2 = VeloIC*VeloIC
      END IF
    END IF
    VeloIC2        = VeloIC*VeloIC
  END SELECT
CASE(2) !SurfaceFlux
  IF (TRIM(Species(FractNbr)%Surfaceflux(iInit)%velocityDistribution).EQ.'constant') THEN
    velocityDistribution=Species(FractNbr)%Surfaceflux(iInit)%velocityDistribution
  ELSE
    CALL abort(&
__STAMP__&
,'only constant velo-distri implemented in SetParticleVelocity for surfaceflux!') !other distris in SetSurfacefluxVelocities!!!
  END IF
  VeloVecIC=Species(FractNbr)%Surfaceflux(iInit)%VeloVecIC(1:3)
  VeloIC=Species(FractNbr)%Surfaceflux(iInit)%VeloIC
  MWTemperatureIC=Species(FractNbr)%Surfaceflux(iInit)%MWTemperatureIC

CASE DEFAULT
  CALL abort(&
__STAMP__&
,'neither iInit nor Surfaceflux defined as reference!')
END SELECT

SELECT CASE(TRIM(velocityDistribution))
CASE('random')
  i = 1
  DO WHILE (i .le. NbrOfParticle)
    PositionNbr = PDM%nextFreePosition(i+PDM%CurrentNextFreePosition)
    IF (PositionNbr .ne. 0) THEN
      CALL RANDOM_NUMBER(RandVal)
      RandVal(:) = RandVal(:) - 0.5
      RandVal(:) = RandVal(:)/SQRT(RandVal(1)**2+RandVal(2)**2+RandVal(3)**2)
      PartState(PositionNbr,4:6) = RandVal(1:3) * VeloIC
    END IF
    i = i + 1
  END DO
!  CASE('EOC_Test')
!     ! for leapfrog EOC test velo has to be set half dt before ICPos.
!     Radius = Species(1)%BasePointIC 
!     IF (Species(1)%BasePointIC(1) > 0. ) THEN
!       n_vec = (/0.,0.,-1./) 
!       Angle = 0.
!       Angle = Angle - PIC%GyrationFrequency * dt * 0.5
!       Radius(1) = cos(Angle)
!       Radius(2) = sin(Angle)   
!     ELSEIF (Species(1)%BasePointIC(3) > 0. ) THEN  
!       n_vec = (/0.,1.,0./) 
!       Angle = PI
!       Angle = Angle - PIC%GyrationFrequency * dt * 0.5
!       Radius(1) = sin(Angle)
!       Radius(3) = cos(Angle)   
!     END IF
!     tan_vec(1) = Radius(2)*n_vec(3) - Radius(3)*n_vec(2)
!     tan_vec(2) = Radius(3)*n_vec(1) - Radius(1)*n_vec(3)
!     tan_vec(3) = Radius(1)*n_vec(2) - Radius(2)*n_vec(1)
!     PartState(1,4:6) = tan_vec(1:3) * Species(1)%VeloIC
CASE('constant')
  i = 1
  DO WHILE (i .le. NbrOfParticle)
     PositionNbr = PDM%nextFreePosition(i+PDM%CurrentNextFreePosition)
     IF (PositionNbr .ne. 0) THEN
        IF (Is_ElemMacro) THEN
          IF (Species(FractNbr)%Init(iInit)%ElemVelocityICFileID.GT.0) THEN
            PartState(PositionNbr,4:6) = Species(FractNbr)%Init(iInit)%ElemVelocityIC(1:3,PEM%Element(PositionNbr))
          ELSE
            PartState(PositionNbr,4:6) = VeloVecIC(1:3) * VeloIC
          END IF
        ELSE
          PartState(PositionNbr,4:6) = VeloVecIC(1:3) * VeloIC
        END IF
     END IF
     i = i + 1
  END DO
CASE('radial_constant')
  i = 1
  DO WHILE (i .le. NbrOfParticle)
     PositionNbr = PDM%nextFreePosition(i+PDM%CurrentNextFreePosition)
     IF (PositionNbr .ne. 0) THEN
        Radius(1:3) = PartState(PositionNbr,1:3) - BasePointIC(1:3)
        !  Unity radius
        !Radius(1:3) = Radius(1:3) / RadiusIC
        Radius(1:3) = Radius(1:3) / SQRT(Radius(1)**2+Radius(2)**2+Radius(3)**2) 
        PartState(PositionNbr,4:6) = Radius(1:3) * VeloIC
     END IF
     i = i + 1
  END DO
CASE('tangential_constant')
  i = 1
  DO WHILE (i .le. NbrOfParticle)
     PositionNbr = PDM%nextFreePosition(i+PDM%CurrentNextFreePosition)
     IF (PositionNbr .ne. 0) THEN
        Radius(1:3) = PartState(PositionNbr,1:3) - BasePointIC(1:3)
        !  Normal Vector of circle
        n_vec(1:3) = NormalIC(1:3)
        ! If we're doing Leapfrog, then use velocities from half-timestep before
        IF (ParticlePushMethod.EQ.'boris_leap_frog_scheme') THEN
          Angle = 0.5 * dt * VeloIC / RadiusIC ! 0.5*dt*(v/r)
          JJ(1,1:3) = (/   0.,-n_vec(3), n_vec(2)/)
          JJ(2,1:3) = (/ n_vec(3),   0.,-n_vec(1)/)
          JJ(3,1:3) = (/-n_vec(2), n_vec(1),   0./)
          II(1,1:3) = (/1.,0.,0./)
          II(2,1:3) = (/0.,1.,0./)
          II(3,1:3) = (/0.,0.,1./)
          forall(j=1:3) NN(:,j) = n_vec(:)*n_vec(j)
          Radius = MATMUL( NN+cos(Angle)*(II-NN)+sin(Angle)*JJ , Radius )
        END IF
        !  Unity radius
        Radius(1:3) = Radius(1:3) / SQRT(Radius(1)**2+Radius(2)**2+Radius(3)**2)
        !  Vector Product rxn
        tan_vec(1) = Radius(2)*n_vec(3) - Radius(3)*n_vec(2)
        tan_vec(2) = Radius(3)*n_vec(1) - Radius(1)*n_vec(3)
        tan_vec(3) = Radius(1)*n_vec(2) - Radius(2)*n_vec(1)

        IF(VelocitySpread.GT.0.)THEN
          IF (RandN_in_Mem) THEN !reusing second RandN form previous polar method
            Vec1D = RandN_save
            RandN_in_Mem=.FALSE.
          ELSE
            CALL RANDOM_NUMBER(RandVal)
            Velo1 = 2.0*RandVal(1)-1.0
            Velo2 = 2.0*RandVal(2)-1.0
            Velosq= Velo1**2+Velo2**2
            DO WHILE ((Velosq.LE.0).OR.(Velosq.GE.1))
              CALL RANDOM_NUMBER(RandVal)
              Velo1 = 2.0*RandVal(1)-1.0
              Velo2 = 2.0*RandVal(2)-1.0
              Velosq= Velo1**2+Velo2**2
            END DO
            Vec1D = Velo1*SQRT(-2*LOG(Velosq)/Velosq)
            RandN_save = Velo2*SQRT(-2*LOG(Velosq)/Velosq)
            RandN_in_Mem=.TRUE.
          END IF
          ! velocity spread of tangential velocity
          IF(Rotation.EQ.1)THEN
            Vec3D  = tan_vec(1:3) * (VeloIC+Vec1D*VelocitySpread) 
          ELSE
            Vec3D = -tan_vec(1:3) * (VeloIC+Vec1D*VelocitySpread)
          END IF
          ! compute axial velocity
          Vec1D = vMag2  - DOT_PRODUCT(Vec3D,Vec3D)
          IF(Vec1D.LT.0) CALL abort(&
__STAMP__&
,' Error in set velocity!',PositionNbr)
          Vec1D=SQRT(Vec1D)
          PartState(PositionNbr,4:6) = Vec3D+n_vec(1:3) * Vec1D
        ELSE ! no velocity spread
          ! If Gyrotron resonator: Add velocity in normal direction!
          IF (Alpha .gt. 0.) THEN 
            n_vec = n_vec * ( 1 / Alpha )
          ELSE 
            n_vec = 0
          END IF
          !  And finally the velocities
          IF(Rotation.EQ.1)THEN
            PartState(PositionNbr,4:6) = tan_vec(1:3) * VeloIC + n_vec(1:3) * VeloIC
          ELSE
            PartState(PositionNbr,4:6) = -tan_vec(1:3) * VeloIC + n_vec(1:3) * VeloIC
          END IF
        END IF 
     END IF
     i = i + 1
  END DO

CASE('gyrotron_circle')
  i = 1
  IF (externalField(6).NE.0) THEN
    PIC%GyroVecDirSIGN = -externalField(6)/(ABS(externalField(6)))
  ELSE
    PIC%GyroVecDirSIGN = -1
  END IF
  DO WHILE (i .le. NbrOfParticle)
     PositionNbr = PDM%nextFreePosition(i+PDM%CurrentNextFreePosition)
     IF (PositionNbr .ne. 0) THEN
     !! Position of particle on gyro circle changed in SetParticlePosition.F90: Problem
     !! We don't have the radius-vector any more. Thus transport the radius vector from there to here.
     ! Or do Alternative way: Hack the radius by intersecting two circles (big IC and small gyro circle)
       r1 = RadiusIC
       r2 = RadiusICGyro
       x_1 = 0.
       y_1 = 0.
       x_2 = PartState(PositionNbr,1)
       y_2 = PartState(PositionNbr,2)
       IF (x_1 .eq. x_2) THEN
         a = (x_1 - x_2)/(y_2-y_1)
         b = ((r1**2-r2**2)-(x_1**2-x_2**2)-(y_1**2-y_2**2))&
             & /(2.*y_2-2.*y_1)
         e = (a**2+1.)
         f = (2.*a*(b-y_1))-2.*x_1
         g = (b-y_1)**2-r1**2+x_1**2
         ! intersection points
         x_01 = (-f + SQRT(ABS(f**2 - 4. * e * g)))/(2.*e) ! the term in SQRT can be -0.0 , therefore the ABS
         x_02 = (-f - SQRT(ABS(f**2 - 4. * e * g)))/(2.*e) ! the term in SQRT can be -0.0 , therefore the ABS
         y_01 = x_01 * a + b
         y_02 = x_02 * a + b
       ELSE
         a = (y_1 - y_2)/(x_2-x_1)
         b = ((r1**2 - r2**2)-(x_1**2-x_2**2)-(y_1**2-y_2**2))&
              & /(2.*x_2 - 2. * x_1)
         e = (a**2 + 1.)
         f = 2. * a * (b - x_1) -2 *y_1
         g = (b-x_1)**2 - r1**2 + y_1**2
         y_01 = (-f + SQRT(ABS(f**2 - 4. * e * g)))/(2.*e) ! the term in SQRT can be -0.0 , therefore the ABS
         y_02 = (-f - SQRT(ABS(f**2 - 4. * e * g)))/(2.*e) ! the term in SQRT can be -0.0 , therefore the ABS
         x_01 = y_01 * a + b
         x_02 = y_02 * a + b
       END IF
       CALL RANDOM_NUMBER(RandVal1)
       IF (RandVal1 .ge. 0.5) THEN
         Radius(1) = PartState(PositionNbr,1) - x_01 
         Radius(2) = PartState(PositionNbr,2) - y_01 
       ELSE
         Radius(1) = PartState(PositionNbr,1) - x_02
         Radius(2) = PartState(PositionNbr,2) - y_02
       END IF     
     
        Radius(3) = 0.
        !Check if Radius has correct length
        IF ((SQRT(Radius(1)**2+Radius(2)**2)-r1).ge.1E-15) THEN
          IPWRITE(UNIT_stdOut,*)"Error in setparticle velocity, gyrotron circle. &
                    & Radius too big after intersection."
        END IF
        !  Normal Vector of circle
        n_vec(1:3) = NormalIC(1:3)

        ! If we're doing Leapfrog, then use velocities from half-timestep before. This only applies in 
        ! x- and y-direction. z has allways same velo. 
!           IF (ParticlePushMethod.EQ.'boris_leap_frog_scheme') THEN
!             ! get angle of part on gyrocircle
!             Angle = ACOS(Radius(1)/Species(1)%RadiusICGyro)
!             IF (Radius(2).LE.0) THEN
!               Angle = 2*PI-Angle
!             END IF
!             ! shift position angle half dt back in time (as particle moves clockwise,
!             ! we add dalpha in ccw direction)
!             Angle = Angle + PIC%GyrationFrequency * dt * 0.5 * PIC%GyroVecDirSIGN  
!             Radius(1) = cos(Angle)
!             Radius(2) = sin(Angle)                 
!           END IF
           !  Unity radius
           Radius(1:3) = Radius(1:3) / SQRT(Radius(1)**2+Radius(2)**2+Radius(3)**2)
           !  Vector Product rxn
           tan_vec(1) = Radius(2)*n_vec(3)*PIC%GyroVecDirSIGN - Radius(3)*n_vec(2)
           tan_vec(2) = Radius(3)*n_vec(1) - Radius(1)*n_vec(3) *PIC%GyroVecDirSIGN
           tan_vec(3) = Radius(1)*n_vec(2) - Radius(2)*n_vec(1)
           ! If Gyrotron resonator: Add velocity in normal direction!
           IF (Alpha .gt. 0.) THEN 
             n_vec = n_vec * ( 1. / Alpha )
           ELSE 
             n_vec = 0.
           END IF
           !  And finally the velocities
           PartState(PositionNbr,4:6) = (tan_vec(1:3) + n_vec(1:3)) * VeloIC
           IF (ABS(SQRT(PartState(PositionNbr,4)*PartState(PositionNbr,4) &
                      + PartState(PositionNbr,5)*PartState(PositionNbr,5))&
                      - VeloIC) .GT. 10.) THEN
             SWRITE(*,'(A,3(E21.14,X))') 'Velocity=', PartState(PositionNbr,4:6)
             CALL abort(&
__STAMP__&
,'ERROR in gyrotron_circle spaceIC!',PositionNbr)
           END If
           IF (PartState(PositionNbr,4).NE.PartState(PositionNbr,4) .OR. &
               PartState(PositionNbr,5).NE.PartState(PositionNbr,5) .OR. &
               PartState(PositionNbr,6).NE.PartState(PositionNbr,6)     ) THEN
             SWRITE(*,'(A,3(E21.14,X))') 'WARNING:! NaN: Velocity=', PartState(PositionNbr,4:6)
           END If
        END IF
        i = i + 1
     END DO
CASE('maxwell_lpn')
  DO i = 1,NbrOfParticle
    PositionNbr = PDM%nextFreePosition(i+PDM%CurrentNextFreePosition)
    IF (PositionNbr .NE. 0) THEN
       IF (Is_ElemMacro) THEN
         CALL CalcVelocity_maxwell_lpn(FractNbr, Vec3D, iInit=iInit, Element=PEM%Element(PositionNbr))
       ELSE
         CALL CalcVelocity_maxwell_lpn(FractNbr, Vec3D, iInit=iInit)
       END IF
       PartState(PositionNbr,4:6) = Vec3D(1:3)
    END IF
  END DO
CASE('emmert')
  DO i = 1,NbrOfParticle
    PositionNbr = PDM%nextFreePosition(i+PDM%CurrentNextFreePosition)
    IF (PositionNbr .NE. 0) THEN
      CALL CalcVelocity_emmert(FractNbr, iInit, Vec3D)
    END IF
    PartState(PositionNbr,4:6) = Vec3D(1:3)
  END DO
CASE('maxwell')
  v_sum(1:3) = 0.0
  v2_sum = 0.0
  
  i = 1
  DO WHILE (i .le. NbrOfParticle)
     PositionNbr = PDM%nextFreePosition(i+PDM%CurrentNextFreePosition)
     IF (PositionNbr .ne. 0) THEN
        DO distnum = 1, 3
!          IF (.NOT.DoZigguratSampling) THEN !polar method
            IF (RandN_in_Mem) THEN !reusing second RandN form previous polar method
              Vec3D(distnum) = RandN_save
              RandN_in_Mem=.FALSE.
            ELSE
              CALL RANDOM_NUMBER(RandVal)
              Velo1 = 2.0*RandVal(1)-1.0
              Velo2 = 2.0*RandVal(2)-1.0
              Velosq= Velo1**2+Velo2**2
              DO WHILE ((Velosq.LE.0).OR.(Velosq.GE.1))
                CALL RANDOM_NUMBER(RandVal)
                Velo1 = 2.0*RandVal(1)-1.0
                Velo2 = 2.0*RandVal(2)-1.0
                Velosq= Velo1**2+Velo2**2
              END DO
              Vec3D(distnum) = Velo1*SQRT(-2*LOG(Velosq)/Velosq)
              RandN_save = Velo2*SQRT(-2*LOG(Velosq)/Velosq)
              RandN_in_Mem=.TRUE.
            END IF
!          ELSE !ziggurat method
!            Vec3D(distnum)=rnor()
!          END IF
        END DO
        PartState(PositionNbr,4:6) = Vec3D(1:3)
        v_sum(1:3) = v_sum(1:3) + Vec3D(1:3)
        v2_sum = v2_sum + Vec3D(1)**2+Vec3D(2)**2+Vec3D(3)**2
     END IF
     i = i + 1
  END DO
  v_sum(1:3) = v_sum(1:3) / NbrOfParticle
  v2_sum = v2_sum / NbrOfParticle
  maxwellfac = SQRT(3. * BoltzmannConst * MWTemperatureIC / &              ! velocity of maximum
                 (Species(FractNbr)%MassIC*v2_sum))

  i = 1
  DO WHILE (i .le. NbrOfParticle)
     PositionNbr = PDM%nextFreePosition(i+PDM%CurrentNextFreePosition)
     IF (PositionNbr .ne. 0) THEN
       PartState(PositionNbr,4:6) = (PartState(PositionNbr,4:6) - v_sum(1:3)) * maxwellfac &
                                    + VeloIC *VeloVecIC(1:3)        
     END IF
     i = i + 1
  END DO
  
CASE('maxwell-juettner')
  xixi = Species(FractNbr)%MassIC*c2/ &
         (BoltzmannConst*MWTemperatureIC)
  BesselK2 = BessK(2,xixi)
  
  ! Find initial value for Newton Algorithm
  IF (xixi .LT. 4.d0) THEN
    gamm_k = 5.d0 * BoltzmannConst*MWTemperatureIC/ &
                    (Species(FractNbr)%MassIC*c2)
  ELSE
    gamm_k = 1.d0 + BoltzmannConst*MWTemperatureIC/ &
                    (Species(FractNbr)%MassIC*c2)
  END IF  
  f_gamm = DEVI(Species(FractNbr)%MassIC, MWTemperatureIC, gamm_k)
  
  ! Newton Algorithm to find maximum value of distribution function
  ! (valid for both the relativistic and quasi relativistic distribution)
  i = 0
  eps=1e-8
  DO WHILE (abs(f_gamm) .GT. eps )
    i = i+1
    gamm_k = gamm_k - f_gamm/(xixi*(3._8*gamm_k**2._8-1._8)-10._8*gamm_k)
    f_gamm = DEVI(Species(FractNbr)%MassIC, MWTemperatureIC, gamm_k)
    IF(i.EQ.101) &
      CALL abort(&
__STAMP__&
,' Newton Algorithm to find maximum value of Maxwell-Juettner distribution has not been successfull!')
  END DO
  
  u_max = sqrt(1.d0-1.d0/(gamm_k*gamm_k))*c
  IF (xixi .LT. 692.5_8) THEN                  ! due to numerical precision
        max_val = SYNGE(u_max, MWTemperatureIC, &
                              Species(FractNbr)%MassIC, BesselK2)
      ELSE 
        max_val = QUASIREL(u_max, MWTemperatureIC, &
                                 Species(FractNbr)%MassIC)
      END IF
  
  DO i = 1,NbrOfParticle
    PositionNbr = PDM%nextFreePosition(i+PDM%CurrentNextFreePosition)
    anta  = 1._8
    value = 0._8
    
    ! acception rejection method for velocity's absolute value
    DO WHILE (anta .GT. value)
      CALL RANDOM_NUMBER(velabs)
      CALL RANDOM_NUMBER(anta)
      velabs = velabs*c
      anta = anta*max_val
      IF (xixi .LT. 692.5_8) THEN
        value = SYNGE(velabs, MWTemperatureIC, &
                              Species(FractNbr)%MassIC, BesselK2)
      ELSE 
        value = QUASIREL(velabs, MWTemperatureIC, &
                                 Species(FractNbr)%MassIC)
      END IF
    END DO
    
    ! polar method for velocity's x&y direction
    ! (required to generate elliptical random distribution)
    qq = 2._8
    DO WHILE ((qq .GT. 1._8) .OR. (qq .EQ. 0._8))
      CALL RANDOM_NUMBER(RandVal)
      RandVal = 2._8*RandVal-1._8
      qq = RandVal(1)*RandVal(1) + RandVal(2)*RandVal(2)
    END DO
    qq = sqrt(-2._8*log(qq)/qq)
    Vec3D(1) = RandVal(1)*qq*MJRatio(1)
    Vec3D(2) = RandVal(2)*qq*MJRatio(2)
    
    ! polar method for velocity's z direction
    qq = 2._8
    DO WHILE ((qq .GT. 1._8) .OR. (qq .EQ. 0._8))
      CALL RANDOM_NUMBER(RandVal)
      RandVal(:) = 2*RandVal(:)-1._8
      qq = RandVal(1)*RandVal(1) + RandVal(2)*RandVal(2)
    END DO
    qq = sqrt(-2._8*log(qq)/qq)
    Vec3D(3) = RandVal(1)*qq*MJRatio(3)
    
    Velosq  = sqrt(Vec3D(1)*Vec3D(1)+Vec3D(2)*Vec3D(2)+Vec3D(3)*Vec3D(3))
    PartState(PositionNbr,4:6) = velabs/Velosq*Vec3D
  END DO


CASE('weibel')
  v_sum(:)  = 0.0
  sigma(:) = 0.0
  
  DO i = 1,NbrOfParticle
    PositionNbr = PDM%nextFreePosition(i+PDM%CurrentNextFreePosition)
    IF (PositionNbr .NE. 0) THEN
!      IF (.NOT.DoZigguratSampling) THEN !polar method
        Velosq = 2.
        DO WHILE ((Velosq .GT. 1.) .OR. (Velosq .EQ. 0.))
          CALL RANDOM_NUMBER(RandVal)
          RandVal(:) = 2*RandVal(:)-1
          Velosq = RandVal(1)**2 + RandVal(2)**2
        END DO
        Velosq = sqrt(-2*log(Velosq)/Velosq)
        Vec3D(1) = RandVal(1)*Velosq
        Vec3D(2) = RandVal(2)*Velosq
        
        IF (RandN_in_Mem) THEN !reusing second RandN form previous polar method
          Vec3D(3) = RandN_save
          RandN_in_Mem=.FALSE.
        ELSE
          Velosq = 2.
          DO WHILE ((Velosq .GT. 1.) .OR. (Velosq .EQ. 0.))
            CALL RANDOM_NUMBER(RandVal)
            RandVal(:) = 2*RandVal(:)-1
            Velosq = RandVal(1)**2 + RandVal(2)**2
          END DO
          Velosq = sqrt(-2*log(Velosq)/Velosq)
          Vec3D(3) = RandVal(1)*Velosq
          RandN_save = RandVal(2)*Velosq
          RandN_in_Mem=.TRUE.
        END IF
!      ELSE !ziggurat method
!        Vec3D(1) = rnor()
!        Vec3D(2) = rnor()
!        Vec3D(3) = rnor()
!      END IF
      v_sum(:) = v_sum(:)  + Vec3D(:)
      sigma(:)   = sigma(:)    + Vec3D(:)**2
      PartState(PositionNbr,4:6) = Vec3D(1:3)
    END IF
  END DO
!  WRITE(*,*) PartVeloX(1), PartVeloY(1), PartVeloZ(1)

!    IF (NbrOfParticle .GT. 0) THEN
!      v_sum(:)  = 0.0
!      sigma(:) = 0.0

!      DO i=1,NbrOfParticle
!  !       elemNbr = PartToElem%Element(i)
!  v_sum(1)  = v_sum(1)  + PartVeloX(i)
!  v_sum(2)  = v_sum(2)  + PartVeloY(i)
!  v_sum(3)  = v_sum(3)  + PartVeloZ(i)
!  sigma(1) = sigma(1) + PartVeloX(i)**2
!  sigma(2) = sigma(2) + PartVeloY(i)**2
!  sigma(3) = sigma(3) + PartVeloZ(i)**2
!  !       NPart(elemNbr) = NPart(elemNbr) + 1
!      END DO

  
  IF (NbrOfParticle .GT. 1) THEN
    v_sum(:)  = v_sum(:)/NbrOfParticle
    sigma(:) = (NbrOfParticle/(NbrOfParticle-1))*(sigma(:)/NbrOfParticle-v_sum(:)**2)  
        ! Verschiebungssatz der korrigierten Stichprobenkovarianz:
  ELSE                                                                            ! s^2(X)=1/(N-1)(N*E(X^2) - N*E(X)^2)   
    v_sum(:) = 0.
    sigma(:) = 1.
  END IF
                                                                                      
  ftl = 0
  DO i=1,NbrOfParticle
    PositionNbr = PDM%nextFreePosition(i+PDM%CurrentNextFreePosition)
    IF (PositionNbr .NE. 0) THEN
      PartState(PositionNbr,4)   = (PartState(PositionNbr,4)  -v_sum(1)) * &
                                    SQRT(WeibelVeloPar**2/sigma(1)) *c
      PartState(PositionNbr,5:6) = (PartState(PositionNbr,5:6)-v_sum(2:3)) * & 
                                    SQRT(WeibelVeloPer**2/sigma(2:3)) *c
      PartVelo = SQRT(PartState(PositionNbr,4)**2+PartState(PositionNbr,5)**2+PartState(PositionNbr,6)**2)
      
      DO WHILE (PartVelo .GE. c)
        ftl = ftl+1
        IPWRITE(UNIT_stdOut,*) 'Number of Particles FTL:', ftl
!        IF (.NOT.DoZigguratSampling) THEN !polar method
          Velosq = 2.
          DO WHILE ((Velosq .GT. 1.) .OR. (Velosq .EQ. 0.))
            CALL RANDOM_NUMBER(RandVal)
            RandVal(:) = 2*RandVal(:)-1
            Velosq = RandVal(1)**2 + RandVal(2)**2
          END DO
          Velosq = sqrt(-2*log(Velosq)/Velosq)
          Vec3D(1) = RandVal(1)*Velosq
          Vec3D(2) = RandVal(2)*Velosq
          
          IF (RandN_in_Mem) THEN !reusing second RandN form previous polar method
            Vec3D(3) = RandN_save
            RandN_in_Mem=.FALSE.
          ELSE
            Velosq = 2.
            DO WHILE ((Velosq .GT. 1.) .OR. (Velosq .EQ. 0.))
              CALL RANDOM_NUMBER(RandVal)
              RandVal(:) = 2*RandVal(:)-1
              Velosq = RandVal(1)**2 + RandVal(2)**2
            END DO
            Velosq = sqrt(-2*log(Velosq)/Velosq)
            Vec3D(3) = RandVal(1)*Velosq
            RandN_save = RandVal(2)*Velosq
            RandN_in_Mem=.TRUE.
          END IF
!        ELSE !ziggurat method
!          Vec3D(1) = rnor()
!          Vec3D(2) = rnor()
!          Vec3D(3) = rnor()
!        END IF
        
        PartState(PositionNbr,4:6) = Vec3D(1:3)
        
        PartState(PositionNbr,4)   = (Vec3D(1)  -v_sum(1)) * &
            SQRT(WeibelVeloPar**2/sigma(1)) *c
        PartState(PositionNbr,5:6) = (Vec3D(2:3)-v_sum(2:3)) * & 
            SQRT(WeibelVeloPer**2/sigma(2:3)) *c
        PartVelo = SQRT(PartState(PositionNbr,4)**2+PartState(PositionNbr,5)**2+PartState(PositionNbr,6)**2)
      END DO
    END IF
  END DO

CASE('OneD-twostreaminstabilty')
  DO i = 1,NbrOfParticle
    PositionNbr = PDM%nextFreePosition(i+PDM%CurrentNextFreePosition)
    IF (PositionNbr .NE. 0) THEN
      PartState(PositionNbr,4) = OneDTwoStreamVelo
      PartState(PositionNbr,5:6) = OneDTwoStreamTransRatio
!      IF (.NOT.DoZigguratSampling) THEN !polar method
        Velosq = 2.
        DO WHILE ((Velosq .GT. 1.) .OR. (Velosq .EQ. 0.))
          CALL RANDOM_NUMBER(RandVal)
          RandVal(:) = 2*RandVal(:)-1
          Velosq = RandVal(1)**2 + RandVal(2)**2
        END DO
        RandVal(1:2) = RandVal(1:2)*sqrt(-2*log(Velosq)/Velosq)
!      ELSE
!        RandVal(1) = rnor()
!        RandVal(2) = rnor()
!      END IF
      PartState(PositionNbr,5) = RandVal(1)*OneDTwoStreamTransRatio* &
                                                   OneDTwoStreamVelo
      PartState(PositionNbr,6) = RandVal(2)*OneDTwoStreamTransRatio* &
                                                   OneDTwoStreamVelo
    END IF  
  END DO

CASE('IMD') ! read IMD particle velocity from *.chkpt file -> velocity space has already been read when particles position was done
  ! do nothing
CASE DEFAULT
  CALL abort(&
__STAMP__&
,'wrong velo-distri!')

END SELECT

END SUBROUTINE SetParticleVelocity


SUBROUTINE SetParticleChargeAndMass(FractNbr,NbrOfParticle)                                        
!===================================================================================================================================
! And partilces mass and charge
!===================================================================================================================================
! MODULES
USE MOD_Particle_Vars,    ONLY : PDM, PartSpecies
!----------------------------------------------------------------------------------------------------------------------------------
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE                                                                                    
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
INTEGER,INTENT(IN)                       :: FractNbr                                                     
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
INTEGER,INTENT(INOUT)                    :: NbrOfParticle                                                
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
INTEGER                                  :: i,PositionNbr                                                
!===================================================================================================================================

IF(NbrOfParticle.gt.PDM%maxParticleNumber)THEN
  NbrOfParticle = PDM%maxParticleNumber
END IF
i = 1
DO WHILE (i .le. NbrOfParticle)
  PositionNbr = PDM%nextFreePosition(i+PDM%CurrentNextFreePosition)
  IF (PositionNbr .ne. 0) THEN
    PartSpecies(PositionNbr) = FractNbr
  END IF
  i = i + 1
END DO

END SUBROUTINE SetParticleChargeAndMass

SUBROUTINE SetParticleMPF(FractNbr,NbrOfParticle) 
!===================================================================================================================================
! finally, set the MPF
!===================================================================================================================================
! MODULES
USE MOD_Particle_Vars,    ONLY : PDM, PartMPF, Species
!===================================================================================================================================
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE                                          
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
INTEGER,INTENT(IN)                       :: FractNbr    
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
INTEGER,INTENT(INOUT)                    :: NbrOfParticle
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
INTEGER                                  :: i,PositionNbr 
!===================================================================================================================================

IF(NbrOfParticle.gt.PDM%maxParticleNumber)THEN
  NbrOfParticle = PDM%maxParticleNumber
END IF
i = 1
DO WHILE (i .le. NbrOfParticle)
  PositionNbr = PDM%nextFreePosition(i+PDM%CurrentNextFreePosition)
  IF (PositionNbr .ne. 0) THEN
    PartMPF(PositionNbr) = Species(FractNbr)%MacroParticleFactor
  END IF
  i = i + 1
END DO

END SUBROUTINE SetParticleMPF

SUBROUTINE ParticleInsertingCellPressure(iSpec,iInit,NbrOfParticle)
!===================================================================================================================================
! Insert constant cell pressure particles (and remove additionals)
!===================================================================================================================================
! MODULES
USE MOD_Globals
USE MOD_Particle_Vars
USE MOD_Mesh_Vars,              ONLY:NGeo,XCL_NGeo,XiCL_NGeo,wBaryCL_NGeo
USE MOD_Particle_Mesh_Vars,     ONLY:GEO
USE MOD_Particle_Tracking_Vars, ONLY:DoRefMapping,TriaTracking
USE MOD_Particle_Mesh,          ONLY:SingleParticleToExactElement,SingleParticleToExactElementNoMap
USE MOD_Eval_xyz,               ONLY:TensorProductInterpolation
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
INTEGER,INTENT(IN)    :: iSpec, iInit
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
INTEGER,INTENT(OUT)   :: NbrOfParticle
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
INTEGER               :: iElem, Elem, iPart, i, NbrPartsInCell, NbrNewParts
INTEGER               :: ParticleIndexNbr
REAL                  :: PartDiff, PartDiffRest, RandVal, RandVal3(1:3)
INTEGER, ALLOCATABLE  :: PartsInCell(:)
!===================================================================================================================================

NbrOfParticle = 0
DO iElem = 1,Species(iSpec)%Init(iInit)%ConstPress%nElemTotalInside
  Elem = Species(iSpec)%Init(iInit)%ConstPress%ElemTotalInside(iElem)
  ! step 1: count and build array of particles in cell (of current species only)
  ALLOCATE(PartsInCell(1:PEM%pNumber(Elem)))
  NbrPartsInCell = 0
  iPart = PEM%pStart(Elem)   
  DO i = 1, PEM%pNumber(Elem)
    IF (PartSpecies(iPart).EQ.iSpec) THEN
      NbrPartsInCell = NbrPartsInCell + 1
      PartsInCell(NbrPartsInCell) = iPart
    END IF
    iPart = PEM%pNext(iPart)
  END DO
  ! step 2: determine number of particles to insert (or remove)
  PartDiff = Species(iSpec)%Init(iInit)%ParticleEmission * GEO%Volume(Elem) - NbrPartsInCell
  PartDiffRest = PartDiff - INT(PartDiff)
  ! step 3: if PartDiff positive (and PartPressAddParts=T), add particles
  IF(PartPressAddParts.AND.PartDiff.GT.0) THEN
    CALL RANDOM_NUMBER(RandVal)
    IF(PartDiffRest.GT.RandVal) PartDiff = PartDiff + 1.0
    NbrNewParts = INT(PartDiff)
    ! insert particles (positions)
    DO i = 1, NbrNewParts
      ! set random position in -1,1 space
      CALL RANDOM_NUMBER(RandVal3)
      RandVal3 = RandVal3 * 2.0 - 1.0 
      ParticleIndexNbr = PDM%nextFreePosition(PDM%CurrentNextFreePosition + i + NbrOfParticle)
      IF (ParticleIndexNbr.NE.0) THEN
        CALL TensorProductInterpolation(RandVal3,3,NGeo,XiCL_NGeo,wBaryCL_NGeo,&
                           XCL_NGeo(1:3,0:NGeo,0:NGeo,0:NGeo,iElem),PartState(ParticleIndexNbr,1:3))
        !PartState(ParticleIndexNbr, 1:3) = MapToGeo(RandVal3,P)
        PDM%ParticleInside(ParticleIndexNbr) = .TRUE.
        IF (.NOT. DoRefMapping) THEN
          IF (TriaTracking) THEN
            CALL SingleParticleToExactElement(ParticleIndexNbr,doHALO=.FALSE.,initFIX=.FALSE.,doRelocate=.FALSE.)
          ELSE
            CALL SingleParticleToExactElementNoMap(ParticleIndexNbr,doHALO=.FALSE.,doRelocate=.FALSE.)
          END IF
        ELSE
          PartPosRef(1:3,ParticleIndexNbr)=RandVal3
        END IF
        IF(.NOT.PDM%ParticleInside(ParticleIndexNbr))THEN
          CALL abort(&
__STAMP__&
,' Particle lost in own MPI region. Need to communicate!')
        END IF
        IF (PDM%ParticleInside(ParticleIndexNbr)) PDM%IsNewPart(ParticleIndexNbr)=.TRUE.
      ELSE
        CALL abort(&
__STAMP__&
,'ERROR in ParticleInsertingCellPressure: ParticleIndexNbr.EQ.0 - maximum nbr of particles reached?')
      END IF
    END DO
    NbrOfParticle = NbrOfParticle + NbrNewParts
  END IF
  ! step 4: if PartDiff negative (and PartPressRemParts=T), remove particles
  IF(PartPressRemParts.AND.PartDiff.LT.0) THEN
    PartDiff = -PartDiff
    CALL RANDOM_NUMBER(RandVal)
    IF(ABS(PartDiffRest).GT.RandVal) PartDiff = PartDiff + 1.0
    NbrNewParts = INT(PartDiff)
    ! remove random part
    DO i = 1, NbrNewParts
      CALL RANDOM_NUMBER(RandVal)
      RandVal = RandVal * REAL(NbrPartsInCell)
      PDM%ParticleInside(PartsInCell(INT(RandVal)+1)) = .FALSE.
    END DO
  END IF
  DEALLOCATE(PartsInCell)
END DO
END SUBROUTINE ParticleInsertingCellPressure

SUBROUTINE ParticleInsertingPressureOut(iSpec,iInit,NbrOfParticle)
!===================================================================================================================================
! Insert constant outflow pressure particles (copied mostly from 'ParticleInsertingCellPressure')
!===================================================================================================================================
! MODULES
USE MOD_Globals
USE MOD_Particle_Vars
USE MOD_Mesh_Vars,              ONLY:NGeo,XCL_NGeo,XiCL_NGeo,wBaryCL_NGeo
USE MOD_Particle_Mesh,          ONLY:SingleParticleToExactElement,SingleParticleToExactElementNoMap
USE MOD_Particle_Tracking_Vars, ONLY:DoRefMapping,TriaTracking
USE MOD_Eval_xyz,               ONLY:TensorProductInterpolation
USE MOD_DSMC_Vars,              ONLY:CollisMode
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
INTEGER,INTENT(IN)            :: iSpec, iInit
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
INTEGER,INTENT(OUT)           :: NbrOfParticle
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
INTEGER                       :: iElem, Elem, iPart, i, NbrPartsInCell,  distnum
INTEGER                       :: ParticleIndexNbr
REAL                          :: RandVal3(1:3)
INTEGER, ALLOCATABLE          :: PartsInCell(:)
REAL                          :: Velo1, Velo2, Velosq, v_sum(3), v2_sum, maxwellfac
REAL                          :: Vec3D(3), RandVal3D(3)
!===================================================================================================================================

NbrOfParticle = 0
IF (CollisMode.EQ.0) THEN
  CALL Abort(&
__STAMP__&
,"Free Molecular Flow (CollisMode=0) is not supported for const pressure outflow BC!")
END IF
IF (TRIM(Species(iSpec)%Init(iInit)%velocityDistribution).NE.'maxwell') THEN
  CALL abort(&
__STAMP__&
,'Only maxwell implemented yet for const pressure outflow BC!')
END IF
DO iElem = 1,Species(iSpec)%Init(iInit)%ConstPress%nElemTotalInside
  Elem = Species(iSpec)%Init(iInit)%ConstPress%ElemTotalInside(iElem)
  ! step 1: count and build array of particles in cell (of current species only)
  ALLOCATE(PartsInCell(1:PEM%pNumber(Elem)))
  NbrPartsInCell = 0
  iPart = PEM%pStart(Elem)   
  DO i = 1, PEM%pNumber(Elem)
    IF (PartSpecies(iPart).EQ.iSpec) THEN
      NbrPartsInCell = NbrPartsInCell + 1
      PartsInCell(NbrPartsInCell) = iPart
    END IF
    iPart = PEM%pNext(iPart)
  END DO
  ! step 2: sample cell values, remove particles, calculate new NbrPartsInCell
  CALL ParticleInsertingPressureOut_Sampling(iSpec,iInit,Elem,iElem,NbrPartsInCell,PartsInCell)
  DEALLOCATE(PartsInCell)
  ! step 3: add new particles
  IF(NbrPartsInCell.GT.0) THEN
    ! insert particles (positions and velocities)
    v_sum(1:3) = 0.0
    v2_sum = 0.0
    DO i = 1, NbrPartsInCell
      ! set random position in -1,1 space
      CALL RANDOM_NUMBER(RandVal3)
      RandVal3 = RandVal3 * 2.0 - 1.0 
      ParticleIndexNbr = PDM%nextFreePosition(PDM%CurrentNextFreePosition + i + NbrOfParticle)
      IF (ParticleIndexNbr.NE.0) THEN
        CALL TensorProductInterpolation(RandVal3,3,NGeo,XiCL_NGeo,wBaryCL_NGeo,&
                           XCL_NGeo(1:3,0:NGeo,0:NGeo,0:NGeo,iElem),PartState(ParticleIndexNbr,1:3))
        PDM%ParticleInside(ParticleIndexNbr) = .TRUE.
        IF (.NOT. DoRefMapping) THEN
          IF (TriaTracking) THEN
            CALL SingleParticleToExactElement(ParticleIndexNbr,doHALO=.FALSE.,initFIX=.FALSE.,doRelocate=.FALSE.)
          ELSE
            CALL SingleParticleToExactElementNoMap(ParticleIndexNbr,doHALO=.FALSE.,doRelocate=.FALSE.)
          END IF
        ELSE
          PartPosRef(1:3,ParticleIndexNbr)=RandVal3
        END IF
        IF(.NOT.PDM%ParticleInside(ParticleIndexNbr))THEN
          CALL abort(&
__STAMP__&
,' Particle lost in own MPI region. Need to communicate!')
        END IF
        IF (PDM%ParticleInside(ParticleIndexNbr)) PDM%IsNewPart(ParticleIndexNbr)=.TRUE.
        ! Determine the particle velocity (maxwell, part 1)
        DO distnum = 1, 3
          CALL RANDOM_NUMBER(RandVal3D)
          Velo1 = 2.0*RandVal3D(1)-1.0
          Velo2 = 2.0*RandVal3D(2)-1.0
          Velosq= Velo1**2+Velo2**2
          DO WHILE ((Velosq.LE.0).OR.(Velosq.GE.1))
            CALL RANDOM_NUMBER(RandVal3D)
            Velo1 = 2.0*RandVal3D(1)-1.0
            Velo2 = 2.0*RandVal3D(2)-1.0
            Velosq= Velo1**2+Velo2**2
          END DO
          Vec3D(distnum) = Velo1*SQRT(-2*LOG(Velosq)/Velosq)
        END DO
        PartState(ParticleIndexNbr,4:6) = Vec3D(1:3)
        v_sum(1:3) = v_sum(1:3) + Vec3D(1:3)
        v2_sum = v2_sum + Vec3D(1)**2+Vec3D(2)**2+Vec3D(3)**2
      ELSE
        CALL abort(&
__STAMP__&
,'ERROR in ParticleInsertingCellPressureOut: ParticleIndexNbr.EQ.0 - maximum nbr of particles reached?')
      END IF
    END DO
    v_sum(1:3) = v_sum(1:3) / (NbrPartsInCell+1) !+1 correct?
    v2_sum = v2_sum / (NbrPartsInCell+1)         !+1 correct?
    !maxwellfactor from new calculated values (no vibrational DOF implemented, equilibirium assumed)
    !Species(iSpec)%Init(iInit)%ConstPress%ConstPressureSamp(iElem,:)
    maxwellfac = SQRT(3. * Species(iSpec)%Init(iInit)%ConstantPressure &
                 / (Species(iSpec)%Init(iInit)%ConstPress%ConstPressureSamp(iElem,4)) / & ! velocity of maximum
                 (Species(iSpec)%MassIC*v2_sum))                                                           ! T = p_o / (<n>*k)
    ! particel velocity (maxwell, part 2)
    DO i = 1, NbrPartsInCell
      ParticleIndexNbr = PDM%nextFreePosition(PDM%CurrentNextFreePosition + i + NbrOfParticle)
      IF (ParticleIndexNbr .ne. 0) THEN
        PartState(ParticleIndexNbr,4:6) = (PartState(ParticleIndexNbr,4:6) - v_sum(1:3)) * maxwellfac &  !macro velocity:
                                                                                      !=vi + VeloVecIC*(<p>-p_o)/(SQRT(a**2)*<n>*mt)
             + Species(iSpec)%Init(iInit)%ConstPress%ConstPressureSamp(iElem,1:3) + Species(iSpec)%Init(iInit)%VeloVecIC(1:3) &
             * (Species(iSpec)%Init(iInit)%ConstPress%ConstPressureSamp(iElem,5) - Species(iSpec)%Init(iInit)%ConstantPressure) &
             / (SQRT(Species(iSpec)%Init(iInit)%ConstPress%ConstPressureSamp(iElem,6)) &
                * Species(iSpec)%Init(iInit)%ConstPress%ConstPressureSamp(iElem,4) * Species(iSpec)%MassIC)
      END IF
    END DO

    NbrOfParticle = NbrOfParticle + NbrPartsInCell
  END IF
END DO
END SUBROUTINE ParticleInsertingPressureOut

SUBROUTINE ParticleInsertingPressureOut_Sampling(iSpec, iInit, iElem, ElemSamp, NbrPartsInCell, PartsInCell)
!===================================================================================================================================
! Subroutine to sample current cell values (partly copied from 'LD_DSMC_Mean_Bufferzone_A_Val' and 'dsmc_analyze')
!===================================================================================================================================
! MODULES
USE MOD_Globals
USE MOD_Globals_Vars,          ONLY : BoltzmannConst
USE MOD_Particle_Vars,         ONLY : PartState,usevMPF,Species,PartSpecies,usevMPF,PartMPF,PDM
USE MOD_DSMC_Vars,             ONLY : SpecDSMC
USE MOD_TimeDisc_Vars,         ONLY : iter
USE MOD_Particle_Mesh_Vars,    ONLY : GEO
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
INTEGER,INTENT(IN)    :: iSpec, iInit, iElem, ElemSamp
INTEGER,INTENT(IN)    :: PartsInCell(:)
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
INTEGER,INTENT(INOUT) :: NbrPartsInCell
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
INTEGER               :: iPart, iPartIndx
REAL                  :: MPFSum, WeightFak, kappa_part, AvogadroConst, RandVal, RealnumberNewParts
REAL                  :: Samp_V2(3), Samp_Temp(4), OldConstPressureSamp(6)
!===================================================================================================================================

IF (NbrPartsInCell .GT. 1) THEN ! Are there more than one particle
  IF(iter.EQ.0) THEN
    OldConstPressureSamp(:) = 0.0
  ELSE
    OldConstPressureSamp(:) = Species(iSpec)%Init(iInit)%ConstPress%ConstPressureSamp(ElemSamp,:)
  END IF
  Species(iSpec)%Init(iInit)%ConstPress%ConstPressureSamp(ElemSamp,:)        = 0.0
  MPFSum                            = 0.0
  Samp_V2(:)                        = 0.0
  Samp_Temp(:)                      = 0.0
  kappa_part                        = 0.0
  AvogadroConst                     = 6.02214129e23 ![1/mol]
  ! Loop over all particles of current species in cell
  DO iPart = 1, NbrPartsInCell
    iPartIndx = PartsInCell(iPart)
    IF (usevMPF) THEN
       WeightFak = PartMPF(iPartIndx)
    ELSE
       WeightFak = Species(iSpec)%MacroParticleFactor
    END IF
    Species(iSpec)%Init(iInit)%ConstPress%ConstPressureSamp(ElemSamp,1:3) &                !vi = vi + vi*w
         = Species(iSpec)%Init(iInit)%ConstPress%ConstPressureSamp(ElemSamp,1:3) &
         + PartState(iPartIndx,4:6) * WeightFak
    Samp_V2(:)                      = Samp_V2(:) + PartState(iPartIndx,4:6)**2 * WeightFak !vi**2 =vi**2 + vi**2*W
    MPFSum                          = MPFSum + WeightFak                                   !MPFsum = MPFsum + W
    PDM%ParticleInside(iPartIndx)=.false. !remove particle
  END DO

  !Calculation of specific heat ratio (no vibrational DOF -> only at low temperatures !!!)
  IF((SpecDSMC(PartSpecies(iPartIndx))%InterID.EQ.2).OR.(SpecDSMC(PartSpecies(iPartIndx))%InterID.EQ.20)) THEN
    kappa_part=1.4
  ELSE IF(SpecDSMC(PartSpecies(iPartIndx))%InterID.EQ.1) THEN
    kappa_part=5.0/3.0
  ELSE
    CALL abort(&
__STAMP__&
,'Wrong PartSpecies for outflow BC!')
  END IF
  ! Calculation of sampling values
  Species(iSpec)%Init(iInit)%ConstPress%ConstPressureSamp(ElemSamp,1:3) &
       = Species(iSpec)%Init(iInit)%ConstPress%ConstPressureSamp(ElemSamp,1:3) / MPFSum              !vi = vi / MPFsum
  Species(iSpec)%Init(iInit)%ConstPress%ConstPressureSamp(ElemSamp,4)   = MPFSum / GEO%Volume(iElem) !n = N / V
  Samp_Temp(1:3) &
       = Species(iSpec)%MassIC / BoltzmannConst * (Samp_V2(:) / MPFSum &                             !Ti = mt/k * (<vi**2>-<vi>**2)
       - Species(iSpec)%Init(iInit)%ConstPress%ConstPressureSamp(ElemSamp,1:3)**2)
  Samp_Temp(4) = (Samp_Temp(1) + Samp_Temp(2) + Samp_Temp(3)) / 3                                    !T = (Tx + Ty + Tz) / 3
  Species(iSpec)%Init(iInit)%ConstPress%ConstPressureSamp(ElemSamp,5) &                              !p = N / V * k * T
       = MPFSum / GEO%Volume(iElem) * BoltzmannConst * Samp_Temp(4)
  Species(iSpec)%Init(iInit)%ConstPress%ConstPressureSamp(ElemSamp,6) &                              !a**2 = kappa * k/mt * T
       = kappa_part * BoltzmannConst/Species(iSpec)%MassIC * Samp_Temp(4)
  

!----Ralaxationfaktor due to statistical noise in DSMC Results
  IF(iter.NE.0) THEN
    Species(iSpec)%Init(iInit)%ConstPress%ConstPressureSamp(ElemSamp,:) = (1.0 - Species(iSpec)%Init(iInit)%ConstPressureRelaxFac) &
                               * OldConstPressureSamp(:) + Species(iSpec)%Init(iInit)%ConstPressureRelaxFac &
                               * Species(iSpec)%Init(iInit)%ConstPress%ConstPressureSamp(ElemSamp,:)
  END IF
! Calculation of new density and resulting number in cell
  RealnumberNewParts = (Species(iSpec)%Init(iInit)%ConstPress%ConstPressureSamp(ElemSamp,4) & !N=(<n> + (p_o-<p>)/(a**2*mt)) * V/MPF
       + (Species(iSpec)%Init(iInit)%ConstantPressure - Species(iSpec)%Init(iInit)%ConstPress%ConstPressureSamp(ElemSamp,5)) &
       / (Species(iSpec)%Init(iInit)%ConstPress%ConstPressureSamp(ElemSamp,6) * Species(iSpec)%MassIC)) &
       * GEO%Volume(iElem) / Species(iSpec)%MacroParticleFactor !!!not sure if MPF treatment is correct!!!
  IF(RealnumberNewParts.GT.0.) THEN
    CALL RANDOM_NUMBER(RandVal)
    NbrPartsInCell = INT(RealnumberNewParts+RandVal)
  ELSE
    NbrPartsInCell = 0
  END IF

ELSE ! no particles in cell!
  CALL abort(&
__STAMP__&
,'YOU NEED MORE PARTICLES INSIDE THE OUTFLOW REGION!!!')
END IF

END SUBROUTINE ParticleInsertingPressureOut_Sampling


SUBROUTINE CalcVelocity_maxwell_lpn(FractNbr, Vec3D, iInit, Element, Temperature)
!===================================================================================================================================
! Subroutine to sample current cell values (partly copied from 'LD_DSMC_Mean_Bufferzone_A_Val' and 'dsmc_analyze')
!===================================================================================================================================
! MODULES
USE MOD_Globals
USE MOD_Globals_Vars,           ONLY : BoltzmannConst
USE MOD_Particle_Vars,          ONLY : Species!, DoZigguratSampling
!USE Ziggurat,                   ONLY : rnor
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
INTEGER,INTENT(IN)               :: FractNbr
INTEGER,INTENT(IN), OPTIONAL     :: iInit
INTEGER, OPTIONAL                :: Element !for BGG from VTK
REAL,INTENT(IN), OPTIONAL        :: Temperature
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
REAL,INTENT(OUT)                 :: Vec3D(3)
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
REAL                             :: RandVal(3), Velo1, Velo2, Velosq, Tx, ty, Tz, v_drift(3)
!===================================================================================================================================
IF(PRESENT(iInit).AND.PRESENT(Temperature))CALL abort(&
__STAMP__&
,'CalcVelocity_maxwell_lpn. iInit and Temperature cannot both be input arguments!')
IF(PRESENT(iInit).AND..NOT.PRESENT(Element))THEN
  Tx=Species(FractNbr)%Init(iInit)%MWTemperatureIC
  Ty=Species(FractNbr)%Init(iInit)%MWTemperatureIC
  Tz=Species(FractNbr)%Init(iInit)%MWTemperatureIC
  v_drift=Species(FractNbr)%Init(iInit)%VeloIC *Species(FractNbr)%Init(iInit)%VeloVecIC(1:3)
ELSE IF (PRESENT(Element)) THEN
  IF (Species(FractNbr)%Init(iInit)%ElemTemperatureFileID.GT.0) THEN
    Tx=Species(FractNbr)%Init(iInit)%ElemTemperatureIC(1,Element)
    Ty=Species(FractNbr)%Init(iInit)%ElemTemperatureIC(2,Element)
    Tz=Species(FractNbr)%Init(iInit)%ElemTemperatureIC(3,Element)
  ELSE
    Tx=Species(FractNbr)%Init(iInit)%MWTemperatureIC
    Ty=Species(FractNbr)%Init(iInit)%MWTemperatureIC
    Tz=Species(FractNbr)%Init(iInit)%MWTemperatureIC
  END IF
  IF (Species(FractNbr)%Init(iInit)%ElemVelocityICFileID.GT.0) THEN
    v_drift=Species(FractNbr)%Init(iInit)%ElemVelocityIC(1:3,Element)
  ELSE
    v_drift=Species(FractNbr)%Init(iInit)%VeloIC *Species(FractNbr)%Init(iInit)%VeloVecIC(1:3)
  END IF
ELSE IF(PRESENT(Temperature))THEN
  Tx=Temperature
  Ty=Temperature
  Tz=Temperature
  v_drift=0.0
ELSE 
CALL abort(&
__STAMP__&
,'PO: force temperature!!')
END IF

!IF (.NOT.DoZigguratSampling) THEN !polar method
  Velosq = 2
  DO WHILE ((Velosq .GE. 1.) .OR. (Velosq .EQ. 0.))
    CALL RANDOM_NUMBER(RandVal)
    Velo1 = 2.*RandVal(1) - 1.
    Velo2 = 2.*RandVal(2) - 1.
    Velosq = Velo1**2 + Velo2**2
  END DO
  Vec3D(1) = Velo1*SQRT(-2*BoltzmannConst*Tx/ &
    Species(FractNbr)%MassIC*LOG(Velosq)/Velosq)                                !x-Komponente
  Vec3D(2) = Velo2*SQRT(-2*BoltzmannConst*Ty/ &
  Species(FractNbr)%MassIC*LOG(Velosq)/Velosq)                                !y-Komponente
  Velosq = 2
  DO WHILE ((Velosq .GE. 1.) .OR. (Velosq .EQ. 0.))
    CALL RANDOM_NUMBER(RandVal)
    Velo1 = 2.*RandVal(1) - 1.
    Velo2 = 2.*RandVal(2) - 1.
    Velosq = Velo1**2 + Velo2**2
  END DO
  Vec3D(3) = Velo1*SQRT(-2*BoltzmannConst*Tz/ &
    Species(FractNbr)%MassIC*LOG(Velosq)/Velosq)                                !z-Komponente
!ELSE !ziggurat method
!  Velo1 = rnor()
!  Vec3D(1) = Velo1*SQRT(BoltzmannConst*Tx/Species(FractNbr)%MassIC)             !x-Komponente
!  Velo1 = rnor()
!  Vec3D(2) = Velo1*SQRT(BoltzmannConst*Ty/Species(FractNbr)%MassIC)             !y-Komponente
!  Velo1 = rnor()
!  Vec3D(3) = Velo1*SQRT(BoltzmannConst*Tz/Species(FractNbr)%MassIC)             !z-Komponente
!END IF
Vec3D(1:3) = Vec3D(1:3) + v_drift

END SUBROUTINE CalcVelocity_maxwell_lpn


SUBROUTINE CalcVelocity_emmert(FractNbr, iInit, Vec3D)
!===================================================================================================================================
! Subroutine to sample particle velos in VecIC from distri by Emmert et al. [Phys. Fluids 23, 803 (1980)] and in normal dir. from MB
!===================================================================================================================================
! MODULES
USE MOD_Globals
USE MOD_Globals_Vars,           ONLY : BoltzmannConst
USE MOD_Particle_Vars,          ONLY : Species!, DoZigguratSampling
!USE Ziggurat,                   ONLY : rnor
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
INTEGER,INTENT(IN)               :: FractNbr, iInit
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
REAL,INTENT(OUT)                 :: Vec3D(3)
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
REAL                             :: RandVal(3), Velo1, Velo2, Velosq, T, v_dir(3), vec_t1(3), vec_t2(3), v_d
!===================================================================================================================================

T=Species(FractNbr)%Init(iInit)%MWTemperatureIC
v_dir=Species(FractNbr)%Init(iInit)%VeloVecIC(1:3)
v_d=Species(FractNbr)%Init(iInit)%VeloIC

!--build arbitrary vectors normal to v_dir
IF (.NOT.ALMOSTEQUAL(v_dir(3),0.)) THEN
  vec_t1(1) = 1.0
  vec_t1(2) = 1.0
  vec_t1(3) = -(v_dir(1)+v_dir(2))/v_dir(3)
  vec_t2(1) = v_dir(2) * vec_t1(3) - v_dir(3)
  vec_t2(2) = v_dir(3) - v_dir(1) * vec_t1(3)
  vec_t2(3) = v_dir(1) - v_dir(2)
  vec_t1 = vec_t1 / SQRT(2.0 + vec_t1(3)*vec_t1(3))
ELSE
  IF (.NOT.ALMOSTEQUAL(v_dir(2),0.)) THEN
    vec_t1(1) = 1.0
    vec_t1(3) = 1.0
    vec_t1(2) = -(v_dir(1)+v_dir(3))/v_dir(2)
    vec_t2(1) = v_dir(2) - v_dir(3) * vec_t1(2)
    vec_t2(2) = v_dir(3) - v_dir(1)
    vec_t2(3) = v_dir(1) * vec_t1(2) - v_dir(2)
    vec_t1 = vec_t1 / SQRT(2.0 + vec_t1(2)*vec_t1(2))
  ELSE
    IF (.NOT.ALMOSTEQUAL(v_dir(1),0.)) THEN
      vec_t1(2) = 1.0
      vec_t1(3) = 1.0
      vec_t1(1) = -(v_dir(2)+v_dir(3))/v_dir(1)
      vec_t2(1) = v_dir(2) - v_dir(3)
      vec_t2(2) = v_dir(3) * vec_t1(1) - v_dir(1)
      vec_t2(3) = v_dir(1) - v_dir(2) * vec_t1(1)
      vec_t1 = vec_t1 / SQRT(2.0 + vec_t1(1)*vec_t1(1))
    ELSE
      CALL abort(&
__STAMP__&
,'Error in CalcVelocity_emmert, VeloVecIC is zero!')
    END IF
  END IF
END IF
vec_t2 = vec_t2 / SQRT(vec_t2(1)*vec_t2(1) + vec_t2(2)*vec_t2(2) + vec_t2(3)*vec_t2(3))

!--sample velocities
!IF (.NOT.DoZigguratSampling) THEN !polar method
  Velosq = 2
  DO WHILE ((Velosq .GE. 1.) .OR. (Velosq .EQ. 0.))
    CALL RANDOM_NUMBER(RandVal)
    Velo1 = 2.*RandVal(1) - 1.
    Velo2 = 2.*RandVal(2) - 1.
    Velosq = Velo1**2 + Velo2**2
  END DO
  Vec3D(1:3) =              vec_t1(1:3)*Velo1*SQRT(-2*BoltzmannConst*T/ &
    Species(FractNbr)%MassIC*LOG(Velosq)/Velosq)                                !n1-Komponente (maxwell_lpn)
  Vec3D(1:3) = Vec3D(1:3) + vec_t2(1:3)*Velo2*SQRT(-2*BoltzmannConst*T/ &
    Species(FractNbr)%MassIC*LOG(Velosq)/Velosq)                                !n2-Komponente (maxwell_lpn)
!ELSE !ziggurat method
!  Velo1=rnor()
!  Vec3D(1:3) =              vec_t1(1:3)*Velo1*SQRT(BoltzmannConst*T/ &
!    Species(FractNbr)%MassIC)                                !n1-Komponente (maxwell_lpn)
!  Velo2=rnor()
!  Vec3D(1:3) = Vec3D(1:3) + vec_t2(1:3)*Velo2*SQRT(BoltzmannConst*T/ &
!    Species(FractNbr)%MassIC)                                !n2-Komponente (maxwell_lpn)
!END IF
Vec3D(1:3) = Vec3D(1:3) + v_dir(1:3)*SQRT(BoltzmannConst*T/Species(FractNbr)%MassIC)* &                ! (emmert)
  sign(1.d0,RandVal(3)-0.5d0)*SQRT(-2*log(1-sign(1.d0,RandVal(3)-0.5d0)*(2*RandVal(3)-1)))

Vec3D(1:3) = Vec3D(1:3) + v_dir(1:3)*v_d

END SUBROUTINE CalcVelocity_emmert


SUBROUTINE InsideExcludeRegionCheck(FractNbr, iInit, Particle_pos, insideExcludeRegion)
!===================================================================================================================================
! Subroutine for checking if calculated particle position would be inside user-defined ExcludeRegion (cuboid or cylinder)
!===================================================================================================================================
! MODULES
USE MOD_Globals,                ONLY : abort
USE MOD_Particle_Vars,          ONLY : Species
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
INTEGER,INTENT(IN)               :: FractNbr, iInit
REAL,INTENT(IN)                  :: Particle_pos(3)
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
LOGICAL,INTENT(OUT)              :: insideExcludeRegion
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
REAL                             :: VecExclude(3), DistExclude
INTEGER                          :: iExclude
!===================================================================================================================================

insideExcludeRegion=.FALSE.
DO iExclude=1,Species(FractNbr)%Init(iInit)%NumberOfExcludeRegions
  VecExclude = Particle_pos - Species(FractNbr)%Init(iInit)%ExcludeRegion(iExclude)%BasePointIC
  SELECT CASE (TRIM(Species(FractNbr)%Init(iInit)%ExcludeRegion(iExclude)%SpaceIC))
  CASE ('cuboid')
    !--check normal direction
    DistExclude = VecExclude(1)*Species(FractNbr)%Init(iInit)%ExcludeRegion(iExclude)%NormalIC(1) &
      + VecExclude(2)*Species(FractNbr)%Init(iInit)%ExcludeRegion(iExclude)%NormalIC(2) &
      + VecExclude(3)*Species(FractNbr)%Init(iInit)%ExcludeRegion(iExclude)%NormalIC(3)
    IF ( (DistExclude .LE. Species(FractNbr)%Init(iInit)%ExcludeRegion(iExclude)%CuboidHeightIC) &
      .AND. (DistExclude .GE. 0.) ) THEN
      insideExcludeRegion = .TRUE.
    ELSE
      insideExcludeRegion = .FALSE.
      CYCLE
    END IF
    !--check BV1 direction
    DistExclude = VecExclude(1)*Species(FractNbr)%Init(iInit)%ExcludeRegion(iExclude)%BaseVector1IC(1) &
      + VecExclude(2)*Species(FractNbr)%Init(iInit)%ExcludeRegion(iExclude)%BaseVector1IC(2) &
      + VecExclude(3)*Species(FractNbr)%Init(iInit)%ExcludeRegion(iExclude)%BaseVector1IC(3)
    IF ( (DistExclude .LE. Species(FractNbr)%Init(iInit)%ExcludeRegion(iExclude)%ExcludeBV_lenghts(1)**2) &
      .AND. (DistExclude .GE. 0.) ) THEN
      insideExcludeRegion = .TRUE.
    ELSE
      insideExcludeRegion = .FALSE.
      CYCLE
    END IF
    !--check BV2 direction
    DistExclude = VecExclude(1)*Species(FractNbr)%Init(iInit)%ExcludeRegion(iExclude)%BaseVector2IC(1) &
      + VecExclude(2)*Species(FractNbr)%Init(iInit)%ExcludeRegion(iExclude)%BaseVector2IC(2) &
      + VecExclude(3)*Species(FractNbr)%Init(iInit)%ExcludeRegion(iExclude)%BaseVector2IC(3)
    IF ( (DistExclude .LE. Species(FractNbr)%Init(iInit)%ExcludeRegion(iExclude)%ExcludeBV_lenghts(2)**2) &
      .AND. (DistExclude .GE. 0.) ) THEN
      insideExcludeRegion = .TRUE.
      RETURN !particle is inside current ExcludeRegion based an all dimensions
    ELSE
      insideExcludeRegion = .FALSE.
      CYCLE
    END IF
  CASE ('cylinder')
    !--check normal direction
    DistExclude = VecExclude(1)*Species(FractNbr)%Init(iInit)%ExcludeRegion(iExclude)%NormalIC(1) &
      + VecExclude(2)*Species(FractNbr)%Init(iInit)%ExcludeRegion(iExclude)%NormalIC(2) &
      + VecExclude(3)*Species(FractNbr)%Init(iInit)%ExcludeRegion(iExclude)%NormalIC(3)
    IF ( (DistExclude .LE. Species(FractNbr)%Init(iInit)%ExcludeRegion(iExclude)%CylinderHeightIC) &
      .AND. (DistExclude .GE. 0.) ) THEN
      insideExcludeRegion = .TRUE.
    ELSE
      insideExcludeRegion = .FALSE.
      CYCLE
    END IF
    !--check radial direction
    DistExclude = SQRT( VecExclude(1)**2 + VecExclude(2)**2 + VecExclude(3)**2 - DistExclude**2 )
    IF ( (DistExclude .LE. Species(FractNbr)%Init(iInit)%ExcludeRegion(iExclude)%RadiusIC) &
      .AND. (DistExclude .GE. Species(FractNbr)%Init(iInit)%ExcludeRegion(iExclude)%Radius2IC) ) THEN
      insideExcludeRegion = .TRUE.
      RETURN !particle is inside current ExcludeRegion based an all dimensions
    ELSE
      insideExcludeRegion = .FALSE.
      CYCLE
    END IF
  CASE DEFAULT
    CALL abort(&
__STAMP__&
,'wrong SpaceIC for ExcludeRegion!')
  END SELECT
END DO

END SUBROUTINE InsideExcludeRegionCheck

SUBROUTINE InitializeParticleSurfaceflux()                                                                     
!===================================================================================================================================
! Init Particle Inserting via Surface Flux
!===================================================================================================================================
! Modules
#ifdef MPI
USE MOD_Particle_MPI_Vars,     ONLY: PartMPI
#endif /* MPI*/
USE MOD_Globals
USE MOD_Globals_Vars,          ONLY: PI, BoltzmannConst
USE MOD_ReadInTools
USE MOD_Particle_Boundary_Vars,ONLY: PartBound,nPartBound, nAdaptiveBC
USE MOD_Particle_Vars,         ONLY: Species, nSpecies, DoSurfaceFlux, DoPoissonRounding, nDataBC_CollectCharges &
                                   , DoTimeDepInflow, Adaptive_MacroVal, MacroRestartData_tmp, AdaptiveWeightFac
USE MOD_PARTICLE_Vars,         ONLY: nMacroRestartFiles
USE MOD_Particle_Vars,         ONLY: DoForceFreeSurfaceFlux
USE MOD_DSMC_Vars,             ONLY: useDSMC, BGGas
USE MOD_Mesh_Vars,             ONLY: nBCSides, BC, SideToElem, NGeo, nElems, offsetElem
USE MOD_Particle_Surfaces_Vars,ONLY: BCdata_auxSF, BezierSampleN, SurfMeshSubSideData, SurfMeshSideAreas
USE MOD_Particle_Surfaces_Vars,ONLY: SurfFluxSideSize, TriaSurfaceFlux, WriteTriaSurfaceFluxDebugMesh, SideType
USE MOD_Particle_Surfaces,      ONLY:GetBezierSampledAreas, GetSideBoundingBox, CalcNormAndTangTriangle
USE MOD_Particle_Mesh_Vars,     ONLY:PartElemToSide !,GEO
USE MOD_Particle_Tracking_Vars, ONLY:TriaTracking
USE MOD_IO_HDF5
USE MOD_HDF5_INPUT             ,ONLY: DatasetExists,ReadAttribute,ReadArray,GetDataSize
USE MOD_Restart_Vars           ,ONLY: DoRestart,RestartFile
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
! Local variable declaration                                                                       
INTEGER               :: iPartBound,iSpec,iSF,SideID,BCSideID,iSide,ElemID,iLocSide,iSample,jSample,iBC,currentBC,iCount,iProc
INTEGER               :: iCopy1, iCopy2, iCopy3, nSides
CHARACTER(32)         :: hilf, hilf2, hilf3
REAL                  :: a, vSF, projFak, v_thermal
REAL                  :: vec_nIn(3), nVFR, vec_t1(3), vec_t2(3), point(2)
LOGICAL               :: AnySimpleRadialVeloFit, noAdaptive
INTEGER               :: MaxSurfacefluxBCs
INTEGER               :: nDataBC                             ! number of different PartBounds used for SFs
INTEGER,ALLOCATABLE   :: TmpMapToBC(:)                       ! PartBC
INTEGER,ALLOCATABLE   :: TmpSideStart(:)                     ! Start of Linked List for Sides in SurfacefluxBC
INTEGER,ALLOCATABLE   :: TmpSideNumber(:)                    ! Number of Particles in Sides in SurfacefluxBC
INTEGER,ALLOCATABLE   :: TmpSideEnd(:)                       ! End of Linked List for Sides in SurfacefluxBC
INTEGER,ALLOCATABLE   :: TmpSideNext(:)                      ! Next Side in same SurfacefluxBC (Linked List)
INTEGER,ALLOCATABLE   :: nType0(:,:), nType1(:,:), nType2(:,:)
REAL, ALLOCATABLE     :: areasLoc(:),areasGlob(:)
REAL                  :: totalArea
REAL,ALLOCATABLE      :: tmp_SubSideAreas(:,:), tmp_SubSideDmax(:,:)
REAL,ALLOCATABLE      :: tmp_Vec_nOut(:,:,:), tmp_Vec_t1(:,:,:), tmp_Vec_t2(:,:,:)
REAL,ALLOCATABLE      :: tmp_BezierControlPoints2D(:,:,:,:,:)
REAL,DIMENSION(1:3,1:8):: BoundingBox
INTEGER,ALLOCATABLE   :: Adaptive_BC_Map(:), tmp_Surfaceflux_BCs(:)
LOGICAL,ALLOCATABLE   :: Adaptive_Found_Flag(:)
INTEGER               :: nAdaptive_Found, iSS, nSurffluxBCs_old, nSurffluxBCs_new, iSFx
REAL,ALLOCATABLE      :: sum_pressurefraction(:)
REAL                  :: Vector1(3),Vector2(3),Vector3(3)
INTEGER               :: dir(3)
REAL                  :: origin(2),xyzNod(3)
REAL                  :: corner(3)
REAL                  :: VecBoundingBox(3)
INTEGER               :: iNode
REAL                  :: vec(2)
REAL                  :: radiusCorner(2,4)
LOGICAL               :: r0inside, intersecExists(2,2)
REAL                  :: corners(2,4),rmin,rmax!,atan2Shift
INTEGER               :: FileID
LOGICAL               :: OutputSurfaceFluxLinked
REAL,ALLOCATABLE      :: ElemData_HDF5(:,:,:)
LOGICAL               :: AdaptiveDataExists, AdaptiveInitDone
INTEGER               :: iElem
!===================================================================================================================================

#ifdef MPI
CALL MPI_BARRIER(PartMPI%COMM,iError)
#endif /*MPI*/
OutputSurfaceFluxLinked=GETLOGICAL('OutputSurfaceFluxLinked','.FALSE.')

! global calculations for sampling the faces for area and vector calculations (checks the integration with CODE_ANALYZE)
ALLOCATE (tmp_SubSideAreas(SurfFluxSideSize(1),SurfFluxSideSize(2)), &
  tmp_Vec_nOut(3,SurfFluxSideSize(1),SurfFluxSideSize(2)), &
  tmp_Vec_t1(3,SurfFluxSideSize(1),SurfFluxSideSize(2)), &
  tmp_Vec_t2(3,SurfFluxSideSize(1),SurfFluxSideSize(2)), &
  SurfMeshSubSideData(SurfFluxSideSize(1),SurfFluxSideSize(2),1:nBCSides)    )
IF (.NOT.TriaSurfaceFlux) THEN
  ALLOCATE (tmp_SubSideDmax(SurfFluxSideSize(1),SurfFluxSideSize(2)), &
    tmp_BezierControlPoints2D(2,0:NGeo,0:NGeo,SurfFluxSideSize(1),SurfFluxSideSize(2)) )
END IF
ALLOCATE(SurfMeshSideAreas(1:nBCSides))
SurfMeshSideAreas=0.
totalArea=0.
DO BCSideID=1,nBCSides
  ElemID = SideToElem(1,BCSideID)
  IF (ElemID.LT.1) THEN !not sure if necessary
    ElemID = SideToElem(2,BCSideID)
    iLocSide = SideToElem(4,BCSideID)
  ELSE
    iLocSide = SideToElem(3,BCSideID)
  END IF
  SideID=PartElemToSide(E2S_SIDE_ID,ilocSide,ElemID)
  IF (TriaSurfaceFlux) THEN
    IF (SurfFluxSideSize(1).NE.1 .OR. SurfFluxSideSize(2).NE.2) CALL abort(&
__STAMP__&
, 'SurfFluxSideSize must be 1,2 for TriaSurfaceFlux!')
    DO jSample=1,SurfFluxSideSize(2); DO iSample=1,SurfFluxSideSize(1)
      CALL CalcNormAndTangTriangle(SideID=SideID,nVec=tmp_Vec_nOut(:,iSample,jSample) &
        ,tang1=tmp_Vec_t1(:,iSample,jSample) &
        ,tang2=tmp_Vec_t2(:,iSample,jSample) &
        ,area=tmp_SubSideAreas(iSample,jSample) &
        ,TriNum=jSample,ElemID_opt=ElemID,LocSideID_opt=ilocSide)
      SurfMeshSideAreas(BCSideID)=SurfMeshSideAreas(BCSideID)+tmp_SubSideAreas(iSample,jSample)
    END DO; END DO  
  ELSE
    IF (ANY(SurfFluxSideSize.NE.BezierSampleN)) CALL abort(&
__STAMP__&
, 'SurfFluxSideSize must be BezierSampleN,BezierSampleN for .NOT.TriaSurfaceFlux!')
    CALL GetBezierSampledAreas(SideID=SideID &
      ,BezierSampleN=BezierSampleN &
      ,SurfMeshSubSideAreas=tmp_SubSideAreas &
      ,SurfMeshSideArea_opt=SurfMeshSideAreas(BCSideID) &
      ,SurfMeshSubSideVec_nOut_opt=tmp_Vec_nOut &
      ,SurfMeshSubSideVec_t1_opt=tmp_Vec_t1 &
      ,SurfMeshSubSideVec_t2_opt=tmp_Vec_t2)
  END IF
  totalArea=totalArea+SurfMeshSideAreas(BCSideID)
  DO jSample=1,SurfFluxSideSize(2); DO iSample=1,SurfFluxSideSize(1)
    SurfMeshSubSideData(iSample,jSample,BCSideID)%vec_nIn=-tmp_Vec_nOut(:,iSample,jSample)
    SurfMeshSubSideData(iSample,jSample,BCSideID)%vec_t1=tmp_Vec_t1(:,iSample,jSample)
    SurfMeshSubSideData(iSample,jSample,BCSideID)%vec_t2=tmp_Vec_t2(:,iSample,jSample)
    SurfMeshSubSideData(iSample,jSample,BCSideID)%area=tmp_SubSideAreas(iSample,jSample)
  END DO; END DO
END DO
#ifdef CODE_ANALYZE
IPWRITE(*,*)" ===== TOTAL AREA (all BCsides) ====="
IPWRITE(*,*)"totalArea       = ",totalArea
IPWRITE(*,*)"totalArea/(pi) = ",totalArea/(ACOS(-1.))
IPWRITE(*,*)" ===== TOTAL AREA (all BCsides) ====="
#endif /*CODE_ANALYZE*/ 

AnySimpleRadialVeloFit=.FALSE.
MaxSurfacefluxBCs=0
nDataBC=nDataBC_CollectCharges !sides may be also used for collectcharges of floating potential!!!
DoSurfaceFlux=.FALSE.
!-- 0.: allocate and initialize aux. data of BCs (SideLists for Surfacefluxes):
!-----moved to end of InitializeVariables in particle_init!!!
!ALLOCATE(BCdata_auxSF(1:nPartBound))
!DO iPartBound=1,nPartBound
!  BCdata_auxSF(iPartBound)%SideNumber=-1 !init value when not used
!END DO

! auxiliary arrays for defining all Adaptive_BCs
IF (nAdaptiveBC.GT.0) THEN
  AdaptiveWeightFac = GETREAL('Part-AdaptiveWeightingFactor','0.001')
  ALLOCATE(Adaptive_BC_Map(1:nAdaptiveBC))
  Adaptive_BC_Map(:)=0
  ALLOCATE(Adaptive_Found_Flag(1:nAdaptiveBC))
  iSS = 0
  DO iPartBound=1,nPartBound
    IF(PartBound%Adaptive(iPartBound))THEN
      iSS = iSS + 1
      Adaptive_BC_Map(iSS) = iPartBound
    END IF
  END DO
  Adaptive_Found_Flag(:) = .FALSE.
  ALLOCATE(sum_pressurefraction(1:nAdaptiveBC))
  sum_pressurefraction(:) = 0.
END IF

!-- 1.: read/prepare parameters and determine nec. BCs
DO iSpec=1,nSpecies
  IF (nAdaptiveBC.GT.0) THEN
    Adaptive_Found_Flag(:) = .FALSE.
  END IF
  WRITE(UNIT=hilf,FMT='(I0)') iSpec
  Species(iSpec)%nSurfacefluxBCs = GETINT('Part-Species'//TRIM(hilf)//'-nSurfacefluxBCs','0')
  IF (useDSMC) THEN
    IF (BGGas%BGGasSpecies.EQ.iSpec) THEN
      IF (Species(iSpec)%nSurfacefluxBCs.GT.0 .OR. nAdaptiveBC.GT.0) CALL abort(&
__STAMP__&
, 'SurfaceFlux or AdaptiveBCs are not implemented for the BGG-species!')
    END IF
  END IF
  ! if no surfacefluxes defined and only adaptive boundaries then first allocation with adaptive
  IF ((Species(iSpec)%nSurfacefluxBCs.EQ.0) .AND. (nAdaptiveBC.GT.0)) THEN
    Species(iSpec)%nSurfacefluxBCs = nAdaptiveBC
    ALLOCATE(Species(iSpec)%Surfaceflux(1:Species(iSpec)%nSurfacefluxBCs))
    DO iSF=1,Species(iSpec)%nSurfacefluxBCs
      Species(iSpec)%Surfaceflux(iSF)%BC = Adaptive_BC_Map(iSF)
    END DO
    nAdaptive_Found = nAdaptiveBC
    Adaptive_Found_Flag(:) = .TRUE.
  ! if no surfaceflux needed
  ELSE IF ((Species(iSpec)%nSurfacefluxBCs.EQ.0) .AND. (nAdaptiveBC.EQ.0)) THEN
    CYCLE
  ELSE
    ALLOCATE(Species(iSpec)%Surfaceflux(1:Species(iSpec)%nSurfacefluxBCs))
    ! Initialize Surfaceflux to BC mapping and check if defined Surfacefluxes from init overlap with Adaptive BCs
    Species(iSpec)%Surfaceflux(:)%BC=-1
    DO iSF=1,Species(iSpec)%nSurfacefluxBCs
      WRITE(UNIT=hilf2,FMT='(I0)') iSF
      hilf2=TRIM(hilf)//'-Surfaceflux'//TRIM(hilf2)
      Species(iSpec)%Surfaceflux(iSF)%BC = GETINT('Part-Species'//TRIM(hilf2)//'-BC','0')
      IF (nAdaptiveBC.GT.0) THEN
        DO iSS=1,nAdaptiveBC
          IF (Adaptive_BC_Map(iSS).EQ.Species(iSpec)%Surfaceflux(iSF)%BC) THEN
            Adaptive_Found_Flag(iSS) = .TRUE.
          END IF
        END DO
      END IF
    END DO
    nAdaptive_Found = 0
    DO iSS=1,nAdaptiveBC
      IF(Adaptive_Found_Flag(iSS)) nAdaptive_Found = nAdaptive_Found + 1
    END DO
  END IF
  ! add missing Adaptive BCs at end of Surfaceflux array and reduce number of constant surfacefluxBC
  ! additionally rearrange surfaceflux array for Adaptive BC being the last entries
  IF (nAdaptiveBC.GT.0) THEN
    ALLOCATE(tmp_Surfaceflux_BCs(1:Species(iSpec)%nSurfacefluxBCs))
    tmp_Surfaceflux_BCs(:) = Species(iSpec)%Surfaceflux(:)%BC
    nSurffluxBCs_old = Species(iSpec)%nSurfacefluxBCs
    Species(iSpec)%nSurfacefluxBCs = Species(iSpec)%nSurfacefluxBCs - nAdaptive_Found
    nSurffluxBCs_new = Species(iSpec)%nSurfacefluxBCs + nAdaptiveBC
    DEALLOCATE(Species(iSpec)%Surfaceflux)
    ALLOCATE(Species(iSpec)%Surfaceflux(1:nSurffluxBCs_new))
    iSFx = 1
    DO iSF=1,nSurffluxBCs_old
      IF (PartBound%Adaptive(tmp_Surfaceflux_BCs(iSF))) CYCLE
      Species(iSpec)%Surfaceflux(iSFx)%BC = tmp_Surfaceflux_BCs(iSF)
      iSFx = iSFx +1
    END DO
    DO iSFx=1,nAdaptiveBC
      Species(iSpec)%Surfaceflux(Species(iSpec)%nSurfacefluxBCs+iSFx)%BC = Adaptive_BC_Map(iSFx)
    END DO
    DEALLOCATE(tmp_Surfaceflux_BCs)
  END IF

  MaxSurfacefluxBCs=MAX(MaxSurfacefluxBCs,Species(iSpec)%nSurfacefluxBCs)
  DO iSF=1,Species(iSpec)%nSurfacefluxBCs+nAdaptiveBC
    IF (iSF .LE. Species(iSpec)%nSurfacefluxBCs) THEN
      noAdaptive=.TRUE.
    ELSE
      noAdaptive=.FALSE.
    END IF
    WRITE(UNIT=hilf2,FMT='(I0)') iSF
    hilf2=TRIM(hilf)//'-Surfaceflux'//TRIM(hilf2)
    Species(iSpec)%Surfaceflux(iSF)%InsertedParticle = 0
    Species(iSpec)%Surfaceflux(iSF)%InsertedParticleSurplus = 0
    Species(iSpec)%Surfaceflux(iSF)%VFR_total = 0
    Species(iSpec)%Surfaceflux(iSF)%VFR_total_allProcsTotal = 0
    ! get surfaceflux data
    IF (Species(iSpec)%Surfaceflux(iSF)%BC.LT.1 .OR. Species(iSpec)%Surfaceflux(iSF)%BC.GT.nPartBound) THEN
      CALL abort(&
__STAMP__&
, 'SurfacefluxBCs must be between 1 and nPartBound!')
    ELSE IF (BCdata_auxSF(Species(iSpec)%Surfaceflux(iSF)%BC)%SideNumber.EQ. -1) THEN !not set yet
      BCdata_auxSF(Species(iSpec)%Surfaceflux(iSF)%BC)%SideNumber=0
      nDataBC=nDataBC+1
    END IF
    IF (noAdaptive) THEN
      Species(iSpec)%Surfaceflux(iSF)%velocityDistribution  = &
          TRIM(GETSTR('Part-Species'//TRIM(hilf2)//'-velocityDistribution','constant'))
      IF (TRIM(Species(iSpec)%Surfaceflux(iSF)%velocityDistribution).NE.'constant' .AND. &
          TRIM(Species(iSpec)%Surfaceflux(iSF)%velocityDistribution).NE.'maxwell' .AND. &
          TRIM(Species(iSpec)%Surfaceflux(iSF)%velocityDistribution).NE.'maxwell_lpn') THEN
        CALL abort(&
__STAMP__&
, 'Only constant or maxwell-like velodistri implemented for surfaceflux!')
      END IF
      Species(iSpec)%Surfaceflux(iSF)%VeloIC                = GETREAL('Part-Species'//TRIM(hilf2)//'-VeloIC','0.')
      Species(iSpec)%Surfaceflux(iSF)%VeloIsNormal          = GETLOGICAL('Part-Species'//TRIM(hilf2)//'-VeloIsNormal','.FALSE.')
      IF (Species(iSpec)%Surfaceflux(iSF)%VeloIsNormal) THEN
        Species(iSpec)%Surfaceflux(iSF)%SimpleRadialVeloFit=.FALSE.
      ELSE
        Species(iSpec)%Surfaceflux(iSF)%VeloVecIC          =GETREALARRAY('Part-Species'//TRIM(hilf2)//'-VeloVecIC',3,'1. , 0. , 0.')
        Species(iSpec)%Surfaceflux(iSF)%SimpleRadialVeloFit=GETLOGICAL('Part-Species'//TRIM(hilf2)//'-SimpleRadialVeloFit','.FALSE.')
        IF (Species(iSpec)%Surfaceflux(iSF)%SimpleRadialVeloFit) THEN
          AnySimpleRadialVeloFit=.TRUE.
          Species(iSpec)%Surfaceflux(iSF)%preFac       = GETREAL('Part-Species'//TRIM(hilf2)//'-preFac','0.')
          Species(iSpec)%Surfaceflux(iSF)%powerFac     = GETREAL('Part-Species'//TRIM(hilf2)//'-powerFac','0.')
          Species(iSpec)%Surfaceflux(iSF)%shiftFac     = GETREAL('Part-Species'//TRIM(hilf2)//'-shiftFac','0.')
          Species(iSpec)%Surfaceflux(iSF)%dir(1)       = GETINT('Part-Species'//TRIM(hilf2)//'-axialDir','1')
          IF (Species(iSpec)%Surfaceflux(iSF)%dir(1).EQ.1) THEN
            Species(iSpec)%Surfaceflux(iSF)%dir(2)=2
            Species(iSpec)%Surfaceflux(iSF)%dir(3)=3
          ELSE IF (Species(iSpec)%Surfaceflux(iSF)%dir(1).EQ.2) THEN
            Species(iSpec)%Surfaceflux(iSF)%dir(2)=3
            Species(iSpec)%Surfaceflux(iSF)%dir(3)=1
          ELSE IF (Species(iSpec)%Surfaceflux(iSF)%dir(1).EQ.3) THEN
            Species(iSpec)%Surfaceflux(iSF)%dir(2)=1
            Species(iSpec)%Surfaceflux(iSF)%dir(3)=2
          ELSE
            CALL abort(__STAMP__&
              ,'ERROR in init: axialDir for SFradial must be between 1 and 3!')
          END IF
          IF ( Species(iSpec)%Surfaceflux(iSF)%VeloVecIC(Species(iSpec)%Surfaceflux(iSF)%dir(2)).NE.0. .OR. &
               Species(iSpec)%Surfaceflux(iSF)%VeloVecIC(Species(iSpec)%Surfaceflux(iSF)%dir(3)).NE.0. ) THEN
            CALL abort(__STAMP__&
              ,'ERROR in init: axialDir for SFradial do not correspond to VeloVecIC!')
          END IF
          Species(iSpec)%Surfaceflux(iSF)%origin       = GETREALARRAY('Part-Species'//TRIM(hilf2)//'-origin',2,'0. , 0.')
          WRITE(UNIT=hilf3,FMT='(E16.8)') HUGE(Species(iSpec)%Surfaceflux(iSF)%rmax)
          Species(iSpec)%Surfaceflux(iSF)%rmax     = GETREAL('Part-Species'//TRIM(hilf2)//'-rmax',TRIM(hilf3))
          Species(iSpec)%Surfaceflux(iSF)%rmin     = GETREAL('Part-Species'//TRIM(hilf2)//'-rmin','0.')
        END IF !Species(iSpec)%Surfaceflux(iSF)%SimpleRadialVeloFit
      END IF !.NOT.VeloIsNormal
    ELSE !Adaptive
      Species(iSpec)%Surfaceflux(iSF)%velocityDistribution  = Species(iSpec)%Init(0)%velocityDistribution
      IF (PartBound%AdaptiveMacroRestartFileID(Species(iSpec)%Surfaceflux(iSF)%BC).EQ.0 .OR. nMacroRestartFiles.EQ.0) THEN
        Species(iSpec)%Surfaceflux(iSF)%VeloIC                = Species(iSpec)%Init(0)%VeloIC
        Species(iSpec)%Surfaceflux(iSF)%VeloVecIC             = Species(iSpec)%Init(0)%VeloVecIC
      END IF
      Species(iSpec)%Surfaceflux(iSF)%VeloIsNormal          = .FALSE.
      Species(iSpec)%Surfaceflux(iSF)%SimpleRadialVeloFit   = .FALSE.
    END IF
    IF (.NOT.Species(iSpec)%Surfaceflux(iSF)%VeloIsNormal .OR. .NOT.noAdaptive) THEN
      !--- normalize VeloVecIC
      IF (PartBound%AdaptiveMacroRestartFileID(Species(iSpec)%Surfaceflux(iSF)%BC).EQ.0 .OR. nMacroRestartFiles.EQ.0) THEN
        IF (.NOT. ALL(Species(iSpec)%Surfaceflux(iSF)%VeloVecIC(:).eq.0.)) THEN
          Species(iSpec)%Surfaceflux(iSF)%VeloVecIC = Species(iSpec)%Surfaceflux(iSF)%VeloVecIC &
            /SQRT(DOT_PRODUCT(Species(iSpec)%Surfaceflux(iSF)%VeloVecIC,Species(iSpec)%Surfaceflux(iSF)%VeloVecIC))
        END IF
      END IF
    END IF
    IF (noAdaptive) THEN
      Species(iSpec)%Surfaceflux(iSF)%MWTemperatureIC       = GETREAL('Part-Species'//TRIM(hilf2)//'-MWTemperatureIC','0.')
      Species(iSpec)%Surfaceflux(iSF)%PartDensity           = GETREAL('Part-Species'//TRIM(hilf2)//'-PartDensity','0.')
      Species(iSpec)%Surfaceflux(iSF)%ReduceNoise           = GETLOGICAL('Part-Species'//TRIM(hilf2)//'-ReduceNoise','.FALSE.')
      IF (DoPoissonRounding .AND. Species(iSpec)%Surfaceflux(iSF)%ReduceNoise) THEN
        SWRITE(*,*)'WARNING: Poisson sampling not possible for noise reduction of surfacefluxes:'
        SWRITE(*,*)'switching now to Random rounding...'
        DoPoissonRounding   = .FALSE.
      END IF
      IF (DoTimeDepInflow .AND. Species(iSpec)%Surfaceflux(iSF)%ReduceNoise) THEN
        SWRITE(*,*)'WARNING: Time-dependent inflow is not possible for noise reduction of surfacefluxes:'
        SWRITE(*,*)'switching now to Random rounding...'
        DoTimeDepInflow   = .FALSE.
      END IF
    ELSE !Adaptive
      WRITE(UNIT=hilf3,FMT='(I0)') Adaptive_BC_Map(iSF-Species(iSpec)%nSurfacefluxBCs)
      Species(iSpec)%Surfaceflux(iSF)%PressureFraction      = &
        GETREAL('Part-Boundary'//TRIM(hilf3)//'-Species'//TRIM(hilf)//'-Pressurefraction','0.')
      sum_pressurefraction(iSF-Species(iSpec)%nSurfacefluxBCs) = sum_pressurefraction(iSF-Species(iSpec)%nSurfacefluxBCs) &
        + Species(iSpec)%Surfaceflux(iSF)%PressureFraction
      IF (PartBound%AdaptiveMacroRestartFileID(Species(iSpec)%Surfaceflux(iSF)%BC).EQ.0 &
          .OR. PartBound%AdaptiveType(Species(iSpec)%Surfaceflux(iSF)%BC).EQ.1 .OR. nMacroRestartFiles.EQ.0) THEN
        Species(iSpec)%Surfaceflux(iSF)%MWTemperatureIC       = PartBound%AdaptiveTemp(Species(iSpec)%Surfaceflux(iSF)%BC)
        Species(iSpec)%Surfaceflux(iSF)%PartDensity           = Species(iSpec)%Surfaceflux(iSF)%PressureFraction &
          * PartBound%AdaptivePressure(Species(iSpec)%Surfaceflux(iSF)%BC) &
          / (BoltzmannConst * Species(iSpec)%Surfaceflux(iSF)%MWTemperatureIC)
      END IF
      Species(iSpec)%Surfaceflux(iSF)%ReduceNoise           = .FALSE.
    END IF
    IF (TriaSurfaceFlux) THEN
      Species(iSpec)%Surfaceflux(iSF)%AcceptReject=.FALSE.
    ELSE
      Species(iSpec)%Surfaceflux(iSF)%AcceptReject          = GETLOGICAL('Part-Species'//TRIM(hilf2)//'-AcceptReject','.TRUE.')
    END IF
    IF (Species(iSpec)%Surfaceflux(iSF)%AcceptReject .AND. BezierSampleN.GT.1) THEN
      SWRITE(*,*)'WARNING: BezierSampleN > 0 may not be necessary as ARM is used for SurfaceFlux!'
    ELSE IF (.NOT.Species(iSpec)%Surfaceflux(iSF)%AcceptReject .AND. BezierSampleN.LE.NGeo .AND. .NOT.TriaSurfaceFlux) THEN
      SWRITE(*,*)'WARNING: The choosen small BezierSampleN (def.: NGeo) might result in inhom. SurfFluxes without ARM!'
    END IF
    IF (Species(iSpec)%Surfaceflux(iSF)%AcceptReject) THEN
      IF (noAdaptive) THEN
        WRITE( hilf3, '(I0.2)') NGeo*NGeo*NGeo !1 for linear elements, this is an arbitray estimation for higher N!
        Species(iSpec)%Surfaceflux(iSF)%ARM_DmaxSampleN = GETINT('Part-Species'//TRIM(hilf2)//'-ARM_DmaxSampleN',hilf3)
      ELSE !Adaptive
        Species(iSpec)%Surfaceflux(iSF)%ARM_DmaxSampleN = NGeo*NGeo*NGeo
      END IF
    ELSE
      Species(iSpec)%Surfaceflux(iSF)%ARM_DmaxSampleN = 0
    END IF
  END DO !iSF
END DO ! iSpec
IF (nAdaptiveBC.GT.0) THEN
  IF( (MINVAL(sum_pressurefraction(:)).LT.0.99).OR.(MAXVAL(sum_pressurefraction(:)).GT.1.01) ) CALL abort( &
__STAMP__&
, 'Sum of all pressurefractions .NE. 1')
END IF

SDEALLOCATE(Adaptive_BC_Map)
SDEALLOCATE(Adaptive_Found_Flag)

#ifdef MPI
CALL MPI_ALLREDUCE(MPI_IN_PLACE,DoPoissonRounding,1,MPI_LOGICAL,MPI_LAND,PartMPI%COMM,iError) !set T if this is for all procs
CALL MPI_ALLREDUCE(MPI_IN_PLACE,DoTimeDepInflow,1,MPI_LOGICAL,MPI_LAND,PartMPI%COMM,iError) !set T if this is for all procs
#endif  /*MPI*/

!-- 2.: create Side lists for applicable BCs
!--- 2a: temporary (linked) lists
ALLOCATE(TmpMapToBC(1:nDataBC) &
        ,TmpSideStart(1:nDataBC) &
        ,TmpSideNumber(1:nDataBC) &
        ,TmpSideEnd(1:nDataBC) &
        ,TmpSideNext(1:nBCSides)) !Next: Sides of diff. BCs ar not overlapping!
TmpMapToBC = 0
TmpSideStart = 0
TmpSideNumber = 0
TmpSideEnd = 0
TmpSideNext = 0
nDataBC=0
DO iBC=1,nPartBound
  IF (BCdata_auxSF(iBC)%SideNumber.EQ. -1) CYCLE !not set for SFs or CollectCharges
  nDataBC=nDataBC+1
  TmpMapToBC(nDataBC)=iBC
END DO
DO BCSideID=1,nBCSides
  currentBC=0
  DO iBC=1,nDataBC
    IF (PartBound%MapToPartBC(BC(BCSideID)) .EQ. TmpMapToBC(iBC)) currentBC=iBC
  END DO
  IF (currentBC.EQ.0) CYCLE
  IF (TmpSideNumber(currentBC).EQ.0) THEN
    TmpSideStart(currentBC) = BCSideID ! Start of Linked List for Sides
  ELSE
    TmpSideNext(TmpSideEnd(currentBC)) = BCSideID ! Next Side
  END IF
  !-- prepare for next entry in list
  TmpSideEnd(currentBC) = BCSideID
  TmpSideNumber(currentBC) = TmpSideNumber(currentBC) + 1  ! Number of Sides
END DO ! BCSideID
IF (AnySimpleRadialVeloFit) THEN
  ALLOCATE(nType0(1:MaxSurfacefluxBCs,1:nSpecies), &
    nType1(1:MaxSurfacefluxBCs,1:nSpecies), &
    nType2(1:MaxSurfacefluxBCs,1:nSpecies) )
  nType0=0
  nType1=0
  nType2=0
END IF
!--- 2b: save sequential lists in BCdata_auxSF
DO iBC=1,nDataBC
  BCdata_auxSF(TmpMapToBC(iBC))%SideNumber=TmpSideNumber(iBC)
  IF (TmpSideNumber(iBC).EQ.0) CYCLE
  ALLOCATE(BCdata_auxSF(TmpMapToBC(iBC))%SideList(1:TmpSideNumber(iBC)))
  IF (TriaSurfaceFlux) THEN
    ALLOCATE(BCdata_auxSF(TmpMapToBC(iBC))%TriaSwapGeo(SurfFluxSideSize(1),SurfFluxSideSize(2),1:TmpSideNumber(iBC)))
    ALLOCATE(BCdata_auxSF(TmpMapToBC(iBC))%TriaSideGeo(1:TmpSideNumber(iBC)))
  END IF
  DO iSpec=1,nSpecies
    DO iSF=1,Species(iSpec)%nSurfacefluxBCs+nAdaptiveBC
      IF (TmpMapToBC(iBC).EQ.Species(iSpec)%Surfaceflux(iSF)%BC) THEN !only surfacefluxes with iBC
        ALLOCATE(Species(iSpec)%Surfaceflux(iSF)%SurfFluxSubSideData(SurfFluxSideSize(1),SurfFluxSideSize(2),1:TmpSideNumber(iBC)) )
        IF (AnySimpleRadialVeloFit .AND. (iSF .LE. Species(iSpec)%nSurfacefluxBCs)) THEN
          ALLOCATE(Species(iSpec)%Surfaceflux(iSF)%SurfFluxSideRejectType(1:TmpSideNumber(iBC)) )
        END IF
      END IF
    END DO
  END DO
  BCSideID=TmpSideStart(iBC)
  iCount=0
  DO !follow BCSideID list seq. with iCount
    iCount=iCount+1
    BCdata_auxSF(TmpMapToBC(iBC))%SideList(iCount)=BCSideID
    IF (TriaSurfaceFlux) THEN
      ElemID = SideToElem(1,BCSideID)
      IF (ElemID.LT.1) THEN !not sure if necessary
        ElemID = SideToElem(2,BCSideID)
        iLocSide = SideToElem(4,BCSideID)
      ELSE
        iLocSide = SideToElem(3,BCSideID)
      END IF
      SideID=PartElemToSide(E2S_SIDE_ID,ilocSide,ElemID)

      IF (.NOT.TriaTracking) THEN !check that all sides are planar if TriaSurfaceFlux is used for tracing or refmapping
        IF (SideType(SideID).NE.PLANAR_RECT .AND. SideType(SideID).NE.PLANAR_NONRECT) CALL abort(&
__STAMP__&
,'every surfaceflux-sides must be planar if TriaSurfaceFlux is used for tracing or refmapping!!!')
      END IF !.NOT.TriaTracking

      DO jSample=1,SurfFluxSideSize(2); DO iSample=1,SurfFluxSideSize(1)
        CALL CalcNormAndTangTriangle(SideID=SideID &
          ,midpoint=BCdata_auxSF(TmpMapToBC(iBC))%TriaSwapGeo(iSample,jSample,iCount)%midpoint &
          ,ndist=BCdata_auxSF(TmpMapToBC(iBC))%TriaSwapGeo(iSample,jSample,iCount)%ndist &
          ,xyzNod=BCdata_auxSF(TmpMapToBC(iBC))%TriaSideGeo(iCount)%xyzNod &
          ,Vectors=BCdata_auxSF(TmpMapToBC(iBC))%TriaSideGeo(iCount)%Vectors &
          ,TriNum=jSample,ElemID_opt=ElemID,LocSideID_opt=ilocSide)
      END DO; END DO
    END IF !TriaSurfaceFlux

    !-- BC-list specific data
    DO jSample=1,SurfFluxSideSize(2); DO iSample=1,SurfFluxSideSize(1)
      BCdata_auxSF(TmpMapToBC(iBC))%LocalArea = BCdata_auxSF(TmpMapToBC(iBC))%LocalArea &
        + SurfMeshSubSideData(iSample,jSample,BCSideID)%area
    END DO; END DO

    !-- next Side
    IF (BCSideID .EQ. TmpSideEnd(iBC)) THEN
      IF (TmpSideNumber(iBC).NE.iCount) THEN
        CALL abort(&
__STAMP__&
,'Someting is wrong with TmpSideNumber of iBC',iBC,999.)
      ELSE
        IF(OutputSurfaceFluxLinked)THEN
          IPWRITE(*,'(I4,I7,A53,I0)') iCount,' Sides have been found for Surfaceflux-linked PartBC ',TmpMapToBC(iBC)
        END IF
        DoSurfaceFlux=.TRUE.
        EXIT
      END IF
    END IF
    BCSideID=TmpSideNext(BCSideID)
  END DO ! BCSideID (iCount)
END DO !iBC
!-- communicate areas
#ifdef MPI
   ALLOCATE( areasLoc(1:nPartBound) , areasGlob(1:nPartBound) )
   areasLoc=0.
   areasGlob=0.
   DO iPartBound=1,nPartBound
     areasLoc(iPartBound)=BCdata_auxSF(iPartBound)%LocalArea
   END DO
   CALL MPI_ALLREDUCE(areasLoc,areasGlob,nPartBound,MPI_DOUBLE_PRECISION,MPI_SUM,PartMPI%COMM,IERROR)
#endif
   DO iPartBound=1,nPartBound
#ifdef MPI
     BCdata_auxSF(iPartBound)%GlobalArea=areasGlob(iPartBound)
#else
     BCdata_auxSF(iPartBound)%GlobalArea=BCdata_auxSF(iPartBound)%LocalArea
#endif
!     IPWRITE(*,'(I4,A,I4,2(x,E16.8))') 'areas:-', &
!       iPartBound,BCdata_auxSF(iPartBound)%GlobalArea,BCdata_auxSF(iPartBound)%LocalArea
   END DO
#ifdef MPI
   DEALLOCATE(areasLoc,areasGlob)
#endif

DEALLOCATE(TmpMapToBC &
          ,TmpSideStart &
          ,TmpSideNumber &
          ,TmpSideEnd &
          ,TmpSideNext) 

!-- 3.: initialize Surfaceflux-specific data
! Allocate sampling of near adaptive boundary element values
IF(nAdaptiveBC.GT.0)THEN
  ALLOCATE(Adaptive_MacroVal(1:DSMC_NVARS,1:nElems,1:nSpecies))
  Adaptive_MacroVal(:,:,:)=0
  ! If restart is done, check if adptiveinfo exists in state, read it in and write to adaptive_macrovalues
  AdaptiveInitDone = .FALSE.
  IF (DoRestart) THEN
    CALL OpenDataFile(RestartFile,create=.FALSE.,single=.FALSE.,readOnly=.TRUE.,communicatorOpt=MPI_COMM_WORLD)
    ! read local ParticleInfo from HDF5
    CALL DatasetExists(File_ID,'nAdaptiveBC',AdaptiveDataExists,attrib=.TRUE.)
    IF(AdaptiveDataExists)THEN
      AdaptiveInitDone = .TRUE.
      ALLOCATE(ElemData_HDF5(1:4,1:nSpecies,1:nElems))
      CALL ReadArray('AdaptiveInfo',3,(/4, nSpecies, nElems/),offsetElem,3,RealArray=ElemData_HDF5(:,:,:))
      DO iElem = 1,nElems
        Adaptive_MacroVal(DSMC_VELOX,iElem,:)   = ElemData_HDF5(1,:,iElem)
        Adaptive_MacroVal(DSMC_VELOY,iElem,:)   = ElemData_HDF5(2,:,iElem)
        Adaptive_MacroVal(DSMC_VELOZ,iElem,:)   = ElemData_HDF5(3,:,iElem)
        Adaptive_MacroVal(DSMC_DENSITY,iElem,:) = ElemData_HDF5(4,:,iElem)
      END DO
      SDEALLOCATE(ElemData_HDF5)
    END IF
    CALL CloseDataFile()
  END IF
END IF

DO iSpec=1,nSpecies
  DO iSF=1,Species(iSpec)%nSurfacefluxBCs+nAdaptiveBC
    IF (iSF .LE. Species(iSpec)%nSurfacefluxBCs) THEN
      noAdaptive=.TRUE.
    ELSE
      noAdaptive=.FALSE.
    END IF
    !--- 3a: SF-specific data of Sides
    currentBC = Species(iSpec)%Surfaceflux(iSF)%BC !go through sides if present in proc...
    IF (BCdata_auxSF(currentBC)%SideNumber.GT.0) THEN
      DO iSide=1,BCdata_auxSF(currentBC)%SideNumber
        BCSideID=BCdata_auxSF(currentBC)%SideList(iSide)
        ElemID = SideToElem(1,BCSideID)
        IF (ElemID.LT.1) THEN !not sure if necessary
          ElemID = SideToElem(2,BCSideID)
          iLocSide = SideToElem(4,BCSideID)
        ELSE
          iLocSide = SideToElem(3,BCSideID)
        END IF
        SideID=PartElemToSide(E2S_SIDE_ID,ilocSide,ElemID)
        IF (Species(iSpec)%Surfaceflux(iSF)%AcceptReject) THEN
          CALL GetBezierSampledAreas(SideID=SideID &
            ,BezierSampleN=BezierSampleN &
            ,BezierSurfFluxProjection_opt=.NOT.Species(iSpec)%Surfaceflux(iSF)%VeloIsNormal &
            ,SurfMeshSubSideAreas=tmp_SubSideAreas &  !SubSide-areas proj. to inwards normals
            ,DmaxSampleN_opt=Species(iSpec)%Surfaceflux(iSF)%ARM_DmaxSampleN &
            ,Dmax_opt=tmp_SubSideDmax &
            ,BezierControlPoints2D_opt=tmp_BezierControlPoints2D)
        ELSE IF (.NOT.TriaSurfaceFlux) THEN
          CALL GetBezierSampledAreas(SideID=SideID &
            ,BezierSampleN=BezierSampleN &
            ,BezierSurfFluxProjection_opt=.NOT.Species(iSpec)%Surfaceflux(iSF)%VeloIsNormal &
            ,SurfMeshSubSideAreas=tmp_SubSideAreas)  !SubSide-areas proj. to inwards normals
        ELSE !TriaSurfaceFlux
          DO jSample=1,SurfFluxSideSize(2); DO iSample=1,SurfFluxSideSize(1)
            tmp_SubSideAreas(iSample,jSample)=SurfMeshSubSideData(iSample,jSample,BCSideID)%area
          END DO; END DO
        END IF
        !-- check where the sides are located relative to rmax (based on corner nodes of bounding box)
        !- RejectType=0 : complete side is inside valid bounds
        !- RejectType=1 : complete side is outside of valid bounds
        !- RejectType=2 : side is partly inside valid bounds
        IF (Species(iSpec)%Surfaceflux(iSF)%SimpleRadialVeloFit) THEN
          CALL GetSideBoundingBox(BCSideID,BoundingBox)
          intersecExists=.FALSE.
          !atan2Shift=0.
          r0inside=.FALSE.
          dir=Species(iSpec)%Surfaceflux(iSF)%dir
          origin=Species(iSpec)%Surfaceflux(iSF)%origin
          Vector1(:)=0.
          Vector2(:)=0.
          Vector3(:)=0.
          xyzNod(1)=MINVAL(BoundingBox(1,:))
          xyzNod(2)=MINVAL(BoundingBox(2,:))
          xyzNod(3)=MINVAL(BoundingBox(3,:))
          VecBoundingBox(1) = MAXVAL(BoundingBox(1,:)) -MINVAL(BoundingBox(1,:))
          VecBoundingBox(2) = MAXVAL(BoundingBox(2,:)) -MINVAL(BoundingBox(2,:))
          VecBoundingBox(3) = MAXVAL(BoundingBox(3,:)) -MINVAL(BoundingBox(3,:))
          Vector1(dir(2)) = VecBoundingBox(dir(2))
          Vector2(dir(2)) = VecBoundingBox(dir(2))
          Vector2(dir(3)) = VecBoundingBox(dir(3))
          Vector3(dir(3)) = VecBoundingBox(dir(3))

          !-- determine rmax (and corners)
          DO iNode=1,4
            SELECT CASE(iNode)
            CASE(1)
              corner = xyzNod
            CASE(2)
              corner = xyzNod + Vector1
            CASE(3)
              corner = xyzNod + Vector2
            CASE(4)
              corner = xyzNod + Vector3
            END SELECT
            corner(dir(2)) = corner(dir(2)) - origin(1)
            corner(dir(3)) = corner(dir(3)) - origin(2)
            corners(1:2,iNode)=(/corner(dir(2)),corner(dir(3))/) !coordinates of orth. dirs
            radiusCorner(1,iNode)=SQRT(corner(dir(2))**2+corner(dir(3))**2)
          END DO !iNode
          rmax=MAXVAL(radiusCorner(1,1:4))

          !-- determine rmin
          DO iNode=1,4
            SELECT CASE(iNode)
            CASE(1)
              point=(/xyzNod(dir(2)),xyzNod(dir(3))/)-origin
              vec=(/Vector1(dir(2)),Vector1(dir(3))/)
            CASE(2)
              point=(/xyzNod(dir(2)),xyzNod(dir(3))/)-origin
              vec=(/Vector3(dir(2)),Vector3(dir(3))/)
            CASE(3)
              point=(/xyzNod(dir(2)),xyzNod(dir(3))/)+(/Vector2(dir(2)),Vector2(dir(3))/)-origin
              vec=(/-Vector1(dir(2)),-Vector1(dir(3))/)
            CASE(4)
              point=(/xyzNod(dir(2)),xyzNod(dir(3))/)+(/Vector2(dir(2)),Vector2(dir(3))/)-origin
              vec=(/-Vector3(dir(2)),-Vector3(dir(3))/)
            END SELECT
            vec=point + MIN(MAX(-DOT_PRODUCT(point,vec)/DOT_PRODUCT(vec,vec),0.),1.)*vec
            radiusCorner(2,iNode)=SQRT(DOT_PRODUCT(vec,vec)) !rmin
          END DO !iNode

          !-- determine if r0 is inside of bounding box
          IF ((origin(1) .GE. MINVAL(BoundingBox(Species(iSpec)%Surfaceflux(iSF)%dir(2),:))) .AND. &
             (origin(1) .LE. MAXVAL(BoundingBox(Species(iSpec)%Surfaceflux(iSF)%dir(2),:))) .AND. &
             (origin(2) .GE. MINVAL(BoundingBox(Species(iSpec)%Surfaceflux(iSF)%dir(3),:))) .AND. &
             (origin(2) .LE. MAXVAL(BoundingBox(Species(iSpec)%Surfaceflux(iSF)%dir(3),:))) ) THEN
             r0inside = .TRUE.
          END IF
          IF (r0inside) THEN
            rmin = 0.
          ELSE
            rmin=MINVAL(radiusCorner(2,1:4))
          END IF
          ! define rejecttype
          IF ( (rmin .GT. Species(iSpec)%Surfaceflux(iSF)%rmax) .OR. (rmax .LT. Species(iSpec)%Surfaceflux(iSF)%rmin) ) THEN
            Species(iSpec)%Surfaceflux(iSF)%SurfFluxSideRejectType(iSide)=1
            nType1(iSF,iSpec)=nType1(iSF,iSpec)+1
          ELSE IF ( (rmax .LE. Species(iSpec)%Surfaceflux(iSF)%rmax) .AND. (rmin .GE. Species(iSpec)%Surfaceflux(iSF)%rmin) ) THEN
            Species(iSpec)%Surfaceflux(iSF)%SurfFluxSideRejectType(iSide)=0
            nType0(iSF,iSpec)=nType0(iSF,iSpec)+1
          ELSE
            Species(iSpec)%Surfaceflux(iSF)%SurfFluxSideRejectType(iSide)=2
            nType2(iSF,iSpec)=nType2(iSF,iSpec)+1
          END IF !  (rmin > Surfaceflux-rmax) .OR. (rmax < Surfaceflux-rmin) 
        END IF !SimpleRadialVeloFit: check r-bounds
        IF (noAdaptive) THEN
          DO jSample=1,SurfFluxSideSize(2); DO iSample=1,SurfFluxSideSize(1)
            vec_nIn = SurfMeshSubSideData(iSample,jSample,BCSideID)%vec_nIn
            vec_t1 = SurfMeshSubSideData(iSample,jSample,BCSideID)%vec_t1
            vec_t2 = SurfMeshSubSideData(iSample,jSample,BCSideID)%vec_t2
            IF (.NOT.Species(iSpec)%Surfaceflux(iSF)%VeloIsNormal) THEN
              projFak = DOT_PRODUCT(vec_nIn,Species(iSpec)%Surfaceflux(iSF)%VeloVecIC) !VeloVecIC projected to inwards normal
            ELSE
              projFak = 1.
            END IF
            v_thermal = SQRT(2.*BoltzmannConst*Species(iSpec)%Surfaceflux(iSF)%MWTemperatureIC/Species(iSpec)%MassIC) !thermal speed
            a = 0 !dummy for projected speed ratio in constant v-distri
            !-- compute total volume flow rate through surface
            SELECT CASE(TRIM(Species(iSpec)%Surfaceflux(iSF)%velocityDistribution))
            CASE('constant')
              vSF = Species(iSpec)%Surfaceflux(iSF)%VeloIC * projFak !Velo proj. to inwards normal
              nVFR = MAX(tmp_SubSideAreas(iSample,jSample) * vSF,0.) !VFR proj. to inwards normal (only positive parts!)
            CASE('maxwell','maxwell_lpn')
              IF ( ALMOSTEQUAL(v_thermal,0.)) THEN
                CALL abort(&
__STAMP__&
,'Something is wrong with the Surfaceflux parameters!')
              END IF
              a = Species(iSpec)%Surfaceflux(iSF)%VeloIC * projFak / v_thermal !speed ratio proj. to inwards n (can be negative!)
              vSF = v_thermal / (2.0*SQRT(PI)) * ( EXP(-(a*a)) + a*SQRT(PI)*(1+ERF(a)) ) !mean flux velocity through normal sub-face
              nVFR = tmp_SubSideAreas(iSample,jSample) * vSF !VFR projected to inwards normal of sub-side
            CASE DEFAULT
              CALL abort(&
__STAMP__&
,'wrong velo-distri for Surfaceflux!')
            END SELECT
            IF (Species(iSpec)%Surfaceflux(iSF)%SimpleRadialVeloFit) THEN !check rmax-rejection
              IF (Species(iSpec)%Surfaceflux(iSF)%SurfFluxSideRejectType(iSide).EQ.1) THEN ! complete side is outside of valid bounds
                nVFR = 0.
              END IF
            END IF
            Species(iSpec)%Surfaceflux(iSF)%VFR_total = Species(iSpec)%Surfaceflux(iSF)%VFR_total + nVFR
            !-- store SF-specific SubSide data in SurfFluxSubSideData (incl. projected velos)
            Species(iSpec)%Surfaceflux(iSF)%SurfFluxSubSideData(iSample,jSample,iSide)%nVFR = nVFR
            Species(iSpec)%Surfaceflux(iSF)%SurfFluxSubSideData(iSample,jSample,iSide)%projFak = projFak
            Species(iSpec)%Surfaceflux(iSF)%SurfFluxSubSideData(iSample,jSample,iSide)%a_nIn = a
            IF (.NOT.Species(iSpec)%Surfaceflux(iSF)%VeloIsNormal) THEN
              Species(iSpec)%Surfaceflux(iSF)%SurfFluxSubSideData(iSample,jSample,iSide)%Velo_t1 &
                = Species(iSpec)%Surfaceflux(iSF)%VeloIC &
                * DOT_PRODUCT(vec_t1,Species(iSpec)%Surfaceflux(iSF)%VeloVecIC) !v in t1-dir
              Species(iSpec)%Surfaceflux(iSF)%SurfFluxSubSideData(iSample,jSample,iSide)%Velo_t2 &
                = Species(iSpec)%Surfaceflux(iSF)%VeloIC &
                * DOT_PRODUCT(vec_t2,Species(iSpec)%Surfaceflux(iSF)%VeloVecIC) !v in t2-dir
            ELSE
              Species(iSpec)%Surfaceflux(iSF)%SurfFluxSubSideData(iSample,jSample,iSide)%Velo_t1 = 0. !v in t1-dir
              Species(iSpec)%Surfaceflux(iSF)%SurfFluxSubSideData(iSample,jSample,iSide)%Velo_t2 = 0. !v in t2-dir
            END IF! .NOT.VeloIsNormal
          END DO; END DO !jSample=1,SurfFluxSideSize(2); iSample=1,SurfFluxSideSize(1)
        END IF
        DO jSample=1,SurfFluxSideSize(2); DO iSample=1,SurfFluxSideSize(1)
          IF (Species(iSpec)%Surfaceflux(iSF)%AcceptReject) THEN
            Species(iSpec)%Surfaceflux(iSF)%SurfFluxSubSideData(iSample,jSample,iSide)%Dmax = tmp_SubSideDmax(iSample,jSample)
            IF (.NOT.Species(iSpec)%Surfaceflux(iSF)%VeloIsNormal) THEN
              ALLOCATE(Species(iSpec)%Surfaceflux(iSF)%SurfFluxSubSideData(iSample,jSample &
                                                                          ,iSide)%BezierControlPoints2D(1:2,0:NGeo,0:NGeo))
              DO iCopy1=0,NGeo; DO iCopy2=0,NGeo; DO iCopy3=1,2
                Species(iSpec)%Surfaceflux(iSF)%SurfFluxSubSideData(iSample,jSample &
                                                                   ,iSide)%BezierControlPoints2D(iCopy3,iCopy2,iCopy1) &
                  = tmp_BezierControlPoints2D(iCopy3,iCopy2,iCopy1,iSample,jSample)
              END DO; END DO; END DO
            END IF !.NOT.VeloIsNormal
          END IF
        END DO; END DO !jSample=1,SurfFluxSideSize(2); iSample=1,SurfFluxSideSize(1)
        IF (.NOT.noAdaptive) THEN
          IF (.NOT.AdaptiveInitDone) THEN
            ! initialize velocity, trans_temperature and density of macrovalues
            FileID = PartBound%AdaptiveMacroRestartFileID(Species(iSpec)%Surfaceflux(iSF)%BC)
            IF (FileID.GT.0 .AND. FileID.LE.nMacroRestartFiles) THEN
              Adaptive_MacroVal(DSMC_VELOX,ElemID,iSpec) = MacroRestartData_tmp(DSMC_VELOX,ElemID,iSpec,FileID)
              Adaptive_MacroVal(DSMC_VELOY,ElemID,iSpec) = MacroRestartData_tmp(DSMC_VELOY,ElemID,iSpec,FileID)
              Adaptive_MacroVal(DSMC_VELOZ,ElemID,iSpec) = MacroRestartData_tmp(DSMC_VELOZ,ElemID,iSpec,FileID)
              Adaptive_MacroVal(DSMC_TEMPX,ElemID,iSpec) = MAX(0.,MacroRestartData_tmp(DSMC_TEMPX,iElem,iSpec,FileID))
              Adaptive_MacroVal(DSMC_TEMPY,ElemID,iSpec) = MAX(0.,MacroRestartData_tmp(DSMC_TEMPY,iElem,iSpec,FileID))
              Adaptive_MacroVal(DSMC_TEMPZ,ElemID,iSpec) = MAX(0.,MacroRestartData_tmp(DSMC_TEMPZ,iElem,iSpec,FileID))
              Adaptive_MacroVal(DSMC_DENSITY,ElemID,iSpec) = MacroRestartData_tmp(DSMC_DENSITY,ElemID,iSpec,FileID)
            ELSE
              Adaptive_MacroVal(DSMC_VELOX,ElemID,iSpec) = Species(iSpec)%Surfaceflux(iSF)%VeloIC &
                  * Species(iSpec)%Surfaceflux(iSF)%VeloVecIC(1)
              Adaptive_MacroVal(DSMC_VELOY,ElemID,iSpec) = Species(iSpec)%Surfaceflux(iSF)%VeloIC &
                  * Species(iSpec)%Surfaceflux(iSF)%VeloVecIC(2)
              Adaptive_MacroVal(DSMC_VELOZ,ElemID,iSpec) = Species(iSpec)%Surfaceflux(iSF)%VeloIC &
                  * Species(iSpec)%Surfaceflux(iSF)%VeloVecIC(3)
              Adaptive_MacroVal(DSMC_TEMPX,ElemID,iSpec) = Species(iSpec)%Surfaceflux(iSF)%MWTemperatureIC / SQRT(3.)
              Adaptive_MacroVal(DSMC_TEMPY,ElemID,iSpec) = Species(iSpec)%Surfaceflux(iSF)%MWTemperatureIC / SQRT(3.)
              Adaptive_MacroVal(DSMC_TEMPZ,ElemID,iSpec) = Species(iSpec)%Surfaceflux(iSF)%MWTemperatureIC / SQRT(3.)
              Adaptive_MacroVal(DSMC_DENSITY,ElemID,iSpec) = Species(iSpec)%Surfaceflux(iSF)%PartDensity
            END IF
          END IF
        END IF
      END DO ! iSide

    ELSE IF (BCdata_auxSF(currentBC)%SideNumber.EQ.-1) THEN
      CALL abort(&
__STAMP__&
,'ERROR in ParticleSurfaceflux: Someting is wrong with SideNumber of BC ',currentBC)
    END IF
#ifdef CODE_ANALYZE
    IF (BCdata_auxSF(currentBC)%SideNumber.GT.0 .AND. Species(iSpec)%Surfaceflux(iSF)%SimpleRadialVeloFit) THEN
      IPWRITE(*,'(I4,A,2(x,I0),A,3(x,I0))') ' For Surfaceflux/Spec',iSF,iSpec,' are nType0,1,2: ' &
                                            , nType0(iSF,iSpec),nType1(iSF,iSpec),nType2(iSF,iSpec)
    END IF
#endif /*CODE_ANALYZE*/

    !--- 3b: ReduceNoise initialization
    IF (Species(iSpec)%Surfaceflux(iSF)%ReduceNoise) THEN
      IF(MPIroot)THEN
        ALLOCATE(Species(iSpec)%Surfaceflux(iSF)%VFR_total_allProcs(0:nProcessors-1))
        Species(iSpec)%Surfaceflux(iSF)%VFR_total_allProcs=0.
      ELSE
        ALLOCATE(Species(iSpec)%Surfaceflux(iSF)%VFR_total_allProcs(1)) !dummy for debug
      END IF !MPIroot
#ifdef MPI
      CALL MPI_GATHER(Species(iSpec)%Surfaceflux(iSF)%VFR_total,1,MPI_DOUBLE_PRECISION &
        ,Species(iSpec)%Surfaceflux(iSF)%VFR_total_allProcs,1,MPI_DOUBLE_PRECISION,0,PartMPI%COMM,iError)
      IF(MPIroot)THEN
        DO iProc=0,PartMPI%nProcs-1
          Species(iSpec)%Surfaceflux(iSF)%VFR_total_allProcsTotal = Species(iSpec)%Surfaceflux(iSF)%VFR_total_allProcsTotal &
            + Species(iSpec)%Surfaceflux(iSF)%VFR_total_allProcs(iProc)
        END DO
      END IF
#else  /*MPI*/
      Species(iSpec)%Surfaceflux(iSF)%VFR_total_allProcs=Species(iSpec)%Surfaceflux(iSF)%VFR_total
      Species(iSpec)%Surfaceflux(iSF)%VFR_total_allProcsTotal=Species(iSpec)%Surfaceflux(iSF)%VFR_total
#endif  /*MPI*/
    END IF !ReduceNoise
  END DO !iSF
END DO !iSpec

!-- write debug-mesh for tria-surfflux
IF (WriteTriaSurfaceFluxDebugMesh) THEN
  !count sides
  nSides=0
  DO iSpec=1,nSpecies
    DO iSF=1,Species(iSpec)%nSurfacefluxBCs+nAdaptiveBC
      currentBC = Species(iSpec)%Surfaceflux(iSF)%BC !go through sides if present in proc...
      IF (BCdata_auxSF(currentBC)%SideNumber.GT.0) THEN
        nSides=nSides+BCdata_auxSF(currentBC)%SideNumber
      ELSE IF (BCdata_auxSF(currentBC)%SideNumber.EQ.-1) THEN
        CALL abort(&
  __STAMP__&
  ,'ERROR in ParticleSurfaceflux: Someting is wrong with SideNumber of BC ',currentBC)
      END IF
    END DO !iSF
  END DO !iSpec
  WRITE(UNIT=hilf,FMT='(I4.4)') myRank
  OPEN(UNIT   = 103, &
         FILE   = 'Tria-Surfflux-debugmesh_'//TRIM(hilf)//'.tec' ,&
         STATUS = 'UNKNOWN')
  WRITE(103,*) 'TITLE="Tria-Surfflux-debugmesh" '
  WRITE(103,'(102a)') 'VARIABLES ="x","y","z","BC","iSF","iSpec"'
  WRITE(103,*) 'ZONE NODES=',4*nSides,', ELEMENTS=',2*nSides,'DATAPACKING=POINT, ZONETYPE=FEQUADRILATERAL'
  ! Write nodes
  DO iSpec=1,nSpecies
    DO iSF=1,Species(iSpec)%nSurfacefluxBCs+nAdaptiveBC
      currentBC = Species(iSpec)%Surfaceflux(iSF)%BC !go through sides if present in proc...
      IF (BCdata_auxSF(currentBC)%SideNumber.GT.0) THEN
        DO iSide=1,BCdata_auxSF(currentBC)%SideNumber
          BCSideID=BCdata_auxSF(currentBC)%SideList(iSide)
          ElemID = SideToElem(1,BCSideID)
          IF (ElemID.LT.1) THEN !not sure if necessary
            ElemID = SideToElem(2,BCSideID)
            iLocSide = SideToElem(4,BCSideID)
          ELSE
            iLocSide = SideToElem(3,BCSideID)
          END IF
          !WRITE(103,'(3(F0.10,1X),3(I0,1X))')GEO%NodeCoords(1:3,1,iLocSide,ElemID),currentBC,iSF,iSpec
          !WRITE(103,'(3(F0.10,1X),3(I0,1X))')GEO%NodeCoords(1:3,2,iLocSide,ElemID),currentBC,iSF,iSpec
          !WRITE(103,'(3(F0.10,1X),3(I0,1X))')GEO%NodeCoords(1:3,3,iLocSide,ElemID),currentBC,iSF,iSpec
          !WRITE(103,'(3(F0.10,1X),3(I0,1X))')GEO%NodeCoords(1:3,4,iLocSide,ElemID),currentBC,iSF,iSpec
          WRITE(103,'(3(F0.10,1X),3(I0,1X))')BCdata_auxSF(currentBC)%TriaSideGeo(iSide)%xyzNod,currentBC,iSF,iSpec
          WRITE(103,'(3(F0.10,1X),3(I0,1X))')BCdata_auxSF(currentBC)%TriaSideGeo(iSide)%xyzNod &
            +BCdata_auxSF(currentBC)%TriaSideGeo(iSide)%Vectors(:,1),currentBC,iSF,iSpec
          WRITE(103,'(3(F0.10,1X),3(I0,1X))')BCdata_auxSF(currentBC)%TriaSideGeo(iSide)%xyzNod &
            +BCdata_auxSF(currentBC)%TriaSideGeo(iSide)%Vectors(:,2),currentBC,iSF,iSpec
          WRITE(103,'(3(F0.10,1X),3(I0,1X))')BCdata_auxSF(currentBC)%TriaSideGeo(iSide)%xyzNod &
            +BCdata_auxSF(currentBC)%TriaSideGeo(iSide)%Vectors(:,3),currentBC,iSF,iSpec
        END DO ! iSide
      END IF
    END DO !iSF
  END DO !iSpec
  ! Write sides
  nSides=0
  DO iSpec=1,nSpecies
    DO iSF=1,Species(iSpec)%nSurfacefluxBCs+nAdaptiveBC
      currentBC = Species(iSpec)%Surfaceflux(iSF)%BC !go through sides if present in proc...
      IF (BCdata_auxSF(currentBC)%SideNumber.GT.0) THEN
        DO iSide=1,BCdata_auxSF(currentBC)%SideNumber
          WRITE(103,'(4(I0,1X))')nSides*4+1,nSides*4+2,nSides*4+3,nSides*4+3 !1. tria
          WRITE(103,'(4(I0,1X))')nSides*4+1,nSides*4+3,nSides*4+4,nSides*4+4 !2. tria
          nSides=nSides+1
        END DO ! iSide
      END IF
    END DO !iSF
  END DO !iSpec
  CLOSE(103)
END IF !TriaSurfaceFlux

#ifdef MPI
CALL MPI_ALLREDUCE(MPI_IN_PLACE,DoSurfaceFlux,1,MPI_LOGICAL,MPI_LOR,PartMPI%COMM,iError) !set T if at least 1 proc have SFs
#endif  /*MPI*/
IF (.NOT.DoSurfaceFlux) THEN !-- no SFs defined
  SWRITE(*,*) 'WARNING: No Sides for SurfacefluxBCs found! DoSurfaceFlux is now disabled!'
END IF
DoForceFreeSurfaceFlux = GETLOGICAL('DoForceFreeSurfaceFlux','.FALSE.')

#ifdef MPI
CALL MPI_BARRIER(PartMPI%COMM,iError)
#endif /*MPI*/


END SUBROUTINE InitializeParticleSurfaceflux


SUBROUTINE ParticleSurfaceflux()
!===================================================================================================================================
! Particle Inserting via Surface Flux and (if present) adaptiveBC (Surface Flux adapting part density, velocity or temperature)
!===================================================================================================================================
! Modules
#ifdef MPI
USE MOD_Particle_MPI_Vars,ONLY: PartMPI
#endif /* MPI*/
USE MOD_Globals
USE MOD_Globals_Vars          , ONLY: PI, BoltzmannConst
#if (PP_TimeDiscMethod==1)||(PP_TimeDiscMethod==2)||(PP_TimeDiscMethod==6)||(PP_TimeDiscMethod>=501 && PP_TimeDiscMethod<=506)
USE MOD_Timedisc_Vars         , ONLY : iter
#endif
USE MOD_Particle_Vars
USE MOD_PIC_Vars
USE MOD_part_tools             ,ONLY : UpdateNextFreePosition
USE MOD_DSMC_Vars              ,ONLY : useDSMC, CollisMode, SpecDSMC, DSMC, PartStateIntEn
USE MOD_SurfaceModel_Vars      ,ONLY : Adsorption, Liquid
USE MOD_DSMC_Analyze           ,ONLY : CalcWallSample
USE MOD_DSMC_Init              ,ONLY : DSMC_SetInternalEnr_LauxVFD
USE MOD_DSMC_PolyAtomicModel   ,ONLY : DSMC_SetInternalEnr_Poly
USE MOD_Particle_Boundary_Vars ,ONLY : SurfMesh, PartBound, nAdaptiveBC, nSurfSample
USE MOD_TimeDisc_Vars          ,ONLY : TEnd, time
#if (PP_TimeDiscMethod==300)
!USE MOD_FPFlow_Init,   ONLY : SetInternalEnr_InitFP
#endif
USE MOD_Particle_Analyze_Vars  ,ONLY: CalcPartBalance
#if (PP_TimeDiscMethod==1)||(PP_TimeDiscMethod==2)||(PP_TimeDiscMethod==6)||(PP_TimeDiscMethod>=501 && PP_TimeDiscMethod<=506)
USE MOD_Particle_Analyze_Vars  ,ONLY: nPartInTmp,PartEkinInTmp,PartAnalyzeStep
#endif
USE MOD_Particle_Analyze_Vars  ,ONLY: nPartIn,PartEkinIn
USE MOD_Timedisc_Vars          ,ONLY: RKdtFrac,RKdtFracTotal,Time
USE MOD_Particle_Analyze       ,ONLY: CalcEkinPart
USE MOD_Mesh_Vars              ,ONLY: SideToElem
USE MOD_Particle_Mesh_Vars     ,ONLY: PartElemToSide
#ifdef CODE_ANALYZE
USE MOD_Particle_Mesh_Vars     ,ONLY: GEO
#endif /*CODE_ANALYZE*/ 
USE MOD_Particle_Surfaces_Vars ,ONLY: BCdata_auxSF, SurfMeshSubSideData!, SideType
USE MOD_Timedisc_Vars          ,ONLY: dt
USE MOD_Particle_Tracking_Vars ,ONLY: TriaTracking
#if defined(IMPA) || defined(ROS)
USE MOD_Particle_Tracking_Vars ,ONLY: DoRefMapping
#endif /*IMPA*/
USE MOD_Particle_Surfaces_Vars ,ONLY: BezierControlPoints3D,BezierSampleXi,SurfFluxSideSize,TriaSurfaceFlux
USE MOD_Particle_Surfaces      ,ONLY: EvaluateBezierPolynomialAndGradient
USE MOD_Mesh_Vars              ,ONLY: NGeo!,XCL_NGeo,XiCL_NGeo,wBaryCL_NGeo
!USE MOD_Particle_Mesh_Vars     ,ONLY: epsInCell
USE MOD_Eval_xyz               ,ONLY: GetPositionInRefElem!, TensorProductInterpolation
#ifdef CODE_ANALYZE
!USE MOD_Timedisc_Vars          ,ONLY: iStage,nRKStages
#if  defined(IMPA) || defined(ROS)
USE MOD_Timedisc_Vars          ,ONLY: iStage,nRKStages
#endif
#endif /*CODE_ANALYZE*/
#if (PP_TimeDiscMethod==1000) || (PP_TimeDiscMethod==1001)
USE MOD_LD_Init                ,ONLY : CalcDegreeOfFreedom
USE MOD_LD_Vars
#endif
USE MOD_Mesh_Vars,              ONLY : BC!, ElemBaryNGeo
#if USE_LOADBALANCE
USE MOD_LoadBalance_Vars,       ONLY:nSurfacefluxPerElem
USE MOD_LoadBalance_tools,      ONLY:LBStartTime, LBElemSplitTime, LBPauseTime
#endif /*USE_LOADBALANCE*/
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
! Local variable declaration                                                                       
INTEGER                     :: iSpec , PositionNbr, iSF, iSide, currentBC, SideID, iLoop
INTEGER                     :: NbrOfParticle, ExtraParts
INTEGER                     :: BCSideID, ElemID, iLocSide, iSample, jSample, PartInsSF, PartInsSubSide, iPart, iPartTotal, IntSample
INTEGER                     :: ParticleIndexNbr, allocStat
REAL                        :: PartIns,VFR_total
REAL                        :: Particle_pos(3), RandVal1, RandVal2(2), xNod,yNod,zNod
REAL,ALLOCATABLE            :: particle_positions(:), particle_xis(:)
INTEGER(KIND=8)             :: inserted_Particle_iter,inserted_Particle_time,inserted_Particle_diff
INTEGER,ALLOCATABLE         :: PartInsProc(:),PartInsSubSides(:,:,:)
REAL                        :: xiab(1:2,1:2),xi(2),E,F,G,D,gradXiEta2D(1:2,1:2),gradXiEta3D(1:2,1:3)
REAL                        :: point(2),origin(2),veloR,vTot,phi,radius,preFac,powerFac,shiftFac
INTEGER                     :: dir(3), nReject, allowedRejections
LOGICAL                     :: AcceptPos, noAdaptive
!variables used for sampling of of energies and impulse of emitted particles from surfaces
INTEGER                     :: PartsEmitted
REAL                        :: TransArray(1:6),IntArray(1:6)
REAL                        :: VelXold, VelYold, VelZold, VeloReal
REAL                        :: EtraOld, EtraWall, EtraNew
REAL                        :: ErotOld, ErotWall, ErotNew
REAL                        :: EvibOld, EvibWall, EVibNew
REAL                        :: Vector1(3),Vector2(3),PartDistance,ndist(3),midpoint(3),AreasTria(2)
INTEGER                     :: p,q,SurfSideID,PartID,Node1,Node2,ExtraPartsTria(2)
REAL                        :: ElemPartDensity, VeloVec(1:3), VeloIC
REAL                        :: VeloVecIC(1:3), ProjFak, v_thermal, a, T, vSF, nVFR,vec_nIn(1:3), pressure
#if USE_LOADBALANCE
! load balance
REAL                        :: tLBStart
#endif /*USE_LOADBALANCE*/
TYPE(tSurfFluxLink),POINTER :: currentSurfFluxPart => NULL()
!===================================================================================================================================

DO iSpec=1,nSpecies
  DO iSF=1,Species(iSpec)%nSurfacefluxBCs+nAdaptiveBC
    PartsEmitted = 0
    IF (iSF .LE. Species(iSpec)%nSurfacefluxBCs) THEN
      noAdaptive=.TRUE.
    ELSE
      noAdaptive=.FALSE.
    END IF
    currentBC = Species(iSpec)%Surfaceflux(iSF)%BC
    NbrOfParticle = 0 ! calculated within (sub)side-Loops!
    iPartTotal=0
    
    IF (Species(iSpec)%Surfaceflux(iSF)%SimpleRadialVeloFit) THEN
      dir   =Species(iSpec)%Surfaceflux(iSF)%dir
      origin=Species(iSpec)%Surfaceflux(iSF)%origin
      preFac=Species(iSpec)%Surfaceflux(iSF)%preFac
      powerFac=Species(iSpec)%Surfaceflux(iSF)%powerFac
      shiftFac=Species(iSpec)%Surfaceflux(iSF)%shiftFac
    END IF
    !--- Noise reduction (both ReduceNoise=T (with comm.) and F (proc local), but not for DoPoissonRounding)
    IF (.NOT.DoPoissonRounding .AND. .NOT. DoTimeDepInflow .AND. noAdaptive) THEN
      IF (Species(iSpec)%Surfaceflux(iSF)%ReduceNoise) THEN
        !-- calc global to-be-inserted number of parts and distribute to procs (root)
        SDEALLOCATE(PartInsProc)
        ALLOCATE(PartInsProc(0:nProcessors-1))
        PartInsProc=0
      END IF !ReduceNoise
      IF (.NOT.Species(iSpec)%Surfaceflux(iSF)%ReduceNoise .OR. MPIroot) THEN !ReduceNoise: root only
        IF (Species(iSpec)%Surfaceflux(iSF)%ReduceNoise) THEN
          VFR_total = Species(iSpec)%Surfaceflux(iSF)%VFR_total_allProcsTotal !proc global total
        ELSE
          VFR_total = Species(iSpec)%Surfaceflux(iSF)%VFR_total               !proc local total
        END IF
        PartIns = Species(iSpec)%Surfaceflux(iSF)%PartDensity / Species(iSpec)%MacroParticleFactor &
          * dt*RKdtFrac * VFR_total
        inserted_Particle_iter = INT(PartIns,8)
        PartIns = Species(iSpec)%Surfaceflux(iSF)%PartDensity / Species(iSpec)%MacroParticleFactor &
          * (Time + dt*RKdtFracTotal) * VFR_total
        !-- random-round the inserted_Particle_time for preventing periodicity
        IF (inserted_Particle_iter.GE.1) THEN
          CALL RANDOM_NUMBER(RandVal1)
          inserted_Particle_time = INT(PartIns+RandVal1,8)
        ELSE IF (inserted_Particle_iter.GE.0) THEN !needed, since InsertedParticleSurplus can increase
                                                   !and _iter>1 needs to be possible for preventing periodicity
          IF (ALMOSTEQUAL(PartIns,0.)) THEN !dummy for procs without SFs (needed for mpi-comm, are cycled later)
            inserted_Particle_time = INT(PartIns,8)
          ELSE !poisson-distri of PartIns-INT(PartIns)
            CALL SamplePoissonDistri( PartIns-INT(PartIns) , IntSample )
            inserted_Particle_time = INT(INT(PartIns)+IntSample,8) !INT(PartIns) + POISDISTRI( PartIns-INT(PartIns) )
          END IF
        ELSE !dummy for procs without SFs (needed for mpi-comm, are cycled later)
          inserted_Particle_time = INT(PartIns,8)
        END IF
        !-- evaluate inserted_Particle_time and inserted_Particle_iter
        inserted_Particle_diff = inserted_Particle_time - Species(iSpec)%Surfaceflux(iSF)%InsertedParticle &
          - inserted_Particle_iter - Species(iSpec)%Surfaceflux(iSF)%InsertedParticleSurplus
        Species(iSpec)%Surfaceflux(iSF)%InsertedParticleSurplus = ABS(MIN(inserted_Particle_iter + inserted_Particle_diff,0))
        PartInsSF = MAX(INT(inserted_Particle_iter + inserted_Particle_diff,4),0)
        Species(iSpec)%Surfaceflux(iSF)%InsertedParticle = Species(iSpec)%Surfaceflux(iSF)%InsertedParticle + INT(PartInsSF,8)
        IF (Species(iSpec)%Surfaceflux(iSF)%ReduceNoise) THEN
#ifdef MPI
          CALL IntegerDivide(PartInsSF,nProcessors,Species(iSpec)%Surfaceflux(iSF)%VFR_total_allProcs(0:nProcessors-1) &
            ,PartInsProc(0:nProcessors-1))
#else  /*MPI*/
          PartInsProc=PartInsSF
#endif  /*MPI*/
        END IF !ReduceNoise
      END IF !ReduceNoise, MPIroot
#ifdef MPI
      IF (Species(iSpec)%Surfaceflux(iSF)%ReduceNoise) THEN !scatter PartInsProc into PartInsSF of procs
        CALL MPI_SCATTER(PartInsProc(0:nProcessors-1),1,MPI_INTEGER,PartInsSF,1,MPI_INTEGER,0,PartMPI%COMM,IERROR)
      END IF !ReduceNoise
#endif  /*MPI*/
!IPWRITE(*,*) 'B: ',iSpec,iSF,PartInsSF !!!!!!!!!!

      !-- calc global to-be-inserted number of parts and distribute to SubSides (proc local)
      SDEALLOCATE(PartInsSubSides)
      ALLOCATE(PartInsSubSides(SurfFluxSideSize(1),SurfFluxSideSize(2),1:BCdata_auxSF(currentBC)%SideNumber))
      PartInsSubSides=0
      IF (BCdata_auxSF(currentBC)%SideNumber.LT.1) THEN
        IF (PartInsSF.NE.0) CALL abort(&
__STAMP__&
,'ERROR in ParticleSurfaceflux: Someting is wrong with PartInsSF of BC ',currentBC)
      ELSE
        CALL IntegerDivide(PartInsSF,BCdata_auxSF(currentBC)%SideNumber*SurfFluxSideSize(1)*SurfFluxSideSize(2) &
          ,Species(iSpec)%Surfaceflux(iSF)%SurfFluxSubSideData(1:SurfFluxSideSize(1),1:SurfFluxSideSize(2) &
                                                              ,1:BCdata_auxSF(currentBC)%SideNumber)%nVFR &
          ,PartInsSubSides(1:SurfFluxSideSize(1),1:SurfFluxSideSize(2),1:BCdata_auxSF(currentBC)%SideNumber) )
      END IF
    END IF !.NOT.DoPoissonRounding .AND. .NOT.DoTimeDepInflow .AND. noAdaptive

!----- 0.: go through (sub)sides if present in proc
    IF (BCdata_auxSF(currentBC)%SideNumber.EQ.0) THEN
      CYCLE
    ELSE IF (BCdata_auxSF(currentBC)%SideNumber.EQ.-1) THEN
      CALL abort(&
__STAMP__&
,'ERROR in ParticleSurfaceflux: Someting is wrong with SideNumber of BC ',currentBC)
    END IF
#if USE_LOADBALANCE
    CALL LBStartTime(tLBStart)
#endif /*USE_LOADBALANCE*/
    DO iSide=1,BCdata_auxSF(currentBC)%SideNumber
      BCSideID=BCdata_auxSF(currentBC)%SideList(iSide)
      ElemID = SideToElem(1,BCSideID)
      IF (ElemID.LT.1) THEN !not sure if necessary
        ElemID = SideToElem(2,BCSideID)
        iLocSide = SideToElem(4,BCSideID)
      ELSE
        iLocSide = SideToElem(3,BCSideID)
      END IF
      SideID=PartElemToSide(E2S_SIDE_ID,ilocSide,ElemID)
      IF (TriaSurfaceFlux) THEN
        xNod = BCdata_auxSF(currentBC)%TriaSideGeo(iSide)%xyzNod(1)
        yNod = BCdata_auxSF(currentBC)%TriaSideGeo(iSide)%xyzNod(2)
        zNod = BCdata_auxSF(currentBC)%TriaSideGeo(iSide)%xyzNod(3)
      END IF
      DO jSample=1,SurfFluxSideSize(2); DO iSample=1,SurfFluxSideSize(1)
        ExtraParts = 0 !set here number of additional to-be-inserted particles in current BCSideID/subsides (e.g. desorption)
        IF (TriaSurfaceFlux) THEN
          !-- compute parallelogram of triangle
          Node1 = jSample+1     ! normal = cross product of 1-2 and 1-3 for first triangle
          Node2 = jSample+2     !          and 1-3 and 1-4 for second triangle
          Vector1 = BCdata_auxSF(currentBC)%TriaSideGeo(iSide)%Vectors(:,Node1-1)
          Vector2 = BCdata_auxSF(currentBC)%TriaSideGeo(iSide)%Vectors(:,Node2-1)
          midpoint(1:3) = BCdata_auxSF(currentBC)%TriaSwapGeo(iSample,jSample,iSide)%midpoint(1:3)
          ndist(1:3) = BCdata_auxSF(currentBC)%TriaSwapGeo(iSample,jSample,iSide)%ndist(1:3)
        END IF
        IF (noAdaptive) THEN
          IF (PartSurfaceModel.GT.0 .OR. (LiquidSimFlag .AND. (PartBound%LiquidSpec(PartBound%MapToPartBC(BC(SideID))).GT.0)) ) THEN
            IF (SurfMesh%SideIDToSurfID(SideID).GT.0) THEN
              IF (PartSurfaceModel.GT.0 .AND. (.NOT.TriaSurfaceFlux.OR.(iSample.EQ.1 .AND. jSample.EQ.1)) ) THEN
                ExtraParts = Adsorption%SumDesorbPart(iSample,jSample,SurfMesh%SideIDToSurfID(SideID),iSpec)
              ELSE IF (LiquidSimFlag .AND. (PartBound%LiquidSpec(PartBound%MapToPartBC(BC(SideID))).GT.0) &
                  .AND. (.NOT.TriaSurfaceFlux.OR.(iSample.EQ.1 .AND. jSample.EQ.1)) )THEN
                ExtraParts = Liquid%SumEvapPart(iSample,jSample,SurfMesh%SideIDToSurfID(SideID),iSpec)
              ELSE IF (.NOT.TriaSurfaceFlux.OR.(iSample.EQ.1 .AND. jSample.EQ.1)) THEN
                CALL abort(&
__STAMP__&
,'ERROR in ParticleSurfaceflux: The code should not go here...')
              END IF
              IF (TriaSurfaceFlux) THEN
                IF (iSample.EQ.1 .AND. jSample.EQ.1) THEN !first tria
                  AreasTria(1)=SurfMeshSubSideData(1,1,BCSideID)%area
                  AreasTria(2)=SurfMeshSubSideData(SurfFluxSideSize(1),SurfFluxSideSize(2),BCSideID)%area
                  ExtraPartsTria(:) = 0
                  CALL IntegerDivide(ExtraParts, 2, AreasTria, ExtraPartsTria)
                  ExtraParts = ExtraPartsTria(1)
                ELSE !second tria
                  ExtraParts = ExtraPartsTria(2)
                END IF
              END IF !TriaSurfaceFlux
            END IF !SurfMesh%SideIDToSurfID(SideID).GT.0
          END IF !PartSurfaceModel .OR. LiquidSimFlag
        END IF

!----- 1.: set positions
        !-- compute number of to be inserted particles
        IF (noAdaptive) THEN
          IF (.NOT.DoPoissonRounding .AND. .NOT.DoTimeDepInflow) THEN
            PartInsSubSide=PartInsSubSides(iSample,jSample,iSide)
!IPWRITE(*,*) PartInsSubSide
!read*
          ELSE IF(DoPoissonRounding .AND. .NOT.DoTimeDepInflow)THEN
            PartIns = Species(iSpec)%Surfaceflux(iSF)%PartDensity / Species(iSpec)%MacroParticleFactor &
                    * dt*RKdtFrac * Species(iSpec)%Surfaceflux(iSF)%SurfFluxSubSideData(iSample,jSample,iSide)%nVFR
            IF (EXP(-PartIns).LE.TINY(PartIns)) THEN
              CALL abort(&
__STAMP__&
,'ERROR in ParticleSurfaceflux: flux is too large for poisson sampling!')
            ELSE !poisson-sampling instead of random rounding (reduces numerical non-equlibrium effects [Tysanner and Garcia 2004]
              CALL SamplePoissonDistri( PartIns , PartInsSubSide )
            END IF
          ELSE !DoTimeDepInflow
            CALL RANDOM_NUMBER(RandVal1)
            PartInsSubSide = INT(Species(iSpec)%Surfaceflux(iSF)%PartDensity / Species(iSpec)%MacroParticleFactor &
                           * dt*RKdtFrac * Species(iSpec)%Surfaceflux(iSF)%SurfFluxSubSideData(iSample,jSample,iSide)%nVFR+RandVal1)
          END IF !DoPoissonRounding
        ELSE !Adaptive
          SELECT CASE(PartBound%AdaptiveType(currentBC))
          CASE(1) ! Pressure inlet (pressure, temperature const)
            ElemPartDensity = Species(iSpec)%Surfaceflux(iSF)%PartDensity
            T =  Species(iSpec)%Surfaceflux(iSF)%MWTemperatureIC
          CASE(2) ! adaptive Outlet/freestream
            ElemPartDensity = Adaptive_MacroVal(DSMC_DENSITY,ElemID,iSpec)
            pressure = PartBound%AdaptivePressure(Species(iSpec)%Surfaceflux(iSF)%BC)
            T = pressure / (BoltzmannConst * SUM(Adaptive_MacroVal(DSMC_DENSITY,ElemID,:)))
            !T = SQRT(Adaptive_MacroVal(4,ElemID,iSpec)**2+Adaptive_MacroVal(5,ElemID,iSpec)**2 &
            !  + Adaptive_MacroVal(6,ElemID,iSpec)**2)
          CASE(3) ! pressure outlet (pressure defined)
          CASE DEFAULT
            CALL abort(&
__STAMP__&
,'wrong adaptive type for Surfaceflux!')
          END SELECT
          VeloVec(1) = Adaptive_MacroVal(DSMC_VELOX,ElemID,iSpec)
          VeloVec(2) = Adaptive_MacroVal(DSMC_VELOY,ElemID,iSpec)
          VeloVec(3) = Adaptive_MacroVal(DSMC_VELOZ,ElemID,iSpec)
          VeloIC = SQRT(DOT_PRODUCT(VeloVec,VeloVec))
          IF (ABS(VeloIC).GT.0.) THEN
            VeloVecIC = VeloVec / VeloIC
          ELSE
            VeloVecIC = (/1.,0.,0./)
          END IF
          vec_nIn(1:3) = SurfMeshSubSideData(iSample,jSample,BCSideID)%vec_nIn(1:3)
          projFak = DOT_PRODUCT(vec_nIn,VeloVecIC) !VeloVecIC projected to inwards normal
          v_thermal = SQRT(2.*BoltzmannConst*T/Species(iSpec)%MassIC) !thermal speed
          a = 0 !dummy for projected speed ratio in constant v-distri
          !-- compute total volume flow rate through surface
          SELECT CASE(TRIM(Species(iSpec)%Surfaceflux(iSF)%velocityDistribution))
          CASE('constant')
            vSF = VeloIC * projFak !Velo proj. to inwards normal
            nVFR = MAX(SurfMeshSubSideData(iSample,jSample,BCSideID)%area * vSF,0.) !VFR proj. to inwards normal (only positive parts!)
          CASE('maxwell','maxwell_lpn')
            IF ( ALMOSTEQUAL(v_thermal,0.)) THEN
              v_thermal = 1.
            END IF
            a = VeloIC * projFak / v_thermal !speed ratio proj. to inwards n (can be negative!)
            vSF = v_thermal / (2.0*SQRT(PI)) * ( EXP(-(a*a)) + a*SQRT(PI)*(1+ERF(a)) ) !mean flux velocity through normal sub-face
            nVFR = SurfMeshSubSideData(iSample,jSample,BCSideID)%area * vSF !VFR projected to inwards normal of sub-side
          CASE DEFAULT
            CALL abort(&
__STAMP__&
,'wrong velo-distri for adaptive Surfaceflux!')
          END SELECT

          CALL RANDOM_NUMBER(RandVal1)
          PartInsSubSide = INT(ElemPartDensity / Species(iSpec)%MacroParticleFactor * dt*RKdtFrac * nVFR+RandVal1)
        END IF
        !-- proceed with calculated to be inserted particles
        IF (PartInsSubSide.LT.0) THEN
          CALL abort(&
__STAMP__&
,'ERROR in ParticleSurfaceflux: PartInsSubSide.LT.0!')
        ELSE IF (PartInsSubSide + ExtraParts.LE.0) THEN
          CYCLE
        END IF
        PartInsSubSide = PartInsSubSide + ExtraParts
        NbrOfParticle = NbrOfParticle + PartInsSubSide
        ALLOCATE( particle_positions(1:PartInsSubSide*3), STAT=allocStat )
        IF (allocStat .NE. 0) THEN
          CALL abort(&
__STAMP__&
,'ERROR in ParticleSurfaceflux: cannot allocate particle_positions!')
        END IF
        IF (Species(iSpec)%Surfaceflux(iSF)%VeloIsNormal .AND. .NOT.TriaSurfaceFlux) THEN
          ALLOCATE( particle_xis(1:PartInsSubSide*2), STAT=allocStat )
          IF (allocStat .NE. 0) THEN
            CALL abort(&
__STAMP__&
,'ERROR in ParticleSurfaceflux: cannot allocate particle_xis!')
          END IF
        END IF !VeloIsNormal
        !-- put particles in subside (rejections are used if contraint reduces actual inserted number)
        iPart=1
        nReject=0
        allowedRejections=0
        DO WHILE (iPart+allowedRejections .LE. PartInsSubSide)
          IF (TriaSurfaceFlux) THEN
            CALL RANDOM_NUMBER(RandVal2)
            Particle_pos = (/xNod,yNod,zNod/) + Vector1 * RandVal2(1)
            Particle_pos =       Particle_pos + Vector2 * RandVal2(2)
            PartDistance = ndist(1)*(Particle_pos(1)-midpoint(1)) & !Distance from v1-v2
                         + ndist(2)*(Particle_pos(2)-midpoint(2)) &
                         + ndist(3)*(Particle_pos(3)-midpoint(3))
            IF (PartDistance.GT.0.) THEN !flip into right triangle if outside
              Particle_pos(1:3) = 2*midpoint(1:3)-Particle_pos(1:3)
            END IF
          ELSE !.NOT.TriaSurfaceFlux
            iLoop=0
            DO !ARM for xi considering the dA of the Subside in RefSpace
              iLoop = iLoop+1
              CALL RANDOM_NUMBER(RandVal2)
              xiab(1,1:2)=(/BezierSampleXi(ISample-1),BezierSampleXi(ISample)/) !correct order?!?
              xiab(2,1:2)=(/BezierSampleXi(JSample-1),BezierSampleXi(JSample)/) !correct order?!?
              xi=(xiab(:,2)-xiab(:,1))*RandVal2+xiab(:,1)
              IF (Species(iSpec)%Surfaceflux(iSF)%AcceptReject) THEN
                IF (.NOT.Species(iSpec)%Surfaceflux(iSF)%VeloIsNormal) THEN
                  CALL EvaluateBezierPolynomialAndGradient(xi,NGeo,2 &
                    ,Species(iSpec)%Surfaceflux(iSF)%SurfFluxSubSideData(iSample,jSample &
                    ,iSide)%BezierControlPoints2D(1:2,0:NGeo,0:NGeo) &
                    ,Gradient=gradXiEta2D)
                  E=DOT_PRODUCT(gradXiEta2D(1,1:2),gradXiEta2D(1,1:2))
                  F=DOT_PRODUCT(gradXiEta2D(1,1:2),gradXiEta2D(2,1:2))
                  G=DOT_PRODUCT(gradXiEta2D(2,1:2),gradXiEta2D(2,1:2))
                ELSE
                  CALL EvaluateBezierPolynomialAndGradient(xi,NGeo,3,BezierControlPoints3D(1:3,0:NGeo,0:NGeo,SideID) &
                    ,Gradient=gradXiEta3D)
                  E=DOT_PRODUCT(gradXiEta3D(1,1:3),gradXiEta3D(1,1:3))
                  F=DOT_PRODUCT(gradXiEta3D(1,1:3),gradXiEta3D(2,1:3))
                  G=DOT_PRODUCT(gradXiEta3D(2,1:3),gradXiEta3D(2,1:3))
                END IF !.NOT.VeloIsNormal
                D=SQRT(E*G-F*F)
                D=D/Species(iSpec)%Surfaceflux(iSF)%SurfFluxSubSideData(iSample,jSample,iSide)%Dmax !scaled Jacobian of xi
                IF (D .GT. 1.01) THEN !arbitrary warning threshold
                  IPWRITE(*,'(I4,x,A28,I0,A9,I0,A22,I0)') &
                    'WARNING: ARM of SurfaceFlux ',iSF,' of Spec ',iSpec,' has inaccurate Dmax! ',D
                END IF
                CALL RANDOM_NUMBER(RandVal1)
                IF (RandVal1.LE.D) THEN
                  EXIT !accept xi
                ELSE
                  IF (MOD(iLoop,100).EQ.0) THEN !arbitrary warning threshold
                    IPWRITE(*,'(I4,x,A28,I0,A9,I0,A18,I0)') &
                      'WARNING: ARM of SurfaceFlux ',iSF,' of Spec ',iSpec,' has reached loop ',iLoop
                    IPWRITE(*,'(I4,x,A19,2(x,E16.8))') &
                      '         R, D/Dmax:',RandVal1,D
                  END IF
                END IF
              ELSE !no ARM -> accept xi
                EXIT
              END IF
            END DO !Jacobian-based ARM-loop
            IF(MINVAL(XI).LT.-1.)THEN
              IPWRITE(UNIT_StdOut,'(I0,A,E16.8)') ' Xi<-1',XI
            END IF
            IF(MAXVAL(XI).GT.1.)THEN
              IPWRITE(UNIT_StdOut,'(I0,A,E16.8)') ' Xi>1',XI
            END IF
            CALL EvaluateBezierPolynomialAndGradient(xi,NGeo,3,BezierControlPoints3D(1:3,0:NGeo,0:NGeo,SideID),Point=Particle_pos)
          END IF !TriaSurfaceFlux

          IF (Species(iSpec)%Surfaceflux(iSF)%SimpleRadialVeloFit) THEN !check rmax-rejection
            SELECT CASE(Species(iSpec)%Surfaceflux(iSF)%SurfFluxSideRejectType(iSide))
            CASE(0) !- RejectType=0 : complete side is inside valid bounds
              AcceptPos=.TRUE.
            CASE(1) !- RejectType=1 : complete side is outside of valid bounds
              CALL abort(&
__STAMP__&
,'side outside of valid bounds was considered although nVFR=0...?!')
              !AcceptPos=.FALSE.
            CASE(2) !- RejectType=2 : side is partly inside valid bounds
              point(1)=Particle_pos(dir(2))-origin(1)
              point(2)=Particle_pos(dir(3))-origin(2)
              radius=SQRT( (point(1))**2+(point(2))**2 )
              IF ((radius.LE.Species(iSpec)%Surfaceflux(iSF)%rmax).AND.(radius.GE.Species(iSpec)%Surfaceflux(iSF)%rmin)) THEN
                AcceptPos=.TRUE.
              ELSE
                AcceptPos=.FALSE.
              END IF
            CASE DEFAULT
              CALL abort(&
__STAMP__&
,'wrong SurfFluxSideRejectType!')
            END SELECT !SurfFluxSideRejectType
          ELSE !no check for rmax-rejection
            AcceptPos=.TRUE.
          END IF !SimpleRadialVeloFit

          !-- save position if accepted:
          IF (AcceptPos) THEN
            particle_positions(iPart*3-2) = Particle_pos(1)
            particle_positions(iPart*3-1) = Particle_pos(2)
            particle_positions(iPart*3  ) = Particle_pos(3)
            IF (Species(iSpec)%Surfaceflux(iSF)%VeloIsNormal .AND. .NOT.TriaSurfaceFlux) THEN
              particle_xis(iPart*2-1) = xi(1)
              particle_xis(iPart*2  ) = xi(2)
            END IF !VeloIsNormal
            iPart=iPart+1
          ELSE
            nReject=nReject+1
            IF (Species(iSpec)%Surfaceflux(iSF)%SimpleRadialVeloFit) THEN !check rmax-rejection
              allowedRejections=allowedRejections+1
            END IF
          END IF
        END DO !put particles in subside: WHILE(iPart+allowedRejections .LE. PartInsSubSide)
        PartInsSubSide = PartInsSubSide - allowedRejections
        NbrOfParticle = NbrOfParticle - allowedRejections
!print*,'accept-part=',REAL(PartInsSubSide)/REAL(PartInsSubSide+nReject)
        
        ParticleIndexNbr = 1
        DO iPart=1,PartInsSubSide
          IF ((iPart.EQ.1).OR.PDM%ParticleInside(ParticleIndexNbr)) THEN
            ParticleIndexNbr = PDM%nextFreePosition(iPartTotal + 1 &
              + PDM%CurrentNextFreePosition)
          END IF
          IF (ParticleIndexNbr .ne. 0) THEN
            PartState(ParticleIndexNbr,1:3) = particle_positions(3*(iPart-1)+1:3*(iPart-1)+3)
            IF (noAdaptive) THEN
              ! check if surfaceflux is used for surface sampling (neccessary for desorption and evaporation)
              ! create linked list of surfaceflux-particle-info for sampling case
              IF (PartSurfaceModel.GT.0 .OR. LiquidSimFlag) THEN
                IF ((DSMC%CalcSurfaceVal.AND.(Time.GE.(1.-DSMC%TimeFracSamp)*TEnd)) &
                    .OR.(DSMC%CalcSurfaceVal.AND.WriteMacroSurfaceValues)) THEN
                  IF (PartBound%TargetBoundCond(CurrentBC).EQ.PartBound%ReflectiveBC) THEN
                    ! first check if linked list is initialized and initialize if neccessary
                    IF (.NOT. ASSOCIATED(currentSurfFluxPart)) THEN
                      ALLOCATE(currentSurfFluxPart)
                      IF (.NOT. ASSOCIATED(Species(iSpec)%Surfaceflux(iSF)%firstSurfFluxPart)) THEN
                        Species(iSpec)%Surfaceflux(iSF)%firstSurfFluxPart => currentSurfFluxPart
                        Species(iSpec)%Surfaceflux(iSF)%lastSurfFluxPart  => currentSurfFluxPart
                      END IF
                    ! check if surfaceflux has already list (happens if second etc. surfaceflux is considered)
                    ! create linke to next surfflux-part from current list
                    ELSE IF (.NOT. ASSOCIATED(Species(iSpec)%Surfaceflux(iSF)%firstSurfFluxPart)) THEN
                      IF (.NOT. ASSOCIATED(currentSurfFluxPart%next)) THEN
                        ALLOCATE(currentSurfFluxPart%next)
                      END IF
                      currentSurfFluxPart => currentSurfFluxPart%next
                      Species(iSpec)%Surfaceflux(iSF)%firstSurfFluxPart => currentSurfFluxPart
                      Species(iSpec)%Surfaceflux(iSF)%lastSurfFluxPart  => currentSurfFluxPart
                    ! surfaceflux has already list but new particle is being inserted
                    ! create linke to next surfflux-part from current list
                    ELSE
                      IF (.NOT. ASSOCIATED(currentSurfFluxPart%next)) THEN
                        ALLOCATE(currentSurfFluxPart%next)
                      END IF
                      currentSurfFluxPart => currentSurfFluxPart%next
                      Species(iSpec)%Surfaceflux(iSF)%lastSurfFluxPart  => currentSurfFluxPart
                    END IF
                    ! save index and sideinfo for current to be inserted particle
                    currentSurfFluxPart%PartIdx = ParticleIndexNbr
                    IF (.NOT.TriaTracking .AND. (nSurfSample.GT.1)) THEN
                      IF (.NOT. ALLOCATED(currentSurfFluxPart%SideInfo)) ALLOCATE(currentSurfFluxPart%SideInfo(1:3))
                      currentSurfFluxPart%SideInfo(1) = iSide
                      currentSurfFluxPart%SideInfo(2) = iSample
                      currentSurfFluxPart%SideInfo(3) = jSample
                    ELSE
                      IF (.NOT. ALLOCATED(currentSurfFluxPart%SideInfo)) ALLOCATE(currentSurfFluxPart%SideInfo(1))
                      currentSurfFluxPart%SideInfo(1) = SurfMesh%SideIDToSurfID(SideID)
                    END IF
                  END IF ! reflective bc
                END IF ! sampling is on (CalcSurfaceVal)
              END IF ! wallmodel or liquidsim
              IF (Species(iSpec)%Surfaceflux(iSF)%VeloIsNormal .AND. .NOT.TriaSurfaceFlux) THEN
                PartState(ParticleIndexNbr,4:5) = particle_xis(2*(iPart-1)+1:2*(iPart-1)+2) !use velo as dummy-storage for xi!
              ELSE IF (Species(iSpec)%Surfaceflux(iSF)%SimpleRadialVeloFit) THEN !PartState is used as drift for case of MB-distri!
                point(1)=PartState(ParticleIndexNbr,dir(2))-origin(1)
                point(2)=PartState(ParticleIndexNbr,dir(3))-origin(2)
                radius=SQRT( (point(1))**2+(point(2))**2 )
                phi=ATAN2(point(2),point(1))
                !-- evaluate radial fit
                vTot = Species(iSpec)%Surfaceflux(iSF)%VeloIC
                veloR=-radius*(preFac*exp(powerFac*radius)+shiftFac)
                IF (ABS(veloR).GT.1.) THEN
                  IPWRITE(*,*) 'radius=',radius
                  IPWRITE(*,*) 'veloR-ratio=',veloR
                  CALL abort(__STAMP__,&
                    'ERROR in VeloFit!')
                END IF
                PartState(ParticleIndexNbr,3+dir(1)) = SIGN(vTot * SQRT(1.-veloR**2) &
                  ,Species(iSpec)%Surfaceflux(iSF)%VeloVecIC(dir(1)))
                veloR = veloR * vToT
                PartState(ParticleIndexNbr,3+dir(2)) = veloR*cos(phi)
                PartState(ParticleIndexNbr,3+dir(3)) = veloR*sin(phi)
              END IF !VeloIsNormal or SimpleRadialVeloFit
            END IF

            ! shift lastpartpos minimal into cell for fail-safe tracking
            LastPartPos(ParticleIndexNbr,1:3)=PartState(ParticleIndexNbr,1:3)
            !SELECT CASE(SideType(SideID))
            !CASE(PLANAR_RECT,PLANAR_NONRECT)
            !  LastPartPos(ParticleIndexNbr,1:3)=ElemBaryNGeo(1:3,ElemID) &
            !  + (PartState(ParticleIndexNbr,1:3)-ElemBaryNGeo(1:3,ElemID)) * (0.9999)
            !CASE(BILINEAR,CURVED,PLANAR_CURVED) !to be changed into more efficient method using known xi
            !  CALL GetPositionInRefElem(PartState(ParticleIndexNbr,1:3),Particle_pos(1:3),ElemID) !RefMap PartState
            !  DO iLoop=1,3 !shift border-RefCoords into elem
            !    IF( ABS(Particle_pos(iLoop)) .GT. 0.9999 ) THEN
            !      Particle_pos(iLoop)=SIGN(0.999999,Particle_pos(iLoop))
            !    END IF
            !  END DO
            !  CALL TensorProductInterpolation(Particle_pos(1:3),3,NGeo,XiCL_NGeo,wBaryCL_NGeo,XCL_NGeo(1:3,0:NGeo,0:NGeo,0:NGeo,ElemID) &
            !    ,LastPartPos(ParticleIndexNbr,1:3)) !Map back into phys. space
            !CASE DEFAULT
            !  CALL abort(&
!__STAMP__&
!,'unknown SideType!')
            !END SELECT

!#ifdef CODE_ANALYZE
!          CALL GetPositionInRefElem(LastPartPos(ParticleIndexNbr,1:3),Particle_pos(1:3),ElemID)
!          IF (ANY(ABS(Particle_pos).GT.1.0)) THEN !maybe 1+epsInCell would be enough...
!            IPWRITE(*,*) 'Particle_pos: ',Particle_pos
!            CALL abort(&
!__STAMP__&
!,'CODE_ANALYZE: RefPos of LastPartPos is outside for ElemID. BC-cells are too deformed for surfaceflux!')
!          END IF
!#endif /*CODE_ANALYZE*/ 
#if defined(IMPA) || defined(ROS)
            IF(DoRefMapping)THEN
              CALL GetPositionInRefElem(PartState(ParticleIndexNbr,1:3),PartPosRef(1:3,ParticleIndexNbr),ElemID) !RefMap PartState
            END IF
            ! important for implicit, correct norm, etc.
            PartState(ParticleIndexNbr,1:3)=LastPartPos(ParticleIndexNbr,1:3)
#endif /*IMPA*/
#ifdef CODE_ANALYZE
            IF(   (LastPartPos(ParticleIndexNbr,1).GT.GEO%xmaxglob).AND. .NOT.ALMOSTEQUAL(LastPartPos(ParticleIndexNbr,1),GEO%xmaxglob) &
              .OR.(LastPartPos(ParticleIndexNbr,1).LT.GEO%xminglob).AND. .NOT.ALMOSTEQUAL(LastPartPos(ParticleIndexNbr,1),GEO%xminglob) &
              .OR.(LastPartPos(ParticleIndexNbr,2).GT.GEO%ymaxglob).AND. .NOT.ALMOSTEQUAL(LastPartPos(ParticleIndexNbr,2),GEO%ymaxglob) &
              .OR.(LastPartPos(ParticleIndexNbr,2).LT.GEO%yminglob).AND. .NOT.ALMOSTEQUAL(LastPartPos(ParticleIndexNbr,2),GEO%yminglob) &
              .OR.(LastPartPos(ParticleIndexNbr,3).GT.GEO%zmaxglob).AND. .NOT.ALMOSTEQUAL(LastPartPos(ParticleIndexNbr,3),GEO%zmaxglob) &
              .OR.(LastPartPos(ParticleIndexNbr,3).LT.GEO%zminglob).AND. .NOT.ALMOSTEQUAL(LastPartPos(ParticleIndexNbr,3),GEO%zminglob) ) THEN
              IPWRITE(UNIt_stdOut,'(I0,A18,L)')                            ' ParticleInside ',PDM%ParticleInside(ParticleIndexNbr)
#ifdef IMPA
              IPWRITE(UNIt_stdOut,'(I0,A18,L)')                            ' PartIsImplicit ', PartIsImplicit(ParticleIndexNbr)
              IPWRITE(UNIt_stdOut,'(I0,A18,E25.14)')                       ' PartDtFrac ', PartDtFrac(ParticleIndexNbr)
#endif /*IMPA*/
              IPWRITE(UNIt_stdOut,'(I0,A18,L)')                            ' PDM%IsNewPart ', PDM%IsNewPart(ParticleIndexNbr)
              IPWRITE(UNIt_stdOut,'(I0,A18,x,A18,x,A18)')                  '    min ', ' value ', ' max '
              IPWRITE(UNIt_stdOut,'(I0,A2,x,E25.14,x,E25.14,x,E25.14)') ' x', GEO%xminglob, LastPartPos(ParticleIndexNbr,1) &
                                                                            , GEO%xmaxglob
              IPWRITE(UNIt_stdOut,'(I0,A2,x,E25.14,x,E25.14,x,E25.14)') ' y', GEO%yminglob, LastPartPos(ParticleIndexNbr,2) &
                                                                            , GEO%ymaxglob
              IPWRITE(UNIt_stdOut,'(I0,A2,x,E25.14,x,E25.14,x,E25.14)') ' z', GEO%zminglob, LastPartPos(ParticleIndexNbr,3) &
                                                                            , GEO%zmaxglob
              CALL abort(&
                 __STAMP__ &
#if  defined(IMPA) || defined(ROS)
                 ,' LastPartPos outside of mesh. iPart=, iStage',ParticleIndexNbr,REAL(iStage))
#else
                 ,' LastPartPos outside of mesh. iPart=',ParticleIndexNbr)
#endif
            END IF
#endif /*CODE_ANALYZE*/ 
            PDM%ParticleInside(ParticleIndexNbr) = .TRUE.
            PDM%dtFracPush(ParticleIndexNbr) = .TRUE.
            PDM%IsNewPart(ParticleIndexNbr) = .TRUE.
            PEM%Element(ParticleIndexNbr) = ElemID
            PEM%lastElement(ParticleIndexNbr) = ElemID !needed when ParticlePush is not executed, e.g. "delay"
            iPartTotal = iPartTotal + 1
          ELSE
            CALL abort(&
__STAMP__&
,'ERROR in ParticleSurfaceflux: ParticleIndexNbr.EQ.0 - maximum nbr of particles reached?')
          END IF
        END DO
        DEALLOCATE(particle_positions)
        IF (Species(iSpec)%Surfaceflux(iSF)%VeloIsNormal .AND. .NOT.TriaSurfaceFlux) DEALLOCATE(particle_xis)
!----- 2a.: set velocities if special for each subside
        IF (TRIM(Species(iSpec)%Surfaceflux(iSF)%velocityDistribution).NE.'constant' &
          .OR. Species(iSpec)%Surfaceflux(iSF)%VeloIsNormal) THEN
          CALL SetSurfacefluxVelocities(iSpec,iSF,iSample,jSample,iSide,BCSideID,SideID,ElemID,NbrOfParticle,PartInsSubSide)
        END IF
        
        PartsEmitted = PartsEmitted + PartInsSubSide
#if USE_LOADBALANCE
        !used for calculating LoadBalance of tCurrent(LB_SURFFLUX) ==> "2b.: set remaining properties"
        nSurfacefluxPerElem(ElemID)=nSurfacefluxPerElem(ElemID)+PartInsSubSide
#endif /*USE_LOADBALANCE*/
        
      END DO; END DO !jSample=1,SurfFluxSideSize(2); iSample=1,SurfFluxSideSize(1)
#if USE_LOADBALANCE
      CALL LBElemSplitTime(ElemID,tLBStart)
#endif /*USE_LOADBALANCE*/
    END DO ! iSide

    IF (NbrOfParticle.NE.iPartTotal) CALL abort(&
__STAMP__&
, 'Error 2 in ParticleSurfaceflux!')
!----- 2b.: set remaining properties
    IF (TRIM(Species(iSpec)%Surfaceflux(iSF)%velocityDistribution).EQ.'constant' &
      .AND. .NOT.Species(iSpec)%Surfaceflux(iSF)%SimpleRadialVeloFit &
      .AND. .NOT.Species(iSpec)%Surfaceflux(iSF)%VeloIsNormal) THEN
      CALL SetParticleVelocity(iSpec,iSF,NbrOfParticle,2)
    END IF
    CALL SetParticleChargeAndMass(iSpec,NbrOfParticle)
    IF (usevMPF) CALL SetParticleMPF(iSpec,NbrOfParticle)
    ! define molecule stuff
    IF (useDSMC.AND.(CollisMode.GT.1)) THEN
      iPart = 1
      DO WHILE (iPart .le. NbrOfParticle)
        PositionNbr = PDM%nextFreePosition(iPart+PDM%CurrentNextFreePosition)
        IF (PositionNbr .ne. 0) THEN
          IF (SpecDSMC(iSpec)%PolyatomicMol) THEN
#if (PP_TimeDiscMethod==300)
             CALL SetInternalEnr_InitFP(iSpec,iSF,PositionNbr,2)
#else
            CALL DSMC_SetInternalEnr_Poly(iSpec,iSF,PositionNbr,2)
#endif
          ELSE
#if (PP_TimeDiscMethod==300)
               CALL SetInternalEnr_InitFP(iSpec,iSF,PositionNbr,2)
#else
               CALL DSMC_SetInternalEnr_LauxVFD(iSpec, iSF, PositionNbr,2)
#endif
          END IF
        END IF
        iPart = iPart + 1
      END DO
    END IF
#if (PP_TimeDiscMethod==1000) || (PP_TimeDiscMethod==1001)
       iPart = 1
       DO WHILE (iPart .le. NbrOfParticle)
         PositionNbr = PDM%nextFreePosition(iPart+PDM%CurrentNextFreePosition)
         IF (PositionNbr .ne. 0) THEN
           PartStateBulkValues(PositionNbr,1) = Species(iSpec)%Surfaceflux(iSF)%VeloVecIC(1) &
                                              * Species(iSpec)%Surfaceflux(iSF)%VeloIC
           PartStateBulkValues(PositionNbr,2) = Species(iSpec)%Surfaceflux(iSF)%VeloVecIC(2) &
                                              * Species(iSpec)%Surfaceflux(iSF)%VeloIC
           PartStateBulkValues(PositionNbr,3) = Species(iSpec)%Surfaceflux(iSF)%VeloVecIC(3) &
                                              * Species(iSpec)%Surfaceflux(iSF)%VeloIC
           PartStateBulkValues(PositionNbr,4) = Species(iSpec)%Surfaceflux(iSF)%MWTemperatureIC
           PartStateBulkValues(PositionNbr,5) = CalcDegreeOfFreedom(PositionNbr)
         END IF
         iPart = iPart + 1
       END DO
#endif
!    CALL UpdateNextFreePosition()
    
    ! compute number of input particles and energy
    IF(CalcPartBalance) THEN
#if ((PP_TimeDiscMethod==1)||(PP_TimeDiscMethod==2)||(PP_TimeDiscMethod==6)||(PP_TimeDiscMethod>=501 && PP_TimeDiscMethod<=506))
      IF((MOD(iter+1,PartAnalyzeStep).EQ.0).AND.(iter.GT.0))THEN ! caution if correct
        print*,'herre'
        nPartInTmp(iSpec)=nPartInTmp(iSpec) + NBrofParticle
        DO iPart=1,NbrOfparticle
          PositionNbr = PDM%nextFreePosition(iPart+PDM%CurrentNextFreePosition)
          IF (PositionNbr .ne. 0) PartEkinInTmp(PartSpecies(PositionNbr)) = &
                                  PartEkinInTmp(PartSpecies(PositionNbr))+CalcEkinPart(PositionNbr)
        END DO ! iPart
      ELSE
        print*,'or here'
        nPartIn(iSpec)=nPartIn(iSpec) + NBrofParticle
        DO iPart=1,NbrOfparticle
          PositionNbr = PDM%nextFreePosition(iPart+PDM%CurrentNextFreePosition)
          IF (PositionNbr .ne. 0) PartEkinIn(PartSpecies(PositionNbr))= &
                                  PartEkinIn(PartSpecies(PositionNbr))+CalcEkinPart(PositionNbr)
        END DO ! iPart
      END IF
#elif  defined(IMPA) || defined(ROS)
      !IF(iStage.EQ.nRKStages)THEN
        nPartIn(iSpec)=nPartIn(iSpec) + NBrofParticle
        DO iPart=1,NbrOfparticle
          PositionNbr = PDM%nextFreePosition(iPart+PDM%CurrentNextFreePosition)
          IF (PositionNbr .ne. 0) PartEkinIn(PartSpecies(PositionNbr))= &
                                  PartEkinIn(PartSpecies(PositionNbr))+CalcEkinPart(PositionNbr)
        END DO ! iPart
      !END IF
#else
      nPartIn(iSpec)=nPartIn(iSpec) + NBrofParticle
      DO iPart=1,NbrOfparticle
        PositionNbr = PDM%nextFreePosition(iPart+PDM%CurrentNextFreePosition)
        IF (PositionNbr .ne. 0) PartEkinIn(PartSpecies(PositionNbr))= &
                                PartEkinIn(PartSpecies(PositionNbr))+CalcEkinPart(PositionNbr)
      END DO ! iPart
#endif
    END IF ! CalcPartBalance

    ! instead of an UpdateNextfreePosition we update the particleVecLength only - enough ?!?
    PDM%CurrentNextFreePosition = PDM%CurrentNextFreePosition + NbrOfParticle
    PDM%ParticleVecLength = PDM%ParticleVecLength + NbrOfParticle
#if USE_LOADBALANCE
    CALL LBPauseTime(LB_SURFFLUX,tLBStart)
#endif /*USE_LOADBALANCE*/
    IF (noAdaptive) THEN
      ! Sample Energies on Surfaces when particles are emitted from them
      IF (NbrOfParticle.NE.PartsEmitted) THEN
        ! should be equal for including the following lines in tSurfaceFlux
        CALL abort(&
__STAMP__&
,'ERROR in ParticleSurfaceflux: NbrOfParticle.NE.PartsEmitted')
      END IF
            IF ((PartBound%TargetBoundCond(CurrentBC).EQ.PartBound%ReflectiveBC) .AND. (PartsEmitted.GT.0)) THEN
#if USE_LOADBALANCE
              CALL LBStartTime(tLBStart)
#endif /*USE_LOADBALANCE*/
              ! check if surfaceflux is used for surface sampling (neccessary for desorption and evaporation)
              ! only allocated if sampling and surface model enabled
              currentSurfFluxPart => Species(iSpec)%Surfaceflux(iSF)%firstSurfFluxPart
              DO WHILE(ASSOCIATED(currentSurfFluxPart))
                PartID     = currentSurfFluxPart%PartIdx
                SurfSideID = currentSurfFluxPart%SideInfo(1)
                IF (TriaTracking.OR.(nSurfSample.EQ.1)) THEN
                  p = 1
                  q = 1
                ELSE
                  p = currentSurfFluxPart%SideInfo(2)
                  q = currentSurfFluxPart%SideInfo(3)
                END IF
                ! set velocities and translational energies
                VelXold  = PartBound%WallVelo(1,CurrentBC)
                VelYold  = PartBound%WallVelo(2,CurrentBC)
                VelZold  = PartBound%WallVelo(3,CurrentBC)
                EtraOld = 0.0
                EtraWall = EtraOld
                VeloReal = SQRT(PartState(PartID,4) * PartState(PartID,4) + PartState(PartID,5) * PartState(PartID,5) &
                                + PartState(PartID,6) * PartState(PartID,6))
                EtraNew = 0.5 * Species(iSpec)%MassIC * VeloReal**2
                ! fill Transarray
                TransArray(1) = EtraOld
                TransArray(2) = EtraWall
                TransArray(3) = EtraNew
                ! must be old_velocity-new_velocity
                TransArray(4) = VelXold-PartState(PartID,4)
                TransArray(5) = VelYold-PartState(PartID,5)
                TransArray(6) = VelZold-PartState(PartID,6)
                IF (CollisMode.GT.1) THEN
                  ! set rotational energies
                  ErotWall = 0
                  ErotOld  = ErotWall
                  ErotNew  = PartStateIntEn(PartID,2)
                  ! fill rotational internal array
                  IntArray(1) = ErotOld
                  IntArray(2) = ErotWall
                  IntArray(3) = ErotNew
                  ! set vibrational energies
                  EvibWall = 0 ! calculated and added in particle desorption calculation
                  EvibOld  = EvibWall ! calculated and added in particle desorption calculation
                  EvibNew  = PartStateIntEn(PartID,1)
                  ! fill vibrational internal array
                  IntArray(4) = EvibOld
                  IntArray(5) = EvibWall
                  IntArray(6) = EvibNew
                ELSE
                  IntArray(:) = 0.
                END IF
                ! sample values
                CALL CalcWallSample(PartID,SurfSideID,p,q,TransArray,IntArray, &
                    (/0.,0.,0./),0.,.False.,0.,currentBC,emission_opt=.TRUE.)
                currentSurfFluxPart => currentSurfFluxPart%next
#if USE_LOADBALANCE
                CALL LBElemSplitTime(PEM%Element(PartID),tLBStart)
#endif /*USE_LOADBALANCE*/
                IF (ASSOCIATED(currentSurfFluxPart,Species(iSpec)%Surfaceflux(iSF)%lastSurfFluxPart%next)) THEN
                  currentSurfFluxPart => Species(iSpec)%Surfaceflux(iSF)%lastSurfFluxPart
                  EXIT
                END IF
              END DO
            END IF ! reflective bc
      IF (ASSOCIATED(Species(iSpec)%Surfaceflux(iSF)%firstSurfFluxPart)) THEN
        Species(iSpec)%Surfaceflux(iSF)%firstSurfFluxPart  => NULL()
        Species(iSpec)%Surfaceflux(iSF)%lastSurfFluxPart  => NULL()
      END IF
    END IF
  END DO !iSF
END DO !iSpec

END SUBROUTINE ParticleSurfaceflux


SUBROUTINE SetSurfacefluxVelocities(FractNbr,iSF,iSample,jSample,iSide,BCSideID,SideID,ElemID,NbrOfParticle,PartIns)
!===================================================================================================================================
! Determine the particle velocity of each inserted particle
!===================================================================================================================================
! MODULES
USE MOD_Globals
USE MOD_Globals_Vars,           ONLY : PI, BoltzmannConst
USE MOD_Particle_Vars
USE MOD_Particle_Surfaces_Vars, ONLY : SurfMeshSubSideData, TriaSurfaceFlux
USE MOD_Particle_Surfaces,      ONLY : CalcNormAndTangBezier
USE MOD_Particle_Boundary_Vars, ONLY : PartBound
!USE Ziggurat,                   ONLY : rnor
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
INTEGER,INTENT(IN)               :: FractNbr,iSF,iSample,jSample,iSide,BCSideID,SideID,ElemID,NbrOfParticle,PartIns
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES           
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
INTEGER                          :: i,PositionNbr,envelope,currentBC
REAL                             :: Vec3D(3), vec_nIn(1:3), vec_t1(1:3), vec_t2(1:3)
REAL                             :: a,zstar,RandVal1,RandVal2(2),RandVal3(3),u,RandN,RandN_save,Velo1,Velo2,Velosq,T,beta,z
LOGICAL                          :: RandN_in_Mem
CHARACTER(30)                    :: velocityDistribution             ! specifying keyword for velocity distribution
REAL                             :: projFak                          ! VeloVecIC projected to inwards normal of tria
REAL                             :: Velo_t1                          ! Velo comp. of first orth. vector in tria
REAL                             :: Velo_t2                          ! Velo comp. of second orth. vector in tria
REAL                             :: VeloIC
REAL                             :: VeloVec(1:3)
REAL                             :: VeloVecIC(1:3),v_thermal, pressure
!===================================================================================================================================

IF(PartIns.lt.1) RETURN

IF (TRIM(Species(FractNbr)%Surfaceflux(iSF)%velocityDistribution).EQ.'maxwell' .OR. &
  TRIM(Species(FractNbr)%Surfaceflux(iSF)%velocityDistribution).EQ.'maxwell_lpn') THEN
  velocityDistribution='maxwell_surfaceflux'
ELSE IF (TRIM(Species(FractNbr)%Surfaceflux(iSF)%velocityDistribution).EQ.'constant' ) THEN
  velocityDistribution='constant'
ELSE
  CALL abort(&
__STAMP__&
,'wrong velo-distri!')
END IF
RandN_in_Mem=.FALSE.
envelope=-1
currentBC = Species(FractNbr)%Surfaceflux(iSF)%BC

IF (.NOT.Species(FractNbr)%Surfaceflux(iSF)%VeloIsNormal) THEN
  vec_nIn(1:3) = SurfMeshSubSideData(iSample,jSample,BCSideID)%vec_nIn(1:3)
  vec_t1(1:3) = SurfMeshSubSideData(iSample,jSample,BCSideID)%vec_t1(1:3)
  vec_t2(1:3) = SurfMeshSubSideData(iSample,jSample,BCSideID)%vec_t2(1:3)
END IF !.NOT.VeloIsNormal

IF(iSF.GT.Species(FractNbr)%nSurfacefluxBCs)THEN
  SELECT CASE(PartBound%AdaptiveType(currentBC))
  CASE(1) ! Pressure inlet (pressure, temperature const)
    T =  Species(FractNbr)%Surfaceflux(iSF)%MWTemperatureIC
  CASE(2) ! adaptive Outlet/freestream
    pressure = PartBound%AdaptivePressure(Species(FractNbr)%Surfaceflux(iSF)%BC)
    T = pressure / (BoltzmannConst * SUM(Adaptive_MacroVal(DSMC_DENSITY,ElemID,:)))
    !T = SQRT(Adaptive_MacroVal(4,ElemID,FractNbr)**2+Adaptive_MacroVal(5,ElemID,FractNbr)**2 &
    !  + Adaptive_MacroVal(6,ElemID,FractNbr)**2)
  CASE(3) ! pressure outlet (pressure defined)
  CASE DEFAULT
    CALL abort(&
__STAMP__&
,'wrong adaptive type for Surfaceflux velocities!')
  END SELECT
  VeloVec(1) = Adaptive_MacroVal(DSMC_VELOX,ElemID,FractNbr)
  VeloVec(2) = Adaptive_MacroVal(DSMC_VELOY,ElemID,FractNbr)
  VeloVec(3) = Adaptive_MacroVal(DSMC_VELOZ,ElemID,FractNbr)
  VeloIC = SQRT(DOT_PRODUCT(VeloVec,VeloVec))
  IF (ABS(VeloIC).GT.0.) THEN
    VeloVecIC = VeloVec / VeloIC
  ELSE
    VeloVecIC = (/1.,0.,0./)
  END IF
  projFak = DOT_PRODUCT(vec_nIn,VeloVecIC) !VeloVecIC projected to inwards normal
  v_thermal = SQRT(2.*BoltzmannConst*T/Species(FractNbr)%MassIC) !thermal speed
  IF ( ALMOSTEQUAL(v_thermal,0.)) THEN
    v_thermal = 1.
  END IF
  a = VeloIC * projFak / v_thermal !speed ratio proj. to inwards n (can be negative!)
  Velo_t1 = VeloIC * DOT_PRODUCT(vec_t1,VeloVecIC) !v in t1-dir
  Velo_t2 = VeloIC * DOT_PRODUCT(vec_t2,VeloVecIC) !v in t2-dir
ELSE
  VeloIC = Species(FractNbr)%Surfaceflux(iSF)%VeloIC
  T = Species(FractNbr)%Surfaceflux(iSF)%MWTemperatureIC
  a = Species(FractNbr)%Surfaceflux(iSF)%SurfFluxSubSideData(iSample,jSample,iSide)%a_nIn
  projFak = Species(FractNbr)%Surfaceflux(iSF)%SurfFluxSubSideData(iSample,jSample,iSide)%projFak
  Velo_t1 = Species(FractNbr)%Surfaceflux(iSF)%SurfFluxSubSideData(iSample,jSample,iSide)%Velo_t1
  Velo_t2 = Species(FractNbr)%Surfaceflux(iSF)%SurfFluxSubSideData(iSample,jSample,iSide)%Velo_t2
END IF

!-- set velocities
SELECT CASE(TRIM(velocityDistribution))
CASE('constant') !constant with normal velocities (for VeloVecIC see SetParticleVelocity!)

  DO i = NbrOfParticle-PartIns+1,NbrOfParticle
    PositionNbr = PDM%nextFreePosition(i+PDM%CurrentNextFreePosition)
    IF (PositionNbr .NE. 0) THEN 
!-- In case of side-normal velocities: calc n-vector at particle position, xi was saved in PartState(4:5)
      IF (Species(FractNbr)%Surfaceflux(iSF)%VeloIsNormal .AND. TriaSurfaceFlux) THEN
        vec_nIn(1:3) = SurfMeshSubSideData(iSample,jSample,BCSideID)%vec_nIn(1:3)
        vec_t1(1:3) = 0. !dummy
        vec_t2(1:3) = 0. !dummy
      ELSE IF (Species(FractNbr)%Surfaceflux(iSF)%VeloIsNormal) THEN
        CALL CalcNormAndTangBezier( nVec=vec_nIn(1:3),xi=PartState(PositionNbr,4),eta=PartState(PositionNbr,5),SideID=SideID )
        vec_nIn(1:3) = -vec_nIn(1:3)
        vec_t1(1:3) = 0. !dummy
        vec_t2(1:3) = 0. !dummy
      ELSE
        CALL abort(&
__STAMP__&
,'this should not happen!')
      END IF !VeloIsNormal
      
!-- build complete velo-vector
      Vec3D(1:3) = vec_nIn(1:3) * Species(FractNbr)%Surfaceflux(iSF)%VeloIC
      PartState(PositionNbr,4:6) = Vec3D(1:3)
    END IF !PositionNbr .NE. 0
  END DO !i = ...NbrOfParticle
CASE('maxwell_surfaceflux')
  !-- determine envelope for most efficient ARM [Garcia and Wagner 2006, JCP217-2]
  IF (.NOT.Species(FractNbr)%Surfaceflux(iSF)%SimpleRadialVeloFit) THEN
    IF (ALMOSTZERO(VeloIC*projFak)) THEN
      ! Rayleigh distri
      envelope = 0
    ELSE IF (-0.4.LT.a .AND. a.LT.1.3) THEN
      ! low speed flow
      IF (a.LE.0.) THEN
        envelope = 1
      ELSE
        envelope = 3
      END IF !choose envelope based on flow direction
    ELSE
      ! high speed / general flow
      IF (a.LT.0.) THEN
        envelope = 2
      ELSE
        envelope = 4
      END IF !choose envelope based on flow direction
    END IF !low speed / high speed / rayleigh flow
  END IF !.NOT.SimpleRadialVeloFit

  DO i = NbrOfParticle-PartIns+1,NbrOfParticle
    PositionNbr = PDM%nextFreePosition(i+PDM%CurrentNextFreePosition)
    IF (PositionNbr .NE. 0) THEN 
!-- 0a.: In case of side-normal velocities: calc n-/t-vectors at particle position, xi was saved in PartState(4:5)
      IF (Species(FractNbr)%Surfaceflux(iSF)%VeloIsNormal .AND. TriaSurfaceFlux) THEN
        vec_nIn(1:3) = SurfMeshSubSideData(iSample,jSample,BCSideID)%vec_nIn(1:3)
        vec_t1(1:3) = SurfMeshSubSideData(iSample,jSample,BCSideID)%vec_t1(1:3)
        vec_t2(1:3) = SurfMeshSubSideData(iSample,jSample,BCSideID)%vec_t2(1:3)
      ELSE IF (Species(FractNbr)%Surfaceflux(iSF)%VeloIsNormal) THEN
        CALL CalcNormAndTangBezier( nVec=vec_nIn(1:3),tang1=vec_t1(1:3),tang2=vec_t2(1:3) &
          ,xi=PartState(PositionNbr,4),eta=PartState(PositionNbr,5),SideID=SideID )
        vec_nIn(1:3) = -vec_nIn(1:3)
!-- 0b.: initialize DataTriaSF if particle-dependent (as in case of SimpleRadialVeloFit), drift vector is already in PartState!!!
      ELSE IF (Species(FractNbr)%Surfaceflux(iSF)%SimpleRadialVeloFit) THEN
        VeloIC = SQRT(DOT_PRODUCT(PartState(PositionNbr,4:6),PartState(PositionNbr,4:6)))
        IF (ALMOSTZERO(VeloIC)) THEN
          projFak = 1. !dummy
          a = 0.
        ELSE
          projFak = DOT_PRODUCT(vec_nIn,PartState(PositionNbr,4:6)) / VeloIC
          a = VeloIC * projFak / SQRT(2.*BoltzmannConst*T/Species(FractNbr)%MassIC) !speed ratio proj. to inwards n (can be negative!)
        END IF
        Velo_t1 = DOT_PRODUCT(vec_t1,PartState(PositionNbr,4:6)) !v in t1-dir
        Velo_t2 = DOT_PRODUCT(vec_t2,PartState(PositionNbr,4:6)) !v in t2-dir
        !-- determine envelope for most efficient ARM [Garcia and Wagner 2006, JCP217-2]
        IF (ALMOSTZERO(VeloIC*projFak)) THEN
          ! Rayleigh distri
          envelope = 0
        ELSE IF (-0.4.LT.a .AND. a.LT.1.3) THEN
          ! low speed flow
          IF (a.LE.0.) THEN
            envelope = 1
          ELSE
            envelope = 3
          END IF !choose envelope based on flow direction
        ELSE
          ! high speed / general flow
          IF (a.LT.0.) THEN
            envelope = 2
          ELSE
            envelope = 4
          END IF !choose envelope based on flow direction
        END IF !low speed / high speed / rayleigh flow
      END IF !VeloIsNormal, else if SimpleRadialVeloFit
!-- 1.: determine zstar (initial generation of potentially too many RVu is for needed indentities of RVu used multiple times!
      SELECT CASE(envelope)
      CASE(0)
        CALL RANDOM_NUMBER(RandVal1)
        zstar = -SQRT(-LOG(RandVal1))
      CASE(1)
        DO
          CALL RANDOM_NUMBER(RandVal2)
          zstar = -SQRT(a*a-LOG(RandVal2(1)))
          IF ( -(a-zstar)/zstar .GT. RandVal2(2)) THEN
            EXIT
          END IF
        END DO
      CASE(2)
        z = 0.5*(a-SQRT(a*a+2.))
        beta  = a-(1.0-a)*(a-z)
        DO
          CALL RANDOM_NUMBER(RandVal3)
          IF (EXP(-(beta*beta))/(EXP(-(beta*beta))+2.0*(a-z)*(a-beta)*EXP(-(z*z))).GT.RandVal3(1)) THEN
            zstar=-SQRT(beta*beta-LOG(RandVal3(2)))
            IF ( -(a-zstar)/zstar .GT. RandVal3(3)) THEN
              EXIT
            END IF
          ELSE
            zstar=beta+(a-beta)*RandVal3(2)
            IF ( (a-zstar)/(a-z)*EXP(z*z-(zstar*zstar)) .GT. RandVal3(3)) THEN
              EXIT
            END IF
          END IF
        END DO
      CASE(3)
        DO
          CALL RANDOM_NUMBER(RandVal3)
          u = RandVal3(1)
          IF ( a*SQRT(PI)/(a*SQRT(PI)+1+a*a) .GT. u) THEN
!            IF (.NOT.DoZigguratSampling) THEN !polar method
              IF (RandN_in_Mem) THEN !reusing second RandN form previous polar method
                RandN = RandN_save
                RandN_in_Mem=.FALSE.
              ELSE
                Velosq = 2
                DO WHILE ((Velosq .GE. 1.) .OR. (Velosq .EQ. 0.))
                  CALL RANDOM_NUMBER(RandVal2)
                  Velo1 = 2.*RandVal2(1) - 1.
                  Velo2 = 2.*RandVal2(2) - 1.
                  Velosq = Velo1**2 + Velo2**2
                END DO
                RandN = Velo1*SQRT(-2*LOG(Velosq)/Velosq)
                RandN_save = Velo2*SQRT(-2*LOG(Velosq)/Velosq)
                RandN_in_Mem=.TRUE.
              END IF
!            ELSE !ziggurat method
!              RandN=rnor()
!            END IF
            zstar = -1./SQRT(2.)*ABS(RandN)
            EXIT
          ELSE IF ( (a*SQRT(PI)+1.)/(a*SQRT(PI)+1+a*a) .GT. u) THEN
            zstar = -SQRT(-LOG(RandVal3(2)))
            EXIT
          ELSE
            zstar = (1.0-SQRT(RandVal3(2)))*a
            IF (EXP(-(zstar*zstar)).GT.RandVal3(3)) THEN
              EXIT
            END IF
          END IF
        END DO
      CASE(4)
        DO
          CALL RANDOM_NUMBER(RandVal3)
          IF (1.0/(2.0*a*SQRT(PI)+1.0).GT.RandVal3(1)) THEN
            zstar=-SQRT(-LOG(RandVal3(2)))
          ELSE
!            IF (.NOT.DoZigguratSampling) THEN !polar method
              IF (RandN_in_Mem) THEN !reusing second RandN form previous polar method
                RandN = RandN_save
                RandN_in_Mem=.FALSE.
              ELSE
                Velosq = 2
                DO WHILE ((Velosq .GE. 1.) .OR. (Velosq .EQ. 0.))
                  CALL RANDOM_NUMBER(RandVal2)
                  Velo1 = 2.*RandVal2(1) - 1.
                  Velo2 = 2.*RandVal2(2) - 1.
                  Velosq = Velo1**2 + Velo2**2
                END DO
                RandN = Velo1*SQRT(-2*LOG(Velosq)/Velosq)
                RandN_save = Velo2*SQRT(-2*LOG(Velosq)/Velosq)
                RandN_in_Mem=.TRUE.
              END IF
!            ELSE !ziggurat method
!              RandN=rnor()
!            END IF
            zstar = 1./SQRT(2.)*RandN
          END IF
          IF ( (a-zstar)/a .GT. RandVal3(3)) THEN
            EXIT
          END IF
        END DO
      CASE DEFAULT
        CALL abort(&
__STAMP__&
,'wrong enevelope in SetSurfacefluxVelocities!')
      END SELECT
      
!-- 2.: sample normal directions and build complete velo-vector
      Vec3D(1:3) = vec_nIn(1:3) * SQRT(2.*BoltzmannConst*T/Species(FractNbr)%MassIC)*(a-zstar)
!      IF (.NOT.DoZigguratSampling) THEN !polar method
        Velosq = 2
        DO WHILE ((Velosq .GE. 1.) .OR. (Velosq .EQ. 0.))
          CALL RANDOM_NUMBER(RandVal2)
          Velo1 = 2.*RandVal2(1) - 1.
          Velo2 = 2.*RandVal2(2) - 1.
          Velosq = Velo1**2 + Velo2**2
        END DO
        Velo1 = Velo1*SQRT(-2*LOG(Velosq)/Velosq)
        Velo2 = Velo2*SQRT(-2*LOG(Velosq)/Velosq)
!      ELSE !ziggurat method
!        Velo1=rnor()
!        Velo2=rnor()
!      END IF
      Vec3D(1:3) = Vec3D(1:3) + vec_t1(1:3) &
        * ( Velo_t1+Velo1*SQRT(BoltzmannConst*T/Species(FractNbr)%MassIC) )     !t1-Komponente (Gauss)
      Vec3D(1:3) = Vec3D(1:3) + vec_t2(1:3) &
        * ( Velo_t2+Velo2*SQRT(BoltzmannConst*T/Species(FractNbr)%MassIC) )     !t2-Komponente (Gauss)

      PartState(PositionNbr,4:6) = Vec3D(1:3)
    ELSE !PositionNbr .EQ. 0
      CALL abort(&
__STAMP__&
,'PositionNbr .EQ. 0!')
    END IF !PositionNbr .NE. 0
  END DO !i = ...NbrOfParticle
CASE DEFAULT
  CALL abort(&
__STAMP__&
,'wrong velo-distri!')
END SELECT

END SUBROUTINE SetSurfacefluxVelocities


SUBROUTINE SamplePoissonDistri(RealTarget,IntSample,Flag_opt)
!===================================================================================================================================
! Sample IntSample from Poisson-Distri around RealTarget (if Flag present it will be turned off at sample limit, otherwise abort)
!===================================================================================================================================
! MODULES
USE MOD_Globals
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
REAL,INTENT(IN)                :: RealTarget
LOGICAL,INTENT(INOUT),OPTIONAL :: Flag_opt
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES      
INTEGER,INTENT(OUT)            :: IntSample    
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
LOGICAL         :: Flag
INTEGER         :: Npois
REAL            :: Tpois, RandVal1
!===================================================================================================================================

IF (PRESENT(Flag_opt)) THEN
  Flag=Flag_opt
ELSE
  Flag=.FALSE.
END IF

Npois=0
Tpois=1.0
CALL RANDOM_NUMBER(RandVal1)
DO
  Tpois=RandVal1*Tpois
  IF (Tpois.LT.TINY(Tpois)) THEN
    IF (Flag) THEN !Turn off Poisson Sampling and "sample" by random-rounding
      IPWRITE(*,*)'WARNING: target is too large for poisson sampling: switching now to Random rounding...'
      IntSample = INT(RealTarget + RandVal1)
      Flag = .FALSE.
      EXIT
    ELSE !Turning off not allowed: abort (RealTarget must be decreased ot PoissonSampling turned off manually)
      CALL abort(&
__STAMP__&
,'ERROR in SamplePoissonDistri: RealTarget (e.g. flux) is too large for poisson sampling!')
    END IF
  END IF
  IF (Tpois.GT.EXP(-RealTarget)) THEN
    Npois=Npois+1
    CALL RANDOM_NUMBER(RandVal1)
  ELSE
    IntSample = Npois
    EXIT
  END IF
END DO

END SUBROUTINE SamplePoissonDistri


SUBROUTINE IntegerDivide(Ntot,length,Ai,Ni)
!===================================================================================================================================
! Divide the Integer Ntot into separate Ni inside different "areas" Ai (attention: old Ni is counted up -> needs to be initialized!)
!===================================================================================================================================
! MODULES
USE MOD_Globals
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
INTEGER,INTENT(IN)               :: Ntot, length
REAL,INTENT(IN)                  :: Ai(1:length)
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES      
INTEGER,INTENT(INOUT)            :: Ni(1:length)     
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
INTEGER         :: iN, iRan, Nitemp, Nrest, Ntot0
REAL            :: Atot, Bi(0:length), RandVal1, A2i(1:length), A2tot !,Error,Nrel(1:length),Arel(1:length)
!===================================================================================================================================

IF(Ntot.EQ.0) RETURN

Atot=0.
Ntot0=0
DO iN=1,length
  Atot=Atot+Ai(iN)
  Ntot0=Ntot0+Ni(iN)
END DO
!print*,Ai/Atot

!-- divide into INT-parts
Nrest=Ntot
A2tot=0.
Bi(:)=0.
DO iN=1,length
  Nitemp=INT(REAL(Ai(iN))/REAL(Atot)*Ntot) !INT-part
  Ni(iN)=Ni(iN)+Nitemp
  Nrest=Nrest-Nitemp !remaining number
  A2i(iN)=REAL(Ai(iN))/REAL(Atot)*Ntot - Nitemp !elem weight for remaining number
  A2tot=A2tot+A2i(iN)
  Bi(iN)=A2tot !elem upper limit for remaining number
END DO

!-- distribute remaining number
IF (Nrest.LT.0) THEN
  CALL abort(&
__STAMP__&
,'ERROR 1 in IntegerDivide!')
ELSE IF (Nrest.GT.0) THEN
  DO iN=1,length
    Bi(iN)=Bi(iN)/A2tot !normalized upper limit
  END DO
  DO iRan=1,Nrest
    CALL RANDOM_NUMBER(RandVal1)
    DO iN=1,length
      IF( Bi(iN-1).LT.RandVal1 .AND. RandVal1.LE.Bi(iN) ) THEN
        Ni(iN)=Ni(iN)+1
        EXIT
      END IF
    END DO
  END DO
END IF

!-- test if remaining number was distributed
Nrest=Ntot+Ntot0
DO iN=1,length
  Nrest=Nrest-Ni(iN)
END DO
IF (Nrest.NE.0) THEN
  IPWRITE(*,*) 'Ntot: ',Ntot
  IPWRITE(*,*) 'Ntot0: ',Ntot0
  IPWRITE(*,*) 'Nrest: ',Nrest
  CALL abort(&
__STAMP__&
,'ERROR 2 in IntegerDivide!')
END IF

!Error=0
!DO iN=1,length
!  Nrel(iN)=REAL(Ni(iN))/REAL(Ntot)
!  Arel(iN)=Ai(iN)      /Atot
!  Error=Error+(Nrel(iN)-Arel(iN))**2
!END DO
!IPWRITE(*,*)'Error=',Error

END SUBROUTINE IntegerDivide


SUBROUTINE SetCellLocalParticlePosition(chunkSize,iSpec,iInit,UseExactPartNum)
!===================================================================================================================================
!> routine for inserting particles positions locally in every cell
!===================================================================================================================================
! MODULES
USE MOD_Globals
USE MOD_Globals_Vars,          ONLY : BoltzmannConst
USE MOD_Particle_Vars,         ONLY : Species, PDM, PartState, PEM
USE MOD_Particle_Tracking_Vars,ONLY : DoRefMapping, TriaTracking
USE MOD_Mesh_Vars,             ONLY : nElems
USE MOD_Particle_Mesh,         ONLY : BoundsOfElement, ParticleInsideQuad3D, PartInElemCheck
USE MOD_Eval_xyz               ,ONLY: GetPositionInRefElem
USE MOD_Particle_Mesh_Vars,    ONLY : GEO, epsOneCell
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
INTEGER, INTENT(IN)              :: iSpec
INTEGER, INTENT(IN)              :: iInit
LOGICAL, INTENT(IN)              :: UseExactPartNum
!-----------------------------------------------------------------------------------------------------------------------------------
! INOUTPUT VARIABLES
INTEGER, INTENT(INOUT)           :: chunkSize
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
INTEGER                          :: iElem, ichunkSize
INTEGER                          :: iPart,  nPart
REAL                             :: iRan, RandomPos(3)
REAL                             :: PartDens
LOGICAL                          :: InsideFlag
REAL                             :: Bounds(1:2,1:3) ! Bounds(1,1:3) --> maxCoords , Bounds(2,1:3) --> minCoords
REAL                             :: Det(6,2)
REAL                             :: RefPos(1:3)
INTEGER                          :: CellChunkSize(1:nElems)
INTEGER                          :: chunkSize_tmp, ParticleIndexNbr
!-----------------------------------------------------------------------------------------------------------------------------------
  IF (UseExactPartNum) THEN
    IF(chunkSize.GE.PDM%maxParticleNumber) THEN
      CALL abort(&
__STAMP__,&
'ERROR in SetCellLocalParticlePosition: Maximum particle number reached! max. particles needed: ',chunksize)
    END IF
    CellChunkSize(:)=0
    IF (Species(iSpec)%Init(iInit)%ElemPartDensityFileID.EQ.0) THEN
      CALL IntegerDivide(chunkSize,nElems,GEO%Volume(:),CellChunkSize(:))
    ELSE
      CALL IntegerDivide(chunkSize,nElems,Species(iSpec)%Init(iInit)%ElemPartDensity(:)*GEO%Volume(:),CellChunkSize(:))
    END IF
  ELSE
    PartDens = Species(iSpec)%Init(iInit)%PartDensity / Species(iSpec)%MacroParticleFactor   ! numerical Partdensity is needed
    chunkSize_tmp = INT(PartDens * GEO%LocalVolume)
    IF(chunkSize_tmp.GE.PDM%maxParticleNumber) THEN
      CALL abort(&
__STAMP__,&
'ERROR in SetCellLocalParticlePosition: Maximum particle number during insanity check! max. particles needed: ',chunkSize_tmp)
    END IF
  END IF

  ichunkSize = 1
  ParticleIndexNbr = 1
  DO iElem = 1, nElems
    CALL BoundsOfElement(iElem,Bounds)
    IF (UseExactPartNum) THEN
      nPart = CellChunkSize(iElem)
    ELSE
      CALL RANDOM_NUMBER(iRan)
      nPart = INT(PartDens * GEO%Volume(iElem) + iRan)
    END IF
    DO iPart = 1, nPart
      ParticleIndexNbr = PDM%nextFreePosition(iChunksize + PDM%CurrentNextFreePosition)
      IF (ParticleIndexNbr .ne. 0) THEN
        InsideFlag=.FALSE.
        DO WHILE(.NOT.InsideFlag)
          CALL RANDOM_NUMBER(RandomPos)
          RandomPos = Bounds(1,:) + RandomPos*(Bounds(2,:)-Bounds(1,:))
          IF (DoRefMapping) THEN
            CALL GetPositionInRefElem(RandomPos,RefPos,iElem)
            IF (MAXVAL(ABS(RefPos)).GT.epsOneCell(iElem)) InsideFlag=.TRUE.
          ELSE
            IF (TriaTracking) THEN
              CALL ParticleInsideQuad3D(RandomPos,iElem,InsideFlag,Det)
            ELSE
              CALL PartInElemCheck(RandomPos,iPart,iElem,InsideFlag)
            END IF
          END IF
        END DO
        PartState(ParticleIndexNbr,1:3) = RandomPos(1:3)
        PDM%ParticleInside(ParticleIndexNbr) = .TRUE.
        PDM%IsNewPart(ParticleIndexNbr)=.TRUE.
        PDM%dtFracPush(ParticleIndexNbr) = .FALSE.
        PEM%Element(ParticleIndexNbr) = iElem
        ichunkSize = ichunkSize + 1
      ELSE
        CALL abort(&
__STAMP__&
,'ERROR in SetCellLocalParticlePosition: Maximum particle number reached during inserting! --> ParticleIndexNbr.EQ.0')
      END IF
    END DO
  END DO
  chunkSize = ichunkSize - 1

END SUBROUTINE SetCellLocalParticlePosition


FUNCTION SYNGE(velabs, temp, mass, BK2)
!===================================================================================================================================
! Maxwell-Juettner distribution according to Synge Book p.48
!===================================================================================================================================
! MODULES
USE MOD_Globals_Vars,   ONLY: BoltzmannConst

USE MOD_Equation_Vars,  ONLY: c_inv,c2
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
REAL,INTENT(IN)   :: velabs, temp, mass, BK2
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLE
REAL              :: SYNGE
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLE
REAL              :: gamma
!===================================================================================================================================
gamma = 1./sqrt(1.-(velabs*c_inv)*(velabs*c_inv))
SYNGE = velabs*velabs*gamma**5/BK2*exp(-mass*c2*gamma/(BoltzmannConst*temp))
END FUNCTION SYNGE


FUNCTION QUASIREL(velabs, temp, mass)
!===================================================================================================================================
! discard gamma in the prefactor, maintain it in the computation of the energy
!===================================================================================================================================
! MODULES
USE MOD_Globals_Vars,  ONLY: BoltzmannConst
USE MOD_Equation_Vars,  ONLY: c_inv,c2
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
REAL ,INTENT(IN)    :: velabs, temp, mass
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLE
REAL     :: QUASIREL
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLE
REAL     :: gamma
!===================================================================================================================================
  gamma = 1/sqrt(1-(velabs*c_inv)*(velabs*c_inv))
  QUASIREL = velabs*velabs*gamma**5._8* &
               exp((1._8-gamma)*mass*c2/(BoltzmannConst*temp))
END FUNCTION


FUNCTION DEVI(mass, temp, gamma)
!===================================================================================================================================
! derivative to find max of function
!===================================================================================================================================
! MODULES
USE MOD_Globals_Vars,  ONLY: BoltzmannConst
USE MOD_Equation_Vars,  ONLY: c2
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
REAL,INTENT(IN)     :: mass, temp, gamma
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLE
REAL                :: DEVI
!===================================================================================================================================
  DEVI = mass*c2/(BoltzmannConst*temp)* &
           gamma*(gamma*gamma-1._8)-5._8*gamma*gamma+3._8
END FUNCTION


FUNCTION BessK(ord,arg)
!===================================================================================================================================
! Modified Bessel function of second kind and integer order (currently only 2nd...) and real argument,
! required for Maxwell-Juettner distribution
!===================================================================================================================================
! MODULES
USE MOD_Globals
USE MOD_Globals_Vars,    ONLY: PI,EuMas
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
REAL,   INTENT(IN)  :: arg
INTEGER,INTENT(IN)  :: ord
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLE
REAL                :: BessK
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
REAL     :: BessI0, BessI1, BessK0, BessK1, BessK0_old 
REAL     :: rr, eps, ct, w0
REAL     :: set_a(12), set_b(12), set_c(8)
INTEGER  :: kk, k0
!===================================================================================================================================

  !em = 0.577215664901533_8        ! Euler–Mascheroni constant
  eps= 1E-15_8
  
  set_a = (/0.125E0_8, 7.03125E-2_8,                  &
          7.32421875E-2_8, 1.1215209960938E-1_8,      &
          2.2710800170898E-1_8, 5.7250142097473E-1_8, &
          1.7277275025845E0_8, 6.0740420012735E0_8,    &
          2.4380529699556E01_8, 1.1001714026925E02_8, &
          5.5133589612202E02_8, 3.0380905109224E03_8/)
     
  set_b = (/-0.375E0_8, -1.171875E-1_8,                 &
          -1.025390625E-1_8, -1.4419555664063E-1_8,     &
          -2.7757644653320E-1_8, -6.7659258842468E-1_8, &
          -1.9935317337513E0_8, -6.8839142681099E0_8,   &
          -2.7248827311269E01_8, -1.2159789187654E02_8, &
          -6.0384407670507E02_8, -3.3022722944809E03_8/)
     
  set_c = (/0.125E0_8, 0.2109375E0_8,                 &
          1.0986328125E0_8, 1.1775970458984E01_8,     &
          2.1461706161499E2_8, 5.9511522710323E03_8,  &
          2.3347645606175E05_8, 1.2312234987631E07_8/)
        
  
!==========================================================================================!
! Compute I_0(x) and I_1(x)
!==========================================================================================!
  IF (arg .EQ. 0.) THEN
    BessI1 = 0.
    BessI0 = 1.
    
  ELSE IF (arg .LE. 18.) THEN
    BessI0 = 1.
    rr     = 1.
    kk     = 0
    DO WHILE ((rr/BessI0) .GT. eps)
      kk = kk+1
      rr = .25*rr*arg*arg/(kk*kk)
      BessI0 = BessI0 + rr
    END DO
!     WRITE(*,*) 'BessI0:', BessI0
!     WRITE(*,*) kk
    BessI1 = 1.
    rr     = 1.
    kk     = 0
    DO WHILE ((rr/BessI1) .GT. eps)
      kk = kk+1
      rr = .25*rr*arg*arg/(kk*(kk+1))
      BessI1 = BessI1 + rr
    END DO
    BessI1 = 0.5*arg*BessI1
!     WRITE(*,*) 'BessI1:', BessI1
    
  ELSE
    IF      (arg .LT. 35.) THEN
      k0 = 12
    ELSE IF (arg .LT. 50.) THEN 
      k0 =  9
    ELSE
      k0 =  7
    END IF
    BessI0 = 1._8
    DO kk = 1,k0
      BessI0 = BessI0 + set_a(kk)*arg**(-kk)
    END DO
    BessI0 = exp(arg)/sqrt(2._8*pi*arg)*BessI0
!     WRITE(*,*) 'BessI0: ', BessI0
    BessI1 = 1._8
    DO kk = 1,k0
      BessI1 = BessI1 + set_b(kk)*arg**(-kk)
    END DO
    BessI1 = exp(arg)/sqrt(2._8*pi*arg)*BessI1
!     WRITE(*,*) 'BessI1: ', BessI1
  END IF
    
!==========================================================================================! 
! Compute K_0(x)
!==========================================================================================!
  IF (arg .LE. 0.) THEN
    CALL abort(&
__STAMP__&
,' mod. Bessel function of second kind requries pos arg:')
  ELSE IF (arg .LE. 9.) THEN
    kk = 1
    ct = -log(arg/2.)-EuMas
    w0 = 1._8
    rr = 0.25*arg*arg
    BessK0 = rr*(w0+ct) 
    BessK0_old = 1.E20
    DO WHILE (abs((BessK0-BessK0_old)/BessK0) .GT. eps)
      kk = kk+1
      BessK0_old = BessK0
      w0 = w0+1._8/kk
      rr = 0.25*rr*arg*arg/(kk*kk)
      BessK0 = BessK0 + rr*(w0+ct)
    END DO
    BessK0 = BessK0 + ct
  ELSE
    BessK0 = 1._8
    DO kk = 1,8
      BessK0 = BessK0 + set_c(kk)*arg**(-2._8*kk)
    END DO
    BessK0 = BessK0/(2._8*arg*BessI0)
!     WRITE(*,*) 'BessK0: ', BessK0
  END IF

!==========================================================================================! 
! Compute K_1(x) and K_n(x)
!==========================================================================================!
  BessK1 = (1._8/arg-BessI1*BessK0)/BessI0
  BessK = 2._8*(ord-1._8)*BessK1/arg + BessK0
  
END FUNCTION BessK


SUBROUTINE AdaptiveBCAnalyze()
!===================================================================================================================================
! Sampling of variables (part-density, velocity and energy) for Adaptive BC elements
!===================================================================================================================================
! MODULES
USE MOD_Globals
USE MOD_Globals_Vars,           ONLY:BoltzmannConst
USE MOD_DSMC_Vars,              ONLY:PartStateIntEn, DSMC, CollisMode, SpecDSMC
USE MOD_DSMC_Vars,              ONLY:useDSMC
USE MOD_Particle_Vars,          ONLY:PartState, PDM, PartSpecies, Species, nSpecies, PEM, Adaptive_MacroVal
USE MOD_Particle_Vars,          ONLY:AdaptiveWeightFac
USE MOD_Mesh_Vars,              ONLY:nElems
USE MOD_Particle_Mesh_Vars,     ONLY:GEO,IsTracingBCElem
USE MOD_DSMC_Analyze,           ONLY:CalcTVib,CalcTVibPoly,CalcTelec
#if USE_LOADBALANCE
USE MOD_LoadBalance_tools,      ONLY:LBStartTime, LBElemSplitTime, LBPauseTime
USE MOD_LoadBalance_vars,       ONLY:nPartsPerBCElem
#endif /*USE_LOADBALANCE*/
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
INTEGER                       :: ElemID, AdaptiveElemID, i, iSpec
REAL                          :: TVib_TempFac
REAL, ALLOCATABLE             :: Source(:,:,:)
#if USE_LOADBALANCE
REAL                          :: tLBStart
#endif /*USE_LOADBALANCE*/
!===================================================================================================================================
ALLOCATE(Source(1:11,1:nElems,1:nSpecies))
Source=0.0
#if USE_LOADBALANCE
CALL LBStartTime(tLBStart)
#endif /*USE_LOADBALANCE*/
DO i=1,PDM%ParticleVecLength
  IF (PDM%ParticleInside(i)) THEN
    ElemID = PEM%Element(i)
    IF(.NOT.IsTracingBCElem(ElemID))CYCLE
#if USE_LOADBALANCE
    nPartsPerBCElem(ElemID) = nPartsPerBCElem(ElemID) + 1
#endif /*USE_LOADBALANCE*/
    !ElemID = BC2AdaptiveElemMap(ElemID)
    iSpec = PartSpecies(i)
    Source(1:3,ElemID, iSpec) = Source(1:3,ElemID,iSpec) + PartState(i,4:6)
    Source(4:6,ElemID, iSpec) = Source(4:6,ElemID,iSpec) + PartState(i,4:6)**2
    Source(7,ElemID, iSpec) = Source(7,ElemID, iSpec) + 1.0  !density
    IF(useDSMC)THEN
      IF ((CollisMode.EQ.2).OR.(CollisMode.EQ.3)) THEN
        IF (SpecDSMC(PartSpecies(i))%InterID.EQ.2) THEN
          Source(8:9,ElemID, iSpec) = Source(8:9,ElemID, iSpec) + PartStateIntEn(i,1:2)
        END IF
      END IF
      IF (DSMC%ElectronicModel) THEN
        Source(10,ElemID, iSpec) = Source(10,ElemID, iSpec) + PartStateIntEn(i,3)
      END IF
    END IF
    Source(11,ElemID, iSpec) = Source(11,ElemID, iSpec) + 1.0
  END IF
END DO
#if USE_LOADBALANCE
CALL LBPauseTime(LB_ADAPTIVE,tLBStart)
#endif /*USE_LOADBALANCE*/

!DO iElem = 1,nElems
!IF(.NOT.IsTracingBCElem(iElem))CYCLE
DO AdaptiveElemID = 1,nElems
IF(.NOT.IsTracingBCElem(AdaptiveElemID))CYCLE
#if USE_LOADBALANCE
CALL LBStartTime(tLBStart)
#endif /*USE_LOADBALANCE*/
DO iSpec = 1,nSpecies
  ! write timesample particle values of bc elements in global macrovalues of bc elements
  IF (Source(11,AdaptiveElemID,iSpec).GT.0.0) THEN
    ! compute flow velocity
    Adaptive_MacroVal(1:3,AdaptiveElemID,iSpec) = (1-AdaptiveWeightFac)*Adaptive_MacroVal(1:3,AdaptiveElemID,iSpec) &
        + AdaptiveWeightFac*Source(1:3,AdaptiveElemID, iSpec) / Source(11,AdaptiveElemID,iSpec)
    ! compute flow Temperature
    Adaptive_MacroVal(4:6,AdaptiveElemID,iSpec) = (1-AdaptiveWeightFac)*Adaptive_MacroVal(4:6,AdaptiveElemID,iSpec) &
      + AdaptiveWeightFac*Species(iSpec)%MassIC/ BoltzmannConst &
      * ( Source(4:6,AdaptiveElemID,iSpec) / Source(11,AdaptiveElemID,iSpec) &
      - (Source(1:3,AdaptiveElemID,iSpec)/Source(11,AdaptiveElemID,iSpec))**2)
    ! compute density
    Adaptive_MacroVal(7,AdaptiveElemID,iSpec) = (1-AdaptiveWeightFac)*Adaptive_MacroVal(7,AdaptiveElemID,iSpec) &
        + AdaptiveWeightFac*Source(7,AdaptiveElemID,iSpec) /GEO%Volume(AdaptiveElemID)*Species(iSpec)%MacroParticleFactor
    IF(useDSMC)THEN
      IF ((CollisMode.EQ.2).OR.(CollisMode.EQ.3))THEN
      IF ((SpecDSMC(iSpec)%InterID.EQ.2).OR.(SpecDSMC(iSpec)%InterID.EQ.20)) THEN
          IF (DSMC%VibEnergyModel.EQ.0) THEN              ! SHO-model
            IF(SpecDSMC(iSpec)%PolyatomicMol) THEN
              IF( (Source(8,AdaptiveElemID,iSpec)/Source(11,AdaptiveElemID,iSpec)) .GT. SpecDSMC(iSpec)%EZeroPoint) THEN
                Adaptive_MacroVal(8,AdaptiveElemID,iSpec) = (1-AdaptiveWeightFac)*Adaptive_MacroVal(8,AdaptiveElemID,iSpec) &
                  + AdaptiveWeightFac*CalcTVibPoly(Source(8,AdaptiveElemID,iSpec) / Source(11,AdaptiveElemID,iSpec),iSpec)
              ELSE
                Adaptive_MacroVal(8,AdaptiveElemID,iSpec) = (1-AdaptiveWeightFac)*Adaptive_MacroVal(8,AdaptiveElemID,iSpec)
              END IF
            ELSE
              TVib_TempFac=Source(8,AdaptiveElemID,iSpec)/ (Source(11,AdaptiveElemID,iSpec) &
                *BoltzmannConst*SpecDSMC(iSpec)%CharaTVib)
              IF (TVib_TempFac.LE.DSMC%GammaQuant) THEN
                Adaptive_MacroVal(8,AdaptiveElemID,iSpec) = (1-AdaptiveWeightFac)*Adaptive_MacroVal(8,AdaptiveElemID,iSpec)
              ELSE
                Adaptive_MacroVal(8,AdaptiveElemID,iSpec) = (1-AdaptiveWeightFac)*Adaptive_MacroVal(8,AdaptiveElemID,iSpec) &
                  + AdaptiveWeightFac*SpecDSMC(iSpec)%CharaTVib / LOG(1 + 1/(TVib_TempFac-DSMC%GammaQuant))
              END IF
            END IF
          ELSE                                            ! TSHO-model
            Adaptive_MacroVal(8,AdaptiveElemID,iSpec) = (1-AdaptiveWeightFac)*Adaptive_MacroVal(8,AdaptiveElemID,iSpec) &
              + AdaptiveWeightFac*CalcTVib(SpecDSMC(iSpec)%CharaTVib &
              , Source(8,AdaptiveElemID,iSpec)/Source(11,AdaptiveElemID,iSpec),SpecDSMC(iSpec)%MaxVibQuant)
          END IF
          Adaptive_MacroVal(9,AdaptiveElemID,iSpec) = (1-AdaptiveWeightFac)*Adaptive_MacroVal(9,AdaptiveElemID,iSpec) &
              + AdaptiveWeightFac*Source(9,AdaptiveElemID,iSpec)/(Source(11,AdaptiveElemID,iSpec)*BoltzmannConst)
          IF (DSMC%ElectronicModel) THEN
            Adaptive_MacroVal(10,AdaptiveElemID,iSpec) = (1-AdaptiveWeightFac)*Adaptive_MacroVal(10,AdaptiveElemID,iSpec) &
              + AdaptiveWeightFac*CalcTelec( Source(10,AdaptiveElemID,iSpec)/Source(11,AdaptiveElemID,iSpec),iSpec)
          END IF
        END IF
      END IF
    END IF
  ELSE
    Adaptive_MacroVal(1:10,AdaptiveElemID,iSpec) = (1-AdaptiveWeightFac)*Adaptive_MacroVal(1:10,AdaptiveElemID,iSpec)
  END IF
END DO
#if USE_LOADBALANCE
CALL LBElemSplitTime(ElemID,tLBStart)
#endif /*USE_LOADBALANCE*/
END DO

END SUBROUTINE AdaptiveBCAnalyze


END MODULE MOD_part_emission
