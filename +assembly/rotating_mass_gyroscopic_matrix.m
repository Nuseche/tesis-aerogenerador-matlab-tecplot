function [G,diagnostics] = rotating_mass_gyroscopic_matrix(Mspatial,omega)
%ROTATING_MASS_GYROSCOPIC_MATRIX Gyroscopic operator of a spatial body mass.
%   Mspatial is the 6-by-6 mass at a reference point. Translation of its CG
%   Coordinates are nominal-corotating perturbations R=R0*exp(S(theta)).
%   Translation gives 2*Bcg'*m*S(omega)*Bcg; the complete rotational block
%   is Jcg*W+W*Jcg-S(Jcg*omega). Inertial transport is performed by assembly.

Mspatial=double(Mspatial);omega=double(omega(:));
if ~isequal(size(Mspatial),[6 6])||numel(omega)~=3|| ...
        any(~isfinite(Mspatial(:)))||any(~isfinite(omega))
    error('assembly:rotating_mass_gyroscopic_matrix:InvalidInput', ...
        'A finite spatial 6-by-6 mass and a finite 3-vector omega are required.');
end
symmetryError=norm(Mspatial-Mspatial.','fro')/max(norm(Mspatial,'fro'),eps);
if symmetryError>1e-11
    error('assembly:rotating_mass_gyroscopic_matrix:NonSymmetricMass', ...
        'The spatial mass must be symmetric.');
end
m=trace(Mspatial(1:3,1:3))/3;
translationError=norm(Mspatial(1:3,1:3)-m*eye(3),'fro')/max(abs(m),eps);
if ~isfinite(m)||m<=0||translationError>1e-10
    error('assembly:rotating_mass_gyroscopic_matrix:InvalidTranslationBlock', ...
        'The translational block must equal a positive m*I.');
end
coupling=Mspatial(1:3,4:6);Soffset=-coupling/m;
Soffset=(Soffset-Soffset.')/2;
offset=[Soffset(3,2);Soffset(1,3);Soffset(2,1)];
Jcg=Mspatial(4:6,4:6)+m*(Soffset*Soffset);
Jcg=(Jcg+Jcg.')/2;
Bcg=[eye(3),-Soffset];Svelocity=skew(omega);
Gtranslation=2*Bcg.'*(m*Svelocity)*Bcg;
Grotation=zeros(6);
Grotation(4:6,4:6)=Jcg*Svelocity+Svelocity*Jcg-skew(Jcg*omega);
G=sparse(Gtranslation+Grotation);G=(G-G.')/2;
skewError=norm(G+G.','fro')/max(norm(G,'fro'),eps);
diagnostics=struct('omega',omega,'mass',m,'cgOffset',offset, ...
    'inertiaCG',Jcg,'angularMomentum',Jcg*omega, ...
    'translationNorm',norm(Gtranslation,'fro'), ...
    'rotationNorm',norm(Grotation,'fro'),'norm',norm(G,'fro'), ...
    'massSymmetryError',symmetryError,'translationBlockError', ...
    translationError,'skewError',skewError,'formula', ...
    "2*Bcg'*m*W*Bcg + Brot'*(Jcg*W+W*Jcg-S(Jcg*Omega))*Brot", ...
    'coordinateFrame',"nominal_corotating");
end

function S=skew(v)
S=[0 -v(3) v(2);v(3) 0 -v(1);-v(2) v(1) 0];
end
