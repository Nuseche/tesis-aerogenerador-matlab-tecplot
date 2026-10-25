function [G,diagnostics] = timoshenko_gyroscopic_matrix( ...
        xI,xJ,auxPoint,section,omegaGlobal,cfg)
%TIMOSHENKO_GYROSCOPIC_MATRIX Distributed blade gyro from sectional inertia.
%   Coordinates are perturbations in the nominal COROTATING frame, with
%   R=R0*exp(S(theta)). The rotational term is derived from the complete
%   quadratic kinetic energy, not from S(J*Omega) alone. Assembly transports
%   this operator to inertial nodal coordinates before imposing constraints.

if nargin<6,cfg=struct();end
[~,Me,elementInfo]=elements.timoshenko3d_matrices( ...
    xI,xJ,auxPoint,section,cfg);
[~,massInfo]=elements.section_mass(section,cfg);
omegaGlobal=double(omegaGlobal(:));
if numel(omegaGlobal)~=3||any(~isfinite(omegaGlobal))
    error('elements:timoshenko_gyroscopic_matrix:InvalidOmega', ...
        'omegaGlobal must be a finite 3-vector.');
end
omegaLocal=elementInfo.R*omegaGlobal;
m=massInfo.massPerLength;r=massInfo.offset(:);J=massInfo.centroidalInertia;
Sr=skew(r);Bcg=[eye(3),-Sr];Somega=skew(omegaLocal);
GsectionTranslation=2*Bcg.'*(m*Somega)*Bcg;
GsectionRotation=zeros(6);
GsectionRotation(4:6,4:6)=J*Somega+Somega*J-skew(J*omegaLocal);
sectionOps=elements.rotating_section_operators(m,J,r,omegaLocal);
Gsection=sectionOps.G;
[xi,weights]=elements.gauss_rule(4);Glocal=zeros(12);
for point=1:numel(xi)
    N=elements.timoshenko_kinematic_matrix(xi(point),elementInfo.L, ...
        elementInfo.formulation,elementInfo.phiY,elementInfo.phiZ);
    Glocal=Glocal+N.'*Gsection*N*(elementInfo.L/2*weights(point));
end
Glocal=(Glocal-Glocal.')/2;
G=sparse(elementInfo.Te.'*Glocal*elementInfo.Te);G=(G-G.')/2;
diagnostics=struct('omegaGlobal',omegaGlobal,'omegaLocal',omegaLocal, ...
    'sectionTranslationNorm',norm(GsectionTranslation,'fro'), ...
    'sectionRotationNorm',norm(GsectionRotation,'fro'), ...
    'localNorm',norm(Glocal,'fro'),'norm',norm(G,'fro'), ...
    'skewError',norm(G+G.','fro')/max(norm(G,'fro'),eps), ...
    'quadratureOrder',4,'mass',sparse(Me), ...
    'coordinateFrame',"nominal_corotating",'formula', ...
    "integral N'*(2*m*Bcg'*W*Bcg + Etheta'*(J*W+W*J-S(J*Omega))*Etheta)*N dx");
end

function S=skew(v)
S=[0 -v(3) v(2);v(3) 0 -v(1);-v(2) v(1) 0];
end
