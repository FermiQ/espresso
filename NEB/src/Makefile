# Makefile for NEB

include ../../make.inc

# location of needed modules and included files (if any)
MODFLAGS= $(BASEMOD_FLAGS) \
          $(MOD_FLAG)../../PW/src \
          $(MOD_FLAG)../../dft-d3/

NEBOBJS = \
neb.o \

NEBLIBS = \
compute_scf.o \
engine_to_path_pos.o \
engine_to_path_alat.o \
engine_to_path_nat.o \
engine_to_path_fix_atom_pos.o \
engine_to_path_tot_charge.o \
fcp_opt_routines.o \
fcp_variables.o \
input.o \
gcscf_variables.o \
input.o \
path_base.o \
path_formats.o \
path_gen_inputs.o \
path_input_parameters_module.o \
path_io_routines.o \
path_io_tools.o \
path_io_units_module.o \
path_opt_routines.o \
path_reparametrisation.o \
path_read_cards_module.o \
path_read_namelists_module.o \
path_to_engine_fix_atom_pos.o \
path_variables.o \
set_defaults.o \
stop_run_path.o 

PWOBJS= ../../PW/src/libpw.a
QEMODS = ../../Modules/libqemod.a ../../KS_Solvers/libks_solvers.a ../../upflib/libupf.a \
         ../../FFTXlib/libqefft.a ../../LAXlib/libqela.a ../../UtilXlib/libutil.a ../../dft-d3/libdftd3qe.a
TLDEPS=pwlibs

all : tldeps neb.x path_interpolation.x

neb.x : $(NEBOBJS) libneb.a $(LIBOBJS) $(PWOBJS) $(QEMODS)
	$(LD) $(LDFLAGS) -o $@ \
	$(NEBOBJS) libneb.a $(PWOBJS) $(QEMODS) $(LIBOBJS) $(QELIBS)
	- ( cd ../../bin; ln -fs ../NEB/src/$@ . )

path_interpolation.x : path_interpolation.o libneb.a $(PWOBJS) $(QEMODS) $(LIBOBJS)
	$(LD) $(LDFLAGS) -o $@ \
	path_interpolation.o libneb.a $(PWOBJS) $(QEMODS) $(LIBOBJS) $(QELIBS)
	- ( cd ../../bin ; ln -fs ../NEB/src/$@ . )

libneb.a : $(NEBLIBS)
	$(AR) $(ARFLAGS) $@ $?
	$(RANLIB) $@

tldeps :
	if test -n "$(TLDEPS)" ; then \
	( cd ../.. ; $(MAKE) $(TLDEPS) || exit 1 ) ; fi

clean :
	- /bin/rm -f *.x *.o *.a *~ *_tmp.f90 *.d *.mod *.i *.L
	- /bin/rm -f ../../bin/neb.x
	- /bin/rm -f ../../bin/path_interpolation.x

include make.depend
