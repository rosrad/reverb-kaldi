#!/bin/bash
dir=${1-""}

if [[ -z $dir ]] ;then
    echo "dst is empty"
    exit
fi
src=/home/14/ren/rev_kaldi/tmp/exp/mfcc/normal/ALIGN/
dst=${dir}/exp/mfcc/normal/ALIGN/
mkdir -p $dst
aligns=("GMM.mono" "GMM.tri1.cmn" "GMM.tri1.cmvn", "DNN.tri1.cmn" "DNN.tri1.cmvn")
for a in ${aligns[*]} ;do
    echo "ln -s $src/$a $dst/$a"
    ln -s $src/$a $dst/$a
done

# echo "link shared task list"
# echo "ln -s /home/14/ren/rev_kaldi/task-units/share ${dir}/task/list/share"
# ln -s /home/14/ren/rev_kaldi/task-units/share ${dir}/task/list/share
