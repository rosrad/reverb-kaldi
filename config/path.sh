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

#feature
export FEATS=${WORKSPACE}/feats
#for bottelneck feature
# TODO should not use the var below
export BNF=${FEATS}/bnf
export BNF_EXP=${BNF}/exp
export BNF_EXTRACT_EXP=${BNF}/exp
export BNF_DATA=${BNF}/data
export BNF_DUMP=${BNF_EXP}/dump
export BNF_PARAM=${BNF}/param


feature_set=(mfcc bnf)

for feat in ${feature_set[*]}; do
    FEAT=${feat^^}              # upper the feature name
    export ${FEAT}_EXP="${WORKSPACE}/exp/${feat}"
    export ${FEAT}_DATA="${FEATS}/${feat}/data"
    export ${FEAT}_FEAT="${FEATS}/${feat}"
    export ${FEAT}_LOG="${WORKSPACE}/log/${feat}"
    # the var is used for the feature type than need to train some model to extract 
    # for example bottleneck feature
    export ${FEAT}_MDL_EXP="${FEATS}/${feat}/exp"
    export ${FEAT}_MDL_PARAM="${FEATS}/${feat}/param"
    export ${FEAT}_MDL_DUMP="${FEATS}/${feat}/exp/dump"
done
# for development set

# used for create the feature relatived variables
feat_data_var=${FEAT_TYPE^^}_DATA
export FEAT_DATA=${!feat_data_var}

export DT_DATA=${FEAT_DATA}
export TR_CLN=${FEAT_DATA}/si_tr
export TR_MC=${FEAT_DATA}/REVERB_tr_cut/SimData_tr_for_1ch_A
# used for create feature relative exp variables
feat_exp_var=${FEAT_TYPE^^}_EXP
export FEAT_EXP=${!feat_exp_var}

# for the feature-type based log 
feat_log_var=${FEAT_TYPE^^}_LOG
export FEAT_LOG=${!feat_log_var}

# DO NOT CHANGE THIS
export LD_LIBRARY_PATH=$KALDI_ROOT/tools/openfst-1.3.2/lib:$LD_LIBRARY_PATH
export PATH=$PWD/utils/:$KALDI_ROOT/src/bin:$KALDI_ROOT/tools/openfst/bin:$KALDI_ROOT/src/fstbin/:$KALDI_ROOT/src/gmmbin/:$KALDI_ROOT/src/featbin/:$KALDI_ROOT/src/lm/:$KALDI_ROOT/src/sgmmbin/:$KALDI_ROOT/src/sgmm2bin/:$KALDI_ROOT/src/fgmmbin/:$KALDI_ROOT/src/latbin/:$KALDI_ROOT/src/nnetbin:$KALDI_ROOT/src/nnet-cpubin/:$KALDI_ROOT/src/kwsbin:$PWD:$PATH
export LC_ALL=C


