function [K6,info] = section_stiffness(section,cfg)
%SECTION_STIFFNESS Generalized Timoshenko section stiffness.
%   K6 = elements.section_stiffness(SECTION,CFG) returns the 6-by-6 matrix for
%   generalized strains [epsilon gamma_y gamma_z kappa_x kappa_y kappa_z].
%   SECTION.K6 is the canonical complete-matrix API. The legacy aliases K
%   and D remain accepted. Scalar GAy/GAz values are treated as effective
%   shear stiffnesses and are never multiplied by a correction factor here.

    if nargin < 2
        cfg = struct();
    end
    if ~isstruct(section) || ~isscalar(section)
        error("elements:section_stiffness:InvalidSection", ...
            "section must be a scalar struct.");
    end

    source = "scalar_properties";
    if isfield(section,"K6") && ~isempty(section.K6)
        K6 = requireMatrix(section.K6,"K6");
        source = "K6";
    elseif isfield(section,"K") && ~isempty(section.K)
        K6 = requireMatrix(section.K,"K");
        source = "K";
    elseif isfield(section,"D") && isequal(size(section.D),[6 6])
        K6 = requireMatrix(section.D,"D");
        source = "D";
    else
        names = ["EA","GAy","GAz","GJ","EIy","EIz"];
        values = zeros(1,6);
        for k = 1:6
            if ~isfield(section,names(k))
                error("elements:section_stiffness:MissingProperty", ...
                    "Section is missing required property '%s'.",names(k));
            end
            values(k) = double(section.(names(k)));
        end
        if any(~isfinite(values([1 4 5 6]))) || ...
                any(isnan(values)) || any(values <= 0) || ...
                any(isinf(values([1 4 5 6]))) || any(values([2 3]) == -Inf)
            error("elements:section_stiffness:InvalidProperty", ...
                "EA, GAy, GAz, GJ, EIy and EIz must be positive; all except shear limits must be finite.");
        end
        K6 = diag(values);
    end

    symmetryTolerance = cfgTolerance(cfg, ...
        ["matrixSymmetry","symmetryTolerance"],1e-12);
    if any(isnan(K6(:))) || any(K6(:) == -Inf)
        error("elements:section_stiffness:InvalidMatrix", ...
            "The generalized section stiffness contains NaN or negative infinity.");
    end
    infiniteLocations = isinf(K6);
    permittedInfinite = false(6);
    permittedInfinite(2,2) = true;
    permittedInfinite(3,3) = true;
    if any(infiniteLocations & ~permittedInfinite,"all")
        error("elements:section_stiffness:InvalidMatrix", ...
            "Only diagonal GAy/GAz may be infinite to request the Euler-Bernoulli limit.");
    end
    finiteCopy = K6;
    finiteCopy(infiniteLocations) = 0;
    symmetryError = norm(finiteCopy-finiteCopy.',"fro") / ...
        max(norm(finiteCopy,"fro"),eps);
    if symmetryError > symmetryTolerance
        error("elements:section_stiffness:NonSymmetric", ...
            "Section K6 symmetry error %.3e exceeds tolerance %.3e.", ...
            symmetryError,symmetryTolerance);
    end

    diagonalValues = diag(K6);
    if any(diagonalValues <= 0) || any(isnan(diagonalValues))
        error("elements:section_stiffness:NonPositive", ...
            "All six generalized diagonal stiffnesses must be positive.");
    end
    isCoupled = norm(finiteCopy-diag(diag(finiteCopy)),"fro") > ...
        symmetryTolerance*max(norm(finiteCopy,"fro"),eps);
    minimumEigenvalue = NaN;
    if ~any(infiniteLocations,"all")
        symmetricK = (K6+K6.')/2;
        eigenvalues = eig(symmetricK);
        minimumEigenvalue = min(eigenvalues);
        [~,notPositiveDefinite] = chol(symmetricK);
        if notPositiveDefinite ~= 0
            error("elements:section_stiffness:NonPositiveDefinite", ...
                "Section K6 must be positive definite; minimum eigenvalue %.6e.", ...
                minimumEigenvalue);
        end
    end
    K6 = (K6+K6.')/2;
    info = struct("source",source,"isDiagonal",~isCoupled, ...
        "isCoupled",isCoupled,"symmetryError",symmetryError, ...
        "minimumEigenvalue",minimumEigenvalue, ...
        "shearStiffnessConvention","GAy_GAz_are_effective_no_extra_factor");
end

function value = requireMatrix(candidate,name)
    if ~isnumeric(candidate) || ~isequal(size(candidate),[6 6])
        error("elements:section_stiffness:InvalidMatrix", ...
            "section.%s must be a numeric 6-by-6 matrix.",name);
    end
    value = double(candidate);
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
