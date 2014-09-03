#!/bin/bash

. check.sh


export TR_MDL="gmm gmm_lda gmm_mc gmm_lda_mc gmm_sat gmm_lda_sat gmm_sat_mc gmm_lda_sat_mc nnet2 nnet2_mc nnet2_lda nnet2_lda_mc "
# export TR_MDL=" gmm_mc gmm_lda_mc gmm gmm_lda"
export DT_MDL=${TR_MDL}
export REG="PHONE.*MLLD"

for feat in mfcc bnf; do
    export FEAT_TYPE=$feat
    # utils/call.sh \
    #     local/TrainAMs.sh
    # decode all development sets
    utils/call.sh \
        local/DecodeDTs.sh fmllr normal
    utils/call.sh \
        local/WerDTs.sh
done

