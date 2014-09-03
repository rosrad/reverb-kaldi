#!/bin/bash

function alignment() {
    fmllr=
    . utils/parse_options.sh
    if [ $# -lt 1 ]; then
        echo "Error: no enough paramaters!"
        echo "Usage: alignment gmm"
        exit 1;
    fi
    mdl=$1
    tr_dir=$2
    dst_ali=${mdl}_ali
    ali_script="align_si.sh"
    if [[ -n $fmllr ]]; then
        ali_script="align_fmllr.sh"
        dst_ali=${mdl}_fmllr_ali
    fi        
    if [ ! -e ${dst_ali}/ali.1.gz ]; then
        steps/${ali_script} --nj $nj_decode ${@:3} \
            $tr_dir ${DATA}/lang ${mdl} ${dst_ali} || exit 1;
    fi
    echo ${dst_ali}
}

function mkgraph() {
    if [ $# -lt 1 ]; then
        Echo "Error: no enough paramaters!"
        echo "Usage: mkgraph gmm"
        exit 1;
    fi
    mdl=$1
    echo "### Make Graph of MDL ${mdl} "
    utils/mkgraph.sh ${@:2} ${DATA}/lang_test_bg_5k ${mdl} ${mdl}/graph_bg_5k
}

# Train monophone model on clean data (si_tr).
function mono(){
    mdl=${FEAT_EXP}/mono
    steps/train_mono.sh --boost-silence 1.25 --nj $nj_train \
        $TR_CLN ${DATA}/lang ${mdl} || exit 1;
    mkgraph  ${mdl} --mono
    alignment ${mdl} $TR_CLN --boost-silence 1.25
}

# Create first triphone recognizer.
function tri1_phone() {
    mdl=${FEAT_EXP}/tri1
    tr_dir=$TR_CLN
    ali=${FEAT_EXP}/mono_ali
    steps/train_deltas.sh --boost-silence 1.25 \
        2000 10000 $tr_dir ${DATA}/lang ${ali} ${mdl} || exit 1;
    mkgraph ${mdl}
    alignment ${mdl} $tr_dir
}

# The following code trains and evaluates a delta feature recognizer, which is similar to the HTK
# baseline (but using per-utterance basis fMLLR instead of batch MLLR). This is for reference only.

function gmm() {
    cond=
    . utils/parse_options.sh
    mdl=${FEAT_EXP}/gmm
    tr_dir=$TR_CLN
    ali=${FEAT_EXP}/tri1_ali
    if [ "$cond" == "mc" ]; then
        tr_dir=$TR_MC
        mdl=${mdl}_mc
    fi

    steps/train_deltas.sh \
        2500 15000 $tr_dir ${DATA}/lang $ali ${mdl} || exit 1;
    mkgraph  ${mdl}
}

function sat() {
    cond=
    fmllr=
    ali=gmm
    . utils/parse_options.sh
    mdl_dir=${FEAT_EXP}/$(opts2mdl ${ali} sat)
    ali_src=${FEAT_EXP}/${ali}
    tr_dir=$TR_CLN
    if [ "$cond" == "mc" ]; then
        tr_dir=$TR_MC
        mdl_dir=${mdl_dir}_mc
        ali_src=${FEAT_EXP}/$(opts2mdl ${ali} mc)
    fi
    alignment --fmllr "$fmllr" ${ali_src} ${tr_dir}
    ali_dir=$(alignment --fmllr "$fmllr" ${ali_src} ${tr_dir})
    steps/train_sat.sh \
        2500 15000 $tr_dir ${DATA}/lang ${ali_dir} ${mdl_dir} || exit 1;
    mkgraph ${mdl_dir}
}

function lda() {
    cond=
    ali=gmm
    . utils/parse_options.sh

    mdl_dir=${FEAT_EXP}/$(opts2mdl ${ali} lda)
    ali_src=${FEAT_EXP}/${ali}
    tr_dir=$TR_CLN
    if [ "$cond" == "mc" ]; then
        tr_dir=$TR_MC
        mdl_dir=${mdl_dir}_mc
        ali_src=${FEAT_EXP}/$(opts2mdl ${ali} mc)
    fi
    alignment ${ali_src} ${tr_dir}
    ali_dir=$(alignment ${ali_src} ${tr_dir})

    steps/train_lda_mllt.sh \
        --splice-opts "--left-context=$context_size --right-context=$context_size" \
        2500 15000 $tr_dir ${DATA}/lang ${ali_dir} ${mdl_dir} || exit 1;
    mkgraph  ${mdl_dir}
}

function nnet2() {
    cond=
    ali=gmm
    . utils/parse_options.sh
    mdl_dir=${FEAT_EXP}/$(ali2mdl nnet2 ${ali})
    ali_src=${FEAT_EXP}/${ali}
    tr_dir=$TR_CLN
    if [ "$cond" == "mc" ]; then
        tr_dir=$TR_MC
        mdl_dir=${mdl_dir}_mc
        ali_src=${FEAT_EXP}/$(opts2mdl ${ali} mc)
    fi
    alignment $ali_src $tr_dir
    ali_dir=$(alignment $ali_src $tr_dir)
    dnn_extra_opts="--num_epochs 20 --num-epochs-extra 10 --add-layers-period 1 --shrink-interval 3"
    steps/nnet2/train_tanh.sh --mix-up 5000 --initial-learning-rate 0.015 \
        --final-learning-rate 0.002 --num-hidden-layers 2  \
        --num-jobs-nnet "$nj_train" "${dnn_train_extra_opts[@]}" \
        ${tr_dir} ${DATA}/lang ${ali_dir} ${mdl_dir}
    mkgraph ${mdl_dir}
    # alignment $(basename ${mdl})
}

function bottleneck_dnn() {
    cond=
    ali=gmm
    stage=-100

    . utils/parse_options.sh
    mdl_dir=${BNF_MDL_EXP}/${ali}
    ali_src=${FEAT_EXP}/${ali} 
    tr_dir=$TR_CLN
    if [ "$cond" == "mc" ]; then
        mdl_dir=${BNF_MDL_EXP}/$(opts2mdl ${ali} mc)
        ali_src=${FEAT_EXP}/$(opts2mdl ${ali} mc) 
        tr_dir=$TR_MC
    fi

    alignment ${ali_src} ${tr_dir}
    ali_dir=$(alignment ${ali_src} ${tr_dir})

    [[ ! -e $BNF_MDL_EXP ]] && mkdir -p ${BNF_MDL_EXP}
    steps/nnet2/train_tanh_bottleneck.sh \
        --stage $stage --num-jobs-nnet 4 \
        --num-threads 1 --mix-up 5000 --max-change 40 \
        --minibatch-size 512 \
        --initial-learning-rate 0.005 \
        --final-learning-rate 0.0005 \
        --num-hidden-layers 5 \
        --bottleneck-dim 42 --hidden-layer-dim 1024 \
        ${tr_dir} ${DATA}/lang $ali_dir ${mdl_dir} || exit 1
}

function train () {
    declare -A MDL=( \
        [mono]="mono" \
        [tri1]="tri1_phone" \
        [gmm]="gmm" \
        [gmm_mc]="gmm --cond mc" \
        [gmm_sat]="sat --ali gmm " \
        [gmm_sat_mc]="sat --ali gmm --cond mc" \
        [gmm_lda]="lda --ali gmm" \
        [gmm_lda_mc]="lda --cond mc --ali gmm" \
        [gmm_lda_sat]="sat --ali gmm_lda --fmllr ture" \
        [gmm_lda_sat_mc]="sat --ali gmm_lda --cond mc --fmllr ture " \
        [nnet2]="nnet2 --ali gmm" \
        [nnet2_mc]="nnet2 --ali gmm --cond mc" \
        [nnet2_mc_adapt]="nnet2 --ali gmm --cond mc" \
        [nnet2_lda]="nnet2 --ali gmm_lda" \
        [nnet2_lda_mc]="nnet2 --ali gmm_lda --cond mc" \
        [bnf]="bottleneck_dnn --ali gmm" \
        [bnf_mc]="bottleneck_dnn --ali gmm --cond mc" \
        )
    
    ORDER=($*)
    echo Training list : ${ORDER[*]}
    # declare -a ORDER=(  nnet2_tri1_mc )
    for mdl in ${ORDER[*]}; do
        if [ ! -e ${FEAT_EXP}/${mdl}/final.mdl ]; then
            echo "### Train MDL ${mdl} ###"
            eval  "${MDL[$mdl]}" || exit 1
        fi
    done

}

echo "### Acoustic Models Train ###"
# export FEAT_TYPE=mfcc
. check.sh
. local/am_util.sh

train ${TR_MDL}
# mkgraph ${FEAT_EXP}/gmm_lda_mc
# alignment ${FEAT_EXP}/mono $TR_CLN --boost-silence 1.25
