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
MODULE MOD_Dielectric_Vars
!===================================================================================================================================
! 
!===================================================================================================================================
! MODULES
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
PUBLIC
SAVE
!-----------------------------------------------------------------------------------------------------------------------------------
! GLOBAL VARIABLES 
!-----------------------------------------------------------------------------------------------------------------------------------
! Dielectric region damping factor
LOGICAL             :: DoDielectric                   ! True/false switch for Dielectric calculation procedures
LOGICAL             :: DielectricFluxNonConserving    ! True/false switch for using conserving or non-conserving fluxes at
!                                                     !dielectric interfaces between a dielectric region and vacuum
LOGICAL             :: DielectricInitIsDone           ! Initialization flag
LOGICAL,ALLOCATABLE :: isDielectricElem(:)            ! True if iElem is an element located within the Dielectric.
!                                                     ! This vector is allocated to (region.1:PP_nElems)
LOGICAL,ALLOCATABLE :: isDielectricFace(:)            ! True if iFace is a Face located within or on the boarder (interface) of the
!                                                     ! Dielectric region. This vector is allocated to (1:nSides)
LOGICAL,ALLOCATABLE :: isDielectricInterFace(:)       ! True if iFace is a Face located on the boarder (interface) of the Dielectric
!                                                     ! region. This vector is allocated to (1:nSides)
LOGICAL             :: DielectricCheckRadius          ! Instead of a bounding box region for setting a dielectric area, use radius
REAL                :: DielectricRadiusValue          ! Radius for setting dielectric element ON/OFF
INTEGER             :: Dielectricspread               ! If true Eps_x=Eps_y=Eps_z for all Dielectric cells
REAL,DIMENSION(6)   :: xyzPhysicalMinMaxDielectric    ! Physical   boundary coordinates, outside = Dielectric region
REAL,DIMENSION(6)   :: xyzDielectricMinMax            ! Dielectric boundary coordinates, outside = physical region
LOGICAL             :: useDielectricMinMax            ! Switch between 'xyzPhysicalMinMax' and 'xyzDielectricMinMax'
CHARACTER(255)      :: DielectricTestCase             ! Special test cases, e.g., "fish eye lens" Maxwell 1860
REAL                :: DielectricEpsR                 ! For Dielectric region shift
REAL                :: DielectricEpsR_inv             ! 1./EpsR
#ifdef PP_HDG
REAL                :: DielectricRatio                ! Set dielectric ratio e_io = eps_inner/eps_outer for dielectric sphere
REAL                :: Dielectric_E_0                 ! Axial electric field strength in x-direction of the dielectric sphere setup
#endif /*PP_HDG*/
REAL                :: DielectricMuR                  ! MuR
REAL                :: DielectricRmax                 ! Maximum radius for dielectric material distribution
REAL                :: DielectricConstant_RootInv     ! 1./sqrt(EpsR*MuR)
REAL                :: eta_c_dielectric               ! ( chi - 1./sqrt(EpsR*MuR) ) * c
REAL                :: c_dielectric                   ! c/sqrt(EpsR*MuR)
REAL                :: c2_dielectric                  ! c**2/(EpsR*MuR)
! mapping variables
INTEGER             :: nDielectricElems,nDielectricFaces,nDielectricInterFaces          ! Number of Dielectric elements and faces
!                                                                                       ! (mapping)
INTEGER,ALLOCATABLE :: DielectricToElem(:),DielectricToFace(:),DielectricInterToFace(:) ! Mapping to total element/face list
INTEGER,ALLOCATABLE :: ElemToDielectric(:),FaceToDielectric(:),FaceToDielectricInter(:) ! Mapping to Dielectric element/face list
!
REAL,ALLOCATABLE,DIMENSION(:,:,:,:)   :: DielectricEps
REAL,ALLOCATABLE,DIMENSION(:,:,:,:)   :: DielectricMu
REAL,ALLOCATABLE,DIMENSION(:,:,:,:)   :: DielectricConstant_inv         ! 1./(EpsR*MuR)
REAL,ALLOCATABLE,DIMENSION(:,:,:,:,:) :: DielectricGlobal               ! Contains DielectricEps and DielectricMu for HDF5 output
REAL,ALLOCATABLE,DIMENSION(:,:,:)     :: Dielectric_Master              ! face array containing 1./SQRT(EpsR*MuR) for each DOF
REAL,ALLOCATABLE,DIMENSION(:,:,:)     :: Dielectric_Slave

! For Poynting vector calculation
LOGICAL                               :: poyntingusemur_inv             ! True/false depending on dielectric permittivity and
!                                                                       ! Poynting vector planes on the same face
REAL,ALLOCATABLE,DIMENSION(:,:,:)     :: Dielectric_MuR_Master_inv      ! face array containing 1./MuR for each DOF
REAL,ALLOCATABLE,DIMENSION(:,:,:)     :: Dielectric_MuR_Slave_inv
!===================================================================================================================================
END MODULE MOD_Dielectric_Vars
