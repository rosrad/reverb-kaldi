#!/bin/bash

. check.sh

#prepare the basic system and basic mfcc features
# utils/call.sh \
#     local/prepare_base.sh\
#     local/extract_dt.sh

#train the Acoustic Models 
export FEAT_TYPE=bnf
#train the Acoustic Models using the feature of FEAT_TYPE=mfcc

# TR_MDL=( mono0a tri1 tri2 tri2_mc tri2_lda_mllt tri2_lda_mllt_mc)
# TR_MDL=( nnet2_tri1 nnet2_tri1_mc nnet2_tri2 nnet2_tri2_mc )
# TR_MDL=( bnf_tri1_mc ) 

# export TR_MDL="mono0a tri1 tri2 tri2_mc"
export TR_MDL="tri2 tri2_mc"
utils/call.sh \
    local/TrainAMs.sh
