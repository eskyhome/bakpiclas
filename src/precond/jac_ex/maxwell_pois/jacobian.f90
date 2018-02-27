#include "boltzplatz.h"

MODULE MOD_Jacobian
!===================================================================================================================================
! Contains the initialization of the DG global variables
! Computes the different DG spatial operators/residuals(Ut) using U 
!===================================================================================================================================
! MODULES
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
PRIVATE
SAVE
!-----------------------------------------------------------------------------------------------------------------------------------
! GLOBAL VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! Public Part ----------------------------------------------------------------------------------------------------------------------
INTERFACE EvalFluxJacobian
  MODULE PROCEDURE EvalFluxJacobian
END INTERFACE

INTERFACE EvalFluxJacobianDielectric
  MODULE PROCEDURE EvalFluxJacobianDielectric
END INTERFACE

PUBLIC::EvalFluxJacobian,EvalFluxJacobianDielectric
!===================================================================================================================================

CONTAINS


SUBROUTINE EvalFluxJacobian(fJac,gJac,hJac)
!===================================================================================================================================
! flux jacobian of Maxwell without dielectric
!===================================================================================================================================
! MODULES
USE MOD_PreProc
USE MOD_Equation_Vars,ONLY:c2,c_corr,c_corr_c2
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
REAL,DIMENSION(PP_nVar,PP_nVar),INTENT(OUT) :: fJac,gJac,hJac             ! Cartesian fluxes (iVar,i,j,k)
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
!===================================================================================================================================

! Maxwell flux x-direction
fJac(1,1:8)= (/     0., 0.,  0.,        0.,  0.,  0.,     0.,  c_corr_c2 /)
fJac(2,1:8)= (/     0., 0.,  0.,        0.,  0.,  c2,     0.,         0. /)
fJac(3,1:8)= (/     0., 0.,  0.,        0., -c2,  0.,     0.,         0. /)
fJac(4,1:8)= (/     0., 0.,  0.,        0.,  0.,  0., c_corr,         0. /)
fJac(5,1:8)= (/     0., 0., -1.,        0.,  0.,  0.,     0.,         0. /)
fJac(6,1:8)= (/     0., 1.,  0.,        0.,  0.,  0.,     0.,         0. /)
fJac(7,1:8)= (/     0., 0.,  0., c_corr_c2,  0.,  0.,     0.,         0. /)
fJac(8,1:8)= (/ c_corr, 0.,  0.,        0.,  0.,  0.,     0.,         0. /)

gJac(1,1:8)= (/     0.,     0.,  0., 0.,        0., -c2,     0.,         0. /)
gJac(2,1:8)= (/     0.,     0.,  0., 0.,        0.,  0.,     0.,  c_corr_c2 /)
gJac(3,1:8)= (/     0.,     0.,  0., c2,        0.,  0.,     0.,         0. /)
gJac(4,1:8)= (/     0.,     0.,  1., 0.,        0.,  0.,     0.,         0. /)
gJac(5,1:8)= (/     0.,     0.,  0., 0.,        0.,  0., c_corr,         0. /)
gJac(6,1:8)= (/    -1.,     0.,  0., 0.,        0.,  0.,     0.,         0. /)
gJac(7,1:8)= (/     0.,     0.,  0., 0., c_corr_c2,  0.,     0.,         0. /)
gJac(8,1:8)= (/     0., c_corr,  0., 0.,        0.,  0.,     0.,         0. /)

hJac(1,1:8)= (/     0.,  0.,      0.,        0.,  c2,        0.,     0.,         0. /)
hJac(2,1:8)= (/     0.,  0.,      0.,       -c2,  0.,        0.,     0.,         0. /)
hJac(3,1:8)= (/     0.,  0.,      0.,        0.,  0.,        0.,     0.,  c_corr_c2 /)
hJac(4,1:8)= (/     0., -1.,      0.,        0.,  0.,        0.,     0.,         0. /)
hJac(5,1:8)= (/     1.,  0.,      0.,        0.,  0.,        0.,     0.,         0. /) 
hJac(6,1:8)= (/     0.,  0.,      0.,        0.,  0.,        0., c_corr,         0. /) 
hJac(7,1:8)= (/     0.,  0.,      0.,        0.,  0., c_corr_c2,     0.,         0. /) 
hJac(8,1:8)= (/     0.,  0.,  c_corr,        0.,  0.,        0.,     0.,         0. /) 
END SUBROUTINE EvalFluxJacobian


SUBROUTINE EvalFluxJacobianDielectric(DielectricConstant_inv,fJac,gJac,hJac)
!===================================================================================================================================
! flux Jacobian of Maxwell's equations and dielectric switched on
!===================================================================================================================================
! MODULES
USE MOD_PreProc
USE MOD_Equation_Vars,ONLY:c2,c_corr,c_corr_c2
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
REAL,DIMENSION(PP_nVar,PP_nVar),INTENT(OUT) :: fJac,gJac,hJac             ! Cartesian fluxes (iVar,i,j,k)
REAL,INTENT(OUT)                            :: DielectricConstant_inv      
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
!===================================================================================================================================

! Maxwell flux x-direction
fJac(1,1:8)= (/     0., 0.,  0.,        0.,  0.,  0.,     0.,  c_corr_c2 /)
fJac(2,1:8)= (/     0., 0.,  0.,        0.,  0.,  c2*DielectricConstant_inv,     0.,         0. /)
fJac(3,1:8)= (/     0., 0.,  0.,        0., -c2*DielectricConstant_inv,  0.,     0.,         0. /)
fJac(4,1:8)= (/     0., 0.,  0.,        0.,  0.,  0., c_corr,         0. /)
fJac(5,1:8)= (/     0., 0., -1.,        0.,  0.,  0.,     0.,         0. /)
fJac(6,1:8)= (/     0., 1.,  0.,        0.,  0.,  0.,     0.,         0. /)
fJac(7,1:8)= (/     0., 0.,  0., c_corr_c2,  0.,  0.,     0.,         0. /)
fJac(8,1:8)= (/ c_corr, 0.,  0.,        0.,  0.,  0.,     0.,         0. /)

gJac(1,1:8)= (/     0.,     0.,  0., 0.,        0., -c2*DielectricConstant_inv,     0.,         0. /)
gJac(2,1:8)= (/     0.,     0.,  0., 0.,        0.,  0.,     0.,  c_corr_c2 /)
gJac(3,1:8)= (/     0.,     0.,  0., c2*DielectricConstant_inv,        0.,  0.,     0.,         0. /)
gJac(4,1:8)= (/     0.,     0.,  1., 0.,        0.,  0.,     0.,         0. /)
gJac(5,1:8)= (/     0.,     0.,  0., 0.,        0.,  0., c_corr,         0. /)
gJac(6,1:8)= (/    -1.,     0.,  0., 0.,        0.,  0.,     0.,         0. /)
gJac(7,1:8)= (/     0.,     0.,  0., 0., c_corr_c2,  0.,     0.,         0. /)
gJac(8,1:8)= (/     0., c_corr,  0., 0.,        0.,  0.,     0.,         0. /)

hJac(1,1:8)= (/     0.,  0.,      0.,        0.,  c2*DielectricConstant_inv,        0.,     0.,         0. /)
hJac(2,1:8)= (/     0.,  0.,      0.,       -c2*DielectricConstant_inv,  0.,        0.,     0.,         0. /)
hJac(3,1:8)= (/     0.,  0.,      0.,        0.,  0.,        0.,     0.,  c_corr_c2 /)
hJac(4,1:8)= (/     0., -1.,      0.,        0.,  0.,        0.,     0.,         0. /)
hJac(5,1:8)= (/     1.,  0.,      0.,        0.,  0.,        0.,     0.,         0. /) 
hJac(6,1:8)= (/     0.,  0.,      0.,        0.,  0.,        0., c_corr,         0. /) 
hJac(7,1:8)= (/     0.,  0.,      0.,        0.,  0., c_corr_c2,     0.,         0. /) 
hJac(8,1:8)= (/     0.,  0.,  c_corr,        0.,  0.,        0.,     0.,         0. /) 
END SUBROUTINE EvalFluxJacobianDielectric


END MODULE MOD_Jacobian
