#!/bin/sh

# TODO Adapt these paths to your system
export base=/CDShare/Corpus/REVERB/
export wsj0cam=${base}/wsjcam0
export reverb_lm=${base}/WSJ0_LangMod_REVERB
export reverb_tr=/home/14/ren/work/data/reverb_task/kaldi_task/source/REVERB_WSJCAM0_tr_cut
# export reverb_tr=/home/14/ren/work/data/reverb14_kaldi_baseline/REVERB_WSJCAM0_tr_cut
# export reverb_dt=/home/14/ren/work/data/reverb_task/telephone/source/set13_dis/iphone/
export phone_dt=/home/14/ren/work/data/reverb_task/telephone/source/set13_dis/iphone/
export phone_sel_dt=/home/14/ren/work/data/reverb_task/telephone/source/set13_dis_sl/iphone/
export reverb_dt=${base}/REVERB_WSJCAM0_dt
export reverb_et=${base}/REVERB_WSJCAM0_et
export reverb_real_dt=${base}/MC_WSJ_AV_Dev
export reverb_real_et=${base}/MC_WSJ_AV_Eval
