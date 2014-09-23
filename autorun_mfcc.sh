#!/bin/bash

. check.sh

# export TR_MDL="gmm gmm_lda gmm_mc gmm_lda_mc gmm_sat gmm_lda_sat gmm_sat_mc gmm_lda_sat_mc nnet2 nnet2_mc nnet2_lda nnet2_lda_mc "
export TR_MDL="gmm_fmllr_raw_mc gmm_fmllr_lda_raw_mc" 
export DT_MDL=${TR_MDL}
export TRANSFORM_PAIRS_DNN="nnet2_fmllr_mc-gmm_mc nnet2_lda-gmm_lda nnet2_lda_mc-gmm_lda_mc "
export TRANSFORM_PAIRS="${TRANSFORM_PAIRS_DNN}"
export REG="Fmllr.*raw.*dt"


for feat in bnf; do
    export FEAT_TYPE=$feat
    # utils/call.sh \
    #     local/TrainAMs.sh
    utils/call.sh \
        local/DecodeDTs.sh normal
    utils/call.sh \
        local/WerDTs.sh
done

