#!/bin/bash
# Copyright 2012  Johns Hopkins University (Author: Daniel Povey).  Apache 2.0.

# This trains a UBM (i.e. a mixture of Gaussians), by clustering
# the Gaussians from a trained HMM/GMM system and then doing a few
# iterations of UBM training.
# We mostly use this for SGMM systems.

# Begin configuration section.
nj=4
cmd=run.pl
silence_weight=  # You can set it to e.g. 0.0, to weight down silence in training.
stage=-2
num_gselect1=50 # first stage of Gaussian-selection
num_gselect2=25 # second stage.
intermediate_num_gauss=2000
num_iters=4
no_fmllr=false
feat_type=
#splice_opts2="--left-context=1 --right-context=1"

# End configuration section.

echo "$0 $@"  # Print the command line for logging
. check.sh
. utils/parse_options.sh

if [ $# != 5 ]; then
    echo "Usage: steps/train_ubm.sh <num-gauss> <data> <lang> <ali-dir> <exp>"
    echo " e.g.: steps/train_ubm.sh 400 data/train_si84 data/lang exp/tri2b_ali_si84 exp/ubm3c"
    echo "main options (for others, see top of script file)"
    echo "  --config <config-file>                           # config containing options"
    echo "  --cmd (utils/run.pl|utils/queue.pl <queue opts>) # how to run jobs."
    echo "  --silence-weight <sil-weight>                    # weight for silence (e.g. 0.5 or 0.0)"
    echo "  --num-iters <#iters>                             # Number of iterations of E-M"\
  echo "  --no-fmllr (true|false)                          # ignore speaker matrices even if present"
    exit 1;
fi

num_gauss=$1
data=$2
lang=$3
alidir=$4
dir=$5

for f in $data/feats.scp $lang/L.fst $alidir/ali.1.gz $alidir/final.mdl; do
    [ ! -f $f ] && echo "No such file $f" && exit 1;
done

if [ $[$num_gauss*2] -gt $intermediate_num_gauss ]; then
    echo "intermediate_num_gauss was too small $intermediate_num_gauss"
    intermediate_num_gauss=$[$num_gauss*2];
    echo "setting it to $intermediate_num_gauss"
fi


# Set various variables.
silphonelist=`cat $lang/phones/silence.csl` || exit 1;
nj=`cat $alidir/num_jobs` || exit 1;

mkdir -p $dir/log
echo $nj > $dir/num_jobs
sdata=$data/split$nj;
[[ -d $sdata && $data/feats.scp -ot $sdata ]] || split_data.sh $data $nj || exit 1;
splice_opts=$(cat $alidir/splice_opts 2>/dev/null) # frame-splicing options.
cp $alidir/splice_opts $dir

cmvn_opts=$(cat $alidir/cmvn_opts 2>/dev/null)
cp $alidir/cmvn_opts $dir 2>/dev/null


# for tracking the feat-type
# call it like a function , because bash can not return string ,we do like this
src_dir=$alidir
dest_dir=$dir
. steps/feat_track.sh
feats=$org_feats
echo "$0: feature type is $feat_type"

# feats="ark,s,cs:apply-cmvn $cmvn_opts --utt2spk=ark:$sdata/JOB/utt2spk scp:$sdata/JOB/cmvn.scp scp:$sdata/JOB/feats.scp ark:- | add-deltas ark:- ark:- |"
# [[ -n ${splice_opts} ]] && feats = ${feats}" splice-feats $splice_opts ark:- ark:- |"


if [ $stage -le -2 ]; then
    echo "$0: clustering model $alidir/final.mdl to get initial UBM"
    $cmd $dir/log/cluster.log \
        init-ubm --intermediate-num-gauss=$intermediate_num_gauss --ubm-num-gauss=$num_gauss \
        --verbose=2 --fullcov-ubm=false $alidir/final.mdl $alidir/final.occs \
        $dir/0.ubm   || exit 1;
fi

# Do initial phase of Gaussian selection and save it to disk -- later on we'll
# do more Gaussian selection to further prune, as the model changes.


if [ $stage -le -1 ]; then
    echo "$0: doing Gaussian selection"
    $cmd JOB=1:$nj $dir/log/gselect.JOB.log \
        gmm-gselect --n=$num_gselect1 $dir/0.ubm "$feats" \
        "ark:|gzip -c >$dir/gselect.JOB.gz" || exit 1;
fi


x=0
while [ $x -lt $num_iters ]; do
    echo "Pass $x"
    $cmd JOB=1:$nj $dir/log/acc.$x.JOB.log \
        gmm-global-acc-stats "--gselect=ark,s,cs:gunzip -c $dir/gselect.JOB.gz|" $dir/$x.ubm "$feats" \
        $dir/$x.JOB.acc || exit 1;
    lowcount_opt="--remove-low-count-gaussians=false"
    [ $[$x+1] -eq $num_iters ] && lowcount_opt=   # Only remove low-count Gaussians 
    # on last iter-- we can't do it earlier, or the Gaussian-selection info would
    # be mismatched.
    $cmd $dir/log/update.$x.log \
        gmm-global-est $lowcount_opt --verbose=2 $dir/$x.ubm "gmm-global-sum-accs - $dir/$x.*.acc |" \
        $dir/$[$x+1].ubm || exit 1;
    rm $dir/$x.*.acc $dir/$x.ubm
    x=$[$x+1]
done

rm $dir/gselect.*.gz
rm $dir/final.ubm 2>/dev/null
mv $dir/$x.ubm $dir/final.ubm || exit 1;
