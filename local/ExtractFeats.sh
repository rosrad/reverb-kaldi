#!/bin/bash

. check.sh
. local/am_util.sh

function dump_bnf() {
    append=
    mdl=tri1_mc
    nj=
    . utils/parse_options.sh

    bnf_data=${BNF_DATA}
    bnf_mdl_param=${BNF_MDL_PARAM}
    bnf_exp=${BNF_EXP}
    bnf_mdl_exp=${BNF_MDL_EXP}
    bnf_mdl_dump=${BNF_MDL_DUMP}

    tag="_bnf_${mdl}"
    [[ -n ${append} ]] && tag=${tag}_append
    if [[ -n $tag ]];then
        bnf_data+=${tag}
        bnf_mdl_param+=${tag}
        bnf_exp=$(dirname ${bnf_exp})/exp${tag}
    fi

    [[ ! -d $bnf_exp ]] && warn_run mkdir -p ${bnf_exp} #  this is necessary for  bnf_switch.sh
    [ ! -d $bnf_mdl_param ] && warn_run mkdir -p $bnf_mdl_param
    [ ! -d $bnf_data ] && warn_run mkdir -p $bnf_data

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
                ${dataset} ${bnf_data}/${relative} ${bnf_mdl_exp}/${mdl} ${bnf_mdl_param}/${relative} ${bnf_mdl_dump}
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
        [bnf]="dump_bnf --mdl tri1_mc" \
        [bnf_mc]="dump_bnf --mdl tri1_mc" \
        [bnf_cln]="dump_bnf --mdl tri1" \
        [bnf_global]="dump_bnf --nj 1 --mdl tri1_mc" 
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
