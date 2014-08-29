#!/bin/bash

function baseam(){
    echo $(basename $1) | awk -F'_' '{print $1}'
}

function trans_opts(){
    echo $(basename $1) | cut -d '_' -f2- |sed 's#_mc$##'|sed 's#_ali$##'
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

