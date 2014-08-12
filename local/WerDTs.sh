#!/bin/bash
. check.sh

function wer_dt() {
    reg=${REG:-".*dt.*"}
    test=
    . utils/parse_options.sh
    if [ $# -lt 1 ] ;then
        echo "ERROR: no enough parametors"
        echo "USAGE: wer_dt.sh --reg Sim*dt*cln* tri1 tri2"
        exit 1
    fi
    echo ============================================================================
    echo "                    Getting Results                                       "
    echo ============================================================================
    AMs=(tri1)
    declare -a AMs=($*)
    for am in ${AMs[*]}; do
        for x in $(find ${EXP}/${am}/ -maxdepth 1 -type d | grep -P 'decode.*'${reg}'.*'|sort); do
            if [[ -n $test ]]; then
                echo "${x}#${am}"
                continue
            fi
            [ -d $x ] && grep WER $x/wer_* | utils/best_wer.sh|awk '{print $2,$14}'|sed -e 's#\./tmp/exp/\(.*\)/decode.*_\([^_]*\)_dt_for_\(.*[0-9]*\).*/wer.*#\1 \2_\3#'
        done
        echo 
    done
}
wer_dt $*
