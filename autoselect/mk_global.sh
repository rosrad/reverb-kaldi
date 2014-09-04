#!/bin/bash

# this script is used to create a global relation between speaker and utterances




function global(){
    src_dir=$1
    tag=$(basename ${src_dir})

    # check the source dir
    [[ ! -d "$(pwd)/${src_dir}" ]] && (echo "Error: Source data dir does not exist!"; echo "Src :${src_dir}") && return

    global_target_set=${FEAT_DATA}/${GLOBAL_TARGET}/${tag}

    # make a clean work source space
    [[ ! -d ${global_target_set} ]] && mkdir -p ${global_target_set}
    for f in $(ls ${global_target_set}/ ) ; do
        rm ${global_target_set}/$f -fr
    done

    # create a spk2utt script with only one speaker for all utterance , this is used for create the global enviroment set
    for f in utt2spk feats.scp wav.scp text ; do
        cp ${src_dir}/${f} ${global_target_set}/
    done

    utt2spk="${global_target_set}/utt2spk"
    spk2utt="${global_target_set}/spk2utt"
    
    mv ${utt2spk} ${utt2spk}.org
    cat ${utt2spk}.org \
        | awk 'BEGIN {spk="";} { if(length(spk)==0) spk=$2; print $1,spk;}' \
        > ${utt2spk}

    utils/utt2spk_to_spk2utt.pl ${utt2spk} > ${spk2utt}
    # we must compute the cmvn stats firstly, because all the other features are depedent on the mfcc, we no need extract feature ,because it has been extracted.
    steps/compute_cmvn_stats.sh ${MFCC_DATA}/${GLOBAL_TARGET}/${tag} ${MFCC_LOG}/make_feats/${GLOBAL_TARGET}/${tag} ${MFCC_MDL_PARAM}/${GLOBAL_TARGET}/${tag}

    echo ""
}

function mk_feats() {
    for f in $* ; do
        case ${f} in
            mfcc) echo "we have the mfcc already";;
            bnf) export DT=${GLOBAL_TARGET}; local/ExtractFeats.sh  bnf_global;;
            *) echo "invalid feature type!"
        esac
    done
}

function mk_all() {
    for d in $(find ${MFCC_DATA} -maxdepth 2 -type d |grep -P ${MFCC_DATA}'/([A-Z]+_){1,}dt/' |grep -v "GLOBAL"|sort) ; do
        warn_run global $d
    done
    mk_feats bnf
}

FEAT_TYPE=mfcc
GLOBAL_TARGET="GLOBAL_dt"
. check.sh
. local/am_util.sh

mk_all
