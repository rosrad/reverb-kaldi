#!/bin/bash

. check.sh
. local/am_util.sh

# local/REVERB_wsjcam0_data_prep.sh $reverb_tr REVERB_tr_cut tr ;;
# local/REVERB_wsjcam0_data_prep.sh $reverb_dt REVERB_dt dt ;;
# local/REVERB_wsjcam0_data_prep.sh $phone_dt PHONE_dt phone ;;
# local/REVERB_wsjcam0_data_prep.sh $phone_sel_dt PHONESEL_dt phone_sel ;;
# local/REVERB_wsjcam0_data_prep.sh $mslp_data REVERB_tr_cut tr 
# local/REVERB_wsjcam0_data_prep.sh $mslp_data REVERB_dt dt 
# local/REVERB_mcwsjav_data_prep.sh $mslp_data REVERB_REAL_dt dt $reverb_real_dt/mlf/WSJ.mlf

#local/REVERB_wsjcam0_data_prep.sh $cut_mslp_data REVERB_tr_cut tr 
#local/REVERB_wsjcam0_data_prep.sh $cut_mslp_data REVERB_dt dt 
#local/REVERB_mcwsjav_data_prep.sh $cut_mslp_data REVERB_REAL_dt dt $reverb_real_dt/mlf/WSJ.mlf 


local/REVERB_wsjcam0_data_prep.sh $mslp_data REVERB_tr_cut tr 
local/REVERB_wsjcam0_data_prep.sh $mslp_data REVERB_dt dt 
local/REVERB_mcwsjav_data_prep.sh $mslp_data REVERB_REAL_dt dt $reverb_real_dt/mlf/WSJ.mlf
