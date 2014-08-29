#!/bin/bash
. check.sh

function wer_dt() {
    reg=${REG:-"dt"}
    regex='decode_.*'${reg}'.*[^(si)]$'
    echo ============================================================================
    echo "                    Getting Results                                       "
    echo "                REGEX: $regex                                             "
    echo ============================================================================

    for am in ${DT_MDL[*]}; do
        for x in $(find ${FEAT_EXP}/${am}/ -maxdepth 1 -type d | grep -P $regex |sort); do
            if [[ -n $test ]]; then
                echo "${am} ${x} "
                continue
            fi
            [ -d $x ] && grep WER $x/wer_* \
                | utils/best_wer.sh|awk '{print $2,$14}' \
                | sed -e 's|\./tmp/exp/\(.*\)/decode.*_\([^_#]*\)#\([^_]*\)_dt_for_\(.*[0-9]*\).*/wer.*|\1_\2 \3_\4|' \
                | awk '{print $1,gensub(/(.*)_$/, "\\1", "1", $2),gensub(/([^_]+_)?([^_]+)_(room|set)([[:digit:]]+)$/,"\\2\\4", "1",$3)}'
        done
        echo 
    done
}
wer_dt $*
