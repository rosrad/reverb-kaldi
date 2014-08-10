#!/bin/bash
. check.sh

function decode_dt() {
    reg="*dt*"
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
        for dataset in ${DATA}/REVERB_dt/${reg} ; do
            echo "#### Decoding  ${dataset} Using AM: $am"
            if [[ $am =~ ^nnet.*  ]]; then
                graph_am=$(echo $am|cut -d'_' -f2)
                echo Graph $graph_am AM $am
                # steps/nnet2/decode.sh --nj $nj_bg --num-threads 6 \
                #     ${EXP}/${graph_am}/graph_bg_5k $dataset ${EXP}/${am}/decode_bg_5k_REVERB_dt_$(basename $dataset)
            else
                echo AM $am
                # steps/decode.sh --nj $nj_bg \
                #     ${EXP}/${am}/graph_bg_5k $dataset ${EXP}/${am}/decode_bg_5k_REVERB_dt_$(basename $dataset)
            fi
        done
    done
}

decode_dt $*

