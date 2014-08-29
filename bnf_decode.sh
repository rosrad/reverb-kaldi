#!/bin/bash

. check.sh


export DT_MDL="nnet2_tri2 nnet2_tri2_mc tri2_mc" 
export FEAT_TYPE=bnf
export REG=".*Phone.*dt.*"
# export TESTONLY=true
# utils/call.sh \
#     local/TestDTs.sh
utils/call.sh \
    local/TestDTs.sh






