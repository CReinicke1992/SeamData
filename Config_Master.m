% PURPOSE
% * Input a desired data size
% * This program should extract the desired data, apply fk etc.

addpath('Functions/');

Nsx = 21;

data5d = load('Data/p_raw_Cartesian.mat');
data5d = data5d.data5d;