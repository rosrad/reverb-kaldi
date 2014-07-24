#!/bin/bash

dnn_model() {
    if [ $# -lt 2 ]; then
        echo "No enough parameters!"
    fi
    condition=${1:-"mc"}
    base=${2:-"tri1"}
    # this is the condition of the trainning data 
    # can be ether "cln"or "mc"

    #dnn used
    dnn="net2"
    model_dst=${base}_${dnn}_${condition}
    echo $model_dst 
}
