# makefile

FC = gfortran
FCFLAGS = -ffree-form -ffree-line-length-none -ftree-vectorize -Wall

# FCFLAGS = -g  -O0 -ffree-line-length-none -fcheck=all -fno-check-array-temporaries -ffpe-trap=invalid,zero,overflow,underflow -g -fbacktrace -Wall -pedantic

# use the command "nf-config --all" to find the location of your netCDF installation
# and enter the path next to " --prefix    ->" on the line below

netcdf = /usr/local

# should not need to modify anything below this line

# ---------------------------------------------

NC_LIB = $(netcdf)/lib
NC_INC = $(netcdf)/include

CPPFLAGS = -I$(NC_INC)
LDFLAGS  = -L$(NC_LIB)
LIBS     = -lnetcdff

# ---------------------------------------------

INITSOIL_OBJS = initsoil.o

NCPASTE-DP-2D_OBJS = ncpaste-dp-2d.o

NCPASTE-DP-3D_OBJS = ncpaste-dp-3d.o

NCPASTE-LANDFRAC_OBJS = ncpaste-landfrac.o

NCPASTE_OBJS = ncpaste.o

PASTECOORDS_OBJS = pastecoords.o

PASTESOIL_OBJS = pastesoil.o

PASTESOILCODE_OBJS = pastesoilcode.o

SOILCALC_OBJS = parametersmod.o     \
                pedotransfermod.o  \
                soilpropertiesmod.o \
                soilcalc.o

# ---------------------------------------------

.SUFFIXES: .o .f90 .F90 .f .mod

%.o : %.c
	$(CC) $(CFLAGS) -c -o $(*F).o $(CPPFLAGS) $<

%.o : %.f
	$(FC) $(FCFLAGS) -c -o $(*F).o $(CPPFLAGS) $<

%.o : %.f90
	$(FC) $(FCFLAGS) -c -o $(*F).o $(CPPFLAGS) $<

%.o : %.F90
	$(FC) $(FCFLAGS) -c -o $(*F).o $(CPPFLAGS) $<

all::	initsoil ncpaste-dp-2d ncpaste-dp-3d ncpaste-landfrac ncpaste pastecoords pastesoil pastesoilcode soilcalc

initsoil: $(INITSOIL_OBJS)
	$(FC) $(FCFLAGS) -o initsoil $(INITSOIL_OBJS) $(LDFLAGS) $(LIBS)

ncpaste-dp-2d: $(NCPASTE-DP-2D_OBJS)
	$(FC) $(FCFLAGS) -o ncpaste-dp-2d $(NCPASTE-DP-2D_OBJS) $(LDFLAGS) $(LIBS)

ncpaste-dp-3d: $(NCPASTE-DP-3D_OBJS)
	$(FC) $(FCFLAGS) -o ncpaste-dp-3d $(NCPASTE-DP-3D_OBJS) $(LDFLAGS) $(LIBS)

ncpaste-landfrac: $(NCPASTE-LANDFRAC_OBJS)
	$(FC) $(FCFLAGS) -o ncpaste-landfrac $(NCPASTE-LANDFRAC_OBJS) $(LDFLAGS) $(LIBS)

ncpaste: $(NCPASTE_OBJS)
	$(FC) $(FCFLAGS) -o ncpaste $(NCPASTE_OBJS) $(LDFLAGS) $(LIBS)

pastecoords: $(PASTECOORDS_OBJS)
	$(FC) $(FCFLAGS) -o pastecoords $(PASTECOORDS_OBJS) $(LDFLAGS) $(LIBS)

pastesoil: $(PASTESOIL_OBJS)
	$(FC) $(FCFLAGS) -o pastesoil $(PASTESOIL_OBJS) $(LDFLAGS) $(LIBS)

pastesoilcode: $(PASTESOILCODE_OBJS)
	$(FC) $(FCFLAGS) -o pastesoilcode $(PASTESOILCODE_OBJS) $(LDFLAGS) $(LIBS)

soilcalc: $(SOILCALC_OBJS)
	$(FC) $(FCFLAGS) -o soilcalc $(SOILCALC_OBJS) $(LDFLAGS) $(LIBS)

clean::	
	-rm *.o *.mod pastesoilcode ncpaste pastesoil pastecoords soilcalc
