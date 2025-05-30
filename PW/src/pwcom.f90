!
! Copyright (C) 2001-2012 Quantum ESPRESSO group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!--------------------------------------------------------------
MODULE klist
  !
  !! This module contains the variables related to the k-points.
  !
  USE kinds,        ONLY : DP
  USE parameters,   ONLY : npk
  !
  IMPLICIT NONE
  !
  SAVE
  !
  CHARACTER (LEN=32) :: smearing 
  !! smearing type
  REAL(DP) :: xk(3,npk)
  !! coordinates of k points
  REAL(DP) :: wk(npk)
  !! weight of k points
  REAL(DP) :: xqq(3)
  !! coordinates of q point (used in the ACFDT part)
  REAL(DP) :: degauss
  !! smearing parameter
  REAL(DP) :: nelec
  !! number of electrons
  REAL(DP) :: nelup=0.0_dp
  !! number of spin-up electrons (if two_fermi_energies=t)
  REAL(DP) :: neldw=0.0_dp
  !! number of spin-dw electrons (if two_fermi_energies=t)
  REAL(DP) :: tot_magnetization
  !! nelup-neldw >= 0 (negative value means unspecified)
  REAL(DP) :: tot_charge
  !! total charge
  REAL(DP) :: qnorm= 0.0_dp
  !! |q|, used in phonon+US calculations only
  INTEGER, ALLOCATABLE :: igk_k(:,:)
  !! index of G corresponding to a given index of k+G
  INTEGER, ALLOCATABLE :: ngk(:)
  !! number of plane waves for each k point
  !
  INTEGER :: nks
  !! number of k points in this pool
  INTEGER :: nkstot
  !! total number of k points
  INTEGER :: ngauss
  !! type of smearing technique
  LOGICAL :: lgauss
  !! if .TRUE.: use gaussian broadening
  LOGICAL :: ltetra
  !! if .TRUE.: use tetrahedra
  LOGICAL :: lxkcry=.FALSE.
  !! if .TRUE.:k-pnts in cryst. basis accepted in input
  LOGICAL :: two_fermi_energies
  !! if .TRUE.: nelup and neldw set ef_up and ef_dw separately
  !
CONTAINS
  !
  !--------------------------------------------------------------
  SUBROUTINE init_igk( npwx, ngm, g, gcutw )
    !--------------------------------------------------------------
    !! Initialize indices \(\text{igk_k}\) and number of plane waves
    !! per k-point:
    !
    !! * \((k_{ik} + G)_i = k_{ik} + G_\text{igk}\);
    !! * i = 1, \text{ngk}(\text{ik});
    !! * \text{igk} = \text{igk}_k(i,ik).
    !
    INTEGER, INTENT (IN) :: npwx, ngm
    REAL(DP), INTENT(IN) :: gcutw, g(3,ngm)
    !
    REAL(DP), ALLOCATABLE :: gk(:)
    INTEGER :: ik
    !
    IF (.NOT.ALLOCATED(igk_k)) ALLOCATE( igk_k(npwx,nks) )
    IF (.NOT.ALLOCATED(ngk))   ALLOCATE( ngk(nks) )
    !
    ALLOCATE ( gk(npwx) )
    igk_k(:,:) = 0
    !
    ! ... The following loop must NOT be called more than once in a run
    ! ... or else there will be problems with variable-cell calculations
    !
    DO ik = 1, nks
       CALL gk_sort( xk(1,ik), ngm, g, gcutw, ngk(ik), igk_k(1,ik), gk )
    ENDDO
    !
    DEALLOCATE( gk )
    !
  END SUBROUTINE init_igk
  !
  !
  SUBROUTINE deallocate_igk( ) 
    !
    IF (ALLOCATED(ngk))     DEALLOCATE( ngk )
    IF (ALLOCATED(igk_k))   DEALLOCATE( igk_k )
    !
  END SUBROUTINE deallocate_igk
  !
  !
END MODULE klist
!
!
!--------------------------------------------------------------
MODULE lsda_mod
  !
  !! It contains the variables needed for the LSDA calculation.
  !
  USE kinds,      ONLY : DP
  USE parameters, ONLY : ntypx, npk
  !
  IMPLICIT NONE
  !
  SAVE
  !
  LOGICAL :: lsda
  !! true if lsda is active
  REAL(DP) :: magtot
  !! total magnetization
  REAL(DP) :: absmag
  !! total absolute magnetization
  REAL(DP) :: starting_magnetization(ntypx)
  !! the magnetization used to start with
  INTEGER :: nspin
  !! number of spin polarization: 2 if lsda, 1 other
  INTEGER :: current_spin
  !! spin of the current kpoint
  INTEGER :: isk(npk)
  !! for each k-point: 1=spin up, 2=spin down
  !
END MODULE lsda_mod
!
!
!
MODULE rap_point_group
   !
   USE kinds,      ONLY : DP
   !
   INTEGER :: code_group
   !! The code of the point group
   INTEGER :: nclass
   !! The number of classes of the point group
   INTEGER :: nelem(12)
   !! The elements of each class
   INTEGER :: elem(8,12)
   !! Which elements in the smat list for each class
   INTEGER :: which_irr(12)
   !! For each class gives its position in the character table.
   !
   COMPLEX(DP) :: char_mat(12,12)
   !! the character tables: rap, class
   !
   CHARACTER(LEN=15) :: name_rap(12)
   !! the name of the representation
   CHARACTER(LEN=3)  :: ir_ram(12)
   !! a string I, R or I+R for infrared, Raman, or
   !! infrared+raman modes.
   CHARACTER(LEN=11) :: gname
   !! the name of the group
   CHARACTER(LEN=5) :: name_class(12)
   !! the name of the class
   CHARACTER(LEN=55) :: elem_name(8,12)=' '
   !! the name of each symmetry in each class
   !
END MODULE rap_point_group
!
!
!
MODULE rap_point_group_so
   !
   USE kinds,      ONLY : DP
   !
   INTEGER :: nrap
   !! The number of classes of the point group
   INTEGER :: nelem_so(24)
   !! The elements of each class
   INTEGER :: elem_so(12,24)
   !! Which elements in the smat list for each class
   INTEGER :: has_e(12,24)
   !! if -1 the smat is multiplied by -E
   INTEGER :: which_irr_so(24)
   !! For each class gives its position in the character table.
   !
   COMPLEX(DP) :: char_mat_so(12,24)
   !! the character tables
   COMPLEX(DP) :: d_spin(2,2,48)
   !! the rotation in spin space
   !
   CHARACTER(len=15) :: name_rap_so(12) 
   !! the name of the representation
   CHARACTER(len=5) :: name_class_so(24)
   !! the name of the class
   CHARACTER(len=5) :: name_class_so1(24)
   !! the name of the class
   CHARACTER(len=55) :: elem_name_so(12,24)=' '
   !! the name of each symmetry in each class
   !
END MODULE rap_point_group_so
!
!
!
MODULE rap_point_group_is
   !
   USE kinds,      ONLY : DP
   !
   INTEGER :: nsym_is
   !! The number of operations of the invariant subgroup
   INTEGER :: code_group_is
   !! The code of the point invariant subgroup
   !
   REAL(DP) :: ft_is(3,48)
   !! The fractional transl. of the invariant subgroup
   REAL(DP) :: sr_is(3,3,48)
   !! The matrices of the invariant subgroup
   !
   COMPLEX(DP) :: d_spin_is(2,2,48)
   !! the rotation in spin space
   !
   CHARACTER(LEN=45) :: sname_is(48)
   !! name of the symmetries
   CHARACTER(LEN=11) :: gname_is
   !! the name of the invariant group
   !
END MODULE rap_point_group_is
!
!
!
MODULE vlocal
  !
  !! The variables needed for the local potential in reciprocal space.
  !
  USE kinds,       ONLY : DP
  USE parameters,  ONLY : ntypx
  !
  SAVE
  !
  COMPLEX(DP), ALLOCATABLE :: strf(:,:)
  !! the structure factor
  REAL(DP), ALLOCATABLE :: vloc(:,:)
  !! the local potential for each atom type
  REAL(DP) :: starting_charge(ntypx)
  !! the atomic charge used to start with
  !
END MODULE vlocal
!
!
!
MODULE wvfct
  !
  !! The variables needed to compute the band structure
  !
  USE kinds, ONLY : DP
  !
  SAVE
  !
  INTEGER ::  npwx
  !! maximum number of PW for wavefunctions
  INTEGER ::  nbndx
  !! max number of bands use in iterative diag
  INTEGER ::  nbnd
  !! number of bands
  INTEGER ::  npw
  !! the number of plane waves
  INTEGER ::  current_k
  !! the index of k-point under consideration
  REAL(DP), ALLOCATABLE :: et(:,:)
  !! eigenvalues of the hamiltonian
  REAL(DP), ALLOCATABLE :: wg(:,:)
  !! the weight of each k point and band
  REAL(DP), ALLOCATABLE :: g2kin(:)
  !! kinetic energy
  INTEGER, ALLOCATABLE :: btype(:,:) 
  !! one if the corresponding state has to be
  !! converged to full accuracy, zero otherwise
  !
END MODULE wvfct
!
!
!
MODULE ener
  !
  !! The variables needed to compute the energies
  !
  USE kinds, ONLY : DP
  !
  SAVE
  !
  REAL(DP) :: etot
  !! the total Kohn-Sham energy of the solid
  REAL(DP) :: hwf_energy
  !! this is the Harris-Weinert-Foulkes energy
  REAL(DP) :: eband
  !! the band energy
  REAL(DP) :: deband
  !! scf correction to have variational energy
  REAL(DP) :: ehart
  !! the Hartree energy
  REAL(DP) :: etxc
  !! the exchange and correlation energy
  REAL(DP) :: vtxc
  !! another exchange-correlation energy
  REAL(DP) :: etxcc
  !! the nlcc exchange and correlation
  REAL(DP) :: ewld
  !! the ewald energy
  REAL(DP) :: elondon
  !! the semi-empirical dispersion energy
  REAL(DP) :: edftd3
  !! the Grimme-d3 dispersion energy
  REAL(DP) :: exdm
  !! the XDM dispersion energy
  REAL(DP) :: demet
  !! variational correction ("-TS") for metals
  REAL(DP) :: epaw
  !! sum of one-center paw contributions
  REAL(DP) :: esol
  !! the solvation energy, from 3D-RISM
  REAL(DP) :: vsol
  !! another solvation energy, from 3D-RISM
  REAL(DP) :: egrand
  !! potentiostat contribution (-mu*N), for GC-SCF
  REAL(DP) :: ef
  !! the Fermi energy
  REAL(DP) :: ef_up
  !! the Fermi energy up (if two_fermi_energies=.TRUE.)
  REAL(DP) :: ef_dw
  !! the Fermi energy down (if two_fermi_energies=.TRUE.)
  !
END MODULE ener
!
!
!
MODULE force_mod
  !
  !! The variables for the first derivative of the energy
  !
  USE kinds, ONLY : DP
  !
  SAVE
  !
  REAL(DP), ALLOCATABLE :: force(:,:)
  !! the force on each atom
  REAL(DP) :: sumfor
  !! norm of the gradient (forces)
  REAL(DP) :: sigma(3,3) 
  !! the stress acting on the system
  LOGICAL :: lforce
  !! if .TRUE. compute the forces
  LOGICAL :: lstres
  !! if .TRUE. compute the stress
  REAL(DP), ALLOCATABLE :: eigenval(:)
  !! eigenvalues of the overlap matrix
  COMPLEX(DP), ALLOCATABLE :: eigenvect(:,:)
  !! eigenvectors of the overlap matrix
  COMPLEX(DP), ALLOCATABLE :: overlap_inv(:,:)
  !! overlap matrix (transposed): (O^{-1/2})^T
  COMPLEX(DP), ALLOCATABLE :: doverlap_inv(:,:)
  !! derivative of the overlap matrix (not transposed): d(O^{-1/2})
  COMPLEX (DP), ALLOCATABLE :: at_dy(:,:), at_dj(:,:)
  !! derivatives of spherical harmonics and spherical Bessel functions (for atomic functions)
  COMPLEX (DP), ALLOCATABLE :: us_dy(:,:), us_dj(:,:)
  !! derivatives of spherical harmonics and spherical Bessel functions (for beta functions)
  !
END MODULE force_mod
!
!
!
MODULE relax
  !
  !! The variables used to control ionic relaxations
  !
  USE kinds, ONLY : DP
  !
  SAVE
  !
  REAL(DP) :: epse = 0.0_dp
  !! threshold on total energy
  REAL(DP) :: epsf
  !! threshold on forces
  REAL(DP) :: epsp
  !! threshold on pressure
  REAL(DP) :: starting_scf_threshold
  !! self-explanatory
  !
END MODULE relax
!
!
!
MODULE cellmd
  !
  !! The variables used to control cell relaxation.
  !
  USE kinds, ONLY : DP
  !
  SAVE
  !
  REAL(DP) :: at_old(3,3)
  !! the lattice vectors at the previous step
  REAL(DP) :: omega_old
  !! the cell volume at the previous step
  REAL(DP) :: cell_factor=0.0_dp
  !! maximum expected (linear) cell contraction
  !! during relaxation/MD
  INTEGER :: nzero
  !! iteration # of last thermalization
  INTEGER :: ntimes=-1
  !! # of thermalization steps to be performed (-i=inf)
  INTEGER :: ntcheck
  !! # of steps between thermalizations
  LOGICAL :: lmovecell
  !! used in cell relaxation
  !
  CHARACTER(LEN=2) :: calc='  '
  !! main switch for variable cell shape MD
  !! see move_ions and vcsmd for allowed values
  !
END MODULE cellmd
!
!
!
MODULE us
  !
  !! These parameters are needed with the US pseudopotentials.
  !
  USE kinds,      ONLY : DP
  !
  SAVE
  !
  INTEGER :: nqxq
  !! size of interpolation table
  INTEGER :: nqx
  !! number of interpolation points
  REAL(DP), PARAMETER:: dq = 0.01D0
  !! space between points in the pseudopotential tab.
  REAL(DP), ALLOCATABLE :: qrad(:,:,:,:)
  !! radial FT of Q functions
  REAL(DP), ALLOCATABLE :: tab(:,:,:)
  !! interpolation table for PPs
  REAL(DP), ALLOCATABLE :: tab_at(:,:,:)
  !! interpolation table for atomic wfc
  LOGICAL :: spline_ps = .FALSE.
  REAL(DP), ALLOCATABLE :: tab_d2y(:,:,:)
  !! for cubic splines
  !
END MODULE us
!
!
!
MODULE fixed_occ
  !
  !! The quantities needed in calculations with fixed occupations.
  !
  USE kinds,      ONLY : DP
  !
  SAVE
  !
  REAL(DP), ALLOCATABLE :: f_inp(:,:)
  !! the occupations for each spin
  LOGICAL :: tfixed_occ
  !! if .TRUE. the occupations are fixed.
  LOGICAL :: one_atom_occupations
  !! if .TRUE. the occupations are decided according to the projections of the
  !! wavefunctions on the initial atomic  wavefunctions (to be used only
  !! for an isolated atom).
  !
END MODULE fixed_occ
!
!
!
MODULE spin_orb
  !
  !! Variables needed for calculations with spin-orbit
  !
  USE kinds,       ONLY : DP
  USE upf_params,  ONLY : lmaxx, lqmax
  !! FIXME: rot_ylm could be dynamically allocated
  !
  SAVE
  !
  LOGICAL :: lspinorb
  !! if .TRUE. this is a spin-orbit calculation
  LOGICAL :: lforcet
  !! if .TRUE. apply Force Theorem to calculate MAE 
  LOGICAL :: starting_spin_angle
  !! if .TRUE. the initial wavefunctions are spin-angle functions. 
  LOGICAL :: domag
  !! if .TRUE. magnetization is computed
  COMPLEX (DP) :: rot_ylm(lqmax,lqmax)
  !! transform real spherical harmonics into complex ones
  COMPLEX (DP), ALLOCATABLE :: fcoef(:,:,:,:,:)
  !! function needed to account for spinors.
  !
END MODULE spin_orb
!
!
!
MODULE pwcom
  !
  USE klist
  USE lsda_mod
  USE vlocal
  USE wvfct
  USE ener
  USE force_mod
  USE relax
  USE cellmd
  USE fixed_occ
  USE spin_orb
  !
END MODULE pwcom
