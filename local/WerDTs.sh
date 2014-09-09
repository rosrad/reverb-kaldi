#!/bin/bash
. check.sh

function wer_dt() {
    reg=${REG:-""}
    regex='decode_.*'${reg}'.*[^(si)]$'
    echo ============================================================================
    echo "                    Getting Results                                       "
    echo "                REGEX: $regex                                             "
    echo ============================================================================

    for am in ${DT_MDL[*]}; do
        for x in $(find ${FEAT_EXP}/${am}/ -maxdepth 1 -type d |grep "decode"|sort); do
			# echo test : $(basename $x |sed 's/decode[^#]*#\(.*\)/\1/'|grep -P '.*(?<!\.si)$'|grep -P $reg)
            [[ -z $(basename $x |sed 's/decode[^#]*#\(.*\)/\1/'|grep -P '.*(?<!\.si)$'|grep -P $reg) ]] && continue 
            if [[ -n $test ]]; then
                echo "${am} ${x} "
                continue
            fi
            [ -d $x ] && grep WER $x/wer_* \
                | utils/best_wer.sh|awk '{print $2,$14}' \
                | sed -e 's|\./tmp/exp/\(.*\)/decode.*_\([^_#]*\)#\(.*\)_dt_for_\(.*[0-9]*\).*/wer.*|\1_\2 \3_\4|' \
                | awk '{print $1,gensub(/(.*)_$/, "\\1", "1", $2),gensub(/(.*)_(room|set)([[:digit:]]+)$/,"\\1\\3", "1",$3)}' \
				| sed 's#SimData_##' 
        done
        echo 
    done
}
wer_dt $*
