#!/bin/bash

# SOURCE The config file.
. ./config

rm $CSVFILE

for ENTRY in "${CSVFOLDER}"/*
do
  if [[ -f $ENTRY ]]; then
    printf "$ENTRY, $CSVDEFAULTSTART, $CSVDEFAULTEND, $CSVNEWNAME \n" >> $CSVFILE
  fi
done