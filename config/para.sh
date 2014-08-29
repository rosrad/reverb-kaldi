#!/bin/bash

# The language models with which to decode (tg_5k or bg_5k or "tg_5k bg_5k" for
# both)
export lms="bg_5k tg_5k"

# number of jobs for feature extraction and model training
export nj_train=10
export nj_decode=8
# number of jobs for decoding
# use less jobs for trigram model
# if you have enough RAM (~ 32 GB), you can use 8 jobs for trigram as well
export nj_bg=8
export nj_tg=4


# LDA context size (left/right) (4 is default)
context_size=4


numLeavesTri1=2000
numGaussTri1=10000
