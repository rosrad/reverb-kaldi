#!/bin/bash

. check.sh

function dump_bnf() {
    mdl=gmm
    nj=
    . utils/parse_options.sh
    
    [ ! -d $BNF_MDL_PARAM ] && mkdir -p $BNF_MDL_PARAM
    [ ! -d $BNF_DATA ] && mkdir -p $BNF_DATA
    mfcc_data=${MFCC_DATA}
    [[ -z $nj ]] && nj=$nj_decode
    echo MFCC data dir : ${mfcc_data}
    for tag in $* ;do
        cmd="find  ${mfcc_data}/${tag}/* -maxdepth 0 -type d"
        if [[ $tag =~ ^si_.* ]]; then
            cmd="find  ${mfcc_data}/${tag}/ -maxdepth 0 -type d"
        fi

        for dataset in $($cmd); do 
            relative=${dataset/${mfcc_data}/}
            echo  Relative Path : $relative
            steps/nnet2/dump_bottleneck_features.sh --nj $nj \
                ${dataset} ${BNF_DATA}/${relative} ${BNF_MDL_EXP}/${mdl} ${BNF_MDL_PARAM}/${relative} ${BNF_MDL_DUMP}
        done
    done
}

function mfcc() {
    for set in $*;do
        case $set in
            REVERB_tr_cut) local/REVERB_wsjcam0_data_prep.sh $reverb_tr REVERB_tr_cut tr ;;
            REVERB_dt) local/REVERB_wsjcam0_data_prep.sh $reverb_dt REVERB_dt dt ;;
            PHONE_dt) local/REVERB_wsjcam0_data_prep.sh $phone_dt PHONE_dt phone ;;
            PHONE_SEL_dt) local/REVERB_wsjcam0_data_prep.sh $phone_sel_dt PHONE_SEL_dt phone_sel ;;
            *) echo "Invalid DATASET: ${set}" && exit 1;
        esac
    done
}

function mkfeats () {
    declare -A FEATS=( \
        [mfcc]="mfcc" \
        [bnf]="dump_bnf --mdl gmm_mc" \
        [bnf_gmm]="dump_bnf --mdl gmm" \
        [bnf_gmm_mc]="dump_bnf --mdl gmm_mc" \
        [bnf_global]="dump_bnf --nj 1 --mdl gmm_mc" 
        )
    
    for feat in $*; do
        echo "### extract features ${feat} ###"
        eval  ${FEATS[$feat]} $DT 
    done

}

# extract_feats --feat $FEAT_TYPE --mdl tri1_mc $DT
# DT=( PHONE_dt PHONE_SEL_dt )
# mkfeats mfcc_fmllr
mkfeats $*
