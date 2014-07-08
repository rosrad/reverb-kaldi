#!/bin/bash

# Copyright 2013-2014 MERL (author: Felix Weninger)

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# THIS CODE IS PROVIDED *AS IS* BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, EITHER EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION ANY IMPLIED
# WARRANTIES OR CONDITIONS OF TITLE, FITNESS FOR A PARTICULAR PURPOSE,
# MERCHANTABLITY OR NON-INFRINGEMENT.
# See the Apache 2 License for the specific language governing permissions and
# limitations under the License.


if [ ! -e path.sh ] || [ ! -e corpus.sh ]; then
    echo "ERROR: path.sh and/or corpus.sh not found"
    echo "You need to create these from {path,corpus}.sh.default to match your system"
    echo "Make sure you follow the instructions in README.txt"
    exit 1
fi

. ./cmd.sh 

. ./corpus.sh

# LDA context size (left/right) (4 is default)
context_size=4
decode_nj=8
train_nj=16


# The language models with which to decode (tg_5k or bg_5k or "tg_5k bg_5k" for
# both)
lms="bg_5k tg_5k"

# number of jobs for feature extraction and model training
nj_train=10

# number of jobs for decoding
# use less jobs for trigram model
# if you have enough RAM (~ 32 GB), you can use 8 jobs for trigram as well
nj_bg=8
nj_tg=4

# set to true if running from scratch
do_prep=false

# set to true if you want the tri2a systems (re-implementation of the HTK baselines)
do_tri2a=false


# The following are the settings determined by Gaussian Process optimization.
# However, they are not used in the final system.
# You can use the code below for training the "tri2c_mc" system.

# LDA parameters for MCT recognizer.
# Use significantly more context than the default (7 frames ~ 85 ms)
mct_lda_left_context=7
mct_lda_right_context=5

# Number of states and Gaussians for the MCT recognizer.
mct_nstates=7500
mct_ngauss=45000

## End of GP tuned settings


if $do_prep; then

    # Prepare clean data and language model.
    local/wsj0cam_data_prep.sh $wsj0cam $reverb_lm || exit 1

    # Prepare merged BEEP/CMU dictionary.
    local/wsj_prepare_beep_dict.sh || exit 1;

    # Prepare wordlists, etc.
    utils/prepare_lang.sh data/local/dict "<SPOKEN_NOISE>" data/local/lang_tmp data/lang || exit 1;

    # Prepare directory structure for clean data. Apply some language model fixes.
    # make new lm_lang model for < bg and  tg > 
    local/wsjcam0_format_data.sh || exit 1;

    # Now it's getting more interesting.
    # Prepare the multi-condition training data and the REVERB dt set.
    # This also extracts MFCC features.
    # This creates the data sets called REVERB_tr_cut and REVERB_dt.
    # If you have processed waveforms, this is a good starting point to integrate them.
    # For example, you could have something like
    # local/REVERB_wsjcam0_data_prep.sh /path/to/processed/REVERB_WSJCAM0_dt processed_REVERB_dt dt
    # The first argument is supposed to point to a folder that has the same structure
    # as the REVERB corpus.
    local/REVERB_wsjcam0_data_prep.sh $reverb_tr REVERB_tr_cut tr || exit 1;
    local/REVERB_wsjcam0_data_prep.sh $reverb_dt REVERB_dt dt     || exit 1;
    # local/REVERB_wsjcam0_data_prep.sh $reverb_et REVERB_et et     || exit 1;

    # Prepare the REVERB "real" dt set from MCWSJAV corpus.
    # This corpus is *never* used for training.
    # This creates the data set called REVERB_Real_dt and its subfolders
    # local/REVERB_mcwsjav_data_prep.sh $reverb_real_dt REVERB_Real_dt dt || exit 1;
    # The MLF file exists only once in the corpus, namely in the real_dt directory
    # so we pass it as 4th argument
    # local/REVERB_mcwsjav_data_prep.sh $reverb_real_et REVERB_Real_et et $reverb_real_dt/mlf/WSJ.mlf || exit 1;


    # Extract MFCC features for clean sets.
    # For the non-clean data sets, this is outsourced to the data preparation scripts.
    mfccdir=mfcc
    for x in si_tr si_dt; do
        steps/make_mfcc.sh --nj $nj_train \
            data/$x exp/make_mfcc/$x $mfccdir || exit 1;
        steps/compute_cmvn_stats.sh data/$x exp/make_mfcc/$x $mfccdir || exit 1;
    done

fi
echo "===================All Data Prepared!=============================="

# Train monophone model on clean data (si_tr).
if [ ! -e exp/mono0a/final.mdl ]; then
    echo "### TRAIN mono0a ###"
    steps/train_mono.sh --boost-silence 1.25 --nj $nj_train \
        data/si_tr data/lang exp/mono0a || exit 1;
fi

# Align monophones with clean data.
if [ ! -e exp/mono0a_ali/ali.1.gz ]; then
    echo "### ALIGN mono0a_ali ###"
    steps/align_si.sh --boost-silence 1.25 --nj $nj_train \
        data/si_tr data/lang exp/mono0a exp/mono0a_ali || exit 1;
fi

# Create first triphone recognizer.
if [ ! -e exp/tri1/final.mdl ]; then
    echo "### TRAIN tri1 ###"
    steps/train_deltas.sh --boost-silence 1.25 \
        2000 10000 data/si_tr data/lang exp/mono0a_ali exp/tri1 || exit 1;
fi

#exit


# Prepare first triphone recognizer and decode clean si_dt for verification.
#utils/mkgraph.sh data/lang_test_bg_5k exp/tri1 exp/tri1/graph_bg_5k || exit 1;
#steps/decode.sh --nj 8 exp/tri1/graph_bg_5k data/si_dt exp/tri1/decode_si_dt

if [ ! -e exp/tri1_ali/ali.1.gz ]; then
    echo "### ALIGN tri1_ali ###"
    # Re-align triphones.
    steps/align_si.sh --nj $nj_train \
        data/si_tr data/lang exp/tri1 exp/tri1_ali || exit 1;
fi


# The following code trains and evaluates a delta feature recognizer, which is similar to the HTK
# baseline (but using per-utterance basis fMLLR instead of batch MLLR). This is for reference only.
if $do_tri2a; then
    echo "==================Do Tri2a System!=============================="
    # Train tri2a, which is deltas + delta-deltas, on clean data.
    steps/train_deltas.sh \
        2500 15000 data/si_tr data/lang exp/tri1_ali exp/tri2a || exit 1;

    # Re-align triphones using clean data. This gives a smallish performance gain.
    steps/align_si.sh --nj $nj_train \
        data/si_tr data/lang exp/tri2a exp/tri2a_ali || exit 1;

    # Train a multi-condition triphone recognizer.
    # This uses alignments on *clean* data, which is allowed for REVERB.
    # However, we have to use the "cut" version so that the length of the 
    # waveforms match.
    # It is actually asserted by the Challenge that clean and multi-condition waves are aligned.
    steps/train_deltas.sh \
        2500 15000 data/REVERB_tr_cut/SimData_tr_for_1ch_A data/lang exp/tri2a_ali exp/tri2a_mc || exit 1;

    # Prepare clean and mc tri2a models for decoding.
    utils/mkgraph.sh data/lang_test_bg_5k exp/tri2a exp/tri2a/graph_bg_5k
    utils/mkgraph.sh data/lang_test_bg_5k exp/tri2a_mc exp/tri2a_mc/graph_bg_5k

    # decode REVERB dt using tri2a, clean
    for dataset in data/REVERB_dt/SimData_dt* data/REVERB_Real_dt/RealData_dt*; do
        steps/decode.sh --nj $nj_bg \
            exp/tri2a/graph_bg_5k $dataset exp/tri2a/decode_bg_5k_REVERB_dt_`basename $dataset` || exit 1;
    done

    # decode REVERB dt using tri2a, mc
    for dataset in data/REVERB_dt/SimData_dt* data/REVERB_Real_dt/RealData_dt*; do
        steps/decode.sh --nj $nj_bg \
            exp/tri2a_mc/graph_bg_5k $dataset exp/tri2a_mc/decode_bg_5k_REVERB_dt_`basename $dataset` || exit 1;
    done

    # basis fMLLR for tri2a_mc system
    # This computes a transform for every training utterance and computes a basis from that.
    steps/get_fmllr_basis.sh --per-utt true data/REVERB_tr_cut/SimData_tr_for_1ch_A data/lang exp/tri2a_mc || exit 1;

    # Recognition using fMLLR adaptation (per-utterance processing).
    for dataset in data/REVERB_dt/SimData_dt* data/REVERB_Real_dt/RealData_dt*; do
        steps/decode_basis_fmllr.sh --nj $nj_bg \
            exp/tri2a_mc/graph_bg_5k $dataset exp/tri2a_mc/decode_basis_fmllr_bg_5k_REVERB_dt_`basename $dataset` || exit 1;
    done


    exit

fi # train tri2a, tri2a_mc

echo ============================================================================
echo "                    DNN Hybrid Training & Decoding                        "
echo ============================================================================

# DNN hybrid system training parameters
dnn_mem_reqs="mem_free=1.0G,ram_free=0.2G"
dnn_extra_opts="--num_epochs 20 --num-epochs-extra 10 --add-layers-period 1 --shrink-interval 3"

# steps/nnet2/train_tanh.sh --mix-up 5000 --initial-learning-rate 0.015 \
#     --final-learning-rate 0.002 --num-hidden-layers 2  \
#     --num-jobs-nnet "$train_nj" "${dnn_train_extra_opts[@]}" \
#     data/si_tr data/lang exp/tri2a_ali exp/tri3a_nnet

# decode REVERB dt using tri2a, clean
decode_extra_opts=(--num-threads 6 --parallel-opts "-pe smp 6 -l mem_free=4G,ram_free=0.7G")
for dataset in data/REVERB_dt/SimData_dt*; do
    decode_dir="exp/tri3a_nnet/decode_dev/decode_bg_5k_REVERB_dt_$(basename ${dataset})"
    [ ! -d ${decode_dir} ] && mkdir -p ${decode_dir}
    steps/nnet2/decode.sh --nj "$decode_nj" "${decode_extra_opts[@]}" \
        exp/tri2a/graph_bg_5k $dataset $decode_dir \
        | tee ${decode_dir}/decode.log
done
echo ============================================================================
echo "                    Getting Results [see RESULTS file]                    "
echo ============================================================================

# for x in exp/*/decode*; do
#     [ -d $x ] && grep WER $x/wer_* | utils/best_wer.sh
# done 

echo ============================================================================
echo "Finished successfully on" `date`
echo ============================================================================

exit 0






