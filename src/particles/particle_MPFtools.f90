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

MODULE MOD_part_MPFtools
!===================================================================================================================================
! CONTAINS THE vMPF part
!===================================================================================================================================
! MODULES
! IMPLICIT VARIABLE HANDLING
  IMPLICIT NONE 
  PRIVATE

INTERFACE SplitParticle
  MODULE PROCEDURE SplitParticle
END INTERFACE

INTERFACE MergeParticles
  MODULE PROCEDURE MergeParticles
END INTERFACE

INTERFACE DefinePolyVec
  MODULE PROCEDURE DefinePolyVec
END INTERFACE

INTERFACE DefineSplitVec
  MODULE PROCEDURE DefineSplitVec
END INTERFACE

INTERFACE StartParticleMerge
  MODULE PROCEDURE StartParticleMerge
END INTERFACE


!-----------------------------------------------------------------------------------------------------------------------------------
! GLOBAL VARIABLES 
!-----------------------------------------------------------------------------------------------------------------------------------
! Private Part ---------------------------------------------------------------------------------------------------------------------
! Public Part ----------------------------------------------------------------------------------------------------------------------
PUBLIC :: SplitParticle, MergeParticles, DefinePolyVec, DefineSplitVec, StartParticleMerge
!===================================================================================================================================

CONTAINS   

SUBROUTINE StartParticleMerge()                                                                
!===================================================================================================================================
! Particle Merge routine
!===================================================================================================================================
! MODULES
USE MOD_Globals           ,ONLY: LocalTime
USE MOD_Particle_Vars     ,ONLY: doParticleMerge, nSpecies,vMPFMergeParticleTarget,vMPF_SpecNumElem,vMPFSplitParticleTarget
USE MOD_Mesh_Vars         ,ONLY: nElems
#if USE_LOADBALANCE
USE MOD_LoadBalance_tools ,ONLY: LBStartTime,LBElemSplitTime
#endif /*USE_LOADBALANCE*/
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
INTEGER                         :: iElem, iSpec
#if USE_LOADBALANCE
REAL                             :: tLBStart
#endif /*USE_LOADBALANCE*/
!===================================================================================================================================
#if USE_LOADBALANCE
CALL LBStartTime(tLBStart) ! Start time measurement
#endif /*USE_LOADBALANCE*/
DO iElem = 1, nElems
  DO iSpec= 1, nSpecies
    IF ((vMPFMergeParticleTarget.GT.0).AND.(vMPF_SpecNumElem(iElem,iSpec).GT.vMPFMergeParticleTarget*2)) THEN
      CALL MergeParticles(iElem, vMPFMergeParticleTarget, vMPF_SpecNumElem(iElem,iSpec), iSpec)
    ELSE IF((vMPFSplitParticleTarget.GT.0).AND.(vMPF_SpecNumElem(iElem,iSpec).LT.vMPFSplitParticleTarget/2) &
      .AND.(vMPF_SpecNumElem(iElem,iSpec).GT.2)) THEN
    CALL MergeParticles(iElem, vMPFSplitParticleTarget, vMPF_SpecNumElem(iElem,iSpec), iSpec)
  END IF
END DO
#if USE_LOADBALANCE
CALL LBElemSplitTime(iElem,tLBStart) ! save time to elem and reset tLBStart variable
#endif /*USE_LOADBALANCE*/
END DO
doParticleMerge=.false.
END SUBROUTINE StartParticleMerge
                                                                                        
                                                                                                   
SUBROUTINE SplitParticle(iPart, deltaE,CSquare)                                                                
!===================================================================================================================================
! Split Particles
!===================================================================================================================================
! MODULES
  USE MOD_Globals,        ONLY : Abort
  USE MOD_Particle_Vars,  ONLY : PDM, PartState, RandomVec, NumRanVec, PartSpecies, PartMPF, PEM, Species, vMPF_relativistic  
  USE MOD_DSMC_Vars,      ONLY : useDSMC, CollisMode, PartStateIntEn    
  USE MOD_Equation_Vars,  ONLY : c2                                                   
!-----------------------------------------------------------------------------------------------------------------------------------
! IMPLICIT VARIABLE HANDLING
  IMPLICIT NONE                                                                                    
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
  INTEGER,INTENT(IN)              :: iPart
  REAL, INTENT(IN)                :: deltaE
  LOGICAL,INTENT(INOUT)           :: CSquare 
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
  INTEGER                         :: PositionNbr, iVec
  REAL                            :: beta, iRan, VeloSQ, Gamma
  REAL                            :: v_old(3), oldEner, old_mom(1:3), new_mom(1:3)
!===================================================================================================================================

  v_old(1:3) = PartState(iPart,4:6)

!.... Get free particle index for the new particle produced
  PDM%ParticleVecLength = PDM%ParticleVecLength + 1
  PDM%CurrentNextFreePosition = PDM%CurrentNextFreePosition + 1 
  PositionNbr = PDM%nextFreePosition(PDM%CurrentNextFreePosition)
  IF (PositionNbr.EQ.0) THEN
    CALL Abort(&
    __STAMP__&
    ,'ERROR in SplitParticle: New Particle Number greater max Part Num!')
  END IF

!Set new particle parameters
  PDM%ParticleInside(PositionNbr) = .true.
  PartSpecies(PositionNbr) = PartSpecies(iPart)
  PartState(PositionNbr,1:3) = PartState(iPart,1:3)
  IF (useDSMC.AND.(CollisMode.GT.1)) THEN
    PartStateIntEn(PositionNbr, 1) = PartStateIntEn(iPart, 1)
    PartStateIntEn(PositionNbr, 2) =   PartStateIntEn(iPart, 2)
  END IF
  PEM%Element(PositionNbr) = PEM%Element(iPart)

!set new MPFs
  PartMPF(iPart) =  PartMPF(iPart) / 2.0
  PartMPF(PositionNbr) = PartMPF(iPart)

!calulating beta = sqrt(deltaE/MPF_old)
  IF (vMPF_relativistic) THEN
    CALL RANDOM_NUMBER(iRan)
    iVec = INT(NumRanVec*iRan + 1)
    VeloSQ = v_old(1)*v_old(1)+v_old(2)*v_old(2)+v_old(3)*v_old(3)
    Gamma = VeloSq/c2      
    Gamma = 1./SQRT(1.-Gamma) 
    oldEner = Species(PartSpecies(iPart))%MassIC * 2.0*PartMPF(iPart)* (Gamma-1.)*c2  
    old_mom(1:3) = Species(PartSpecies(iPart))%MassIC *2.0* PartMPF(iPart)* v_old(1:3)*Gamma 
    !beta = CalcRelaBeta(oldEner,RandomVec(iVec, 1:3), PartMPF(iPart), PartSpecies(iPart), deltaE, old_mom(1:3))
    beta = CalcRelaBeta2(oldEner,RandomVec(iVec, 1:3), PartMPF(iPart), PartSpecies(iPart), deltaE, old_mom(1:3))
    
    new_mom(1:3) = old_mom(1:3)/2.0 + beta*RandomVec(iVec, 1:3)
    PartState(iPart,4:6) = RelVeloFromMom(new_mom(1:3), PartSpecies(iPart), PartMPF(iPart))
    new_mom(1:3) = old_mom(1:3)/2.0 - beta*RandomVec(iVec, 1:3)
    PartState(PositionNbr,4:6) = RelVeloFromMom(new_mom(1:3), PartSpecies(iPart), PartMPF(iPart))
  ELSE  
    beta = SQRT(2*deltaE/(PartMPF(iPart)*Species(PartSpecies(iPart))%MassIC))
    CALL RANDOM_NUMBER(iRan)
    iVec = INT(NumRanVec*iRan + 1)
    PartState(iPart,4:6) = v_old(1:3) - beta * RandomVec(iVec, 1:3)
    PartState(PositionNbr,4:6) = v_old(1:3) + beta * RandomVec(iVec, 1:3)
  END IF

  VeloSQ = PartState(iPart,4) * PartState(iPart,4) &
        + PartState(iPart,5) * PartState(iPart,5) &
        + PartState(iPart,6) * PartState(iPart,6)
  IF(VeloSQ.GT.c2) THEN
    CSquare=.true.
    PDM%ParticleInside(PositionNbr)=.false.
  END IF
  VeloSQ = PartState(PositionNbr,4) * PartState(PositionNbr,4) &
        + PartState(PositionNbr,5) * PartState(PositionNbr,5) &
        + PartState(PositionNbr,6) * PartState(PositionNbr,6)
  IF(VeloSQ.GT.c2) THEN
    CSquare=.true.
    PDM%ParticleInside(PositionNbr)=.false.
  END IF
END SUBROUTINE SplitParticle


SUBROUTINE DoEnergyConservation(iPart,iPart2, deltaE,CSquare)
!===================================================================================================================================
! Split Particles
!===================================================================================================================================
  USE MOD_Particle_Vars, ONLY : PartState, RandomVec, NumRanVec, PartSpecies, PartMPF, Species, vMPF_relativistic  
  USE MOD_Equation_Vars,          ONLY : c2
!----------------------------------------------------------------------------------------------------------------------------------
! IMPLICIT VARIABLE HANDLING
  IMPLICIT NONE
!----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
  INTEGER,INTENT(IN)              :: iPart, iPart2
  REAL, INTENT(IN)                :: deltaE 
  LOGICAL,INTENT(INOUT)          :: CSquare      
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES  
!----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
  INTEGER                         ::  iVec
  REAL                            :: beta, iRan, VeloSQ, VeloSQ2, Gamma
  REAL                            :: v_mom(3), v_mom2, enerpart, v_old(1:3), oldEner, old_mom(1:3), new_mom(1:3)
!===================================================================================================================================
  IF (vMPF_relativistic) THEN
    CALL RANDOM_NUMBER(iRan)
    iVec = INT(NumRanVec*iRan + 1)
    v_old(1:3) = PartState(iPart,4:6)
    VeloSQ = v_old(1)*v_old(1)+v_old(2)*v_old(2)+v_old(3)*v_old(3)
    Gamma = VeloSq/c2      
    Gamma = 1./SQRT(1.-Gamma) 
    oldEner = Species(PartSpecies(iPart))%MassIC * PartMPF(iPart)* (Gamma-1.)*c2  
    old_mom(1:3) = Species(PartSpecies(iPart))%MassIC * PartMPF(iPart)* v_old(1:3)*Gamma

    v_old(1:3) = PartState(iPart2,4:6)
    VeloSQ = v_old(1)*v_old(1)+v_old(2)*v_old(2)+v_old(3)*v_old(3)
    Gamma = VeloSq/c2      
    Gamma = 1./SQRT(1.-Gamma) 
    oldEner = oldEner + Species(PartSpecies(iPart))%MassIC *PartMPF(iPart)* (Gamma-1.)*c2  
    old_mom(1:3) = old_mom(1:3) + Species(PartSpecies(iPart))%MassIC * PartMPF(iPart)* v_old(1:3)*Gamma  
    !beta = CalcRelaBeta(oldEner,RandomVec(iVec, 1:3), PartMPF(iPart), PartSpecies(iPart), deltaE, old_mom(1:3))
    beta = CalcRelaBeta2(oldEner,RandomVec(iVec, 1:3), PartMPF(iPart), PartSpecies(iPart), deltaE, old_mom(1:3))

    new_mom(1:3) = old_mom(1:3)/2.0 + beta*RandomVec(iVec, 1:3)
    PartState(iPart,4:6) = RelVeloFromMom(new_mom(1:3), PartSpecies(iPart), PartMPF(iPart))
    new_mom(1:3) = old_mom(1:3)/2.0 - beta*RandomVec(iVec, 1:3)
    PartState(iPart2,4:6) = RelVeloFromMom(new_mom(1:3), PartSpecies(iPart2), PartMPF(iPart2))
  ELSE
    v_mom(1:3) = (PartState(iPart,4:6)*PartMPF(iPart) + PartState(iPart2,4:6)*PartMPF(iPart2))*Species(PartSpecies(iPart))%MassIC
    v_mom2 = v_mom(1)*v_mom(1)+v_mom(2)*v_mom(2)+v_mom(3)*v_mom(3)
    enerpart = 0.5*Species(PartSpecies(iPart))%MassIC*(PartMPF(iPart) & 
        *(PartState(iPart,4)*PartState(iPart,4)+PartState(iPart,5)*PartState(iPart,5)+PartState(iPart,6)*PartState(iPart,6)) &
        + PartMPF(iPart2) &
        *(PartState(iPart2,4)*PartState(iPart2,4)+PartState(iPart2,5)*PartState(iPart2,5)+PartState(iPart2,6)*PartState(iPart2,6)))

    !calulating beta = sqrt(deltaE/MPF_old)
    beta = SQRT((enerpart+deltaE)*PartMPF(iPart2)*Species(PartSpecies(iPart))%MassIC-v_mom2/4.0)
    !set new velocity v1
    CALL RANDOM_NUMBER(iRan)
    iVec = INT(NumRanVec*iRan + 1)
    PartState(iPart,4:6) = (v_mom(1:3)/2.0 + beta * RandomVec(iVec, 1:3))/(PartMPF(iPart)*Species(PartSpecies(iPart))%MassIC)
    PartState(iPart2,4:6) = (v_mom(1:3)/2.0 - beta * RandomVec(iVec, 1:3))/(PartMPF(iPart2)*Species(PartSpecies(iPart2))%MassIC)
  END IF

  VeloSQ = PartState(iPart,4) * PartState(iPart,4) &
        + PartState(iPart,5) * PartState(iPart,5) &
        + PartState(iPart,6) * PartState(iPart,6)
  IF(VeloSQ.GT.c2) THEN
    CSquare=.true.
  END IF  
  VeloSQ2 = PartState(iPart2,4) * PartState(iPart2,4) &
        + PartState(iPart2,5) * PartState(iPart2,5) &
        + PartState(iPart2,6) * PartState(iPart2,6)
  IF(VeloSQ2.GT.c2) THEN
    CSquare=.true.
  END IF
END SUBROUTINE DoEnergyConservation


SUBROUTINE MergeParticles(iElem, NumFinPart, SpecNum, SpecID)                                                                
!===================================================================================================================================
! Merge Particles
!===================================================================================================================================
! MODULES
  USE MOD_Globals
  USE MOD_Particle_Vars
  USE Levenberg_Marquardt
  USE MOD_Eval_xyz,               ONLY:GetPositionInRefElem
  USE MOD_Particle_Tracking_Vars, ONLY:DoRefmapping
#if (PP_TimeDiscMethod==300)
  USE MOD_FPFlow_Vars,            ONLY: vMPFOldVeloVib, vMPFOldVeloRot
#endif
! IMPLICIT VARIABLE HANDLING
  IMPLICIT NONE                                                                      
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES                                                                        
  INTEGER,INTENT(IN)              :: iElem, SpecNum, SpecID
  INTEGER,INTENT(IN)              :: NumFinPart
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
  REAL                  :: CellTemp(3)
  INTEGER               :: iPart, iLoop, iLoop2, PositionNbr
  LOGICAL               :: PosFailed
!===================================================================================================================================

  ALLOCATE(vMPFOldVelo(3,SpecNum))
  ALLOCATE(vMPFOldPos(3,SpecNum), vMPFOldMPF(SpecNum))
#if (PP_TimeDiscMethod==300)
  ALLOCATE(vMPFOldVeloVib(2,SpecNum))
  ALLOCATE(vMPFOldVeloRot(2,SpecNum))
#endif
  iLoop2=1
  ALLOCATE(PartStateMap(SpecNum,3))
  IF (SpecNum.GE.NumFinPart) THEN
    ALLOCATE(PartStatevMPFSpec(SpecNum))
  ELSE
    ALLOCATE(PartStatevMPFSpec(NumFinPart))
  END IF
  iPart = PEM%pStart(iElem)                        
  DO iLoop = 1, PEM%pNumber(iElem)
    IF(PartSpecies(iPart).EQ.SpecID) THEN
      IF(DoRefMapping)THEN ! here Nearst-GP is missing
        PartStateMap(iLoop2,1:3)=PartPosRef(1:3,iLoop2)
      ELSE
        CALL GetPositionInRefElem(PartState(iPart,1:3), PartStateMap(iLoop2,1:3), iElem)
      END IF
      PartStatevMPFSpec(iLoop2) = iPart
      iLoop2 = iLoop2 + 1
    END IF
    iPart = PEM%pNext(iPart)    
  END DO

  SWRITE(*,*) 'Start Particle Split/Merge'
  IF (NumFinPart.GT.SpecNum) THEN
    ALLOCATE(vMPFNewPosNum(NumFinPart - SpecNum))
    DO iLoop = 1 , NumFinPart - SpecNum
      PDM%ParticleVecLength = PDM%ParticleVecLength + 1
      PDM%CurrentNextFreePosition = PDM%CurrentNextFreePosition + 1 
      PositionNbr = PDM%nextFreePosition(PDM%CurrentNextFreePosition)
      IF (PositionNbr.EQ.0) THEN
        CALL Abort(&
        __STAMP__&
        ,'ERROR in SplitParticle: New Particle Number greater max Part Num!')
      END IF
      PartStatevMPFSpec(SpecNum + iLoop) = PositionNbr
      vMPFNewPosNum(iLoop)=PositionNbr
      !Set new particle parameters
      PDM%ParticleInside(PositionNbr) = .true.
      PartSpecies(PositionNbr) = SpecID
      PEM%Element(PositionNbr) = iElem
    END DO
  END IF

  IF(vMPF_velocityDistribution.NE.'DENSEST') THEN
    CALL SplitRegion(SpecNum)
    CALL DeleteParticlesMPF(NumFinPart, CellTemp, SpecNum, SpecID)
    CALL SetMPFParticlePosCube(iElem, NumFinPart)
    CALL SetNewvMPF(NumFinPart)
    CALL SetNewVelos(NumFinPart, CellTemp, SpecNum, SpecID)
  ELSE
    CALL DeleteParticlesMPF(NumFinPart, CellTemp, SpecNum, SpecID)
    CALL SetMPFParticlePosDensEst(iElem, NumFinPart,SpecNum,PosFailed)
    IF(.NOT.PosFailed) THEN
      CALL SetNewvMPF(NumFinPart)
      CALL SetNewVelos(NumFinPart, CellTemp, SpecNum, SpecID)
    END IF
  END IF

  SWRITE(*,*) 'Finish Particle Split/Merge'

  DEALLOCATE(PartStateMap, PartStatevMPFSpec, vMPFOldVelo, vMPFOldPos, vMPFOldMPF)
  IF (vMPF_velocityDistribution.EQ.'DENSEST') DEALLOCATE(vMPF_NewPosRefElem) 
  IF (NumFinPart.GT.SpecNum) DEALLOCATE(vMPFNewPosNum)
#if (PP_TimeDiscMethod==300)
  DEALLOCATE(vMPFOldVeloVib,vMPFOldVeloRot)
#endif

END SUBROUTINE MergeParticles


SUBROUTINE fcn (m, n, x, fvec, fjac, iflag)
!===================================================================================================================================
! do not know / BLACK MAGIC ;)
!===================================================================================================================================
! MODULES
! IMPLICIT VARIABLE HANDLING
  IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
  INTEGER, PARAMETER         :: dp = SELECTED_REAL_KIND(12, 60)
! INPUT VARIABLES
  INTEGER, INTENT(IN)        :: m, n
  REAL (dp), INTENT(IN)      :: x(:)
  REAL (dp), INTENT(IN OUT)  :: fvec(:)
  INTEGER, INTENT(IN OUT)    :: iflag
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
  REAL (dp), INTENT(OUT)     :: fjac(:,:)
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
!===================================================================================================================================
IF (iflag == 1) CALL ssqfcn (m, n, x, fvec)
IF (iflag == 2) CALL ssqjac (m, n, fjac)
RETURN
END SUBROUTINE fcn


SUBROUTINE ssqjac (m, n, fjac)
!===================================================================================================================================
! ssqjac / more magic - calculate values of polynomial fit function on interpolation points
!===================================================================================================================================
! MODULES
  USE Levenberg_Marquardt
  USE MOD_Particle_Vars,    ONLY:vMPFPolyPoint, vMPF_OrderVec
! IMPLICIT VARIABLE HANDLING
  IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
  INTEGER, INTENT(IN)     :: m, n
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
  REAL (dp), INTENT(OUT)  :: fjac(:,:)
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
  INTEGER                 :: i_Sol, i_DOFIn
!===================================================================================================================================

  DO i_Sol = 1 ,m
    DO i_DOFIn =1, n   
      FJAC(i_Sol,i_DOFIn) = - vMPFPolyPoint(1,i_Sol)**(vMPF_OrderVec(1,i_DOFIn)) &
                            * vMPFPolyPoint(2,i_Sol)**(vMPF_OrderVec(2,i_DOFIn)) &
                            * vMPFPolyPoint(3,i_Sol)**(vMPF_OrderVec(3,i_DOFIn))
    END DO
  END DO

  RETURN
END SUBROUTINE ssqjac


SUBROUTINE ssqfcn (m, n, x, fvec)
!===================================================================================================================================
! ssqfcn?! final MAAAGIC - calc diff between values on interpolation points and actual polynomial fit
!===================================================================================================================================
! MODULES
  USE Levenberg_Marquardt
  USE MOD_Particle_Vars,    ONLY:vMPFPolyPoint, vMPF_OrderVec, vMPFPolySol,vMPFOldMPF
! IMPLICIT VARIABLE HANDLING
  IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
  INTEGER, INTENT(IN)     :: m, n
  REAL (dp), INTENT(IN)   :: x(:)
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
  REAL (dp), INTENT(OUT)  :: fvec(:)
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
  INTEGER                 :: i_Sol, i_DOFIn
!===================================================================================================================================

  DO i_Sol = 1 ,m
    FVEC(i_Sol) = vMPFPolySol(i_Sol) 
    DO i_DOFIn =1, n   
      FVEC(i_Sol) = FVEC(i_Sol) - x(i_DOFIn) *vMPFPolyPoint(1,i_Sol)**(vMPF_OrderVec(1,i_DOFIn)) &
                        *vMPFPolyPoint(2,i_Sol)**(vMPF_OrderVec(2,i_DOFIn)) &
                        *vMPFPolyPoint(3,i_Sol)**(vMPF_OrderVec(3,i_DOFIn))
    END DO
    FVEC(i_Sol)=FVEC(i_Sol)*vMPFOldMPF(i_Sol)
  END DO

END SUBROUTINE ssqfcn


SUBROUTINE DefinePolyVec(VecOrder)                                                                
!===================================================================================================================================
! build fit polynomial
!===================================================================================================================================
! MODULES
  USE MOD_Particle_Vars, ONLY : vMPF_OrderVec                                                      
!----------------------------------------------------------------------------------------------------------------------------------
! IMPLICIT VARIABLE HANDLING
  IMPLICIT NONE                                                                                    !
!----------------------------------------------------------------------------------------------------------------------------------
! ARGUMENT LIST DECLARATION                                                                        !
  INTEGER,INTENT(IN)              :: VecOrder
!----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLE DECLARATION
  INTEGER                         :: DOF_Poly
  INTEGER                         :: x_dir, y_dir, z_dir, sum_dir
!===================================================================================================================================

  DOF_Poly = (VecOrder+3)*(VecOrder+2)*(VecOrder+1)/6
  sum_dir = 1
  ALLOCATE(vMPF_OrderVec(3,DOF_Poly))
  DO x_dir = 0, VecOrder
    DO y_dir = 0, VecOrder
      DO z_dir = 0, VecOrder
        IF ((x_dir+y_dir+z_dir).GT.VecOrder) CYCLE
        vMPF_OrderVec(1, sum_dir) = x_dir
        vMPF_OrderVec(2, sum_dir) = y_dir
        vMPF_OrderVec(3, sum_dir) = z_dir
        sum_dir = sum_dir + 1
      END DO
    END DO
  END DO

END SUBROUTINE DefinePolyVec


SUBROUTINE DefineSplitVec(SplitOrder)                                                                !
!===================================================================================================================================
! blabla
!===================================================================================================================================
! MODULES
  USE MOD_Particle_Vars, ONLY : vMPF_SplitVec ,vMPF_SplitVecBack                                                     !
!----------------------------------------------------------------------------------------------------------------------------------
! IMPLICIT VARIABLE HANDLING
  IMPLICIT NONE                                                                                    !
!----------------------------------------------------------------------------------------------------------------------------------
! ARGUMENT LIST DECLARATION                                                                        !
  INTEGER,INTENT(IN)              :: SplitOrder
!----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLE DECLARATION
  INTEGER                         :: DOF_Split
  INTEGER                         :: x_dir, y_dir, z_dir, sum_dir
!===================================================================================================================================
  DOF_Split = (SplitOrder+1)**3
  sum_dir = 1
  ALLOCATE(vMPF_SplitVec(3,DOF_Split))
  ALLOCATE(vMPF_SplitVecBack(SplitOrder+1,SplitOrder+1,SplitOrder+1))
  DO x_dir = 0, SplitOrder
    DO y_dir = 0, SplitOrder
      DO z_dir = 0, SplitOrder
        vMPF_SplitVec(1, sum_dir) = x_dir
        vMPF_SplitVec(2, sum_dir) = y_dir
        vMPF_SplitVec(3, sum_dir) = z_dir
        vMPF_SplitVecBack(x_dir+1,y_dir+1,z_dir+1) = sum_dir
        sum_dir = sum_dir + 1
      END DO
    END DO
  END DO

END SUBROUTINE DefineSplitVec


SUBROUTINE SplitRegion(SpecNum)
!===================================================================================================================================
!
!===================================================================================================================================
! MODULES
  USE MOD_Particle_Vars, ONLY : vMPFMergeCellSplitOrder,PartStateMap, vMPF_SplitVec, vMPFPolyPoint &
                                ,vMPFPolySol, PartMPF, vMPF_oldMPFSum, vMPF_SplitVecBack, PartStatevMPFSpec
!----------------------------------------------------------------------------------------------------------------------------------
! IMPLICIT VARIABLE HANDLING
  IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! ARGUMENT LIST DECLARATION
  INTEGER, INTENT(IN)   :: SpecNum
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLE DECLARATION
  REAL, ALLOCATABLE     :: RegPartNum(:)
  INTEGER               :: iPart, PolOrder, x_cube, y_cube, z_cube
  REAL                  :: ZoneLenght, RegPartSum
!===================================================================================================================================

  ZoneLenght = 2.0/(vMPFMergeCellSplitOrder+1)
  PolOrder = (vMPFMergeCellSplitOrder+1)**3
  ALLOCATE(RegPartNum(PolOrder))
  RegPartNum = 0                        

  DO iPart = 1, SpecNum
    x_cube = MIN(INT((PartStateMap(iPart,1)+1)/2*(vMPFMergeCellSplitOrder+1)+1),(vMPFMergeCellSplitOrder+1))
    y_cube = MIN(INT((PartStateMap(iPart,2)+1)/2*(vMPFMergeCellSplitOrder+1)+1),(vMPFMergeCellSplitOrder+1))
    z_cube = MIN(INT((PartStateMap(iPart,3)+1)/2*(vMPFMergeCellSplitOrder+1)+1),(vMPFMergeCellSplitOrder+1))
    RegPartNum(vMPF_SplitVecBack(x_cube,y_cube,z_cube)) = RegPartNum(vMPF_SplitVecBack(x_cube,y_cube,z_cube))  &
                          + PartMPF(PartStatevMPFSpec(iPart))
  END DO

  ALLOCATE(vMPFPolyPoint(3,PolOrder))
  ALLOCATE(vMPFPolySol(PolOrder))
  RegPartSum = SUM(RegPartNum)

  vMPF_oldMPFSum = RegPartSum
  vMPFPolySol = RegPartNum/RegPartSum
  vMPFPolyPoint = vMPF_SplitVec*ZoneLenght-1+ZoneLenght/2

END SUBROUTINE SplitRegion


SUBROUTINE DeleteParticlesMPF(FinPartNum, Temp, SpecNum, SpecID)
!===================================================================================================================================
!
!===================================================================================================================================
! MODULES
  USE MOD_Particle_Vars, ONLY : PartState, vMPF_oldEngSum, vMPF_oldMomSum ,Species, PartMPF, PDM, &
                                  PartStatevMPFSpec, vMPFOldPos, vMPFOldVelo, vMPFOldMPF, vMPF_relativistic
  USE MOD_Globals_Vars,          ONLY: BoltzmannConst
  USE MOD_Equation_Vars, ONLY : c2
#if (PP_TimeDiscMethod==300)
  USE MOD_FPFlow_Vars,  ONLY : FPInnerVelos, vMPF_oldEngSumRot,vMPF_oldEngSumVib, vMPF_oldMomSumVib, vMPF_oldMomSumRot
  USE MOD_DSMC_Vars, ONLY : SpecDSMC
#endif
!===================================================================================================================================
! IMPLICIT VARIABLE HANDLING
  IMPLICIT NONE
!----------------------------------------------------------------------------------------------------------------------------------
! ARGUMENT LIST DECLARATION
  INTEGER, INTENT(IN)   :: FinPartNum, SpecNum, SpecID
  REAL, INTENT(OUT)     :: Temp(3)
!----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLE DECLARATION
  INTEGER               :: iLoop
  REAL                  :: PartV_2(3), PartV2(3), RealPartNum, VeloSq, Gamma
!===================================================================================================================================

  vMPF_oldMomSum = 0.0
  vMPF_oldEngSum = 0.0 
  PartV_2 = 0.0
  PartV2 = 0.0
  RealPartNum = 0.0
                          
  DO iLoop = 1, SpecNum
    IF (vMPF_relativistic) THEN
      VeloSq = PartState(PartStatevMPFSpec(iLoop),4) * PartState(PartStatevMPFSpec(iLoop),4) &
               + PartState(PartStatevMPFSpec(iLoop),5) * PartState(PartStatevMPFSpec(iLoop),5) &
               + PartState(PartStatevMPFSpec(iLoop),6) * PartState(PartStatevMPFSpec(iLoop),6)
      Gamma = VeloSq/c2      
      Gamma = 1./SQRT(1.-Gamma)
      vMPF_oldEngSum = vMPF_oldEngSum+  Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iLoop)) &
                * (Gamma-1.)*c2
      vMPF_oldMomSum(1:3) = vMPF_oldMomSum(1:3) + Species(SpecID)%MassIC &
                      * PartMPF(PartStatevMPFSpec(iLoop)) * PartState(PartStatevMPFSpec(iLoop),4:6)*Gamma
    ELSE
      vMPF_oldEngSum = vMPF_oldEngSum+  0.5 * Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iLoop)) &
                * (PartState(PartStatevMPFSpec(iLoop),4)**2 + PartState(PartStatevMPFSpec(iLoop),5)**2  &
                 + PartState(PartStatevMPFSpec(iLoop),6)**2)
      vMPF_oldMomSum(1:3) = vMPF_oldMomSum(1:3) + Species(SpecID)%MassIC &
                      * PartMPF(PartStatevMPFSpec(iLoop)) * PartState(PartStatevMPFSpec(iLoop),4:6)  
    END IF
    PartV_2 = PartV_2 + PartState(PartStatevMPFSpec(iLoop),4:6) * PartMPF(PartStatevMPFSpec(iLoop))
    PartV2 = PartV2 + PartState(PartStatevMPFSpec(iLoop),4:6)**2 * PartMPF(PartStatevMPFSpec(iLoop))
    RealPartNum = RealPartNum + PartMPF(PartStatevMPFSpec(iLoop))
    vMPFOldVelo(1:3, iLoop) = PartState(PartStatevMPFSpec(iLoop),4:6)
    vMPFOldPos(1:3, iLoop) = PartState(PartStatevMPFSpec(iLoop),1:3)
    vMPFOldMPF(iLoop) = PartMPF(PartStatevMPFSpec(iLoop))
    IF (iLoop.GT.FinPartNum) PDM%ParticleInside(PartStatevMPFSpec(iLoop)) = .false.

#if (PP_TimeDiscMethod==300)
    IF (SpecDSMC(SpecID)%InterID.EQ.2) THEN
      IF (vMPF_relativistic) THEN
        VeloSq = FPInnerVelos(PartStatevMPFSpec(iLoop))%FP_VibVelo(1) * FPInnerVelos(PartStatevMPFSpec(iLoop))%FP_VibVelo(1) &
                 + FPInnerVelos(PartStatevMPFSpec(iLoop))%FP_VibVelo(2) * FPInnerVelos(PartStatevMPFSpec(iLoop))%FP_VibVelo(2) 
        Gamma = VeloSq/c2      
        Gamma = 1./SQRT(1.-Gamma)
        vMPF_oldEngSumVib = vMPF_oldEngSumVib + PartMPF(PartStatevMPFSpec(iLoop))* (Gamma-1.)*c2
        vMPF_oldMomSumVib(1:2) = vMPF_oldMomSumVib(1:2) &
              + PartMPF(PartStatevMPFSpec(iLoop)) * FPInnerVelos(PartStatevMPFSpec(iLoop))%FP_VibVelo(1:2)*Gamma

        VeloSq = FPInnerVelos(PartStatevMPFSpec(iLoop))%FP_RotVelo(1) * FPInnerVelos(PartStatevMPFSpec(iLoop))%FP_RotVelo(1) &
                 + FPInnerVelos(PartStatevMPFSpec(iLoop))%FP_RotVelo(2) * FPInnerVelos(PartStatevMPFSpec(iLoop))%FP_RotVelo(2) 
        Gamma = VeloSq/c2      
        Gamma = 1./SQRT(1.-Gamma)
        vMPF_oldEngSumRot = vMPF_oldEngSumRot + PartMPF(PartStatevMPFSpec(iLoop))* (Gamma-1.)*c2
        vMPF_oldMomSumRot(1:2) = vMPF_oldMomSumRot(1:2) &
              + PartMPF(PartStatevMPFSpec(iLoop)) * FPInnerVelos(PartStatevMPFSpec(iLoop))%FP_RotVelo(1:2)*Gamma
      ELSE
        vMPF_oldEngSumVib = vMPF_oldEngSumVib+  0.5 * PartMPF(PartStatevMPFSpec(iLoop)) &
                  * (FPInnerVelos(PartStatevMPFSpec(iLoop))%FP_VibVelo(1)**2 &
                  + FPInnerVelos(PartStatevMPFSpec(iLoop))%FP_VibVelo(2)**2)
        vMPF_oldMomSumVib(1:2) = vMPF_oldMomSumVib(1:2) + PartMPF(PartStatevMPFSpec(iLoop)) &
                * FPInnerVelos(PartStatevMPFSpec(iLoop))%FP_VibVelo(1:2)
        vMPF_oldEngSumRot = vMPF_oldEngSumRot+  0.5 * PartMPF(PartStatevMPFSpec(iLoop)) &
                  * (FPInnerVelos(PartStatevMPFSpec(iLoop))%FP_RotVelo(1)**2 &
                  + FPInnerVelos(PartStatevMPFSpec(iLoop))%FP_RotVelo(2)**2)
        vMPF_oldMomSumRot(1:2) = vMPF_oldMomSumRot(1:2) + PartMPF(PartStatevMPFSpec(iLoop)) &
                * FPInnerVelos(PartStatevMPFSpec(iLoop))%FP_RotVelo(1:2)
      END IF
    END IF
#endif

  END DO
  PartV_2 = (PartV_2/RealPartNum)**2
  PartV2 = PartV2/RealPartNum
  Temp(1:3) = Species(SpecID)%MassIC/(BoltzmannConst)*(PartV2(1:3)-PartV_2(1:3))

END SUBROUTINE DeleteParticlesMPF


#ifdef DONTCOMPILETHIS
SUBROUTINE SetMPFParticlePos(FinPartNum,x)
!===================================================================================================================================
!
!===================================================================================================================================
! Modules
  USE MOD_Particle_Vars, ONLY : PartState,vMPFMergePolyOrder, vMPF_OrderVec
!----------------------------------------------------------------------------------------------------------------------------------
! IMPLICIT VARIABLE HANDLING
  IMPLICIT NONE
!----------------------------------------------------------------------------------------------------------------------------------
! ARGUMENT LIST DECLARATION
  INTEGER, INTENT(IN)   :: FinPartNum
  REAL, INTENT(IN)      :: x(:)
!----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLE DECLARATION
  INTEGER               :: iPart, iLoop, iDOF, DOF_LMInput
  REAL                  :: RandVac(3), ProbPos,  iRan
!===================================================================================================================================

  DOF_LMInput = (vMPFMergePolyOrder+1)*(vMPFMergePolyOrder+2)*(vMPFMergePolyOrder+3)/6                 
  DO iLoop = 1, FinPartNum
  ProbPos = 0.0
    CALL RANDOM_NUMBER(RandVac)  
    RandVac = RandVac * 2.0 - 1.0
    DO iDOF =1, DOF_LMInput  
      ProbPos = ProbPos + x(iDOF) *RandVac(1)**(vMPF_OrderVec(1,iDOF)) &
                        *RandVac(2)**(vMPF_OrderVec(2,iDOF)) &
                        *RandVac(3)**(vMPF_OrderVec(3,iDOF))
    END DO
    CALL RANDOM_NUMBER(iRan)
    DO WHILE (iRan.GE.ProbPos)
      ProbPos = 0.0
      CALL RANDOM_NUMBER(RandVac)  
      RandVac = RandVac * 2.0 - 1.0

      DO iDOF =1, DOF_LMInput  
        ProbPos = ProbPos + x(iDOF) *RandVac(1)**(vMPF_OrderVec(1,iDOF)) &
                          *RandVac(2)**(vMPF_OrderVec(2,iDOF)) &
                          *RandVac(3)**(vMPF_OrderVec(3,iDOF))
      END DO
      CALL RANDOM_NUMBER(iRan)
    END DO
    PartState(iLoop, 1:3) = RandVac
  END DO

END SUBROUTINE SetMPFParticlePos
#endif /*DONTCOMPILETHIS*/


SUBROUTINE SetMPFParticlePosCube(iElem, FinPartNum)
!===================================================================================================================================
!
!===================================================================================================================================
! MODULES
  USE MOD_Particle_Vars, ONLY : PartState, vMPFMergeCellSplitOrder&
                        , vMPFPolySol, vMPF_SplitVecBack, PartStatevMPFSpec, vMPF_velocityDistribution &
                        , vMPF_NewPosRefElem
  USE MOD_Eval_xyz,           ONLY:TensorProductInterpolation
  USE MOD_Mesh_Vars,          ONLY:NGeo,XCL_NGeo,XiCL_NGeo,wBaryCL_NGeo
!----------------------------------------------------------------------------------------------------------------------------------
! IMPLICIT VARIABLE HANDLING
  IMPLICIT NONE
!----------------------------------------------------------------------------------------------------------------------------------
! ARGUMENT LIST DECLARATION
  INTEGER, INTENT(IN)   :: iElem, FinPartNum
!----------------------------------------------------------------------------------------------------------------------------------
! Local variable declaration
  INTEGER               :: iLoop, x_cube, y_cube, z_cube, iLoop2
  REAL                  :: RandVac(3), ProbPos,  iRan
!===================================================================================================================================

  iLoop2 = 1                      

  IF(vMPF_velocityDistribution.EQ.'DENSEST') ALLOCATE(vMPF_NewPosRefElem(FinPartNum,3))  

  DO iLoop = 1, FinPartNum
    ProbPos = 0.0
    CALL RANDOM_NUMBER(RandVac)  
    x_cube = MIN(INT(RandVac(1)*(vMPFMergeCellSplitOrder+1)+1),(vMPFMergeCellSplitOrder+1))
    y_cube = MIN(INT(RandVac(2)*(vMPFMergeCellSplitOrder+1)+1),(vMPFMergeCellSplitOrder+1))
    z_cube = MIN(INT(RandVac(3)*(vMPFMergeCellSplitOrder+1)+1),(vMPFMergeCellSplitOrder+1))
    ProbPos = vMPFPolySol(vMPF_SplitVecBack(x_cube,y_cube,z_cube))
    CALL RANDOM_NUMBER(iRan)
    DO WHILE (iRan.GE.ProbPos)
      ProbPos = 0.0
      CALL RANDOM_NUMBER(RandVac)  
      x_cube = MIN(INT(RandVac(1)*(vMPFMergeCellSplitOrder+1)+1),(vMPFMergeCellSplitOrder+1))
      y_cube = MIN(INT(RandVac(2)*(vMPFMergeCellSplitOrder+1)+1),(vMPFMergeCellSplitOrder+1))
      z_cube = MIN(INT(RandVac(3)*(vMPFMergeCellSplitOrder+1)+1),(vMPFMergeCellSplitOrder+1))
      ProbPos = vMPFPolySol(vMPF_SplitVecBack(x_cube,y_cube,z_cube))
      CALL RANDOM_NUMBER(iRan) 
    END DO
    RandVac = RandVac * 2.0 - 1.0
    IF(vMPF_velocityDistribution.EQ.'DENSEST')  vMPF_NewPosRefElem(iLoop, 1:3) = RandVac 
    CALL TensorProductInterpolation(RandVac,3,NGeo,XiCL_NGeo,wBaryCL_NGeo,&
                       XCL_NGeo(:,:,:,:,iElem),PartState(PartStatevMPFSpec(iLoop),1:3))!,iElem)
    !PartState(PartStatevMPFSpec(iLoop), 1:3) = MapToGeo(RandVac, P)
  END DO

END SUBROUTINE SetMPFParticlePosCube

SUBROUTINE SetMPFParticlePosDensEst(iElem, FinPartNum, SpecNum,PosFailed)
!===================================================================================================================================
!
!===================================================================================================================================
! MODULES
  USE MOD_Particle_Vars, ONLY : PartState,PartStatevMPFSpec, PartStateMap &
                        , vMPF_oldMPFSum, vMPFOldMPF, vMPF_NewPosRefElem, vMPF_velocityDistribution &
                        ,vMPFOldPos, vMPFOldVelo, vMPFNewPosNum, PartMPF, PDM
  USE MOD_Eval_xyz,           ONLY:TensorProductInterpolation
  USE MOD_Mesh_Vars,          ONLY:NGeo,XCL_NGeo,XiCL_NGeo,wBaryCL_NGeo

!----------------------------------------------------------------------------------------------------------------------------------
! IMPLICIT VARIABLE HANDLING
  IMPLICIT NONE                                                                                    !
!----------------------------------------------------------------------------------------------------------------------------------
! ARGUMENT LIST DECLARATION                                                                        !
INTEGER, INTENT(IN)   :: iElem, FinPartNum, SpecNum
LOGICAL , INTENT(INOUT)             :: PosFailed
!----------------------------------------------------------------------------------------------------------------------------------
! Local variable declaration
INTEGER               :: iLoop,  iLoop2, NumLoop
REAL                  :: RandVac(3), ProbPos,  iRan,  bandwidth, MaxProb, MaxProbtemp

!===================================================================================================================================
bandwidth = 0.03 !0.03
PosFailed=.false.
!DO iNode = 1,8
!  P(1:3,iNode) = GEO%NodeCoords(1:3,GEO%ElemToNodeID(iNode,iElem))
!END DO                   

IF(vMPF_velocityDistribution.EQ.'DENSEST') ALLOCATE(vMPF_NewPosRefElem(FinPartNum,3))   

MaxProb=0.0
DO iLoop = 1, SpecNum  
  MaxProbtemp = 0.0
  DO iLoop2 = 1, SpecNum
    MaxProbtemp = MaxProbtemp + GaussCore(bandwidth, PartStateMap(iLoop2,1:3), PartStateMap(iLoop,1:3))
  END DO
  IF (MaxProbtemp.GT.MaxProb) MaxProb = MaxProbTemp
END DO
MaxProb = MaxProb/(bandwidth*SpecNum)

DO iLoop = 1, FinPartNum
  ProbPos = 0.0
  CALL RANDOM_NUMBER(RandVac)  
  RandVac = RandVac * 2.0 - 1.0
  DO iLoop2 = 1, SpecNum
    ProbPos = ProbPos + GaussCore(bandwidth, PartStateMap(iLoop2,1:3), RandVac(1:3))
  END DO
  ProbPos = ProbPos/(MaxProb*bandwidth*SpecNum)
  !IF(ProbPos.GT.1.0) print*, 'Sauarsch: ', ProbPos
  CALL RANDOM_NUMBER(iRan)
  NumLoop = 0
  DO WHILE (iRan.GE.ProbPos)
    ProbPos = 0.0
    CALL RANDOM_NUMBER(RandVac)  
    RandVac = RandVac * 2.0 - 1.0
    DO iLoop2 = 1, SpecNum
      ProbPos = ProbPos + GaussCore(bandwidth, PartStateMap(iLoop2,1:3), RandVac(1:3))
    END DO
    ProbPos = ProbPos/(MaxProb*bandwidth*SpecNum)
    CALL RANDOM_NUMBER(iRan)
    NumLoop = NumLoop + 1
    IF(NumLoop.GT.100000) THEN
      PosFailed = .true.
      EXIT
    END IF
  END DO
  IF(PosFailed) EXIT
  IF(vMPF_velocityDistribution.EQ.'DENSEST')  vMPF_NewPosRefElem(iLoop, 1:3) = RandVac
  CALL TensorProductInterpolation(RandVac,3,NGeo,XiCL_NGeo,wBaryCL_NGeo,&
                     XCL_NGeo(1:3,0:NGeo,0:NGeo,0:NGeo,iElem),PartState(PartStatevMPFSpec(iLoop),1:3))!,iElem)
  !PartState(PartStatevMPFSpec(iLoop), 1:3) = MapToGeo(RandVac, P)
END DO

IF(PosFailed) THEN
  DO iLoop = 1, SpecNum
    PartState(PartStatevMPFSpec(iLoop), 1:3) = vMPFOldPos(1:3,iLoop)
    PartState(PartStatevMPFSpec(iLoop), 4:6) = vMPFOldVelo(1:3,iLoop)
    PartMPF(PartStatevMPFSpec(iLoop)) =  vMPFOldMPF(iLoop)
    PDM%ParticleInside(PartStatevMPFSpec(iLoop)) = .true.
  END DO
  IF(FinPartNum.GT.SpecNum) THEN
      DO iLoop = 1, FinPartNum - SpecNum
        PDM%ParticleInside(vMPFNewPosNum(iLoop)) = .false.
      END DO
  END IF
END IF

vMPF_oldMPFSum = SUM(vMPFOldMPF)
 
!--------------------------------------------------------------------------------------------------!
!--------------------------------------------------------------------------------------------------!
END SUBROUTINE SetMPFParticlePosDensEst 


SUBROUTINE SetNewVelos(NewPartNum, Temp, SpecNum, SpecID)                                                                
!===================================================================================================================================
!
!===================================================================================================================================
! MODULES
  USE MOD_Particle_Vars
  USE Levenberg_Marquardt
  USE MOD_Globals
  USE MOD_Equation_Vars,          ONLY : c2
#if (PP_TimeDiscMethod==300)
  USE MOD_DSMC_Vars, ONLY : SpecDSMC, DSMC, PartStateIntEn
  USE MOD_FPFlow_Vars, ONLY : vMPFOldVeloVib, vMPFOldVeloRot, FPInnerVelos, SpecFP
#endif
!----------------------------------------------------------------------------------------------------------------------------------
! IMPLICIT VARIABLE HANDLING
  IMPLICIT NONE
!----------------------------------------------------------------------------------------------------------------------------------
! ARGUMENT LIST DECLARATION
  INTEGER,INTENT(IN)              :: NewPartNum, SpecNum, SpecID
  REAL,INTENT(IN)                 :: Temp(3)
!----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLE DECLARATION
  INTEGER                         :: iPart, iLoop, iDir, DOF_LMInput, info, iPart2
  INTEGER, ALLOCATABLE            :: iwa(:)
  DOUBLE PRECISION, ALLOCATABLE   :: fjac(:,:), fvec(:), x(:) !!evtl double
  DOUBLE PRECISION                :: tol
  REAL                            :: iRan, VeloSq, Gamma
  LOGICAL                         :: CSquare, CSquareFP
!===================================================================================================================================
  CSquareFP=.false.
  CSquare=.false.
  IF (vMPF_velocityDistribution.NE.'DENSEST') THEN
    tol = SQRT( EPSILON(tol) )
    DOF_LMInput = (vMPFMergePolyOrder+1)*(vMPFMergePolyOrder+2)*(vMPFMergePolyOrder+3)/6
    ALLOCATE(iwa(DOF_LMInput), & 
             x(DOF_LMInput), &
             fjac(SpecNum,DOF_LMInput), &
             fvec(SpecNum))
    DEALLOCATE(vMPFPolyPoint,vMPFPolySol)
    ALLOCATE(vMPFPolyPoint(3,SpecNum))
    ALLOCATE(vMPFPolySol(SpecNum))

    IF (vMPF_velocityDistribution.EQ.'OVDR') THEN
      ALLOCATE(vMPFOldBrownVelo(SpecNum,3))
    END IF

    vMPFPolyPoint = vMPFOldPos
    DO iDir = 1, 3
      vMPFPolySol(:) = vMPFOldVelo(iDir,:)
      x = 1.0
      CALL lmder1 (fcn, SpecNum, DOF_LMInput, x, fvec, fjac, tol, info, iwa)

    !Sample old brownian velo
      IF (vMPF_velocityDistribution.EQ.'OVDR') THEN
        DO iPart = 1, SpecNum
          vMPFOldBrownVelo(iPart,iDir) = vMPFOldVelo(iDir,iPart)
          DO iLoop =1, DOF_LMInput  
            vMPFOldBrownVelo(iPart,iDir)  = vMPFOldBrownVelo(iPart,iDir)  - x(iLoop) &
                              *vMPFPolyPoint(1,iPart)**(vMPF_OrderVec(1,iLoop)) &
                              *vMPFPolyPoint(2,iPart)**(vMPF_OrderVec(2,iLoop)) &
                              *vMPFPolyPoint(3,iPart)**(vMPF_OrderVec(3,iLoop))
          END DO
        END DO
      END IF

      DO iPart = 1, NewPartNum - 1
        PartState(PartStatevMPFSpec(iPart),iDir + 3) = 0.0      
        DO iLoop =1, DOF_LMInput  
          PartState(PartStatevMPFSpec(iPart),iDir + 3) = PartState(PartStatevMPFSpec(iPart),iDir + 3) + x(iLoop) &
                            *PartState(PartStatevMPFSpec(iPart), 1)**(vMPF_OrderVec(1,iLoop)) &
                            *PartState(PartStatevMPFSpec(iPart), 2)**(vMPF_OrderVec(2,iLoop)) &
                            *PartState(PartStatevMPFSpec(iPart), 3)**(vMPF_OrderVec(3,iLoop))
        END DO
      END DO
    END DO

    IF(vMPF_relativistic) THEN
      DO iPart=1, NewPartNum -1     
        VeloSq = PartState(PartStatevMPFSpec(iPart),4) * PartState(PartStatevMPFSpec(iPart),4) &
                 + PartState(PartStatevMPFSpec(iPart),5) * PartState(PartStatevMPFSpec(iPart),5) &
                 + PartState(PartStatevMPFSpec(iPart),6) * PartState(PartStatevMPFSpec(iPart),6)
        IF (VeloSQ.GT.c2) THEN
          Csquare=.true.
          RETURN
        END IF
        Gamma = VeloSq/c2      
        Gamma = 1./SQRT(1.-Gamma)
        vMPF_oldEngSum = vMPF_oldEngSum - Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart)) &
                         * (Gamma-1.)*c2
        vMPF_oldMomSum(1:3) = vMPF_oldMomSum(1:3) - Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart)) &
                             * PartState(PartStatevMPFSpec(iPart),4:6)*Gamma  
      END DO
      PartState(PartStatevMPFSpec(NewPartNum),4:6) = &
               RelVeloFromMom(vMPF_oldMomSum(1:3), SpecID, PartMPF(PartStatevMPFSpec(NewPartNum)))
      VeloSq = PartState(PartStatevMPFSpec(NewPartNum),4) * PartState(PartStatevMPFSpec(NewPartNum),4) &
               + PartState(PartStatevMPFSpec(NewPartNum),5) * PartState(PartStatevMPFSpec(NewPartNum),5) &
               + PartState(PartStatevMPFSpec(NewPartNum),6) * PartState(PartStatevMPFSpec(NewPartNum),6)
      IF (VeloSQ.GT.c2) THEN
        Csquare=.true.
        RETURN
      END IF
      Gamma = VeloSq/c2      
      Gamma = 1./SQRT(1.-Gamma)
      vMPF_oldEngSum = vMPF_oldEngSum - Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(NewPartNum)) &
                         * (Gamma-1.)*c2
      vMPF_oldMomSum(1:3) = vMPF_oldMomSum(1:3) - Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(NewPartNum)) &
                             * PartState(PartStatevMPFSpec(NewPartNum),4:6)*Gamma 
    ELSE
      DO iPart = 1, NewPartNum -1
        vMPF_oldEngSum = vMPF_oldEngSum - 0.5 * Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart)) &
                * (PartState(PartStatevMPFSpec(iPart),4)**2 + PartState(PartStatevMPFSpec(iPart),5)**2 &
                + PartState(PartStatevMPFSpec(iPart),6)**2)
        vMPF_oldMomSum(1:3) = vMPF_oldMomSum(1:3) - Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart)) &
                             * PartState(PartStatevMPFSpec(iPart),4:6)
      END DO
      PartState(PartStatevMPFSpec(NewPartNum),4:6) = vMPF_oldMomSum(1:3) &
                      /(Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(NewPartNum)))
      vMPF_oldEngSum = vMPF_oldEngSum - 0.5 * Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(NewPartNum)) &
                  * (PartState(PartStatevMPFSpec(NewPartNum),4)**2 + PartState(PartStatevMPFSpec(NewPartNum),5)**2 &
                  + PartState(PartStatevMPFSpec(NewPartNum),6)**2)
      vMPF_oldMomSum(1:3) = vMPF_oldMomSum(1:3) - Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(NewPartNum)) &
                             * PartState(PartStatevMPFSpec(NewPartNum),4:6)
    END IF
  END IF

IF (vMPF_velocityDistribution.EQ.'MBDR') THEN
  CALL SetNewTemp_2(Temp, NewPartNum)
ELSE IF (vMPF_velocityDistribution.EQ.'OVDR') THEN 
  CALL SetNewDistrVelo(NewPartNum, 100, SpecNum, CSquare)
ELSE IF (vMPF_velocityDistribution.EQ.'DENSEST') THEN
  CALL SetNewDistrVeloDensEst(NewPartNum, SpecNum,CSquare)
END IF 

#if (PP_TimeDiscMethod==300)
  IF (SpecDSMC(SpecID)%InterID.EQ.2) THEN
    IF (vMPF_velocityDistribution.EQ.'DENSEST') THEN
      CALL SetNewDistrFPInnerDensEst(NewPartNum, SpecNum,CSquareFP)
    ELSE IF (vMPF_velocityDistribution.EQ.'OVDR') THEN 
      CALL SetNewDistrFPInner(NewPartNum, 100, SpecNum, CSquareFP)
    ELSE
      WRITE(*,*) 'Bisher nur DENSEST mit FP erlaubt!'
      STOP
    END IF
    DO iPart =1, NewPartNum
      PartStateIntEn(PartStatevMPFSpec(iPart), 1) = &
                0.5*(FPInnerVelos(PartStatevMPFSpec(iPart))%FP_VibVelo(1)*FPInnerVelos(PartStatevMPFSpec(iPart))%FP_VibVelo(1) &
                + FPInnerVelos(PartStatevMPFSpec(iPart))%FP_VibVelo(2)*FPInnerVelos(PartStatevMPFSpec(iPart))%FP_VibVelo(2)) &
                + DSMC%GammaQuant*SpecDSMC(SpecID)%CharaTVib*BoltzmannConst
      PartStateIntEn(PartStatevMPFSpec(iPart), 2) = 0.5*SpecFP(SpecID)%RotMomentum & 
          *(FPInnerVelos(PartStatevMPFSpec(iPart))%FP_RotVelo(1)*FPInnerVelos(PartStatevMPFSpec(iPart))%FP_RotVelo(1) &
          +FPInnerVelos(PartStatevMPFSpec(iPart))%FP_RotVelo(2)*FPInnerVelos(PartStatevMPFSpec(iPart))%FP_RotVelo(2))
    END DO
  END IF
#endif
  

IF ((vMPF_oldEngSum.GT.0).AND.(.NOT.CSquare).AND.(.NOT.CSquareFP)) THEN
  CALL RANDOM_NUMBER(iRan)
  iPart = INT(NewPartNum * iRan +1)
  CALL RANDOM_NUMBER(iRan)
  iPart2 = INT(NewPartNum * iRan +1)
  DO WHILE(iPart2.EQ.iPart)
    CALL RANDOM_NUMBER(iRan)
    iPart2 = INT(NewPartNum * iRan +1)
  END DO
  CALL DoEnergyConservation(PartStatevMPFSpec(iPart),PartStatevMPFSpec(iPart2), vMPF_oldEngSum, CSquare)
  !CALL SplitParticle(PartStatevMPFSpec(iPart), vMPF_oldEngSum, CSquare)
  IF (CSquare) THEN
    SWRITE(*,*) 'Particles could not be merged/split! Continue without merge/split process. v>c'
    DO iPart = 1, SpecNum
      PartState(PartStatevMPFSpec(iPart), 1:3) = vMPFOldPos(1:3,iPart)
      PartState(PartStatevMPFSpec(iPart), 4:6) = vMPFOldVelo(1:3,iPart)
      PartMPF(PartStatevMPFSpec(iPart)) =  vMPFOldMPF(iPart)
      PDM%ParticleInside(PartStatevMPFSpec(iPart)) = .true.     

#if (PP_TimeDiscMethod==300)
  IF (SpecDSMC(SpecID)%InterID.EQ.2) THEN
      FPInnerVelos(PartStatevMPFSpec(iPart))%FP_VibVelo(1:2) = vMPFOldVeloVib(1:2,iPart)
      FPInnerVelos(PartStatevMPFSpec(iPart))%FP_RotVelo(1:2) = vMPFOldVeloRot(1:2,iPart)    
      PartStateIntEn(PartStatevMPFSpec(iPart), 1) = 0.5*(FPInnerVelos(PartStatevMPFSpec(iPart))%FP_VibVelo(1)&
          *FPInnerVelos(PartStatevMPFSpec(iPart))%FP_VibVelo(1) &
          +FPInnerVelos(PartStatevMPFSpec(iPart))%FP_VibVelo(2)*FPInnerVelos(PartStatevMPFSpec(iPart))%FP_VibVelo(2)) &
              + DSMC%GammaQuant*SpecDSMC(SpecID)%CharaTVib*BoltzmannConst
      PartStateIntEn(PartStatevMPFSpec(iPart), 2) = 0.5*SpecFP(SpecID)%RotMomentum & 
        *(FPInnerVelos(PartStatevMPFSpec(iPart))%FP_RotVelo(1)*FPInnerVelos(PartStatevMPFSpec(iPart))%FP_RotVelo(1) &
        +FPInnerVelos(PartStatevMPFSpec(iPart))%FP_RotVelo(2)*FPInnerVelos(PartStatevMPFSpec(iPart))%FP_RotVelo(2))
  END IF
#endif
    END DO
    IF(NewPartNum.GT.SpecNum) THEN
      DO iPart = 1, NewPartNum - SpecNum
        PDM%ParticleInside(vMPFNewPosNum(iPart)) = .false.
      END DO
    END IF
  ELSE 
    WRITE(*,*) 'Particles merged/split successful!'
  END IF
ELSE  !IF (vMPF_oldEngSum.LT.0) THEN
  WRITE(*,*) 'Particles could not be merged/split! Continue without merge/split process.'
  DO iPart = 1, SpecNum
    PartState(PartStatevMPFSpec(iPart), 1:3) = vMPFOldPos(1:3,iPart)
    PartState(PartStatevMPFSpec(iPart), 4:6) = vMPFOldVelo(1:3,iPart)
    PartMPF(PartStatevMPFSpec(iPart)) =  vMPFOldMPF(iPart)
    PDM%ParticleInside(PartStatevMPFSpec(iPart)) = .true.
#if (PP_TimeDiscMethod==300)
  IF (SpecDSMC(SpecID)%InterID.EQ.2) THEN
      FPInnerVelos(PartStatevMPFSpec(iPart))%FP_VibVelo(1:2) = vMPFOldVeloVib(1:2,iPart)
      FPInnerVelos(PartStatevMPFSpec(iPart))%FP_RotVelo(1:2) = vMPFOldVeloRot(1:2,iPart)
      PartStateIntEn(PartStatevMPFSpec(iPart), 1) = 0.5*(FPInnerVelos(PartStatevMPFSpec(iPart))%FP_VibVelo(1)&
          *FPInnerVelos(PartStatevMPFSpec(iPart))%FP_VibVelo(1) &
          +FPInnerVelos(PartStatevMPFSpec(iPart))%FP_VibVelo(2)*FPInnerVelos(PartStatevMPFSpec(iPart))%FP_VibVelo(2)) &
              + DSMC%GammaQuant*SpecDSMC(SpecID)%CharaTVib*BoltzmannConst
      PartStateIntEn(PartStatevMPFSpec(iPart), 2) = 0.5*SpecFP(SpecID)%RotMomentum & 
        *(FPInnerVelos(PartStatevMPFSpec(iPart))%FP_RotVelo(1)*FPInnerVelos(PartStatevMPFSpec(iPart))%FP_RotVelo(1) &
        +FPInnerVelos(PartStatevMPFSpec(iPart))%FP_RotVelo(2)*FPInnerVelos(PartStatevMPFSpec(iPart))%FP_RotVelo(2))
  END IF
#endif
  END DO
  IF(NewPartNum.GT.SpecNum) THEN
      DO iPart = 1, NewPartNum - SpecNum
        PDM%ParticleInside(vMPFNewPosNum(iPart)) = .false.
      END DO
  END IF
END IF

  IF (vMPF_velocityDistribution.NE.'DENSEST') THEN
    DEALLOCATE(iwa, x, fjac, fvec, vMPFPolyPoint, vMPFPolySol)
  END IF

  IF (vMPF_velocityDistribution.EQ.'OVDR') THEN 
    DEALLOCATE(vMPFOldBrownVelo)
  END IF

END SUBROUTINE SetNewVelos


FUNCTION GaussCore(bandwidth,oldpos,newpos)
!===================================================================================================================================
!
!===================================================================================================================================
! MODULES
!----------------------------------------------------------------------------------------------------------------------------------
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
REAL,INTENT(IN)          :: oldpos(3), newpos(3)      ! 
REAL,INTENT(IN)          :: bandwidth     ! 
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
REAL                     :: GaussCore  !  
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES 
!===================================================================================================================================

GaussCore = 1.0/SQRT(2.0*3.14159265359)*EXP(-((newpos(1)-oldpos(1))*(newpos(1)-oldpos(1)) &
              + (newpos(2)-oldpos(2))*(newpos(2)-oldpos(2)) &
              + (newpos(3)-oldpos(3))*(newpos(3)-oldpos(3)))/(2.0*bandwidth*bandwidth)) 

 
END FUNCTION GaussCore  


FUNCTION GaussCore4D(bandwidth,oldpos,oldvelo,newpos,newvelo)
!===================================================================================================================================
!
!===================================================================================================================================
! MODULES
!----------------------------------------------------------------------------------------------------------------------------------
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
REAL,INTENT(IN)          :: oldpos(3), newpos(3)      ! 
REAL,INTENT(IN)          :: bandwidth,oldvelo,newvelo     ! 
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
REAL                     :: GaussCore4D  !  
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES 
!===================================================================================================================================

GaussCore4D = 1.0/SQRT(2.0*3.14159265359)*EXP(-((newpos(1)-oldpos(1))*(newpos(1)-oldpos(1)) &
              + (newpos(2)-oldpos(2))*(newpos(2)-oldpos(2)) &
              + (newpos(3)-oldpos(3))*(newpos(3)-oldpos(3)) &
              + (newvelo-oldvelo)*(newvelo-oldvelo))/(2.0*bandwidth*bandwidth))


END FUNCTION GaussCore4D


#ifdef DONTCOMPILETHIS
SUBROUTINE SetNewTemp(PartIndx, Temp, iPart)                                                                !
!===================================================================================================================================
!
!===================================================================================================================================
! MODULES
  USE MOD_Particle_Vars,         ONLY : PartState, Species, PartSpecies, vMPF_oldEngSum, vMPF_oldMomSum, PartMPF
  USE MOD_Globals_Vars,          ONLY : BoltzmannConst
!----------------------------------------------------------------------------------------------------------------------------------
! IMPLICIT VARIABLE HANDLING
  IMPLICIT NONE                                                                                    !
!----------------------------------------------------------------------------------------------------------------------------------
! ARGUMENT LIST DECLARATION                                                                        !
  INTEGER,INTENT(IN)              :: PartIndx, iPart
  REAL,INTENT(IN)                 :: Temp
!----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLE DECLARATION
  REAL                            :: SumRan, RandVal(2), ran1, ran2
!===================================================================================================================================

  SumRan = 2
  DO WHILE (SumRan .GT. 1)
   CALL RANDOM_NUMBER(RandVal)
   ran1 = 2*RandVal(1) - 1
   ran2 = 2*RandVal(2) - 1
   SumRan = ran1**2 + ran2**2
  END DO
  PartState(PartIndx, 4) = PartState(PartIndx, 4) & 
              + ran1*SQRT(-2*BoltzmannConst*Temp/Species(PartSpecies(PartIndx))%MassIC*LOG(SumRan)/SumRan)
  PartState(PartIndx, 5) = PartState(PartIndx, 5) &
              + ran2*SQRT(-2*BoltzmannConst*Temp/Species(PartSpecies(PartIndx))%MassIC*LOG(SumRan)/SumRan)

  SumRan = 2
  DO WHILE (SumRan .GT. 1)
   CALL RANDOM_NUMBER(RandVal)
   ran1 = 2*RandVal(1) - 1
   ran2 = 2*RandVal(2) - 1
   SumRan = ran1**2 + ran2**2
  END DO
  PartState(PartIndx, 6) =PartState(PartIndx, 6) &
              + ran1*SQRT(-2*BoltzmannConst*Temp/Species(PartSpecies(PartIndx))%MassIC*LOG(SumRan)/SumRan)

  vMPF_oldEngSum = vMPF_oldEngSum - 0.5 * Species(PartSpecies(PartIndx))%MassIC * PartMPF(PartIndx) &
          * (PartState(PartIndx,4)**2 + PartState(PartIndx,5)**2 &
          + PartState(PartIndx,6)**2)
  vMPF_oldMomSum(1:3) = vMPF_oldMomSum(1:3) - Species(PartSpecies(PartIndx))%MassIC * PartMPF(PartIndx) &
                       * PartState(PartIndx,4:6)
  IF(vMPF_oldEngSum.lT.0) then
   print*, 'mist: ', iPart
    read*
  end if

END SUBROUTINE SetNewTemp
#endif /*DONTCOMPILETHIS*/


SUBROUTINE SetNewvMPF(FinPartNum)                                                                !
!===================================================================================================================================
!
!===================================================================================================================================
! MODULES
  USE MOD_Particle_Vars, ONLY : PartMPF, vMPF_oldMPFSum, PartStatevMPFSpec
!----------------------------------------------------------------------------------------------------------------------------------
! IMPLICIT VARIABLE HANDLING
  IMPLICIT NONE                                                                                    !
!----------------------------------------------------------------------------------------------------------------------------------
! ARGUMENT LIST DECLARATION                                                                        !
  INTEGER,INTENT(IN)              :: FinPartNum
!----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLE DECLARATION
  INTEGER                         :: iLoop
  REAL                            :: NewMPF
!===================================================================================================================================

  NewMPF = vMPF_oldMPFSum/FinPartNum
  DO iLoop = 1, FinPartNum  
    PartMPF(PartStatevMPFSpec(iLoop)) = NewMPF
  END DO

END SUBROUTINE SetNewvMPF


SUBROUTINE SetNewTemp_2(Temp, NewPartNum)                                                                !
!===================================================================================================================================
!
!===================================================================================================================================
! MODULES
  USE MOD_Particle_Vars,         ONLY : PartState, Species, PartSpecies, vMPF_oldEngSum, vMPF_oldMomSum, PartMPF, PartStatevMPFSpec
  USE MOD_Globals_Vars,          ONLY : BoltzmannConst
!----------------------------------------------------------------------------------------------------------------------------------
! IMPLICIT VARIABLE HANDLING
  IMPLICIT NONE                                                                                    !
!----------------------------------------------------------------------------------------------------------------------------------
! ARGUMENT LIST DECLARATION                                                                        !
  INTEGER,INTENT(IN)              :: NewPartNum
  REAL,INTENT(IN)                 :: Temp(3)
!----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLE DECLARATION
  REAL                            :: SumRan, RandVal(2), ran1, ran2, v2_sum, v_sum(1:3), maxwellfac(1:3), v_merge
  INTEGER                         :: iPart, distnum, SpecID, iLoop, iDir, iPart2
  REAL, ALLOCATABLE               :: PartTemp(:,:)
  REAL                      :: TempPartVelo(NewPartNum,3)
!===================================================================================================================================

  ALLOCATE(PartTemp(NewPartNum,1:3))
  v_sum(1:3) = 0.0
  v2_sum = 0.0
  SpecID = PartSpecies(PartStatevMPFSpec(1))
  iPart = 1
  DO WHILE (iPart .le. NewPartNum)  
    DO distnum = 1, 3
      CALL RANDOM_NUMBER(RandVal)
      ran1 = 2.0*RandVal(1)-1.0
      ran2 = 2.0*RandVal(2)-1.0
      SumRan= ran1**2+ran2**2
      DO WHILE ((SumRan.LE.0).OR.(SumRan.GE.1))
        CALL RANDOM_NUMBER(RandVal) 
        ran1 = 2.0*RandVal(1)-1.0
        ran2 = 2.0*RandVal(2)-1.0
        SumRan= ran1**2+ran2**2
      END DO
      PartTemp(iPart,distnum) = ran1*SQRT(-2*LOG(SumRan)/SumRan)
    END DO                    
    v_sum(1:3) = v_sum(1:3) + PartTemp(iPart,1:3)
    v2_sum = v2_sum + PartTemp(iPart,1)**2+PartTemp(iPart,2)**2+PartTemp(iPart,3)**2
    iPart = iPart + 1
  END DO
  v_sum(1:3) = v_sum(1:3) / (NewPartNum) 
  v2_sum = v2_sum / (NewPartNum) 
  maxwellfac(1:3) = SQRT(3. * BoltzmannConst * Temp(1:3)/ &              ! velocity of maximum
                 (Species(SpecID)%MassIC*v2_sum))


  DO iPart =1, NewPartNum -1
    vMPF_oldEngSum = vMPF_oldEngSum + 0.5 * Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart)) &
            * (PartState(PartStatevMPFSpec(iPart),4)**2 + PartState(PartStatevMPFSpec(iPart),5)**2 &
            + PartState(PartStatevMPFSpec(iPart),6)**2)
    vMPF_oldMomSum(1:3) = vMPF_oldMomSum(1:3) + Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart)) &
                         * PartState(PartStatevMPFSpec(iPart),4:6)   

    PartState(PartStatevMPFSpec(iPart),4:6) = PartState(PartStatevMPFSpec(iPart),4:6) &
                        + (PartTemp(iPart,1:3) - v_sum(1:3)) * maxwellfac(1:3)
    vMPF_oldEngSum = vMPF_oldEngSum - 0.5 * Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart)) &
            * (PartState(PartStatevMPFSpec(iPart),4)**2 + PartState(PartStatevMPFSpec(iPart),5)**2 &
            + PartState(PartStatevMPFSpec(iPart),6)**2)
    vMPF_oldMomSum(1:3) = vMPF_oldMomSum(1:3) - Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart)) &
                         * PartState(PartStatevMPFSpec(iPart),4:6)  
  END DO

  vMPF_oldEngSum = vMPF_oldEngSum + 0.5 * Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(NewPartNum)) &
          * (PartState(PartStatevMPFSpec(NewPartNum),4)**2 + PartState(PartStatevMPFSpec(NewPartNum),5)**2 &
          + PartState(PartStatevMPFSpec(NewPartNum),6)**2)
  vMPF_oldMomSum(1:3) = vMPF_oldMomSum(1:3) + Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(NewPartNum)) &
                         * PartState(PartStatevMPFSpec(NewPartNum),4:6)  

  PartState(PartStatevMPFSpec(NewPartNum),4:6) =vMPF_oldMomSum(1:3) &
                        / (Species(SpecID)%MassIC*PartMPF(PartStatevMPFSpec(NewPartNum)) )
  vMPF_oldEngSum = vMPF_oldEngSum - 0.5 * Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(NewPartNum)) &
          * (PartState(PartStatevMPFSpec(NewPartNum),4)**2 + PartState(PartStatevMPFSpec(NewPartNum),5)**2 &
          + PartState(PartStatevMPFSpec(NewPartNum),6)**2)

  IF (vMPF_oldEngSum.LT.0.0) THEN
    DO iPart = 1, NewPartNum  
      TempPartVelo(iPart,1:3) = PartState(PartStatevMPFSpec(iPart),4:6)
    END DO

    iLoop = 0
     DO WHILE (vMPF_oldEngSum.LT.0.0)
      CALL RANDOM_NUMBER(ran1)    
      iDir = INT(3*ran1 + 1) + 3
      iPart2 = MAXLOC(TempPartVelo(:,iDir-3),1)
      iPart = MINLOC(TempPartVelo(:,iDir-3),1)
      IF (iPart2.EQ.iPart) CYCLE      
      vMPF_oldEngSum = vMPF_oldEngSum + 0.5 * Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart2)) &
              * (PartState(PartStatevMPFSpec(iPart2),iDir)**2)
      vMPF_oldEngSum = vMPF_oldEngSum + 0.5 * Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart)) &
              * (PartState(PartStatevMPFSpec(iPart),iDir)**2)

      CALL RANDOM_NUMBER(ran1) 
      v_merge = (PartState(PartStatevMPFSpec(iPart2),iDir) - PartState(PartStatevMPFSpec(iPart), iDir))
      PartState(PartStatevMPFSpec(iPart2),iDir)=PartState(PartStatevMPFSpec(iPart),iDir) + v_merge*ran1
      PartState(PartStatevMPFSpec(iPart), iDir) =PartState(PartStatevMPFSpec(iPart),iDir) + v_merge*(1.0-ran1)

      vMPF_oldEngSum = vMPF_oldEngSum - 0.5 * Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart2)) &
              * (PartState(PartStatevMPFSpec(iPart2),iDir)**2)
      vMPF_oldEngSum = vMPF_oldEngSum - 0.5 * Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart)) &
              * (PartState(PartStatevMPFSpec(iPart),iDir)**2)
      iLoop= iLoop + 1
      TempPartVelo(iPart,iDir-3)=PartState(PartStatevMPFSpec(iPart), iDir)
      TempPartVelo(iPart2,iDir-3)=PartState(PartStatevMPFSpec(iPart2), iDir)
    END DO
    WRITE(*,*)'Loops for energy transformation needed: ', iLoop
  END IF

  DEALLOCATE(PartTemp)

END SUBROUTINE SetNewTemp_2

SUBROUTINE SetNewDistrVelo(NewPartNum, nDist, SpecNum, Csquare)                                                                !
!===================================================================================================================================
!
!===================================================================================================================================
! MODULES
  USE MOD_Particle_Vars, ONLY : PartState, Species, PartSpecies, vMPF_oldEngSum, vMPF_oldMomSum, &
                     PartMPF, PartStatevMPFSpec, vMPFOldBrownVelo, vMPFOldMPF, vMPF_oldMPFSum, vMPF_relativistic
  USE MOD_Globals
  USE MOD_Equation_Vars,          ONLY : c2
!----------------------------------------------------------------------------------------------------------------------------------
! IMPLICIT VARIABLE HANDLING
  IMPLICIT NONE                                                                                    !
!----------------------------------------------------------------------------------------------------------------------------------
! ARGUMENT LIST DECLARATION                                                                        !
  INTEGER,INTENT(IN)                 :: NewPartNum, nDist, SpecNum
  LOGICAL,INTENT(INOUT)              :: Csquare
!----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLE DECLARATION
  REAL                            :: v_min, v_max, v_width, iRan, iRan2, v_merge, ran1
  INTEGER                         :: iDir, iPart, iBar, SpecID, iLoop, iPart2
  REAL, ALLOCATABLE            :: numDist(:,:)
  REAL                      :: TempPartVelo(NewPartNum,3), Gamma, VeloSQ
!===================================================================================================================================

  SpecID = PartSpecies(PartStatevMPFSpec(1))
  ALLOCATE(numDist(3, nDist))
  DO iDir = 1, 3
    v_min = MINVAL(vMPFOldBrownVelo(:, iDir))
    v_max = MAXVAL(vMPFOldBrownVelo(:, iDir))
    v_width = (v_max - v_min)/nDist
    numDist(iDir,:) = 0
    DO iPart = 1, SpecNum
      iBar = MIN(INT((vMPFOldBrownVelo(iPart, iDir)-v_min)/v_width+1), nDist)
      numDist(iDir,iBar) = numDist(iDir,iBar) + vMPFOldMPF(iPart)
    END DO

    numDist(iDir,:) = numDist(iDir,:) / vMPF_oldMPFSum

    DO iPart =1, NewPartNum -1 
      IF (iDir.EQ.1) THEN 
        IF (vMPF_relativistic) THEN
          VeloSq = PartState(PartStatevMPFSpec(iPart),4) * PartState(PartStatevMPFSpec(iPart),4) &
           + PartState(PartStatevMPFSpec(iPart),5) * PartState(PartStatevMPFSpec(iPart),5) &
           + PartState(PartStatevMPFSpec(iPart),6) * PartState(PartStatevMPFSpec(iPart),6)
          IF (VeloSQ.GT.c2) THEN
            Csquare=.true.
            RETURN
          END IF
          Gamma = VeloSq/c2      
          Gamma = 1./SQRT(1.-Gamma)
          vMPF_oldEngSum = vMPF_oldEngSum + Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart)) &
                           * (Gamma-1.)*c2
          vMPF_oldMomSum(1:3) = vMPF_oldMomSum(1:3) + Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart)) &
                               * PartState(PartStatevMPFSpec(iPart),4:6)*Gamma  
        ELSE
          vMPF_oldEngSum = vMPF_oldEngSum + 0.5 * Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart)) &
                * (PartState(PartStatevMPFSpec(iPart),4)**2 + PartState(PartStatevMPFSpec(iPart),5)**2 &
                + PartState(PartStatevMPFSpec(iPart),6)**2)
          vMPF_oldMomSum(1:3) = vMPF_oldMomSum(1:3) + Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart)) &
                           * PartState(PartStatevMPFSpec(iPart),4:6)   
        END IF
      END IF
      
      CALL RANDOM_NUMBER(iRan)  
      iBar = INT(iRan*nDist + 1)    
      CALL RANDOM_NUMBER(iRan2)
      DO WHILE (iRan2.GE.numDist(iDir,iBar)) 
        CALL RANDOM_NUMBER(iRan)  
        iBar = INT(iRan*nDist + 1)    
        CALL RANDOM_NUMBER(iRan2)
      END DO  
      CALL RANDOM_NUMBER(iRan)
      PartState(PartStatevMPFSpec(iPart),iDir+3) = PartState(PartStatevMPFSpec(iPart),iDir+3) & 
                          + (v_min + v_width*(iBar-1) + v_width*iRan)  
    END DO
  END DO

  
  IF (vMPF_relativistic) THEN
    DO iPart=1, NewPartNum -1
      VeloSq = PartState(PartStatevMPFSpec(iPart),4) * PartState(PartStatevMPFSpec(iPart),4) &
               + PartState(PartStatevMPFSpec(iPart),5) * PartState(PartStatevMPFSpec(iPart),5) &
               + PartState(PartStatevMPFSpec(iPart),6) * PartState(PartStatevMPFSpec(iPart),6)
      IF (VeloSQ.GT.c2) THEN
        Csquare=.true.
        RETURN
      END IF
      Gamma = VeloSq/c2      
      Gamma = 1./SQRT(1.-Gamma)
      vMPF_oldEngSum = vMPF_oldEngSum - Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart)) &
                       * (Gamma-1.)*c2
      vMPF_oldMomSum(1:3) = vMPF_oldMomSum(1:3) - Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart)) &
                           * PartState(PartStatevMPFSpec(iPart),4:6)*Gamma   
    END DO

    VeloSq = PartState(PartStatevMPFSpec(NewPartNum),4) * PartState(PartStatevMPFSpec(NewPartNum),4) &
             + PartState(PartStatevMPFSpec(NewPartNum),5) * PartState(PartStatevMPFSpec(NewPartNum),5) &
             + PartState(PartStatevMPFSpec(NewPartNum),6) * PartState(PartStatevMPFSpec(NewPartNum),6)
    IF (VeloSQ.GT.c2) THEN
      Csquare=.true.
      RETURN
    END IF
    Gamma = VeloSq/c2      
    Gamma = 1./SQRT(1.-Gamma)
    vMPF_oldEngSum = vMPF_oldEngSum + Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(NewPartNum)) &
                     * (Gamma-1.)*c2
    vMPF_oldMomSum(1:3) = vMPF_oldMomSum(1:3) + Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(NewPartNum)) &
                               * PartState(PartStatevMPFSpec(NewPartNum),4:6)*Gamma  
    PartState(PartStatevMPFSpec(NewPartNum),4:6) = &
             RelVeloFromMom(vMPF_oldMomSum(1:3), SpecID, PartMPF(PartStatevMPFSpec(NewPartNum)))
    VeloSq = PartState(PartStatevMPFSpec(NewPartNum),4) * PartState(PartStatevMPFSpec(NewPartNum),4) &
             + PartState(PartStatevMPFSpec(NewPartNum),5) * PartState(PartStatevMPFSpec(NewPartNum),5) &
             + PartState(PartStatevMPFSpec(NewPartNum),6) * PartState(PartStatevMPFSpec(NewPartNum),6)
    IF (VeloSQ.GT.c2) THEN
      Csquare=.true.
      RETURN
    END IF
    Gamma = VeloSq/c2      
    Gamma = 1./SQRT(1.-Gamma)
    vMPF_oldEngSum = vMPF_oldEngSum - Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(NewPartNum)) &
                       * (Gamma-1.)*c2
    vMPF_oldMomSum(1:3) = vMPF_oldMomSum(1:3) - Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(NewPartNum)) &
                           * PartState(PartStatevMPFSpec(NewPartNum),4:6)*Gamma  
  ELSE
    DO iPart=1, NewPartNum -1 
      vMPF_oldEngSum = vMPF_oldEngSum - 0.5 * Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart)) &
              * (PartState(PartStatevMPFSpec(iPart),4)**2 + PartState(PartStatevMPFSpec(iPart),5)**2 &
              + PartState(PartStatevMPFSpec(iPart),6)**2)
      vMPF_oldMomSum(1:3) = vMPF_oldMomSum(1:3) - Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart)) &
                           * PartState(PartStatevMPFSpec(iPart),4:6)      
    END DO
    vMPF_oldEngSum = vMPF_oldEngSum + 0.5 * Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(NewPartNum)) &
            * (PartState(PartStatevMPFSpec(NewPartNum),4)**2 + PartState(PartStatevMPFSpec(NewPartNum),5)**2 &
            + PartState(PartStatevMPFSpec(NewPartNum),6)**2)
    vMPF_oldMomSum(1:3) = vMPF_oldMomSum(1:3) + Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(NewPartNum)) &
                           * PartState(PartStatevMPFSpec(NewPartNum),4:6)     
    PartState(PartStatevMPFSpec(NewPartNum),4:6) =vMPF_oldMomSum(1:3) & 
                          / (Species(SpecID)%MassIC*PartMPF(PartStatevMPFSpec(NewPartNum)) )
    vMPF_oldEngSum = vMPF_oldEngSum - 0.5 * Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(NewPartNum)) &
            * (PartState(PartStatevMPFSpec(NewPartNum),4)**2 + PartState(PartStatevMPFSpec(NewPartNum),5)**2 &
            + PartState(PartStatevMPFSpec(NewPartNum),6)**2)
  END IF


  IF (vMPF_oldEngSum.LT.0.0) THEN
    DO iPart = 1, NewPartNum  
      TempPartVelo(iPart,1:3) = PartState(PartStatevMPFSpec(iPart),4:6)  
    END DO  

!!!!!!!!!!!!!!!!!!
! Hier mal noch eine grundsätzliche Idee, wie man einzelne Ausreiser in der Geschwindigkeitsverteilung wegbekommen
! kann, ohne zuuu viel innerhalb der Verteilungsfunktion zu verschmieren.
!!!!!!!!!!!!!!!!!

!DO iDir = 4, 6
!    iPart2 = MAXLOC(TempPartVeloMean(1:NewPartNum,iDir-3),1)
!    iPart = MINLOC(TempPartVeloMean(1:NewPartNum,iDir-3),1)
!    IF (iPart2.EQ.iPart) CYCLE      
!    IF (iPart2.EQ.NewPartNum) THEN
!      v_merge = PartState(PartStatevMPFSpec(MAXLOC(TempPartVeloMean(1:NewPartNum-1,iDir-3),1)),iDir) &
!                - PartState(PartStatevMPFSpec(NewPartNum),iDir)
!      vMPF_oldEngSum = vMPF_oldEngSum + 0.5 * Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(NewPartNum)) &
!              * (PartState(PartStatevMPFSpec(NewPartNum),iDir)**2)
!      PartState(PartStatevMPFSpec(NewPartNum), iDir) = PartState(PartStatevMPFSpec(NewPartNum), iDir) + v_merge
!      vMPF_oldEngSum = vMPF_oldEngSum - 0.5 * Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(NewPartNum)) &
!        * (PartState(PartStatevMPFSpec(NewPartNum),iDir)**2)
!      TempPartVeloMean(NewPartNum,iDir-3)=PartState(PartStatevMPFSpec(NewPartNum), iDir)
!      v_merge = v_merge / (NewPartNum -1)
!      DO iPart = 1, NewPartNum - 1 
!        vMPF_oldEngSum = vMPF_oldEngSum + 0.5 * Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart)) &
!                * (PartState(PartStatevMPFSpec(iPart),iDir)**2)
!        PartState(PartStatevMPFSpec(iPart), iDir) = PartState(PartStatevMPFSpec(iPart), iDir) - v_merge
!        vMPF_oldEngSum = vMPF_oldEngSum - 0.5 * Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart)) &
!          * (PartState(PartStatevMPFSpec(iPart),iDir)**2)
!        TempPartVeloMean(iPart,iDir-3)=PartState(PartStatevMPFSpec(iPart), iDir)
!      END DO
!    ELSE IF(iPart.EQ.NewPartNum) THEN
!      v_merge = PartState(PartStatevMPFSpec(MINLOC(TempPartVeloMean(1:NewPartNum-1,iDir-3),1)),iDir) &
!                 - PartState(PartStatevMPFSpec(NewPartNum),iDir)
!      vMPF_oldEngSum = vMPF_oldEngSum + 0.5 * Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(NewPartNum)) &
!              * (PartState(PartStatevMPFSpec(NewPartNum),iDir)**2)
!      PartState(PartStatevMPFSpec(NewPartNum), iDir) = PartState(PartStatevMPFSpec(NewPartNum), iDir) + v_merge
!      vMPF_oldEngSum = vMPF_oldEngSum - 0.5 * Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(NewPartNum)) &
!        * (PartState(PartStatevMPFSpec(NewPartNum),iDir)**2)
!      TempPartVeloMean(NewPartNum,iDir-3)=PartState(PartStatevMPFSpec(NewPartNum), iDir)
!      v_merge = v_merge / (NewPartNum -1)
!      DO iPart = 1, NewPartNum - 1 
!        vMPF_oldEngSum = vMPF_oldEngSum + 0.5 * Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart)) &
!                * (PartState(PartStatevMPFSpec(iPart),iDir)**2)
!        PartState(PartStatevMPFSpec(iPart), iDir) = PartState(PartStatevMPFSpec(iPart), iDir) - v_merge
!        vMPF_oldEngSum = vMPF_oldEngSum - 0.5 * Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart)) &
!          * (PartState(PartStatevMPFSpec(iPart),iDir)**2)
!        TempPartVeloMean(iPart,iDir-3)=PartState(PartStatevMPFSpec(iPart), iDir)
!      END DO
!    END IF
!  END DO

!!!!!!!!!!!!!!!!!!!
! Und hier noch ein Ansatz, wie man auch beim Glätten der Verteilungsfunktion dennoch die ursprüngliche
! Verteilungsfunktion beachtet
!!!!!!!!!!!!!!!!!!
!     DO iDir = 1, 3
!      v_min = MINVAL(TempPartVeloMean(:,iDir))
!      v_max = MAXVAL(TempPartVeloMean(:,iDir))
!      v_width = (v_max - v_min)/nBar
!      partinbar(:,iDir) = 0
!      partindxbar(:,iDir,:) = 0
!      velosbar(:,iDir,:) = 0.0
!      DO iPart = 1, NewPartNum
!        iBar = MIN(INT((TempPartVeloMean(iPart, iDir)-v_min)/v_width+1), nBar)
!        partinbar(iBar,iDir) = partinbar(iBar,iDir) + 1
!        partindxbar(iBar,iDir,partinbar(iBar,iDir)) = iPart
!        velosbar(iBar,iDir,partinbar(iBar,iDir)) = TempPartVeloMean(iPart, iDir)
!      END DO
!    END DO
!    
!    iLoop = 0  
!    IF (iLoop.LT.1000) THEN
!      CALL RANDOM_NUMBER(ran1)    
!      iDir = INT(3*ran1 + 1) + 3
!      CALL RANDOM_NUMBER(ran1) 
!      iBar = INT(nBar*ran1 + 1)
!      IF (partinbar(iBar,iDir-3).LT.2) CYCLE
!      iPart2 = MAXLOC(velosbar(iBar,iDir-3, 1:partinbar(iBar,iDir-3)),1)
!      iPart = MINLOC(velosbar(iBar,iDir-3, 1:partinbar(iBar,iDir-3)),1)
!      IF (iPart2.EQ.iPart) CYCLE      
!      vMPF_oldEngSum = vMPF_oldEngSum + 0.5 * Species(SpecID)%MassIC &
!               * PartMPF(PartStatevMPFSpec(partindxbar(iBar,iDir-3,iPart2))) &
!              * (PartState(PartStatevMPFSpec(partindxbar(iBar,iDir-3,iPart2)),iDir)**2)
!      vMPF_oldEngSum = vMPF_oldEngSum + 0.5 * Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(partindxbar(iBar,iDir-3,iPart))) &
!              * (PartState(PartStatevMPFSpec(partindxbar(iBar,iDir-3,iPart)),iDir)**2)
!      CALL RANDOM_NUMBER(ran1) 
!      v_merge = (PartState(PartStatevMPFSpec(partindxbar(iBar,iDir-3,iPart2)),iDir) &
!                - PartState(PartStatevMPFSpec(partindxbar(iBar,iDir-3,iPart)), iDir))
!      PartState(PartStatevMPFSpec(partindxbar(iBar,iDir-3,iPart2)),iDir)= &
!                PartState(PartStatevMPFSpec(partindxbar(iBar,iDir-3,iPart)),iDir) + v_merge*ran1
!      PartState(PartStatevMPFSpec(partindxbar(iBar,iDir-3,iPart)),iDir) = &
!                PartState(PartStatevMPFSpec(partindxbar(iBar,iDir-3,iPart)),iDir) + v_merge*(1.0-ran1)
!      vMPF_oldEngSum = vMPF_oldEngSum - 0.5 * Species(SpecID)%MassIC &
!              * PartMPF(PartStatevMPFSpec(partindxbar(iBar,iDir-3,iPart2))) &
!              * (PartState(PartStatevMPFSpec(partindxbar(iBar,iDir-3,iPart2)),iDir)**2)
!      vMPF_oldEngSum = vMPF_oldEngSum - 0.5 * Species(SpecID)%MassIC &
!              * PartMPF(PartStatevMPFSpec(partindxbar(iBar,iDir-3,iPart))) &
!              * (PartState(PartStatevMPFSpec(partindxbar(iBar,iDir-3,iPart)),iDir)**2)
!      iLoop= iLoop + 1
!      velosbar(iBar,iDir-3, iPart) = PartState(PartStatevMPFSpec(partindxbar(iBar,iDir-3,iPart)),iDir)
!      velosbar(iBar,iDir-3, iPart2) = PartState(PartStatevMPFSpec(partindxbar(iBar,iDir-3,iPart2)),iDir)
!      TempPartVeloMean(partindxbar(iBar,iDir-3,iPart),iDir-3) = PartState(PartStatevMPFSpec(partindxbar(iBar,iDir-3,iPart)),iDir)
!      TempPartVeloMean(partindxbar(iBar,iDir-3,iPart2),iDir-3)= PartState(PartStatevMPFSpec(partindxbar(iBar,iDir-3,iPart2)),iDir)
!    ELSE
!!!!!!!!!!!!!!!

    iLoop = 0
    DO WHILE (vMPF_oldEngSum.LT.0.0)
      CALL RANDOM_NUMBER(ran1)    
      iDir = INT(3*ran1 + 1) + 3
      iPart2 = MAXLOC(TempPartVelo(:,iDir-3),1)
      iPart = MINLOC(TempPartVelo(:,iDir-3),1)
      IF (iPart2.EQ.iPart) CYCLE      
      IF (vMPF_relativistic) THEN 
        VeloSq = PartState(PartStatevMPFSpec(iPart2),4) * PartState(PartStatevMPFSpec(iPart2),4) &
             + PartState(PartStatevMPFSpec(iPart2),5) * PartState(PartStatevMPFSpec(iPart2),5) &
             + PartState(PartStatevMPFSpec(iPart2),6) * PartState(PartStatevMPFSpec(iPart2),6)    
        Gamma = VeloSq/c2      
        Gamma = 1./SQRT(1.-Gamma)
        vMPF_oldEngSum = vMPF_oldEngSum + Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart2)) &
                       * (Gamma-1.)*c2
        vMPF_oldMomSum(1:3) = vMPF_oldMomSum(1:3)  + Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart2)) &
                           * PartState(PartStatevMPFSpec(iPart2),4:6)*Gamma  
        VeloSq = PartState(PartStatevMPFSpec(iPart),4) * PartState(PartStatevMPFSpec(iPart),4) &
             + PartState(PartStatevMPFSpec(iPart),5) * PartState(PartStatevMPFSpec(iPart),5) &
             + PartState(PartStatevMPFSpec(iPart),6) * PartState(PartStatevMPFSpec(iPart),6)    
        Gamma = VeloSq/c2      
        Gamma = 1./SQRT(1.-Gamma)
        vMPF_oldEngSum = vMPF_oldEngSum + Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart)) &
                       * (Gamma-1.)*c2
        vMPF_oldMomSum(1:3) = vMPF_oldMomSum(1:3)  + Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart)) &
                           * PartState(PartStatevMPFSpec(iPart),4:6)*Gamma  
        CALL RANDOM_NUMBER(ran1) 
        v_merge = (PartState(PartStatevMPFSpec(iPart2),iDir) - PartState(PartStatevMPFSpec(iPart), iDir))
        PartState(PartStatevMPFSpec(iPart2),iDir)=PartState(PartStatevMPFSpec(iPart),iDir) + v_merge*ran1
        !hier mal nur für eine impulsrichtung einbauen!!    
        VeloSq = PartState(PartStatevMPFSpec(iPart2),4) * PartState(PartStatevMPFSpec(iPart2),4) &
             + PartState(PartStatevMPFSpec(iPart2),5) * PartState(PartStatevMPFSpec(iPart2),5) &
             + PartState(PartStatevMPFSpec(iPart2),6) * PartState(PartStatevMPFSpec(iPart2),6)    
        Gamma = VeloSq/c2      
        Gamma = 1./SQRT(1.-Gamma)
        vMPF_oldEngSum = vMPF_oldEngSum - Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart2)) &
                       * (Gamma-1.)*c2
        vMPF_oldMomSum(1:3) = vMPF_oldMomSum(1:3)  - Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart2)) &
                           * PartState(PartStatevMPFSpec(iPart2),4:6)*Gamma 
        PartState(PartStatevMPFSpec(iPart),4:6) = RelVeloFromMom(vMPF_oldMomSum(1:3), SpecID, PartMPF(PartStatevMPFSpec(iPart)))
        VeloSq = PartState(PartStatevMPFSpec(iPart),4) * PartState(PartStatevMPFSpec(iPart),4) &
             + PartState(PartStatevMPFSpec(iPart),5) * PartState(PartStatevMPFSpec(iPart),5) &
             + PartState(PartStatevMPFSpec(iPart),6) * PartState(PartStatevMPFSpec(iPart),6)    
        Gamma = VeloSq/c2      
        Gamma = 1./SQRT(1.-Gamma)
        vMPF_oldEngSum = vMPF_oldEngSum - Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart)) &
                       * (Gamma-1.)*c2
        vMPF_oldMomSum(1:3) = vMPF_oldMomSum(1:3)  - Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart)) &
                           * PartState(PartStatevMPFSpec(iPart),4:6)*Gamma
        iLoop= iLoop + 1
        TempPartVelo(iPart,iDir-3)=PartState(PartStatevMPFSpec(iPart), iDir)
        TempPartVelo(iPart2,iDir-3)=PartState(PartStatevMPFSpec(iPart2), iDir)
        IF(iLoop.GT.50000) THEN
            Csquare=.true.
            RETURN       
        END IF
      ELSE  
        vMPF_oldEngSum = vMPF_oldEngSum + 0.5 * Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart2)) &
                * (PartState(PartStatevMPFSpec(iPart2),iDir)**2)
        vMPF_oldEngSum = vMPF_oldEngSum + 0.5 * Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart)) &
                * (PartState(PartStatevMPFSpec(iPart),iDir)**2)

        CALL RANDOM_NUMBER(ran1) 
        v_merge = (PartState(PartStatevMPFSpec(iPart2),iDir) - PartState(PartStatevMPFSpec(iPart), iDir))
        PartState(PartStatevMPFSpec(iPart2),iDir)=PartState(PartStatevMPFSpec(iPart),iDir) + v_merge*ran1
        PartState(PartStatevMPFSpec(iPart), iDir) =PartState(PartStatevMPFSpec(iPart),iDir) + v_merge*(1.0-ran1)

        vMPF_oldEngSum = vMPF_oldEngSum - 0.5 * Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart2)) &
                * (PartState(PartStatevMPFSpec(iPart2),iDir)**2)
        vMPF_oldEngSum = vMPF_oldEngSum - 0.5 * Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart)) &
                * (PartState(PartStatevMPFSpec(iPart),iDir)**2)
        iLoop= iLoop + 1
        TempPartVelo(iPart,iDir-3)=PartState(PartStatevMPFSpec(iPart), iDir)
        TempPartVelo(iPart2,iDir-3)=PartState(PartStatevMPFSpec(iPart2), iDir)
      END IF
    END DO
    SWRITE(*,*)'Loops for energy transformation needed: ', iLoop
  END IF

  DO iPart = 1, NewPartNum 
      VeloSQ = PartState(PartStatevMPFSpec(iPart),4)*PartState(PartStatevMPFSpec(iPart),4) &
            + PartState(PartStatevMPFSpec(iPart),5) * PartState(PartStatevMPFSpec(iPart),5) &
            + PartState(PartStatevMPFSpec(iPart),6) * PartState(PartStatevMPFSpec(iPart),6)           
    IF (VeloSQ.GT.c2) THEN
      Csquare=.true.
      EXIT
    END IF
  END DO

END SUBROUTINE SetNewDistrVelo   


SUBROUTINE SetNewDistrVeloDensEst(NewPartNum, SpecNum,Csquare)                                                                  !
!===================================================================================================================================
!
!===================================================================================================================================
! MODULES
  USE MOD_Particle_Vars, ONLY : PartState, Species, PartSpecies, vMPF_oldEngSum, vMPF_oldMomSum, &
                     PartMPF, PartStatevMPFSpec,  PartStateMap &
                    , vMPF_NewPosRefElem, vMPFOldVelo, vMPF_relativistic
  USE MOD_Equation_Vars,          ONLY : c2
  USE MOD_Globals
!----------------------------------------------------------------------------------------------------------------------------------
! IMPLICIT VARIABLE HANDLING
  IMPLICIT NONE                                                                                    !
!----------------------------------------------------------------------------------------------------------------------------------
! ARGUMENT LIST DECLARATION                                                                        !
  INTEGER,INTENT(IN)              :: NewPartNum, SpecNum
  LOGICAL,INTENT(INOUT)              :: Csquare
!----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLE DECLARATION
  REAL                            :: v_min, v_max, iRan, iRan2, v_merge, ran1
  INTEGER                         :: iDir, iPart, SpecID, iLoop, iPart2, iLoop2, numloop
  REAL                            :: TempPartVelo(NewPartNum,3),MaxProb, MaxProbtemp, NormVeloOld(SpecNum, 1:3)
  REAL                            :: bandwidth, ProbPos, VeloSQ, Gamma
!===================================================================================================================================
bandwidth= 0.03 !0.03
SpecID = PartSpecies(PartStatevMPFSpec(1))
  
DO iDir = 1, 3
  v_min = MINVAL(vMPFOldVelo(iDir, :))
  v_max = MAXVAL(vMPFOldVelo(iDir, :))
  NormVeloOld(1:SpecNum,iDir) = 2.0*(vMPFOldVelo(iDir,1:SpecNum)-v_min)/(v_max-v_min)-1.0

  MaxProb=0.0
  DO iLoop = 1, SpecNum  
    MaxProbtemp = 0.0
    DO iLoop2 = 1, SpecNum
      MaxProbtemp = MaxProbtemp + GaussCore4D(bandwidth, PartStateMap(iLoop2,1:3), NormVeloOld(iLoop2,iDir) &
              , PartStateMap(iLoop,1:3), NormVeloOld(iLoop,iDir))
    END DO
    IF (MaxProbtemp.GT.MaxProb) MaxProb = MaxProbTemp
  END DO
  MaxProb = MaxProb/(bandwidth*SpecNum)
  DO iPart =1, NewPartNum -1

    ProbPos = 0.0
    CALL RANDOM_NUMBER(iRan)  
    iRan = iRan * 2.0 - 1.0
    DO iLoop2 = 1, SpecNum
      ProbPos = ProbPos + GaussCore4D(bandwidth, PartStateMap(iLoop2,1:3),  NormVeloOld(iLoop2,iDir), &
                vMPF_NewPosRefElem(iPart, 1:3),iRan)
    END DO
    ProbPos = ProbPos/(MaxProb*bandwidth*SpecNum)
    CALL RANDOM_NUMBER(iRan2)
    numloop = 0
    DO WHILE (iRan2.GE.ProbPos)
      ProbPos = 0.0
      CALL RANDOM_NUMBER(iRan)  
      iRan = iRan * 2.0 - 1.0
      DO iLoop2 = 1, SpecNum
            ProbPos = ProbPos + GaussCore4D(bandwidth, PartStateMap(iLoop2,1:3),  NormVeloOld(iLoop2,iDir), &
              vMPF_NewPosRefElem(iPart, 1:3),iRan)
      END DO
      ProbPos = ProbPos/(MaxProb*bandwidth*SpecNum)
      CALL RANDOM_NUMBER(iRan2)
      numloop = numloop + 1
      IF(numloop.GT.200000) THEN
          Csquare=.true.
          RETURN       
      END IF
    END DO  
    PartState(PartStatevMPFSpec(iPart),iDir+3) = 0.5*(iRan+1.0)*(v_max-v_min)+v_min
  END DO
END DO

IF (vMPF_relativistic) THEN
  DO iPart=1, NewPartNum -1
    VeloSq = PartState(PartStatevMPFSpec(iPart),4) * PartState(PartStatevMPFSpec(iPart),4) &
             + PartState(PartStatevMPFSpec(iPart),5) * PartState(PartStatevMPFSpec(iPart),5) &
             + PartState(PartStatevMPFSpec(iPart),6) * PartState(PartStatevMPFSpec(iPart),6)
    IF (VeloSQ.GT.c2) THEN
      Csquare=.true.
      RETURN
    END IF
    Gamma = VeloSq/c2      
    Gamma = 1./SQRT(1.-Gamma)
    vMPF_oldEngSum = vMPF_oldEngSum - Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart)) &
                     * (Gamma-1.)*c2
    vMPF_oldMomSum(1:3) = vMPF_oldMomSum(1:3) - Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart)) &
                         * PartState(PartStatevMPFSpec(iPart),4:6)*Gamma  
  END DO
  PartState(PartStatevMPFSpec(NewPartNum),4:6) = RelVeloFromMom(vMPF_oldMomSum(1:3), SpecID, PartMPF(PartStatevMPFSpec(NewPartNum)))
  VeloSq = PartState(PartStatevMPFSpec(NewPartNum),4) * PartState(PartStatevMPFSpec(NewPartNum),4) &
           + PartState(PartStatevMPFSpec(NewPartNum),5) * PartState(PartStatevMPFSpec(NewPartNum),5) &
           + PartState(PartStatevMPFSpec(NewPartNum),6) * PartState(PartStatevMPFSpec(NewPartNum),6)
  IF (VeloSQ.GT.c2) THEN
    Csquare=.true.
    RETURN
  END IF
  Gamma = VeloSq/c2      
  Gamma = 1./SQRT(1.-Gamma)
  vMPF_oldEngSum = vMPF_oldEngSum - Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(NewPartNum)) &
                     * (Gamma-1.)*c2
  vMPF_oldMomSum(1:3) = vMPF_oldMomSum(1:3) - Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(NewPartNum)) &
                         * PartState(PartStatevMPFSpec(NewPartNum),4:6)*Gamma  
ELSE
  DO iPart=1, NewPartNum -1
    vMPF_oldEngSum = vMPF_oldEngSum - 0.5 * Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart)) &
            * (PartState(PartStatevMPFSpec(iPart),4)**2 + PartState(PartStatevMPFSpec(iPart),5)**2 &
            + PartState(PartStatevMPFSpec(iPart),6)**2)
    vMPF_oldMomSum(1:3) = vMPF_oldMomSum(1:3) - Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart)) &
                         * PartState(PartStatevMPFSpec(iPart),4:6)    
  END DO
  PartState(PartStatevMPFSpec(NewPartNum),4:6) =vMPF_oldMomSum(1:3) &
                        / (Species(SpecID)%MassIC*PartMPF(PartStatevMPFSpec(NewPartNum)) )
  vMPF_oldEngSum = vMPF_oldEngSum - 0.5 * Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(NewPartNum)) &
          * (PartState(PartStatevMPFSpec(NewPartNum),4)**2 + PartState(PartStatevMPFSpec(NewPartNum),5)**2 &
          + PartState(PartStatevMPFSpec(NewPartNum),6)**2)
END IF

IF (vMPF_oldEngSum.LT.0.0) THEN
  DO iPart = 1, NewPartNum  
    TempPartVelo(iPart,1:3) = PartState(PartStatevMPFSpec(iPart),4:6)
  END DO

  iLoop = 0 
  numloop = 0
   DO WHILE (vMPF_oldEngSum.LT.0.0)
    CALL RANDOM_NUMBER(ran1)    
    iDir = INT(3*ran1 + 1) + 3
    iPart2 = MAXLOC(TempPartVelo(:,iDir-3),1)
    iPart = MINLOC(TempPartVelo(:,iDir-3),1)
    IF (iPart2.EQ.iPart) CYCLE
   IF (vMPF_relativistic) THEN 
      VeloSq = PartState(PartStatevMPFSpec(iPart2),4) * PartState(PartStatevMPFSpec(iPart2),4) &
           + PartState(PartStatevMPFSpec(iPart2),5) * PartState(PartStatevMPFSpec(iPart2),5) &
           + PartState(PartStatevMPFSpec(iPart2),6) * PartState(PartStatevMPFSpec(iPart2),6)    
      Gamma = VeloSq/c2      
      Gamma = 1./SQRT(1.-Gamma)
      vMPF_oldEngSum = vMPF_oldEngSum + Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart2)) &
                     * (Gamma-1.)*c2
      vMPF_oldMomSum(1:3) = vMPF_oldMomSum(1:3)  + Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart2)) &
                         * PartState(PartStatevMPFSpec(iPart2),4:6)*Gamma  
      VeloSq = PartState(PartStatevMPFSpec(iPart),4) * PartState(PartStatevMPFSpec(iPart),4) &
           + PartState(PartStatevMPFSpec(iPart),5) * PartState(PartStatevMPFSpec(iPart),5) &
           + PartState(PartStatevMPFSpec(iPart),6) * PartState(PartStatevMPFSpec(iPart),6)    
      Gamma = VeloSq/c2      
      Gamma = 1./SQRT(1.-Gamma)
      vMPF_oldEngSum = vMPF_oldEngSum + Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart)) &
                     * (Gamma-1.)*c2
      vMPF_oldMomSum(1:3) = vMPF_oldMomSum(1:3)  + Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart)) &
                         * PartState(PartStatevMPFSpec(iPart),4:6)*Gamma  
      CALL RANDOM_NUMBER(ran1) 
      v_merge = (PartState(PartStatevMPFSpec(iPart2),iDir) - PartState(PartStatevMPFSpec(iPart), iDir))
      PartState(PartStatevMPFSpec(iPart2),iDir)=PartState(PartStatevMPFSpec(iPart),iDir) + v_merge*ran1
      !hier mal nur für eine impulsrichtung einbauen!!    
      VeloSq = PartState(PartStatevMPFSpec(iPart2),4) * PartState(PartStatevMPFSpec(iPart2),4) &
           + PartState(PartStatevMPFSpec(iPart2),5) * PartState(PartStatevMPFSpec(iPart2),5) &
           + PartState(PartStatevMPFSpec(iPart2),6) * PartState(PartStatevMPFSpec(iPart2),6)    
      Gamma = VeloSq/c2      
      Gamma = 1./SQRT(1.-Gamma)
      vMPF_oldEngSum = vMPF_oldEngSum - Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart2)) &
                     * (Gamma-1.)*c2
      vMPF_oldMomSum(1:3) = vMPF_oldMomSum(1:3)  - Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart2)) &
                         * PartState(PartStatevMPFSpec(iPart2),4:6)*Gamma 
      PartState(PartStatevMPFSpec(iPart),4:6) = RelVeloFromMom(vMPF_oldMomSum(1:3), SpecID, PartMPF(PartStatevMPFSpec(iPart)))
      VeloSq = PartState(PartStatevMPFSpec(iPart),4) * PartState(PartStatevMPFSpec(iPart),4) &
           + PartState(PartStatevMPFSpec(iPart),5) * PartState(PartStatevMPFSpec(iPart),5) &
           + PartState(PartStatevMPFSpec(iPart),6) * PartState(PartStatevMPFSpec(iPart),6)    
      Gamma = VeloSq/c2      
      Gamma = 1./SQRT(1.-Gamma)
      vMPF_oldEngSum = vMPF_oldEngSum - Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart)) &
                     * (Gamma-1.)*c2
      vMPF_oldMomSum(1:3) = vMPF_oldMomSum(1:3)  - Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart)) &
                         * PartState(PartStatevMPFSpec(iPart),4:6)*Gamma
      iLoop= iLoop + 1
      TempPartVelo(iPart,iDir-3)=PartState(PartStatevMPFSpec(iPart), iDir)
      TempPartVelo(iPart2,iDir-3)=PartState(PartStatevMPFSpec(iPart2), iDir)
      IF(iLoop.GT.50000) THEN
          Csquare=.true.
          RETURN       
      END IF
    ELSE      
      vMPF_oldEngSum = vMPF_oldEngSum + 0.5 * Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart2)) &
              * (PartState(PartStatevMPFSpec(iPart2),iDir)**2)
      vMPF_oldEngSum = vMPF_oldEngSum + 0.5 * Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart)) &
              * (PartState(PartStatevMPFSpec(iPart),iDir)**2)

      CALL RANDOM_NUMBER(ran1) 
      v_merge = (PartState(PartStatevMPFSpec(iPart2),iDir) - PartState(PartStatevMPFSpec(iPart), iDir))
      PartState(PartStatevMPFSpec(iPart2),iDir)=PartState(PartStatevMPFSpec(iPart),iDir) + v_merge*ran1
      PartState(PartStatevMPFSpec(iPart), iDir) =PartState(PartStatevMPFSpec(iPart),iDir) + v_merge*(1.0-ran1)

      vMPF_oldEngSum = vMPF_oldEngSum - 0.5 * Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart2)) &
              * (PartState(PartStatevMPFSpec(iPart2),iDir)**2)
      vMPF_oldEngSum = vMPF_oldEngSum - 0.5 * Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart)) &
              * (PartState(PartStatevMPFSpec(iPart),iDir)**2)
      iLoop= iLoop + 1
      TempPartVelo(iPart,iDir-3)=PartState(PartStatevMPFSpec(iPart), iDir)
      TempPartVelo(iPart2,iDir-3)=PartState(PartStatevMPFSpec(iPart2), iDir)
      IF(iLoop.GT.200000) THEN
        Csquare=.true.
        RETURN       
      END IF
    END IF
  END DO
  SWRITE(*,*)'Loops for energy transformation needed: ', iLoop
END IF

DO iPart = 1, NewPartNum 
    VeloSQ = PartState(PartStatevMPFSpec(iPart),4)*PartState(PartStatevMPFSpec(iPart),4) &
          + PartState(PartStatevMPFSpec(iPart),5) * PartState(PartStatevMPFSpec(iPart),5) &
          + PartState(PartStatevMPFSpec(iPart),6) * PartState(PartStatevMPFSpec(iPart),6)           
  IF (VeloSQ.GT.c2) THEN
    Csquare=.true.
    EXIT
  END IF 
END DO

END SUBROUTINE SetNewDistrVeloDensEst

FUNCTION RelVeloFromMom(RelMom, SpecID, MPF)
!===================================================================================================================================
! calculates relativistic velocities from relativistic momentum
!===================================================================================================================================
! MODULES
  USE MOD_Equation_Vars,          ONLY : c2
  USE MOD_Particle_Vars,          ONLY : Species
!----------------------------------------------------------------------------------------------------------------------------------
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
REAL,INTENT(IN)          :: RelMom(3),MPF      ! 
INTEGER, INTENT(IN)      :: SpecID
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
REAL                     :: RelVeloFromMom(3)  !  
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES 
REAL                    :: MappedMom(3)
REAL                    :: Omega
!===================================================================================================================================
MappedMom(1) = c2*Species(SpecID)%MassIC*Species(SpecID)%MassIC*MPF*MPF/(RelMom(1)*RelMom(1))
MappedMom(2) = c2*Species(SpecID)%MassIC*Species(SpecID)%MassIC*MPF*MPF/(RelMom(2)*RelMom(2))
MappedMom(3) = c2*Species(SpecID)%MassIC*Species(SpecID)%MassIC*MPF*MPF/(RelMom(3)*RelMom(3))
Omega = (1.0-1.0/(1.0+MappedMom(3)))/((1.0+MappedMom(2))-1.0/(1.0+MappedMom(3))) &
      + (1.0-1.0/(1.0+MappedMom(2)))/((1.0+MappedMom(3))-1.0/(1.0+MappedMom(2))) 

RelVeloFromMom(1) = c2*(1.0 - Omega)/(1.0 + MappedMom(1) - Omega)

RelVeloFromMom(2) = (c2 - RelVeloFromMom(1))*(1.0 - 1.0/(1.0+MappedMom(3))) &
                    / (1 + MappedMom(2) - 1.0/(1.0+MappedMom(3)) )
RelVeloFromMom(3) = (c2 - RelVeloFromMom(1) - RelVeloFromMom(2))/(1.0 + MappedMom(3))

RelVeloFromMom(1) = SIGN(SQRT(RelVeloFromMom(1)),RelMom(1))
RelVeloFromMom(2) = SIGN(SQRT(RelVeloFromMom(2)),RelMom(2))
RelVeloFromMom(3) = SIGN(SQRT(RelVeloFromMom(3)),RelMom(3))

END FUNCTION RelVeloFromMom 


REAL FUNCTION CalcRelaBeta(energy,randvecin, mpf, SpecID, DeltaE, OldMomentum)
!===================================================================================================================================
! calculates relativistic beta for energy conservation
!===================================================================================================================================
! MODULES
  USE MOD_Globals
  USE MOD_Equation_Vars,          ONLY : c2
  USE MOD_Particle_Vars,          ONLY : Species
!--------------------------------------------------------------------------------------------------!
! IMPLICIT VARIABLE HANDLING
   IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
  REAL,INTENT(IN)                    :: energy, mpf, DeltaE
  REAL,INTENT(IN)                    ::  OldMomentum(3), randvecin(3)
  INTEGER, INTENT(IN)               :: SpecID
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES                                                                       
  REAL                    :: LowerVal, UpperVal, MiddleVal, MaxPosiVal, ZeroVal1, ZeroVal2    
  REAl                    :: eps_prec=1.0e-29   ! precision of zero point search
  REAL                    :: resu, OldMomentumMap(3),randvec(3)
  REAL                    :: omegay, omegaz, omegayn, omegazn
  REAL                    :: vxp2, vyp2, vzp2, vxn2, vyn2, vzn2
!===================================================================================================================================
  resu = (energy+DeltaE) /(mpf*c2*Species(SpecID)%MassIC) + 2.0
  OldMomentumMap(1:3) = OldMomentum(1:3)/(mpf*Species(SpecID)%MassIC)
  randvec(1:3) = randvecin(1:3)/(mpf*Species(SpecID)%MassIC)
  LowerVal  = 0.0 !SQRT(0.5*DeltaE*(mpf*Species(SpecID)%MassIC))
  UpperVal  = SQRT(12.0*DeltaE*(mpf*Species(SpecID)%MassIC))
  MaxPosiVal = LOG(HUGE(MaxPosiVal))  ! maximum value possible in system

  omegay = (1.0-1.0/(1.0+c2/(OldMomentumMap(3)/2.0+LowerVal*randvec(3))**2)) &
              /(1.0+c2/(OldMomentumMap(2)/2.0+LowerVal*randvec(2))**2-1.0/(1.0+c2/(OldMomentumMap(3)/2.0+LowerVal*randvec(3))**2))
  omegaz = (1.0-1.0/(1.0+c2/(OldMomentumMap(2)/2.0+LowerVal*randvec(2))**2)) &
            /(1.0+c2/(OldMomentumMap(3)/2.0+LowerVal*randvec(3))**2-1.0/(1.0+c2/(OldMomentumMap(2)/2.0+LowerVal*randvec(2))**2))
  vxp2 = c2*(1.0 - omegay - omegaz)/(1.0 - omegay - omegaz + c2/(OldMomentumMap(1)/2.0+LowerVal*randvec(1))**2)
  vyp2 = c2*omegay*(1.0 - (1.0 - omegay - omegaz)/(1.0 - omegay - omegaz + c2/(OldMomentumMap(1)/2.0+LowerVal*randvec(1))**2))
  vzp2 = c2*omegaz*(1.0 - (1.0 - omegay - omegaz)/(1.0 - omegay - omegaz + c2/(OldMomentumMap(1)/2.0+LowerVal*randvec(1))**2))

  omegayn = (1.0-1.0/(1.0+c2/(OldMomentumMap(3)/2.0-LowerVal*randvec(3))**2)) &
            /(1.0+c2/(OldMomentumMap(2)/2.0-LowerVal*randvec(2))**2-1.0/(1.0+c2/(OldMomentumMap(3)/2.0-LowerVal*randvec(3))**2))
  omegazn = (1.0-1.0/(1.0+c2/(OldMomentumMap(2)/2.0-LowerVal*randvec(2))**2)) &
            /(1.0+c2/(OldMomentumMap(3)/2.0-LowerVal*randvec(3))**2-1.0/(1.0+c2/(OldMomentumMap(2)/2.0-LowerVal*randvec(2))**2))
  vxn2 = c2*(1.0 - omegayn - omegazn)/(1.0 - omegayn - omegazn + c2/(OldMomentumMap(1)/2.0-LowerVal*randvec(1))**2)
  vyn2 = c2*omegayn*(1.0 - (1.0 - omegayn - omegazn)/(1.0 - omegayn - omegazn + c2/(OldMomentumMap(1)/2.0-LowerVal*randvec(1))**2))
  vzn2 = c2*omegazn*(1.0 - (1.0 - omegayn - omegazn)/(1.0 - omegayn - omegazn + c2/(OldMomentumMap(1)/2.0-LowerVal*randvec(1))**2))
        
  ZeroVal1 = 1.0/SQRT(1.0-(vxp2+vyp2+vzp2)/c2) + 1.0/SQRT(1.0-(vxn2+vyn2+vzn2)/c2) - resu

  omegay = (1.0-1.0/(1.0+c2/(OldMomentumMap(3)/2.0+UpperVal*randvec(3))**2)) &
            /(1.0+c2/(OldMomentumMap(2)/2.0+UpperVal*randvec(2))**2-1.0/(1.0+c2/(OldMomentumMap(3)/2.0+UpperVal*randvec(3))**2))
  omegaz = (1.0-1.0/(1.0+c2/(OldMomentumMap(2)/2.0+UpperVal*randvec(2))**2)) &
            /(1.0+c2/(OldMomentumMap(3)/2.0+UpperVal*randvec(3))**2-1.0/(1.0+c2/(OldMomentumMap(2)/2.0+UpperVal*randvec(2))**2))
  vxp2 = c2*(1.0 - omegay - omegaz)/(1.0 - omegay - omegaz + c2/(OldMomentumMap(1)/2.0+UpperVal*randvec(1))**2)
  vyp2 = c2*omegay*(1.0 - (1.0 - omegay - omegaz)/(1.0 - omegay - omegaz + c2/(OldMomentumMap(1)/2.0+UpperVal*randvec(1))**2))
  vzp2 = c2*omegaz*(1.0 - (1.0 - omegay - omegaz)/(1.0 - omegay - omegaz + c2/(OldMomentumMap(1)/2.0+UpperVal*randvec(1))**2))

  omegayn = (1.0-1.0/(1.0+c2/(OldMomentumMap(3)/2.0-UpperVal*randvec(3))**2)) &
            /(1.0+c2/(OldMomentumMap(2)/2.0-UpperVal*randvec(2))**2-1.0/(1.0+c2/(OldMomentumMap(3)/2.0-UpperVal*randvec(3))**2))
  omegazn = (1.0-1.0/(1.0+c2/(OldMomentumMap(2)/2.0-UpperVal*randvec(2))**2)) &
            /(1.0+c2/(OldMomentumMap(3)/2.0-UpperVal*randvec(3))**2-1.0/(1.0+c2/(OldMomentumMap(2)/2.0-UpperVal*randvec(2))**2))
  vxn2 = c2*(1.0 - omegayn - omegazn)/(1.0 - omegayn - omegazn + c2/(OldMomentumMap(1)/2.0-UpperVal*randvec(1))**2)
  vyn2 = c2*omegayn*(1.0 - (1.0 - omegayn - omegazn)/(1.0 - omegayn - omegazn + c2/(OldMomentumMap(1)/2.0-UpperVal*randvec(1))**2))
  vzn2 = c2*omegazn*(1.0 - (1.0 - omegayn - omegazn)/(1.0 - omegayn - omegazn + c2/(OldMomentumMap(1)/2.0-UpperVal*randvec(1))**2))

  ZeroVal2 = 1.0/SQRT(1.0-(vxp2+vyp2+vzp2)/c2) + 1.0/SQRT(1.0-(vxn2+vyn2+vzn2)/c2) - resu

  DO WHILE (ABS(LowerVal-UpperVal).GT.eps_prec)                      !  Let's search the zero point by bisection
    MiddleVal = 0.5*(LowerVal+UpperVal)
    IF ((LowerVal.GT.MaxPosiVal).OR.(MiddleVal.GT.MaxPosiVal)) THEN
      CALL abort(&
      __STAMP__&
      ,' Cannot find zero point in E-relativistic calcualtion function!')
    END IF
    ! decision of direction of bisection
    IF (ZeroVal1*ZeroVal2.LT.0) THEN
      UpperVal = MiddleVal
    ELSE
      LowerVal = MiddleVal
    END IF
  END DO
  CalcRelaBeta = LowerVal
  RETURN

END FUNCTION CalcRelaBeta


REAL FUNCTION CalcRelaBeta2(energy,randvecin, mpf, SpecID, DeltaE, OldMomentum)
!===================================================================================================================================
! calculates relativistic beta for energy conservation
!===================================================================================================================================
! MODULES
  USE MOD_Globals
  USE MOD_Equation_Vars,          ONLY : c2
  USE MOD_Particle_Vars,          ONLY : Species
!-----------------------------------------------------------------------------------------------------------------------------------
! IMPLICIT VARIABLE HANDLING
   IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
  REAL,INTENT(IN)                    :: energy, mpf, DeltaE
  REAL,INTENT(IN)                 ::  OldMomentum(3), randvecin(3)
  INTEGER, INTENT(IN)                :: SpecID
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES                                                                        !
  REAL                    :: LowerVal, UpperVal, MiddleVal, ZeroLow, ZeroUp, ZeroMid   ! upper and lower value of zero point search 
  REAl                    :: eps_prec !=1.0e-29   ! precision of zero point search
  REAL                    :: resu, OldMomentumMapPos(3),randvec(3),OldMomentumMapNeg(3)
  REAL                    :: omegay, omegayn
  REAL                    :: vxp2, vyp2, vzp2, vxn2, vyn2, vzn2
!===================================================================================================================================
  resu = (energy+DeltaE) /(mpf*c2*Species(SpecID)%MassIC) + 2.0
  randvec(1:3) = randvecin(1:3)/(mpf*Species(SpecID)%MassIC)
  LowerVal  = 0.0 !SQRT(0.5*DeltaE*(mpf*Species(SpecID)%MassIC))
  UpperVal  = SQRT(4.0*(energy+DeltaE)*(mpf*Species(SpecID)%MassIC))
  eps_prec = (UpperVal-LowerVal)/1E15
  IF (eps_prec.LT.1.0E-30) eps_prec=1.0E-30
  OldMomentumMapPos(1:3) = OldMomentum(1:3)/(2.0*mpf*Species(SpecID)%MassIC)+LowerVal*randvec
  OldMomentumMapNeg(1:3) = OldMomentum(1:3)/(2.0*mpf*Species(SpecID)%MassIC)-LowerVal*randvec    

  omegay = (1.0-1.0/(1.0+c2/OldMomentumMapPos(3)**2)) &
            /(1.0+c2/OldMomentumMapPos(2)**2-1.0/(1.0+c2/OldMomentumMapPos(3)**2))
  vxp2 = c2*(1.0 - omegay - (1.0-omegay)/(1.0+c2/OldMomentumMapPos(3)**2)) &
      /(1.0 - omegay - (1.0-omegay)/(1.0+c2/OldMomentumMapPos(3)**2)+c2/OldMomentumMapPos(1)**2)
  vyp2 = (c2-vxp2)*omegay
  vzp2 = (c2-vxp2-vyp2)/(1.0+c2/OldMomentumMapPos(3)**2)

  omegayn = (1.0-1.0/(1.0+c2/OldMomentumMapNeg(3)**2)) &
            /(1.0+c2/OldMomentumMapNeg(2)**2-1.0/(1.0+c2/OldMomentumMapNeg(3)**2))      
  vxn2 = c2*(1.0 - omegayn - (1.0-omegayn)/(1.0+c2/OldMomentumMapNeg(3)**2)) &
      /(1.0 - omegayn - (1.0-omegayn)/(1.0+c2/OldMomentumMapNeg(3)**2)+c2/OldMomentumMapNeg(1)**2)
  vyn2 = (c2-vxn2)*omegayn
  vzn2 = (c2-vxn2-vyn2)/(1.0+c2/OldMomentumMapNeg(3)**2)
        
  ZeroLow = 1.0/SQRT(1.0-(vxp2+vyp2+vzp2)/c2) + 1.0/SQRT(1.0-(vxn2+vyn2+vzn2)/c2) - resu

  OldMomentumMapPos(1:3) = OldMomentum(1:3)/(2.0*mpf*Species(SpecID)%MassIC)+UpperVal*randvec
  OldMomentumMapNeg(1:3) = OldMomentum(1:3)/(2.0*mpf*Species(SpecID)%MassIC)-UpperVal*randvec    

  omegay = (1.0-1.0/(1.0+c2/OldMomentumMapPos(3)**2)) &
            /(1.0+c2/OldMomentumMapPos(2)**2-1.0/(1.0+c2/OldMomentumMapPos(3)**2))
  vxp2 = c2*(1.0 - omegay - (1.0-omegay)/(1.0+c2/OldMomentumMapPos(3)**2)) &
      /(1.0 - omegay - (1.0-omegay)/(1.0+c2/OldMomentumMapPos(3)**2)+c2/OldMomentumMapPos(1)**2)
  vyp2 = (c2-vxp2)*omegay
  vzp2 = (c2-vxp2-vyp2)/(1.0+c2/OldMomentumMapPos(3)**2)

  omegayn = (1.0-1.0/(1.0+c2/OldMomentumMapNeg(3)**2)) &
            /(1.0+c2/OldMomentumMapNeg(2)**2-1.0/(1.0+c2/OldMomentumMapNeg(3)**2))      
  vxn2 = c2*(1.0 - omegayn - (1.0-omegayn)/(1.0+c2/OldMomentumMapNeg(3)**2)) &
      /(1.0 - omegayn - (1.0-omegayn)/(1.0+c2/OldMomentumMapNeg(3)**2)+c2/OldMomentumMapNeg(1)**2)
  vyn2 = (c2-vxn2)*omegayn
  vzn2 = (c2-vxn2-vyn2)/(1.0+c2/OldMomentumMapNeg(3)**2)

  ZeroUp = 1.0/SQRT(1.0-(vxp2+vyp2+vzp2)/c2) + 1.0/SQRT(1.0-(vxn2+vyn2+vzn2)/c2) - resu

  DO WHILE (ABS(LowerVal-UpperVal).GT.eps_prec)                      !  Let's search the zero point by bisection
    IF ((ZeroLow*ZeroUp).GT.0.0) THEN
      CALL abort(&
      __STAMP__&
      ,' Cannot find zero point in E-relativistic calcualtion function!')
    END IF
    MiddleVal = 0.5*(LowerVal+UpperVal)
    OldMomentumMapPos(1:3) = OldMomentum(1:3)/(2.0*mpf*Species(SpecID)%MassIC)+MiddleVal*randvec
    OldMomentumMapNeg(1:3) = OldMomentum(1:3)/(2.0*mpf*Species(SpecID)%MassIC)-MiddleVal*randvec    
    omegay = (1.0-1.0/(1.0+c2/OldMomentumMapPos(3)**2)) &
              /(1.0+c2/OldMomentumMapPos(2)**2-1.0/(1.0+c2/OldMomentumMapPos(3)**2))
    vxp2 = c2*(1.0 - omegay - (1.0-omegay)/(1.0+c2/OldMomentumMapPos(3)**2)) &
        /(1.0 - omegay - (1.0-omegay)/(1.0+c2/OldMomentumMapPos(3)**2)+c2/OldMomentumMapPos(1)**2)
    vyp2 = (c2-vxp2)*omegay
    vzp2 = (c2-vxp2-vyp2)/(1.0+c2/OldMomentumMapPos(3)**2)
    omegayn = (1.0-1.0/(1.0+c2/OldMomentumMapNeg(3)**2)) &
              /(1.0+c2/OldMomentumMapNeg(2)**2-1.0/(1.0+c2/OldMomentumMapNeg(3)**2))      
    vxn2 = c2*(1.0 - omegayn - (1.0-omegayn)/(1.0+c2/OldMomentumMapNeg(3)**2)) &
        /(1.0 - omegayn - (1.0-omegayn)/(1.0+c2/OldMomentumMapNeg(3)**2)+c2/OldMomentumMapNeg(1)**2)
    vyn2 = (c2-vxn2)*omegayn
    vzn2 = (c2-vxn2-vyn2)/(1.0+c2/OldMomentumMapNeg(3)**2)
          
    ZeroMid = 1.0/SQRT(1.0-(vxp2+vyp2+vzp2)/c2) + 1.0/SQRT(1.0-(vxn2+vyn2+vzn2)/c2) - resu
    ! decision of direction of bisection
    IF (ZeroLow*ZeroMid.LE.0) THEN
      UpperVal = MiddleVal
    ELSE
      LowerVal = MiddleVal
    END IF
  END DO
  CalcRelaBeta2 = LowerVal

  RETURN

END FUNCTION CalcRelaBeta2


#if (PP_TimeDiscMethod==300)
SUBROUTINE SetNewDistrFPInnerDensEst(NewPartNum, SpecNum,Csquare)                                                                  !
!===================================================================================================================================
!
!===================================================================================================================================
! MODULES
  USE MOD_Particle_Vars, ONLY : PartState, Species, PartSpecies, &
                     PartMPF, PartStatevMPFSpec, vMPFOldBrownVelo, vMPFOldMPF,vMPF_oldMPFSum, PartStateMap &
                    , vMPF_NewPosRefElem, vMPF_relativistic
  USE MOD_Equation_Vars,          ONLY : c2
  USE MOD_Globals
  USE MOD_FPFlow_Vars,  ONLY : FPInnerVelos, vMPF_oldEngSumRot,vMPF_oldEngSumVib, vMPF_oldMomSumVib, vMPF_oldMomSumRot
  USE MOD_FPFlow_Vars,  ONLY : vMPFOldVeloVib, vMPFOldVeloRot
!----------------------------------------------------------------------------------------------------------------------------------
! IMPLICIT VARIABLE HANDLING
  IMPLICIT NONE                                                                                    !
!----------------------------------------------------------------------------------------------------------------------------------
! ARGUMENT LIST DECLARATION                                                                        !
  INTEGER,INTENT(IN)              :: NewPartNum, SpecNum
  LOGICAL,INTENT(INOUT)              :: Csquare
!----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLE DECLARATION
  REAL                            :: v_min, v_max, iRan, iRan2, v_merge, ran1
  INTEGER                         :: iDir, iPart, SpecID, iLoop, iPart2, iLoop2, numloop
  REAL                            :: TempPartVelo(NewPartNum,2),MaxProb, MaxProbtemp, NormVeloOld(SpecNum, 1:2)
  REAL                            :: bandwidth, ProbPos, VeloSQ, Gamma
!===================================================================================================================================
bandwidth= 0.05 !0.03
SpecID = PartSpecies(PartStatevMPFSpec(1))

DO iLoop = 1, SpecNum
  vMPFOldVeloVib(1:2,iLoop) = FPInnerVelos(PartStatevMPFSpec(iLoop))%FP_VibVelo(1:2)
  vMPFOldVeloRot(1:2,iLoop) = FPInnerVelos(PartStatevMPFSpec(iLoop))%FP_RotVelo(1:2)
END DO


!first Vib  
DO iDir = 1, 2
  v_min = MINVAL(vMPFOldVeloVib(iDir, :))
  v_max = MAXVAL(vMPFOldVeloVib(iDir, :))
  NormVeloOld(1:SpecNum,iDir) = 2.0*(vMPFOldVeloVib(iDir,1:SpecNum)-v_min)/(v_max-v_min)-1.0

  MaxProb=0.0
  DO iLoop = 1, SpecNum  
    MaxProbtemp = 0.0
    DO iLoop2 = 1, SpecNum
      MaxProbtemp = MaxProbtemp + GaussCore4D(bandwidth, PartStateMap(iLoop2,1:3), NormVeloOld(iLoop2,iDir) &
              , PartStateMap(iLoop,1:3), NormVeloOld(iLoop,iDir))
    END DO
    IF (MaxProbtemp.GT.MaxProb) MaxProb = MaxProbTemp
  END DO
  MaxProb = MaxProb/(bandwidth*SpecNum)
  DO iPart =1, NewPartNum -1

    ProbPos = 0.0
    CALL RANDOM_NUMBER(iRan)  
    iRan = iRan * 2.0 - 1.0
    DO iLoop2 = 1, SpecNum
      ProbPos = ProbPos + GaussCore4D(bandwidth, PartStateMap(iLoop2,1:3),  NormVeloOld(iLoop2,iDir), &
                vMPF_NewPosRefElem(iPart, 1:3),iRan)
    END DO
    ProbPos = ProbPos/(MaxProb*bandwidth*SpecNum)
    CALL RANDOM_NUMBER(iRan2)
    numloop = 0
    DO WHILE (iRan2.GE.ProbPos)
      ProbPos = 0.0
      CALL RANDOM_NUMBER(iRan)  
      iRan = iRan * 2.0 - 1.0
      DO iLoop2 = 1, SpecNum
            ProbPos = ProbPos + GaussCore4D(bandwidth, PartStateMap(iLoop2,1:3),  NormVeloOld(iLoop2,iDir), &
              vMPF_NewPosRefElem(iPart, 1:3),iRan)
      END DO
      ProbPos = ProbPos/(MaxProb*bandwidth*SpecNum)
      CALL RANDOM_NUMBER(iRan2)
      numloop = numloop + 1
      IF(numloop.GT.200000) THEN
          Csquare=.true.
          RETURN       
      END IF
    END DO  
    FPInnerVelos(PartStatevMPFSpec(iPart))%FP_VibVelo(iDir) = 0.5*(iRan+1.0)*(v_max-v_min)+v_min
  END DO
END DO

IF (vMPF_relativistic) THEN
  DO iPart=1, NewPartNum -1
    VeloSq = FPInnerVelos(PartStatevMPFSpec(iPart))%FP_VibVelo(1) * FPInnerVelos(PartStatevMPFSpec(iPart))%FP_VibVelo(1) &
             + FPInnerVelos(PartStatevMPFSpec(iPart))%FP_VibVelo(2) * FPInnerVelos(PartStatevMPFSpec(iPart))%FP_VibVelo(2) 
    IF (VeloSQ.GT.c2) THEN
      Csquare=.true.
      RETURN
    END IF
    Gamma = VeloSq/c2      
    Gamma = 1./SQRT(1.-Gamma)
    vMPF_oldEngSumVib = vMPF_oldEngSumVib - PartMPF(PartStatevMPFSpec(iPart)) * (Gamma-1.)*c2
    vMPF_oldMomSumVib(1:2) = vMPF_oldMomSumVib(1:2) -  PartMPF(PartStatevMPFSpec(iPart)) &
                         * FPInnerVelos(PartStatevMPFSpec(iPart))%FP_VibVelo(1:2)*Gamma  
  END DO
  !Must be done
  WRITE(*,*) 'relativistic not possible using FP'
  STOP
!PartState(PartStatevMPFSpec(NewPartNum),4:6) = RelVeloFromMom(vMPF_oldMomSum(1:3), SpecID, PartMPF(PartStatevMPFSpec(NewPartNum)))
!  VeloSq = PartState(PartStatevMPFSpec(NewPartNum),4) * PartState(PartStatevMPFSpec(NewPartNum),4) &
!           + PartState(PartStatevMPFSpec(NewPartNum),5) * PartState(PartStatevMPFSpec(NewPartNum),5) &
!           + PartState(PartStatevMPFSpec(NewPartNum),6) * PartState(PartStatevMPFSpec(NewPartNum),6)
!  IF (VeloSQ.GT.c2) THEN
!    Csquare=.true.
!    RETURN
!  END IF
!  Gamma = VeloSq/c2      
!  Gamma = 1./SQRT(1.-Gamma)
!  vMPF_oldEngSum = vMPF_oldEngSum - Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(NewPartNum)) &
!                     * (Gamma-1.)*c2
!  vMPF_oldMomSum(1:3) = vMPF_oldMomSum(1:3) - Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(NewPartNum)) &
!                         * PartState(PartStatevMPFSpec(NewPartNum),4:6)*Gamma  
ELSE
  DO iPart=1, NewPartNum -1
    vMPF_oldEngSumVib = vMPF_oldEngSumVib - 0.5 * PartMPF(PartStatevMPFSpec(iPart)) &
            * (FPInnerVelos(PartStatevMPFSpec(iPart))%FP_VibVelo(1)**2 + FPInnerVelos(PartStatevMPFSpec(iPart))%FP_VibVelo(2)**2)
    vMPF_oldMomSumVib(1:2) = vMPF_oldMomSumVib(1:2) - PartMPF(PartStatevMPFSpec(iPart)) &
        * FPInnerVelos(PartStatevMPFSpec(iPart))%FP_VibVelo(1:2)    
  END DO
  FPInnerVelos(PartStatevMPFSpec(NewPartNum))%FP_VibVelo(1:2) =vMPF_oldMomSumVib(1:2) &
                        / (PartMPF(PartStatevMPFSpec(NewPartNum)) )
  vMPF_oldEngSumVib = vMPF_oldEngSumVib - 0.5 * PartMPF(PartStatevMPFSpec(NewPartNum)) &
          * (FPInnerVelos(PartStatevMPFSpec(NewPartNum))%FP_VibVelo(1)**2  &
          + FPInnerVelos(PartStatevMPFSpec(NewPartNum))%FP_VibVelo(2)**2)
END IF

IF (vMPF_oldEngSumVib.LT.0.0) THEN
  DO iPart = 1, NewPartNum  
    TempPartVelo(iPart,1:2) = FPInnerVelos(PartStatevMPFSpec(iPart))%FP_VibVelo(1:2)
  END DO

  iLoop = 0 
  numloop = 0
   DO WHILE (vMPF_oldEngSumVib.LT.0.0)
    CALL RANDOM_NUMBER(ran1)    
    iDir = INT(2*ran1 + 1)
    iPart2 = MAXLOC(TempPartVelo(:,iDir),1)
    iPart = MINLOC(TempPartVelo(:,iDir),1)
    IF (iPart2.EQ.iPart) CYCLE
    IF (vMPF_relativistic) THEN 

    
      STOP

!      VeloSq = PartState(PartStatevMPFSpec(iPart2),4) * PartState(PartStatevMPFSpec(iPart2),4) &
!           + PartState(PartStatevMPFSpec(iPart2),5) * PartState(PartStatevMPFSpec(iPart2),5) &
!           + PartState(PartStatevMPFSpec(iPart2),6) * PartState(PartStatevMPFSpec(iPart2),6)    
!      Gamma = VeloSq/c2      
!      Gamma = 1./SQRT(1.-Gamma)
!      vMPF_oldEngSum = vMPF_oldEngSum + Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart2)) &
!                     * (Gamma-1.)*c2
!      vMPF_oldMomSum(1:3) = vMPF_oldMomSum(1:3)  + Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart2)) &
!                         * PartState(PartStatevMPFSpec(iPart2),4:6)*Gamma  
!      VeloSq = PartState(PartStatevMPFSpec(iPart),4) * PartState(PartStatevMPFSpec(iPart),4) &
!           + PartState(PartStatevMPFSpec(iPart),5) * PartState(PartStatevMPFSpec(iPart),5) &
!           + PartState(PartStatevMPFSpec(iPart),6) * PartState(PartStatevMPFSpec(iPart),6)    
!      Gamma = VeloSq/c2      
!      Gamma = 1./SQRT(1.-Gamma)
!      vMPF_oldEngSum = vMPF_oldEngSum + Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart)) &
!                     * (Gamma-1.)*c2
!      vMPF_oldMomSum(1:3) = vMPF_oldMomSum(1:3)  + Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart)) &
!                         * PartState(PartStatevMPFSpec(iPart),4:6)*Gamma  
!      CALL RANDOM_NUMBER(ran1) 
!      v_merge = (PartState(PartStatevMPFSpec(iPart2),iDir) - PartState(PartStatevMPFSpec(iPart), iDir))
!      PartState(PartStatevMPFSpec(iPart2),iDir)=PartState(PartStatevMPFSpec(iPart),iDir) + v_merge*ran1
!      !hier mal nur für eine impulsrichtung einbauen!!    
!      VeloSq = PartState(PartStatevMPFSpec(iPart2),4) * PartState(PartStatevMPFSpec(iPart2),4) &
!           + PartState(PartStatevMPFSpec(iPart2),5) * PartState(PartStatevMPFSpec(iPart2),5) &
!           + PartState(PartStatevMPFSpec(iPart2),6) * PartState(PartStatevMPFSpec(iPart2),6)    
!      Gamma = VeloSq/c2      
!      Gamma = 1./SQRT(1.-Gamma)
!      vMPF_oldEngSum = vMPF_oldEngSum - Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart2)) &
!                     * (Gamma-1.)*c2
!      vMPF_oldMomSum(1:3) = vMPF_oldMomSum(1:3)  - Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart2)) &
!                         * PartState(PartStatevMPFSpec(iPart2),4:6)*Gamma 
!      PartState(PartStatevMPFSpec(iPart),4:6) = RelVeloFromMom(vMPF_oldMomSum(1:3), SpecID, PartMPF(PartStatevMPFSpec(iPart)))
!      VeloSq = PartState(PartStatevMPFSpec(iPart),4) * PartState(PartStatevMPFSpec(iPart),4) &
!           + PartState(PartStatevMPFSpec(iPart),5) * PartState(PartStatevMPFSpec(iPart),5) &
!           + PartState(PartStatevMPFSpec(iPart),6) * PartState(PartStatevMPFSpec(iPart),6)    
!      Gamma = VeloSq/c2      
!      Gamma = 1./SQRT(1.-Gamma)
!      vMPF_oldEngSum = vMPF_oldEngSum - Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart)) &
!                     * (Gamma-1.)*c2
!      vMPF_oldMomSum(1:3) = vMPF_oldMomSum(1:3)  - Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart)) &
!                         * PartState(PartStatevMPFSpec(iPart),4:6)*Gamma
!      iLoop= iLoop + 1
!      TempPartVelo(iPart,iDir)=PartState(PartStatevMPFSpec(iPart), iDir)
!      TempPartVelo(iPart2,iDir)=PartState(PartStatevMPFSpec(iPart2), iDir)
!      IF(iLoop.GT.50000) THEN
!          Csquare=.true.
!          RETURN       
!      END IF
    ELSE      
      vMPF_oldEngSumVib = vMPF_oldEngSumVib + 0.5 * PartMPF(PartStatevMPFSpec(iPart2)) &
              * (FPInnerVelos(PartStatevMPFSpec(iPart2))%FP_VibVelo(iDir)**2)
      vMPF_oldEngSumVib = vMPF_oldEngSumVib + 0.5 * PartMPF(PartStatevMPFSpec(iPart)) &
              * (FPInnerVelos(PartStatevMPFSpec(iPart))%FP_VibVelo(iDir)**2)

      CALL RANDOM_NUMBER(ran1) 
      v_merge = (FPInnerVelos(PartStatevMPFSpec(iPart2))%FP_VibVelo(iDir) &
              - FPInnerVelos(PartStatevMPFSpec(iPart))%FP_VibVelo( iDir))
      FPInnerVelos(PartStatevMPFSpec(iPart2))%FP_VibVelo(iDir)= &
                FPInnerVelos(PartStatevMPFSpec(iPart))%FP_VibVelo(iDir) + v_merge*ran1
      FPInnerVelos(PartStatevMPFSpec(iPart))%FP_VibVelo( iDir) = &
                FPInnerVelos(PartStatevMPFSpec(iPart))%FP_VibVelo(iDir) + v_merge*(1.0-ran1)

      vMPF_oldEngSumVib = vMPF_oldEngSumVib - 0.5 * PartMPF(PartStatevMPFSpec(iPart2)) &
              * (FPInnerVelos(PartStatevMPFSpec(iPart2))%FP_VibVelo(iDir)**2)
      vMPF_oldEngSumVib = vMPF_oldEngSumVib - 0.5 * PartMPF(PartStatevMPFSpec(iPart)) &
              * (FPInnerVelos(PartStatevMPFSpec(iPart))%FP_VibVelo(iDir)**2)
      iLoop= iLoop + 1
      TempPartVelo(iPart,iDir)=FPInnerVelos(PartStatevMPFSpec(iPart))%FP_VibVelo( iDir)
      TempPartVelo(iPart2,iDir)=FPInnerVelos(PartStatevMPFSpec(iPart2))%FP_VibVelo( iDir)
      IF(iLoop.GT.200000) THEN
        Csquare=.true.
        RETURN       
      END IF
    END IF
  END DO
  SWRITE(*,*)'Loops for energy transformation needed: ', iLoop
END IF

!DO iPart = 1, NewPartNum 
!    VeloSQ = FPInnerVelos(PartStatevMPFSpec(iPart))%FP_VibVelo(1)*FPInnerVelos(PartStatevMPFSpec(iPart))%FP_VibVelo(1) &
!          + FPInnerVelos(PartStatevMPFSpec(iPart))%FP_VibVelo(2) * FPInnerVelos(PartStatevMPFSpec(iPart))%FP_VibVelo(2)          
!  IF (VeloSQ.GT.c2) THEN
!    Csquare=.true.
!    RETURN
!  END IF 
!END DO

!second rot 
DO iDir = 1, 2
  v_min = MINVAL(vMPFOldVeloRot(iDir, :))
  v_max = MAXVAL(vMPFOldVeloRot(iDir, :))
  NormVeloOld(1:SpecNum,iDir) = 2.0*(vMPFOldVeloRot(iDir,1:SpecNum)-v_min)/(v_max-v_min)-1.0

  MaxProb=0.0
  DO iLoop = 1, SpecNum  
    MaxProbtemp = 0.0
    DO iLoop2 = 1, SpecNum
      MaxProbtemp = MaxProbtemp + GaussCore4D(bandwidth, PartStateMap(iLoop2,1:3), NormVeloOld(iLoop2,iDir) &
              , PartStateMap(iLoop,1:3), NormVeloOld(iLoop,iDir))
    END DO
    IF (MaxProbtemp.GT.MaxProb) MaxProb = MaxProbTemp
  END DO
  MaxProb = MaxProb/(bandwidth*SpecNum)
  DO iPart =1, NewPartNum -1

    ProbPos = 0.0
    CALL RANDOM_NUMBER(iRan)  
    iRan = iRan * 2.0 - 1.0
    DO iLoop2 = 1, SpecNum
      ProbPos = ProbPos + GaussCore4D(bandwidth, PartStateMap(iLoop2,1:3),  NormVeloOld(iLoop2,iDir), &
                vMPF_NewPosRefElem(iPart, 1:3),iRan)
    END DO
    ProbPos = ProbPos/(MaxProb*bandwidth*SpecNum)
    CALL RANDOM_NUMBER(iRan2)
    numloop = 0
    DO WHILE (iRan2.GE.ProbPos)
      ProbPos = 0.0
      CALL RANDOM_NUMBER(iRan)  
      iRan = iRan * 2.0 - 1.0
      DO iLoop2 = 1, SpecNum
            ProbPos = ProbPos + GaussCore4D(bandwidth, PartStateMap(iLoop2,1:3),  NormVeloOld(iLoop2,iDir), &
              vMPF_NewPosRefElem(iPart, 1:3),iRan)
      END DO
      ProbPos = ProbPos/(MaxProb*bandwidth*SpecNum)
      CALL RANDOM_NUMBER(iRan2)
      numloop = numloop + 1
      IF(numloop.GT.200000) THEN
          Csquare=.true.
          RETURN       
      END IF
    END DO  
    FPInnerVelos(PartStatevMPFSpec(iPart))%FP_RotVelo(iDir) = 0.5*(iRan+1.0)*(v_max-v_min)+v_min
  END DO
END DO

IF (vMPF_relativistic) THEN
  DO iPart=1, NewPartNum -1
    VeloSq = FPInnerVelos(PartStatevMPFSpec(iPart))%FP_RotVelo(1) * FPInnerVelos(PartStatevMPFSpec(iPart))%FP_RotVelo(1) &
             + FPInnerVelos(PartStatevMPFSpec(iPart))%FP_RotVelo(2) * FPInnerVelos(PartStatevMPFSpec(iPart))%FP_RotVelo(2) 
    IF (VeloSQ.GT.c2) THEN
      Csquare=.true.
      RETURN
    END IF
    Gamma = VeloSq/c2      
    Gamma = 1./SQRT(1.-Gamma)
    vMPF_oldEngSumRot = vMPF_oldEngSumRot - PartMPF(PartStatevMPFSpec(iPart)) * (Gamma-1.)*c2
    vMPF_oldMomSumRot(1:2) = vMPF_oldMomSumRot(1:2) -  PartMPF(PartStatevMPFSpec(iPart)) &
                         * FPInnerVelos(PartStatevMPFSpec(iPart))%FP_RotVelo(1:2)*Gamma  
  END DO
  !Must be done
  WRITE(*,*) 'relativistic not possible using FP'
  STOP
!PartState(PartStatevMPFSpec(NewPartNum),4:6) = RelVeloFromMom(vMPF_oldMomSum(1:3), SpecID, PartMPF(PartStatevMPFSpec(NewPartNum)))
!  VeloSq = PartState(PartStatevMPFSpec(NewPartNum),4) * PartState(PartStatevMPFSpec(NewPartNum),4) &
!           + PartState(PartStatevMPFSpec(NewPartNum),5) * PartState(PartStatevMPFSpec(NewPartNum),5) &
!           + PartState(PartStatevMPFSpec(NewPartNum),6) * PartState(PartStatevMPFSpec(NewPartNum),6)
!  IF (VeloSQ.GT.c2) THEN
!    Csquare=.true.
!    RETURN
!  END IF
!  Gamma = VeloSq/c2      
!  Gamma = 1./SQRT(1.-Gamma)
!  vMPF_oldEngSum = vMPF_oldEngSum - Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(NewPartNum)) &
!                     * (Gamma-1.)*c2
!  vMPF_oldMomSum(1:3) = vMPF_oldMomSum(1:3) - Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(NewPartNum)) &
!                         * PartState(PartStatevMPFSpec(NewPartNum),4:6)*Gamma  
ELSE
  DO iPart=1, NewPartNum -1
    vMPF_oldEngSumRot = vMPF_oldEngSumRot - 0.5 * PartMPF(PartStatevMPFSpec(iPart)) &
            * (FPInnerVelos(PartStatevMPFSpec(iPart))%FP_RotVelo(1)**2 + FPInnerVelos(PartStatevMPFSpec(iPart))%FP_RotVelo(2)**2)
    vMPF_oldMomSumRot(1:2) = vMPF_oldMomSumRot(1:2) - PartMPF(PartStatevMPFSpec(iPart)) &
          * FPInnerVelos(PartStatevMPFSpec(iPart))%FP_RotVelo(1:2)    
  END DO
  FPInnerVelos(PartStatevMPFSpec(NewPartNum))%FP_RotVelo(1:2) =vMPF_oldMomSumRot(1:2) &
                        / (PartMPF(PartStatevMPFSpec(NewPartNum)) )
  vMPF_oldEngSumRot = vMPF_oldEngSumRot - 0.5 * PartMPF(PartStatevMPFSpec(NewPartNum)) &
          * (FPInnerVelos(PartStatevMPFSpec(NewPartNum))%FP_RotVelo(1)**2 & 
          + FPInnerVelos(PartStatevMPFSpec(NewPartNum))%FP_RotVelo(2)**2)
END IF

IF (vMPF_oldEngSumRot.LT.0.0) THEN
  DO iPart = 1, NewPartNum  
    TempPartVelo(iPart,1:2) = FPInnerVelos(PartStatevMPFSpec(iPart))%FP_RotVelo(1:2)
  END DO

  iLoop = 0 
  numloop = 0
   DO WHILE (vMPF_oldEngSumRot.LT.0.0)
    CALL RANDOM_NUMBER(ran1)    
    iDir = INT(2*ran1 + 1)
    iPart2 = MAXLOC(TempPartVelo(:,iDir),1)
    iPart = MINLOC(TempPartVelo(:,iDir),1)
    IF (iPart2.EQ.iPart) CYCLE
    IF (vMPF_relativistic) THEN 

    
      STOP

!      VeloSq = PartState(PartStatevMPFSpec(iPart2),4) * PartState(PartStatevMPFSpec(iPart2),4) &
!           + PartState(PartStatevMPFSpec(iPart2),5) * PartState(PartStatevMPFSpec(iPart2),5) &
!           + PartState(PartStatevMPFSpec(iPart2),6) * PartState(PartStatevMPFSpec(iPart2),6)    
!      Gamma = VeloSq/c2      
!      Gamma = 1./SQRT(1.-Gamma)
!      vMPF_oldEngSum = vMPF_oldEngSum + Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart2)) &
!                     * (Gamma-1.)*c2
!      vMPF_oldMomSum(1:3) = vMPF_oldMomSum(1:3)  + Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart2)) &
!                         * PartState(PartStatevMPFSpec(iPart2),4:6)*Gamma  
!      VeloSq = PartState(PartStatevMPFSpec(iPart),4) * PartState(PartStatevMPFSpec(iPart),4) &
!           + PartState(PartStatevMPFSpec(iPart),5) * PartState(PartStatevMPFSpec(iPart),5) &
!           + PartState(PartStatevMPFSpec(iPart),6) * PartState(PartStatevMPFSpec(iPart),6)    
!      Gamma = VeloSq/c2      
!      Gamma = 1./SQRT(1.-Gamma)
!      vMPF_oldEngSum = vMPF_oldEngSum + Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart)) &
!                     * (Gamma-1.)*c2
!      vMPF_oldMomSum(1:3) = vMPF_oldMomSum(1:3)  + Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart)) &
!                         * PartState(PartStatevMPFSpec(iPart),4:6)*Gamma  
!      CALL RANDOM_NUMBER(ran1) 
!      v_merge = (PartState(PartStatevMPFSpec(iPart2),iDir) - PartState(PartStatevMPFSpec(iPart), iDir))
!      PartState(PartStatevMPFSpec(iPart2),iDir)=PartState(PartStatevMPFSpec(iPart),iDir) + v_merge*ran1
!      !hier mal nur für eine impulsrichtung einbauen!!    
!      VeloSq = PartState(PartStatevMPFSpec(iPart2),4) * PartState(PartStatevMPFSpec(iPart2),4) &
!           + PartState(PartStatevMPFSpec(iPart2),5) * PartState(PartStatevMPFSpec(iPart2),5) &
!           + PartState(PartStatevMPFSpec(iPart2),6) * PartState(PartStatevMPFSpec(iPart2),6)    
!      Gamma = VeloSq/c2      
!      Gamma = 1./SQRT(1.-Gamma)
!      vMPF_oldEngSum = vMPF_oldEngSum - Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart2)) &
!                     * (Gamma-1.)*c2
!      vMPF_oldMomSum(1:3) = vMPF_oldMomSum(1:3)  - Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart2)) &
!                         * PartState(PartStatevMPFSpec(iPart2),4:6)*Gamma 
!      PartState(PartStatevMPFSpec(iPart),4:6) = RelVeloFromMom(vMPF_oldMomSum(1:3), SpecID, PartMPF(PartStatevMPFSpec(iPart)))
!      VeloSq = PartState(PartStatevMPFSpec(iPart),4) * PartState(PartStatevMPFSpec(iPart),4) &
!           + PartState(PartStatevMPFSpec(iPart),5) * PartState(PartStatevMPFSpec(iPart),5) &
!           + PartState(PartStatevMPFSpec(iPart),6) * PartState(PartStatevMPFSpec(iPart),6)    
!      Gamma = VeloSq/c2      
!      Gamma = 1./SQRT(1.-Gamma)
!      vMPF_oldEngSum = vMPF_oldEngSum - Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart)) &
!                     * (Gamma-1.)*c2
!      vMPF_oldMomSum(1:3) = vMPF_oldMomSum(1:3)  - Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart)) &
!                         * PartState(PartStatevMPFSpec(iPart),4:6)*Gamma
!      iLoop= iLoop + 1
!      TempPartVelo(iPart,iDir)=PartState(PartStatevMPFSpec(iPart), iDir)
!      TempPartVelo(iPart2,iDir)=PartState(PartStatevMPFSpec(iPart2), iDir)
!      IF(iLoop.GT.50000) THEN
!          Csquare=.true.
!          RETURN       
!      END IF
    ELSE      
      vMPF_oldEngSumRot = vMPF_oldEngSumRot + 0.5 * PartMPF(PartStatevMPFSpec(iPart2)) &
              * (FPInnerVelos(PartStatevMPFSpec(iPart2))%FP_RotVelo(iDir)**2)
      vMPF_oldEngSumRot = vMPF_oldEngSumRot + 0.5 * PartMPF(PartStatevMPFSpec(iPart)) &
              * (FPInnerVelos(PartStatevMPFSpec(iPart))%FP_RotVelo(iDir)**2)

      CALL RANDOM_NUMBER(ran1) 
      v_merge = (FPInnerVelos(PartStatevMPFSpec(iPart2))%FP_RotVelo(iDir) &
              - FPInnerVelos(PartStatevMPFSpec(iPart))%FP_RotVelo( iDir))
      FPInnerVelos(PartStatevMPFSpec(iPart2))%FP_RotVelo(iDir)= &
              FPInnerVelos(PartStatevMPFSpec(iPart))%FP_RotVelo(iDir) + v_merge*ran1
      FPInnerVelos(PartStatevMPFSpec(iPart))%FP_RotVelo( iDir) = &
            FPInnerVelos(PartStatevMPFSpec(iPart))%FP_RotVelo(iDir) + v_merge*(1.0-ran1)

      vMPF_oldEngSumRot = vMPF_oldEngSumRot - 0.5 * PartMPF(PartStatevMPFSpec(iPart2)) &
              * (FPInnerVelos(PartStatevMPFSpec(iPart2))%FP_RotVelo(iDir)**2)
      vMPF_oldEngSumRot = vMPF_oldEngSumRot- 0.5 * PartMPF(PartStatevMPFSpec(iPart)) &
              * (FPInnerVelos(PartStatevMPFSpec(iPart))%FP_RotVelo(iDir)**2)
      iLoop= iLoop + 1
      TempPartVelo(iPart,iDir)=FPInnerVelos(PartStatevMPFSpec(iPart))%FP_RotVelo( iDir)
      TempPartVelo(iPart2,iDir)=FPInnerVelos(PartStatevMPFSpec(iPart2))%FP_RotVelo( iDir)
      IF(iLoop.GT.200000) THEN
        Csquare=.true.
        RETURN       
      END IF
    END IF
  END DO
  SWRITE(*,*)'Loops for energy transformation needed: ', iLoop
END IF

!DO iPart = 1, NewPartNum 
!    VeloSQ = FPInnerVelos(PartStatevMPFSpec(iPart))%FP_RotVelo(1)*FPInnerVelos(PartStatevMPFSpec(iPart))%FP_RotVelo(1) &
!          + FPInnerVelos(PartStatevMPFSpec(iPart))%FP_RotVelo(2) * FPInnerVelos(PartStatevMPFSpec(iPart))%FP_RotVelo(2)          
!  IF (VeloSQ.GT.c2) THEN
!    Csquare=.true.
!    RETURN
!  END IF 
!END DO

CALL RANDOM_NUMBER(iRan)
iPart = INT(NewPartNum * iRan +1)
CALL RANDOM_NUMBER(iRan)
iPart2 = INT(NewPartNum * iRan +1)
DO WHILE(iPart2.EQ.iPart)
  CALL RANDOM_NUMBER(iRan)
  iPart2 = INT(NewPartNum * iRan +1)
END DO
CALL DoEnergyConservationFPInner(PartStatevMPFSpec(iPart),PartStatevMPFSpec(iPart2), vMPF_oldEngSumVib, vMPF_oldEngSumRot, CSquare)

END SUBROUTINE SetNewDistrFPInnerDensEst


SUBROUTINE DoEnergyConservationFPInner(iPart,iPart2, deltaEVib, deltaERot,CSquare)
!===================================================================================================================================
! Split Particles
!===================================================================================================================================
  USE MOD_Particle_Vars, ONLY : PDM, PartState, RandomVec, NumRanVec, PartSpecies, PartMPF, PEM, Species, vMPF_relativistic  
  USE MOD_DSMC_Vars, ONLY : useDSMC, CollisMode, PartStateIntEn       
  USE MOD_Equation_Vars,          ONLY : c2     
  USE MOD_FPFlow_Vars,  ONLY : FPInnerVelos, vMPF_oldEngSumRot,vMPF_oldEngSumVib, vMPF_oldMomSumVib, vMPF_oldMomSumRot
!----------------------------------------------------------------------------------------------------------------------------------
! IMPLICIT VARIABLE HANDLING
  IMPLICIT NONE                                                                                    
!----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
  INTEGER,INTENT(IN)              :: iPart, iPart2
  REAL, INTENT(IN)                :: deltaEVib, deltaERot 
  LOGICAL,INTENT(INOUT)          :: CSquare      
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES  
!----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
  INTEGER                         ::  iVec
  REAL                            :: beta, iRan, VeloSQ, VeloSQ2, Gamma
  REAL                            :: v_mom(2), v_mom2, enerpart, v_old(1:2), oldEner, old_mom(1:2), new_mom(1:2)
!===================================================================================================================================
  IF (vMPF_relativistic) THEN
  

    STOP
!  
!    CALL RANDOM_NUMBER(iRan)
!    iVec = INT(NumRanVec*iRan + 1)
!    v_old(1:3) = PartState(iPart,4:6)
!    VeloSQ = v_old(1)*v_old(1)+v_old(2)*v_old(2)+v_old(3)*v_old(3)
!    Gamma = VeloSq/c2      
!    Gamma = 1./SQRT(1.-Gamma) 
!    oldEner = Species(PartSpecies(iPart))%MassIC * PartMPF(iPart)* (Gamma-1.)*c2  
!    old_mom(1:3) = Species(PartSpecies(iPart))%MassIC * PartMPF(iPart)* v_old(1:3)*Gamma

!    v_old(1:3) = PartState(iPart2,4:6)
!    VeloSQ = v_old(1)*v_old(1)+v_old(2)*v_old(2)+v_old(3)*v_old(3)
!    Gamma = VeloSq/c2      
!    Gamma = 1./SQRT(1.-Gamma) 
!    oldEner = oldEner + Species(PartSpecies(iPart))%MassIC *PartMPF(iPart)* (Gamma-1.)*c2  
!    old_mom(1:3) = old_mom(1:3) + Species(PartSpecies(iPart))%MassIC * PartMPF(iPart)* v_old(1:3)*Gamma  
!    !beta = CalcRelaBeta(oldEner,RandomVec(iVec, 1:3), PartMPF(iPart), PartSpecies(iPart), deltaE, old_mom(1:3))
!    beta = CalcRelaBeta2(oldEner,RandomVec(iVec, 1:3), PartMPF(iPart), PartSpecies(iPart), deltaEVib, old_mom(1:3))

!    new_mom(1:3) = old_mom(1:3)/2.0 + beta*RandomVec(iVec, 1:3)
!    PartState(iPart,4:6) = RelVeloFromMom(new_mom(1:3), PartSpecies(iPart), PartMPF(iPart))
!    new_mom(1:3) = old_mom(1:3)/2.0 - beta*RandomVec(iVec, 1:3)
!    PartState(iPart2,4:6) = RelVeloFromMom(new_mom(1:3), PartSpecies(iPart2), PartMPF(iPart2))
  ELSE
    v_mom(1:2) = (FPInnerVelos(iPart)%FP_VibVelo(1:2)*PartMPF(iPart) + FPInnerVelos(iPart2)%FP_VibVelo(1:2)*PartMPF(iPart2))
    v_mom2 = v_mom(1)*v_mom(1)+v_mom(2)*v_mom(2)
    enerpart = 0.5*(PartMPF(iPart) & 
        *(FPInnerVelos(iPart)%FP_VibVelo(1)*FPInnerVelos(iPart)%FP_VibVelo(1) & 
         +FPInnerVelos(iPart)%FP_VibVelo(2)*FPInnerVelos(iPart)%FP_VibVelo(2)) &
        + PartMPF(iPart2) &
        *(FPInnerVelos(iPart2)%FP_VibVelo(1)*FPInnerVelos(iPart2)%FP_VibVelo(1) &
        +FPInnerVelos(iPart2)%FP_VibVelo(2)*FPInnerVelos(iPart2)%FP_VibVelo(2)))

    beta = SQRT((enerpart+deltaEVib)*PartMPF(iPart2)-v_mom2/4.0)
    !set new velocity v1
    CALL RANDOM_NUMBER(iRan)
    iVec = INT(NumRanVec*iRan + 1)
    FPInnerVelos(iPart)%FP_VibVelo(1:2) = (v_mom(1:2)/2.0 + beta * RandomVec(iVec, 1:2))/(PartMPF(iPart))
    FPInnerVelos(iPart2)%FP_VibVelo(1:2) = (v_mom(1:2)/2.0 - beta * RandomVec(iVec, 1:2))/(PartMPF(iPart2))
  END IF

!  VeloSQ = FPInnerVelos(iPart)%FP_VibVelo(1) * FPInnerVelos(iPart)%FP_VibVelo(1) &
!        + FPInnerVelos(iPart)%FP_VibVelo(2) * FPInnerVelos(iPart)%FP_VibVelo(2) 
!  IF(VeloSQ.GT.c2) THEN
!    CSquare=.true.
!  END IF  
!  VeloSQ2 = FPInnerVelos(iPart2)%FP_VibVelo(1) * FPInnerVelos(iPart2)%FP_VibVelo(1) &
!        + FPInnerVelos(iPart2)%FP_VibVelo(2) * FPInnerVelos(iPart2)%FP_VibVelo(2) 
!  IF(VeloSQ2.GT.c2) THEN
!    CSquare=.true.
!  END IF

  IF (vMPF_relativistic) THEN
  

    STOP
  
!    CALL RANDOM_NUMBER(iRan)
!    iVec = INT(NumRanVec*iRan + 1)
!    v_old(1:3) = PartState(iPart,4:6)
!    VeloSQ = v_old(1)*v_old(1)+v_old(2)*v_old(2)+v_old(3)*v_old(3)
!    Gamma = VeloSq/c2      
!    Gamma = 1./SQRT(1.-Gamma) 
!    oldEner = Species(PartSpecies(iPart))%MassIC * PartMPF(iPart)* (Gamma-1.)*c2  
!    old_mom(1:3) = Species(PartSpecies(iPart))%MassIC * PartMPF(iPart)* v_old(1:3)*Gamma

!    v_old(1:3) = PartState(iPart2,4:6)
!    VeloSQ = v_old(1)*v_old(1)+v_old(2)*v_old(2)+v_old(3)*v_old(3)
!    Gamma = VeloSq/c2      
!    Gamma = 1./SQRT(1.-Gamma) 
!    oldEner = oldEner + Species(PartSpecies(iPart))%MassIC *PartMPF(iPart)* (Gamma-1.)*c2  
!    old_mom(1:3) = old_mom(1:3) + Species(PartSpecies(iPart))%MassIC * PartMPF(iPart)* v_old(1:3)*Gamma  
!    !beta = CalcRelaBeta(oldEner,RandomVec(iVec, 1:3), PartMPF(iPart), PartSpecies(iPart), deltaE, old_mom(1:3))
!    beta = CalcRelaBeta2(oldEner,RandomVec(iVec, 1:3), PartMPF(iPart), PartSpecies(iPart), deltaERot, old_mom(1:3))

!    new_mom(1:3) = old_mom(1:3)/2.0 + beta*RandomVec(iVec, 1:3)
!    PartState(iPart,4:6) = RelVeloFromMom(new_mom(1:3), PartSpecies(iPart), PartMPF(iPart))
!    new_mom(1:3) = old_mom(1:3)/2.0 - beta*RandomVec(iVec, 1:3)
!    PartState(iPart2,4:6) = RelVeloFromMom(new_mom(1:3), PartSpecies(iPart2), PartMPF(iPart2))
  ELSE
    v_mom(1:2) = (FPInnerVelos(iPart)%FP_RotVelo(1:2)*PartMPF(iPart) + FPInnerVelos(iPart2)%FP_RotVelo(1:2)*PartMPF(iPart2))
    v_mom2 = v_mom(1)*v_mom(1)+v_mom(2)*v_mom(2)
    enerpart = 0.5*(PartMPF(iPart) & 
        *(FPInnerVelos(iPart)%FP_RotVelo(1)*FPInnerVelos(iPart)%FP_RotVelo(1) &
        +FPInnerVelos(iPart)%FP_RotVelo(2)*FPInnerVelos(iPart)%FP_RotVelo(2)) &
        + PartMPF(iPart2) &
        *(FPInnerVelos(iPart2)%FP_RotVelo(1)*FPInnerVelos(iPart2)%FP_RotVelo(1) &
        +FPInnerVelos(iPart2)%FP_RotVelo(2)*FPInnerVelos(iPart2)%FP_RotVelo(2)))

    beta = SQRT((enerpart+deltaERot)*PartMPF(iPart2)-v_mom2/4.0)
    !set new velocity v1
    CALL RANDOM_NUMBER(iRan)
    iVec = INT(NumRanVec*iRan + 1)
    FPInnerVelos(iPart)%FP_RotVelo(1:2) = (v_mom(1:2)/2.0 + beta * RandomVec(iVec, 1:2))/(PartMPF(iPart))
    FPInnerVelos(iPart2)%FP_RotVelo(1:2) = (v_mom(1:2)/2.0 - beta * RandomVec(iVec, 1:2))/(PartMPF(iPart2))
  END IF

!  VeloSQ = FPInnerVelos(iPart)%FP_RotVelo(1) * FPInnerVelos(iPart)%FP_RotVelo(1) &
!        + FPInnerVelos(iPart)%FP_RotVelo(2) * FPInnerVelos(iPart)%FP_RotVelo(2) 
!  IF(VeloSQ.GT.c2) THEN
!    CSquare=.true.
!  END IF  
!  VeloSQ2 = FPInnerVelos(iPart2)%FP_RotVelo(1) * FPInnerVelos(iPart2)%FP_RotVelo(1) &
!        + FPInnerVelos(iPart2)%FP_RotVelo(2) * FPInnerVelos(iPart2)%FP_RotVelo(2) 
!  IF(VeloSQ2.GT.c2) THEN
!    CSquare=.true.
!  END IF
END SUBROUTINE DoEnergyConservationFPInner


SUBROUTINE SetNewDistrFPInner(NewPartNum, nDist, SpecNum, Csquare)                                                                !
!===================================================================================================================================
!
!===================================================================================================================================
! MODULES
  USE MOD_Particle_Vars, ONLY : PartState, Species, PartSpecies, vMPF_oldEngSum, vMPF_oldMomSum, &
                     PartMPF, PartStatevMPFSpec, vMPFOldBrownVelo, vMPFOldMPF, vMPF_oldMPFSum, vMPF_relativistic
  USE MOD_Globals
  USE MOD_Equation_Vars,          ONLY : c2
  USE MOD_FPFlow_Vars,  ONLY : FPInnerVelos, vMPF_oldEngSumRot,vMPF_oldEngSumVib, vMPF_oldMomSumVib, vMPF_oldMomSumRot
  USE MOD_FPFlow_Vars,  ONLY : vMPFOldVeloVib, vMPFOldVeloRot
!----------------------------------------------------------------------------------------------------------------------------------
! IMPLICIT VARIABLE HANDLING
  IMPLICIT NONE                                                                                    !
!----------------------------------------------------------------------------------------------------------------------------------
! ARGUMENT LIST DECLARATION                                                                        !
  INTEGER,INTENT(IN)                 :: NewPartNum, nDist, SpecNum
  LOGICAL,INTENT(INOUT)              :: Csquare
!----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLE DECLARATION
  REAL                            :: v_minVib, v_maxVib, v_widthVib, iRan, iRan2, v_merge, ran1
  REAL                            :: v_minRot, v_maxRot, v_widthRot
  INTEGER                         :: iDir, iPart, iBar, SpecID, iLoop, iPart2
  REAL, ALLOCATABLE            :: numDistVib(:,:), numDistRot(:,:)
  REAL                      :: TempPartVelo(NewPartNum,2), Gamma, VeloSQ
!===================================================================================================================================


  SpecID = PartSpecies(PartStatevMPFSpec(1))
  ALLOCATE(numDistVib(2, nDist), numDistRot(2, nDist))

  DO iLoop = 1, SpecNum
    vMPFOldVeloVib(1:2,iLoop) = FPInnerVelos(PartStatevMPFSpec(iLoop))%FP_VibVelo(1:2)
    vMPFOldVeloRot(1:2,iLoop) = FPInnerVelos(PartStatevMPFSpec(iLoop))%FP_RotVelo(1:2)
  END DO
  
  DO iDir = 1, 2
    v_minVib = MINVAL(vMPFOldVeloVib(iDir,:))
    v_maxVib = MAXVAL(vMPFOldVeloVib(iDir,:))
    v_widthVib = (v_maxVib - v_minVib)/nDist
    numDistVib(iDir,:) = 0
    DO iPart = 1, SpecNum
      iBar = MIN(INT((vMPFOldVeloVib(iDir, iPart)-v_minVib)/v_widthVib+1), nDist)
      numDistVib(iDir,iBar) = numDistVib(iDir,iBar) + vMPFOldMPF(iPart)
    END DO

    v_minRot = MINVAL(vMPFOldVeloRot(iDir,:))
    v_maxRot = MAXVAL(vMPFOldVeloRot(iDir,:))
    v_widthRot = (v_maxRot - v_minRot)/nDist
    numDistRot(iDir,:) = 0
    DO iPart = 1, SpecNum
      iBar = MIN(INT((vMPFOldVeloRot(iDir, iPart)-v_minRot)/v_widthRot+1), nDist)
      numDistRot(iDir,iBar) = numDistRot(iDir,iBar) + vMPFOldMPF(iPart)
    END DO


    numDistVib(iDir,:) = numDistVib(iDir,:) / vMPF_oldMPFSum
    numDistRot(iDir,:) = numDistRot(iDir,:) / vMPF_oldMPFSum

    DO iPart =1, NewPartNum - 1      
      CALL RANDOM_NUMBER(iRan)  
      iBar = INT(iRan*nDist + 1)    
      CALL RANDOM_NUMBER(iRan2)
      DO WHILE (iRan2.GE.numDistVib(iDir,iBar)) 
        CALL RANDOM_NUMBER(iRan)  
        iBar = INT(iRan*nDist + 1)    
        CALL RANDOM_NUMBER(iRan2)
      END DO  
      CALL RANDOM_NUMBER(iRan)
      FPInnerVelos(PartStatevMPFSpec(iPart))%FP_VibVelo(iDir) = (v_minVib + v_widthVib*(iBar-1) + v_widthVib*iRan) 

      CALL RANDOM_NUMBER(iRan)  
      iBar = INT(iRan*nDist + 1)    
      CALL RANDOM_NUMBER(iRan2)
      DO WHILE (iRan2.GE.numDistRot(iDir,iBar)) 
        CALL RANDOM_NUMBER(iRan)  
        iBar = INT(iRan*nDist + 1)    
        CALL RANDOM_NUMBER(iRan2)
      END DO  
      CALL RANDOM_NUMBER(iRan)
      FPInnerVelos(PartStatevMPFSpec(iPart))%FP_RotVelo(iDir) = (v_minRot + v_widthRot*(iBar-1) + v_widthRot*iRan)  
    END DO
  END DO

  
  IF (vMPF_relativistic) THEN
    STOP
!    DO iPart=1, NewPartNum -1
!      VeloSq = PartState(PartStatevMPFSpec(iPart),4) * PartState(PartStatevMPFSpec(iPart),4) &
!               + PartState(PartStatevMPFSpec(iPart),5) * PartState(PartStatevMPFSpec(iPart),5) &
!               + PartState(PartStatevMPFSpec(iPart),6) * PartState(PartStatevMPFSpec(iPart),6)
!      IF (VeloSQ.GT.c2) THEN
!        Csquare=.true.
!        RETURN
!      END IF
!      Gamma = VeloSq/c2      
!      Gamma = 1./SQRT(1.-Gamma)
!      vMPF_oldEngSum = vMPF_oldEngSum - Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart)) &
!                       * (Gamma-1.)*c2
!      vMPF_oldMomSum(1:3) = vMPF_oldMomSum(1:3) - Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart)) &
!                           * PartState(PartStatevMPFSpec(iPart),4:6)*Gamma   
!    END DO

!    VeloSq = PartState(PartStatevMPFSpec(NewPartNum),4) * PartState(PartStatevMPFSpec(NewPartNum),4) &
!             + PartState(PartStatevMPFSpec(NewPartNum),5) * PartState(PartStatevMPFSpec(NewPartNum),5) &
!             + PartState(PartStatevMPFSpec(NewPartNum),6) * PartState(PartStatevMPFSpec(NewPartNum),6)
!    IF (VeloSQ.GT.c2) THEN
!      Csquare=.true.
!      RETURN
!    END IF
!    Gamma = VeloSq/c2      
!    Gamma = 1./SQRT(1.-Gamma)
!    vMPF_oldEngSum = vMPF_oldEngSum + Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(NewPartNum)) &
!                     * (Gamma-1.)*c2
!    vMPF_oldMomSum(1:3) = vMPF_oldMomSum(1:3) + Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(NewPartNum)) &
!                               * PartState(PartStatevMPFSpec(NewPartNum),4:6)*Gamma  
!    PartState(PartStatevMPFSpec(NewPartNum),4:6) = &
!             RelVeloFromMom(vMPF_oldMomSum(1:3), SpecID, PartMPF(PartStatevMPFSpec(NewPartNum)))
!    VeloSq = PartState(PartStatevMPFSpec(NewPartNum),4) * PartState(PartStatevMPFSpec(NewPartNum),4) &
!             + PartState(PartStatevMPFSpec(NewPartNum),5) * PartState(PartStatevMPFSpec(NewPartNum),5) &
!             + PartState(PartStatevMPFSpec(NewPartNum),6) * PartState(PartStatevMPFSpec(NewPartNum),6)
!    IF (VeloSQ.GT.c2) THEN
!      Csquare=.true.
!      RETURN
!    END IF
!    Gamma = VeloSq/c2      
!    Gamma = 1./SQRT(1.-Gamma)
!    vMPF_oldEngSum = vMPF_oldEngSum - Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(NewPartNum)) &
!                       * (Gamma-1.)*c2
!    vMPF_oldMomSum(1:3) = vMPF_oldMomSum(1:3) - Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(NewPartNum)) &
!                           * PartState(PartStatevMPFSpec(NewPartNum),4:6)*Gamma  
  ELSE
    DO iPart=1, NewPartNum -1 
      vMPF_oldEngSumVib = vMPF_oldEngSumVib - 0.5 * PartMPF(PartStatevMPFSpec(iPart)) &
              * (FPInnerVelos(PartStatevMPFSpec(iPart))%FP_VibVelo(1)**2 + FPInnerVelos(PartStatevMPFSpec(iPart))%FP_VibVelo(2)**2 )
      vMPF_oldMomSumVib(1:2) = vMPF_oldMomSumVib(1:2) - PartMPF(PartStatevMPFSpec(iPart)) &
                           * FPInnerVelos(PartStatevMPFSpec(iPart))%FP_VibVelo(1:2)      
      vMPF_oldEngSumRot = vMPF_oldEngSumRot - 0.5 * PartMPF(PartStatevMPFSpec(iPart)) &
              * (FPInnerVelos(PartStatevMPFSpec(iPart))%FP_RotVelo(1)**2 + FPInnerVelos(PartStatevMPFSpec(iPart))%FP_RotVelo(2)**2 )
      vMPF_oldMomSumRot(1:2) = vMPF_oldMomSumRot(1:2) - PartMPF(PartStatevMPFSpec(iPart)) &
                           * FPInnerVelos(PartStatevMPFSpec(iPart))%FP_RotVelo(1:2) 
    END DO   
    FPInnerVelos(PartStatevMPFSpec(NewPartNum))%FP_VibVelo(1:2) =vMPF_oldMomSumVib(1:2) & 
                          / (PartMPF(PartStatevMPFSpec(NewPartNum)) )
    vMPF_oldEngSumVib = vMPF_oldEngSumVib - 0.5 * PartMPF(PartStatevMPFSpec(NewPartNum)) &
            * (FPInnerVelos(PartStatevMPFSpec(NewPartNum))%FP_VibVelo(1)**2 &
              + FPInnerVelos(PartStatevMPFSpec(NewPartNum))%FP_VibVelo(2)**2 )
    FPInnerVelos(PartStatevMPFSpec(NewPartNum))%FP_RotVelo(1:2) =vMPF_oldMomSumRot(1:2) & 
                          / (PartMPF(PartStatevMPFSpec(NewPartNum)) )
    vMPF_oldEngSumRot = vMPF_oldEngSumRot - 0.5 * PartMPF(PartStatevMPFSpec(NewPartNum)) &
            * (FPInnerVelos(PartStatevMPFSpec(NewPartNum))%FP_RotVelo(1)**2 &
            + FPInnerVelos(PartStatevMPFSpec(NewPartNum))%FP_RotVelo(2)**2 )
  END IF


!!! HIER WEITER
! Vib Energy
  IF (vMPF_oldEngSumVib.LT.0.0) THEN
    DO iPart = 1, NewPartNum  
      TempPartVelo(iPart,1:2) = FPInnerVelos(PartStatevMPFSpec(iPart))%FP_VibVelo(1:2)  
    END DO  

!!!!!!!!!!!!!!!!!!
! Hier mal noch eine grundsätzliche Idee, wie man einzelne Ausreiser in der Geschwindigkeitsverteilung wegbekommen
! kann, ohne zuuu viel innerhalb der Verteilungsfunktion zu verschmieren.
!!!!!!!!!!!!!!!!!

!DO iDir = 4, 6
!    iPart2 = MAXLOC(TempPartVeloMean(1:NewPartNum,iDir-3),1)
!    iPart = MINLOC(TempPartVeloMean(1:NewPartNum,iDir-3),1)
!    IF (iPart2.EQ.iPart) CYCLE      
!    IF (iPart2.EQ.NewPartNum) THEN
!      v_merge = PartState(PartStatevMPFSpec(MAXLOC(TempPartVeloMean(1:NewPartNum-1,iDir-3),1)),iDir) &
!                - PartState(PartStatevMPFSpec(NewPartNum),iDir)
!      vMPF_oldEngSum = vMPF_oldEngSum + 0.5 * Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(NewPartNum)) &
!              * (PartState(PartStatevMPFSpec(NewPartNum),iDir)**2)
!      PartState(PartStatevMPFSpec(NewPartNum), iDir) = PartState(PartStatevMPFSpec(NewPartNum), iDir) + v_merge
!      vMPF_oldEngSum = vMPF_oldEngSum - 0.5 * Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(NewPartNum)) &
!        * (PartState(PartStatevMPFSpec(NewPartNum),iDir)**2)
!      TempPartVeloMean(NewPartNum,iDir-3)=PartState(PartStatevMPFSpec(NewPartNum), iDir)
!      v_merge = v_merge / (NewPartNum -1)
!      DO iPart = 1, NewPartNum - 1 
!        vMPF_oldEngSum = vMPF_oldEngSum + 0.5 * Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart)) &
!                * (PartState(PartStatevMPFSpec(iPart),iDir)**2)
!        PartState(PartStatevMPFSpec(iPart), iDir) = PartState(PartStatevMPFSpec(iPart), iDir) - v_merge
!        vMPF_oldEngSum = vMPF_oldEngSum - 0.5 * Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart)) &
!          * (PartState(PartStatevMPFSpec(iPart),iDir)**2)
!        TempPartVeloMean(iPart,iDir-3)=PartState(PartStatevMPFSpec(iPart), iDir)
!      END DO
!    ELSE IF(iPart.EQ.NewPartNum) THEN
!      v_merge = PartState(PartStatevMPFSpec(MINLOC(TempPartVeloMean(1:NewPartNum-1,iDir-3),1)),iDir) &
!                 - PartState(PartStatevMPFSpec(NewPartNum),iDir)
!      vMPF_oldEngSum = vMPF_oldEngSum + 0.5 * Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(NewPartNum)) &
!              * (PartState(PartStatevMPFSpec(NewPartNum),iDir)**2)
!      PartState(PartStatevMPFSpec(NewPartNum), iDir) = PartState(PartStatevMPFSpec(NewPartNum), iDir) + v_merge
!      vMPF_oldEngSum = vMPF_oldEngSum - 0.5 * Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(NewPartNum)) &
!        * (PartState(PartStatevMPFSpec(NewPartNum),iDir)**2)
!      TempPartVeloMean(NewPartNum,iDir-3)=PartState(PartStatevMPFSpec(NewPartNum), iDir)
!      v_merge = v_merge / (NewPartNum -1)
!      DO iPart = 1, NewPartNum - 1 
!        vMPF_oldEngSum = vMPF_oldEngSum + 0.5 * Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart)) &
!                * (PartState(PartStatevMPFSpec(iPart),iDir)**2)
!        PartState(PartStatevMPFSpec(iPart), iDir) = PartState(PartStatevMPFSpec(iPart), iDir) - v_merge
!        vMPF_oldEngSum = vMPF_oldEngSum - 0.5 * Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart)) &
!          * (PartState(PartStatevMPFSpec(iPart),iDir)**2)
!        TempPartVeloMean(iPart,iDir-3)=PartState(PartStatevMPFSpec(iPart), iDir)
!      END DO
!    END IF
!  END DO

!!!!!!!!!!!!!!!!!!!
! Und hier noch ein Ansatz, wie man auch beim Glätten der Verteilungsfunktion dennoch die ursprüngliche
! Verteilungsfunktion beachtet
!!!!!!!!!!!!!!!!!!
!     DO iDir = 1, 3
!      v_min = MINVAL(TempPartVeloMean(:,iDir))
!      v_max = MAXVAL(TempPartVeloMean(:,iDir))
!      v_width = (v_max - v_min)/nBar
!      partinbar(:,iDir) = 0
!      partindxbar(:,iDir,:) = 0
!      velosbar(:,iDir,:) = 0.0
!      DO iPart = 1, NewPartNum
!        iBar = MIN(INT((TempPartVeloMean(iPart, iDir)-v_min)/v_width+1), nBar)
!        partinbar(iBar,iDir) = partinbar(iBar,iDir) + 1
!        partindxbar(iBar,iDir,partinbar(iBar,iDir)) = iPart
!        velosbar(iBar,iDir,partinbar(iBar,iDir)) = TempPartVeloMean(iPart, iDir)
!      END DO
!    END DO
!    
!    iLoop = 0  
!    IF (iLoop.LT.1000) THEN
!      CALL RANDOM_NUMBER(ran1)    
!      iDir = INT(3*ran1 + 1) + 3
!      CALL RANDOM_NUMBER(ran1) 
!      iBar = INT(nBar*ran1 + 1)
!      IF (partinbar(iBar,iDir-3).LT.2) CYCLE
!      iPart2 = MAXLOC(velosbar(iBar,iDir-3, 1:partinbar(iBar,iDir-3)),1)
!      iPart = MINLOC(velosbar(iBar,iDir-3, 1:partinbar(iBar,iDir-3)),1)
!      IF (iPart2.EQ.iPart) CYCLE      
!      vMPF_oldEngSum = vMPF_oldEngSum + 0.5 * Species(SpecID)%MassIC &
!               * PartMPF(PartStatevMPFSpec(partindxbar(iBar,iDir-3,iPart2))) &
!              * (PartState(PartStatevMPFSpec(partindxbar(iBar,iDir-3,iPart2)),iDir)**2)
!      vMPF_oldEngSum = vMPF_oldEngSum + 0.5 * Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(partindxbar(iBar,iDir-3,iPart))) &
!              * (PartState(PartStatevMPFSpec(partindxbar(iBar,iDir-3,iPart)),iDir)**2)
!      CALL RANDOM_NUMBER(ran1) 
!      v_merge = (PartState(PartStatevMPFSpec(partindxbar(iBar,iDir-3,iPart2)),iDir) &
!                - PartState(PartStatevMPFSpec(partindxbar(iBar,iDir-3,iPart)), iDir))
!      PartState(PartStatevMPFSpec(partindxbar(iBar,iDir-3,iPart2)),iDir)= &
!                PartState(PartStatevMPFSpec(partindxbar(iBar,iDir-3,iPart)),iDir) + v_merge*ran1
!      PartState(PartStatevMPFSpec(partindxbar(iBar,iDir-3,iPart)),iDir) = &
!                PartState(PartStatevMPFSpec(partindxbar(iBar,iDir-3,iPart)),iDir) + v_merge*(1.0-ran1)
!      vMPF_oldEngSum = vMPF_oldEngSum - 0.5 * Species(SpecID)%MassIC &
!              * PartMPF(PartStatevMPFSpec(partindxbar(iBar,iDir-3,iPart2))) &
!              * (PartState(PartStatevMPFSpec(partindxbar(iBar,iDir-3,iPart2)),iDir)**2)
!      vMPF_oldEngSum = vMPF_oldEngSum - 0.5 * Species(SpecID)%MassIC &
!              * PartMPF(PartStatevMPFSpec(partindxbar(iBar,iDir-3,iPart))) &
!              * (PartState(PartStatevMPFSpec(partindxbar(iBar,iDir-3,iPart)),iDir)**2)
!      iLoop= iLoop + 1
!      velosbar(iBar,iDir-3, iPart) = PartState(PartStatevMPFSpec(partindxbar(iBar,iDir-3,iPart)),iDir)
!      velosbar(iBar,iDir-3, iPart2) = PartState(PartStatevMPFSpec(partindxbar(iBar,iDir-3,iPart2)),iDir)
!      TempPartVeloMean(partindxbar(iBar,iDir-3,iPart),iDir-3) = PartState(PartStatevMPFSpec(partindxbar(iBar,iDir-3,iPart)),iDir)
!      TempPartVeloMean(partindxbar(iBar,iDir-3,iPart2),iDir-3)= PartState(PartStatevMPFSpec(partindxbar(iBar,iDir-3,iPart2)),iDir)
!    ELSE
!!!!!!!!!!!!!!!

    iLoop = 0
    DO WHILE (vMPF_oldEngSumVib.LT.0.0)
      CALL RANDOM_NUMBER(ran1)    
      iDir = INT(2*ran1 + 1)
      iPart2 = MAXLOC(TempPartVelo(:,iDir),1)
      iPart = MINLOC(TempPartVelo(:,iDir),1)
      IF (iPart2.EQ.iPart) CYCLE      
      IF (vMPF_relativistic) THEN 
        STOP
!        VeloSq = PartState(PartStatevMPFSpec(iPart2),4) * PartState(PartStatevMPFSpec(iPart2),4) &
!             + PartState(PartStatevMPFSpec(iPart2),5) * PartState(PartStatevMPFSpec(iPart2),5) &
!             + PartState(PartStatevMPFSpec(iPart2),6) * PartState(PartStatevMPFSpec(iPart2),6)    
!        Gamma = VeloSq/c2      
!        Gamma = 1./SQRT(1.-Gamma)
!        vMPF_oldEngSum = vMPF_oldEngSum + Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart2)) &
!                       * (Gamma-1.)*c2
!        vMPF_oldMomSum(1:3) = vMPF_oldMomSum(1:3)  + Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart2)) &
!                           * PartState(PartStatevMPFSpec(iPart2),4:6)*Gamma  
!        VeloSq = PartState(PartStatevMPFSpec(iPart),4) * PartState(PartStatevMPFSpec(iPart),4) &
!             + PartState(PartStatevMPFSpec(iPart),5) * PartState(PartStatevMPFSpec(iPart),5) &
!             + PartState(PartStatevMPFSpec(iPart),6) * PartState(PartStatevMPFSpec(iPart),6)    
!        Gamma = VeloSq/c2      
!        Gamma = 1./SQRT(1.-Gamma)
!        vMPF_oldEngSum = vMPF_oldEngSum + Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart)) &
!                       * (Gamma-1.)*c2
!        vMPF_oldMomSum(1:3) = vMPF_oldMomSum(1:3)  + Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart)) &
!                           * PartState(PartStatevMPFSpec(iPart),4:6)*Gamma  
!        CALL RANDOM_NUMBER(ran1) 
!        v_merge = (PartState(PartStatevMPFSpec(iPart2),iDir) - PartState(PartStatevMPFSpec(iPart), iDir))
!        PartState(PartStatevMPFSpec(iPart2),iDir)=PartState(PartStatevMPFSpec(iPart),iDir) + v_merge*ran1
!        !hier mal nur für eine impulsrichtung einbauen!!    
!        VeloSq = PartState(PartStatevMPFSpec(iPart2),4) * PartState(PartStatevMPFSpec(iPart2),4) &
!             + PartState(PartStatevMPFSpec(iPart2),5) * PartState(PartStatevMPFSpec(iPart2),5) &
!             + PartState(PartStatevMPFSpec(iPart2),6) * PartState(PartStatevMPFSpec(iPart2),6)    
!        Gamma = VeloSq/c2      
!        Gamma = 1./SQRT(1.-Gamma)
!        vMPF_oldEngSum = vMPF_oldEngSum - Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart2)) &
!                       * (Gamma-1.)*c2
!        vMPF_oldMomSum(1:3) = vMPF_oldMomSum(1:3)  - Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart2)) &
!                           * PartState(PartStatevMPFSpec(iPart2),4:6)*Gamma 
!        PartState(PartStatevMPFSpec(iPart),4:6) = RelVeloFromMom(vMPF_oldMomSum(1:3), SpecID, PartMPF(PartStatevMPFSpec(iPart)))
!        VeloSq = PartState(PartStatevMPFSpec(iPart),4) * PartState(PartStatevMPFSpec(iPart),4) &
!             + PartState(PartStatevMPFSpec(iPart),5) * PartState(PartStatevMPFSpec(iPart),5) &
!             + PartState(PartStatevMPFSpec(iPart),6) * PartState(PartStatevMPFSpec(iPart),6)    
!        Gamma = VeloSq/c2      
!        Gamma = 1./SQRT(1.-Gamma)
!        vMPF_oldEngSum = vMPF_oldEngSum - Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart)) &
!                       * (Gamma-1.)*c2
!        vMPF_oldMomSum(1:3) = vMPF_oldMomSum(1:3)  - Species(SpecID)%MassIC * PartMPF(PartStatevMPFSpec(iPart)) &
!                           * PartState(PartStatevMPFSpec(iPart),4:6)*Gamma
!        iLoop= iLoop + 1
!        TempPartVelo(iPart,iDir-3)=PartState(PartStatevMPFSpec(iPart), iDir)
!        TempPartVelo(iPart2,iDir-3)=PartState(PartStatevMPFSpec(iPart2), iDir)
!        IF(iLoop.GT.50000) THEN
!            Csquare=.true.
!            RETURN       
!        END IF
      ELSE  
        vMPF_oldEngSumVib = vMPF_oldEngSumVib + 0.5 * PartMPF(PartStatevMPFSpec(iPart2)) &
                * (FPInnerVelos(PartStatevMPFSpec(iPart2))%FP_VibVelo(iDir)**2)
        vMPF_oldEngSumVib = vMPF_oldEngSumVib + 0.5 * PartMPF(PartStatevMPFSpec(iPart)) &
                * (FPInnerVelos(PartStatevMPFSpec(iPart))%FP_VibVelo(iDir)**2)

        CALL RANDOM_NUMBER(ran1) 
        v_merge = (FPInnerVelos(PartStatevMPFSpec(iPart2))%FP_VibVelo(iDir) &
                - FPInnerVelos(PartStatevMPFSpec(iPart))%FP_VibVelo( iDir))
        FPInnerVelos(PartStatevMPFSpec(iPart2))%FP_VibVelo(iDir)= &
                FPInnerVelos(PartStatevMPFSpec(iPart))%FP_VibVelo(iDir) + v_merge*ran1
        FPInnerVelos(PartStatevMPFSpec(iPart))%FP_VibVelo( iDir) = &
                FPInnerVelos(PartStatevMPFSpec(iPart))%FP_VibVelo(iDir) + v_merge*(1.0-ran1)

        vMPF_oldEngSumVib = vMPF_oldEngSumVib - 0.5 * PartMPF(PartStatevMPFSpec(iPart2)) &
                * (FPInnerVelos(PartStatevMPFSpec(iPart2))%FP_VibVelo(iDir)**2)
        vMPF_oldEngSumVib = vMPF_oldEngSumVib - 0.5 * PartMPF(PartStatevMPFSpec(iPart)) &
                * (FPInnerVelos(PartStatevMPFSpec(iPart))%FP_VibVelo(iDir)**2)
        iLoop= iLoop + 1
        TempPartVelo(iPart,iDir)=FPInnerVelos(PartStatevMPFSpec(iPart))%FP_VibVelo( iDir)
        TempPartVelo(iPart2,iDir)=FPInnerVelos(PartStatevMPFSpec(iPart2))%FP_VibVelo( iDir)
        IF(iLoop.GT.100000) THEN
          Csquare=.true.
          RETURN       
        END IF
      END IF
    END DO
   ! SWRITE(*,*)'Loops for energy transformation needed: ', iLoop
  END IF

!  DO iPart = 1, NewPartNum 
!      VeloSQ = PartState(PartStatevMPFSpec(iPart),4)*PartState(PartStatevMPFSpec(iPart),4) &
!            + PartState(PartStatevMPFSpec(iPart),5) * PartState(PartStatevMPFSpec(iPart),5) &
!            + PartState(PartStatevMPFSpec(iPart),6) * PartState(PartStatevMPFSpec(iPart),6)           
!    IF (VeloSQ.GT.c2) THEN
!      Csquare=.true.
!      EXIT
!    END IF
!  END DO

  IF (vMPF_oldEngSumRot.LT.0.0) THEN
    DO iPart = 1, NewPartNum  
      TempPartVelo(iPart,1:2) = FPInnerVelos(PartStatevMPFSpec(iPart))%FP_RotVelo(1:2)  
    END DO  

    iLoop = 0
    DO WHILE (vMPF_oldEngSumRot.LT.0.0)
      CALL RANDOM_NUMBER(ran1)    
      iDir = INT(2*ran1 + 1)
      iPart2 = MAXLOC(TempPartVelo(:,iDir),1)
      iPart = MINLOC(TempPartVelo(:,iDir),1)
      IF (iPart2.EQ.iPart) CYCLE      
      IF (vMPF_relativistic) THEN 
        STOP
      ELSE  
        vMPF_oldEngSumRot = vMPF_oldEngSumRot + 0.5 * PartMPF(PartStatevMPFSpec(iPart2)) &
                * (FPInnerVelos(PartStatevMPFSpec(iPart2))%FP_RotVelo(iDir)**2)
        vMPF_oldEngSumRot = vMPF_oldEngSumRot + 0.5 * PartMPF(PartStatevMPFSpec(iPart)) &
                * (FPInnerVelos(PartStatevMPFSpec(iPart))%FP_RotVelo(iDir)**2)

        CALL RANDOM_NUMBER(ran1) 
        v_merge = (FPInnerVelos(PartStatevMPFSpec(iPart2))%FP_RotVelo(iDir) &
                - FPInnerVelos(PartStatevMPFSpec(iPart))%FP_RotVelo( iDir))
        FPInnerVelos(PartStatevMPFSpec(iPart2))%FP_RotVelo(iDir)= &
                FPInnerVelos(PartStatevMPFSpec(iPart))%FP_RotVelo(iDir) + v_merge*ran1
        FPInnerVelos(PartStatevMPFSpec(iPart))%FP_RotVelo( iDir) = &
                FPInnerVelos(PartStatevMPFSpec(iPart))%FP_RotVelo(iDir) + v_merge*(1.0-ran1)

        vMPF_oldEngSumRot = vMPF_oldEngSumRot - 0.5 * PartMPF(PartStatevMPFSpec(iPart2)) &
                * (FPInnerVelos(PartStatevMPFSpec(iPart2))%FP_RotVelo(iDir)**2)
        vMPF_oldEngSumRot = vMPF_oldEngSumRot - 0.5 * PartMPF(PartStatevMPFSpec(iPart)) &
                * (FPInnerVelos(PartStatevMPFSpec(iPart))%FP_RotVelo(iDir)**2)
        iLoop= iLoop + 1
        TempPartVelo(iPart,iDir)=FPInnerVelos(PartStatevMPFSpec(iPart))%FP_RotVelo( iDir)
        TempPartVelo(iPart2,iDir)=FPInnerVelos(PartStatevMPFSpec(iPart2))%FP_RotVelo( iDir)
        IF(iLoop.GT.100000) THEN
          Csquare=.true.
          RETURN       
        END IF
      END IF
    END DO
   ! SWRITE(*,*)'Loops for energy transformation needed: ', iLoop
  END IF

  CALL RANDOM_NUMBER(iRan)
  iPart = INT(NewPartNum * iRan +1)
  CALL RANDOM_NUMBER(iRan)
  iPart2 = INT(NewPartNum * iRan +1)
  DO WHILE(iPart2.EQ.iPart)
    CALL RANDOM_NUMBER(iRan)
    iPart2 = INT(NewPartNum * iRan +1)
  END DO
  CALL DoEnergyConservationFPInner(PartStatevMPFSpec(iPart),PartStatevMPFSpec(iPart2), &
            vMPF_oldEngSumVib, vMPF_oldEngSumRot, CSquare)

END SUBROUTINE SetNewDistrFPInner 
#endif


END MODULE MOD_part_MPFtools
