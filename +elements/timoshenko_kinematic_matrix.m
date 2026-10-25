function N = timoshenko_kinematic_matrix(xi,L,formulation,phiY,phiZ)
%TIMOSHENKO_KINEMATIC_MATRIX Section motion from the accepted interpolation.
%   N maps the 12 local nodal DOFs to [u v w rx ry rz] at xi in [-1,1].

if nargin<3||strlength(string(formulation))==0,formulation="closed_exact";end
if nargin<4,phiY=0;end
if nargin<5,phiZ=0;end
if ~isscalar(xi)||~isfinite(xi)||xi<-1||xi>1|| ...
        ~isscalar(L)||~isfinite(L)||L<=0
    error('elements:timoshenko_kinematic_matrix:InvalidInput', ...
        'xi must lie in [-1,1] and L must be positive.');
end
formulation=lower(string(formulation));
if any(formulation==["selective_integration","selective","sri"])
    [~,~,N]=elements.timoshenko_B_matrices(xi,L);return
end
if ~any(formulation==["closed_exact","closed","exact"])
    error('elements:timoshenko_kinematic_matrix:UnknownFormulation', ...
        'Unsupported Timoshenko formulation %s.',formulation);
end
s=(xi+1)/2;powers=[1 s s^2 s^3];
[CvY,CrY]=coefficients(L,phiY);[CvZ,CrZ]=coefficients(L,phiZ);
signZ=diag([1 -1 1 -1]);N=zeros(6,12);
N(1,[1 7])=[1-s,s];N(4,[4 10])=[1-s,s];
N(2,[2 6 8 12])=powers*CvY;N(6,[2 6 8 12])=powers*CrY;
N(3,[3 5 9 11])=powers*CvZ*signZ;
N(5,[3 5 9 11])=-powers*CrZ*signZ;
end

function [Cv,Cr]=coefficients(L,phi)
if ~isscalar(phi)||~isfinite(phi)||phi<0
    error('elements:timoshenko_kinematic_matrix:InvalidShearParameter', ...
        'Shear parameters must be finite and nonnegative.');
end
d=1+phi;
Cv=[1+phi,0,0,0;-phi,L*(1+phi/2),phi,-L*phi/2; ...
    -3,-L*(2+phi/2),3,-L*(1-phi/2);2,L,-2,L]/d;
Cr=[0,1+phi,0,0;-6/L,-(4+phi),6/L,-(2-phi); ...
    6/L,3,-6/L,3;0,0,0,0]/d;
end
