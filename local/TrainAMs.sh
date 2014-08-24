#!/bin/bash

function mdl_name() {
    fmllr=
    ali=
    mc=
    lda=
    . utils/parse_options.sh

    mdl=${1}
    opt=""
    if [[ -n ${ali} ]];then
        mdl=${mdl}_${ali}
    fi
    PARAMATERS=( mc fmllr lda )
    for para in ${PARAMATERS[*]} ;do
        if [[ -n ${!para} ]];then
            opt=${opt}_${para}
        fi
    done
    echo ${mdl}${opt}
}

function alignment() {
    fmllr=
    . utils/parse_options.sh
    
    if [ $# -lt 1 ]; then
        echo "Error: no enough paramaters!"
        echo "Usage: alignment tri2"
        exit 1;
    fi
    mdl=${FEAT_EXP}/$1
    dst_ali=${mdl}_ali
    ali_script="align_si.sh"
    if [[ -n $fmllr ]]; then
        dst_ali=${mdl}_fmllr_ali
        ali_script="align_fmllr.sh"
    fi        
    if [ ! -e ${dst_ali}/ali.1.gz ]; then
        echo "Align Model #${mdl}#."
        steps/${ali_script} --nj $nj_train ${@:2} \
            $TR_CLN ${DATA}/lang ${mdl} ${dst_ali} || exit 1;
    fi
    echo ${dst_ali}
}

function mkgraph() {
    if [ $# -lt 1 ]; then
        Echo "Error: no enough paramaters!"
        echo "Usage: mkgraph tri2"
        exit 1;
    fi
    mdl=$1
    echo "### Make Graph of MDL ${mdl} "
    utils/mkgraph.sh ${@:2} ${DATA}/lang_test_bg_5k ${mdl} ${mdl}/graph_bg_5k
}

# Train monophone model on clean data (si_tr).
function mono(){
    mdl=${FEAT_EXP}/mono0a
    steps/train_mono.sh --boost-silence 1.25 --nj $nj_train \
        $TR_CLN ${DATA}/lang ${mdl} || exit 1;
    mkgraph ${mdl} --mono
    alignment ${mdl} --boost-silence 1.25
}

# Create first triphone recognizer.
function tri1_phone() {
    cond=
    . utils/parse_options.sh
    mdl=${FEAT_EXP}/tri1
    train=$TR_CLN
    ali=${FEAT_EXP}/mono0a_ali
    if [ "$cond" == "mc" ]; then
        train=$TR_MC
        ali=${mdl}_ali
        mdl=${mdl}_mc
    fi
    steps/train_deltas.sh --boost-silence 1.25 \
        2000 10000 $train ${DATA}/lang ${ali} ${mdl} || exit 1;
    mkgraph ${mdl}
}

# The following code trains and evaluates a delta feature recognizer, which is similar to the HTK
# baseline (but using per-utterance basis fMLLR instead of batch MLLR). This is for reference only.

function tri2_phone() {
    # Train tri2phone, which is deltas + delta-deltas, on clean data.
    cond=
    . utils/parse_options.sh
    mdl=${FEAT_EXP}/tri2
    train=$TR_CLN
    ali=$(alignment tri1)
    if [ "$cond" == "mc" ]; then
        train=$TR_MC
        ali=${mdl}_ali
        mdl=${mdl}_mc
    fi
    steps/train_deltas.sh \
        2500 15000 $train ${DATA}/lang $ali ${mdl} || exit 1;
    mkgraph ${mdl}
}

function lda_mllt() {
    cond=
    ali=tri2
    . utils/parse_options.sh
    mdl=${FEAT_EXP}/lda_mllt_${ali}
    ali=$(alignment ${ali})
    train=$TR_CLN
    
    if [ "$cond" == "mc" ]; then
        train=$TR_MC
        mdl=${mdl}_mc
    fi
    steps/train_lda_mllt.sh \
        --splice-opts "--left-context=$context_size --right-context=$context_size" \
        2500 15000 $train ${DATA}/lang ${ali} ${mdl} || exit 1;
    mkgraph ${mdl}
}

function nnet2() {
    cond=
    ali=tril
    fmllr=
    . utils/parse_options.sh
    echo ${ali}

    mdl=${FEAT_EXP}/$(mdl_name --fmllr "$fmllr" --ali "${ali}" --mc "${cond}" nnet2)
    ali=$(alignment --fmllr "$fmllr" ${ali})
    train=$TR_CLN
    if [ "$cond" == "mc" ]; then
        train=$TR_MC
    fi
    dnn_extra_opts="--num_epochs 20 --num-epochs-extra 10 --add-layers-period 1 --shrink-interval 3"

    steps/nnet2/train_tanh.sh --mix-up 5000 --initial-learning-rate 0.015 \
        --final-learning-rate 0.002 --num-hidden-layers 2  \
        --num-jobs-nnet "$nj_train" "${dnn_train_extra_opts[@]}" \
        ${train} ${DATA}/lang ${ali} ${mdl}
}

function bottleneck_dnn() {
    cond=
    ali=tri2
    fmllr=
    stage=-100
    . utils/parse_options.sh
    mdl=${BNF_EXP}/${ali}
    ali=$(alignment --fmllr "$fmllr" ${ali})
    train=$TR_CLN
    if [ "$cond" == "mc" ]; then
        train=$TR_MC
        mdl=${mdl}_mc
    fi
    [[ ! -e $BNF_EXP ]] && mkdir -p ${BNF_EXP}
    steps/nnet2/train_tanh_bottleneck.sh \
        --stage $stage --num-jobs-nnet 4 \
        --num-threads 1 --mix-up 5000 --max-change 40 \
        --minibatch-size 512 \
        --initial-learning-rate 0.005 \
        --final-learning-rate 0.0005 \
        --num-hidden-layers 5 \
        --bottleneck-dim 42 --hidden-layer-dim 1024 \
        ${train} ${DATA}/lang $ali ${mdl} || exit 1
}

function train () {
    declare -A MDL=( \
        [mono0a]="mono" \
        [tri1]="tri1_phone" \
        [tri1_mc]="tri1_phone --cond mc" \
        [tri2]="tri2_phone" \
        [tri2_mc]="tri2_phone --cond tri2" \
        [lda_mllt_tri2]="lda_mllt --ali tri2" \
        [lda_mllt_tri2_mc]="lda_mllt --cond mc --ali tri2" \
        [nnet2_tri1]="nnet2 --ali tri1" \
        [nnet2_tri1_mc]="nnet2 --ali tri1 --cond mc" \
        [nnet2_tri2]="nnet2 --ali tri2" \
        [nnet2_tri2_mc]="nnet2 --ali tri2 --cond mc" \
        [nnet2_lda_mllt_tri2]="nnet2 --ali lda_mllt_tri2" \
        [nnet2_lda_mllt_tri2_mc]="nnet2 --ali lda_mllt_tri2 --cond mc" \
        [nnet2_lda_mllt_tri2_fmllr]="nnet2 --ali lda_mllt_tri2 --fmllr true" \
        [nnet2_lda_mllt_tri2_mc_fmllr]="nnet2 --ali lda_mllt_tri2 --cond mc --fmllr true" \
        [bnf_tri1]="bottleneck_dnn --ali tri1" \
        [bnf_tri1_mc]="bottleneck_dnn --ali tri1 --cond mc" \
        [bnf_tri2]="bottleneck_dnn --ali tri2" \
        [bnf_tri2_mc]="bottleneck_dnn --ali tri2 --cond mc" \
        )
    
    # declare -a ORDER=(mono0a tri1 tri2 tri2_mc tri2_lda_mllt tri2_lda_mllt_mc)

    # declare -a ORDER=( nnet2_tri1 nnet2_tri1_mc nnet2_tri2 nnet2_tri2_mc )
    # declare -a ORDER=( bnf_tri1_mc ) 
    ORDER=($*)
    # declare -a ORDER=(  nnet2_tri1_mc )
    for mdl in ${ORDER[*]}; do
        if [ ! -e ${FEAT_EXP}/${mdl}/final.mdl ]; then
            echo "### Train MDL ${mdl} ###"
            eval ${MDL[$mdl]} || exit 1
        fi
    done

}

. check.sh
echo "### Acoustic Models Train ###"

train ${TR_MDL}

