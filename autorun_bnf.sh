#!/bin/bash

. check.sh

export TR_MDL="gmm_mc gmm_lda_mc nnet2_mc nnet2_lda_mc" # 
export DT_MDL=${TR_MDL}
export TRANSFORM_PAIRS_DNN="nnet2-gmm nnet2_mc-gmm_mc nnet2_lda-gmm_lda nnet2_lda_mc-gmm_lda_mc "
export TRANSFORM_PAIRS="${TRANSFORM_PAIRS_DNN}"
export REG="^(?!Global).*dt.*"

for feat in bnf; do
    export FEAT_TYPE=$feat
    utils/call.sh \
        local/TrainAMs.sh
    utils/call.sh  \              
        local/DecodeDTs.sh  fmllr normal
    utils/call.sh \
        local/WerDTs.sh
done

