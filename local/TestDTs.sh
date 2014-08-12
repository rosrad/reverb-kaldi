#!/bin/bash
. check.sh


function test_dt() {
    CMDs=(local/DecodeDTs.sh  local/WerDTs.sh)
    # CMDs=(local/WerDTs.sh)
    [ ! -d ${LOG} ] && mkdir -p ${LOG}
    for cmd in ${CMDs[*]}; do
        # execute cmd and write to log file
        echo "Executing ${cmd} $*"
        log=${LOG}/$(basename ${cmd}).log
        date > $log
        ${cmd} $* 2>&1 | tee -a $log
        date >> $log
    done
}

# test_dt --reg *dt* tri1 tri2 tri2_mc
export REG="cln*dt"
test_dt ${DT_MDL}


