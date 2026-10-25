function [MR,details] = rigid_body_mass_matrix(varargin)
%RIGID_BODY_MASS_MATRIX Spatial mass at a reference/master node.
%   MR = rigid.rigid_body_mass_matrix(BODY) accepts mass, inertiaBody,
%   orientationBodyToGlobal and cgOffsetBody (or global equivalents).
%   MR = ... (m,rGlobal,Jbody,RbodyToGlobal) is also supported.
%   DOF order is [ux uy uz theta_x theta_y theta_z].

    [m,r,Jbody,R]=parseInputs(varargin{:});
    if ~isscalar(m)||~isfinite(m)||m<=0
        error("rigid:rigid_body_mass_matrix:InvalidMass","Rigid-body mass must be positive and finite.");
    end
    if ~isequal(size(Jbody),[3 3]) || any(~isfinite(Jbody(:))) || ...
            norm(Jbody-Jbody.',"fro")>1e-11*max(1,norm(Jbody,"fro"))
        error("rigid:rigid_body_mass_matrix:InvalidInertia","Body inertia must be a finite symmetric 3-by-3 matrix.");
    end
    Jbody=(Jbody+Jbody.')/2;
    inertiaEigenvalues=sort(real(eig(Jbody)));
    inertiaScale=max(1,max(abs(inertiaEigenvalues)));
    if min(inertiaEigenvalues) < -1e-12*inertiaScale
        error("rigid:rigid_body_mass_matrix:InvalidInertia","Body inertia must be positive semidefinite.");
    end
    triangleResidual=inertiaEigenvalues(3)-sum(inertiaEigenvalues(1:2));
    triangleTolerance=1e-10*inertiaScale;
    if triangleResidual>triangleTolerance
        error("rigid:rigid_body_mass_matrix:NonPhysicalInertia", ...
            "Principal mass moments must satisfy the physical triangle inequalities.");
    end
    if ~isequal(size(R),[3 3]) || any(~isfinite(R(:))) || ...
            norm(R*R.'-eye(3),"fro")>1e-10 || det(R)<=0
        error("rigid:rigid_body_mass_matrix:InvalidOrientation", ...
            "Body-to-global orientation must be a right-handed orthonormal matrix.");
    end
    r=reshape(double(r),3,1);
    if any(~isfinite(r))
        error("rigid:rigid_body_mass_matrix:InvalidOffset","CG offset must be finite.");
    end
    Jglobal=R*Jbody*R.';
    S=skew(r);
    inertiaAboutMaster=Jglobal-m*(S*S);
    MR=[m*eye(3),-m*S;m*S,inertiaAboutMaster];
    MR=(MR+MR.')/2;
    details=struct("mass",m,"cgOffsetGlobal",r,"inertiaGlobalCG",Jglobal, ...
        "inertiaGlobalMaster",inertiaAboutMaster, ...
        "orientationBodyToGlobal",R, ...
        "inertiaEigenvalues",inertiaEigenvalues, ...
        "inertiaTriangleResidual",triangleResidual, ...
        "inertiaTriangleTolerance",triangleTolerance, ...
        "spatialMassEigenvalues",sort(real(eig(MR))));
end

function [m,r,J,R]=parseInputs(varargin)
    if nargin==1 && isstruct(varargin{1})
        b=varargin{1};
        if ~isfield(b,"mass"), error("rigid:rigid_body_mass_matrix:MissingMass","Body.mass is required."); end
        m=double(b.mass);
        if isfield(b,"orientationBodyToGlobal") && ~isempty(b.orientationBodyToGlobal)
            R=double(b.orientationBodyToGlobal);
        elseif isfield(b,"R") && ~isempty(b.R)
            R=double(b.R);
        else
            R=eye(3);
        end
        if isfield(b,"inertiaBody"), J=double(b.inertiaBody);
        elseif isfield(b,"inertia"), J=double(b.inertia);
        elseif isfield(b,"J"), J=double(b.J);
        else, error("rigid:rigid_body_mass_matrix:MissingInertia","Body inertia is required."); end
        if isvector(J) && numel(J)==3, J=diag(J); end
        if isfield(b,"cgOffsetGlobal") && ~isempty(b.cgOffsetGlobal)
            r=double(b.cgOffsetGlobal(:));
        elseif isfield(b,"cgOffsetBody") && ~isempty(b.cgOffsetBody)
            r=R*double(b.cgOffsetBody(:));
        elseif isfield(b,"cgOffset") && ~isempty(b.cgOffset)
            r=double(b.cgOffset(:));
        else
            r=zeros(3,1);
        end
    elseif nargin>=3
        m=double(varargin{1});r=double(varargin{2});J=double(varargin{3});
        if isvector(J)&&numel(J)==3,J=diag(J);end
        if nargin>=4 && ~isempty(varargin{4}),R=double(varargin{4});else,R=eye(3);end
    else
        error("rigid:rigid_body_mass_matrix:InvalidInput","Use (body) or (mass,rGlobal,Jbody,RbodyToGlobal).");
    end
end

function S=skew(r)
    S=[0 -r(3) r(2);r(3) 0 -r(1);-r(2) r(1) 0];
end
