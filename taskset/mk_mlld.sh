#!/bin/bash


function mk_lik_list() {
    mdl=gmm
    . utils/parse_options.sh
    local tag_list=($*)

    echo "gather the likelihood of each utterance for each set"
    dir=${FEAT_AUTOSEL}/${mdl}
    [[ ! -d $dir ]] && mkdir -p $dir

    for tag in ${tag_list[@]}; do
        src=${FEAT_EXP}/${mdl}/decode_#${tag}
        lattice-to-post --acoustic-scale=0.1 "ark:gunzip -c ${src}/lat.*.gz|" ark,t:${dir}/tmp.post ark,t:- \
            | sort -k1 | uniq > ${dir}/${tag}.lik
    done
}       

function sel_maximum() {
    target=${AUTOSEL_TARGET}
    source=${AUTOSEL_SOURCE}
    set_tag="PhoneMlld_dt_for_set1"
    mdl=gmm
    . utils/parse_options.sh

    dir=${FEAT_AUTOSEL}/${mdl}
    local tag_list=$(echo $* | awk '{for (i=1; i<=NF; i++) printf "'${dir}/'%s.lik ",$i}')
    local tags=($*)

    FEAT_AUTOSEL_SOURCE=${FEAT_DATA}/${source}
    FEAT_AUTOSEL_TARGET=${FEAT_DATA}/${target}
    utt_suffix="selected_uttids"
    echo TAGS: ${tags[@]}

    paste ${tag_list} \
        | awk '{ min=2; for (i=min; i<=NF; i+=2) {if ($i < $min) min=i;} printf "%s %d\n",$1,min/2;}' \
        | sort -k2 \
        | awk '{print $1 > "'${dir}'/" $2 "'.${utt_suffix}'" }'
    
    autosel_data=${FEAT_AUTOSEL_TARGET}/${set_tag}
    [[ ! -d ${autosel_data} ]] && mkdir -p ${autosel_data}

    for f in feats.scp wav.scp; do
        # clear the file feats.scp wav.scp
        [[ -f ${dir}/${f} ]]  && warn_run rm ${dir}/${f}
        for idx in ${!tags[@]}; do
            utils/filter_scp.pl ${dir}/$[${idx}+1].${utt_suffix} ${FEAT_AUTOSEL_SOURCE}/${tags[$idx]}/${f} >> ${dir}/${f}.org
        done
        cat ${dir}/${f}.org | sort -k1 | uniq > ${dir}/$f
        warn_run cp ${dir}/$f ${autosel_data}
    done
    for f in spk2utt utt2spk text; do
        warn_run cp ${FEAT_AUTOSEL_SOURCE}/${tags[0]}/${f} ${autosel_data}
    done

    # we must compute the cmvn stats firstly, because all the other features are depedent on the mfcc, we no need extract feature ,because it has been extracted.
    warn_run steps/compute_cmvn_stats.sh ${MFCC_DATA}/${target}/${set_tag} ${MFCC_LOG}/make_feats/${target}/${set_tag} ${MFCC_MDL_PARAM}/${target}/${set_tag}
}

function mk_feats() {
    for f in $* ; do
        case ${f} in
            mfcc) echo "we have the mfcc already";;
            bnf*) export DT=${AUTOSEL_TARGET}; local/ExtractFeats.sh  ${f};;
            *) echo "invalid feature type!"
        esac
    done
}

function selection() {
    tag_list=$(ls ${MFCC_DATA}/${AUTOSEL_SOURCE})
    echo tag list : ${tag_list}
    # mk_lik_list --mdl gmm ${tag_list} 
    # sel_maximum --mdl gmm ${tag_list}
    mk_feats bnf_org
}


export FEAT_TYPE=mfcc
. check.sh
. local/am_util.sh
export AUTOSEL=${WORKSPACE}/auto_select
export FEAT_AUTOSEL=${AUTOSEL}/${FEAT_TYPE}
export AUTOSEL_TARGET="PHONEMLLD_dt"
export AUTOSEL_SOURCE="PHONE_dt"

selection

