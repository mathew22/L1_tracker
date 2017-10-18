function [out, mu , std_dev] = whitening(in)
% Perform whitening operation on the given vector
%
%  in     -- lx1
%  out    -- lx1

l = size(in,1);
mu = mean(in);
b = std(in)+1e-14;
out = (in - ones(l,1)* mu) ./ (ones(l,1)* std_dev);
