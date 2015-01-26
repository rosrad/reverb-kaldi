#!/bin/bash
# Copyright 2012  Johns Hopkins University (Author: Daniel Povey)
# Apache 2.0

# Computes training alignments using a model with delta or
# LDA+MLLT features.

# If you supply the "--use-graphs true" option, it will use the training
# graphs from the source directory (where the model is).  In this
# case the number of jobs must match with the source directory.


# Begin configuration section.  
nj=4
cmd=utils/run.pl
use_graphs=false
# Begin configuration.
scale_opts="--transition-scale=1.0 --acoustic-scale=0.1 --self-loop-scale=0.1"
beam=10
retry_beam=40
boost_silence=1.0 # Factor by which to boost silence during alignment.
feat=
# End configuration options.

echo "$0 $@"  # Print the command line for logging

. parse_options.sh || exit 1;

if [ $# != 4 ]; then
    echo "usage: steps/align_si.sh <data-dir> <lang-dir> <src-dir> <align-dir>"
    echo "e.g.:  steps/align_si.sh data/train data/lang exp/tri1 exp/tri1_ali"
    echo "main options (for others, see top of script file)"
    echo "  --config <config-file>                           # config containing options"
    echo "  --nj <nj>                                        # number of parallel jobs"
    echo "  --use-graphs true                                # use graphs in src-dir"
    echo "  --cmd (utils/run.pl|utils/queue.pl <queue opts>) # how to run jobs."
    exit 1;
fi

data=$1
lang=$2
srcdir=$3
dir=$4


oov=`cat $lang/oov.int` || exit 1;
mkdir -p $dir/log
echo $nj > $dir/num_jobs
sdata=$data/split$nj
splice_opts=`cat $srcdir/splice_opts 2>/dev/null` # frame-splicing options.
cp $srcdir/splice_opts $dir 2>/dev/null # frame-splicing options.
cmvn_opts=`cat $srcdir/cmvn_opts 2>/dev/null`
cp $srcdir/cmvn_opts $dir 2>/dev/null # cmn/cmvn option.

[[ -d $sdata && $data/feats.scp -ot $sdata ]] || utils/split_data.sh $data $nj || exit 1;

cp $srcdir/{tree,final.mdl} $dir || exit 1;
cp $srcdir/final.occs $dir;

echo "${feat}" > $dir/feat_opt
feats=$(echo ${feat} | sed -s 's#SDATA_JOB#'${sdata}'/JOB#g')
echo "${feats}" >$dir/feat_string # keep track of feature type 

echo "$0: aligning data in $data using model from $srcdir, putting alignments in $dir"

mdl="gmm-boost-silence --boost=$boost_silence `cat $lang/phones/optional_silence.csl` $dir/final.mdl - |"

if $use_graphs; then 
    [ $nj != "`cat $srcdir/num_jobs`" ] && echo "$0: mismatch in num-jobs" && exit 1;
    [ ! -f $srcdir/fsts.1.gz ] && echo "$0: no such file $srcdir/fsts.1.gz" && exit 1;

    $cmd JOB=1:$nj $dir/log/align.JOB.log \
        gmm-align-compiled $scale_opts --beam=$beam --retry-beam=$retry_beam "$mdl" \
        "ark:gunzip -c $srcdir/fsts.JOB.gz|" "$feats" "ark:|gzip -c >$dir/ali.JOB.gz" || exit 1;
else
    tra="ark:utils/sym2int.pl --map-oov $oov -f 2- $lang/words.txt $sdata/JOB/text|";
    # We could just use gmm-align in the next line, but it's less efficient as it compiles the
    # training graphs one by one.
    $cmd JOB=1:$nj $dir/log/align.JOB.log \
        compile-train-graphs $dir/tree $dir/final.mdl  $lang/L.fst "$tra" ark:- \| \
        gmm-align-compiled $scale_opts --beam=$beam --retry-beam=$retry_beam "$mdl" ark:- \
        "$feats" "ark,t:|gzip -c >$dir/ali.JOB.gz" || exit 1;
fi

echo "$0: done aligning data."
