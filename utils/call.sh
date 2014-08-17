#!/bin/bash
. check.sh
[ ! -d ${FEAT_LOG} ] && mkdir -p ${FEAT_LOG}
echo ${DT[*]}
for cmd in $@; do
    # execute cmd and write to log file
    echo "Executing ${cmd}"
    log=${FEAT_LOG}/$(basename ${cmd}).log
    date > $log
    eval ${cmd} 2>&1 | tee -a $log
    date >> $log
done
