#!/bin/bash

. ./corpus.sh


declare -A data
data[PhoneSel]="/home/14/ren/work/data/reverb_task/telephone/source/set13_dis_sl/iphone/"
data[Phone]="/home/14/ren/work/data/reverb_task/telephone/source/set13_dis/iphone/"
data[SimData]=${base}/REVERB_WSJCAM0_dt

for dtype in Phone; do
    local/REVERB_wsjcam0_data_prep.sh ${data[${dtype}]} REVERB_dt dt $dtype
done
