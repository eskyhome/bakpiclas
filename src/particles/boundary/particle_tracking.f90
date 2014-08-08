#include "boltzplatz.h"

MODULE MOD_Particle_Tracking
!===================================================================================================================================
! Contains global variables provided by the particle surfaces routines
!===================================================================================================================================
! MODULES
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
PUBLIC

INTERFACE ParticleTracking
  MODULE PROCEDURE ParticleTracking
END INTERFACE

PUBLIC::ParticleTracking
!-----------------------------------------------------------------------------------------------------------------------------------
!-----------------------------------------------------------------------------------------------------------------------------------
!===================================================================================================================================

CONTAINS

SUBROUTINE ParticleTracking()
!===================================================================================================================================
! read required parameters
!===================================================================================================================================
! MODULES
USE MOD_Globals,                     ONLY:abort
USE MOD_Mesh_Vars,                   ONLY:ElemToSide,nBCSides
USE MOD_Particle_Vars,               ONLY:PEM,PDM
USE MOD_Particle_Vars,               ONLY:PartState,LastPartPos
USE MOD_Particle_Surfaces_Vars,      ONLY:epsilontol,SideIsPlanar,epsilonOne,neighborElemID,neighborlocSideID,epsilonbilinear
USE MOD_Particle_Surfaces_Vars,      ONLY:nPartCurved, SuperSampledNodes,nQuads
!USE MOD_Particle_Boundary_Condition, ONLY:GetBoundaryInteraction
USE MOD_Particle_Boundary_Condition, ONLY:GetBoundaryInteractionSuperSampled
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
! INPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT/OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
INTEGER                       :: iPart,ElemID
INTEGER                       :: ilocSide,SideID,flip
INTEGER                       :: iInterSect,nInter
INTEGER                       :: p,q,QuadID,iQuad,minQuadID,maxQuadID
LOGICAL                       :: PartisDone,dolocSide(1:6)
!REAL                          :: alpha(1:6),xietaIntersect(1:2,1:6)
REAL                          :: alpha,xi,eta!xietaIntersect(1:2,1:6)
REAL                          :: alpha_loc(1:nQuads),xi_loc(1:nQuads),eta_loc(1:nQuads)
REAL                          :: xNodes(1:3,4),Displacement,xdisplace(1:3)
REAL                          :: PartTrajectory(1:3)
!===================================================================================================================================

!print*,'ici'
!read*
DO iPart=1,PDM%ParticleVecLength
  IF(PDM%ParticleInside(iPart))THEN
    PartisDone=.FALSE.
    ElemID = PEM%lastElement(iPart)
!    print*,'ElemID','new RK',ElemID
!    print*,'lastpos',LastPartPos(iPart,1:3)
    PartTrajectory=PartState(iPart,1:3) - LastPartPos(iPart,1:3)
!    print*,'PartTrajectory',PartTrajectory
!    read*
    ! track particle vector until the final particle position is achieved
    dolocSide=.TRUE.
    DO WHILE (.NOT.PartisDone)
      DO ilocSide=1,6
        alpha_loc=-1.0
        IF(.NOT.dolocSide(ilocSide)) CYCLE
        SideID=ElemToSide(E2S_SIDE_ID,ilocSide,ElemID) 
        flip  =ElemToSide(E2S_FLIP,ilocSide,ElemID)
        QuadID=0
        ! supersampling of each side
        DO q=0,NPartCurved-1
          DO p=0,NPartCurved-1
            QuadID=QuadID+1
            xNodes(:,1)=SuperSampledNodes(1:3,p  ,q  ,SideID)
            xNodes(:,2)=SuperSampledNodes(1:3,p+1,q  ,SideID)
            xNodes(:,3)=SuperSampledNodes(1:3,p+1,q+1,SideID)
            xNodes(:,4)=SuperSampledNodes(1:3,p  ,q+1,SideID)
            ! compute displacement || decision between planar or bi-linear plane 
            xdisplace(1:3) = xNodes(:,1)-xNodes(:,2)+xNodes(:,3)-xNodes(:,4)
            Displacement = xdisplace(1)*xdisplace(1)+xdisplace(2)*xdisplace(2)+xdisplace(3)*xdisplace(3)
            !print*,displacement
            IF(Displacement.LT.epsilonbilinear)THEN
!              CALL ComputePlanarIntersectionSuperSampled(xNodes,PartTrajectory &
!                                                         ,alpha_loc(QuadID),xi_loc(QuadID),eta_loc(QuadID),iPart)

              CALL ComputePlanarIntersectionSuperSampled(xNodes,PartTrajectory &
                                                         ,alpha_loc(QuadID),xi_loc(QuadID),eta_loc(QuadID),flip,iPart)
            ELSE
!           print*, CALL abort(__STAMP__,&
!                ' flip missing!!! ',999,999.)

              CALL ComputeBiLinearIntersectionSuperSampled(xNodes,PartTrajectory &
                                                          ,alpha_loc(QuadID),xi_loc(QuadID),eta_loc(QuadID),iPart,SideID)
            END IF
          END DO ! p
        END DO ! q
        ! get correct intersection
        IF(SideID.LE.nBCSides)THEN
          alpha=10.0
          minQuadID=10
          ! get smallest alpha
          DO iQuad=1,nQuads
            IF(alpha_loc(iQuad).GT.epsilontol)THEN
              IF(alpha.GT.alpha_loc(iQuad))THEN
                alpha=alpha_loc(iQuad)
                minQuadID=iQuad
              END IF ! alpha.GT.alpha_loc
            END IF ! alpha_loc.GT.espilontol
          END DO ! iQuad
          ! check if interesction is possible and take first intersection
          !print*,alpha,minQuadID
!          read*
          IF(alpha.GT.epsilontol.AND.alpha.LT.epsilonOne)THEN
!            xi=xi_loc(minQuadID)
!            eta=eta_loc(minQuadID)
!            QuadID=minQuadID
            print*,'Boundary interaction implemented for new method'
            print*,'Side',SideID
            print*,'oldstate',PartState(iPart,1:3)
            CALL GetBoundaryInteractionSuperSampled(PartTrajectory,alpha,xi_loc(minQuadID),eta_loc(minQuadID),&
                                                                                            iPart,QuadID,SideID,ElemID)
!            CALL abort(__STAMP__,&
!                ' Boundary interaction not implemented for new method.',999,999.)
            print*,'newState',PartState(iPart,1:3)
            print*,'newTrajectory',PartTrajectory
!            read*
             EXIT
          ELSE ! no intersection
            alpha=-1.0
          END IF
        ELSE ! no BC Side
          ! search max alpha
          alpha=-10
          maxQuadID=-1
          nInter=0
          ! get largest possible intersection
          DO iQuad=1,nQuads
            IF(alpha_loc(iQuad).GT.alpha)THEN
              alpha=alpha_loc(iQuad)
              maxQuadID=iQuad
            END IF
            IF(alpha_loc(iQuad).GT.epsilontol)THEN
              nInter=nInter+1
            END IF
          END DO ! iQuad
          IF(MOD(nInter,2).EQ.0) alpha=-1.0
          IF(alpha.GT.epsilontol)THEN
!             print*,'next elem'
!             print*,'alpha',alpha
             xi=xi_loc(maxQuadID) 
             eta=eta_loc(maxQuadID)
             ! check if the found alpha statisfy the selection condition
             iInterSect=INT((ABS(xi)-2*epsilontol)/1.0)+INT((ABS(eta)-2*epsilontol)/1.0)
             IF(iInterSect.GT.0)THEN
               CALL abort(__STAMP__,&
                   ' Particle went through edge or node. Not implemented yet.',999,999.)
             ELSE
               dolocSide=.TRUE.
               dolocSide(neighborlocSideID(ilocSide,ElemID))=.FALSE.
               ElemID=neighborElemID(ilocSide,ElemID)
!               print*,'new elem id',ElemID
               !print*,'new particle positon',ElemID
  !             CALL abort(__STAMP__,&
  !                 ' Particle mapping to neighbor elem not verified!',999,999.)
               EXIT
             END IF ! possible intersect
           ELSE
             alpha=-1.0
           END IF ! alpha.GT.epsilontol
        END IF ! SideID.LT.nBCSides
      END DO ! ilocSide
      ! no intersection found
      IF(alpha.EQ.-1.0)THEN
        PEM%Element(iPart) = ElemID
        PartisDone=.TRUE.
      END IF
    END DO ! PartisDone=.FALSE.
  END IF ! Part inside
END DO ! iPart

END SUBROUTINE ParticleTracking


!SUBROUTINE ParticleTrackinglin()
!===================================================================================================================================
!! read required parameters
!===================================================================================================================================
!! MODULES
!USE MOD_Globals,                     ONLY:abort
!USE MOD_Mesh_Vars,                   ONLY:ElemToSide,nBCSides
!USE MOD_Particle_Vars,               ONLY:PEM,PDM
!USE MOD_Particle_Vars,               ONLY:PartState,LastPartPos
!USE MOD_Particle_Surfaces_Vars,      ONLY:epsilontol,SideIsPlanar,epsilonOne,neighborElemID,neighborlocSideID
!USE MOD_Particle_Boundary_Condition, ONLY:GetBoundaryInteraction
!! IMPLICIT VARIABLE HANDLING
!IMPLICIT NONE
! INPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT/OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
!! LOCAL VARIABLES
!INTEGER                       :: iPart,ElemID
!INTEGER                       :: ilocSide,SideID
!INTEGER                       :: iInterSect
!LOGICAL                       :: PartisDone,dolocSide(1:6)
!!REAL                          :: alpha(1:6),xietaIntersect(1:2,1:6)
!REAL                          :: alpha,xi,eta!xietaIntersect(1:2,1:6)
!REAL                          :: PartTrajectory(1:3)
!===================================================================================================================================
!
!DO iPart=1,PDM%ParticleVecLength
!  IF(PDM%ParticleInside(iPart))THEN
!    PartisDone=.FALSE.
!    ElemID = PEM%lastElement(iPart)
!   !Element = PEM%lastElement(i)
!    print*,ElemID
!    PartTrajectory=PartState(iPart,1:3) - LastPartPos(iPart,1:3)
!    ! track particle vector until the final particle position is achieved
!    alpha=-1.
!    dolocSide=.TRUE.
!    DO WHILE (.NOT.PartisDone)
!      DO ilocSide=1,6
!        IF(.NOT.dolocSide(ilocSide)) CYCLE
!        SideID=ElemToSide(E2S_SIDE_ID,ilocSide,ElemID) 
!        IF(SideIsPlanar(SideID))THEN
!          !CALL ComputePlanarIntersection(PartTrajectory,iPart,SideID,ElemID,alpha,xietaIntersect(1,ilocSide) &
!          !                              ,XiEtaIntersect(2,ilocSide))
!          CALL ComputePlanarIntersection(PartTrajectory,alpha,xi,eta,iPart,SideID)
!        ELSE
!          CALL ComputeBiLinearIntersection(PartTrajectory,alpha,xi,eta,iPart,SideID)
!          !CALL ComputeBiLinearIntersection(PartTrajectory,iPart,SideID,ElemID,alpha,xietaIntersect(1,ilocSide) &
!          !                              ,XiEtaIntersect(2,ilocSide))
!        END IF
!        !print*,ilocSide,alpha
!        !print*,'ilocSide,alpha,xi,eta',ilocSide,alpha,xi,eta
!        !print*,'neighborElemID',neighborElemID(ilocSide,ElemID)
!        ! check after each side if particle went through checked side
!        IF(alpha.GT.epsilontol)THEN ! or minus epsilontol
!          !IF(alpha+epsilontol.GE.epsilonOne) PartisDone=.TRUE.
!          IF(SideID.LE.nBCSides)THEN
!            print*,'Boundary interaction implemented for new method'
!            CALL GetBoundaryInteraction(PartTrajectory,alpha,xi,eta,iPart,SideID,ElemID)
!            !CALL abort(__STAMP__,&
!                !' Boundary interaction not implemented for new method.',999,999.)
!          END IF
!          iInterSect=INT((ABS(xi)-epsilontol)/1.0)+INT((ABS(eta)-epsilontol)/1.0)
!          IF(iInterSect.GT.0)THEN
!            CALL abort(__STAMP__,&
!                ' Particle went through edge or node. Not implemented yet.',999,999.)
!          ELSE
!            dolocSide=.TRUE.
!            dolocSide(neighborlocSideID(ilocSide,ElemID))=.FALSE.
!            ElemID=neighborElemID(ilocSide,ElemID)
!            !print*,'new particle positon',ElemID
!!            CALL abort(__STAMP__,&
!!                ' Particle mapping to neighbor elem not verified!',999,999.)
!            EXIT
!          END IF ! iInteSect
!        END IF
!      END DO ! ilocSide
!      !sop
!      !read*
!      ! no intersection found
!      IF(alpha.EQ.-1.0)THEN
!        PEM%Element(iPart) = ElemID
!        PartisDone=.TRUE.
!      END IF
!    END DO ! PartisDone=.FALSE.
!  END IF ! Part inside
!END DO ! iPart
!
!END SUBROUTINE ParticleTracking

!SUBROUTINE ComputePlanarIntersection(PartTrajectory,alpha,xi,eta,iPart,SideID)
!==================================================================================================================================
!! Compute the Intersection with planar surface
!==================================================================================================================================
!! MODULES
!USE MOD_Particle_Vars,           ONLY:LastPartPos
!USE MOD_Particle_Surfaces_Vars,  ONLY:epsilonbilinear,BiLinearCoeff, SideNormVec,epsilontol,SideDistance,epsilonOne
!!USE MOD_Particle_Surfaces_Vars,  ONLY:epsilonOne,SideIsPlanar,BiLinearCoeff,SideNormVec
!! IMPLICIT VARIABLE HANDLING
!IMPLICIT NONE
!! INPUT VARIABLES
!!----------------------------------------------------------------------------------------------------------------------------------
!! INPUT VARIABLES
!REAL,INTENT(IN),DIMENSION(1:3)    :: PartTrajectory
!INTEGER,INTENT(IN)                :: iPart,SideID!,ElemID
!!----------------------------------------------------------------------------------------------------------------------------------
!! OUTPUT VARIABLES
!REAL,INTENT(OUT)                  :: alpha,xi,eta
!!----------------------------------------------------------------------------------------------------------------------------------
!! LOCAL VARIABLES
!REAL                              :: coeffA,coeffB,xInter(3)
!REAL                              :: Axz, Bxz, Cxz
!REAL                              :: Ayz, Byz, Cyz
!==================================================================================================================================
!
!! set alpha to minus 1, asume no intersection
!alpha=-1.0
!xi=-2.
!eta=-2.
!
!! check if the particle can intersect with the planar plane
!! if the normVec point in the opposite direction, cycle
!coeffA=DOT_PRODUCT(SideNormVec(1:3,SideID),PartTrajectory)
!!print*,'coeffA',coeffA
!IF(ABS(coeffA).LT.+epsilontol)THEN
!  ! particle tangential to surface ==> no interesection, particle remains in element
!  RETURN
!END IF
!
!! distance of plane fromn origion minus trajectory start point times normal vector of side
!coeffB=SideDistance(SideID)-DOT_PRODUCT(SideNormVec(1:3,SideID),LastPartPos(iPart,1:3))
!
!alpha=coeffB/coeffA
!!print*,'coeffB',coeffB
!!print*,'alpha',alpha
!!read*
!
!IF((alpha.GT.epsilonOne).OR.(alpha.LT.epsilontol))THEN
!  alpha=-1.0
!  RETURN
!END IF
!
!! compute intersection
!xInter(1:3) =LastPartPos(iPart,1:3)+alpha*PartTrajectory(1:3)
!
!!! theoretically, can be computed in advance
!Axz = BiLinearCoeff(1,2,SideID) - BiLinearCoeff(3,2,SideID)
!Bxz = BiLinearCoeff(1,3,SideID) - BiLinearCoeff(3,3,SideID)
!Cxz = xInter(1) - BiLinearCoeff(1,4,SideID) - xInter(3) + BiLinearCoeff(3,4,SideID)
!
!Ayz = BiLinearCoeff(2,2,SideID) - BiLinearCoeff(3,2,SideID)
!Byz = BiLinearCoeff(2,3,SideID) - BiLinearCoeff(3,3,SideID)
!Cyz = xInter(2) - BiLinearCoeff(2,4,SideID) - xInter(3) + BiLinearCoeff(3,4,SideID)
!
!print*,'Bxz,Byz',Bxz,Byz
!
!IF(ABS(Bxz).LT.epsilontol)THEN
!  xi = Axz + Bxz*Ayz/Byz
!  ! check denominator
!  xi = (Cxz - Bxz*Ayz/Byz*Cyz)/xi
!ELSE
!  xi = Ayz + Byz*Axz/Bxz
!  ! check denominator
!  xi = (Cyz - Byz*Axz/Bxz*Cxz)/xi
!END IF
!
!IF(ABS(xi).GT.epsilonOne) THEN 
!  ! xi outside of possible range
!  alpha=-1.0
!  RETURN
!END IF
!
!eta = Bxz+Byz
!eta = (Cxz+Cyz - (Axz+Ayz)*xi) / eta
!
!!print*,'xi,eta',xi,eta
!IF(ABS(eta).GT.epsilonOne) THEN 
!  ! eta outside of possible range
!  alpha=-1.0
!  RETURN
!END IF
!
!! here, eta,xi,alpha are computed
!
!END SUBROUTINE ComputePlanarIntersection


!SUBROUTINE ComputePlanarIntersectionSuperSampled(xNodes,PartTrajectory,alpha,xi,eta,iPart)
SUBROUTINE ComputePlanarIntersectionSuperSampled(xNodes,PartTrajectory,alpha,xi,eta,flip,iPart)
!===================================================================================================================================
! Compute the Intersection with planar surface
!===================================================================================================================================
! MODULES
USE MOD_Globals,                 ONLY:Cross
USE MOD_Particle_Vars,           ONLY:LastPartPos
USE MOD_Particle_Surfaces_Vars,  ONLY:epsilonbilinear,BiLinearCoeff, SideNormVec,epsilontol,epsilonOne
!USE MOD_Particle_Surfaces_Vars,  ONLY:epsilonOne,SideIsPlanar,BiLinearCoeff,SideNormVec
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
! INPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
REAL,INTENT(IN),DIMENSION(1:3)    :: PartTrajectory
REAL,INTENT(IN),DIMENSION(1:3,4)  :: xNodes
INTEGER,INTENT(IN)                :: iPart!,SideID!,ElemID
INTEGER,INTENT(IN)                :: flip
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
REAL,INTENT(OUT)                  :: alpha,xi,eta
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
REAL,DIMENSION(1:3)               :: P0,P1,P2,nVec,nlength
REAL,DIMENSION(2:4)               :: a1,a2  ! array dimension from 2:4 according to bi-linear surface
REAL                              :: coeffA,coeffB
!===================================================================================================================================

! set alpha to minus 1, asume no intersection
!print*,PartTrajectory
alpha=-1.0
xi=-2.
eta=-2.

! compute basis vectors of plane
! first vector of plane
P1 = -xNodes(:,1)+xNodes(:,2)+xNodes(:,3)-xNodes(:,4)
! second vector
P2 = -xNodes(:,1)-xNodes(:,2)+xNodes(:,3)+xNodes(:,4)
! base point
P0 = xNodes(:,1)+xNodes(:,2)+xNodes(:,3)+xNodes(:,4)
P1=0.25*P1
P2=0.25*P2
P0=0.25*P0
! planar plane
! P1*xi + P2*eta+P0

nVec=CROSS(P1,P2)
nlength=nVec(1)*nVec(1)+nVec(2)*nVec(2) +nVec(3)*nVec(3) 
nlength=SQRT(nlength)
nVec=nVec/nlength
IF(flip.NE.0)THEN
  nVec=-nVec
END IF
 
!! compute distance along trajectory
coeffA=DOT_PRODUCT(nVec,PartTrajectory)
!IF(flip.EQ.0)THEN ! master side ! is in flip for normVec
!  IF(coeffA.LT.epsilontol)RETURN
!ELSE ! slave sides
!  IF(coeffA.GT.-epsilontol)RETURN
!END IF ! flip

!! corresponding to particle starting in plane
!! interaction should be computed in last step
IF(coeffA.LT.+epsilontol)THEN 
  RETURN
END IF
! distance of plane fromn origion minus trajectory start point times normal vector of side
P0=P0-LastPartPos(iPart,1:3)
coeffB=DOT_PRODUCT(P0,nVec)

alpha=coeffB/coeffA
!print*,'coeffB',coeffB
!print*,'alpha',alpha
!read*

IF((alpha.GT.epsilonOne).OR.(alpha.LT.-epsilontol))THEN
  alpha=-1.0
  RETURN
END IF

a1(2)= P1(1)*PartTrajectory(3)-P1(3)*PartTrajectory(1)
a1(3)= P2(1)*PartTrajectory(3)-P2(3)*PartTrajectory(1)
a1(4)= P0(1)*PartTrajectory(3) -P0(3)*PartTrajectory(1)

a2(2)= P1(2)*PartTrajectory(3)-P1(3)*PartTrajectory(2)
a2(3)= P2(2)*PartTrajectory(3)-P2(3)*PartTrajectory(2)
a2(4)= P0(2)*PartTrajectory(3) &
      -P0(3)*PartTrajectory(2)

!print*,'a12',a1(2)
!print*,'a13',a1(3)
!print*,'a14',a1(4)


!print*,'a22',a2(2)
!print*,'a23',a2(3)
!print*,'a24',a2(4)
!print*,'a23,a13',a2(3),a1(3)
!print*,'a22,a12',a2(2),a1(2)

! old one               ! working in not all cases
!! caution with accuracy
!IF(ABS(a2(3)).LT.epsilontol)THEN ! term c is close to zero ==> eta is zero
!  eta=0.
!  IF(ABS(a2(2)).LT.epsilontol)THEN
!    xi=0.
!  ELSE
!    ! compute xi
!    xi=a1(2)-a2(2)
!    xi=1.0/xi
!    xi=(a2(4)-a1(4))*xi
!  END IF
!!  IF(ABS(xi).GT.epsilonOne)THEN
!!    RETURN
!!  END IF
!ELSE ! a2(3) not zero
!  IF(ABS(a2(2)).LT.epsilontol)THEN
!    xi=0.
!    eta=a1(3)-a2(3)
!    eta=1.0/eta
!    eta=(a2(4)-a1(4))*eta
!  ELSE
!    xi = a1(2) - a1(3)*a2(2)/a2(3)
!    xi = 1.0/xi
!    xi = (-a1(4)-a1(3)*a2(4)/a2(3))*xi
!    ! check distance of xi 
!  !  IF(ABS(xi).GT.epsilonOne)THEN
!  !    RETURN
!  !  END IF
!    ! compute eta
!    eta=a1(3)-a2(3)
!    eta=1.0/eta
!    eta=((a2(2)-a1(2))*xi+a2(4)-a1(4))*eta
!  END IF
!END IF

IF(ABS(a2(3)).LT.epsilontol)THEN ! term c is close to zero ==> eta is zero
  eta=0.
  IF(ABS(a2(2)).LT.epsilontol)THEN
    xi=0.
  ELSE
    ! compute xi
    xi=a1(2)-a2(2)
    xi=1.0/xi
    xi=(a2(4)-a1(4))*xi
  END IF
!  IF(ABS(xi).GT.epsilonOne)THEN
!    RETURN
!  END IF
ELSE ! a2(3) not zero
  IF(ABS(a2(2)).LT.epsilontol)THEN
    xi=0.
    eta=a1(3)-a2(3)
    IF(ABS(eta).LT.epsilontol)THEN
      eta=0.
    ELSE
      eta=1.0/eta
      eta=(a2(4)-a1(4))*eta
    END IF
  ELSE
    xi = a1(2) - a1(3)*a2(2)/a2(3)
    xi=0.
    xi = 1.0/xi
    xi = (-a1(4)-a1(3)*a2(4)/a2(3))*xi
      ! check distance of xi 
  !  IF(ABS(xi).GT.epsilonOne)THEN
  !    RETURN
  !  END IF
    ! compute eta
    eta=a1(3)-a2(3)
    IF(ABS(eta).LT.epsilontol)THEN
      eta=0.
    ELSE ! eta not zero
     eta=1.0/eta
     eta=((a2(2)-a1(2))*xi+a2(4)-a1(4))*eta
    END IF ! eta .LT.epsilontol
  END IF
END IF

!xi = a1(2) - a1(3)*a2(2)/a2(3) !xi = 1.0/xi
!xi = (-a1(4)-a1(3)*a2(4)/a2(3))*xi
!! check distance of xi 
IF(ABS(xi).GT.epsilonOne)THEN
  alpha=-1.0
  RETURN
END IF
!! compute eta
!eta=a1(3)-a2(3)
!eta=1.0/eta
!eta=((a2(2)-a1(2))*xi+a2(4)-a1(4))*eta
!
IF(ABS(eta).GT.epsilonOne)THEN
  alpha=-1.0
  RETURN
END IF

!! compute distance with intersection
!IF((ABS(PartTrajectory(1)).GE.ABS(PartTrajectory(2))).AND.(ABS(PartTrajectory(1)).GT.ABS(PartTrajectory(3))))THEN
!  alpha =xi*BilinearCoeff(1,2,SideID)+eta*BilinearCoeff(1,3,SideID)+BilinearCoeff(1,4,SideID) -lastPartPos(iPart,1)
!  alpha = alpha/ PartTrajectory(1)
!ELSE IF(ABS(PartTrajectory(2)).GE.ABS(PartTrajectory(3)))THEN
!  alpha =xi*BilinearCoeff(2,2,SideID)+eta*BilinearCoeff(2,3,SideID)+BilinearCoeff(2,4,SideID) -lastPartPos(iPart,2)
!  alpha = alpha/ PartTrajectory(2)
!ELSE
!  alpha =xi*BilinearCoeff(3,2,SideID)+eta*BilinearCoeff(3,3,SideID)+BilinearCoeff(3,4,SideID) -lastPartPos(iPart,3)
!  alpha = alpha/ PartTrajectory(3)
!END IF
!
!IF((alpha.LT.epsilontol).OR.(alpha.GT.epsilonOne)) alpha=-1.0

END SUBROUTINE ComputePlanarIntersectionSuperSampled

SUBROUTINE ComputePlanarIntersection(PartTrajectory,alpha,xi,eta,iPart,SideID)
!===================================================================================================================================
! Compute the Intersection with planar surface
!===================================================================================================================================
! MODULES
USE MOD_Particle_Vars,           ONLY:LastPartPos
USE MOD_Particle_Surfaces_Vars,  ONLY:epsilonbilinear,BiLinearCoeff, SideNormVec,epsilontol,SideDistance,epsilonOne
!USE MOD_Particle_Surfaces_Vars,  ONLY:epsilonOne,SideIsPlanar,BiLinearCoeff,SideNormVec
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
! INPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
REAL,INTENT(IN),DIMENSION(1:3)    :: PartTrajectory
INTEGER,INTENT(IN)                :: iPart,SideID!,ElemID
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
REAL,INTENT(OUT)                  :: alpha,xi,eta
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
REAL,DIMENSION(2:4)                 :: a1,a2  ! array dimension from 2:4 according to bi-linear surface
REAL                                :: coeffA,coeffB
!===================================================================================================================================

! set alpha to minus 1, asume no intersection
!print*,PartTrajectory
alpha=-1.0
xi=-2.
eta=-2.

! compute distance of lastPartPos with planar plane

coeffA=DOT_PRODUCT(SideNormVec(1:3,SideID),PartTrajectory)
!print*,'coeffA',coeffA
!read*
! corresponding to particle starting in plane
! interaction should be computed in last step
IF(ABS(coeffA).LT.+epsilontol)THEN 
  RETURN
END IF
! distance of plane fromn origion minus trajectory start point times normal vector of side
coeffB=SideDistance(SideID)-DOT_PRODUCT(SideNormVec(1:3,SideID),LastPartPos(iPart,1:3))

alpha=coeffB/coeffA
!!print*,'coeffB',coeffB
!!print*,'alpha',alpha
!!read*

IF((alpha.GT.epsilonOne).OR.(alpha.LT.-epsilontol))THEN
  alpha=-1.0
  RETURN
END IF


a1(2)= BilinearCoeff(1,2,SideID)*PartTrajectory(3) - BilinearCoeff(3,2,SideID)*PartTrajectory(1)
a1(3)= BilinearCoeff(1,3,SideID)*PartTrajectory(3) - BilinearCoeff(3,3,SideID)*PartTrajectory(1)
a1(4)= (BilinearCoeff(1,4,SideID)-LastPartPos(iPart,1))*PartTrajectory(3) &
     - (BilinearCoeff(3,4,SideID)-LastPartPos(iPart,3))*PartTrajectory(1)

a2(2)= BilinearCoeff(2,2,SideID)*PartTrajectory(3) - BilinearCoeff(3,2,SideID)*PartTrajectory(2)
a2(3)= BilinearCoeff(2,3,SideID)*PartTrajectory(3) - BilinearCoeff(3,3,SideID)*PartTrajectory(2)
a2(4)= (BilinearCoeff(2,4,SideID)-LastPartPos(iPart,2))*PartTrajectory(3) &
     - (BilinearCoeff(3,4,SideID)-LastPartPos(iPart,3))*PartTrajectory(2)

!print*,'a23,a13',a2(3),a1(3)
!print*,'a22,a12',a2(2),a1(2)

!! caution with accuracy
IF(ABS(a2(3)).LT.epsilontol)THEN ! term c is close to zero ==> eta is zero
  eta=0.
  IF(ABS(a2(2)).LT.epsilontol)THEN
    xi=0.
  ELSE
    ! compute xi
    xi=a1(2)-a2(2)
    xi=1.0/xi
    xi=(a2(4)-a1(4))*xi
  END IF
!  IF(ABS(xi).GT.epsilonOne)THEN
!    RETURN
!  END IF
ELSE ! a2(3) not zero
  IF(ABS(a2(2)).LT.epsilontol)THEN
    xi=0.
    eta=a1(3)-a2(3)
    eta=1.0/eta
    eta=(a2(4)-a1(4))*eta
  ELSE
    xi = a1(2) - a1(3)*a2(2)/a2(3)
    xi = 1.0/xi
    xi = (-a1(4)-a1(3)*a2(4)/a2(3))*xi
    ! check distance of xi 
  !  IF(ABS(xi).GT.epsilonOne)THEN
  !    RETURN
  !  END IF
    ! compute eta
    eta=a1(3)-a2(3)
    eta=1.0/eta
    eta=((a2(2)-a1(2))*xi+a2(4)-a1(4))*eta
  END IF
END IF

!xi = a1(2) - a1(3)*a2(2)/a2(3)
!xi = 1.0/xi
!xi = (-a1(4)-a1(3)*a2(4)/a2(3))*xi
!! check distance of xi 
IF(ABS(xi).GT.epsilonOne)THEN
  alpha=-1.0
  RETURN
END IF
!! compute eta
!eta=a1(3)-a2(3)
!eta=1.0/eta
!eta=((a2(2)-a1(2))*xi+a2(4)-a1(4))*eta
!
IF(ABS(eta).GT.epsilonOne)THEN
  alpha=-1.0
  RETURN
END IF

!! compute distance with intersection
!IF((ABS(PartTrajectory(1)).GE.ABS(PartTrajectory(2))).AND.(ABS(PartTrajectory(1)).GT.ABS(PartTrajectory(3))))THEN
!  alpha =xi*BilinearCoeff(1,2,SideID)+eta*BilinearCoeff(1,3,SideID)+BilinearCoeff(1,4,SideID) -lastPartPos(iPart,1)
!  alpha = alpha/ PartTrajectory(1)
!ELSE IF(ABS(PartTrajectory(2)).GE.ABS(PartTrajectory(3)))THEN
!  alpha =xi*BilinearCoeff(2,2,SideID)+eta*BilinearCoeff(2,3,SideID)+BilinearCoeff(2,4,SideID) -lastPartPos(iPart,2)
!  alpha = alpha/ PartTrajectory(2)
!ELSE
!  alpha =xi*BilinearCoeff(3,2,SideID)+eta*BilinearCoeff(3,3,SideID)+BilinearCoeff(3,4,SideID) -lastPartPos(iPart,3)
!  alpha = alpha/ PartTrajectory(3)
!END IF
!
!IF((alpha.LT.epsilontol).OR.(alpha.GT.epsilonOne)) alpha=-1.0

END SUBROUTINE ComputePlanarIntersection

SUBROUTINE ComputeBiLinearIntersection(PartTrajectory,alpha,xitild,etatild,iPart,SideID)
!===================================================================================================================================
! Compute the Intersection with planar surface
!===================================================================================================================================
! MODULES
USE MOD_Particle_Vars,           ONLY:LastPartPos
USE MOD_Mesh_Vars,               ONLY:nBCSides
USE MOD_Particle_Surfaces_Vars,  ONLY:epsilonbilinear,BiLinearCoeff, epsilontol,epsilonOne
!USE MOD_Particle_Surfaces_Vars,  ONLY:epsilonOne,SideIsPlanar,BiLinearCoeff,SideNormVec
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
! INPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
REAL,INTENT(IN),DIMENSION(1:3)    :: PartTrajectory
INTEGER,INTENT(IN)                :: iPart,SideID
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
REAL,INTENT(OUT)                  :: alpha,xitild,etatild
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
REAL,DIMENSION(4)                 :: a1,a2
REAL                              :: A,B,C
REAL                              :: xi(2),eta(2),t(2), q1(3)
INTEGER                           :: nInter,nRoot
!===================================================================================================================================

! set alpha to minus one // no interesction
alpha=-1.0
xitild=-2.0
etatild=-2.0

a1(1)= BilinearCoeff(1,1,SideID)*PartTrajectory(3) - BilinearCoeff(3,1,SideID)*PartTrajectory(1)
a1(2)= BilinearCoeff(1,2,SideID)*PartTrajectory(3) - BilinearCoeff(3,2,SideID)*PartTrajectory(1)
a1(3)= BilinearCoeff(1,3,SideID)*PartTrajectory(3) - BilinearCoeff(3,3,SideID)*PartTrajectory(1)
a1(4)= (BilinearCoeff(1,4,SideID)-LastPartPos(iPart,1))*PartTrajectory(3) &
     - (BilinearCoeff(3,4,SideID)-LastPartPos(iPart,3))*PartTrajectory(1)

a2(1)= BilinearCoeff(2,1,SideID)*PartTrajectory(3) - BilinearCoeff(3,1,SideID)*PartTrajectory(2)
a2(2)= BilinearCoeff(2,2,SideID)*PartTrajectory(3) - BilinearCoeff(3,2,SideID)*PartTrajectory(2)
a2(3)= BilinearCoeff(2,3,SideID)*PartTrajectory(3) - BilinearCoeff(3,3,SideID)*PartTrajectory(2)
a2(4)= (BilinearCoeff(2,4,SideID)-LastPartPos(iPart,2))*PartTrajectory(3) &
     - (BilinearCoeff(3,4,SideID)-LastPartPos(iPart,3))*PartTrajectory(2)

A = a2(1)*a1(3)-a1(1)*a2(3)
B = a2(1)*a1(4)-a1(1)*a2(4)+a2(2)*a1(3)-a1(2)*a2(3)
C = a1(4)*a2(2)-a1(2)*a2(4)
!print*,'A,B,C', A,B,C
CALL QuatricSolver(A,B,C,nRoot,Eta(1),Eta(2))
!print*,nRoot,Eta
!  IF(iloop.EQ.34)THEN
!    print*,eta
!  END IF

IF(nRoot.EQ.0)THEN
  RETURN
END IF

IF (nRoot.EQ.1) THEN
  IF(ABS(eta(1)).LT.epsilonOne)THEN
    xi(1)=eta(1)*(a2(1)-a1(1))+a2(2)-a1(2)
    xi(1)=1.0/xi(1)
    xi(1)=(eta(1)*(a1(3)-a2(3))+a1(4)-a2(4))*xi(1)
    IF(ABS(xi(1)).LT.epsilonOne)THEN
      !q1=xi(1)*eta(1)*BilinearCoeff(:,1)+xi(1)*BilinearCoeff(:,2)+eta(1)*BilinearCoeff(:,3)+BilinearCoeff(:,4)-lastPartState
      t(1)=ComputeSurfaceDistance(xi(1),eta(1),PartTrajectory,iPart,SideID)
      IF((t(1).GE.+epsilontol).AND.(t(1).LE.epsilonOne))THEN
        alpha=t(1)
        xitild=xi(1)
        etatild=eta(1)
        RETURN
      ELSE ! t is not in range
        RETURN
      END IF
    ELSE ! xi not in range
      RETURN
    END IF ! xi .lt. epsilonOne
  ELSE ! eta not in reange
    RETURN 
  END IF ! eta .lt. epsilonOne
ELSE 
  nInter=0
  IF(ABS(eta(1)).LT.epsilonOne)THEN
    xi(1)=eta(1)*(a2(1)-a1(1))+a2(2)-a1(2)
    xi(1)=1.0/xi(1)
    xi(1)=(eta(1)*(a1(3)-a2(3))+a1(4)-a2(4))*xi(1)
    IF(ABS(xi(1)).LT.epsilonOne)THEN
      ! q1=xi(1)*eta(1)*BilinearCoeff(:,1)+xi(1)*BilinearCoeff(:,2)+eta(1)*BilinearCoeff(:,3)+BilinearCoeff(:,4)-lastPartState
      !  WRITE(*,*) ' t ', t(2)
      !  WRITE(*,*) ' Intersection at ', lastPartState+t(2)*q
      t(1)=ComputeSurfaceDistance(xi(1),eta(1),PartTrajectory,iPart,SideID)
      IF((t(1).LT.epsilontol).OR.(t(1).GT.epsilonOne))THEN
        t(1)=-2.0
      ELSE
        nInter=nInter+1
      END IF
!      IF((t(1).LT.epsilontol).AND.(t(1).GT.epsilonOne))THEN
!        t(1)=-1
!      END IF
    END IF
  END IF
  IF(ABS(eta(2)).LT.epsilonOne)THEN
    xi(2)=eta(2)*a2(1)-eta(2)*a1(1)+a2(2)-a1(2)
    xi(2)=1.0/xi(2)
    xi(2)=(eta(2)*a1(3)-eta(2)*a2(3)+a1(4)-a2(4))*xi(2)
    IF(ABS(xi(2)).LT.epsilonOne)THEN
      ! q1=xi(2)*eta(2)*BilinearCoeff(:,1)+xi(2)*BilinearCoeff(:,2)+eta(2)*BilinearCoeff(:,3)+BilinearCoeff(:,4)-lastPartState
      t(2)=ComputeSurfaceDistance(xi(2),eta(2),PartTrajectory,iPart,SideID)
      IF((t(2).LT.epsilontol).OR.(t(2).GT.epsilonOne))THEN
        t(2)=-2.0
      ELSE
        nInter=nInter+1
      END IF
!      IF((t(2).LT.epsilontol).AND.(t(2).GT.epsilonOne))THEN
!        t(2)=-1
!      END IF
      !IF((t(2).GE.epsZero).AND.(t(2).LE.epsOne))THEN
      !!  WRITE(*,*) ' Second Intersection'
      !!  WRITE(*,*) ' t ', t(2)
      !!  WRITE(*,*) ' Intersection at ', lastPartState+t(2)*q
      !END IF 
    END IF
  END IF
  ! if no intersection, return
  IF(nInter.EQ.0) RETURN
  IF(SideID.LE.nBCSides)THEN
    IF(ABS(t(1)).LT.ABS(t(2)))THEN
      alpha=t(1)
      xitild=xi(1)
      etatild=eta(1)
    ELSE
      alpha=t(2)
      xitild=xi(2)
      etatild=eta(2)
    END IF
  ELSE ! no BC Side
    ! if two intersections, return, particle re-enters element
    IF(nInter.EQ.2) RETURN
    IF(ABS(t(1)).LT.ABS(t(2)))THEN
      alpha=t(1)
      xitild=xi(1)
      etatild=eta(1)
    ELSE
      alpha=t(2)
      xitild=xi(2)
      etatild=eta(2)
    END IF
  END IF ! SideID.LT.nCBSides
END IF ! nRoot

END SUBROUTINE ComputeBiLinearIntersection

SUBROUTINE ComputeBiLinearIntersectionSuperSampled(xNodes,PartTrajectory,alpha,xitild,etatild,iPart,SideID)
!===================================================================================================================================
! Compute the Intersection with planar surface
!===================================================================================================================================
! MODULES
USE MOD_Particle_Vars,           ONLY:LastPartPos
USE MOD_Mesh_Vars,               ONLY:nBCSides
USE MOD_Particle_Surfaces_Vars,  ONLY:epsilontol,epsilonOne
!USE MOD_Particle_Surfaces_Vars,  ONLY:epsilonOne,SideIsPlanar,BiLinearCoeff,SideNormVec
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
! INPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
REAL,INTENT(IN),DIMENSION(1:3)    :: PartTrajectory
REAL,INTENT(IN),DIMENSION(1:3,4)  :: xNodes
INTEGER,INTENT(IN)                :: iPart,SideID
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
REAL,INTENT(OUT)                  :: alpha,xitild,etatild
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
REAL,DIMENSION(4)                 :: a1,a2
REAL,DIMENSION(1:3,1:4)           :: BiLinearCoeff
REAL                              :: A,B,C
REAL                              :: xi(2),eta(2),t(2), q1(3)
INTEGER                           :: nInter,nRoot
!===================================================================================================================================

! set alpha to minus one // no interesction
alpha=-1.0
xitild=-2.0
etatild=-2.0

! compute initial vectors
BiLinearCoeff(:,1) = xNodes(:,1)-xNodes(:,2)+xNodes(:,3)-xNodes(:,4)
BiLinearCoeff(:,2) =-xNodes(:,1)+xNodes(:,2)+xNodes(:,3)-xNodes(:,4)
BiLinearCoeff(:,3) =-xNodes(:,1)-xNodes(:,2)+xNodes(:,3)+xNodes(:,4)
BiLinearCoeff(:,4) = xNodes(:,1)+xNodes(:,2)+xNodes(:,3)+xNodes(:,4)
BiLinearCoeff= 0.25*BiLinearCoeff

! compute product with particle trajectory
a1(1)= BilinearCoeff(1,1)*PartTrajectory(3) - BilinearCoeff(3,1)*PartTrajectory(1)
a1(2)= BilinearCoeff(1,2)*PartTrajectory(3) - BilinearCoeff(3,2)*PartTrajectory(1)
a1(3)= BilinearCoeff(1,3)*PartTrajectory(3) - BilinearCoeff(3,3)*PartTrajectory(1)
a1(4)=(BilinearCoeff(1,4)-LastPartPos(iPart,1))*PartTrajectory(3) &
     -(BilinearCoeff(3,4)-LastPartPos(iPart,3))*PartTrajectory(1)

a2(1)= BilinearCoeff(2,1)*PartTrajectory(3) - BilinearCoeff(3,1)*PartTrajectory(2)
a2(2)= BilinearCoeff(2,2)*PartTrajectory(3) - BilinearCoeff(3,2)*PartTrajectory(2)
a2(3)= BilinearCoeff(2,3)*PartTrajectory(3) - BilinearCoeff(3,3)*PartTrajectory(2)
a2(4)=(BilinearCoeff(2,4)-LastPartPos(iPart,2))*PartTrajectory(3) &
     -(BilinearCoeff(3,4)-LastPartPos(iPart,3))*PartTrajectory(2)

A = a2(1)*a1(3)-a1(1)*a2(3)
B = a2(1)*a1(4)-a1(1)*a2(4)+a2(2)*a1(3)-a1(2)*a2(3)
C = a1(4)*a2(2)-a1(2)*a2(4)
!print*,'A,B,C', A,B,C
CALL QuatricSolver(A,B,C,nRoot,Eta(1),Eta(2))
!print*,nRoot,Eta
!  IF(iloop.EQ.34)THEN
!    print*,eta
!  END IF

IF(nRoot.EQ.0)THEN
  RETURN
END IF

IF (nRoot.EQ.1) THEN
  IF(ABS(eta(1)).LT.epsilonOne)THEN
    xi(1)=eta(1)*(a2(1)-a1(1))+a2(2)-a1(2)
    xi(1)=1.0/xi(1)
    xi(1)=(eta(1)*(a1(3)-a2(3))+a1(4)-a2(4))*xi(1)
    IF(ABS(xi(1)).LT.epsilonOne)THEN
      !q1=xi(1)*eta(1)*BilinearCoeff(:,1)+xi(1)*BilinearCoeff(:,2)+eta(1)*BilinearCoeff(:,3)+BilinearCoeff(:,4)-lastPartState
      t(1)=ComputeSurfaceDistance2(BiLinearCoeff,xi(1),eta(1),PartTrajectory,iPart)
      IF((t(1).GE.+epsilontol).AND.(t(1).LE.epsilonOne))THEN
        alpha=t(1)
        xitild=xi(1)
        etatild=eta(1)
        RETURN
      ELSE ! t is not in range
        RETURN
      END IF
    ELSE ! xi not in range
      RETURN
    END IF ! xi .lt. epsilonOne
  ELSE ! eta not in reange
    RETURN 
  END IF ! eta .lt. epsilonOne
ELSE 
  nInter=0
  IF(ABS(eta(1)).LT.epsilonOne)THEN
    xi(1)=eta(1)*(a2(1)-a1(1))+a2(2)-a1(2)
    xi(1)=1.0/xi(1)
    xi(1)=(eta(1)*(a1(3)-a2(3))+a1(4)-a2(4))*xi(1)
    IF(ABS(xi(1)).LT.epsilonOne)THEN
      ! q1=xi(1)*eta(1)*BilinearCoeff(:,1)+xi(1)*BilinearCoeff(:,2)+eta(1)*BilinearCoeff(:,3)+BilinearCoeff(:,4)-lastPartState
      !  WRITE(*,*) ' t ', t(2)
      !  WRITE(*,*) ' Intersection at ', lastPartState+t(2)*q
      t(1)=ComputeSurfaceDistance2(BiLinearCoeff,xi(1),eta(1),PartTrajectory,iPart)
      IF((t(1).LT.epsilontol).OR.(t(1).GT.epsilonOne))THEN
        t(1)=-2.0
      ELSE
        nInter=nInter+1
      END IF
!      IF((t(1).LT.epsilontol).AND.(t(1).GT.epsilonOne))THEN
!        t(1)=-1
!      END IF
    END IF
  END IF
  IF(ABS(eta(2)).LT.epsilonOne)THEN
    xi(2)=eta(2)*a2(1)-eta(2)*a1(1)+a2(2)-a1(2)
    xi(2)=1.0/xi(2)
    xi(2)=(eta(2)*a1(3)-eta(2)*a2(3)+a1(4)-a2(4))*xi(2)
    IF(ABS(xi(2)).LT.epsilonOne)THEN
      ! q1=xi(2)*eta(2)*BilinearCoeff(:,1)+xi(2)*BilinearCoeff(:,2)+eta(2)*BilinearCoeff(:,3)+BilinearCoeff(:,4)-lastPartState
      t(2)=ComputeSurfaceDistance2(BiLinearCoeff,xi(2),eta(2),PartTrajectory,iPart)
      IF((t(2).LT.epsilontol).OR.(t(2).GT.epsilonOne))THEN
        t(2)=-2.0
      ELSE
        nInter=nInter+1
      END IF
!      IF((t(2).LT.epsilontol).AND.(t(2).GT.epsilonOne))THEN
!        t(2)=-1
!      END IF
      !IF((t(2).GE.epsZero).AND.(t(2).LE.epsOne))THEN
      !!  WRITE(*,*) ' Second Intersection'
      !!  WRITE(*,*) ' t ', t(2)
      !!  WRITE(*,*) ' Intersection at ', lastPartState+t(2)*q
      !END IF 
    END IF
  END IF
  ! if no intersection, return
  IF(nInter.EQ.0) RETURN
  IF(SideID.LE.nBCSides)THEN
    IF(ABS(t(1)).LT.ABS(t(2)))THEN
      alpha=t(1)
      xitild=xi(1)
      etatild=eta(1)
    ELSE
      alpha=t(2)
      xitild=xi(2)
      etatild=eta(2)
    END IF
  ELSE ! no BC Side
    ! if two intersections, return, particle re-enters element
    IF(nInter.EQ.2) RETURN
    IF(ABS(t(1)).LT.ABS(t(2)))THEN
      alpha=t(1)
      xitild=xi(1)
      etatild=eta(1)
    ELSE
      alpha=t(2)
      xitild=xi(2)
      etatild=eta(2)
    END IF
  END IF ! SideID.LT.nCBSides
END IF ! nRoot

END SUBROUTINE ComputeBiLinearIntersectionSuperSampled

SUBROUTINE QuatricSolver(A,B,C,nRoot,r1,r2)
!================================================================================================================================
! subroutine to compute the modified a,b,c equation, parameter already mapped in final version
!================================================================================================================================
IMPLICIT NONE
!--------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
REAL,INTENT(IN)         :: A,B,C
!--------------------------------------------------------------------------------------------------------------------------------
INTEGER,INTENT(OUT)     :: nRoot
REAL,INTENT(OUT)        :: R1,R2
!--------------------------------------------------------------------------------------------------------------------------------
! local variables
REAL                    :: eps=1e-12, radicant
!================================================================================================================================

radicant = B*B-4.0*A*C
IF(ABS(a).LT.eps)THEN
  IF(ABS(b).LT.eps)THEN
    nRoot=0
    R1=0.
    R2=0.
  ELSE
    nRoot=1
    R1=-c/b
    R2=0.
  END IF
ELSE
  IF(radicant.LT.0) THEN
    nRoot = 0
    R1=0.
    R2=0.
  ELSE IF (ABS(radicant).LT.eps)THEN
    nRoot =1
    R1 = -0.5*B/A
    R2 = 0.
  ELSE
    nRoot=2
    R1 = SQRT(B*B-4.0*A*C)
    R2 = -R1
    R1 = -B+R1
    R1 = 0.5*R1/A
    R2 = -B+R2
    R2 = 0.5*R2/A
  END IF
END IF

END SUBROUTINE QuatricSolver

FUNCTION ComputeSurfaceDistance(xi,eta,PartTrajectory,iPart,SideID)
!================================================================================================================================
! compute the required vector length to intersection
!================================================================================================================================
USE MOD_Particle_Surfaces_Vars,   ONLY:epsilontol,BiLinearCoeff
USE MOD_Particle_Vars,            ONLY:PartState,LastPartPos
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!--------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
REAL,DIMENSION(3),INTENT(IN)         :: PartTrajectory
REAL,INTENT(IN)                      :: xi,eta
INTEGER,INTENT(IN)                   :: iPart,SideID
!--------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
REAL                                 :: ComputeSurfaceDistance
!--------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
REAL                                 :: t
!================================================================================================================================

IF((ABS(PartTrajectory(1)).GE.ABS(PartTrajectory(2))).AND.(ABS(PartTrajectory(1)).GT.ABS(PartTrajectory(3))))THEN
  t =xi*eta*BiLinearCoeff(1,1,SideID)+xi*BilinearCoeff(1,2,SideID)+eta*BilinearCoeff(1,3,SideID)+BilinearCoeff(1,4,SideID) &
             -lastPartPos(iPart,1)
  t = t/ PartTrajectory(1)-epsilontol 
ELSE IF(ABS(PartTrajectory(2)).GE.ABS(PartTrajectory(3)))THEN
  t =xi*eta*BilinearCoeff(2,1,SideID)+xi*BilinearCoeff(2,2,SideID)+eta*BilinearCoeff(2,3,SideID)+BilinearCoeff(2,4,SideID) &
             -lastPartPos(iPart,2)
  t = t/ PartTrajectory(2)-epsilontol 
ELSE
  t =xi*eta*BilinearCoeff(3,1,SideID)+xi*BilinearCoeff(3,2,SideID)+eta*BilinearCoeff(3,3,SideID)+BilinearCoeff(3,4,SideID) &
             -lastPartPos(iPart,3)
  t = t/ PartTrajectory(3)-epsilontol 
END IF

ComputeSurfaceDistance=t

END FUNCTION ComputeSurfaceDistance


FUNCTION ComputeSurfaceDistance2(BiLinearCoeff,xi,eta,PartTrajectory,iPart)
!================================================================================================================================
! compute the required vector length to intersection
!================================================================================================================================
USE MOD_Particle_Surfaces_Vars,   ONLY:epsilontol
USE MOD_Particle_Vars,            ONLY:PartState,LastPartPos
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!--------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
REAL,DIMENSION(3),INTENT(IN)         :: PartTrajectory
REAL,DIMENSION(3),INTENT(IN)         :: BiLinearCoeff(1:3,4)
REAL,INTENT(IN)                      :: xi,eta
INTEGER,INTENT(IN)                   :: iPart
!--------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
REAL                                 :: ComputeSurfaceDistance2
!--------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
REAL                                 :: t
!================================================================================================================================

IF((ABS(PartTrajectory(1)).GE.ABS(PartTrajectory(2))).AND.(ABS(PartTrajectory(1)).GT.ABS(PartTrajectory(3))))THEN
  t =xi*eta*BiLinearCoeff(1,1)+xi*BilinearCoeff(1,2)+eta*BilinearCoeff(1,3)+BilinearCoeff(1,4) -lastPartPos(iPart,1)
  t = t/ PartTrajectory(1)-epsilontol 
ELSE IF(ABS(PartTrajectory(2)).GE.ABS(PartTrajectory(3)))THEN
  t =xi*eta*BilinearCoeff(2,1)+xi*BilinearCoeff(2,2)+eta*BilinearCoeff(2,3)+BilinearCoeff(2,4) -lastPartPos(iPart,2)
  t = t/ PartTrajectory(2)-epsilontol 
ELSE
  t =xi*eta*BilinearCoeff(3,1)+xi*BilinearCoeff(3,2)+eta*BilinearCoeff(3,3)+BilinearCoeff(3,4) -lastPartPos(iPart,3)
  t = t/ PartTrajectory(3)-epsilontol 
END IF

ComputeSurfaceDistance2=t

END FUNCTION ComputeSurfaceDistance2


END MODULE MOD_Particle_Tracking