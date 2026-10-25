function [Mout, diagnostics] = apply_mass_formulation(Mconsistent, cfg, modelData)
%APPLY_MASS_FORMULATION Apply an explicit, traceable mass choice.
%   Rigid-body masses must be added after this function so their spatial
%   coupling terms are never discarded.

method = "consistent";
if isfield(cfg,'mass') && isfield(cfg.mass,'formulation')
    method = lower(string(cfg.mass.formulation));
end
Mconsistent = sparse((Mconsistent+Mconsistent.')/2);
switch method
    case "consistent"
        Mout = Mconsistent;
        diagnostics = struct('method',method,'consistent',Mconsistent, ...
            'rowSums',full(sum(Mconsistent,2)),'outputDiagonal',false, ...
            'usesAbsoluteValue',false,'scope', ...
            "production distributed mass; spatial bodies added afterward");
    case {"hrz","diagonal_hrz"}
        if nargin<3||isempty(modelData)
            error('assembly:apply_mass_formulation:MissingDofMap', ...
                'HRZ mass requires modelData or an explicit nodal DOF map.');
        end
        [Mout,diagnostics]=assembly.hrz_lump_mass(Mconsistent,modelData);
        diagnostics.consistent=Mconsistent;
        diagnostics.rowSums=full(sum(Mconsistent,2));
    case {"row_sum","diagonal_row_sum"}
        diagonal = full(sum(Mconsistent,2));
        scale = max(abs(diagonal));
        tolerance = 1e-12*max(scale,1);
        if any(diagonal < -tolerance)
            error('assembly:apply_mass_formulation:NegativeRowSum', ...
                ['Row-sum lumping produced a negative diagonal. The solver ' ...
                 'will not hide it with abs; select consistent mass.']);
        end
        diagonal(abs(diagonal)<=tolerance) = 0;
        Mout = spdiags(diagonal,0,size(Mconsistent,1),size(Mconsistent,2));
        diagnostics = struct('method',method,'consistent',Mconsistent, ...
            'rowSums',full(sum(Mconsistent,2)),'outputDiagonal',true, ...
            'usesAbsoluteValue',false,'scope', ...
            "diagnostic legacy row sum; not accepted for production");
    otherwise
        error('assembly:apply_mass_formulation:UnknownMethod', ...
            'Supported mass formulations are consistent, hrz and diagnostic row_sum; got %s.',method);
end
diagnostics.symmetryError=norm(Mout-Mout.','fro')/max(norm(Mout,'fro'),eps);
end
