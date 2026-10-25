function terms=transport_rotating_operators(M,Gcorotating,omega)
%TRANSPORT_ROTATING_OPERATORS Nominal-corotating to inertial perturbations.
%   At the reference azimuth q_c=E*q_g, E=I, Edot=-W, Eddot=W^2.
%   This is a time-dependent change of coordinates, NOT an extra physical
%   gyroscope. The symmetric mass-rate term must not be discarded.
M=sparse(M);Gc=sparse(Gcorotating);omega=double(omega(:));
n=size(M,1);
if size(M,2)~=n||~isequal(size(Gc),[n n])||mod(n,3)~=0|| ...
        numel(omega)~=3||any(~isfinite(omega))
    error('assembly:transport_rotating_operators:InvalidInput', ...
        'Square 3-block matrices and a finite angular velocity are required.');
end
S=[0 -omega(3) omega(2);omega(3) 0 -omega(1);-omega(2) omega(1) 0];
W=kron(speye(n/3),sparse(S));
massRate=W*M-M*W;
Ginertial=Gc-M*W-W*M;
terms=struct('G',Ginertial,'massRate',massRate, ...
    'D',Gc-2*M*W,'Ktransport',-Gc*W+M*(W*W), ...
    'W',W,'coordinateFrame',"inertial_snapshot", ...
    'identityError',norm((Gc-2*M*W)-Ginertial-massRate,'fro')/ ...
        max(norm(Gc-2*M*W,'fro'),1));
end
