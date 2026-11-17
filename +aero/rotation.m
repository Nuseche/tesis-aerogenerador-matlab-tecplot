function [R,J]=rotation(theta)
%ROTATION Exponential map and spatial left Jacobian, angles in radians.
a=norm(theta);S=aero.skew(theta);
if a<1e-6
    b=1-a*a/6+a^4/120;c=.5-a*a/24+a^4/720;d=1/6-a*a/120+a^4/5040;
else
    b=sin(a)/a;c=(1-cos(a))/a^2;d=(a-sin(a))/a^3;
end
R=eye(3)+b*S+c*S*S;J=eye(3)+c*S+d*S*S;
end
