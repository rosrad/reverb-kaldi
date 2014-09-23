#!/bin/bash

function alignment() {
    fmllr=
	opts=
    . utils/parse_options.sh
    if [ $# -lt 1 ]; then
        echo "Error: no enough paramaters!"
        echo "Usage: alignment gmm"
        exit 1;
    fi
    local mdl=$1
    local tr_dir=$2
    local dst_ali=${mdl}_ali
    local ali_script="align_si.sh"
	local options=

	if [[ ${fmllr} == "raw" ]] ;then
        ali_script="align_raw_fmllr.sh"
        dst_ali=${mdl}_raw_fmllr_ali
		options="--use-graphs true"
    elif [[ -n $fmllr ]]; then
        ali_script="align_fmllr.sh"
        dst_ali=${mdl}_fmllr_ali
    fi        

	if [ ! -e ${dst_ali}/ali.1.gz ]; then
		steps/${ali_script} --nj $nj_decode ${opts} ${@:3} \
			$tr_dir ${DATA}/lang ${mdl} ${dst_ali} || exit 1;
	fi
	echo ${dst_ali}
}

function mkgraph() {
    if [ $# -lt 1 ]; then
        Echo "Error: no enough paramaters!"
        echo "Usage: mkgraph gmm"
        exit 1;
    fi
    mdl=$1
    echo "### Make Graph of MDL ${mdl} "
    utils/mkgraph.sh ${@:2} ${DATA}/lang_test_bg_5k ${mdl} ${mdl}/graph_bg_5k
}

# Train monophone model on clean data (si_tr).
function mono(){
    mdl=${MFCC_EXP}/mono
    steps/train_mono.sh --boost-silence 1.25 --nj $nj_train \
        $TR_CLN ${DATA}/lang ${mdl} || exit 1;
    mkgraph  ${mdl} --mono
    alignment ${mdl} $TR_CLN --boost-silence 1.25
}

# Create first triphone recognizer.
function tri1_phone() {
    cond=
    . utils/parse_options.sh
    mdl=${MFCC_EXP}/tri1
    ali=${MFCC_EXP}/mono_ali
    tr_dir=$TR_CLN
    if [ "$cond" == "mc" ]; then
        tr_dir=$TR_MC
        mdl=${mdl}_mc
    fi

    steps/train_deltas.sh --boost-silence 1.25 \
        2000 10000 $tr_dir ${DATA}/lang ${ali} ${mdl} || exit 1;
    mkgraph ${mdl}
    alignment ${mdl} $tr_dir
}

# The following code trains and evaluates a delta feature recognizer, which is similar to the HTK
# baseline (but using per-utterance basis fMLLR instead of batch MLLR). This is for reference only.

function gmm() {
    cond=
	feat=
    . utils/parse_options.sh
	if [[ -n $feat ]];then
		tr_opts="--feat_type ${feat}"
		opts="${feat}"
	fi

	local mdl_dir=${FEAT_EXP}/$(mk_uniq $(concat_opts gmm ${opts}))	
	echo "MDL ${mdl_dir}"
	local tr_dir=$TR_CLN
    local ali=${MFCC_EXP}/tri1_ali	# we are only using the mfcc exp for triphone gmm
    if [ "$cond" == "mc" ]; then
        tr_dir=$TR_MC
        mdl_dir=${mdl_dir}_mc
    fi

    steps/train_deltas.sh ${tr_opts} \
        2500 15000 \
		$tr_dir ${DATA}/lang $ali ${mdl_dir} \
		|| exit 1;

    mkgraph  ${mdl_dir}
}

function gmm_splice() {
	cond=
    fmllr=
    ali=gmm
    . utils/parse_options.sh
    mdl_dir=${FEAT_EXP}/$(opts2mdl ${ali} splice)
    ali_src=${FEAT_EXP}/${ali}
    tr_dir=$TR_CLN
    if [ "$cond" == "mc" ]; then
        tr_dir=$TR_MC
        mdl_dir=${mdl_dir}_mc
        ali_src=${FEAT_EXP}/$(opts2mdl ${ali} mc)
	fi
	[[ -n $fmllr ]] && ali_opt="--fmllr $fmllr"
    alignment ${ali_opt} ${ali_src} ${tr_dir}
    local ali_dir=$(alignment ${ali_opt} ${ali_src} ${tr_dir})
	steps/train_splice.sh \
		--splice-opts "--left-context=2 --right-context=2" \
		1200 10000  \
		$tr_dir ${DATA}/lang ${ali_dir} ${mdl_dir} \
		|| return 1

    mkgraph  ${mdl_dir}
}

function ubm() {
	cond=
    ali=gmm_splice
	opts=
    . utils/parse_options.sh

	option=()
	if [[ ${opts/fmllr/} != ${opts} || ${ali/fmllr/} != ${ali} ]];then
		option+=("fmllr")
		fmllr="fmllr"
	fi
	if [[ ${opts/raw/} != ${opts} || ${ali/raw/} != ${ali} ]];then
		option+=("raw")
		raw="raw"
	fi

	local mdl_dir=${FEAT_EXP}/$(mk_uniq $(concat_opts $(ali2mdl ubm ${ali}) ${option[@]}))
	echo $mdl_dir
    local ali_src=${FEAT_EXP}/${ali}
    local tr_dir=$TR_CLN
    if [ "$cond" == "mc" ]; then
        tr_dir=$TR_MC
        mdl_dir=${mdl_dir}_mc
        ali_src=${FEAT_EXP}/$(opts2mdl ${ali} mc)
	fi
    
	local ali_opts=
	[[ -n ${fmllr} ]] && ali_opts="--fmllr ${fmllr}"
    alignment $ali_opts $ali_src $tr_dir
    local ali_dir=$(alignment $ali_opts $ali_src $tr_dir)

	if [[ -n ${fmllr} ]]; then
		fmllr_tr_mc $(concat_opts gmm ${raw} mc)
		tr_dir=${FMLLR_TR_MC}
	fi

	steps/train_ubm_splice.sh  ${tr_opts}\
		100 \
		$tr_dir ${DATA}/lang ${ali_dir} ${mdl_dir} \
		|| return 1
    # mkgraph  ${mdl_dir}
}

function plda() {
	cond=
    ali=gmm
	ubm=ubm
	opts=
    . utils/parse_options.sh

	option=()
	if [[ ${opts/fmllr/} != ${opts} || ${ali/fmllr/} != ${ali} ]];then
		option+=("fmllr")
		fmllr="fmllr"
	fi
	if [[ ${opts/raw/} != ${opts} || ${ali/raw/} != ${ali} ]];then
		option+=("raw")
		raw="raw"
	fi

	local mdl_dir=${FEAT_EXP}/$(mk_uniq $(concat_opts $(ali2mdl plda ${ali}) ${option[@]}))
    local ali_src=${FEAT_EXP}/${ali}
    local tr_dir=$TR_CLN
	local ubm_dir=${FEAT_EXP}/${ubm}
    if [ "$cond" == "mc" ]; then
        tr_dir=$TR_MC
        mdl_dir=${mdl_dir}_mc
        ali_src=${FEAT_EXP}/$(opts2mdl ${ali} mc)
		ubm_dir=${FEAT_EXP}/$(opts2mdl ${ubm} mc)
	fi

	local ali_opts=
	[[ -n ${fmllr} ]] && ali_opts="--fmllr ${fmllr}"
    alignment $ali_opts $ali_src $tr_dir
    local ali_dir=$(alignment $ali_opts $ali_src $tr_dir)

	if [[ -n ${fmllr} ]]; then
		fmllr_tr_mc $(concat_opts gmm ${raw} mc)
		tr_dir=${FMLLR_TR_MC}
	fi

	# we need to copy  finial.ubm and tree to the plda model dir
	[[ ! -d ${mdl_dir} ]] && mkdir -p ${mdl_dir} 
	for f in final.ubm splice_opts cmvn_opts; do
		cp $ubm_dir/${f} ${mdl_dir}/
	done
	cp $ali_src/tree ${mdl_dir}/

	steps/train_plda.sh ${tr_opts} \
		2400 20000  \
		$tr_dir ${DATA}/lang ${ali_dir} ${mdl_dir} \
		|| return 1

    mkgraph  ${mdl_dir}
}


function sat() {
    cond=
    fmllr=
    ali=gmm
    . utils/parse_options.sh
	local opts="${ali}"
	[[ ${fmllr/raw/} != $fmllr ]] && opts+=" raw"
    local mdl_dir=${FEAT_EXP}/$(concat_opts ${opts} sat)
    local ali_src=${FEAT_EXP}/${ali}
	local tr_dir=$TR_CLN
    if [ "$cond" == "mc" ]; then
        tr_dir=$TR_MC
        mdl_dir=${mdl_dir}_mc
        ali_src=${FEAT_EXP}/$(opts2mdl ${ali} mc)
    fi
    alignment --fmllr "$fmllr" ${ali_src} ${tr_dir}
    local ali_dir=$(alignment --fmllr "$fmllr" ${ali_src} ${tr_dir})

	local script="train_sat.sh"
	[[ ${fmllr/raw/} != $fmllr ]] && script="train_raw_sat.sh"
	steps/${script} \
        2500 15000 $tr_dir ${DATA}/lang ${ali_dir} ${mdl_dir} || exit 1;
    mkgraph ${mdl_dir}
}

function lda() {
    cond=
    ali=gmm
	opts=
    . utils/parse_options.sh
	local option=()
	if [[ ${opts/fmllr/} != ${opts} ]];then
		option+=("fmllr")
		local fmllr="fmllr"
	fi

	local mdl_dir=${FEAT_EXP}/$(mk_uniq $(concat_opts ${ali} lda ${option[@]}))
    echo mdl_dir ${mdl_dir}
    local ali_src=${FEAT_EXP}/${ali}
    local tr_dir=$TR_CLN
    if [ "$cond" == "mc" ]; then
        tr_dir=$TR_MC
        mdl_dir=${mdl_dir}_mc
        ali_src=${ali_src}_mc
	fi
	[[ -n ${fmllr} ]] && ali_opts="--fmllr ${fmllr}"

    alignment $ali_opts $ali_src $tr_dir
    local ali_dir=$(alignment $ali_opts $ali_src $tr_dir)

	if [[ -n ${fmllr} ]] ;then
		fmllr_tr_mc $(basename ${ali_src})
		tr_dir=${FMLLR_TR_MC}
	fi

    [[ ${context_size} != 0 ]] && splice_opts="--left-context=$context_size --right-context=$context_size"
    
	steps/train_lda_mllt.sh \
        --splice-opts "${splice_opts}" \
        2500 15000 $tr_dir ${DATA}/lang ${ali_dir} ${mdl_dir} || exit 1;
	mkgraph  ${mdl_dir}
}

function nnet2() {
    cond=
    ali=gmm
	opts=
    . utils/parse_options.sh

	option=()
	if [[ ${opts/fmllr/} != ${opts} || ${ali/fmllr/} != ${ali} ]];then
		option+=("fmllr")
		fmllr="fmllr"
	fi
	if [[ ${opts/raw/} != ${opts} || ${ali/raw/} != ${ali} ]];then
		option+=("raw")
		raw="raw"
	fi

	
	local mdl_dir=${FEAT_EXP}/$(mk_uniq $(concat_opts $(ali2mdl nnet2 ${ali}) ${option[@]}))
	local ali_src=${FEAT_EXP}/${ali}
	local tr_dir=$TR_CLN
    if [ "$cond" == "mc" ]; then
        tr_dir=$TR_MC
        mdl_dir=${mdl_dir}_mc
        ali_src=${FEAT_EXP}/${ali}_mc
    fi
    
	local ali_opts=
	[[ -n ${fmllr} ]] && ali_opts="--fmllr ${fmllr}"
    alignment $ali_opts $ali_src $tr_dir
    ali_dir=$(alignment $ali_opts $ali_src $tr_dir)

	if [[ -n ${fmllr} ]]; then
		fmllr_tr_mc $(concat_opts gmm ${raw} mc)
		tr_dir=${FMLLR_TR_MC}
	fi
    dnn_extra_opts="--num_epochs 20 --num-epochs-extra 10 --add-layers-period 1 --shrink-interval 3"
	# --num-threads 1 \
    steps/nnet2/train_tanh.sh --mix-up 5000 --initial-learning-rate 0.015 \
		--final-learning-rate 0.002 --num-hidden-layers 2  \
        --num-jobs-nnet "$nj_train" "${dnn_train_extra_opts[@]}" \
        ${tr_dir} ${DATA}/lang ${ali_dir} ${mdl_dir}
    mkgraph ${mdl_dir}

}

function bottleneck_dnn() {
    cond=
    ali=gmm
    stage=-100
	minibatch=512
	tag=
    . utils/parse_options.sh
    mdl_dir=${BNF_MDL_EXP}/${ali}
    ali_src=${FEAT_EXP}/${ali} 
    tr_dir=$TR_CLN
    if [ "$cond" == "mc" ]; then
        mdl_dir=${BNF_MDL_EXP}/$(opts2mdl ${ali} mc)
        ali_src=${FEAT_EXP}/$(opts2mdl ${ali} mc) 
        tr_dir=$TR_MC
    fi

    alignment ${ali_src} ${tr_dir}
    ali_dir=$(alignment ${ali_src} ${tr_dir})
	
    [[ ! -e $BNF_MDL_EXP ]] && mkdir -p ${BNF_MDL_EXP}
	[[ -n $tag ]] && mdl_dir="${mdl_dir}.${tag}"
	echo steps/nnet2/train_tanh_bottleneck.sh \
        --stage $stage --num-jobs-nnet 4 \
		--num-threads 1 \
		--mix-up 5000 --max-change 40 \
        --minibatch-size ${minibatch} \
        --initial-learning-rate 0.005 \
        --final-learning-rate 0.0005 \
        --num-hidden-layers 5 \
        --bottleneck-dim 42 --hidden-layer-dim 1024 \
        ${tr_dir} ${DATA}/lang $ali_dir ${mdl_dir} || exit 1
}

function train () {
    declare -A MDL=( \
        [mono]="mono" \
        [tri1]="tri1_phone" \
        [tri1_mc]="tri1_phone --cond mc" \
        [gmm_mc]="gmm --cond mc" \
		[gmm_raw_mc]="gmm --cond mc --feat raw" \
        [gmm_sat_mc]="sat --ali gmm --cond mc " \
        [gmm_lda_mc]="lda --cond mc --ali gmm" \
        [gmm_lda_raw_mc]="lda --cond mc --ali gmm_raw" \
		[gmm_fmllr_lda_raw_mc]="lda --cond mc --ali gmm_raw --opts fmllr " \
		[gmm_fmllr_lda_mc]="lda --ali gmm --cond mc --opts fmllr" \
		[gmm_splice_mc]="gmm_splice --ali gmm --cond mc" \
		[ubm_splice_mc]="ubm --ali gmm_splice --cond mc" \
		[plda_splice_mc]="plda --ali gmm --ubm ubm_splice --cond mc" \
		[ubm_mc]="ubm --ali gmm --cond mc" \
		[plda_mc]="plda --ali gmm --ubm ubm --cond mc" \
		[ubm_raw_mc]="ubm --ali gmm_raw --cond mc " \
		[plda_raw_mc]="plda --ali gmm_raw --ubm ubm_raw --cond mc"  \
		[ubm_lda_mc]="ubm --ali gmm_lda --cond mc" \
        [plda_lda_mc]="plda --ali gmm_lda --ubm ubm_lda --cond mc" \
		[ubm_lda_raw_mc]="ubm --ali gmm_lda_raw --cond mc" \
        [plda_lda_raw_mc]="plda --ali gmm_lda_raw --ubm ubm_lda_raw --cond mc" \
		[ubm_fmllr_raw_mc]="ubm --ali gmm_raw --cond mc --opts fmllr" \
        [plda_fmllr_raw_mc]="plda --ali gmm_raw --ubm ubm_raw --opts fmllr --cond mc" \
		[ubm_fmllr_lda_raw_mc]="ubm --ali gmm_lda_raw --cond mc --opts fmllr" \
        [plda_fmllr_lda_raw_mc]="plda --ali gmm_lda_raw --ubm ubm_lda_raw --opts fmllr --cond mc" \
		[ubm_fmllr_mc]="ubm --ali gmm --cond mc --opts fmllr" \
        [plda_fmllr_mc]="plda --ali gmm --ubm ubm --opts fmllr --cond mc" \
		[ubm_fmllr_lda_mc]="ubm --ali gmm_lda --cond mc --opts fmllr" \
        [plda_fmllr_lda_mc]="plda --ali gmm_lda --ubm ubm_lda --opts fmllr --cond mc" \
        [nnet2_mc]="nnet2 --ali gmm --cond mc" \
		[nnet2_raw_mc]="nnet2 --ali gmm_raw --cond mc" \
		[nnet2_fmllr_mc]="nnet2 --ali gmm --cond mc --opts fmllr" \
		[nnet2_fmllr_raw_mc]="nnet2 --ali gmm_raw --cond mc --opts fmllr" \
        [nnet2_lda_mc]="nnet2 --ali gmm_lda --cond mc" \
		[nnet2_lda_raw_mc]="nnet2 --ali gmm_lda_raw --cond mc" \
		[nnet2_fmllr_lda_mc]="nnet2 --ali gmm_fmllr_lda --cond mc " \
		[nnet2_fmllr_lda_raw_mc]="nnet2 --ali gmm_fmllr_lda_raw --cond mc " \
        [bnf_mc]="bottleneck_dnn --ali tri1 --cond mc" \
		[bnf_mc.gpu_256]="bottleneck_dnn --ali tri1 --cond mc --minibatch 256 --tag gpu_256" \

    )
    
    ORDER=($*)
    echo Training list : ${ORDER[*]}
    # declare -a ORDER=(  nnet2_tri1_mc )
    for mdl in ${ORDER[*]}; do
        if [ ! -e ${FEAT_EXP}/${mdl}/final.mdl ]; then
            echo "### Train MDL ${mdl} ###"
            eval  "${MDL[$mdl]}" || exit 1
        fi
    done

}

echo "### Acoustic Models Train ###"
# export FEAT_TYPE=mfcc
. check.sh
. local/am_util.sh

train ${TR_MDL}
# mkgraph ${FEAT_EXP}/gmm_lda_mc
# alignment  ${FEAT_EXP}/mono $TR_CLN
