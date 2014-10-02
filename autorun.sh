#!/bin/bash

. check.sh


# export TR_MDL="gmm_lda_mc  gmm_sat_mc gmm_lda_sat_mc nnet2_mc nnet2_lda_mc nnet2_sat_mc nnet2_lda_sat_mc"
export TR_MDL="nnet2_layer5_lda_raw_mc"
export DT_MDL=${TR_MDL}
export REG="^(?!Global|Fmllr).*dt.*"

for feat in mfcc ; do
    export FEAT_TYPE=$feat
    utils/call.sh \
        local/TrainAMs.sh
    utils/call.sh --tag nnet \
        local/DecodeDTs.sh normal
    utils/call.sh \
        local/WerDTs.sh
done


