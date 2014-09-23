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
	local file=$(basename ${dst})
	if [[ ${file/fmllr/} != ${file} ]]; then
        local fmllr_gmm=$(echo ${TRANSFORM_PAIRS}|awk 'BEGIN{RS=" "; FS="-"} $1 ~ /^'${am}'$/{print $2}')
        local fmllr_dir=${FEAT_EXP}/${fmllr_gmm}/${file}
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
	local decode_sel=()
	local opts=()
	[[ ${1/fmllr/} != $1 ]] && decode_sel+=(fmllr)
    local decode_script="steps/$(concat_opts decode ${decode_sel[@]}).sh"
    ${decode_script} --nj ${nj} ${opts[*]} \
        ${FEAT_EXP}/${am}/graph_bg_5k $dt $dst
}

function plda() {
    am=
    dt=
    dst=
    local nj=
    . utils/parse_options.sh

	if [[ ${1/fmllr/} != ${1} ]] ; then
		echo "Warning: No fmllr decoding  supported"
		return 1
	fi
    [[ -z $nj ]] && nj=${nj_decode}
    local options=("--stage -1")

    local decode_script="steps/decode_plda.sh"
    ${decode_script} --nj ${nj} ${options[@]} \
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
        for dt in $(find ${DT_DATA}/ -maxdepth 2 -xtype d  | grep -P ${DT_DATA}'/([A-Z]+_){1,}dt/'|sort);do
            [[ -z $(basename $dt | grep -P $reg) ]] && continue
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
		[raw]="inter_decode raw " \
        [fmllr]="inter_decode fmllr " \
        [raw_fmllr]="inter_decode raw_fmllr " \
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


