#!/bin/bash
. check.sh
. local/am_util.sh
function nnet2() {
    am=
    dt=
    dst=
    . utils/parse_options.sh

    graph_am=$(echo $am| sed 's#nnet2_\(.*tri.\).*#\1#')
    echo "am ${am}"
    echo "graph: ${graph_am}"

    steps/nnet2/decode.sh --nj $nj_bg --num-threads 6 $options \
        ${FEAT_EXP}/${graph_am}/graph_bg_5k $dt $dst

}

function gmm() {
    am=$1
    dt=$2
    dst=$3
    . utils/parse_options.sh

    decode_script="steps/$(echo decode $*|sed 's# #_#').sh"
    ${decode_script} --nj ${nj_bg} ${options} \
        ${FEAT_EXP}/${am}/graph_bg_5k $dt $dst
}

function inter_decode() {
    reg=${REG:-"dt"}    
    test=
    . utils/parse_options.sh
    echo ============================================================================
    echo "                    DECODING                                              "
    echo ============================================================================
    echo "### GmmHmm Decode using DT:${reg} ###"
    opts=$(echo $*|sed 's# #_#')#
    for am in ${DT_MDL[*]}; do
        for dt in $(find ${DT_DATA} -maxdepth 2 -type d  | grep -P ${DT_DATA}'/([A-Z]+_){1,}dt/.*'$reg'.*'|sort);do
            base_am=$(baseam $am )
            dst="${FEAT_EXP}/${am}/decode_${opts}$(basename $dt)"
            cmd="${base_am} --am $am --dt ${dt} --dst $dst $*"
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

