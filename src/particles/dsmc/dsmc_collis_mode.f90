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

MODULE MOD_DSMC_Collis
!===================================================================================================================================
! Module including collisions, relaxation and reaction decision
!===================================================================================================================================
! MODULES
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
PRIVATE

INTERFACE DSMC_perform_collision
  MODULE PROCEDURE DSMC_perform_collision
END INTERFACE

!-----------------------------------------------------------------------------------------------------------------------------------
! GLOBAL VARIABLES 
!-----------------------------------------------------------------------------------------------------------------------------------
! Private Part ---------------------------------------------------------------------------------------------------------------------
! Public Part ----------------------------------------------------------------------------------------------------------------------
PUBLIC :: DSMC_perform_collision
!===================================================================================================================================

CONTAINS

SUBROUTINE DSMC_Elastic_Col(iPair, iElem)
!===================================================================================================================================
! Performs simple elastic collision (CollisMode = 1)
!===================================================================================================================================
! MODULES  
  USE MOD_DSMC_Vars,              ONLY : Coll_pData, CollInf, DSMC_RHS, PairE_vMPF
  USE MOD_Particle_Vars,          ONLY : PartSpecies, PartState, usevMPF, PartMPF
  USE MOD_Particle_Mesh_Vars,     ONLY : GEO
  USE MOD_vmpf_collision,         ONLY : vMPF_PostVelo
  USE MOD_part_tools,             ONLY : DiceUnitVector
! IMPLICIT VARIABLE HANDLING
  IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
  INTEGER, INTENT(IN)           :: iPair
  INTEGER, INTENT(IN)           :: iElem
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
  REAL                          :: FracMassCent1, FracMassCent2     ! mx/(mx+my)
  REAL                          :: VeloMx, VeloMy, VeloMz           ! center of mass velo
  REAL                          :: RanVelox, RanVeloy, RanVeloz     ! random relativ velo
  REAL                          :: RanVec(3)
!===================================================================================================================================

  FracMassCent1 = CollInf%FracMassCent(PartSpecies(Coll_pData(iPair)%iPart_p1), Coll_pData(iPair)%PairType)
  FracMassCent2 = CollInf%FracMassCent(PartSpecies(Coll_pData(iPair)%iPart_p2), Coll_pData(iPair)%PairType)
  
  !Calculation of velo from center of mass
  VeloMx = FracMassCent1 * PartState(Coll_pData(iPair)%iPart_p1, 4) &
         + FracMassCent2 * PartState(Coll_pData(iPair)%iPart_p2, 4)
  VeloMy = FracMassCent1 * PartState(Coll_pData(iPair)%iPart_p1, 5) &
         + FracMassCent2 * PartState(Coll_pData(iPair)%iPart_p2, 5)
  VeloMz = FracMassCent1 * PartState(Coll_pData(iPair)%iPart_p1, 6) &
         + FracMassCent2 * PartState(Coll_pData(iPair)%iPart_p2, 6)

  IF(usevMPF) THEN
    IF (iPair.EQ.PairE_vMPF(1)) THEN  
      Coll_pData(iPair)%CRela2 = Coll_pData(iPair)%CRela2 + 2 * GEO%DeltaEvMPF(iElem) &
                               / CollInf%MassRed(Coll_pData(iPair)%PairType) &
                               / PartMPF(PairE_vMPF(2))
    END IF
  END IF

  !calculate random vec
  RanVec(1:3) = DiceUnitVector()
  RanVelox = SQRT(Coll_pData(iPair)%CRela2) * RanVec(1)
  RanVeloy = SQRT(Coll_pData(iPair)%CRela2) * RanVec(2)
  RanVeloz = SQRT(Coll_pData(iPair)%CRela2) * RanVec(3)
  
 ! deltaV particle 1 
  DSMC_RHS(Coll_pData(iPair)%iPart_p1,1) = VeloMx + FracMassCent2*RanVelox &
          - PartState(Coll_pData(iPair)%iPart_p1, 4)
  DSMC_RHS(Coll_pData(iPair)%iPart_p1,2) = VeloMy + FracMassCent2*RanVeloy &
          - PartState(Coll_pData(iPair)%iPart_p1, 5)
  DSMC_RHS(Coll_pData(iPair)%iPart_p1,3) = VeloMz + FracMassCent2*RanVeloz &
          - PartState(Coll_pData(iPair)%iPart_p1, 6)
 ! deltaV particle 2
  DSMC_RHS(Coll_pData(iPair)%iPart_p2,1) = VeloMx - FracMassCent1*RanVelox &
          - PartState(Coll_pData(iPair)%iPart_p2, 4)
  DSMC_RHS(Coll_pData(iPair)%iPart_p2,2) = VeloMy - FracMassCent1*RanVeloy &
          - PartState(Coll_pData(iPair)%iPart_p2, 5)
  DSMC_RHS(Coll_pData(iPair)%iPart_p2,3) = VeloMz - FracMassCent1*RanVeloz &
          - PartState(Coll_pData(iPair)%iPart_p2, 6)

  IF(usevMPF) CALL vMPF_PostVelo(iPair, iElem)

END SUBROUTINE DSMC_Elastic_Col

SUBROUTINE DSMC_Scat_Col(iPair)
!===================================================================================================================================
! Performs a collision with the possibility of a CEX. In the calculation of the new particle velocities a scattering angle is used,
! which is interpolated from a lookup table.
!===================================================================================================================================
! MODULES
  USE MOD_DSMC_Vars,              ONLY : Coll_pData, CollInf, DSMC_RHS, TLU_Data, ChemReac
  USE MOD_Particle_Vars,          ONLY : PartSpecies, PartState
  USE MOD_vmpf_collision,         ONLY : vMPF_PostVelo
  USE MOD_part_tools,             ONLY : DiceUnitVector
  USE MOD_DSMC_ChemReact,         ONLY : simpleCEX, simpleMEX

! IMPLICIT VARIABLE HANDLING
  IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
  INTEGER, INTENT(IN)           :: iPair
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
  REAL                          :: FracMassCent1, FracMassCent2                ! mx/(mx+my)
  REAL                          :: VeloMx, VeloMy, VeloMz                      ! center of mass velo
  REAL                          :: CRelax, CRelay, CRelaz                      ! pre-collisional relativ velo
  REAL                          :: CRelaxN, CRelayN, CRelazN                   ! post-collisional relativ velo
  REAL                          :: b, bmax                                     ! impact parameters
  REAL                          :: Ekin
  REAL                          :: ScatAngle, RotAngle                         ! scattering and rotational angle
  REAL                          :: sigma_el, sigma_tot                         ! cross-sections
  REAL                          :: P_CEX                                       ! charge exchange probability
  INTEGER                       :: iReac
  REAL                          :: uRan2, uRan3, uRanRot, uRanVHS
  REAL                          :: Pi, aEL, bEL, aCEX, bCEX
!===================================================================================================================================
  Pi = ACOS(-1.0)

  aCEX = ChemReac%CEXa(ChemReac%ReactNum(PartSpecies(Coll_pData(iPair)%iPart_p1),PartSpecies(Coll_pData(iPair)%iPart_p2),1))
  bCEX = ChemReac%CEXb(ChemReac%ReactNum(PartSpecies(Coll_pData(iPair)%iPart_p1),PartSpecies(Coll_pData(iPair)%iPart_p2),1))
  aEL  = ChemReac%ELa(ChemReac%ReactNum(PartSpecies(Coll_pData(iPair)%iPart_p1),PartSpecies(Coll_pData(iPair)%iPart_p2),1))
  bEL  = ChemReac%ELb(ChemReac%ReactNum(PartSpecies(Coll_pData(iPair)%iPart_p1),PartSpecies(Coll_pData(iPair)%iPart_p2),1))
  ! Decision if scattering angle is greater than 1 degree and should be calculated

  sigma_el  = bEL + aEL*0.5 * LOG10(Coll_pData(iPair)%CRela2)

  sigma_tot = ((aCEX+0.5*aEL)*0.5*LOG10(Coll_pData(iPair)%CRela2)+bCEX+0.5*bEL)

  CALL RANDOM_NUMBER(uRan2)
  
IF ((sigma_el/sigma_tot).GT.uRan2) THEN
    ! Calculation of relative veloocities
    CRelax = PartState(Coll_pData(iPair)%iPart_p1, 4) - PartState(Coll_pData(iPair)%iPart_p2, 4)
    CRelay = PartState(Coll_pData(iPair)%iPart_p1, 5) - PartState(Coll_pData(iPair)%iPart_p2, 5)
    CRelaz = PartState(Coll_pData(iPair)%iPart_p1, 6) - PartState(Coll_pData(iPair)%iPart_p2, 6)
    
    FracMassCent1 = CollInf%FracMassCent(PartSpecies(Coll_pData(iPair)%iPart_p1), Coll_pData(iPair)%PairType)
    FracMassCent2 = CollInf%FracMassCent(PartSpecies(Coll_pData(iPair)%iPart_p2), Coll_pData(iPair)%PairType)
  
    ! Calculation of velo from center of mass
    VeloMx = FracMassCent1 * PartState(Coll_pData(iPair)%iPart_p1, 4) &
      + FracMassCent2 * PartState(Coll_pData(iPair)%iPart_p2, 4)
    VeloMy = FracMassCent1 * PartState(Coll_pData(iPair)%iPart_p1, 5) &
      + FracMassCent2 * PartState(Coll_pData(iPair)%iPart_p2, 5)
    VeloMz = FracMassCent1 * PartState(Coll_pData(iPair)%iPart_p1, 6) &
      + FracMassCent2 * PartState(Coll_pData(iPair)%iPart_p2, 6)

    ! Calculation of impact parameter b
    bmax = SQRT(sigma_el/Pi)
    b = bmax * SQRT(uRan2)
    Ekin = (0.5*CollInf%MassRed(Coll_pData(iPair)%PairType)*Coll_pData(iPair)%CRela2/(1.6021766208E-19))
    
    
    ! Determination of scattering angle by interpolation from a lookup table
    ! Check if Collision Energy is below the threshold of table
    IF (Ekin.LT.TLU_Data%Emin) THEN
      ! Isotropic scattering
      CALL RANDOM_NUMBER(uRanVHS)
      ScatAngle = 2*ACOS(SQRT(uRanVHS))
    ELSE
      ! scattering correspnding to table lookup
      CALL TLU_Scat_Interpol(Ekin,b,ScatAngle)
    END IF

    ! Determination of rotational angle by random number
    CALL RANDOM_NUMBER(uRanRot)
    RotAngle = uRanRot * 2 * Pi

    ! Calculation of post-collision relative velocities in CM frame
    CRelaxN = COS(ScatAngle)*CRelax + SIN(ScatAngle)*SIN(RotAngle)*(CRelay**2+CRelaz**2)**0.5
    CRelayN = COS(ScatAngle)*CRelay &
     +SIN(ScatAngle)*(SQRT(Coll_pData(ipair)%CRela2)*CRelaz*COS(RotAngle)-CRelax*CRelay*SIN(RotAngle))/(CRelay**2+CRelaz**2)**0.5
    CRelazN = COS(ScatAngle)*CRelaz &
     -SIN(ScatAngle)*(SQRT(Coll_pData(ipair)%CRela2)*CRelay*COS(RotAngle)+CRelax*CRelaz*SIN(RotAngle))/(CRelay**2+CRelaz**2)**0.5

    ! Transformation in LAB frame
    ! deltaV particle 1
    DSMC_RHS(Coll_pData(iPair)%iPart_p1,1) = VeloMx + FracMassCent2*CRelaxN &
      - PartState(Coll_pData(iPair)%iPart_p1, 4)
    DSMC_RHS(Coll_pData(iPair)%iPart_p1,2) = VeloMy + FracMassCent2*CRelayN &
      - PartState(Coll_pData(iPair)%iPart_p1, 5)
    DSMC_RHS(Coll_pData(iPair)%iPart_p1,3) = VeloMz + FracMassCent2*CRelazN &
      - PartState(Coll_pData(iPair)%iPart_p1, 6)
    ! deltaV particle 2
    DSMC_RHS(Coll_pData(iPair)%iPart_p2,1) = VeloMx - FracMassCent1*CRelaxN &
      - PartState(Coll_pData(iPair)%iPart_p2, 4)
    DSMC_RHS(Coll_pData(iPair)%iPart_p2,2) = VeloMy - FracMassCent1*CRelayN &
      - PartState(Coll_pData(iPair)%iPart_p2, 5)
    DSMC_RHS(Coll_pData(iPair)%iPart_p2,3) = VeloMz - FracMassCent1*CRelazN &
      - PartState(Coll_pData(iPair)%iPart_p2, 6)

    ! Decision concerning CEX 
    P_CEX = 0.5
    CALL RANDOM_NUMBER(uRan3)
    iReac    = ChemReac%ReactNum(PartSpecies(Coll_pData(iPair)%iPart_p1), PartSpecies(Coll_pData(iPair)%iPart_p2), 1)
    IF (P_CEX.GT.uRan3) THEN
      CALL simpleCEX(iReac, iPair, resetRHS_opt=.FALSE.)
    ELSE
      CALL simpleMEX(iReac, iPair)
    END IF
    
  ELSE
    ! Perform CEX and leave velocity vectors alone otherwise
    ! CEX
    iReac    = ChemReac%ReactNum(PartSpecies(Coll_pData(iPair)%iPart_p1), PartSpecies(Coll_pData(iPair)%iPart_p2), 1)
    CALL simpleCEX(iReac, iPair)
    
  END IF

END SUBROUTINE DSMC_Scat_Col

SUBROUTINE TLU_Scat_Interpol(E_p,b_p,ScatAngle)
!===================================================================================================================================
! Interpolates ScatAngle from a lookup table
!===================================================================================================================================
! MODULES
  USE MOD_Globals
  USE MOD_DSMC_Vars,              ONLY :  TLU_Data 
! IMPLICIT VARIABLE HANDLING
  IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
  REAL, INTENT (IN)              :: E_p, b_p          ! E_p has to have the unit eV
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
  REAL, INTENT (OUT)             :: ScatAngle
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
  REAL                           :: i_f_jp1, j_f, i_f_j
  INTEGER                        :: I_j,I_jp1,J
  REAL                           :: w_i_j,w_i_jp1,w_j
  INTEGER                        :: szb,szE
  REAL                           :: chi_b_p_E_j,chi_b_p_E_jp1,chi_b_p_e_p
!===================================================================================================================================
  IF (E_p.GT.TLU_Data%Emax) THEN 
    CALL abort(__STAMP__,&
        'Collis_mode - Error in TLU_Scat_Interpol: E_p GT Emax')
  END IF
  !write (*,*) (E_p-TLU_Data%Emin), TLU_Data%deltaE
  j_f = (E_p-TLU_Data%Emin)/TLU_Data%deltaE 
  J = FLOOR(j_f)
  w_j = j_f - J
  J = J + 1                                ! Fitting of the indices for the use in FORTRAN matrix
  !write (*,*) j_f, J, w_j
  i_f_j   = ABS((b_p)/TLU_Data%deltabj(J))
  i_f_jp1 = ABS((b_p)/TLU_Data%deltabj(J+1))
  I_j     = FLOOR(i_f_j)
  I_jp1   = FLOOR(i_f_jp1)

  w_i_j = i_f_j - I_j
  w_i_jp1 = i_f_jp1-I_jp1
  
  I_j     = FLOOR(i_f_j)+1                ! Fitting of the indices for the use in FORTRAN matrix
  I_jp1   = FLOOR(i_f_jp1)+1              !
  
  szE = SIZE(TLU_Data%Chitable,dim=1)   !SIZE(delta_b_j)
  szB = SIZE(TLU_Data%Chitable,dim=2)



  IF ((I_jp1+1).GE.szB) THEN
    chi_b_p_E_j   = (1 - w_i_j) * TLU_Data%Chitable(J,szB)       !+ w_i_j   * TLU_Data%Chitable(J,szB)
    chi_b_p_E_jp1 = (1-w_i_jp1) * TLU_Data%Chitable((J+1),szB)
    chi_b_p_E_p   = (1-w_j)     * chi_b_p_E_j               + w_j     * chi_b_p_E_jp1
  ELSE
    chi_b_p_E_j   = (1 - w_i_j) * TLU_Data%Chitable(J,I_j)       + w_i_j   * TLU_Data%Chitable(J,I_jp1)
    chi_b_p_E_jp1 = (1-w_i_jp1) * TLU_Data%Chitable((J+1),I_jp1) + w_i_jp1 * TLU_Data%Chitable((J+1),(I_jp1+1))
    chi_b_p_E_p   = (1-w_j)     * chi_b_p_E_j               + w_j     * chi_b_p_E_jp1
  END IF
  ScatAngle = chi_b_p_E_p
  
  !write(*,*) (ScatAngle/ACOS(-1.0)*180), I_jp1, szB
END SUBROUTINE TLU_Scat_Interpol

SUBROUTINE DSMC_Relax_Col_LauxTSHO(iPair, iElem)
!===================================================================================================================================
! Performs inelastic collisions with energy exchange (CollisMode = 2/3), allows the relaxation of both collision partners
! Vibrational (of the relaxing molecule), rotational and relative translational energy (of both molecules) is redistributed (V-R-T)
!===================================================================================================================================
! MODULES  
  USE MOD_DSMC_Vars,              ONLY : Coll_pData, CollInf, DSMC_RHS, DSMC, &
                                         SpecDSMC, PartStateIntEn, PairE_vMPF!, Debug_Energy
  USE MOD_Globals_Vars,           ONLY : BoltzmannConst
  USE MOD_Particle_Vars,          ONLY : PartSpecies, PartState, usevMPF, PartMPF
  USE MOD_vmpf_collision,         ONLY : vMPF_PostVelo 
  USE MOD_Particle_Mesh_Vars,     ONLY : GEO
  USE MOD_DSMC_ElectronicModel,   ONLY : ElectronicEnergyExchange, TVEEnergyExchange
  USE MOD_DSMC_PolyAtomicModel,   ONLY : DSMC_RotRelaxPoly, DSMC_VibRelaxPoly
  USE MOD_DSMC_Relaxation,        ONLY : DSMC_VibRelaxDiatomic
  USE MOD_part_tools,             ONLY : DiceUnitVector
! IMPLICIT VARIABLE HANDLING
  IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
  INTEGER, INTENT(IN)           :: iPair
  INTEGER, INTENT(IN)           :: iElem
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
  REAL                          :: FracMassCent1, FracMassCent2     ! mx/(mx+my)
  REAL                          :: VeloMx, VeloMy, VeloMz           ! center of mass velo
  REAL                          :: RanVelox, RanVeloy, RanVeloz     ! random relativ velo
  REAL (KIND=8)                 :: iRan
  LOGICAL                       :: DoRot1, DoRot2, DoVib1, DoVib2   ! Check whether rot or vib relax is performed
  REAL (KIND=8)                 :: Xi_rel, Xi, FakXi                ! Factors of DOF
  REAL                          :: RanVec(3)                        ! Max. Quantum Number
  REAL                          :: PartStateIntEnTemp, Phi!, DeltaPartStateIntEn ! temp. var for inertial energy (needed for vMPF)
  ! variables for electronic level relaxation and transition
  LOGICAL                       :: DoElec1, DoElec2
!REAL::evor, enach
!===================================================================================================================================

  DoRot1  = .FALSE.
  DoRot2  = .FALSE.
  DoVib1  = .FALSE.
  DoVib2  = .FALSE.
  DoElec1 = .FALSE.
  DoElec2 = .FALSE.
  
  Xi_rel = 2*(2. - SpecDSMC(PartSpecies(Coll_pData(iPair)%iPart_p1))%omegaVHS)
    ! DOF of relative motion in VHS model, only for one omega!!
 
  Coll_pData(iPair)%Ec = 0.5 * CollInf%MassRed(Coll_pData(iPair)%PairType)*Coll_pData(iPair)%CRela2

!  IF((usevMPF).AND.(iPair.EQ.PairE_vMPF(1))) THEN         ! adding energy lost due to vMPF
!    Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec + GEO%DeltaEvMPF(iElem) / PartMPF(PairE_vMPF(2))
!    GEO%DeltaEvMPF(iElem) = 0.0
!  END IF

  Xi = Xi_rel !Xi are all DOF in the collision

!--------------------------------------------------------------------------------------------------!
! Decision if Rotation, Vibration and Electronic Relaxation of particles is performed
!--------------------------------------------------------------------------------------------------!

  CALL RANDOM_NUMBER(iRan)
  IF((SpecDSMC(PartSpecies(Coll_pData(iPair)%iPart_p1))%InterID.EQ.2) &
    .OR.(SpecDSMC(PartSpecies(Coll_pData(iPair)%iPart_p1))%InterID.EQ.20)) THEN
    IF(SpecDSMC(PartSpecies(Coll_pData(iPair)%iPart_p1))%RotRelaxProb.GT.iRan) THEN
      DoRot1 = .TRUE.
      Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec + PartStateIntEn(Coll_pData(iPair)%iPart_p1,2) ! adding rot energy to coll energy
      Xi = Xi + SpecDSMC(PartSpecies(Coll_pData(iPair)%iPart_p1))%Xi_Rot
      IF(SpecDSMC(PartSpecies(Coll_pData(iPair)%iPart_p1))%VibRelaxProb.GT.iRan) DoVib1 = .TRUE.
    END IF
  END IF
  IF ( DSMC%ElectronicModel ) THEN
    ! step as TRUE
    CALL RANDOM_NUMBER(iRan)
    IF ( SpecDSMC(PartSpecies(Coll_pData(iPair)%iPart_p1))%InterID .ne. 4 ) THEN
      IF ( SpecDSMC(PartSpecies(Coll_pData(iPair)%iPart_p1))%ElecRelaxProb .GT. iRan ) THEN
        DoElec1 = .TRUE.
      END IF
    END IF
  END IF

  CALL RANDOM_NUMBER(iRan)
  IF((SpecDSMC(PartSpecies(Coll_pData(iPair)%iPart_p2))%InterID.EQ.2) &
    .OR.(SpecDSMC(PartSpecies(Coll_pData(iPair)%iPart_p2))%InterID.EQ.20)) THEN
    IF(SpecDSMC(PartSpecies(Coll_pData(iPair)%iPart_p2))%RotRelaxProb.GT.iRan) THEN
      DoRot2 = .TRUE.
      Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec + PartStateIntEn(Coll_pData(iPair)%iPart_p2,2) ! adding rot energy to coll energy
      Xi = Xi + SpecDSMC(PartSpecies(Coll_pData(iPair)%iPart_p2))%Xi_Rot
      IF(SpecDSMC(PartSpecies(Coll_pData(iPair)%iPart_p2))%VibRelaxProb.GT.iRan) DoVib2 = .TRUE.
    END IF
  END IF
  IF ( DSMC%ElectronicModel ) THEN
    ! step as TRUE
    CALL RANDOM_NUMBER(iRan)
    IF (SpecDSMC(PartSpecies(Coll_pData(iPair)%iPart_p2))%InterID.NE.4) THEN
      IF (SpecDSMC(PartSpecies(Coll_pData(iPair)%iPart_p2))%ElecRelaxProb.GT.iRan) THEN
        DoElec2 = .TRUE.
      END IF
    END IF
  END IF

  FakXi = 0.5*Xi  - 1  ! exponent factor of DOF, substitute of Xi_c - Xi_vib, laux diss page 40

!--------------------------------------------------------------------------------------------------!
! Electronic Relaxation / Transition
!--------------------------------------------------------------------------------------------------!
IF (DSMC%DoTEVRRelaxation) THEN
  IF(.NOT.SpecDSMC(PartSpecies(Coll_pData(iPair)%iPart_p1))%PolyatomicMol) THEN
    IF(DoElec1.AND.DoVib1) THEN
      Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec + PartStateIntEn(Coll_pData(iPair)%iPart_p1,3)  &
                           +    PartStateIntEn(Coll_pData(iPair)%iPart_p1,1)
#if (PP_TimeDiscMethod == 42)
      CALL TVEEnergyExchange(Coll_pData(iPair)%Ec,Coll_pData(iPair)%iPart_p1,FakXi,Coll_pData(iPair)%iPart_p2)
#else
      CALL TVEEnergyExchange(Coll_pData(iPair)%Ec,Coll_pData(iPair)%iPart_p1,FakXi)
#endif
      Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec - PartStateIntEn(Coll_pData(iPair)%iPart_p1,3)  &
                           -    PartStateIntEn(Coll_pData(iPair)%iPart_p1,1)
      DoElec1=.false.
      DoVib1=.false.
    END IF
  END IF

  IF(.NOT.SpecDSMC(PartSpecies(Coll_pData(iPair)%iPart_p2))%PolyatomicMol) THEN
    IF(DoElec2.AND.DoVib2) THEN
      Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec + PartStateIntEn(Coll_pData(iPair)%iPart_p2,3)  &
                           +    PartStateIntEn(Coll_pData(iPair)%iPart_p2,1)
#if (PP_TimeDiscMethod == 42)
      CALL TVEEnergyExchange(Coll_pData(iPair)%Ec,Coll_pData(iPair)%iPart_p2,FakXi,Coll_pData(iPair)%iPart_p1)
#else
      CALL TVEEnergyExchange(Coll_pData(iPair)%Ec,Coll_pData(iPair)%iPart_p2,FakXi)
#endif
      Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec - PartStateIntEn(Coll_pData(iPair)%iPart_p2,3)  &
                           -    PartStateIntEn(Coll_pData(iPair)%iPart_p2,1)
      DoElec2=.false.
      DoVib2=.false.
    END IF
  END IF
END IF

  ! Relaxation of first particle
  IF ( DoElec1 ) THEN
    ! calculate energy for electronic relaxation of particle 1
    Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec + PartStateIntEn(Coll_pData(iPair)%iPart_p1,3)
#if (PP_TimeDiscMethod == 42)
    CALL ElectronicEnergyExchange(iPair,Coll_pData(iPair)%iPart_p1,FakXi,Coll_pData(iPair)%iPart_p2)
#else
    IF (usevMPF) THEN
      CALL ElectronicEnergyExchange(iPair,Coll_pData(iPair)%iPart_p1,FakXi,Coll_pData(iPair)%iPart_p2,iElem)
    ELSE
      CALL ElectronicEnergyExchange(iPair,Coll_pData(iPair)%iPart_p1,FakXi )
    END IF
#endif
    Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec - PartStateIntEn(Coll_pData(iPair)%iPart_p1,3)
  END IF
  ! Electronic relaxation of second particle
  IF ( DoElec2 ) THEN
    ! calculate energy for electronic relaxation of particle 1
    Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec + PartStateIntEn(Coll_pData(iPair)%iPart_p2,3)
#if (PP_TimeDiscMethod == 42)
    CALL ElectronicEnergyExchange(iPair,Coll_pData(iPair)%iPart_p2,FakXi,Coll_pData(iPair)%iPart_p1)
#else
    IF (usevMPF) THEN
      CALL ElectronicEnergyExchange(iPair,Coll_pData(iPair)%iPart_p2,FakXi,Coll_pData(iPair)%iPart_p1,iElem)
    ELSE
      CALL ElectronicEnergyExchange(iPair,Coll_pData(iPair)%iPart_p2,FakXi )
    END IF
#endif
    Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec - PartStateIntEn(Coll_pData(iPair)%iPart_p2,3)
  END IF

#if (PP_TimeDiscMethod==42)
  ! for TimeDisc 42 & only transition counting: prohibit relaxation and energy exchange
  IF (.NOT.DSMC%ReservoirSimuRate) THEN
#endif


!--------------------------------------------------------------------------------------------------!
! Vibrational Relaxation
!--------------------------------------------------------------------------------------------------!

  IF(DoVib1) THEN
    Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec + PartStateIntEn(Coll_pData(iPair)%iPart_p1,1)
    IF(SpecDSMC(PartSpecies(Coll_pData(iPair)%iPart_p1))%PolyatomicMol) THEN
      CALL DSMC_VibRelaxPoly(iPair, Coll_pData(iPair)%iPart_p1,FakXi)
    ELSE
      CALL DSMC_VibRelaxDiatomic(iPair, Coll_pData(iPair)%iPart_p1,FakXi)
    END IF
    Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec - PartStateIntEn(Coll_pData(iPair)%iPart_p1,1)
  END IF

  IF(DoVib2) THEN
    Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec + PartStateIntEn(Coll_pData(iPair)%iPart_p2,1)
    IF(SpecDSMC(PartSpecies(Coll_pData(iPair)%iPart_p2))%PolyatomicMol) THEN
      CALL DSMC_VibRelaxPoly(iPair, Coll_pData(iPair)%iPart_p2,FakXi)
    ELSE
      CALL DSMC_VibRelaxDiatomic(iPair, Coll_pData(iPair)%iPart_p2,FakXi)
    END IF
    Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec - PartStateIntEn(Coll_pData(iPair)%iPart_p2,1)
  END IF

!--------------------------------------------------------------------------------------------------! 
! Rotational Relaxation
!--------------------------------------------------------------------------------------------------! 
  IF(DoRot1) THEN
    IF(SpecDSMC(PartSpecies(Coll_pData(iPair)%iPart_p1))%PolyatomicMol.AND. &
        (SpecDSMC(PartSpecies(Coll_pData(iPair)%iPart_p1))%Xi_Rot.EQ.3)) THEN
      FakXi = FakXi - 0.5*SpecDSMC(PartSpecies(Coll_pData(iPair)%iPart_p1))%Xi_Rot
      CALL DSMC_RotRelaxPoly(iPair, Coll_pData(iPair)%iPart_p1, FakXi)      
      Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec - PartStateIntEn(Coll_pData(iPair)%iPart_p1,2)
    ELSE
      CALL RANDOM_NUMBER(iRan)
      IF (usevMPF) THEN
        IF (PartMPF(Coll_pData(iPair)%iPart_p1).GT.PartMPF(Coll_pData(iPair)%iPart_p2)) THEN
          Phi = PartMPF(Coll_pData(iPair)%iPart_p2) / PartMPF(Coll_pData(iPair)%iPart_p1)
          PartStateIntEnTemp = Coll_pData(iPair)%Ec * (1.0 - iRan**(1.0/FakXi))
          Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec - PartStateIntEnTemp
          FakXi = FakXi - 0.5*SpecDSMC(PartSpecies(Coll_pData(iPair)%iPart_p1))%Xi_Rot
          PartStateIntEn(Coll_pData(iPair)%iPart_p1,2) = (1-Phi) * PartStateIntEn(Coll_pData(iPair)%iPart_p1,2) &
                                                       + Phi * PartStateIntEnTemp
        END IF
      ELSE
        PartStateIntEn(Coll_pData(iPair)%iPart_p1,2) = Coll_pData(iPair)%Ec * (1.0 - iRan**(1.0/FakXi))
        Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec - PartStateIntEn(Coll_pData(iPair)%iPart_p1,2)
        FakXi = FakXi - 0.5*SpecDSMC(PartSpecies(Coll_pData(iPair)%iPart_p1))%Xi_Rot
      END IF
    END IF
  END IF

  IF(DoRot2) THEN
    IF(SpecDSMC(PartSpecies(Coll_pData(iPair)%iPart_p2))%PolyatomicMol.AND. &
        (SpecDSMC(PartSpecies(Coll_pData(iPair)%iPart_p2))%Xi_Rot.EQ.3)) THEN
      FakXi = FakXi - 0.5*SpecDSMC(PartSpecies(Coll_pData(iPair)%iPart_p2))%Xi_Rot
      CALL DSMC_RotRelaxPoly(iPair, Coll_pData(iPair)%iPart_p2, FakXi)
      Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec - PartStateIntEn(Coll_pData(iPair)%iPart_p2,2)
    ELSE
      CALL RANDOM_NUMBER(iRan)
      IF (usevMPF) THEN
        IF (PartMPF(Coll_pData(iPair)%iPart_p2).GT.PartMPF(Coll_pData(iPair)%iPart_p1)) THEN
          Phi = PartMPF(Coll_pData(iPair)%iPart_p1) / PartMPF(Coll_pData(iPair)%iPart_p2)
          PartStateIntEnTemp = Coll_pData(iPair)%Ec * (1.0 - iRan**(1.0/FakXi))
          Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec - PartStateIntEnTemp
          PartStateIntEn(Coll_pData(iPair)%iPart_p2,2) = (1-Phi) * PartStateIntEn(Coll_pData(iPair)%iPart_p2,2) &
                                                       + Phi * PartStateIntEnTemp
        END IF
      ELSE
        PartStateIntEn(Coll_pData(iPair)%iPart_p2,2) = Coll_pData(iPair)%Ec * (1.0 - iRan**(1.0/FakXi))
        Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec - PartStateIntEn(Coll_pData(iPair)%iPart_p2,2)
      END IF
    END IF
  END IF

!--------------------------------------------------------------------------------------------------!
! Calculation of new particle velocities
!--------------------------------------------------------------------------------------------------!

  IF(usevMPF) THEN
    IF (iPair.EQ.PairE_vMPF(1)) THEN         ! adding energy lost due to vMPF
      Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec + GEO%DeltaEvMPF(iElem) / PartMPF(PairE_vMPF(2))
      GEO%DeltaEvMPF(iElem) = 0.0
    END IF
  END IF

  FracMassCent1 = CollInf%FracMassCent(PartSpecies(Coll_pData(iPair)%iPart_p1), Coll_pData(iPair)%PairType)
  FracMassCent2 = CollInf%FracMassCent(PartSpecies(Coll_pData(iPair)%iPart_p2), Coll_pData(iPair)%PairType)

  !Calculation of velo from center of mass
  VeloMx = FracMassCent1 * PartState(Coll_pData(iPair)%iPart_p1, 4) &
         + FracMassCent2 * PartState(Coll_pData(iPair)%iPart_p2, 4)
  VeloMy = FracMassCent1 * PartState(Coll_pData(iPair)%iPart_p1, 5) &
         + FracMassCent2 * PartState(Coll_pData(iPair)%iPart_p2, 5)
  VeloMz = FracMassCent1 * PartState(Coll_pData(iPair)%iPart_p1, 6) &
         + FracMassCent2 * PartState(Coll_pData(iPair)%iPart_p2, 6)

  !calculate random vec and new squared velocities
  Coll_pData(iPair)%CRela2 = 2 * Coll_pData(iPair)%Ec/CollInf%MassRed(Coll_pData(iPair)%PairType)
  RanVec(1:3) = DiceUnitVector()

  RanVelox = SQRT(Coll_pData(iPair)%CRela2) * RanVec(1)
  RanVeloy = SQRT(Coll_pData(iPair)%CRela2) * RanVec(2)
  RanVeloz = SQRT(Coll_pData(iPair)%CRela2) * RanVec(3)

  ! deltaV particle 1
  DSMC_RHS(Coll_pData(iPair)%iPart_p1,1) = VeloMx + FracMassCent2*RanVelox &
          - PartState(Coll_pData(iPair)%iPart_p1, 4)
  DSMC_RHS(Coll_pData(iPair)%iPart_p1,2) = VeloMy + FracMassCent2*RanVeloy &
          - PartState(Coll_pData(iPair)%iPart_p1, 5)
  DSMC_RHS(Coll_pData(iPair)%iPart_p1,3) = VeloMz + FracMassCent2*RanVeloz &
          - PartState(Coll_pData(iPair)%iPart_p1, 6)
 ! deltaV particle 2
  DSMC_RHS(Coll_pData(iPair)%iPart_p2,1) = VeloMx - FracMassCent1*RanVelox &
          - PartState(Coll_pData(iPair)%iPart_p2, 4)
  DSMC_RHS(Coll_pData(iPair)%iPart_p2,2) = VeloMy - FracMassCent1*RanVeloy &
          - PartState(Coll_pData(iPair)%iPart_p2, 5)
  DSMC_RHS(Coll_pData(iPair)%iPart_p2,3) = VeloMz - FracMassCent1*RanVeloz &
          - PartState(Coll_pData(iPair)%iPart_p2, 6)

  IF(usevMPF) CALL vMPF_PostVelo(iPair, iElem)

#if (PP_TimeDiscMethod==42)
  ! for TimeDisc 42 & only transition counting: prohibit relaxation and energy exchange
  END IF
#endif

END SUBROUTINE DSMC_Relax_Col_LauxTSHO


SUBROUTINE DSMC_Relax_Col_Gimelshein(iPair, iElem)
!===================================================================================================================================
! Performs inelastic collisions with energy exchange (CollisMode = 2/3)
! Selection procedure according to Gimelshein et al. (Physics of Fluids, V 14, No 12, 2002: 'Vibrational Relaxation rates in the 
! DSMC Method') For further understanding see Zhang, Schwarzentruber, Physics of Fluids, V25, 2013: 'inelastic collision selection
! procedures for DSMC calculation of gas mixtures')
!===================================================================================================================================
! MODULES  
  USE MOD_Globals,                ONLY : Abort
  USE MOD_Globals_Vars,           ONLY : BoltzmannConst
  USE MOD_DSMC_Vars,              ONLY : Coll_pData, CollInf, DSMC_RHS, DSMC, PolyatomMolDSMC, VibQuantsPar, &
                                         SpecDSMC, PartStateIntEn, PairE_vMPF
  USE MOD_Particle_Vars,          ONLY : PartSpecies, PartState, usevMPF, PartMPF
  USE MOD_Particle_Mesh_Vars,     ONLY : GEO
  USE MOD_vmpf_collision,         ONLY : vMPF_PostVelo 
  USE MOD_DSMC_ElectronicModel,   ONLY : ElectronicEnergyExchange, TVEEnergyExchange
  USE MOD_DSMC_PolyAtomicModel,   ONLY : DSMC_RotRelaxPoly, DSMC_VibRelaxPoly
  USE MOD_DSMC_Relaxation,        ONLY : DSMC_VibRelaxDiatomic
  USE MOD_part_tools,             ONLY : DiceUnitVector
! IMPLICIT VARIABLE HANDLING
  IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
  INTEGER, INTENT(IN)           :: iPair
  INTEGER, INTENT(IN)           :: iElem
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
  REAL                          :: FracMassCent1, FracMassCent2                 ! mx/(mx+my)
  REAL                          :: VeloMx, VeloMy, VeloMz                       ! center of mass velo
  REAL                          :: RanVelox, RanVeloy, RanVeloz                 ! random relativ velo
  INTEGER                       :: iSpec, jSpec, iDOF, iPolyatMole, DOFRelax
  REAL (KIND=8)                 :: iRan
  LOGICAL                       :: DoRot1, DoRot2, DoVib1, DoVib2               ! Check whether rot or vib relax is performed
  REAL (KIND=8)                 :: FakXi, Xi_rel                                ! Factors of DOF
  INTEGER                       :: iQuaMax, iQua                                ! Quantum Numbers
  REAL                          :: MaxColQua, RanVec(3)                         ! Max. Quantum Number
  REAL                          :: PartStateIntEnTemp, Phi!, DeltaPartStateIntEn ! temp. var for inertial energy (needed for vMPF)
  REAL                          :: ProbFrac1, ProbFrac2, ProbFrac3, ProbFrac4   ! probability-fractions according to Zhang
  REAL                          :: ProbRot1, ProbRot2, ProbVib1, ProbVib2       ! probabilities for rot-/vib-relax for part 1/2
  REAL                          :: BLCorrFact, ProbRotMax1, ProbRotMax2         ! Correction factor for BL-redistribution of energy
  REAL                          :: ProbVibMax1, ProbVibMax2                     ! according to Zhang (see paper, NDD-RotRelax-Model)

!===================================================================================================================================

  ! set some initial values
  DoRot1  = .FALSE.
  DoRot2  = .FALSE.
  DoVib1  = .FALSE.
  DoVib2  = .FALSE.

  iSpec = PartSpecies(Coll_pData(iPair)%iPart_p1)
  jSpec = PartSpecies(Coll_pData(iPair)%iPart_p2)

  Xi_rel = 2.*(2. - SpecDSMC(iSpec)%omegaVHS) ! DOF of relative motion in VHS model
  FakXi = 0.5*Xi_rel - 1.

  Coll_pData(iPair)%Ec = 0.5 * CollInf%MassRed(Coll_pData(iPair)%PairType) * Coll_pData(iPair)%CRela2

!--------------------------------------------------------------------------------------------------!
! Decision if Rotation, Vibration and Electronic Relaxation of particles is performed
!--------------------------------------------------------------------------------------------------!
  
  ! calculate probability for rotational/vibrational relaxation for both particles
  IF (SpecDSMC(iSpec)%InterID.EQ.2) THEN
    CALL DSMC_calc_P_vib(iSpec, jSpec, iPair, Xi_rel, ProbVib1, ProbVibMax1)
    CALL DSMC_calc_P_rot(iSpec, iPair, Coll_pData(iPair)%iPart_p1, Xi_rel, ProbRot1, ProbRotMax1)
  ELSE
    ProbVib1 = 0.
    ProbRot1 = 0.
  END IF
  IF (SpecDSMC(jSpec)%InterID.EQ.2) THEN
    CALL DSMC_calc_P_vib(jSpec, iSpec, iPair, Xi_rel, ProbVib2, ProbVibMax2)
    CALL DSMC_calc_P_rot(jSpec, iPair, Coll_pData(iPair)%iPart_p2, Xi_rel, ProbRot2, ProbRotMax2)
  ELSE
    ProbVib2 = 0.
    ProbRot2 = 0.
  END IF

  ! Calculate probability fractions
  IF(SpecDSMC(iSpec)%PolyatomicMol) THEN
    IF(DSMC%PolySingleMode) THEN
      ! If single-mode relaxation is considered, every mode has its own probability while it accumulates all the previous ones
      ! Here, the last mode of the molecule has the highest probability, later it is found which exact mode is going to be relaxed
      iPolyatMole = SpecDSMC(iSpec)%SpecToPolyArray
      ProbFrac1 = PolyatomMolDSMC(iPolyatMole)%VibRelaxProb(PolyatomMolDSMC(iPolyatMole)%VibDOF)
    ELSE
      ProbFrac1 = ProbVib1
    END IF
  ELSE
    ProbFrac1 = ProbVib1
  END IF
  IF(SpecDSMC(jSpec)%PolyatomicMol) THEN
    IF(DSMC%PolySingleMode) THEN
      iPolyatMole = SpecDSMC(jSpec)%SpecToPolyArray
      ProbFrac2 = ProbFrac1 + PolyatomMolDSMC(iPolyatMole)%VibRelaxProb(PolyatomMolDSMC(iPolyatMole)%VibDOF)
    ELSE
      ProbFrac2 = ProbFrac1 + ProbVib2
    END IF
  ELSE
    ProbFrac2 = ProbFrac1 + ProbVib2
  END IF
  ProbFrac3 = ProbFrac2 + ProbRot1
  ProbFrac4 = ProbFrac3 + ProbRot2

  ! Check if sum of probabilities is less than 1.
  IF (ProbFrac4.GT. 1.0) THEN
    CALL Abort(&
__STAMP__&
,'Error! Sum of internal relaxation probabilities > 1.0 for iPair ',iPair)
  END IF

  ! Select relaxation procedure (vibration, rotation)
  CALL RANDOM_NUMBER(iRan)
  IF(iRan .LT. ProbFrac1) THEN                    !            R1 < A1
    IF (SpecDSMC(iSpec)%PolyatomicMol.AND.DSMC%PolySingleMode) THEN
      ! Determination which vibrational mode should be relaxed for single-mode polyatomic relaxation
      iPolyatMole = SpecDSMC(iSpec)%SpecToPolyArray
      DO iDOF = 1, PolyatomMolDSMC(iPolyatMole)%VibDOF
        IF(PolyatomMolDSMC(iPolyatMole)%VibRelaxProb(iDOF).GT.iRan) THEN
          DoVib1 = .TRUE.
          DOFRelax = iDOF
          EXIT
        END IF
      END DO
    ELSE
      DoVib1 = .TRUE.
    END IF
  ELSEIF(iRan .LT. ProbFrac2) THEN                !      A1 <= R1 < A2
    IF (SpecDSMC(jSpec)%PolyatomicMol.AND.DSMC%PolySingleMode) THEN
      ! Determination which vibrational mode should be relaxed for single-mode polyatomic relaxation
      iPolyatMole = SpecDSMC(jSpec)%SpecToPolyArray
      DO iDOF = 1, PolyatomMolDSMC(iPolyatMole)%VibDOF
        IF(ProbFrac1 + PolyatomMolDSMC(iPolyatMole)%VibRelaxProb(iDOF).GT.iRan) THEN
          DoVib2 = .TRUE.
          DOFRelax = iDOF
          EXIT
        END IF
      END DO
    ELSE
      DoVib2 = .TRUE.
    END IF
  ELSEIF(iRan .LT. ProbFrac3) THEN                !      A2 <= R1 < A3
    DoRot1 = .TRUE.
  ELSEIF(iRan .LT. ProbFrac4) THEN                !      A3 <= R1 < A4
    DoRot2 = .TRUE.
  END IF

!--------------------------------------------------------------------------------------------------!
! Vibrational Relaxation
!--------------------------------------------------------------------------------------------------!

  IF(DoVib1) THEN
    ! check if correction term for BL redistribution (depending on relaxation model) is needed
    BLCorrFact = 1.
    ! Adding the interal energy of the particle to be redistributed
    Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec + PartStateIntEn(Coll_pData(iPair)%iPart_p1,1)
    IF(SpecDSMC(PartSpecies(Coll_pData(iPair)%iPart_p1))%PolyatomicMol) THEN
      IF (.NOT.DSMC%PolySingleMode) THEN
        ! --------------------------------------------------------------------------------------------------!
        !  Multi-mode relaxation with the Metropolis-Hastings method
        ! --------------------------------------------------------------------------------------------------!
        CALL DSMC_VibRelaxPoly(iPair,Coll_pData(iPair)%iPart_p1,FakXi)
        Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec - PartStateIntEn(Coll_pData(iPair)%iPart_p1,1)
      ELSE
        ! --------------------------------------------------------------------------------------------------!
        !  Single-mode relaxation with loop over all vibrational modes
        ! --------------------------------------------------------------------------------------------------!
        !  Not all vibrational energy is redistributed but only the energy of the selected vibrational degree of freedom
        Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec - PartStateIntEn(Coll_pData(iPair)%iPart_p1,1)
        iPolyatMole = SpecDSMC(iSpec)%SpecToPolyArray
        Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec                                                                 &
                      + (VibQuantsPar(Coll_pData(iPair)%iPart_p1)%Quants(DOFRelax) + DSMC%GammaQuant) * BoltzmannConst  &
                      * PolyatomMolDSMC(iPolyatMole)%CharaTVibDOF(DOFRelax)
        MaxColQua = Coll_pData(iPair)%Ec/(BoltzmannConst*PolyatomMolDSMC(iPolyatMole)%CharaTVibDOF(DOFRelax))  &
                  - DSMC%GammaQuant
        iQuaMax = MIN(INT(MaxColQua) + 1, PolyatomMolDSMC(iPolyatMole)%MaxVibQuantDOF(DOFRelax))
        CALL RANDOM_NUMBER(iRan)
        iQua = INT(iRan * iQuaMax)
        CALL RANDOM_NUMBER(iRan)
        DO WHILE (iRan.GT.(1 - iQua/MaxColQua)**FakXi)
         !laux diss page 31
         CALL RANDOM_NUMBER(iRan)
         iQua = INT(iRan * iQuaMax)
         CALL RANDOM_NUMBER(iRan)
        END DO
        PartStateIntEn(Coll_pData(iPair)%iPart_p1,1) = PartStateIntEn(Coll_pData(iPair)%iPart_p1,1)     &
          - (VibQuantsPar(Coll_pData(iPair)%iPart_p1)%Quants(DOFRelax) + DSMC%GammaQuant) * BoltzmannConst  &
          * PolyatomMolDSMC(iPolyatMole)%CharaTVibDOF(DOFRelax)                                                       &
          + (iQua + DSMC%GammaQuant) * BoltzmannConst * PolyatomMolDSMC(iPolyatMole)%CharaTVibDOF(DOFRelax)

        VibQuantsPar(Coll_pData(iPair)%iPart_p1)%Quants(DOFRelax) = iQua
        Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec &
                                - (iQua + DSMC%GammaQuant) * BoltzmannConst * PolyatomMolDSMC(iPolyatMole)%CharaTVibDOF(DOFRelax)
      END IF
    ELSE
      CALL DSMC_VibRelaxDiatomic(iPair,Coll_pData(iPair)%iPart_p1,FakXi)
      Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec - PartStateIntEn(Coll_pData(iPair)%iPart_p1,1)
    END IF

  END IF

  IF(DoVib2) THEN
    ! check if correction term for BL redistribution (depending on relaxation model) is needed
    BLCorrFact = 1.
    ! Adding the interal energy of the particle to be redistributed (not if single-mode polyatomic relaxation is enabled)
    Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec + PartStateIntEn(Coll_pData(iPair)%iPart_p2,1)
    IF(SpecDSMC(PartSpecies(Coll_pData(iPair)%iPart_p2))%PolyatomicMol) THEN
      IF (.NOT.DSMC%PolySingleMode) THEN
        ! --------------------------------------------------------------------------------------------------!
        !  Multi-mode relaxation with the Metropolis-Hastings method
        ! --------------------------------------------------------------------------------------------------!
        CALL DSMC_VibRelaxPoly(iPair,Coll_pData(iPair)%iPart_p2,FakXi)
        Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec - PartStateIntEn(Coll_pData(iPair)%iPart_p2,1)
      ELSE
        ! --------------------------------------------------------------------------------------------------!
        !  Single-mode relaxation with loop over all vibrational modes
        ! --------------------------------------------------------------------------------------------------!
        !  Not all vibrational energy is redistributed but only the energy of the selected vibrational degree of freedom
        Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec - PartStateIntEn(Coll_pData(iPair)%iPart_p2,1)
        iPolyatMole = SpecDSMC(jSpec)%SpecToPolyArray
        Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec                                                                 &
                      + (VibQuantsPar(Coll_pData(iPair)%iPart_p2)%Quants(DOFRelax) + DSMC%GammaQuant) * BoltzmannConst  &
                      * PolyatomMolDSMC(iPolyatMole)%CharaTVibDOF(DOFRelax)
        MaxColQua = Coll_pData(iPair)%Ec/(BoltzmannConst*PolyatomMolDSMC(iPolyatMole)%CharaTVibDOF(DOFRelax))  &
                  - DSMC%GammaQuant
        iQuaMax = MIN(INT(MaxColQua) + 1, PolyatomMolDSMC(iPolyatMole)%MaxVibQuantDOF(DOFRelax))
        CALL RANDOM_NUMBER(iRan)
        iQua = INT(iRan * iQuaMax)
        CALL RANDOM_NUMBER(iRan)
        DO WHILE (iRan.GT.(1 - iQua/MaxColQua)**FakXi)
         !laux diss page 31
         CALL RANDOM_NUMBER(iRan)
         iQua = INT(iRan * iQuaMax)
         CALL RANDOM_NUMBER(iRan)
        END DO
        PartStateIntEn(Coll_pData(iPair)%iPart_p2,1) = PartStateIntEn(Coll_pData(iPair)%iPart_p2,1)     &
          - (VibQuantsPar(Coll_pData(iPair)%iPart_p2)%Quants(DOFRelax) + DSMC%GammaQuant) * BoltzmannConst  &
          * PolyatomMolDSMC(iPolyatMole)%CharaTVibDOF(DOFRelax)                                                       &
          + (iQua + DSMC%GammaQuant) * BoltzmannConst * PolyatomMolDSMC(iPolyatMole)%CharaTVibDOF(DOFRelax)

        VibQuantsPar(Coll_pData(iPair)%iPart_p2)%Quants(DOFRelax) = iQua
        Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec &
                                - (iQua + DSMC%GammaQuant) * BoltzmannConst * PolyatomMolDSMC(iPolyatMole)%CharaTVibDOF(DOFRelax)
      END IF
    ELSE
      CALL DSMC_VibRelaxDiatomic(iPair,Coll_pData(iPair)%iPart_p2,FakXi)
      Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec - PartStateIntEn(Coll_pData(iPair)%iPart_p2,1)      
    END IF
  END IF

!--------------------------------------------------------------------------------------------------! 
! Rotational Relaxation
!--------------------------------------------------------------------------------------------------! 

  IF(DoRot1) THEN
    !check if correction term in distribution (depending on relaxation model) is needed
    IF(DSMC%RotRelaxProb.EQ.3.0) THEN
      BLCorrFact = ProbRot1 / ProbRotMax1
    ELSE
      BLCorrFact = 1.
    END IF
    Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec + PartStateIntEn(Coll_pData(iPair)%iPart_p1,2)    ! adding ro en to collision energy
    ! check for polyatomic treatment
    IF(SpecDSMC(PartSpecies(Coll_pData(iPair)%iPart_p1))%PolyatomicMol.AND. &
        (SpecDSMC(PartSpecies(Coll_pData(iPair)%iPart_p1))%Xi_Rot.EQ.3)) THEN
      FakXi = FakXi - 0.5*SpecDSMC(PartSpecies(Coll_pData(iPair)%iPart_p1))%Xi_Rot
      CALL DSMC_RotRelaxPoly(iPair, Coll_pData(iPair)%iPart_p1, FakXi)      
      Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec - PartStateIntEn(Coll_pData(iPair)%iPart_p1,2)
    ! no polyatomic treatment
    ELSE
     CALL RANDOM_NUMBER(iRan)
      ! variable MPF
      IF (usevMPF) THEN
        IF (PartMPF(Coll_pData(iPair)%iPart_p1).GT.PartMPF(Coll_pData(iPair)%iPart_p2)) THEN
          Phi = PartMPF(Coll_pData(iPair)%iPart_p2) / PartMPF(Coll_pData(iPair)%iPart_p1)
          PartStateIntEnTemp = Coll_pData(iPair)%Ec * (1.0 - iRan**(1.0/FakXi))
          Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec - PartStateIntEnTemp
          PartStateIntEn(Coll_pData(iPair)%iPart_p1,2) = (1-Phi) * PartStateIntEn(Coll_pData(iPair)%iPart_p1,2) &
                                                       + Phi * PartStateIntEnTemp
        END IF
      ! standartd MPF
      ELSE
        PartStateIntEnTemp = iRan * Coll_pData(iPair)%Ec
        CALL RANDOM_NUMBER(iRan)
        DO WHILE(iRan.GT.(1. - PartStateIntEnTemp/Coll_pData(iPair)%Ec)**FakXi*BLCorrFact)      ! FakXi hier nur 0.5*Xi_rel - 1 !
          CALL RANDOM_NUMBER(iRan)
          PartStateIntEnTemp = iRan * Coll_pData(iPair)%Ec
          CALL RANDOM_NUMBER(iRan)
        END DO
        PartStateIntEn(Coll_pData(iPair)%iPart_p1,2) = PartStateIntEnTemp
        Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec - PartStateIntEn(Coll_pData(iPair)%iPart_p1,2)
      END IF
    END IF
  END IF

  IF(DoRot2) THEN
    !check if correction term in distribution (depending on relaxation model) is needed
    IF(DSMC%RotRelaxProb.EQ.3.0) THEN
      BLCorrFact = ProbRot2 / ProbRotMax2
    ELSE
      BLCorrFact = 1.
    END IF
    Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec + PartStateIntEn(Coll_pData(iPair)%iPart_p2,2)    ! adding rot en to collision en
    IF(SpecDSMC(PartSpecies(Coll_pData(iPair)%iPart_p2))%PolyatomicMol.AND. &
        (SpecDSMC(PartSpecies(Coll_pData(iPair)%iPart_p2))%Xi_Rot.EQ.3)) THEN
      FakXi = FakXi - 0.5*SpecDSMC(PartSpecies(Coll_pData(iPair)%iPart_p2))%Xi_Rot
      CALL DSMC_RotRelaxPoly(iPair, Coll_pData(iPair)%iPart_p2, FakXi)
      Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec - PartStateIntEn(Coll_pData(iPair)%iPart_p2,2)
    ELSE
      CALL RANDOM_NUMBER(iRan)
      IF (usevMPF) THEN
        IF (PartMPF(Coll_pData(iPair)%iPart_p2).GT.PartMPF(Coll_pData(iPair)%iPart_p1)) THEN
          Phi = PartMPF(Coll_pData(iPair)%iPart_p1) / PartMPF(Coll_pData(iPair)%iPart_p2)
          PartStateIntEnTemp = Coll_pData(iPair)%Ec * (1.0 - iRan**(1.0/FakXi))
          Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec - PartStateIntEnTemp
          PartStateIntEn(Coll_pData(iPair)%iPart_p2,2) = (1-Phi) * PartStateIntEn(Coll_pData(iPair)%iPart_p2,2) &
                                                       + Phi * PartStateIntEnTemp
        END IF
      ELSE
        PartStateIntEnTemp = iRan * Coll_pData(iPair)%Ec
        CALL RANDOM_NUMBER(iRan)
        DO WHILE(iRan.GT.(1. - PartStateIntEnTemp/Coll_pData(iPair)%Ec)**FakXi*BLCorrFact)       ! FakXi hier nur 0.5*Xi_rel -1 !
          CALL RANDOM_NUMBER(iRan)
          PartStateIntEnTemp = iRan * Coll_pData(iPair)%Ec
          CALL RANDOM_NUMBER(iRan)
        END DO
        PartStateIntEn(Coll_pData(iPair)%iPart_p2,2) = PartStateIntEnTemp
        Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec - PartStateIntEn(Coll_pData(iPair)%iPart_p2,2)
      END IF
    END IF
  END IF

!--------------------------------------------------------------------------------------------------!
! Calculation of new particle velocities
!--------------------------------------------------------------------------------------------------!

  IF(usevMPF) THEN
    IF (iPair.EQ.PairE_vMPF(1)) THEN         ! adding energy lost due to vMPF
      Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec + GEO%DeltaEvMPF(iElem) / PartMPF(PairE_vMPF(2))
      GEO%DeltaEvMPF(iElem) = 0.0
    END IF
  END IF

  FracMassCent1 = CollInf%FracMassCent(PartSpecies(Coll_pData(iPair)%iPart_p1), Coll_pData(iPair)%PairType)
  FracMassCent2 = CollInf%FracMassCent(PartSpecies(Coll_pData(iPair)%iPart_p2), Coll_pData(iPair)%PairType)

  !Calculation of velo from center of mass
  VeloMx = FracMassCent1 * PartState(Coll_pData(iPair)%iPart_p1, 4) &
         + FracMassCent2 * PartState(Coll_pData(iPair)%iPart_p2, 4)
  VeloMy = FracMassCent1 * PartState(Coll_pData(iPair)%iPart_p1, 5) &
         + FracMassCent2 * PartState(Coll_pData(iPair)%iPart_p2, 5)
  VeloMz = FracMassCent1 * PartState(Coll_pData(iPair)%iPart_p1, 6) &
         + FracMassCent2 * PartState(Coll_pData(iPair)%iPart_p2, 6)

  !calculate random vec and new squared velocities
  Coll_pData(iPair)%CRela2 = 2 * Coll_pData(iPair)%Ec/CollInf%MassRed(Coll_pData(iPair)%PairType)
  RanVec(1:3) = DiceUnitVector()

  RanVelox = SQRT(Coll_pData(iPair)%CRela2) * RanVec(1)
  RanVeloy = SQRT(Coll_pData(iPair)%CRela2) * RanVec(2)
  RanVeloz = SQRT(Coll_pData(iPair)%CRela2) * RanVec(3)

  ! deltaV particle 1
  DSMC_RHS(Coll_pData(iPair)%iPart_p1,1) = VeloMx + FracMassCent2*RanVelox &
          - PartState(Coll_pData(iPair)%iPart_p1, 4)
  DSMC_RHS(Coll_pData(iPair)%iPart_p1,2) = VeloMy + FracMassCent2*RanVeloy &
          - PartState(Coll_pData(iPair)%iPart_p1, 5)
  DSMC_RHS(Coll_pData(iPair)%iPart_p1,3) = VeloMz + FracMassCent2*RanVeloz &
          - PartState(Coll_pData(iPair)%iPart_p1, 6)
 ! deltaV particle 2
  DSMC_RHS(Coll_pData(iPair)%iPart_p2,1) = VeloMx - FracMassCent1*RanVelox &
          - PartState(Coll_pData(iPair)%iPart_p2, 4)
  DSMC_RHS(Coll_pData(iPair)%iPart_p2,2) = VeloMy - FracMassCent1*RanVeloy &
          - PartState(Coll_pData(iPair)%iPart_p2, 5)
  DSMC_RHS(Coll_pData(iPair)%iPart_p2,3) = VeloMz - FracMassCent1*RanVeloz &
            - PartState(Coll_pData(iPair)%iPart_p2, 6)

  IF(usevMPF) CALL vMPF_PostVelo(iPair, iElem)

END SUBROUTINE DSMC_Relax_Col_Gimelshein


SUBROUTINE DSMC_perform_collision(iPair, iElem, NodeVolume, NodePartNum)
!===================================================================================================================================
! Collision mode is selected (1: Elastic, 2: Non-elastic, 3: Non-elastic with chemical reactions)
!===================================================================================================================================
! MODULES
  USE MOD_Globals,            ONLY : Abort
  USE MOD_DSMC_Vars,          ONLY : CollisMode, Coll_pData, SelectionProc
  USE MOD_DSMC_Vars,          ONLY : DSMC
  USE MOD_Particle_Vars,      ONLY : PartState, WriteMacroVolumeValues
  USE MOD_TimeDisc_Vars,      ONLY : TEnd, Time
! IMPLICIT VARIABLE HANDLING
  IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
  INTEGER, INTENT(IN)           :: iPair
  INTEGER, INTENT(IN)           :: iElem
  REAL, INTENT(IN), OPTIONAL    :: NodeVolume
  INTEGER, INTENT(IN), OPTIONAL :: NodePartNum
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
  LOGICAL                       :: RelaxToDo
!===================================================================================================================================
  
  IF(DSMC%CalcQualityFactors) THEN  
    IF((Time.GE.(1-DSMC%TimeFracSamp)*TEnd).OR.WriteMacroVolumeValues) THEN
      DSMC%CollSepDist = DSMC%CollSepDist + SQRT((PartState(Coll_pData(iPair)%iPart_p1,1) &
                                         - PartState(Coll_pData(iPair)%iPart_p2,1))**2 &
                                         +(PartState(Coll_pData(iPair)%iPart_p1,2) &
                                         - PartState(Coll_pData(iPair)%iPart_p2,2))**2 &
                                         +(PartState(Coll_pData(iPair)%iPart_p1,3) &
                                         - PartState(Coll_pData(iPair)%iPart_p2,3))**2)
      DSMC%CollSepCount = DSMC%CollSepCount + 1
    END IF
  END IF

  SELECT CASE(CollisMode)
    CASE(1) ! elastic collision
#if (PP_TimeDiscMethod==42)
      ! Reservoir simulation for obtaining the reaction rate at one given point does not require to perform the reaction
      IF (.NOT.DSMC%ReservoirSimuRate) THEN
#endif
        CALL DSMC_Elastic_Col(iPair, iElem)
#if (PP_TimeDiscMethod==42)
      END IF
#endif
    CASE(2) ! collision with relaxation
#if (PP_TimeDiscMethod==42)
      ! Reservoir simulation for obtaining the reaction rate at one given point does not require to perform the reaction
      IF (.NOT.DSMC%ReservoirSimuRate) THEN
#endif
        SELECT CASE(SelectionProc)
          CASE(1)
            CALL DSMC_Relax_Col_LauxTSHO(iPair, iElem)
          CASE(2)
            CALL DSMC_Relax_Col_Gimelshein(iPair, iElem)
          CASE DEFAULT
            CALL Abort(&
__STAMP__&
,'ERROR in DSMC_perform_collision: Wrong Selection Procedure:',SelectionProc)
        END SELECT
#if (PP_TimeDiscMethod==42)
      END IF
#endif
    CASE(3) ! chemical reactions
      RelaxToDo = .TRUE.
      IF (PRESENT(NodeVolume).AND.PRESENT(NodePartNum)) THEN
        CALL ReactionDecision(iPair, RelaxToDo, iElem, NodeVolume, NodePartNum)
      ELSE
        CALL ReactionDecision(iPair, RelaxToDo, iElem)
      END IF
#if (PP_TimeDiscMethod==42)
      ! Reservoir simulation for obtaining the reaction rate at one given point does not require to perform the reaction
      IF (.NOT.DSMC%ReservoirSimuRate) THEN
#endif
        IF (RelaxToDo) THEN
          SELECT CASE(SelectionProc)
            CASE(1)
              CALL DSMC_Relax_Col_LauxTSHO(iPair, iElem)
            CASE(2)
              CALL DSMC_Relax_Col_Gimelshein(iPair, iElem)
            CASE DEFAULT
              CALL Abort(&
__STAMP__&
,'ERROR in DSMC_perform_collision: Wrong Selection Procedure:',SelectionProc)
          END SELECT
        END IF
#if (PP_TimeDiscMethod==42)
      END IF
#endif
    CASE DEFAULT
      CALL Abort(&
__STAMP__&
,'ERROR in DSMC_perform_collision: Wrong Collision Mode:',CollisMode)
  END SELECT

END SUBROUTINE DSMC_perform_collision


SUBROUTINE ReactionDecision(iPair, RelaxToDo, iElem, NodeVolume, NodePartNum)
!===================================================================================================================================
! Decision of reaction type (recombination, exchange, dissociation, CEX/MEX and multiple combinations of those)
!===================================================================================================================================
! MODULES
  USE MOD_Globals,                ONLY : Abort
  USE MOD_Globals_Vars,           ONLY : BoltzmannConst, ElementaryCharge
  USE MOD_DSMC_Vars,              ONLY : Coll_pData, CollInf, DSMC, SpecDSMC, PartStateIntEn, ChemReac
  USE MOD_Particle_Vars,          ONLY : PartSpecies, PEM, usevMPF
  USE MOD_DSMC_ChemReact,         ONLY : DSMC_Chemistry, simpleCEX, simpleMEX, CalcReactionProb
  USE MOD_Globals,                ONLY : Unit_stdOut
  USE MOD_vmpf_collision,         ONLY : AtomRecomb_vMPF
  USE MOD_Particle_Mesh_Vars,     ONLY : GEO
  USE MOD_DSMC_QK_PROCEDURES,     ONLY : QK_dissociation, QK_recombination, QK_exchange, QK_ImpactIonization, QK_IonRecombination
! IMPLICIT VARIABLE HANDLING
  IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
  INTEGER, INTENT(IN)           :: iPair
  INTEGER, INTENT(IN)           :: iElem
  LOGICAL, INTENT(INOUT)        :: RelaxToDo
  REAL, INTENT(IN), OPTIONAL    :: NodeVolume
  INTEGER, INTENT(IN), OPTIONAL :: NodePartNum
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
INTEGER                       :: CaseOfReaction, iReac, PartToExec, PartReac2, iPart_p3
INTEGER                       :: PartToExecSec, PartReac2Sec, iReac2, iReac3, iReac4
INTEGER                       :: nPartNode, PairForRec, nPair
REAL                          :: EZeroPoint, Volume, sigmaCEX, sigmaMEX
REAL (KIND=8)                 :: ReactionProb, ReactionProb2, ReactionProb3, ReactionProb4
REAL (KIND=8)                 :: iRan, iRan2, iRan3
!===================================================================================================================================
  IF (ChemReac%NumOfReact.EQ.0) THEN
    CaseOfReaction = 0
  ELSE
    CaseOfReaction = ChemReac%ReactCase(PartSpecies(Coll_pData(iPair)%iPart_p1),PartSpecies(Coll_pData(iPair)%iPart_p2))
  END IF
  IF (PRESENT(NodeVolume)) THEN
    Volume = NodeVolume
  ELSE
    Volume = GEO%Volume(iElem)
  END IF
  IF (PRESENT(NodePartNum)) THEN
    nPartNode = NodePartNum
  ELSE
    nPartNode = PEM%pNumber(iElem)
  END IF
  nPair = INT(nPartNode/2)
  SELECT CASE(CaseOfReaction)
! ############################################################################################################################### !
    CASE(1) ! Only recombination is possible
! ############################################################################################################################### !
      ! searching third collison partner
      IF(ChemReac%RecombParticle.EQ. 0) THEN
        IF(iPair.LT.(nPair - ChemReac%nPairForRec)) THEN
          PairForRec = nPair - ChemReac%nPairForRec
          ChemReac%nPairForRec = ChemReac%nPairForRec + 1
          iPart_p3 = Coll_pData(PairForRec)%iPart_p1
        ELSE
          iPart_p3 = 0
        END IF
      ELSE
        iPart_p3 = ChemReac%RecombParticle
      END IF
!-----------------------------------------------------------------------------------------------------------------------------------
      IF (iPart_p3 .GT. 0) THEN
        iReac = ChemReac%ReactNum(PartSpecies(Coll_pData(iPair)%iPart_p1), &
                                  PartSpecies(Coll_pData(iPair)%iPart_p2), &
                                  PartSpecies(iPart_p3))
        IF(iReac.EQ.0) THEN
          iReac = ChemReac%ReactNumRecomb(PartSpecies(Coll_pData(iPair)%iPart_p1), &
                                          PartSpecies(Coll_pData(iPair)%iPart_p2), &
                                          PartSpecies(iPart_p3))
        END IF
        IF (ChemReac%QKProcedure(iReac)) THEN
          ! QK - model
          CALL QK_recombination(iPair,iReac,iPart_p3,RelaxToDo,iElem,NodeVolume,NodePartNum)
        ELSE
!-----------------------------------------------------------------------------------------------------------------------------------
        ! traditional Recombination
          ! Calculation of reaction probability
          CALL CalcReactionProb(iPair,iReac,ReactionProb,iPart_p3,nPartNode,Volume)
#if (PP_TimeDiscMethod==42)
          IF (.NOT.DSMC%ReservoirRateStatistic) THEN
            ChemReac%NumReac(iReac) = ChemReac%NumReac(iReac) + ReactionProb  ! for calculation of reaction rate coefficient
            ChemReac%ReacCount(iReac) = ChemReac%ReacCount(iReac) + 1
          END IF
#endif
          CALL RANDOM_NUMBER(iRan)
          IF (ReactionProb.GT.iRan) THEN
#if (PP_TimeDiscMethod==42)
            ! Reservoir simulation for obtaining the reaction rate at one given point does not require to perform the reaction
            IF (.NOT.DSMC%ReservoirSimuRate) THEN
#endif
              IF (usevMPF) THEN
                CALL AtomRecomb_vMPF(iReac, iPair, iPart_p3, iElem)
              ELSE
                CALL DSMC_Chemistry(iPair, iReac, iPart_p3)
                IF(ChemReac%RecombParticle.EQ. 0) THEN
                  Coll_pData(PairForRec)%NeedForRec = .TRUE.
                  ChemReac%RecombParticle = Coll_pData(PairForRec)%iPart_p2
                ELSE
                  ChemReac%RecombParticle = 0
                END IF
              END IF
#if (PP_TimeDiscMethod==42)
            END IF
            IF (DSMC%ReservoirRateStatistic) THEN
              ChemReac%NumReac(iReac) = ChemReac%NumReac(iReac) + 1  ! for calculation of reaction rate coefficient
            END IF
#endif
            RelaxToDo = .FALSE.
          END IF ! ReactionProb > iRan
        END IF ! Q-K
      END IF ! iPart > 0
! ############################################################################################################################### !
    CASE(2) ! Only one dissociation is possible
! ############################################################################################################################### !
      iReac = ChemReac%ReactNum(PartSpecies(Coll_pData(iPair)%iPart_p1), PartSpecies(Coll_pData(iPair)%iPart_p2), 1)
      IF (ChemReac%QKProcedure(iReac)) THEN
        CALL QK_dissociation(iPair,iReac,RelaxToDo)
      ELSE
        ! Arrhenius-based reaction probability
        CALL CalcReactionProb(iPair,iReac,ReactionProb)
#if (PP_TimeDiscMethod==42)
        IF (.NOT.DSMC%ReservoirRateStatistic) THEN
          ChemReac%NumReac(iReac) = ChemReac%NumReac(iReac) + ReactionProb  ! for calculation of reaction rate coefficient
          ChemReac%ReacCount(iReac) = ChemReac%ReacCount(iReac) + 1
        END IF
#endif
        CALL RANDOM_NUMBER(iRan)
        IF (ReactionProb.GT.iRan) THEN
#if (PP_TimeDiscMethod==42)
          ! Reservoir simulation for obtaining the reaction rate at one given point does not require to perform the reaction
          IF (.NOT.DSMC%ReservoirSimuRate) THEN
#endif
            CALL DSMC_Chemistry(iPair, iReac)
#if (PP_TimeDiscMethod==42)
          END IF
          IF (DSMC%ReservoirRateStatistic) THEN
            ChemReac%NumReac(iReac) = ChemReac%NumReac(iReac) + 1  ! for calculation of reaction rate coefficient
          END IF
#endif
          RelaxToDo = .FALSE.
        END IF
      END IF
! ############################################################################################################################### !
    CASE(3) ! Only one exchange reaction is possible
! ############################################################################################################################### !
      iReac = ChemReac%ReactNum(PartSpecies(Coll_pData(iPair)%iPart_p1), PartSpecies(Coll_pData(iPair)%iPart_p2), 1)
      IF (ChemReac%QKProcedure(iReac)) THEN
        CALL QK_exchange(iPair,iReac,RelaxToDo)
      ELSE
        ! Arrhenius-based reaction probability
        CALL CalcReactionProb(iPair,iReac,ReactionProb)
#if (PP_TimeDiscMethod==42)
        IF (.NOT.DSMC%ReservoirRateStatistic) THEN
          ChemReac%NumReac(iReac) = ChemReac%NumReac(iReac) + ReactionProb  ! for calculation of reaction rate coefficient
          ChemReac%ReacCount(iReac) = ChemReac%ReacCount(iReac) + 1
        END IF
#endif
        CALL RANDOM_NUMBER(iRan)
        IF (ReactionProb.GT.iRan) THEN
#if (PP_TimeDiscMethod==42)
          ! Reservoir simulation for obtaining the reaction rate at one given point does not require to perform the reaction
          IF (.NOT.DSMC%ReservoirSimuRate) THEN
#endif
            CALL DSMC_Chemistry(iPair, iReac)
#if (PP_TimeDiscMethod==42)
          END IF
          IF (DSMC%ReservoirRateStatistic) THEN
            ChemReac%NumReac(iReac) = ChemReac%NumReac(iReac) + 1  ! for calculation of reaction rate coefficient
          END IF
#endif
          RelaxToDo = .FALSE.
        END IF
      END IF
! ############################################################################################################################### !
    CASE(4) ! One dissociation and one exchange reaction are possible
! ############################################################################################################################### !
      iReac = ChemReac%ReactNum(PartSpecies(Coll_pData(iPair)%iPart_p1), PartSpecies(Coll_pData(iPair)%iPart_p2), 1)
      iReac2 = ChemReac%ReactNum(PartSpecies(Coll_pData(iPair)%iPart_p1), PartSpecies(Coll_pData(iPair)%iPart_p2), 2)
      IF (ChemReac%QKProcedure(iReac)) THEN
        ! first check, if the the molecule dissociate, afterwards, check if an exchange reaction is possible
        CALL QK_dissociation(iPair,iReac,RelaxToDo)
        IF (RelaxToDo) THEN
        ! exchange reactions
          iReac = ChemReac%ReactNum(PartSpecies(Coll_pData(iPair)%iPart_p1), PartSpecies(Coll_pData(iPair)%iPart_p2), 2)
          IF (ChemReac%QKProcedure(iReac)) THEN
            CALL QK_exchange(iPair,iReac,RelaxToDo)
          ELSE
            ! Arrhenius based Exchange Reaction
            Coll_pData(iPair)%Ec = 0.5 * CollInf%MassRed(Coll_pData(iPair)%PairType)*Coll_pData(iPair)%CRela2                  &
                                 + PartStateIntEn(Coll_pData(iPair)%iPart_p1,1) + PartStateIntEn(Coll_pData(iPair)%iPart_p2,1) &
                                 + PartStateIntEn(Coll_pData(iPair)%iPart_p1,2) + PartStateIntEn(Coll_pData(iPair)%iPart_p2,2)
            CALL CalcReactionProb(iPair,iReac,ReactionProb)                     
#if (PP_TimeDiscMethod==42)
            IF (.NOT.DSMC%ReservoirRateStatistic) THEN
              ChemReac%NumReac(iReac) = ChemReac%NumReac(iReac) + ReactionProb  ! for calculation of reaction rate coefficient
              ChemReac%ReacCount(iReac) = ChemReac%ReacCount(iReac) + 1
            END IF
#endif
            CALL RANDOM_NUMBER(iRan)
            IF (ReactionProb.GT.iRan) THEN
#if (PP_TimeDiscMethod==42)
              ! Reservoir simulation for obtaining the reaction rate at one given point does not require to perform the reaction
              IF (.NOT.DSMC%ReservoirSimuRate) THEN
#endif
                CALL DSMC_Chemistry(iPair, iReac)
#if (PP_TimeDiscMethod==42)
              END IF
              IF (DSMC%ReservoirRateStatistic) THEN
                ChemReac%NumReac(iReac) = ChemReac%NumReac(iReac) + 1  ! for calculation of reaction rate coefficient
              END IF
#endif
              RelaxToDo = .FALSE.
            END IF
          END IF
        END IF
      ELSE
!-----------------------------------------------------------------------------------------------------------------------------------
        ! Arrhenius-based reaction probability
        ! calculation of dissociation probability
        CALL CalcReactionProb(iPair,iReac,ReactionProb)
#if (PP_TimeDiscMethod==42)
        IF (.NOT.DSMC%ReservoirRateStatistic) THEN
          ChemReac%NumReac(iReac) = ChemReac%NumReac(iReac) + ReactionProb  ! for calculation of reaction rate coefficient
          ChemReac%ReacCount(iReac) = ChemReac%ReacCount(iReac) + 1
        END IF
#endif
        ! calculation of exchange reaction probability
        CALL CalcReactionProb(iPair,iReac2,ReactionProb2)
#if (PP_TimeDiscMethod==42)
        IF (.NOT.DSMC%ReservoirRateStatistic) THEN
          ChemReac%NumReac(iReac2) = ChemReac%NumReac(iReac2) + ReactionProb2  ! for calculation of reaction rate coefficient
          ChemReac%ReacCount(iReac2) = ChemReac%ReacCount(iReac2) + 1
        END IF
#endif
        CALL RANDOM_NUMBER(iRan)
        IF ((ReactionProb + ReactionProb2).GT.iRan) THEN
          CALL RANDOM_NUMBER(iRan)
          IF((ReactionProb/(ReactionProb + ReactionProb2)).GT.iRan) THEN
            ! Reservoir simulation for obtaining the reaction rate at one given point does not require to perform the reaction
#if (PP_TimeDiscMethod==42)
            IF (.NOT.DSMC%ReservoirSimuRate) THEN
#endif
              CALL DSMC_Chemistry(iPair, iReac)
#if (PP_TimeDiscMethod==42)
            END IF
            IF (DSMC%ReservoirRateStatistic) THEN
              ChemReac%NumReac(iReac) = ChemReac%NumReac(iReac) + 1  ! for calculation of reaction rate coefficient
            END IF
#endif
          ELSE
#if (PP_TimeDiscMethod==42)
          ! Reservoir simulation for obtaining the reaction rate at one given point does not require to perform the reaction
            IF (.NOT.DSMC%ReservoirSimuRate) THEN
#endif
              CALL DSMC_Chemistry(iPair, iReac2)
#if (PP_TimeDiscMethod==42)
            END IF
            IF (DSMC%ReservoirRateStatistic) THEN
              ChemReac%NumReac(iReac2) = ChemReac%NumReac(iReac2) + 1  ! for calculation of reaction rate coefficient
            END IF
#endif
          END IF
          RelaxToDo = .FALSE.
        END IF
      END IF
! ############################################################################################################################### !
    CASE(5) ! Two dissociation reactions are possible
! ############################################################################################################################### !
      iReac  = ChemReac%ReactNum(PartSpecies(Coll_pData(iPair)%iPart_p1), PartSpecies(Coll_pData(iPair)%iPart_p2), 1)
      iReac2 = ChemReac%ReactNum(PartSpecies(Coll_pData(iPair)%iPart_p1), PartSpecies(Coll_pData(iPair)%iPart_p2), 2)
      IF (ChemReac%QKProcedure(iReac).AND.ChemReac%QKProcedure(iReac2)) THEN ! both Reaction QK
        ! collision energy without internal energy
        Coll_pData(iPair)%Ec = 0.5 * CollInf%MassRed(Coll_pData(iPair)%PairType)*Coll_pData(iPair)%CRela2
        ! first pseudo reaction probability
        IF (ChemReac%DefinedReact(iReac,1,1).EQ.PartSpecies(Coll_pData(iPair)%iPart_p1)) THEN
          PartToExec = Coll_pData(iPair)%iPart_p1
          PartReac2 = Coll_pData(iPair)%iPart_p2
        ELSE
          PartToExec = Coll_pData(iPair)%iPart_p2
          PartReac2 = Coll_pData(iPair)%iPart_p1
        END IF
        ReactionProb = ( Coll_pData(iPair)%Ec + PartStateIntEn(PartToExec,1)    - &
                         SpecDSMC(PartSpecies(PartToExec))%Ediss_eV * ElementaryCharge  )  / &
                       ( Coll_pData(iPair)%Ec + PartStateIntEn(PartToExec,1) )
        IF (ReactionProb.LE.0.) THEN
          ReactionProb = 0.
        END IF
        IF (ChemReac%DefinedReact(iReac2,1,1).EQ.PartSpecies(Coll_pData(iPair)%iPart_p1)) THEN
          PartToExecSec = Coll_pData(iPair)%iPart_p1
          PartReac2Sec = Coll_pData(iPair)%iPart_p2
        ELSE
          PartToExecSec = Coll_pData(iPair)%iPart_p2
          PartReac2Sec = Coll_pData(iPair)%iPart_p1
        END IF
        ! pseudo probability for second reaction
        ReactionProb2 = ( Coll_pData(iPair)%Ec + PartStateIntEn(PartToExecSec,1 )  - &
                          SpecDSMC(PartSpecies(PartToExecSec))%Ediss_eV * ElementaryCharge )  / &
                        ( Coll_pData(iPair)%Ec + PartStateIntEn(PartToExecSec,1) )
        IF (ReactionProb2.LE.0.) THEN
          ReactionProb2 = 0
        END IF
        IF (ReactionProb.GT.0.) THEN
          ! determine if first molecule dissociate
          CALL RANDOM_NUMBER(iRan)
          IF ( ReactionProb / ( ReactionProb + ReactionProb2) .gt. iRan) THEN
            CALL QK_dissociation(iPair,iReac,RelaxToDo)
            ! first molecule does not dissociate. what is the second particle doing?
          ELSE IF ( ReactionProb2 .gt. 0 ) THEN
          ! dissociation second molecule
            CALL QK_dissociation(iPair,iReac2,RelaxToDo)
          END IF
        ! ReactionProb = 0, check if second dissociation is possible
        ELSE IF ( ReactionProb2 .gt. 0 ) THEN
!           ! dissociationof second molecule
            CALL QK_dissociation(iPair,iReac2,RelaxToDo)
        END IF
      ELSE IF ( ChemReac%QKProcedure(iReac) .OR. ChemReac%QKProcedure(iReac2) ) THEN ! only one Reaction QK
        ! collision energy without internal energy
        Coll_pData(iPair)%Ec = 0.5 * CollInf%MassRed(Coll_pData(iPair)%PairType)*Coll_pData(iPair)%CRela2
        ! set QK reaction as first tested reaction
        IF (ChemReac%QKProcedure(iReac2)) THEN
          iReac  = ChemReac%ReactNum(PartSpecies(Coll_pData(iPair)%iPart_p1), PartSpecies(Coll_pData(iPair)%iPart_p2), 2)
          iReac2 = ChemReac%ReactNum(PartSpecies(Coll_pData(iPair)%iPart_p1), PartSpecies(Coll_pData(iPair)%iPart_p2), 1)
        END IF
        ! first pseude reaction probability
        IF (ChemReac%DefinedReact(iReac,1,1).EQ.PartSpecies(Coll_pData(iPair)%iPart_p1)) THEN
          PartToExec = Coll_pData(iPair)%iPart_p1
          PartReac2 = Coll_pData(iPair)%iPart_p2
        ELSE
          PartToExec = Coll_pData(iPair)%iPart_p2
          PartReac2 = Coll_pData(iPair)%iPart_p1
        END IF
        ReactionProb = ( Coll_pData(iPair)%Ec + PartStateIntEn(PartToExec,1)    - &
                         SpecDSMC(PartSpecies(PartToExec))%Ediss_eV * ElementaryCharge  )  / &
                       ( Coll_pData(iPair)%Ec + PartStateIntEn(PartToExec,1) )
        IF (ReactionProb.LE.0.) THEN
          ReactionProb = 0.
        END IF
        ! second reaction probability
        IF (ChemReac%DefinedReact(iReac2,1,1).EQ.PartSpecies(Coll_pData(iPair)%iPart_p1)) THEN
          PartToExecSec = Coll_pData(iPair)%iPart_p1
          PartReac2Sec = Coll_pData(iPair)%iPart_p2
        ELSE
          PartToExecSec = Coll_pData(iPair)%iPart_p2
          PartReac2Sec = Coll_pData(iPair)%iPart_p1
        END IF
        ! pseudo probability for second reaction
        ReactionProb2 = ( Coll_pData(iPair)%Ec + PartStateIntEn(PartToExecSec,1 )  - &
                          SpecDSMC(PartSpecies(PartToExecSec))%Ediss_eV * ElementaryCharge )  / &
                        ( Coll_pData(iPair)%Ec + PartStateIntEn(PartToExecSec,1) )
        IF (ReactionProb2.LE.0.) THEN
          ReactionProb2 = 0.
        END IF
        IF ( ReactionProb .gt. 0 ) THEN
          ! determine if first molecule dissociates
          CALL RANDOM_NUMBER(iRan)
          IF ( ReactionProb / ( ReactionProb + ReactionProb2) .gt. iRan) THEN
            CALL QK_dissociation(iPair,iReac,RelaxToDo)
          ELSE
          ! perform Arrhenius dissociation
            Coll_pData(iPair)%Ec = 0.5 * CollInf%MassRed(Coll_pData(iPair)%PairType)*Coll_pData(iPair)%CRela2 &
                                  + PartStateIntEn(Coll_pData(iPair)%iPart_p1,1) + PartStateIntEn(Coll_pData(iPair)%iPart_p2,1) &
                                  + PartStateIntEn(Coll_pData(iPair)%iPart_p1,2) + PartStateIntEn(Coll_pData(iPair)%iPart_p2,2)
            EZeroPoint = DSMC%GammaQuant*BoltzmannConst*SpecDSMC(PartSpecies(PartReac2Sec))%CharaTVib
            IF((Coll_pData(iPair)%Ec-EZeroPoint).GE.ChemReac%EActiv(iReac2)) THEN
              ReactionProb = ChemReac%ReactInfo(iReac2)%Beta_Diss_Arrhenius(                                                     &
                             ChemReac%MeanEVibQua_PerIter(PartSpecies(PartToExecSec))                                            &
                             , ChemReac%MeanEVibQua_PerIter(PartSpecies(PartReac2Sec)))                                          &
                             * (Coll_pData(iPair)%Ec - ChemReac%EActiv(iReac2))                                                  &
                          ** (ChemReac%Arrhenius_Powerfactor(iReac2) - 1.5 + SpecDSMC(ChemReac%DefinedReact(iReac2,1,1))%omegaVHS&
                             + ChemReac%ReactInfo(iReac2)%Xi_Total(ChemReac%MeanEVibQua_PerIter(PartSpecies(PartToExecSec))      &
                            , ChemReac%MeanEVibQua_PerIter(PartSpecies(PartReac2Sec)))/2)                                        &
                             * Coll_pData(iPair)%Ec                                                                              &
                             ** (1.0 - SpecDSMC(ChemReac%DefinedReact(iReac2,1,1))%VFD_Phi3_Factor                               &
                                 - ChemReac%ReactInfo(iReac2)%Xi_Total(ChemReac%MeanEVibQua_PerIter(PartSpecies(PartToExecSec))  &
                                  , ChemReac%MeanEVibQua_PerIter(PartSpecies(PartReac2Sec)))/2)                                  &
                                 * PartStateIntEn(PartToExecSec,1) ** SpecDSMC(ChemReac%DefinedReact(iReac2,1,1))%VFD_Phi3_Factor
            ELSE
              ReactionProb = 0.0
            END IF
#if (PP_TimeDiscMethod==42)
            IF (.NOT.DSMC%ReservoirRateStatistic) THEN
              ChemReac%NumReac(iReac) = ChemReac%NumReac(iReac) + ReactionProb  ! for calculation of reaction rate coefficient
              ChemReac%ReacCount(iReac) = ChemReac%ReacCount(iReac) + 1
            END IF
#endif
            CALL RANDOM_NUMBER(iRan)
            IF (ReactionProb.GT.iRan) THEN
#if (PP_TimeDiscMethod==42)
              ! Reservoir simulation for obtaining the reaction rate at one given point does not require to perform the reaction
              IF (.NOT.DSMC%ReservoirSimuRate) THEN
#endif
                CALL DSMC_Chemistry(iPair, iReac2)
#if (PP_TimeDiscMethod==42)
              END IF
              IF (DSMC%ReservoirRateStatistic) THEN
                ChemReac%NumReac(iReac) = ChemReac%NumReac(iReac) + 1  ! for calculation of reaction rate coefficient
              END IF
#endif
              RelaxToDo = .FALSE.
            END IF
          END IF
        END IF
      ELSE ! both reactions Arrhenius
!-----------------------------------------------------------------------------------------------------------------------------------
        ! Arrhenius-based reaction probability
        CALL CalcReactionProb(iPair,iReac,ReactionProb)
#if (PP_TimeDiscMethod==42)
        IF (.NOT.DSMC%ReservoirRateStatistic) THEN
          ChemReac%NumReac(iReac) = ChemReac%NumReac(iReac) + ReactionProb  ! for calculation of reaction rate coefficient
          ChemReac%ReacCount(iReac) = ChemReac%ReacCount(iReac) + 1
        END IF
#endif
        ! calculation of dissociation probability
        CALL CalcReactionProb(iPair,iReac2,ReactionProb2)
#if (PP_TimeDiscMethod==42)
        IF (.NOT.DSMC%ReservoirRateStatistic) THEN
          ChemReac%NumReac(iReac2) = ChemReac%NumReac(iReac2) + ReactionProb2  ! for calculation of reaction rate coefficient
          ChemReac%ReacCount(iReac2) = ChemReac%ReacCount(iReac2) + 1
        END IF
#endif
        CALL RANDOM_NUMBER(iRan)
        IF ((ReactionProb + ReactionProb2).GT.iRan) THEN
          CALL RANDOM_NUMBER(iRan)
          IF((ReactionProb/(ReactionProb + ReactionProb2)).GT.iRan) THEN
            ! Reservoir simulation for obtaining the reaction rate at one given point does not require to perform the reaction
#if (PP_TimeDiscMethod==42)
            IF (.NOT.DSMC%ReservoirSimuRate) THEN
#endif
              CALL DSMC_Chemistry(iPair, iReac)
#if (PP_TimeDiscMethod==42)
            END IF
            IF (DSMC%ReservoirRateStatistic) THEN
              ChemReac%NumReac(iReac) = ChemReac%NumReac(iReac) + 1  ! for calculation of reaction rate coefficient
            END IF
#endif
          ELSE
            ! Reservoir simulation for obtaining the reaction rate at one given point does not require to perform the reaction
#if (PP_TimeDiscMethod==42)
            IF (.NOT.DSMC%ReservoirSimuRate) THEN
#endif
              CALL DSMC_Chemistry(iPair, iReac2)
#if (PP_TimeDiscMethod==42)
            END IF
            IF (DSMC%ReservoirRateStatistic) THEN
              ChemReac%NumReac(iReac2) = ChemReac%NumReac(iReac2) + 1  ! for calculation of reaction rate coefficient
            END IF
#endif
          END IF
          RelaxToDo = .FALSE.
        END IF
      END IF
! ############################################################################################################################### !
    CASE(6) ! ionization or ion recombination
! ############################################################################################################################### !
      ! searching third collison partner
      IF(ChemReac%RecombParticle.EQ. 0) THEN
        IF(iPair.LT.(nPair - ChemReac%nPairForRec)) THEN
          PairForRec = nPair - ChemReac%nPairForRec
          ChemReac%nPairForRec = ChemReac%nPairForRec + 1
          iPart_p3 = Coll_pData(PairForRec)%iPart_p1
        ELSE
          iPart_p3 = 0
        END IF
      ELSE
        iPart_p3 = ChemReac%RecombParticle
      END IF
!--------------------------------------------------------------------------------------------------!
      iReac  = ChemReac%ReactNum(PartSpecies(Coll_pData(iPair)%iPart_p1), PartSpecies(Coll_pData(iPair)%iPart_p2), 1)
!--------------------------------------------------------------------------------------------------!
#if (PP_TimeDiscMethod==42)
      IF (.NOT.DSMC%ReservoirRateStatistic) THEN
        ChemReac%ReacCount(iReac) = ChemReac%ReacCount(iReac) + 1
      END IF
#endif
      ! calculation of recombination probability
      IF (iPart_p3 .GT. 0) THEN
        iReac2 = ChemReac%ReactNumRecomb(PartSpecies(Coll_pData(iPair)%iPart_p1), PartSpecies(Coll_pData(iPair)%iPart_p2), &
                                                                                  PartSpecies(iPart_p3))
        CALL CalcReactionProb(iPair,iReac2,ReactionProb2,iPart_p3,nPartNode,Volume)
      ELSE
        ReactionProb2 = 0.0
      END IF
      CALL RANDOM_NUMBER(iRan)
      IF(ReactionProb2.GT.iRan) THEN
#if (PP_TimeDiscMethod==42)
      IF (.NOT.DSMC%ReservoirRateStatistic) THEN
        ChemReac%NumReac(iReac2) = ChemReac%NumReac(iReac2) + ReactionProb2  ! for calculation of reaction rate coefficient
        ChemReac%ReacCount(iReac2) = ChemReac%ReacCount(iReac2) + 1
      END IF
#endif
          ! Reservoir simulation for obtaining the reaction rate at one given point does not require to perform the reaction
#if (PP_TimeDiscMethod==42)
        IF (.NOT.DSMC%ReservoirSimuRate) THEN
# endif
          CALL DSMC_Chemistry(iPair, iReac2, iPart_p3)
          IF(ChemReac%RecombParticle.EQ. 0) THEN
            Coll_pData(PairForRec)%NeedForRec = .TRUE.
            ChemReac%RecombParticle = Coll_pData(PairForRec)%iPart_p2
          ELSE
            ChemReac%RecombParticle = 0
          END IF
#if (PP_TimeDiscMethod==42)
        END IF
        IF (DSMC%ReservoirRateStatistic) THEN
          ChemReac%NumReac(iReac2) = ChemReac%NumReac(iReac2) + 1  ! for calculation of reaction rate coefficient
        END IF
        RelaxToDo = .FALSE.
# endif
      ELSE
        ! Reservoir simulation for obtaining the reaction rate at one given point does not require to perform the reaction
#if (PP_TimeDiscMethod==42)
        IF (.NOT.DSMC%ReservoirSimuRate) THEN
# endif
          CALL QK_ImpactIonization(iPair,iReac,RelaxToDo)
#if (PP_TimeDiscMethod==42)
        END IF
        IF (DSMC%ReservoirRateStatistic) THEN
          ChemReac%NumReac(iReac) = ChemReac%NumReac(iReac) + 1  ! for calculation of reaction rate coefficient
        END IF
# endif
      END IF

! ############################################################################################################################### !
    CASE(7) ! three diss reactions possible (at least one molecule is polyatomic)
! ############################################################################################################################### !
      iReac  = ChemReac%ReactNum(PartSpecies(Coll_pData(iPair)%iPart_p1), PartSpecies(Coll_pData(iPair)%iPart_p2), 1)
      iReac2 = ChemReac%ReactNum(PartSpecies(Coll_pData(iPair)%iPart_p1), PartSpecies(Coll_pData(iPair)%iPart_p2), 2)
      iReac3 = ChemReac%ReactNum(PartSpecies(Coll_pData(iPair)%iPart_p1), PartSpecies(Coll_pData(iPair)%iPart_p2), 3)
      IF ( ChemReac%QKProcedure(iReac) .OR. ChemReac%QKProcedure(iReac2) .OR. ChemReac%QKProcedure(iReac3) ) THEN ! all Q-K
          CALL Abort(&
__STAMP__&
,'ERROR! Reaction case not supported with Q-K reactions!')
!--------------------------------------------------------------------------------------------------!
      ELSE ! all reactions Arrhenius
!--------------------------------------------------------------------------------------------------!
        ! calculation of first dissociation probability
        CALL CalcReactionProb(iPair,iReac,ReactionProb)
#if (PP_TimeDiscMethod==42)
        IF (.NOT.DSMC%ReservoirRateStatistic) THEN
          ChemReac%NumReac(iReac) = ChemReac%NumReac(iReac) + ReactionProb  ! for calculation of reaction rate coefficient
          ChemReac%ReacCount(iReac) = ChemReac%ReacCount(iReac) + 1
        END IF
#endif
        ! calculation of second dissociation probability
        CALL CalcReactionProb(iPair,iReac2,ReactionProb2)
#if (PP_TimeDiscMethod==42)
        IF (.NOT.DSMC%ReservoirRateStatistic) THEN
          ChemReac%NumReac(iReac2) = ChemReac%NumReac(iReac2) + ReactionProb2  ! for calculation of reaction rate coefficient
          ChemReac%ReacCount(iReac2) = ChemReac%ReacCount(iReac2) + 1
        END IF
#endif
        ! calculation of third dissociation probability
        CALL CalcReactionProb(iPair,iReac3,ReactionProb3)
#if (PP_TimeDiscMethod==42)
        IF (.NOT.DSMC%ReservoirRateStatistic) THEN
          ChemReac%NumReac(iReac3) = ChemReac%NumReac(iReac3) + ReactionProb3  ! for calculation of reaction rate coefficient
          ChemReac%ReacCount(iReac3) = ChemReac%ReacCount(iReac3) + 1
        END IF
#endif
        CALL RANDOM_NUMBER(iRan)
        IF ((ReactionProb + ReactionProb2 + ReactionProb3).GT.iRan) THEN
          CALL RANDOM_NUMBER(iRan)
          CALL RANDOM_NUMBER(iRan2)
          IF((ReactionProb/(ReactionProb + ReactionProb2 + ReactionProb3)).GT.iRan) THEN
            ! Reservoir simulation for obtaining the reaction rate at one given point does not require to perform the reaction
#if (PP_TimeDiscMethod==42)
            IF (.NOT.DSMC%ReservoirSimuRate) THEN
# endif
              CALL DSMC_Chemistry(iPair, iReac)
#if (PP_TimeDiscMethod==42)
            END IF
            IF ( DSMC%ReservoirRateStatistic  ) THEN
              ChemReac%NumReac(iReac) = ChemReac%NumReac(iReac) + 1  ! for calculation of reaction rate coefficient
            END IF
# endif
          ELSEIF(ReactionProb2/(ReactionProb2 + ReactionProb3).GT.iRan2) THEN
            ! Reservoir simulation for obtaining the reaction rate at one given point does not require to perform the reaction
#if (PP_TimeDiscMethod==42)
            IF (.NOT.DSMC%ReservoirSimuRate) THEN
# endif
              CALL DSMC_Chemistry(iPair, iReac2)
#if (PP_TimeDiscMethod==42)
            END IF
            IF (DSMC%ReservoirRateStatistic) THEN
              ChemReac%NumReac(iReac2) = ChemReac%NumReac(iReac2) + 1  ! for calculation of reaction rate coefficient
            END IF
# endif
          ELSE
            ! Reservoir simulation for obtaining the reaction rate at one given point does not require to perform the reaction
#if (PP_TimeDiscMethod==42)
            IF (.NOT.DSMC%ReservoirSimuRate) THEN
# endif
              CALL DSMC_Chemistry(iPair, iReac3)
#if (PP_TimeDiscMethod==42)
            END IF
            IF (DSMC%ReservoirRateStatistic) THEN
              ChemReac%NumReac(iReac3) = ChemReac%NumReac(iReac3) + 1  ! for calculation of reaction rate coefficient
            END IF
# endif
          END IF
          RelaxToDo = .FALSE.
        END IF
      END IF
! ############################################################################################################################### !
    CASE(8) ! four diss reactions possible (at least one polyatomic molecule)
! ############################################################################################################################### !
      iReac  = ChemReac%ReactNum(PartSpecies(Coll_pData(iPair)%iPart_p1), PartSpecies(Coll_pData(iPair)%iPart_p2), 1)
      iReac2 = ChemReac%ReactNum(PartSpecies(Coll_pData(iPair)%iPart_p1), PartSpecies(Coll_pData(iPair)%iPart_p2), 2)
      iReac3 = ChemReac%ReactNum(PartSpecies(Coll_pData(iPair)%iPart_p1), PartSpecies(Coll_pData(iPair)%iPart_p2), 3)
      iReac4 = ChemReac%ReactNum(PartSpecies(Coll_pData(iPair)%iPart_p1), PartSpecies(Coll_pData(iPair)%iPart_p2), 4)
      IF ( ChemReac%QKProcedure(iReac) .OR. ChemReac%QKProcedure(iReac2) &
      .OR. ChemReac%QKProcedure(iReac3) .OR. ChemReac%QKProcedure(iReac4)) THEN ! all Q-K
          CALL Abort(&
__STAMP__&
,'ERROR! Reaction case not supported with Q-K reactions!')
!--------------------------------------------------------------------------------------------------!
      ELSE ! all reactions Arrhenius
!--------------------------------------------------------------------------------------------------!
        ! calculation of first dissociation probability
        CALL CalcReactionProb(iPair,iReac,ReactionProb)
#if (PP_TimeDiscMethod==42)
        IF (.NOT.DSMC%ReservoirRateStatistic) THEN
          ChemReac%NumReac(iReac) = ChemReac%NumReac(iReac) + ReactionProb  ! for calculation of reaction rate coefficient
          ChemReac%ReacCount(iReac) = ChemReac%ReacCount(iReac) + 1
        END IF
#endif
        ! calculation of second dissociation probability
        CALL CalcReactionProb(iPair,iReac2,ReactionProb2)
#if (PP_TimeDiscMethod==42)
        IF (.NOT.DSMC%ReservoirRateStatistic) THEN
          ChemReac%NumReac(iReac2) = ChemReac%NumReac(iReac2) + ReactionProb2  ! for calculation of reaction rate coefficient
          ChemReac%ReacCount(iReac2) = ChemReac%ReacCount(iReac2) + 1
        END IF
#endif
        ! calculation of third dissociation probability
        CALL CalcReactionProb(iPair,iReac3,ReactionProb3)
#if (PP_TimeDiscMethod==42)
        IF (.NOT.DSMC%ReservoirRateStatistic) THEN
          ChemReac%NumReac(iReac3) = ChemReac%NumReac(iReac3) + ReactionProb3  ! for calculation of reaction rate coefficient
          ChemReac%ReacCount(iReac3) = ChemReac%ReacCount(iReac3) + 1
        END IF
#endif
        ! calculation of fourth dissociation probability
        CALL CalcReactionProb(iPair,iReac4,ReactionProb4)
#if (PP_TimeDiscMethod==42)
        IF (.NOT.DSMC%ReservoirRateStatistic) THEN
          ChemReac%NumReac(iReac4) = ChemReac%NumReac(iReac4) + ReactionProb4  ! for calculation of reaction rate coefficient
          ChemReac%ReacCount(iReac4) = ChemReac%ReacCount(iReac4) + 1
        END IF
#endif
        CALL RANDOM_NUMBER(iRan)
        IF ((ReactionProb + ReactionProb2 + ReactionProb3 + ReactionProb4).GT.iRan) THEN
          CALL RANDOM_NUMBER(iRan)
          CALL RANDOM_NUMBER(iRan2)
          CALL RANDOM_NUMBER(iRan3)
          IF((ReactionProb/(ReactionProb + ReactionProb2 + ReactionProb3 + ReactionProb4)).GT.iRan) THEN
            ! Reservoir simulation for obtaining the reaction rate at one given point does not require to perform the reaction
#if (PP_TimeDiscMethod==42)
            IF (.NOT.DSMC%ReservoirSimuRate) THEN
# endif
              CALL DSMC_Chemistry(iPair, iReac)
#if (PP_TimeDiscMethod==42)
            END IF
            IF (DSMC%ReservoirRateStatistic) THEN
              ChemReac%NumReac(iReac) = ChemReac%NumReac(iReac) + 1  ! for calculation of reaction rate coefficient
            END IF
# endif
          ELSEIF(ReactionProb2/(ReactionProb2 + ReactionProb3 + ReactionProb4).GT.iRan2) THEN
            ! Reservoir simulation for obtaining the reaction rate at one given point does not require to perform the reaction
#if (PP_TimeDiscMethod==42)
            IF (.NOT.DSMC%ReservoirSimuRate) THEN
# endif
              CALL DSMC_Chemistry(iPair, iReac2)
#if (PP_TimeDiscMethod==42)
            END IF
            IF (DSMC%ReservoirRateStatistic) THEN
              ChemReac%NumReac(iReac2) = ChemReac%NumReac(iReac2) + 1  ! for calculation of reaction rate coefficient
            END IF
# endif
          ELSEIF(ReactionProb3/(ReactionProb3 + ReactionProb4).GT.iRan3) THEN
            ! Reservoir simulation for obtaining the reaction rate at one given point does not require to perform the reaction
#if (PP_TimeDiscMethod==42)
            IF (.NOT.DSMC%ReservoirSimuRate) THEN
# endif
              CALL DSMC_Chemistry(iPair, iReac3)
#if (PP_TimeDiscMethod==42)
            END IF
            IF (DSMC%ReservoirRateStatistic) THEN
              ChemReac%NumReac(iReac3) = ChemReac%NumReac(iReac3) + 1  ! for calculation of reaction rate coefficient
            END IF
# endif
          ELSE
            ! Reservoir simulation for obtaining the reaction rate at one given point does not require to perform the reaction
#if (PP_TimeDiscMethod==42)
            IF (.NOT.DSMC%ReservoirSimuRate) THEN
# endif
              CALL DSMC_Chemistry(iPair, iReac4)
#if (PP_TimeDiscMethod==42)
            END IF
            IF (DSMC%ReservoirRateStatistic) THEN
              ChemReac%NumReac(iReac4) = ChemReac%NumReac(iReac4) + 1  ! for calculation of reaction rate coefficient
            END IF
# endif
          END IF
          RelaxToDo = .FALSE.
        END IF
      END IF
! ############################################################################################################################### !
    CASE(9) ! three diss and one exchange reaction possible (at least one polyatomic molecule)
! ############################################################################################################################### !
      iReac  = ChemReac%ReactNum(PartSpecies(Coll_pData(iPair)%iPart_p1), PartSpecies(Coll_pData(iPair)%iPart_p2), 1)
      iReac2 = ChemReac%ReactNum(PartSpecies(Coll_pData(iPair)%iPart_p1), PartSpecies(Coll_pData(iPair)%iPart_p2), 2)
      iReac3 = ChemReac%ReactNum(PartSpecies(Coll_pData(iPair)%iPart_p1), PartSpecies(Coll_pData(iPair)%iPart_p2), 3)
      iReac4 = ChemReac%ReactNum(PartSpecies(Coll_pData(iPair)%iPart_p1), PartSpecies(Coll_pData(iPair)%iPart_p2), 4)
      IF ( ChemReac%QKProcedure(iReac) .OR. ChemReac%QKProcedure(iReac2) &
      .OR. ChemReac%QKProcedure(iReac3) .OR. ChemReac%QKProcedure(iReac4)) THEN ! all Q-K
          CALL Abort(&
__STAMP__&
,'ERROR! Reaction case not supported with Q-K reactions!')
!--------------------------------------------------------------------------------------------------!
      ELSE ! all reactions Arrhenius
!--------------------------------------------------------------------------------------------------!
        ! calculation of first dissociation probability
        CALL CalcReactionProb(iPair,iReac,ReactionProb)
#if (PP_TimeDiscMethod==42)
        IF (.NOT.DSMC%ReservoirRateStatistic) THEN
          ChemReac%NumReac(iReac) = ChemReac%NumReac(iReac) + ReactionProb  ! for calculation of reaction rate coefficient
          ChemReac%ReacCount(iReac) = ChemReac%ReacCount(iReac) + 1
        END IF
#endif
        ! calculation of second dissociation probability
        CALL CalcReactionProb(iPair,iReac2,ReactionProb2)
#if (PP_TimeDiscMethod==42)
        IF (.NOT.DSMC%ReservoirRateStatistic) THEN
          ChemReac%NumReac(iReac2) = ChemReac%NumReac(iReac2) + ReactionProb2  ! for calculation of reaction rate coefficient
          ChemReac%ReacCount(iReac2) = ChemReac%ReacCount(iReac2) + 1
        END IF
#endif
        ! calculation of third dissociation probability
        CALL CalcReactionProb(iPair,iReac3,ReactionProb3)
#if (PP_TimeDiscMethod==42)
        IF (.NOT.DSMC%ReservoirRateStatistic) THEN
          ChemReac%NumReac(iReac3) = ChemReac%NumReac(iReac3) + ReactionProb3  ! for calculation of reaction rate coefficient
          ChemReac%ReacCount(iReac3) = ChemReac%ReacCount(iReac3) + 1
        END IF
#endif
        ! calculation of exchange probability
        CALL CalcReactionProb(iPair,iReac4,ReactionProb4)
#if (PP_TimeDiscMethod==42)
        IF (.NOT.DSMC%ReservoirRateStatistic) THEN
          ChemReac%NumReac(iReac4) = ChemReac%NumReac(iReac4) + ReactionProb4  ! for calculation of reaction rate coefficient
          ChemReac%ReacCount(iReac4) = ChemReac%ReacCount(iReac4) + 1
        END IF
#endif
        CALL RANDOM_NUMBER(iRan)
        IF ((ReactionProb + ReactionProb2 + ReactionProb3 + ReactionProb4).GT.iRan) THEN
          CALL RANDOM_NUMBER(iRan)
          CALL RANDOM_NUMBER(iRan2)
          CALL RANDOM_NUMBER(iRan3)
          IF((ReactionProb/(ReactionProb + ReactionProb2 + ReactionProb3 + ReactionProb4)).GT.iRan) THEN
            ! Reservoir simulation for obtaining the reaction rate at one given point does not require to perform the reaction
#if (PP_TimeDiscMethod==42)
            IF (.NOT.DSMC%ReservoirSimuRate) THEN
# endif
              CALL DSMC_Chemistry(iPair, iReac)
#if (PP_TimeDiscMethod==42)
            END IF
            IF (DSMC%ReservoirRateStatistic) THEN
              ChemReac%NumReac(iReac) = ChemReac%NumReac(iReac) + 1  ! for calculation of reaction rate coefficient
            END IF
# endif
          ELSEIF(ReactionProb2/(ReactionProb2 + ReactionProb3 + ReactionProb4).GT.iRan2) THEN
            ! Reservoir simulation for obtaining the reaction rate at one given point does not require to perform the reaction
#if (PP_TimeDiscMethod==42)
            IF (.NOT.DSMC%ReservoirSimuRate) THEN
# endif
              CALL DSMC_Chemistry(iPair, iReac2)
#if (PP_TimeDiscMethod==42)
            END IF
            IF (DSMC%ReservoirRateStatistic) THEN
              ChemReac%NumReac(iReac2) = ChemReac%NumReac(iReac2) + 1  ! for calculation of reaction rate coefficient
            END IF
# endif
          ELSEIF(ReactionProb3/(ReactionProb3 + ReactionProb4).GT.iRan3) THEN
            ! Reservoir simulation for obtaining the reaction rate at one given point does not require to perform the reaction
#if (PP_TimeDiscMethod==42)
            IF (.NOT.DSMC%ReservoirSimuRate) THEN
# endif
              CALL DSMC_Chemistry(iPair, iReac3)
#if (PP_TimeDiscMethod==42)
            END IF
            IF (DSMC%ReservoirRateStatistic) THEN
              ChemReac%NumReac(iReac3) = ChemReac%NumReac(iReac3) + 1  ! for calculation of reaction rate coefficient
            END IF
# endif
          ELSE
            ! Reservoir simulation for obtaining the reaction rate at one given point does not require to perform the reaction
#if (PP_TimeDiscMethod==42)
            IF (.NOT.DSMC%ReservoirSimuRate) THEN
# endif
              CALL DSMC_Chemistry(iPair, iReac4)
#if (PP_TimeDiscMethod==42)
            END IF
            IF (DSMC%ReservoirRateStatistic) THEN
              ChemReac%NumReac(iReac4) = ChemReac%NumReac(iReac4) + 1  ! for calculation of reaction rate coefficient
            END IF
# endif
          END IF
          RelaxToDo = .FALSE.
        END IF
      END IF
! ############################################################################################################################### !
    CASE(10) ! two diss and one exchange reaction possible
! ############################################################################################################################### !
      iReac  = ChemReac%ReactNum(PartSpecies(Coll_pData(iPair)%iPart_p1), PartSpecies(Coll_pData(iPair)%iPart_p2), 1)
      iReac2 = ChemReac%ReactNum(PartSpecies(Coll_pData(iPair)%iPart_p1), PartSpecies(Coll_pData(iPair)%iPart_p2), 2)
      iReac3 = ChemReac%ReactNum(PartSpecies(Coll_pData(iPair)%iPart_p1), PartSpecies(Coll_pData(iPair)%iPart_p2), 3)
      IF ( ChemReac%QKProcedure(iReac) .OR. ChemReac%QKProcedure(iReac2) .OR. ChemReac%QKProcedure(iReac3) ) THEN ! all Q-K
          CALL Abort(&
__STAMP__&
,'ERROR! Reaction case not supported with Q-K reactions!')
!--------------------------------------------------------------------------------------------------!
      ELSE ! all reactions Arrhenius
!--------------------------------------------------------------------------------------------------!
        ! calculation of first dissociation probability
          CALL CalcReactionProb(iPair,iReac,ReactionProb)
#if (PP_TimeDiscMethod==42)
        IF (.NOT.DSMC%ReservoirRateStatistic) THEN
          ChemReac%NumReac(iReac) = ChemReac%NumReac(iReac) + ReactionProb  ! for calculation of reaction rate coefficient
          ChemReac%ReacCount(iReac) = ChemReac%ReacCount(iReac) + 1
        END IF
#endif
        ! calculation of second dissociation probability
          CALL CalcReactionProb(iPair,iReac2,ReactionProb2)
#if (PP_TimeDiscMethod==42)
        IF (.NOT.DSMC%ReservoirRateStatistic) THEN
          ChemReac%NumReac(iReac2) = ChemReac%NumReac(iReac2) + ReactionProb2  ! for calculation of reaction rate coefficient
          ChemReac%ReacCount(iReac2) = ChemReac%ReacCount(iReac2) + 1
        END IF
#endif
        ! calculation of exchange probability
        CALL CalcReactionProb(iPair,iReac3,ReactionProb3)
#if (PP_TimeDiscMethod==42)
        IF (.NOT.DSMC%ReservoirRateStatistic) THEN
          ChemReac%NumReac(iReac3) = ChemReac%NumReac(iReac3) + ReactionProb3  ! for calculation of reaction rate coefficient
          ChemReac%ReacCount(iReac3) = ChemReac%ReacCount(iReac3) + 1
        END IF
#endif
        CALL RANDOM_NUMBER(iRan)
        IF ((ReactionProb + ReactionProb2 + ReactionProb3).GT.iRan) THEN
          CALL RANDOM_NUMBER(iRan)
          CALL RANDOM_NUMBER(iRan2)
          IF((ReactionProb/(ReactionProb + ReactionProb2 + ReactionProb3)).GT.iRan) THEN
            ! Reservoir simulation for obtaining the reaction rate at one given point does not require to perform the reaction
#if (PP_TimeDiscMethod==42)
            IF (.NOT.DSMC%ReservoirSimuRate) THEN
# endif
              CALL DSMC_Chemistry(iPair, iReac)
#if (PP_TimeDiscMethod==42)
            END IF
            IF (DSMC%ReservoirRateStatistic) THEN
              ChemReac%NumReac(iReac) = ChemReac%NumReac(iReac) + 1  ! for calculation of reaction rate coefficient
            END IF
# endif
          ELSEIF(ReactionProb2/(ReactionProb2 + ReactionProb3).GT.iRan2) THEN
            ! Reservoir simulation for obtaining the reaction rate at one given point does not require to perform the reaction
#if (PP_TimeDiscMethod==42)
            IF (.NOT.DSMC%ReservoirSimuRate) THEN
# endif
              CALL DSMC_Chemistry(iPair, iReac2)
#if (PP_TimeDiscMethod==42)
            END IF
            IF (DSMC%ReservoirRateStatistic) THEN
              ChemReac%NumReac(iReac2) = ChemReac%NumReac(iReac2) + 1  ! for calculation of reaction rate coefficient
            END IF
# endif
          ELSE
            ! Reservoir simulation for obtaining the reaction rate at one given point does not require to perform the reaction
#if (PP_TimeDiscMethod==42)
            IF (.NOT.DSMC%ReservoirSimuRate) THEN
# endif
              CALL DSMC_Chemistry(iPair, iReac3)
#if (PP_TimeDiscMethod==42)
            END IF
            IF (DSMC%ReservoirRateStatistic) THEN
              ChemReac%NumReac(iReac3) = ChemReac%NumReac(iReac3) + 1  ! for calculation of reaction rate coefficient
            END IF
# endif
          END IF
          RelaxToDo = .FALSE.
        END IF
      END IF
! ############################################################################################################################### !
    CASE(11) ! two diss, one exchange and one recombination reaction possible
! ############################################################################################################################### !
      ! searching third collison partner
      IF(ChemReac%RecombParticle.EQ. 0) THEN
        IF(iPair.LT.(nPair - ChemReac%nPairForRec)) THEN
          PairForRec = nPair - ChemReac%nPairForRec
          ChemReac%nPairForRec = ChemReac%nPairForRec + 1
          iPart_p3 = Coll_pData(PairForRec)%iPart_p1
        ELSE
          iPart_p3 = 0
        END IF
      ELSE
        iPart_p3 = ChemReac%RecombParticle
      END IF
!--------------------------------------------------------------------------------------------------!
      iReac  = ChemReac%ReactNum(PartSpecies(Coll_pData(iPair)%iPart_p1), PartSpecies(Coll_pData(iPair)%iPart_p2), 1)
      iReac2 = ChemReac%ReactNum(PartSpecies(Coll_pData(iPair)%iPart_p1), PartSpecies(Coll_pData(iPair)%iPart_p2), 2)
      iReac3 = ChemReac%ReactNum(PartSpecies(Coll_pData(iPair)%iPart_p1), PartSpecies(Coll_pData(iPair)%iPart_p2), 3)
      IF ( ChemReac%QKProcedure(iReac) .OR. ChemReac%QKProcedure(iReac2) &
      .OR. ChemReac%QKProcedure(iReac3)) THEN ! all Q-K
        CALL Abort(&
__STAMP__&
,'ERROR! Reaction case not supported with Q-K reactions!')
!--------------------------------------------------------------------------------------------------!
      ELSE ! all reactions Arrhenius
!--------------------------------------------------------------------------------------------------!
        ! calculation of first dissociation probability
        CALL CalcReactionProb(iPair,iReac,ReactionProb)
#if (PP_TimeDiscMethod==42)
        IF (.NOT.DSMC%ReservoirRateStatistic) THEN
          ChemReac%NumReac(iReac) = ChemReac%NumReac(iReac) + ReactionProb  ! for calculation of reaction rate coefficient
          ChemReac%ReacCount(iReac) = ChemReac%ReacCount(iReac) + 1
        END IF
# endif
        ! calculation of second dissociation probability
          CALL CalcReactionProb(iPair,iReac2,ReactionProb2)
#if (PP_TimeDiscMethod==42)
        IF (.NOT.DSMC%ReservoirRateStatistic) THEN
          ChemReac%NumReac(iReac2) = ChemReac%NumReac(iReac2) + ReactionProb2  ! for calculation of reaction rate coefficient
          ChemReac%ReacCount(iReac2) = ChemReac%ReacCount(iReac2) + 1
        END IF
# endif
        ! calculation of exchange probability
        CALL CalcReactionProb(iPair,iReac3,ReactionProb3)
#if (PP_TimeDiscMethod==42)
        IF (.NOT.DSMC%ReservoirRateStatistic) THEN
          ChemReac%NumReac(iReac3) = ChemReac%NumReac(iReac3) + ReactionProb3  ! for calculation of reaction rate coefficient
          ChemReac%ReacCount(iReac3) = ChemReac%ReacCount(iReac3) + 1
        END IF
#endif
        ! calculation of recombination probability
        IF (iPart_p3 .GT. 0) THEN
          iReac4 = ChemReac%ReactNumRecomb(PartSpecies(Coll_pData(iPair)%iPart_p1), &
                                           PartSpecies(Coll_pData(iPair)%iPart_p2), &
                                           PartSpecies(iPart_p3))
          CALL CalcReactionProb(iPair,iReac4,ReactionProb4,iPart_p3,nPartNode,Volume)
        ELSE
          ReactionProb4 = 0.0
        END IF
#if (PP_TimeDiscMethod==42)
        IF ((.NOT.DSMC%ReservoirRateStatistic).AND.(iPart_p3.GT.0)) THEN
          ChemReac%NumReac(iReac4) = ChemReac%NumReac(iReac4) + ReactionProb4  ! for calculation of reaction rate coefficient
        END IF
# endif
        ! reaction decision
        CALL RANDOM_NUMBER(iRan)
        IF ((ReactionProb + ReactionProb2 + ReactionProb3 + ReactionProb4).GT.iRan) THEN
          CALL RANDOM_NUMBER(iRan)
          CALL RANDOM_NUMBER(iRan2)
          CALL RANDOM_NUMBER(iRan3)
          IF((ReactionProb/(ReactionProb + ReactionProb2 + ReactionProb3 + ReactionProb4)).GT.iRan) THEN
            ! Reservoir simulation for obtaining the reaction rate at one given point does not require to perform the reaction
#if (PP_TimeDiscMethod==42)
            IF (.NOT.DSMC%ReservoirSimuRate) THEN
# endif
              CALL DSMC_Chemistry(iPair, iReac)
#if (PP_TimeDiscMethod==42)
            END IF
            IF (DSMC%ReservoirRateStatistic) THEN
              ChemReac%NumReac(iReac) = ChemReac%NumReac(iReac) + 1  ! for calculation of reaction rate coefficient
            END IF
# endif
          ELSEIF(ReactionProb2/(ReactionProb2 + ReactionProb3 + ReactionProb4).GT.iRan2) THEN
            ! Reservoir simulation for obtaining the reaction rate at one given point does not require to perform the reaction
#if (PP_TimeDiscMethod==42)
            IF (.NOT.DSMC%ReservoirSimuRate) THEN
# endif
              CALL DSMC_Chemistry(iPair, iReac2)
#if (PP_TimeDiscMethod==42)
            END IF
            IF (DSMC%ReservoirRateStatistic) THEN
              ChemReac%NumReac(iReac2) = ChemReac%NumReac(iReac2) + 1  ! for calculation of reaction rate coefficient
            END IF
# endif
          ELSEIF(ReactionProb3/(ReactionProb3 + ReactionProb4).GT.iRan3) THEN
            ! Reservoir simulation for obtaining the reaction rate at one given point does not require to perform the reaction
#if (PP_TimeDiscMethod==42)
            IF (.NOT.DSMC%ReservoirSimuRate) THEN
# endif
              CALL DSMC_Chemistry(iPair, iReac3)
#if (PP_TimeDiscMethod==42)
            END IF
            IF (DSMC%ReservoirRateStatistic) THEN
              ChemReac%NumReac(iReac3) = ChemReac%NumReac(iReac3) + 1  ! for calculation of reaction rate coefficient
            END IF
# endif
          ELSEIF(ReactionProb4.GT.0.0) THEN ! Probability is set to zero if no third collision partner is found
#if (PP_TimeDiscMethod==42)
            IF (.NOT.DSMC%ReservoirSimuRate) THEN
# endif
              CALL DSMC_Chemistry(iPair, iReac4, iPart_p3)
              IF(ChemReac%RecombParticle.EQ. 0) THEN
                Coll_pData(PairForRec)%NeedForRec = .TRUE.
                ChemReac%RecombParticle = Coll_pData(PairForRec)%iPart_p2
              ELSE
                ChemReac%RecombParticle = 0
              END IF
#if (PP_TimeDiscMethod==42)
            END IF
            IF (DSMC%ReservoirRateStatistic) THEN
              ChemReac%NumReac(iReac4) = ChemReac%NumReac(iReac4) + 1  ! for calculation of reaction rate coefficient
            END IF
# endif
          END IF
          RelaxToDo = .FALSE.
        END IF
      END IF
! ############################################################################################################################### !
    CASE(12) ! two diss and one recomb reaction possible
! ############################################################################################################################### !
      ! searching third collison partner
      IF(ChemReac%RecombParticle.EQ. 0) THEN
        IF(iPair.LT.(nPair - ChemReac%nPairForRec)) THEN
          PairForRec = nPair - ChemReac%nPairForRec
          ChemReac%nPairForRec = ChemReac%nPairForRec + 1
          iPart_p3 = Coll_pData(PairForRec)%iPart_p1
        ELSE
          iPart_p3 = 0
        END IF
      ELSE
        iPart_p3 = ChemReac%RecombParticle
      END IF
!--------------------------------------------------------------------------------------------------!
      iReac  = ChemReac%ReactNum(PartSpecies(Coll_pData(iPair)%iPart_p1), PartSpecies(Coll_pData(iPair)%iPart_p2), 1)
      iReac2 = ChemReac%ReactNum(PartSpecies(Coll_pData(iPair)%iPart_p1), PartSpecies(Coll_pData(iPair)%iPart_p2), 2)
      IF (ChemReac%QKProcedure(iReac).OR.ChemReac%QKProcedure(iReac2)) THEN ! all Q-K
        CALL Abort(&
         __STAMP__,&
        'ERROR! Reaction case not supported with Q-K reactions!')
!--------------------------------------------------------------------------------------------------!
      ELSE ! all reactions Arrhenius
!--------------------------------------------------------------------------------------------------!
        ! calculation of first dissociation probability
        CALL CalcReactionProb(iPair,iReac,ReactionProb)
#if (PP_TimeDiscMethod==42)
        IF (.NOT.DSMC%ReservoirRateStatistic) THEN
          ChemReac%NumReac(iReac) = ChemReac%NumReac(iReac) + ReactionProb  ! for calculation of reaction rate coefficient
          ChemReac%ReacCount(iReac) = ChemReac%ReacCount(iReac) + 1
        END IF
#endif
        ! calculation of second dissociation probability
          CALL CalcReactionProb(iPair,iReac2,ReactionProb2)
#if (PP_TimeDiscMethod==42)
        IF (.NOT.DSMC%ReservoirRateStatistic) THEN
          ChemReac%NumReac(iReac2) = ChemReac%NumReac(iReac2) + ReactionProb2  ! for calculation of reaction rate coefficient
          ChemReac%ReacCount(iReac2) = ChemReac%ReacCount(iReac2) + 1
        END IF
#endif
        ! calculation of recombination probability
        IF (iPart_p3 .GT. 0) THEN
          iReac3 = ChemReac%ReactNumRecomb(PartSpecies(Coll_pData(iPair)%iPart_p1), PartSpecies(Coll_pData(iPair)%iPart_p2), &
                                                                                      PartSpecies(iPart_p3))
          CALL CalcReactionProb(iPair,iReac3,ReactionProb3,iPart_p3,nPartNode,Volume)
        ELSE 
          ReactionProb3 = 0.0
        END IF
#if (PP_TimeDiscMethod==42)
        IF ((.NOT.DSMC%ReservoirRateStatistic).AND.(iPart_p3.GT.0)) THEN
          ChemReac%NumReac(iReac3) = ChemReac%NumReac(iReac3) + ReactionProb3  ! for calculation of reaction rate coefficient
          ChemReac%ReacCount(iReac3) = ChemReac%ReacCount(iReac3) + 1
        END IF
#endif
        CALL RANDOM_NUMBER(iRan)
        IF ((ReactionProb + ReactionProb2 + ReactionProb3).GT.iRan) THEN
          CALL RANDOM_NUMBER(iRan)
          CALL RANDOM_NUMBER(iRan2)
          IF((ReactionProb/(ReactionProb + ReactionProb2 + ReactionProb3)).GT.iRan) THEN
            ! Reservoir simulation for obtaining the reaction rate at one given point does not require to perform the reaction
#if (PP_TimeDiscMethod==42)
            IF (.NOT.DSMC%ReservoirSimuRate) THEN
# endif
              CALL DSMC_Chemistry(iPair, iReac)
#if (PP_TimeDiscMethod==42)
            END IF
            IF (DSMC%ReservoirRateStatistic) THEN
              ChemReac%NumReac(iReac) = ChemReac%NumReac(iReac) + 1  ! for calculation of reaction rate coefficient
            END IF
# endif
          ELSEIF(ReactionProb2/(ReactionProb2 + ReactionProb3).GT.iRan2) THEN
            ! Reservoir simulation for obtaining the reaction rate at one given point does not require to perform the reaction
#if (PP_TimeDiscMethod==42)
            IF (.NOT.DSMC%ReservoirSimuRate) THEN
# endif
              CALL DSMC_Chemistry(iPair, iReac2)
#if (PP_TimeDiscMethod==42)
            END IF
            IF (DSMC%ReservoirRateStatistic) THEN
              ChemReac%NumReac(iReac2) = ChemReac%NumReac(iReac2) + 1  ! for calculation of reaction rate coefficient
            END IF
# endif
          ELSEIF(ReactionProb3.GT.0.0) THEN ! Probability is set to zero if no third collision partner is found
#if (PP_TimeDiscMethod==42)
            IF (.NOT.DSMC%ReservoirSimuRate) THEN
# endif
              CALL DSMC_Chemistry(iPair, iReac3, iPart_p3)
              IF(ChemReac%RecombParticle.EQ. 0) THEN
                Coll_pData(PairForRec)%NeedForRec = .TRUE.
                ChemReac%RecombParticle = Coll_pData(PairForRec)%iPart_p2
              ELSE
                ChemReac%RecombParticle = 0
              END IF
#if (PP_TimeDiscMethod==42)
            END IF
            IF (DSMC%ReservoirRateStatistic) THEN
              ChemReac%NumReac(iReac3) = ChemReac%NumReac(iReac3) + 1  ! for calculation of reaction rate coefficient
            END IF
# endif
          END IF
          RelaxToDo = .FALSE.
        END IF ! Prob > iRan
      END IF ! Q-K
! ############################################################################################################################### !
    CASE(13) ! one diss, one exchange and one recomb reaction possible
! ############################################################################################################################### !
      ! searching third collison partner
      IF(ChemReac%RecombParticle.EQ. 0) THEN
        IF(iPair.LT.(nPair - ChemReac%nPairForRec)) THEN
          PairForRec = nPair - ChemReac%nPairForRec
          ChemReac%nPairForRec = ChemReac%nPairForRec + 1
          iPart_p3 = Coll_pData(PairForRec)%iPart_p1
        ELSE
          iPart_p3 = 0
        END IF
      ELSE
        iPart_p3 = ChemReac%RecombParticle
      END IF
!--------------------------------------------------------------------------------------------------!
      iReac  = ChemReac%ReactNum(PartSpecies(Coll_pData(iPair)%iPart_p1), PartSpecies(Coll_pData(iPair)%iPart_p2), 1)
      iReac2 = ChemReac%ReactNum(PartSpecies(Coll_pData(iPair)%iPart_p1), PartSpecies(Coll_pData(iPair)%iPart_p2), 2)
      IF (ChemReac%QKProcedure(iReac).OR.ChemReac%QKProcedure(iReac2)) THEN ! all Q-K
        CALL Abort(&
         __STAMP__,&
        'ERROR! Reaction case not supported with Q-K reactions!')
!--------------------------------------------------------------------------------------------------!
      ELSE ! all reactions Arrhenius
!--------------------------------------------------------------------------------------------------!
        ! calculation of first dissociation probability
        CALL CalcReactionProb(iPair,iReac,ReactionProb)
#if (PP_TimeDiscMethod==42)
        IF (.NOT.DSMC%ReservoirRateStatistic) THEN
          ChemReac%NumReac(iReac) = ChemReac%NumReac(iReac) + ReactionProb  ! for calculation of reaction rate coefficient
          ChemReac%ReacCount(iReac) = ChemReac%ReacCount(iReac) + 1
        END IF
#endif
        ! calculation of exchange probability
        CALL CalcReactionProb(iPair,iReac2,ReactionProb2)
#if (PP_TimeDiscMethod==42)
        IF (.NOT.DSMC%ReservoirRateStatistic) THEN
          ChemReac%NumReac(iReac2) = ChemReac%NumReac(iReac2) + ReactionProb2  ! for calculation of reaction rate coefficient
          ChemReac%ReacCount(iReac2) = ChemReac%ReacCount(iReac2) + 1
        END IF
#endif
        ! calculation of recombination probability
        IF (iPart_p3 .GT. 0) THEN
          iReac3 = ChemReac%ReactNumRecomb(PartSpecies(Coll_pData(iPair)%iPart_p1), PartSpecies(Coll_pData(iPair)%iPart_p2), &
                                                                                  PartSpecies(iPart_p3))
          CALL CalcReactionProb(iPair,iReac3,ReactionProb3,iPart_p3,nPartNode,Volume)
        ELSE 
          ReactionProb3 = 0.0
        END IF
#if (PP_TimeDiscMethod==42)
        IF ((.NOT.DSMC%ReservoirRateStatistic).AND.(iPart_p3.GT.0)) THEN
          ChemReac%NumReac(iReac3) = ChemReac%NumReac(iReac3) + ReactionProb3  ! for calculation of reaction rate coefficient
          ChemReac%ReacCount(iReac3) = ChemReac%ReacCount(iReac3) + 1
        END IF
#endif
        CALL RANDOM_NUMBER(iRan)
        IF ((ReactionProb + ReactionProb2 + ReactionProb3).GT.iRan) THEN
          CALL RANDOM_NUMBER(iRan)
          CALL RANDOM_NUMBER(iRan2)
          IF((ReactionProb/(ReactionProb + ReactionProb2 + ReactionProb3)).GT.iRan) THEN
            ! Reservoir simulation for obtaining the reaction rate at one given point does not require to perform the reaction
#if (PP_TimeDiscMethod==42)
            IF (.NOT.DSMC%ReservoirSimuRate) THEN
# endif
              CALL DSMC_Chemistry(iPair, iReac)
#if (PP_TimeDiscMethod==42)
            END IF
            IF (DSMC%ReservoirRateStatistic) THEN
              ChemReac%NumReac(iReac) = ChemReac%NumReac(iReac) + 1  ! for calculation of reaction rate coefficient
            END IF
# endif
          ELSEIF(ReactionProb2/(ReactionProb2 + ReactionProb3).GT.iRan2) THEN
            ! Reservoir simulation for obtaining the reaction rate at one given point does not require to perform the reaction
#if (PP_TimeDiscMethod==42)
            IF (.NOT.DSMC%ReservoirSimuRate) THEN
# endif
              CALL DSMC_Chemistry(iPair, iReac2)
#if (PP_TimeDiscMethod==42)
            END IF
            IF (DSMC%ReservoirRateStatistic) THEN
              ChemReac%NumReac(iReac2) = ChemReac%NumReac(iReac2) + 1  ! for calculation of reaction rate coefficient
            END IF
# endif
          ELSEIF(ReactionProb3.GT.0.0) THEN ! Probability is set to zero if no third collision partner is found
#if (PP_TimeDiscMethod==42)
            IF (.NOT.DSMC%ReservoirSimuRate) THEN
# endif
              CALL DSMC_Chemistry(iPair, iReac3, iPart_p3)
              IF(ChemReac%RecombParticle.EQ. 0) THEN
                Coll_pData(PairForRec)%NeedForRec = .TRUE.
                ChemReac%RecombParticle = Coll_pData(PairForRec)%iPart_p2
              ELSE
                ChemReac%RecombParticle = 0
              END IF
#if (PP_TimeDiscMethod==42)
            END IF
            IF (DSMC%ReservoirRateStatistic) THEN
              ChemReac%NumReac(iReac3) = ChemReac%NumReac(iReac3) + 1  ! for calculation of reaction rate coefficient
            END IF
# endif
          END IF
          RelaxToDo = .FALSE.
        END IF ! Prob > iRan
      END IF ! Q-K
! ############################################################################################################################### !
    CASE(14) ! one diss and one recomb reaction possible
! ############################################################################################################################### !
      ! searching third collison partner
      IF(ChemReac%RecombParticle.EQ. 0) THEN
        IF(iPair.LT.(nPair - ChemReac%nPairForRec)) THEN
          PairForRec = nPair - ChemReac%nPairForRec
          ChemReac%nPairForRec = ChemReac%nPairForRec + 1
          iPart_p3 = Coll_pData(PairForRec)%iPart_p1
        ELSE
          iPart_p3 = 0
        END IF
      ELSE
        iPart_p3 = ChemReac%RecombParticle
      END IF
!--------------------------------------------------------------------------------------------------!
      iReac  = ChemReac%ReactNum(PartSpecies(Coll_pData(iPair)%iPart_p1), PartSpecies(Coll_pData(iPair)%iPart_p2), 1)
      IF(ChemReac%QKProcedure(iReac)) THEN ! all Q-K
        CALL Abort(&
         __STAMP__,&
        'ERROR! Reaction case not supported with Q-K reactions!')
!--------------------------------------------------------------------------------------------------!
      ELSE ! all reactions Arrhenius
!--------------------------------------------------------------------------------------------------!
        ! calculation of first dissociation probability
        CALL CalcReactionProb(iPair,iReac,ReactionProb)
#if (PP_TimeDiscMethod==42)
        IF (.NOT.DSMC%ReservoirRateStatistic) THEN
          ChemReac%NumReac(iReac) = ChemReac%NumReac(iReac) + ReactionProb  ! for calculation of reaction rate coefficient
          ChemReac%ReacCount(iReac) = ChemReac%ReacCount(iReac) + 1
        END IF
#endif
        ! calculation of recombination probability
        IF (iPart_p3 .GT. 0) THEN
          iReac2 = ChemReac%ReactNumRecomb(PartSpecies(Coll_pData(iPair)%iPart_p1), PartSpecies(Coll_pData(iPair)%iPart_p2), &
                                                                                    PartSpecies(iPart_p3))
          CALL CalcReactionProb(iPair,iReac2,ReactionProb2,iPart_p3,nPartNode,Volume)
        ELSE
          ReactionProb2 = 0.0
        END IF
#if (PP_TimeDiscMethod==42)
        IF ((.NOT.DSMC%ReservoirRateStatistic).AND.(iPart_p3.GT.0)) THEN
          ChemReac%NumReac(iReac2) = ChemReac%NumReac(iReac2) + ReactionProb2  ! for calculation of reaction rate coefficient
          ChemReac%ReacCount(iReac2) = ChemReac%ReacCount(iReac2) + 1
        END IF
#endif
        CALL RANDOM_NUMBER(iRan)
        IF ((ReactionProb + ReactionProb2).GT.iRan) THEN
          CALL RANDOM_NUMBER(iRan)
          IF((ReactionProb/(ReactionProb + ReactionProb2)).GT.iRan) THEN
            ! Reservoir simulation for obtaining the reaction rate at one given point does not require to perform the reaction
#if (PP_TimeDiscMethod==42)
            IF (.NOT.DSMC%ReservoirSimuRate) THEN
# endif
              CALL DSMC_Chemistry(iPair, iReac)
#if (PP_TimeDiscMethod==42)
            END IF
            IF (DSMC%ReservoirRateStatistic) THEN
              ChemReac%NumReac(iReac) = ChemReac%NumReac(iReac) + 1  ! for calculation of reaction rate coefficient
            END IF
# endif
          ELSEIF(ReactionProb2.GT.0.0) THEN ! Probability is set to zero if no third collision partner is found
#if (PP_TimeDiscMethod==42)
            IF (.NOT.DSMC%ReservoirSimuRate) THEN
# endif
              CALL DSMC_Chemistry(iPair, iReac2, iPart_p3)
              IF(ChemReac%RecombParticle.EQ. 0) THEN
                Coll_pData(PairForRec)%NeedForRec = .TRUE.
                ChemReac%RecombParticle = Coll_pData(PairForRec)%iPart_p2
              ELSE
                ChemReac%RecombParticle = 0
              END IF
#if (PP_TimeDiscMethod==42)
            END IF
            IF (DSMC%ReservoirRateStatistic) THEN
              ChemReac%NumReac(iReac2) = ChemReac%NumReac(iReac2) + 1  ! for calculation of reaction rate coefficient
            END IF
# endif
          END IF
          RelaxToDo = .FALSE.
        END IF
      END IF
! ############################################################################################################################### !
    CASE(15) ! one exchange and one recomb reaction possible
! ############################################################################################################################### !
      ! searching third collison partner
      IF(ChemReac%RecombParticle.EQ. 0) THEN
        IF(iPair.LT.(nPair - ChemReac%nPairForRec)) THEN
          PairForRec = nPair - ChemReac%nPairForRec
          ChemReac%nPairForRec = ChemReac%nPairForRec + 1
          iPart_p3 = Coll_pData(PairForRec)%iPart_p1
        ELSE
          iPart_p3 = 0
        END IF
      ELSE
        iPart_p3 = ChemReac%RecombParticle
      END IF
!--------------------------------------------------------------------------------------------------!
      iReac  = ChemReac%ReactNum(PartSpecies(Coll_pData(iPair)%iPart_p1), PartSpecies(Coll_pData(iPair)%iPart_p2), 1)
      IF(ChemReac%QKProcedure(iReac)) THEN ! all Q-K
        CALL Abort(&
         __STAMP__,&
        'ERROR! Reaction case not supported with Q-K reactions!')
!--------------------------------------------------------------------------------------------------!
      ELSE ! all reactions Arrhenius
!--------------------------------------------------------------------------------------------------!
        ! calculation of exchange probability
        CALL CalcReactionProb(iPair,iReac,ReactionProb)
#if (PP_TimeDiscMethod==42)
        IF (.NOT.DSMC%ReservoirRateStatistic) THEN
          ChemReac%NumReac(iReac) = ChemReac%NumReac(iReac) + ReactionProb  ! for calculation of reaction rate coefficient
          ChemReac%ReacCount(iReac) = ChemReac%ReacCount(iReac) + 1
        END IF
#endif
        ! calculation of recombination probability (only if third collision partner is available)
        IF (iPart_p3 .GT. 0) THEN
          iReac2 = ChemReac%ReactNumRecomb(PartSpecies(Coll_pData(iPair)%iPart_p1), PartSpecies(Coll_pData(iPair)%iPart_p2), &
                                                                                  PartSpecies(iPart_p3))
          CALL CalcReactionProb(iPair,iReac2,ReactionProb2,iPart_p3,nPartNode,Volume)
        ELSE
          ReactionProb2 = 0.0
        END IF
#if (PP_TimeDiscMethod==42)
        IF ((.NOT.DSMC%ReservoirRateStatistic).AND.(iPart_p3.GT.0)) THEN
          ChemReac%NumReac(iReac2) = ChemReac%NumReac(iReac2) + ReactionProb2  ! for calculation of reaction rate coefficient
          ChemReac%ReacCount(iReac2) = ChemReac%ReacCount(iReac2) + 1
        END IF
#endif
        CALL RANDOM_NUMBER(iRan)
        IF ((ReactionProb + ReactionProb2).GT.iRan) THEN
          CALL RANDOM_NUMBER(iRan)
          IF((ReactionProb/(ReactionProb + ReactionProb2)).GT.iRan) THEN
            ! Reservoir simulation for obtaining the reaction rate at one given point does not require to perform the reaction
#if (PP_TimeDiscMethod==42)
            IF (.NOT.DSMC%ReservoirSimuRate) THEN
#endif
              CALL DSMC_Chemistry(iPair, iReac)
#if (PP_TimeDiscMethod==42)
            END IF
            IF (DSMC%ReservoirRateStatistic) THEN
              ChemReac%NumReac(iReac) = ChemReac%NumReac(iReac) + 1  ! for calculation of reaction rate coefficient
            END IF
#endif
          ELSEIF(ReactionProb2.GT.0.0) THEN ! Probability is set to zero if no third collision partner is found
#if (PP_TimeDiscMethod==42)
            IF (.NOT.DSMC%ReservoirSimuRate) THEN
#endif
              CALL DSMC_Chemistry(iPair, iReac2, iPart_p3)
              IF(ChemReac%RecombParticle.EQ. 0) THEN
                Coll_pData(PairForRec)%NeedForRec = .TRUE.
                ChemReac%RecombParticle = Coll_pData(PairForRec)%iPart_p2
              ELSE
                ChemReac%RecombParticle = 0
              END IF
#if (PP_TimeDiscMethod==42)
            END IF
            IF (DSMC%ReservoirRateStatistic) THEN
              ChemReac%NumReac(iReac2) = ChemReac%NumReac(iReac2) + 1  ! for calculation of reaction rate coefficient
            END IF
#endif
          END IF
          RelaxToDo = .FALSE.
        END IF
      END IF

! ############################################################################################################################### !
    CASE(16) ! simple CEX/MEX
! ############################################################################################################################### !
      iReac    = ChemReac%ReactNum(PartSpecies(Coll_pData(iPair)%iPart_p1), PartSpecies(Coll_pData(iPair)%iPart_p2), 1)
      IF (ChemReac%DoScat(iReac)) THEN! MEX
        CALL DSMC_Scat_Col(iPair)
      ELSE
        sigmaCEX = (ChemReac%CEXa(iReac)*0.5*LOG10(Coll_pData(iPair)%CRela2) + ChemReac%CEXb(iReac))
        sigmaMEX = (ChemReac%MEXa(iReac)*0.5*LOG10(Coll_pData(iPair)%CRela2) + ChemReac%MEXb(iReac))
        ReactionProb=0.
        IF ((sigmaMEX.eq.0.).and.(sigmaCEX.gt.0.)) THEN
          ReactionProb=1.
        ELSEIF  ((sigmaMEX.gt.0.).and.(sigmaCEX.ge.0.)) THEN
          ReactionProb=(sigmaCEX/sigmaMEX)/((sigmaCEX/sigmaMEX)+1)
        ELSE
          CALL Abort(&
            __STAMP__&
            ,'ERROR! CEX/MEX cross sections are both zero or at least one of them is negative.')
        END IF
#if (PP_TimeDiscMethod==42)
        IF (.NOT.DSMC%ReservoirRateStatistic) THEN
          ChemReac%NumReac(iReac) = ChemReac%NumReac(iReac) + ReactionProb  ! for calculation of reaction rate coefficient
          ChemReac%ReacCount(iReac) = ChemReac%ReacCount(iReac) + 1
        END IF
#endif
        CALL RANDOM_NUMBER(iRan)
        IF (ReactionProb.GT.iRan) THEN !CEX, otherwise MEX
#if (PP_TimeDiscMethod==42)
          ! Reservoir simulation for obtaining the reaction rate at one given point does not require to perform the reaction
          IF (.NOT.DSMC%ReservoirSimuRate) THEN
#endif
            CALL simpleCEX(iReac, iPair)
#if (PP_TimeDiscMethod==42)
          END IF
          IF (DSMC%ReservoirRateStatistic) THEN
            ChemReac%NumReac(iReac) = ChemReac%NumReac(iReac) + 1  ! for calculation of reaction rate coefficient
          END IF
#endif
        ELSE
          CALL DSMC_Elastic_Col(iPair, iElem)
          CALL simpleMEX(iReac, iPair)
        END IF
      END IF !ChemReac%DoScat(iReac)
      RelaxToDo = .FALSE.
! ############################################################################################################################### !
    CASE(17) ! one dissociation, two exchange possible
! ############################################################################################################################### !
      iReac  = ChemReac%ReactNum(PartSpecies(Coll_pData(iPair)%iPart_p1), PartSpecies(Coll_pData(iPair)%iPart_p2), 1)
      iReac2 = ChemReac%ReactNum(PartSpecies(Coll_pData(iPair)%iPart_p1), PartSpecies(Coll_pData(iPair)%iPart_p2), 2)
      iReac3 = ChemReac%ReactNum(PartSpecies(Coll_pData(iPair)%iPart_p1), PartSpecies(Coll_pData(iPair)%iPart_p2), 3)
      IF ( ChemReac%QKProcedure(iReac) .OR. ChemReac%QKProcedure(iReac2) .OR. ChemReac%QKProcedure(iReac3) ) THEN ! all Q-K
          CALL Abort(&
__STAMP__&
,'ERROR! Reaction case not supported with Q-K reactions!')
!--------------------------------------------------------------------------------------------------!
      ELSE ! all reactions Arrhenius
!--------------------------------------------------------------------------------------------------!
        ! calculation of first dissociation probability
        CALL CalcReactionProb(iPair,iReac,ReactionProb)
#if (PP_TimeDiscMethod==42)
        IF (.NOT.DSMC%ReservoirRateStatistic) THEN
          ChemReac%NumReac(iReac) = ChemReac%NumReac(iReac) + ReactionProb  ! for calculation of reaction rate coefficient
          ChemReac%ReacCount(iReac) = ChemReac%ReacCount(iReac) + 1
        END IF
#endif
        ! calculation of second dissociation probability
        CALL CalcReactionProb(iPair,iReac2,ReactionProb2)
#if (PP_TimeDiscMethod==42)
        IF (.NOT.DSMC%ReservoirRateStatistic) THEN
          ChemReac%NumReac(iReac2) = ChemReac%NumReac(iReac2) + ReactionProb2  ! for calculation of reaction rate coefficient
          ChemReac%ReacCount(iReac2) = ChemReac%ReacCount(iReac2) + 1
        END IF
#endif
        ! calculation of third dissociation probability
        CALL CalcReactionProb(iPair,iReac3,ReactionProb3)
#if (PP_TimeDiscMethod==42)
        IF (.NOT.DSMC%ReservoirRateStatistic) THEN
          ChemReac%NumReac(iReac3) = ChemReac%NumReac(iReac3) + ReactionProb3  ! for calculation of reaction rate coefficient
          ChemReac%ReacCount(iReac3) = ChemReac%ReacCount(iReac3) + 1
        END IF
#endif
        CALL RANDOM_NUMBER(iRan)
        IF ((ReactionProb + ReactionProb2 + ReactionProb3).GT.iRan) THEN
          CALL RANDOM_NUMBER(iRan)
          CALL RANDOM_NUMBER(iRan2)
          IF((ReactionProb/(ReactionProb + ReactionProb2 + ReactionProb3)).GT.iRan) THEN
            ! Reservoir simulation for obtaining the reaction rate at one given point does not require to perform the reaction
#if (PP_TimeDiscMethod==42)
            IF (.NOT.DSMC%ReservoirSimuRate) THEN
# endif
              CALL DSMC_Chemistry(iPair, iReac)
#if (PP_TimeDiscMethod==42)
            END IF
            IF ( DSMC%ReservoirRateStatistic  ) THEN
              ChemReac%NumReac(iReac) = ChemReac%NumReac(iReac) + 1  ! for calculation of reaction rate coefficient
            END IF
# endif
          ELSEIF(ReactionProb2/(ReactionProb2 + ReactionProb3).GT.iRan2) THEN
            ! Reservoir simulation for obtaining the reaction rate at one given point does not require to perform the reaction
#if (PP_TimeDiscMethod==42)
            IF (.NOT.DSMC%ReservoirSimuRate) THEN
# endif
              CALL DSMC_Chemistry(iPair, iReac2)
#if (PP_TimeDiscMethod==42)
            END IF
            IF (DSMC%ReservoirRateStatistic) THEN
              ChemReac%NumReac(iReac2) = ChemReac%NumReac(iReac2) + 1  ! for calculation of reaction rate coefficient
            END IF
# endif
          ELSE
            ! Reservoir simulation for obtaining the reaction rate at one given point does not require to perform the reaction
#if (PP_TimeDiscMethod==42)
            IF (.NOT.DSMC%ReservoirSimuRate) THEN
# endif
              CALL DSMC_Chemistry(iPair, iReac3)
#if (PP_TimeDiscMethod==42)
            END IF
            IF (DSMC%ReservoirRateStatistic) THEN
              ChemReac%NumReac(iReac3) = ChemReac%NumReac(iReac3) + 1  ! for calculation of reaction rate coefficient
            END IF
# endif
          END IF
          RelaxToDo = .FALSE.
        END IF
      END IF
!############################################################################################################################### !
    CASE(18) ! only electron impact ionization possible Ar + e -> Ar(+) + e + e
! ############################################################################################################################### !
      iReac = ChemReac%ReactNum(PartSpecies(Coll_pData(iPair)%iPart_p1), PartSpecies(Coll_pData(iPair)%iPart_p2), 1)
      IF (ChemReac%QKProcedure(iReac)) THEN
        IF ( .NOT. DSMC%ElectronicModel ) THEN
          CALL Abort(&
__STAMP__&
,'ERROR! Atomic electron shell has to be initalized.')
        END IF
        CALL QK_ImpactIonization(iPair,iReac,RelaxToDo)
      END IF
!-----------------------------------------------------------------------------------------------------------------------------------
      IF (.NOT.ChemReac%QKProcedure(iReac)) THEN
         CALL Abort(&
__STAMP__&
,'ERROR! Electron impact ionization not implemented without QK')
      END IF
!############################################################################################################################### !
    CASE(19) ! only ion recombination possible Ar(+) + e + e -> Ar + e
! ############################################################################################################################### !
      ! searching third collison partner
      IF(ChemReac%RecombParticle.EQ. 0) THEN
        IF(iPair.LT.(nPair - ChemReac%nPairForRec)) THEN
          PairForRec = nPair - ChemReac%nPairForRec
          ChemReac%nPairForRec = ChemReac%nPairForRec + 1
          iPart_p3 = Coll_pData(PairForRec)%iPart_p1
        ELSE
          iPart_p3 = 0
        END IF
      ELSE
        iPart_p3 = ChemReac%RecombParticle
      END IF
!-----------------------------------------------------------------------------------------------------------------------------------
      IF ( iPart_p3 .GT. 0 ) THEN
        iReac = ChemReac%ReactNum(PartSpecies(Coll_pData(iPair)%iPart_p1), &
                                  PartSpecies(Coll_pData(iPair)%iPart_p2), &
                                  PartSpecies(iPart_p3))
        IF(iReac.EQ.0) THEN
          iReac = ChemReac%ReactNumRecomb(PartSpecies(Coll_pData(iPair)%iPart_p1), &
                                          PartSpecies(Coll_pData(iPair)%iPart_p2), &
                                          PartSpecies(iPart_p3))
        END IF
!        IF(SpecDSMC(PartSpecies(iPart_p3))%InterID.NE.4)RETURN
        IF ( ChemReac%QKProcedure(iReac)  ) THEN
          IF ( .NOT. DSMC%ElectronicModel ) THEN
            CALL Abort(&
__STAMP__&
,' ERROR! Atomic electron shell has to be initalized.')
          END IF
          CALL QK_IonRecombination(iPair,iReac,iPart_p3,RelaxToDo,NodeVolume,NodePartNum)
!          CALL QK_IonRecombination(iPair,iReac,iPart_p3,RelaxToDo,iElem,NodeVolume,NodePartNum)
!-----------------------------------------------------------------------------------------------------------------------------------
        ELSE
        ! traditional Recombination
          ! Calculation of reaction probability
          CALL CalcReactionProb(iPair,iReac,ReactionProb,iPart_p3,nPartNode,Volume)
          
#if (PP_TimeDiscMethod==42)
          IF (.NOT.DSMC%ReservoirRateStatistic) THEN
            ChemReac%NumReac(iReac) = ChemReac%NumReac(iReac) + ReactionProb  ! for calculation of reaction rate coefficient
            ChemReac%ReacCount(iReac) = ChemReac%ReacCount(iReac) + 1
          END IF
#endif
          CALL RANDOM_NUMBER(iRan)
          IF (ReactionProb.GT.iRan) THEN
#if (PP_TimeDiscMethod==42)
            ! Reservoir simulation for obtaining the reaction rate at one given point does not require to perform the reaction
            IF (.NOT.DSMC%ReservoirSimuRate) THEN
#endif
              IF (usevMPF) THEN
                CALL Abort(&
                 __STAMP__,&
                ' ERROR! IonRecomb not possible using vMPF.')
              ELSE
                CALL DSMC_Chemistry(iPair, iReac, iPart_p3)
                IF(ChemReac%RecombParticle.EQ. 0) THEN
                  Coll_pData(PairForRec)%NeedForRec = .TRUE.
                  ChemReac%RecombParticle = Coll_pData(PairForRec)%iPart_p2
                ELSE
                  ChemReac%RecombParticle = 0
                END IF
              END IF
#if (PP_TimeDiscMethod==42)
            END IF
            IF (DSMC%ReservoirRateStatistic) THEN
              ChemReac%NumReac(iReac) = ChemReac%NumReac(iReac) + 1  ! for calculation of reaction rate coefficient
            END IF
#endif
            RelaxToDo = .FALSE.
          END IF ! ReactionProb > iRan
        END IF ! Q-K
      END IF
!-----------------------------------------------------------------------------------------------------------------------------------
    CASE DEFAULT
      IF(CaseOfReaction.NE.0) THEN
        CALL Abort(&
__STAMP__&
,'Error! Reaction case not defined:',CaseOfReaction)
      END IF
  END SELECT

END SUBROUTINE ReactionDecision


SUBROUTINE DSMC_calc_P_rot(iSpec, iPair, iPart, Xi_rel, ProbRot, ProbRotMax)
!===================================================================================================================================
! Calculation of probability for rotational relaxation. Different Models implemented:
! 0 - Constant Probability
! 1 - No rotational relaxation. RotRelaxProb = 0
! 2 - Boyd
! 3 - Zhang (Nonequilibrium Direction Dependent)
!===================================================================================================================================
! MODULES
  USE MOD_Globals,            ONLY : Abort
  USE MOD_Globals_Vars,       ONLY : BoltzmannConst
  USE MOD_DSMC_Vars,          ONLY : SpecDSMC, Coll_pData, PartStateIntEn, DSMC
! IMPLICIT VARIABLE HANDLING
  IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
  INTEGER, INTENT(IN)       :: iSpec, iPair, iPart
  REAL, INTENT(IN)          :: Xi_rel
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
  REAL, INTENT(INOUT)       :: ProbRot, ProbRotMax
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
  REAL                        :: TransEn, RotEn, RotDOF, CorrFact
  REAL, PARAMETER           :: PI=3.14159265358979323846_8
!===================================================================================================================================

  TransEn = Coll_pData(iPair)%Ec      ! notice that during probability calculation,Collision energy only contains translational part
  RotDOF = SpecDSMC(iSpec)%Xi_Rot
  RotEn = PartStateIntEn(iPart,2)
  ProbRot = 0.
  ProbRotMax = 0.

  ! calculate correction factor according to Lumpkin et al.
  ! - depending on selection procedure. As only one particle undergoes relaxation
  ! - only one RotDOF is needed (of considered species)
  CorrFact = 1. + RotDOF/Xi_rel

  ! calculate corrected probability for rotational relaxation
  IF(DSMC%RotRelaxProb.GE.0.0.AND.DSMC%RotRelaxProb.LE.1.0) THEN
    ProbRot = DSMC%RotRelaxProb * CorrFact
  ELSEIF(DSMC%RotRelaxProb.EQ.2.0) THEN ! P_rot according to Boyd (based on Parker's model)
    ProbRot = 1/SpecDSMC(iSpec)%CollNumRotInf * (1 + lacz_gamma(RotDOF+2.-SpecDSMC(iSpec)%omegaVHS) & 
            / lacz_gamma(RotDOF+1.5-SpecDSMC(iSpec)%omegaVHS) * (PI**(3./2.)/2.)*(BoltzmannConst*SpecDSMC(iSpec)%TempRefRot &
            / (TransEn + RotEn) )**(1./2.) + lacz_gamma(RotDOF+2.-SpecDSMC(iSpec)%omegaVHS)  &
            / lacz_gamma(RotDOF+1.-SpecDSMC(iSpec)%omegaVHS) * (BoltzmannConst*SpecDSMC(iSpec)%TempRefRot &
            / (TransEn + RotEn) ) * (PI**2./4. + PI)) &
            * CorrFact     

  ELSEIF(DSMC%RotRelaxProb.EQ.3.0) THEN ! P_rot according to Zhang (NDD)
    ! if model is used for further species but N2, it should be checked if factors n = 0.5 and Cn = 1.92 are still valid 
    ! (see original eq of Zhang)
    ProbRot = 1.92 * lacz_gamma(Xi_rel/2.) * lacz_gamma(RotDOF/2.) / lacz_gamma(Xi_rel/2.+0.5) / lacz_gamma(RotDOF/2.-0.5) &
            * (1 + (Xi_rel/2-0.5)*BoltzmannConst*SpecDSMC(iSpec)%TempRefRot/TransEn) * (TransEn/RotEn)**0.5 &
            * CorrFact  
    ProbRotMax = MAX(ProbRot, 0.5) ! BL energy redistribution correction factor
    ProbRot = MIN(ProbRot, 0.5)
  ELSE
    CALL Abort(&
__STAMP__&
,'Error! Model for rotational relaxation undefined:',RealInfoOpt=DSMC%RotRelaxProb)
  END IF

END SUBROUTINE DSMC_calc_P_rot


SUBROUTINE DSMC_calc_P_vib(iSpec, jSpec, iPair, Xi_rel, ProbVib, ProbVibMax)
!===================================================================================================================================
! Calculation of probability for vibrational relaxation. Different Models implemented:
! 0 - Constant Probability
! 1 - No vibrational relaxation. VibRelaxProb = 0
! 2 - Boyd with correction of Abe
!===================================================================================================================================
! MODULES
  USE MOD_Globals,            ONLY : Abort
  USE MOD_Globals_Vars,       ONLY : BoltzmannConst
  USE MOD_DSMC_Vars,          ONLY : SpecDSMC, Coll_pData, DSMC, CollInf, CRelaMax, CRelaAv
  USE MOD_DSMC_Vars,          ONLY : PolyatomMolDSMC

! IMPLICIT VARIABLE HANDLING
  IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
INTEGER, INTENT(IN)       :: iPair, iSpec, jSpec
REAL, INTENT(IN)          :: Xi_rel
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
REAL, INTENT(INOUT)       :: ProbVib, ProbVibMax
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
REAL                      :: CorrFact, CRelaSub, TempCorr, DrefVHS
INTEGER                   :: iPolyatMole, iDOF
REAL, PARAMETER           :: PI=3.14159265358979323846_8
!===================================================================================================================================

  ProbVib = 0.

  ! calculate correction factor according to Gimelshein et al.
  ! - depending on selection procedure. As only one particle undergoes relaxation
  ! - only one VibDOF (GammaVib) is needed (of considered species)
  CorrFact = 1. + SpecDSMC(iSpec)%GammaVib/Xi_rel

  IF((DSMC%VibRelaxProb.GE.0.0).AND.(DSMC%VibRelaxProb.LE.1.0)) THEN
    IF (SpecDSMC(iSpec)%PolyatomicMol.AND.(DSMC%PolySingleMode)) THEN
      iPolyatMole = SpecDSMC(iSpec)%SpecToPolyArray
      PolyatomMolDSMC(iPolyatMole)%VibRelaxProb(1) = DSMC%VibRelaxProb   &
                                                   * (1. + PolyatomMolDSMC(iPolyatMole)%GammaVib(1)/Xi_rel)
      DO iDOF = 2, PolyatomMolDSMC(iPolyatMole)%VibDOF
        PolyatomMolDSMC(iPolyatMole)%VibRelaxProb(iDOF) = PolyatomMolDSMC(iPolyatMole)%VibRelaxProb(iDOF - 1)   &
                                                   + DSMC%VibRelaxProb * (1. + PolyatomMolDSMC(iPolyatMole)%GammaVib(1)/Xi_rel)
      END DO
    ELSE
      ProbVib = DSMC%VibRelaxProb * CorrFact
    END IF
  ELSEIF(DSMC%VibRelaxProb.EQ.2.0) THEN ! P_vib according to Boyd, corrected by Abe, only V-T transfer
          ! instead of averaging over all collisions in a cell, for convenience a cell averaged relative velocity is used.
    ! determine joint omegaVHS and Dref factor and rel velo of one vib quantum level below the current one
    DrefVHS = 0.5 * (SpecDSMC(iSpec)%DrefVHS + SpecDSMC(jSpec)%DrefVHS)
    CRelaSub = CRelaAv - 2.*(BoltzmannConst*SpecDSMC(iSpec)%CharaTVib) / CollInf%MassRed(Coll_pData(iPair)%PairType)
    IF(CRelaSub.LT.0.) THEN
      CRelaSub = 0.
    ELSE
      CRelaSub = SQRT(CRelaSub)
    END IF
    ! calculate non-corrected probabilities
    ProbVib = 1. /SpecDSMC(iSpec)%CollNumVib* CRelaAv**(3.+2.*SpecDSMC(iSpec)%omegaVHS) &
            * EXP(-1*SpecDSMC(iSpec)%CharaVelo(jSpec)/CRelaAv)
    ProbVibMax = 1. /SpecDSMC(iSpec)%CollNumVib* CRelaMax**(3.+2.*SpecDSMC(iSpec)%omegaVHS) &
               * EXP(-1*SpecDSMC(iSpec)%CharaVelo(jSpec)/CRelaMax)
    ! calculate high temperature correction
    TempCorr = SpecDSMC(iSpec)%VibCrossSec / (SQRT(2.)*PI*DrefVHS**2.) &
             * (  CollInf%MassRed(Coll_pData(iPair)%PairType)*CRelaAv &
                / (2.*(2.-SpecDSMC(iSpec)%omegaVHS)*BoltzmannConst*SpecDSMC(iSpec)%TrefVHS))**SpecDSMC(iSpec)%omegaVHS
    ! determine corrected probabilities
    ProbVib = ProbVib * TempCorr / (ProbVib + TempCorr) * CorrFact
    ProbVibMax = ProbVibMax * TempCorr / (ProbVibMax + TempCorr) * CorrFact
  ELSE
    CALL Abort(&
__STAMP__&
,'Error! Model for vibrational relaxation undefined:',RealInfoOpt=DSMC%VibRelaxProb)
  END IF

END SUBROUTINE DSMC_calc_P_vib


RECURSIVE FUNCTION lacz_gamma(a) RESULT(g)
!===================================================================================================================================
! gamma function taken from
! http://rosettacode.org/wiki/Gamma_function#Fortran
! variefied against build in and compiled with double precision
!===================================================================================================================================
! MODULES
! IMPLICIT VARIABLE HANDLING
  IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES                                                                                
  REAL(KIND=8), INTENT(IN) :: a
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
  REAL(KIND=8) :: g
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
  REAL(KIND=8), PARAMETER :: pi = 3.14159265358979324
  INTEGER, PARAMETER :: cg = 7
  ! these precomputed values are taken by the sample code in Wikipedia,
  ! and the sample itself takes them from the GNU Scientific Library
  REAL(KIND=8), DIMENSION(0:8), PARAMETER :: p = &
       (/ 0.99999999999980993, 676.5203681218851, -1259.1392167224028, &
       771.32342877765313, -176.61502916214059, 12.507343278686905, &
       -0.13857109526572012, 9.9843695780195716e-6, 1.5056327351493116e-7 /)
  REAL(KIND=8) :: t, w, x
  INTEGER :: i
!===================================================================================================================================

  x = a

  IF ( x < 0.5 ) THEN
     g = pi / ( sin(pi*x) * lacz_gamma(1.0-x) )
  ELSE
     x = x - 1.0
     t = p(0)
     DO i=1, cg+2
        t = t + p(i)/(x+real(i))
     END DO
     w = x + real(cg) + 0.5
     g = sqrt(2.0*pi) * w**(x+0.5) * exp(-w) * t
  END IF
END FUNCTION lacz_gamma


!--------------------------------------------------------------------------------------------------!
END MODULE MOD_DSMC_Collis
