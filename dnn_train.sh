#!/bin/bash
. ./util.sh
base=${2:-"tri1"}
# this is the condition of the trainning data 
# can be ether "cln"or "mc"
condition=${1:-"mc"}
#dnn used
dnn="net2"
model_dst=$(dnn_model ${condition} ${base})
echo "================== Train DNN ======================= "
echo "CONDTION: ${condition}"
echo "BASE_FEATURE: ${base}"
echo "MODEL DEST: ${model_dst} "

train_nj=16
train_set="data/REVERB_tr_cut/SimData_tr_for_1ch_A"
align_set="exp/${base}_ali"
if [ ${condition} == "cln" ]; then  # using reverb train data
    train_set="data/si_tr"
fi
echo "Train Set : ${train_set}"
dnn_extra_opts="--num_epochs 20 --num-epochs-extra 10 --add-layers-period 1 --shrink-interval 3"
# steps/nnet2/train_tanh.sh --mix-up 5000 --initial-learning-rate 0.015 \
#     --final-learning-rate 0.002 --num-hidden-layers 2  \
#     --num-jobs-nnet "$train_nj" "${dnn_train_extra_opts[@]}" \
#      ${train_set} data/lang ${align_set} exp/${model_dst}

echo "CONDTION: ${condition}"
echo "BASE_FEATURE: ${base}"
echo "MODEL DEST: ${model_dst} "
echo "================== End Train DNN ======================= "
