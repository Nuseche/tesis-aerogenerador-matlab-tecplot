function [Kg,info] = geometric_stiffness(varargin)
%GEOMETRIC_STIFFNESS Consistent beam-column geometric stiffness.
%   Kg = elements.geometric_stiffness(L,N) returns a local matrix, with N
%   positive in tension (stiffening) and negative in compression.
%   Kg = ... (xI,xJ,auxPoint,N) returns the global matrix.

    [L,N,T,isGlobal,phiY,phiZ]=parseInputs(varargin{:});
    planeY=integratedPlane(L,N,phiY,1);
    planeZ=integratedPlane(L,N,phiZ,-1);
    local=zeros(12);
    local([2 6 8 12],[2 6 8 12])=planeY;
    local([3 5 9 11],[3 5 9 11])=planeZ;
    if isGlobal, Kg=T.'*local*T; else, Kg=local; end
    Kg=(Kg+Kg.')/2;
    info=struct("length",L,"axialForce",N,"phiY",phiY,"phiZ",phiZ, ...
        "Klocal",local,"transformation",T, ...
        "formulation","integrated Timoshenko translation gradients");
end

function [L,N,T,isGlobal,phiY,phiZ]=parseInputs(varargin)
    if nargin==2 && isscalar(varargin{1}) && isscalar(varargin{2})
        L=double(varargin{1});N=double(varargin{2});T=eye(12);isGlobal=false;
        phiY=0;phiZ=0;
    elseif nargin>=4
        xI=double(varargin{1});xJ=double(varargin{2});aux=double(varargin{3});N=double(varargin{4});
        [~,T,L]=elements.element_rotation_matrix(reshape(xI,1,3),reshape(xJ,1,3),reshape(aux,1,3));
        isGlobal=true;
        phiY=0;phiZ=0;
        if nargin>=5&&isstruct(varargin{5})
            section=varargin{5};
            phiY=12*double(section.EIz)/(double(section.GAy)*L^2);
            phiZ=12*double(section.EIy)/(double(section.GAz)*L^2);
        end
    else
        error("elements:geometric_stiffness:InvalidInput","Use (L,N) or (xI,xJ,auxPoint,N).");
    end
    if ~isfinite(L)||L<=0||~isfinite(N)
        error("elements:geometric_stiffness:InvalidValue","Length must be positive and axial force finite.");
    end
end

function plane=integratedPlane(L,N,phi,rotationSign)
    [points,weights]=elements.gauss_rule(4);plane=zeros(4);
    for index=1:numel(points)
        x=(points(index)+1)/2;d=1+phi;
        derivative=[(-phi-6*x+6*x^2)/(d*L), ...
            rotationSign*((1+phi/2)-2*(2+phi/2)*x+3*x^2)/d, ...
            (phi+6*x-6*x^2)/(d*L), ...
            rotationSign*(-phi/2-2*(1-phi/2)*x+3*x^2)/d];
        plane=plane+N*(derivative.'*derivative)*(weights(index)*L/2);
    end
end
