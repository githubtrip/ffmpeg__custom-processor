#!/bin/bash

# SOURCE The config file.
. ./config

# Read the file and loop over the lines.
while read -r line
do
  ./src/scripts/convert_with_ffmpeg.sh $line;
done < "$CSVFILE"