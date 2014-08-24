#!/bin/bash
. check.sh


function test_dt() {
    CMDs=(local/DecodeDTs.sh  local/WerDTs.sh)
    [[ -n $TESTONLY ]] && CMDs=(local/WerDTs.sh)

    for cmd in ${CMDs[*]}; do
        echo "##########  $cmd $@ ${DT_MDL}"
        utils/call.sh \
            $cmd $@ ${DT_MDL}
    done
}

# test_dt --reg *dt* tri1 tri2 tri2_mc
# export REG=".*Phone_.*"

test_dt $@ 


