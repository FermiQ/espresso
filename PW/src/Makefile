# Makefile for PW

include ../../make.inc

# location of needed modules and included files (if any)
MODFLAGS= $(BASEMOD_FLAGS) \
          $(MOD_FLAG)../../dft-d3/

PWOBJS = \
pwscf.o 

PWLIBS = \
a2fmod.o \
add_bfield.o \
add_efield.o \
add_vuspsi.o \
add_gatefield.o \
add_paw_to_deeq.o \
add_vhub_to_deeq.o \
addusdens.o \
addusforce.o \
addusstress.o \
allocate_fft.o \
allocate_locpot.o \
allocate_nlpot.o \
allocate_wfc.o \
atomic_rho.o \
atomic_wfc.o \
atomic_wfc_mod.o \
average_pp.o \
acfdt_in_pw.o \
newd.o \
beef.o \
bp_mod.o \
bp_c_phase.o \
bp_calc_btq.o \
bp_qvan3.o \
bp_strings.o \
buffers.o \
c_bands.o \
c_phase_field.o \
orbm_kubo.o \
cdiagh.o \
clean_pw.o \
close_files.o \
compute_becsum.o \
compute_deff.o \
compute_dip.o \
compute_rho.o \
compute_qdipol.o \
compute_qdipol_so.o \
compute_ux.o \
coset.o \
Coul_cut_2D.o \
d_matrix.o \
data_structure.o \
deriv_drhoc.o \
divide_class.o \
divide_class_so.o \
divide_et_impera.o \
dqvan2.o \
drhoc.o \
rotate_wfc.o \
rotate_xpsi.o \
run_driver.o \
dvloc_of_g.o \
dynamics_module.o \
efermig.o \
efermit.o \
electrons.o \
eqvect.o \
esm.o \
esm_common_mod.o \
esm_ewald_mod.o \
esm_force_mod.o \
esm_hartree_mod.o \
esm_local_mod.o \
esm_stres_mod.o \
ewald.o \
ewald_dipole.o \
extfield.o \
exx_base.o \
exx_band.o \
exx.o \
fcp_capacitance.o \
fcp_dyn_calcavg.o \
fcp_dyn_printavg.o \
fcp_dynamics.o \
fcp_hessian.o \
fcp_input.o \
fcp_module.o \
fcp_relaxation.o \
find_group.o \
forces_bp_efield.o \
force_cc.o \
force_corr.o \
force_ew.o \
force_hub.o \
force_lc.o \
force_us.o \
forces.o \
g_psi.o \
g_psi_mod.o \
gcscf_input.o \
gcscf_module.o \
gen_at_dj.o \
gen_at_dy.o \
gen_us_dj.o \
gen_us_dy.o \
get_locals.o \
gk_sort.o \
gradcorr.o \
gram_schmidt.o \
gweights.o \
g2_kin.o \
hs_psi.o \
hs_1psi.o \
h_epsi_her_apply.o \
h_epsi_her_set.o \
h_psi.o \
h_psi_meta.o \
hinit0.o \
hinit1.o \
init_ns.o \
init_q_aeps.o \
init_run.o \
init_us_0.o \
init_us_b0.o \
init_us_1.o \
init_us_2.o \
init_at_1.o \
init_vloc.o \
input.o \
io_rho_xml.o \
irrek.o \
iweights.o \
intersite_V.o \
init_nsg.o \
nsg_adj.o \
start_k.o \
kpoint_grid.o \
lchk_tauxk.o \
ldaU.o \
make_pointlists.o \
makov_payne.o \
manypw.o \
martyna_tuckerman.o \
memory_report.o \
mix_rho.o \
move_ions.o \
multable.o \
n_plane_waves.o \
new_ns.o \
new_nsb.o \
new_nsg.o \
new_occ.o \
ns_adj.o \
non_scf.o \
offset_atom_wfc.o \
openfil.o \
orthoatwfc.o \
output_tau.o \
para.o \
paw_exx.o \
paw_init.o \
paw_onecenter.o \
paw_symmetry.o \
plugin_print_energies.o \
plugin_scf_energy.o \
plugin_scf_potential.o \
plugin_init_ions.o \
plugin_init_cell.o \
plugin_init_potential.o \
plugin_initbase.o \
plugin_clean.o \
plugin_check.o \
plugin_clock.o \
plugin_summary.o \
plugin_initialization.o \
plugin_ext_forces.o \
plugin_int_forces.o \
plugin_read_input.o \
plus_u_full.o \
potinit.o \
print_clock_pw.o \
print_ks_energies.o \
punch.o \
pw_restart_new.o \
add_qexsd_step.o \
pw_init_qexsd_input.o \
pwcom.o \
pw2blip.o \
pw2casino.o \
pw2casino_write.o \
qvan2.o \
rdiagh.o \
read_conf_from_file.o \
read_file_new.o \
realus.o \
remove_atomic_rho.o \
report_mag.o \
restart_in_electrons.o \
rho2zeta.o \
rism_module.o \
ruotaijk.o \
run_pwscf.o \
s_1psi.o \
s_psi.o \
sannp_charge_ew.o \
sannp_energy_ew.o \
sannp_energy_hub.o \
sannp_energy_lc.o \
sannp_energy_paw.o \
sannp_energy_us.o \
sannp_exc.o \
sannp_hartree.o \
sannp_module.o \
sannp_rhoa.o \
sannp_sum_band.o \
save_in_cbands.o \
save_in_electrons.o \
scale_h.o \
loc_scdm.o \
loc_scdm_k.o \
scf_mod.o \
set_kplusq.o \
set_kup_and_kdw.o \
set_occupations.o \
set_rhoc.o \
set_spin_vars.o \
set_vrs.o \
setlocal.o \
setup.o \
spinor.o \
sph_ind.o \
stop_run.o \
stres_cc.o \
stres_ewa.o \
stres_gradcorr.o \
stres_har.o \
stres_hub.o \
stres_knl.o \
stres_loc.o \
stres_us.o \
stres_nonloc_dft.o \
stres_mgga.o \
stress.o \
struct_fact.o \
sum_band.o \
sumkg.o \
sumkt.o \
summary.o \
symme.o \
symm_base.o \
symmetrize_at.o \
tabd.o \
tetra.o \
transform_becsum_so.o \
transform_becsum_nc.o \
transform_qq_so.o \
trnvecc.o \
update_pot.o \
us_exx.o \
usnldiag.o \
v_of_rho.o \
vcsmd.o \
vcsubs.o \
vhpsi.o \
vloc_of_g.o \
vloc_psi.o \
utils.o \
xdm_dispersion.o \
wfcinit.o \
write_ns.o \
wsweight.o \
weights.o \
ortho_wfc.o \
wannier_init.o \
wannier_check.o \
wannier_clean.o \
wannier_occ.o

QEMODS=../../Modules/libqemod.a ../../KS_Solvers/libks_solvers.a ../../upflib/libupf.a \
       ../../FFTXlib/libqefft.a ../../LAXlib/libqela.a ../../UtilXlib/libutil.a ../../dft-d3/libdftd3qe.a

TLDEPS= bindir libs mods libks_solvers dftd3

all : tldeps pw.x

pw.x : $(PWOBJS) libpw.a $(LIBOBJS) $(QEMODS)
	$(LD) $(LDFLAGS) -o $@ \
	   $(PWOBJS) libpw.a $(QEMODS) $(LIBOBJS) $(QELIBS)
	- ( cd ../../bin; ln -fs ../PW/src/$@ . ; \
               ln -fs ../PW/src/$@ dist.x ; ln -fs ../PW/src/$@ manypw.x ; )
# dist.x and manypw.x link the same executable pw.x

libpw.a : $(PWLIBS) 
	$(AR) $(ARFLAGS) $@ $?
	$(RANLIB) $@

tldeps :
	if test -n "$(TLDEPS)" ; then \
	( cd ../.. ; $(MAKE) $(TLDEPS) || exit 1 ) ; fi

clean :
	- /bin/rm -f *.x *.o *.a *~ *_tmp.f90 *.d *.mod *.i *.L

include make.depend

# DO NOT DELETE
