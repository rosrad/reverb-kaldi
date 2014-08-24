#!/bin/bash

. check.sh

#prepare the basic system and basic mfcc features
# utils/call.sh \
#     local/prepare_base.sh\
#     local/extract_dt.sh

#train the Acoustic Models 

#train the Acoustic Models using the feature of FEAT_TYPE=mfcc

# TR_MDL=( mono0a tri1 tri2 tri2_mc tri2_lda_mllt tri2_lda_mllt_mc)
# TR_MDL=( nnet2_tri1 nnet2_tri1_mc nnet2_tri2 nnet2_tri2_mc )
# TR_MDL=( bnf_tri1_mc ) 

# export TR_MDL="mono0a tri1 tri2 tri2_mc"


# Train Bottleneck DNN model
# export FEAT_TYPE=mfcc
# export TR_MDL="bnf_tri1 bnf_tri2 bnf_tri2_mc"
# utils/call.sh \
#     local/TrainAMs.sh

# train DNN model using the bottleneck features

# export TR_MDL="lda_mllt_tri2 lda_mllt_tri2_mc"

# export TR_MDL="nnet2_lda_mllt_tri2 nnet2_lda_mllt_tri2_mc nnet2_fmllr_lda_mllt_tri2 nnet2_fmllr_lda_mllt_tri2_mc"
export TR_MDL="lda_mllt_tri2 lda_mllt_tri2_mc"
for feat in  bnf ; do
    export FEAT_TYPE=$feat
    utils/call.sh \
        local/TrainAMs.sh
done

