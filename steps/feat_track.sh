
if [[ -z ${feat_type} && -f $src_dir/feat_type ]]; then
    cp $src_dir/feat_type $dest_dir 2>/dev/null # keep tracking the feat_type
    feat_type=$(cat $src_dir/feat_type)
fi

if [[ -z $lda_splice_opts && -f $src_dir/lda_splice_opts ]] ; then
	lda_splice_opts=$(cat $src_dir/lda_splice_opts 2>/dev/null)
	cp $src_dir/lda_splice_opts $dest_dir/
	[[ -n $lda_splice_opts ]] && lda_splice="splice-feats $lda_splice_opts ark:- ark:- |"
fi

if [[ -z $splice_opts && -f $src_dir/splice_opts ]] ; then
	splice_opts=$(cat $src_dir/splice_opts 2>/dev/null)
	cp $src_dir/splice_opts $dest_dir/
fi
echo ${splice_opts}

case $feat_type in
	raw) org_feats="ark,s,cs:apply-cmvn $cmvn_opts --utt2spk=ark:$sdata/JOB/utt2spk scp:$sdata/JOB/cmvn.scp scp:$sdata/JOB/feats.scp ark:- |"
		[[ -n $splice_opts ]] && org_feats=${org_feats}"splice-feats $splice_opts ark:- ark:- |"
		;;
	delta) org_feats="ark,s,cs:apply-cmvn $cmvn_opts --utt2spk=ark:$sdata/JOB/utt2spk scp:$sdata/JOB/cmvn.scp scp:$sdata/JOB/feats.scp ark:- | add-deltas ark:- ark:- |"
		[[ -n $splice_opts ]] && org_feats=${org_feats}"splice-feats $splice_opts ark:- ark:- |"
		;;
	raw-lda)
		org_feats="ark,s,cs:apply-cmvn $cmvn_opts --utt2spk=ark:$sdata/JOB/utt2spk scp:$sdata/JOB/cmvn.scp scp:$sdata/JOB/feats.scp ark:- | ${lda_splice} transform-feats $src_dir/final.mat ark:- ark:- |"
		[[ -n $splice_opts ]] && org_feats=${org_feats}"splice-feats $splice_opts ark:- ark:- |"
		cp $src_dir/final.mat $src_dir/full.mat $dest_dir    
		;;
	delta-lda)
		org_feats="ark,s,cs:apply-cmvn $cmvn_opts --utt2spk=ark:$sdata/JOB/utt2spk scp:$sdata/JOB/cmvn.scp scp:$sdata/JOB/feats.scp ark:- | ${lda_splice} transform-feats $src_dir/final.mat ark:- ark:- |"
		[[ -n $splice_opts ]] && org_feats=${org_feats}"splice-feats $splice_opts ark:- ark:- |"
		cp $src_dir/final.mat $src_dir/full.mat $dest_dir    
		;;
	*) echo "$0: invalid feature type $feat_type" && exit 1;
esac
echo ${org_feats} > $dest_dir/feat_string
