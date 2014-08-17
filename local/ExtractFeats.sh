#!/bin/bash

. check.sh

function dump_bnf() {
    mdl=tril
    . utils/parse_options.sh
    
    [ ! -d $BNF_PARAM ] && mkdir -p $BNF_PARAM
    [ ! -d $BNF_DATA ] && mkdir -p $BNF_DATA
    for tag in $* ;do
        cmd="find  ${DATA}/${tag}/* -maxdepth 0 -type d"
        if [[ $tag =~ ^si_.* ]]; then
            cmd="find  ${DATA}/${tag}/ -maxdepth 0 -type d"
        fi

        for dataset in $($cmd); do 
            relative=${dataset/${DATA}/}
            steps/nnet2/dump_bottleneck_features.sh --nj $nj_decode \
                ${dataset} ${BNF_DATA}/${relative} ${BNF_EXP}/${mdl} ${BNF_PARAM} ${BNF_DUMP}
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

function extract_feats() {
    feat=mfcc
    mdl=
    . utils/parse_options.sh
    echo Feature: $feat
    case $feat in
        mfcc) mfcc $*;;
        bnf) dump_bnf --mdl "${mdl}" $* ;;
        *) echo "Invalid FEAT: ${feat}"
    esac
}
# declare -a DT=( REVERB_tr_cut REVERB_dt PHONE_dt PHONE_SEL_dt )
extract_feats --feat $FEAT_TYPE --mdl tri1_mc $DT

