function varargout = transform_rotating_system(varargin)
%TRANSFORM_ROTATING_SYSTEM Transform M,D,K with MBC derivative terms.
%   result = rotor.transform_rotating_system(ops,map,psi,omega,options)
%   result = rotor.transform_rotating_system(M,D,K,map,psi,omega,options)
%
%   options.method may be "frozen" (default) or "azimuth_average".

[M,D,K,map,azimuth,omega,options] = parseInputs(varargin{:});
n = size(M,1);
if ~isequal(size(M),[n n],size(D),size(K))
    error('rotor:MBC:InvalidSystem','M, D and K must be square matrices of equal size.');
end
if ~isfield(options,'nDof'), options.nDof = n; end
method = lower(string(getOption(options,'method', ...
    getOption(options,'formulation','frozen'))));

switch method
    case {"frozen","instantaneous"}
        sampleAzimuths = azimuth;
    case {"azimuth_average","azimuthal_average","average"}
        nSamples = getOption(options,'nAzimuthSamples',36);
        if ~isscalar(nSamples) || ~isfinite(nSamples) || nSamples < 1 || nSamples ~= fix(nSamples)
            error('rotor:MBC:InvalidAzimuthSamples', ...
                'nAzimuthSamples must be a positive integer.');
        end
        sampleAzimuths = azimuth + (0:nSamples-1)*(2*pi/nSamples);
    otherwise
        error('rotor:MBC:UnsupportedMethod', ...
            'Supported methods are frozen and azimuth_average.');
end

Mbar = sparse(n,n); Dbar = sparse(n,n); Kbar = sparse(n,n);
samples = repmat(struct('azimuth',0,'M',[],'D',[],'K',[]),numel(sampleAzimuths),1);
for k = 1:numel(sampleAzimuths)
    derivatives = rotor.mbc_derivatives(map,sampleAzimuths(k),omega,options);
    T = derivatives.T; Td = derivatives.Tdot; Tdd = derivatives.Tddot;
    Mk = T'*(M*T);
    Dk = T'*(D*T + 2*M*Td);
    Kk = T'*(K*T + D*Td + M*Tdd);
    Mbar = Mbar + Mk/numel(sampleAzimuths);
    Dbar = Dbar + Dk/numel(sampleAzimuths);
    Kbar = Kbar + Kk/numel(sampleAzimuths);
    samples(k) = struct('azimuth',sampleAzimuths(k),'M',Mk,'D',Dk,'K',Kk);
end

result = struct('M',Mbar,'D',Dbar,'K',Kbar,'Kt',Kbar, ...
    'method',method,'omegaRadPerSec',omega,'referenceAzimuth',azimuth, ...
    'sampleAzimuths',sampleAzimuths(:),'samples',samples, ...
    'transformation',rotor.mbc_derivatives(map,azimuth,omega,options));
if nargout <= 1
    varargout{1} = result;
else
    varargout{1} = Mbar;
    varargout{2} = Dbar;
    varargout{3} = Kbar;
    if nargout >= 4, varargout{4} = result; end
end
end

function [M,D,K,map,psi,omega,options] = parseInputs(varargin)
if numel(varargin) >= 4 && isstruct(varargin{1})
    ops = varargin{1}; map = varargin{2}; psi = varargin{3}; omega = varargin{4};
    if numel(varargin) >= 5, options = varargin{5}; else, options = struct(); end
    M = pickField(ops,{'M','mass'});
    D = pickField(ops,{'D','Ctotal'});
    if isempty(D)
        D = pickField(ops,{'C'});
        if isempty(D), D = sparse(size(M,1),size(M,1)); end
        G = pickField(ops,{'G'});
        if ~isempty(G), D = D+G; end
    end
    K = pickField(ops,{'Kt','Ktotal','K'});
elseif numel(varargin) >= 6
    M = varargin{1}; D = varargin{2}; K = varargin{3}; map = varargin{4};
    psi = varargin{5}; omega = varargin{6};
    if numel(varargin) >= 7, options = varargin{7}; else, options = struct(); end
else
    error('rotor:MBC:InvalidCall','Invalid transform_rotating_system input signature.');
end
end

function value = pickField(s,names)
value = [];
for k = 1:numel(names)
    if isfield(s,names{k}) && ~isempty(s.(names{k})), value = s.(names{k}); return; end
end
end

function value = getOption(s,name,defaultValue)
value = defaultValue;
if isstruct(s) && isfield(s,name) && ~isempty(s.(name)), value = s.(name); end
end
