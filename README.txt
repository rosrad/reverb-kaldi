Improved multi condition training baseline for REVERB challenge based on Kaldi
==============================================================================

updated 
Wed Apr  9 12:14:02 CEST 2014 Felix Weninger <felix@weninger.de>

original:
Wed Nov  6 14:47:59 EST 2013 Felix Weninger <felix@weninger.de>

Key specs:
- MFCC-LDA-STC front-end
- Boosted MMI trained GMM-HMM
- Utterance-based adaptation using basis fMLLR
- Tri-gram LM minimum Bayes risk decoding

WER [%]
@ Language model weight = 15
Avg(SimData_(far|near)) = 11.73
Avg(RealData)           = 30.44
@ Language model weight = 16 (optimal)
Avg(SimData_(far|near)) = 11.72
Avg(RealData)           = 30.28

Kaldi SVN rev. 3006, 9/28/13
tested on Ubuntu 13.04 and Ubuntu 12.04


LICENSE:
++++++++
This is open-source code, Apache License, ver 2.0.
See COPYING for details.
Based on Kaldi's "s5" recipe for WSJ.

If you find this software useful for your own research, please cite the
following paper:

Felix Weninger, Shinji Watanabe, Jonathan Le Roux, John R. Hershey, Yuuki
Tachioka, Jürgen Geiger, Björn Schuller, Gerhard Rigoll: "The MERL/MELCO/TUM
system for the REVERB Challenge using Deep Recurrent Neural Network Feature
Enhancement", Proc. REVERB Workshop, IEEE, Florence, Italy, May 2014.


INSTRUCTIONS:
+++++++++++++

1) Copy the file Generate_mcTrainData_cut.m to the REVERB directory for
   generating the multi-condition training set
   (reverb_tools_for_Generate_mcTrainData)

   You have to change the save_dir variable in this script.
   Change to the reverb_tools_for_Generate_mcTrainData directory and run the
   Generate_mcTrainData_cut script in MATLAB (it works exactly as the
   Generate_mcTrainData script).

   This script generates a multi-condition training set where
   utterance lengths match the original set.
   This enables using clean alignments in multi-condition training (stereo training).

2) Set the path names in corpus.sh.default and path.sh.default, 
   and copy these files to "corpus.sh" and "path.sh"

-----
3) [optional:] If you have speech enhancement (processed waveforms), then

3a) Change directories and data preparation steps
    For example, you could have something like

    local/REVERB_wsjcam0_data_prep.sh /path/to/processed/REVERB_WSJCAM0_dt REVERB_dt_derev dt

    The first argument is supposed to point to a folder that has the same
    structure as the REVERB corpus.

3b) run the multi-condition training steps in run.sh with the processed
    training set, e.g., REVERB_tr_cut_derev, if you want to investigate
    recognizer re-training

    - Any system that has _mc in its name uses multi-condition training
    - You probably want to change the system names if you are using enhanced
      data for training (e.g. tri2b_mc -> tri2b_mc_derev)

3c) Add your re-trained recognizer to the list of recognizers that are
    discriminatively re-trained

3d) Modify the decoding steps in run.sh so that they use enhanced data and add
    your re-trained recognizer(s) to the list
-----

4) Execute the training and recognition steps by

   ./run.sh

   Depending on your system specs (# of CPUs, RAM) you might want (or have) to 
   change the number of parallel jobs -- this is controlled by the nj_train,
   nj_bg, and nj_tg variables (# of jobs for training, for bi-gram and tri-gram
   decoding).

   If you also want to have the re-implementation of the HTK baseline in Kaldi 
   (tri2a and tri2a_mc systems), set the do_tri2a variable to true in run.sh.

5) Execute 

   ./get_results.sh 

   to display the results corresponding to Table 1 in
   the following paper,

   Felix Weninger, Shinji Watanabe, Jonathan Le Roux, John R. Hershey, Yuuki
   Tachioka, Jürgen Geiger, Björn Schuller, Gerhard Rigoll: "The MERL/MELCO/TUM
   system for the REVERB Challenge using Deep Recurrent Neural Network Feature
   Enhancement", to appear in Proc. REVERB Workshop, IEEE, Florence, Italy, 2014.

   NOTE: It is very common to have slightly different results (up to +/- 1%
   absolute WER per REVERB task file) on different machines.  The reason for
   this is not fully known.

   NOTE 2: By default, only the LDA-STC systems are trained - set do_tri2a in
   run.sh to true to also train the Delta+Delta-Delta systems (cf. above).

-----
6) You can get more recognition results (for other combinations of front-ends, 
   adaptation, language model, etc.), by 

   $> perl summarize_results.pl [options] <system_name> [ <decoding_prefix> [ <data_suffix ] ]

   where system_name is, e.g., tri2b_mc, or tri2b_mc_derev 
   (a hypothetical system trained on dereverberated data)
   
   decoding_prefix: one of basis_fmllr, mbr, mbr_basis_fmllr, or '' (empty)
    - if the string "basis_fmllr" is given, (basis) fMLLR results are displayed
    - if mbr is given, minimum Bayes risk decoding results are displayed
    - if '' is given, no adaptation is used and ML decoding is used
   
   data_suffix is, e.g., "derev" if your data sets are named "REVERB_dt_derev", etc.
   
   By default, the optimum language model weight across all conditions is selected and
   displayed. Note that Table 1 in the above paper uses a constant weight of 15.
   
   Options: 
   --lmw=x      Set fixed language model weight instead of best, x \in { 9, ..., 20 }
   --lm=xg_5k   Display tri-gram (x=t) or bi-gram (x=b) LM decoding results
   ----

