#!/bin/bash

. check.sh

#prepare the basic system and basic mfcc features
# utils/call.sh \
#     local/prepare_base.sh\
#     local/extract_dt.sh

#train the Acoustic Models 
export TR_MDL="mono tri1 gmm gmm_lda gmm_sat"
for feat in  mfcc ; do
    export FEAT_TYPE=$feat
    utils/call.sh \
        local/TrainAMs.sh
done

