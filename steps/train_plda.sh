#!/bin/bash

# Copyright 2014 Liang Lu
# Apache 2.0

# Begin configuration.
stage=-100 #  This allows restarting after partway, when something when wrong.
config=
cmd=utils/run.pl
scale_opts="--transition-scale=1.0 --acoustic-scale=0.1 --self-loop-scale=0.1"
realign_iters="10 15 20";
num_iters=25    # Number of iterations of training
max_iter_inc=18 # Last iter to increase #Gauss on.
num_iters_fagmm=6
beam=10
retry_beam=40
boost_silence=1.0 # Factor by which to boost silence likelihoods in alignment
power=0.25 # Exponent for number of gaussians according to occurrence counts
cluster_thresh=-1  # for build-tree control final bottom-up clustering of leaves
num_gselect1=50
num_gselect2=15
rand_prune=0.1 # Randomized-pruning parameter for posteriors, to speed up training.
feat=
# End configuration.

echo "$0 $@"  # Print the command line for logging

[ -f path.sh ] && . ./path.sh;
. parse_options.sh || exit 1;

if [ $# != 6 ]; then
	echo "Usage: steps/train_plda.sh  <data-dir> <lang-dir> <alignment-dir> <exp-dir>"
	echo "e.g.: steps/train_plda.sh data/train_si84_half data/lang exp/mono_ali exp/tri1"
	echo "main options (for others, see top of script file)"
	echo "  --cmd (utils/run.pl|utils/queue.pl <queue opts>) # how to run jobs."
	echo "  --config <config-file>                           # config containing options"
	echo "  --stage <stage>                                  # stage to do partial re-run from."
	exit 1;
fi

num_leaves=$1
totsubstates=$2
data=$3
lang=$4
alidir=$5
dir=$6

for f in $alidir/final.mdl $alidir/ali.1.gz $data/feats.scp $lang/phones.txt; do
	[ ! -f $f ] && echo "train_deltas.sh: no such file $f" && exit 1;
done


silphonelist=`cat $lang/phones/silence.csl` || exit 1;
oov=`cat $lang/oov.int` || exit 1;
ciphonelist=`cat $lang/phones/context_indep.csl` || exit 1;
numsubstates=$num_leaves # Initial #-substates.
incsubstates=$[($totsubstates-$numsubstates)/$max_iter_inc] # per-iter increment for #substates
nj=`cat $alidir/num_jobs` || exit 1;
mkdir -p $dir/log
echo $nj > $dir/num_jobs

sdata=$data/split$nj;
[[ -d $sdata && $data/feats.scp -ot $sdata ]] || utils/split_data.sh $data $nj || exit 1;


echo "${feat}" > $dir/feat_opt
feats=$(echo ${feat} | sed -s 's#SDATA_JOB#'${sdata}'/JOB#g')
echo "${feats}" >$dir/feat_string # keep track of feature type 

feats_one="$(echo "$feats" | sed s:JOB:1:g)"
feat_dim=$(feat-to-dim "$feats_one" -) || exit 1;

echo "feat dimension: ${feat_dim}"
rm $dir/.error 2>/dev/null

if [ $stage -le -5 ]; then
	echo "$0: doing Gaussian selection"
	$cmd JOB=1:$nj $dir/log/gselect.JOB.log \
		gmm-gselect --n=$num_gselect1 $dir/final.ubm  "$feats" \
		"ark:|gzip -c >$dir/gselect1.JOB.gz" || exit 1;

	[[ ${feat_dim} -lt 40 ]] && fa_gmm_opts="--speech-dim=${feat_dim} --state-dim=${feat_dim}"
    fa-gmm-init --binary=true  --use-full-gmm=false ${fa_gmm_opts} $dir/final.ubm $dir/final.fagmm >$dir/log/init.log 2>&1
fi

if [ $stage -le -4 ]; then

	$cmd $dir/log/init_model.log \
		plda-init  $lang/topo $dir/tree $dir/final.fagmm $dir/0.mdl  || exit 1;
	grep 'no stats' $dir/log/init_model.log && echo "This is a bad warning.";
fi

if [ $stage -le -3 ]; then
	# Convert the alignments.
	echo "$0: converting alignments from $alidir to use current tree"
	$cmd JOB=1:$nj $dir/log/convert.JOB.log \
		convert-ali $alidir/final.mdl $dir/0.mdl $dir/tree \
		"ark:gunzip -c $alidir/ali.JOB.gz|" "ark:|gzip -c >$dir/ali.JOB.gz" || exit 1;
fi

if [ $stage -le -2 ]; then
	echo "$0: compiling graphs of transcripts"
	$cmd JOB=1:$nj $dir/log/compile_graphs.JOB.log \
		compile-train-graphs $dir/tree $dir/0.mdl  $lang/L.fst  \
		"ark:utils/sym2int.pl --map-oov $oov -f 2- $lang/words.txt < $data/split$nj/JOB/text |" \
		"ark:|gzip -c >$dir/fsts.JOB.gz" || exit 1;
fi

if [ $stage -le -1 ]; then

	x=0
	while [ $x -lt $num_iters_fagmm ]; do
		echo "Pass $x"

		$cmd JOB=1:$nj $dir/log/acc_fagmm_pre.$x.JOB.log \
			fgmm-gselect --gselect="ark,s,cs:gunzip -c $dir/gselect1.JOB.gz|" --n=$num_gselect2 "fa-gmm-to-fgmm $dir/final.fagmm - |" \
			"$feats" ark:- \| \
			fa-gmm-acc-stats --binary=true $dir/final.fagmm "ark,s,cs:-" "$feats" \
			$dir/$x.JOB.acc || exit 1;

		$cmd $dir/log/update_fagmm_pre.$x.log \
			fa-gmm-est --binary=true --update-flags="Uvwb" --verbose=2 $dir/final.fagmm "fa-gmm-sum-accs - $dir/$x.*.acc |" \
			$dir/final.fagmm_new || exit 1;

		mv $dir/final.fagmm_new $dir/final.fagmm
		cp $dir/final.fagmm $dir/final.fagmm.$x
		rm $dir/$x.*.acc

		x=$[$x+1]
	done

	$cmd JOB=1:$nj $dir/log/gselect2.JOB.log \
		fgmm-gselect --gselect="ark,s,cs:gunzip -c $dir/gselect1.JOB.gz|" --n=$num_gselect2 "fa-gmm-to-fgmm $dir/final.fagmm - |" \
        "$feats" "ark:|gzip -c >$dir/gselect.JOB.gz" || exit 1;

fi

x=0
while [ $x -lt $num_iters ]; do

	if echo $realign_iters | grep -w $x >/dev/null; then
		echo "$0: aligning data"
		#      mdl="gmm-boost-silence --boost=$boost_silence `cat $lang/phones/optional_silence.csl` $dir/$x.mdl - |"
		$cmd JOB=1:$nj $dir/log/align.$x.JOB.log \
			plda-align-compiled $scale_opts --beam=$beam --retry-beam=$[$beam*4] $dir/$x.mdl \
			"ark:gunzip -c $dir/fsts.JOB.gz|" "$feats" "ark,s,cs:gunzip -c $dir/gselect.JOB.gz|" \
			"ark,t:|gzip -c >$dir/ali.JOB.gz" \
			|| exit 1;
	fi

	if [ $x -eq 0 ]; then
		flags="z"
	else
		flags="UvwbGzt"
	fi


	echo "$0: training pass $x"
    $cmd JOB=1:$nj $dir/log/acc.$x.JOB.log \
		plda-acc-stats-ali --binary=true --update-flags=$flags --rand-prune=$rand_prune $dir/$x.mdl "$feats" \
		"ark,s,cs:gunzip -c $dir/gselect.JOB.gz|" "ark:gunzip -c $dir/ali.JOB.gz|"  $dir/$x.JOB.acc || exit 1;

    $cmd $dir/log/update.$x.log \
		plda-est --verbose=2 --binary=true --min-gaussian-occupancy=2.0 --update-flags=$flags --split-substates=$numsubstates \
		--power=$power  --write-occs=$dir/$[$x+1].occs $dir/$x.mdl \
		"plda-sum-accs - $dir/$x.*.acc |" $dir/$[$x+1].mdl || exit 1;
	
	if [ $x -lt $max_iter_inc ]; then
		numsubstates=$[$numsubstates+$incsubstates]
	fi
	
	rm $dir/$x.mdl $dir/$x.occs $dir/$x.*.acc
	x=$[$x+1];
	
done

rm $dir/final.mdl 2>/dev/null
ln -s $x.mdl $dir/final.mdl
ln -s $x.occs $dir/final.occs

# Summarize warning messages...
utils/summarize_warnings.pl  $dir/log

echo "$0: Done training system with delta+delta-delta features in $dir"

