#!/bin/bash
. check.sh
[ ! -d ${LOG} ] && mkdir -p ${LOG}
function test_dt() {
    para=${*:-"--reg *dt* tri1 tri2 tri2_mc"}
    CMDs=(local/DecodeDTs.sh  local/WerDTs.sh)
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
test_dt --reg *dt* nnet2_tri1 nnet2_tri1_mc nnet2_tri2 nnet2_tri2_mc


