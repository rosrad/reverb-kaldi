#!/bin/bash
. check.sh

function ls_transform(){
    fmllr=
    set=
    . utils/parse_options.sh
    if [[ -z ${fmllr} ]];then
        exit 0
    fi
    adapt_mdl_dir=${FEAT_EXP}/$(echo ${fmllr} | awk -F'/' '{print $1}')
    lable=$(echo ${fmllr} | awk -F'/' '{print $2}')
    if [[ -n $lable ]];then
        fmllr_regex=${lable//:/.*}'[^(si)]*$'
    else
        fmllr_regex=FMLLR-${set}
    fi

    candidate=$(ls $adapt_mdl_dir|grep -P $fmllr_regex |sort|head -n1)
    if [[ -z ${candidate} ]];then
        exit 0
    fi
    echo $adapt_mdl_dir/${candidate}
}

function nnet2() {
    fmllr=
    . utils/parse_options.sh
    am=$1
    dt_set=$2
    set=$(basename ${dt_set})

    graph_am=$(echo $am| sed 's#nnet2_\(.*\)#\1#')
    transform_dir=$(ls_transform --fmllr "$fmllr" --set "$set")
    echo "Transform Dir: $transform_dir"
    options=""
    prefix=""
    if [[ -n $transform_dir ]]; then
        options=" --transform-dir ${transform_dir} "
        prefix="FMLLR-"        
    fi

    steps/nnet2/decode.sh --nj $nj_bg --num-threads 6 $options \
        ${FEAT_EXP}/${graph_am}/graph_bg_5k $dt_set ${FEAT_EXP}/${am}/decode_bg_5k_REVERB_dt_${prefix}${set}

}

function gmm() {
    fmllr=
    . utils/parse_options.sh
    am=$1
    dt_set=$2
    set=$(basename ${dt_set})
    transform_dir=$(ls_transform --fmllr "$fmllr" --set "$set")
    echo "Transform Dir: $transform_dir"
    if [[ -n $fmllr && -z $transform_dir ]]; then
        steps/decode_fmllr.sh --nj $nj_bg \
            ${FEAT_EXP}/${am}/graph_bg_5k $dt_set ${FEAT_EXP}/${am}/decode_bg_5k_REVERB_dt_FMLLR-${set}
    else
        steps/decode.sh --nj $nj_bg --transform-dir "$transform_dir" \
            ${FEAT_EXP}/${am}/graph_bg_5k $dt_set ${FEAT_EXP}/${am}/decode_bg_5k_REVERB_dt_${set}
    fi
}

function decode_dt() {
    reg=${REG:-".*dt.*"}
    test=
    fmllr=
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
                nnet2 --fmllr "$fmllr" $am $dt
            else
                gmm  --fmllr "$fmllr" $am $dt
            fi
        done
        echo 
    done
}

decode_dt $*

