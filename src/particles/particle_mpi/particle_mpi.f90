#include "boltzplatz.h"

MODULE MOD_Particle_MPI
!===================================================================================================================================
! Contains global variables provided by the particle surfaces routines
!===================================================================================================================================
! MODULES
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
PUBLIC
SAVE
!-----------------------------------------------------------------------------------------------------------------------------------
! required variables
!-----------------------------------------------------------------------------------------------------------------------------------
! GLOBAL VARIABLES

INTERFACE InitParticleMPI
  MODULE PROCEDURE InitParticleMPI
END INTERFACE

#ifdef MPI
INTERFACE IRecvNbOfParticles
  MODULE PROCEDURE IRecvNbOfParticles
END INTERFACE

INTERFACE FinalizeParticleMPI
  MODULE PROCEDURE FinalizeParticleMPI
END INTERFACE

INTERFACE MPIParticleSend
  MODULE PROCEDURE MPIParticleSend
END INTERFACE

INTERFACE MPIParticleRecv
  MODULE PROCEDURE MPIParticleRecv
END INTERFACE

INTERFACE InitHaloMesh
  MODULE PROCEDURE InitHaloMesh
END INTERFACE

INTERFACE InitParticleCommSize
  MODULE PROCEDURE InitParticleCommSize
END INTERFACE

INTERFACE InitEmissionComm
  MODULE PROCEDURE InitEmissionComm
END INTERFACE

INTERFACE BoxInProc
  MODULE PROCEDURE BoxInProc
END INTERFACE

PUBLIC :: InitParticleMPI,FinalizeParticleMPI,InitHaloMesh, InitParticleCommSize, IRecvNbOfParticles, MPIParticleSend
PUBLIC :: MPIParticleRecv
PUBLIC :: InitEmissionComm
#else
PUBLIC :: InitParticleMPI
#endif /*MPI*/

!===================================================================================================================================

CONTAINS

SUBROUTINE InitParticleMPI()
!===================================================================================================================================
! read required parameters
!===================================================================================================================================
! MODULES
USE MOD_Globals
USE MOD_Preproc
USE MOD_Particle_MPI_Vars
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
! INPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT/OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
!REAL                             :: myRealTestValue
!===================================================================================================================================

SWRITE(UNIT_StdOut,'(132("-"))')
SWRITE(UNIT_stdOut,'(A)')' INIT PARTICLE MPI ... '
IF(ParticleMPIInitIsDone) &
  CALL abort(__STAMP__&
  ,' Particle MPI already initialized!')

#ifdef MPI
PartMPI%COMM   = MPI_COMM_WORLD
PartMPI%myrank = myRank
PartMPI%nProcs = nProcessors
PartCommSize   = 0  
IF(PartMPI%MyRank.EQ.0) THEN
  PartMPI%MPIRoot=.TRUE.
ELSE
  PartMPI%MPIRoot=.FALSE.
END IF
#else
PartMPI%myRank = 0 
PartMPI%nProcs = 1 
PartMPI%MPIRoot=.TRUE.
#endif  /*MPI*/
!! determine datatype length for variables to be sent
!myRealKind = KIND(myRealTestValue)
!IF (myRealKind.EQ.4) THEN
!  myRealKind = MPI_REAL
!ELSE IF (myRealKind.EQ.8) THEN
!  myRealKind = MPI_DOUBLE_PRECISION
!ELSE
!  myRealKind = MPI_REAL
!END IF

ParticleMPIInitIsDone=.TRUE.
SWRITE(UNIT_stdOut,'(A)')' INIT PARTICLE MPI DONE!'
SWRITE(UNIT_StdOut,'(132("-"))')

END SUBROUTINE InitParticleMPI


#ifdef MPI
SUBROUTINE InitParticleCommSize()
!===================================================================================================================================
! get size of Particle-MPI-Message. Unfortunately, this subroutine have to be called after particle_init because
! all required features have to be read from the ini-File
!===================================================================================================================================
! MODULES
USE MOD_Globals
USE MOD_Preproc
USE MOD_Particle_MPI_Vars
USE MOD_DSMC_Vars,           ONLY:useDSMC, CollisMode, DSMC
USE MOD_Particle_Vars,       ONLY:usevMPF
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
! INPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT/OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
!===================================================================================================================================

PartCommSize   = 0  
IF (useDSMC.AND.(CollisMode.NE.1)) THEN
  IF (usevMPF .AND. DSMC%ElectronicState) THEN
    PartCommSize = 18
  ELSE IF (usevMPF ) THEN
    PartCommSize = 17
  ELSE IF ( DSMC%ElectronicState ) THEN
    PartCommSize = 17
  ELSE
    PartCommSize = 16
  END IF
ELSE
  IF (usevMPF) THEN
    PartCommSize = 15
  ELSE
    PartCommSize = 14
  END IF
END IF

#if ((PP_TimeDiscMethod!=1) && (PP_TimeDiscMethod!=2) && (PP_TimeDiscMethod!=6))  /* RK3 and RK4 only */
  PartCommSize = PartCommSize - 6
#endif

ALLOCATE( PartMPIExchange%nPartsSend(PartMPI%nMPINeighbors)  & 
        , PartMPIExchange%nPartsRecv(PartMPI%nMPINeighbors)  &
        , PartRecvBuf(1:PartMPI%nMPINeighbors)                 &
        , PartMPIExchange%SendRequest(2,PartMPI%nMPINeighbors) &
        , PartMPIExchange%RecvRequest(2,PartMPI%nMPINeighbors) )
END SUBROUTINE InitParticleCommSize


SUBROUTINE IRecvNbOfParticles()
!===================================================================================================================================
! Open Recv-Buffer for number of received particles
!===================================================================================================================================
! MODULES
USE MOD_Globals
USE MOD_Preproc
USE MOD_Particle_MPI_Vars,      ONLY:PartMPI,PartMPIExchange
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
! INPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT/OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
INTEGER               :: iProc
!===================================================================================================================================

PartMPIExchange%nPartsRecv=0
DO iProc=1,PartMPI%nMPINeighbors
  CALL MPI_IRECV( PartMPIExchange%nPartsRecv(iProc)                          &
                , 1                                                          &
                , MPI_INTEGER                                                &
                , PartMPI%MPINeighbor(iProc)                                 &
                , 1001                                                       &
                , PartMPI%COMM                                               &
                , PartMPIExchange%RecvRequest(1,iProc)                       &
                , IERROR )
!  CALL MPI_IRECV( PartMPIExchange%nPartsRecv(iProc)                          &
!                , 1                                                          &
!                , MPI_INTEGER                                                &
!                , PartMPI%MPINeighbor(iProc)                                 &
!                , 1001                                                       &
!                , PartMPI%COMM                                               &
!                , PartMPIExchange%RecvRequest(1,PartMPI%MPINeighbor(iProc))  &
!                , IERROR )
END DO ! iProc

END SUBROUTINE IRecvNbOfParticles


SUBROUTINE MPIParticleSend()
!===================================================================================================================================
! this routine sends the particles. Following steps are performed
! 1) Compute number of Send Particles
! 2) Performe MPI_ISEND with number of particles
! 3) Build Message 
! 4) MPI_WAIT for number of received particles
! 5) Open Receive-Buffer for particle message -> MPI_IRECV
! 6) Send Particles -> MPI_ISEND
!===================================================================================================================================
! MODULES
USE MOD_Globals
USE MOD_Preproc
USE MOD_Particle_MPI_Vars,        ONLY:PartMPI,PartMPIExchange,PartHaloToProc, PartCommSize,tMPIMessage, PartRecvBuf
USE MOD_Particle_Vars,            ONLY:PartState,PartSpecies,usevMPF,PartMPF,PEM,PDM, Pt_temp,Species
USE MOD_DSMC_Vars,                ONLY:useDSMC, CollisMode, DSMC, PartStateIntEn
USE MOD_Particle_Mesh_Vars,       ONLY:GEO
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
! INPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT/OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
INTEGER                       :: iPart,ElemID,iPos,iProc
INTEGER                       :: recv_status_list(1:MPI_STATUS_SIZE,1:PartMPI%nMPINeighbors)
INTEGER                       :: MessageSize, nRecvParticles, nSendParticles
TYPE(tMPIMessage)             :: SendBuf(0:PartMPI%nMPINeighbors)                          
! shape function 
INTEGER, ALLOCATABLE          :: shape_indices(:)
INTEGER                       :: CellX,CellY,CellZ, iPartShape
!===================================================================================================================================

! 1) get number of send particles
PartMPIExchange%nPartsSend=0
DO iPart=1,PDM%ParticleVecLength
  IF(.NOT.PDM%ParticleInside(iPart)) CYCLE
  ElemID=PEM%Element(iPart)
  IF(ElemID.GT.PP_nElems)  PartMPIExchange%nPartsSend(PartHaloToProc(LOCAL_PROC_ID,ElemID))=             &
                                        PartMPIExchange%nPartsSend(PartHaloToProc(LOCAL_PROC_ID,ElemID))+1
END DO ! iPart

! external particles add to same message
! IF(DoExternalParts)THEN
!   ALLOCATE( shape_indices(1:PDM%ParticleVecLength), stat=allocstat)
!   shape_indices(:) = 0
!   iPartShape=1
!   DO iPart=1,PDM%ParticleVecLength
!     IF(PDM%ParticleInside(iPart))THEN
!       IF(ALMOSTZERO(Species(PartSpecies(iPart))%ChargeIC) CYCLE        ! Don't deposite neutral particles!
!       CellX = INT((PartState(iPart,1)-GEO%xminglob)/GEO%FIBGMdeltas(1))+1
!       CellX = MIN(GEO%FIBGMimax,CellX)
!       CellX = MAX(GEO%FIBGMimin,CellX)
!       CellY = INT((PartState(iPart,2)-GEO%yminglob)/GEO%FIBGMdeltas(2))+1
!       CellY = MIN(GEO%FIBGMkmax,CellY)
!       CellY = MAX(GEO%FIBGMkmin,CellY)
!       CellZ = INT((PartState(iPart,3)-GEO%zminglob)/GEO%FIBGMdeltas(3))+1
!       CellZ = MIN(GEO%FIBGMlmax,CellZ)
!       CellZ = MAX(GEO%FIBGMlmin,CellZ)
!       IF(ALLOCATED(GEO%FIBGM(CellX,CellY,CellZ)%ShapeProcs)) THEN
!         IF(GEO%FIBGM(CellX,CellY,CellZ)%ShapeProcs(1) .GT. 0) THEN
!           shape_indices(iPartShape) = i
!           iPartShape = iPartShape + 1
!         END IF
!       END IF
!     END IF ! ParticleInside
!   END DO ! iPart
!   iPartShape = iPartShape - 1
! 
! END IF ! DoExternalParts

! 2) send number of send particles
DO iProc=1,PartMPI%nMPINeighbors
  !IPWRITE(UNIT_stdOut,*) 'Target Number of send particles',PartMPI%MPINeighbor(iProc),PartMPIExchange%nPartsSend(iProc)
  CALL MPI_ISEND( PartMPIExchange%nPartsSend(iProc)                          &
                , 1                                                          &
                , MPI_INTEGER                                                &
                , PartMPI%MPINeighbor(iProc)                                 &
                , 1001                                                       &
                , PartMPI%COMM                                               &
                , PartMPIExchange%SendRequest(1,iProc)                       &
                , IERROR )

!  CALL MPI_ISEND( PartMPIExchange%nPartsSend(iProc)                          &
!                , 1                                                          &
!                , MPI_INTEGER                                                &
!                , PartMPI%MPINeighbor(iProc)                                 &
!                , 1001                                                       &
!                , PartMPI%COMM                                               &
!                , PartMPIExchange%SendRequest(1,PartMPI%MPINeighbor(iProc))  &
!                , IERROR )
END DO ! iProc
!IPWRITE(UNIT_stdOut,*) 'Number of send  particles',   SUM(PartMPIExchange%nPartsSend(:))

! 3) Build Message
DO iProc=1, PartMPI%nMPINeighbors
  ! allocate SendBuf
  nSendParticles=PartMPIExchange%nPartsSend(iProc)
  iPos=0
  IF(nSendParticles.EQ.0) CYCLE
  MessageSize=nSendParticles*PartCommSize
  ALLOCATE(SendBuf(iProc)%content(MessageSize))
  ! fill message
  DO iPart=1,PDM%ParticleVecLength
    IF(.NOT.PDM%ParticleInside(iPart)) CYCLE
    ElemID=PEM%Element(iPart)
    IF(ElemID.GT.PP_nElems) THEN
      !IF(PartHaloToProc(NATIVE_PROC_ID,ElemID).NE.PartMPI%MPINeighbor(iProc))THEN
      IF(PartHaloToProc(LOCAL_PROC_ID,ElemID).NE.iProc) CYCLE
      !iPos=iPos+1
      ! fill content
      SendBuf(iProc)%content(1+iPos:6+iPos) = PartState(iPart,1:6)
      !IPWRITE(UNIT_stdOut,*) ' send state',PartState(iPart,1:6)
      SendBuf(iProc)%content(       7+iPos) = REAL(PartSpecies(iPart))
#if ((PP_TimeDiscMethod==1)||(PP_TimeDiscMethod==2)||(PP_TimeDiscMethod==6))  /* only LSERK */
      SendBuf(iProc)%content(8+iPos:13+iPos) = Pt_temp(iPart,1:6)
      !IPWRITE(UNIT_stdOut,*) ' send pt',SendBuf(iProc)%content(8+iPos:13+iPos)
      SendBuf(iProc)%content(       14+iPos) = REAL(PartHaloToProc(NATIVE_ELEM_ID,ElemID))
      !IF(.NOT.UseLD) THEN   
        IF (useDSMC.AND.(CollisMode.NE.1)) THEN
          IF (usevMPF .AND. DSMC%ElectronicState) THEN
            SendBuf(iProc)%content(15+iPos) = PartStateIntEn(iPart, 1)
            SendBuf(iProc)%content(16+iPos) = PartStateIntEn(iPart, 2)    
            SendBuf(iProc)%content(17+iPos) = PartMPF(iPart)
            SendBuf(iProc)%content(18+iPos) = PartStateIntEn(iPart, 3)
          ELSE IF (usevMPF) THEN
            SendBuf(iProc)%content(15+iPos) = PartStateIntEn(iPart, 1)
            SendBuf(iProc)%content(16+iPos) = PartStateIntEn(iPart, 2)    
            SendBuf(iProc)%content(17+iPos) = PartMPF(iPart)
          ELSE IF ( DSMC%ElectronicState ) THEN
            SendBuf(iProc)%content(15+iPos) = PartStateIntEn(iPart, 1)
            SendBuf(iProc)%content(16+iPos) = PartStateIntEn(iPart, 2)    
            SendBuf(iProc)%content(17+iPos) = PartStateIntEn(iPart, 3)
          ELSE
            SendBuf(iProc)%content(15+iPos) = PartStateIntEn(iPart, 1)
            SendBuf(iProc)%content(16+iPos) = PartStateIntEn(iPart, 2)
          END IF
        ELSE
          IF (usevMPF) THEN
            SendBuf(iProc)%content(15+iPos) = PartMPF(iPart)
          END IF
        END IF
      !ELSE ! UseLD == true      =>      useDSMC == true
      !  IF (CollisMode.NE.1) THEN
      !    IF (usevMPF .AND. DSMC%ElectronicState) THEN
      !      SendBuf(iProc)%content(15+iPos) = PartStateIntEn(iPart, 1)
      !      SendBuf(iProc)%content(16+iPos) = PartStateIntEn(iPart, 2)    
      !      SendBuf(iProc)%content(17+iPos) = PartMPF(iPart)
      !      SendBuf(iProc)%content(18+iPos) = PartStateIntEn(iPart, 3)
      !      SendBuf(iProc)%content(19+iPos:23+iPos) = PartStateBulkValues(iPart,1:5)
      !    ELSE IF (usevMPF) THEN
      !      SendBuf(iProc)%content(15+iPos) = PartStateIntEn(iPart, 1)
      !      SendBuf(iProc)%content(16+iPos) = PartStateIntEn(iPart, 2)    
      !      SendBuf(iProc)%content(17+iPos) = PartMPF(iPart)
      !      SendBuf(iProc)%content(18+iPos:22+iPos) = PartStateBulkValues(iPart,1:5)
      !    ELSE IF ( DSMC%ElectronicState ) THEN
      !      SendBuf(iProc)%content(15+iPos) = PartStateIntEn(iPart, 1)
      !      SendBuf(iProc)%content(16+iPos) = PartStateIntEn(iPart, 2)    
      !      SendBuf(iProc)%content(17+iPos) = PartStateIntEn(iPart, 3)
      !      SendBuf(iProc)%content(18+iPos:22+iPos) = PartStateBulkValues(iPart,1:5)
      !    ELSE
      !      SendBuf(iProc)%content(15+iPos) = PartStateIntEn(iPart, 1)
      !      SendBuf(iProc)%content(16+iPos) = PartStateIntEn(iPart, 2)
      !      SendBuf(iProc)%content(17+iPos:21+iPos) = PartStateBulkValues(iPart,1:5)
      !    END IF
      !  ELSE
      !    IF (usevMPF) THEN
      !      SendBuf(iProc)%content(15+iPos) = PartMPF(iPart)
      !      SendBuf(iProc)%content(16+iPos:20+iPos) = PartStateBulkValues(iPart,1:5)
      !    ELSE
      !      SendBuf(iProc)%content(15+iPos:19+iPos) = PartStateBulkValues(iPart,1:5)
      !    END IF
      !  END IF
      !END IF
#else 
      SendBuf(iProc)%content(    8+iPos) = REAL(PartHaloToProc(NATIVE_ELEM_ID,ElemID))
      !IF(.NOT.UseLD) THEN   
        IF (useDSMC.AND.(CollisMode.NE.1)) THEN
          IF (usevMPF .AND. DSMC%ElectronicState) THEN
            SendBuf(iProc)%content( 9+iPos) = PartStateIntEn(iPart, 1)
            SendBuf(iProc)%content(10+iPos) = PartStateIntEn(iPart, 2)    
            SendBuf(iProc)%content(11+iPos) = PartMPF(iPart)
            SendBuf(iProc)%content(12+iPos) = PartStateIntEn(iPart, 3)
          ELSE IF (usevMPF) THEN
            SendBuf(iProc)%content( 9+iPos) = PartStateIntEn(iPart, 1)
            SendBuf(iProc)%content(10+iPos) = PartStateIntEn(iPart, 2)    
            SendBuf(iProc)%content(11+iPos) = PartMPF(iPart)
          ELSE IF ( DSMC%ElectronicState ) THEN
            SendBuf(iProc)%content( 9+iPos) = PartStateIntEn(iPart, 1)
            SendBuf(iProc)%content(10+iPos) = PartStateIntEn(iPart, 2)    
            SendBuf(iProc)%content(11+iPos) = PartStateIntEn(iPart, 3)
          ELSE
            SendBuf(iProc)%content( 9+iPos) = PartStateIntEn(iPart, 1)
            SendBuf(iProc)%content(10+iPos) = PartStateIntEn(iPart, 2)
          END IF
        ELSE
          IF (usevMPF) THEN
            SendBuf(iProc)%content( 9+iPos) = PartMPF(iPart)
          END IF
        END IF
      !ELSE ! UseLD == true      =>      useDSMC == true
      !  IF (CollisMode.NE.1) THEN
      !    IF (usevMPF .AND. DSMC%ElectronicState) THEN
      !      SendBuf(iProc)%content( 9+iPos) = PartStateIntEn(iPart, 1)
      !      SendBuf(iProc)%content(10+iPos) = PartStateIntEn(iPart, 2)    
      !      SendBuf(iProc)%content(11+iPos) = PartMPF(iPart)
      !      SendBuf(iProc)%content(12+iPos) = PartStateIntEn(iPart, 3)
      !      SendBuf(iProc)%content(13+iPos:17+iPos) = PartStateBulkValues(iPart,1:5)
      !    ELSE IF (usevMPF) THEN
      !      SendBuf(iProc)%content( 9+iPos) = PartStateIntEn(iPart, 1)
      !      SendBuf(iProc)%content(10+iPos) = PartStateIntEn(iPart, 2)    
      !      SendBuf(iProc)%content(11+iPos) = PartMPF(iPart)
      !      SendBuf(iProc)%content(12+iPos:16+iPos) = PartStateBulkValues(iPart,1:5)
      !    ELSE IF ( DSMC%ElectronicState ) THEN
      !      SendBuf(iProc)%content( 9+iPos) = PartStateIntEn(iPart, 1)
      !      SendBuf(iProc)%content(10+iPos) = PartStateIntEn(iPart, 2)    
      !      SendBuf(iProc)%content(11+iPos) = PartStateIntEn(iPart, 3)
      !      SendBuf(iProc)%content(12+iPos:15+iPos) = PartStateBulkValues(iPart,1:5)
      !    ELSE
      !      SendBuf(iProc)%content( 9+iPos) = PartStateIntEn(iPart, 1)
      !      SendBuf(iProc)%content(10+iPos) = PartStateIntEn(iPart, 2)
      !      SendBuf(iProc)%content(11+iPos:15+iPos) = PartStateBulkValues(iPart,1:5)
      !    END IF
      !  ELSE
      !    IF (usevMPF) THEN
      !      SendBuf(iProc)%content( 9+iPos) = PartMPF(iPart)
      !      SendBuf(iProc)%content(10+iPos:14+iPos) = PartStateBulkValues(iPart,1:5)
      !    ELSE
      !      SendBuf(iProc)%content( 9+iPos:13+iPos) = PartStateBulkValues(iPart,1:5)
      !    END IF
      !  END IF
      !END IF
#endif 
      iPos=iPos+PartCommSize
      ! particle is ready for send, now it can deleted
      PDM%ParticleInside(iPart) = .FALSE.  
    END IF ! ElemID is HaloElement
  END DO  ! iPart
END DO ! iProc

! 4) Finish Received number of particles
DO iProc=1,PartMPI%nMPINeighbors
  CALL MPI_WAIT(PartMPIExchange%RecvRequest(1,iProc),recv_status_list(:,iProc),IERROR)
END DO ! iProc

! total number of received particles
PartMPIExchange%nMPIParticles=SUM(PartMPIExchange%nPartsRecv(:))
!IPWRITE(UNIT_stdOut,*) 'Number of received particles',SUM(PartMPIExchange%nPartsRecv(:))


! 5) Allocate received buffer and open MPI_IRECV
DO iProc=1,PartMPI%nMPINeighbors
  nRecvParticles=PartMPIExchange%nPartsRecv(iProc)
  IF(nRecvParticles.EQ.0) CYCLE
  MessageSize=nRecvParticles*PartCommSize
  ALLOCATE(PartRecvBuf(iProc)%content(MessageSize))
  CALL MPI_IRECV( PartRecvBuf(iProc)%content                                 &
                , MessageSize                                                &
                , MPI_DOUBLE_PRECISION                                       &
                , PartMPI%MPINeighbor(iProc)                                 &
                , 1002                                                       &
                , PartMPI%COMM                                               &
                , PartMPIExchange%RecvRequest(2,iProc)                       &
                , IERROR )

!  CALL MPI_IRECV( PartRecvBuf(iProc)%content                                 &
!                , MessageSize                                                &
!                , MPI_DOUBLE_PRECISION                                       &
!                , PartMPI%MPINeighbor(iProc)                                 &
!                , 1002                                                       &
!                , PartMPI%COMM                                               &
!                , PartMPIExchange%RecvRequest(2,PartMPI%MPINeighbor(iProc))  &
!                , IERROR )
END DO ! iProc

! 6) Send Particles
DO iProc=1,PartMPI%nMPINeighbors
  nSendParticles=PartMPIExchange%nPartsSend(iProc)
  IF(nSendParticles.EQ.0) CYCLE
  MessageSize=nSendParticles*PartCommSize
  !ALLOCATE(SendBuf(iProc)%content(PartCommSize,nSendParticles))
  CALL MPI_ISEND( SendBuf(iProc)%content                                     &
                , MessageSize                                                &
                , MPI_DOUBLE_PRECISION                                       &
                , PartMPI%MPINeighbor(iProc)                                 &
                , 1002                                                       &
                , PartMPI%COMM                                               &
                , PartMPIExchange%SendRequest(2,iProc)                       &
                , IERROR )
!  CALL MPI_ISEND( SendBuf(iProc)%content                                     &
!                , MessageSize                                                &
!                , MPI_DOUBLE_PRECISION                                       &
!                , PartMPI%MPINeighbor(iProc)                                 &
!                , 1002                                                       &
!                , PartMPI%COMM                                               &
!                , PartMPIExchange%SendRequest(2,PartMPI%MPINeighbor(iProc))  &
!                , IERROR )
END DO ! iProc

! deallocate send buffer
DO iProc=1,PartMPI%nMPINeighbors
  SDEALLOCATE(SendBuf(iProc)%content)
END DO ! iProc

END SUBROUTINE MPIParticleSend


SUBROUTINE MPIParticleRecv()
!===================================================================================================================================
! this routine sends the particles. Following steps are performed
! 1) Compute number of Send Particles
! 2) Performe MPI_ISEND with number of particles
! 3) Build Message 
! 4) MPI_WAIT for number of received particles
! 5) Open Receive-Buffer for particle message -> MPI_IRECV
! 6) Send Particles -> MPI_ISEND
!===================================================================================================================================
! MODULES
USE MOD_Globals
USE MOD_Preproc
USE MOD_Particle_MPI_Vars,        ONLY:PartMPI,PartMPIExchange,PartHaloToProc, PartCommSize, PartRecvBuf
USE MOD_Particle_Vars,            ONLY:PartState,PartSpecies,usevMPF,PartMPF,PEM,PDM, Pt_temp
USE MOD_DSMC_Vars,                ONLY:useDSMC, CollisMode, DSMC, PartStateIntEn
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
! INPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT/OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
INTEGER                       :: iProc, iPos, nRecv, PartID
INTEGER                       :: recv_status_list(1:MPI_STATUS_SIZE,1:PartMPI%nMPINeighbors)
INTEGER                       :: MessageSize
INTEGER                       :: nRecvParticles
!===================================================================================================================================

!IPWRITE(UNIT_stdOut,*) 'exchange',PartMPIExchange%nMPIParticles

nRecv=0
DO iProc=1,PartMPI%nMPINeighbors
  nRecvParticles=PartMPIExchange%nPartsRecv(iProc)
  IF(nRecvParticles.EQ.0) CYCLE
  MessageSize=nRecvParticles*PartCommSize
  ! finish communication with iproc
  CALL MPI_WAIT(PartMPIExchange%RecvRequest(2,iProc),recv_status_list(:,iProc),IERROR)
  !DO iPos=1,nRecvParticles
  DO iPos=0,MessageSize-1,PartCommSize
    nRecv=nRecv+1
    PartID = PDM%nextFreePosition(nRecv+PDM%CurrentNextFreePosition)
    IF(PartID.EQ.0)  CALL abort(__STAMP__&
          ,' Error in ParticleExchange_parallel. Corrupted list: PIC%nextFreePosition', nRecv)
    PartState(PartID,1:6)   = PartRecvBuf(iProc)%content( 1+iPos: 6+iPos)
    !IPWRITE(UNIT_stdOut,*) ' recv  state',PartState(PartID,1:6)
    PartSpecies(PartID)     = INT(PartRecvBuf(iProc)%content( 7+iPos))
#if ((PP_TimeDiscMethod==1)||(PP_TimeDiscMethod==2)||(PP_TimeDiscMethod==6))  /* RK3 and RK4 only */
    Pt_temp(PartID,1:6)     = PartRecvBuf(iProc)%content( 8+iPos:13+iPos)
    !IPWRITE(UNIT_stdOut,*) ' recv pt',Pt_temp(PartID,1:6)
    PEM%Element(PartID)     = INT(PartRecvBuf(iProc)%content(14+iPos))
    !IF(.NOT.UseLD) THEN
      IF (useDSMC.AND.(CollisMode.NE.1)) THEN
        IF (usevMPF .AND. DSMC%ElectronicState) THEN
          PartStateIntEn(PartID, 1) = PartRecvBuf(iProc)%content(15+iPos)
          PartStateIntEn(PartID, 2) = PartRecvBuf(iProc)%content(16+iPos)
          PartMPF(PartID)           = PartRecvBuf(iProc)%content(17+iPos)
          PartStateIntEn(PartID, 3) = PartRecvBuf(iProc)%content(18+iPos)
        ELSE IF ( usevMPF) THEN
          PartStateIntEn(PartID, 1) = PartRecvBuf(iProc)%content(15+iPos)
          PartStateIntEn(PartID, 2) = PartRecvBuf(iProc)%content(16+iPos)
          PartMPF(PartID)           = PartRecvBuf(iProc)%content(17+iPos)
        ELSE IF ( DSMC%ElectronicState ) THEN
          PartStateIntEn(PartID, 1) = PartRecvBuf(iProc)%content(15+iPos)
          PartStateIntEn(PartID, 2) = PartRecvBuf(iProc)%content(16+iPos)
          PartStateIntEn(PartID, 3) = PartRecvBuf(iProc)%content(17+iPos)
        ELSE
          PartStateIntEn(PartID, 1) = PartRecvBuf(iProc)%content(15+iPos)
          PartStateIntEn(PartID, 2) = PartRecvBuf(iProc)%content(16+iPos)
        END IF
      ELSE
        IF (usevMPF) PartMPF(PartID) = PartRecvBuf(iProc)%content(15+iPos)
      END IF
    !ELSE ! UseLD == true      =>      useDSMC == true
      !IF (CollisMode.NE.1) THEN
        !IF (usevMPF .AND. DSMC%ElectronicState) THEN
          !PartStateIntEn(PartID, 1)       = PartRecvBuf(iProc)%content(15+iPos)
          !PartStateIntEn(PartID, 2)       = PartRecvBuf(iProc)%content(16+iPos)
          !PartMPF(PartID)                 = PartRecvBuf(iProc)%content(17+iPos)
          !PartStateIntEn(PartID, 3)       = PartRecvBuf(iProc)%content(18+iPos)
          !PartStateBulkValues(PartID,1:5) = PartRecvBuf(iProc)%content(19+iPos:23+iPos)
        !ELSE IF ( usevMPF) THEN
          !PartStateIntEn(PartID, 1)       = PartRecvBuf(iProc)%content(15+iPos)
          !PartStateIntEn(PartID, 2)       = PartRecvBuf(iProc)%content(16+iPos)
          !PartMPF(PartID)                 = PartRecvBuf(iProc)%content(17+iPos)
          !PartStateBulkValues(PartID,1:5) = PartRecvBuf(iProc)%content(18+iPos:22+iPos)
        !ELSE IF ( DSMC%ElectronicState ) THEN
          !PartStateIntEn(PartID, 1)       = PartRecvBuf(iProc)%content(15+iPos)
          !PartStateIntEn(PartID, 2)       = PartRecvBuf(iProc)%content(16+iPos)
          !PartStateIntEn(PartID, 3)       = PartRecvBuf(iProc)%content(17+iPos)
          !PartStateBulkValues(PartID,1:5) = PartRecvBuf(iProc)%content(18+iPos:22+iPos)
        !ELSE
          !PartStateIntEn(PartID, 1)       = PartRecvBuf(iProc)%content(15+iPos)
          !PartStateIntEn(PartID, 2)       = PartRecvBuf(iProc)%content(16+iPos)
          !PartStateBulkValues(PartID,1:5) = PartRecvBuf(iProc)%content(17+iPos:21+iPos)
        !END IF
      !ELSE
        !IF (usevMPF) THEN
          !PartMPF(PartID)                 = PartRecvBuf(iProc)%content(15+iPos)
          !PartStateBulkValues(PartID,1:5) = PartRecvBuf(iProc)%content(16+iPos:20+iPos)
        !ELSE
          !PartStateBulkValues(PartID,1:5) = PartRecvBuf(iProc)%content(15+iPos:19+iPos)
        !END IF
      !END IF
    !END IF
#else 
    PEM%Element(PartID)     = INT(PartRecvBuf(iProc)%content(8+iPos))
    !IF(.NOT.UseLD) THEN
      IF (useDSMC.AND.(CollisMode.NE.1)) THEN
        IF (usevMPF .AND. DSMC%ElectronicState) THEN
          PartStateIntEn(PartID, 1) = PartRecvBuf(iProc)%content( 9+iPos)
          PartStateIntEn(PartID, 2) = PartRecvBuf(iProc)%content(10+iPos)
          PartMPF(PartID)           = PartRecvBuf(iProc)%content(11+iPos)
          PartStateIntEn(PartID, 3) = PartRecvBuf(iProc)%content(12+iPos)
        ELSE IF ( usevMPF ) THEN
          PartStateIntEn(PartID, 1) = PartRecvBuf(iProc)%content( 9+iPos)
          PartStateIntEn(PartID, 2) = PartRecvBuf(iProc)%content(10+iPos)
          PartMPF(PartID)           = PartRecvBuf(iProc)%content(11+iPos)
        ELSE IF ( DSMC%ElectronicState) THEN
          PartStateIntEn(PartID, 1) = PartRecvBuf(iProc)%content( 9+iPos)
          PartStateIntEn(PartID, 2) = PartRecvBuf(iProc)%content(10+iPos)
          PartStateIntEn(PartID, 3) = PartRecvBuf(iProc)%content(11+iPos)
        ELSE
          PartStateIntEn(PartID, 1) = PartRecvBuf(iProc)%content( 9+iPos)
          PartStateIntEn(PartID, 2) = PartRecvBuf(iProc)%content(10+iPos)
        END IF
      ELSE
        IF (usevMPF) PartMPF(PartID) = PartRecvBuf(iProc)%content( 9+iPos)
      END IF
    !ELSE ! UseLD == true      =>      useDSMC == true
      !IF (CollisMode.NE.1) THEN
        !IF (usevMPF .AND. DSMC%ElectronicState) THEN
          !PartStateIntEn(PartID, 1)       = PartRecvBuf(iProc)%content( 9+iPos)
          !PartStateIntEn(PartID, 2)       = PartRecvBuf(iProc)%content(10+iPos)
          !PartMPF(PartID)                 = PartRecvBuf(iProc)%content(11+iPos)
          !PartStateIntEn(PartID, 3)       = PartRecvBuf(iProc)%content(12+iPos)
          !PartStateBulkValues(PartID,1:5) = PartRecvBuf(iProc)%content(13+iPos:17+iPos)
        !ELSE IF ( usevMPF) THEN
          !PartStateIntEn(PartID, 1)       = PartRecvBuf(iProc)%content( 9+iPos)
          !PartStateIntEn(PartID, 2)       = PartRecvBuf(iProc)%content(10+iPos)
          !PartMPF(PartID)                 = PartRecvBuf(iProc)%content(11+iPos)
          !PartStateBulkValues(PartID,1:5) = PartRecvBuf(iProc)%content(12+iPos:16+iPos)
        !ELSE IF ( DSMC%ElectronicState ) THEN
          !PartStateIntEn(PartID, 1)       = PartRecvBuf(iProc)%content( 9+iPos)
          !PartStateIntEn(PartID, 2)       = PartRecvBuf(iProc)%content(10+iPos)
          !PartStateIntEn(PartID, 3)       = PartRecvBuf(iProc)%content(11+iPos)
          !PartStateBulkValues(PartID,1:5) = PartRecvBuf(iProc)%content(12+iPos:16+iPos)
        !ELSE
          !PartStateIntEn(PartID, 1)       = PartRecvBuf(iProc)%content( 9+iPos)
          !PartStateIntEn(PartID, 2)       = PartRecvBuf(iProc)%content(10+iPos)
          !PartStateBulkValues(PartID,1:5) = PartRecvBuf(iProc)%content(11+iPos:15+iPos)
        !END IF
      !ELSE
        !IF (usevMPF) THEN
          !PartMPF(PartID)                 = PartRecvBuf(iProc)%content( 9+iPos)
          !PartStateBulkValues(PartID,1:5) = PartRecvBuf(iProc)%content(10+iPos:14+iPos)
        !ELSE
          !PartStateBulkValues(PartID,1:5) = PartRecvBuf(iProc)%content(9+iPos:13+iPos)
        !END IF
      !END IF
    !END IF
#endif
    ! Set Flag for received parts in order to localize them later
    PEM%lastElement(PartID) = -888 
    PDM%ParticleInside(PartID) = .TRUE.
  END DO
  ! be nice: deallocate the receive buffer
  ! deallocate non used array
  DEALLOCATE(PartRecvBuf(iProc)%Content)
END DO ! iProc

PDM%ParticleVecLength       = PDM%ParticleVecLength + PartMPIExchange%nMPIParticles
PDM%CurrentNextFreePosition = PDM%CurrentNextFreePosition + PartMPIExchange%nMPIParticles



END SUBROUTINE MPIParticleRecv


SUBROUTINE FinalizeParticleMPI()
!===================================================================================================================================
! read required parameters
!===================================================================================================================================
! MODULES
USE MOD_Globals
USE MOD_Particle_MPI_Vars
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT/OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
!===================================================================================================================================

ParticleMPIInitIsDone=.FALSE.
SDEALLOCATE( PartMPI%isMPINeighbor)
SDEALLOCATE( PartMPI%MPINeighbor )
SDEALLOCATE( PartMPIExchange%nPartsSend)
SDEALLOCATE( PartMPIExchange%nPartsRecv)
SDEALLOCATE( PartMPIExchange%RecvRequest)
SDEALLOCATE( PartMPIExchange%SendRequest)
END SUBROUTINE FinalizeParticleMPI


SUBROUTINE InitHaloMesh()
!===================================================================================================================================
! communicate all direct neighbor sides from master to slave
! has to be called after GetSideType and MPI_INIT of DG solver
! read required parameters
!===================================================================================================================================
! MODULES
USE MOD_Globals
USE MOD_MPI_Vars
USE MOD_PreProc
USE MOD_Particle_Surfaces_vars,     ONLY:DoRefMapping,BezierControlPoints3D
USE MOD_Particle_Surfaces,          ONLY:GetSlabNormalsAndIntervalls
USE MOD_Mesh_Vars,                  ONLY:NGeo,nSides,SideID_minus_Upper,NGeo
USE MOD_Particle_MPI_Vars,          ONLY:PartMPI,PartHaloToProc
USE MOD_Particle_MPI_Halo,          ONLY:IdentifyHaloMPINeighborhood,ExchangeHaloGeometry,ExchangeMappedHaloGeometry
USE MOD_Particle_Mesh_Vars,         ONLY:nTotalElems
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT/OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
INTEGER                 ::BezierSideSize,SendID, iElem,iSide
INTEGER                 ::iProc,ALLOCSTAT,iMPINeighbor
LOGICAL                 :: TmpNeigh
INTEGER,ALLOCATABLE     ::SideIndex(:),ElemIndex(:)
!===================================================================================================================================

! funny: should not be required, as sides are build for master and slave sides??
! communicate the MPI Master Sides to Slaves
! all processes have now filled sides and can compute the particles inside the proc region
IF(.NOT.DoRefMapping)THEN
  SendID=1
  BezierSideSize=3*(NGeo+1)*(NGeo+1)
  DO iNbProc=1,nNbProcs
    ! Start receive face data
    IF(nMPISides_rec(iNbProc,SendID).GT.0)THEN
      nRecVal     =BezierSideSize*nMPISides_rec(iNbProc,SendID)
      SideID_start=OffsetMPISides_rec(iNbProc-1,SendID)+1
      SideID_end  =OffsetMPISides_rec(iNbProc,SendID)
      CALL MPI_IRECV(BezierControlPoints3D(:,:,:,SideID_start:SideID_end),nRecVal,MPI_DOUBLE_PRECISION,  &
                      nbProc(iNbProc),0,MPI_COMM_WORLD,RecRequest_Flux(iNbProc),iError)
    END IF
    ! Start send face data
    IF(nMPISides_send(iNbProc,SendID).GT.0)THEN
      nSendVal    =BezierSideSize*nMPISides_send(iNbProc,SendID)
      SideID_start=OffsetMPISides_send(iNbProc-1,SendID)+1
      SideID_end  =OffsetMPISides_send(iNbProc,SendID)
      CALL MPI_ISEND(BezierControlPoints3D(:,:,:,SideID_start:SideID_end),nSendVal,MPI_DOUBLE_PRECISION,  &
                      nbProc(iNbProc),0,MPI_COMM_WORLD,SendRequest_Flux(iNbProc),iError)
    END IF
  END DO !iProc=1,nNBProcs
  
  DO iNbProc=1,nNbProcs
    IF(nMPISides_rec(iNbProc,SendID).GT.0) CALL MPI_WAIT(RecRequest_Flux(iNbProc) ,MPIStatus,iError)
  END DO !iProc=1,nNBProcs
  ! Check send operations
  DO iNbProc=1,nNbProcs
    IF(nMPISides_send(iNbProc,SendID).GT.0) CALL MPI_WAIT(SendRequest_Flux(iNbProc),MPIStatus,iError)
  END DO !iProc=1,nNBProcs

  DO iSide=sideID_minus_upper+1,nSides
    CALL GetSlabNormalsAndIntervalls(NGeo,iSide)
  END DO
END IF ! DoRefMapping

ALLOCATE(SideIndex(1:nSides),STAT=ALLOCSTAT)
IF (ALLOCSTAT.NE.0) CALL abort(__STAMP__&
,'  Cannot allocate SideIndex!')
SideIndex=0
ALLOCATE(ElemIndex(1:PP_nElems),STAT=ALLOCSTAT)
IF (ALLOCSTAT.NE.0) CALL abort(__STAMP__&
,'  Cannot allocate ElemIndex!')
ElemIndex=0

! check epsilondistance
DO iProc=0,PartMPI%nProcs-1
  IF(iProc.EQ.PartMPI%MyRank) CYCLE
  LOGWRITE(*,*)'  - Identify non-immediate MPI-Neighborhood...'
  !--- AS: identifies which of my node have to be sent to iProc w.r.t. to 
  !        eps vicinity region.
  CALL IdentifyHaloMPINeighborhood(iProc,SideIndex,ElemIndex)
  LOGWRITE(*,*)'    ...Done'

  LOGWRITE(*,*)'  - Exchange Geometry of MPI-Neighborhood...'
  IF(.NOT.DoRefMapping)THEN
    CALL ExchangeHaloGeometry(iProc,SideIndex,ElemIndex)
  ELSE
    CALL ExchangeMappedHaloGeometry(iProc,SideIndex,ElemIndex)
  END IF
  LOGWRITE(*,*)'    ...Done'
  SideIndex(:)=0
  ElemIndex(:)=0
END DO 
DEALLOCATE(SideIndex,STAT=ALLOCSTAT)
IF (ALLOCSTAT.NE.0) THEN
  CALL abort(__STAMP__,&
                       'Could not deallocate SideIndex')
END IF

! Make sure PMPIVAR%MPINeighbor is consistent
DO iProc=0,PartMPI%nProcs-1
  IF (PartMPI%MyRank.EQ.iProc) CYCLE
  IF (PartMPI%MyRank.LT.iProc) THEN
    CALL MPI_SEND(PartMPI%isMPINeighbor(iProc),1,MPI_LOGICAL,iProc,1101,PartMPI%COMM,IERROR)
    CALL MPI_RECV(TmpNeigh,1,MPI_LOGICAL,iProc,1101,PartMPI%COMM,MPISTATUS,IERROR)
  ELSE IF (PartMPI%MyRank.GT.iProc) THEN
    CALL MPI_RECV(TmpNeigh,1,MPI_LOGICAL,iProc,1101,PartMPI%COMM,MPISTATUS,IERROR)
    CALL MPI_SEND(PartMPI%isMPINeighbor(iProc),1,MPI_LOGICAL,iProc,1101,PartMPI%COMM,IERROR)
  END IF
  !IPWRITE(UNIT_stdOut,*) 'check',tmpneigh,PartMPI%isMPINeighbor(iProc)
  IF (TmpNeigh.NEQV.PartMPI%isMPINeighbor(iProc)) THEN
    WRITE(*,*) 'WARNING: MPINeighbor set to TRUE',PartMPI%MyRank,iProc
    PartMPI%isMPINeighbor(iProc) = .TRUE.
    PartMPI%nMPINeighbors=PartMPI%nMPINeighbors+1
  END IF
END DO


! fill list with neighbor proc id and add local neighbor id to PartHaloToProc
ALLOCATE( PartMPI%MPINeighbor(PartMPI%nMPINeighbors))
iMPINeighbor=0
!CALL MPI_BARRIER(PartMPI%COMM,IERROR)
!IPWRITE(UNIT_stdOut,*) 'PartMPI%nMPINeighbors',PartMPI%nMPINeighbors
!IPWRITE(UNIT_stdOut,*) 'blabla',PartMPI%isMPINeighbor
!CALL MPI_BARRIER(PartMPI%COMM,IERROR)
DO iProc=0,PartMPI%nProcs-1
  IF(PartMPI%isMPINeighbor(iProc))THEN
    iMPINeighbor=iMPINeighbor+1
    PartMPI%MPINeighbor(iMPINeighbor)=iProc
    DO iElem=PP_nElems+1,nTotalElems
      IF(iProc.EQ.PartHaloToProc(NATIVE_PROC_ID,iElem)) PartHaloToProc(LOCAL_PROC_ID,iElem)=iMPINeighbor
    END DO ! iElem
  END IF
END DO
IF(PartMPI%nMPINeighbors.GT.0)THEN
  IF(ANY(PartHaloToProc(LOCAL_PROC_ID,:).EQ.-1)) IPWRITE(UNIT_stdOut,*) ' Local proc id not found'
  IF(MAXVAL(PartHaloToProc(LOCAL_PROC_ID,:)).GT.PartMPI%nMPINeighbors) IPWRITE(UNIT_stdOut,*) ' Local proc id too high.'
END IF
!IPWRITE(UNIT_stdOut,*) ' List Of Neighbor Procs',  PartMPI%nMPINeighbors,PartMPI%MPINeighbor

IF(iMPINeighbor.NE.PartMPI%nMPINeighbors) CALL abort(&
  __STAMP__&
  , ' Found number of mpi neighbors does not match! ', iMPINeighbor,REAL(PartMPI%nMPINeighbors))

!IF(DepositionType.EQ.'shape_function') THEN
!  PMPIVAR%MPINeighbor(PMPIVAR%iProc) = .TRUE.
!ELSE
!  PMPIVAR%MPINeighbor(PMPIVAR%iProc) = .FALSE.
!END IF

!CALL  WriteParticlePartitionInformation()

END SUBROUTINE InitHaloMesh


SUBROUTINE InitEmissionComm()
!===================================================================================================================================
! build emission communicators for particle emission regions
!===================================================================================================================================
! MODULES
USE MOD_Globals
USE MOD_Preproc
USE MOD_Particle_MPI_Vars,      ONLY:PartMPI
USE MOD_Particle_Vars,          ONLY:Species,nSpecies
USE MOD_Particle_Mesh_Vars,     ONLY:GEO
USE MOD_CalcTimeStep,           ONLY: CalcTimeStep
!USE MOD_Particle_Mesh,          ONLY:BoxInProc
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
! INPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT/OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
INTEGER                         :: iSpec,iInit,iNode
INTEGER                         :: nInitRegions
LOGICAL                         :: RegionOnProc
REAL                            :: xCoords(3,8),lineVector(3),radius
REAL                            :: xlen,ylen,zlen
REAL                            :: dt
INTEGER                         :: color,iProc
INTEGER                         :: noInitRank,InitRank,MyInitRank
INTEGER                         :: iRank
LOGICAL                         :: hasRegion
!===================================================================================================================================

! get number of total init regions
nInitRegions=0
DO iSpec=1,nSpecies
  nInitRegions=nInitRegions+Species(iSpec)%NumberOfInits+(1-Species(iSpec)%StartnumberOfInits)
END DO ! iSpec
IF(nInitRegions.EQ.0) RETURN

! allocate communicators
ALLOCATE( PartMPI%InitGroup(1:nInitRegions))

nInitRegions=0
DO iSpec=1,nSpecies
  RegionOnProc=.FALSE.
  DO iInit=Species(iSpec)%StartnumberOfInits, Species(iSpec)%NumberOfInits
    nInitRegions=nInitRegions+1
    SELECT CASE(TRIM(Species(iSpec)%Init(iInit)%SpaceIC))
    CASE ('point')
       xCoords(1:3,1)=Species(iSpec)%Init(iInit)%BasePointIC
       RegionOnProc=PointInProc(xCoords(1:3,1))
    CASE ('line_with_equidistant_distribution')
      xCoords(1:3,1)=Species(iSpec)%Init(iInit)%BasePointIC
      xCoords(1:3,2)=Species(iSpec)%Init(iInit)%BasePointIC+Species(iSpec)%Init(iInit)%BaseVector1IC
      RegionOnProc=BoxInProc(xCoords(1:3,1:2),2)
    CASE ('line')
      xCoords(1:3,1)=Species(iSpec)%Init(iInit)%BasePointIC
      xCoords(1:3,2)=Species(iSpec)%Init(iInit)%BasePointIC+Species(iSpec)%Init(iInit)%BaseVector1IC
      RegionOnProc=BoxInProc(xCoords(1:3,1:2),2)
    CASE('disc')
      xlen=Species(iSpec)%Init(iInit)%RadiusIC * &
           SQRT(1.0 - Species(iSpec)%Init(iInit)%NormalIC(1)*Species(iSpec)%Init(iInit)%NormalIC(1))
      ylen=Species(iSpec)%Init(iInit)%RadiusIC * &
           SQRT(1.0 - Species(iSpec)%Init(iInit)%NormalIC(2)*Species(iSpec)%Init(iInit)%NormalIC(2))
      zlen=Species(iSpec)%Init(iInit)%RadiusIC * &
           SQRT(1.0 - Species(iSpec)%Init(iInit)%NormalIC(3)*Species(iSpec)%Init(iInit)%NormalIC(3))
      ! all 8 edges
      xCoords(1:3,1) = Species(iSpec)%Init(iInit)%BasePointIC+(/-xlen,-ylen,-zlen/)
      xCoords(1:3,2) = Species(iSpec)%Init(iInit)%BasePointIC+(/+xlen,-ylen,-zlen/)
      xCoords(1:3,3) = Species(iSpec)%Init(iInit)%BasePointIC+(/-xlen,+ylen,-zlen/)
      xCoords(1:3,4) = Species(iSpec)%Init(iInit)%BasePointIC+(/+xlen,+ylen,-zlen/)
      xCoords(1:3,5) = Species(iSpec)%Init(iInit)%BasePointIC+(/-xlen,-ylen,+zlen/)
      xCoords(1:3,6) = Species(iSpec)%Init(iInit)%BasePointIC+(/+xlen,-ylen,+zlen/)
      xCoords(1:3,7) = Species(iSpec)%Init(iInit)%BasePointIC+(/-xlen,+ylen,+zlen/)
      xCoords(1:3,8) = Species(iSpec)%Init(iInit)%BasePointIC+(/+xlen,+ylen,+zlen/)
      RegionOnProc=BoxInProc(xCoords(1:3,1:8),8)
    CASE('circle')
      xlen=Species(iSpec)%Init(iInit)%RadiusIC * &
           SQRT(1.0 - Species(iSpec)%Init(iInit)%NormalIC(1)*Species(iSpec)%Init(iInit)%NormalIC(1))
      ylen=Species(iSpec)%Init(iInit)%RadiusIC * &
           SQRT(1.0 - Species(iSpec)%Init(iInit)%NormalIC(2)*Species(iSpec)%Init(iInit)%NormalIC(2))
      zlen=Species(iSpec)%Init(iInit)%RadiusIC * &
           SQRT(1.0 - Species(iSpec)%Init(iInit)%NormalIC(3)*Species(iSpec)%Init(iInit)%NormalIC(3))
      ! all 8 edges
      xCoords(1:3,1) = Species(iSpec)%Init(iInit)%BasePointIC+(/-xlen,-ylen,-zlen/)
      xCoords(1:3,2) = Species(iSpec)%Init(iInit)%BasePointIC+(/+xlen,-ylen,-zlen/)
      xCoords(1:3,3) = Species(iSpec)%Init(iInit)%BasePointIC+(/-xlen,+ylen,-zlen/)
      xCoords(1:3,4) = Species(iSpec)%Init(iInit)%BasePointIC+(/+xlen,+ylen,-zlen/)
      xCoords(1:3,5) = Species(iSpec)%Init(iInit)%BasePointIC+(/-xlen,-ylen,+zlen/)
      xCoords(1:3,6) = Species(iSpec)%Init(iInit)%BasePointIC+(/+xlen,-ylen,+zlen/)
      xCoords(1:3,7) = Species(iSpec)%Init(iInit)%BasePointIC+(/-xlen,+ylen,+zlen/)
      xCoords(1:3,8) = Species(iSpec)%Init(iInit)%BasePointIC+(/+xlen,+ylen,+zlen/)
      RegionOnProc=BoxInProc(xCoords(1:3,1:8),8)
    CASE('gyrotron_circle')
      Radius=Species(iSpec)%Init(iInit)%RadiusIC+Species(iSpec)%Init(iInit)%RadiusICGyro
      xlen=Species(iSpec)%Init(iInit)%RadiusIC * &
           SQRT(1.0 - Species(iSpec)%Init(iInit)%NormalIC(1)*Species(iSpec)%Init(iInit)%NormalIC(1))
      ylen=Species(iSpec)%Init(iInit)%RadiusIC * &
           SQRT(1.0 - Species(iSpec)%Init(iInit)%NormalIC(2)*Species(iSpec)%Init(iInit)%NormalIC(2))
      zlen=Species(iSpec)%Init(iInit)%RadiusIC * &
           SQRT(1.0 - Species(iSpec)%Init(iInit)%NormalIC(3)*Species(iSpec)%Init(iInit)%NormalIC(3))
      IF(Species(iSpec)%Init(iInit)%initialParticleNumber.NE.0)THEN
        lineVector(1:3)=(/0.,0.,Species(iSpec)%Init(iInit)%CuboidHeightIC/)
      ELSE
        dt = CALCTIMESTEP()
        lineVector(1:3)= dt* Species(iSpec)%Init(iInit)%VeloIC/Species(iSpec)%Init(iInit)%alpha 
      END IF
      xCoords(1:3,1) = Species(iSpec)%Init(iInit)%BasePointIC+(/-xlen,-ylen,-zlen/)
      xCoords(1:3,2) = Species(iSpec)%Init(iInit)%BasePointIC+(/+xlen,-ylen,-zlen/)
      xCoords(1:3,3) = Species(iSpec)%Init(iInit)%BasePointIC+(/-xlen,+ylen,-zlen/)
      xCoords(1:3,4) = Species(iSpec)%Init(iInit)%BasePointIC+(/+xlen,+ylen,-zlen/)
      xCoords(1:3,5) = Species(iSpec)%Init(iInit)%BasePointIC+lineVector+(/-xlen,-ylen,+zlen/)
      xCoords(1:3,6) = Species(iSpec)%Init(iInit)%BasePointIC+lineVector+(/+xlen,-ylen,+zlen/)
      xCoords(1:3,7) = Species(iSpec)%Init(iInit)%BasePointIC+lineVector+(/-xlen,+ylen,+zlen/)
      xCoords(1:3,8) = Species(iSpec)%Init(iInit)%BasePointIC+lineVector+(/+xlen,+ylen,+zlen/)
      RegionOnProc=BoxInProc(xCoords(1:3,1:8),8)
    CASE('circle_equidistant')
      CALL abort(__STAMP__,&
          'not implemented')
    CASE('cuboid')
      lineVector(1) = Species(iSpec)%Init(iInit)%BaseVector1IC(2) * Species(iSpec)%Init(iInit)%BaseVector2IC(3) - &
        Species(iSpec)%Init(iInit)%BaseVector1IC(3) * Species(iSpec)%Init(iInit)%BaseVector2IC(2)
      lineVector(2) = Species(iSpec)%Init(iInit)%BaseVector1IC(3) * Species(iSpec)%Init(iInit)%BaseVector2IC(1) - &
        Species(iSpec)%Init(iInit)%BaseVector1IC(1) * Species(iSpec)%Init(iInit)%BaseVector2IC(3)
      lineVector(3) = Species(iSpec)%Init(iInit)%BaseVector1IC(1) * Species(iSpec)%Init(iInit)%BaseVector2IC(2) - &
        Species(iSpec)%Init(iInit)%BaseVector1IC(2) * Species(iSpec)%Init(iInit)%BaseVector2IC(1)
      IF ((lineVector(1).eq.0).AND.(lineVector(2).eq.0).AND.(lineVector(3).eq.0)) THEN
         CALL abort(__STAMP__,&
           'BaseVectors are parallel!')
      ELSE
        lineVector = lineVector / SQRT(lineVector(1) * lineVector(1) + lineVector(2) * lineVector(2) + &
          lineVector(3) * lineVector(3))
      END IF
      xCoords(1:3,1)=Species(iSpec)%Init(iInit)%BasePointIC
      xCoords(1:3,2)=Species(iSpec)%Init(iInit)%BasePointIC+Species(iSpec)%Init(iInit)%BaseVector1IC
      xCoords(1:3,3)=Species(iSpec)%Init(iInit)%BasePointIC+Species(iSpec)%Init(iInit)%BaseVector2IC
      xCoords(1:3,4)=Species(iSpec)%Init(iInit)%BasePointIC+Species(iSpec)%Init(iInit)%BaseVector1IC&
                                                           +Species(iSpec)%Init(iInit)%BaseVector2IC

      DO iNode=1,4
        xCoords(1:3,iNode+4)=xCoords(1:3,iNode)+lineVector
      END DO ! iNode
      RegionOnProc=BoxInProc(xCoords,8)
    CASE('cylinder')
      CALL abort(__STAMP__,&
          'not implemented')
    CASE('cuboid_vpi')
      CALL abort(__STAMP__,&
          'not implemented')
    CASE('cylinder_vpi')
      CALL abort(__STAMP__,&
          'not implemented')
!    CASE('LD_insert')
!      CALL LD_SetParticlePosition(chunkSize,particle_positions_Temp,iSpec,iInit)
!      DEALLOCATE( particle_positions, STAT=allocStat )
!      IF (allocStat .NE. 0) THEN
!        CALL abort(__STAMP__,&
!          'ERROR in ParticleEmission_parallel: cannot deallocate particle_positions!')
!      END IF
!      ALLOCATE(particle_positions(3*chunkSize))
!      particle_positions(1:3*chunkSize) = particle_positions_Temp(1:3*chunkSize)
!      DEALLOCATE( particle_positions_Temp, STAT=allocStat )
!      IF (allocStat .NE. 0) THEN
!        CALL abort(__STAMP__,&
!          'ERROR in ParticleEmission_parallel: cannot deallocate particle_positions!')
!      END IF
    CASE('cuboid_equal')
      CALL abort(__STAMP__,&
          'ERROR in ParticleEmission_parallel: cannot deallocate particle_positions!')
    CASE ('cuboid_with_equidistant_distribution') 
       xlen = SQRT(Species(iSpec)%Init(iInit)%BaseVector1IC(1)**2 &
            + Species(iSpec)%Init(iInit)%BaseVector1IC(2)**2 &
            + Species(iSpec)%Init(iInit)%BaseVector1IC(3)**2 )
       ylen = SQRT(Species(iSpec)%Init(iInit)%BaseVector2IC(1)**2 &
            + Species(iSpec)%Init(iInit)%BaseVector2IC(2)**2 &
            + Species(iSpec)%Init(iInit)%BaseVector2IC(3)**2 )
       zlen = ABS(Species(iSpec)%Init(iInit)%CuboidHeightIC)

       ! make sure the vectors correspond to x,y,z-dir
       IF ((xlen.NE.Species(iSpec)%Init(iInit)%BaseVector1IC(1)).OR. &
           (ylen.NE.Species(iSpec)%Init(iInit)%BaseVector2IC(2)).OR. &
           (zlen.NE.Species(iSpec)%Init(iInit)%CuboidHeightIC)) THEN
          CALL abort(__STAMP__,&
            'Basevectors1IC,-2IC and CuboidHeightIC have to be in x,y,z-direction, respectively for emission condition')
       END IF
       DO iNode=1,8
        xCoords(1:3,iNode) = Species(iSpec)%Init(iInit)%BasePointIC(1:3)
       END DO
       xCoords(1,2)   = xCoords(1,1) + xlen
       xCoords(2,3)   = xCoords(2,1) + ylen
       xCoords(1,4)   = xCoords(1,1) + xlen
       xCoords(2,4)   = xCoords(2,1) + ylen
       xCoords(3,5)   = xCoords(3,1) + zlen
       xCoords(1,6)   = xCoords(1,5) + xlen
       xCoords(2,7)   = xCoords(2,5) + ylen
       xCoords(1,8)   = xCoords(1,5) + xlen
       xCoords(2,8)   = xCoords(2,5) + ylen
       RegionOnProc=BoxInProc(xCoords,8)
    CASE('sin_deviation')
       IF(Species(iSpec)%Init(iInit)%initialParticleNumber.NE. &
            (Species(iSpec)%Init(iInit)%maxParticleNumberX * Species(iSpec)%Init(iInit)%maxParticleNumberY &
            * Species(iSpec)%Init(iInit)%maxParticleNumberZ)) THEN
         SWRITE(*,*) 'for species ',iSpec,' does not match number of particles in each direction!'
         CALL abort(__STAMP__,&
            'ERROR: Number of particles in init / emission region',iInit)
       END IF
       xlen = abs(GEO%xmaxglob  - GEO%xminglob)  
       ylen = abs(GEO%ymaxglob  - GEO%yminglob)
       zlen = abs(GEO%zmaxglob  - GEO%zminglob)
       xCoords(1:3,1) = (/GEO%xminglob,GEO%yminglob,GEO%zminglob/)
       xCoords(1,2)   = xCoords(1,1) + xlen
       xCoords(2,3)   = xCoords(2,1) + ylen
       xCoords(1,4)   = xCoords(1,1) + xlen
       xCoords(2,4)   = xCoords(2,1) + ylen
       xCoords(3,5)   = xCoords(3,1) + zlen
       xCoords(1,6)   = xCoords(1,5) + xlen
       xCoords(2,7)   = xCoords(2,5) + ylen
       xCoords(1,8)   = xCoords(1,5) + xlen
       xCoords(2,8)   = xCoords(2,5) + ylen
       RegionOnProc=BoxInProc(xCoords,8)
    CASE DEFAULT
      CALL abort(__STAMP__,&
          'not implemented')
    END SELECT
    ! create new communicator
    color=MPI_UNDEFINED
    !IPWRITE(UNIT_stdOut,*) RegionOnProc
    IF(RegionOnProc) color=nInitRegions!+1
    ! set communicator id
    Species(iSpec)%Init(iInit)%InitComm=nInitRegions

    ! create ranks for RP communicator
    IF(PartMPI%MPIRoot) THEN
      InitRank=-1
      noInitRank=-1
      !myRPRank=0
      iRank=0
      PartMPI%InitGroup(nInitRegions)%MyRank=0
      IF(RegionOnProc) THEN
        InitRank=0
      ELSE 
        noInitRank=0
      END IF
      DO iProc=1,PartMPI%nProcs-1
        CALL MPI_RECV(hasRegion,1,MPI_LOGICAL,iProc,0,PartMPI%COMM,MPIstatus,iError)
        IF(hasRegion) THEN
          InitRank=InitRank+1
          CALL MPI_SEND(InitRank,1,MPI_INTEGER,iProc,0,PartMPI%COMM,iError)
        ELSE
          noInitRank=noInitRank+1
          CALL MPI_SEND(noInitRank,1,MPI_INTEGER,iProc,0,PartMPI%COMM,iError)
        END IF
      END DO
    ELSE
      CALL MPI_SEND(RegionOnProc,1,MPI_LOGICAL,0,0,PartMPI%COMM,iError)
      CALL MPI_RECV(PartMPI%InitGroup(nInitRegions)%MyRank,1,MPI_INTEGER,0,0,PartMPI%COMM,MPIstatus,iError)
    END IF

    ! create new emission communicator
!    IPWRITE(UNIT_stdOut,*) 'color',color
!    SWRITE(*,*) 'comm null',MPI_COMM_NULL
    CALL MPI_COMM_SPLIT(PartMPI%COMM, color, PartMPI%InitGroup(nInitRegions)%MyRank, PartMPI%InitGroup(nInitRegions)%COMM,iError)
    IF(RegionOnProc) CALL MPI_COMM_SIZE(PartMPI%InitGroup(nInitRegions)%COMM,PartMPI%InitGroup(nInitRegions)%nProcs ,iError)
!    IPWRITE(UNIT_stdOut,*) 'loc rank',PartMPI%InitGroup(nInitRegions)%MyRank
!    IPWRITE(UNIT_stdOut,*) 'loc comm',PartMPI%InitGroup(nInitRegions)%COMM
    IF(PartMPI%InitGroup(nInitRegions)%MyRank.EQ.0 .AND. RegionOnProc) &
    WRITE(*,*) ' Emission-Region,Emission-Communicator:',nInitRegions,PartMPI%InitGroup(nInitRegions)%nProcs,' procs'
    IF(PartMPI%InitGroup(nInitRegions)%COMM.NE.MPI_COMM_NULL) THEN
      IF(PartMPI%InitGroup(nInitRegions)%MyRank.EQ.0) THEN
        PartMPI%InitGroup(nInitRegions)%MPIRoot=.TRUE.
      ELSE
        PartMPI%InitGroup(nInitRegions)%MPIRoot=.FALSE.
      END IF
    END IF
  END DO ! iniT
END DO ! iSpec

END SUBROUTINE InitEmissionComm


FUNCTION BoxInProc(CartNodes,nNodes)
!===================================================================================================================================
! check if bounding box is on proc
!===================================================================================================================================
! MODULES
USE MOD_Particle_Mesh_Vars,       ONLY:GEO
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
REAL,INTENT(IN)   :: CartNodes(1:3,1:nNodes)
INTEGER,INTENT(IN):: nNodes
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
LOGICAL           :: BoxInProc
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
INTEGER           :: xmin,xmax,ymin,ymax,zmin,zmax,testval
!===================================================================================================================================

BoxInProc=.FALSE.
! get background of nodes
xmin=HUGE(1)
xmax=-HUGE(1)
ymin=HUGE(1)
ymax=-HUGE(1)
zmin=HUGE(1)
zmax=-HUGE(1)
testval = CEILING((MINVAL(CartNodes(1,:))-GEO%xminglob)/GEO%FIBGMdeltas(1)) 
xmin    = MIN(xmin,testval)
testval = CEILING((MAXVAL(CartNodes(1,:))-GEO%xminglob)/GEO%FIBGMdeltas(1)) 
xmax    = MAX(xmax,testval)
testval = CEILING((MINVAL(CartNodes(2,:))-GEO%yminglob)/GEO%FIBGMdeltas(2)) 
ymin    = MIN(ymin,testval)
testval = CEILING((MAXVAL(CartNodes(2,:))-GEO%yminglob)/GEO%FIBGMdeltas(2)) 
ymax    = MAX(ymax,testval)
testval = CEILING((MINVAL(CartNodes(3,:))-GEO%zminglob)/GEO%FIBGMdeltas(3)) 
zmin    = MIN(zmin,testval)
testval = CEILING((MAXVAL(CartNodes(3,:))-GEO%zminglob)/GEO%FIBGMdeltas(3)) 
zmax    = MAX(zmax,testval)

IF(    ((xmin.LE.GEO%FIBGMimax).AND.(xmax.GE.GEO%FIBGMimin)) &
  .AND.((ymin.LE.GEO%FIBGMjmax).AND.(ymax.GE.GEO%FIBGMjmin)) &
  .AND.((zmin.LE.GEO%FIBGMkmax).AND.(zmax.GE.GEO%FIBGMkmin)) ) BoxInProc=.TRUE.

END FUNCTION BoxInProc


FUNCTION PointInProc(CartNode)
!===================================================================================================================================
! check if point is on proc
!===================================================================================================================================
! MODULES
USE MOD_Particle_Mesh_Vars,       ONLY:GEO
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
REAL,INTENT(IN)   :: CartNode(1:3)
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
LOGICAL           :: PointInProc
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
INTEGER           :: xmin,xmax,ymin,ymax,zmin,zmax,testval
!===================================================================================================================================

PointInProc=.FALSE.
! get background of nodes
xmin=HUGE(1)
xmax=-HUGE(1)
ymin=HUGE(1)
ymax=-HUGE(1)
zmin=HUGE(1)
zmax=-HUGE(1)
testval = CEILING((CartNode(1)-GEO%xminglob)/GEO%FIBGMdeltas(1)) 
xmin    = MIN(xmin,testval)
testval = CEILING((CartNode(1)-GEO%xminglob)/GEO%FIBGMdeltas(1)) 
xmax    = MAX(xmax,testval)
testval = CEILING((CartNode(2)-GEO%yminglob)/GEO%FIBGMdeltas(2)) 
ymin    = MIN(ymin,testval)
testval = CEILING((CartNode(2)-GEO%yminglob)/GEO%FIBGMdeltas(2)) 
ymax    = MAX(ymax,testval)
testval = CEILING((CartNode(3)-GEO%zminglob)/GEO%FIBGMdeltas(3)) 
zmin    = MIN(zmin,testval)
testval = CEILING((CartNode(3)-GEO%zminglob)/GEO%FIBGMdeltas(3)) 
zmax    = MAX(zmax,testval)

IF(    ((xmin.LE.GEO%FIBGMimax).AND.(xmax.GE.GEO%FIBGMimin)) &
  .AND.((ymin.LE.GEO%FIBGMjmax).AND.(ymax.GE.GEO%FIBGMjmin)) &
  .AND.((zmin.LE.GEO%FIBGMkmax).AND.(zmax.GE.GEO%FIBGMkmin)) ) PointInProc=.TRUE.

END FUNCTION PointInProc
#endif /*MPI*/

END MODULE MOD_Particle_MPI
