#!/bin/csh 
#
# This script should be used to read .sphere file and convert it to .pcm file.
#
set sphere_file = $1
set wave_file   = $2
set tmp_file    = $2.tmp

set sphere_dir  = ./bin

$sphere_dir/w_decode -f -o pcm $sphere_file $tmp_file
$sphere_dir/h_strip $tmp_file $wave_file
rm -f $tmp_file
