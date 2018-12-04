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

MODULE MOD_AnalyzeField
!===================================================================================================================================
! Contains the Poynting Vector Integral part for the power analysis of the field vector
!===================================================================================================================================
USE MOD_Globals, ONLY:UNIT_stdout
USE MOD_PreProc
!===================================================================================================================================
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
PRIVATE
!----------------------------------------------------------------------------------------------------------------------------------
! GLOBAL VARIABLES 
!----------------------------------------------------------------------------------------------------------------------------------
! Private Part ---------------------------------------------------------------------------------------------------------------------
! Public Part ----------------------------------------------------------------------------------------------------------------------
!----------------------------------------------------------------------------------------------------------------------------------

INTERFACE GetPoyntingIntPlane
  MODULE PROCEDURE GetPoyntingIntPlane
END INTERFACE

INTERFACE FinalizePoyntingInt
  MODULE PROCEDURE FinalizePoyntingInt
END INTERFACE

#if (PP_nVar>=6)
INTERFACE CalcPoyntingIntegral
  MODULE PROCEDURE CalcPoyntingIntegral
END INTERFACE
#endif

INTERFACE CalcPotentialEnergy
  MODULE PROCEDURE CalcPotentialEnergy
END INTERFACE
INTERFACE CalcPotentialEnergy_Dielectric
  MODULE PROCEDURE CalcPotentialEnergy_Dielectric
END INTERFACE

PUBLIC:: GetPoyntingIntPlane,FinalizePoyntingInt,CalcPotentialEnergy,CalcPotentialEnergy_Dielectric
#if (PP_nVar>=6)
PUBLIC:: CalcPoyntingIntegral
#endif
PUBLIC:: AnalyzeField
!===================================================================================================================================

CONTAINS

SUBROUTINE AnalyzeField(Time)
!===================================================================================================================================
! Initializes variables necessary for analyse subroutines
!===================================================================================================================================
! MODULES
USE MOD_Globals
USE MOD_Preproc
USE MOD_Analyze_Vars         ,ONLY: DoFieldAnalyze,CalcEpot,CalcPoyntingInt,nPoyntingIntPlanes,PosPoyntingInt, &
                                    Wel,Wmag
USE MOD_Particle_Analyze_Vars,ONLY: IsRestart
USE MOD_Restart_Vars         ,ONLY: DoRestart
USE MOD_Dielectric_Vars      ,ONLY: DoDielectric
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
REAL,INTENT(IN)     :: Time
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
LOGICAL             :: isOpen
CHARACTER(LEN=350)  :: outfile
INTEGER             :: unit_index, OutputCounter,iPlane
REAL                :: PoyntingIntegral(1:nPoyntingIntPlanes)
!===================================================================================================================================
IF ( DoRestart ) THEN
  isRestart = .true.
END IF
IF (.NOT.DoFieldAnalyze) RETURN
OutputCounter = 2
unit_index = 537
#ifdef MPI
IF(MPIROOT)THEN
#endif    /* MPI */
  INQUIRE(UNIT   = unit_index , OPENED = isOpen)
  IF (.NOT.isOpen) THEN
    outfile = 'FieldAnalyze.csv'
    IF (isRestart .and. FILEEXISTS(outfile)) THEN
       OPEN(unit_index,file=TRIM(outfile),position="APPEND",status="OLD")
       !CALL FLUSH (unit_index)
    ELSE
       OPEN(unit_index,file=TRIM(outfile))
       !CALL FLUSH (unit_index)
       !--- insert header
     
       WRITE(unit_index,'(A6,A5)',ADVANCE='NO') 'TIME', ' '
       IF (CalcEpot) THEN 
         WRITE(unit_index,'(A1)',ADVANCE='NO') ','
         WRITE(unit_index,'(I3.3,A11)',ADVANCE='NO') OutputCounter,'-E-El      '
           OutputCounter = OutputCounter + 1
         WRITE(unit_index,'(A1)',ADVANCE='NO') ','
         WRITE(unit_index,'(I3.3,A11)',ADVANCE='NO') OutputCounter,'-E-Mag    '
           OutputCounter = OutputCounter + 1
         WRITE(unit_index,'(A1)',ADVANCE='NO') ','
         WRITE(unit_index,'(I3.3,A11)',ADVANCE='NO') OutputCounter,'-E-pot    '
           OutputCounter = OutputCounter + 1
       END IF
       IF(CalcPoyntingInt)THEN
         DO iPlane=1,nPoyntingIntPlanes
           WRITE(unit_index,'(A1)',ADVANCE='NO') ','
           WRITE(unit_index,'(I3.3,A11,I0.3,A1,E14.7,A1)',ADVANCE='NO') &
                                          OutputCounter,'-Plane-Pos-',iPlane,'(', PosPoyntingInt(iPlane),')'
           OutputCounter = OutputCounter + 1
         END DO              
       END IF
       WRITE(unit_index,'(A14)') ' ' 
    END IF
  END IF
#ifdef MPI
END IF
#endif    /* MPI */

IF(CalcEpot)THEN
  IF(DoDielectric)THEN
    CALL CalcPotentialEnergy_Dielectric(WEl,WMag)
  ELSE
    CALL CalcPotentialEnergy(WEl,WMag)
  END IF
END IF
#if (PP_nVar>=6)
IF(CalcPoyntingInt) CALL CalcPoyntingIntegral(PoyntingIntegral,doProlong=.TRUE.)
#endif

#ifdef MPI
 IF(MPIROOT)THEN
#endif    /* MPI */
   WRITE(unit_index,WRITEFORMAT,ADVANCE='NO') Time
   IF (CalcEpot) THEN 
     WRITE(unit_index,'(A1)',ADVANCE='NO') ','
     WRITE(unit_index,WRITEFORMAT,ADVANCE='NO') WEl
     WRITE(unit_index,'(A1)',ADVANCE='NO') ','
     WRITE(unit_index,WRITEFORMAT,ADVANCE='NO') WMag
     WRITE(unit_index,'(A1)',ADVANCE='NO') ','
     WRITE(unit_index,WRITEFORMAT,ADVANCE='NO') WEl + WMag
   END IF
   IF(CalcPoyntingInt)THEN
     DO iPlane=1,nPoyntingIntPlanes
       WRITE(unit_index,'(A1)',ADVANCE='NO') ','
       WRITE(unit_index,WRITEFORMAT,ADVANCE='NO') PoyntingIntegral(iPlane)
     END DO
   END IF
   WRITE(unit_index,'(A1)') ' ' 
#ifdef MPI
 END IF
#endif    /* MPI */


END SUBROUTINE AnalyzeField

#if (PP_nVar>=6)
SUBROUTINE CalcPoyntingIntegral(PoyntingIntegral,doProlong)
!===================================================================================================================================
! Calculation of Poynting Integral with its own Prolong to face // check if Gauss-Labatto or Gaus Points is used is missing ... ups
!===================================================================================================================================
! MODULES
USE MOD_Mesh_Vars          ,ONLY: isPoyntingIntSide,nElems, SurfElem, NormVec,whichPoyntingPlane
USE MOD_Mesh_Vars          ,ONLY: ElemToSide,PoyntingMainDir
USE MOD_Analyze_Vars       ,ONLY: nPoyntingIntPlanes,S
USE MOD_Interpolation_Vars ,ONLY: L_Minus,L_Plus,wGPSurf
USE MOD_DG_Vars            ,ONLY: U,U_master
USE MOD_Equation_Vars      ,ONLY: smu0
USE MOD_Dielectric_Vars    ,ONLY: isDielectricFace,PoyntingUseMuR_Inv,Dielectric_MuR_Master_inv,DoDielectric
#ifdef MPI
  USE MOD_Globals
#endif
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
LOGICAL,INTENT(IN),OPTIONAL :: doProlong
!----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
REAL,INTENT(INOUT)          :: PoyntingIntegral(1:nPoyntingIntPlanes)
!----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
INTEGER          :: iElem, SideID,ilocSide,iPoyntingSide
INTEGER          :: p,q,l
REAL             :: Uface(PP_nVar,0:PP_N,0:PP_N)
REAL             :: SIP(0:PP_N,0:PP_N)
#ifdef MPI
REAL             :: SumSabs(nPoyntingIntPlanes)
#endif
LOGICAL          :: Prolong=.TRUE.
!REAL             :: sresvac
!===================================================================================================================================

IF(PRESENT(doProlong))THEN
  Prolong=doProlong
ELSE
  Prolong=.TRUE.
ENDIF  

S    = 0.
PoyntingIntegral = 0.

iPoyntingSide = 0 ! only if all Poynting vectors are desired
DO iELEM = 1, nElems
  Do ilocSide = 1, 6
    IF(ElemToSide(E2S_FLIP,ilocSide,iElem)==0)THEN ! only master sides
      SideID=ElemToSide(E2S_SIDE_ID,ilocSide,iElem)
      IF(.NOT.isPoyntingIntSide(SideID)) CYCLE
      IF(Prolong)THEN
#if (PP_NodeType==1) /* for Gauss-points*/
        SELECT CASE(ilocSide)
        CASE(XI_MINUS)
          DO q=0,PP_N
            DO p=0,PP_N
              Uface(:,q,p)=U(:,0,p,q,iElem)*L_Minus(0)
              DO l=1,PP_N
                ! switch to right hand system
                Uface(:,q,p)=Uface(:,q,p)+U(:,l,p,q,iElem)*L_Minus(l)
              END DO ! l
            END DO ! p
          END DO ! q
        CASE(ETA_MINUS)
          DO q=0,PP_N
            DO p=0,PP_N
              Uface(:,p,q)=U(:,p,0,q,iElem)*L_Minus(0)
              DO l=1,PP_N
                Uface(:,p,q)=Uface(:,p,q)+U(:,p,l,q,iElem)*L_Minus(l)
              END DO ! l
            END DO ! p
          END DO ! q
        CASE(ZETA_MINUS)
          DO q=0,PP_N
            DO p=0,PP_N
              Uface(:,q,p)=U(:,p,q,0,iElem)*L_Minus(0)
              DO l=1,PP_N
                ! switch to right hand system
                Uface(:,q,p)=Uface(:,q,p)+U(:,p,q,l,iElem)*L_Minus(l)
              END DO ! l
            END DO ! p
          END DO ! qfirst stuff
        CASE(XI_PLUS)
          DO q=0,PP_N
            DO p=0,PP_N
              Uface(:,p,q)=U(:,0,p,q,iElem)*L_Plus(0)
              DO l=1,PP_N
                Uface(:,p,q)=Uface(:,p,q)+U(:,l,p,q,iElem)*L_Plus(l)
              END DO ! l
            END DO ! p
          END DO ! q
        CASE(ETA_PLUS)
          DO q=0,PP_N
            DO p=0,PP_N
              Uface(:,PP_N-p,q)=U(:,p,0,q,iElem)*L_Plus(0)
              DO l=1,PP_N
                ! switch to right hand system
                Uface(:,PP_N-p,q)=Uface(:,PP_N-p,q)+U(:,p,l,q,iElem)*L_Plus(l)
              END DO ! l
            END DO ! p
          END DO ! q
        CASE(ZETA_PLUS)
          DO q=0,PP_N
            DO p=0,PP_N
              Uface(:,p,q)=U(:,p,q,0,iElem)*L_Plus(0)
              DO l=1,PP_N
                Uface(:,p,q)=Uface(:,p,q)+U(:,p,q,l,iElem)*L_Plus(l)
              END DO ! l
            END DO ! p
          END DO ! q
        END SELECT
#else /* for Gauss-Lobatto-points*/
        SELECT CASE(ilocSide)
        CASE(XI_MINUS)
          DO q=0,PP_N
            DO p=0,PP_N
              Uface(:,q,p)=U(:,0,p,q,iElem)
            END DO ! p
          END DO ! q
        CASE(ETA_MINUS)
          Uface(:,:,:)=U(:,:,0,:,iElem)
        CASE(ZETA_MINUS)
          DO q=0,PP_N
            DO p=0,PP_N
              Uface(:,q,p)=U(:,p,q,0,iElem)
            END DO ! p
          END DO ! q
        CASE(XI_PLUS)
          Uface(:,:,:)=U(:,PP_N,:,:,iElem)
        CASE(ETA_PLUS)
          DO q=0,PP_N
            DO p=0,PP_N
              Uface(:,PP_N-p,q)=U(:,p,PP_N,q,iElem)
            END DO ! p
          END DO ! q
        CASE(ZETA_PLUS)
          DO q=0,PP_N
            DO p=0,PP_N
              Uface(:,p,q)=U(:,p,q,PP_N,iElem)
            END DO ! p
          END DO ! q
        END SELECT
#endif
        ELSE ! no prolonge to face
          Uface=U_master(:,:,:,SideID)
        END IF ! Prolong
        ! calculate Poynting vector
        iPoyntingSide = iPoyntingSide + 1

        ! check if dielectric regions are involved
        IF(DoDielectric)THEN
          IF(PoyntingUseMuR_Inv.AND.isDielectricFace(SideID))THEN
            CALL PoyntingVectorDielectric(Uface(:,:,:),S(:,:,:,iPoyntingSide),Dielectric_MuR_Master_inv(0:PP_N,0:PP_N,SideID))
          ELSE
            CALL PoyntingVector(Uface(:,:,:),S(:,:,:,iPoyntingSide))
          END IF
        ELSE
          CALL PoyntingVector(Uface(:,:,:),S(:,:,:,iPoyntingSide))
        END IF
        
        IF ( NormVec(PoyntingMainDir,0,0,SideID) .GT. 0 ) THEN
          SIP(:,:) = S(1,:,:,iPoyntingSide) * NormVec(1,:,:,SideID) &
                   + S(2,:,:,iPoyntingSide) * NormVec(2,:,:,SideID) &
                   + S(3,:,:,iPoyntingSide) * NormVec(3,:,:,SideID)
        ELSE ! NormVec(PoyntingMainDir,:,:,iPoyningSide) < 0
          SIP(:,:) =-S(1,:,:,iPoyntingSide) * NormVec(1,:,:,SideID) &
                   - S(2,:,:,iPoyntingSide) * NormVec(2,:,:,SideID) &
                   - S(3,:,:,iPoyntingSide) * NormVec(3,:,:,SideID)
        END IF ! NormVec(PoyntingMainDir,:,:,iPoyntingSide)
        ! multiplied by surface element and  Gaus Points
        SIP(:,:) = SIP(:,:) * SurfElem(:,:,SideID) * wGPSurf(:,:)

        ! total flux through each plane
        PoyntingIntegral(whichPoyntingPlane(SideID)) = PoyntingIntegral(whichPoyntingPlane(SideID)) + smu0* SUM(SIP(:,:))
    END IF ! flip =0
  END DO ! iSides
END DO ! iElems

#ifdef MPI
  CALL MPI_REDUCE   (PoyntingIntegral(:) , sumSabs(:) , nPoyntingIntPlanes , MPI_DOUBLE_PRECISION ,MPI_SUM, 0, MPI_COMM_WORLD,IERROR)
  PoyntingIntegral(:) = sumSabs(:)
#endif /* MPI */

END SUBROUTINE CalcPoyntingIntegral
#endif


#if (PP_nVar>=6)
PURE SUBROUTINE PoyntingVector(Uface_in,Sloc)
!===================================================================================================================================
!> Calculate the Poynting Vector on a certain face for vacuum properties
!> 
!> ATTENTION: permeability is not applied here due to performance gain
!> Definition: S = E x H = 1/mu0 * ( E x H )
!> Here      : S = E x B (i.e. mu0 is applied later)
!===================================================================================================================================
! MODULES
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
REAL,INTENT(IN)       :: Uface_in(PP_nVar,0:PP_N,0:PP_N)
!----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
REAL,INTENT(OUT)      :: Sloc(1:3,0:PP_N,0:PP_N)
!----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
INTEGER               :: p,q
!===================================================================================================================================

! calculate the Poynting vector at each node, additionally the abs of the Poynting vector only based on E
DO p = 0,PP_N
  DO q = 0,PP_N
    Sloc(1,p,q)  =  Uface_in(2,p,q)*Uface_in(6,p,q) - Uface_in(3,p,q)*Uface_in(5,p,q) 
    Sloc(2,p,q)  = -Uface_in(1,p,q)*Uface_in(6,p,q) + Uface_in(3,p,q)*Uface_in(4,p,q) 
    Sloc(3,p,q)  =  Uface_in(1,p,q)*Uface_in(5,p,q) - Uface_in(2,p,q)*Uface_in(4,p,q) 
  END DO ! q - PP_N
END DO  ! p - PP_N

END SUBROUTINE PoyntingVector


PURE SUBROUTINE PoyntingVectorDielectric(Uface_in,Sloc,mu_r_inv)
!===================================================================================================================================
!> Calculate the Poynting Vector on a certain face for dielectric properties (consider mu_r here, but not mu0)
!> 
!> ATTENTION: permeability is not applied here due to performance gain
!> Definition: S = E x H = 1/(mu_r*mu_0) * ( E x H )
!> Here      : S = 1/mu_r * E x B (i.e. mu0 is applied later)
!===================================================================================================================================
! MODULES
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
REAL,INTENT(IN)       :: Uface_in(PP_nVar,0:PP_N,0:PP_N)
REAL,INTENT(IN)       :: mu_r_inv(0:PP_N,0:PP_N)         ! 1/mu_r for every face DOF (may vary on face depending on position)
!                                                        ! (isotropic property for permittivity)
!----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
REAL,INTENT(OUT)      :: Sloc(1:3,0:PP_N,0:PP_N)
!----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
INTEGER               :: p,q
!===================================================================================================================================

! calculate the Poynting vector at each node, additionally the abs of the Poynting vector only based on E
DO p = 0,PP_N
  DO q = 0,PP_N
    Sloc(1,p,q)  = (  Uface_in(2,p,q)*Uface_in(6,p,q) - Uface_in(3,p,q)*Uface_in(5,p,q) ) * mu_r_inv(p,q)
    Sloc(2,p,q)  = ( -Uface_in(1,p,q)*Uface_in(6,p,q) + Uface_in(3,p,q)*Uface_in(4,p,q) ) * mu_r_inv(p,q) 
    Sloc(3,p,q)  = (  Uface_in(1,p,q)*Uface_in(5,p,q) - Uface_in(2,p,q)*Uface_in(4,p,q) ) * mu_r_inv(p,q) 
  END DO ! q - PP_N
END DO  ! p - PP_N

END SUBROUTINE PoyntingVectorDielectric
#endif

SUBROUTINE GetPoyntingIntPlane()
!===================================================================================================================================
!> Initializes Poynting vector integral variables and check every side: set "isPoyntingIntSide(SideID) = .TRUE." if a side coincides
!> with a defined Poynting vector integral plane. 
!===================================================================================================================================
! MODULES
USE MOD_Mesh_Vars       ,ONLY: nPoyntingIntSides,isPoyntingIntSide,nSides,nElems,Face_xGP,whichPoyntingPlane
USE MOD_Mesh_Vars       ,ONLY: ElemToSide,normvec,PoyntingMainDir
USE MOD_Analyze_Vars    ,ONLY: PoyntingIntCoordErr,nPoyntingIntPlanes,PosPoyntingInt,S,STEM,PoyntingIntPlaneFactor
USE MOD_ReadInTools     ,ONLY: GETINT,GETREAL
USE MOD_Dielectric_Vars ,ONLY: DoDielectric,nDielectricElems,DielectricMu,ElemToDielectric,isDielectricInterFace
USE MOD_Dielectric_Vars ,ONLY: isDielectricFace,PoyntingUseMuR_Inv
USE MOD_Globals         ,ONLY: abort
#ifdef MPI
USE MOD_Globals
#endif
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
!----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
INTEGER             :: iElem, iSide, iPlane, SideID
INTEGER,ALLOCATABLE :: nFaces(:)
REAL                :: diff
INTEGER             :: p,q
CHARACTER(LEN=32)   :: index_plane
INTEGER,ALLOCATABLE :: sumFaces(:)
INTEGER             :: sumAllfaces
LOGICAL             :: CheckDielectricSides
INTEGER             :: PoyntingNormalDir1,PoyntingNormalDir2
!===================================================================================================================================

SWRITE(UNIT_stdOut,'(A)') ' GET PLANES TO CALCULATE POYNTING VECTOR INTEGRAL ...'

! Initialize number of Poynting plane sides zero and set all sides to false
nPoyntingIntSides=0 
ALLOCATE(isPoyntingIntSide(1:nSides))
isPoyntingIntSide = .FALSE.

! Get the number of Poynting planes and coordinates
nPoyntingIntPlanes = GETINT('PoyntingVecInt-Planes','0')
PoyntingMainDir = GETINT('PoyntingMainDir','3') ! default "3" is z-direction 
SELECT CASE (PoyntingMainDir)
  CASE (1) ! poynting vector integral in x-direction
    PoyntingNormalDir1=2
    PoyntingNormalDir2=3
  CASE (2) ! poynting vector integral in y-direction
    PoyntingNormalDir1=1
    PoyntingNormalDir2=3
  CASE (3) ! poynting vector integral in z-direction
    PoyntingNormalDir1=1
    PoyntingNormalDir2=2
  CASE DEFAULT
    CALL abort(&
    __STAMP__&
    ,'Poynting vector itnegral currently only in x,y,z!')
END SELECT
ALLOCATE(PosPoyntingInt(nPoyntingIntPlanes))
ALLOCATE(whichPoyntingPlane(nSides))
ALLOCATE(nFaces(nPoyntingIntPlanes))
whichPoyntingPlane = -1
nFaces(:) = 0

! Get z-coordinates and factors for every Poynting plane
DO iPlane=1,nPoyntingIntPlanes
 WRITE(UNIT=index_plane,FMT='(I2.2)') iPlane 
 SELECT CASE (PoyntingMainDir)
    CASE (1)
      PosPoyntingInt(iPlane)= GETREAL('Plane-'//TRIM(index_plane)//'-x-coord','0.')
    CASE (2)
      PosPoyntingInt(iPlane)= GETREAL('Plane-'//TRIM(index_plane)//'-y-coord','0.')
    CASE (3)
      PosPoyntingInt(iPlane)= GETREAL('Plane-'//TRIM(index_plane)//'-z-coord','0.')
  END SELECT
  PoyntingIntPlaneFactor= GETREAL('Plane-'//TRIM(index_plane)//'-factor','1.')
END DO
PoyntingIntCoordErr=GETREAL('Plane-Tolerance','1E-5')

! Dielectric Sides: 
! 1.) check if a dielectric region (only permeability, NOT permittivity is important) coincides with a Poynting vector 
!     integral plane. Dielectric interfaces with mu_r .NE. 1.0 cannot compute a Poynting vector because of the jump in material
!     parameter of mu_r
CheckDielectricSides=.FALSE.
IF(DoDielectric)THEN
  IF(ANY(ABS(DielectricMu(:,:,:,1:nDielectricElems)-1.0).GT.0.0))THEN
    CheckDielectricSides=.TRUE.
  END IF
END IF

! 2.) for dielectric sides (NOT interface sides between dielectric and some other region), determine mu_r on face for Poynting vector
PoyntingUseMuR_Inv=.FALSE.

! Loop over all planes
DO iPlane = 1, nPoyntingIntPlanes
  ! Loop over all elements
  DO iElem=1,nElems
    ! Loop over all local sides
    DO iSide=1,6
      IF(ElemToSide(E2S_FLIP,iSide,iElem)==0)THEN ! only master sides
        SideID=ElemToSide(E2S_SIDE_ID,iSide,iElem)
        ! First search only planes with normal vector parallel to direction of "MainDir"
        IF((     NormVec(PoyntingNormalDir1,0,0,SideID)  < PoyntingIntCoordErr) .AND. &
           (     NormVec(PoyntingNormalDir2,0,0,SideID)  < PoyntingIntCoordErr) .AND. &
           ( ABS(NormVec(PoyntingMainDir   ,0,0,SideID)) > PoyntingIntCoordErr))THEN
        ! Loop over all Points on Face
          DO q=0,PP_N
            DO p=0,PP_N
              diff = ABS(Face_xGP(PoyntingMainDir,p,q,SideID) - PosPoyntingInt(iPlane))
              IF (diff < PoyntingIntCoordErr) THEN
                IF (.NOT.isPoyntingIntSide(SideID)) THEN
                  nPoyntingIntSides = nPoyntingIntSides +1
                  whichPoyntingPlane(SideID) = iPlane
                  isPoyntingIntSide(SideID) = .TRUE.
                  nFaces(iPlane) = nFaces(iPlane) + 1

                  ! Dielectric sides
                  IF(CheckDielectricSides)THEN
                    ! 1.) Check for illegal sides in dielectrics: mu_r != 1.0 on dielectric interface
                    IF(isDielectricInterFace(SideID))THEN
                      IF(ANY(ABS(DielectricMu(:,:,:,ElemToDielectric(iElem))-1.0).GT.0.0))THEN
                        ! If the Poynting vector integral SideID additionally is a dielectric interface between a dielectric region
                        ! with a permittivity and vacuum, then mu_r might be unequal to 1.0 on the interface and the calculation of
                        ! the Poynting vector is not implemented for this case
                        IPWRITE(UNIT_stdOut,*) " "
                        IPWRITE(UNIT_stdOut,*) "Found illegal Poyting plane side. SideID= ",SideID,&
                            " z-coordinate= ",PosPoyntingInt(iPlane)
                        CALL abort(&
                            __STAMP__&
                            ,'GetPoyntingIntPlane: Found SideID for Poynting vector integral which is attached to an element'//&
                            ' within which the dielectric permittivity mu_r is not euqal to 1.0 everywhere. The value could be'//& 
                            ' unequal to 1.0 on the interface and this is not implemented. TODO: determine mu_r on interface,'//&
                            ' communicate it via MPI (do not forget Mortar sides) and calculate the Poynting vector on that'//&
                            ' interface via some method.')
                      END IF
                    END IF

                    ! 2.) Check for legal sides in dielectrics: mu_r != 1.0 within dielectric region
                    IF(isDielectricFace(SideID))THEN
                      !IPWRITE(UNIT_stdOut,*) "found dielectric face: ",SideID,"z= ",PosPoyntingInt(iPlane)
                      PoyntingUseMuR_Inv=.TRUE.
                    END IF
                  END IF
                  
                END IF
              END IF ! diff < eps
            END DO !p
          END DO !q
        END IF ! n parallel gyrotron axis
      END IF ! flip = 0 master side
    END DO ! iSides
  END DO !iElem=1,nElems
END DO ! iPlanes

! Dielectric sides:
#ifdef MPI
! Send info to ALL MPI ranks:
! TODO: If 1/mu_r is never needed on master AND slave procs, this routine can be adjusted so that only master procs determine the
! prolonged values of mu_r and no MPI information has to be sent. The master side cannot currently be outside of the dielectric
! region (e.g. in vacuum) because that is not allowed. If this would be allowed that MPI rank would need the information of the
! prolonged dielectric material properties from the slave side
  CALL MPI_ALLREDUCE(MPI_IN_PLACE,PoyntingUseMuR_Inv,1,MPI_LOGICAL,MPI_LOR,MPI_COMM_WORLD,iError)
#endif
! Determine mu_r on faces within a dielectric region for calculating the Poynting vector and communicate the
! prolonged values via MPI
#if (PP_nVar>=6)
IF(PoyntingUseMuR_Inv) CALL SetDielectricFaceProfileForPoynting()
#endif /*(PP_nVar>=6)*/

ALLOCATE(sumFaces(nPoyntingIntPlanes))
#ifdef MPI
sumFaces=0
sumAllFaces=0
  CALL MPI_REDUCE(nFaces , sumFaces , nPoyntingIntPlanes , MPI_INTEGER, MPI_SUM,0, MPI_COMM_WORLD, IERROR)
  !nFaces(:) = sumFaces(:)
  CALL MPI_REDUCE(nPoyntingIntSides , sumAllFaces , 1 , MPI_INTEGER, MPI_SUM,0, MPI_COMM_WORLD, IERROR)
  !nPoyntingIntSides = sumAllFaces
#else
sumFaces=nFaces
sumAllFaces=nPoyntingIntSides
#endif /* MPI */

DO iPlane= 1, nPoyntingIntPlanes
  SWRITE(UNIT_stdOut,'(A,I2,A,I10,A)') 'Processed plane no.: ',iPlane,'. Found ',sumFaces(iPlane),' surfaces.'
END DO
SWRITE(UNIT_stdOut,'(A,I10,A)') 'A total of',sumAllFaces, &
                        ' surfaces for the poynting vector integral calculation are found.'

ALLOCATE(S    (1:3,0:PP_N,0:PP_N,1:nPoyntingIntSides) , &
         STEM     (0:PP_N,0:PP_N,1:nPoyntingIntSides)  )

SWRITE(UNIT_stdOut,'(A)') ' ... POYNTING VECTOR INTEGRAL INITIALIZATION DONE.'  

END SUBROUTINE GetPoyntingIntPlane

SUBROUTINE FinalizePoyntingInt()
!===================================================================================================================================
! Finalize Poynting Integral
!===================================================================================================================================
! MODULES
USE MOD_Mesh_Vars         ,ONLY:isPoyntingIntSide,whichPoyntingPlane
USE MOD_Analyze_Vars      ,ONLY:PosPoyntingInt, S, STEM
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
!----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
!===================================================================================================================================
! DEALLOCATE ALL
SDEALLOCATE(isPoyntingIntSide)
SDEALLOCATE(PosPoyntingInt)
SDEALLOCATE(whichPoyntingPlane)
SDEALLOCATE(S)
SDEALLOCATE(STEM)

END SUBROUTINE FinalizePoyntingInt

SUBROUTINE CalcPotentialEnergy(WEl, WMag) 
!===================================================================================================================================
! Initializes variables necessary for analyse subroutines
!===================================================================================================================================
! MODULES
USE MOD_Globals
USE MOD_Preproc
USE MOD_Mesh_Vars,          ONLY : nElems, sJ
USE MOD_Interpolation_Vars, ONLY : wGP
USE MOD_Equation_Vars,      ONLY : smu0, eps0 
#ifndef PP_HDG
USE MOD_DG_Vars,            ONLY : U
#endif /*PP_nVar=8*/        
#ifdef PP_HDG
#if PP_nVar==1
USE MOD_Equation_Vars,        ONLY:E
#elif PP_nVar==3
USE MOD_Equation_Vars,        ONLY:B
#else
USE MOD_Equation_Vars,        ONLY:B,E
#endif /*PP_nVar==1*/
#else
USE MOD_PML_Vars,             ONLY:DoPML,isPMLElem
#endif /*PP_HDG*/
#ifdef MPI
#endif /*MPI*/
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
REAL,INTENT(OUT)                :: WEl, WMag 
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
INTEGER           :: iElem
INTEGER           :: i,j,k
REAL              :: J_N(1,0:PP_N,0:PP_N,0:PP_N)
REAL              :: WEl_tmp, WMag_tmp, E_abs
#ifndef PP_HDG
REAL              :: B_abs 
#endif
#ifdef MPI
REAL              :: RD
#endif
!===================================================================================================================================

Wel=0.
WMag=0.
DO iElem=1,nElems
#ifndef PP_HDG
  IF(DoPML)THEN
    IF(isPMLElem(iElem))CYCLE
  END IF
#endif
  !--- Calculate and save volume of element iElem
  WEl_tmp=0. 
  WMag_tmp=0. 
  J_N(1,0:PP_N,0:PP_N,0:PP_N)=1./sJ(:,:,:,iElem)
  DO k=0,PP_N; DO j=0,PP_N; DO i=0,PP_N
! in electromagnetische felder by henke 2011 - springer
! WMag = 1/(2mu) * int_V B^2 dV 
#ifdef PP_HDG
#if PP_nVar==1
    E_abs = E(1,i,j,k,iElem)*E(1,i,j,k,iElem) + E(2,i,j,k,iElem)*E(2,i,j,k,iElem) + E(3,i,j,k,iElem)*E(3,i,j,k,iElem)
#elif PP_nVar==3
    B_abs = B(1,i,j,k,iElem)*B(1,i,j,k,iElem) + B(2,i,j,k,iElem)*B(2,i,j,k,iElem) + B(3,i,j,k,iElem)*B(3,i,j,k,iElem)
#else /*PP_nVar==4*/
    E_abs = E(1,i,j,k,iElem)*E(1,i,j,k,iElem) + E(2,i,j,k,iElem)*E(2,i,j,k,iElem) + E(3,i,j,k,iElem)*E(3,i,j,k,iElem)
    B_abs = B(1,i,j,k,iElem)*B(1,i,j,k,iElem) + B(2,i,j,k,iElem)*B(2,i,j,k,iElem) + B(3,i,j,k,iElem)*B(3,i,j,k,iElem)
#endif /*PP_nVar==1*/
#else
    E_abs = U(1,i,j,k,iElem)*U(1,i,j,k,iElem) + U(2,i,j,k,iElem)*U(2,i,j,k,iElem) + U(3,i,j,k,iElem)*U(3,i,j,k,iElem)
#endif /*PP_HDG*/

#if (PP_nVar==8)
    B_abs = U(4,i,j,k,iElem)*U(4,i,j,k,iElem) + U(5,i,j,k,iElem)*U(5,i,j,k,iElem) + U(6,i,j,k,iElem)*U(6,i,j,k,iElem)
#endif /*PP_nVar=8*/        
#ifdef PP_HDG
#if PP_nVar==3
      WMag_tmp = WMag_tmp + wGP(i)*wGP(j)*wGP(k) * J_N(1,i,j,k) * B_abs
#elif PP_nVar==4
      WMag_tmp = WMag_tmp + wGP(i)*wGP(j)*wGP(k) * J_N(1,i,j,k) * B_abs
#endif /*PP_nVar==3*/
#endif /*PP_HDG*/
    WEl_tmp  = WEl_tmp  + wGP(i)*wGP(j)*wGP(k) * J_N(1,i,j,k) * E_abs 
#if (PP_nVar==8)
    WMag_tmp = WMag_tmp + wGP(i)*wGP(j)*wGP(k) * J_N(1,i,j,k) * B_abs
#endif /*PP_nVar=8*/        
  END DO; END DO; END DO
  WEl = WEl + WEl_tmp
#if (PP_nVar==8)
  WMag = WMag + WMag_tmp
#endif /*PP_nVar=8*/        
END DO

WEl = WEl * eps0 * 0.5 
WMag = WMag * smu0 * 0.5

#ifdef MPI
IF(MPIRoot)THEN
  CALL MPI_REDUCE(MPI_IN_PLACE,WEl  , 1 , MPI_DOUBLE_PRECISION, MPI_SUM,0, MPI_COMM_WORLD, IERROR)
  CALL MPI_REDUCE(MPI_IN_PLACE,WMag , 1 , MPI_DOUBLE_PRECISION, MPI_SUM,0, MPI_COMM_WORLD, IERROR)
ELSE
  CALL MPI_REDUCE(WEl         ,RD   , 1 , MPI_DOUBLE_PRECISION, MPI_SUM,0, MPI_COMM_WORLD, IERROR)
  CALL MPI_REDUCE(WMag        ,RD   , 1 , MPI_DOUBLE_PRECISION, MPI_SUM,0, MPI_COMM_WORLD, IERROR)
END IF
#endif /*MPI*/

END SUBROUTINE CalcPotentialEnergy


SUBROUTINE CalcPotentialEnergy_Dielectric(WEl, WMag) 
!===================================================================================================================================
! Initializes variables necessary for analyse subroutines
!===================================================================================================================================
! MODULES
USE MOD_Globals
USE MOD_Preproc
USE MOD_Mesh_Vars          ,ONLY: nElems, sJ
USE MOD_Interpolation_Vars ,ONLY: wGP
USE MOD_Equation_Vars      ,ONLY: smu0, eps0 
USE MOD_Dielectric_vars    ,ONLY: isDielectricElem,DielectricEps,DielectricMu,ElemToDielectric
#ifndef PP_HDG
USE MOD_DG_Vars            ,ONLY: U
#endif /*PP_nVar=8*/        
#ifdef PP_HDG
#if PP_nVar==1
USE MOD_Equation_Vars      ,ONLY: E
#elif PP_nVar==3
USE MOD_Equation_Vars      ,ONLY: B
#else
USE MOD_Equation_Vars      ,ONLY: B,E
#endif /*PP_nVar==1*/
#else
USE MOD_PML_Vars           ,ONLY: DoPML,isPMLElem
#endif /*PP_HDG*/
#ifdef MPI
#endif /*MPI*/
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
REAL,INTENT(OUT)                :: WEl, WMag 
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
INTEGER           :: iElem
INTEGER           :: i,j,k
REAL              :: J_N(1,0:PP_N,0:PP_N,0:PP_N)
REAL              :: WEl_tmp, WMag_tmp, E_abs
#ifndef PP_HDG
REAL              :: B_abs 
#endif
#ifdef MPI
REAL              :: RD
#endif
!===================================================================================================================================

Wel=0.
WMag=0.
DO iElem=1,nElems
#ifndef PP_HDG
  IF(DoPML)THEN
    IF(isPMLElem(iElem))CYCLE
  END IF
#endif
  !--- Calculate and save volume of element iElem
  WEl_tmp=0. 
  WMag_tmp=0. 
  J_N(1,0:PP_N,0:PP_N,0:PP_N)=1./sJ(:,:,:,iElem)





  IF(isDielectricElem(iElem))THEN
    DO k=0,PP_N; DO j=0,PP_N; DO i=0,PP_N
      ! in electromagnetische felder by henke 2011 - springer
      ! WMag = 1/(2mu) * int_V B^2 dV 
#ifdef PP_HDG
#if PP_nVar==1
      E_abs = E(1,i,j,k,iElem)*E(1,i,j,k,iElem) + E(2,i,j,k,iElem)*E(2,i,j,k,iElem) + E(3,i,j,k,iElem)*E(3,i,j,k,iElem)
#elif PP_nVar==3
      B_abs = B(1,i,j,k,iElem)*B(1,i,j,k,iElem) + B(2,i,j,k,iElem)*B(2,i,j,k,iElem) + B(3,i,j,k,iElem)*B(3,i,j,k,iElem)
#else /*PP_nVar==4*/
      E_abs = E(1,i,j,k,iElem)*E(1,i,j,k,iElem) + E(2,i,j,k,iElem)*E(2,i,j,k,iElem) + E(3,i,j,k,iElem)*E(3,i,j,k,iElem)
      B_abs = B(1,i,j,k,iElem)*B(1,i,j,k,iElem) + B(2,i,j,k,iElem)*B(2,i,j,k,iElem) + B(3,i,j,k,iElem)*B(3,i,j,k,iElem)
#endif /*PP_nVar==1*/
#else
      E_abs = U(1,i,j,k,iElem)*U(1,i,j,k,iElem) + U(2,i,j,k,iElem)*U(2,i,j,k,iElem) + U(3,i,j,k,iElem)*U(3,i,j,k,iElem)
#endif /*PP_HDG*/

#if (PP_nVar==8)
      B_abs = U(4,i,j,k,iElem)*U(4,i,j,k,iElem) + U(5,i,j,k,iElem)*U(5,i,j,k,iElem) + U(6,i,j,k,iElem)*U(6,i,j,k,iElem)
#endif /*PP_nVar=8*/        
#ifdef PP_HDG
#if PP_nVar==3
      WMag_tmp = WMag_tmp + wGP(i)*wGP(j)*wGP(k) * J_N(1,i,j,k) * B_abs / DielectricMu( i,j,k,ElemToDielectric(iElem))
#elif PP_nVar==4
      WMag_tmp = WMag_tmp + wGP(i)*wGP(j)*wGP(k) * J_N(1,i,j,k) * B_abs / DielectricMu( i,j,k,ElemToDielectric(iElem))
#endif /*PP_nVar==3*/
#endif /*PP_HDG*/
      WEl_tmp  = WEl_tmp  + wGP(i)*wGP(j)*wGP(k) * J_N(1,i,j,k) * E_abs * DielectricEps(i,j,k,ElemToDielectric(iElem))
#if (PP_nVar==8)
      WMag_tmp = WMag_tmp + wGP(i)*wGP(j)*wGP(k) * J_N(1,i,j,k) * B_abs / DielectricMu(i,j,k,ElemToDielectric(iElem))
#endif /*PP_nVar=8*/        
    END DO; END DO; END DO
  ELSE
    DO k=0,PP_N; DO j=0,PP_N; DO i=0,PP_N
      ! in electromagnetische felder by henke 2011 - springer
      ! WMag = 1/(2mu) * int_V B^2 dV 
#ifdef PP_HDG
#if PP_nVar==1
      E_abs = E(1,i,j,k,iElem)*E(1,i,j,k,iElem) + E(2,i,j,k,iElem)*E(2,i,j,k,iElem) + E(3,i,j,k,iElem)*E(3,i,j,k,iElem)
#elif PP_nVar==3
      B_abs = B(1,i,j,k,iElem)*B(1,i,j,k,iElem) + B(2,i,j,k,iElem)*B(2,i,j,k,iElem) + B(3,i,j,k,iElem)*B(3,i,j,k,iElem)
#else /*PP_nVar==4*/
      E_abs = E(1,i,j,k,iElem)*E(1,i,j,k,iElem) + E(2,i,j,k,iElem)*E(2,i,j,k,iElem) + E(3,i,j,k,iElem)*E(3,i,j,k,iElem)
      B_abs = B(1,i,j,k,iElem)*B(1,i,j,k,iElem) + B(2,i,j,k,iElem)*B(2,i,j,k,iElem) + B(3,i,j,k,iElem)*B(3,i,j,k,iElem)
#endif /*PP_nVar==1*/
#else
      E_abs = U(1,i,j,k,iElem)*U(1,i,j,k,iElem) + U(2,i,j,k,iElem)*U(2,i,j,k,iElem) + U(3,i,j,k,iElem)*U(3,i,j,k,iElem)
#endif /*PP_HDG*/

#if (PP_nVar==8)
      B_abs = U(4,i,j,k,iElem)*U(4,i,j,k,iElem) + U(5,i,j,k,iElem)*U(5,i,j,k,iElem) + U(6,i,j,k,iElem)*U(6,i,j,k,iElem)
#endif /*PP_nVar=8*/        
#ifdef PP_HDG
#if PP_nVar==3
      WMag_tmp = WMag_tmp + wGP(i)*wGP(j)*wGP(k) * J_N(1,i,j,k) * B_abs
#elif PP_nVar==4
      WMag_tmp = WMag_tmp + wGP(i)*wGP(j)*wGP(k) * J_N(1,i,j,k) * B_abs
#endif /*PP_nVar==3*/
#endif /*PP_HDG*/
      WEl_tmp  = WEl_tmp  + wGP(i)*wGP(j)*wGP(k) * J_N(1,i,j,k) * E_abs
#if (PP_nVar==8)
      WMag_tmp = WMag_tmp + wGP(i)*wGP(j)*wGP(k) * J_N(1,i,j,k) * B_abs
#endif /*PP_nVar=8*/        
    END DO; END DO; END DO
  END IF


    WEl = WEl + WEl_tmp
#if (PP_nVar==8)
    WMag = WMag + WMag_tmp
#endif /*PP_nVar=8*/        




END DO

WEl = WEl * eps0 * 0.5 
WMag = WMag * smu0 * 0.5

#ifdef MPI
IF(MPIRoot)THEN
  CALL MPI_REDUCE(MPI_IN_PLACE,WEl  , 1 , MPI_DOUBLE_PRECISION, MPI_SUM,0, MPI_COMM_WORLD, IERROR)
  CALL MPI_REDUCE(MPI_IN_PLACE,WMag , 1 , MPI_DOUBLE_PRECISION, MPI_SUM,0, MPI_COMM_WORLD, IERROR)
ELSE
  CALL MPI_REDUCE(WEl         ,RD   , 1 , MPI_DOUBLE_PRECISION, MPI_SUM,0, MPI_COMM_WORLD, IERROR)
  CALL MPI_REDUCE(WMag        ,RD   , 1 , MPI_DOUBLE_PRECISION, MPI_SUM,0, MPI_COMM_WORLD, IERROR)
END IF
#endif /*MPI*/

END SUBROUTINE CalcPotentialEnergy_Dielectric


#if (PP_nVar>=6)
SUBROUTINE SetDielectricFaceProfileForPoynting()
!===================================================================================================================================
!> THIS ROUTINE IS ONLY CALLED FOR THE POYNTING VECTOR INTEGRAL CALCULATION ON INITIALIZATION
!>
!> Set the dielectric factor 1./MuR for each face DOF in the array "Dielectric_MuR_Master_inv" (needed for S = E X H calculation).
!> Only the array "Dielectric_MuR_Master_inv" is used in the Riemann solver, as only the master calculates the flux array
!> (maybe slave information is used in the future)
!>
!> Note:
!> for MPI communication, the data on the faces has to be stored in an array which is completely sent to the corresponding MPI 
!> threads (one cannot simply send parts of an array using, e.g., "2:5" for an allocated array of dimension "1:5" because this
!> is not allowed)
!> re-map data from dimension PP_nVar (due to prolong to face routine) to 1 (only one dimension is needed to transfer the 
!> information)
!> This could be overcome by using template subroutines .t90 (see FlexiOS)
!===================================================================================================================================
! MODULES
USE MOD_Globals
USE MOD_PreProc
USE MOD_Dielectric_Vars ,ONLY: Dielectric_MuR_Master_inv,Dielectric_MuR_Slave_inv
USE MOD_Dielectric_Vars ,ONLY: isDielectricElem,ElemToDielectric,DielectricMu
USE MOD_Mesh_Vars       ,ONLY: nSides
USE MOD_ProlongToFace   ,ONLY: ProlongToFace
#ifdef MPI
USE MOD_MPI_Vars
USE MOD_MPI             ,ONLY: StartReceiveMPIData,StartSendMPIData,FinishExchangeMPIData
#endif
USE MOD_FillMortar      ,ONLY: U_Mortar
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLE,Dielectric_dummy_Master2S
REAL,DIMENSION(PP_nVar,0:PP_N,0:PP_N,1:nSides)           :: Dielectric_dummy_Master 
REAL,DIMENSION(PP_nVar,0:PP_N,0:PP_N,1:nSides)           :: Dielectric_dummy_Slave  
REAL,DIMENSION(PP_nVar,0:PP_N,0:PP_N,0:PP_N,1:PP_nElems) :: Dielectric_dummy_elem   
#ifdef MPI
REAL,DIMENSION(1,0:PP_N,0:PP_N,1:nSides)                 :: Dielectric_dummy_Master2
REAL,DIMENSION(1,0:PP_N,0:PP_N,1:nSides)                 :: Dielectric_dummy_Slave2 
INTEGER                                                  :: I,J,iSide
#endif /*MPI*/
INTEGER                                                  :: iElem
!===================================================================================================================================
! General workflow:
! 1.  Initialize dummy arrays for Elem/Face
! 2.  Fill dummy element values for non-Dielectric sides
! 3.  Map dummy element values to face arrays (prolong to face needs data of dimension PP_nVar)
! 4.  For MPI communication, the data on the faces has to be stored in an array which is completely sent to the corresponding MPI 
!     threads (one cannot simply send parts of an array using, e.g., "2:5" for an allocated array of dimension "1:5" because this
!     is not allowed)
!     re-map data from dimension PP_nVar (due to prolong to face routine) to 1 (only one dimension is needed to transfer the 
!     information)
! 5.  Send/Receive MPI data
! 6.  Allocate the actually needed arrays containing the dielectric material information on the sides
! 7.  With MPI, use dummy array which was used for sending the MPI data
!     or with single execution, directly use prolonged data on face
! 8.  Check if the default value remains unchanged (negative material constants are not allowed until now)

! 1.  Initialize dummy arrays for Elem/Face
Dielectric_dummy_elem    = -1.
Dielectric_dummy_Master  = -1.
Dielectric_dummy_Slave   = -1.

! 2.  Fill dummy element values for non-Dielectric sides
DO iElem=1,PP_nElems
  IF(isDielectricElem(iElem))THEN
    ! set only the first dimension to 1./MuR (the rest are dummies)
    Dielectric_dummy_elem(1,0:PP_N,0:PP_N,0:PP_N,(iElem))=1.0 / DielectricMu(0:PP_N,0:PP_N,0:PP_N,ElemToDielectric(iElem))
  ELSE
    Dielectric_dummy_elem(1,0:PP_N,0:PP_N,0:PP_N,(iElem))=1.0
  END IF
END DO

!3.   Map dummy element values to face arrays (prolong to face needs data of dimension PP_nVar)
CALL ProlongToFace(Dielectric_dummy_elem,Dielectric_dummy_Master,Dielectric_dummy_Slave,doMPISides=.FALSE.)
CALL U_Mortar(Dielectric_dummy_Master,Dielectric_dummy_Slave,doMPISides=.FALSE.)
#ifdef MPI
  CALL ProlongToFace(Dielectric_dummy_elem,Dielectric_dummy_Master,Dielectric_dummy_Slave,doMPISides=.TRUE.)
  CALL U_Mortar(Dielectric_dummy_Master,Dielectric_dummy_Slave,doMPISides=.TRUE.)
  
  ! 4.  For MPI communication, the data on the faces has to be stored in an array which is completely sent to the corresponding MPI 
  !     threads (one cannot simply send parts of an array using, e.g., "2:5" for an allocated array of dimension "1:5" because this
  !     is not allowed)
  !     re-map data from dimension PP_nVar (due to prolong to face routine) to 1 (only one dimension is needed to transfer the 
  !     information)
  Dielectric_dummy_Master2 = 0.
  Dielectric_dummy_Slave2  = 0.
  DO I=0,PP_N
    DO J=0,PP_N
      DO iSide=1,nSides
        Dielectric_dummy_Master2(1,I,J,iSide)=Dielectric_dummy_Master(1,I,J,iSide)
        Dielectric_dummy_Slave2 (1,I,J,iSide)=Dielectric_dummy_Slave( 1,I,J,iSide)
      END DO
    END DO
  END DO
  
  ! 5.  Send Slave Dielectric info (real array with dimension (N+1)*(N+1)) to Master procs
  CALL StartReceiveMPIData(1,Dielectric_dummy_Slave2 ,1,nSides ,RecRequest_U2,SendID=2) ! Receive MINE
  CALL StartSendMPIData(   1,Dielectric_dummy_Slave2 ,1,nSides,SendRequest_U2,SendID=2) ! Send YOUR
  
  ! Send Master Dielectric info (real array with dimension (N+1)*(N+1)) to Slave procs
  CALL StartReceiveMPIData(1,Dielectric_dummy_Master2,1,nSides ,RecRequest_U ,SendID=1) ! Receive YOUR
  CALL StartSendMPIData(   1,Dielectric_dummy_Master2,1,nSides,SendRequest_U ,SendID=1) ! Send MINE
  
  CALL FinishExchangeMPIData(SendRequest_U2,RecRequest_U2,SendID=2) !Send MINE - receive YOUR
  CALL FinishExchangeMPIData(SendRequest_U, RecRequest_U ,SendID=1) !Send YOUR - receive MINE 
#endif /*MPI*/

! 6.  Allocate the actually needed arrays containing the dielectric material information on the sides
ALLOCATE(Dielectric_MuR_Master_inv(0:PP_N,0:PP_N,1:nSides))
ALLOCATE(Dielectric_MuR_Slave_inv( 0:PP_N,0:PP_N,1:nSides))


! 7.  With MPI, use dummy array which was used for sending the MPI data
!     or with single execution, directly use prolonged data on face
#ifdef MPI
  Dielectric_MuR_Master_inv=Dielectric_dummy_Master2(1,0:PP_N,0:PP_N,1:nSides)
  Dielectric_MuR_Slave_inv =Dielectric_dummy_Slave2( 1,0:PP_N,0:PP_N,1:nSides)
#else
  Dielectric_MuR_Master_inv=Dielectric_dummy_Master(1,0:PP_N,0:PP_N,1:nSides)
  Dielectric_MuR_Slave_inv =Dielectric_dummy_Slave( 1,0:PP_N,0:PP_N,1:nSides)
#endif /*MPI*/

! 8.  Check if the default value remains unchanged (negative material constants are not allowed until now)
IF(MINVAL(Dielectric_MuR_Master_inv).LE.0.0)THEN
  CALL abort(&
  __STAMP__&
  ,'Dielectric material values for Riemann solver not correctly determined. MINVAL(Dielectric_MuR_Master_inv)=',&
  RealInfoOpt=MINVAL(Dielectric_MuR_Master_inv))
END IF
END SUBROUTINE SetDielectricFaceProfileForPoynting
#endif /*(PP_nVar>=6)*/

END MODULE MOD_AnalyzeField
