#!/bin/bash

. check.sh

export FEAT_TYPE=mfcc
# export DT_MDL_GMM="gmm gmm_sat gmm_lda gmm_lda_sat gmm_mc gmm_sat_mc gmm_lda_mc gmm_lda_sat_mc" 
# export DT_MDL_GMM="gmm_lda_mc"
export DT_MDL_GMM="gmm gmm_lda  gmm_mc  gmm_lda_mc" # 
# export DT_MDL_DNN="nnet2 nnet2_sat nnet2_lda nnet2_lda_sat nnet2_mc nnet2_sat_mc nnet2_lda_mc nnet2_lda_sat_mc"
export DT_MDL_DNN="nnet2  nnet2_lda  nnet2_mc  nnet2_lda_mc" 
all=true
dnn=false
gmm=false

$all && (
    export REG="dt"
    export DT_MDL="${DT_MDL_GMM} ${DT_MDL_DNN}"
    utils/call.sh \
        local/WerDTs.sh
    echo Test Results of ALL     
)

$gmm && (
    export REG="dt"
    export DT_MDL="${DT_MDL_GMM}"
    utils/call.sh \
        local/WerDTs.sh
    echo Test Results of GMM 
)

$dnn && (
    export REG="dt"
    export DT_MDL="${DT_MDL_DNN}"
    utils/call.sh \
        local/WerDTs.sh
    echo Test Results of DNN     
)
