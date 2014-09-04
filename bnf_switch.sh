#!/bin/bash

function current() {            
    tag=
    for p in exp data param ;do
        inter_para=BNF_${p^^}
        cur_tag=$(readlink -e ${!inter_para}|awk -F'/' '{ print $NF}' |sed 's#^.*bnf_##')
        if [[ -z ${cur_tag} ]];then
            echo "BNF Parts #${p^^}# does not exist"
            return 1
        fi
        
        [[ -z ${tag} ]] && tag=${cur_tag}

        if [[ ${tag} != ${cur_tag} ]];then
            echo "BNF Parts #${p^^}# does match each other"
            return 1
        fi
        echo ${p} : ${cur_tag}
    done
    echo $tag
    return 0
}

function switchto() {
    tag=${1:-"EMPTY"}           # this tag must have the default value 
    dst_tag=
    linked=0
    for p in exp data param ;do
        inter_para=BNF_${p^^}
        cur_part=$(echo ${!inter_para}|sed 's#/*$##')
        dir=$(dirname $cur_part)
        if [[ -L ${cur_part} ]];then
            echo "Unlinking Part #${p}# : ${cur_part}"
            unlink ${cur_part}
        fi
        # fuzzy search
        # dst_tag=$(ls ${dir} | grep ${p}_bnf_${tag})
        # hard search
        dst_tag=${p}_bnf_${tag}
        if [[ -d ${dir}/${dst_tag} ]]; then
            echo "Linking Part #${p}# to ${dst_tag}"
            cwd=$(pwd)
            cd ${dir}
            ln -s ${dst_tag} $(basename ${!inter_para})
            cd ${cwd}
            linked=$[${linked}+1]
        fi
    done

    if [[ ${linked} -eq 3 ]]; then
        echo  "switch BNF to #${dst_tag/*bnf_/}#"
    else
        echo  "switch BNF to #EMPTY#"
    fi
}

function test() {
    tag=${1:-"EMPTY"}           # this tag must have the default value 
    matched=0
    # for the mdl match
    for p in exp data param ;do
        inter_para=BNF_${p^^}
        dir=$(dirname ${!inter_para})
        for part in $(ls ${dir} |grep -P ^${p}_bnf_'.*'); do
            cur_tag=$(echo ${part} | sed 's#.*bnf_##')
            [[ "$cur_tag" == "$tag" ]] && matched=$[${matched}+1]
        done
    done
    echo "Matched Number : ${matched} "
    [[ ${matched} -eq 3 ]] && return 0

    return 1
}

function switch () {
    tag=${1:-"EMPTY"}           # this tag must have the default value 
    # current || echo "Current BNF has errors"
    test ${tag} # || return 1
    switchto ${tag}
}

. check.sh
. local/am_util.sh

# switch tri2_mc  
switch $1
