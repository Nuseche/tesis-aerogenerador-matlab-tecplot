function S=skew(v)
%SKEW Matrix satisfying S*w=cross(v,w).
v=v(:);S=[0 -v(3) v(2);v(3) 0 -v(1);-v(2) v(1) 0];
end
