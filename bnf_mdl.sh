#!/bin/bash

. check.sh


export TR_MDL="bnf_mc"
export DT_MDL=${TR_MDL}
export REG=""

for feat in mfcc; do
    export FEAT_TYPE=$feat
    utils/call.sh --tag bnf_mdl \
        local/TrainAMs.sh
done

export DT="REVERB_tr_cut REVERB_dt PHONE_dt PHONE_SEL_dt si_tr"
utils/call.sh \
    local/ExtractFeats.sh  bnf
