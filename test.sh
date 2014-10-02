#!/bin/bash

. check.sh

export FEAT_TYPE=mfcc
# export DT_MDL_GMM="gmm gmm_sat gmm_lda gmm_lda_sat gmm_mc gmm_sat_mc gmm_lda_mc gmm_lda_sat_mc" 
# export DT_MDL_GMM="gmm_lda_mc"
#
# export DT_MDL_GMM="plda_raw_mc plda_fmllr_raw_mc plda_lda_raw_mc plda_fmllr_lda_raw_mc" #
# export DT_MDL_PLDA="plda_raw_mc plda_fmllr_raw_mc plda_lda_raw_mc plda_fmllr_lda_raw_mc" # 
# export DT_MDL_PLDA="plda_mc plda_fmllr_mc plda_lda_mc plda_fmllr_lda_mc" #
# export DT_MDL_PLDA_RAW="plda_raw_mc plda_fmllr_raw_mc plda_lda_raw_mc plda_fmllr_lda_raw_mc" # 
# export DT_MDL_GMM="gmm_mc gmm_lda_mc gmm_fmllr_lda_mc" # 
# export DT_MDL_GMM_RAW="gmm_raw_mc gmm_lda_raw_mc gmm_fmllr_lda_raw_mc" # 
# export DT_MDL_DNN="nnet2 nnet2_sat nnet2_lda nnet2_lda_sat nnet2_mc nnet2_sat_mc nnet2_lda_mc nnet2_lda_sat_mc"
# export DT_MDL_DNN="nnet2_mc nnet2_fmllr_mc nnet2_lda_mc nnet2_fmllr_lda_mc" #
export DT_MDL_DNN5="nnet2_layer5_mc nnet2_fmllr_layer5_mc nnet2_layer5_lda_mc nnet2_fmllr_layer5_lda_mc"
# export DT_MDL_DNN5="nnet2_fmllr_layer5_lda_mc"
# export DT_MDL_DNN5_RAW="nnet2_layer5_raw_mc nnet2_fmllr_layer5_raw_mc nnet2_layer5_lda_raw_mc nnet2_fmllr_layer5_lda_raw_mc" #
export REG="(?!Global).*dt.*"

dnn=1
gmm=1
plda=1

all=0
[[ $all != 0 ]] && (
    export DT_MDL="${DT_MDL_GMM} ${DT_MDL_PLDA} ${DT_MDL_DNN}"
    utils/call.sh \
        local/WerDTs.sh
    echo Test Results of ALL     
)

[[ $plda != 0 ]] && (
    export DT_MDL="${DT_MDL_PLDA} ${DT_MDL_PLDA_RAW}"
    utils/call.sh \
        local/WerDTs.sh
    echo Test Results of ALL     
)


[[ $gmm != 0 ]] && (
    export DT_MDL="${DT_MDL_GMM} ${DT_MDL_GMM_RAW}"
    utils/call.sh \
        local/WerDTs.sh
    echo Test Results of GMM 
)

[[ $dnn != 0 ]] && (
    export DT_MDL="${DT_MDL_DNN5_RAW} ${DT_MDL_DNN5} ${DT_MDL_DNN}"
    utils/call.sh \
        local/WerDTs.sh
    echo Test Results of DNN     
)
