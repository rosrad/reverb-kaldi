#!/bin/bash
. check.sh
echo "### GmmHmm Train ###"

function alignment() {
    if [ $# -lt 1 ]; then
        echo "Error: no enough paramaters!"
        echo "Usage: alignment tri2"
        exit 1;
    fi
    mdl=$1
    if [ ! -e ${mdl}_ali/ali.1.gz ]; then
        echo "Align Model #${mdl}#."
        steps/align_si.sh --nj $nj_train ${@:2} \
            $TR_CLN ${DATA}/lang ${mdl} ${mdl}_ali || exit 1;
    fi
}

function mkgraph() {
    if [ $# -lt 1 ]; then
        echo "Error: no enough paramaters!"
        echo "Usage: mkgraph tri2"
        exit 1;
    fi
    mdl=$1
    echo "### Make Graph of MDL ${mdl} "
    utils/mkgraph.sh ${DATA}/lang_test_bg_5k ${mdl} ${mdl}/graph_bg_5k
}

function fmllr(){
    if [ $# -lt 1 ]; then
        echo "Error: no enough paramaters!"
        echo "Usage: fmllr tri2a_mc"
        exit 1;
    fi
    mdl=$1
    steps/get_fmllr_basis.sh --per-utt true $TR_MC ${DATA}/lang ${mdl} || exit 1;
}

# Train monophone model on clean data (si_tr).
function mono(){
    mdl=${EXP}/mono0a
    steps/train_mono.sh --boost-silence 1.25 --nj $nj_train \
        $TR_CLN ${DATA}/lang ${mdl} || exit 1;
    mkgraph ${mdl}
    alignment ${mdl} --boost-silence 1.25
}

# Create first triphone recognizer.
function tri1_phone() {
    mdl=${EXP}/tri1
    echo MDL = $mdl

    steps/train_deltas.sh --boost-silence 1.25 \
        2000 10000 $TR_CLN ${DATA}/lang ${EXP}/mono0a_ali ${mdl} || exit 1;
    mkgraph ${mdl}
    alignment ${mdl}
}

# The following code trains and evaluates a delta feature recognizer, which is similar to the HTK
# baseline (but using per-utterance basis fMLLR instead of batch MLLR). This is for reference only.

function tri2_phone() {
    # Train tri2phone, which is deltas + delta-deltas, on clean data.
    cond=
    . utils/parse_options.sh
    mdl=${EXP}/tri2
    train=$TR_CLN
    ali=${EXP}/tri1_ali
    if [ "$cond" == "mc" ]; then
        train=$TR_MC
        mdl=${mdl}_mc
        ali=${mdl}_ali
    fi
    steps/train_deltas.sh \
        2500 15000 $train ${DATA}/lang $ali ${mdl} || exit 1;
    mkgraph ${mdl}
    [ $cond != "mc" ] && alignment ${mdl}
}

# function mk_mc() {
#     ali=
#     . utils/parse_options.sh 
#     mdl=${EXP}/$1
#     mc_ali=${ali:-${mdl}_ali}
#     echo "Train MultiCondition of MDL:${mdl}"
#     steps/train_deltas.sh ${@:2}\
#         2500 15000 $TR_MC ${DATA}/lang  ${mdl}_mc || exit 1;
#     mkgraph ${mdl}_mc
# }

function tri2_lda_mllt() {
    cond=
    . utils/parse_options.sh
    mdl=${EXP}/tri2_lda_mllt
    train=$TR_CLN
    if [ "$cond" == "mc" ]; then
        train=$TR_MC
        mdl=${mdl}_mc
    fi
    steps/train_lda_mllt.sh \
        --splice-opts "--left-context=$context_size --right-context=$context_size" \
        2500 15000 $train ${DATA}/lang ${EXP}/tri1_ali ${mdl} || exit 1;
    mkgraph ${mdl}
    [ "$cond" != "mc" ] && alignment ${mdl}
}


function train () {
    declare -A MDL=( \
        [mono0a]="mono" \
        [tri1]="tri1_phone" \
        [tri2]="tri2_phone" \
        [tri2_mc]="tri2_phone --cond mc" \
        [tri2_lda_mllt]="tri2_lda_mllt" \
        [tri2_lda_mllt_mc]="tri2_lda_mllt --cond mc" \
        )
    
    declare -a ORDER=(mono0a tri1 tri2 tri2_mc tri2_lda_mllt tri2_lda_mllt_mc)
    for mdl in ${ORDER[*]}; do
        if [ ! -e ${EXP}/${mdl}/final.mdl ]; then
            echo "### Train MDL ${mdl} ###"
            eval ${MDL[$mdl]} || exit 1
        fi
    done

}



train
# mkgraph ${EXP}/tri1
# mkgraph ${EXP}/tri2
# mk_mc tri2
# # basis fMLLR for tri2a_mc system
# # This computes a transform for every training utterance and computes a basis from that.


# Recognition using fMLLR adaptation (per-utterance processing).
# for dataset in ${DATA}/REVERB_dt/SimData_dt* ; do
#     steps/decode_basis_fmllr.sh --nj $nj_bg \
#         ${EXP}/tri2a_mc/graph_bg_5k $dataset ${EXP}/tri2a_mc/decode_basis_fmllr_bg_5k_REVERB_dt_`basename $dataset` || exit 1;
# done


# # decode REVERB dt using tri2a, clean
# for dataset in ${DATA}/REVERB_dt/SimData_dt* ; do
#     steps/decode.sh --nj $nj_bg \
#         ${EXP}/tri2a/graph_bg_5k $dataset ${EXP}/tri2a/decode_bg_5k_REVERB_dt_`basename $dataset` || exit 1;
# done

# # decode REVERB dt using tri2a, mc
# for dataset in ${DATA}/REVERB_dt/SimData_dt*; do
#     steps/decode.sh --nj $nj_bg \
#         ${EXP}/tri2a_mc/graph_bg_5k $dataset ${EXP}/tri2a_mc/decode_bg_5k_REVERB_dt_`basename $dataset` || exit 1;
# done








