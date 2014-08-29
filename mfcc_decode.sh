#!/bin/bash

. check.sh

export FEAT_TYPE=mfcc

(
    export DT_MDL="gmm gmm_sat gmm_lda gmm_lda_sat gmm_mc gmm_sat_mc gmm_lda_mc gmm_lda_sat_mc"
    export REG="PhoneSel"
    utils/call.sh \
        local/DecodeDTs.sh normal fmllr
)

(
    export DT_MDL="gmm_sat gmm_sat_mc gmm_lda_sat gmm_lda_sat_mc"
    export REG="dt"
    utils/call.sh \
        local/DecodeDTs.sh normal 
)

(
    export REG="dt"
    export DT_MDL="gmm gmm_sat gmm_lda gmm_lda_sat gmm_mc gmm_sat_mc gmm_lda_mc gmm_lda_sat_mc"
    utils/call.sh \
        local/WerDTs.sh
)

