#!/bin/bash
. check.sh
[ ! -d ${LOG} ] && mkdir -p ${LOG}
function auto_test() {
    para=${*:-"--reg *dt* tri1 tri2 tri2_mc"}
    CMDs=(local/DecodeDTs.sh  local/WerDTs.sh)
    for cmd in ${CMDs[*]}; do
        # execute cmd and write to log file
        log=${LOG}/$(basename ${cmd}).log
        date > $log
        eval ${cmd} $para 2>&1 | tee -a $log
        date >> $log
    done
}

auto_test --reg *dt* tri1 tri2 tri2_mc
