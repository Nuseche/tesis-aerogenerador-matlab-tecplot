function [M6,info] = section_mass(section,cfg)
%SECTION_MASS Generalized sectional inertia per unit length.
%   The DOF order is [u v w theta_x theta_y theta_z]. The reference-line
%   offset is r=[xcg,ycg,zcg], and Jx/Jy/Jz are centroidal mass moments per
%   unit length. SECTION.M6 is the canonical complete-matrix API;
%   SECTION.massMatrix remains a backward-compatible alias. Explicit M6 is
%   preserved rather than decomposed and reconstructed by the beam element.

    if nargin < 2
        cfg = struct();
    end
    if ~isstruct(section) || ~isscalar(section)
        error("elements:section_mass:InvalidSection","section must be a scalar struct.");
    end

    if isfield(section,"M6") && ~isempty(section.M6)
        M6 = requireMatrix(section.M6,"M6");
        source = "M6";
        info = validateMass(M6,cfg);
        info.source = source;
        validateDeclaredProperties(section,info,cfg);
        return
    end
    if isfield(section,"massMatrix") && ~isempty(section.massMatrix)
        M6 = requireMatrix(section.massMatrix,"massMatrix");
        source = "massMatrix";
        info = validateMass(M6,cfg);
        info.source = source;
        validateDeclaredProperties(section,info,cfg);
        return
    end

    requireField(section,"m");
    m = double(section.m);
    if ~isfinite(m) || m <= 0
        error("elements:section_mass:InvalidMass","Section mass per unit length must be positive and finite.");
    end

    if isfield(section,"J") && isequal(size(section.J),[3 3])
        J = double(section.J);
    else
        requireField(section,"Jy");
        requireField(section,"Jz");
        Jy = requiredScalar(section,"Jy");
        Jz = requiredScalar(section,"Jz");
        if isfield(section,"Jx") && ~isempty(section.Jx)
            Jx = double(section.Jx);
            if ~isscalar(Jx)
                error("elements:section_mass:InvalidProperty", ...
                    "Property 'Jx' must be a scalar.");
            end
        else
            Jx = NaN;
        end
        rule = torsionalInertiaRule(section,cfg);
        if ~isfinite(Jx) || Jx <= 0
            if rule == "perpendicular_axis"
                Jx = Jy+Jz;
            else
                error("elements:section_mass:MissingTorsionalInertia", ...
                    "A positive Jx is required. Set an explicit value or " + ...
                    "document torsionalInertiaRule='perpendicular_axis'.");
            end
        end
        J = diag([Jx,Jy,Jz]);
    end
    if any(~isfinite(J(:))) || norm(J-J.',"fro") > 1e-11*max(1,norm(J,"fro"))
        error("elements:section_mass:InvalidInertia","Section inertia must be finite and symmetric.");
    end
    if min(eig((J+J.')/2)) < -1e-12*max(1,norm(J,2))
        error("elements:section_mass:InvalidInertia","Section inertia must be positive semidefinite.");
    end

    r = [optionalScalar(section,"xcg",0);optionalScalar(section,"ycg",0); ...
        optionalScalar(section,"zcg",0)];
    S = skew(r);
    M6 = [m*eye(3),-m*S;m*S,J-m*(S*S)];
    M6 = (M6+M6.')/2;
    info = validateMass(M6,cfg);
    info.source = "scalar_properties";
    info.torsionalInertiaRule = torsionalInertiaRule(section,cfg);
end

function requireField(s,name)
    if ~isfield(s,name)
        error("elements:section_mass:MissingProperty","Section is missing required property '%s'.",name);
    end
end

function x = optionalScalar(s,name,defaultValue)
    if isfield(s,name) && ~isempty(s.(name))
        x = double(s.(name));
    else
        x = defaultValue;
    end
    if ~isscalar(x) || ~isfinite(x)
        error("elements:section_mass:InvalidProperty","Property '%s' must be a finite scalar.",name);
    end
end

function x = requiredScalar(s,name)
    x = optionalScalar(s,name,NaN);
    if ~isfinite(x)
        error("elements:section_mass:InvalidProperty", ...
            "Property '%s' must be supplied as a finite scalar.",name);
    end
end

function S = skew(r)
    S = [0 -r(3) r(2); r(3) 0 -r(1); -r(2) r(1) 0];
end

function info = validateMass(M6,cfg)
    symmetryTolerance = cfgTolerance(cfg, ...
        ["matrixSymmetry","symmetryTolerance"],1e-12);
    if any(~isfinite(M6(:)))
        error("elements:section_mass:InvalidMatrix", ...
            "Generalized section mass must contain only finite values.");
    end
    symmetryError = norm(M6-M6.',"fro")/max(norm(M6,"fro"),eps);
    if symmetryError > symmetryTolerance
        error("elements:section_mass:InvalidMatrix","Generalized section mass must be finite and symmetric.");
    end
    M6 = (M6+M6.')/2;
    minimumEigenvalue = min(eig(M6));
    positiveTolerance = cfgTolerance(cfg,["positiveTolerance"],1e-12);
    if minimumEigenvalue < -positiveTolerance*max(1,norm(M6,2))
        error("elements:section_mass:InvalidMatrix","Generalized section mass must be positive semidefinite.");
    end

    Mtt = M6(1:3,1:3);
    m = trace(Mtt)/3;
    structureTolerance = max(100*symmetryTolerance,1e-10);
    translationalError = norm(Mtt-m*eye(3),"fro")/max(abs(m),eps);
    if ~isfinite(m) || m <= 0 || translationalError > structureTolerance
        error("elements:section_mass:InvalidTranslationalBlock", ...
            "M6(1:3,1:3) must equal m*I; relative residual %.3e.",translationalError);
    end
    coupling = M6(1:3,4:6);
    couplingSkewError = norm(coupling+coupling.',"fro")/max(norm(coupling,"fro"),eps);
    if couplingSkewError > structureTolerance
        error("elements:section_mass:InvalidOffsetCoupling", ...
            "Translation-rotation mass coupling must be skew; residual %.3e.", ...
            couplingSkewError);
    end
    S = -coupling/m;
    S = (S-S.')/2;
    offset = [S(3,2);S(1,3);S(2,1)];
    Jcentroid = M6(4:6,4:6)+m*(S*S);
    Jcentroid = (Jcentroid+Jcentroid.')/2;
    inertiaEigenvalues = sort(real(eig(Jcentroid)));
    inertiaScale = max([1;abs(inertiaEigenvalues)]);
    if inertiaEigenvalues(1) < -positiveTolerance*inertiaScale
        error("elements:section_mass:InvalidInertia", ...
            "Recovered centroidal inertia is not positive semidefinite.");
    end
    triangleResidual = inertiaEigenvalues(3)-sum(inertiaEigenvalues(1:2));
    triangleTolerance = cfgTolerance(cfg,["inertiaTriangleRelative"],1e-4);
    if triangleResidual > triangleTolerance*inertiaScale
        error("elements:section_mass:InvalidInertia", ...
            "Centroidal principal inertias violate the inertia triangle inequality.");
    end
    info = struct("massPerLength",m,"offset",offset, ...
        "centroidalInertia",Jcentroid,"symmetryError",symmetryError, ...
        "minimumEigenvalue",minimumEigenvalue, ...
        "translationalBlockError",translationalError, ...
        "couplingSkewError",couplingSkewError, ...
        "inertiaEigenvalues",inertiaEigenvalues, ...
        "inertiaTriangleResidual",triangleResidual, ...
        "inertiaTriangleTolerance",triangleTolerance);
end

function validateDeclaredProperties(section,info,cfg)
    tol = max(cfgTolerance(cfg,["massConservation"],1e-10),1e-10);
    if isfield(section,"m") && ~isempty(section.m)
        declared = double(section.m);
        if ~isscalar(declared) || ~isfinite(declared) || ...
                abs(declared-info.massPerLength) > tol*max(abs(declared),1)
            error("elements:section_mass:InconsistentMass", ...
                "Declared m is inconsistent with the translational block of M6.");
        end
    end
    names = ["xcg","ycg","zcg"];
    declaredOffset = zeros(3,1);
    hasOffset = false;
    for k = 1:3
        if isfield(section,names(k)) && ~isempty(section.(names(k)))
            declaredOffset(k) = optionalScalar(section,names(k),0);
            hasOffset = true;
        end
    end
    if hasOffset && norm(declaredOffset-info.offset) > tol*max(norm(declaredOffset),1)
        error("elements:section_mass:InconsistentOffset", ...
            "Declared centroid offset is inconsistent with M6 coupling terms.");
    end
end

function value = requireMatrix(candidate,name)
    if ~isnumeric(candidate) || ~isequal(size(candidate),[6 6])
        error("elements:section_mass:InvalidMatrix", ...
            "section.%s must be a numeric 6-by-6 matrix.",name);
    end
    value = double(candidate);
end

function rule = torsionalInertiaRule(section,cfg)
    rule = "explicit";
    if isfield(section,"torsionalInertiaRule") && ~isempty(section.torsionalInertiaRule)
        rule = lower(string(section.torsionalInertiaRule));
        return
    end
    if ~isstruct(cfg) || ~isfield(cfg,"sections") || ~isstruct(cfg.sections)
        return
    end
    cursor = cfg.sections;
    if isfield(section,"type") && isfield(cursor,char(string(section.type)))
        cursor = cursor.(char(string(section.type)));
    end
    if isstruct(cursor) && isfield(cursor,"torsionalInertiaRule")
        rule = lower(string(cursor.torsionalInertiaRule));
    end
end

function value = cfgTolerance(cfg,names,fallback)
    value = fallback;
    if ~isstruct(cfg),return,end
    if isfield(cfg,"validation") && isstruct(cfg.validation)
        cfg = cfg.validation;
    end
    for name = names
        if isfield(cfg,name)
            candidate = double(cfg.(name));
            if isscalar(candidate) && isfinite(candidate) && candidate >= 0
                value = candidate;
                return
            end
        end
    end
end
