function result = blade_frame_transformation(frameData,azimuth,omega,options)
%BLADE_FRAME_TRANSFORMATION Homologous blade-local to inertial coordinates.
%   H maps local [e1 e2 e3] translations/rotations at each non-root blade
%   station to inertial analysis coordinates. The reference frames rotate
%   through azimuth about the rotor axis, so Hdot and Hddot contain the
%   physical frame derivatives in addition to the harmonic MBC derivatives.

arguments
    frameData (1,1) struct
    azimuth (1,1) double {mustBeFinite}
    omega (1,1) double {mustBeFinite}
    options = struct()
end
required={'map','referenceR','rotorAxis'};
if ~all(isfield(frameData,required))
    error('rotor:BladeFrame:MissingData', ...
        'frameData requires map, referenceR and rotorAxis.');
end
map=double(frameData.map);referenceR=double(frameData.referenceR);
if size(map,2)~=3||mod(size(map,1),6)~=0
    error('rotor:BladeFrame:InvalidMap', ...
        'frameData.map must contain six-component station blocks by three blades.');
end
nStation=size(map,1)/6;
if ~isequal(size(referenceR),[3 3 nStation 3])
    error('rotor:BladeFrame:InvalidFrames', ...
        'referenceR must be 3-by-3-by-nStation-by-3.');
end
nDof=option(options,'nDof',option(frameData,'nDof',max(map,[],'all')));
if any(map<1|map>nDof|map~=fix(map),'all')||numel(unique(map(:)))~=numel(map)
    error('rotor:BladeFrame:InvalidMap', ...
        'Mapped analysis DOFs must be unique integers within nDof.');
end
axis=double(frameData.rotorAxis(:));
if numel(axis)~=3||any(~isfinite(axis))||norm(axis)==0
    error('rotor:BladeFrame:InvalidAxis', ...
        'rotorAxis must be a finite nonzero 3-vector.');
end
axis=axis/norm(axis);
alpha=option(options,'angularAcceleration',option(options,'alpha',0));
Saxis=skew(axis);Rspin=eye(3)+sin(azimuth)*Saxis+ ...
    (1-cos(azimuth))*(Saxis*Saxis);
W=skew(omega*axis);Wdot=skew(alpha*axis);
H=speye(nDof);Hdot=sparse(nDof,nDof);Hddot=sparse(nDof,nDof);
maximumOrthogonality=0;maximumDeterminantError=0;
for blade=1:3
    for station=1:nStation
        rows=(station-1)*6+(1:6);indices=map(rows,blade);
        Q0=referenceR(:,:,station,blade);
        orthogonality=norm(Q0.'*Q0-eye(3),'fro');
        determinantError=abs(det(Q0)-1);
        maximumOrthogonality=max(maximumOrthogonality,orthogonality);
        maximumDeterminantError=max(maximumDeterminantError,determinantError);
        if orthogonality>1e-10||det(Q0)<=0
            error('rotor:BladeFrame:NonOrthonormalFrame', ...
                'Blade %d station %d has an invalid reference frame.',blade,station);
        end
        Q=Rspin*Q0;
        Qdot=W*Q;
        Qddot=(Wdot+W*W)*Q;
        H(indices,indices)=blkdiag(Q,Q);
        Hdot(indices,indices)=blkdiag(Qdot,Qdot);
        Hddot(indices,indices)=blkdiag(Qddot,Qddot);
    end
end
Hinv=H.';identityError=norm(Hinv*H-speye(nDof),'fro')/max(sqrt(nDof),1);
result=struct('H',H,'Hinv',Hinv,'Hdot',Hdot,'Hddot',Hddot, ...
    'azimuth',azimuth,'omega',omega,'angularAcceleration',alpha, ...
    'rotorAxis',axis,'map',map,'nDof',nDof, ...
    'identityError',identityError, ...
    'maximumReferenceOrthogonalityError',maximumOrthogonality, ...
    'maximumReferenceDeterminantError',maximumDeterminantError, ...
    'coordinateConvention', ...
    "q_inertial=H(psi)*q_homologous; blocks use rotating columns [e1 e2 e3]");
end

function S=skew(vector)
S=[0 -vector(3) vector(2);vector(3) 0 -vector(1); ...
    -vector(2) vector(1) 0];
end

function value=option(source,name,fallback)
value=fallback;
if isstruct(source)&&isfield(source,name)&&~isempty(source.(name))
    value=source.(name);
end
if ~isscalar(value)||~isnumeric(value)||~isfinite(value)
    error('rotor:BladeFrame:InvalidOption','%s must be a finite scalar.',name);
end
value=double(value);
end
