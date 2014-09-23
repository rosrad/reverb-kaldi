#!/bin/bash

. check.sh

export FEAT_TYPE=bnf
# export DT_MDL_GMM="gmm gmm_sat gmm_lda gmm_lda_sat gmm_mc gmm_sat_mc gmm_lda_mc gmm_lda_sat_mc" 
# export DT_MDL_GMM="gmm_lda_mc"
#
# export DT_MDL_GMM="plda_raw_mc plda_fmllr_raw_mc plda_lda_raw_mc plda_fmllr_lda_raw_mc" #
export DT_MDL_PLDA="plda_raw_mc plda_fmllr_raw_mc plda_lda_raw_mc plda_fmllr_lda_raw_mc" # 
export DT_MDL_GMM="gmm_raw_mc gmm_lda_raw_mc gmm_fmllr_lda_raw_mc" # 
# export DT_MDL_DNN="nnet2 nnet2_sat nnet2_lda nnet2_lda_sat nnet2_mc nnet2_sat_mc nnet2_lda_mc nnet2_lda_sat_mc"
export DT_MDL_DNN="nnet2_raw_mc nnet2_fmllr_raw_mc nnet2_lda_raw_mc nnet2_fmllr_lda_raw_mc" # 
export REG=".*dt.*"

all=false
dnn=false
gmm=false
plda=true

$all && (
    export DT_MDL="${DT_MDL_GMM} ${DT_MDL_PLDA} ${DT_MDL_DNN}"
    utils/call.sh \
        local/WerDTs.sh
    echo Test Results of ALL     
)

$plda && (
    export DT_MDL="${DT_MDL_PLDA}"
    utils/call.sh \
        local/WerDTs.sh
    echo Test Results of ALL     
)


$gmm && (
    export DT_MDL="${DT_MDL_GMM}"
    utils/call.sh \
        local/WerDTs.sh
    echo Test Results of GMM 
)

$dnn && (
    export DT_MDL="${DT_MDL_DNN}"
    utils/call.sh \
        local/WerDTs.sh
    echo Test Results of DNN     
)
