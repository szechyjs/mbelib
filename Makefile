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

CC = gcc
CFLAGS = -O2 -fPIC
INCLUDES = -I.
INSTALL=install
AR=ar
RANLIB=ranlib
LDCONFIG=/sbin/ldconfig
DEST_BASE=/usr/local
DEST_INC=${DEST_BASE}/include
DEST_LIB=${DEST_BASE}/lib
DEST_BIN=${DEST_BASE}/bin

all: libmbe.a libmbe.so.1 libmbe.so ecc.o imbe7200x4400.o imbe7100x4400.c ambe3600x2250.o mbelib.o

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

libmbe.so.1: ecc.o imbe7200x4400.o imbe7100x4400.o ambe3600x2250.o mbelib.o mbelib.h mbelib_const.h imbe7200x4400_const.h ambe3600x2250_const.h
	$(CC) -shared -Wl,-soname,libmbe.so.1 -o libmbe.so.1 \
         ecc.o imbe7200x4400.o imbe7100x4400.o ambe3600x2250.o mbelib.o -lc -lm

libmbe.so: libmbe.so.1
	rm -f libmbe.so
	ln -s libmbe.so.1 libmbe.so

clean:
	rm -f *.o
	rm -f *.a
	rm -f *.so*

install: libmbe.a libmbe.so.1 libmbe.so
	$(INSTALL) mbelib.h $(DEST_INC)
	$(INSTALL) libmbe.a $(DEST_LIB)
	$(INSTALL) libmbe.so.1 $(DEST_LIB)
	$(INSTALL) libmbe.so $(DEST_LIB)
	$(LDCONFIG) $(DEST_LIB)

uninstall: 
	rm -f $(DEST_INC)/mbelib.h
	rm -f $(DEST_LIB)/libmbe.a
	rm -f $(DEST_LIB)/libmbe.so.1
	rm -f $(DEST_LIB)/libmbe.so
