#!/bin/bash

# for extract the bottleneck features from the reverb-challenge corpus
. ./util.sh
base=${2:-"tri1"}
condition=${1:-"mc"}


align_dir="exp/${base}_ali"
train_dir="data/REVERB_tr_cut/SimData_tr_for_1ch_A"
test_dir="data/si_dt"

bnf_train_stage=-100
exp_bnf="exp_bnf/${base}_${condition}_bnf"

if [ ! -f ${exp_bnf}/.done ]; then
    mkdir -p ${exp_bnf}
    echo ---------------------------------------------------------------------
    echo "Starting training the bottleneck network"
    echo ---------------------------------------------------------------------
    steps/nnet2/train_tanh_bottleneck.sh \
        --stage $bnf_train_stage --num-jobs-nnet 4 \
        --num-threads 1 --mix-up 5000 --max-change 40 \
        --minibatch-size 512 \
        --initial-learning-rate 0.005 \
        --final-learning-rate 0.0005 \
        --num-hidden-layers 5 \
        --bottleneck-dim 42 --hidden-layer-dim 1024 \
        ${train_dir} data/lang $align_dir $exp_bnf || exit 1 
    touch ${exp_bnf}/.done
fi

echo "====================Dump bottleneck features ========================="
# dump bottleneck feature for train data
[ ! -d param_bnf ] && mkdir -p param_bnf
if [ ! -f data_bnf/train_bnf/.done ]; then
    mkdir -p data_bnf
    # put the archives in param_bnf/.
    steps/nnet2/dump_bottleneck_features.sh --nj 8\
        ${train_dir} data_bnf/train_bnf ${exp_bnf} param_bnf exp_bnf/dump_bnf
    touch data_bnf/train_bnf/.done
fi 

# dump bottleneck feature for test data
for dataset in data/REVERB_dt/${dtype}_dt_for*; do
    steps/nnet2/dump_bottleneck_features.sh --nj 8 \
        ${dataset} data_bnf/$(basename ${dataset})_bnf $exp_bnf param_bnf exp_bnf/dump_bnf
done









