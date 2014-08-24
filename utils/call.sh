#!/bin/bash
. check.sh
[ ! -d ${FEAT_LOG} ] && mkdir -p ${FEAT_LOG}
# execute cmd and write to log file
echo "Executing $@"
log=${FEAT_LOG}/$(basename $0).log.$(date +%Y%m%d-%H:%M)
date > $log
eval $@ 2>&1 | tee -a $log
date >> $log
