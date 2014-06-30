#!/bin/bash

# TODO Adapt these paths to your system
export KALDI_ROOT=/wanglab/kaldi/kaldi-latest/
export REVERB_ASR_ROOT=/home/14/ren/work/experiment/ueda/reverb_tools_for_asr/


# DO NOT CHANGE THIS
export LD_LIBRARY_PATH=$KALDI_ROOT/tools/openfst-1.3.2/lib:$LD_LIBRARY_PATH
export PATH=$PWD/utils/:$KALDI_ROOT/src/bin:$KALDI_ROOT/tools/openfst/bin:$KALDI_ROOT/src/fstbin/:$KALDI_ROOT/src/gmmbin/:$KALDI_ROOT/src/featbin/:$KALDI_ROOT/src/lm/:$KALDI_ROOT/src/sgmmbin/:$KALDI_ROOT/src/sgmm2bin/:$KALDI_ROOT/src/fgmmbin/:$KALDI_ROOT/src/latbin/:$KALDI_ROOT/src/nnetbin:$KALDI_ROOT/src/nnet-cpubin/:$KALDI_ROOT/src/kwsbin:$PWD:$PATH
export LC_ALL=C
