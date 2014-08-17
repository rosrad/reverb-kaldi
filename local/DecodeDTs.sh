#!/bin/bash
. check.sh

function decode_dt() {
    reg=${REG:-".*dt.*"}
    test=
    . utils/parse_options.sh
    if [ $# -lt 1 ] ;then
        echo "ERROR: no enough parametors"
        echo "USAGE: decode_dt.sh --reg Sim*dt*cln* tri1 tri2"
        exit 1
    fi
    echo ============================================================================
    echo "                    DECODING                                              "
    echo ============================================================================
    echo "### GmmHmm Decode using DT:${reg} ###"
    declare -a AMS=($*)
    for am in ${AMS[*]}; do
        for dt in $(find ${DT_DATA} -maxdepth 2 -type d |grep -P ${DT_DATA}/'[^(si)].*_dt/.*'$reg'.*'|sort );do
            if [[ -n $test ]]; then
                echo "${dt}#${am}"
                continue
            fi
            if [[ $am =~ ^nnet.*  ]]; then
                graph_am=$(echo $am|cut -d'_' -f2)
                steps/nnet2/decode.sh --nj $nj_bg --num-threads 6 \
                    ${FEAT_EXP}/${graph_am}/graph_bg_5k $dt ${FEAT_EXP}/${am}/decode_bg_5k_REVERB_dt_$(basename ${dt})
            else
                steps/decode.sh --nj $nj_bg \
                    ${FEAT_EXP}/${am}/graph_bg_5k $dt ${FEAT_EXP}/${am}/decode_bg_5k_REVERB_dt_$(basename ${dt})
            fi
        done
        echo 
    done
}

decode_dt $*

