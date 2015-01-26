#!/bin/bash

. check.sh

# Now it's getting more interesting.
# Prepare the multi-condition training data and the REVERB dt set.
# This also extracts MFCC features.
# This creates the data sets called REVERB_tr_cut and REVERB_dt.
# If you have processed waveforms, this is a good starting point to integrate them.
# For example, you could have something like
# ${LOCAL}/REVERB_wsjcam0_data_prep.sh /path/to/processed/REVERB_WSJCAM0_dt processed_REVERB_dt dt
# The first argument is supposed to point to a folder that has the same structure
# as the REVERB corpus.

# local/REVERB_wsjcam0_data_prep.sh $reverb_tr_cut REVERB_tr_cut tr || exit 1;
local/REVERB_wsjcam0_data_prep.sh $reverb_tr REVERB_tr tr || exit 1;
return 
# local/REVERB_wsjcam0_data_prep.sh $reverb_dt REVERB_dt dt     || exit 1;

# local/REVERB_wsjcam0_data_prep.sh $phone_dt PHONE_dt phone     || exit 1;
# local/REVERB_wsjcam0_data_prep.sh $phone_sel_dt PHONE_SEL_dt phone_sel     || exit 1;

# local/REVERB_wsjcam0_data_prep.sh $reverb_et REVERB_et et     || exit 1;

# Prepare the REVERB "real" dt set from MCWSJAV corpus.
# This corpus is *never* used for training.
# This creates the data set called REVERB_Real_dt and its subfolders
local/REVERB_mcwsjav_data_prep.sh $reverb_real_dt REVERB_REAL_dt dt || exit 1;
# The MLF file exists only once in the corpus, namely in the real_dt directory
# so we pass it as 4th argument
local/REVERB_mcwsjav_data_prep.sh $reverb_real_et REVERB_REAL_et et $reverb_real_dt/mlf/WSJ.mlf || exit 1;

