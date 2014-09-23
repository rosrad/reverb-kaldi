#!/bin/bash
function fmllr(){
	mdl=gmm_mc
	type=train					# or test
	. utils/parse_options.sh
	src_dir=$1

	src_file=$(basename ${src_dir})
	local tag="${FMLLR_PREFIX}_${mdl}_${src_file}"
    [[ ! -d "$(pwd)/${src_dir}" ]] && (echo "Error: Source data dir does not exist!"; echo "Src :${src_dir}") && return
	local target_set=${FEAT_DATA}/${FMLLR_TARGET}/${tag}
	[[ ! -d ${target_set} ]] && warn_run mkdir -p ${target_set}


	local transform_dir=${FEAT_EXP}/${mdl}_fmllr_ali
	[[ ${type/train/} == ${type} ]] && transform_dir=${FEAT_EXP}/${mdl}/decode_fmllr#${src_file}

	if [[ ! -d ${transform_dir} ]]; then
		echo "ERROR: no transform dir :${transform_dir}"
		return 1
	fi

	local opts=()
	steps/nnet/make_fmllr_feats.sh  \
		--transform-dir $transform_dir \
		${target_set} \
		${src_dir} \
		${FEAT_EXP}/${mdl} \
		${FEAT_LOG}/make_feats/${FMLLR_TARGET}/${tag} \
		${FEAT_MDL_PARAM}/${FMLLR_TARGET}/${tag}
	# make the cmvn 
	steps/compute_cmvn_stats.sh ${target_set} \
		${FEAT_LOG}/make_fmllr_feats/${FMLLR_TARGET}/${tag} \
		${FEAT_MDL_PARAM}/${FMLLR_TARGET}/${tag}
}

function mk_all(){
	mdl=${1} 			# this should not be a clean model

	[[ -z ${mdl} ]] && mdl=${DEFAULT_FMLLR_GMM}
	[[ -n ${mdl} ]] && options="--mdl ${mdl}"

	
	echo "Making fMLLR features "
	# make fmllr of and multi-conditon train set
	warn_run fmllr "${options}" --type "train" ${TR_MC}
	# make fmllr of dev set
    for d in  $(find ${FEAT_DATA}/ -maxdepth 2 -xtype d |grep -P ${FEAT_DATA}'/([A-Z]+_){1,}dt/' |grep -v "FMLLR" | grep -v "GLOBAL"|sort) ; do
		fmllr ${options} --type "dev" ${d}
    done
}




export FEAT_TYPE=mfcc
export FMLLR_TYPE=raw
. check.sh
. local/am_util.sh
mk_all
