#!/bin/bash

. check.sh

export FEAT_TYPE=mfcc
export DT_MDL="nnet2_gmm nnet2_gmm_mc "
export REG="dt"

(
    utils/call.sh \
        local/DecodeDTs.sh normal 
)

(
    utils/call.sh \
        local/WerDTs.sh
)

