#!/bin/sh

SRCDIR=""
if grep '^abs_srcdir = ' Makefile > /dev/null ; then
   SRCDIR=$(grep '^abs_srcdir = ' Makefile | sed 's,^abs_srcdir = ,,')
   echo SRCDIR="$SRCDIR"
   if [ ! -d "$SRCDIR" ] ; then
      SRCDIR=""
   elif [ ! -r "$SRCDIR"/README.rst ] ; then
      SRCDIR=""
   fi
fi
if [ -z "$SRCDIR" ] ; then
   echo "Unable to find source directory"
   exit 1
fi

copy_lisp=""
copy_gphts=""
copy_phts=""
GCL_DIST=""

while test $# -gt 0 ; do
   opt=$1
   case ${opt} in
      --copy_lisp)
        copy_lisp=y
        ;;
      --copy_gphts)
        copy_gphts=y
        ;;
      --copy_phts)
        copy_phts=y
        copy_gphts=y
        ;;
      --copy_gcl=*)
        GCL_DIST=`echo ${opt} | sed 's,--copy_gcl=,,'`
        if [ ! -d "${GCL_DIST}" ] ; then
           echo The directory "${GCL_DIST}" does not exist
           exit 1
        fi
        ;;
      --copy_help=*)
        HELP_DIR=`echo ${opt} | sed 's,--copy_help=,,'`
        if [ ! -d "${HELP_DIR}" ] ; then
            echo The directory "${HELP_DIR}" does not exist
            exit 1
        fi
        ;;
      *)
        echo Unrecognized option "${opt}"
        exit 1
        ;;
   esac
   shift
done

echo copy_lisp=\"${copy_lisp}\"
echo copy_gphts=\"${copy_gphts}\"
echo copy_phts=\"${copy_phts}\"
echo GCL_DIST=\"${GCL_DIST}\"
echo HELP_DIR=\"${HELP_DIR}\"

# copy sources
cp -r $SRCDIR dist
cd dist || exit 1
rm -rf .git*

# copy gcl
if [ ! -z "${GCL_DIST}" ] ; then
   cp -r "${GCL_DIST}" gcl
   clean_svn gcl
fi

# copy help files
if [ ! -z "${HELP_DIR}" ] ; then
   mkdir -p pre-generated/target/share/spadhelp
   cp "${HELP_DIR}"/*.help pre-generated/target/share/spadhelp
   cp ../src/doc/*.help pre-generated/target/share/spadhelp
fi

# copy graphic .pht pages
if [ ! -z "${copy_gphts}" ]; then
   mkdir -p pre-generated/target/share/hypertex/pages
   for A in SEGBIND explot2d coverex explot3d graphics ug01 ug07 \
           ug08 ug10 ug11
   do
      cp ../src/doc/${A}.pht pre-generated/target/share/hypertex/pages
   done

# copy generated images
   mkdir -p pre-generated/target/share/viewports
   (cd ../src/doc; \
      for A in *.VIEW; do \
         cp -r $A ../../dist/pre-generated/target/share/viewports ; \
      done)
fi

# copy normal .ht and .pht pages
if [ ! -z "${copy_phts}" ]; then
    mkdir -p pre-generated/target/share/hypertex/pages
    cp ../src/doc/*.ht pre-generated/target/share/hypertex/pages
    cp ../src/doc/*.pht pre-generated/target/share/hypertex/pages
    cp ../src/doc/ht.db pre-generated/target/share/hypertex/pages
fi

# copy databases and algebra bootstrap files
if [ ! -z "${copy_lisp}" ]; then
   (cd ../src/algebra; ls -d *.NRLIB | sed 's,\.NRLIB$,,' ) > ../nrlst
   mkdir -p pre-generated/src/algebra
   for A in $(cat ../nrlst); do
      cp ../src/algebra/${A}.NRLIB/${A}.lsp pre-generated/src/algebra/${A}.lsp
   done
   mkdir -p pre-generated/target/algebra
   cp ../src/algebra/*.daase pre-generated/target/algebra
   cp ../src/algebra/libdb.text pre-generated/target/algebra
   cp ../src/algebra/comdb.text pre-generated/target/algebra
   cp ../src/doc/glossdef.text pre-generated/target/algebra
   cp ../src/doc/glosskey.text pre-generated/target/algebra
   cp -r ../src/algebra/USERS.DAASE pre-generated/target/algebra
   cp -r ../src/algebra/DEPENDENTS.DAASE pre-generated/target/algebra
fi
