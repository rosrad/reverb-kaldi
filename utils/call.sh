#!/bin/bash
. check.sh
[ ! -d ${LOG} ] && mkdir -p ${LOG}
echo ${DT[*]}
for cmd in $@; do
    # execute cmd and write to log file
    echo "Executing ${cmd}"
    log=${LOG}/$(basename ${cmd}).log
    date > $log
    eval ${cmd} 2>&1 | tee -a $log
    date >> $log
done
