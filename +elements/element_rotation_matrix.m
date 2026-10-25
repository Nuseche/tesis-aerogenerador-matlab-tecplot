function [R,Te,L,info] = element_rotation_matrix(xI,xJ,auxPoint,tolerances)
%ELEMENT_ROTATION_MATRIX Right-handed local frame and DOF transformation.
%   [R,TE,L,INFO] = ELEMENT_ROTATION_MATRIX(XI,XJ,AUX,TOLERANCES) places
%   the element axis e1 from XI to XJ and defines the positive local e3
%   direction by projecting XI-to-AUX normal to e1. The remaining axis is
%   e2=cross(e3,e1). R stores the local axes in rows, hence
%   qLocal=TE*qGlobal with TE=blkdiag(R,R,R,R).
%
%   TOLERANCES may be cfg, cfg.validation, or a scalar frame tolerance. A
%   missing/NaN auxiliary point selects a deterministic global basis and is
%   reported in INFO.usedDefaultAuxiliary.

    if nargin < 3 || isempty(auxPoint)
        auxPoint = [NaN NaN NaN];
    end
    if nargin < 4
        tolerances = struct();
    end
    xI = validatePoint(xI,"xI");
    xJ = validatePoint(xJ,"xJ");
    auxPoint = reshape(double(auxPoint),1,[]);
    if numel(auxPoint) ~= 3
        error("elements:element_rotation_matrix:InvalidPoint", ...
            "auxPoint must contain exactly three coordinates.");
    end

    tol = frameTolerance(tolerances);
    chord = xJ(:)-xI(:);
    L = norm(chord);
    coordinateScale = max([1,norm(xI),norm(xJ)]);
    lengthTolerance = max(tol*coordinateScale,100*eps(coordinateScale));
    if ~isfinite(L) || L <= lengthTolerance
        error("elements:element_rotation_matrix:ZeroLength", ...
            "Element length %.16g is not greater than tolerance %.16g.",L,lengthTolerance);
    end
    e1 = chord/L;

    usedDefault = any(~isfinite(auxPoint));
    if usedDefault
        basis = eye(3);
        [~,idx] = min((basis.'*e1).^2);
        trial = basis(:,idx);
    else
        trial = auxPoint(:)-xI(:);
    end
    projected = trial-e1*(e1.'*trial);
    projectedNorm = norm(projected);
    trialScale = max([1,norm(trial),L]);
    projectionTolerance = max(tol*trialScale,1e3*eps(trialScale));
    if ~isfinite(projectedNorm) || projectedNorm <= projectionTolerance
        error("elements:element_rotation_matrix:DegenerateAuxPoint", ...
            "Auxiliary projection %.16g is not greater than tolerance %.16g.", ...
            projectedNorm,projectionTolerance);
    end

    % PLAN_ACCION_02 convention: the projected auxiliary direction is e3.
    e3 = projected/projectedNorm;
    e2 = cross(e3,e1);
    e2 = e2/norm(e2);
    e3 = cross(e1,e2); % remove roundoff without changing the chosen side
    e3 = e3/norm(e3);

    R = [e1.';e2.';e3.'];
    orthogonalityError = norm(R*R.'-eye(3),"fro");
    determinant = det(R);
    if determinant <= 0 || orthogonalityError > max(10*tol,1e-12)
        error("elements:element_rotation_matrix:InvalidFrame", ...
            "Invalid local frame: orthogonality error %.3e, determinant %.16g.", ...
            orthogonalityError,determinant);
    end
    Te = blkdiag(R,R,R,R);
    info = struct("orthogonalityError",orthogonalityError, ...
        "determinant",determinant,"auxProjectionNorm",projectedNorm, ...
        "lengthTolerance",lengthTolerance, ...
        "projectionTolerance",projectionTolerance, ...
        "usedDefaultAuxiliary",usedDefault,"e1",e1,"e2",e2,"e3",e3);
end

function point = validatePoint(value,label)
    point = reshape(double(value),1,[]);
    if numel(point) ~= 3 || any(~isfinite(point))
        error("elements:element_rotation_matrix:InvalidPoint", ...
            "%s must be a finite three-coordinate point.",label);
    end
end

function tol = frameTolerance(value)
    tol = 1e-12;
    if isnumeric(value) && isscalar(value) && isfinite(value) && value > 0
        tol = double(value);
        return
    end
    if ~isstruct(value)
        return
    end
    if isfield(value,"validation") && isstruct(value.validation)
        value = value.validation;
    end
    names = ["rotationOrthogonality","frameTolerance","geometryTolerance"];
    for name = names
        if isfield(value,name)
            candidate = double(value.(name));
            if isscalar(candidate) && isfinite(candidate) && candidate > 0
                tol = candidate;
                return
            end
        end
    end
end
