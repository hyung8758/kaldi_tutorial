#!/bin/bash
# Copyright 2009-2012  Microsoft Corporation  Johns Hopkins University (Author: Daniel Povey)
# Apache 2.0.
#                             modified by Hyungwon Yang
#                             hyung8758@gmail.com
#                             NAMZ & EMCS Labs

# This script checks several prerequsite codes.

if [ $# -ne 1 ]; then
   echo "Please check your input arguments. Only kaldi directory path is needed." && exit 1
fi

KALDI_ROOT=$1

# sph2pipe check
sph2pipe=$KALDI_ROOT/tools/sph2pipe_v2.5/sph2pipe
if [ ! -x $sph2pipe ]; then
  echo "Could not find (or execute) the sph2pipe program at $sph2pipe";
  exit 1;
fi

# SRILM check
SRILM=$KALDI_ROOT/tools/srilm/bin
cmd_line=`find $SRILM -name ngram-count | wc -l`
if [[ $cmd_line -ne 1 ]] ; then
  echo "$0: Error: the SRILM is not available or compiled" >&2
  echo "$0: Error: We used to install it by default, but." >&2
  echo "$0: Error: this is no longer the case." >&2
  echo "$0: Error: To install it, go to $KALDI_ROOT/tools" >&2
  echo "$0: Error: and run extras/install_srilm.sh" >&2
  exit 1
fi

# G2P check
if [ ! -d local/KoG2P ]; then
    echo "G2P is not found. Downloading G2P..."
    echo "If it is not correctly downloaded then visit 'https://github.com/scarletcho/KoG2P' and download it in /local directory."
    git clone https://github.com/scarletcho/KoG2P.git
    mv KoG2P local/
fi

echo "code checked."
