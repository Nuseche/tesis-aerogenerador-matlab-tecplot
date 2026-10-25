function varargout = mbc_derivatives(bladeDofMap, azimuth, omega, options)
%MBC_DERIVATIVES Analytic Tdot and Tddot for the three-blade MBC.
%   omega is d(azimuth)/dt in rad/s. options.angularAcceleration defaults
%   to zero. Derivatives include only time-dependent rotating blocks.

arguments
    bladeDofMap
    azimuth (1,1) double {mustBeFinite}
    omega (1,1) double {mustBeFinite}
    options = struct()
end

base = rotor.mbc_transformation(bladeDofMap,azimuth,options);
map = base.bladeDofMap;
nDof = base.nDof;
alpha = getOption(options,'angularAcceleration',getOption(options,'alpha',0));
angles = base.bladeAzimuths;

Bdot = sparse(nDof,nDof);
Bddot = sparse(nDof,nDof);
for row = 1:size(map,1)
    idx = map(row,:);
    dBlock = [zeros(3,1), -omega*sin(angles(:)), omega*cos(angles(:))];
    ddBlock = [zeros(3,1), ...
        -omega^2*cos(angles(:))-alpha*sin(angles(:)), ...
        -omega^2*sin(angles(:))+alpha*cos(angles(:))];
    Bdot(idx,idx) = dBlock;
    Bddot(idx,idx) = ddBlock;
end

harmonic=struct('T',base.T,'Tinv',base.Tinv,'Tdot',Bdot, ...
    'Tddot',Bddot,'identityError',base.identityError, ...
    'coordinateOrder',base.coordinateOrder);
frame=struct();T=base.T;Tinv=base.Tinv;Tdot=Bdot;Tddot=Bddot;
coordinateState="global_components_mixed_directly";
if isfield(options,'frameData')&&~isempty(options.frameData)
    frame=rotor.blade_frame_transformation( ...
        options.frameData,azimuth,omega,options);
    H=frame.H;Hd=frame.Hdot;Hdd=frame.Hddot;B=base.T;
    T=H*B;Tinv=base.Tinv*frame.Hinv;
    Tdot=Hd*B+H*Bdot;
    Tddot=Hdd*B+2*Hd*Bdot+H*Bddot;
    coordinateState="global=H(psi)*T_MBC(psi)*multiblade";
end
identityError=norm(Tinv*T-speye(nDof),'fro')/max(sqrt(nDof),1);
result = struct('T',T,'Tinv',Tinv,'Tdot',Tdot, ...
    'Tddot',Tddot,'omega',omega,'angularAcceleration',alpha, ...
    'azimuth',azimuth,'bladeAzimuths',angles,'bladeDofMap',map);
result.identityError=identityError;result.harmonic=harmonic;
result.frame=frame;result.coordinateState=coordinateState;
if nargout <= 1
    varargout{1} = result;
else
    varargout{1} = Tdot;
    varargout{2} = Tddot;
    if nargout >= 3, varargout{3} = result; end
end
end

function value = getOption(s,name,defaultValue)
value = defaultValue;
if isstruct(s) && isfield(s,name) && ~isempty(s.(name)), value = s.(name); end
end
