#!/bin/bash


OPERATION=$1
BUILD_PACKAGES="nasm yasm pthreads zlib bzip2 faac faad2 gsm lame opencoreamr openssl rtmpdump libogg libvorbis libtheora x264 xvidcore"
#BUILD_PACKAGES=""
#BUILT_PACKAGES="nasm yasm pthreads zlib bzip2 faac faad2 gsm lame opencoreamr openssl rtmpdump libogg libvorbis libtheora x264 xvidcore"


ALL_PACKAGES="${BUILD_PACKAGES} ${BUILT_PACKAGES}"
LOCAL_PATCHES="ffmpeg.diff x264-pthreads.diff"
for patch in ${LOCAL_PATCHES}
do
  if [ ! -f archives/${patch} ]; then
    cp -a ${patch} archives/
  fi
done


# configure
for package in ${BUILD_PACKAGES}
do
  ./modbuild.sh ${package} ${OPERATION}
  if [ "$?" -ne 0 ]; then
    exit 1
  fi
done


# check enabled modules
for package in ${ALL_PACKAGES}
do
  if [ -f ${package}.ini ]; then
    echo "#!/bin/bash" > temp.ini
    cat ${package}.ini >> temp.ini
#    sed -e "s/^\([^#].\\+\)=/export ${package}_\1=/" ${package}.ini >> temp.ini
    sed -e "s/^\(ENABLED\)=/export ${package}_\1=/" ${package}.ini >> temp.ini
    source temp.ini
    rm -f temp.ini
  fi
done


if [ "${pthreads_ENABLED} " == "yes " ]; then
  PREBUILD1_EXTRAS+=" --enable-pthreads --extra-ldflags=-static"
fi
if [ "${faac_ENABLED} " == "yes " ]; then
  PREBUILD1_EXTRAS+=" --enable-nonfree --enable-libfaac"
fi
if [ "${faad2_ENABLED} " == "yes " ]; then
  PREBUILD1_EXTRAS+=" --enable-libfaad"
fi
if [ "${gsm_ENABLED} " == "yes " ]; then
  PREBUILD1_EXTRAS+=" --enable-libgsm"
fi
if [ "${lame_ENABLED} " == "yes " ]; then
  PREBUILD1_EXTRAS+=" --enable-libmp3lame"
fi
if [ "${opencoreamr_ENABLED} " == "yes " ]; then
  PREBUILD1_EXTRAS+=" --enable-libopencore-amrnb --enable-libopencore-amrwb"
fi
if [ "${rtmpdump_ENABLED} " == "yes " ]; then
  PREBUILD1_EXTRAS+=" --enable-librtmp"
fi
if [ "${libogg_ENABLED}${libvorbis_ENABLED} " == "yesyes " ]; then
  PREBUILD1_EXTRAS+=" --enable-libvorbis"
fi
if [ "${libogg_ENABLED}${libtheora_ENABLED} " == "yesyes " ]; then
  PREBUILD1_EXTRAS+=" --enable-libtheora"
fi
if [ "${x264_ENABLED} " == "yes " ]; then
  PREBUILD1_EXTRAS+=" --enable-libx264"
fi
if [ "${xvidcore_ENABLED} " == "yes " ]; then
  PREBUILD1_EXTRAS+=" --enable-libxvid"
fi

export PREBUILD1_EXTRAS
./modbuild.sh ffmpeg

