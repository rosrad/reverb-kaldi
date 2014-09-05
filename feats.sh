#!/bin/bash

export FEAT_TYPE=mfcc
. check.sh

# STEP 1 prepare the basic transptions and
# relation between skp and utterance (very important! )
# Just run once !

# utils/call.sh \
#     local/prepare_base.sh


# STEP 2 extract mfcc features 
export DT="REVERB_tr_cut REVERB_dt PHONE_dt PHONE_SEL_dt " 
# export DT="si_tr si_dt"
for f in bnf_cln ;do
    utils/call.sh \
        local/ExtractFeats.sh  $f
done


# STEP 3 used to  select the most efficient microphone audio  
# autoselect/sel_mlld.sh


