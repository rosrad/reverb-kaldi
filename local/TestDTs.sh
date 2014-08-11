#!/bin/bash
. check.sh


function test_dt() {

    para=${*:-"--reg *dt* tri1 tri2 tri2_mc"}
    CMDs=(local/DecodeDTs.sh  local/WerDTs.sh)
    # CMDs=(local/WerDTs.sh)
    [ ! -d ${LOG} ] && mkdir -p ${LOG}
    for cmd in ${CMDs[*]}; do
        # execute cmd and write to log file
        echo "Executing ${cmd}"
        log=${LOG}/$(basename ${cmd}).log
        date > $log
        eval ${cmd} $para 2>&1 | tee -a $log
        date >> $log
    done
}

# test_dt --reg *dt* tri1 tri2 tri2_mc
test_dt --reg *dt* ${DT_MDL[*]}


