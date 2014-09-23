#!/bin/bash

. check.sh

export TR_MDL="plda_fmllr_lda_raw_mc" # 
export DT_MDL=${TR_MDL}
export REG="Fmllr.*raw.*dt.*"

for feat in bnf; do
    export FEAT_TYPE=$feat
    # utils/call.sh \
    #     local/TrainAMs.sh
    utils/call.sh --tag plda  \              
        local/DecodeDTs.sh normal
    utils/call.sh \
        local/WerDTs.sh
done

