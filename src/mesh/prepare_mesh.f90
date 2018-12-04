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

MODULE MOD_Prepare_Mesh
!===================================================================================================================================
! Contains subroutines to build (curviilinear) meshes and provide metrics, etc.
!===================================================================================================================================
! MODULES
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
PRIVATE
!-----------------------------------------------------------------------------------------------------------------------------------
! GLOBAL VARIABLES (PUBLIC)
!-----------------------------------------------------------------------------------------------------------------------------------
! Public Part ----------------------------------------------------------------------------------------------------------------------

INTERFACE setLocalSideIDs
  MODULE PROCEDURE setLocalSideIDs
END INTERFACE

INTERFACE fillMeshInfo
  MODULE PROCEDURE fillMeshInfo
END INTERFACE

PUBLIC::setLocalSideIDs,fillMeshInfo

#ifdef MPI
INTERFACE exchangeFlip
  MODULE PROCEDURE exchangeFlip
END INTERFACE

PUBLIC::exchangeFlip 
#endif
!===================================================================================================================================

CONTAINS


SUBROUTINE setLocalSideIDs()
!===================================================================================================================================
!> This routine sorts sides into three groups containing BC sides, inner sides and MPI sides in the following manner:
!> 
!> * BCSides         : sides with boundary conditions (excluding periodic BCs)
!> * InnerMortars    : "virtual" sides introduced for collecting the data of the small sides at a non-conforming interface
!> * InnerSides      : normal inner sides
!> * MPI_MINE sides  : MPI sides to be processed by the current processor (e.g. flux computation)
!> * MPI_YOUR sides  : MPI sides to be processed by the neighbour processor
!> * MPIMortars      : mortar interfaces to be comunicated
!> 
!> Each side can be accessed through its SideID defining its position in the processor local side list.
!> The routine furthermore sets the MPI masters and slave sides.
!===================================================================================================================================
! MODULES
USE MOD_Globals
USE MOD_Mesh_Vars,          ONLY:tElem,tSide
USE MOD_Mesh_Vars,          ONLY: nElems,nInnerSides,nSides,nBCSides,offsetElem
USE MOD_Mesh_ReadIn,        ONLY: INVMAP
#ifdef PP_HDG
#ifdef MPI
USE MOD_Mesh_Vars,          ONLY: offsetSide
#endif /*MPI*/
#endif /*PP_HDG*/
USE MOD_LoadBalance_Vars,   ONLY: writePartitionInfo
USE MOD_Mesh_Vars,          ONLY: Elems,nMPISides_MINE,nMPISides_YOUR,BoundaryType,nBCs
USE MOD_Mesh_Vars,          ONLY: nMortarSides,nMortarInnerSides,nMortarMPISides
USE MOD_LoadBalance_Vars,   ONLY: DoLoadBalance,nLoadBalanceSteps, LoadDistri, PartDistri
#ifdef MPI
USE MOD_ReadInTools,        ONLY: GETLOGICAL
USE MOD_MPI_Vars,           ONLY: nNbProcs,NbProc,nMPISides_Proc,nMPISides_MINE_Proc,nMPISides_YOUR_Proc
USE MOD_MPI_Vars,           ONLY: offsetMPISides_MINE,offsetMPISides_YOUR,nMPISides_send,offSetMPISides_send
USE MOD_MPI_Vars,           ONLY: nMPISides_rec, OffsetMPISides_rec
#endif
#ifdef PARTICLES
USE MOD_Particle_Mesh_Vars, ONLY: SidePeriodicType
#endif /*PARTICLES*/
IMPLICIT NONE
! INPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT/OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
TYPE(tElem),POINTER   :: aElem
TYPE(tSide),POINTER   :: aSide
INTEGER               :: iElem,FirstElemInd,LastElemInd
INTEGER               :: iLocSide,iSide,iInnerSide,iBCSide
INTEGER               :: iMortar,iMortarInnerSide,iMortarMPISide,nMortars
INTEGER               :: i,j
INTEGER               :: PeriodicBCMap(nBCs)       !connected periodic BCs
#ifdef MPI
INTEGER               :: nSmallMortarSides
INTEGER               :: nSmallMortarInnerSides
INTEGER               :: nSmallMortarMPISides_MINE
INTEGER               :: nSmallMortarMPISides_YOUR
INTEGER               :: iNbProc,ioUnit, addToInnerMortars
INTEGER               :: ProcInfo(9),nNBmax      !for output only
INTEGER,ALLOCATABLE   :: SideIDMap(:)
INTEGER,ALLOCATABLE   :: NBinfo(:,:),NBinfo_glob(:,:,:),nNBProcs_glob(:),Procinfo_glob(:,:),tmparray(:,:)  !for output only
REAL,ALLOCATABLE      :: tmpreal(:,:),tmpreal2(:,:)
CHARACTER(LEN=10)     :: formatstr
CHARACTER(LEN=64)     :: filename
CHARACTER(LEN=4)      :: hilf
#ifdef PP_HDG
#ifdef MPI
INTEGER, ALLOCATABLE         :: offsetSideMPI(:)
INTEGER                      :: iProc
#endif /*MPI*/
#endif /*PP_HDG*/
#endif
!===================================================================================================================================
FirstElemInd= offsetElem+1
LastElemInd = offsetElem+nElems
! ----------------------------------------
! Set side IDs to arrange sides:
! 1. BC sides
! 2. inner sides
! 3. MPI sides
! MPI Sides are not included here!
! ----------------------------------------
! Get connection between periodic BCs
PeriodicBCMap=-2
DO i=1,nBCs
  IF((BoundaryType(i,BC_TYPE).NE.1)) PeriodicBCMap(i)=-1 ! not periodic
  IF((BoundaryType(i,BC_TYPE).EQ.1).AND.(BoundaryType(i,BC_ALPHA).GT.0)) PeriodicBCMap(i)=-1 ! slave
  IF((BoundaryType(i,BC_TYPE).EQ.1).AND.(BoundaryType(i,BC_ALPHA).LT.0))THEN
    DO j=1,nBCs
      IF(BoundaryType(j,BC_TYPE).NE.1) CYCLE
      IF(BoundaryType(j,BC_ALPHA).EQ.(-BoundaryType(i,BC_ALPHA))) PeriodicBCMap(i)=j
    END DO
  END IF
END DO
IF(ANY(PeriodicBCMap.EQ.-2))&
  CALL abort(&
  __STAMP__&
  ,'Periodic connection not found.')

DO iElem=FirstElemInd,LastElemInd
  aElem=>Elems(iElem)%ep
  DO iLocSide=1,6
    aSide=>aElem%Side(iLocSide)%sp
    nMortars=aSide%nMortars
    DO iMortar=0,nMortars
      IF(iMortar.GT.0) aSide=>aElem%Side(iLocSide)%sp%mortarSide(iMortar)%sp

      aSide%sideID=-1
      ! periodics have two bcs: set to (positive) master bc (e.g. from -1 to 1)
#ifdef PARTICLES
      IF(aSide%BCIndex.GE.1)THEN
        IF(BoundaryType(aSide%BCIndex,BC_TYPE).EQ.1)THEN
          ! additionally, the flip of the side has to be taken into account
          ! the alpha value is only correct for slave sides, for master sides, the 
          ! value has to be turned
          IF(aSide%BC_Alpha.GT.0)THEN
            aSide%BC_Alpha=BoundaryType(aSide%BCIndex,BC_ALPHA)
          ELSE
            aSide%BC_Alpha=-BoundaryType(aSide%BCIndex,BC_ALPHA)
          END IF
        ELSE
          aSide%BC_Alpha=0
        END IF
      ELSE
        ! get the correct  alpha and BCIndex for the side for the later use with particles
        aSide%BC_Alpha=0
      END IF
#endif
      IF(aSide%BCIndex.GE.1)THEN
        IF(PeriodicBCMap(aSide%BCIndex).NE.-1)&
          aSide%BCIndex=PeriodicBCMap(aSide%BCIndex)
      END IF
    END DO !iMortar
  END DO
END DO

nMortarInnerSides=0
nMortarMPISides=0
DO iElem=FirstElemInd,LastElemInd
  aElem=>Elems(iElem)%ep
  DO iLocSide=1,6
    aSide=>aElem%Side(iLocSide)%sp
    aSide%tmp=0
    IF(aSide%nMortars.GT.0)THEN
      DO iMortar=1,aSide%nMortars
        IF(aElem%Side(iLocSide)%sp%mortarSide(iMortar)%sp%nbProc.NE.-1)THEN
          aSide%tmp=-1
          EXIT
        END IF
      END DO !iMortar
      IF(aSide%tmp.EQ.-1) THEN
        nMortarMPISides=nMortarMPISides+1
      ELSE
        nMortarInnerSides=nMortarInnerSides+1
      END IF
    END IF !nMortars>0
  END DO
END DO
IF((nMortarInnerSides+nMortarMPISides).NE.nMortarSides) &
   CALL abort(__STAMP__,'nInner+nMPI mortars <> nMortars.')

#ifdef PARTICLES
ALLOCATE(SidePeriodicType(1:nSides))
SidePeriodicType = 0
! positive entry: adding the periodic vector ends on the plus side
! neg. entry: minus the periodic vector ends on the minus side
! e.g. in periodic vector direction
!      side+.xGP = side-.xGP + PeriodicVector
!      side-.xGP = side+.xGP - PeriodicVector
#endif /*PARTICLES*/

iSide=0
iBCSide=0
iMortarInnerSide=nBCSides
iInnerSide=nBCSides+nMortarInnerSides
iMortarMPISide=nSides-nMortarMPISides
DO iElem=FirstElemInd,LastElemInd
  aElem=>Elems(iElem)%ep
  DO iLocSide=1,6
    aSide=>aElem%Side(iLocSide)%sp
    nMortars=aSide%nMortars
    DO iMortar=0,nMortars
      IF(iMortar.GT.0) aSide=>aElem%Side(iLocSide)%sp%mortarSide(iMortar)%sp

      IF(aSide%sideID.EQ.-1)THEN
        IF(aSide%NbProc.EQ.-1)THEN ! no MPI Sides
          IF(ASSOCIATED(aSide%connection))THEN
            iInnerSide=iInnerSide+1
            iSide=iSide+1
            aSide%SideID=iInnerSide
            aSide%connection%SideID=iInnerSide
          ELSE
            IF(aSide%MortarType.GT.0) THEN
              IF(aSide%tmp.EQ.-1)THEN !MPI mortar side
                iMortarMPISide=iMortarMPISide+1
                aSide%SideID=iMortarMPISide
              ELSE
                iMortarInnerSide=iMortarInnerSide+1
                iSide=iSide+1
                aSide%SideID=iMortarInnerSide
              END IF !mpi mortar
            ELSE !this is now a BC side, really!
              iBCSide=iBCSide+1
              iSide=iSide+1
              aSide%SideID=iBCSide
            END IF !mortar
          END IF !associated connection
        END IF ! .NOT. MPISide
#ifdef PARTICLES
        IF(aSide%SideID.GT.0) SidePeriodicType(aSide%SideID)=aSide%BC_Alpha
#endif /*PARTICLES*/
      END IF !sideID NE -1
    END DO !iMortar
  END DO ! iLocSide=1,6
END DO !iElem
IF(iSide.NE.nInnerSides+nBCSides+nMortarInnerSides) CALL abort(&
  __STAMP__&
  ,'not all SideIDs are set!')
LOGWRITE(*,*)'-------------------------------------------------------'
LOGWRITE(*,'(A22,I8)')'nMortarSides:',nMortarSides
LOGWRITE(*,'(A22,I8)')'nMortarInnerSides:',nMortarInnerSides
LOGWRITE(*,'(A22,I8)')'nMortarMPISides:',nMortarMPISides
LOGWRITE(*,*)'-------------------------------------------------------'

nMPISides_MINE=0
nMPISides_YOUR=0

#ifdef MPI
! SPLITTING MPISides in MINE and YOURS
ALLOCATE(nMPISides_MINE_Proc(1:nNbProcs),nMPISides_YOUR_Proc(1:nNbProcs))
nMPISides_MINE_Proc=0
nMPISides_YOUR_Proc=0
DO iNbProc=1,nNbProcs
  IF(myRank.LT.NbProc(iNbProc)) THEN
    nMPISides_MINE_Proc(iNbProc)=nMPISides_Proc(iNbProc)/2
  ELSE
    nMPISides_MINE_Proc(iNbProc)=nMPISides_Proc(iNbProc)-nMPISides_Proc(iNbProc)/2
  END IF    
  nMPISides_YOUR_Proc(iNbProc)=nMPISides_Proc(iNbProc)-nMPISides_MINE_Proc(iNbProc)
END DO
nMPISides_MINE=SUM(nMPISides_MINE_Proc)
nMPISides_YOUR=SUM(nMPISides_YOUR_Proc)

ALLOCATE(offsetMPISides_YOUR(0:nNbProcs),offsetMPISides_MINE(0:nNbProcs))
offsetMPISides_MINE=0
offsetMPISides_YOUR=0
! compute offset, first all MINE , then all YOUR MPISides
offsetMPISides_MINE(0)=nInnerSides+nBCSides+nMortarInnerSides
DO iNbProc=1,nNbProcs
  offsetMPISides_MINE(iNbProc)=offsetMPISides_MINE(iNbProc-1)+nMPISides_MINE_Proc(iNbProc)
END DO
offsetMPISides_YOUR(0)=offsetMPISides_MINE(nNbProcs)
DO iNbProc=1,nNbProcs
  offsetMPISides_YOUR(iNbProc)=offsetMPISides_YOUR(iNbProc-1)+nMPISides_YOUR_Proc(iNbProc)
END DO

DO iNbProc=1,nNbProcs
  ALLOCATE(SideIDMap(nMPISides_Proc(iNbProc)))
  iSide=0
  DO iElem=FirstElemInd,LastElemInd
    aElem=>Elems(iElem)%ep
    DO iLocSide=1,6
      aSide=>aElem%Side(iLocSide)%sp
      nMortars=aSide%nMortars
      DO iMortar=0,nMortars
        IF(iMortar.GT.0) aSide=>aElem%Side(iLocSide)%sp%mortarSide(iMortar)%sp
        IF(aSide%NbProc.NE.NbProc(iNbProc))CYCLE
        iSide=iSide+1
        !trick: put non-mortars first to optimize addtoInnerMortars (also small mortar sides are marked with MortarType<0)
        IF((iMortar.EQ.0).AND.(aSide%MortarType.EQ.0)) aSide%ind=-aSide%ind
        !
        SideIDMap(iSide)=aSide%ind !global Side Index
      END DO !iMortar
    END DO !iLocSide
  END DO !iElem
  IF(iSide.GT.1) CALL MergeSort(SideIDMap(1:iSide),iSide) !sort by global side index
  DO iElem=FirstElemInd,LastElemInd
    aElem=>Elems(iElem)%ep
    DO iLocSide=1,6
      aSide=>aElem%Side(iLocSide)%sp
      nMortars=aSide%nMortars
      DO iMortar=0,nMortars
        IF(iMortar.GT.0) aSide=>aElem%Side(iLocSide)%sp%mortarSide(iMortar)%sp
        IF(aSide%NbProc.NE.NbProc(iNbProc))CYCLE
        aSide%SideID=INVMAP(aSide%ind,nMPISides_Proc(iNbProc),SideIDMap) ! get sorted iSide
        IF(myRank.LT.aSide%NbProc)THEN
          IF(aSide%SideID.LE.nMPISides_MINE_Proc(iNbProc))THEN !MINE
            aSide%SideID=aSide%SideID +offsetMPISides_MINE(iNbProc-1)
#ifdef PARTICLES
            SidePeriodicType(aSide%SideID)=aSide%BC_Alpha
#endif /*PARTICLES*/
          ELSE !YOUR
            aSide%SideID=(aSide%SideID-nMPISides_MINE_Proc(iNbProc))+offsetMPISides_YOUR(iNbProc-1)
#ifdef PARTICLES
            SidePeriodicType(aSide%SideID)=aSide%BC_Alpha ! -1
#endif /*PARTICLES*/
          END IF
        ELSE
          IF(aSide%SideID.LE.nMPISides_YOUR_Proc(iNbProc))THEN !MINE
            aSide%SideID=aSide%SideID +offsetMPISides_YOUR(iNbProc-1)
#ifdef PARTICLES
            SidePeriodicType(aSide%SideID)=aSide%BC_Alpha
#endif /*PARTICLES*/
          ELSE !YOUR
            aSide%SideID=(aSide%SideID-nMPISides_YOUR_Proc(iNbProc))+offsetMPISides_MINE(iNbProc-1)
#ifdef PARTICLES
            SidePeriodicType(aSide%SideID)=aSide%BC_Alpha ! -1
#endif /*PARTICLES*/
          END IF
        END IF !myrank<NbProc
      END DO !iMortar
    END DO !iLocSide
  END DO !iElem
  DEALLOCATE(SideIDMap)
END DO !nbProc(i)
DO iElem=FirstElemInd,LastElemInd
  aElem=>Elems(iElem)%ep
  DO iLocSide=1,6
    aSide=>aElem%Side(iLocSide)%sp
    nMortars=aSide%nMortars
    DO iMortar=0,nMortars
      IF(iMortar.GT.0) aSide=>aElem%Side(iLocSide)%sp%mortarSide(iMortar)%sp
      aSide%ind=ABS(aSide%ind) ! set back trick
    END DO !iMortar
  END DO !iLocSide
END DO !iElem
! optimize mortars: search for mortars being fully MPI_MINE and add them to innerMortars
IF(nMortarSides.GT.0)THEN
  addToInnerMortars=0
  DO iElem=FirstElemInd,LastElemInd
    aElem=>Elems(iElem)%ep
    DO iLocSide=1,6
      aSide=>aElem%Side(iLocSide)%sp
      aSide%tmp=0
      DO iMortar=1,aSide%nMortars
        aElem%Side(iLocSide)%sp%mortarSide(iMortar)%sp%tmp=0
      END DO !iMortar
    END DO !iLocSide
  END DO !iElem
  DO iElem=FirstElemInd,LastElemInd
    aElem=>Elems(iElem)%ep
    DO iLocSide=1,6
      aSide=>aElem%Side(iLocSide)%sp
      IF(aSide%nMortars.GT.0)THEN
        aSide%tmp=-1 !mortar side
        DO iMortar=1,aSide%nMortars
          IF(aElem%Side(iLocSide)%sp%mortarSide(iMortar)%sp%SideID.GT.offsetMPISides_YOUR(0))THEN
            aSide%tmp=-2  !mortar side with side used in MPI_YOUR
            EXIT
          END IF
        END DO !iMortar
        IF(aSide%tmp.EQ.-1) THEN
          addToInnerMortars=addToInnerMortars+1
        END IF
      END IF !nMortars>0
    END DO !iLocSide
  END DO !iElem
  addToInnerMortars=addToInnerMortars-nMortarInnerSides
  IF(addToInnerMortars.GT.0)THEN
    iMortarInnerSide=nBCSides+nMortarInnerSides
    DO iElem=FirstElemInd,LastElemInd
      aElem=>Elems(iElem)%ep
      DO iLocSide=1,6
        aSide=>aElem%Side(iLocSide)%sp
        IF((aSide%tmp.EQ.0).AND.(aSide%SideID.GT.iMortarInnerSide))THEN
          !shift SideID
          aSide%SideID=aSide%SideID+addToInnerMortars
          aSide%tmp=1
        END IF
        nMortars=aSide%nMortars
        DO iMortar=1,nMortars
          aSide=>aElem%Side(iLocSide)%sp%mortarSide(iMortar)%sp
          IF((aSide%tmp.EQ.0).AND.(aSide%SideID.GT.iMortarInnerSide))THEN
            aSide%SideID=aSide%SideID+addToInnerMortars
            aSide%tmp=1
          END IF
        END DO !iMortar
      END DO !iLocSide
    END DO !iElem
    offsetMPISides_MINE=offsetMPISides_MINE+addToInnerMortars
    offsetMPISides_YOUR=offsetMPISides_YOUR+addToInnerMortars

    nMortarInnerSides=nMortarInnerSides+addToInnerMortars
    nMortarMPISides  =nMortarMPISides-addToInnerMortars
    iMortarMPISide=nSides-nMortarMPISides
    iMortarInnerSide=nBCSides

    DO iElem=FirstElemInd,LastElemInd
      aElem=>Elems(iElem)%ep
      DO iLocSide=1,6
        aSide=>aElem%Side(iLocSide)%sp
        IF(aSide%tmp.EQ.-2)THEN !MPI mortars, renumber SideIDs
          iMortarMPISide=iMortarMPISide+1
          aSide%SideID=iMortarMPISide
#ifdef PARTICLES
          SidePeriodicType(aSide%SideID)=aSide%BC_Alpha
#endif /*PARTICLES*/
        ELSEIF(aSide%tmp.EQ.-1)THEN !innermortars mortars, renumber SideIDs
          iMortarInnerSide=iMortarInnerSide+1
          aSide%SideID=iMortarInnerSide
#ifdef PARTICLES
          SidePeriodicType(aSide%SideID)=aSide%BC_Alpha
#endif /*PARTICLES*/
        END IF !aSide%tmp==-1
      END DO !iLocSide
    END DO !iElem
  END IF !addToInnerMortars>0
  LOGWRITE(*,*)'-------------------------------------------------------'
  LOGWRITE(*,'(A22,I8)')'addToInnerMortars:',addToInnerMortars
  LOGWRITE(*,'(A22,I8)')'new nMortarSides:',nMortarSides
  LOGWRITE(*,'(A22,I8)')'new nMortarInnerSides:',nMortarInnerSides
  LOGWRITE(*,'(A22,I8)')'new nMortarMPISides:',nMortarMPISides
  LOGWRITE(*,*)'-------------------------------------------------------'
END IF !nMortarSides>0

nSmallMortarSides=0
nSmallMortarMPIsides_MINE=0
nSmallMortarMPIsides_YOUR=0
DO iElem=1,nElems
  aElem=>Elems(iElem+offsetElem)%ep
  DO iLocSide=1,6
    aSide=>aElem%Side(iLocSide)%sp
    IF(aSide%nMortars.GT.0)THEN !mortar side
      nSmallMortarSides=nSmallMortarSides+aSide%nMortars
      DO iMortar=1,aSide%nMortars
        IF (aSide%MortarSide(iMortar)%sp%SideID.GT.offsetMPISides_YOUR(0))THEN
          nSmallMortarMPIsides_YOUR=nSmallMortarMPISides_YOUR+1
        ELSE
          IF(aSide%MortarSide(iMortar)%sp%SideID.GT.offsetMPISides_MINE(0))THEN
            nSmallMortarMPISides_MINE=nSmallMortarMPISides_MINE+1
          END IF
        END IF
      END DO !iMortar
    END IF !mortarSide
  END DO ! LocSideID
END DO ! iElem
nSmallMortarInnerSides=nSmallMortarSides-nSmallMortarMPISides_MINE-nSmallMortarMPISides_YOUR

!------------------------------------------------------
! Copy data into some MPI arrays
!------------------------------------------------------

ALLOCATE(nMPISides_send(       nNbProcs,2))
ALLOCATE(OffsetMPISides_send(0:nNbProcs,2))
ALLOCATE(nMPISides_rec(        nNbProcs,2))
ALLOCATE(OffsetMPISides_rec( 0:nNbProcs,2))
! Set number of sides and offset for SEND MINE - RECEIVE YOUR case
nMPISides_send(:,1)     =nMPISides_MINE_Proc
OffsetMPISides_send(:,1)=OffsetMPISides_MINE
nMPISides_rec(:,1)      =nMPISides_YOUR_Proc
OffsetMPISides_rec(:,1) =OffsetMPISides_YOUR
! Set number of sides and offset for SEND YOUR - RECEIVE MINE case
nMPISides_send(:,2)     =nMPISides_YOUR_Proc
OffsetMPISides_send(:,2)=OffsetMPISides_YOUR
nMPISides_rec(:,2)      =nMPISides_MINE_Proc
OffsetMPISides_rec(:,2) =OffsetMPISides_MINE

!------------------------------------------------------
! From this point on only debug output is performed
!------------------------------------------------------

WRITE(formatstr,'(a5,I2,a3)')'(A22,',nNBProcs,'I8)'
LOGWRITE(*,*)'-------------------------------------------------------'
LOGWRITE(*,'(A22,I8)')'nNbProcs:',nNbProcs
LOGWRITE(*,*)'-------------------------------------------------------'
LOGWRITE(*,formatstr)'NbProc:'   ,NbProc
LOGWRITE(*,*)'-------------------------------------------------------'
LOGWRITE(*,formatstr)'nMPISides_Proc:',nMPISides_Proc
LOGWRITE(*,*)'-------------------------------------------------------'
LOGWRITE(*,formatstr)'nMPISides_MINE_Proc:',nMPISides_MINE_Proc
LOGWRITE(*,formatstr)'nMPISides_YOUR_Proc:',nMPISides_YOUR_Proc
WRITE(formatstr,'(a5,I2,a3)')'(A22,',nNBProcs+1,'I8)'
LOGWRITE(*,*)'-------------------------------------------------------'
LOGWRITE(*,formatstr)'offsetMPISides_MINE:',offsetMPISides_MINE
LOGWRITE(*,formatstr)'offsetMPISides_YOUR:',offsetMPISides_YOUR
LOGWRITE(*,*)'-------------------------------------------------------'

#ifdef PP_HDG
#ifdef MPI
! CAUTION: MY-MORTAR-MPI-Sides are missing
IF(ALLOCATED(offsetSideMPI))DEALLOCATE(offsetSideMPI)
ALLOCATE(offsetSideMPI(nProcessors))
CALL MPI_ALLGATHER(nSides-nMPISides_YOUR,1,MPI_INTEGER,offsetSideMPI,1,MPI_INTEGER,MPI_COMM_WORLD,IERROR)
offsetSide=0 ! set default for restart!!!
DO iProc=1, myrank
  offsetSide = offsetSide + offsetSideMPI(iProc)
END DO
#endif /*MPI*/
#endif /*PP_HDG*/

writePartitionInfo = GETLOGICAL('writePartitionInfo','.FALSE.')
IF(DoLoadBalance)THEN
  writePartitionInfo=.TRUE.
  WRITE( hilf,'(I4.4)') nLoadBalanceSteps
  filename='partitionInfo-'//TRIM(hilf)//'.out'
ELSE
  filename='partitionInfo.out'
END IF

IF(.NOT.writePartitionInfo) RETURN
!output partitioning info
ProcInfo(1)=nElems
ProcInfo(2)=nSides
ProcInfo(3)=nInnerSides
ProcInfo(4)=nBCSides
ProcInfo(5)=nMortarInnerSides
ProcInfo(6)=nMortarMPISides
ProcInfo(7)=nSmallMortarInnerSides
ProcInfo(8)=nSmallMortarMPISides_MINE
ProcInfo(9)=nSmallMortarMPISides_YOUR
IF(MPIroot)THEN
  ALLOCATE(nNBProcs_glob(0:nProcessors-1))
  ALLOCATE(ProcInfo_glob(9,0:nProcessors-1))
  nNBProcs_glob=-99999
  Procinfo_glob=-88888
ELSE
  ALLOCATE(nNBProcs_glob(1)) !dummy for debug
  ALLOCATE(ProcInfo_glob(1,1)) !dummy for debug
END IF !MPIroot 
CALL MPI_GATHER(nNBProcs,1,MPI_INTEGER,nNBProcs_glob,1,MPI_INTEGER,0,MPI_COMM_WORLD,iError)
CALL MPI_GATHER(ProcInfo,9,MPI_INTEGER,ProcInfo_glob,9,MPI_INTEGER,0,MPI_COMM_WORLD,iError)
IF(MPIroot)THEN
  nNBmax=MAXVAL(nNBProcs_glob) !count, total number of columns in table
  ALLOCATE(NBinfo_glob(6,nNBmax,0:nProcessors))
  NBinfo_glob=-77777
ELSE
  ALLOCATE(NBinfo_glob(1,1,1)) !dummy for debug
END IF
CALL MPI_BCAST(nNBmax,1,MPI_INTEGER,0,MPI_COMM_WORLD,iError) 
ALLOCATE(NBinfo(6,nNbmax))
NBinfo=0
NBinfo(1,1:nNBProcs)=NBProc
NBinfo(2,1:nNBProcs)=nMPISides_Proc
NBinfo(3,1:nNBProcs)=nMPISides_MINE_Proc
NBinfo(4,1:nNBProcs)=nMPISides_YOUR_Proc
NBinfo(5,1:nNBProcs)=offsetMPISides_MINE(0:nNBProcs-1)
NBinfo(6,1:nNBProcs)=offsetMPISides_YOUR(0:nNBProcs-1)
CALL MPI_GATHER(NBinfo,6*nNBmax,MPI_INTEGER,NBinfo_glob,6*nNBmax,MPI_INTEGER,0,MPI_COMM_WORLD,iError)
DEALLOCATE(NBinfo)
IF(MPIroot)THEN
  ioUnit=GETFREEUNIT()
  OPEN(UNIT=ioUnit,FILE=filename,STATUS='REPLACE')
  WRITE(ioUnit,*)'Partition Information:'
  WRITE(ioUnit,*)'total number of Procs,',nProcessors
  WRITE(ioUnit,*)'total number of Elems,',SUM(Procinfo_glob(1,:))

  WRITE(ioUnit,'(15(A23))')'Rank','nElems','nParts','Load','nSides','nInnerSides','nBCSides','nMPISides', &
      'nMPISides_MINE','nNBProcs' ,&
              'nMortarInnerSides', 'nMortarMPISides', 'nSmallMortInnerSides', 'nSmallMortMPISidesMINE', 'nSmallMortMPISidesYOUR'
  WRITE(ioUnit,'(345("="))')
  !statistics
  ALLOCATE(tmparray(13,0:3),tmpreal(13,2),tmpreal2(1,0:5))
  tmparray(:,0)=0      !tmp
  tmparray(:,1)=0      !mean
  tmparray(:,2)=0       !HUGE(-1)  !max
  tmparray(:,3)=HUGE(1)   !min
  tmpreal2(:,0)=0.      !tmp
  tmpreal2(:,1)=0.      !mean
  tmpreal2(:,2)=0.       !HUGE(-1)  !max
  tmpreal2(:,3)=HUGE(1.)   !min
  DO i=0,nProcessors-1
    !actual proc
    tmparray( 1,0)=Procinfo_glob(1,i)
    tmparray( 2,0)=PartDistri(i) ! particles in proc i
    tmparray( 3,0)=Procinfo_glob(2,i)
    tmparray( 4,0)=Procinfo_glob(3,i)
    tmparray( 5,0)=Procinfo_glob(4,i)
    tmparray( 6,0)=SUM(NBinfo_glob(2,:,i))
    tmparray( 7,0)=SUM(NBinfo_glob(3,:,i))
    tmparray( 8,0)=nNBProcs_glob(i)
    tmparray( 9,0)=Procinfo_glob(5,i)
    tmparray(10,0)=Procinfo_glob(6,i)
    tmparray(11,0)=Procinfo_glob(7,i)
    tmparray(12,0)=Procinfo_glob(8,i)
    tmparray(13,0)=Procinfo_glob(9,i)
    tmpreal2(1,0)=LoadDistri(i) ! load of proc i
    DO j=1,13
      !mean
      tmparray(j,1)=tmparray(j,1)+tmparray(j,0)
      !max
      tmparray(j,2)=MAX(tmparray(j,2),tmparray(j,0))
      tmparray(j,3)=MIN(tmparray(j,3),tmparray(j,0))
    END DO
    DO j=1,1
      !mean
      tmpreal2(j,1)=tmpreal2(j,1)+tmpreal2(j,0)
      !max
      tmpreal2(j,2)=MAX(tmpreal2(j,2),tmpreal2(j,0))
      tmpreal2(j,3)=MIN(tmpreal2(j,3),tmpreal2(j,0))
    END DO
  END DO
  tmpreal(:,1)=REAL(tmparray(:,1))/REAL(nProcessors) !mean in REAL
  tmpreal(:,2)=0.   !RMS
  tmpreal2(:,4)=tmpreal2(:,1)/REAL(nProcessors) !mean in REAL
  tmpreal2(:,5)=0.   !RMS
  DO i=0,nProcessors-1
    !actual proc
    tmparray( 1,0)=Procinfo_glob(1,i)
    tmparray( 2,0)=PartDistri(i) ! particles in proc i
    tmparray( 3,0)=Procinfo_glob(2,i)
    tmparray( 4,0)=Procinfo_glob(3,i)
    tmparray( 5,0)=Procinfo_glob(4,i)
    tmparray( 6,0)=SUM(NBinfo_glob(2,:,i))
    tmparray( 7,0)=SUM(NBinfo_glob(3,:,i))
    tmparray( 8,0)=nNBProcs_glob(i)
    tmparray( 9,0)=Procinfo_glob(5,i)
    tmparray(10,0)=Procinfo_glob(6,i)
    tmparray(11,0)=Procinfo_glob(7,i)
    tmparray(12,0)=Procinfo_glob(8,i)
    tmparray(13,0)=Procinfo_glob(9,i)
    tmpreal2(1,0)=LoadDistri(i) ! load of proc i
    DO j=1,13
      tmpreal(j,2)=tmpreal(j,2)+(tmparray(j,0)-tmpreal(j,1))**2 
    END DO
    DO j=1,1
      tmpreal2(j,5)=tmpreal2(j,5)+(tmpreal2(j,0)-tmpreal2(j,4))**2 
    END DO
  END DO
  tmpreal(:,2)=SQRT(tmpreal(:,2)/REAL(nProcessors))
  tmpreal2(:,5)=SQRT(tmpreal2(:,5)/REAL(nProcessors))
  WRITE(ioUnit,'(A23,9(13X,F10.2))')'   MEAN        ',tmpreal(1:2,1),tmpreal2(1:1,4),tmpreal(3:13,1)
  WRITE(ioUnit,'(345("-"))')
  WRITE(ioUnit,'(A23,9(13X,F10.2))')'   RMS         ',tmpreal(1:2,2),tmpreal2(1:1,5),tmpreal(3:13,2)
  WRITE(ioUnit,'(345("-"))')
  WRITE(ioUnit,'(A23,2(13X,I10),13x,F10.2,6(13X,I10))')'   MIN         ',tmparray(1:2,3),tmpreal2(1:1,3),tmparray(3:13,3)
  WRITE(ioUnit,'(345("-"))')
  WRITE(ioUnit,'(A23,2(13X,I10),13x,F10.2,6(13X,I10))')'   MAX         ',tmparray(1:2,2),tmpreal2(1:1,2),tmparray(3:13,2)
  WRITE(ioUnit,'(345("="))')
  DO i=0,nProcessors-1
    WRITE(ioUnit,'(3(13X,I10),13x,F10.2,6(13X,I10))')i,Procinfo_glob(1,i),PartDistri(i),LoadDistri(i),Procinfo_glob(2:4,i)&
                               ,SUM(NBinfo_glob(2,:,i)),SUM(NBinfo_glob(3,:,i)),nNBProcs_glob(i),Procinfo_glob(5:9,i)
    WRITE(ioUnit,'(345("-"))')
  END DO
  WRITE(ioUnit,*)' '
  WRITE(ioUnit,*)'Information per neighbor processor'
  WRITE(ioUnit,*)' '
  WRITE(ioUnit,'(7(A15))')'Rank','NBProc','nMPISides_Proc','nMPISides_MINE','nMPISides_YOUR','offset_MINE','offset_YOUR'
  WRITE(ioUnit,'(105("="))')
  DO i=0,nProcessors-1
    WRITE(ioUnit,'(7(5X,I10))')i,NBinfo_glob(:,1,i)
    DO j=2,nNBProcs_glob(i)
      WRITE(ioUnit,'(A15,6(5X,I10))')' ',NBinfo_glob(:,j,i)
    END DO
  WRITE(ioUnit,'(105("="))')
  END DO
  DEALLOCATE(tmparray,tmpreal,tmpreal2)
  CLOSE(ioUnit) 
END IF !MPIroot
DEALLOCATE(NBinfo_glob,nNBProcs_glob,ProcInfo_glob)
#endif /*MPI*/  
END SUBROUTINE setLocalSideIDs


SUBROUTINE fillMeshInfo()
!===================================================================================================================================
!> This routine condenses the mesh topology from a pointer-based structure into arrays.
!> The array ElemToSide contains for each elements local side the global SideID and its
!> flip with regard to the neighbour side.
!> The SideToElem array contains for each side the neighbour elements (master and slave)
!> as well as the local side IDs of the side within those elements.
!> The last entry is the flip of the slave with regard to the master element.
!===================================================================================================================================
! MODULES
USE MOD_Globals
USE MOD_Mesh_Vars,ONLY:tElem,tSide,Elems
USE MOD_Mesh_Vars,ONLY: nElems,offsetElem,nBCSides,nSides
USE MOD_Mesh_Vars,ONLY: firstMortarInnerSide,lastMortarInnerSide,nMortarInnerSides,firstMortarMPISide
USE MOD_Mesh_Vars,ONLY: ElemToSide,SideToElem,BC,AnalyzeSide,ElemToElemGlob
USE MOD_Mesh_Vars,ONLY: MortarType,MortarInfo,MortarSlave2MasterInfo
USE MOD_Mesh_Vars,ONLY:BoundaryType ! is required for particles and periodic sides!!
#ifdef MPI
USE MOD_MPI_vars
#endif
IMPLICIT NONE
! INPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT/OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
TYPE(tElem),POINTER :: aElem
TYPE(tSide),POINTER :: aSide,mSide
INTEGER             :: iElem,LocSideID,nSides_flip(0:4),SideID
INTEGER             :: nSides_MortarType(1:3),iMortar
INTEGER             :: FirstElemID,LastElemID,ilocSide,locMortarSide,NBElemID,SideID2,NBlocSideID
#ifdef MPI
INTEGER             :: dummy(0:4)
#endif
!===================================================================================================================================
! ELement to Side mapping
nSides_flip=0
DO iElem=1,nElems
  aElem=>Elems(iElem+offsetElem)%ep
  DO LocSideID=1,6
    aSide=>aElem%Side(LocSideID)%sp
    ElemToSide(E2S_SIDE_ID,LocSideID,iElem)=aSide%SideID
    ElemToSide(E2S_FLIP,LocSideID,iElem)   =aSide%Flip
    nSides_flip(aSide%flip)=nSides_flip(aSide%flip)+1
  END DO ! LocSideID
END DO ! iElem

! Side to Element mapping, sorted by SideID
DO iElem=1,nElems
  aElem=>Elems(iElem+offsetElem)%ep
  DO LocSideID=1,6
    aSide=>aElem%Side(LocSideID)%sp
    IF(aSide%Flip.EQ.0)THEN !root side
      SideToElem(S2E_ELEM_ID,aSide%SideID)         = iElem !root Element
      SideToElem(S2E_LOC_SIDE_ID,aSide%SideID)     = LocSideID
      AnalyzeSide(aSide%sideID)                    = aSide%BCIndex
    ELSE
      SideToElem(S2E_NB_ELEM_ID,aSide%SideID)      = iElem ! element with flipped side
      SideToElem(S2E_NB_LOC_SIDE_ID,aSide%SideID)  = LocSideID
      SideToElem(S2E_FLIP,aSide%SideID)            = aSide%Flip
    END IF
    IF(aSide%sideID .LE. nBCSides)THEN
      BC(aSide%sideID)=aSide%BCIndex
    ELSE
      ! mark periodic BCs
      IF(aSide%BCindex.NE.0)THEN !side is BC or periodic side
        IF(BoundaryType(aSide%BCindex,BC_TYPE).EQ.1) BC(aSide%SideID)=aSide%BCindex
      END IF
#ifdef PARTICLES
      ! mark analyze-sides or inner-BCs for particles
      IF(aSide%BCindex.NE.0)THEN ! side is inner-BC or analyze side
        IF(BoundaryType(aSide%BCindex,BC_TYPE).NE.1) BC(aSide%SideID)=aSide%BCindex
      END IF
#endif /*PARTICLES*/
    END IF
  END DO ! LocSideID
END DO ! iElem

! Side to Element mapping, sorted by iElem, only MINE are added
nSides_MortarType=0

DO iElem=1,nElems
  aElem=>Elems(iElem+offsetElem)%ep
  DO LocSideID=1,6
    aSide=>aElem%Side(LocSideID)%sp
    IF(aSide%nMortars.GT.0)THEN !mortar side
      ! compute index of big mortar in MortarInfo = [1:nMortarSides]
      SideID=aSide%SideID+1-MERGE(firstMortarInnerSide,firstMortarMPISide-nMortarInnerSides,&
                                  aSide%SideID.LE.lastMortarInnerSide)
      MortarType(1,aSide%SideID)=aSide%MortarType
      MortarType(2,aSide%SideID)=SideID
      DO iMortar=1,aSide%nMortars
        mSide=>aSide%MortarSide(iMortar)%sp
        MortarInfo(MI_SIDEID,iMortar,SideID)=mSide%SideID
        MortarInfo(MI_FLIP,iMortar,SideID)=mSide%Flip
      END DO !iMortar
      nSides_MortarType(aSide%MortarType)=nSides_MortarType(aSide%MortarType)+1
    END IF !mortarSide
  END DO ! LocSideID
END DO ! iElem

MortarSlave2MasterInfo(:) = -1
DO SideID=1,nSides
  IF (MortarType(MI_SIDEID,SideID).NE.-1) THEN
    DO iMortar=1,4
      IF (MortarInfo(MI_SIDEID,iMortar,MortarType(2,SideID)).NE.-1) THEN
      MortarSlave2MasterInfo(MortarInfo(MI_SIDEID,iMortar,MortarType(2,SideID))) = SideID
      END IF
    END DO
  END IF
END DO

#ifdef MPI
IF(MPIroot)THEN
  CALL MPI_REDUCE(MPI_IN_PLACE,nSides_flip,5,MPI_INTEGER,MPI_SUM,0,MPI_COMM_WORLD,iError)
  CALL MPI_REDUCE(MPI_IN_PLACE     ,nSides_MortarType,3,MPI_INTEGER,MPI_SUM,0,MPI_COMM_WORLD,iError)
ELSE
  CALL MPI_REDUCE(nSides_flip,dummy,5,MPI_INTEGER,MPI_SUM,0,MPI_COMM_WORLD,iError)
  CALL MPI_REDUCE(nSides_MortarType,nSides_MortarType,3,MPI_INTEGER,MPI_SUM,0,MPI_COMM_WORLD,iError)
END IF
#endif /*MPI*/
SWRITE(UNIT_StdOut,'(132("."))')
SWRITE(*,'(A,A34,I0)')' |','nSides with Flip=0 | ',nSides_flip(0)
SWRITE(*,'(A,A34,I0)')' |','nSides with Flip=1 | ',nSides_flip(1)
SWRITE(*,'(A,A34,I0)')' |','nSides with Flip=2 | ',nSides_flip(2)
SWRITE(*,'(A,A34,I0)')' |','nSides with Flip=3 | ',nSides_flip(3)
SWRITE(*,'(A,A34,I0)')' |','nSides with Flip=4 | ',nSides_flip(4)
SWRITE(UNIT_StdOut,'(132("."))')
SWRITE(*,'(A,A34,I0)')' |','nSides of MortarType=1 | ',nSides_MortarType(1)
SWRITE(*,'(A,A34,I0)')' |','nSides of MortarType=2 | ',nSides_MortarType(2)
SWRITE(*,'(A,A34,I0)')' |','nSides of MortarType=3 | ',nSides_MortarType(3)
SWRITE(UNIT_StdOut,'(132("."))')

LOGWRITE(*,*)'============================= START SIDE CHECKER ==================='
DO iElem=1,nElems
  aElem=>Elems(iElem+offsetElem)%ep
  LOGWRITE(*,*)'=============== iElem= ',iElem, '==================='
  DO LocSideID=1,6
    aSide=>aElem%Side(LocSideID)%sp
    LOGWRITE(*,'(5(A,I4))')'globSideID= ',aSide%ind, &
                 ', flip= ',aSide%flip ,&
                 ', SideID= ', aSide%SideID,', nMortars= ',aSide%nMortars,', nbProc= ',aSide%nbProc
    IF(aSide%nMortars.GT.0)THEN !mortar side
      LOGWRITE(*,*)'   --- Mortars ---'
      DO iMortar=1,aSide%nMortars
        LOGWRITE(*,'(I4,4(A,I4))') iMortar,', globSideID= ',aSide%MortarSide(iMortar)%sp%ind, &
                     ', flip= ',aSide%MortarSide(iMortar)%sp%Flip, &
                     ', SideID= ',aSide%MortarSide(iMortar)%sp%SideID, &
                     ', nbProc= ',aSide%MortarSide(iMortar)%sp%nbProc

      END DO !iMortar
    END IF !mortarSide
  END DO ! LocSideID
END DO ! iElem
LOGWRITE(*,*)'============================= END SIDE CHECKER ==================='


! build global connection of elements to elements
FirstElemID=offsetElem+1
LastElemID=offsetElem+nElems
ALLOCATE(ElemToElemGlob(1:4,1:6,FirstElemID:LastElemID))
ElemToElemGlob=-1
DO iElem=1,nElems
  DO ilocSide=1,6
    SideID=ElemToSide(E2S_SIDE_ID,ilocSide,iElem)
    IF(SideID.LE.nBCSides) ElemToElemGlob(1,ilocSide,offSetElem+iElem)=0
    locMortarSide=MortarType(2,SideID)
    IF(locMortarSide.EQ.-1)THEN ! normal side or small mortar side
      NBElemID=SideToElem(S2E_NB_ELEM_ID,SideID)
      IF(NBElemID.GT.0)THEN
        IF(NBElemID.NE.iElem) ElemToElemGlob(1,ilocSide,offSetElem+iElem)=offSetElem+NBElemID
      END IF
      NBElemID=SideToElem(S2E_ELEM_ID,SideID)
      IF(NBElemID.GT.0)THEN
        IF(NBElemID.NE.iElem) ElemToElemGlob(1,ilocSide,offSetElem+iElem)=offSetElem+NBElemID
      END IF
    ELSE ! mortar side
      DO iMortar=1,4
        SideID2=MortarInfo(MI_SIDEID,iMortar,locMortarSide)
        IF(SideID2.GT.0)THEN
          NBElemID=SideToElem(S2E_NB_ELEM_ID,SideID2)
          IF(NBElemID.GT.0)THEN
            ElemToElemGlob(iMortar,ilocSide,offSetElem+iElem)=offSetElem+NBElemID
            ! mapping from small mortar side to neighbor, inverse of above
            NBlocSideID=SideToElem(S2E_NB_LOC_SIDE_ID,SideID2)
            ElemToElemGlob(1,NBlocSideID,offSetElem+NBElemID)=offSetElem+iElem
          END IF
        END IF
      END DO ! iMortar=1,4
    END IF ! locMortarSide
    ! self connectivity in MPI case
    IF(ElemToElemGlob(1,ilocSide,offSetElem+iElem).EQ.-1) ElemToElemGlob(1,ilocSide,offSetElem+iElem) = offSetElem+iElem
  END DO ! ilocSide=1,6
END DO ! iElem=1,PP_nElems

#ifdef MPI
CALL exchangeElemID()
#endif /*MPI*/

END SUBROUTINE fillMeshInfo


#ifdef MPI
SUBROUTINE exchangeFlip()
!===================================================================================================================================
!> This routine communicates the flip between MPI sides, as the flip determines wheter
!> a side is a master or a slave side. The flip of MINE sides is set to zero, therefore
!> send MINE flip to other processor, so YOUR sides get their corresponding flip>0.
!===================================================================================================================================
! MODULES
USE MOD_Globals
USE MOD_Mesh_Vars,ONLY:nElems,offsetElem
USE MOD_Mesh_Vars,ONLY:tElem,tSide,Elems
USE MOD_MPI_vars
#ifdef PARTICLES
USE MOD_Particle_Mesh_Vars, ONLY: SidePeriodicType
#endif /*PARTICLES*/
IMPLICIT NONE
! INPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT/OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
TYPE(tElem),POINTER :: aElem
TYPE(tSide),POINTER :: aSide
INTEGER             :: iElem,LocSideID
INTEGER             :: iMortar,nMortars
INTEGER             :: Flip_MINE(offsetMPISides_MINE(0)+1:offsetMPISides_MINE(nNBProcs))
INTEGER             :: Flip_YOUR(offsetMPISides_YOUR(0)+1:offsetMPISides_YOUR(nNBProcs))
INTEGER             :: SendRequest(nNbProcs),RecRequest(nNbProcs)
!===================================================================================================================================
IF(nProcessors.EQ.1) RETURN
!fill MINE flip info
DO iElem=1,nElems
  aElem=>Elems(iElem+offsetElem)%ep
  DO LocSideID=1,6
    aSide=>aElem%Side(LocSideID)%sp
    nMortars=aSide%nMortars
    DO iMortar=0,nMortars
      IF(iMortar.GT.0) aSide=>aElem%Side(LocSideID)%sp%mortarSide(iMortar)%sp
      IF((aSide%SideID.GT.offsetMPISides_MINE(0)       ).AND.&
         (aSide%SideID.LE.offsetMPISides_MINE(nNBProcs)))THEN
        Flip_MINE(aSide%sideID)=aSide%flip
      END IF
    END DO ! iMortar
  END DO ! LocSideID
END DO ! iElem
DO iNbProc=1,nNbProcs
  ! Start send flip from MINE
  IF(nMPISides_MINE_Proc(iNbProc).GT.0)THEN
    nSendVal    =nMPISides_MINE_Proc(iNbProc)
    SideID_start=OffsetMPISides_MINE(iNbProc-1)+1
    SideID_end  =OffsetMPISides_MINE(iNbProc)
    CALL MPI_ISEND(Flip_MINE(SideID_start:SideID_end),nSendVal,MPI_INTEGER,  &
                    nbProc(iNbProc),0,MPI_COMM_WORLD,SendRequest(iNbProc),iError)
  END IF
  ! Start receive flip to YOUR
  IF(nMPISides_YOUR_Proc(iNbProc).GT.0)THEN
    nRecVal     =nMPISides_YOUR_Proc(iNbProc)
    SideID_start=OffsetMPISides_YOUR(iNbProc-1)+1
    SideID_end  =OffsetMPISides_YOUR(iNbProc)
    CALL MPI_IRECV(Flip_YOUR(SideID_start:SideID_end),nRecVal,MPI_INTEGER,  &
                    nbProc(iNbProc),0,MPI_COMM_WORLD,RecRequest(iNbProc),iError)
  END IF
END DO !iProc=1,nNBProcs
DO iNbProc=1,nNbProcs
  IF(nMPISides_YOUR_Proc(iNbProc).GT.0)CALL MPI_WAIT(RecRequest(iNbProc) ,MPIStatus,iError)
  IF(iERROR.NE.0) CALL abort(&
  __STAMP__&
  ,' MPI-Error during flip-exchange. iError', iERROR)
  IF(nMPISides_MINE_Proc(iNBProc).GT.0)CALL MPI_WAIT(SendRequest(iNbProc),MPIStatus,iError)
  IF(iERROR.NE.0) CALL abort(&
  __STAMP__&
  ,' MPI-Error during flip-exchange. iError', iERROR)
END DO !iProc=1,nNBProcs
DO iElem=1,nElems
  aElem=>Elems(iElem+offsetElem)%ep
  DO LocSideID=1,6
    aSide=>aElem%Side(LocSideID)%sp
    nMortars=aSide%nMortars
    DO iMortar=0,nMortars
      IF(iMortar.GT.0) aSide=>aElem%Side(LocSideID)%sp%mortarSide(iMortar)%sp
      IF(aSide%NbProc.EQ.-1) CYCLE !no MPISide
      IF(aSide%SideID.GT.offsetMPISides_YOUR(0))THEN
        IF(aSide%flip.EQ.0)THEN
          IF(Flip_YOUR(aSide%SideID).EQ.0) CALL abort(__STAMP__&
              ,'problem in exchangeflip') 
#ifdef PARTICLES
          ! switch side-alpha if flip is changed. The other side now constructs the side, thus it has to be changed
          IF(aSide%flip.NE.Flip_YOUR(aSide%SideID))  SidePeriodicType(aSide%SideID) =-SidePeriodicType(aSide%SideID)
#endif /*PARTICLES*/
          aSide%flip=Flip_YOUR(aSide%sideID)
        END IF
      ELSE
#ifdef PARTICLES
        ! if side has not been a master side, i.e. a slave side, it is now used as a master side, hence, the
        ! periodic displacement vector has to be rotated
        IF(aSide%flip.NE.0) SidePeriodicType(aSide%SideID) =-SidePeriodicType(aSide%SideID)
#endif /*PARTICLES*/
        aSide%flip=0 !MINE MPISides flip=0
      END IF
    END DO ! iMortar
  END DO ! LocSideID
END DO ! iElem
 
END SUBROUTINE exchangeFlip
#endif


#ifdef MPI
SUBROUTINE exchangeElemID()
!===================================================================================================================================
!> This routine communicates the global-elemid between MPI interfaces
!===================================================================================================================================
! MODULES
USE MOD_Globals
USE MOD_Mesh_Vars,ONLY:nElems,offsetElem
USE MOD_Mesh_Vars,ONLY:tElem,tSide,Elems
USE MOD_Mesh_Vars, ONLY:ElemToElemGlob
USE MOD_MPI_vars
IMPLICIT NONE
! INPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT/OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
TYPE(tElem),POINTER :: aElem
TYPE(tSide),POINTER :: aSide
INTEGER             :: iElem,LocSideID
INTEGER             :: iMortar,nMortars
INTEGER             :: ElemID_MINE(offsetMPISides_MINE(0)+1:offsetMPISides_YOUR(nNBProcs))
INTEGER             :: ElemID_YOUR(offsetMPISides_MINE(0)+1:offsetMPISides_YOUR(nNBProcs))
INTEGER             :: SendRequest(nNbProcs),RecRequest(nNbProcs)
!===================================================================================================================================
IF(nProcessors.EQ.1) RETURN

!fill MINE ElemID info
ElemID_MINE=-1
DO iElem=1,nElems
  aElem=>Elems(iElem+offsetElem)%ep
  DO LocSideID=1,6
    aSide=>aElem%Side(LocSideID)%sp
    nMortars=aSide%nMortars
    DO iMortar=0,nMortars
      IF(iMortar.GT.0) aSide=>aElem%Side(LocSideID)%sp%mortarSide(iMortar)%sp
      IF((aSide%SideID.GT.offsetMPISides_MINE(0)       ).AND.&
         (aSide%SideID.LE.offsetMPISides_YOUR(nNBProcs)))THEN
        ElemID_MINE(aSide%sideID)=offSetElem+iElem
      END IF
    END DO ! iMortar
  END DO ! LocSideID
END DO ! iElem

! first communication: Slave to Master
DO iNbProc=1,nNbProcs
  ! Start send flip from MINE
  nSendVal    =nMPISides_send(iNBProc,2)
  SideID_start=OffsetMPISides_send(iNbProc-1,2)+1  
  SideID_end  =OffsetMPISides_send(iNbProc,2)    
  IF(nSendVal.GT.0)THEN
    CALL MPI_ISEND(ElemID_MINE(SideID_start:SideID_end),nSendVal,MPI_INTEGER,  &
                    nbProc(iNbProc),0,MPI_COMM_WORLD,SendRequest(iNbProc),iError)
  END IF
  ! Start receive flip to YOUR
  nRecVal     =nMPISides_rec(iNbProc,2)
  SideID_start=OffsetMPISides_rec(iNbProc-1,2)+1
  SideID_end  =OffsetMPISides_rec(iNbProc,2)
  IF(nRecVal.GT.0)THEN
    CALL MPI_IRECV(ElemID_YOUR(SideID_start:SideID_end),nRecVal,MPI_INTEGER,  &
                    nbProc(iNbProc),0,MPI_COMM_WORLD,RecRequest(iNbProc),iError)
  END IF
END DO !iProc=1,nNBProcs
DO iNbProc=1,nNbProcs
  nRecVal     =nMPISides_rec(iNbProc,2)
  IF(nRecVal.GT.0)CALL MPI_WAIT(RecRequest(iNbProc) ,MPIStatus,iError)
  IF(iERROR.NE.0) CALL abort(&
  __STAMP__&
  ,' MPI-Error during ElemID-exchange. iError', iERROR)
  nSendVal    =nMPISides_send(iNBProc,2)
  IF(nSendVal.GT.0)CALL MPI_WAIT(SendRequest(iNbProc),MPIStatus,iError)
  IF(iERROR.NE.0) CALL abort(&
  __STAMP__&
  ,' MPI-Error during ElemID-exchange. iError', iERROR)
END DO !iProc=1,nNBProcs

! second communication: Master to Slave 
DO iNbProc=1,nNbProcs
  ! Start send flip from MINE
  nSendVal    =nMPISides_send(iNBProc,1)
  SideID_start=OffsetMPISides_send(iNbProc-1,1)+1  
  SideID_end  =OffsetMPISides_send(iNbProc,1)    
  IF(nSendVal.GT.0)THEN
    CALL MPI_ISEND(ElemID_MINE(SideID_start:SideID_end),nSendVal,MPI_INTEGER,  &
                    nbProc(iNbProc),0,MPI_COMM_WORLD,SendRequest(iNbProc),iError)
  END IF
  ! Start receive flip to YOUR
  nRecVal     =nMPISides_rec(iNbProc,1)
  SideID_start=OffsetMPISides_rec(iNbProc-1,1)+1
  SideID_end  =OffsetMPISides_rec(iNbProc,1)
  IF(nRecVal.GT.0)THEN
    CALL MPI_IRECV(ElemID_YOUR(SideID_start:SideID_end),nRecVal,MPI_INTEGER,  &
                    nbProc(iNbProc),0,MPI_COMM_WORLD,RecRequest(iNbProc),iError)
  END IF
END DO !iProc=1,nNBProcs
DO iNbProc=1,nNbProcs
  nRecVal     =nMPISides_rec(iNbProc,1)
  IF(nRecVal.GT.0)CALL MPI_WAIT(RecRequest(iNbProc) ,MPIStatus,iError)
  IF(iERROR.NE.0) CALL abort(&
  __STAMP__&
  ,' MPI-Error during ElemID-exchange. iError', iERROR)
  nSendVal    =nMPISides_send(iNBProc,1)
  IF(nSendVal.GT.0)CALL MPI_WAIT(SendRequest(iNbProc),MPIStatus,iError)
  IF(iERROR.NE.0) CALL abort(&
  __STAMP__&
  ,' MPI-Error during ElemID-exchange. iError', iERROR)
END DO !iProc=1,nNBProcs

DO iElem=1,nElems
  aElem=>Elems(iElem+offsetElem)%ep
  DO LocSideID=1,6
    aSide=>aElem%Side(LocSideID)%sp
    nMortars=aSide%nMortars
    DO iMortar=0,nMortars
      IF(iMortar.GT.0) aSide=>aElem%Side(LocSideID)%sp%mortarSide(iMortar)%sp
      IF((aSide%SideID.GT.offsetMPISides_MINE(0)       ).AND.&
         (aSide%SideID.LE.offsetMPISides_YOUR(nNBProcs)))THEN
        IF(iMortar.EQ.0)THEN
          ElemToElemGlob(1,locSideID,offSetElem+iElem)=ElemID_YOUR(aside%sideID)
        ELSE
          ElemToElemGlob(iMortar,locSideID,offSetElem+iElem)=ElemID_YOUR(aside%sideID)
        END IF
      END IF
    END DO ! iMortar
  END DO ! LocSideID
END DO ! iElem
 
END SUBROUTINE exchangeElemID
#endif


RECURSIVE SUBROUTINE MergeSort(A,nTotal)
!===================================================================================================================================
!> Fast recursive sorting algorithm for integer arrays
!===================================================================================================================================
! MODULES
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
INTEGER,INTENT(IN)    :: nTotal    !< size of array to be sorted
INTEGER,INTENT(INOUT) :: A(nTotal) !< array to be sorted
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
INTEGER               :: nA,nB,tmp
!===================================================================================================================================
IF(nTotal.LT.2) RETURN
IF(nTotal.EQ.2)THEN
  IF(A(1).GT.A(2))THEN
    tmp  = A(1)
    A(1) = A(2)
    A(2) = tmp
  ENDIF
  RETURN
ENDIF
nA=(nTotal+1)/2
CALL MergeSort(A,nA)
nB=nTotal-nA
CALL MergeSort(A(nA+1:nTotal),nB)
! Performed first on lowest level
IF(A(nA).GT.A(nA+1)) CALL DoMerge(A,nA,nB)
END SUBROUTINE MergeSort


SUBROUTINE DoMerge(A,nA,nB)
!===================================================================================================================================
!> Merge subarrays (part of mergesort)
!===================================================================================================================================
! MODULES
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
INTEGER,INTENT(IN)    :: nA        !< number of items in A
INTEGER,INTENT(IN)    :: nB        !< number of items in B
INTEGER,INTENT(INOUT) :: A(nA+nB)  !< subarray to be merged
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
INTEGER :: i,j,k
INTEGER :: part1(nA),part2(nB)
!===================================================================================================================================
part1(1:nA)=A(1:nA)
part2(1:nB)=A(nA+1:nA+nB)
i=1; j=1; k=1;
DO WHILE((i.LE.nA).AND.(j.LE.nB))
  IF(part1(i).LE.part2(j))THEN
    A(k)=part1(i)
    i=i+1
  ELSE
    A(k)=part2(j)
    j=j+1
  ENDIF
  k=k+1
END DO
j=nA-i
A(k:k+nA-i)=part1(i:nA)
END SUBROUTINE DoMerge


END MODULE MOD_Prepare_Mesh
