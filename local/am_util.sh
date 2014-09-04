#!/bin/bash

function baseam(){
    echo $(basename $1) | awk -F'_' '{print $1}'
}

function trans_opts(){
    echo $(basename $1) \
        |awk -F'_' '{sep="" ;for(i=2;i<=NF;i++) { if (i==NF && ($i=="mc" || $i == "ali")) continue ; printf "%s%s", sep, $i; sep="_"} printf "\n"}' 
}

function clean_opts() {
    echo $1|sed 's#_*$##'|sed 's#^_*##'
}

function opts2mdl() {
    echo ${1}_${2}|sed 's#_$##'
}

function ali2mdl() {
    opts2mdl  ${1} $(trans_opts $2)
}

function mc () {
    echo $(basename $1) | sed  's#\(.*\)_mc$##'
}

function warn_run() {
    cmd="$@"
    echo ${cmd}
    ${cmd}
}
