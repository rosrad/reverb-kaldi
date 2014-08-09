#!/bin/bash
echo ============================================================================
echo "                    Getting Results [see RESULTS file]                    "
echo ============================================================================

decode=${1:-"cln"}
model=${2:-"net"}
echo "search for"
echo "DECODE SET: ${decode}"
echo "MODEL: ${model}"
for x in exp/*${model}*/*decode*${decode}*; do
    [ -d $x ] && grep WER $x/wer_* | utils/best_wer.sh|awk '{print $2,$14}'|sed -e 's#exp/\(.*\)/decode.*_\([^_]*\)_dt_for_\(.*[0-9]*\).*/wer.*#\1 \2_\3#'
    # | awk '{print $2, $14}'|sed -e 's#exp/\(.*\)/decode.*1ch_\(.*\)/wer.*#\1/\2#'
done 

