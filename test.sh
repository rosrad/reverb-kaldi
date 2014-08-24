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
# export TR_MDL="bnf_tri1_mc"
# utils/call.sh \
#     local/TrainAMs.sh
# export FEAT_TYPE=bnf
# export DT="REVERB_tr_cut REVERB_dt"
# utils/call.sh \
#     local/ExtractFeats.sh



# for Decode and get results of the Development Set
# nnet2_tri1 nnet2_tri1_mc nnet2_tri2 nnet2_tri2_mc tri1 tri2 tri2_mc"
# nnet2_tri1_mc nnet2_tri2 nnet2_tri2_mc tri1 tri2 tri2_mc"
# function feat_data() {
#     fmllr
# }

# export FEAT_DATA=${MFCC_FMLLR}/tri1_mc_/data
# export FEAT_TYPE=mfcc
# export DT_MDL="nnet2_tri2 nnet2_tri2_mc"
# # export DT_MDL="tri2 tri2_mc nnet2_tri2 nnet2_tri2_mc"
# # export DT_MDL="tri1 tri2 tri1_mc tri2_mc"
# # export DT_MDL="tri1_mc"
# export REG=".*Sim.*dt.*"
# # export TESTONLY=true
# utils/call.sh \
#     local/TestDTs.sh    --fmllr tri2_mc

export TR_MDL="nnet2_lda_mllt_tri2"
export DT_MDL=${TR_MDL}
#     utils/call.sh \
#         local/TrainAMs.sh
# decode all development sets



for feat in  mfcc ; do
    export FEAT_TYPE=$feat
    export REG=".*dt.*"
    # export TESTONLY=true
    for fmllr in "" "true"; do
        if [[ -z $fmllr ]];then
            utils/call.sh \
                local/TestDTs.sh
        else
            utils/call.sh \
                local/TestDTs.sh --fmllr lda_mllt_tri2_mc
        fi
    done
done
# export FEAT_TYPE=mfcc
# # export TESTONLY=true
# utils/call.sh \
#     local/TestDTs.sh --fmllr lda_mllt_tri2_mc







