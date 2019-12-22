#!/bin/bash

# SOURCE The config file.
. ./config

# ┌─────────────────────────────────────────────────────────────────────────┐ 
# │                                                                         │░
# │                   Converts video ready for Instagram.                   │░
# │                                                                         │░
# └─────────────────────────────────────────────────────────────────────────┘░
#  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
# - Adds watermark for 3secs
# - 1080x608, 60sec, 30fps

# Take Arguments.
if [ "$#" -ne 4 ]; then
  echo "$0 $1 $2 $3 $4"  >&2
  echo "Usage: $0 FILE START_TIME DURATION OUTPUTFILE" >&2
  exit 1
fi

# remove the commas from csv - ${1//,}
INPUTFILE=${1//,}
STARTTIME=${2//,}
DURATION=${3//,}
OUTPUTFILE=${4//,}

# If the specified $OUTPUTFILE doesn't = 'original'
# Change it to what is specified.
if [ $OUTPUTFILE = "original" ]; then
  OUTPUTFILE=${INPUTFILE##*/} # filename.ext
fi

OUTPUTBASENAME=${OUTPUTFILE%.*}    # filename

# For intermediate, cut down rendering time by having duration+3sec
# This should be enough for the keyframe issue and freezing the end
# cut because it's not on a keyframe, but speed up encoding because
# not needed to encode to end of file.
INTDURATION=$(($DURATION+3))

# ffmpeg \
#     -sameq -ss 0 -t 60              # Trim to 60secs.
#     -i input.m4v \                  # INPUT File 0
#     -framerate 30 \                 # Framerate of image to 30fps
#     -loop 1 \                       # Loop frame once only (because it's an image.)
#     -i watermark/ldnpk_white.png \  # INPUT File 1
#
#     # 1. [1:v] Filter input 1 (image) : v (video channel)
#     # fade filter (st)arts at 3 seconds, (d)uration of 1 second, (alpha) channel on. set [o]utput [v]ideo as [ov].
#     # 2. [0:v] Filter input 0 (video) : v (video channel) + the [ov]
#     # overlay at row 0, column 0 and output video as [v].
#
#     -filter_complex "[1:v] fade=out:st=3:d=1:alpha=1 [ov]; [0:v][ov] overlay=0:0 [v]" \
#
#     -map "[v]" \                    # Map the filter output [v] to output.
#     -map 0:a \                      # Map input 0 audio to output.
#     -s 1080x608 \                   # Instagram 1.78 aspect ratio
#     -c:v libx264 \                  # Scale to 1280x720.
#     -c:a copy \                     # copy to output, don't overwrite.
#     -r 30 \                         # covert to 30fps
#     -shortest output.mov            # Finish encoding when the shortest input stream ends - which should be the video.
#     -nostdin                        # https://stackoverflow.com/questions/13995715/bash-while-loop-wait-until-task-has-completed

# OVERWRITE
if [ $OVERWRITE = "true" ]; then
  rm $OUTFOLDER/$OUTPUTBASENAME.out.$OUTFORMAT
fi

# Delete the intermediate.
rm $INTFOLDER/$OUTPUTBASENAME.int.$OUTFORMAT

# Stage-1
# ENCODE intermediate video file with watermark over it & scale it down.
ffmpeg -hide_banner \
    -i $INPUTFILE \
    -framerate 59 \
    -loop 1 \
    -i $WATERMARK \
    -s 1080x608 \
    -filter_complex "[1:v] fade=out:st=3:d=1:alpha=1 [ov]; [0:v][ov] overlay=0:0 [v]" \
    -map "[v]" \
    -map 0:a \
    -c:v libx264 \
    -c:a copy \
    -t $INTDURATION \
    -nostdin \
    -shortest $INTFOLDER/$OUTPUTBASENAME.int.$OUTFORMAT

# Stage-2
# STREAM & Trim/cut the intermediate file to required duration
# to the output file.
# This will be a FAST process.
ffmpeg -hide_banner \
    -ss $STARTTIME \
    -i $INTFOLDER/$OUTPUTBASENAME.int.$OUTFORMAT \
    -c:v copy \
    -c:a copy \
    -t $DURATION \
    -nostdin \
    -shortest $OUTFOLDER/$OUTPUTBASENAME.out.$OUTFORMAT

# Remove intermediate
if [ $DELINT = "true" ]; then
  rm $INTFOLDER/$OUTPUTBASENAME.int.$OUTFORMAT
fi

exit 0