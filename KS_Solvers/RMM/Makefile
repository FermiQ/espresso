# Makefile for RMM

include ../../make.inc

# location of needed modules and included files (if any)
MODFLAGS= $(MOD_FLAG) ../../ELPA/src $(MOD_FLAG) ../../LAXlib $(MOD_FLAG) ../../UtilXlib $(MOD_FLAG).

RMM = \
crmmdiagg.o \
rrmmdiagg.o \
rotate_xpsi_k.o \
rotate_xpsi_gamma.o \
gram_schmidt_k.o \
gram_schmidt_gamma.o

all : librmm.a


librmm.a:  $(RMM)
	$(AR) $(ARFLAGS) $@ $?       
	$(RANLIB) $@    

clean :
	- /bin/rm -f *.o *.a *.d *.i *~ *_tmp.f90 *.mod *.L *.x

include make.depend
