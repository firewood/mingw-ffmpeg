#!/bin/bash


OPERATION=$1
BUILD_PACKAGES="nasm yasm pthreads zlib bzip2 faac faad2 gsm lame opencoreamr openssl rtmpdump libogg libvorbis libtheora x264 xvidcore"
#BUILD_PACKAGES=""
#BUILT_PACKAGES="nasm yasm pthreads zlib bzip2 faac faad2 gsm lame opencoreamr openssl rtmpdump libogg libvorbis libtheora x264 xvidcore"


# x264 patch
mkdir -p archives
cat > archives/x264-pthreads.diff << EOT
diff -ur x264.orig/configure x264/configure
--- x264.orig/configure	2010-05-18 05:45:07 +0900
+++ x264/configure	2010-05-19 01:11:06 +0900
@@ -477,6 +477,10 @@
                 pthread="yes"
                 libpthread="-lpthreadGC2 -lws2_32"
                 define PTW32_STATIC_LIB
+            elif cc_check pthread.h "-lpthread -lws2_32 -DPTW32_STATIC_LIB" "pthread_create(0,0,0,0);" ; then
+                pthread="yes"
+                libpthread="-lpthread -lws2_32"
+                define PTW32_STATIC_LIB
             fi
             ;;
         OPENBSD)
EOT


# ffmpeg patch
cat > archives/ffmpeg.diff << EOT
diff -ur ffmpeg.orig/configure ffmpeg/configure
--- ffmpeg.orig/configure	2010-05-17 02:49:04 +0900
+++ ffmpeg/configure	2010-05-17 02:49:04 +0900
@@ -2608,22 +2608,22 @@
                       require  libdirac libdirac_encoder/dirac_encoder.h dirac_encoder_init \$(pkg-config --libs dirac)
 enabled libfaac    && require2 libfaac "stdint.h faac.h" faacEncGetVersion -lfaac
 enabled libfaad    && require2 libfaad faad.h faacDecOpen -lfaad
-enabled libgsm     && require  libgsm gsm/gsm.h gsm_create -lgsm
+enabled libgsm     && require  libgsm gsm.h gsm_create -lgsm
 enabled libmp3lame && require  libmp3lame lame/lame.h lame_init -lmp3lame -lm
 enabled libnut     && require  libnut libnut.h nut_demuxer_init -lnut
 enabled libopencore_amrnb  && require libopencore_amrnb opencore-amrnb/interf_dec.h Decoder_Interface_init -lopencore-amrnb -lm
 enabled libopencore_amrwb  && require libopencore_amrwb opencore-amrwb/dec_if.h D_IF_init -lopencore-amrwb -lm
 enabled libopenjpeg && require libopenjpeg openjpeg.h opj_version -lopenjpeg
-enabled librtmp    && require  librtmp librtmp/rtmp.h RTMP_Init -lrtmp
+enabled librtmp    && require  librtmp librtmp/rtmp.h RTMP_Init -lrtmp -lssl -lcrypto -lwinmm -lws2_32 -lgdi32 -lz
 enabled libschroedinger && add_cflags \$(pkg-config --cflags schroedinger-1.0) &&
                            require libschroedinger schroedinger/schro.h schro_init \$(pkg-config --libs schroedinger-1.0)
 enabled libspeex   && require  libspeex speex/speex.h speex_decoder_init -lspeex
 enabled libtheora  && require  libtheora theora/theoraenc.h th_info_init -ltheoraenc -ltheoradec -logg
 enabled libvorbis  && require  libvorbis vorbis/vorbisenc.h vorbis_info_init -lvorbisenc -lvorbis -logg
-enabled libx264    && require  libx264 x264.h x264_encoder_encode -lx264 -lm &&
+enabled libx264    && require  libx264 x264.h x264_encoder_encode -lx264 -lm -lpthread -lws2_32 &&
                       { check_cpp_condition x264.h "X264_BUILD >= 90" ||
                         die "ERROR: libx264 version must be >= 0.90."; }
-enabled libxvid    && require  libxvid xvid.h xvid_global -lxvidcore
+enabled libxvid    && require  libxvid xvid.h xvid_global -lxvidcore  -lpthread -lws2_32
 enabled mlib       && require  mediaLib mlib_types.h mlib_VectorSub_S16_U8_Mod -lmlib
 
 # libdc1394 check
--- ffmpeg.orig/libavcodec/libxvidff.c	2010-04-20 23:45:34 +0900
+++ ffmpeg/libavcodec/libxvidff-new.c	2010-05-17 04:34:34 +0900
@@ -408,6 +408,11 @@
     xvid_enc_frame.motion = x->me_flags;
     xvid_enc_frame.type = XVID_TYPE_AUTO;
 
+    /* Fix default aspect ratio */
+    if (avctx->sample_aspect_ratio.num == 0 && avctx->sample_aspect_ratio.den == 1) {
+        avctx->sample_aspect_ratio.num = 1;
+    }
+
     /* Pixel aspect ratio setting */
     if (avctx->sample_aspect_ratio.num < 1 || avctx->sample_aspect_ratio.num > 255 ||
         avctx->sample_aspect_ratio.den < 1 || avctx->sample_aspect_ratio.den > 255) {
EOT


# configure
for package in ${BUILD_PACKAGES}
do
  ./modbuild.sh ${package} ${OPERATION}
done


# check enabled modules
ALL_PACKAGES="${BUILD_PACKAGES} ${BUILT_PACKAGES}"
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

PREBUILD1_EXTRAS="--enable-memalign-hack --enable-postproc"
PREBUILD1_EXTRAS+=" --enable-gpl --enable-version3"
PREBUILD1_EXTRAS+=" --disable-ffserver --disable-ffplay --disable-ffprobe"
PREBUILD1_EXTRAS+=" --disable-decoder=aac"
PREBUILD1_EXTRAS+=" --enable-avisynth"
#PREBUILD1_EXTRAS+=" --disable-avfilter"
#PREBUILD1_EXTRAS+=" --enable-small"

# Core2 optimizations
PREBUILD1_EXTRAS2="--extra-cflags='-mtune=core2 -mfpmath=sse -msse -fno-strict-aliasing'"

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

