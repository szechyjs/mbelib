# Copyright (C) 2010 mbelib Author
# GPG Key ID: 0xEA5EFE2C (9E7A 5527 9CDC EBF7 BF1B  D772 4F98 E863 EA5E FE2C)
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND ISC DISCLAIMS ALL WARRANTIES WITH
# REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS.  IN NO EVENT SHALL ISC BE LIABLE FOR ANY SPECIAL, DIRECT,
# INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
# LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE
# OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
# PERFORMANCE OF THIS SOFTWARE.

CC 						?= 		gcc
LD						:=		$(CC)
CFLAGS					?=		-g -O2
CFLAGS 					:= 		$(CFLAGS) -fPIC
INCLUDES 				?= 		-I.
INSTALL					?=		install
AR						?=		ar
RANLIB					?=		ranlib
LDCONFIG				?=		/sbin/ldconfig

PREFIX 					?=		/usr/local
DEST_INC				=		${PREFIX}/include
DEST_LIB				=		${PREFIX}/lib
DEST_BIN				=		${DEST_BASE}/bin

PLATFORM ?= $(shell ./idplatform.sh)

# Make sure the platform ID is valid
VALID_PLATFORMS :=      osx linux win32
ifeq ($(filter $(PLATFORM),$(VALID_PLATFORMS)),)
	$(error Invalid PLATFORM '$(PLATFORM)'. Valid platforms are: $(VALID_PLATFORMS))
endif

SOLIB_PFX               :=      libmbe
SONAME_VERSION			:= 		1

ifeq ($(PLATFORM),osx)
	SOLIB               :=      $(SOLIB_PFX).dylib
	SONAME              :=      $(SOLIB_PFX).$(SONAME_VERSION).dylib
	SOVERS              :=      $(SOLIB_PFX).$(SONAME_VERSION).0.dylib
	LDFLAGS             :=      $(LDFLAGS) -dynamiclib -install_name $(SONAME)
endif

ifeq ($(PLATFORM),linux)
	SOLIB               :=      $(SOLIB_PFX).so
	SONAME              :=      $(SOLIB_PFX).so.$(SONAME_VERSION)
	SOVERS              :=      $(SOLIB_PFX).so.$(SONAME_VERSION).0
	LDFLAGS             :=      $(LDFLAGS) -shared -Wl,-soname,$(SONAME)
endif

ifeq ($(PLATFORM),win32)
	SOLIB               :=      $(SOLIB_PFX).dll
	SONAME              :=      $(SOLIB_PFX).$(SONAME_VERSION).dll
	SOVERS              :=      $(SOLIB_PFX).$(SONAME_VERSION).0.dll
	LDFLAGS             :=      $(LDFLAGS) -shared -Wl,-soname,$(SONAME)
endif


all: libmbe.a $(SONAME) $(SOVERS) ecc.o imbe7200x4400.o imbe7100x4400.c ambe3600x2250.o mbelib.o

build: all

ecc.o:  ecc.c mbelib.h
	$(CC) $(CFLAGS) -c ecc.c -o ecc.o $(INCLUDES)

imbe7200x4400.o: imbe7200x4400.c mbelib.h mbelib_const.h imbe7200x4400_const.h
	$(CC) $(CFLAGS) -c imbe7200x4400.c -o imbe7200x4400.o $(INCLUDES)

imbe7100x4400.o: imbe7100x4400.c mbelib.h mbelib_const.h
	$(CC) $(CFLAGS) -c imbe7100x4400.c -o imbe7100x4400.o $(INCLUDES)

ambe3600x2250.o: ambe3600x2250.c mbelib.h mbelib_const.h ambe3600x2250_const.h
	$(CC) $(CFLAGS) -c ambe3600x2250.c -o ambe3600x2250.o $(INCLUDES)

mbelib.o: mbelib.c mbelib.h
	$(CC) $(CFLAGS) -c mbelib.c -o mbelib.o $(INCLUDES)

libmbe.a: ecc.o imbe7200x4400.o imbe7100x4400.o ambe3600x2250.o mbelib.o mbelib.h mbelib_const.h imbe7200x4400_const.h ambe3600x2250_const.h
	$(AR) rvs libmbe.a ecc.o imbe7200x4400.o imbe7100x4400.o ambe3600x2250.o mbelib.o
	$(RANLIB) libmbe.a

$(SOVERS): ecc.o imbe7200x4400.o imbe7100x4400.o ambe3600x2250.o mbelib.o mbelib.h mbelib_const.h imbe7200x4400_const.h ambe3600x2250_const.h
	$(LD) $(LDFLAGS) -o $@ \
         ecc.o imbe7200x4400.o imbe7100x4400.o ambe3600x2250.o mbelib.o -lc -lm

$(SONAME) $(SOLIB): $(SOVERS)
	rm -f $(SONAME) $(SOLIB)
	ln -s $(notdir $<) $(SONAME)
	ln -s $(notdir $<) $(SOLIB)

clean:
	rm -f *.o
	rm -f *.a
	rm -f *.so*
	rm -f $(SOLIB) $(SOVERS) $(SONAME)

install: libmbe.a $(SONAME) $(SOVERS)
	mkdir -p $(DEST_INC) $(DEST_LIB)
	$(INSTALL) mbelib.h $(DEST_INC)
	$(INSTALL) libmbe.a $(DEST_LIB)
	$(INSTALL) $(SOVERS) $(DEST_LIB)
	$(INSTALL) $(SONAME) $(DEST_LIB)
ifneq ($(PLATFORM),osx)
	$(LDCONFIG) $(DEST_LIB)
endif

uninstall: 
	rm -f $(DEST_INC)/mbelib.h
	rm -f $(DEST_LIB)/libmbe.a
	rm -f $(DEST_LIB)/$(SOVERS)
	rm -f $(DEST_LIB)/$(SONAME)
