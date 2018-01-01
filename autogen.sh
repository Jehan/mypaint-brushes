#!/bin/sh

# This script does all the magic calls to automake/autoconf and
# friends that are needed to configure a git clone.
#
# If you are compiling from a released tarball you don't need these
# tools and you shouldn't use this script. Just call ./configure
# directly.

ACLOCAL=${ACLOCAL-aclocal-1.13}
AUTOCONF=${AUTOCONF-autoconf}
AUTOMAKE=${AUTOMAKE-automake-1.13}

AUTOCONF_REQUIRED_VERSION=2.62
AUTOMAKE_REQUIRED_VERSION=1.13


PROJECT="mypaint-brushes"
TEST_TYPE=-f
FILE=pkgconfig.pc.in


srcdir=`dirname $0`
test -z "$srcdir" && srcdir=.
ORIGDIR=`pwd`
cd $srcdir


check_version ()
{
    VERSION_A=$1
    VERSION_B=$2

    save_ifs="$IFS"
    IFS=.
    set dummy $VERSION_A 0 0 0
    MAJOR_A=$2
    MINOR_A=$3
    MICRO_A=$4
    set dummy $VERSION_B 0 0 0
    MAJOR_B=$2
    MINOR_B=$3
    MICRO_B=$4
    IFS="$save_ifs"

    if expr "$MAJOR_A" = "$MAJOR_B" > /dev/null; then
        if expr "$MINOR_A" \> "$MINOR_B" > /dev/null; then
           echo "yes (version $VERSION_A)"
        elif expr "$MINOR_A" = "$MINOR_B" > /dev/null; then
            if expr "$MICRO_A" \>= "$MICRO_B" > /dev/null; then
               echo "yes (version $VERSION_A)"
            else
                echo "Too old (version $VERSION_A)"
                DIE=1
            fi
        else
            echo "Too old (version $VERSION_A)"
            DIE=1
        fi
    elif expr "$MAJOR_A" \> "$MAJOR_B" > /dev/null; then
	echo "Major version might be too new ($VERSION_A)"
    else
	echo "Too old (version $VERSION_A)"
	DIE=1
    fi
}

echo
echo "I am testing that you have the tools required to build"
echo "$PROJECT from git. This test is not foolproof."
echo

DIE=0

echo -n "checking for autoconf >= $AUTOCONF_REQUIRED_VERSION ... "
if ($AUTOCONF --version) < /dev/null > /dev/null 2>&1; then
    VER=`$AUTOCONF --version | head -n 1 \
         | grep -iw autoconf | sed "s/.* \([0-9.]*\)[-a-z0-9]*$/\1/"`
    check_version $VER $AUTOCONF_REQUIRED_VERSION
else
    echo
    echo "  You must have autoconf installed to compile $PROJECT."
    echo "  Download the appropriate package for your distribution,"
    echo "  or get the source tarball at ftp://ftp.gnu.org/pub/gnu/autoconf/"
    echo
    DIE=1;
fi


echo -n "checking for automake >= $AUTOMAKE_REQUIRED_VERSION ... "
if ($AUTOMAKE --version) < /dev/null > /dev/null 2>&1; then
   AUTOMAKE=$AUTOMAKE
elif (automake-1.15 --version) < /dev/null > /dev/null 2>&1; then
   AUTOMAKE=automake-1.15
   ACLOCAL=aclocal-1.15
elif (automake-1.14 --version) < /dev/null > /dev/null 2>&1; then
   AUTOMAKE=automake-1.14
   ACLOCAL=aclocal-1.14
elif (automake-1.13 --version) < /dev/null > /dev/null 2>&1; then
   AUTOMAKE=automake-1.13
   ACLOCAL=aclocal-1.13
else
    echo
    echo "  You must have automake $AUTOMAKE_REQUIRED_VERSION or newer installed to compile $PROJECT."
    echo "  Download the appropriate package for your distribution,"
    echo "  or get the source tarball at ftp://ftp.gnu.org/pub/gnu/automake/"
    echo
    DIE=1
fi

if test x$AUTOMAKE != x; then
    VER=`$AUTOMAKE --version \
         | grep automake | sed "s/.* \([0-9.]*\)[-a-z0-9]*$/\1/"`
    check_version $VER $AUTOMAKE_REQUIRED_VERSION
fi


if test "$DIE" -eq 1; then
    echo
    echo "Please install/upgrade the missing tools and call me again."
    echo
    exit 1
fi


test $TEST_TYPE $FILE || {
    echo
    echo "You must run this script in the top-level $PROJECT directory."
    echo
    exit 1
}

if test -z "$ACLOCAL_FLAGS"; then
    m4list="glib-2.0.m4 glib-gettext.m4 intltool.m4 pkg.m4"
    acdir0=`$ACLOCAL --print-ac-dir`
    acpaths=`echo "${ACLOCAL_PATH}:${acdir0}" | sed 's/:/ /g'`
    for file in $m4list; do
        file_path=""
        for acdir in $acpaths; do
            if test -f "${acdir}/${file}"; then
                file_path="$acdir/$file"
                break
            fi
        done
        if test "x$file_path" = "x"; then
            echo "WARNING: cannot find $file in aclocal's search path."
            echo "         You may see fatal macro warnings below."
            echo "         I looked in: $acpaths"
            echo "         If these files are installed in /some/dir, set the "
            echo "         ACLOCAL_FLAGS environment variable to \"-I /some/dir\","
            echo "         or append \":/some/dir\" to ACLOCAL_PATH,"
            echo "         or install $acdir0/$file."
            echo
        fi
    done
fi

rm -rf autom4te.cache

$ACLOCAL $ACLOCAL_FLAGS
RC=$?
if test $RC -ne 0; then
   echo "$ACLOCAL gave errors. Please fix the error conditions and try again."
   exit $RC
fi

touch ChangeLog
$AUTOMAKE --add-missing || exit $?
$AUTOCONF || exit $?

cd $ORIGDIR
