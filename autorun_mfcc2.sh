#!/bin/bash

. check.sh

# export TR_MDL="gmm gmm_lda gmm_mc gmm_lda_mc gmm_sat gmm_lda_sat gmm_sat_mc gmm_lda_sat_mc nnet2 nnet2_mc nnet2_lda nnet2_lda_mc "
# export TR_MDL="ubm_fmllr_lda_mc plda_fmllr_lda_mc"
export TR_MDL="gmm_raw_mc" 
export DT_MDL=" ${TR_MDL}"
export REG="Fmllr.*dt.*"


for feat in mfcc; do
    export FEAT_TYPE=$feat
    # utils/call.sh \
    #     local/TrainAMs.sh
    utils/call.sh \
        local/DecodeDTs.sh fmllr
    utils/call.sh \
        local/WerDTs.sh
done

