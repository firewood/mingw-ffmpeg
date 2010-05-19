#!/bin/bash


TOPDIR=`pwd`


function get_patch_filename {
  patch_filename=`echo $1 | sed -e "s/.*[\\/?=]//"`
  patch_ext=`echo ${patch_filename} | sed -e "s/.*\(\\..*\)/\1/"`
  if [ "${patch_filename} " == "${patch_ext} " ]; then
    patch_filename=${patch_filename}.txt
    patch_ext=
  fi
  echo "${patch_filename}"
#  echo "${patch_ext}"
}


# check .ini file
if [ ! -f $1.ini ]; then
  echo "$1.ini not found"
  exit 1
fi


# load .ini file
echo "#!/bin/bash" > temp.ini
sed -e "s/^\([^#].\\+\)=/export \1=/" $1.ini >> temp.ini
source temp.ini
#cat temp.ini
rm -f temp.ini


# enabled?
if [ "${ENABLED} " != "yes " ]; then
  echo "[${PACKAGE}] skipped"
  exit 0
fi


# download
mkdir -p archives
cd archives
if [ ! -f ${ARCHIVEFILE} ]; then
  echo "[${PACKAGE}] downloading: ${ARCHIVEFILE}"
  wget ${DOWNLOADURI}
fi
PATCHES="${PATCH1} ${PATCH2} ${PATCH3} ${PATCH4} "
for patch in ${PATCHES}
do
  filename=`get_patch_filename ${patch}`
  if [ ! -f ${filename} ]; then
    echo "[${PACKAGE}] downloading: ${filename}"
    wget -O ${filename} ${patch}
  fi
done
cd ..


# extract options
#if [ "${SRCDIR} " == " " ]; then
#  SRCDIR=${PACKAGE}-${VERSION}
#fi
#if [ "${BLDDIR} " == " " ]; then
#  BLDDIR=${SRCDIR}
#fi
if [ "${ARCHIVETYPE} " == "tar.gz " ]; then
  EXTRACT_COMMAND=tar
  EXTRACT_OPTIONS=zxf
elif [ "${ARCHIVETYPE} " == "tar.bz2 " ]; then
  EXTRACT_COMMAND=tar
  EXTRACT_OPTIONS=jxf
elif [ "${ARCHIVETYPE} " == "tar.lzma " ]; then
  EXTRACT_COMMAND=tar
  EXTRACT_OPTIONS=xf --lzma
fi


# extract
mkdir -p ${PACKAGE}
cd ${PACKAGE}
if [ "${SRCDIR} " == " " ]; then
  SRCDIR=${PACKAGE}-${VERSION}
fi
_SRCDIR=`echo ${SRCDIR}`
_BLDDIR=${BLDDIR}
if [ "${_BLDDIR} " == " " ]; then
  _BLDDIR=${_SRCDIR}
fi
if [ -d "${_BLDDIR}" ]; then
  cd ${_BLDDIR}
  echo "[${PACKAGE}] build directory: ${_BLDDIR}"




else
  echo "[${PACKAGE}] extracting: ${ARCHIVEFILE}"
  ${EXTRACT_COMMAND} ${EXTRACT_OPTIONS} ../archives/${ARCHIVEFILE}

  _SRCDIR=`echo ${SRCDIR}`
  if [ ! -d "${_BLDDIR}" ]; then
    _BLDDIR=${_SRCDIR}
  fi
  cd ${_SRCDIR}
  for patch in ${PATCHES}
  do
    filename=`get_patch_filename ${patch}`
    echo "[${PACKAGE}] applying patch ${filename}"
    patch -p1 < ${TOPDIR}/archives/${filename}
  done

  # configure
  cd ${TOPDIR}/${PACKAGE}/${_BLDDIR}
  #if [ "$2 " == "configure " ]; then
    if [ "${PREBUILD1} " != " " ]; then
      echo "[${PACKAGE}] configuring"
      echo "# ${PREBUILD1} ${PREBUILD1_EXTRAS} ${PREBUILD1_EXTRAS2}"
      ${PREBUILD1} ${PREBUILD1_EXTRAS} ${PREBUILD1_EXTRAS2}
    fi
    if [ "${PREBUILD2} " != " " ]; then
      echo "[${PACKAGE}] configuring"
      echo "# ${PREBUILD2}"
      ${PREBUILD2}
    fi
    if [ "${PREBUILD3} " != " " ]; then
      echo "[${PACKAGE}] configuring"
      echo "# ${PREBUILD3}"
      ${PREBUILD3}
    fi
  #fi
fi


#if [ "$2 " == "clean " ]; then
#  if [ "${CLEAN} " != " " ]; then
#    echo "[${PACKAGE}] clean"
#    echo "# ${CLEAN}"
#    ${CLEAN}
#  fi
#fi


# build
#if [ "$2 " == "build " ]; then
  if [ "${BUILD} " != " " ]; then
    echo "[${PACKAGE}] building"
    echo "# ${BUILD}"
    ${BUILD}
  fi
#fi

#if [ "$2 " == "install " ]; then
  if [ "${POSTBUILD1} " != " " ]; then
    echo "[${PACKAGE}] installing"
    echo "# ${POSTBUILD1}"
    ${POSTBUILD1} < /dev/null
  fi
  if [ "${POSTBUILD2} " != " " ]; then
    echo "[${PACKAGE}] installing"
    echo "# ${POSTBUILD2}"
    ${POSTBUILD2} < /dev/null
  fi
#fi

