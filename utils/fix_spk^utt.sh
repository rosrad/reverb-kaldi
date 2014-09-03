#!/bin/bash
spk2utt=$1
dir=$(dirname $1)
echo Fix path :$dir

for f in spk2utt utt2spk; do
    if  [[ ! -f $dir/${f}.bak ]]; then
        echo backup $f
        cp $dir/${f}  $dir/${f}.bak
    fi
done

cat $dir/spk2utt |awk '{print substr($1,0,3),$2}' >$dir/spk2utt.new
utils/spk2utt_to_utt2spk.pl $dir/spk2utt.new >  $dir/utt2spk.new


for f in spk2utt utt2spk; do
    echo ${f} total lines $(cat $dir/${f}.new |wc -l)
    head -n3 $dir/${f}.new
    echo mv ${f}.new ${f}
    mv $dir/${f}.new  $dir/${f}
done

    
