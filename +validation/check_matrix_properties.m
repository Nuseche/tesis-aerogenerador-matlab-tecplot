function report = check_matrix_properties(ops, cfg)
%CHECK_MATRIX_PROPERTIES Audit complete and reduced operator properties.
%   Aerodynamic tangents may be nonsymmetric and are never altered here;
%   passive mechanical parts are checked separately.

tolSym = localCfg(cfg, {'validation','matrixTolerance'}, 1e-9);
tolSkew = localCfg(cfg, {'validation','skewTolerance'}, 1e-9);
tolPos = localCfg(cfg, {'validation','positiveTolerance'}, 1e-10);
tolIdentity = localCfg(cfg, {'validation','matrixIdentityTolerance'}, 1e-12);
tolCondition = localCfg(cfg, {'validation','transformationRcondTolerance'}, 1e-12);
requireSparse = localLogicalCfg(cfg, {'validation','requireSparseOperators'}, true);
report = repmat(localCheck("", true, 0, 0, "", false), 0, 1);

[fullOps,reducedOps] = localOperatorLevels(ops);
report = [report; localLevelChecks(fullOps,"full",tolSym,tolSkew, ...
    tolPos,tolIdentity,requireSparse,false)]; %#ok<AGROW>
report = [report; localLevelChecks(reducedOps,"reduced",tolSym,tolSkew, ...
    tolPos,tolIdentity,requireSparse,true)]; %#ok<AGROW>

Tc = localGet(reducedOps,{'Tc'});
if isempty(Tc), Tc = localGet(fullOps,{'Tc'}); end
if ~isempty(Tc)
    report = [report; localTransformationChecks(Tc,tolCondition, ...
        requireSparse)]; %#ok<AGROW>
end
end

function checks = localLevelChecks(level,label,tolSym,tolSkew,tolPos, ...
        tolIdentity,requireSparse,positiveMass)
checks = repmat(localCheck("", true, 0, 0, "", false), 0, 1);
if ~isstruct(level) || isempty(fieldnames(level)), return; end

allNames = {'M','C','D','K','Ke','Kg','KOmega','Kaero','Caero','G', ...
    'massRate','Ktransport','constraintK','constraintD','Tdot','Tddot'};
for index = 1:numel(allNames)
    key = allNames{index};
    if ~isfield(level,key) || isempty(level.(key)), continue; end
    A = level.(key);
    finite = isnumeric(A) && ismatrix(A) && all(isfinite(nonzeros(A)));
    checks(end+1,1) = localCheck(label+"."+key+".finite",finite, ...
        double(~finite),0,"All stored entries must be finite.",true); %#ok<AGROW>
    if requireSparse
        sparsePass = issparse(A);
        checks(end+1,1) = localCheck(label+"."+key+".sparse", ...
            sparsePass,double(~sparsePass),0, ...
            "Global operators must remain sparse.",true); %#ok<AGROW>
    end
end

passiveNames = {'M','Ke','Kg','KOmega'};
for index = 1:numel(passiveNames)
    key = passiveNames{index};
    if ~isfield(level,key) || isempty(level.(key)), continue; end
    A = level.(key);
    residual = localRelativeResidual(A-A.',A);
    checks(end+1,1) = localCheck(label+"."+key+".symmetry", ...
        residual<=tolSym,residual,tolSym, ...
        "Relative Frobenius symmetry residual for a passive operator.", ...
        true); %#ok<AGROW>
end

% C includes Caero in the operating-matrix convention. Test only its
% explicitly passive remainder for symmetry and semidefiniteness.
if isfield(level,'C') && ~isempty(level.C)
    Cpassive = level.C;
    if isfield(level,'Caero') && ~isempty(level.Caero)
        Cpassive = Cpassive-level.Caero;
    end
    residual = localRelativeResidual(Cpassive-Cpassive.',Cpassive);
    checks(end+1,1) = localCheck(label+".Cpassive.symmetry", ...
        residual<=tolSym,residual,tolSym, ...
        "Passive damping C-Caero must be symmetric; Caero is unchanged.", ...
        true); %#ok<AGROW>
    if positiveMass
        Cpassive = (Cpassive+Cpassive.')/2;
        minimum = localSmallestEigenvalue(Cpassive);
        scale = max(norm(Cpassive,1),eps);
        checks(end+1,1) = localCheck(label+".Cpassive.semidefinite", ...
            minimum>=-tolPos*scale,minimum,-tolPos*scale, ...
            "Smallest eigenvalue of passive reduced damping.",true); %#ok<AGROW>
    end
end

if isfield(level,'G') && ~isempty(level.G)
    G = level.G;
    residual = localRelativeResidual(G+G.',G);
    checks(end+1,1) = localCheck(label+".G.skewSymmetry", ...
        residual<=tolSkew,residual,tolSkew, ...
        "Relative Frobenius skew-symmetry residual.",true); %#ok<AGROW>
end

if isfield(level,'D') && isfield(level,'C') && isfield(level,'G') && ...
        ~isempty(level.D) && ~isempty(level.C) && ~isempty(level.G)
    expected = level.C+level.G;
    if isfield(level,'massRate'),expected=expected+level.massRate;end
    residual = localRelativeResidual(level.D-expected,expected);
    checks(end+1,1) = localCheck(label+".D.componentIdentity", ...
        residual<=tolIdentity,residual,tolIdentity, ...
        "D=C+G+massRate; massRate is present for time-dependent coordinates.",true); %#ok<AGROW>
end

stiffnessNames = {'Ke','Kg','KOmega','Kaero'};
if isfield(level,'K') && ~isempty(level.K) && ...
        all(isfield(level,stiffnessNames)) && ...
        all(cellfun(@(name)~isempty(level.(name)),stiffnessNames))
    expected = level.Ke+level.Kg+level.KOmega+level.Kaero;
    if isfield(level,'Ktransport'),expected=expected+level.Ktransport;end
    if isfield(level,'constraintK'),expected=expected+level.constraintK;end
    residual = localRelativeResidual(level.K-expected,expected);
    checks(end+1,1) = localCheck(label+".K.componentIdentity", ...
        residual<=tolIdentity,residual,tolIdentity, ...
        "K equals elastic, prestress, aerodynamic and coordinate-transport terms.",true); %#ok<AGROW>
end

if positiveMass && isfield(level,'M') && ~isempty(level.M)
    M = (level.M+level.M.')/2;
    [~,flag] = chol(M);
    if flag == 0
        minimum = NaN;
        pass = true;
        message = "Cholesky factorization confirms strict positive definiteness.";
    else
        minimum = localSmallestEigenvalue(M);
        pass = false;
        message = "Reduced mass must be strictly positive definite.";
    end
    checks(end+1,1) = localCheck(label+".M.positive",pass,minimum, ...
        tolPos,message,true); %#ok<AGROW>
end
end

function checks = localTransformationChecks(Tc,tolerance,requireSparse)
checks = repmat(localCheck("",true,0,0,"",false),0,1);
finite = isnumeric(Tc) && ismatrix(Tc) && all(isfinite(nonzeros(Tc)));
checks(end+1,1) = localCheck("transformation.Tc.finite",finite, ...
    double(~finite),0,"Tc entries must be finite.",true);
if requireSparse
    sparsePass = issparse(Tc);
    checks(end+1,1) = localCheck("transformation.Tc.sparse",sparsePass, ...
        double(~sparsePass),0,"Tc must remain sparse.",true);
end
if size(Tc,1) < size(Tc,2)
    fullRank = false;
    reciprocalCondition = 0;
else
    gram = Tc.'*Tc;
    [~,flag] = chol((gram+gram.')/2);
    fullRank = flag == 0;
    if fullRank
        try
            reciprocalCondition = 1/condest(gram);
        catch
            reciprocalCondition = rcond(full(gram));
        end
    else
        reciprocalCondition = 0;
    end
end
checks(end+1,1) = localCheck("transformation.Tc.fullColumnRank", ...
    fullRank,double(fullRank),1,"Tc must have full numerical column rank.",true);
checks(end+1,1) = localCheck("transformation.Tc.conditioning", ...
    reciprocalCondition>=tolerance,reciprocalCondition,tolerance, ...
    "Reciprocal condition estimate of Tc'*Tc.",true);
end

function residual = localRelativeResidual(delta,reference)
residual = norm(delta,'fro')/max(norm(reference,'fro'),eps);
end

function value = localSmallestEigenvalue(A)
n = size(A,1);
if n == 0, value = NaN; return; end
if nnz(A) == 0, value = 0; return; end
try
    if n > 12
        % ARPACK reports a recoverable non-convergence as a warning plus
        % NaN. Silence only that known warning locally; the finite check
        % below still forces the deterministic dense fallback.
        warningState=warning('query','MATLAB:eigs:NotAllEigsConverged');
        restoreWarning=onCleanup(@()warning( ...
            warningState.state,'MATLAB:eigs:NotAllEigsConverged')); %#ok<NASGU>
        warning('off','MATLAB:eigs:NotAllEigsConverged');
        value = real(eigs(A,1,'smallestreal'));
        if ~isfinite(value)
            % ARPACK may return NaN with flag~=0 instead of throwing.  A
            % deterministic dense fallback prevents a false acceptance or
            % rejection in that case.
            value = min(real(eig(full(A))));
        end
    else
        value = min(real(eig(full(A))));
    end
catch
    value = min(real(eig(full(A))));
end
end

function [fullOps,reducedOps] = localOperatorLevels(ops)
fullOps = struct(); reducedOps = struct();
if isstruct(ops) && isfield(ops,'full') && isstruct(ops.full)
    fullOps = ops.full;
end
if isstruct(ops) && isfield(ops,'reduced') && isstruct(ops.reduced)
    reducedOps = ops.reduced;
end
if isempty(fieldnames(reducedOps)) && isstruct(ops), reducedOps = ops; end
end

function value = localGet(source,names)
value = [];
for index = 1:numel(names)
    if isstruct(source) && isfield(source,names{index}) && ...
            ~isempty(source.(names{index}))
        value = source.(names{index});
        return
    end
end
end

function item = localCheck(name,pass,value,tolerance,message,critical)
item = struct('name',string(name),'pass',logical(pass),'value',value, ...
    'tolerance',tolerance,'message',string(message), ...
    'critical',logical(critical));
end

function value = localCfg(cfg,path,fallback)
value = fallback; cursor = cfg;
for index = 1:numel(path)
    if ~isstruct(cursor) || ~isfield(cursor,path{index}), return; end
    cursor = cursor.(path{index});
end
if isnumeric(cursor) && isscalar(cursor) && isfinite(cursor), value = cursor; end
end

function value = localLogicalCfg(cfg,path,fallback)
value = fallback; cursor = cfg;
for index = 1:numel(path)
    if ~isstruct(cursor) || ~isfield(cursor,path{index}), return; end
    cursor = cursor.(path{index});
end
if (islogical(cursor) || isnumeric(cursor)) && isscalar(cursor)
    value = logical(cursor);
end
end
