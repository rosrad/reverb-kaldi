#!/bin/bash

# TODO Adapt these paths to your system
export KALDI_ROOT=/wanglab/kaldi/kaldi-latest/
export REVERB_ASR_ROOT=/home/14/ren/exp/


# the PATH about some subset scripts
export HOME=.
export WORKSPACE=${HOME}/tmp
export CONF=${HOME}/config
#config and taskfile
export TASKFILES=$CONF/taskFiles
# script directory alias
export LOCAL=${HOME}/local
export UTILS=${HOME}/utils
export STEPS=${HOME}/steps

# tools directory alias
export TOOLS=${HOME}/tools
export FIXEDLM=${TOOLS}/LanguageModel

# tmp directory alias
export DATA=${WORKSPACE}/data
export EXP=${WORKSPACE}/exp
export LOG=${WORKSPACE}/log

export TR_CLN=${DATA}/si_tr
export TR_MC=${DATA}/REVERB_tr_cut/SimData_tr_for_1ch_A

# DO NOT CHANGE THIS
export LD_LIBRARY_PATH=$KALDI_ROOT/tools/openfst-1.3.2/lib:$LD_LIBRARY_PATH
export PATH=$PWD/utils/:$KALDI_ROOT/src/bin:$KALDI_ROOT/tools/openfst/bin:$KALDI_ROOT/src/fstbin/:$KALDI_ROOT/src/gmmbin/:$KALDI_ROOT/src/featbin/:$KALDI_ROOT/src/lm/:$KALDI_ROOT/src/sgmmbin/:$KALDI_ROOT/src/sgmm2bin/:$KALDI_ROOT/src/fgmmbin/:$KALDI_ROOT/src/latbin/:$KALDI_ROOT/src/nnetbin:$KALDI_ROOT/src/nnet-cpubin/:$KALDI_ROOT/src/kwsbin:$PWD:$PATH
export LC_ALL=C

