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
MODULE MOD_HDG_Vars
!===================================================================================================================================
! Contains global variables used by the HDG modules.
!===================================================================================================================================
! MODULES
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
PUBLIC
SAVE
!-----------------------------------------------------------------------------------------------------------------------------------
! GLOBAL VARIABLES 
!-----------------------------------------------------------------------------------------------------------------------------------
#ifdef PP_HDG
INTEGER             :: HDG_N
LOGICAL             :: HDG_MassOverintegration
INTEGER             :: nGP_vol              !=(PP_N+1)**3
INTEGER             :: nGP_face             !=(PP_N+1)**2
                    
LOGICAL             :: useHDG=.FALSE.
LOGICAL             :: OnlyPostProc=.FALSE. ! Flag to initialize exact function for lambda and only make the postprocessing
LOGICAL             :: ExactLambda =.FALSE. ! Flag to initialize exact function for lambda 
REAL,ALLOCATABLE    :: InvDhat(:,:,:)       ! Inverse of Dhat matrix (nGP_vol,nGP_vol,nElems)
REAL,ALLOCATABLE    :: Ehat(:,:,:,:)        ! Ehat matrix (nGP_Face,nGP_vol,6sides,nElems)
REAL,ALLOCATABLE    :: Fdiag(:,:)           ! diagonal mass matrix for side sytem (nGP_face,nSides)
REAL,ALLOCATABLE    :: wGP_vol(:)           ! 3D quadrature weights 
REAL,ALLOCATABLE    :: JwGP_vol(:,:)        ! 3D quadrature weights*Jacobian for all elements
REAL,ALLOCATABLE    :: lambda(:,:,:)          ! lambda, ((PP_N+1)^2,nSides)
REAL,ALLOCATABLE    :: RHS_vol(:,:,:)         ! Source RHS
REAL,ALLOCATABLE    :: Tau(:)               ! Stabilization parameter, per element 
REAL,ALLOCATABLE    :: Smat(:,:,:,:,:)      ! side to side matrix, (ngpface, ngpface, 6sides, 6sides, nElems) 
REAL,ALLOCATABLE    :: Precond(:,:,:)       ! block diagonal preconditioner for lambda(nGP_face, nGP-face, nSides)
REAL,ALLOCATABLE    :: InvPrecondDiag(:,:)  ! 1/diagonal of Precond
REAL,ALLOCATABLE    :: qn_face(:,:,:)         ! for Neumann BC 
REAL,ALLOCATABLE    :: qn_face_MagStat(:,:,:)         ! for Neumann BC 
INTEGER             :: nDirichletBCsides 
INTEGER             :: nNeumannBCsides 
INTEGER,ALLOCATABLE :: DirichletBC(:)
INTEGER,ALLOCATABLE :: NeumannBC(:)
REAL                :: RelaxFacNonlinear, RelaxFacNonlinear0 ! Relaxation factor fur Fix point it.
REAL                :: NormNonlinearDevLimit                 ! -''-, Threshold for assumed instability
INTEGER             :: AdaptIterFixPoint, AdaptIterFixPoint0 ! -''-, Interval for automatic adaption
LOGICAL             :: nonlinear            ! Use non-linear sources for HDG? (e.g. Boltzmann electrons)
LOGICAL             :: NewtonExactApprox
LOGICAL             :: AdaptNewtonStartValue
INTEGER             :: AdaptIterNewton
INTEGER             :: AdaptIterNewtonToLinear
INTEGER             :: AdaptIterNewtonOld
INTEGER             :: NonLinSolver  ! 1 Newton, 2 Fixpoint
REAL,ALLOCATABLE    :: NonlinVolumeFac(:,:)      !Factor for Volumeintegration necessary for nonlinear sources
!mappings                                                 
INTEGER             :: sideDir(6),pm(6),dirPm2iSide(2,3)
REAL,ALLOCATABLE    :: delta(:,:)
REAL,ALLOCATABLE    :: LL_minus(:,:),LL_plus(:,:)
REAL,ALLOCATABLE    :: Domega(:,:)
REAL,ALLOCATABLE    :: Lomega_m(:),Lomega_p(:)
!CG parameters
INTEGER             :: PrecondType=0  !0: none 1: block diagonal 2: only diagonal 3:Identity, debug
INTEGER             :: MaxIterCG, MaxIterFixPoint
REAL                :: EpsCG,EpsNonLinear
LOGICAL             :: UseRelativeAbortCrit
LOGICAL             :: HDGInitIsDone=.FALSE.
!===================================================================================================================================
#endif /* PP_HDG*/
END MODULE MOD_HDG_Vars
