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

MODULE MOD_ParticleInit
!===================================================================================================================================
! Add comments please!
!===================================================================================================================================
! MODULES
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
PRIVATE
!-----------------------------------------------------------------------------------------------------------------------------------
! GLOBAL VARIABLES 
!-----------------------------------------------------------------------------------------------------------------------------------
! Private Part ---------------------------------------------------------------------------------------------------------------------
! Public Part ----------------------------------------------------------------------------------------------------------------------

INTERFACE InitParticles
  MODULE PROCEDURE InitParticles
END INTERFACE

INTERFACE FinalizeParticles
  MODULE PROCEDURE FinalizeParticles
END INTERFACE

INTERFACE rotx
  MODULE PROCEDURE rotx
END INTERFACE

INTERFACE roty
  MODULE PROCEDURE roty
END INTERFACE

!INTERFACE rotz
!  MODULE PROCEDURE rotz
!END INTERFACE

INTERFACE Ident
  MODULE PROCEDURE Ident
END INTERFACE

INTERFACE InitRandomSeed
  MODULE PROCEDURE InitRandomSeed
END INTERFACE

INTERFACE PortabilityGetPID
  FUNCTION GetPID_C() BIND (C, name='getpid')
    !GETPID() is an intrinstic compiler function in gnu. This routine ensures the portability with other compilers. 
    USE ISO_C_BINDING,         ONLY: PID_T => C_INT
    IMPLICIT NONE
    INTEGER(KIND=PID_T)        :: GetPID_C
  END FUNCTION GetPID_C
END INTERFACE

PUBLIC::InitParticles,FinalizeParticles

PUBLIC::DefineParametersParticles
!===================================================================================================================================

CONTAINS

!==================================================================================================================================
!> Define parameters for particles
!==================================================================================================================================
SUBROUTINE DefineParametersParticles()
! MODULES
USE MOD_ReadInTools ,ONLY: prms,addStrListEntry
IMPLICIT NONE
!==================================================================================================================================
CALL prms%SetSection("Particle")

CALL prms%CreateRealOption(     'Particles-ManualTimeStep'  ,         'Manual timestep [sec]', '0.0')
CALL prms%CreateRealOption(     'Part-AdaptiveWeightingFactor', 'Weighting factor theta for weighting of average'//&
                                                                ' instantaneous values with those of previous iterations.', '0.001')
CALL prms%CreateIntOption(      'Particles-SurfaceModel', &
                                'Define Model used for particle surface interaction. If >0 then look in section SurfaceModel.\n'//&
                                '0: Maxwell scattering\n'//&
                                '1: Kisliuk / Polanyi Wigner (currently not working)\n'//&
                                '2: Recombination model\n'//&
                                '3: (SMCR with UBI-QEP, TST and TCE)', '0')
CALL prms%CreateIntOption(      'Part-nSpecies' ,                 'Number of species used in calculation', '1')
CALL prms%CreateIntOption(      'Part-nMacroRestartFiles' ,       'Number of Restart files used for calculation', '0')
CALL prms%CreateStringOption(   'Part-MacroRestartFile[$]' ,      'relative path to Restart file [$] used for calculation','none' &
                                                          ,numberedmulti=.TRUE.)
CALL prms%CreateIntOption(      'Part-MaxParticleNumber', 'Maximum number of Particles per proc (used for array init)'&
                                                                 , '1')
CALL prms%CreateRealOption(     'Particles-dt_part_ratio'     , 'TODO-DEFINE-PARAMETER\n'//&
                                                                'Factors for td200/201 '//&
                                                                     'overrelaxation/subcycling ', '3.8')
CALL prms%CreateRealOption(     'Particles-overrelax_factor'  , 'TODO-DEFINE-PARAMETER\n'//&
                                                                'Factors for td200/201'//&
                                                                    ' overrelaxation/subcycling', '1.0')
CALL prms%CreateIntOption(      'Part-NumberOfRandomSeeds'    , 'Number of Seeds for Random Number Generator'//&
                                                                'Choose nRandomSeeds \n'//&
                                                                '=-1    Random \n'//&
                                                                '= 0    Debugging-friendly with hard-coded deterministic numbers\n'//&
                                                                '> 0    Debugging-friendly with numbers from ini. ', '0')
CALL prms%CreateIntOption(      'Particles-RandomSeed[$]'     , 'Seed [$] for Random Number Generator', '1', numberedmulti=.TRUE.)

CALL prms%CreateLogicalOption(  'Particles-DoPoissonRounding' , 'TODO-DEFINE-PARAMETER\n'//&
                                                                'Flag to perform Poisson sampling'//&
                                                                ' instead of random rounding', '.FALSE.')
CALL prms%CreateLogicalOption(  'Particles-DoTimeDepInflow'   , 'TODO-DEFINE-PARAMETER\n'//&
                                                                'Insertion and SurfaceFlux with'//&
                                                                ' simple random rounding. Linearly ramping of'//&
                                                                ' inflow-number-of-particles is only possible with'//&
                                                                ' PoissonRounding or DoTimeDepInflow', '.FALSE.')

CALL prms%CreateIntOption(      'Part-nPeriodicVectors'       , 'TODO-DEFINE-PARAMETER\n'//&
                                                                'Number of the periodic vectors j=1,...,n.'//&
                                                                   ' Value has to be the same as defined in preprog.ini', '0')
CALL prms%CreateRealArrayOption('Part-PeriodicVector[$]'      , 'TODO-DEFINE-PARAMETER\nVector for periodic boundaries.'//&
                                                                   'Has to be the same as defined in preproc.ini in their'//&
                                                                   ' respective order. ', '1. , 0. , 0.', numberedmulti=.TRUE.)

CALL prms%CreateRealOption(     'Part-DelayTime'              , "TODO-DEFINE-PARAMETER\n"//&
                                                                "During delay time the particles,"//&
                                                                    " won't be moved so the EM field can be evolved", '0.0')
CALL prms%CreateLogicalOption(  'Particles-OutputVpiWarnings' , 'TODO-DEFINE-PARAMETER\n'//&
                                                                'Flag for warnings for rejected'//&
                                                                ' v if VPI+PartDensity', '.FALSE.')

CALL prms%CreateRealOption(     'Part-SafetyFactor'           , 'TODO-DEFINE-PARAMETER\n'//&
                                                                'Factor to scale the halo region with MPI'&
                                                              , '1.0')
CALL prms%CreateRealOption(     'Particles-HaloEpsVelo'       , 'TODO-DEFINE-PARAMETER\n'//&
                                                                'Halo region radius', '0.')

CALL prms%CreateIntOption(      'NbrOfRegions'                , 'TODO-DEFINE-PARAMETER\n'//&
                                                                'Number of regions to be mapped to Elements', '0')
CALL prms%CreateRealArrayOption('RegionBounds[$]'                , 'TODO-DEFINE-PARAMETER\nRegionBounds ((xmin,xmax,ymin,...)'//&
                                                                '|1:NbrOfRegions)'&
                                                                , '0. , 0. , 0. , 0. , 0. , 0.', numberedmulti=.TRUE.)
CALL prms%CreateRealArrayOption('Part-RegionElectronRef[$]'   , 'rho_ref, phi_ref, and Te[eV] for Region#'&
                                                              , '0. , 0. , 1.', numberedmulti=.TRUE.)
CALL prms%CreateRealOption('Part-RegionElectronRef[$]-PhiMax'   , 'max. expected phi for Region#\n'//&
                                                                '(linear approx. above! def.: phi_ref)', numberedmulti=.TRUE.)

CALL prms%CreateIntOption(      'Part-LorentzType'              , 'TODO-DEFINE-PARAMETER\n'//&
                                                                'Used Lorentz boost ', '3')
CALL prms%CreateLogicalOption(  'PrintrandomSeeds'            , 'Flag defining if random seeds are written.', '.FALSE.')
CALL prms%CreateIntOption(      'Particles-NumberOfRandomVectors', 'Option defining how many random vectors are calculated'&
                                                                 , '100000')
#if (PP_TimeDiscMethod==509)
CALL prms%CreateLogicalOption(  'velocityOutputAtTime' , 'Flag if leapfrog uses an velocity-output at real time' , '.TRUE.')
#endif

CALL prms%CreateLogicalOption(  'Part-DoFieldIonization'      , 'Do Field Ionization. Implemented models are:\n'//&                                  
                                                                ' * Ammosov-Delone-Krainov (ADK) model', '.FALSE.')

CALL prms%SetSection("IMD")
! IMD things
CALL prms%CreateRealOption(     'IMDTimeScale'                , 'Time unit of input file.\n The default value is'//&
                                                                ' ~10.18 fs which comes from the unit system in IMD', '10.18e-15')
CALL prms%CreateRealOption(     'IMDLengthScale'              , 'Length unit scale used by IMD which is 1 angstrom'&
                                                              , '1.0e-10')
CALL prms%CreateStringOption(   'IMDAtomFile'                 , 'IMD data file containing the atomic states for PartState(1:6)'&
                                                              , 'no file found')
CALL prms%CreateStringOption(   'IMDCutOff'                   , 'Atom cut-off parameter for reducing the number of improrted '//&
                                                                'IMD particles\n'//&
                                                                '1.) no_cutoff\n'//&
                                                                '2.) Epot\n'//&
                                                                '3.) coordinates\n'//&
                                                                '4.) velocity', 'no_cutoff')
CALL prms%CreateRealOption(     'IMDCutOffxValue'              ,"Cut-off coordinate for"//&
                                                                " IMDCutOff='coordiantes'" &
                                                              , '-999.9')
CALL prms%CreateIntOption(      'IMDnSpecies'                 , 'Count of IMD species', '1')
CALL prms%CreateStringOption(   'IMDInputFile'                , 'Laser data file name containing '//&
                                                                'PartState(1:6) ' &
                                                              , 'no file found')
CALL prms%SetSection("VMPF")
                              
! vmpf stuff
CALL prms%CreateLogicalOption(  'Part-vMPF'                      , 'TODO-DEFINE-PARAMETER\n'//&
                                                                'Flag to use variable '//&
                                                                'Macro Particle Factor.', '.FALSE.')
CALL prms%CreateLogicalOption(  'Part-vMPFPartMerge'              , 'TODO-DEFINE-PARAMETER\n'//&
                                                                'Enable Particle Merge routines.'&
                                                              , '.FALSE.')
CALL prms%CreateIntOption(      'Part-vMPFMergePolOrder'      , 'TODO-DEFINE-PARAMETER\n'//&
                                                                'Polynomial degree for vMPF particle merge.'&
                                                              , '2')
CALL prms%CreateIntOption(      'Part-vMPFCellSplitOrder'     , 'TODO-DEFINE-PARAMETER\n'//&
                                                                'Order for cell splitting of variable MPF'&
                                                              , '15')
CALL prms%CreateIntOption(      'Part-vMPFMergeParticleTarget', 'TODO-DEFINE-PARAMETER\n'//&
                                                                'Count of particles wanted after merge.', '0')
CALL prms%CreateIntOption(      'Part-vMPFSplitParticleTarget', 'TODO-DEFINE-PARAMETER\n'//&
                                                                'Number of particles wanted after split.','0')
CALL prms%CreateIntOption(      'Part-vMPFMergeParticleIter'  , 'TODO-DEFINE-PARAMETER\n'//&
                                                                'Number of iterations between particle '//&
                                                                'merges.', '100')
CALL prms%CreateStringOption(   'Part-vMPFvelocityDistribution','TODO-DEFINE-PARAMETER\n'//&
                                                                'Velocity distribution for variable '//&
                                                                'MPF.' , 'OVDR')
CALL prms%CreateLogicalOption(  'Part-vMPFrelativistic'              , 'TODO-DEFINE-PARAMETER', '.FALSE.')


CALL prms%SetSection("Particle Sampling")
           
! output of macroscopic values
CALL prms%CreateLogicalOption(  'Part-WriteMacroValues'&
  , 'Set [T] to activate ITERATION DEPENDANT h5 output of macroscopic values sampled every [Part-IterationForMacroVal] iterat'//&
  'ions from particles. Sampling starts from simulation start. Can not be enabled together with Part-TimeFracForSampling.\n'//&
  '(HALOWIKI:)Write macro values (e.g. rotational Temperature).'&
  , '.FALSE.')
CALL prms%CreateLogicalOption(  'Part-WriteMacroVolumeValues'&
  , 'Similar to Part-WriteMacroValues. Set [T] to activate iteration dependant sampling and h5 output for each element.'//&
  ' Is automatically set true if Part-WriteMacroValues is true.\n'//&
  'Can not be enabled if Part-TimeFracForSampling is set.', '.FALSE.')
CALL prms%CreateLogicalOption(  'Part-WriteMacroSurfaceValues'&
  , 'Similar to Part-WriteMacroValues. Set [T] to activate iteration dependant sampling and h5 output on surfaces.'//&
  ' Is automatically set true if Part-WriteMacroValues is true.\n'//&
  'Can not be enbaled if Part-TimeFracForSampling is set.', '.FALSE.')
CALL prms%CreateIntOption(      'Part-IterationForMacroVal'&
  , 'Set number of iterations used for sampling if Part-WriteMacroValues is set true.', '1')

CALL prms%CreateRealOption(     'Part-TimeFracForSampling'&
  , 'Set value greater 0.0 to enable TIME DEPENDANT sampling. The given simulation time fraction will be sampled. Sampling'//&
  ' starts after TEnd*(1-Part-TimefracForSampling).\n'//&
  'Can not be enabled together with Part-WriteMacroValues.' , '0.0')
CALL prms%CreateIntOption(      'Particles-NumberForDSMCOutputs'&
  , 'Give the number of outputs for time fraction sampling.\n'//&
  'Default value is 1 if Part-TimeFracForSampling is enabled.', '0')

CALL prms%CreateLogicalOption(  'Particles-DSMC-CalcSurfaceVal'&
  , 'Set [T] to activate sampling, analyze and h5 output for surfaces. Therefore either time fraction or iteration sampling'//&
  ' have to be enabled as well.', '.FALSE.')

CALL prms%CreateStringOption(   'DSMC-HOSampling-Type'  , 'TODO-DEFINE-PARAMETER', 'cell_mean')
CALL prms%CreateIntOption(      'Particles-DSMC-OutputOrder'  , 'TODO-DEFINE-PARAMETER', '1')
CALL prms%CreateStringOption(   'DSMC-HOSampling-NodeType'  , 'TODO-DEFINE-PARAMETER', 'visu')
CALL prms%CreateRealArrayOption('DSMCSampVolWe-BGMdeltas'  , 'TODO-DEFINE-PARAMETER', '0. , 0. , 0.')
CALL prms%CreateRealArrayOption('DSMCSampVolWe-FactorBGM'  , 'TODO-DEFINE-PARAMETER', '1. , 1. , 1.')
CALL prms%CreateIntOption(      'DSMCSampVolWe-VolIntOrd'  , 'TODO-DEFINE-PARAMETER', '50')
CALL prms%CreateIntOption(      'DSMC-nSurfSample'  , 'Define polynomial degree of particle BC sampling. Default: NGeo', '1')

CALL prms%SetSection("Particle SurfCollis")
CALL prms%CreateLogicalOption(  'Particles-CalcSurfCollis_OnlySwaps'    ,  'TODO-DEFINE-PARAMETER\n'//&
                                                                           'Count only wall collisions being SpeciesSwaps'&
                                                                        ,  '.FALSE.')
CALL prms%CreateLogicalOption(  'Particles-CalcSurfCollis_Only0Swaps'   ,  'TODO-DEFINE-PARAMETER\n'//&
                                                                           'Count only wall collisions being delete-SpeciesSwaps'&
                                                                           , '.FALSE.')
CALL prms%CreateLogicalOption(  'Particles-CalcSurfCollis_Output'       ,  'TODO-DEFINE-PARAMETER\n'//&
                                                                           'Print sums of all counted wall collisions'&
                                                                           , '.FALSE.')
CALL prms%CreateLogicalOption(  'Particles-AnalyzeSurfCollis'           ,  'TODO-DEFINE-PARAMETER\n'//&
                                                                           'Output of collided/swaped particles during Sampling'//&
                                                                           ' period? ', '.FALSE.')
CALL prms%CreateIntOption(      'Particles-DSMC-maxSurfCollisNumber'    ,  'TODO-DEFINE-PARAMETER\n'//&
                                                                           'Max. number of collided/swaped particles during'//&
                                                                           ' Sampling', '0')
CALL prms%CreateIntOption(      'Particles-DSMC-NumberOfBCs'            ,  'TODO-DEFINE-PARAMETER\n'//&
                                                                           'Count of BC to be analyzed', '1')
CALL prms%CreateIntArrayOption( 'Particles-DSMC-SurfCollisBC'           ,  'BCs to be analyzed (def.: 0 = all)')
CALL prms%CreateIntOption(      'Particles-CalcSurfCollis_NbrOfSpecies' ,  'TODO-DEFINE-PARAMETER\n'//&
                                                                           'Count of Species for wall  collisions (0: all)'&
                                                                           , '0')
CALL prms%CreateIntArrayOption( 'Particles-CalcSurfCollis_Species'      ,  'TODO-DEFINE-PARAMETER\n'//&
                                                                           'Help array for reading surface stuff')
                                                                           

CALL prms%CreateLogicalOption(  'Part-WriteFieldsToVTK',                      'TODO-DEFINE-PARAMETER\n'//&
                                                                           'Not in Code anymore, but read-in has to be deleted'//&
                                                                           ' in particle_init.f90', '.FALSE.')
CALL prms%CreateLogicalOption(  'Part-ConstPressAddParts',                  'TODO-DEFINE-PARAMETER', '.TRUE.')
CALL prms%CreateLogicalOption(  'Part-ConstPressRemParts',                        'TODO-DEFINE-PARAMETER', '.FALSE.')

CALL prms%SetSection("Particle Species")
! species inits
CALL prms%CreateIntOption(      'Part-Species[$]-nInits'  &
                                , 'Number of different initial particle placements for Species [$]', '0', numberedmulti=.TRUE.)
CALL prms%CreateLogicalOption(  'Part-Species[$]-Reset'  &
                                , 'Flag for resetting species distribution with init during restart' &
                                , '.FALSE.', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-ChargeIC'  &
                                , '[TODO-DEFINE-PARAMETER]\n'//&
                                  'Particle Charge (without MPF) of species[$] dim' &
                                , '0.', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-MassIC'  &
                                , 'Particle Mass (without MPF) of species [$] [kg]', '0.', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-MacroParticleFactor' &
                                , 'Number of Microparticle per Macroparticle for species [$]', '1.', numberedmulti=.TRUE.)
CALL prms%CreateLogicalOption(  'Part-Species[$]-IsImplicit'  &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Flag if specific particle is implicit', '.FALSE.', numberedmulti=.TRUE.)

CALL prms%CreateLogicalOption(  'Part-Species[$]-UseForInit'&
                                , 'Flag to use species[$] for initialization.', '.TRUE.', numberedmulti=.TRUE.)
CALL prms%CreateLogicalOption(  'Part-Species[$]-UseForEmission'  &
  , 'Use species[$] for volume emission. (set EmissionType)', '.TRUE.', numberedmulti=.TRUE.)
CALL prms%CreateStringOption(   'Part-Species[$]-SpaceIC'  &
                                , 'Specifying Keyword for particle space condition of species [$] in case of one init.\n'//&
                                ' - point \n'//&
                                ' - line_with_equidistant_distribution \n'//&
                                ' - line \n'//&
                                ' - disc \n'//&
                                ' - gyrotron_circle \n'//&
                                ' - circle_equidistant \n'//&
                                ' - cuboid \n'//&
                                ' - cylinder \n'//&
                                ' - cuboid_vpi \n'//&
                                ' - cylinder_vpi \n'//&
                                ' - LD_insert \n'//&
                                ' - cell_local \n'//&
                                ' - cuboid_equal \n'//&
                                ' - cuboid_with_equidistant_distribution \n'//&
                                ' - sin_deviation \n'//&
                                ' - IMD'&
                              , 'cuboid', numberedmulti=.TRUE.)
CALL prms%CreateStringOption(   'Part-Species[$]-velocityDistribution'  &
                                , 'Used velocity distribution.\n'//&
                                  '   constant: all particles have the same defined velocity.(VeloIC, VeloVec)\n'//&
                                  '   maxwell: sampled from maxwell distribution.(for MWTemperatureIC)\n'//&
                                  '   maxwell_lpn: maxwell with low particle number (better maxwell dist. approx. for lpn).' &
                                  , 'constant', numberedmulti=.TRUE.)
CALL prms%CreateIntOption(      'Part-Species[$]-rotation'  &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Direction of rotation, similar to TE-mode', '1', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-velocityspread'  &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Velocity spread in percent', '0.', numberedmulti=.TRUE.)
CALL prms%CreateIntOption(      'Part-Species[$]-velocityspreadmethod'  &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Method to compute the velocity spread', '0', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-InflowRiseTime'  &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Time to ramp the number of inflow particles,linearly from zero to unity'&
                                , '0.', numberedmulti=.TRUE.)
CALL prms%CreateIntOption(      'Part-Species[$]-initialParticleNumber'  &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Initial particle number', '0', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-RadiusIC'  &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Radius for IC circle', '1.', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-Radius2IC'  &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Radius for IC cylinder (ring)', '0.', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-RadiusICGyro'  &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Gyrotron radius', '1.', numberedmulti=.TRUE.)
CALL prms%CreateRealArrayOption('Part-Species[$]-NormalIC'  &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Normal orientation of circle.', '0. , 0. , 1.', numberedmulti=.TRUE.)
CALL prms%CreateRealArrayOption('Part-Species[$]-BasePointIC'  &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Base point for IC cuboid and IC sphere', '0. , 0. , 0.'&
                                , numberedmulti=.TRUE.)
CALL prms%CreateRealArrayOption('Part-Species[$]-BaseVector1IC'  &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'First base vector for IC cuboid', '1. , 0. , 0.', numberedmulti=.TRUE.)
CALL prms%CreateRealArrayOption('Part-Species[$]-BaseVector2IC'  &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Second base vector for IC cuboid', '0. , 1. , 0.', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-CuboidHeightIC'  &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Height of cuboid if SpaceIC=cuboid', '1.', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-CylinderHeightIC'  &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Height of cylinder if SpaceIC=cylinder', '1.', numberedmulti=.TRUE.)
CALL prms%CreateLogicalOption(  'Part-Species[$]-CalcHeightFromDt'  &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Calculated cuboid/cylinder height from v and dt?'&
                                , '.FALSE.', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-VeloIC'  &
                                , 'Absolute value of initial velocity. (ensemble velocity) ', '0.', numberedmulti=.TRUE.)
CALL prms%CreateRealArrayOption('Part-Species[$]-VeloVecIC '  &
                                , 'Normalized velocity vector for given VeloIC', '0. , 0. , 0.', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-Amplitude'  &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Amplitude for sin-deviation', '0.01', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-WaveNumber'  &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Wave number for sin-deviation', '2.', numberedmulti=.TRUE.)
CALL prms%CreateIntOption(      'Part-Species[$]-maxParticleNumber-x'  &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'MaximumNumber of all particles in x-direction', '0', numberedmulti=.TRUE.)
CALL prms%CreateIntOption(      'Part-Species[$]-maxParticleNumber-y'  &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'MaximumNumber of all particles in y-direction', '0', numberedmulti=.TRUE.)
CALL prms%CreateIntOption(      'Part-Species[$]-maxParticleNumber-z'  &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'MaximumNumber of all particles in z-direction', '0', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-Alpha' &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Factor for normal speed in gyrotron simulations.', '0.'&
                                , numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-MWTemperatureIC' &
                                , 'Initial translational temperature for Maxwell distribution initialization.', '0.'&
                                , numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-ConstantPressure' &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Pressure for an area with constant pressure', '0.', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-ConstPressureRelaxFac' &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Relaxation Factor for constant pressure sampling.', '1.'&
                                , numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-PartDensity' &
                                , 'Define particle density for species [$]. PartDensity (real particles per m^3).\n'//&
                                  'Used for DSMC with (vpi_)cuboid/cylinder and cell_local initial inserting.\n'// &
                                  'Also for LD_insert or (vpi_)cub./cyl. / cell_local as alternative to Part.Emis. in Type1', '0.'&
                                , numberedmulti=.TRUE.)
CALL prms%CreateIntOption(      'Part-Species[$]-ParticleEmissionType'  &
                                , 'Define Emission Type for particles (volume emission)\n'//&
                                  '1 = emission rate in part/s,\n'//&
                                  '2 = emission rate part/iteration\n'//&
                                  '3 = user def. emission rate\n'//&
                                  '4 = const. cell pressure\n'//&
                                  '5 = cell pres. w. complete part removal\n'//&
                                  '6 = outflow BC (characteristics method)', '2', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-ParticleEmission' &
                                , 'Emission rate in part/s or part/iteration.', '0.', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-NSigma' &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Sigma multiple of maxwell for virtual insert length.', '10.'&
                                , numberedmulti=.TRUE.)
CALL prms%CreateIntOption(      'Part-Species[$]-NumberOfExcludeRegions'  &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Number of different regions to be excluded', '0', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-MJxRatio' &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'x direction portion of velocity for Maxwell-Juettner', '0.'&
                                , numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-MJyRatio' &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'y direction portion of velocity for Maxwell-Juettner', '0.'&
                                , numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-MJzRatio' &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'z direction portion of velocity for Maxwell-Juettner', '0.'&
                                , numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-WeibelVeloPar' &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Parallel velocity component for Weibel', '0.'&
                                , numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-WeibelVeloPer' &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Perpendicular velocity component for Weibel', '0.'&
                                , numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-OneDTwoStreamVelo' &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Stream Velocity for the Two Stream Instability', '0.'&
                                , numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-OneDTwoStreamTransRatio' &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Ratio between perpendicular and parallel velocity', '0.'&
                                , numberedmulti=.TRUE.)
CALL prms%CreateStringOption(   'Part-Species[$]-vpiDomainType'  &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Specifying Keyword for virtual Pre-Inserting region\n'//&
                                  'implemented: - perpendicular_extrusion (default)\n'//&
                                  ' - freestream\n'//&
                                  ' - orifice\n'//&
                                  ' - ...more following...\n'&
                                  , 'perpendicular_extrusion', numberedmulti=.TRUE.)
CALL prms%CreateLogicalOption(  'Part-Species[$]-vpiBV1BufferNeg' &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'incl. buffer region in -BV1 direction?', '.TRUE.', numberedmulti=.TRUE.)
CALL prms%CreateLogicalOption(  'Part-Species[$]-vpiBV1BufferPos' &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'incl. buffer region in +BV1 direction?', '.TRUE.', numberedmulti=.TRUE.)
CALL prms%CreateLogicalOption(  'Part-Species[$]-vpiBV2BufferNeg' &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'incl. buffer region in -BV2 direction?', '.TRUE.', numberedmulti=.TRUE.)
CALL prms%CreateLogicalOption(  'Part-Species[$]-vpiBV2BufferPos' &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'incl. buffer region in +BV2 direction?', '.TRUE.', numberedmulti=.TRUE.)
CALL prms%CreateLogicalOption(  'Part-Species[$]-IsIMDSpecies' &
                                , 'TODO-DEFINE-PARAMETER', '.FALSE.', numberedmulti=.TRUE.)
CALL prms%CreateIntOption(      'Part-Species[$]-MacroRestartFileID'  &
                                , 'Define File ID of file used for Elem specific cell_local init of all macroscopic values' &
                                , '0', numberedmulti=.TRUE.)
CALL prms%CreateIntOption(      'Part-Species[$]-ElemTemperatureFileID'  &
                                , 'Define File ID of file used for Elem specific cell_local'// &
                                  ' init of translational temperature. (x,y,z are used from State)\n'// &
                                  'DEFAULT: MacroRestartFileID' &
                                , numberedmulti=.TRUE.)
CALL prms%CreateIntOption(      'Part-Species[$]-ElemPartDensityFileID'  &
                                , 'Define File ID of file used for Elem specific cell_local'// &
                                  ' init of number density.\n'// &
                                  'DEFAULT: MacroRestartFileID' &
                                , numberedmulti=.TRUE.)
CALL prms%CreateIntOption(      'Part-Species[$]-ElemVelocityICFileID'  &
                                , 'Define File ID of file used for Elem specific cell_local'// &
                                  ' init of drift velocity. (x,y,z are used from State)\n'// &
                                  'DEFAULT: MacroRestartFileID' &
                                , numberedmulti=.TRUE.)
CALL prms%CreateIntOption(      'Part-Species[$]-ElemTVibFileID'  &
                                , 'Define File ID of file used for Elem specific cell_local'// &
                                  ' init of vibrational temperature.\n'// &
                                  'DEFAULT: MacroRestartFileID\n only used if DSMC + collismode>1' &
                                , numberedmulti=.TRUE.)
CALL prms%CreateIntOption(      'Part-Species[$]-ElemTRotFileID'  &
                                , 'Define File ID of file used for Elem specific cell_local'// &
                                  ' init of rotational temperature.\n'// &
                                  'DEFAULT: MacroRestartFileID\n only used if DSMC + collismode>1' &
                                , numberedmulti=.TRUE.)
CALL prms%CreateIntOption(      'Part-Species[$]-ElemTElecFileID'  &
                                , 'Define File ID of file used for Elem specific cell_local'// &
                                  ' init of electronic temperature.\n'// &
                                  'DEFAULT: MacroRestartFileID\n only used if DSMC + collismode>1 + electronicmodel' &
                                , numberedmulti=.TRUE.)


CALL prms%SetSection("Particle Species Ninits")
! if Ninit>0 some variables have to be defined twice
CALL prms%CreateLogicalOption(  'Part-Species[$]-Init[$]-UseForInit' &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Flag to use Init/Emission for init', '.TRUE.', numberedmulti=.TRUE.)
CALL prms%CreateLogicalOption(  'Part-Species[$]-Init[$]-UseForEmission' &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Flag to use Init/Emission for emission', '.FALSE.', numberedmulti=.TRUE.)
CALL prms%CreateStringOption(   'Part-Species[$]-Init[$]-SpaceIC' &
                                , 'Specifying Keyword for particle space condition of species [$] in case of multiple inits' &
                                , 'cuboid', numberedmulti=.TRUE.)
CALL prms%CreateStringOption(   'Part-Species[$]-Init[$]-velocityDistribution'  &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Specifying keyword for velocity distribution', 'constant'&
                                , numberedmulti=.TRUE.)
CALL prms%CreateIntOption(      'Part-Species[$]-Init[$]-rotation' &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Direction of rotation, similar to TE-mode', '1', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-Init[$]-velocityspread' &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Velocity spread in percent', '0.', numberedmulti=.TRUE.)
CALL prms%CreateIntOption(      'Part-Species[$]-Init[$]-velocityspreadmethod' &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Method to compute the velocity spread', '0', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-Init[$]-InflowRiseTime' &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Time to ramp the number of inflow particles linearly from zero to unity'&
                                , '0.', numberedmulti=.TRUE.)
CALL prms%CreateIntOption(      'Part-Species[$]-Init[$]-initialParticleNumber' &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Number of Particles at time 0.0', '0', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-Init[$]-RadiusIC'  &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Radius for IC circle', '1.', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-Init[$]-Radius2IC' &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Radius2 for IC cylinder (ring)', '0.', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-Init[$]-RadiusICGyro' &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Radius for Gyrotron gyro radius', '1.', numberedmulti=.TRUE.)
CALL prms%CreateRealArrayOption('Part-Species[$]-Init[$]-NormalIC'  &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Normal / Orientation of circle', '0. , 0. , 1.', numberedmulti=.TRUE.)
CALL prms%CreateRealArrayOption('Part-Species[$]-Init[$]-BasePointIC'  &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Base point for IC cuboid and IC sphere ', '0. , 0. , 0.'&
                                , numberedmulti=.TRUE.)
CALL prms%CreateRealArrayOption('Part-Species[$]-Init[$]-BaseVector1IC'  &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'First base vector for IC cuboid', '1. , 0. , 0.'&
                                , numberedmulti=.TRUE.)
CALL prms%CreateRealArrayOption('Part-Species[$]-Init[$]-BaseVector2IC'  &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Second base vector for IC cuboid', '0. , 1. , 0.'&
                                , numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-Init[$]-CuboidHeightIC'  &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Height of cuboid if SpaceIC = cuboid. (set 0 for flat rectangle)'//&
                                  ',negative value = opposite direction', '1.', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-Init[$]-CylinderHeightIC'  &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Third measure of cylinder  (set 0 for flat rectangle),'//&
                                  ' negative value = opposite direction', '1.', numberedmulti=.TRUE.)
CALL prms%CreateLogicalOption(  'Part-Species[$]-Init[$]-CalcHeightFromDt'  &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Calculate cuboid/cylinder height from v and dt?', '.FALSE.'&
                                , numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-Init[$]-VeloIC'  &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Velocity for inital Data', '0.', numberedmulti=.TRUE.)
CALL prms%CreateRealArrayOption('Part-Species[$]-Init[$]-VeloVecIC'  &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Normalized velocity vector', '0. , 0. , 0.', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-Init[$]-Amplitude'  &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Amplitude for sin-deviation initiation.', '0.01', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-Init[$]-WaveNumber'  &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'WaveNumber for sin-deviation initiation', '2.', numberedmulti=.TRUE.)
CALL prms%CreateIntOption(      'Part-Species[$]-Init[$]-maxParticleNumber-x'  &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Maximum Number of all Particles in x direction', '0', numberedmulti=.TRUE.)
CALL prms%CreateIntOption(      'Part-Species[$]-Init[$]-maxParticleNumber-y'  &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Maximum Number of all Particles in y direction', '0', numberedmulti=.TRUE.)
CALL prms%CreateIntOption(      'Part-Species[$]-Init[$]-maxParticleNumber-z'  &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Maximum Number of all Particles in z direction', '0', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-Init[$]-Alpha' &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'WaveNumber for sin-deviation initiation.', '0.', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-Init[$]-MWTemperatureIC' &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Temperature for Maxwell Distribution', '0.', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-Init[$]-ConstantPressure' &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Pressure for an Area with a Constant Pressure', '0.'&
                                , numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-Init[$]-ConstPressureRelaxFac' &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Relaxation Factor for constant pressure sampling.', '1.'&
                                , numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-Init[$]-PartDensity' &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'PartDensity (real particles per m^3) for LD_insert or (vpi_)cub./cyl. '//&
                                  'as alternative to Part.Emis. in Type1 ', '0.', numberedmulti=.TRUE.)
CALL prms%CreateIntOption(      'Part-Species[$]-Init[$]-ParticleEmissionType'  &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Emission Type \n'//&
                                  '1 = emission rate in 1/s,\n'//&
                                  '2 = emission rate 1/iteration\n'//&
                                  '3 = user def. emission rate\n'//&
                                  '4 = const. cell pressure\n'//&
                                  '5 = cell pres. w. complete part removal\n'//&
                                  '6 = outflow BC (characteristics method)', '2', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-Init[$]-ParticleEmission' &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Emission in [1/s] or [1/Iteration]', '0.', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-Init[$]-NSigma' &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Sigma multiple of maxwell for virtual insert length', '10.'&
                                , numberedmulti=.TRUE.)
CALL prms%CreateIntOption(      'Part-Species[$]-Init[$]-NumberOfExcludeRegions'  &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Number of different regions to be excluded', '0', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-Init[$]-MJxRatio' &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'x direction portion of velocity for Maxwell-Juettner', '0.'&
                                , numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-Init[$]-MJyRatio' &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'y direction portion of velocity for Maxwell-Juettner', '0.'&
                                , numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-Init[$]-MJzRatio' &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'z direction portion of velocity for Maxwell-Juettner', '0.'&
                                , numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-Init[$]-WeibelVeloPar' &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Parallel velocity component for Weibel', '0.', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-Init[$]-WeibelVeloPer' &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Perpendicular velocity component for Weibel', '0.'&
                                , numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-Init[$]-OneDTwoStreamVelo' &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Stream Velocity for the Two Stream Instability', '0.'&
                                , numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-Init[$]-OneDTwoStreamTransRatio' &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Ratio between perpendicular and parallel velocity', '0.'&
                                , numberedmulti=.TRUE.)
CALL prms%CreateStringOption(   'Part-Species[$]-Init[$]-vpiDomainType'  &
                                   , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Specifying Keyword for virtual Pre-Inserting region\n'//&
                                  'implemented: - perpendicular_extrusion (default)\n'//&
                                  ' - freestream\n'//&
                                  ' - orifice\n'//&
                                  ' - ...more following...\n'&
                                  , 'perpendicular_extrusion', numberedmulti=.TRUE.)
CALL prms%CreateLogicalOption(  'Part-Species[$]-Init[$]-vpiBV1BufferNeg' &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'incl. buffer region in -BV1 direction?', '.TRUE.', numberedmulti=.TRUE.)
CALL prms%CreateLogicalOption(  'Part-Species[$]-Init[$]-vpiBV1BufferPos' &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'incl. buffer region in +BV1 direction?', '.TRUE.', numberedmulti=.TRUE.)
CALL prms%CreateLogicalOption(  'Part-Species[$]-Init[$]-vpiBV2BufferNeg' &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'incl. buffer region in -BV2 direction?', '.TRUE.', numberedmulti=.TRUE.)
CALL prms%CreateLogicalOption(  'Part-Species[$]-Init[$]-vpiBV2BufferPos' &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'incl. buffer region in +BV2 direction?', '.TRUE.', numberedmulti=.TRUE.)

CALL prms%CreateIntOption(      'Part-Species[$]-Init[$]-MacroRestartFileID'  &
                                , 'Define File ID of file used for Elem specific cell_local init of all macroscopic values' &
                                , '0', numberedmulti=.TRUE.)
CALL prms%CreateIntOption(      'Part-Species[$]-Init[$]-ElemTemperatureFileID'  &
                                , 'Define File ID of file used for Elem specific cell_local'// &
                                  ' init of translational temperature. (x,y,z are used from State)\n'// &
                                  'DEFAULT: MacroRestartFileID' &
                                , numberedmulti=.TRUE.)
CALL prms%CreateIntOption(      'Part-Species[$]-Init[$]-ElemPartDensityFileID'  &
                                , 'Define File ID of file used for Elem specific cell_local'// &
                                  ' init of number density.\n'// &
                                  'DEFAULT: MacroRestartFileID' &
                                , numberedmulti=.TRUE.)
CALL prms%CreateIntOption(      'Part-Species[$]-Init[$]-ElemVelocityICFileID'  &
                                , 'Define File ID of file used for Elem specific cell_local'// &
                                  ' init of drift velocity. (x,y,z are used from State)\n'// &
                                  'DEFAULT: MacroRestartFileID' &
                                , numberedmulti=.TRUE.)
CALL prms%CreateIntOption(      'Part-Species[$]-Init[$]-ElemTVibFileID'  &
                                , 'Define File ID of file used for Elem specific cell_local'// &
                                  ' init of vibrational temperature.\n'// &
                                  'DEFAULT: MacroRestartFileID\n only used if DSMC + collismode>1' &
                                , numberedmulti=.TRUE.)
CALL prms%CreateIntOption(      'Part-Species[$]-Init[$]-ElemTRotFileID'  &
                                , 'Define File ID of file used for Elem specific cell_local'// &
                                  ' init of rotational temperature.\n'// &
                                  'DEFAULT: MacroRestartFileID\n only used if DSMC + collismode>1' &
                                , numberedmulti=.TRUE.)
CALL prms%CreateIntOption(      'Part-Species[$]-Init[$]-ElemTElecFileID'  &
                                , 'Define File ID of file used for Elem specific cell_local'// &
                                  ' init of electronic temperature.\n'// &
                                  'DEFAULT: MacroRestartFileID\n only used if DSMC + collismode>1 + electronicmodel' &
                                , numberedmulti=.TRUE.)

CALL prms%SetSection("Particle Species Init RegionExculdes")
! some inits or exluded in some regions
CALL prms%CreateStringOption(   'Part-Species[$]-Init[$]-ExcludeRegion[$]-SpaceIC' &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Specified keyword for excluded particle space condition of'//&
                                  ' species[$] in case of multiple inits  ', 'cuboid', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-Init[$]-ExcludeRegion[$]-RadiusIC'  &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Radius for excluded IC circle', '1.', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-Init[$]-ExcludeRegion[$]-Radius2IC' &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Radius2 for excluded IC cylinder (ring)', '0.', numberedmulti=.TRUE.)
CALL prms%CreateRealArrayOption('Part-Species[$]-Init[$]-ExcludeRegion[$]-NormalIC'  &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Normal orientation of excluded circle', '0. , 0. , 1.'&
                                , numberedmulti=.TRUE.)
CALL prms%CreateRealArrayOption('Part-Species[$]-Init[$]-ExcludeRegion[$]-BasePointIC'  &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Base point for excluded IC cuboid and IC sphere', '0. , 0. , 0.'&
                                , numberedmulti=.TRUE.)
CALL prms%CreateRealArrayOption('Part-Species[$]-Init[$]-ExcludeRegion[$]-BaseVector1IC'  &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'First base vector for excluded IC cuboid', '1. , 0. , 0.'&
                                , numberedmulti=.TRUE.)
CALL prms%CreateRealArrayOption('Part-Species[$]-Init[$]-ExcludeRegion[$]-BaseVector2IC'  &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Second base vector for excluded IC cuboid', '0. , 1. , 0.'&
                                , numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-Init[$]-ExcludeRegion[$]-CuboidHeightIC'  &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Height of excluded cuboid, if'//&
                                  ' Part-Species[$]-Init[$]-ExcludeRegion[$]-SpaceIC=cuboid (set 0 for flat rectangle),'//&
                                  ' negative value = opposite direction', '1.', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Species[$]-Init[$]-ExcludeRegion[$]-CylinderHeightIC'  &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Height of excluded cylinder, if'//&
                                  ' Part-Species[$]-Init[$]-ExcludeRegion[$]-SpaceIC=cylinder (set 0 for flat circle),'//&
                                  'negative value = opposite direction ', '1.', numberedmulti=.TRUE.)

CALL prms%SetSection("Particle Boundaries")

CALL prms%CreateIntOption(      'Part-nBounds'     , 'TODO-DEFINE-PARAMETER\n'//&
                                                       'Number of particle boundaries.', '1')
CALL prms%CreateIntOption(      'Part-Boundary[$]-NbrOfSpeciesSwaps'  &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Number of Species to be changed at wall.', '0', numberedmulti=.TRUE.)
CALL prms%CreateStringOption(   'Part-Boundary[$]-Condition'  &
                                , 'TODO-DEFINE-PARAMETER\n'//&
                                  'Used boundary condition for boundary[$].\n'//&
                                  '- open\n'//&
                                  '- reflective\n'//&
                                  '- periodic\n'//&
                                  '- simple_anode\n'//&
                                  '- simple_cathode.\n'//&
                                 'If condition=open, the following parameters are'//&
                                  ' used: (Part-Boundary[$]-=PB) PB-Ambient ,PB-AmbientTemp,PB-AmbientMeanPartMass,'//&
                                  'PB-AmbientVelo,PB-AmbientDens,PB-AmbientDynamicVisc,PB-AmbientThermalCond,PB-Voltage\n'//&
                                 'If condition=reflective: PB-MomentumACC,PB-WallTemp,PB-TransACC,PB-VibACC,PB-RotACC,'//&
                                  'PB-WallVelo,Voltage,SpeciesSwaps.If condition=periodic:Part-nPeriodicVectors,'//&
                                  'Part-PeriodicVector[$]', 'open', numberedmulti=.TRUE.)
CALL prms%CreateLogicalOption(  'Part-Boundary[$]-AmbientCondition'  &
                                , 'TODO-DEFINE-PARAMETER'//&
                                  'Use ambient condition (condition "behind" boundary).', '.FALSE.'&
                                , numberedmulti=.TRUE.)
CALL prms%CreateLogicalOption(  'Part-Boundary[$]-AmbientConditionFix'  &
                                , 'TODO-DEFINE-PARAMETER', '.TRUE.', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Boundary[$]-AmbientTemp'  &
                                , 'TODO-DEFINE-PARAMETER'//&
                                  'Ambient temperature ', '0.', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Boundary[$]-AmbientMeanPartMass'  &
                                , 'TODO-DEFINE-PARAMETER'//&
                                  'Ambient mean particle mass', '0.', numberedmulti=.TRUE.)
CALL prms%CreateRealArrayOption('Part-Boundary[$]-AmbientVelo'  &
                                , 'TODO-DEFINE-PARAMETER'//&
                                  'Ambient velocity', '0. , 0. , 0.', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Boundary[$]-AmbientDens'  &
                                , 'TODO-DEFINE-PARAMETER'//&
                                  'Ambient density', '0.', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Boundary[$]-AmbientDynamicVisc'  &
                                , 'TODO-DEFINE-PARAMETER'//&
                                  'Ambient dynamic viscosity', '1.72326582572253E-5', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Boundary[$]-AmbientThermalCond'  &
                                , 'TODO-DEFINE-PARAMETER'//&
                                  'Ambient thermal conductivity', '2.42948500556027E-2'&
                                , numberedmulti=.TRUE.)
CALL prms%CreateLogicalOption(  'Part-Boundary[$]-Adaptive'  &
  , 'Define if particle boundary [$] is adaptive [.TRUE.] or not [.FALSE.]', '.FALSE.', numberedmulti=.TRUE.)
CALL prms%CreateIntOption(      'Part-Boundary[$]-AdaptiveType'  &
  , 'Define type of adaptive boundary [$]\n'//&
    '[1] (STREAM INLET) with define temperature and pressure and pressurefraction\n'//&
    '[2] (STREAM OUTLET) with defined pressure and pressurefraction', '2', numberedmulti=.TRUE.)
CALL prms%CreateIntOption(      'Part-Boundary[$]-AdaptiveMacroRestartFileID'  &
  , 'Define FileID of adaptive boundary [$] macro restart if macro restart is used' &
    , '0', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Boundary[$]-AdaptiveTemp'  &
  , 'Define temperature for adaptive particle boundary [$] (in [K])', '0.', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Boundary[$]-AdaptivePressure'  &
  , 'Define pressure for adaptive particle boundary [$] (in [Pa])', '0.', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Boundary[$]-Species[$]-Pressurefraction'  &
  , 'If particle boundary [$] adaptive, define pressurefractions for each species, so sum of all species for this adaptive'//&
    'is 1.0. Results in abort if not set right.' , '0.', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Boundary[$]-Voltage'  &
                                , 'TODO-DEFINE-PARAMETER'//&
                                  'Voltage on boundary [$]', '0.', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Boundary[$]-WallTemp'  &
                                , 'Wall temperature (in [K]) of reflective particle boundary [$].' &
                                , '0.', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Boundary[$]-MomentumACC'  &
                                , 'Momentum accommodation coefficient of reflective particle boundary [$].' &
                                , '0.', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Boundary[$]-TransACC'  &
                                , 'Translation accommodation coefficient of reflective particle boundary [$].' &
                                , '0.', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Boundary[$]-VibACC'  &
                                , 'Vibrational accommodation coefficient of reflective particle boundary [$].' &
                                , '0.', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Boundary[$]-RotACC'  &
                                , 'Rotational accommodation coefficient of reflective particle boundary [$].' &
                                , '0.', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Boundary[$]-ElecACC '  &
                                , 'Electronic accommodation coefficient of reflective particle boundary [$].' &
                                , '0.', numberedmulti=.TRUE.)
CALL prms%CreateLogicalOption(  'Part-Boundary[$]-Resample'  &
                                , 'TODO-DEFINE-PARAMETER'//&
                                  'Resample Equilibrum Distribution with reflection', '.FALSE.'&
                                , numberedmulti=.TRUE.)
CALL prms%CreateRealArrayOption('Part-Boundary[$]-WallVelo'  &
                                , 'Velocity (global x,y,z in [m/s]) of reflective particle boundary [$].' &
                                , '0. , 0. , 0.', numberedmulti=.TRUE.)
CALL prms%CreateLogicalOption(  'Part-Boundary[$]-SolidState'  &
                                , 'Flag defining if reflective BC is solid [TRUE] or liquid [FALSE].'&
                                , '.TRUE.', numberedmulti=.TRUE.)
CALL prms%CreateLogicalOption(  'Part-Boundary[$]-SolidCatalytic'  &
                                , 'Flag for defining solid surface to be treated catalytically (for surfacemodel>0).', '.FALSE.'&
                                , numberedmulti=.TRUE.)
CALL prms%CreateIntOption(      'Part-Boundary[$]-SolidSpec'  &
                                , 'Set Species of Solid Boundary. (currently not used)', '0', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Boundary[$]-SolidPartDens'  &
  , 'If particle boundary defined as solid set surface atom density (in [part/m^2]).', '1.0E+19', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Boundary[$]-SolidMassIC'  &
                                , 'Set mass of solid surface particles (in [kg]).', '3.2395E-25', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Boundary[$]-SolidAreaIncrease'  &
                                , 'TODO-DEFINE-PARAMETER ', '1.', numberedmulti=.TRUE.)
CALL prms%CreateIntOption(      'Part-Boundary[$]-SolidCrystalIndx'  &
                                , 'Set number of interaction for hollow sites.', '4', numberedmulti=.TRUE.)
CALL prms%CreateIntOption(      'Part-Boundary[$]-LiquidSpec'  &
                                , 'Set used species of Liquid Boundary', '0', numberedmulti=.TRUE.)
CALL prms%CreateRealArrayOption('Part-Boundary[$]-ParamAntoine'  &
                                , 'Parameters for Antoine Eq (vapor pressure)', '0. , 0. , 0.'&
                                , numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-Boundary[$]-ProbOfSpeciesSwaps'  &
                                , 'TODO-DEFINE-PARAMETER'//&
                                  'Probability of SpeciesSwaps at wall', '1.', numberedmulti=.TRUE.)
CALL prms%CreateIntArrayOption( 'Part-Boundary[$]-SpeciesSwaps[$]'  &
                                , 'TODO-DEFINE-PARAMETER'//&
                                  'Species to be changed at wall (out=: delete)', '0 , 0'&
                                , numberedmulti=.TRUE.)
CALL prms%CreateStringOption(   'Part-Boundary[$]-SourceName'  &
                                , 'TODO-DEFINE-PARAMETER'//&
                                  'No Default. Source Name of Boundary[i]. Has to be selected for all'//&
                                  'nBounds. Has to be same name as defined in preproc tool', numberedmulti=.TRUE.)
CALL prms%CreateLogicalOption(  'Part-Boundary[$]-UseForQCrit'  &
                                , 'TODO-DEFINE-PARAMETER'//&
                                  'Flag to use Boundary for Q-Criterion', '.TRUE.', numberedmulti=.TRUE.)

CALL prms%CreateIntOption(      'Part-nAuxBCs'  &
                                , 'TODO-DEFINE-PARAMETER'//&
                                  'Number of auxillary BCs that are checked during tracing',  '0')
CALL prms%CreateIntOption(      'Part-AuxBC[$]-NbrOfSpeciesSwaps'  &
                                , 'TODO-DEFINE-PARAMETER'//&
                                  'Number of Species to be changed at wall.',  '0', numberedmulti=.TRUE.)
CALL prms%CreateStringOption(   'Part-AuxBC[$]-Condition'  &
                                , 'TODO-DEFINE-PARAMETER'//&
                                  'Used auxillary boundary condition for boundary[$].'//&
                                  '- open'//&
                                  '- reflective'//&
                                  '- periodic)'//&
                                  '-> more details see also Part-Boundary[$]-Condition',  'open', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-AuxBC[$]-MomentumACC'  &
                                , 'TODO-DEFINE-PARAMETER'//&
                                  'Momentum accommodation',  '0', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-AuxBC[$]-WallTemp'  &
                                , 'TODO-DEFINE-PARAMETER'//&
                                  'Wall temperature of boundary[$]',  '0', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-AuxBC[$]-TransACC'  &
                                , 'TODO-DEFINE-PARAMETER'//&
                                  'Translation accommodation on boundary [$]',  '0', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-AuxBC[$]-VibACC'  &
                                , 'TODO-DEFINE-PARAMETER'//&
                                  'Vibrational accommodation on boundary [$]',  '0', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-AuxBC[$]-RotACC'  &
                                , 'TODO-DEFINE-PARAMETER'//&
                                  'Rotational accommodation on boundary [$]',  '0', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-AuxBC[$]-ElecACC'  &
                                , 'TODO-DEFINE-PARAMETER'//&
                                  'Electronic accommodation on boundary [$]',  '0', numberedmulti=.TRUE.)
CALL prms%CreateLogicalOption(  'Part-AuxBC[$]-Resample'  &
                                , 'TODO-DEFINE-PARAMETER'//&
                                  'Resample Equilibirum Distribution with reflection',  '.FALSE.'&
                                , numberedmulti=.TRUE.)
CALL prms%CreateRealArrayOption('Part-AuxBC[$]-WallVelo'  &
                                , 'TODO-DEFINE-PARAMETER'//&
                                  'Emitted velocity on boundary [$]', '0. , 0. , 0.', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-AuxBC[$]-ProbOfSpeciesSwaps'  &
                                , 'TODO-DEFINE-PARAMETER'//&
                                  'Probability of SpeciesSwaps at wall',  '1.', numberedmulti=.TRUE.)
CALL prms%CreateIntArrayOption( 'Part-AuxBC[$]-SpeciesSwaps[$]'  &
                                , 'TODO-DEFINE-PARAMETER'//&
                                  'Species to be changed at wall (out=: delete)', '0 , 0'&
                                , numberedmulti=.TRUE.)
CALL prms%CreateStringOption(   'Part-AuxBC[$]-Type'  &
                                , 'TODO-DEFINE-PARAMETER'//&
                                  'Type of BC (plane, ...)',  'plane', numberedmulti=.TRUE.)
CALL prms%CreateRealArrayOption('Part-AuxBC[$]-r_vec'  &
                                , 'TODO-DEFINE-PARAMETER', '0. , 0. , 0.', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-AuxBC[$]-radius'  &
                                , 'TODO-DEFINE-PARAMETER', numberedmulti=.TRUE.) !def. might be calculated!!!
CALL prms%CreateRealArrayOption('Part-AuxBC[$]-n_vec'  &
                                , 'TODO-DEFINE-PARAMETER', '1. , 0. , 0.', numberedmulti=.TRUE.)
CALL prms%CreateRealArrayOption('Part-AuxBC[$]-axis'  &
                                , 'TODO-DEFINE-PARAMETER', '1. , 0. , 0.', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-AuxBC[$]-lmin'  &
                                , 'TODO-DEFINE-PARAMETER', numberedmulti=.TRUE.) !def. might be calculated!!!
CALL prms%CreateRealOption(     'Part-AuxBC[$]-lmax'  &
                                , 'TODO-DEFINE-PARAMETER', numberedmulti=.TRUE.) !def. is calculated!!!
CALL prms%CreateLogicalOption(  'Part-AuxBC[$]-inwards'  &
                                , 'TODO-DEFINE-PARAMETER',  '.TRUE.', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-AuxBC[$]-rmax'  &
                                , 'TODO-DEFINE-PARAMETER',  '0.', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-AuxBC[$]-halfangle'  &
                                , 'TODO-DEFINE-PARAMETER',  '45.', numberedmulti=.TRUE.)
CALL prms%CreateRealOption(     'Part-AuxBC[$]-zfac'  &
                                , 'TODO-DEFINE-PARAMETER',  '1.', numberedmulti=.TRUE.)

END SUBROUTINE DefineParametersParticles

SUBROUTINE InitParticles()
!===================================================================================================================================
! Glue Subroutine for particle initialization 
!===================================================================================================================================
! MODULES
USE MOD_Globals!,       ONLY: MPIRoot,UNIT_STDOUT
USE MOD_ReadInTools
USE MOD_IO_HDF5,                    ONLY: AddToElemData,ElementOut
USE MOD_Mesh_Vars,                  ONLY: nElems
USE MOD_LoadBalance_Vars,           ONLY: nPartsPerElem
USE MOD_Particle_Vars,              ONLY: ParticlesInitIsDone,WriteMacroVolumeValues,WriteMacroSurfaceValues,nSpecies
USE MOD_Particle_Vars,              ONLY: MacroRestartData_tmp,PartSurfaceModel, LiquidSimFlag
USE MOD_part_emission,              ONLY: InitializeParticleEmission, InitializeParticleSurfaceflux
USE MOD_DSMC_Analyze,               ONLY: InitHODSMC
USE MOD_DSMC_Init,                  ONLY: InitDSMC
USE MOD_LD_Init,                    ONLY: InitLD
USE MOD_LD_Vars,                    ONLY: useLD
USE MOD_DSMC_Vars,                  ONLY: useDSMC, DSMC, DSMC_HOSolution,HODSMC
USE MOD_Mesh_Vars,                  ONLY: nElems
USE MOD_InitializeBackgroundField,  ONLY: InitializeBackgroundField
USE MOD_PICInterpolation_Vars,      ONLY: useBGField
USE MOD_Particle_Boundary_Sampling, ONLY: InitParticleBoundarySampling
USE MOD_SurfaceModel_Init,          ONLY: InitSurfaceModel, InitLiquidSurfaceModel
#ifdef MPI
USE MOD_Particle_MPI,               ONLY: InitParticleCommSize
#endif
! IMPLICIT VARIABLE HANDLING
 IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
!===================================================================================================================================
IF(ParticlesInitIsDone)THEN
   SWRITE(*,*) "InitParticles already called."
   RETURN
END IF
SWRITE(UNIT_StdOut,'(132("-"))')
SWRITE(UNIT_stdOut,'(A)') ' INIT PARTICLES ...'

IF(.NOT.ALLOCATED(nPartsPerElem))THEN
  ALLOCATE(nPartsPerElem(1:nElems))
  nPartsPerElem=0
  CALL AddToElemData(ElementOut,'nPartsPerElem',LongIntArray=nPartsPerElem(:))
END IF

CALL InitializeVariables()
IF(useBGField) CALL InitializeBackgroundField()

CALL InitializeParticleEmission()
CALL InitializeParticleSurfaceflux()

SDEALLOCATE(MacroRestartData_tmp) !might be used for adaptive BC initialization allocated in InitializeVariables()

! Initialize volume sampling
IF(useDSMC .OR. WriteMacroVolumeValues) THEN
! definition of DSMC sampling values
  DSMC%SampNum = 0
  HODSMC%SampleType = TRIM(GETSTR('DSMC-HOSampling-Type','cell_mean'))
  IF (TRIM(HODSMC%SampleType).EQ.'cell_mean') THEN
    HODSMC%nOutputDSMC = 1
    SWRITE(*,*) 'DSMCHO output order is set to 1 for sampling type cell_mean!'
    ALLOCATE(DSMC_HOSolution(1:11,1,1,1,1:nElems,1:nSpecies))
  ELSE
    HODSMC%nOutputDSMC = GETINT('Particles-DSMC-OutputOrder','1')
    ALLOCATE(DSMC_HOSolution(1:11,0:HODSMC%nOutputDSMC,0:HODSMC%nOutputDSMC,0:HODSMC%nOutputDSMC,1:nElems,1:nSpecies))
  END IF
  DSMC_HOSolution = 0.0
  CALL InitHODSMC()
END IF

! Initialize surface sampling
IF (WriteMacroSurfaceValues.OR.DSMC%CalcSurfaceVal.OR.(PartSurfaceModel.GT.0).OR.LiquidSimFlag) THEN
  CALL InitParticleBoundarySampling()
END IF

IF (useDSMC) THEN
  CALL  InitDSMC()
  IF (useLD) CALL InitLD
  IF (PartSurfaceModel.GT.0) CALL InitSurfaceModel()
  IF (LiquidSimFlag) CALL InitLiquidSurfaceModel()
ELSE IF (WriteMacroVolumeValues.OR.WriteMacroSurfaceValues) THEN
  DSMC%ElectronicModel = .FALSE.
  DSMC%OutputMeshInit  = .FALSE.
  DSMC%OutputMeshSamp  = .FALSE.
END IF

#ifdef MPI
! has to be called AFTER InitializeVariables and InitDSMC 
CALL InitParticleCommSize()
#endif

ParticlesInitIsDone=.TRUE.
SWRITE(UNIT_stdOut,'(A)')' INIT PARTICLES DONE!'
SWRITE(UNIT_StdOut,'(132("-"))')
END SUBROUTINE InitParticles


SUBROUTINE InitializeVariables()
!===================================================================================================================================
! Initialize the variables first 
!===================================================================================================================================
! MODULES
USE MOD_Globals
USE MOD_Globals_Vars
USE MOD_ReadInTools
USE MOD_Particle_Vars
USE MOD_Particle_Boundary_Vars ,ONLY: PartBound,nPartBound,nAdaptiveBC,PartAuxBC
USE MOD_Particle_Boundary_Vars ,ONLY: nAuxBCs,AuxBCType,AuxBCMap,AuxBC_plane,AuxBC_cylinder,AuxBC_cone,AuxBC_parabol,UseAuxBCs
USE MOD_Particle_Mesh_Vars     ,ONLY: NbrOfRegions,RegionBounds,GEO
USE MOD_Mesh_Vars              ,ONLY: nElems, BoundaryName,BoundaryType, nBCs
USE MOD_Particle_Surfaces_Vars ,ONLY: BCdata_auxSF
USE MOD_DSMC_Vars              ,ONLY: useDSMC, DSMC, BGGas
USE MOD_Particle_Output_Vars   ,ONLY: WriteFieldsToVTK
USE MOD_part_MPFtools          ,ONLY: DefinePolyVec, DefineSplitVec
USE MOD_PICInterpolation       ,ONLY: InitializeInterpolation
USE MOD_PICInit                ,ONLY: InitPIC
USE MOD_Particle_Mesh          ,ONLY: InitFIBGM,MapRegionToElem,MarkAuxBCElems
USE MOD_Particle_Tracking_Vars ,ONLY: DoRefMapping
USE MOD_Particle_MPI_Vars      ,ONLY: SafetyFactor,halo_eps_velo
USE MOD_part_pressure          ,ONLY: ParticlePressureIni,ParticlePressureCellIni
USE MOD_TimeDisc_Vars          ,ONLY: TEnd
#if defined(ROS) || defined (IMPA)
USE MOD_TimeDisc_Vars          ,ONLY: nRKStages
#endif /*ROS*/
#ifdef MPI
USE MOD_Particle_MPI           ,ONLY: InitEmissionComm
USE MOD_LoadBalance_Vars       ,ONLY: PerformLoadBalance
USE MOD_Particle_MPI_Vars      ,ONLY: PartMPI
#endif /*MPI*/
! IMPLICIT VARIABLE HANDLING
 IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
INTEGER               :: iSpec, iInit, iPartBound, iSeed, iCC
INTEGER               :: SeedSize, iPBC, iBC, iSwaps, iRegions, iExclude, nRandomSeeds
INTEGER               :: iAuxBC, nAuxBCplanes, nAuxBCcylinders, nAuxBCcones, nAuxBCparabols
INTEGER               :: ALLOCSTAT
CHARACTER(32)         :: hilf , hilf2, hilf3
CHARACTER(200)        :: tmpString
LOGICAL               :: PartDens_OnlyInit
REAL                  :: iRan, aVec, bVec   ! random numbers for random vectors
REAL                  :: lineVector(3), v_drift_line, A_ins, n_vec(3), cos2, rmax
INTEGER               :: iVec, MaxNbrOfSpeciesSwaps,iIMDSpec
LOGICAL               :: exitTrue,IsIMDSpecies
REAL, DIMENSION(3,1)  :: n,n1,n2
REAL, DIMENSION(3,3)  :: rot1, rot2
REAL                  :: alpha1, alpha2
INTEGER               :: dummy_int
INTEGER               :: MacroRestartFileID
LOGICAL,ALLOCATABLE   :: MacroRestartFileUsed(:)
INTEGER               :: FileID, iElem
REAL                  :: particlenumber_tmp, phimax_tmp
!===================================================================================================================================
! Read print flags
printRandomSeeds = GETLOGICAL('printRandomSeeds','.FALSE.')
! Read basic particle parameter
PDM%maxParticleNumber = GETINT('Part-maxParticleNumber','1')
#if (PP_TimeDiscMethod==509)
velocityOutputAtTime = GETLOGICAL('velocityOutputAtTime','.FALSE.')
#endif

!#if (PP_TimeDiscMethod==1)||(PP_TimeDiscMethod==2)||(PP_TimeDiscMethod==6)||(PP_TimeDiscMethod>=501 && PP_TimeDiscMethod<=506)
#if defined(LSERK)
!print*, "SFSDRWE#"
ALLOCATE(Pt_temp(1:PDM%maxParticleNumber,1:6), STAT=ALLOCSTAT)  
IF (ALLOCSTAT.NE.0) THEN
  CALL abort(&
__STAMP__&
  ,'ERROR in particle_init.f90: Cannot allocate Particle arrays!')
END IF
Pt_temp=0.
#endif 
#if (PP_TimeDiscMethod==509)
IF (velocityOutputAtTime) THEN
  ALLOCATE(velocityAtTime(1:PDM%maxParticleNumber,1:3), STAT=ALLOCSTAT)
  IF (ALLOCSTAT.NE.0) THEN
    CALL abort(&
      __STAMP__&
      ,'ERROR in particle_init.f90: Cannot allocate velocityAtTime array!')
  END IF
  velocityAtTime=0.
END IF
#endif /*(PP_TimeDiscMethod==509)*/

#ifdef IMPA
ALLOCATE(PartStage(1:PDM%maxParticleNumber,1:6,1:nRKStages-1), STAT=ALLOCSTAT)  ! save memory
IF (ALLOCSTAT.NE.0) THEN
  CALL abort(&
__STAMP__&
  ,' Cannot allocate PartStage arrays!')
END IF
ALLOCATE(PartStateN(1:PDM%maxParticleNumber,1:6), STAT=ALLOCSTAT)  
IF (ALLOCSTAT.NE.0) THEN
  CALL abort(&
__STAMP__&
  ,' Cannot allocate PartStateN arrays!')
END IF
ALLOCATE(PartQ(1:6,1:PDM%maxParticleNumber), STAT=ALLOCSTAT)  ! save memory
IF (ALLOCSTAT.NE.0) THEN
  CALL abort(&
__STAMP__&
  ,'Cannot allocate PartQ arrays!')
END IF
! particle function values at X0
ALLOCATE(F_PartX0(1:6,1:PDM%maxParticleNumber), STAT=ALLOCSTAT)  ! save memory
IF (ALLOCSTAT.NE.0) THEN
  CALL abort(&
__STAMP__&
  ,'Cannot allocate F_PartX0 arrays!')
END IF
! particle function values at Xk
ALLOCATE(F_PartXk(1:6,1:PDM%maxParticleNumber), STAT=ALLOCSTAT)  ! save memory
IF (ALLOCSTAT.NE.0) THEN
  CALL abort(&
__STAMP__&
  ,'Cannot allocate F_PartXk arrays!')
END IF
! and the required norms
ALLOCATE(Norm_F_PartX0(1:PDM%maxParticleNumber), STAT=ALLOCSTAT)  ! save memory
IF (ALLOCSTAT.NE.0) THEN
  CALL abort(&
__STAMP__&
  ,'Cannot allocate Norm_F_PartX0 arrays!')
END IF
ALLOCATE(Norm_F_PartXk(1:PDM%maxParticleNumber), STAT=ALLOCSTAT)  ! save memory
IF (ALLOCSTAT.NE.0) THEN
  CALL abort(&
__STAMP__&
  ,'Cannot allocate Norm_F_PartXk arrays!')
END IF
ALLOCATE(Norm_F_PartXk_old(1:PDM%maxParticleNumber), STAT=ALLOCSTAT)  ! save memory
IF (ALLOCSTAT.NE.0) THEN
  CALL abort(&
__STAMP__&
  ,'Cannot allocate Norm_F_PartXk_old arrays!')
END IF
ALLOCATE(PartDeltaX(1:6,1:PDM%maxParticleNumber), STAT=ALLOCSTAT)  ! save memory
IF (ALLOCSTAT.NE.0) THEN
  CALL abort(&
__STAMP__&
  ,'Cannot allocate PartDeltaX arrays!')
END IF
ALLOCATE(PartLambdaAccept(1:PDM%maxParticleNumber), STAT=ALLOCSTAT)  ! save memory
IF (ALLOCSTAT.NE.0) THEN
  CALL abort(&
__STAMP__&
  ,'Cannot allocate PartLambdaAccept arrays!')
END IF
ALLOCATE(DoPartInNewton(1:PDM%maxParticleNumber), STAT=ALLOCSTAT)  ! save memory
IF (ALLOCSTAT.NE.0) THEN
  CALL abort(&
__STAMP__&
      ,'Cannot allocate DoPartInNewton arrays!')
END IF
#endif /* IMPA */
#ifdef ROS
ALLOCATE(PartStage(1:PDM%maxParticleNumber,1:6,1:nRKStages-1), STAT=ALLOCSTAT)  ! save memory
IF (ALLOCSTAT.NE.0) THEN
  CALL abort(&
__STAMP__&
  ,' Cannot allocate PartStage arrays!')
END IF
ALLOCATE(PartStateN(1:PDM%maxParticleNumber,1:6), STAT=ALLOCSTAT)  
IF (ALLOCSTAT.NE.0) THEN
  CALL abort(&
__STAMP__&
  ,' Cannot allocate PartStateN arrays!')
END IF
ALLOCATE(PartQ(1:6,1:PDM%maxParticleNumber), STAT=ALLOCSTAT)  ! save memory
IF (ALLOCSTAT.NE.0) THEN
  CALL abort(&
__STAMP__&
  ,'Cannot allocate PartQ arrays!')
END IF
ALLOCATE(PartDtFrac(1:PDM%maxParticleNumber), STAT=ALLOCSTAT)  ! save memory
IF (ALLOCSTAT.NE.0) THEN
  CALL abort(&
__STAMP__&
  ,' Cannot allocate PartDtFrac arrays!')
END IF
PartDtFrac=1.
ALLOCATE(PEM%ElementN(1:PDM%maxParticleNumber),STAT=ALLOCSTAT) 
IF (ALLOCSTAT.NE.0) THEN
   CALL abort(&
 __STAMP__&
   ,' Cannot allocate the stage position and element arrays!')
END IF
PEM%ElementN=0
ALLOCATE(PEM%NormVec(1:PDM%maxParticleNumber,1:3),STAT=ALLOCSTAT) 
IF (ALLOCSTAT.NE.0) THEN
   CALL abort(&
 __STAMP__&
   ,' Cannot allocate the normal vector for reflections!')
END IF
PEM%NormVec=0
ALLOCATE(PEM%PeriodicMoved(1:PDM%maxParticleNumber),STAT=ALLOCSTAT) 
IF (ALLOCSTAT.NE.0) THEN
   CALL abort(&
 __STAMP__&
   ,' Cannot allocate the stage position and element arrays!')
END IF
PEM%PeriodicMoved=.FALSE.
#endif /* ROSENBROCK */

#if IMPA
ALLOCATE(PartIsImplicit(1:PDM%maxParticleNumber), STAT=ALLOCSTAT)  ! save memory
IF (ALLOCSTAT.NE.0) THEN
  CALL abort(&
__STAMP__&
  ,' Cannot allocate PartIsImplicit arrays!')
END IF
PartIsImplicit=.FALSE.
ALLOCATE(PartDtFrac(1:PDM%maxParticleNumber), STAT=ALLOCSTAT)  ! save memory
IF (ALLOCSTAT.NE.0) THEN
  CALL abort(&
__STAMP__&
  ,' Cannot allocate PartDtFrac arrays!')
END IF
PartDtFrac=1.
ALLOCATE(PEM%ElementN(1:PDM%maxParticleNumber),STAT=ALLOCSTAT) 
IF (ALLOCSTAT.NE.0) THEN
   CALL abort(&
 __STAMP__&
   ,' Cannot allocate the stage position and element arrays!')
END IF
PEM%ElementN=0
ALLOCATE(PEM%NormVec(1:PDM%maxParticleNumber,1:3),STAT=ALLOCSTAT) 
IF (ALLOCSTAT.NE.0) THEN
   CALL abort(&
 __STAMP__&
   ,' Cannot allocate the normal vector for reflections!')
END IF
PEM%NormVec=0
ALLOCATE(PEM%PeriodicMoved(1:PDM%maxParticleNumber),STAT=ALLOCSTAT) 
IF (ALLOCSTAT.NE.0) THEN
   CALL abort(&
 __STAMP__&
   ,' Cannot allocate the stage position and element arrays!')
END IF
PEM%PeriodicMoved=.FALSE.
#endif

IF(DoRefMapping)THEN
  ALLOCATE(PartPosRef(1:3,PDM%MaxParticleNumber), STAT=ALLOCSTAT)
  IF (ALLOCSTAT.NE.0) CALL abort(&
  __STAMP__&
  ,' Cannot allocate partposref!')
  PartPosRef=-888.
END IF

! predefine random vectors
NumRanVec = GETINT('Particles-NumberOfRandomVectors','100000')
IF ((usevMPF).OR.(useDSMC)) THEN
  ALLOCATE(RandomVec(NumRanVec, 3))
  RandomVec = 0
  DO iVec = 1, NumRanVec  ! calculation of NumRanVec different Vectors
    CALL RANDOM_NUMBER(iRan)
    bVec              = 1 - 2*iRan
    aVec              = SQRT(1 - bVec**2)
    RandomVec(iVec,1) = bVec
    CALL RANDOM_NUMBER(iRan)
    bVec              = Pi *2 * iRan
    RandomVec(iVec,2) = aVec * COS(bVec)
    RandomVec(iVec,3) = aVec * SIN(bVec)
  END DO
END IF

ALLOCATE(PartState(1:PDM%maxParticleNumber,1:6)       , &
         LastPartPos(1:PDM%maxParticleNumber,1:3)     , &
         Pt(1:PDM%maxParticleNumber,1:3)              , &
         PartSpecies(1:PDM%maxParticleNumber)         , &
         PDM%ParticleInside(1:PDM%maxParticleNumber)  , &
         PDM%nextFreePosition(1:PDM%maxParticleNumber), &
         PDM%dtFracPush(1:PDM%maxParticleNumber)      , &
         PDM%IsNewPart(1:PDM%maxParticleNumber), STAT=ALLOCSTAT)
IF (ALLOCSTAT.NE.0) THEN
  CALL abort(&
__STAMP__&
  ,'ERROR in particle_init.f90: Cannot allocate Particle arrays!')
END IF
PDM%ParticleInside(1:PDM%maxParticleNumber) = .FALSE.
PDM%dtFracPush(1:PDM%maxParticleNumber) = .FALSE.
PDM%IsNewPart(1:PDM%maxParticleNumber) = .FALSE.
LastPartPos(1:PDM%maxParticleNumber,1:3)    = 0.
PartState=0.
Pt=0.
PartSpecies        = 0
PDM%nextFreePosition(1:PDM%maxParticleNumber)=0

nSpecies = GETINT('Part-nSpecies','1')

! IMD data import from *.chkpt file
DoImportIMDFile=.FALSE. ! default
IMDLengthScale=0.0

IMDTimeScale          = GETREAL('IMDTimeScale','10.18e-15')
IMDLengthScale        = GETREAL('IMDLengthScale','1.0E-10')
IMDAtomFile           = GETSTR( 'IMDAtomFile','no file found')         
IMDCutOff             = GETSTR( 'IMDCutOff','no_cutoff')
IMDCutOffxValue       = GETREAL('IMDCutOffxValue','-999.9')

IF(TRIM(IMDAtomFile).NE.'no file found')DoImportIMDFile=.TRUE.
IF(DoImportIMDFile)THEN
  DoRefMapping=.FALSE. ! for faster init don't use DoRefMapping!
  SWRITE(UNIT_stdOut,'(A68,L,A)') ' | DoImportIMDFile=T DoRefMapping |                                 ',DoRefMapping,&
  ' | *CHANGE |'
END IF


! init varibale MPF per particle
IF (usevMPF) THEN
  enableParticleMerge = GETLOGICAL('Part-vMPFPartMerge','.FALSE.')
  IF (enableParticleMerge) THEN
    vMPFMergePolyOrder = GETINT('Part-vMPFMergePolOrder','2')
    vMPFMergeCellSplitOrder = GETINT('Part-vMPFCellSplitOrder','15')
    vMPFMergeParticleTarget = GETINT('Part-vMPFMergeParticleTarget','0')
    IF (vMPFMergeParticleTarget.EQ.0) WRITE(*,*) 'vMPFMergeParticleTarget equals zero: no merging is performed!'
    vMPFSplitParticleTarget = GETINT('Part-vMPFSplitParticleTarget','0')
    IF (vMPFSplitParticleTarget.EQ.0) WRITE(*,*) 'vMPFSplitParticleTarget equals zero: no split is performed!'
    vMPFMergeParticleIter = GETINT('Part-vMPFMergeParticleIter','100')
    vMPF_velocityDistribution = TRIM(GETSTR('Part-vMPFvelocityDistribution','OVDR'))
    vMPF_relativistic = GETLOGICAL('Part-vMPFrelativistic','.FALSE.')
    IF(vMPF_relativistic.AND.(vMPF_velocityDistribution.EQ.'MBDR')) THEN
      CALL abort(&
__STAMP__&
      ,'Relativistic handling of vMPF is not possible using MBDR velocity distribution!')
    END IF
    ALLOCATE(vMPF_SpecNumElem(1:nElems,1:nSpecies))
  END IF
  ALLOCATE(PartMPF(1:PDM%maxParticleNumber), STAT=ALLOCSTAT)
  IF (ALLOCSTAT.NE.0) THEN
    CALL abort(&
__STAMP__&
    ,'ERROR in particle_init.f90: Cannot allocate Particle arrays!')
  END IF
END IF
           
! output of macroscopic values
WriteMacroValues = GETLOGICAL('Part-WriteMacroValues','.FALSE.')
WriteMacroVolumeValues = GETLOGICAL('Part-WriteMacroVolumeValues','.FALSE.')
WriteMacroSurfaceValues = GETLOGICAL('Part-WriteMacroSurfaceValues','.FALSE.')
IF(WriteMacroValues)THEN
  WriteMacroVolumeValues = .TRUE.
  WriteMacroSurfaceValues = .TRUE.
ELSE IF((WriteMacroVolumeValues.AND.WriteMacroSurfaceValues).AND.(.NOT.WriteMacroValues))THEN
  WriteMacroValues = .TRUE.
END IF
MacroValSamplIterNum = GETINT('Part-IterationForMacroVal','1')
DSMC%TimeFracSamp = GETREAL('Part-TimeFracForSampling','0.0')
DSMC%CalcSurfaceVal = GETLOGICAL('Particles-DSMC-CalcSurfaceVal','.FALSE.')
IF(WriteMacroVolumeValues.OR.WriteMacroSurfaceValues)THEN
  IF(DSMC%TimeFracSamp.GT.0.0) CALL abort(&
__STAMP__&
    ,'ERROR: Init Macrosampling: WriteMacroValues and Time fraction sampling enabled at the same time')
  IF(WriteMacroSurfaceValues.AND.(.NOT.DSMC%CalcSurfaceVal)) DSMC%CalcSurfaceVal = .TRUE.
END IF
DSMC%NumOutput = GETINT('Particles-NumberForDSMCOutputs','0')
IF((DSMC%TimeFracSamp.GT.0.0).AND.(DSMC%NumOutput.EQ.0)) DSMC%NumOutput = 1
IF (DSMC%NumOutput.NE.0) THEN
  IF (DSMC%TimeFracSamp.GT.0.0) THEN
    DSMC%DeltaTimeOutput = (DSMC%TimeFracSamp * TEnd) / REAL(DSMC%NumOutput)
  ELSE
    DSMC%NumOutput=0
    SWRITE(UNIT_STDOUT,*)'DSMC_NumOutput was set to 0 because timefracsamp is 0.0'
  END IF
END IF

!ParticlePushMethod = TRIM(GETSTR('Part-ParticlePushMethod','boris_leap_frog_scheme')
WriteFieldsToVTK = GETLOGICAL('Part-WriteFieldsToVTK','.FALSE.')

!!!! Logicals for Constant Pressure in Cells
! are particles to be ADDED to cells in order to reach constant pressure? Default YES
PartPressAddParts = GETLOGICAL('Part-ConstPressAddParts','.TRUE.')
! are particles to be REMOVED from cells in order to reach constant pressure? Default NO
PartPressRemParts = GETLOGICAL('Part-ConstPressRemParts','.FALSE.')

! Read particle species data
!nSpecies = CNTSTR('Part-Species-SpaceIC')

IF (nSpecies.LE.0) THEN
  CALL abort(&
__STAMP__&
  ,'ERROR: nSpecies .LE. 0:', nSpecies)
END IF

! initialize macroscopic restart
ALLOCATE(SpecReset(1:nSpecies))
SpecReset=.FALSE.
nMacroRestartFiles = GETINT('Part-nMacroRestartFiles')
IF (nMacroRestartFiles.GT.0) THEN
  ALLOCATE(MacroRestartFileUsed(1:nMacroRestartFiles))
  MacroRestartFileUsed(:)=.FALSE.
  ALLOCATE(MacroRestartData_tmp(1:DSMC_NVARS,1:nElems,1:nSpecies,1:nMacroRestartFiles))
  CALL ReadMacroRestartFiles(MacroRestartData_tmp)
END IF ! nMacroRestartFiles.GT.0

PartPressureCell = .FALSE.
ALLOCATE(Species(1:nSpecies))

DoFieldIonization = GETLOGICAL('Part-DoFieldIonization')

DO iSpec = 1, nSpecies
  WRITE(UNIT=hilf,FMT='(I0)') iSpec
  Species(iSpec)%NumberOfInits         = GETINT('Part-Species'//TRIM(hilf)//'-nInits','0')
#ifdef MPI
  IF(.NOT.PerformLoadBalance) THEN
#endif /*MPI*/
    SpecReset(iSpec)                     = GETLOGICAL('Part-Species'//TRIM(hilf)//'-Reset','.FALSE.')
#ifdef MPI
  END IF
#endif /*MPI*/
  ALLOCATE(Species(iSpec)%Init(0:Species(iSpec)%NumberOfInits))
  DO iInit = 0, Species(iSpec)%NumberOfInits
    ! set help characters
    IF(iInit.EQ.0)THEN
      hilf2=TRIM(hilf)
    ELSE ! iInit >0
      WRITE(UNIT=hilf2,FMT='(I0)') iInit
      hilf2=TRIM(hilf)//'-Init'//TRIM(hilf2)
    END IF ! iInit
    ! get species values // only once
    IF(iInit.EQ.0)THEN
      !General Species Values
      Species(iSpec)%ChargeIC              = GETREAL('Part-Species'//TRIM(hilf2)//'-ChargeIC','0.')
      Species(iSpec)%MassIC                = GETREAL('Part-Species'//TRIM(hilf2)//'-MassIC','0.')
      Species(iSpec)%MacroParticleFactor   = GETREAL('Part-Species'//TRIM(hilf2)//'-MacroParticleFactor','1.')
#if defined(IMPA)
      Species(iSpec)%IsImplicit            = GETLOGICAL('Part-Species'//TRIM(hilf2)//'-IsImplicit','.FALSE.')
#endif
    END IF ! iInit
    Species(iSpec)%Init(iInit)%SpaceIC               = TRIM(GETSTR('Part-Species'//TRIM(hilf2)//'-SpaceIC','cell_local'))
    ! initilize macrorestart files and arrays
    !-------------------------------------------------------------------------------------------------------------------------------
    IF (TRIM(Species(iSpec)%Init(iInit)%SpaceIC).EQ.'cell_local') THEN
      ! get emission and init data
      Species(iSpec)%Init(iInit)%UseForInit            = GETLOGICAL('Part-Species'//TRIM(hilf2)//'-UseForInit','.TRUE.')
      !Species(iSpec)%Init(iInit)%UseForEmission        = GETLOGICAL('Part-Species'//TRIM(hilf2)//'-UseForEmission','.FALSE.')
      Species(iSpec)%Init(iInit)%UseForEmission        = .FALSE.
      IF (nMacroRestartFiles.GT.0) THEN
        MacroRestartFileID = GETINT('Part-Species'//TRIM(hilf2)//'-MacroRestartFileID','0')
        WRITE(UNIT=hilf3,FMT='(I0)') MacroRestartFileID
        Species(iSpec)%Init(iInit)%ElemTemperatureFileID = GETINT('Part-Species'//TRIM(hilf2)//'-ElemTemperatureFileID',TRIM(hilf3))
        Species(iSpec)%Init(iInit)%ElemPartDensityFileID = GETINT('Part-Species'//TRIM(hilf2)//'-ElemPartDensityFileID',TRIM(hilf3))
        Species(iSpec)%Init(iInit)%ElemVelocityICFileID  = GETINT('Part-Species'//TRIM(hilf2)//'-ElemVelocityICFileID',TRIM(hilf3))
        IF (useDSMC) THEN
          Species(iSpec)%Init(iInit)%ElemTVibFileID  = GETINT('Part-Species'//TRIM(hilf2)//'-ElemTVibFileID',TRIM(hilf3))
          Species(iSpec)%Init(iInit)%ElemTRotFileID  = GETINT('Part-Species'//TRIM(hilf2)//'-ElemTRotFileID',TRIM(hilf3))
          Species(iSpec)%Init(iInit)%ElemTElecFileID = GETINT('Part-Species'//TRIM(hilf2)//'-ElemTElecFileID',TRIM(hilf3))
        ELSE
          Species(iSpec)%Init(iInit)%ElemTVibFileID  = 0
          Species(iSpec)%Init(iInit)%ElemTRotFileID  = 0
          Species(iSpec)%Init(iInit)%ElemTElecFileID = 0
        END IF
      ELSE
        Species(iSpec)%Init(iInit)%ElemTemperatureFileID = 0
        Species(iSpec)%Init(iInit)%ElemPartDensityFileID = 0
        Species(iSpec)%Init(iInit)%ElemVelocityICFileID  = 0
        Species(iSpec)%Init(iInit)%ElemTVibFileID  = 0
        Species(iSpec)%Init(iInit)%ElemTRotFileID  = 0
        Species(iSpec)%Init(iInit)%ElemTElecFileID = 0
      END IF
      IF (Species(iSpec)%Init(iInit)%ElemTemperatureFileID.GT.0 .OR. &
          Species(iSpec)%Init(iInit)%ElemPartDensityFileID.GT.0 .OR. &
          Species(iSpec)%Init(iInit)%ElemVelocityICFileID.GT.0 .OR. &
          Species(iSpec)%Init(iInit)%ElemTVibFileID.GT.0 .OR. &
          Species(iSpec)%Init(iInit)%ElemTRotFileID.GT.0 .OR. &
          Species(iSpec)%Init(iInit)%ElemTElecFileID.GT.0 ) THEN
#ifdef MPI
        IF(.NOT.PerformLoadBalance) THEN
#endif /*MPI*/
          IF(.NOT.SpecReset(iSpec)) THEN
            SWRITE(*,*) "WARNING: Species-",iSpec," will be reset from macroscopic values."
          END IF
          SpecReset(iSpec)=.TRUE.
#ifdef MPI
        END IF
#endif /*MPI*/
        FileID = Species(iSpec)%Init(iInit)%ElemTemperatureFileID
        IF (FileID.GT.0 .AND. FileID.LE.nMacroRestartFiles) THEN
          MacroRestartFileUsed(FileID) = .TRUE.
          SDEALLOCATE(Species(iSpec)%Init(iInit)%ElemTemperatureIC)
          ALLOCATE(Species(iSpec)%Init(iInit)%ElemTemperatureIC(1:3,1:nElems))
          ! negative temperature can lead to NAN velocities if in those areas particles are inserted given by either other 
          ! macro-file or by init value --> leads to NANs in crela2 --> always max(0.,macroval)
          DO iElem = 1,nElems
            Species(iSpec)%Init(iInit)%ElemTemperatureIC(1,iElem) = MAX(0.,MacroRestartData_tmp(DSMC_TEMPX,iElem,iSpec,FileID))
            Species(iSpec)%Init(iInit)%ElemTemperatureIC(2,iElem) = MAX(0.,MacroRestartData_tmp(DSMC_TEMPY,iElem,iSpec,FileID))
            Species(iSpec)%Init(iInit)%ElemTemperatureIC(3,iElem) = MAX(0.,MacroRestartData_tmp(DSMC_TEMPZ,iElem,iSpec,FileID))
          END DO
        END IF
        FileID = Species(iSpec)%Init(iInit)%ElemPartDensityFileID
        IF (FileID.GT.0 .AND. FileID.LE.nMacroRestartFiles) THEN
          MacroRestartFileUsed(FileID) = .TRUE.
          SDEALLOCATE(Species(iSpec)%Init(iInit)%ElemPartDensity)
          ALLOCATE(Species(iSpec)%Init(iInit)%ElemPartDensity(1:nElems))
          DO iElem = 1,nElems
            Species(iSpec)%Init(iInit)%ElemPartDensity(iElem) = MacroRestartData_tmp(DSMC_DENSITY,iElem,iSpec,FileID)
          END DO
        END IF
        FileID = Species(iSpec)%Init(iInit)%ElemVelocityICFileID
        IF (FileID.GT.0 .AND. FileID.LE.nMacroRestartFiles) THEN
          MacroRestartFileUsed(FileID) = .TRUE.
          SDEALLOCATE(Species(iSpec)%Init(iInit)%ElemVelocityIC)
          ALLOCATE(Species(iSpec)%Init(iInit)%ElemVelocityIC(1:3,1:nElems))
          DO iElem = 1,nElems
            Species(iSpec)%Init(iInit)%ElemVelocityIC(1,iElem) = MacroRestartData_tmp(DSMC_VELOX,iElem,iSpec,FileID)
            Species(iSpec)%Init(iInit)%ElemVelocityIC(2,iElem) = MacroRestartData_tmp(DSMC_VELOY,iElem,iSpec,FileID)
            Species(iSpec)%Init(iInit)%ElemVelocityIC(3,iElem) = MacroRestartData_tmp(DSMC_VELOZ,iElem,iSpec,FileID)
          END DO
        END IF
        FileID = Species(iSpec)%Init(iInit)%ElemTVibFileID
        IF (FileID.GT.0 .AND. FileID.LE.nMacroRestartFiles) THEN
          MacroRestartFileUsed(FileID) = .TRUE.
          SDEALLOCATE(Species(iSpec)%Init(iInit)%ElemTVib)
          ALLOCATE(Species(iSpec)%Init(iInit)%ElemTVib(1:nElems))
          DO iElem = 1,nElems
            Species(iSpec)%Init(iInit)%ElemTVib(iElem) = MAX(0.,MacroRestartData_tmp(DSMC_TVIB,iElem,iSpec,FileID))
          END DO
        END IF
        FileID = Species(iSpec)%Init(iInit)%ElemTRotFileID
        IF (FileID.GT.0 .AND. FileID.LE.nMacroRestartFiles) THEN
          MacroRestartFileUsed(FileID) = .TRUE.
          SDEALLOCATE(Species(iSpec)%Init(iInit)%ElemTRot)
          ALLOCATE(Species(iSpec)%Init(iInit)%ElemTRot(1:nElems))
          DO iElem = 1,nElems
            Species(iSpec)%Init(iInit)%ElemTRot(iElem) = MAX(0.,MacroRestartData_tmp(DSMC_TROT,iElem,iSpec,FileID))
          END DO
        END IF
        FileID = Species(iSpec)%Init(iInit)%ElemTElecFileID
        IF (FileID.GT.0 .AND. FileID.LE.nMacroRestartFiles) THEN
          MacroRestartFileUsed(FileID) = .TRUE.
          SDEALLOCATE(Species(iSpec)%Init(iInit)%ElemTElec)
          ALLOCATE(Species(iSpec)%Init(iInit)%ElemTElec(1:nElems))
          DO iElem = 1,nElems
            Species(iSpec)%Init(iInit)%ElemTElec(iElem) = MAX(0.,MacroRestartData_tmp(DSMC_TELEC,iElem,iSpec,FileID))
          END DO
        END IF
      END IF
    ELSE ! SpaceIC not cell_local
      Species(iSpec)%Init(iInit)%UseForInit            = GETLOGICAL('Part-Species'//TRIM(hilf2)//'-UseForInit')
      Species(iSpec)%Init(iInit)%UseForEmission        = GETLOGICAL('Part-Species'//TRIM(hilf2)//'-UseForEmission')
      Species(iSpec)%Init(iInit)%ElemTemperatureFileID= 0
      Species(iSpec)%Init(iInit)%ElemPartDensityFileID= 0
      Species(iSpec)%Init(iInit)%ElemVelocityICFileID = 0
      Species(iSpec)%Init(iInit)%ElemTVibFileID       = 0
      Species(iSpec)%Init(iInit)%ElemTRotFileID       = 0
      Species(iSpec)%Init(iInit)%ElemTElecFileID      = 0
    END IF
    !-------------------------------------------------------------------------------------------------------------------------------
    IF (Species(iSpec)%Init(iInit)%ElemTemperatureFileID.EQ.0) THEN
      Species(iSpec)%Init(iInit)%velocityDistribution  = TRIM(GETSTR('Part-Species'//TRIM(hilf2)//'-velocityDistribution'&
        ,'constant'))
    ELSE
      Species(iSpec)%Init(iInit)%velocityDistribution  = TRIM(GETSTR('Part-Species'//TRIM(hilf2)//'-velocityDistribution'&
        ,'maxwell_lpn'))
    END IF
    IF(TRIM(Species(iSpec)%Init(iInit)%velocityDistribution).EQ.'tangential_constant')THEN
      Species(iSpec)%Init(iInit)%Rotation        = GETINT('Part-Species'//TRIM(hilf2)//'-rotation','1')
      Species(iSpec)%Init(iInit)%VelocitySpread  = GETREAL('Part-Species'//TRIM(hilf2)//'-velocityspread','0.')
      IF(Species(iSpec)%Init(iInit)%VelocitySpread.LT.0. .OR. Species(iSpec)%Init(iInit)%VelocitySpread.GT.1.) CALL abort(&
__STAMP__&
          ,' Wrong input parameter for VelocitySpread in [0;1].')
      Species(iSpec)%Init(iInit)%VelocitySpreadMethod  = GETINT('Part-Species'//TRIM(hilf2)//'-velocityspreadmethod','0')
    END IF
    Species(iSpec)%Init(iInit)%InflowRiseTime        = GETREAL('Part-Species'//TRIM(hilf2)//'-InflowRiseTime','0.')
    IF (Species(iSpec)%Init(iInit)%ElemPartDensityFileID.EQ.0) THEN
      Species(iSpec)%Init(iInit)%initialParticleNumber = GETINT('Part-Species'//TRIM(hilf2)//'-initialParticleNumber','0')
    ELSE
      Species(iSpec)%Init(iInit)%initialParticleNumber = 0 !dummy
    END IF
    Species(iSpec)%Init(iInit)%RadiusIC              = GETREAL('Part-Species'//TRIM(hilf2)//'-RadiusIC','1.')
    Species(iSpec)%Init(iInit)%Radius2IC             = GETREAL('Part-Species'//TRIM(hilf2)//'-Radius2IC','0.')
    Species(iSpec)%Init(iInit)%RadiusICGyro          = GETREAL('Part-Species'//TRIM(hilf2)//'-RadiusICGyro','1.')
    Species(iSpec)%Init(iInit)%NormalIC              = GETREALARRAY('Part-Species'//TRIM(hilf2)//'-NormalIC',3,'0. , 0. , 1.')
    Species(iSpec)%Init(iInit)%BasePointIC           = GETREALARRAY('Part-Species'//TRIM(hilf2)//'-BasePointIC',3,'0. , 0. , 0.')
    Species(iSpec)%Init(iInit)%BaseVector1IC         = GETREALARRAY('Part-Species'//TRIM(hilf2)//'-BaseVector1IC',3,'1. , 0. , 0.')
    Species(iSpec)%Init(iInit)%BaseVector2IC         = GETREALARRAY('Part-Species'//TRIM(hilf2)//'-BaseVector2IC',3,'0. , 1. , 0.')
    Species(iSpec)%Init(iInit)%CuboidHeightIC        = GETREAL('Part-Species'//TRIM(hilf2)//'-CuboidHeightIC','1.')
    Species(iSpec)%Init(iInit)%CylinderHeightIC      = GETREAL('Part-Species'//TRIM(hilf2)//'-CylinderHeightIC','1.')
    Species(iSpec)%Init(iInit)%CalcHeightFromDt      = GETLOGICAL('Part-Species'//TRIM(hilf2)//'-CalcHeightFromDt','.FALSE.')
    IF (Species(iSpec)%Init(iInit)%ElemVelocityICFileID.EQ.0) THEN
      Species(iSpec)%Init(iInit)%VeloIC                = GETREAL('Part-Species'//TRIM(hilf2)//'-VeloIC','0.')
      Species(iSpec)%Init(iInit)%VeloVecIC             = GETREALARRAY('Part-Species'//TRIM(hilf2)//'-VeloVecIC',3,'0. , 0. , 0.')
    END IF
    Species(iSpec)%Init(iInit)%Amplitude             = GETREAL('Part-Species'//TRIM(hilf2)//'-Amplitude','0.01')
    Species(iSpec)%Init(iInit)%WaveNumber            = GETREAL('Part-Species'//TRIM(hilf2)//'-WaveNumber','2.')
    Species(iSpec)%Init(iInit)%maxParticleNumberX    = GETINT('Part-Species'//TRIM(hilf2)//'-maxParticleNumber-x','0')
    Species(iSpec)%Init(iInit)%maxParticleNumberY    = GETINT('Part-Species'//TRIM(hilf2)//'-maxParticleNumber-y','0')
    Species(iSpec)%Init(iInit)%maxParticleNumberZ    = GETINT('Part-Species'//TRIM(hilf2)//'-maxParticleNumber-z','0')
    Species(iSpec)%Init(iInit)%Alpha                 = GETREAL('Part-Species'//TRIM(hilf2)//'-Alpha','0.')
    IF (Species(iSpec)%Init(iInit)%ElemTemperatureFileID.EQ.0) &
      Species(iSpec)%Init(iInit)%MWTemperatureIC       = GETREAL('Part-Species'//TRIM(hilf2)//'-MWTemperatureIC','0.')
    Species(iSpec)%Init(iInit)%ConstantPressure      = GETREAL('Part-Species'//TRIM(hilf2)//'-ConstantPressure','0.')
    Species(iSpec)%Init(iInit)%ConstPressureRelaxFac = GETREAL('Part-Species'//TRIM(hilf2)//'-ConstPressureRelaxFac','1.')
    IF (Species(iSpec)%Init(iInit)%ElemPartDensityFileID.EQ.0) THEN
      Species(iSpec)%Init(iInit)%PartDensity           = GETREAL('Part-Species'//TRIM(hilf2)//'-PartDensity','0.')
    ELSE
      Species(iSpec)%Init(iInit)%PartDensity           = 0.
    END IF
    IF (Species(iSpec)%Init(iInit)%UseForEmission) THEN
      Species(iSpec)%Init(iInit)%ParticleEmissionType  = GETINT('Part-Species'//TRIM(hilf2)//'-ParticleEmissionType','2')
      Species(iSpec)%Init(iInit)%ParticleEmission      = GETREAL('Part-Species'//TRIM(hilf2)//'-ParticleEmission','0.')
    ELSE
      Species(iSpec)%Init(iInit)%ParticleEmissionType  = 0 !dummy
      Species(iSpec)%Init(iInit)%ParticleEmission      = 0. !dummy
    END IF
    Species(iSpec)%Init(iInit)%NSigma                = GETREAL('Part-Species'//TRIM(hilf2)//'-NSigma','10.')
    Species(iSpec)%Init(iInit)%NumberOfExcludeRegions= GETINT('Part-Species'//TRIM(hilf2)//'-NumberOfExcludeRegions','0')
    Species(iSpec)%Init(iInit)%InsertedParticle      = 0
    Species(iSpec)%Init(iInit)%InsertedParticleSurplus = 0
    IF(TRIM(Species(iSpec)%Init(iInit)%velocityDistribution).EQ.'maxwell-juettner') THEN
      Species(iSpec)%Init(iInit)%MJxRatio       = GETREAL('Part-Species'//TRIM(hilf2)//'-MJxRatio','0')
      Species(iSpec)%Init(iInit)%MJyRatio       = GETREAL('Part-Species'//TRIM(hilf2)//'-MJyRatio','0')
      Species(iSpec)%Init(iInit)%MJzRatio       = GETREAL('Part-Species'//TRIM(hilf2)//'-MJzRatio','0')
    END IF
    IF(TRIM(Species(iSpec)%Init(iInit)%velocityDistribution).EQ.'weibel') THEN
      Species(iSpec)%Init(iInit)%WeibelVeloPar       = GETREAL('Part-Species'//TRIM(hilf2)//'-WeibelVeloPar','0')
      Species(iSpec)%Init(iInit)%WeibelVeloPer       = GETREAL('Part-Species'//TRIM(hilf2)//'-WeibelVeloPer','0')
    END IF
    IF(TRIM(Species(iSpec)%Init(iInit)%velocityDistribution).EQ. 'OneD-twostreaminstabilty') THEN
      Species(iSpec)%Init(iInit)%OneDTwoStreamVelo   = GETREAL('Part-Species'//TRIM(hilf2)//'-OneDTwoStreamVelo','0')
      Species(iSpec)%Init(iInit)%OneDTwoStreamTransRatio = GETREAL('Part-Species'//TRIM(hilf2)//'-OneDTwoStreamTransRatio','0')
    END IF

    !----------- various checks/calculations after read-in of Species(i)%Init(iInit)%-data ----------------------------------!
    !--- Check if Initial ParticleInserting is really used
    !IF ( ((Species(iSpec)%Init(iInit)%ParticleEmissionType.EQ.1).OR.(Species(iSpec)%Init(iInit)%ParticleEmissionType.EQ.2)) &
    !  .AND. 
    IF (Species(iSpec)%Init(iInit)%UseForInit) THEN
      IF ( (Species(iSpec)%Init(iInit)%initialParticleNumber.EQ.0) &
      .AND. (Species(iSpec)%Init(iInit)%PartDensity.EQ.0.) &
      .AND. Species(iSpec)%Init(iInit)%ElemPartDensityFileID.EQ.0 ) THEN
        Species(iSpec)%Init(iInit)%UseForInit=.FALSE.
        SWRITE(*,*) "WARNING: Initial ParticleInserting disabled as neither ParticleNumber"
        SWRITE(*,*) "nor PartDensity detected for Species, Init ", iSpec, iInit
      END IF
    END IF
    !--- cuboid-/cylinder-height calculation from v and dt
    IF (.NOT.Species(iSpec)%Init(iInit)%CalcHeightFromDt) THEN
      IF (TRIM(Species(iSpec)%Init(iInit)%SpaceIC).EQ.'cuboid') THEN
        IF (ALMOSTEQUAL(Species(iSpec)%Init(iInit)%CuboidHeightIC,-1.)) THEN ! flag is initialized with -1, compatibility issue 
          Species(iSpec)%Init(iInit)%CalcHeightFromDt=.TRUE.                 
          SWRITE(*,*) "WARNING: Cuboid height will be calculated from v and dt!"
        END IF
      ELSE IF (TRIM(Species(iSpec)%Init(iInit)%SpaceIC).EQ.'cylinder') THEN
        IF (ALMOSTEQUAL(Species(iSpec)%Init(iInit)%CylinderHeightIC,-1.)) THEN !flag is initialized with -1, compatibility issue 
          Species(iSpec)%Init(iInit)%CalcHeightFromDt=.TRUE.                   
          SWRITE(*,*) "WARNING: Cylinder height will be calculated from v and dt!"
        END IF
      END IF
    END IF
    IF (Species(iSpec)%Init(iInit)%CalcHeightFromDt) THEN
      IF ( (Species(iSpec)%Init(iInit)%ParticleEmissionType.NE.1) .AND. (Species(iSpec)%Init(iInit)%ParticleEmissionType.NE.2) ) &
        CALL abort(&
__STAMP__&
          ,' Calculating height from v and dt is only supported for EmiType1 or EmiType2(=default)!')
      IF ((TRIM(Species(iSpec)%Init(iInit)%SpaceIC).NE.'cuboid') &
          .AND.(TRIM(Species(iSpec)%Init(iInit)%SpaceIC).NE.'cylinder')) &
        CALL abort(&
__STAMP__&
          ,' Calculating height from v and dt is only supported for cuboid or cylinder!')
      IF (Species(iSpec)%Init(iInit)%UseForInit) &
        CALL abort(&
__STAMP__&
          ,' Calculating height from v and dt is not supported for initial ParticleInserting!')
    END IF
    !--- virtual pre-insertion (vpi) checks and calculations
    IF ((TRIM(Species(iSpec)%Init(iInit)%SpaceIC).EQ.'cuboid_vpi') &
      .OR.(TRIM(Species(iSpec)%Init(iInit)%SpaceIC).EQ.'cylinder_vpi')) THEN
      IF ( (Species(iSpec)%Init(iInit)%ParticleEmissionType.NE.1) .AND. (Species(iSpec)%Init(iInit)%ParticleEmissionType.NE.2) ) &
        CALL abort(&
__STAMP__&
        ,' Wrong emission-type for virtual Pre-Inserting region!')
      IF (TRIM(Species(iSpec)%Init(iInit)%velocityDistribution).NE.'maxwell_lpn') &
        CALL abort(&
__STAMP__&
        ,' Only maxwell_lpn is implemened as velocity-distribution for virtual Pre-Inserting region!')
      IF (Species(iSpec)%Init(iInit)%UseForInit) &
        CALL abort(&
__STAMP__&
          ,' virtual Pre-Inserting is not supported for initial ParticleInserting. Use additional Init!')
      !-- Virtual Pre-Inserting is used correctly !
      Species(iSpec)%Init(iInit)%VirtPreInsert = .TRUE.
      SWRITE(*,*) "Virtual Pre-Inserting is used for Species, Init ", iSpec, iInit
      IF (Species(iSpec)%Init(iInit)%PartDensity .EQ. 0.) THEN
        SWRITE(*,*) "WARNING: If VPI-BC is open, a backflow might not be compensated"
        SWRITE(*,*) "         (use PartDensity instead of ParticleEmission)!"
      END IF
      Species(iSpec)%Init(iInit)%vpiDomainType = TRIM(GETSTR('Part-Species'//TRIM(hilf2)//'-vpiDomainType','perpendicular_extrusion'))
      SELECT CASE ( TRIM(Species(iSpec)%Init(iInit)%vpiDomainType) )
      CASE ( 'freestream' )
        IF ( TRIM(Species(iSpec)%Init(iInit)%SpaceIC) .NE. 'cuboid_vpi' ) THEN
          CALL abort(&
__STAMP__&
            ,' Only cuboid_vpi is supported for a freestream vpiDomainType! (Use default vpiDomainType for cylinder.)')
        ELSE
          Species(iSpec)%Init(iInit)%vpiBVBuffer(1) = GETLOGICAL('Part-Species'//TRIM(hilf2)//'-vpiBV1BufferNeg','.TRUE.')
          Species(iSpec)%Init(iInit)%vpiBVBuffer(2) = GETLOGICAL('Part-Species'//TRIM(hilf2)//'-vpiBV1BufferPos','.TRUE.')
          Species(iSpec)%Init(iInit)%vpiBVBuffer(3) = GETLOGICAL('Part-Species'//TRIM(hilf2)//'-vpiBV2BufferNeg','.TRUE.')
          Species(iSpec)%Init(iInit)%vpiBVBuffer(4) = GETLOGICAL('Part-Species'//TRIM(hilf2)//'-vpiBV2BufferPos','.TRUE.')
        END IF
      CASE ( 'orifice' )
        Species(iSpec)%Init(iInit)%vpiBVBuffer = .TRUE.
        IF ( ABS(Species(iSpec)%Init(iInit)%Radius2IC) .GT. 0. ) THEN
          CALL abort(&
__STAMP__&
            ,' Annular orifice is not implemented yet!')
        END IF
      CASE ( 'perpendicular_extrusion' )
        Species(iSpec)%Init(iInit)%vpiBVBuffer = .TRUE. !dummy
      CASE DEFAULT
        CALL abort(&
__STAMP__&
,'vpiDomainType is not implemented!')
      END SELECT
      !--
    ELSE
      Species(iSpec)%Init(iInit)%VirtPreInsert = .FALSE.
    END IF
    !--- integer check for ParticleEmissionType 2
    IF((Species(iSpec)%Init(iInit)%ParticleEmissionType.EQ.2).AND. &
         ((Species(iSpec)%Init(iInit)%ParticleEmission-INT(Species(iSpec)%Init(iInit)%ParticleEmission)).NE.0)) THEN
       CALL abort(&
__STAMP__&
       ,' If ParticleEmissionType = 2 (parts per iteration), ParticleEmission has to be an integer number')
    END IF
    !--- flag for cell-based constant-pressure-EmiTypes
    IF ((Species(iSpec)%Init(iInit)%ParticleEmissionType .EQ. 4).OR. &
        (Species(iSpec)%Init(iInit)%ParticleEmissionType .EQ. 6)) PartPressureCell = .TRUE.
    IF (Species(iSpec)%Init(iInit)%ElemVelocityICFileID.EQ.0) THEN
      !--- normalize VeloVecIC and NormalIC (and BaseVector 1 & 2 IC for cylinder) for Inits
      IF (.NOT. ALL(Species(iSpec)%Init(iInit)%VeloVecIC(:).eq.0.)) THEN
        Species(iSpec)%Init(iInit)%VeloVecIC = Species(iSpec)%Init(iInit)%VeloVecIC            / &
          SQRT(Species(iSpec)%Init(iInit)%VeloVecIC(1)*Species(iSpec)%Init(iInit)%VeloVecIC(1) + &
          Species(iSpec)%Init(iInit)%VeloVecIC(2)*Species(iSpec)%Init(iInit)%VeloVecIC(2)      + &
          Species(iSpec)%Init(iInit)%VeloVecIC(3)*Species(iSpec)%Init(iInit)%VeloVecIC(3))
      END IF
    END IF
    Species(iSpec)%Init(iInit)%NormalIC = Species(iSpec)%Init(iInit)%NormalIC /                 &
      SQRT(Species(iSpec)%Init(iInit)%NormalIC(1)*Species(iSpec)%Init(iInit)%NormalIC(1) + &
      Species(iSpec)%Init(iInit)%NormalIC(2)*Species(iSpec)%Init(iInit)%NormalIC(2) + &
      Species(iSpec)%Init(iInit)%NormalIC(3)*Species(iSpec)%Init(iInit)%NormalIC(3))
    IF ((TRIM(Species(iSpec)%Init(iInit)%SpaceIC).EQ.'cylinder')&
        .OR.(TRIM(Species(iSpec)%Init(iInit)%SpaceIC).EQ.'cylinder_vpi')) THEN
        Species(iSpec)%Init(iInit)%BaseVector1IC =&
                  Species(iSpec)%Init(iInit)%RadiusIC * Species(iSpec)%Init(iInit)%BaseVector1IC /     &
        SQRT(Species(iSpec)%Init(iInit)%BaseVector1IC(1)*Species(iSpec)%Init(iInit)%BaseVector1IC(1) + &
        Species(iSpec)%Init(iInit)%BaseVector1IC(2)*Species(iSpec)%Init(iInit)%BaseVector1IC(2) + &
        Species(iSpec)%Init(iInit)%BaseVector1IC(3)*Species(iSpec)%Init(iInit)%BaseVector1IC(3))
        Species(iSpec)%Init(iInit)%BaseVector2IC =&
                   Species(iSpec)%Init(iInit)%RadiusIC * Species(iSpec)%Init(iInit)%BaseVector2IC /    &
        SQRT(Species(iSpec)%Init(iInit)%BaseVector2IC(1)*Species(iSpec)%Init(iInit)%BaseVector2IC(1) + &
        Species(iSpec)%Init(iInit)%BaseVector2IC(2)*Species(iSpec)%Init(iInit)%BaseVector2IC(2)      + &
        Species(iSpec)%Init(iInit)%BaseVector2IC(3)*Species(iSpec)%Init(iInit)%BaseVector2IC(3))
    END IF
    !--- read stuff for ExcludeRegions and normalize/calculate corresponding vectors
    IF (Species(iSpec)%Init(iInit)%NumberOfExcludeRegions.GT.0) THEN
      ALLOCATE(Species(iSpec)%Init(iInit)%ExcludeRegion(1:Species(iSpec)%Init(iInit)%NumberOfExcludeRegions)) 
      IF (((TRIM(Species(iSpec)%Init(iInit)%SpaceIC).EQ.'cuboid') &
       .OR.(TRIM(Species(iSpec)%Init(iInit)%SpaceIC).EQ.'cylinder')) &
      .OR.((TRIM(Species(iSpec)%Init(iInit)%SpaceIC).EQ.'cuboid_vpi') &
       .OR.(TRIM(Species(iSpec)%Init(iInit)%SpaceIC).EQ.'cylinder_vpi'))) THEN
        DO iExclude=1,Species(iSpec)%Init(iInit)%NumberOfExcludeRegions
          WRITE(UNIT=hilf3,FMT='(I0)') iExclude
          hilf3=TRIM(hilf2)//'-ExcludeRegion'//TRIM(hilf3)
          Species(iSpec)%Init(iInit)%ExcludeRegion(iExclude)%SpaceIC             &
            = TRIM(GETSTR('Part-Species'//TRIM(hilf3)//'-SpaceIC','cuboid'))
          Species(iSpec)%Init(iInit)%ExcludeRegion(iExclude)%RadiusIC             &
            = GETREAL('Part-Species'//TRIM(hilf3)//'-RadiusIC','1.')
          Species(iSpec)%Init(iInit)%ExcludeRegion(iExclude)%Radius2IC            &
            = GETREAL('Part-Species'//TRIM(hilf3)//'-Radius2IC','0.')
          Species(iSpec)%Init(iInit)%ExcludeRegion(iExclude)%NormalIC             &
            = GETREALARRAY('Part-Species'//TRIM(hilf3)//'-NormalIC',3,'0. , 0. , 1.')
          Species(iSpec)%Init(iInit)%ExcludeRegion(iExclude)%BasePointIC          &
            = GETREALARRAY('Part-Species'//TRIM(hilf3)//'-BasePointIC',3,'0. , 0. , 0.')
          Species(iSpec)%Init(iInit)%ExcludeRegion(iExclude)%BaseVector1IC        &
            = GETREALARRAY('Part-Species'//TRIM(hilf3)//'-BaseVector1IC',3,'1. , 0. , 0.')
          Species(iSpec)%Init(iInit)%ExcludeRegion(iExclude)%BaseVector2IC        &
            = GETREALARRAY('Part-Species'//TRIM(hilf3)//'-BaseVector2IC',3,'0. , 1. , 0.')
          Species(iSpec)%Init(iInit)%ExcludeRegion(iExclude)%CuboidHeightIC       &
            = GETREAL('Part-Species'//TRIM(hilf3)//'-CuboidHeightIC','1.')
          Species(iSpec)%Init(iInit)%ExcludeRegion(iExclude)%CylinderHeightIC     &
            = GETREAL('Part-Species'//TRIM(hilf3)//'-CylinderHeightIC','1.')
          !--normalize and stuff
          IF ((TRIM(Species(iSpec)%Init(iInit)%ExcludeRegion(iExclude)%SpaceIC).EQ.'cuboid') .OR. &
               ((((.NOT.ALMOSTEQUAL(Species(iSpec)%Init(iInit)%ExcludeRegion(iExclude)%BaseVector1IC(1),1.) &
              .OR. .NOT.ALMOSTEQUAL(Species(iSpec)%Init(iInit)%ExcludeRegion(iExclude)%BaseVector1IC(2),0.)) &
              .OR. .NOT.ALMOSTEQUAL(Species(iSpec)%Init(iInit)%ExcludeRegion(iExclude)%BaseVector1IC(3),0.)) &
            .OR. ((.NOT.ALMOSTEQUAL(Species(iSpec)%Init(iInit)%ExcludeRegion(iExclude)%BaseVector2IC(1),0.) &
              .OR. .NOT.ALMOSTEQUAL(Species(iSpec)%Init(iInit)%ExcludeRegion(iExclude)%BaseVector2IC(2),1.)) &
              .OR. .NOT.ALMOSTEQUAL(Species(iSpec)%Init(iInit)%ExcludeRegion(iExclude)%BaseVector2IC(3),0.))) &
            .AND. (((ALMOSTEQUAL(Species(iSpec)%Init(iInit)%ExcludeRegion(iExclude)%NormalIC(1),0.)) &
              .AND. (ALMOSTEQUAL(Species(iSpec)%Init(iInit)%ExcludeRegion(iExclude)%NormalIC(2),0.))) &
              .AND. (ALMOSTEQUAL(Species(iSpec)%Init(iInit)%ExcludeRegion(iExclude)%NormalIC(3),1.))))) THEN
            !-- cuboid; or BV are non-default and NormalIC is default: calc. NormalIC for ExcludeRegions from BV1/2
            !   (for def. BV and non-def. NormalIC; or all def. or non-def.: Use User-defined NormalIC when ExclRegion is cylinder)
            Species(iSpec)%Init(iInit)%ExcludeRegion(iExclude)%NormalIC(1) &
              = Species(iSpec)%Init(iInit)%ExcludeRegion(iExclude)%BaseVector1IC(2) &
              * Species(iSpec)%Init(iInit)%ExcludeRegion(iExclude)%BaseVector2IC(3) &
              - Species(iSpec)%Init(iInit)%ExcludeRegion(iExclude)%BaseVector1IC(3) &
              * Species(iSpec)%Init(iInit)%ExcludeRegion(iExclude)%BaseVector2IC(2)
            Species(iSpec)%Init(iInit)%ExcludeRegion(iExclude)%NormalIC(2) &
              = Species(iSpec)%Init(iInit)%ExcludeRegion(iExclude)%BaseVector1IC(3) &
              * Species(iSpec)%Init(iInit)%ExcludeRegion(iExclude)%BaseVector2IC(1) &
              - Species(iSpec)%Init(iInit)%ExcludeRegion(iExclude)%BaseVector1IC(1) &
              * Species(iSpec)%Init(iInit)%ExcludeRegion(iExclude)%BaseVector2IC(3)
            Species(iSpec)%Init(iInit)%ExcludeRegion(iExclude)%NormalIC(3) &
              = Species(iSpec)%Init(iInit)%ExcludeRegion(iExclude)%BaseVector1IC(1) &
              * Species(iSpec)%Init(iInit)%ExcludeRegion(iExclude)%BaseVector2IC(2) &
              - Species(iSpec)%Init(iInit)%ExcludeRegion(iExclude)%BaseVector1IC(2) &
              * Species(iSpec)%Init(iInit)%ExcludeRegion(iExclude)%BaseVector2IC(1)
          ELSE IF ( (TRIM(Species(iSpec)%Init(iInit)%ExcludeRegion(iExclude)%SpaceIC).NE.'cuboid') .AND. &
                    (TRIM(Species(iSpec)%Init(iInit)%ExcludeRegion(iExclude)%SpaceIC).NE.'cylinder') )THEN
            CALL abort(&
__STAMP__&
,'Error in ParticleInit, ExcludeRegions must be cuboid or cylinder!')
          END IF
          IF (Species(iSpec)%Init(iInit)%ExcludeRegion(iExclude)%NormalIC(1)**2 + &
              Species(iSpec)%Init(iInit)%ExcludeRegion(iExclude)%NormalIC(2)**2 + &
              Species(iSpec)%Init(iInit)%ExcludeRegion(iExclude)%NormalIC(3)**2 .GT. 0.) THEN
            Species(iSpec)%Init(iInit)%ExcludeRegion(iExclude)%NormalIC &
              = Species(iSpec)%Init(iInit)%ExcludeRegion(iExclude)%NormalIC &
              / SQRT(Species(iSpec)%Init(iInit)%ExcludeRegion(iExclude)%NormalIC(1)**2 &
              + Species(iSpec)%Init(iInit)%ExcludeRegion(iExclude)%NormalIC(2)**2 &
              + Species(iSpec)%Init(iInit)%ExcludeRegion(iExclude)%NormalIC(3)**2)
            Species(iSpec)%Init(iInit)%ExcludeRegion(iExclude)%ExcludeBV_lenghts(1) &
              = SQRT(Species(iSpec)%Init(iInit)%ExcludeRegion(iExclude)%BaseVector1IC(1)**2 &
              + Species(iSpec)%Init(iInit)%ExcludeRegion(iExclude)%BaseVector1IC(2)**2 &
              + Species(iSpec)%Init(iInit)%ExcludeRegion(iExclude)%BaseVector1IC(3)**2)
            Species(iSpec)%Init(iInit)%ExcludeRegion(iExclude)%ExcludeBV_lenghts(2) &
              = SQRT(Species(iSpec)%Init(iInit)%ExcludeRegion(iExclude)%BaseVector2IC(1)**2 &
              + Species(iSpec)%Init(iInit)%ExcludeRegion(iExclude)%BaseVector2IC(2)**2 &
              + Species(iSpec)%Init(iInit)%ExcludeRegion(iExclude)%BaseVector2IC(3)**2)
          ELSE
            CALL abort(&
__STAMP__&
,'Error in ParticleInit, NormalIC Vector must not be zero!')
          END IF
        END DO !iExclude
      ELSE
        CALL abort(&
__STAMP__&
,'Error in ParticleInit, ExcludeRegions are currently only implemented for the SpaceIC cuboid(_vpi) or cylinder(_vpi)!')
      END IF
    END IF
    !--- stuff for calculating ParticleEmission/InitialParticleNumber from PartDensity when this value is not used for LD-stuff
    !                                                                                  (additional not-LD checks might be necassary)
    PartDens_OnlyInit=.FALSE.
    IF ((Species(iSpec)%Init(iInit)%PartDensity.GT.0.).AND.(TRIM(Species(iSpec)%Init(iInit)%SpaceIC).NE.'LD_insert')) THEN
      IF (Species(iSpec)%Init(iInit)%ParticleEmissionType.NE.1) THEN
        IF ( (Species(iSpec)%Init(iInit)%ParticleEmissionType.EQ.2 .OR. Species(iSpec)%Init(iInit)%ParticleEmissionType.EQ.0) &
            .AND. (Species(iSpec)%Init(iInit)%UseForInit) ) THEN
          PartDens_OnlyInit=.TRUE.
        ELSE
          CALL abort(&
__STAMP__&
            , 'PartDensity without LD is only supported for EmiType1 or initial ParticleInserting with EmiType1/2!')
        END IF
      END IF
      IF ((TRIM(Species(iSpec)%Init(iInit)%SpaceIC).EQ.'cuboid').OR.(TRIM(Species(iSpec)%Init(iInit)%SpaceIC).EQ.'cylinder')) THEN
        IF  ((((TRIM(Species(iSpec)%Init(iInit)%velocityDistribution).EQ.'constant') &
          .OR.(TRIM(Species(iSpec)%Init(iInit)%velocityDistribution).EQ.'maxwell') ) &
          .OR.(TRIM(Species(iSpec)%Init(iInit)%velocityDistribution).EQ.'maxwell_lpn') ) &
          .OR.(TRIM(Species(iSpec)%Init(iInit)%velocityDistribution).EQ.'emmert') ) THEN
          IF (Species(iSpec)%Init(iInit)%ParticleEmission .GT. 0.) THEN
            CALL abort(&
__STAMP__&
            ,'Either ParticleEmission or PartDensity can be defined for selected emission parameters, not both!')
          END IF
          !---calculation of Base-Area and corresponding component of VeloVecIC
          lineVector(1) = Species(iSpec)%Init(iInit)%BaseVector1IC(2) * Species(iSpec)%Init(iInit)%BaseVector2IC(3) - &
            Species(iSpec)%Init(iInit)%BaseVector1IC(3) * Species(iSpec)%Init(iInit)%BaseVector2IC(2)
          lineVector(2) = Species(iSpec)%Init(iInit)%BaseVector1IC(3) * Species(iSpec)%Init(iInit)%BaseVector2IC(1) - &
            Species(iSpec)%Init(iInit)%BaseVector1IC(1) * Species(iSpec)%Init(iInit)%BaseVector2IC(3)
          lineVector(3) = Species(iSpec)%Init(iInit)%BaseVector1IC(1) * Species(iSpec)%Init(iInit)%BaseVector2IC(2) - &
            Species(iSpec)%Init(iInit)%BaseVector1IC(2) * Species(iSpec)%Init(iInit)%BaseVector2IC(1)
          A_ins = lineVector(1)*lineVector(1) + lineVector(2)*lineVector(2) + lineVector(3)*lineVector(3)
          IF (A_ins .GT. 0.) THEN
            A_ins = SQRT(A_ins)
            lineVector = lineVector / A_ins
            IF (Species(iSpec)%Init(iInit)%CalcHeightFromDt) THEN
              v_drift_line = Species(iSpec)%Init(iInit)%VeloIC * &
                ( Species(iSpec)%Init(iInit)%VeloVecIC(1)*lineVector(1) + Species(iSpec)%Init(iInit)%VeloVecIC(2)*lineVector(2) &
                + Species(iSpec)%Init(iInit)%VeloVecIC(3)*lineVector(3) ) !lineVector component of drift-velocity
            ELSE
              v_drift_line = 0.
              IF (Species(iSpec)%Init(iInit)%UseForInit) THEN
                PartDens_OnlyInit=.TRUE.
              ELSE
                CALL abort(&
__STAMP__&
                  ,'PartDensity without LD is only supported for CalcHeightFromDt, vpi, or initial ParticleInserting!')
              END IF
            END IF
            IF ( TRIM(Species(iSpec)%Init(iInit)%SpaceIC) .EQ. 'cylinder' ) THEN
              A_ins = Pi * (Species(iSpec)%Init(iInit)%RadiusIC**2-Species(iSpec)%Init(iInit)%Radius2IC**2)
            END IF
            !---calculation of particle flow (macroparticles/s) through boundary
            IF (.NOT.PartDens_OnlyInit) THEN
              Species(iSpec)%Init(iInit)%ParticleEmission &
                = Species(iSpec)%Init(iInit)%PartDensity / Species(iSpec)%MacroParticleFactor * v_drift_line * A_ins
            END IF
            !---calculation of initial (macro)particle number
            IF (Species(iSpec)%Init(iInit)%UseForInit) THEN
              IF (Species(iSpec)%Init(iInit)%initialParticleNumber .GT. 0) THEN
                CALL abort(&
__STAMP__&
                  ,'Either initialParticleNumber or PartDensity can be defined for selected parameters, not both!')
              END IF
              IF (TRIM(Species(iSpec)%Init(iInit)%SpaceIC).EQ.'cuboid') THEN
                Species(iSpec)%Init(iInit)%initialParticleNumber &
                  = INT(Species(iSpec)%Init(iInit)%PartDensity / Species(iSpec)%MacroParticleFactor &
                  * Species(iSpec)%Init(iInit)%CuboidHeightIC * A_ins)
              ELSE !cylinder
                Species(iSpec)%Init(iInit)%initialParticleNumber &
                  = INT(Species(iSpec)%Init(iInit)%PartDensity / Species(iSpec)%MacroParticleFactor &
                  * Species(iSpec)%Init(iInit)%CylinderHeightIC * A_ins)
              END IF
            END IF
          ELSE
            CALL abort(&
__STAMP__&
              ,'BaseVectors are parallel or zero!')
          END IF
        ELSE
          CALL abort(&
__STAMP__&
          ,'Only const. or maxwell(_lpn) is supported as velocityDistr. for PartDensity without LD!')
        END IF
      ELSE IF (Species(iSpec)%Init(iInit)%VirtPreInsert) THEN
        IF (Species(iSpec)%Init(iInit)%ParticleEmission .GT. 0.) THEN
               CALL abort(&
__STAMP__&
          ,'Either ParticleEmission or PartDensity can be defined for selected emission parameters, not both!')
        ELSE
          SWRITE(*,*) "PartDensity is used for VPI of Species, Init ", iSpec, iInit !Value is calculated inside SetParticlePostion!
        END IF
      ELSE IF ((TRIM(Species(iSpec)%Init(iInit)%SpaceIC).EQ.'cell_local')) THEN
        IF  ((TRIM(Species(iSpec)%Init(iInit)%velocityDistribution).EQ.'constant') &
          .OR.(TRIM(Species(iSpec)%Init(iInit)%velocityDistribution).EQ.'maxwell_lpn') ) THEN
          IF (Species(iSpec)%Init(iInit)%ParticleEmission .GT. 0.) THEN
            CALL abort(&
__STAMP__&
            ,'Either ParticleEmission or PartDensity can be defined for cell_local emission parameters, not both!')
          END IF
          IF (GEO%LocalVolume.GT.0.) THEN
            IF (Species(iSpec)%Init(iInit)%UseForInit) THEN
              IF (Species(iSpec)%Init(iInit)%initialParticleNumber .GT. 0) THEN
                CALL abort(&
__STAMP__&
                  ,'Either initialParticleNumber or PartDensity can be defined for selected parameters, not both!')
              END IF
              Species(iSpec)%Init(iInit)%initialParticleNumber &
                  = NINT(Species(iSpec)%Init(iInit)%PartDensity / Species(iSpec)%MacroParticleFactor * GEO%LocalVolume)
            END IF
          ELSE
            CALL abort(&
__STAMP__&
              ,'Local mesh volume is zero!')
          END IF
        ELSE
          ! maxwell might also work for cell_local but not with cell dependant temperatures as with MacroRestart
          CALL abort(&
__STAMP__&
          ,'Only const. or maxwell_lpn is supported as velocityDistr. using cell_local inserting with PartDensity!')
        END IF
      ELSE
        CALL abort(&
__STAMP__&
        ,'PartDensity without LD is only supported for the SpaceIC cuboid(_vpi) or cylinder(_vpi)!')
      END IF
    END IF
    !--- determine if cell_local macro restart with density distribution
    IF (Species(iSpec)%Init(iInit)%ElemPartDensityFileID.GT.0) THEN
      IF  ((TRIM(Species(iSpec)%Init(iInit)%velocityDistribution).EQ.'constant') &
        .OR.(TRIM(Species(iSpec)%Init(iInit)%velocityDistribution).EQ.'maxwell_lpn') ) THEN
        IF (GEO%LocalVolume.GT.0.) THEN
          IF (Species(iSpec)%Init(iInit)%UseForInit) THEN
            particlenumber_tmp = 0.
            DO iElem = 1,nElems
              particlenumber_tmp = particlenumber_tmp + Species(iSpec)%Init(iInit)%ElemPartDensity(iElem) &
                  / Species(iSpec)%MacroParticleFactor * GEO%Volume(iElem)
            END DO
            Species(iSpec)%Init(iInit)%initialParticleNumber = NINT(particlenumber_tmp)
          END IF
        ELSE
          CALL abort(&
__STAMP__&
,'Error in particle_init: Local mesh volume is zero!')
        END IF
      ELSE
        ! maxwell might also work for cell_local but not with cell dependant temperatures as with MacroRestart
        CALL abort(&
__STAMP__&
,'Only const. or maxwell_lpn is supported as velocityDistr. using cell_local inserting with Macro-ElemPartDensity Insert!')
      END IF
    END IF
    !--- determine StartnumberOfInits (start loop index, e.g., for emission loops)
    IF(iInit.EQ.0)THEN
      !!!for new case: check if to be included!!!
      IF((( (Species(iSpec)%Init(iInit)%initialParticleNumber.EQ.0)&
        .AND.(Species(iSpec)%Init(iInit)%ParticleEmission.EQ.0.) )  &
        .AND.(Species(iSpec)%Init(iInit)%PartDensity.EQ.0.) )       &
        .AND.(Species(iSpec)%Init(iInit)%ConstantPressure.EQ.0.)    &
        .AND.(Species(iSpec)%NumberOfInits.GT.0))       THEN 
        Species(iSpec)%StartnumberOfInits = 1 ! only new style paramaters defined (Part-Species(i)-Init(iInit)-***)
      ELSE
        Species(iSpec)%StartnumberOfInits = 0 ! old style parameters has been defined for inits/emissions (Part-Species(i)-***)
      END IF
      SWRITE(*,*) "StartnumberOfInits of Species ", iSpec, " = ", Species(iSpec)%StartnumberOfInits
    END IF ! iInit .EQ.0

  END DO ! iInit
END DO ! iSpec 

! get information for IMD atom/ion charge determination and distribution
IMDnSpecies         = GETINT('IMDnSpecies','1')
IMDInputFile        = GETSTR('IMDInputFile','no file found')
ALLOCATE(IMDSpeciesID(IMDnSpecies))
ALLOCATE(IMDSpeciesCharge(IMDnSpecies))
iIMDSpec=1
DO iSpec = 1, nSpecies
  WRITE(UNIT=hilf,FMT='(I0)') iSpec
  IsIMDSpecies = GETLOGICAL('Part-Species'//TRIM(hilf)//'-IsIMDSpecies','.FALSE.')
  IF(IsIMDSpecies)THEN
    IMDSpeciesID(iIMDSpec)=iSpec
    IMDSpeciesCharge(iIMDSpec)=NINT(Species(iSpec)%ChargeIC/ElementaryCharge)
    iIMDSpec=iIMDSpec+1
  END IF
END DO


! Which Lorentz boost method should be used?
PartLorentzType = GETINT('Part-LorentzType','3')

! Read in boundary parameters
dummy_int = CNTSTR('Part-nBounds')       ! check if Part-nBounds is present in .ini file
nPartBound = GETINT('Part-nBounds','1.') ! get number of particle boundaries
IF ((nPartBound.LE.0).OR.(dummy_int.LT.0)) THEN
  CALL abort(&
__STAMP__&
  ,'ERROR: nPartBound .LE. 0:', nPartBound)
END IF
ALLOCATE(PartBound%SourceBoundName(1:nPartBound))
ALLOCATE(PartBound%TargetBoundCond(1:nPartBound))
ALLOCATE(PartBound%MomentumACC(1:nPartBound))
ALLOCATE(PartBound%WallTemp(1:nPartBound))
ALLOCATE(PartBound%TransACC(1:nPartBound))
ALLOCATE(PartBound%VibACC(1:nPartBound))
ALLOCATE(PartBound%RotACC(1:nPartBound))
ALLOCATE(PartBound%ElecACC(1:nPartBound))
ALLOCATE(PartBound%Resample(1:nPartBound))
ALLOCATE(PartBound%WallVelo(1:3,1:nPartBound))
ALLOCATE(PartBound%AmbientCondition(1:nPartBound))
ALLOCATE(PartBound%AmbientConditionFix(1:nPartBound))
ALLOCATE(PartBound%AmbientTemp(1:nPartBound))
ALLOCATE(PartBound%AmbientMeanPartMass(1:nPartBound))
ALLOCATE(PartBound%AmbientBeta(1:nPartBound))
ALLOCATE(PartBound%AmbientVelo(1:3,1:nPartBound))
ALLOCATE(PartBound%AmbientDens(1:nPartBound))
ALLOCATE(PartBound%AmbientDynamicVisc(1:nPartBound))
ALLOCATE(PartBound%AmbientThermalCond(1:nPartBound))
ALLOCATE(PartBound%SolidState(1:nPartBound))
ALLOCATE(PartBound%SolidCatalytic(1:nPartBound))
ALLOCATE(PartBound%SolidSpec(1:nPartBound))
ALLOCATE(PartBound%SolidPartDens(1:nPartBound))
ALLOCATE(PartBound%SolidMassIC(1:nPartBound))
ALLOCATE(PartBound%SolidAreaIncrease(1:nPartBound))
ALLOCATE(PartBound%SolidCrystalIndx(1:nPartBound))
ALLOCATE(PartBound%LiquidSpec(1:nPartBound))
ALLOCATE(PartBound%ParamAntoine(1:3,1:nPartBound))
PartBound%SolidState(1:nPartBound)=.FALSE.
PartBound%LiquidSpec(1:nPartBound)=0
SolidSimFlag = .FALSE.
LiquidSimFlag = .FALSE.

ALLOCATE(PartBound%Adaptive(1:nPartBound))
ALLOCATE(PartBound%AdaptiveType(1:nPartBound))
ALLOCATE(PartBound%AdaptiveMacroRestartFileID(1:nPartBound))
ALLOCATE(PartBound%AdaptiveTemp(1:nPartBound))
ALLOCATE(PartBound%AdaptivePressure(1:nPartBound))
nAdaptiveBC = 0
PartBound%Adaptive(:) = .FALSE.
PartBound%AdaptiveType(:) = -1
PartBound%AdaptiveMacroRestartFileID(:) = 0
PartBound%AdaptiveTemp(:) = -1.
PartBound%AdaptivePressure(:) = -1.

ALLOCATE(PartBound%Voltage(1:nPartBound))
ALLOCATE(PartBound%UseForQCrit(1:nPartBound))
ALLOCATE(PartBound%Voltage_CollectCharges(1:nPartBound))
PartBound%Voltage_CollectCharges(:)=0.
ALLOCATE(PartBound%NbrOfSpeciesSwaps(1:nPartBound))
!--determine MaxNbrOfSpeciesSwaps for correct allocation
MaxNbrOfSpeciesSwaps=0
DO iPartBound=1,nPartBound
  WRITE(UNIT=hilf,FMT='(I0)') iPartBound
  PartBound%NbrOfSpeciesSwaps(iPartBound)= GETINT('Part-Boundary'//TRIM(hilf)//'-NbrOfSpeciesSwaps','0')
  MaxNbrOfSpeciesSwaps=max(PartBound%NbrOfSpeciesSwaps(iPartBound),MaxNbrOfSpeciesSwaps)
END DO
IF (MaxNbrOfSpeciesSwaps.gt.0) THEN
  ALLOCATE(PartBound%ProbOfSpeciesSwaps(1:nPartBound))
  ALLOCATE(PartBound%SpeciesSwaps(1:2,1:MaxNbrOfSpeciesSwaps,1:nPartBound))
END IF
!--
PartMeshHasPeriodicBCs=.FALSE.
#if defined(IMPA) || defined(ROS)
PartMeshHasReflectiveBCs=.FALSE.
#endif
DO iPartBound=1,nPartBound
  WRITE(UNIT=hilf,FMT='(I0)') iPartBound
  tmpString = TRIM(GETSTR('Part-Boundary'//TRIM(hilf)//'-Condition','open'))
  SELECT CASE (TRIM(tmpString))
  CASE('open')
     PartBound%TargetBoundCond(iPartBound) = PartBound%OpenBC          ! definitions see typesdef_pic
     PartBound%AmbientCondition(iPartBound) = GETLOGICAL('Part-Boundary'//TRIM(hilf)//'-AmbientCondition','.FALSE.')
     IF(PartBound%AmbientCondition(iPartBound)) THEN
       PartBound%AmbientConditionFix(iPartBound) = GETLOGICAL('Part-Boundary'//TRIM(hilf)//'-AmbientConditionFix','.TRUE.')
       PartBound%AmbientTemp(iPartBound) = GETREAL('Part-Boundary'//TRIM(hilf)//'-AmbientTemp','0')
       PartBound%AmbientMeanPartMass(iPartBound) = GETREAL('Part-Boundary'//TRIM(hilf)//'-AmbientMeanPartMass','0')
       PartBound%AmbientBeta(iPartBound) = &
       SQRT(PartBound%AmbientMeanPartMass(iPartBound)/(2*BoltzmannConst*PartBound%AmbientTemp(iPartBound)))
       PartBound%AmbientVelo(1:3,iPartBound) = GETREALARRAY('Part-Boundary'//TRIM(hilf)//'-AmbientVelo',3,'0. , 0. , 0.')
       PartBound%AmbientDens(iPartBound) = GETREAL('Part-Boundary'//TRIM(hilf)//'-AmbientDens','0')
       PartBound%AmbientDynamicVisc(iPartBound)=&
           GETREAL('Part-Boundary'//TRIM(hilf)//'-AmbientDynamicVisc','1.72326582572253E-5') ! N2:T=288K
       PartBound%AmbientThermalCond(iPartBound)=&
           GETREAL('Part-Boundary'//TRIM(hilf)//'-AmbientThermalCond','2.42948500556027E-2') ! N2:T=288K
     END IF
     PartBound%Adaptive(iPartBound) = GETLOGICAL('Part-Boundary'//TRIM(hilf)//'-Adaptive','.FALSE.')
     IF(PartBound%Adaptive(iPartBound)) THEN
       nAdaptiveBC = nAdaptiveBC + 1
       PartBound%AdaptiveType(iPartBound) = GETINT('Part-Boundary'//TRIM(hilf)//'-AdaptiveType','2')
       IF (nMacroRestartFiles.GT.0) THEN
         PartBound%AdaptiveMacroRestartFileID(iPartBound) = GETINT('Part-Boundary'//TRIM(hilf)//'-AdaptiveMacroRestartFileID','0')
       END IF
       FileID = PartBound%AdaptiveMacroRestartFileID(iPartBound)
       IF (FileID.GT.0 .AND. FileID.LE.nMacroRestartFiles) THEN
         MacroRestartFileUsed(FileID) = .TRUE.
         IF (PartBound%AdaptiveType(iPartBound).EQ.1) THEN
           PartBound%AdaptiveTemp(iPartBound) = GETREAL('Part-Boundary'//TRIM(hilf)//'-AdaptiveTemp','0.')
           IF (PartBound%AdaptiveTemp(iPartBound).EQ.0.) CALL abort(&
__STAMP__&
,'Error during ParticleBoundary init: Part-Boundary'//TRIM(hilf)//'-AdaptiveTemp not defined')
         END IF
       ELSE
         PartBound%AdaptiveTemp(iPartBound) = GETREAL('Part-Boundary'//TRIM(hilf)//'-AdaptiveTemp','0.')
         IF (PartBound%AdaptiveTemp(iPartBound).EQ.0.) CALL abort(&
__STAMP__&
,'Error during ParticleBoundary init: Part-Boundary'//TRIM(hilf)//'-AdaptiveTemp not defined')
       END IF
       PartBound%AdaptivePressure(iPartBound) = GETREAL('Part-Boundary'//TRIM(hilf)//'-AdaptivePressure','0.')
       IF (PartBound%AdaptivePressure(iPartBound).EQ.0.) CALL abort(&
__STAMP__&
,'Error during ParticleBoundary init: Part-Boundary'//TRIM(hilf)//'-AdaptivePressure not defined')
     END IF
     PartBound%Voltage(iPartBound)         = GETREAL('Part-Boundary'//TRIM(hilf)//'-Voltage','0')
  CASE('reflective')
#if defined(IMPA) || defined(ROS)
     PartMeshHasReflectiveBCs=.TRUE.
#endif
     PartBound%TargetBoundCond(iPartBound) = PartBound%ReflectiveBC
     PartBound%MomentumACC(iPartBound)     = GETREAL('Part-Boundary'//TRIM(hilf)//'-MomentumACC','0')
     PartBound%WallTemp(iPartBound)        = GETREAL('Part-Boundary'//TRIM(hilf)//'-WallTemp','0')
     PartBound%TransACC(iPartBound)        = GETREAL('Part-Boundary'//TRIM(hilf)//'-TransACC','0')
     PartBound%VibACC(iPartBound)          = GETREAL('Part-Boundary'//TRIM(hilf)//'-VibACC','0')
     PartBound%RotACC(iPartBound)          = GETREAL('Part-Boundary'//TRIM(hilf)//'-RotACC','0')
     PartBound%ElecACC(iPartBound)         = GETREAL('Part-Boundary'//TRIM(hilf)//'-ElecACC','0')
     PartBound%Resample(iPartBound)        = GETLOGICAL('Part-Boundary'//TRIM(hilf)//'-Resample','.FALSE.')
     PartBound%WallVelo(1:3,iPartBound)    = GETREALARRAY('Part-Boundary'//TRIM(hilf)//'-WallVelo',3,'0. , 0. , 0.')
     PartBound%Voltage(iPartBound)         = GETREAL('Part-Boundary'//TRIM(hilf)//'-Voltage','0')
     PartBound%SolidState(iPartBound)      = GETLOGICAL('Part-Boundary'//TRIM(hilf)//'-SolidState','.TRUE.')
     PartBound%LiquidSpec(iPartBound)      = GETINT('Part-Boundary'//TRIM(hilf)//'-LiquidSpec','0')
     IF(PartBound%SolidState(iPartBound))THEN
       SolidSimFlag = .TRUE.
       PartBound%SolidCatalytic(iPartBound)    = GETLOGICAL('Part-Boundary'//TRIM(hilf)//'-SolidCatalytic','.FALSE.')
       PartBound%SolidSpec(iPartBound)         = GETINT('Part-Boundary'//TRIM(hilf)//'-SolidSpec','0')
       PartBound%SolidPartDens(iPartBound)     = GETREAL('Part-Boundary'//TRIM(hilf)//'-SolidPartDens','1.0E+19')
       PartBound%SolidMassIC(iPartBound)       = GETREAL('Part-Boundary'//TRIM(hilf)//'-SolidMassIC','3.2395E-25')
       PartBound%SolidAreaIncrease(iPartBound) = GETREAL('Part-Boundary'//TRIM(hilf)//'-SolidAreaIncrease','1.')
       PartBound%SolidCrystalIndx(iPartBound)  = GETINT('Part-Boundary'//TRIM(hilf)//'-SolidCrystalIndx','4')
     END IF
     IF (PartBound%LiquidSpec(iPartBound).GT.nSpecies) CALL abort(&
__STAMP__&
     ,'Particle Boundary Liquid Species not defined. Liquid Species: ',PartBound%LiquidSpec(iPartBound))
     ! Parameters for evaporation pressure using Antoine Eq.
     PartBound%ParamAntoine(1:3,iPartBound) = GETREALARRAY('Part-Boundary'//TRIM(hilf)//'-ParamAntoine',3,'0. , 0. , 0.')
     IF ( (.NOT.PartBound%SolidState(iPartBound)) .AND. (ALMOSTZERO(PartBound%ParamAntoine(1,iPartBound))) &
          .AND. (ALMOSTZERO(PartBound%ParamAntoine(2,iPartBound))) .AND. (ALMOSTZERO(PartBound%ParamAntoine(3,iPartBound))) ) THEN
        CALL abort(&
__STAMP__&
       ,'Antoine Parameters not defined for Liquid Particle Boundary: ',iPartBound)
     END IF
     IF (.NOT.PartBound%SolidState(iPartBound)) LiquidSimFlag = .TRUE.
     IF (PartBound%NbrOfSpeciesSwaps(iPartBound).gt.0) THEN  
       !read Species to be changed at wall (in, out), out=0: delete
       PartBound%ProbOfSpeciesSwaps(iPartBound)= GETREAL('Part-Boundary'//TRIM(hilf)//'-ProbOfSpeciesSwaps','1.')
       DO iSwaps=1,PartBound%NbrOfSpeciesSwaps(iPartBound)
         WRITE(UNIT=hilf2,FMT='(I0)') iSwaps
         PartBound%SpeciesSwaps(1:2,iSwaps,iPartBound) = &
             GETINTARRAY('Part-Boundary'//TRIM(hilf)//'-SpeciesSwaps'//TRIM(hilf2),2,'0. , 0.')
       END DO
     END IF
  CASE('periodic')
     PartBound%TargetBoundCond(iPartBound) = PartBound%PeriodicBC
     PartMeshHasPeriodicBCs = .TRUE.
  CASE('simple_anode')
     PartBound%TargetBoundCond(iPartBound) = PartBound%SimpleAnodeBC
  CASE('simple_cathode')
     PartBound%TargetBoundCond(iPartBound) = PartBound%SimpleCathodeBC
  CASE('symmetric')
#if defined(IMPA) || defined(ROS)
     PartMeshHasReflectiveBCs=.TRUE.
#endif
     PartBound%TargetBoundCond(iPartBound) = PartBound%SymmetryBC
     PartBound%WallVelo(1:3,iPartBound)    = (/0.,0.,0./)
  CASE('analyze')
     PartBound%TargetBoundCond(iPartBound) = PartBound%AnalyzeBC
     IF (PartBound%NbrOfSpeciesSwaps(iPartBound).gt.0) THEN  
       !read Species to be changed at wall (in, out), out=0: delete
       PartBound%ProbOfSpeciesSwaps(iPartBound)= GETREAL('Part-Boundary'//TRIM(hilf)//'-ProbOfSpeciesSwaps','1.')
       DO iSwaps=1,PartBound%NbrOfSpeciesSwaps(iPartBound)
         WRITE(UNIT=hilf2,FMT='(I0)') iSwaps
         PartBound%SpeciesSwaps(1:2,iSwaps,iPartBound) = &
             GETINTARRAY('Part-Boundary'//TRIM(hilf)//'-SpeciesSwaps'//TRIM(hilf2),2,'0. , 0.')
       END DO
     END IF
  CASE DEFAULT
     SWRITE(*,*) ' Boundary does not exists: ', TRIM(tmpString)
     CALL abort(&
__STAMP__&
         ,'Particle Boundary Condition does not exist')
  END SELECT
  PartBound%SourceBoundName(iPartBound) = TRIM(GETSTR('Part-Boundary'//TRIM(hilf)//'-SourceName'))
  PartBound%UseForQCrit(iPartBound) = GETLOGICAL('Part-Boundary'//TRIM(hilf)//'-UseForQCrit','.TRUE.')
  SWRITE(*,*)"PartBound",iPartBound,"is used for the Q-Criterion"
END DO

IF (nMacroRestartFiles.GT.0) THEN
  IF (ALL(.NOT.MacroRestartFileUsed(:))) CALL abort(&
  __STAMP__&
  ,'None of defined Macro-Restart-Files used for any init!')
  DO FileID = 1,nMacroRestartFiles
    IF (.NOT.MacroRestartFileUsed(FileID)) THEN
      SWRITE(*,*) "WARNING: MacroRestartFile: ",FileID," not used for any Init"
    END IF
  END DO
END IF

DEALLOCATE(PartBound%AmbientMeanPartMass)
DEALLOCATE(PartBound%AmbientTemp)
! Set mapping from field boundary to particle boundary index
ALLOCATE(PartBound%MapToPartBC(1:nBCs))
PartBound%MapToPartBC(:)=-10
DO iPBC=1,nPartBound
  DO iBC = 1, nBCs
    IF (BoundaryType(iBC,BC_TYPE).EQ.0) THEN
      PartBound%MapToPartBC(iBC) = -1 !there are no internal BCs in the mesh, they are just in the name list!
      SWRITE(*,*)"... PartBound",iPBC,"is internal bound, no mapping needed"
    ELSEIF(BoundaryType(iBC,BC_TYPE).EQ.100)THEN
      IF(DoRefMapping)THEN
        SWRITE(UNIT_STDOUT,'(A)') ' Analyze sides are not implemented for DoRefMapping=T, because '//  &
                                  ' orientation of SideNormVec is unknown.'
     CALL abort(&
__STAMP__&
,' Analyze-BCs cannot be used for internal reflection in general cases! ')
      END IF
    END IF
    IF (TRIM(BoundaryName(iBC)).EQ.TRIM(PartBound%SourceBoundName(iPBC))) THEN
      PartBound%MapToPartBC(iBC) = iPBC !PartBound%TargetBoundCond(iPBC)
      SWRITE(*,*)"... Mapped PartBound",iPBC,"on FieldBound",BoundaryType(iBC,1),",i.e.:",TRIM(BoundaryName(iBC))
    END IF
  END DO
END DO
! Errorhandler for PartBound-Types that could not be mapped to the 
! FieldBound-Types.
DO iBC = 1,nBCs
  IF (PartBound%MapToPartBC(iBC).EQ.-10) THEN
    CALL abort(&
__STAMP__&
    ,' PartBound%MapToPartBC for Boundary is not set. iBC: :',iBC)
  END IF
END DO

ALLOCATE(PEM%Element(1:PDM%maxParticleNumber), PEM%lastElement(1:PDM%maxParticleNumber), STAT=ALLOCSTAT) 
IF (ALLOCSTAT.NE.0) THEN
 CALL abort(&
__STAMP__&
  ,' Cannot allocate PEM arrays!')
END IF
IF (useDSMC.OR.PartPressureCell) THEN
  ALLOCATE(PEM%pStart(1:nElems)                         , &
           PEM%pNumber(1:nElems)                        , &
           PEM%pEnd(1:nElems)                           , &
           PEM%pNext(1:PDM%maxParticleNumber)           , STAT=ALLOCSTAT) 
           !PDM%nextUsedPosition(1:PDM%maxParticleNumber)
  IF (ALLOCSTAT.NE.0) THEN
    CALL abort(&
__STAMP__&
    , ' Cannot allocate DSMC PEM arrays!')
  END IF
END IF
IF (useDSMC) THEN
  ALLOCATE(PDM%PartInit(1:PDM%maxParticleNumber), STAT=ALLOCSTAT) 
           !PDM%nextUsedPosition(1:PDM%maxParticleNumber)
  IF (ALLOCSTAT.NE.0) THEN
    CALL abort(&
__STAMP__&
    ,' Cannot allocate DSMC PEM arrays!')
  END IF
END IF

!--- Read Manual Time Step
useManualTimeStep = .FALSE.
ManualTimeStep = GETREAL('Particles-ManualTimeStep', '0.0')
IF (ManualTimeStep.GT.0.0) THEN
  useManualTimeStep=.True.
END IF
#if (PP_TimeDiscMethod==201||PP_TimeDiscMethod==200)
  dt_part_ratio = GETREAL('Particles-dt_part_ratio', '3.8')
  overrelax_factor = GETREAL('Particles-overrelax_factor', '1.0')
#if (PP_TimeDiscMethod==200)
IF ( ALMOSTEQUAL(overrelax_factor,1.0) .AND. .NOT.ALMOSTEQUAL(dt_part_ratio,3.8) ) THEN
  overrelax_factor = dt_part_ratio !compatibility
END IF
#endif
#endif

! initialization of surface model flags
KeepWallParticles = .FALSE.
IF (SolidSimFlag) THEN
  !0: elastic/diffusive reflection, 1:ad-/desorption empiric, 2:chem. ad-/desorption UBI-QEP
  PartSurfaceModel = GETINT('Particles-SurfaceModel','0')
ELSE
  PartSurfaceModel = 0
END IF
IF (PartSurfaceModel.GT.0 .AND. .NOT.useDSMC) THEN
  CALL abort(&
__STAMP__&
,'Cant use surfacemodel>0 withoput useDSMC flag!')
END IF

!--- initialize randomization
nRandomSeeds = GETINT('Part-NumberOfRandomSeeds','0')
CALL RANDOM_SEED(Size = SeedSize)    ! specifies compiler specific minimum number of seeds
ALLOCATE(Seeds(SeedSize))
Seeds(:)=1 ! to ensure a solid run when an unfitting number of seeds is provided in ini
IF(nRandomSeeds.EQ.-1) THEN
  ! ensures different random numbers through irreproducable random seeds (via System_clock)
  CALL InitRandomSeed(nRandomSeeds,SeedSize,Seeds)
ELSE IF(nRandomSeeds.EQ.0) THEN
 !   IF (Restart) THEN
 !   CALL !numbers from state file
 ! ELSE IF (.NOT.Restart) THEN
CALL InitRandomSeed(nRandomSeeds,SeedSize,Seeds)
ELSE IF(nRandomSeeds.GT.0) THEN
  ! read in numbers from ini
  IF(nRandomSeeds.GT.SeedSize) THEN
    SWRITE (*,*) 'Expected ',SeedSize,'seeds. Provided ',nRandomSeeds,'. Computer uses default value for all unset values.'
  ELSE IF(nRandomSeeds.LT.SeedSize) THEN
    SWRITE (*,*) 'Expected ',SeedSize,'seeds. Provided ',nRandomSeeds,'. Computer uses default value for all unset values.'
  END IF
  DO iSeed=1,MIN(SeedSize,nRandomSeeds)
    WRITE(UNIT=hilf,FMT='(I0)') iSeed
    Seeds(iSeed)= GETINT('Particles-RandomSeed'//TRIM(hilf))
  END DO
  IF (ALL(Seeds(:).EQ.0)) THEN
    CALL ABORT(&
     __STAMP__&
     ,'Not all seeds can be set to zero ')
  END IF
  CALL InitRandomSeed(nRandomSeeds,SeedSize,Seeds)
ELSE 
  SWRITE (*,*) 'Error: nRandomSeeds not defined.'//&
  'Choose nRandomSeeds'//&
  '=-1    pseudo random'//&
  '= 0    hard-coded deterministic numbers'//&
  '> 0    numbers from ini. Expected ',SeedSize,'seeds.'
END IF


!DoZigguratSampling = GETLOGICAL('Particles-DoZigguratSampling','.FALSE.')
DoPoissonRounding = GETLOGICAL('Particles-DoPoissonRounding','.FALSE.')
DoTimeDepInflow   = GETLOGICAL('Particles-DoTimeDepInflow','.FALSE.')

DO iSpec = 1, nSpecies
  DO iInit = Species(iSpec)%StartnumberOfInits, Species(iSpec)%NumberOfInits
    IF(Species(iSpec)%Init(iInit)%InflowRiseTime.GT.0.)THEN
      IF(.NOT.DoPoissonRounding .AND. .NOT.DoTimeDepInflow)  CALL CollectiveStop(&
__STAMP__, &
' Linearly ramping of inflow-number-of-particles is only possible with PoissonRounding or DoTimeDepInflow!')
    END IF      
  END DO ! iInit = 0, Species(iSpec)%NumberOfInits
END DO ! iSpec = 1, nSpecies


DelayTime = GETREAL('Part-DelayTime','0.')

!-- Read Flag if warnings to be displayed for rejected velocities when virtual Pre-Inserting region (vpi) is used with PartDensity
OutputVpiWarnings = GETLOGICAL('Particles-OutputVpiWarnings','.FALSE.')


! init interpolation
CALL InitializeInterpolation() ! not any more required ! has to be called earliear
CALL InitPIC()
! always, because you have to construct a halo_eps region around each bc element

#ifdef MPI
CALL MPI_BARRIER(PartMPI%COMM,IERROR)
#endif /*MPI*/
SWRITE(UNIT_StdOut,'(132("-"))')
SWRITE(UNIT_stdOut,'(A)')' INIT FIBGM...' 
SafetyFactor  =GETREAL('Part-SafetyFactor','1.0')
halo_eps_velo =GETREAL('Particles-HaloEpsVelo','0')

!-- AuxBCs
nAuxBCs=GETINT('Part-nAuxBCs','0')
IF (nAuxBCs.GT.0) THEN
  UseAuxBCs=.TRUE.
  ALLOCATE (AuxBCType(1:nAuxBCs) &
            ,AuxBCMap(1:nAuxBCs) )
  AuxBCMap=0
  !- Read in BC parameters
  ALLOCATE(PartAuxBC%TargetBoundCond(1:nAuxBCs))
  ALLOCATE(PartAuxBC%MomentumACC(1:nAuxBCs))
  ALLOCATE(PartAuxBC%WallTemp(1:nAuxBCs))
  ALLOCATE(PartAuxBC%TransACC(1:nAuxBCs))
  ALLOCATE(PartAuxBC%VibACC(1:nAuxBCs))
  ALLOCATE(PartAuxBC%RotACC(1:nAuxBCs))
  ALLOCATE(PartAuxBC%ElecACC(1:nAuxBCs))
  ALLOCATE(PartAuxBC%Resample(1:nAuxBCs))
  ALLOCATE(PartAuxBC%WallVelo(1:3,1:nAuxBCs))
  ALLOCATE(PartAuxBC%NbrOfSpeciesSwaps(1:nAuxBCs))
  !--determine MaxNbrOfSpeciesSwaps for correct allocation
  MaxNbrOfSpeciesSwaps=0
  DO iPartBound=1,nAuxBCs
    WRITE(UNIT=hilf,FMT='(I0)') iPartBound
    PartAuxBC%NbrOfSpeciesSwaps(iPartBound)= GETINT('Part-AuxBC'//TRIM(hilf)//'-NbrOfSpeciesSwaps','0')
    MaxNbrOfSpeciesSwaps=max(PartAuxBC%NbrOfSpeciesSwaps(iPartBound),MaxNbrOfSpeciesSwaps)
  END DO
  IF (MaxNbrOfSpeciesSwaps.gt.0) THEN
    ALLOCATE(PartAuxBC%ProbOfSpeciesSwaps(1:nAuxBCs))
    ALLOCATE(PartAuxBC%SpeciesSwaps(1:2,1:MaxNbrOfSpeciesSwaps,1:nAuxBCs))
  END IF
  !--
  DO iPartBound=1,nAuxBCs
    WRITE(UNIT=hilf,FMT='(I0)') iPartBound
    tmpString = TRIM(GETSTR('Part-AuxBC'//TRIM(hilf)//'-Condition','open'))
    SELECT CASE (TRIM(tmpString))
    CASE('open')
      PartAuxBC%TargetBoundCond(iPartBound) = PartAuxBC%OpenBC          ! definitions see typesdef_pic
    CASE('reflective')
      PartAuxBC%TargetBoundCond(iPartBound) = PartAuxBC%ReflectiveBC
      PartAuxBC%MomentumACC(iPartBound)     = GETREAL('Part-AuxBC'//TRIM(hilf)//'-MomentumACC','0')
      PartAuxBC%WallTemp(iPartBound)        = GETREAL('Part-AuxBC'//TRIM(hilf)//'-WallTemp','0')
      PartAuxBC%TransACC(iPartBound)        = GETREAL('Part-AuxBC'//TRIM(hilf)//'-TransACC','0')
      PartAuxBC%VibACC(iPartBound)          = GETREAL('Part-AuxBC'//TRIM(hilf)//'-VibACC','0')
      PartAuxBC%RotACC(iPartBound)          = GETREAL('Part-AuxBC'//TRIM(hilf)//'-RotACC','0')
      PartAuxBC%ElecACC(iPartBound)         = GETREAL('Part-AuxBC'//TRIM(hilf)//'-ElecACC','0')
      PartAuxBC%Resample(iPartBound)        = GETLOGICAL('Part-AuxBC'//TRIM(hilf)//'-Resample','.FALSE.')
      PartAuxBC%WallVelo(1:3,iPartBound)    = GETREALARRAY('Part-AuxBC'//TRIM(hilf)//'-WallVelo',3,'0. , 0. , 0.')
      IF (PartAuxBC%NbrOfSpeciesSwaps(iPartBound).gt.0) THEN
        !read Species to be changed at wall (in, out), out=0: delete
        PartAuxBC%ProbOfSpeciesSwaps(iPartBound)= GETREAL('Part-AuxBC'//TRIM(hilf)//'-ProbOfSpeciesSwaps','1.')
        DO iSwaps=1,PartAuxBC%NbrOfSpeciesSwaps(iPartBound)
          WRITE(UNIT=hilf2,FMT='(I0)') iSwaps
          PartAuxBC%SpeciesSwaps(1:2,iSwaps,iPartBound) = &
            GETINTARRAY('Part-AuxBC'//TRIM(hilf)//'-SpeciesSwaps'//TRIM(hilf2),2,'0. , 0.')
        END DO
      END IF
    CASE DEFAULT
      SWRITE(*,*) ' AuxBC Condition does not exists: ', TRIM(tmpString)
      CALL abort(&
        __STAMP__&
        ,'AuxBC Condition does not exist')
    END SELECT
  END DO
  !- read and count types
  nAuxBCplanes = 0
  nAuxBCcylinders = 0
  nAuxBCcones = 0
  nAuxBCparabols = 0
  DO iAuxBC=1,nAuxBCs
    WRITE(UNIT=hilf,FMT='(I0)') iAuxBC
    AuxBCType(iAuxBC) = TRIM(GETSTR('Part-AuxBC'//TRIM(hilf)//'-Type','plane'))
    SELECT CASE (TRIM(AuxBCType(iAuxBC)))
    CASE ('plane')
      nAuxBCplanes = nAuxBCplanes + 1
      AuxBCMap(iAuxBC) = nAuxBCplanes
    CASE ('cylinder')
      nAuxBCcylinders = nAuxBCcylinders + 1
      AuxBCMap(iAuxBC) = nAuxBCcylinders
    CASE ('cone')
      nAuxBCcones = nAuxBCcones + 1
      AuxBCMap(iAuxBC) = nAuxBCcones
    CASE ('parabol')
      nAuxBCparabols = nAuxBCparabols + 1
      AuxBCMap(iAuxBC) = nAuxBCparabols
    CASE DEFAULT
      SWRITE(*,*) ' AuxBC does not exist: ', TRIM(AuxBCType(iAuxBC))
      CALL abort(&
        __STAMP__&
        ,'AuxBC does not exist')
    END SELECT
  END DO
  !- allocate type-specifics
  IF (nAuxBCplanes.GT.0) THEN
    ALLOCATE (AuxBC_plane(1:nAuxBCplanes))
  END IF
  IF (nAuxBCcylinders.GT.0) THEN
    ALLOCATE (AuxBC_cylinder(1:nAuxBCcylinders))
  END IF
  IF (nAuxBCcones.GT.0) THEN
    ALLOCATE (AuxBC_cone(1:nAuxBCcones))
  END IF
  IF (nAuxBCparabols.GT.0) THEN
    ALLOCATE (AuxBC_parabol(1:nAuxBCparabols))
  END IF
  !- read type-specifics
  DO iAuxBC=1,nAuxBCs
    WRITE(UNIT=hilf,FMT='(I0)') iAuxBC
    SELECT CASE (TRIM(AuxBCType(iAuxBC)))
    CASE ('plane')
      AuxBC_plane(AuxBCMap(iAuxBC))%r_vec = GETREALARRAY('Part-AuxBC'//TRIM(hilf)//'-r_vec',3,'0. , 0. , 0.')
      WRITE(UNIT=hilf2,FMT='(G0)') HUGE(AuxBC_plane(AuxBCMap(iAuxBC))%radius)
      AuxBC_plane(AuxBCMap(iAuxBC))%radius= GETREAL('Part-AuxBC'//TRIM(hilf)//'-radius',TRIM(hilf2))
      n_vec                               = GETREALARRAY('Part-AuxBC'//TRIM(hilf)//'-n_vec',3,'1. , 0. , 0.')
      IF (DOT_PRODUCT(n_vec,n_vec).EQ.0.) THEN
        CALL abort(&
          __STAMP__&
          ,'Part-AuxBC-n_vec is zero for AuxBC',iAuxBC)
      ELSE !scale vector
        AuxBC_plane(AuxBCMap(iAuxBC))%n_vec = n_vec/SQRT(DOT_PRODUCT(n_vec,n_vec))
      END IF
    CASE ('cylinder')
      AuxBC_cylinder(AuxBCMap(iAuxBC))%r_vec = GETREALARRAY('Part-AuxBC'//TRIM(hilf)//'-r_vec',3,'0. , 0. , 0.')
      n_vec                                  = GETREALARRAY('Part-AuxBC'//TRIM(hilf)//'-axis',3,'1. , 0. , 0.')
      IF (DOT_PRODUCT(n_vec,n_vec).EQ.0.) THEN
        CALL abort(&
          __STAMP__&
          ,'Part-AuxBC-axis is zero for AuxBC',iAuxBC)
      ELSE !scale vector
        AuxBC_cylinder(AuxBCMap(iAuxBC))%axis = n_vec/SQRT(DOT_PRODUCT(n_vec,n_vec))
      END IF
      AuxBC_cylinder(AuxBCMap(iAuxBC))%radius  = GETREAL('Part-AuxBC'//TRIM(hilf)//'-radius','1.')
      WRITE(UNIT=hilf2,FMT='(G0)') -HUGE(AuxBC_cylinder(AuxBCMap(iAuxBC))%lmin)
      AuxBC_cylinder(AuxBCMap(iAuxBC))%lmin  = GETREAL('Part-AuxBC'//TRIM(hilf)//'-lmin',TRIM(hilf2))
      WRITE(UNIT=hilf2,FMT='(G0)') HUGE(AuxBC_cylinder(AuxBCMap(iAuxBC))%lmin)
      AuxBC_cylinder(AuxBCMap(iAuxBC))%lmax  = GETREAL('Part-AuxBC'//TRIM(hilf)//'-lmax',TRIM(hilf2))
      AuxBC_cylinder(AuxBCMap(iAuxBC))%inwards = GETLOGICAL('Part-AuxBC'//TRIM(hilf)//'-inwards','.TRUE.')
    CASE ('cone')
      AuxBC_cone(AuxBCMap(iAuxBC))%r_vec = GETREALARRAY('Part-AuxBC'//TRIM(hilf)//'-r_vec',3,'0. , 0. , 0.')
      n_vec                              = GETREALARRAY('Part-AuxBC'//TRIM(hilf)//'-axis',3,'1. , 0. , 0.')
      IF (DOT_PRODUCT(n_vec,n_vec).EQ.0.) THEN
        CALL abort(&
          __STAMP__&
          ,'Part-AuxBC-axis is zero for AuxBC',iAuxBC)
      ELSE !scale vector
        AuxBC_cone(AuxBCMap(iAuxBC))%axis = n_vec/SQRT(DOT_PRODUCT(n_vec,n_vec))
      END IF
      AuxBC_cone(AuxBCMap(iAuxBC))%lmin  = GETREAL('Part-AuxBC'//TRIM(hilf)//'-lmin','0.')
      IF (AuxBC_cone(AuxBCMap(iAuxBC))%lmin.LT.0.) CALL abort(&
          __STAMP__&
          ,'Part-AuxBC-lminis .lt. zero for AuxBC',iAuxBC)
      WRITE(UNIT=hilf2,FMT='(G0)') HUGE(AuxBC_cone(AuxBCMap(iAuxBC))%lmin)
      AuxBC_cone(AuxBCMap(iAuxBC))%lmax  = GETREAL('Part-AuxBC'//TRIM(hilf)//'-lmax',TRIM(hilf2))
      rmax  = GETREAL('Part-AuxBC'//TRIM(hilf)//'-rmax','0.')
      ! either define rmax at lmax or the halfangle
      IF (rmax.EQ.0.) THEN
        AuxBC_cone(AuxBCMap(iAuxBC))%halfangle  = GETREAL('Part-AuxBC'//TRIM(hilf)//'-halfangle','45.')*PI/180.
      ELSE
        AuxBC_cone(AuxBCMap(iAuxBC))%halfangle  = ATAN(rmax/AuxBC_cone(AuxBCMap(iAuxBC))%lmax)
      END IF
      IF (AuxBC_cone(AuxBCMap(iAuxBC))%halfangle.LE.0.) CALL abort(&
          __STAMP__&
          ,'Part-AuxBC-halfangle is .le. zero for AuxBC',iAuxBC)
      AuxBC_cone(AuxBCMap(iAuxBC))%inwards = GETLOGICAL('Part-AuxBC'//TRIM(hilf)//'-inwards','.TRUE.')
      cos2 = COS(AuxBC_cone(AuxBCMap(iAuxBC))%halfangle)**2
      AuxBC_cone(AuxBCMap(iAuxBC))%geomatrix(:,1) &
        = AuxBC_cone(AuxBCMap(iAuxBC))%axis(1)*AuxBC_cone(AuxBCMap(iAuxBC))%axis - (/cos2,0.,0./)
      AuxBC_cone(AuxBCMap(iAuxBC))%geomatrix(:,2) &
        = AuxBC_cone(AuxBCMap(iAuxBC))%axis(2)*AuxBC_cone(AuxBCMap(iAuxBC))%axis - (/0.,cos2,0./)
      AuxBC_cone(AuxBCMap(iAuxBC))%geomatrix(:,3) &
        = AuxBC_cone(AuxBCMap(iAuxBC))%axis(3)*AuxBC_cone(AuxBCMap(iAuxBC))%axis - (/0.,0.,cos2/)
    CASE ('parabol')
      AuxBC_parabol(AuxBCMap(iAuxBC))%r_vec = GETREALARRAY('Part-AuxBC'//TRIM(hilf)//'-r_vec',3,'0. , 0. , 0.')
      n_vec                              = GETREALARRAY('Part-AuxBC'//TRIM(hilf)//'-axis',3,'1. , 0. , 0.')
      IF (DOT_PRODUCT(n_vec,n_vec).EQ.0.) THEN
        CALL abort(&
          __STAMP__&
          ,'Part-AuxBC-axis is zero for AuxBC',iAuxBC)
      ELSE !scale vector
        AuxBC_parabol(AuxBCMap(iAuxBC))%axis = n_vec/SQRT(DOT_PRODUCT(n_vec,n_vec))
      END IF
      AuxBC_parabol(AuxBCMap(iAuxBC))%lmin  = GETREAL('Part-AuxBC'//TRIM(hilf)//'-lmin','0.')
      IF (AuxBC_parabol(AuxBCMap(iAuxBC))%lmin.LT.0.) CALL abort(&
          __STAMP__&
          ,'Part-AuxBC-lmin is .lt. zero for AuxBC',iAuxBC)
      WRITE(UNIT=hilf2,FMT='(G0)') HUGE(AuxBC_parabol(AuxBCMap(iAuxBC))%lmin)
      AuxBC_parabol(AuxBCMap(iAuxBC))%lmax  = GETREAL('Part-AuxBC'//TRIM(hilf)//'-lmax',TRIM(hilf2))
      AuxBC_parabol(AuxBCMap(iAuxBC))%zfac  = GETREAL('Part-AuxBC'//TRIM(hilf)//'-zfac','1.')
      AuxBC_parabol(AuxBCMap(iAuxBC))%inwards = GETLOGICAL('Part-AuxBC'//TRIM(hilf)//'-inwards','.TRUE.')

      n(:,1)=AuxBC_parabol(AuxBCMap(iAuxBC))%axis
      IF (.NOT.ALMOSTZERO(SQRT(n(1,1)**2+n(3,1)**2))) THEN !collinear with y?
        alpha1=ATAN2(n(1,1),n(3,1))
        CALL roty(rot1,alpha1)
        n1=MATMUL(rot1,n)
      ELSE
        alpha1=0.
        CALL ident(rot1)
        n1=n
      END IF
      !print*,'alpha1=',alpha1/PI*180.,'n1=',n1
      IF (.NOT.ALMOSTZERO(SQRT(n1(2,1)**2+n1(3,1)**2))) THEN !collinear with x?
        alpha2=-ATAN2(n1(2,1),n1(3,1))
        CALL rotx(rot2,alpha2)
        n2=MATMUL(rot2,n1)
      ELSE
        CALL abort(&
          __STAMP__&
          ,'vector is collinear with x-axis. this should not be possible... AuxBC:',iAuxBC)
      END IF
      !print*,'alpha2=',alpha2/PI*180.,'n2=',n2
      AuxBC_parabol(AuxBCMap(iAuxBC))%rotmatrix(:,:)=MATMUL(rot2,rot1)
      AuxBC_parabol(AuxBCMap(iAuxBC))%geomatrix4(:,:)=0.
      AuxBC_parabol(AuxBCMap(iAuxBC))%geomatrix4(1,1)=1.
      AuxBC_parabol(AuxBCMap(iAuxBC))%geomatrix4(2,2)=1.
      AuxBC_parabol(AuxBCMap(iAuxBC))%geomatrix4(3,3)=0.
      AuxBC_parabol(AuxBCMap(iAuxBC))%geomatrix4(3,4)=-0.5*AuxBC_parabol(AuxBCMap(iAuxBC))%zfac
      AuxBC_parabol(AuxBCMap(iAuxBC))%geomatrix4(4,3)=-0.5*AuxBC_parabol(AuxBCMap(iAuxBC))%zfac
    CASE DEFAULT
      SWRITE(*,*) ' AuxBC does not exist: ', TRIM(AuxBCType(iAuxBC))
      CALL abort(&
        __STAMP__&
        ,'AuxBC does not exist for AuxBC',iAuxBC)
    END SELECT
  END DO
  CALL MarkAuxBCElems()
ELSE
  UseAuxBCs=.FALSE.
END IF

!-- Finalizing InitializeVariables
CALL InitFIBGM()
!CALL InitSFIBGM()
#ifdef MPI
CALL InitEmissionComm()
#endif /*MPI*/
#ifdef MPI
CALL MPI_BARRIER(PartMPI%COMM,IERROR)
#endif /*MPI*/

SWRITE(UNIT_StdOut,'(132("-"))')

!-- Read parameters for particle-data on region mapping

!-- Read parameters for region mapping
NbrOfRegions = GETINT('NbrOfRegions','0')
IF (NbrOfRegions .GT. 0) THEN
  ALLOCATE(RegionBounds(1:6,1:NbrOfRegions))
  DO iRegions=1,NbrOfRegions
    WRITE(UNIT=hilf2,FMT='(I0)') iRegions
    RegionBounds(1:6,iRegions) = GETREALARRAY('RegionBounds'//TRIM(hilf2),6,'0. , 0. , 0. , 0. , 0. , 0.')
  END DO
END IF

IF (NbrOfRegions .GT. 0) THEN
  CALL MapRegionToElem()
  ALLOCATE(RegionElectronRef(1:3,1:NbrOfRegions))
  DO iRegions=1,NbrOfRegions
    WRITE(UNIT=hilf2,FMT='(I0)') iRegions
    ! 1:3 - rho_ref, phi_ref, and Te[eV]
    RegionElectronRef(1:3,iRegions) = GETREALARRAY('Part-RegionElectronRef'//TRIM(hilf2),3,'0. , 0. , 1.')
    WRITE(UNIT=hilf,FMT='(G0)') RegionElectronRef(2,iRegions)
    phimax_tmp = GETREAL('Part-RegionElectronRef'//TRIM(hilf2)//'-PhiMax',TRIM(hilf))
    IF (phimax_tmp.NE.RegionElectronRef(2,iRegions)) THEN !shift reference point (rho_ref, phi_ref) to phi_max:
      RegionElectronRef(1,iRegions) = RegionElectronRef(1,iRegions) &
        * EXP((phimax_tmp-RegionElectronRef(2,iRegions))/RegionElectronRef(3,iRegions))
      RegionElectronRef(2,iRegions) = phimax_tmp
      SWRITE(*,*) 'WARNING: BR-reference point is shifted to:', RegionElectronRef(1:2,iRegions)
    END IF
  END DO
END IF

exitTrue=.false.
DO iSpec = 1,nSpecies
  DO iInit = Species(iSpec)%StartnumberOfInits, Species(iSpec)%NumberOfInits
    IF((Species(iSpec)%Init(iInit)%ParticleEmissionType .EQ. 3).OR.(Species(iSpec)%Init(iInit)%ParticleEmissionType .EQ. 5)) THEN
      CALL ParticlePressureIni()
      exitTrue=.true.
      EXIT
    END IF
  END DO
  IF (exitTrue) EXIT
END DO

exitTrue=.false.
DO iSpec = 1,nSpecies
  DO iInit = Species(iSpec)%StartnumberOfInits, Species(iSpec)%NumberOfInits
    IF ((Species(iSpec)%Init(iInit)%ParticleEmissionType .EQ. 4).OR.(Species(iSpec)%Init(iInit)%ParticleEmissionType .EQ. 6)) THEN
      CALL ParticlePressureCellIni()
      exitTrue=.true.
      EXIT
    END IF
  END DO
  IF (exitTrue) EXIT
END DO




IF(enableParticleMerge) THEN
 CALL DefinePolyVec(vMPFMergePolyOrder) 
 CALL DefineSplitVec(vMPFMergeCellSplitOrder)
END IF

!-- Floating Potential
ALLOCATE(BCdata_auxSF(1:nPartBound))
DO iPartBound=1,nPartBound
  BCdata_auxSF(iPartBound)%SideNumber=-1 !init value when not used
  BCdata_auxSF(iPartBound)%GlobalArea=0.
  BCdata_auxSF(iPartBound)%LocalArea=0.
END DO
nDataBC_CollectCharges=0
nCollectChargesBCs = GETINT('PIC-nCollectChargesBCs','0')
IF (nCollectChargesBCs .GT. 0) THEN
#if !(defined (PP_HDG) && (PP_nVar==1))
  CALL abort(__STAMP__&
    , 'CollectCharges only implemented for electrostatic HDG!')
#endif
  ALLOCATE(CollectCharges(1:nCollectChargesBCs))
  DO iCC=1,nCollectChargesBCs
    WRITE(UNIT=hilf,FMT='(I0)') iCC
    CollectCharges(iCC)%BC = GETINT('PIC-CollectCharges'//TRIM(hilf)//'-BC','0')
    IF (CollectCharges(iCC)%BC.LT.1 .OR. CollectCharges(iCC)%BC.GT.nPartBound) THEN
      CALL abort(__STAMP__&
      , 'nCollectChargesBCs must be between 1 and nPartBound!')
    ELSE IF (BCdata_auxSF(CollectCharges(iCC)%BC)%SideNumber.EQ. -1) THEN !not set yet
      BCdata_auxSF(CollectCharges(iCC)%BC)%SideNumber=0
      nDataBC_CollectCharges=nDataBC_CollectCharges+1 !side-data will be set in InitializeParticleSurfaceflux!!!
    END IF
    CollectCharges(iCC)%NumOfRealCharges = GETREAL('PIC-CollectCharges'//TRIM(hilf)//'-NumOfRealCharges','0.')
    CollectCharges(iCC)%NumOfNewRealCharges = 0.
    CollectCharges(iCC)%ChargeDist = GETREAL('PIC-CollectCharges'//TRIM(hilf)//'-ChargeDist','0.')
  END DO !iCC
END IF !nCollectChargesBCs .GT. 0

!-- reading BG Gas stuff
!   (moved here from dsmc_init for switching off the initial emission)
IF (useDSMC) THEN
  BGGas%BGGasSpecies  = GETINT('Particles-DSMCBackgroundGas','0')
  IF (BGGas%BGGasSpecies.NE.0) THEN
    IF (Species(BGGas%BGGasSpecies)%NumberOfInits.NE.0 &
      .OR. Species(BGGas%BGGasSpecies)%StartnumberOfInits.NE.0) CALL abort(&
__STAMP__&
,'BGG species can be used ONLY for BGG!')
    IF (Species(BGGas%BGGasSpecies)%Init(0)%UseForInit .OR. Species(BGGas%BGGasSpecies)%Init(0)%UseForEmission) THEN
      SWRITE(*,*) 'WARNING: Emission was switched off for BGG species!'
      Species(BGGas%BGGasSpecies)%Init(0)%UseForInit=.FALSE.
      Species(BGGas%BGGasSpecies)%Init(0)%UseForEmission=.FALSE.
    END IF
    IF (Species(BGGas%BGGasSpecies)%Init(0)%ElemTemperatureFileID.GT.0 &
      .OR. Species(BGGas%BGGasSpecies)%Init(0)%ElemPartDensityFileID.GT.0 &
      .OR. Species(BGGas%BGGasSpecies)%Init(0)%ElemVelocityICFileID .GT.0 ) THEN! &
      !-- from MacroRestartFile (inner DOF not yet implemented!):
      IF(Species(BGGas%BGGasSpecies)%Init(0)%ElemTemperatureFileID.LE.0 .OR. &
        .NOT.ALLOCATED(Species(BGGas%BGGasSpecies)%Init(0)%ElemTemperatureIC)) CALL abort(&
__STAMP__&
,'ElemTemperatureIC not defined in Init0 for BGG from MacroRestartFile!')
      IF(Species(BGGas%BGGasSpecies)%Init(0)%ElemPartDensityFileID.LE.0 .OR. &
        .NOT.ALLOCATED(Species(BGGas%BGGasSpecies)%Init(0)%ElemPartDensity)) CALL abort(&
__STAMP__&
,'ElemPartDensity not defined in Init0 for BGG from MacroRestartFile!')
      IF(Species(BGGas%BGGasSpecies)%Init(0)%ElemVelocityICFileID.LE.0 .OR. &
        .NOT.ALLOCATED(Species(BGGas%BGGasSpecies)%Init(0)%ElemVelocityIC)) THEN
        CALL abort(&
__STAMP__&
,'ElemVelocityIC not defined in Init0 for BGG from MacroRestartFile!')
      ELSE IF (Species(BGGas%BGGasSpecies)%Init(0)%velocityDistribution.NE.'maxwell_lpn') THEN !(use always Init 0 for BGG !!!)
        CALL abort(&
__STAMP__&
,'only maxwell_lpn is implemened as velocity-distribution for BGG from MacroRestartFile!')
      END IF
    ELSE
      !-- constant values (some from init0)
      BGGas%BGGasDensity  = GETREAL('Particles-DSMCBackgroundGasDensity','0.')
      IF (BGGas%BGGasDensity.EQ.0.) CALL abort(&
__STAMP__&
,'BGGas%BGGasDensity must be defined for homogeneous BGG!')
      IF (Species(BGGas%BGGasSpecies)%Init(0)%MWTemperatureIC.EQ.0.) CALL abort(&
__STAMP__&
,'MWTemperatureIC not defined in Init0 for homogeneous BGG!')
    END IF
  END IF !BGGas%BGGasSpecies.NE.0
END IF !useDSMC

END SUBROUTINE InitializeVariables


SUBROUTINE ReadMacroRestartFiles(MacroRestartData)
!===================================================================================================================================
!> read DSMCHOState file and set MacroRestartData values for FileID
!===================================================================================================================================
! MODULES                                                                                                                          !
!----------------------------------------------------------------------------------------------------------------------------------!
USE MOD_Globals
USE MOD_IO_HDF5
USE MOD_HDF5_INPUT             ,ONLY: DatasetExists,GetDataProps,ReadAttribute,ReadArray,GetDataSize
USE MOD_Mesh_Vars              ,ONLY: nGlobalElems, nElems, offsetElem
USE MOD_PARTICLE_Vars          ,ONLY: nSpecies, nMacroRestartFiles
USE MOD_ReadInTools            ,ONLY: GETSTR
USE MOD_Particle_MPI_Vars      ,ONLY: PartMPI
!----------------------------------------------------------------------------------------------------------------------------------!
IMPLICIT NONE
! INPUT / OUTPUT VARIABLES
REAL,INTENT(INOUT)          :: MacroRestartData(1:DSMC_NVARS,1:nElems,1:nSpecies,1:nMacroRestartFiles)
!----------------------------------------------------------------------------------------------------------------------------------!
! LOCAL VARIABLES
CHARACTER(LEN=255)               :: FileName, Type_HDF5, NodeType_HDF5
CHARACTER(32)                    :: hilf
REAL , ALLOCATABLE               :: State_HDF5(:,:)
LOGICAL                          :: exists
INTEGER                          :: nSpecies_HDF5, nVar_HDF5, nElems_HDF5, N_HDF5
INTEGER                          :: nVarAdditional
INTEGER                          :: iFile, iSpec, iElem, iVar
!===================================================================================================================================
DO iFile = 1, nMacroRestartFiles
  IF (nMacroRestartFiles.EQ.1) THEN
    FileName = GETSTR('Part-MacroRestartFile')
  ELSE
    FileName = 'none'
  END IF
  WRITE(UNIT=hilf,FMT='(I0)') iFile
  FileName = GETSTR('Part-MacroRestartFile'//TRIM(hilf),TRIM(FileName))
  IF (TRIM(FileName).EQ.'none') THEN
    CALL abort(&
__STAMP__&
,'Error in Macrofile read in: filename not defined!',iFile)
  END IF

  SWRITE(UNIT_StdOut, '(A)')' INIT MACRO RESTART DATA FROM '//TRIM(FileName)//' ...'
  CALL OpenDataFile(TRIM(FileName),create=.FALSE.,single=.FALSE.,readOnly=.TRUE.,communicatorOpt=PartMPI%COMM)!MPI_COMM_WORLD)
  exists=.FALSE.
  ! check if given file is of type 'DSMCHO_State'
  CALL DatasetExists(File_ID,'File_Type',exists,attrib=.TRUE.)
  IF (exists) THEN
    CALL ReadAttribute(File_ID,'File_Type',1,StrScalar=Type_HDF5)
    IF (TRIM(Type_HDF5).NE.'DSMCHOState') CALL abort(&
__STAMP__&
,'Error in Macrofile read in: is not of type DSMCHO_State!',iFile)
  ELSE
    CALL abort(&
__STAMP__&
,'Error in Macrofile read in: attribute "filetype" does not exist!',iFile)
  END IF
  ! check if number of species is equal
  CALL DatasetExists(File_ID,'NSpecies',exists,attrib=.TRUE.)
  IF (exists) THEN
    CALL ReadAttribute(File_ID,'NSpecies',1,IntegerScalar=nSpecies_HDF5)
    IF (nSpecies_HDF5.NE.nSpecies) CALL abort(&
__STAMP__&
,'Error in Macrofile read in: number of Species does not match!',iFile)
  ELSE
    CALL abort(&
__STAMP__&
,'Error in Macrofile read in: attribute "nSpecies" does not exist!',iFile)
  END IF

  ! check if Dataset SurfaceData exists and read from container
  CALL DatasetExists(File_ID,'ElemData',exists)
  IF (exists) THEN
    CALL GetDataProps('ElemData',nVar_HDF5,N_HDF5,nElems_HDF5,NodeType_HDF5)
    IF (nElems_HDF5.NE.nGlobalElems) CALL abort(&
__STAMP__&
,'Error in Macrofile read in: number of global elements in HDF5-file does not match!')
    IF (N_HDF5.NE.1) CALL abort(&
__STAMP__&
,'Error in Macrofile read in: N!=1 !')
    ! check if (nVar_HDF5-DSMC_NVARS-nVarAdditional) equal to DSMC_NVARS*nSpecies
    nVarAdditional = MOD(nVar_HDF5,DSMC_NVARS)
    IF ((nVar_HDF5-DSMC_NVARS-nVarAdditional).NE.(DSMC_NVARS*nSpecies)) CALL abort(&
__STAMP__&
,'Error in Macrofile read in: wrong Nodetype !')
    IF (NodeType_HDF5.NE.'VISU') CALL abort(&
__STAMP__&
,'Error in Macrofile read in: wrong nVar_HDF5 !')
    SDEALLOCATE(State_HDF5)
    ALLOCATE(State_HDF5(1:nVar_HDF5,nElems))
    CALL ReadArray('ElemData',2,(/nVar_HDF5,nElems/),offsetElem,2,RealArray=State_HDF5(:,:))
    iVar = 1
    DO iSpec = 1, nSpecies
      DO iElem = 1, nElems
        MacroRestartData(:,iElem,iSpec,iFile) = State_HDF5(iVar:iVar-1+DSMC_NVARS,iElem)
      END DO
      iVar = iVar + DSMC_NVARS
    END DO
    SDEALLOCATE(State_HDF5)
  ELSE
    CALL abort(&
__STAMP__&
,'Error in Macrofile read in: dataset "ElemData" does not exist!')
  END IF
  CALL CloseDataFile()
  SWRITE(UNIT_StdOut, '(A)')' INIT MACRO RESTART DATA FROM '//TRIM(FileName)//' DONE!'

END DO ! iFile = 1, nMacroRestartFiles

END SUBROUTINE ReadMacroRestartFiles


SUBROUTINE FinalizeParticles() 
!----------------------------------------------------------------------------------------------------------------------------------!
! finalize particle variables
!----------------------------------------------------------------------------------------------------------------------------------!
! MODULES                                                                                                                          !
!----------------------------------------------------------------------------------------------------------------------------------!
USE MOD_Globals
USE MOD_Particle_Vars
USE MOD_Particle_Mesh_Vars
USE MOD_Particle_Boundary_Vars
!USE MOD_DSMC_Vars,                  ONLY: SampDSMC
!----------------------------------------------------------------------------------------------------------------------------------!
IMPLICIT NONE
! INPUT VARIABLES 
!----------------------------------------------------------------------------------------------------------------------------------!
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
!===================================================================================================================================
#if defined(LSERK)
!#if (PP_TimeDiscMethod==1)||(PP_TimeDiscMethod==2)||(PP_TimeDiscMethod==6)||(PP_TimeDiscMethod>=501 && PP_TimeDiscMethod<=506)
SDEALLOCATE( Pt_temp)
#endif
#if (PP_TimeDiscMethod==509)
IF (velocityOutputAtTime) THEN
  SDEALLOCATE(velocityAtTime)
END IF
#endif /*(PP_TimeDiscMethod==509)*/
#if defined(ROS) || defined(IMPA)
SDEALLOCATE(PartStage)
SDEALLOCATE(PartStateN)
SDEALLOCATE(PartQ)
SDEALLOCATE(PartDtFrac)
SDEALLOCATE(PEM%ElementN)
SDEALLOCATE(PEM%NormVec)
SDEALLOCATE(PEM%PeriodicMoved)
#endif /*defined(ROS) || defined(IMPA)*/
#if defined(IMPA)
SDEALLOCATE(F_PartXk)
SDEALLOCATE(F_PartX0)
SDEALLOCATE(Norm_F_PartXk_old)
SDEALLOCATE(Norm_F_PartXk)
SDEALLOCATE(Norm_F_PartX0)
SDEALLOCATE(PartDeltaX)
SDEALLOCATE(PartLambdaAccept)
SDEALLOCATE(DoPartInNewton)
SDEALLOCATE(PartIsImplicit)
#endif /*defined(IMPA)*/
!SDEALLOCATE(SampDSMC)
SDEALLOCATE(PartPosRef)
SDEALLOCATE(RandomVec)
SDEALLOCATE(PartState)
SDEALLOCATE(LastPartPos)
SDEALLOCATE(PartSpecies)
SDEALLOCATE(Pt)
SDEALLOCATE(PDM%ParticleInside)
SDEALLOCATE(PDM%nextFreePosition)
SDEALLOCATE(PDM%nextFreePosition)
SDEALLOCATE(PDM%dtFracPush)
SDEALLOCATE(PDM%IsNewPart)
SDEALLOCATE(vMPF_SpecNumElem)
SDEALLOCATE(PartMPF)
!SDEALLOCATE(Species%Init)
SDEALLOCATE(Species)
SDEALLOCATE(SpecReset)
SDEALLOCATE(IMDSpeciesID)
SDEALLOCATE(IMDSpeciesCharge)
SDEALLOCATE(PartBound%SourceBoundName)
SDEALLOCATE(PartBound%TargetBoundCond)
SDEALLOCATE(PartBound%MomentumACC)
SDEALLOCATE(PartBound%WallTemp)
SDEALLOCATE(PartBound%TransACC)
SDEALLOCATE(PartBound%VibACC)
SDEALLOCATE(PartBound%RotACC)
SDEALLOCATE(PartBound%ElecACC)
SDEALLOCATE(PartBound%Resample)
SDEALLOCATE(PartBound%WallVelo)
SDEALLOCATE(PartBound%AmbientCondition)
SDEALLOCATE(PartBound%AmbientConditionFix)
SDEALLOCATE(PartBound%AmbientTemp)
SDEALLOCATE(PartBound%AmbientMeanPartMass)
SDEALLOCATE(PartBound%AmbientBeta)
SDEALLOCATE(PartBound%AmbientVelo)
SDEALLOCATE(PartBound%AmbientDens)
SDEALLOCATE(PartBound%AmbientDynamicVisc)
SDEALLOCATE(PartBound%AmbientThermalCond)
SDEALLOCATE(PartBound%Adaptive)
SDEALLOCATE(PartBound%AdaptiveType)
SDEALLOCATE(PartBound%AdaptiveMacroRestartFileID)
SDEALLOCATE(PartBound%AdaptiveTemp)
SDEALLOCATE(PartBound%AdaptivePressure)
SDEALLOCATE(Adaptive_MacroVal)
SDEALLOCATE(PartBound%Voltage)
SDEALLOCATE(PartBound%UseForQCrit)
SDEALLOCATE(PartBound%Voltage_CollectCharges)
SDEALLOCATE(PartBound%NbrOfSpeciesSwaps)
SDEALLOCATE(PartBound%ProbOfSpeciesSwaps)
SDEALLOCATE(PartBound%SpeciesSwaps)
SDEALLOCATE(PartBound%MapToPartBC)
SDEALLOCATE(PartBound%SolidState)
SDEALLOCATE(PartBound%SolidCatalytic)
SDEALLOCATE(PartBound%SolidSpec)
SDEALLOCATE(PartBound%SolidPartDens)
SDEALLOCATE(PartBound%SolidMassIC)
SDEALLOCATE(PartBound%SolidAreaIncrease)
SDEALLOCATE(PartBound%SolidCrystalIndx)
SDEALLOCATE(PartBound%LiquidSpec)
SDEALLOCATE(PartBound%ParamAntoine)
SDEALLOCATE(PEM%Element)
SDEALLOCATE(PEM%lastElement)
SDEALLOCATE(PEM%pStart)
SDEALLOCATE(PEM%pNumber)
SDEALLOCATE(PEM%pEnd)
SDEALLOCATE(PEM%pNext)
SDEALLOCATE(seeds)
SDEALLOCATE(RegionBounds)
SDEALLOCATE(RegionElectronRef)
END SUBROUTINE FinalizeParticles

!-- matrices for coordtrafo:
!SUBROUTINE rotz(mat,a)
!IMPLICIT NONE
!REAL, INTENT(OUT), DIMENSION(3,3) :: mat
!REAL, INTENT(IN) :: a
!mat(:,1)=(/COS(a) ,-SIN(a) , 0./)
!mat(:,2)=(/SIN(a) , COS(a) , 0./)
!mat(:,3)=(/0.     , 0.     , 1./)
!END SUBROUTINE
SUBROUTINE rotx(mat,a)
IMPLICIT NONE
REAL, INTENT(OUT), DIMENSION(3,3) :: mat
REAL, INTENT(IN) :: a
mat(:,1)=(/1.0 , 0.     , 0.  /)
mat(:,2)=(/0.0 , COS(a) ,-SIN(a)/)
mat(:,3)=(/0.0 , SIN(a) , COS(a)/)
END SUBROUTINE
SUBROUTINE roty(mat,a)
IMPLICIT NONE
REAL, INTENT(OUT), DIMENSION(3,3) :: mat
REAL, INTENT(IN) :: a
mat(:,1)=(/ COS(a) , 0., SIN(a)/)
mat(:,2)=(/ 0.     , 1., 0.  /)
mat(:,3)=(/-SIN(a) , 0., COS(a)/)
END SUBROUTINE
SUBROUTINE ident(mat)
IMPLICIT NONE
REAL, INTENT(OUT), DIMENSION(3,3) :: mat
INTEGER :: j
mat = 0.
FORALL(j = 1:3) mat(j,j) = 1.
END SUBROUTINE




SUBROUTINE InitRandomSeed(nRandomSeeds,SeedSize,Seeds)
!===================================================================================================================================
!> Initialize pseudo random numbers: Create Random_seed array
!===================================================================================================================================
! MODULES
#ifdef MPI
USE MOD_Particle_MPI_Vars,     ONLY:PartMPI
#endif
! IMPLICIT VARIABLE HANDLING
!===================================================================================================================================
IMPLICIT NONE
! VARIABLES
INTEGER,INTENT(IN)             :: nRandomSeeds
INTEGER,INTENT(IN)             :: SeedSize
INTEGER,INTENT(INOUT)          :: Seeds(SeedSize)
!----------------------------------------------------------------------------------------------------------------------------------!
! LOCAL VARIABLES
INTEGER                        :: iSeed,DateTime(8),ProcessID,iStat,OpenFileID,GoodSeeds
INTEGER(KIND=8)                :: Clock,AuxilaryClock
LOGICAL                        :: uRandomExists
!==================================================================================================================================

uRandomExists=.FALSE.
IF (nRandomSeeds.NE.-1) THEN
  Clock     = 1536679165842_8
  ProcessID = 3671
ELSE
! First try if the OS provides a random number generator
  OPEN(NEWUNIT=OpenFileID, FILE="/dev/urandom", ACCESS="stream", &
       FORM="unformatted", ACTION="read", STATUS="old", IOSTAT=iStat)
  IF (iStat.EQ.0) THEN
    READ(OpenFileID) Seeds
    CLOSE(OpenFileID)
    uRandomExists=.TRUE.
  ELSE
    ! Fallback to XOR:ing the current time and pid. The PID is
    ! useful in case one launches multiple instances of the same
    ! program in parallel.
    CALL SYSTEM_CLOCK(COUNT=Clock)
    IF (Clock .EQ. 0) THEN
      CALL DATE_AND_TIME(values=DateTime)
      Clock =(DateTime(1) - 1970) * 365_8 * 24 * 60 * 60 * 1000 &
      + DateTime(2) * 31_8 * 24 * 60 * 60 * 1000 &
      + DateTime(3) * 24_8 * 60 * 60 * 1000 &
      + DateTime(5) * 60 * 60 * 1000 &
      + DateTime(6) * 60 * 1000 &
      + DateTime(7) * 1000 &
      + DateTime(8)
    END IF
    ProcessID = GetPID_C()
  END IF
END IF
IF(.NOT. uRandomExists) THEN
  Clock = IEOR(Clock, INT(ProcessID, KIND(Clock)))
  AuxilaryClock=Clock
  DO iSeed = 1, SeedSize
#ifdef MPI
    IF (nRandomSeeds.EQ.0) THEN
      AuxilaryClock=AuxilaryClock+PartMPI%MyRank
    ELSE IF(nRandomSeeds.GT.0) THEN
      AuxilaryClock=AuxilaryClock+(PartMPI%MyRank+1)*Seeds(iSeed)*37
    END IF
#else
    IF (nRandomSeeds.GT.0) THEN
      AuxilaryClock=AuxilaryClock+Seeds(iSeed)*37
    END IF
#endif
    IF (AuxilaryClock .EQ. 0) THEN
      AuxilaryClock = 104729
    ELSE
      AuxilaryClock = MOD(AuxilaryClock, 4294967296_8)
    END IF
    AuxilaryClock = MOD(AuxilaryClock * 279470273_8, 4294967291_8)
    GoodSeeds = INT(MOD(AuxilaryClock, INT(HUGE(0),KIND=8)), KIND(0))
    Seeds(iSeed) = GoodSeeds
  END DO
END IF
CALL RANDOM_SEED(PUT=Seeds)

END SUBROUTINE InitRandomSeed


END MODULE MOD_ParticleInit
