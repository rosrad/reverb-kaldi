#!/bin/bash
. check.sh
. local/am_util.sh

function alignment() {
    fmllr=
    
    . utils/parse_options.sh
    if [ $# -lt 1 ]; then
        echo "Error: no enough paramaters!"
        echo "Usage: alignment gmm"
        exit 1;
    fi
    if [[ -z $(mc $1) ]];then
        echo "Warning: We should no align the multicontion train set"
        exit 1;
    fi
    mdl=${FEAT_EXP}/$1
    dst_ali=${mdl}_ali
    ali_script="align_si.sh"
    if [[ -n $fmllr ]]; then
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
    alignment $(basename ${mdl}) --boost-silence 1.25
}

# Create first triphone recognizer.
function tri1_phone() {
    mdl=${FEAT_EXP}/tri1
    train=$TR_CLN
    ali=${FEAT_EXP}/mono_ali
    steps/train_deltas.sh --boost-silence 1.25 \
        2000 10000 $train ${DATA}/lang ${ali} ${mdl} || exit 1;
    mkgraph ${mdl}
    alignment $(basename ${mdl})
}

# The following code trains and evaluates a delta feature recognizer, which is similar to the HTK
# baseline (but using per-utterance basis fMLLR instead of batch MLLR). This is for reference only.

function gmm() {
    cond=
    . utils/parse_options.sh
    mdl=${FEAT_EXP}/gmm
    train=$TR_CLN
    ali=${FEAT_EXP}/tri1_ali
    if [ "$cond" == "mc" ]; then
        train=$TR_MC
        mdl=${mdl}_mc
    fi

    steps/train_deltas.sh \
        2500 15000 $train ${DATA}/lang $ali ${mdl} || exit 1;
    mkgraph  ${mdl}
    alignment $(basename ${mdl})
}

function sat() {
    cond=
    ali=gmm
    . utils/parse_options.sh

    mdl=${FEAT_EXP}/$(opts2mdl ${ali} sat)
    ali=${FEAT_EXP}/${ali}
    train=$TR_CLN
    if [ "$cond" == "mc" ]; then
        train=$TR_MC
        mdl=${mdl}_mc
    fi
    steps/train_sat.sh \
        2500 15000 $train ${DATA}/lang ${ali} ${mdl} || exit 1;

    mkgraph ${mdl}
    alignment --fmllr ture $(basename ${mdl})
}

function lda() {
    cond=
    ali=gmm
    . utils/parse_options.sh

    mdl=${FEAT_EXP}/$(opts2mdl ${ali} lda)
    ali=${FEAT_EXP}/${ali}
    train=$TR_CLN
    if [ "$cond" == "mc" ]; then
        train=$TR_MC
        mdl=${mdl}_mc
    fi
    steps/train_lda_mllt.sh \
        --splice-opts "--left-context=$context_size --right-context=$context_size" \
        2500 15000 $train ${DATA}/lang ${ali} ${mdl} || exit 1;
    mkgraph  ${mdl}
    alignment $(basename ${mdl})
}

function nnet2() {
    cond=
    ali=gmm
    . utils/parse_options.sh

    mdl=${FEAT_EXP}/$(ali2mdl nnet2 ${ali})
    ali=${FEAT_EXP}/$(opts2mdl ${ali} ali)
    train=$TR_CLN
    if [ "$cond" == "mc" ]; then
        train=$TR_MC
        mdl=${mdl}_mc
    fi

    dnn_extra_opts="--num_epochs 20 --num-epochs-extra 10 --add-layers-period 1 --shrink-interval 3"
    steps/nnet2/train_tanh.sh --mix-up 5000 --initial-learning-rate 0.015 \
        --final-learning-rate 0.002 --num-hidden-layers 2  \
        --num-jobs-nnet "$nj_train" "${dnn_train_extra_opts[@]}" \
        ${train} ${DATA}/lang ${ali} ${mdl}
    mkgraph ${mdl}
    # alignment $(basename ${mdl})
}

function bottleneck_dnn() {
    cond=
    ali=gmm
    stage=-100
    . utils/parse_options.sh
    mdl=${BNF_EXP}/${ali}
    ali=${MFCC_EXP}/$(opts2mdl ${ali} ali)
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
        [mono]="mono" \
        [tri1]="tri1_phone" \
        [gmm]="gmm" \
        [gmm_mc]="gmm --cond mc" \
        [gmm_sat]="sat --ali gmm " \
        [gmm_sat_mc]="sat --ali gmm --cond mc" \
        [gmm_lda]="lda --ali gmm" \
        [gmm_lda_mc]="lda --cond mc --ali gmm" \
        [gmm_lda_sat]="sat --ali gmm_lda" \
        [gmm_lda_sat_mc]="sat --ali gmm_lda --cond mc" \
        [nnet2]="nnet2 --ali gmm" \
        [nnet2_mc]="nnet2 --ali gmm --cond mc" \
        [nnet2_lda]="nnet2 --ali gmm_lda" \
        [nnet2_lda_mc]="nnet2 --ali gmm_lda --cond mc" \
        [bnf]="bottleneck_dnn --ali gmm" \
        [bnf_mc]="bottleneck_dnn --ali gmm --cond mc" \
        )
    
    ORDER=($*)
    # declare -a ORDER=(  nnet2_tri1_mc )
    for mdl in ${ORDER[*]}; do
        if [ ! -e ${FEAT_EXP}/${mdl}/final.mdl ]; then
            echo "### Train MDL ${mdl} ###"
            eval  "${MDL[$mdl]}" || exit 1
        fi
    done

}
# export FEAT_TYPE=mfcc
echo "### Acoustic Models Train ###"

train ${TR_MDL}
# alignment --fmllr ture gmm_sat
