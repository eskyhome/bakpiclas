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

MODULE MOD_DSMC_CollisionProb
!===================================================================================================================================
! Module calculating the collision probability
!===================================================================================================================================
! MODULES
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
PRIVATE

INTERFACE DSMC_prob_calc
  MODULE PROCEDURE DSMC_prob_calc
END INTERFACE

!-----------------------------------------------------------------------------------------------------------------------------------
! GLOBAL VARIABLES 
!-----------------------------------------------------------------------------------------------------------------------------------
! Private Part ---------------------------------------------------------------------------------------------------------------------
! Public Part ----------------------------------------------------------------------------------------------------------------------
PUBLIC :: DSMC_prob_calc
!===================================================================================================================================

CONTAINS

SUBROUTINE DSMC_prob_calc(iElem, iPair, NodeVolume)
!===================================================================================================================================
! Routine calculating the collision probability
!===================================================================================================================================
! MODULES
  USE MOD_Globals
  USE MOD_DSMC_Vars,              ONLY : SpecDSMC, Coll_pData, CollInf, DSMC, BGGas, ChemReac
  USE MOD_Particle_Vars,          ONLY : PartSpecies, Species, usevMPF, PartState
  USE MOD_Particle_Mesh_Vars,     ONLY : Geo       ! da muss noch was getan werden (s.u.)
  USE MOD_TimeDisc_Vars,          ONLY : dt
!  USE MOD_Equation_Vars,          ONLY : c2              ! da muss noch was getan werden (s.u.)
  USE MOD_DSMC_SpecXSec
#if (PP_TimeDiscMethod==42)
  USE MOD_Particle_Vars,          ONLY : nSpecies
#endif
! IMPLICIT VARIABLE HANDLING
  IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
  INTEGER, INTENT(IN)                 :: iElem, iPair
  REAL(KIND=8), INTENT(IN), OPTIONAL  :: NodeVolume
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
  INTEGER                             :: iPType, SpecToExec, NbrOfReaction
  INTEGER(KIND=8)                     :: SpecNum1, SpecNum2
  REAL                                :: aCEX, bCEX, aMEX, bMEX, aEL, bEL, BGGasDensity_new, sigma_tot
  REAL(KIND=8)                        :: Volume
  LOGICAL                             :: DoSimpleElectronColl
#if (PP_TimeDiscMethod==42)
  INTEGER                             :: iReac, iSpec
#endif
!===================================================================================================================================
  
  iPType = SpecDSMC(PartSpecies(Coll_pData(iPair)%iPart_p1))%InterID &
         + SpecDSMC(PartSpecies(Coll_pData(iPair)%iPart_p2))%InterID !definition of collision case

  IF (PRESENT(NodeVolume)) THEN
    Volume = NodeVolume
  ELSE
    Volume = GEO%Volume(iElem)
  END IF
  SELECT CASE(iPType)

    CASE(2,3,4,11,12,21,22,20,30,40)
    ! Atom-Atom,  Atom-Mol, Mol-Mol, Atom-Atomic (non-CEX/MEX) Ion, Molecule-Atomic Ion, Atom-Molecular Ion, Molecule-Molecular Ion
      SpecNum1 = NINT(CollInf%Coll_SpecPartNum(PartSpecies(Coll_pData(iPair)%iPart_p1)),8) !number of particles of spec 1
      SpecNum2 = NINT(CollInf%Coll_SpecPartNum(PartSpecies(Coll_pData(iPair)%iPart_p2)),8) !number of particles of spec 2
      IF (BGGas%BGGasSpecies.NE.0) THEN       
        Coll_pData(iPair)%Prob = BGGas%BGColl_SpecPartNum/(1 + CollInf%KronDelta(Coll_pData(iPair)%PairType))  & 
                * CollInf%Cab(Coll_pData(iPair)%PairType)                                               & ! Cab species comb fac
                * Species(PartSpecies(Coll_pData(iPair)%iPart_p1))%MacroParticleFactor                  & 
                        ! weighting Fact, here only one MPF is used!!!
                * Coll_pData(iPair)%CRela2 ** (0.5-SpecDSMC(PartSpecies(Coll_pData(iPair)%iPart_p1))%omegaVHS) &
                        ! relative velo to the power of (1 -2omega) !! only one omega is used!!
                * dt / Volume                     ! timestep (should be sclaed in time disc)  divided by cell volume
      ELSE
        Coll_pData(iPair)%Prob = SpecNum1*SpecNum2/(1 + CollInf%KronDelta(Coll_pData(iPair)%PairType))  & 
                * CollInf%Cab(Coll_pData(iPair)%PairType)                                               & ! Cab species comb fac
                * Species(PartSpecies(Coll_pData(iPair)%iPart_p1))%MacroParticleFactor                  & 
                        ! weighting Fact, here only one MPF is used!!!
                / CollInf%Coll_CaseNum(Coll_pData(iPair)%PairType)                                      & ! sum of coll cases Sab
                * Coll_pData(iPair)%CRela2 ** (0.5-SpecDSMC(PartSpecies(Coll_pData(iPair)%iPart_p1))%omegaVHS) &
                        ! relative velo to the power of (1 -2omega) !! only one omega is used!!
                * dt / Volume                     ! timestep (should be sclaed in time disc)  divided by cell volume
      END IF

    CASE(5,6) !Atom - Electron ! Molecule - Electron
      ALLOCATE(Coll_pData(iPair)%Sigma(0:3))  ! Cross Section of Collision of this pair
      Coll_pData(iPair)%Sigma = 0
! ist/war gedacht als relativistische energie, da elektronen ja doch recht schnell werden ...
!prob ist, dass hier nicht die gesamte Ec sonder nur die SchwerpunktsEc gebracuht wird.
! hier muß also für relativistische Fälle noch etwas getan werden
!      Ec = 0 ! Energy of collision (in case of e + A = Ekin)
!      
!      !relativistic Ekin of particle 1
!      partV2 = PartState(Coll_pData(iPair)%iPart_p1,4) * PartState(Coll_pData(iPair)%iPart_p1,4) &
!               + PartState(Coll_pData(iPair)%iPart_p1,5) * PartState(Coll_pData(iPair)%iPart_p1,5) &
!               + PartState(Coll_pData(iPair)%iPart_p1,6) * PartState(Coll_pData(iPair)%iPart_p1,6)
!      GammaRel = partV2/c2
!      GammaRel = 1./SQRT(1.-GammaRel)  !Calculation of the Lorenzt Boost of the particle
!      Ec = Ec + (GammaRel-1.) &
!           * Species(PartSpecies(Coll_pData(iPair)%iPart_p1))%MassIC &
!           * Species(PartSpecies(Coll_pData(iPair)%iPart_p1))%MacroParticleFactor * c2 ! Only to use with one MPF!!
!      
!      !relativistic Ekin of particle 2
!      partV2 = PartState(Coll_pData(iPair)%iPart_p2,4) * PartState(Coll_pData(iPair)%iPart_p2,4) &
!               + PartState(Coll_pData(iPair)%iPart_p2,5) * PartState(Coll_pData(iPair)%iPart_p2,5) &
!               + PartState(Coll_pData(iPair)%iPart_p2,6) * PartState(Coll_pData(iPair)%iPart_p2,6)
!      GammaRel = partV2/c2
!      GammaRel = 1./SQRT(1.-GammaRel)  !Calculation of the Lorenzt Boost of the particle
!      Ec = Ec + (GammaRel-1.) &
!           * Species(PartSpecies(Coll_pData(iPair)%iPart_p2))%MassIC &
!           * Species(PartSpecies(Coll_pData(iPair)%iPart_p2))%MacroParticleFactor * c2 ! Only to use with one MPF!!
!      Coll_pData(iPair)%Ec = Ec
      Coll_pData(iPair)%Ec = 0.5 * CollInf%MassRed(Coll_pData(iPair)%PairType)*Coll_pData(iPair)%CRela2
  
      ! polarization method
      ! Define what species is the atom and is execuded
      IF (SpecDSMC(PartSpecies(Coll_pData(iPair)%iPart_p1))%InterID.eq.1) THEN
        SpecToExec = PartSpecies(Coll_pData(iPair)%iPart_p1) 
      ELSE
        SpecToExec = PartSpecies(Coll_pData(iPair)%iPart_p2)
      END IF
      SELECT CASE(SpecDSMC(SpecToExec)%NumOfPro)        ! Number of protons, which element
        ! if a proton number is given, than a model based on polarisation is used
        ! for further information, see Diss. Dejan Petkov
        CASE (18)                                      ! Argon
          CALL XSec_Argon_DravinLotz(SpecToExec, iPair)
          DoSimpleElectronColl=.FALSE.
        CASE DEFAULT
        ! default case, use same collision probability as for Atom-Atom,etc.
        ! Note, that the correct mechanism for vMPF is NOT implemented
          DoSimpleElectronColl=.TRUE.
      END SELECT

      SpecNum1 = NINT(CollInf%Coll_SpecPartNum(PartSpecies(Coll_pData(iPair)%iPart_p1)),8) !number of particles of spec 1
      SpecNum2 = NINT(CollInf%Coll_SpecPartNum(PartSpecies(Coll_pData(iPair)%iPart_p2)),8) !number of particles of spec 2
      ! generally this is only a HS calculation of the prob
      IF (DoSimpleElectronColl) THEN
        ! copy & past from above (atom, molecular,etc.)
        IF (BGGas%BGGasSpecies.NE.0) THEN
            Coll_pData(iPair)%Prob = BGGas%BGColl_SpecPartNum/(1 + CollInf%KronDelta(Coll_pData(iPair)%PairType))  & 
                    * CollInf%Cab(Coll_pData(iPair)%PairType)                                               &! Cab species comb fac
                    * Species(PartSpecies(Coll_pData(iPair)%iPart_p1))%MacroParticleFactor                  & 
                            ! weighting Fact, here only one MPF is used!!!
                    * Coll_pData(iPair)%CRela2 ** (0.5-SpecDSMC(PartSpecies(Coll_pData(iPair)%iPart_p1))%omegaVHS) &
                            ! relative velo to the power of (1 -2omega) !! only one omega is used!!
                    * dt / Volume                     ! timestep (should be sclaed in time disc)  divided by cell volume
        ELSE
          Coll_pData(iPair)%Prob = SpecNum1*SpecNum2/(1 + CollInf%KronDelta(Coll_pData(iPair)%PairType))                & 
                  * CollInf%Cab(Coll_pData(iPair)%PairType)           &    ! Cab species comb fac         
                  * Species(PartSpecies(Coll_pData(iPair)%iPart_p1))%MacroParticleFactor                                & 
                          ! weighting Fact, here only one MPF is used!!!      
                    / CollInf%Coll_CaseNum(Coll_pData(iPair)%PairType)                                                  & 
                  * Coll_pData(iPair)%CRela2 ** (0.5-SpecDSMC(PartSpecies(Coll_pData(iPair)%iPart_p1))%omegaVHS)        &
                          ! relative velo to the power of (1 -2omega) !! only one omega is used!!
                  * dt / Volume                     ! timestep (should be sclaed in time disc)  divided by cell volume
        END IF
      ELSE ! collision probability with polarization
        IF (BGGas%BGGasSpecies.NE.0) THEN
          IF (usevMPF) THEN
            IF (Species(BGGas%BGGasSpecies)%Init(0)%ElemPartDensityFileID.GT.0) THEN
              BGGasDensity_new=Species(BGGas%BGGasSpecies)%Init(0)%ElemPartDensity(iElem)
            ELSE
              BGGasDensity_new=BGGas%BGGasDensity
            END IF
            Coll_pData(iPair)%Prob = BGGasDensity_new * GEO%Volume(iElem)      &
                   /(1 + CollInf%KronDelta(Coll_pData(iPair)%PairType))  & 
                          ! weighting Fact, here only one MPF is used!!!      
                  * SQRT(Coll_pData(iPair)%CRela2)*Coll_pData(iPair)%Sigma(0) &
                          ! relative velo to the power of (1 -2omega) !! only one omega is used!!
                  * dt / Volume                     ! timestep (should be sclaed in time disc)  divided by cell volume
          ELSE
            Coll_pData(iPair)%Prob = BGGas%BGColl_SpecPartNum/(1 + CollInf%KronDelta(Coll_pData(iPair)%PairType))  & 
                  * Species(PartSpecies(Coll_pData(iPair)%iPart_p1))%MacroParticleFactor                  & 
                          ! weighting Fact, here only one MPF is used!!!      
                  * SQRT(Coll_pData(iPair)%CRela2)*Coll_pData(iPair)%Sigma(0) &
                          ! relative velo to the power of (1 -2omega) !! only one omega is used!!
                  * dt / Volume                     ! timestep (should be sclaed in time disc)  divided by cell vol
          END IF
        ELSE
          Coll_pData(iPair)%Prob = SpecNum1*SpecNum2/(1 + CollInf%KronDelta(Coll_pData(iPair)%PairType))  & 
                  * Species(PartSpecies(Coll_pData(iPair)%iPart_p1))%MacroParticleFactor                  & 
                          ! weighting Fact, here only one MPF is used!!!      
                  / CollInf%Coll_CaseNum(Coll_pData(iPair)%PairType)                                      & ! sum of coll cases Sab
                  * SQRT(Coll_pData(iPair)%CRela2)*Coll_pData(iPair)%Sigma(0) &
                          ! relative velo to the power of (1 -2omega) !! only one omega is used!!
                  * dt / Volume                     ! timestep (should be sclaed in time disc)  divided by cell volume
        END IF
      END IF
    CASE(8) !Electron - Electron
      Coll_pData(iPair)%Prob = 0
    CASE(14) !Electron - Atomic Ion
      ! again simple VHS idea as for molecules, etc. 
      DoSimpleElectronColl=.TRUE.
      Coll_pData(iPair)%Ec = 0.5 * CollInf%MassRed(Coll_pData(iPair)%PairType)*Coll_pData(iPair)%CRela2
      IF (SpecDSMC(PartSpecies(Coll_pData(iPair)%iPart_p1))%InterID.eq.1) THEN
        SpecToExec = PartSpecies(Coll_pData(iPair)%iPart_p1) 
      ELSE
        SpecToExec = PartSpecies(Coll_pData(iPair)%iPart_p2)
      END IF
      SpecNum1 = NINT(CollInf%Coll_SpecPartNum(PartSpecies(Coll_pData(iPair)%iPart_p1)),8) !number of particles of spec 1
      SpecNum2 = NINT(CollInf%Coll_SpecPartNum(PartSpecies(Coll_pData(iPair)%iPart_p2)),8) !number of particles of spec 2
      IF(DoSimpleElectronColl)THEN
        ! copy & past from above (atom, molecular,etc.)
        IF (BGGas%BGGasSpecies.NE.0) THEN
            Coll_pData(iPair)%Prob = BGGas%BGColl_SpecPartNum/(1 + CollInf%KronDelta(Coll_pData(iPair)%PairType))  & 
                    * CollInf%Cab(Coll_pData(iPair)%PairType)                                               & ! Cab species comb fac
                    * Species(PartSpecies(Coll_pData(iPair)%iPart_p1))%MacroParticleFactor                  & 
                            ! weighting Fact, here only one MPF is used!!!
                    * Coll_pData(iPair)%CRela2 ** (0.5-SpecDSMC(PartSpecies(Coll_pData(iPair)%iPart_p1))%omegaVHS) &
                            ! relative velo to the power of (1 -2omega) !! only one omega is used!!
                    * dt / Volume                     ! timestep (should be sclaed in time disc)  divided by cell volume
        ELSE
          Coll_pData(iPair)%Prob = SpecNum1*SpecNum2/(1 + CollInf%KronDelta(Coll_pData(iPair)%PairType))                & 
                  * CollInf%Cab(Coll_pData(iPair)%PairType)           &    ! Cab species comb fac
                  * Species(PartSpecies(Coll_pData(iPair)%iPart_p1))%MacroParticleFactor                                & 
                          ! weighting Fact, here only one MPF is used!!!      
                    / CollInf%Coll_CaseNum(Coll_pData(iPair)%PairType)                                                  & 
                  * Coll_pData(iPair)%CRela2 ** (0.5-SpecDSMC(PartSpecies(Coll_pData(iPair)%iPart_p1))%omegaVHS)        &
                          ! relative velo to the power of (1 -2omega) !! only one omega is used!!
                  * dt / Volume                     ! timestep (should be sclaed in time disc)  divided by cell volume
        END IF
      ELSE
       ! collision probability based on polarization
       Coll_pData(iPair)%Prob=0.
      END IF
    CASE(16) !Atom-Atomic CEX/MEX Ion
      NbrOfReaction = ChemReac%ReactNum(PartSpecies(Coll_pData(iPair)%iPart_p1),PartSpecies(Coll_pData(iPair)%iPart_p2),1)
      aCEX = ChemReac%CEXa(NbrOfReaction)
      bCEX = ChemReac%CEXb(NbrOfReaction)
      aMEX = ChemReac%MEXa(NbrOfReaction)
      bMEX = ChemReac%MEXb(NbrOfReaction)
      aEL = ChemReac%ELa(NbrOfReaction)
      bEL = ChemReac%ELb(NbrOfReaction)
      IF (ChemReac%DoScat(NbrOfReaction)) THEN
        IF (Coll_pData(iPair)%CRela2.EQ.0) THEN 
          sigma_tot = 0
        ELSE
          !Coll_pData(iPair)%Ec = 0.5 * CollInf%MassRed(Coll_pData(iPair)%PairType)*Coll_pData(iPair)%CRela2
          sigma_tot = ((aCEX+0.5*aEL)*0.5*LOG10(Coll_pData(iPair)%CRela2)+bCEX+0.5*bEL)
          !write (*,*) "CRela2=", Coll_pData(iPair)%CRela2
          !write (*,*) "CASE(16) !Atom-Atomic CEX/MEX Ion", sigma_tot , ((aCEX+aMEX)*0.5*LOG10(Coll_pData(iPair)%CRela2) + bCEX+bMEX)
        END IF
      ELSE
        IF (Coll_pData(iPair)%CRela2.EQ.0) THEN
          sigma_tot = 0
        ELSE
          ! equation based on empirical equation, probably by J.S. Miller et al (J.Appl.Phys.91,984-991 (2002))
          ! probably: sigma_tot = sigma_CEX+sigma_MEX
          ! originally: sigma_CEX = 87.3 - 13.6*LOG10(E(in eV) with LAB energy E in electronvolt.
          ! here: equation is modified in order to use only CRela2 --> has influence on the input values
          ! --> E/1.6021766208E-19 --> sigma_CEX = -168.316 - 13.6*LOG10(E(in Joule))
          ! --> E=0.5*m_Xe_ion*CRela2 --> sigma_CEX = 171.2 - 13.6*LOG10(CRela2)
          ! --> due to the formulation of the euation in the next line, the value of aCEX, 13.6, has to be doubled in the input file
          sigma_tot = ((aCEX+aMEX)*0.5*LOG10(Coll_pData(iPair)%CRela2) + bCEX+bMEX)
        END IF
      END IF
      SpecNum1 = NINT(CollInf%Coll_SpecPartNum(PartSpecies(Coll_pData(iPair)%iPart_p1)),8) !number of particles of spec 1
      SpecNum2 = NINT(CollInf%Coll_SpecPartNum(PartSpecies(Coll_pData(iPair)%iPart_p2)),8) !number of particles of spec 2
      IF (Coll_pData(iPair)%CRela2.eq.0.) THEN !avoid log(0)
        Coll_pData(iPair)%Prob=0.
      ELSE
        IF (BGGas%BGGasSpecies.NE.0) THEN
          Coll_pData(iPair)%Prob = BGGas%BGColl_SpecPartNum/(1 + CollInf%KronDelta(Coll_pData(iPair)%PairType))  &
            !* CollInf%Cab(Coll_pData(iPair)%PairType)                                               & ! Cab species comb fac
            * Species(PartSpecies(Coll_pData(iPair)%iPart_p1))%MacroParticleFactor                  &
              ! weighting Fact, here only one MPF is used!!!
            * 1.0E-20 * SQRT(Coll_pData(iPair)%CRela2) * sigma_tot &
              ! CEX/MEX-relation to relative velo
            * dt / Volume                   ! timestep (should be sclaed in time disc)  divided by cell volume
        ELSE
          Coll_pData(iPair)%Prob = SpecNum1*SpecNum2/(1 + CollInf%KronDelta(Coll_pData(iPair)%PairType))  &
            !* CollInf%Cab(Coll_pData(iPair)%PairType)                                               & ! Cab species comb fac
            * Species(PartSpecies(Coll_pData(iPair)%iPart_p1))%MacroParticleFactor                  &
              ! weighting Fact, here only one MPF is used!!!
            / CollInf%Coll_CaseNum(Coll_pData(iPair)%PairType)                                      & ! sum of coll cases Sab
            * 1.0E-20 * SQRT(Coll_pData(iPair)%CRela2) * sigma_tot  &
              ! CEX/MEX-relation to relative velo
            * dt / Volume                   ! timestep (should be sclaed in time disc)  divided by cell volume
        END IF
      END IF !avoid log(0)
    CASE(19) !Electron - Atomic CEX/MEX Ion
      Coll_pData(iPair)%Prob = 0
!    CASE(20) !Atomic Ion - Atomic Ion
!      Coll_pData(iPair)%Prob = 0
    CASE(24) !Molecular Ion - Electron
      ! again simple VHS idea as for molecules, etc. 
      DoSimpleElectronColl=.TRUE.
      Coll_pData(iPair)%Ec = 0.5 * CollInf%MassRed(Coll_pData(iPair)%PairType)*Coll_pData(iPair)%CRela2
      SpecNum1 = NINT(CollInf%Coll_SpecPartNum(PartSpecies(Coll_pData(iPair)%iPart_p1)),8) !number of particles of spec 1
      SpecNum2 = NINT(CollInf%Coll_SpecPartNum(PartSpecies(Coll_pData(iPair)%iPart_p2)),8) !number of particles of spec 2
      IF(DoSimpleElectronColl)THEN
        ! copy & past from above (atom, molecular,etc.)
        IF (BGGas%BGGasSpecies.NE.0) THEN
            Coll_pData(iPair)%Prob = BGGas%BGColl_SpecPartNum/(1 + CollInf%KronDelta(Coll_pData(iPair)%PairType))  & 
                    * CollInf%Cab(Coll_pData(iPair)%PairType)                                               & ! Cab species comb fac
                    * Species(PartSpecies(Coll_pData(iPair)%iPart_p1))%MacroParticleFactor                  & 
                            ! weighting Fact, here only one MPF is used!!!
                    * Coll_pData(iPair)%CRela2 ** (0.5-SpecDSMC(PartSpecies(Coll_pData(iPair)%iPart_p1))%omegaVHS) &
                            ! relative velo to the power of (1 -2omega) !! only one omega is used!!
                    * dt / Volume                     ! timestep (should be sclaed in time disc)  divided by cell volume
        ELSE
          Coll_pData(iPair)%Prob = SpecNum1*SpecNum2/(1 + CollInf%KronDelta(Coll_pData(iPair)%PairType))                & 
                  * CollInf%Cab(Coll_pData(iPair)%PairType)           &    ! Cab species comb fac
                  * Species(PartSpecies(Coll_pData(iPair)%iPart_p1))%MacroParticleFactor                                & 
                          ! weighting Fact, here only one MPF is used!!!      
                    / CollInf%Coll_CaseNum(Coll_pData(iPair)%PairType)                                                  & 
                  * Coll_pData(iPair)%CRela2 ** (0.5-SpecDSMC(PartSpecies(Coll_pData(iPair)%iPart_p1))%omegaVHS)        &
                          ! relative velo to the power of (1 -2omega) !! only one omega is used!!
                  * dt / Volume                     ! timestep (should be sclaed in time disc)  divided by cell volume
        END IF
      ELSE
       ! collision probability based on polarization
       Coll_pData(iPair)%Prob=0.
      END IF
!    CASE(30) !Atomic Ion - Molecular Ion
!      Coll_pData(iPair)%Prob = 0
!    CASE(40) !Molecular Ion - Molecular Ion
!      Coll_pData(iPair)%Prob = 0    
    CASE DEFAULT
      CALL Abort(&
__STAMP__&
,'ERROR in DSMC_collis: Wrong iPType case! = ',iPType)
  END SELECT
  IF ( SQRT(DOT_PRODUCT(PartState(Coll_pData(iPair)%iPart_p1,4:6),PartState(Coll_pData(iPair)%iPart_p1,4:6)))&
    .LT.DSMC%veloMinColl(PartSpecies(Coll_pData(iPair)%iPart_p1)) .OR. &
       SQRT(DOT_PRODUCT(PartState(Coll_pData(iPair)%iPart_p2,4:6),PartState(Coll_pData(iPair)%iPart_p2,4:6)))&
    .LT.DSMC%veloMinColl(PartSpecies(Coll_pData(iPair)%iPart_p2))) Coll_pData(iPair)%Prob = 0.
  IF (ISNAN(Coll_pData(iPair)%Prob)) THEN
    IPWRITE(UNIT_errOut,*)iPair,'in',iElem,'is NaN!'
    CALL Abort(&
__STAMP__&
,'Collision probability is NaN! CRela:',RealInfoOpt=SQRT(Coll_pData(iPair)%CRela2))
  END IF
  IF(DSMC%CalcQualityFactors) THEN
    DSMC%CollProbMax = MAX(Coll_pData(iPair)%Prob, DSMC%CollProbMax)
    DSMC%CollProbMean = DSMC%CollProbMean + Coll_pData(iPair)%Prob
    DSMC%CollProbMeanCount = DSMC%CollProbMeanCount + 1
  END IF
#if (PP_TimeDiscMethod==42)
  ! Sum of collision probabilities for the collision pair and the corresponding reaction, required for the correct reaction rate
  IF(ChemReac%NumOfReact.GT.0) THEN
    DO iSpec=1, nSpecies
      iReac=ChemReac%ReactNum(PartSpecies(Coll_pData(iPair)%iPart_p1),PartSpecies(Coll_pData(iPair)%iPart_p2),iSpec)
      IF (iReac.NE.0) THEN
        ChemReac%ReacCollMean(iReac) = ChemReac%ReacCollMean(iReac) + Coll_pData(iPair)%Prob
        ChemReac%ReacCollMeanCount(iReac) = ChemReac%ReacCollMeanCount(iReac) + 1
      END IF
    END DO
  END IF
#endif
END SUBROUTINE DSMC_prob_calc

END MODULE MOD_DSMC_CollisionProb
