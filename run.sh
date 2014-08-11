#!/bin/bash

. check.sh

#prepare the basic system and basic mfcc features
# utils/call.sh \
#     local/prepare_base.sh\
#     local/extract_dt.sh

#train the Acoustic Models and Decode the development set
# FEAT_TYPE=mfcc


# DT=(REVERB_tr_cut REVERB_dt PHONE_dt PHONE_SEL_dt)
# nnet2_tri1 nnet2_tri1_mc nnet2_tri2 nnet2_tri2_mc
# nnet2_tri1_mc nnet2_tri2 nnet2_tri2_mc

# TR_MDL=(nnet2_tri1 nnet2_tri1_mc nnet2_tri2 nnet2_tri2_mc)


# for train Acoustic models and extract features
# feature type and development set planed to extract

# train models
export TR_MDL="bnf_tri1_mc"
utils/call.sh \
    local/TrainAMs.sh
export FEAT_TYPE=bnf
export DT="REVERB_tr_cut REVERB_dt"
utils/call.sh \
    local/ExtractFeats.sh



# for Decode and get results of the Development Set
DT_MDL="tri1"
# utils/call.sh \
# local/TestDTs.sh
