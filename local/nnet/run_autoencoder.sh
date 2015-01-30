#!/bin/bash

# Train,

dir=ae-tmp/exp/ae_test
feat_dir=ae-tmp/feats/mfcc/
labels="ark:feat-to-post scp:$feat_dir/si_tr/feats.scp ark:- |"
# $cmd $dir/log/train_nnet.log \
dummy_dir=${dir}/dummy
steps/nnet/train.sh --hid-layers 2 --hid-dim 200 --learn-rate 0.00001 \
    --labels "$labels" --num-tgt 40 --train-tool "nnet-train-frmshuff --objective-function=mse" \
    --proto-opts "--no-softmax --activation-type=<Tanh> --hid-bias-mean=0.0 --hid-bias-range=1.0 --param-stddev-factor=0.01" \
    $feat_dir/tr_90 $feat_dir/cv_10 $dummy_dir $dummy_dir $dummy_dir $dir || exit 1;

# Forward the data,
out_dir=ae-tmp/exp/ae_test/REVERB_CLN_dt
steps/nnet/make_bn_feats.sh --nj 1 --cmd "$train_cmd" --remove-last-components 0 \
    $out_dir $feat_dir/REVERB_CLN_dt $dir $out_dir/{log,data} || exit 1
