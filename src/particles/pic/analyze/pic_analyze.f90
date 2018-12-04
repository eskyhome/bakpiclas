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

MODULE MOD_PIC_Analyze
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
PRIVATE
!-----------------------------------------------------------------------------------------------------------------------------------
! GLOBAL VARIABLES 
!-----------------------------------------------------------------------------------------------------------------------------------
! Private Part ---------------------------------------------------------------------------------------------------------------------
! Public Part ----------------------------------------------------------------------------------------------------------------------
INTERFACE VerifyDepositedCharge
  MODULE PROCEDURE VerifyDepositedCharge
END INTERFACE

INTERFACE CalcDepositedCharge
  MODULE PROCEDURE CalcDepositedCharge
END INTERFACE

INTERFACE CalculateBRElectronsPerCell
  MODULE PROCEDURE CalculateBRElectronsPerCell
END INTERFACE


PUBLIC:: VerifyDepositedCharge, CalcDepositedCharge, CalculateBRElectronsPerCell
!===================================================================================================================================

CONTAINS

SUBROUTINE VerifyDepositedCharge() 
!===================================================================================================================================
! calcs the deposited chrages
!===================================================================================================================================
! MODULES
USE MOD_Globals
USE MOD_Preproc
USE MOD_Mesh_Vars,            ONLY:nElems, sJ
USE MOD_Particle_Vars,        ONLY:PDM, Species, PartSpecies ,PartMPF,usevMPF
USE MOD_Interpolation_Vars,   ONLY:wGP
USE MOD_Particle_Analyze_Vars,ONLY:ChargeCalcDone
#if defined(IMPA)
USE MOD_LinearSolver_Vars,    ONLY:ImplicitSource
#else
USE MOD_PICDepo_Vars,         ONLY:PartSource
#endif
#ifdef MPI
USE MOD_Particle_MPI_Vars,    ONLY:PartMPI
#endif /*MPI*/
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
INTEGER           :: iElem
INTEGER           :: i,j,k
REAL              :: J_N(1,0:PP_N,0:PP_N,0:PP_N)
REAL              :: Charge, ChargeLoc, PartCharge
#ifdef MPI
REAL              :: PartCharge_sum, Charge_sum
#endif
!===================================================================================================================================
SWRITE(UNIT_StdOut,'(132("-"))')
SWRITE(UNIT_stdOut,'(A)') ' PERFORMING CHARGE DEPOSITION PLAUSIBILITY CHECK...'

Charge=0.
DO iElem=1,nElems
  !--- Calculate and save volume of element iElem
  ChargeLoc=0. 
  J_N(1,0:PP_N,0:PP_N,0:PP_N)=1./sJ(:,:,:,iElem)
  DO k=0,PP_N; DO j=0,PP_N; DO i=0,PP_N
#if defined(IMPA)
    ChargeLoc = ChargeLoc + wGP(i)*wGP(j)*wGP(k) * ImplicitSource(4,i,j,k,iElem) * J_N(1,i,j,k)
#else
    ChargeLoc = ChargeLoc + wGP(i)*wGP(j)*wGP(k) * PartSource(4,i,j,k,iElem) * J_N(1,i,j,k)
#endif
  END DO; END DO; END DO
  Charge = Charge + ChargeLoc
END DO


PartCharge=0.
DO i=1,PDM%ParticleVecLength
  IF (PDM%ParticleInside(i)) THEN
    IF(usevMPF)THEN
      PartCharge = PartCharge + Species(PartSpecies(i))%ChargeIC * PartMPF(i)
    ELSE
      PartCharge = PartCharge + Species(PartSpecies(i))%ChargeIC * Species(PartSpecies(i))%MacroParticleFactor
    END IF
  END IF
END DO

#ifdef MPI
   CALL MPI_ALLREDUCE(PartCharge, PartCharge_sum, 1, MPI_DOUBLE_PRECISION, MPI_SUM, PartMPI%COMM, IERROR)
   CALL MPI_ALLREDUCE(Charge, Charge_sum, 1, MPI_DOUBLE_PRECISION, MPI_SUM, PartMPI%COMM, IERROR)
   PartCharge = PartCharge_sum
   Charge = Charge_sum
#endif
SWRITE(*,*) "On the grid deposited charge", Charge
SWRITE(*,*) "Charge by the particles:", PartCharge
SWRITE(*,*) "Absolute deposition error:", ABS(PartCharge-Charge)
SWRITE(*,*) "Relative deposition error in percent:", ABS(PartCharge-Charge)/PartCharge*100
SWRITE(UNIT_stdOut,'(A)')' CHARGE DEPOSITION PLAUSIBILITY CHECK DONE!'
SWRITE(UNIT_StdOut,'(132("-"))')
ChargeCalcDone = .TRUE.

END SUBROUTINE VerifyDepositedCharge


SUBROUTINE CalcDepositedCharge() 
!===================================================================================================================================
! Calculation of deposited charge and compute the absolute and relative error
!===================================================================================================================================
! MODULES
USE MOD_Globals
USE MOD_Preproc
USE MOD_Mesh_Vars,              ONLY:sJ
USE MOD_Particle_Vars,          ONLY:PDM, Species, PartSpecies, usevmpf, PartMPF
USE MOD_Interpolation_Vars,     ONLY:wGP
USE MOD_Particle_Analyze_Vars,  ONLY:PartCharge
USE MOD_TimeDisc_Vars,          ONLY:iter
#if defined(IMPA)
USE MOD_LinearSolver_Vars,      ONLY:ImplicitSource
#else
USE MOD_PICDepo_Vars,           ONLY:PartSource
#endif
USE MOD_Particle_MPI_Vars,      ONLY:PartMPI
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
INTEGER           :: iElem
INTEGER           :: i,j,k,iPart
REAL              :: J_N(1,0:PP_N,0:PP_N,0:PP_N)
REAL              :: Charge(2)
#ifdef MPI
REAL              :: RECBR(2)
#endif /*MPI*/
!===================================================================================================================================


! compute local charge
Charge=0.
PartCharge=0.
IF(iter.EQ.0) RETURN
DO iElem=1,PP_nElems
  ! compute the deposited charge
  J_N(1,0:PP_N,0:PP_N,0:PP_N)=1./sJ(:,:,:,iElem)
  DO k=0,PP_N; DO j=0,PP_N; DO i=0,PP_N
#if defined(IMPA)
#ifdef PP_HDG
    Charge(1) = Charge(1)+ wGP(i)*wGP(j)*wGP(k) * ImplicitSource(1,i,j,k,iElem) * J_N(1,i,j,k)
#else /* DG */
    Charge(1) = Charge(1)+ wGP(i)*wGP(j)*wGP(k) * ImplicitSource(4,i,j,k,iElem) * J_N(1,i,j,k)
#endif
#else
    Charge(1) = Charge(1)+ wGP(i)*wGP(j)*wGP(k) * PartSource(4,i,j,k,iElem) * J_N(1,i,j,k)
#endif
  END DO; END DO; END DO
END DO

! charge of all particles inside of domain
DO iPart=1,PDM%ParticleVecLength
  IF (.NOT.PDM%ParticleInside(iPart)) CYCLE
  IF(usevMPF)THEN
    Charge(2) = Charge(2) + Species(PartSpecies(iPart))%ChargeIC * PartMPF(iPart)
  ELSE
    Charge(2) = Charge(2) + Species(PartSpecies(iPart))%ChargeIC * Species(PartSpecies(iPart))%MacroParticleFactor
  END IF
END DO

! MPI Communication
#ifdef MPI
IF (PartMPI%MPIRoot) THEN
  CALL MPI_REDUCE(MPI_IN_PLACE,Charge , 2 , MPI_DOUBLE_PRECISION, MPI_SUM,0, PartMPI%COMM, IERROR)
ELSE ! no Root
  CALL MPI_REDUCE(Charge,RECBR  ,2,MPI_DOUBLE_PRECISION,MPI_SUM,0,PartMPI%COMM, IERROR)
END IF
#endif

IF (PartMPI%MPIRoot) THEN
  PartCharge(1)=Charge(1)
  ! absolute error
  PartCharge(2)=ABS(Charge(2)-Charge(1))
  ! relative error
  IF(ALMOSTZERO(Charge(2)))THEN
    PartCharge(3)=0.
  ELSE
    PartCharge(3)=ABS(Charge(2)-Charge(1))/Charge(2)
  END IF
END IF

END SUBROUTINE CalcDepositedCharge

SUBROUTINE CalculateBRElectronsPerCell(iElem,RegionID,ElectronNumberCell) 
!===================================================================================================================================
! calcs integrated (physical) number of BR electrons in cell
!===================================================================================================================================
! MODULES
USE MOD_Globals
USE MOD_Globals_Vars,         ONLY:ElementaryCharge
USE MOD_Preproc
USE MOD_Mesh_Vars,            ONLY:sJ
USE MOD_Interpolation_Vars,   ONLY:wGP
USE MOD_Particle_Mesh_Vars,   ONLY:GEO
USE MOD_Particle_Vars,        ONLY:RegionElectronRef
USE MOD_DG_Vars,              ONLY:U
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
INTEGER,INTENT(IN):: iElem, RegionID
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
REAL,INTENT(OUT)  :: ElectronNumberCell
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
INTEGER           :: i,j,k
REAL              :: J_N(1,0:PP_N,0:PP_N,0:PP_N)
REAL              :: source_e
!===================================================================================================================================
ElectronNumberCell=0.
J_N(1,0:PP_N,0:PP_N,0:PP_N)=1./sJ(:,:,:,iElem)
DO k=0,PP_N; DO j=0,PP_N; DO i=0,PP_N
#if (defined (PP_HDG) && (PP_nVar==1))
  source_e = U(1,i,j,k,iElem)-RegionElectronRef(2,RegionID)
#else
  CALL abort(&
__STAMP__&
,' CalculateBRElectronsPerCell only implemented for electrostatic HDG!')
#endif
  IF (source_e .LT. 0.) THEN
    source_e = RegionElectronRef(1,RegionID) &         !--- boltzmann relation (electrons as isothermal fluid!)
    * EXP( (source_e) / RegionElectronRef(3,RegionID) )
  ELSE
    source_e = RegionElectronRef(1,RegionID) &         !--- linearized boltzmann relation at positive exponent
    * (1. + ((source_e) / RegionElectronRef(3,RegionID)) )
  END IF
  ElectronNumberCell = ElectronNumberCell + wGP(i)*wGP(j)*wGP(k) * source_e * J_N(1,i,j,k)
END DO; END DO; END DO
ElectronNumberCell=ElectronNumberCell/ElementaryCharge

END SUBROUTINE CalculateBRElectronsPerCell


END MODULE MOD_PIC_Analyze
