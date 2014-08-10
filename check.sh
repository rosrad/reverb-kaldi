#!/bin/bash

# export script_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
config=config
if [ ! -e ${config}/path.sh ] || [ ! -e ${config}/corpus.sh ]; then
    echo "ERROR: path.sh and/or corpus.sh not found"
    echo "You need to create these from {path,corpus}.sh.default to match your system"
    echo "Make sure you follow the instructions in README.txt"
    exit 1
fi
echo 
. ${config}/corpus.sh
. ${config}/path.sh
. ${config}/para.sh

