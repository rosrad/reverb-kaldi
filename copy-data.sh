#!/bin/sh

set=REVERB_REAL_dt
src=${1-""}
dst=${2-""}
# if [[ -z $src || -z $dst ]] ;then
#     echo "src or dst is empty"
#     exit
# fi

for d in `find ${src}/feats/mfcc/normal/data/${set}/* -maxdepth 1 -type d`; do
    dir=${d/$src/$dst}
    for f in spk2utt utt2spk; do
        echo "$d/${f}==> $dir/"
        cp $d/${f} $dir/
    done
    find ${dir} -type d -iname "split*" |xargs rm -fr
done
