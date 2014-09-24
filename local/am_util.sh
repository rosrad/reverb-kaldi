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
function mk_uniq() {
	local mdl=$(echo $@ | cut -d'_' -f1)
	local uniq_opts=$(echo $@|awk -F'_' '{for (i=2;i<=NF;i++) print $i; }'|sort|uniq)
	printf "${mdl}\n${uniq_opts}" | tr -s \\n '_' \
		|sed 's#_*$##'|sed 's#^_*##'
}

function uniq_mdl() {
	local mdl=$1
	local uniq_opts=$(echo ${@:2:}|tr -s ' ' \\n |sort|uniq)
	printf "${mdl}\n${uniq_opts}" | tr -s \\n '_' \
		|sed 's#_*$##'|sed 's#^_*##'
}


function concat_opts() {
	echo $@|sed 's# #_#g'
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
