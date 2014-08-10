function [x]=read_sphere(fname)
% function [x]=read_sphere(fname)
%
% The function to read a sphere data using NIST w_decode, h_strip.
%
% Input variable
%     fname: string name of the input .sphere file
% Output variable 
%         x: loaded data
%
% Note that this function calls the following functions 
%    1) ./sphere_to_wave.ch
%    2) ./bin/hstrip
%    3) ./bin/w_decode
% The 2nd and 3rd items should be obtained from REVERB_TOOL_FOR_ASR/tools/SPHERE/nist/bin/,
% which is included in the ASR baseline system distributed at http://reverb2014.dereverberation.com/download.html

unix(['./sphere_to_wave.csh ',fname,'.wv1 tmp.pcm']);
fd=fopen('tmp.pcm','rb');
x=fread(fd,[1,inf],'short');
fclose(fd);
delete('tmp.pcm');
