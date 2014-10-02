#!/bin/bash

. check.sh

# export TR_MDL="gmm gmm_lda gmm_mc gmm_lda_mc gmm_sat gmm_lda_sat gmm_sat_mc gmm_lda_sat_mc nnet2 nnet2_mc nnet2_lda nnet2_lda_mc "
export TR_MDL="nnet2_fmllr_layer5_lda_mc " 
export DT_MDL=${TR_MDL}
export REG="^Fmllr.*dt"


for feat in mfcc; do
    export FEAT_TYPE=$feat
    utils/call.sh \
        local/TrainAMs.sh
    utils/call.sh \
        local/DecodeDTs.sh normal
    utils/call.sh \
        local/WerDTs.sh
done

