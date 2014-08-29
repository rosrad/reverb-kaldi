#!/bin/bash

. check.sh


export TR_MDL="nnet2 nnet2_mc nnet2_lda nnet2_lda_mc"
export DT_MDL=${TR_MDL}
export REG="dt"

for feat in  mfcc ; do
    export FEAT_TYPE=$feat
    utils/call.sh \
        local/TrainAMs.sh
    # decode all development sets
    utils/call.sh \
        local/DecodeDTs.sh normal

    utils/call.sh \
        local/WerDTs.sh
done

