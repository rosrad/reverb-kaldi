#!/bin/bash

. check.sh
# nnet2_fmllr_layer5_mc
export TR_MDL="nnet2_fmllr_layer5_lda_mc nnet2_fmllr_layer5_raw_mc nnet2_fmllr_layer5_lda_raw_mc"
export DT_MDL=${TR_MDL}
export REG="^Fmllr_.*dt.*"

for feat in mfcc; do
    export FEAT_TYPE=$feat
    utils/call.sh \
        local/TrainAMs.sh
    # utils/call.sh --tag plda  \              
    #     local/DecodeDTs.sh normal
    # utils/call.sh \
    #     local/WerDTs.sh
done

