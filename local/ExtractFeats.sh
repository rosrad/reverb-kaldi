#!/bin/bash

. check.sh

function dump_bnf() {
    mdl=tril
    . utils/parse_options.sh
    
    [ ! -d $BNF_MDL_PARAM ] && mkdir -p $BNF_MDL_PARAM
    [ ! -d $BNF_DATA ] && mkdir -p $BNF_DATA
    mfcc_data=${DATA}
    for tag in $* ;do
        cmd="find  ${mfcc_data}/${tag}/* -maxdepth 0 -type d"
        if [[ $tag =~ ^si_.* ]]; then
            cmd="find  ${mfcc_data}/${tag}/ -maxdepth 0 -type d"
        fi

        for dataset in $($cmd); do 
            relative=${dataset/${mfcc_data}/}
            steps/nnet2/dump_bottleneck_features.sh --nj $nj_decode \
                ${dataset} ${BNF_DATA}/${relative} ${BNF_MDL_EXP}/${mdl} ${BNF_MDL_PARAM} ${BNF_MDL_DUMP}
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

function fmllr() {
    gmm=tri1_mc
    label=
    feat=mfcc
    . utils/parse_options.sh

    feat_am=${feat^^}_EXP
    am=${!feat_am}/${gmm}
    # using  some tricks to expand the the path
    feat_data_var=${feat^^}_DATA
    src_data=${!feat_data_var}

    fmllr_var=${feat^^}_FMLLR
    fmllr_dir=${!fmllr_var}/${gmm}_${label}
    
    for tag in $@; do
        for set in $(find ${src_data}/$tag -maxdepth 1 -type d |grep -P ${src_data}/'[^(si)].*_dt/.*'$reg'.*'|sort ); do
            fmllr_data=$fmllr_dir/data/$tag/$(basename ${set})
            echo $fmllr_data
            # transform_dir=$(ls ${am}|grep FMLLR-$(basename ${set}))
            transform_dir=$am/$(ls ${am}|grep -P FMLLR-${label}-?$(basename ${set})'$')
            if [[ ! -f $transform_dir/trans.1 ]]; then
                echo "ERROR no transform file in $transform_dir"
            else                
                steps/make_fmllr_feats.sh --nj $nj_bg --transform-dir $transform_dir \
                    $fmllr_data \
                    $set \
                    $am \
                    $fmllr_dir/log \
                    $fmllr_dir/param
            fi
        done
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

function mkfeats () {
    declare -A FEATS=( \
        [mfcc]="mfcc" \
        [mfcc_fmllr]="fmllr --gmm tri1_mc --feat mfcc" \
        [bnf]="dump_bnf --mdl tri1_mc" \
        [bnf_tri1_mc]="dump_bnf --mdl tri1_mc" \
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



