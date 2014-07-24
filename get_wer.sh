#!/bin/bash
echo ============================================================================
echo "                    Getting Results [see RESULTS file]                    "
echo ============================================================================
model=${1:-"net"}
decode=${2:-"cln"}
echo "search for"
echo "MODEL: ${model}"
echo "DECODE SET: ${decode}"
for x in exp/*${model}*/*decode*${decode}*; do
    [ -d $x ] && grep WER $x/wer_* | utils/best_wer.sh|awk '{print $2,$14}'|sed -e 's#exp/\(.*\)/decode.*for_\(1ch_\)*\(.*room[0-9]*\).*/wer.*#\1 \3#'
    # | awk '{print $2, $14}'|sed -e 's#exp/\(.*\)/decode.*1ch_\(.*\)/wer.*#\1/\2#'
done 

