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

MODULE MOD_DSMC_ChemReact
!===================================================================================================================================
! Module for chemical reactions including calculation of probabilities and collisions
!===================================================================================================================================
! MODULES
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
PRIVATE

INTERFACE DSMC_Chemistry
  MODULE PROCEDURE DSMC_Chemistry
END INTERFACE

INTERFACE simpleCEX
  MODULE PROCEDURE simpleCEX
END INTERFACE

INTERFACE simpleMEX
  MODULE PROCEDURE simpleMEX
END INTERFACE

INTERFACE CalcReactionProb
  MODULE PROCEDURE CalcReactionProb
END INTERFACE

INTERFACE CalcBackwardRate
  MODULE PROCEDURE CalcBackwardRate
END INTERFACE
!-----------------------------------------------------------------------------------------------------------------------------------
! GLOBAL VARIABLES 
!-----------------------------------------------------------------------------------------------------------------------------------
! Private Part ---------------------------------------------------------------------------------------------------------------------
! Public Part ----------------------------------------------------------------------------------------------------------------------
PUBLIC :: DSMC_Chemistry, simpleCEX, simpleMEX, CalcReactionProb, CalcBackwardRate, gammainc, CalcPartitionFunction
!===================================================================================================================================

CONTAINS

SUBROUTINE CalcReactionProb(iPair,iReac,ReactionProb,iPart_p3,nPartNode,Volume)
!===================================================================================================================================
! Calculates the reaction probability for dissociation, exchange, recombination and associative ionization reactions
!===================================================================================================================================
! MODULES
  USE MOD_Globals
  USE MOD_Globals_Vars,           ONLY : BoltzmannConst
  USE MOD_DSMC_PolyAtomicModel,   ONLY : Calc_Beta_Poly
  USE MOD_DSMC_Vars,              ONLY : Coll_pData, DSMC, SpecDSMC, PartStateIntEn, ChemReac, CollInf
  USE MOD_Particle_Vars,          ONLY : PartState, Species, PartSpecies, nSpecies
  USE MOD_DSMC_Analyze,           ONLY : CalcTVibPoly, CalcTelec
  USE MOD_Globals_Vars,           ONLY : Pi
! IMPLICIT VARIABLE HANDLING
  IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
  INTEGER, INTENT(IN)           :: iPair, iReac
  INTEGER, INTENT(IN), OPTIONAL :: iPart_p3, nPartNode
  REAL, INTENT(IN), OPTIONAL    :: Volume
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
  REAL, INTENT(OUT)             :: ReactionProb
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
  INTEGER                       :: React1Inx, React2Inx, ProductReac(1:3), EductReac(1:3), iReacForward
  REAL                          :: EZeroPoint_Educt, EZeroPoint_Prod, EReact 
  REAL                          :: Xi_vib1, Xi_vib2, Xi_vib3, Xi_Total, Xi_elec1, Xi_elec2, Xi_elec3
  REAL(KIND=8)                 :: BetaReaction, BackwardRate, ForwardRate
  REAL                          :: Rcoll, Tcoll, Telec, b, TiQK
!===================================================================================================================================

  IF (ChemReac%DefinedReact(iReac,1,1).EQ.PartSpecies(Coll_pData(iPair)%iPart_p1)) THEN
    React1Inx = Coll_pData(iPair)%iPart_p1
    React2Inx = Coll_pData(iPair)%iPart_p2
  ELSE
    React1Inx = Coll_pData(iPair)%iPart_p2
    React2Inx = Coll_pData(iPair)%iPart_p1
  END IF

  EductReac(1:3) = ChemReac%DefinedReact(iReac,1,1:3)
  ProductReac(1:3) = ChemReac%DefinedReact(iReac,2,1:3)

  IF((EductReac(3).NE.0).AND.(.NOT.PRESENT(iPart_p3))) THEN
    CALL abort(&
     __STAMP__&
     ,'Optional argument (iPart_p3) is missing for the recombination reaction. Reaction: ',iReac)
  END IF

  IF(TRIM(ChemReac%ReactType(iReac)).EQ.'R') THEN
    ! The third-collision partner during a recombination is chosen randomly, but DefinedReact(iReac) might differ
    EductReac(3) = PartSpecies(iPart_p3)
    ProductReac(2) = PartSpecies(iPart_p3)
  END IF

  !---------------------------------------------------------------------------------------------------------------------------------
  ! Calculation of the collision energy
  !---------------------------------------------------------------------------------------------------------------------------------

  Coll_pData(iPair)%Ec = 0.5 * CollInf%MassRed(Coll_pData(iPair)%PairType)*Coll_pData(iPair)%CRela2                  &
                       + PartStateIntEn(React1Inx,1) + PartStateIntEn(React2Inx,1) &
                       + PartStateIntEn(React1Inx,2) + PartStateIntEn(React2Inx,2)

  IF(EductReac(3).NE.0) THEN
    Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec + 0.5 * Species(EductReac(3))%MassIC                         &
                         * (PartState(iPart_p3,4)**2 + PartState(iPart_p3,5)**2 + PartState(iPart_p3,6)**2 )         &
                         + PartStateIntEn(iPart_p3,1) + PartStateIntEn(iPart_p3,2)
  END IF
  !---------------------------------------------------------------------------------------------------------------------------------
  ! Calculation of the zero-point-energies and vibrational degrees of freedom
  !---------------------------------------------------------------------------------------------------------------------------------
  EZeroPoint_Educt = 0.0
  EZeroPoint_Prod = 0.0
  Xi_vib1 = 0.0
  Xi_vib2 = 0.0
  Xi_vib3 = 0.0
  Xi_elec1 = 0.0
  Xi_elec2 = 0.0
  Xi_elec3 = 0.0
  ! Testing if the first reacting particle is an atom or molecule, if molecule: is it polyatomic?
  IF((SpecDSMC(EductReac(1))%InterID.EQ.2).OR.(SpecDSMC(EductReac(1))%InterID.EQ.20)) THEN
    EZeroPoint_Educt = EZeroPoint_Educt + SpecDSMC(EductReac(1))%EZeroPoint
    IF(SpecDSMC(EductReac(1))%PolyatomicMol) THEN
      ! Calculation of the vibrational degree of freedom for the particle 
      IF (PartStateIntEn(React1Inx,1).GT.SpecDSMC(EductReac(1))%EZeroPoint) THEN
        Xi_vib1 = 2.*(PartStateIntEn(React1Inx,1)-SpecDSMC(EductReac(1))%EZeroPoint)                                  &
                / (BoltzmannConst*CalcTVibPoly(PartStateIntEn(React1Inx,1), EductReac(1)))
      END IF
    ELSE
      IF(ChemReac%MeanEVibQua_PerIter(EductReac(1)).GT.0.0) THEN
        Xi_vib1 = 2.*ChemReac%MeanEVibQua_PerIter(EductReac(1)) &
              * LOG(1.0/ ChemReac%MeanEVibQua_PerIter(EductReac(1)) + 1.0 )
      END IF
    END IF
  END IF
  !---------------------------------------------------------------------------------------------------------------------------------
  ! Testing if the second particle is an atom or molecule, if molecule: is it polyatomic?
  IF((SpecDSMC(EductReac(2))%InterID.EQ.2).OR.(SpecDSMC(EductReac(2))%InterID.EQ.20)) THEN
    EZeroPoint_Educt = EZeroPoint_Educt + SpecDSMC(EductReac(2))%EZeroPoint
    IF(SpecDSMC(EductReac(2))%PolyatomicMol) THEN
      ! Calculation of the vibrational degree of freedom for the particle 
      IF (PartStateIntEn(React2Inx,1).GT.SpecDSMC(EductReac(2))%EZeroPoint) THEN
        Xi_vib2 = 2.*(PartStateIntEn(React2Inx,1)-SpecDSMC(EductReac(2))%EZeroPoint)                                  &
                / (BoltzmannConst*CalcTVibPoly(PartStateIntEn(React2Inx,1), EductReac(2)))
      END IF 
    ELSE
      IF(ChemReac%MeanEVibQua_PerIter(EductReac(2)).GT.0.0) THEN
        Xi_vib2 = 2.*ChemReac%MeanEVibQua_PerIter(EductReac(2)) &
        * LOG(1.0/ ChemReac%MeanEVibQua_PerIter(EductReac(2)) + 1.0 )
      END IF
    END IF
  END IF
  !---------------------------------------------------------------------------------------------------------------------------------
  IF(EductReac(3).NE.0) THEN
    ! Testing if the third particle is an atom or molecule, if molecule: is it polyatomic?
    IF((SpecDSMC(EductReac(3))%InterID.EQ.2).OR.(SpecDSMC(EductReac(3))%InterID.EQ.20)) THEN
      EZeroPoint_Educt = EZeroPoint_Educt + SpecDSMC(EductReac(3))%EZeroPoint
      IF(SpecDSMC(EductReac(3))%PolyatomicMol) THEN
        ! Calculation of the vibrational degree of freedom for the particle 
        IF (PartStateIntEn(iPart_p3,1).GT.SpecDSMC(EductReac(3))%EZeroPoint) THEN
          Xi_vib3 = 2.*(PartStateIntEn(iPart_p3,1)-SpecDSMC(EductReac(3))%EZeroPoint)                                  &
                  / (BoltzmannConst*CalcTVibPoly(PartStateIntEn(iPart_p3,1), EductReac(3)))
        END IF
      ELSE
        IF(ChemReac%MeanEVibQua_PerIter(EductReac(3)).GT.0.0) THEN
          Xi_vib3 = 2.0*ChemReac%MeanEVibQua_PerIter(EductReac(3)) &
                  * LOG(1.0/ChemReac%MeanEVibQua_PerIter(EductReac(3)) + 1.0)
        END IF
      END IF
    END IF
  END IF
  !---------------------------------------------------------------------------------------------------------------------------------
  ! Testing if the first produced particle is an atom or molecule, if molecule: is it polyatomic?
  IF((SpecDSMC(ProductReac(1))%InterID.EQ.2).OR.(SpecDSMC(ProductReac(1))%InterID.EQ.20)) THEN
    EZeroPoint_Prod = EZeroPoint_Prod + SpecDSMC(ProductReac(1))%EZeroPoint
  END IF
  ! Testing if the second produced particle is an atom or molecule, if molecule: is it polyatomic?
  IF((SpecDSMC(ProductReac(2))%InterID.EQ.2).OR.(SpecDSMC(ProductReac(2))%InterID.EQ.20)) THEN
    EZeroPoint_Prod = EZeroPoint_Prod + SpecDSMC(ProductReac(2))%EZeroPoint
  END IF
  IF(ProductReac(3).NE.0) THEN
    IF((SpecDSMC(ProductReac(3))%InterID.EQ.2).OR.(SpecDSMC(ProductReac(3))%InterID.EQ.20)) THEN
      EZeroPoint_Prod = EZeroPoint_Prod + SpecDSMC(ProductReac(3))%EZeroPoint
    END IF
  END IF
  !---------------------------------------------------------------------------------------------------------------------------------
  ! Considering the electronic shell (including the addition of the electronic energy to the collision energy)
  !---------------------------------------------------------------------------------------------------------------------------------
  IF (DSMC%ElectronicModel ) THEN
    Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec + PartStateIntEn(React1Inx,3) + PartStateIntEn(React2Inx,3)
    IF(SpecDSMC(EductReac(1))%InterID.NE.4) THEN 
      IF(PartStateIntEn(React1Inx,3).GT.0.0)THEN
        Telec=CalcTelec( PartStateIntEn(React1Inx,3) , EductReac(1))
        Xi_elec1=2.*PartStateIntEn(React1Inx,3)/(BoltzmannConst*Telec)
      END IF
    END IF
  !---------------------------------------------------------------------------------------------------------------------------------
    IF(SpecDSMC(EductReac(2))%InterID.NE.4) THEN 
      IF(PartStateIntEn(React2Inx,3).GT.0.0)THEN
        Telec=CalcTelec( PartStateIntEn(React2Inx,3) , EductReac(2))
        Xi_elec2=2.*PartStateIntEn(React2Inx,3)/(BoltzmannConst*Telec)
      END IF
    END IF
  !---------------------------------------------------------------------------------------------------------------------------------
    IF(EductReac(3).NE.0) THEN
      Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec + PartStateIntEn(iPart_p3,3)
      IF(SpecDSMC(EductReac(3))%InterID.NE.4) THEN 
        IF(PartStateIntEn(iPart_p3,3).GT.0.0)THEN
          Telec=CalcTelec( PartStateIntEn(iPart_p3,3) , EductReac(3))
          Xi_elec3=2.*PartStateIntEn(iPart_p3,3)/(BoltzmannConst*Telec)
        END IF
      END IF
    END IF
  END IF
  !---------------------------------------------------------------------------------------------------------------------------------
  ! Calculation of the reaction probability, if collision energy minus the zero-point energy of the EDUCTS is greater than the
  ! activation energy AND collision energy minus the zero-point energy of the PRODUCTS is greater than the heat of formation
  !---------------------------------------------------------------------------------------------------------------------------------
  IF(((Coll_pData(iPair)%Ec-EZeroPoint_Educt).GE.ChemReac%EActiv(iReac)) .AND. &
    ((Coll_pData(iPair)%Ec-EZeroPoint_Prod).GE.(-1*ChemReac%EForm(iReac)))) THEN
    ! Determination of the total degree of freedom
    Xi_Total = Xi_vib1 + Xi_vib2 + SpecDSMC(EductReac(1))%Xi_Rot + SpecDSMC(EductReac(2))%Xi_Rot &
               + 2.*(2.-SpecDSMC(EductReac(1))%omegaVHS)
    IF(EductReac(3).NE.0) THEN
      Xi_Total = Xi_Total + 3. + Xi_vib3 + SpecDSMC(EductReac(3))%Xi_Rot
    END IF
    IF (DSMC%ElectronicModel ) THEN
      Xi_Total = Xi_Total + Xi_elec1 + Xi_elec2
      IF(EductReac(3).NE.0) Xi_Total = Xi_Total + Xi_elec3
    END IF
    ! Zero-point energy of educts is removed from the collision energy utilized for the calculation of the reaction probability
    EReact = Coll_pData(iPair)%Ec - EZeroPoint_Educt
    ! Determination of the Beta coefficient (array for diatomic molecules, calculation for polyatomic)
    IF (SpecDSMC(EductReac(1))%PolyatomicMol                &
        .OR.SpecDSMC(EductReac(2))%PolyatomicMol           &
        .OR.SpecDSMC(ProductReac(1))%PolyatomicMol  &
        .OR.SpecDSMC(ProductReac(2))%PolyatomicMol) THEN
      BetaReaction = Calc_Beta_Poly(iReac,Xi_Total)
    ELSE
      IF(TRIM(ChemReac%ReactType(iReac)).EQ.'D') THEN
        BetaReaction = ChemReac%ReactInfo(iReac)%Beta_Diss_Arrhenius(                                                         &
                              ChemReac%MeanEVibQua_PerIter(EductReac(1)),                                          &
                              ChemReac%MeanEVibQua_PerIter(EductReac(2)))
      ELSE IF(TRIM(ChemReac%ReactType(iReac)).EQ.'E') THEN
        BetaReaction = ChemReac%ReactInfo(iReac)%Beta_Exch_Arrhenius(                                                         &
                              ChemReac%MeanEVibQua_PerIter(EductReac(1)),                                          &
                              ChemReac%MeanEVibQua_PerIter(EductReac(2)))
      ELSE IF(TRIM(ChemReac%ReactType(iReac)).EQ.'R') THEN
        IF(SpecDSMC(EductReac(3))%PolyatomicMol) THEN
          BetaReaction = Calc_Beta_Poly(iReac,Xi_Total)
        ELSE
          BetaReaction = &
            ChemReac%ReactInfo(iReac)%Beta_Rec_Arrhenius(EductReac(3),ChemReac%MeanEVibQua_PerIter(EductReac(3)))
        END IF
      ELSE
!        CALL abort(&
!       __STAMP__&
!        ,'Reaction Type is not properly specified. Reaction: ',iReac)
      END IF
    END IF
    ! Calculation of the backward reaction rate coefficient and applying to Beta coefficient after Boyd "Modeling backward chemical
    ! rate processes in the direct simulation Monte Carlo method", Phys. Fluids 19, 1261103 (2007)
    IF(DSMC%BackwardReacRate.AND.((iReac.GT.ChemReac%NumOfReact/2))) THEN
      iReacForward = iReac - ChemReac%NumOfReact/2
      IF(DSMC%InstantTransTemp(nSpecies+1).GT.0.0) THEN
        CALL CalcBackwardRate(iReac,DSMC%InstantTransTemp(nSpecies+1),BackwardRate)
        IF(TRIM(ChemReac%ReactType(iReac)).EQ.'E') THEN
          BetaReaction = BetaReaction * BackwardRate &
            / EXP(-(ChemReac%EActiv(iReacForward)-ChemReac%EActiv(iReac))/(BoltzmannConst*DSMC%InstantTransTemp(nSpecies+1))) &
            / (ChemReac%Arrhenius_Prefactor(iReac) * DSMC%InstantTransTemp(nSpecies+1)**ChemReac%Arrhenius_Powerfactor(iReac))
        END IF
      ELSE
        BackwardRate = 0.0
        BetaReaction = 0.0
      END IF
    END IF
    ! Actual calculation of the reaction probability, different equation for recombination reaction
    IF((TRIM(ChemReac%ReactType(iReac)).EQ.'R').OR.(TRIM(ChemReac%ReactType(iReac)).EQ.'r')) THEN
      IF(DSMC%BackwardReacRate.AND.((iReac.GT.ChemReac%NumOfReact/2))) THEN
        Tcoll = CollInf%MassRed(Coll_pData(iPair)%PairType)*Coll_pData(iPair)%CRela2  / (BoltzmannConst &
              * 2.*(2.-SpecDSMC(EductReac(1))%omegaVHS))
        b=     (0.5 - SpecDSMC(EductReac(1))%omegaVHS)
        Rcoll = 2. * SQRT(Pi) / (1 + CollInf%KronDelta(CollInf%Coll_Case(EductReac(1),EductReac(2)))) &
          * (SpecDSMC(EductReac(1))%DrefVHS/2. + SpecDSMC(EductReac(2))%DrefVHS/2.)**2 &
          * (Tcoll / SpecDSMC(EductReac(1))%TrefVHS)**(0.5 - SpecDSMC(EductReac(1))%omegaVHS) &
          * SQRT(2. * BoltzmannConst * SpecDSMC(EductReac(1))%TrefVHS &
          / (CollInf%MassRed(CollInf%Coll_Case(EductReac(1), EductReac(2)))))
        Rcoll = Rcoll * (2.-SpecDSMC(EductReac(1))%omegaVHS)**b * GAMMA(2.-SpecDSMC(EductReac(1))%omegaVHS) &
                        / GAMMA(2.-SpecDSMC(EductReac(1))%omegaVHS+b)
        ReactionProb = BackwardRate / Rcoll * nPartNode / Volume * Species(EductReac(3))%MacroParticleFactor
      ELSE
        ! Reaction probability after regular TCE-model
        ReactionProb = BetaReaction * (nPartNode*Species(EductReac(3))%MacroParticleFactor/Volume)    &
                 * EReact**(ChemReac%Arrhenius_Powerfactor(iReac) - 0.5 + SpecDSMC(EductReac(3))%omegaVHS)
      END IF
    ELSE IF(TRIM(ChemReac%ReactType(iReac)).EQ.'iQK') THEN
      TiQK = (CollInf%MassRed(Coll_pData(iPair)%PairType)*Coll_pData(iPair)%CRela2 &
                + 2.*PartStateIntEn(React1Inx,3))/((2.*(2.-SpecDSMC(ChemReac%DefinedReact(iReac,1,1))%omegaVHS) &
                + Xi_elec1)*BoltzmannConst)
      CALL CalcForwardRate(iReac,TiQK,ForwardRate)
      Tcoll = CollInf%MassRed(Coll_pData(iPair)%PairType)*Coll_pData(iPair)%CRela2  / (BoltzmannConst &
              * 2.*(2.-SpecDSMC(ChemReac%DefinedReact(iReac,1,1))%omegaVHS)) 
      b=     (0.5 - SpecDSMC(EductReac(1))%omegaVHS)     
      Rcoll = 2. * SQRT(Pi) / (1 + CollInf%KronDelta(CollInf%Coll_Case(EductReac(1),EductReac(2)))) &
        * (SpecDSMC(EductReac(1))%DrefVHS/2. + SpecDSMC(EductReac(2))%DrefVHS/2.)**2 &
        * (Tcoll / SpecDSMC(EductReac(1))%TrefVHS)**(0.5 - SpecDSMC(EductReac(1))%omegaVHS) &
        * SQRT(2. * BoltzmannConst * SpecDSMC(EductReac(1))%TrefVHS &
        / (CollInf%MassRed(CollInf%Coll_Case(EductReac(1), EductReac(2)))))
      Rcoll = Rcoll * (2.-SpecDSMC(EductReac(1))%omegaVHS)**b &
           * gamma(2.-SpecDSMC(EductReac(1))%omegaVHS)/gamma(2.-SpecDSMC(EductReac(1))%omegaVHS+b)
      ReactionProb = ForwardRate / Rcoll 
    ELSE
      IF(SpecDSMC(EductReac(2))%PolyatomicMol.OR.SpecDSMC(EductReac(1))%PolyatomicMol) THEN
        ! Energy is multiplied by a factor to increase the resulting exponent and avoid floating overflows for high vibrational
        ! degree of freedom, later the reaction probability is scaled again with the same factor and the respective exponents
        ReactionProb = BetaReaction * ((EReact - ChemReac%EActiv(iReac))*1E6)                                                   &
              ** (ChemReac%Arrhenius_Powerfactor(iReac)-1.5+SpecDSMC(EductReac(1))%omegaVHS+Xi_Total/2.)    &
               * (EReact * 1E6)**(1.0 - Xi_Total/2.)
        ReactionProb = ReactionProb / ((1E6)**(ChemReac%Arrhenius_Powerfactor(iReac) - 0.5 + SpecDSMC(EductReac(1))%omegaVHS))
      ELSE
        ReactionProb = BetaReaction * ((EReact - ChemReac%EActiv(iReac)))                                                       &
              ** (ChemReac%Arrhenius_Powerfactor(iReac) - 1.5 + SpecDSMC(EductReac(1))%omegaVHS             &
              + Xi_Total/2.) * (EReact) ** (1.0 - SpecDSMC(EductReac(1))%VFD_Phi3_Factor - Xi_Total/2.)
      END IF
    END IF
  ELSE
    ReactionProb = 0.0
  END IF

  IF(DSMC%ReservoirSimu) THEN
#if (PP_TimeDiscMethod==42)
    IF(DSMC%ReservoirRateStatistic) THEN
#endif
      IF(ReactionProb.GT.1) THEN
        IPWRITE(*,*) 'Warning: ReactionProb greater than unity! ReacNbr:', iReac
      END IF
#if (PP_TimeDiscMethod==42)
    END IF
#endif
  END IF

END SUBROUTINE CalcReactionProb


SUBROUTINE DSMC_Chemistry(iPair, iReac, iPart_p3)
!===================================================================================================================================
! Routine performs an exchange reaction of the type A + B + C -> D + E + F, where A, B, C, D, E, F can be anything
!===================================================================================================================================
! MODULES
USE MOD_Globals,               ONLY : abort
USE MOD_Globals_Vars,          ONLY : BoltzmannConst, ElementaryCharge
USE MOD_DSMC_Vars,             ONLY : Coll_pData, DSMC_RHS, DSMC, CollInf, SpecDSMC, DSMCSumOfFormedParticles
USE MOD_DSMC_Vars,             ONLY : ChemReac, PartStateIntEn, PolyatomMolDSMC, VibQuantsPar
USE MOD_Particle_Vars,         ONLY : PartSpecies, PartState, PDM, PEM, PartPosRef, Species
USE MOD_vmpf_collision,        ONLY : vMPF_AfterSplitting
USE MOD_DSMC_ElectronicModel,  ONLY : ElectronicEnergyExchange, CalcXiElec
USE MOD_DSMC_PolyAtomicModel,  ONLY : DSMC_VibRelaxPoly, DSMC_RotRelaxPoly, DSMC_RelaxVibPolyProduct
USE MOD_DSMC_Analyze,          ONLY : CalcTVib, CalcTVibPoly, CalcTelec
USE MOD_DSMC_Relaxation,       ONLY : DSMC_VibRelaxDiatomic, CalcXiVibPart, CalcXiTotalEqui
USE MOD_part_tools,            ONLY : DiceUnitVector
USE MOD_Particle_Tracking_Vars,ONLY : DoRefmapping
USE MOD_Particle_Analyze_Vars, ONLY : ChemEnergySum
! IMPLICIT VARIABLE HANDLING
  IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES                                                                                
  INTEGER, INTENT(IN)           :: iPair, iReac
  INTEGER, INTENT(IN), OPTIONAL  :: iPart_p3
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
  REAL                          :: FracMassCent1, FracMassCent2, MassRed     ! mx/(mx+my)
  REAL                          :: VeloMx, VeloMy, VeloMz           ! center of mass velo
  REAL                          :: RanVelox, RanVeloy, RanVeloz , RanVec(3)   ! random relativ velo
  REAL                          :: FakXi, Xi_rel, iRan, FacEtraDistri
  REAL                          :: ERel_React1_React2, ERel_React1_React3
  INTEGER                       :: React1Inx, React2Inx, React3Inx
  INTEGER                       :: ProductReac(1:3), EductReac(1:3), nProd, nDOFMAX, iProd, iPolyatMole
  REAL                          :: Xi_elec(1:3), Telec(1:3), EZeroTempToExec(1:3)
  REAL, ALLOCATABLE             :: Xi_Vib1(:), Xi_Vib2(:), Xi_Vib3(:), XiVibPart(:,:)
  REAL                          :: VxPseuMolec, VyPseuMolec, VzPseuMolec
!===================================================================================================================================
  Xi_elec = 0.
  Telec = 0.
  EZeroTempToExec = 0.

!..Get the index of react1 and the react2
  IF (PartSpecies(Coll_pData(iPair)%iPart_p1).EQ.ChemReac%DefinedReact(iReac,1,1)) THEN
    React1Inx = Coll_pData(iPair)%iPart_p1
    React2Inx = Coll_pData(iPair)%iPart_p2 
  ELSE
    React2Inx = Coll_pData(iPair)%iPart_p1
    React1Inx = Coll_pData(iPair)%iPart_p2
  END IF

  EductReac(1:3) = ChemReac%DefinedReact(iReac,1,1:3)
  ProductReac(1:3) = ChemReac%DefinedReact(iReac,2,1:3)

  IF(PRESENT(iPart_p3)) THEN
    React3Inx = iPart_p3
    IF((TRIM(ChemReac%ReactType(iReac)).EQ.'R').OR.(TRIM(ChemReac%ReactType(iReac)).EQ.'r')) THEN
      EductReac(3) = PartSpecies(React3Inx)
      ProductReac(2) = PartSpecies(React3Inx)
    END IF
    IF(ProductReac(3).EQ.0) THEN
      PDM%ParticleInside(React3Inx) = .FALSE.
    ELSE
      PartSpecies(React3Inx) = ProductReac(3)
    END IF
  ELSE
    IF(ProductReac(3).NE.0) THEN
      !.... Get free particle index for the 3rd particle produced
      DSMCSumOfFormedParticles = DSMCSumOfFormedParticles + 1
      React3Inx = PDM%nextFreePosition(DSMCSumOfFormedParticles+PDM%CurrentNextFreePosition)
      IF (React3Inx.EQ.0) THEN
        CALL abort(__STAMP__,&
        'New Particle Number greater max Part Num in DSMC_Chemistry. Reaction: ',iReac)
      END IF
      !Set new Species of new particle
      PDM%ParticleInside(React3Inx) = .true.
      PDM%IsNewPart(React3Inx) = .true.
      PDM%dtFracPush(React3Inx) = .FALSE.
      PartSpecies(React3Inx) = ProductReac(3)
      PartState(React3Inx,1:3) = PartState(React1Inx,1:3)
      IF(DoRefMapping)THEN ! here Nearst-GP is missing
        PartPosRef(1:3,React3Inx)=PartPosRef(1:3,React1Inx)
      END IF
      PartStateIntEn(React3Inx, 1) = 0.
      PartStateIntEn(React3Inx, 2) = 0.
      IF ( DSMC%ElectronicModel )  PartStateIntEn(React3Inx, 3) = 0.
      PEM%Element(React3Inx) = PEM%Element(React1Inx)
    END IF
  END IF

  ! Add heat of formation to collision energy
  Coll_pData(iPair)%Ec = 0.5 * CollInf%MassRed(Coll_pData(iPair)%PairType)*Coll_pData(iPair)%CRela2 + ChemReac%EForm(iReac)
  ChemEnergySum = ChemEnergySum + ChemReac%EForm(iReac)*Species(PartSpecies(React1Inx))%MacroParticleFactor
  !-------------------------------------------------------------------------------------------------------------------------------
  ! Rotational degrees of freedom
  !-------------------------------------------------------------------------------------------------------------------------------
  IF(ProductReac(3).EQ.0) THEN
    Xi_rel = 2.*(2. - SpecDSMC(PartSpecies(Coll_pData(iPair)%iPart_p1))%omegaVHS)
    FakXi = 0.5*(Xi_rel + SpecDSMC(ProductReac(1))%Xi_Rot &
          + SpecDSMC(ProductReac(2))%Xi_Rot) - 1.0
    nProd = 2
  ELSE
    Xi_rel = 4.*(2. - SpecDSMC(PartSpecies(Coll_pData(iPair)%iPart_p1))%omegaVHS)
    FakXi = 0.5*(Xi_rel + SpecDSMC(ProductReac(1))%Xi_Rot &
          + SpecDSMC(ProductReac(2))%Xi_Rot + SpecDSMC(ProductReac(3))%Xi_Rot) - 1.0
    nProd = 3
  END IF

  ! Adding the vibrational and rotational energy to the collision energy
  Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec + PartStateIntEn(React1Inx,2) + PartStateIntEn(React2Inx,2) &
                        + PartStateIntEn(React1Inx,1) + PartStateIntEn(React2Inx,1)
  ! Addition of the electronic energy to the collision energy)
  IF (DSMC%ElectronicModel) THEN
    Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec + PartStateIntEn(React1Inx,3) + PartStateIntEn(React2Inx,3)
  END IF

  IF(EductReac(3).NE.0) THEN
    ! If a third collision partner exists (recombination/exchange reactions with defined third educt, A + B+ C), calculation of
    ! the centre of mass of a pseudo-molecule consisting of the first two educts -> (AB) + C
    FracMassCent1 = CollInf%FracMassCent(EductReac(1), Coll_pData(iPair)%PairType)
    FracMassCent2 = CollInf%FracMassCent(EductReac(2), Coll_pData(iPair)%PairType)

    VeloMx = FracMassCent1 * PartState(React1Inx, 4) &
           + FracMassCent2 * PartState(React2Inx, 4)
    VeloMy = FracMassCent1 * PartState(React1Inx, 5) &
           + FracMassCent2 * PartState(React2Inx, 5)
    VeloMz = FracMassCent1 * PartState(React1Inx, 6) &
           + FracMassCent2 * PartState(React2Inx, 6)

    ! Overwriting the PartState of the first particle with the new PartState of the pseudo-molecule (AB)
    PartState(React1Inx, 4) = VeloMx
    PartState(React1Inx, 5) = VeloMy
    PartState(React1Inx, 6) = VeloMz

    ! Calculation of the reduced mass of the pseudo-molecule and third collision partner
    CALL CalcPseudoScatterVars(EductReac(1),EductReac(2),EductReac(3),FracMassCent1,FracMassCent2,MassRed)
    ! Addition of the relative translation energy between (AB) and C, rotational and vibrational energy of the third
    Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec + PartStateIntEn(React3Inx,1) + PartStateIntEn(React3Inx,2) &
      + 0.5 * MassRed * ((VeloMx-PartState(React3Inx,4))**2+(VeloMy-PartState(React3Inx,5))**2+(VeloMz-PartState(React3Inx,6))**2)
    IF(DSMC%ElectronicModel) Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec + PartStateIntEn(React3Inx,3)
  END IF

  !-------------------------------------------------------------------------------------------------------------------------------
  ! Redistribution of collisional energy according to the equipartion theorem
  !-------------------------------------------------------------------------------------------------------------------------------
  ! Determining the maximal number of vibrational SHOs for allocation of the XiVibPart array
  nDOFMAX = 0
  DO iProd = 1, nProd
    IF((SpecDSMC(ProductReac(iProd))%InterID.EQ.2).OR.(SpecDSMC(ProductReac(iProd))%InterID.EQ.20)) THEN
      IF(SpecDSMC(ProductReac(iProd))%PolyatomicMol) THEN
        iPolyatMole = SpecDSMC(ProductReac(iProd))%SpecToPolyArray
        nDOFMAX = MAX(nDOFMAX,PolyatomMolDSMC(iPolyatMole)%VibDOF)
      ELSE
        nDOFMAX = MAX(nDOFMAX,1)
      END IF
    END IF
  END DO

  ! Root-finding algorithm to determine the vibrational and electronic degrees of freedom
  IF((nDOFMAX.GT.0).AND.(DSMC%ElectronicModel)) THEN
    ALLOCATE(XiVibPart(nProd,nDOFMAX))
    CALL CalcXiTotalEqui(iReac, iPair, Xi_rel, XiVibPart=XiVibPart, XiElecPart=Xi_elec)
  ELSEIF(DSMC%ElectronicModel) THEN
    CALL CalcXiTotalEqui(iReac, iPair, Xi_rel, XiElecPart=Xi_elec)
  ELSEIF(nDOFMAX.GT.0) THEN
    ALLOCATE(XiVibPart(nProd,nDOFMAX))
    CALL CalcXiTotalEqui(iReac, iPair, Xi_rel, XiVibPart=XiVibPart)
  END IF
  
  IF(nDOFMAX.GT.0) THEN
    IF((SpecDSMC(ProductReac(1))%InterID.EQ.2).OR.(SpecDSMC(ProductReac(1))%InterID.EQ.20)) THEN
      IF(SpecDSMC(ProductReac(1))%PolyatomicMol) THEN
        iPolyatMole = SpecDSMC(ProductReac(1))%SpecToPolyArray
        ALLOCATE(Xi_vib1(PolyatomMolDSMC(iPolyatMole)%VibDOF))
        Xi_vib1(1:PolyatomMolDSMC(iPolyatMole)%VibDOF)=XiVibPart(1,1:PolyatomMolDSMC(iPolyatMole)%VibDOF)
      ELSE
        ALLOCATE(Xi_vib1(1))
        Xi_vib1(1) = XiVibPart(1,1)
      END IF
      FakXi = FakXi + 0.5*SUM(Xi_vib1)
      EZeroTempToExec(1) = SpecDSMC(ProductReac(1))%EZeroPoint
    END IF
    IF((SpecDSMC(ProductReac(2))%InterID.EQ.2).OR.(SpecDSMC(ProductReac(2))%InterID.EQ.20)) THEN
      IF(SpecDSMC(ProductReac(2))%PolyatomicMol) THEN
        iPolyatMole = SpecDSMC(ProductReac(2))%SpecToPolyArray
        ALLOCATE(Xi_vib2(PolyatomMolDSMC(iPolyatMole)%VibDOF))
        Xi_vib2(1:PolyatomMolDSMC(iPolyatMole)%VibDOF)=XiVibPart(2,1:PolyatomMolDSMC(iPolyatMole)%VibDOF)
      ELSE
        ALLOCATE(Xi_vib2(1))
        Xi_vib2(1) = XiVibPart(2,1)
      END IF
      FakXi = FakXi + 0.5*SUM(Xi_vib2)
      EZeroTempToExec(2) = SpecDSMC(ProductReac(2))%EZeroPoint
    END IF
    IF(ProductReac(3).NE.0) THEN
      IF((SpecDSMC(ProductReac(3))%InterID.EQ.2).OR.(SpecDSMC(ProductReac(3))%InterID.EQ.20)) THEN
        IF(SpecDSMC(ProductReac(3))%PolyatomicMol) THEN
          iPolyatMole = SpecDSMC(ProductReac(3))%SpecToPolyArray
          ALLOCATE(Xi_vib3(PolyatomMolDSMC(iPolyatMole)%VibDOF))
          Xi_vib3(1:PolyatomMolDSMC(iPolyatMole)%VibDOF)= XiVibPart(3,1:PolyatomMolDSMC(iPolyatMole)%VibDOF)
        ELSE
          ALLOCATE(Xi_vib3(1))
          Xi_vib3(1) = XiVibPart(3,1)
        END IF
        FakXi = FakXi + 0.5*SUM(Xi_vib3)
        EZeroTempToExec(3) = SpecDSMC(ProductReac(3))%EZeroPoint
      END IF
    END IF
  END IF

  ! Substracting the zero-point energy of the products (is added back later)
  Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec - SUM(EZeroTempToExec(:))
  ! Set new Species of molec and atom
  PartSpecies(React1Inx) = ProductReac(1)
  PartSpecies(React2Inx) = ProductReac(2)

  !--------------------------------------------------------------------------------------------------
  ! Electronic energy exchange
  !--------------------------------------------------------------------------------------------------
  IF (DSMC%ElectronicModel) THEN
    FakXi = FakXi + 0.5*(Xi_elec(1)+Xi_elec(2))
    IF(ProductReac(3).NE.0) THEN
      IF(SpecDSMC(ProductReac(3))%InterID.EQ.4) THEN
        PartStateIntEn(React3Inx,3) = 0.0
      ELSE
        CALL ElectronicEnergyExchange(iPair,React3Inx,FakXi)
        Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec - PartStateIntEn(React3Inx,3)
      END IF
    END IF
    FakXi = FakXi - 0.5*Xi_elec(2)
    IF(SpecDSMC(ProductReac(2))%InterID.EQ.4) THEN
      PartStateIntEn(React2Inx,3) = 0.0
    ELSE
      CALL ElectronicEnergyExchange(iPair,React2Inx,FakXi)
      Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec - PartStateIntEn(React2Inx,3)
    END IF
    FakXi = FakXi - 0.5*Xi_elec(1)
    IF(SpecDSMC(ProductReac(1))%InterID.EQ.4) THEN
      PartStateIntEn(React1Inx,3) = 0.0
    ELSE
      CALL ElectronicEnergyExchange(iPair,React1Inx,FakXi)
      Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec - PartStateIntEn(React1Inx,3)
    END IF
  END IF ! DSMC%ElectronicModel
  !--------------------------------------------------------------------------------------------------
  ! Vibrational energy exchange
  !--------------------------------------------------------------------------------------------------
  IF(ProductReac(3).NE.0) THEN
    ! Relaxation of third collision partner
    IF((SpecDSMC(ProductReac(3))%InterID.EQ.2).OR.(SpecDSMC(ProductReac(3))%InterID.EQ.20)) THEN
      FakXi = FakXi - 0.5*Xi_vib3(1)
      IF(SpecDSMC(ProductReac(3))%PolyatomicMol) THEN
        ! Zero-point energy is added (for every vibrational dof separately) and new vibrational state is substracted
        ! from the collision energy within the routine
        CALL DSMC_RelaxVibPolyProduct(iPair, React3Inx, FakXi, Xi_Vib3)
      ELSE
        IF(EductReac(3).NE.0) THEN
          IF(SpecDSMC(EductReac(3))%PolyatomicMol) DEALLOCATE(VibQuantsPar(React3Inx)%Quants)
        END IF
        Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec + EZeroTempToExec(3)
        CALL DSMC_VibRelaxDiatomic(iPair,React3Inx,FakXi)
        Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec - PartStateIntEn(React3Inx,1)
      END IF
    END IF
  END IF

  ! Relaxation of first product
  IF((SpecDSMC(ProductReac(1))%InterID.EQ.2).OR.(SpecDSMC(ProductReac(1))%InterID.EQ.20)) THEN
    FakXi = FakXi - 0.5*Xi_vib1(1)
    IF(SpecDSMC(ProductReac(1))%PolyatomicMol) THEN
      ! Zero-point energy is added (for every vibrational dof separately) and new vibrational state is substracted
      ! from the collision energy within the routine
      CALL DSMC_RelaxVibPolyProduct(iPair, React1Inx, FakXi, Xi_Vib1)
    ELSE
      Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec + EZeroTempToExec(1)
      IF(SpecDSMC(EductReac(1))%PolyatomicMol) DEALLOCATE(VibQuantsPar(React1Inx)%Quants)
      CALL DSMC_VibRelaxDiatomic(iPair,React1Inx,FakXi)
      Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec - PartStateIntEn(React1Inx,1)
    END IF
  END IF

  ! Relaxation of second product
  IF((SpecDSMC(ProductReac(2))%InterID.EQ.2).OR.(SpecDSMC(ProductReac(2))%InterID.EQ.20)) THEN
    FakXi = FakXi - 0.5*Xi_vib2(1)
    IF(SpecDSMC(ProductReac(2))%PolyatomicMol) THEN
      ! Zero-point energy is added (for every vibrational dof separately) and new vibrational state is substracted
      ! from the collision energy within the routine
      CALL DSMC_RelaxVibPolyProduct(iPair, React2Inx, FakXi, Xi_Vib2)
    ELSE
      Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec + EZeroTempToExec(2)
      CALL DSMC_VibRelaxDiatomic(iPair,React2Inx,FakXi)
      Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec - PartStateIntEn(React2Inx,1)
    END IF
  END IF

  !--------------------------------------------------------------------------------------------------
  ! Rotational energy exchange (additional check: If new particle is an atom, internal energies are zero)
  !--------------------------------------------------------------------------------------------------
  ! Rotational Relaxation 3
  IF(ProductReac(3).NE.0) THEN
    IF ((SpecDSMC(ProductReac(3))%InterID.EQ.2).OR.(SpecDSMC(ProductReac(3))%InterID.EQ.20)) THEN
      IF(SpecDSMC(ProductReac(3))%Xi_Rot.EQ.3) THEN
        FakXi = FakXi - 0.5*SpecDSMC(ProductReac(3))%Xi_Rot
        CALL DSMC_RotRelaxPoly(iPair, React3Inx, FakXi)
      ELSE
        CALL RANDOM_NUMBER(iRan)
        PartStateIntEn(React3Inx,2) = Coll_pData(iPair)%Ec * (1.0 - iRan**(1.0/FakXi))
        FakXi = FakXi - 0.5*SpecDSMC(ProductReac(3))%Xi_Rot
      END IF    
      Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec - PartStateIntEn(React3Inx,2)
    ELSE
      PartStateIntEn(React3Inx,1) = 0.0
      PartStateIntEn(React3Inx,2) = 0.0
    END IF
  END IF
  ! Rotational Relaxation 1
  IF((SpecDSMC(ProductReac(1))%InterID.EQ.2).OR.(SpecDSMC(ProductReac(1))%InterID.EQ.20)) THEN
    IF(SpecDSMC(ProductReac(1))%Xi_Rot.EQ.3) THEN
      FakXi = FakXi - 0.5*SpecDSMC(ProductReac(1))%Xi_Rot
      CALL DSMC_RotRelaxPoly(iPair, React1Inx, FakXi)
    ELSE
      CALL RANDOM_NUMBER(iRan)
      PartStateIntEn(React1Inx,2) = Coll_pData(iPair)%Ec * (1.0 - iRan**(1.0/FakXi))
      FakXi = FakXi - 0.5*SpecDSMC(ProductReac(1))%Xi_Rot
    END IF
    Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec - PartStateIntEn(React1Inx,2)
  ELSE
    PartStateIntEn(React1Inx,1) = 0.0
    PartStateIntEn(React1Inx,2) = 0.0
  END IF
  ! Rotational Relaxation 2
  IF((SpecDSMC(ProductReac(2))%InterID.EQ.2).OR.(SpecDSMC(ProductReac(2))%InterID.EQ.20)) THEN
    IF(SpecDSMC(ProductReac(2))%Xi_Rot.EQ.3) THEN
      FakXi = FakXi - 0.5*SpecDSMC(ProductReac(2))%Xi_Rot
      CALL DSMC_RotRelaxPoly(iPair, React2Inx, FakXi)
    ELSE
      CALL RANDOM_NUMBER(iRan)
      PartStateIntEn(React2Inx,2) = Coll_pData(iPair)%Ec * (1.0 - iRan**(1.0/FakXi))
      FakXi = FakXi - 0.5*SpecDSMC(ProductReac(2))%Xi_Rot
    END IF
    Coll_pData(iPair)%Ec = Coll_pData(iPair)%Ec - PartStateIntEn(React2Inx,2)
  ELSE
    PartStateIntEn(React2Inx,1) = 0.0
    PartStateIntEn(React2Inx,2) = 0.0
  END IF

!--------------------------------------------------------------------------------------------------! 
! Calculation of new particle velocities
!--------------------------------------------------------------------------------------------------! 
  IF(ProductReac(3).NE.0) THEN
    ! If a third product exists, the remaining collision energy has to distributed onto three particles
    CALL RANDOM_NUMBER(iRan)
    FacEtraDistri = iRan
    CALL RANDOM_NUMBER(iRan)
    ! laux diss page 40, omegaVHS only of one species
    DO WHILE ((4 *FacEtraDistri*(1-FacEtraDistri))**(1-SpecDSMC(EductReac(1))%omegaVHS).LT.iRan)
      CALL RANDOM_NUMBER(iRan)
      FacEtraDistri = iRan
      CALL RANDOM_NUMBER(iRan)
    END DO
    ERel_React1_React2 = Coll_pData(iPair)%Ec * FacEtraDistri
    ERel_React1_React3 = Coll_pData(iPair)%Ec - ERel_React1_React2
    IF(EductReac(3).NE.0) THEN
      ! Scattering 3 -> 3: Utilizing the FracMassCent's from above, calculated for the pseudo-molecule and the third educt,
      ! PartState(React1Inx) is the centre of mass of the pseudo-molecule
      VeloMx = FracMassCent1 * PartState(React1Inx, 4) &
             + FracMassCent2 * PartState(React3Inx, 4)
      VeloMy = FracMassCent1 * PartState(React1Inx, 5) &
             + FracMassCent2 * PartState(React3Inx, 5)
      VeloMz = FracMassCent1 * PartState(React1Inx, 6) &
             + FracMassCent2 * PartState(React3Inx, 6)
    ELSE
      ! Scattering 2 -> 3
      FracMassCent1 = CollInf%FracMassCent(EductReac(1), Coll_pData(iPair)%PairType)
      FracMassCent2 = CollInf%FracMassCent(EductReac(2), Coll_pData(iPair)%PairType)

      !Calculation of velo from center of mass
      VeloMx = FracMassCent1 * PartState(React1Inx, 4) &
             + FracMassCent2 * PartState(React2Inx, 4)
      VeloMy = FracMassCent1 * PartState(React1Inx, 5) &
             + FracMassCent2 * PartState(React2Inx, 5)
      VeloMz = FracMassCent1 * PartState(React1Inx, 6) &
             + FracMassCent2 * PartState(React2Inx, 6)
    END IF

    ! FracMassCent's and reduced mass are calculated for the pseudo-molecule 1-3 and the second product, in the case of dissociation
    ! this is the non-reating collision partner
    CALL CalcPseudoScatterVars(ProductReac(1),ProductReac(3),ProductReac(2),FracMassCent1,FracMassCent2,MassRed)

    ! Calculate random vec and new squared velocities
    Coll_pData(iPair)%CRela2 = 2 * ERel_React1_React2 / MassRed
    RanVec(1:3) = DiceUnitVector()
    RanVelox = SQRT(Coll_pData(iPair)%CRela2) * RanVec(1)
    RanVeloy = SQRT(Coll_pData(iPair)%CRela2) * RanVec(2)
    RanVeloz = SQRT(Coll_pData(iPair)%CRela2) * RanVec(3)
    
    ! Determine right-hand side for the second product molecule (only required due to the push procedure in the timedisc)
    DSMC_RHS(React2Inx,1) = VeloMx - FracMassCent1*RanVelox - PartState(React2Inx, 4)
    DSMC_RHS(React2Inx,2) = VeloMy - FracMassCent1*RanVeloy - PartState(React2Inx, 5)
    DSMC_RHS(React2Inx,3) = VeloMz - FracMassCent1*RanVeloz - PartState(React2Inx, 6)

    ! Set velocity of pseudo molec (AB) and calculate the centre of mass frame velocity: m_pseu / (m_3 + m_4) * v_pseu
    ! (Velocity of pseudo molecule is NOT equal to the COM frame velocity)
    VxPseuMolec = (VeloMx + FracMassCent2*RanVelox)
    VyPseuMolec = (VeloMy + FracMassCent2*RanVeloy)
    VzPseuMolec = (VeloMz + FracMassCent2*RanVeloz)

    ! Scattering of (AB)
    FracMassCent1 = CollInf%FracMassCent(ProductReac(1),CollInf%Coll_Case(ProductReac(1),ProductReac(3)))
    FracMassCent2 = CollInf%FracMassCent(ProductReac(3),CollInf%Coll_Case(ProductReac(1),ProductReac(3)))

    !calculate random vec and new squared velocities
    Coll_pData(iPair)%CRela2 = 2 *  ERel_React1_React3 / & 
            CollInf%MassRed(CollInf%Coll_Case(ProductReac(1),ProductReac(3)))
    RanVec(1:3) = DiceUnitVector()
    RanVelox = SQRT(Coll_pData(iPair)%CRela2) * RanVec(1)
    RanVeloy = SQRT(Coll_pData(iPair)%CRela2) * RanVec(2)
    RanVeloz = SQRT(Coll_pData(iPair)%CRela2) * RanVec(3)

    !deltaV particle 1
    DSMC_RHS(React1Inx,1) = VxPseuMolec + FracMassCent2*RanVelox - PartState(React1Inx, 4)
    DSMC_RHS(React1Inx,2) = VyPseuMolec + FracMassCent2*RanVeloy - PartState(React1Inx, 5)
    DSMC_RHS(React1Inx,3) = VzPseuMolec + FracMassCent2*RanVeloz - PartState(React1Inx, 6)

    !deltaV particle 3
    PartState(React3Inx,4:6) = 0.
    DSMC_RHS(React3Inx,1) = VxPseuMolec - FracMassCent1*RanVelox
    DSMC_RHS(React3Inx,2) = VyPseuMolec - FracMassCent1*RanVeloy
    DSMC_RHS(React3Inx,3) = VzPseuMolec - FracMassCent1*RanVeloz

  ELSEIF(ProductReac(3).EQ.0) THEN
    IF(EductReac(3).NE.0) THEN
      ! Scattering 3 -> 2
      VxPseuMolec = FracMassCent1 * PartState(React1Inx, 4) &
             + FracMassCent2 * PartState(React3Inx, 4)
      VyPseuMolec = FracMassCent1 * PartState(React1Inx, 5) &
             + FracMassCent2 * PartState(React3Inx, 5)
      VzPseuMolec = FracMassCent1 * PartState(React1Inx, 6) &
             + FracMassCent2 * PartState(React3Inx, 6)
      ! When RHS is set, React2Inx is utilized, not an error as the old state cancels out after the particle push in the time disc,
      ! therefore, there is no need to set change the index as the proper species, ProductReac(2), was utilized for the relaxation
    ELSE
      ! Scattering 2 -> 2
      FracMassCent1 = CollInf%FracMassCent(EductReac(1), &
                    CollInf%Coll_Case(EductReac(1),EductReac(2)))
      FracMassCent2 = CollInf%FracMassCent(EductReac(2), & 
                    CollInf%Coll_Case(EductReac(1),EductReac(2)))

      VxPseuMolec = FracMassCent1 * PartState(React1Inx, 4) &
             + FracMassCent2 * PartState(React2Inx, 4)
      VyPseuMolec = FracMassCent1 * PartState(React1Inx, 5) &
             + FracMassCent2 * PartState(React2Inx, 5)
      VzPseuMolec = FracMassCent1 * PartState(React1Inx, 6) &
             + FracMassCent2 * PartState(React2Inx, 6)
    END IF
    ERel_React1_React3 = Coll_pData(iPair)%Ec

    ! Scattering of (AB)
    FracMassCent1 = CollInf%FracMassCent(ProductReac(1),CollInf%Coll_Case(ProductReac(1),ProductReac(2)))
    FracMassCent2 = CollInf%FracMassCent(ProductReac(2),CollInf%Coll_Case(ProductReac(1),ProductReac(2)))

    !calculate random vec and new squared velocities
    Coll_pData(iPair)%CRela2 = 2 *  ERel_React1_React3 / & 
            CollInf%MassRed(CollInf%Coll_Case(ProductReac(1),ProductReac(2)))
    RanVec(1:3) = DiceUnitVector()
    RanVelox = SQRT(Coll_pData(iPair)%CRela2) * RanVec(1)
    RanVeloy = SQRT(Coll_pData(iPair)%CRela2) * RanVec(2)
    RanVeloz = SQRT(Coll_pData(iPair)%CRela2) * RanVec(3)

    !deltaV particle 1
    DSMC_RHS(React1Inx,1) = VxPseuMolec + FracMassCent2*RanVelox - PartState(React1Inx, 4)
    DSMC_RHS(React1Inx,2) = VyPseuMolec + FracMassCent2*RanVeloy - PartState(React1Inx, 5)
    DSMC_RHS(React1Inx,3) = VzPseuMolec + FracMassCent2*RanVeloz - PartState(React1Inx, 6)

    !deltaV particle 2
    DSMC_RHS(React2Inx,1) = VxPseuMolec - FracMassCent1*RanVelox - PartState(React2Inx, 4)
    DSMC_RHS(React2Inx,2) = VyPseuMolec - FracMassCent1*RanVeloy - PartState(React2Inx, 5)
    DSMC_RHS(React2Inx,3) = VzPseuMolec - FracMassCent1*RanVeloz - PartState(React2Inx, 6)
  END IF

END SUBROUTINE DSMC_Chemistry


SUBROUTINE simpleCEX(iReac, iPair, resetRHS_opt)
!===================================================================================================================================
! simple charge exchange interaction     
! ION(v1) + ATOM(v2) -> ATOM(v1) + ION(v2)
!===================================================================================================================================
! MODULES
  USE MOD_DSMC_Vars,             ONLY : Coll_pData, DSMC_RHS
  USE MOD_DSMC_Vars,             ONLY : ChemReac
  USE MOD_Particle_Vars,         ONLY : PartSpecies
! IMPLICIT VARIABLE HANDLING
  IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES                                                                                
  INTEGER, INTENT(IN)           :: iPair, iReac
  LOGICAL, INTENT(IN), OPTIONAL :: resetRHS_opt
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
  INTEGER                       :: React1Inx, React2Inx
  LOGICAL                       :: resetRHS
!===================================================================================================================================

  IF (PRESENT(resetRHS_opt)) THEN
    resetRHS=resetRHS_opt
  ELSE
    resetRHS=.TRUE.
  END IF

  IF (PartSpecies(Coll_pData(iPair)%iPart_p1).EQ.ChemReac%DefinedReact(iReac,1,1)) THEN
    React1Inx = Coll_pData(iPair)%iPart_p1
    React2Inx = Coll_pData(iPair)%iPart_p2
  ELSE
    React2Inx = Coll_pData(iPair)%iPart_p1
    React1Inx = Coll_pData(iPair)%iPart_p2
  END IF
  ! change species
  PartSpecies(React1Inx) = ChemReac%DefinedReact(iReac,2,1)
  PartSpecies(React2Inx) = ChemReac%DefinedReact(iReac,2,2)

  IF (resetRHS) THEN
    ! deltaV particle 1
    DSMC_RHS(Coll_pData(iPair)%iPart_p1,1) = 0.
    DSMC_RHS(Coll_pData(iPair)%iPart_p1,2) = 0.
    DSMC_RHS(Coll_pData(iPair)%iPart_p1,3) = 0.
    ! deltaV particle 2
    DSMC_RHS(Coll_pData(iPair)%iPart_p2,1) = 0.
    DSMC_RHS(Coll_pData(iPair)%iPart_p2,2) = 0.
    DSMC_RHS(Coll_pData(iPair)%iPart_p2,3) = 0.
  END IF

END SUBROUTINE simpleCEX


SUBROUTINE simpleMEX(iReac, iPair)
!===================================================================================================================================
! simple momentum exchange interaction     
! ION(v1) + ATOM(v2) -> ION2(v1') + ATOM(v2')
!===================================================================================================================================
! MODULES
  USE MOD_Globals,               ONLY : abort
  USE MOD_DSMC_Vars,             ONLY : Coll_pData !, DSMC_RHS
  USE MOD_DSMC_Vars,             ONLY : ChemReac
  USE MOD_Particle_Vars,         ONLY : PartSpecies,Species
! IMPLICIT VARIABLE HANDLING
  IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES                                                                                
  INTEGER, INTENT(IN)           :: iPair, iReac
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
  INTEGER                       :: React1Inx, React2Inx
!===================================================================================================================================

  IF (PartSpecies(Coll_pData(iPair)%iPart_p1).EQ.ChemReac%DefinedReact(iReac,1,1)) THEN
    React1Inx = Coll_pData(iPair)%iPart_p1
    React2Inx = Coll_pData(iPair)%iPart_p2
  ELSE
    React2Inx = Coll_pData(iPair)%iPart_p1
    React1Inx = Coll_pData(iPair)%iPart_p2
  END IF
  ! change species of educt-ion to product-ion
  IF (Species(PartSpecies(React1Inx))%ChargeIC.NE.0. .AND. Species(PartSpecies(React2Inx))%ChargeIC.EQ.0.) THEN
    PartSpecies(React1Inx) = ChemReac%DefinedReact(iReac,2,2)
  ELSE IF (Species(PartSpecies(React2Inx))%ChargeIC.NE.0. .AND. Species(PartSpecies(React1Inx))%ChargeIC.EQ.0.) THEN
    PartSpecies(React2Inx) = ChemReac%DefinedReact(iReac,2,1)
  ELSE
    CALL abort(&
     __STAMP__&
      ,'ERROR in simpleMEX: one of the products must be an ion!')
  END IF

END SUBROUTINE simpleMEX


SUBROUTINE CalcPartitionFunction(iSpec, Temp, Qtra, Qrot, Qvib, Qelec)
!===================================================================================================================================
! Calculation of the partition function for a species at the given temperature
!===================================================================================================================================
! MODULES
USE MOD_Globals
USE MOD_Globals_Vars,       ONLY: Pi, PlanckConst, BoltzmannConst
USE MOD_DSMC_Vars,          ONLY: SpecDSMC, PolyatomMolDSMC
USE MOD_Particle_Vars,      ONLY: Species
! IMPLICIT VARIABLE HANDLING
 IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
  INTEGER, INTENT(IN)           :: iSpec
  REAL, INTENT(IN)               :: Temp
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
  REAL, INTENT(OUT)              :: Qtra, Qrot, Qvib, Qelec
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
  INTEGER                        :: iPolyatMole, iDOF
!===================================================================================================================================

  Qtra = (2. * Pi * Species(iSpec)%MassIC * BoltzmannConst * Temp / (PlanckConst**2))**(1.5)
  IF((SpecDSMC(iSpec)%InterID.EQ.2).OR.(SpecDSMC(iSpec)%InterID.EQ.20)) THEN
    IF(SpecDSMC(iSpec)%PolyatomicMol) THEN
      iPolyatMole = SpecDSMC(iSpec)%SpecToPolyArray
      IF(PolyatomMolDSMC(iPolyatMole)%LinearMolec) THEN
        Qrot = Temp / (SpecDSMC(iSpec)%SymmetryFactor * PolyatomMolDSMC(iPolyatMole)%CharaTRotDOF(1))
      ELSE
        Qrot = SQRT(Pi) / SpecDSMC(iSpec)%SymmetryFactor * SQRT(Temp**3/( PolyatomMolDSMC(iPolyatMole)%CharaTRotDOF(1)    &
                                                                        * PolyatomMolDSMC(iPolyatMole)%CharaTRotDOF(2)    &
                                                                        * PolyatomMolDSMC(iPolyatMole)%CharaTRotDOF(3)))
      END IF
      Qvib = 1.
      DO iDOF = 1, PolyatomMolDSMC(iPolyatMole)%VibDOF
        Qvib = Qvib / (1. - EXP(-PolyatomMolDSMC(iPolyatMole)%CharaTVibDOF(iDOF) / Temp))
      END DO
    ELSE
      Qrot = Temp / (SpecDSMC(iSpec)%SymmetryFactor * SpecDSMC(iSpec)%CharaTRot)
      Qvib = 1. / (1. - EXP(-SpecDSMC(iSpec)%CharaTVib / Temp))
    END IF
  ELSE
    Qrot = 1.
    Qvib = 1.
  END IF
  IF(SpecDSMC(iSpec)%InterID.NE.4) THEN
    Qelec = 0.
    DO iDOF=0, SpecDSMC(iSpec)%MaxElecQuant - 1 
      Qelec = Qelec + SpecDSMC(iSpec)%ElectronicState(1,iDOF) * EXP(-SpecDSMC(iSpec)%ElectronicState(2,iDOF) / Temp)
    END DO
  ELSE
    Qelec = 1.
  END IF 

END SUBROUTINE CalcPartitionFunction


SUBROUTINE CalcBackwardRate(iReacTmp,LocalTemp,BackwardRate)
!===================================================================================================================================
! Calculation of the backward reaction rate with partition sums, interpolation within the given temperature interval
!===================================================================================================================================
! MODULES
  USE MOD_Globals
  USE MOD_DSMC_Vars,             ONLY : DSMC, SpecDSMC, ChemReac, QKBackWard
  USE MOD_Particle_Vars,         ONLY : nSpecies
! IMPLICIT VARIABLE HANDLING
  IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
  INTEGER, INTENT(IN)           :: iReacTmp
  REAL, INTENT(IN)              :: LocalTemp
  REAL, INTENT(OUT)             :: BackwardRate
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
  INTEGER                        :: iReac, iSpec, LowerLevel, UpperLevel, iChemDir, MaxElecQua
  REAL                            :: PartFuncProduct(2), k_b_lower, k_b_upper, ActivationEnergy, PartitionFunction
  REAL                            :: Qtra, Qrot, Qvib, Qelec
!===================================================================================================================================
  ! Determination of the lower and upper value of the temperature interval
  LowerLevel = INT(LocalTemp/DSMC%PartitionInterval)
  UpperLevel = LowerLevel + 1

  ! Reading the stoichiometric coefficients from the reactants
  iReac = iReacTmp - ChemReac%NumOfReact/2
  IF (ChemReac%QKProcedure(iReac)) THEN
    IF (TRIM(ChemReac%ReactType(iReac)).EQ.'iQK') THEN
      MaxElecQua=SpecDSMC(ChemReac%DefinedReact(iReac,1,1))%MaxElecQuant - 1
      ActivationEnergy = SpecDSMC(ChemReac%DefinedReact(iReac,1,1))%ElectronicState(2,MaxElecQua)
    END IF
  END IF

  ! Calculation of the backward reaction rate using the equilibrium constant)
  IF((UpperLevel.GT.INT(DSMC%PartitionMaxTemp / DSMC%PartitionInterval)).OR.(LowerLevel.EQ.0)) THEN
  ! Direct calculation at given temperature
    PartFuncProduct(1:2) = 1.
    DO iSpec = 1, nSpecies
      DO iChemDir = 1,2
        IF(ChemReac%ReactInfo(iReac)%StoichCoeff(iSpec,iChemDir).NE.0) THEN
          CALL CalcPartitionFunction(iSpec, LocalTemp, Qtra, Qrot, Qvib, Qelec)
          PartitionFunction = Qtra * Qrot * Qvib * Qelec
          PartFuncProduct(iChemDir) = PartFuncProduct(iChemDir)   &
            * PartitionFunction**(ChemReac%ReactInfo(iReac)%StoichCoeff(iSpec,iChemDir))
        END IF
      END DO
    END DO
    BackwardRate = ChemReac%Arrhenius_Prefactor(iReac)  &
                * (LocalTemp)**ChemReac%Arrhenius_Powerfactor(iReac) &
                * (PartFuncProduct(1)/PartFuncProduct(2))
  ELSE
  ! Interpolation between tabulated lower and upper values
    PartFuncProduct(1:2) = 1.
    DO iSpec = 1, nSpecies
      DO iChemDir = 1,2
        IF(ChemReac%ReactInfo(iReac)%StoichCoeff(iSpec,iChemDir).NE.0) THEN
          PartFuncProduct(iChemDir) = PartFuncProduct(iChemDir)   &
            * SpecDSMC(iSpec)%PartitionFunction(LowerLevel)**(ChemReac%ReactInfo(iReac)%StoichCoeff(iSpec,iChemDir))
        END IF
      END DO
    END DO
    IF((PartFuncProduct(1).NE.0.).AND.(PartFuncProduct(2).NE.0.)) THEN
      IF (ChemReac%QKProcedure(iReac)) THEN
        k_b_lower = QKBackWard(iReacTmp)%ForwardRate(LowerLevel)* (PartFuncProduct(1)/PartFuncProduct(2)) &
            * EXP(ActivationEnergy/(LowerLevel * DSMC%PartitionInterval))
      ELSE
        k_b_lower = ChemReac%Arrhenius_Prefactor(iReac)  &
                * (LowerLevel * DSMC%PartitionInterval)**ChemReac%Arrhenius_Powerfactor(iReac) &
                * (PartFuncProduct(1)/PartFuncProduct(2))
      END IF
    ELSE
      k_b_lower = 0.0
    END IF

    PartFuncProduct(1:2) = 1.
    DO iSpec = 1, nSpecies
      DO iChemDir = 1,2
        IF(ChemReac%ReactInfo(iReac)%StoichCoeff(iSpec,iChemDir).NE.0) THEN
          PartFuncProduct(iChemDir) = PartFuncProduct(iChemDir)   &
            * SpecDSMC(iSpec)%PartitionFunction(UpperLevel)**(ChemReac%ReactInfo(iReac)%StoichCoeff(iSpec,iChemDir))
        END IF
      END DO
    END DO
    IF((PartFuncProduct(1).NE.0.).AND.(PartFuncProduct(2).NE.0.)) THEN
      IF (ChemReac%QKProcedure(iReac)) THEN
        k_b_upper = QKBackWard(iReacTmp)%ForwardRate(UpperLevel)* (PartFuncProduct(1)/PartFuncProduct(2)) &
            * EXP(ActivationEnergy/(UpperLevel * DSMC%PartitionInterval))
      ELSE
        k_b_upper = ChemReac%Arrhenius_Prefactor(iReac) &
              * (UpperLevel * DSMC%PartitionInterval)**ChemReac%Arrhenius_Powerfactor(iReac) &
              * (PartFuncProduct(1)/PartFuncProduct(2))
      END IF
    ELSE
      k_b_upper = 0.0
    END IF
  ! Linear interpolation of the backward rate coefficient at the actual temperature
    BackwardRate = k_b_lower &
              + (k_b_upper - k_b_lower)  &
              / (DSMC%PartitionInterval) * (LocalTemp - LowerLevel * DSMC%PartitionInterval)
  END IF

END SUBROUTINE CalcBackwardRate


SUBROUTINE CalcPseudoScatterVars(PseuSpec1, PseuSpec2, ScatterSpec3, FracMassCent1, FracMassCent2, MassRed)
!===================================================================================================================================
! Routine determines the reduced mass and the mass fraction between a pseudo-molecule and third species
!===================================================================================================================================
! MODULES
  USE MOD_Globals
  USE MOD_Particle_Vars,         ONLY : Species
! IMPLICIT VARIABLE HANDLING
  IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
  INTEGER, INTENT(IN)           :: PseuSpec1, PseuSpec2, ScatterSpec3
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
  REAL, INTENT(OUT)             :: FracMassCent1, FracMassCent2, MassRed
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
  REAL                            :: Mass
!===================================================================================================================================
  Mass = Species(PseuSpec1)%MassIC + Species(PseuSpec2)%MassIC
  FracMassCent1 = Mass / (Mass + Species(ScatterSpec3)%MassIC)
  FracMassCent2 = Species(ScatterSpec3)%MassIC / (Mass + Species(ScatterSpec3)%MassIC)
  MassRed = (Mass*Species(ScatterSpec3)%MassIC) &
                         / (Mass+Species(ScatterSpec3)%MassIC)
END SUBROUTINE CalcPseudoScatterVars


SUBROUTINE CalcForwardRate(iReacTmp,LocalTemp,ForwardRate)
!===================================================================================================================================
! Calculation of the backward reaction rate with partition sums, interpolation within the given temperature interval
!===================================================================================================================================
! MODULES
  USE MOD_Globals
  USE MOD_DSMC_Vars,             ONLY : DSMC, ChemReac, QKBackWard
! IMPLICIT VARIABLE HANDLING
  IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
  INTEGER, INTENT(IN)           :: iReacTmp
  REAL, INTENT(IN)              :: LocalTemp
  REAL, INTENT(OUT)             :: ForwardRate
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
  INTEGER                        :: iReac, LowerLevel, UpperLevel
  REAL                            :: k_f_lower, k_f_upper
!===================================================================================================================================
  ! Determination of the lower and upper value of the temperature interval
  LowerLevel = INT(LocalTemp/DSMC%PartitionInterval)
  UpperLevel = LowerLevel + 1
  iReac = iReacTmp + ChemReac%NumOfReact/2
  IF(UpperLevel.GT.INT(DSMC%PartitionMaxTemp / DSMC%PartitionInterval)) THEN
    CALL abort(&
     __STAMP__&
      ,'Temperature limit for the forward reaction rate calculation exceeds the given value! Temp: ',RealInfoOpt=LocalTemp)
  END IF

  ! Calculation of the backward reaction rate at the lower temperature value (using the equilibrium constant)
  k_f_lower = QKBackWard(iReac)%ForwardRate(LowerLevel)

! Calculation of the backward reaction rate at the upper temperature value (using the equilibrium constant)
  k_f_upper = QKBackWard(iReac)%ForwardRate(UpperLevel)

! Linear interpolation of the backward rate coefficient at the actual temperature
  ForwardRate = k_f_lower &
            + (k_f_upper - k_f_lower)  &
            / (DSMC%PartitionInterval) * (LocalTemp - LowerLevel * DSMC%PartitionInterval)

END SUBROUTINE CalcForwardRate


FUNCTION gammainc( arg )
!===================================================================================================================================
! Program to test the incomplete gamma function
! the following gamma function is the one of Birds Q-K rate code
! ev. take another gamma function implementation
!===================================================================================================================================
! MODULES
! IMPLICIT VARIABLE HANDLING
  IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES                                                                                
  INTEGER,PARAMETER              :: real_kind=8
  REAL(KIND=real_kind),DIMENSION(1:2), INTENT(IN) :: arg
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
  INTEGER                        :: n
  REAL(KIND=real_kind)           :: gamser, gln, ap, del, summ, an, ser, tmp, x,y, b,c,d,h
  REAL(KIND=real_kind)           :: gammainc
  ! parameters
  REAL(KIND=real_kind),PARAMETER,DIMENSION(6) :: &
                                      cof= [ 76.18009172947146      , &
                                            -86.50532032941677     , &
                                             24.01409824083091      , &
                                             -1.231739572450155     , &
                                              0.1208650973866179e-2  , &
                                            -0.5395239384953e-5 ]
  REAL(KIND=real_kind),PARAMETER :: stp=2.5066282746310005        , &
                                    fpmin=1.e-30
!===================================================================================================================================

  x=arg(1)
  y=x
  tmp=x+5.5
  tmp=(x+0.5)*log(tmp)-tmp
  ser=1.000000000190015
  DO n = 1, 6
    y=y+1.
    ser=ser+cof(n)/y
  END DO
  gln=tmp+log(stp*ser/x)
  IF (arg(2) < arg(1)+1.) THEN
    IF (arg(2) <= 0.) THEN
      gamser=0.
    ELSE
      ap=arg(1)
      summ=1./arg(1)
      del=summ
      DO WHILE (abs(del) > abs(summ)*1.e-8 )
        ap=ap+1.
        del=del*arg(2)/ap
        summ=summ+del
      END DO
      gamser=summ*exp(-arg(2)+arg(1)*log(arg(2))-gln)
    END IF
    gammainc=1.-gamser
  ELSE
    b =arg(2)+1.-arg(1)
    c=1./fpmin
    d=1./b
    h=d
    del=d*c
    n=0
    DO WHILE ( abs(del-1.) >= 1.e-8 )
      n=n+1
      an=-n*(n-arg(1))
      b=b+2.
      d=an*d+b
      IF ( abs(d) < fpmin ) THEN
        d=fpmin
      END IF
      c=b+an/c
      IF ( abs(c) < fpmin ) THEN
        c=fpmin
      END IF
      d=1./d
      del=d*c
      h=h*del
    END DO
    gammainc=exp(-arg(2)+arg(1)*log(arg(2))-gln) * h
  END IF
END FUNCTION gammainc

END MODULE MOD_DSMC_ChemReact
