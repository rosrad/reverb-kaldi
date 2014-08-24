#!/bin/bash

. check.sh
# # Prepare clean data and language model.
# local/wsj0cam_data_prep.sh $wsj0cam $reverb_lm || exit 1

# # Prepare merged BEEP/CMU dictionary.
# local/wsj_prepare_beep_dict.sh || exit 1;

# Prepare wordlists, etc.
utils/prepare_lang.sh ${DATA}/local/dict "<SPOKEN_NOISE>" ${DATA}/local/lang_tmp ${DATA}/lang || exit 1;

# Prepare directory structure for clean data. Apply some language model fixes.
# make new lm_lang model for < bg and  tg > 
local/wsjcam0_format_data.sh || exit 1;

#extract the basic clean train and development data set
mfccdir=${WORKSPACE}/mfcc
for x in si_tr si_dt; do
    steps/make_mfcc.sh --nj $nj_train \
        ${DATA}/$x ${EXP}/make_mfcc/$x $mfccdir || exit 1;
    steps/compute_cmvn_stats.sh ${DATA}/$x ${EXP}/make_mfcc/$x $mfccdir || exit 1;
done