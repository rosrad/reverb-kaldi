#!/bin/bash
. check.sh
tag=
. utils/parse_options.sh

[ ! -d ${FEAT_LOG} ] && mkdir -p ${FEAT_LOG}
# execute cmd and write to log file


echo "Executing $@"
[[ -n $tag ]] && tag=.${tag}

log=${FEAT_LOG}/$(basename $1)${tag}.log.$(date +%Y%m%d-%H:%M)
date > $log
eval $@ 2>&1 | tee -a $log
date >> $log
