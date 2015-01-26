#!/bin/bash

# Copyright 2012  Johns Hopkins University (Author: Daniel Povey)
# Apache 2.0

# Begin configuration section.  
transform_dir=
iter=
model= # You can specify the model to use (e.g. if you want to use the .alimdl)
nj=4
cmd=utils/run.pl
max_active=7000
beam=13.0
latbeam=6.0
acwt=0.083333 # note: only really affects pruning (scoring is on lattices).
min_lmwt=6
max_lmwt=20
stage=-2
feat=
# End configuration section.

echo "$0 $@"  # Print the command line for logging

[ -f ./path.sh ] && . ./path.sh; # source the path.
. parse_options.sh || exit 1;

if [ $# != 3 ]; then
	echo "Usage: steps/decode_fagmm.sh [options] <graph-dir> <data-dir> <decode-dir>"
	echo "... where <decode-dir> is assumed to be a sub-directory of the directory"
	echo " where the model is."
	echo "e.g.: steps/decode.sh_fagmm exp/mono/graph_tgpr data/test_dev93 ubm  exp/mono/decode_dev93_tgpr"
	echo ""
	echo "This script works on CMN + (delta+delta-delta | LDA+MLLT) features; it works out"
	echo "what type of features you used (assuming it's one of these two)"
	echo ""
	echo "main options (for others, see top of script file)"
	echo "  --config <config-file>                           # config containing options"
	echo "  --nj <nj>                                        # number of parallel jobs"
	echo "  --iter <iter>                                    # Iteration of model to test."
	echo "  --model <model>                                  # which model to use (e.g. to"
	echo "                                                   # specify the final.alimdl)"
	echo "  --cmd (utils/run.pl|utils/queue.pl <queue opts>) # how to run jobs."
	echo "  --transform-dir <trans-dir>                      # dir to find fMLLR transforms "
	echo "  --acwt <float>                                   # acoustic scale used for lattice generation "
	echo "  --min-lmwt <int>                                 # minumum LM-weight for lattice rescoring "
	echo "  --max-lmwt <int>                                 # maximum LM-weight for lattice rescoring "
	echo "                                                   # speaker-adapted decoding"
	echo "  --stage <stage>                                  # stage to do partial re-run from."
	exit 1;
fi


graphdir=$1
data=$2
dir=$3
srcdir=`dirname $dir`; # The model directory is one level up from decoding directory.
sdata=$data/split$nj;

echo "$0 $@" > $dir/cmd

mkdir -p $dir/log
[[ -d $sdata && $data/feats.scp -ot $sdata ]] || utils/split_data.sh $data $nj || exit 1;
echo $nj > $dir/num_jobs

if [ -z "$model" ]; then # if --model <mdl> was not specified on the command line...
	if [ -z $iter ]; then model=$srcdir/final.mdl; 
	else model=$srcdir/$iter.mdl; fi
fi

for f in $sdata/1/feats.scp $sdata/1/cmvn_*.scp $model $graphdir/HCLG.fst; do
	[ ! -f $f ] && echo "decode.sh: no such file $f" && exit 1;
done

echo "${feat}" > $dir/feat_opt
feats=$(echo ${feat} | sed -s 's#SDATA_JOB#'${sdata}'/JOB#g')
echo "${feats}" >$dir/feat_string # keep track of feature type 


feats_one="$(echo "$feats" | sed s:JOB:1:g)"
feat_dim=$(feat-to-dim "$feats_one" -) || exit 1;

echo "feat dimension: ${feat_dim}"

if [ $stage -le -1 ]; then
	echo "$0: doing Gaussian selection"
	fa-gmm-to-fgmm $srcdir/final.fagmm $srcdir/final.ubm > $dir/log/ubm.log 2>&1

	$cmd JOB=1:$nj $dir/log/gselect1.JOB.log \
		gmm-gselect --n=50 "fgmm-global-to-gmm $srcdir/final.ubm - |" "$feats" \
		"ark:|gzip -c >$dir/gselect1.JOB.gz" || exit 1;

	$cmd JOB=1:$nj $dir/log/gselect2.JOB.log \
		fgmm-gselect --gselect="ark,s,cs:gunzip -c $dir/gselect1.JOB.gz|" --n=15 $srcdir/final.ubm \
        "$feats" "ark:|gzip -c >$dir/gselect.JOB.gz" || exit 1;
fi

$cmd JOB=1:$nj $dir/log/decode.JOB.log \
	plda-latgen-faster --max-active=$max_active --beam=$beam --lattice-beam=$latbeam \
	--acoustic-scale=$acwt --allow-partial=true --word-symbol-table=$graphdir/words.txt \
	$model $graphdir/HCLG.fst "$feats" "ark,s,cs:gunzip -c $dir/gselect.JOB.gz|" "ark:|gzip -c > $dir/lat.JOB.gz" || exit 1; # "ark,s,cs:gunzip -c $dir/gselect.JOB.gz|"

[ ! -x local/score.sh ] && \
	echo "Not scoring because local/score.sh does not exist or not executable." && exit 1;
local/score.sh --cmd "$cmd" --min_lmwt $min_lmwt --max_lmwt $max_lmwt $data $graphdir $dir

exit 0;
