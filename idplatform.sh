#!/bin/sh

UNAME_S=`uname -s`

if [ "x$UNAME_S" = "xDarwin" ]; then
	echo osx
elif [ "x$UNAME_S" = "xLinux" ]; then
	echo linux
else
	echo unknown
fi

