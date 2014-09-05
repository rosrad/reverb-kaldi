#!/bin/bash
. check.sh
. local/am_util.sh
function nnet2() {
    am=
    dt=
    dst=
    local nj=
    . utils/parse_options.sh
    [[ -z $nj ]] && nj=${nj_decode}

    local options=
    if [[ ${dst/fmllr/} != ${dst} ]]; then
        local fmllr_gmm=$(echo ${TRANSFORM_PAIRS}|awk 'BEGIN{RS=" "; FS="-"} $1 ~ /^'${am}'$/{print $2}')
        local fmllr_dir=${FEAT_EXP}/${fmllr_gmm}/$(basename ${dst}) # 
        [[ -d $fmllr_dir ]] &&  options="--transform-dir ${fmllr_dir}" # make sure it is exit
        [[ -z ${options} ]] && return 1 # 
    fi
    steps/nnet2/decode.sh --nj $nj --num-threads 6 $options \
        ${FEAT_EXP}/${am}/graph_bg_5k $dt $dst

}

function gmm() {
    am=
    dt=
    dst=
    local nj=
    . utils/parse_options.sh

    [[ -z $nj ]] && nj=${nj_decode}
    local options=
    
    local decode_script="steps/$(echo decode $*|sed 's# #_#').sh"
    ${decode_script} --nj ${nj} ${options} \
        ${FEAT_EXP}/${am}/graph_bg_5k $dt $dst
}

function inter_decode() {
    reg=${REG:-""}    
    test=
    . utils/parse_options.sh
    echo ============================================================================
    echo "                    DECODING                                              "
    echo ============================================================================
    echo "### GmmHmm Decode using DT:${reg} ###"
    local opts=$(echo $*|sed 's# #_#')#
    for am in ${DT_MDL[*]}; do
        for dt in $(find ${DT_DATA} -maxdepth 2 -type d  | grep -P ${DT_DATA}'/([A-Z]+_){1,}dt/.*'$reg'.*'|sort);do
            base_am=$(baseam $am )
            dst="${FEAT_EXP}/${am}/decode_${opts}$(basename $dt)"
            local options=
            [[ ${dt/GLOBAL/} != ${dt} ]] && options="--nj 1"
            cmd="${base_am} ${options} --am $am --dt ${dt} --dst $dst $*"
            if [[ -n $test ]] ;then
                echo ${cmd}
                continue
            fi
            echo "Acoustic Model : ${base_am}"
            ${cmd}
        done
        echo 
    done
}

function decode () {
    declare -A DECOER=( \
        [test]="inter_decode --test ture  " \
        [normal]="inter_decode  " \
        [fmllr]="inter_decode fmllr " \
        )

    list=($*)
    for idx in ${list[*]}; do
        echo "### Decode with options ${idx} ###"
        echo  ${DECOER[$idx]}
        eval  ${DECOER[$idx]} || exit 1
    done

}
# export FEAT_TYPE=mfcc



decode $@ 

