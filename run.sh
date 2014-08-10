#!/bin/bash

. check.sh

#prepare the basic system and basic mfcc features
# utils/call.sh \
#     local/prepare_base.sh\
#     local/extract_dt.sh

#train the Acoustic Models and Decode the development set
utils/call.sh \
    local/TrainAMs.sh\
    local/TestDTs.sh
