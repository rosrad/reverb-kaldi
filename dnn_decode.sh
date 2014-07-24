#!/bin/bash
# decode REVERB dt usting the dnn model
. ./util.sh
condition=${1:-"mc"}
base=${2:-"tri1"}
model=$(dnn_model ${condition} ${base})
decode_nj=8
echo "================== Decode DNN ======================= "
echo "CONDTION: ${condition}"
echo "BASE_FEATURE: ${base}"
echo "MODEL DEST: ${model} "

for dataset in data/REVERB_dt/SimData_dt*; do
    decode_dir="exp/${model}/decode_bg_5k_REVERB_dt_$(basename ${dataset})"
    [ ! -d ${decode_dir} ] && mkdir -p ${decode_dir}
    steps/nnet2/decode.sh --nj "$decode_nj" --num-threads 6 \
        exp/${base}/graph_bg_5k \
        $dataset $decode_dir \
        | tee ${decode_dir}/decode.log
done

echo "================== End Decode DNN ======================= "
echo "CONDTION: ${condition}"
echo "BASE_FEATURE: ${base}"
echo "MODEL DEST: ${model} "

# for dt in near far cln ; do
#     get_wer.sh "${base}*${condtion}" |tee res/${base}_${condtion}_${dt}_$(date +%Y%m%d-%H:%M).res
# done
