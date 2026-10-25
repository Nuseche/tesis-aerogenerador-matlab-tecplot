function [Ke,Me,elementData] = timoshenko3d_matrices(varargin)
%TIMOSHENKO3D_MATRICES Two-node 3-D Timoshenko beam matrices.
%   [K,M,DATA] = ... (L,SECTION[,CFG]) returns local matrices.
%   [K,M,DATA] = ... (xI,xJ,auxPoint,SECTION[,CFG]) returns global matrices.
%
%   The default cfg.element.formulation="closed_exact" preserves the
%   locking-free closed element used by the solver. Setting it to
%   "selective_integration" uses linear generalized fields, two Gauss
%   points for extension/torsion/curvature, one point for every stiffness
%   term containing shear, and two points for constant sectional mass.
%   Complete coupled K6 is supported by selective integration. Complete
%   physical M6 is preserved by both formulations.
%
%   Nodal DOFs are [u v w theta_x theta_y theta_z] at nodes I and J.

    [L,section,R,Te,isGlobal,cfg,rotationInfo] = parseInputs(varargin{:});
    [K6,stiffnessInfo] = elements.section_stiffness(section,cfg);
    [M6,massInfo] = elements.section_mass(section,cfg);
    formulation = requestedFormulation(section,cfg);

    switch formulation
        case "closed_exact"
            if stiffnessInfo.isCoupled
                error("elements:timoshenko3d_matrices:CoupledClosedStiffness", ...
                    "The closed_exact formulation requires diagonal K6. " + ...
                    "Use cfg.element.formulation='selective_integration' for coupled K6.");
            end
            [KeLocal,phiY,phiZ,gaussInfo,recovery] = ...
                closedExactStiffness(K6,L);
            [MeLocal,massRule] = closedExactMass(M6,L,phiY,phiZ);
            gaussInfo.mass = massRule;
        case "selective_integration"
            if any(~isfinite(K6(:)))
                error("elements:timoshenko3d_matrices:InfiniteSelectiveStiffness", ...
                    "selective_integration requires finite K6 entries.");
            end
            [KeLocal,gaussInfo,recovery] = selectiveStiffness(K6,L);
            [MeLocal,massRule] = selectiveMass(M6,L);
            gaussInfo.mass = massRule;
            phiY = shearParameter(K6(6,6),K6(2,2),L);
            phiZ = shearParameter(K6(5,5),K6(3,3),L);
        otherwise
            error("elements:timoshenko3d_matrices:UnknownFormulation", ...
                "Unsupported Timoshenko formulation '%s'.",formulation);
    end

    diagnostics = validateElementMatrices(KeLocal,MeLocal,L,cfg);
    KeLocal = (KeLocal+KeLocal.')/2;
    MeLocal = (MeLocal+MeLocal.')/2;
    if isGlobal
        Ke = Te.'*KeLocal*Te;
        Me = Te.'*MeLocal*Te;
    else
        Ke = KeLocal;
        Me = MeLocal;
    end
    Ke = (Ke+Ke.')/2;
    Me = (Me+Me.')/2;

    elementData = struct("L",L,"length",L,"R",R,"Te",Te, ...
        "transformation",Te,"KeLocal",KeLocal,"Klocal",KeLocal, ...
        "MeLocal",MeLocal,"Mlocal",MeLocal,"K6",K6,"M6",M6, ...
        "formulation",formulation,"phiY",phiY,"phiZ",phiZ, ...
        "gauss",gaussInfo,"recovery",recovery, ...
        "recoveryConvention", ...
            "epsilon=recovery(k).B*qLocal; resultant=K6*epsilon", ...
        "symmetryErrorK",diagnostics.symmetryErrorK, ...
        "symmetryErrorM",diagnostics.symmetryErrorM, ...
        "minMassEigenvalue",diagnostics.minMassEigenvalue, ...
        "minimumStiffnessEigenvalue",diagnostics.minimumStiffnessEigenvalue, ...
        "stiffnessSingularValues",diagnostics.stiffnessSingularValues, ...
        "rigidModeCount",diagnostics.rigidModeCount, ...
        "rigidEnergyResidual",diagnostics.rigidEnergyResidual, ...
        "sectionId",sectionIdentifier(section), ...
        "sectionStiffness",stiffnessInfo,"sectionMass",massInfo, ...
        "rotation",rotationInfo, ...
        "coordinates",string(choose(isGlobal,"global","local")));
end

function [L,section,R,Te,isGlobal,cfg,rotationInfo] = parseInputs(varargin)
    cfg = struct();
    if numel(varargin) >= 2 && isscalar(varargin{1}) && isstruct(varargin{2})
        L = double(varargin{1});
        section = varargin{2};
        if numel(varargin) >= 3,cfg = varargin{3};end
        R = eye(3);Te = eye(12);isGlobal = false;
        rotationInfo = localRotationInfo();
    elseif numel(varargin) >= 2 && isstruct(varargin{1}) && isscalar(varargin{2})
        section = varargin{1};
        L = double(varargin{2});
        if numel(varargin) >= 3,cfg = varargin{3};end
        R = eye(3);Te = eye(12);isGlobal = false;
        rotationInfo = localRotationInfo();
    elseif numel(varargin) >= 4
        xI = reshape(double(varargin{1}),1,[]);
        xJ = reshape(double(varargin{2}),1,[]);
        aux = reshape(double(varargin{3}),1,[]);
        section = varargin{4};
        if numel(varargin) >= 5,cfg = varargin{5};end
        [R,Te,L,rotationInfo] = elements.element_rotation_matrix(xI,xJ,aux,cfg);
        isGlobal = true;
    else
        error("elements:timoshenko3d_matrices:InvalidInput", ...
            "Use (L,section[,cfg]) for local or " + ...
            "(xI,xJ,auxPoint,section[,cfg]) for global matrices.");
    end
    if ~isfinite(L) || L <= 0
        error("elements:timoshenko3d_matrices:InvalidLength", ...
            "Element length must be positive and finite.");
    end
    if ~isstruct(section) || ~isscalar(section)
        error("elements:timoshenko3d_matrices:InvalidSection", ...
            "section must be a scalar struct.");
    end
    if isempty(cfg),cfg = struct();end
    if ~isstruct(cfg)
        error("elements:timoshenko3d_matrices:InvalidConfiguration", ...
            "cfg must be a struct when supplied.");
    end
end

function info = localRotationInfo()
    info = struct("orthogonalityError",0,"determinant",1, ...
        "auxProjectionNorm",NaN,"lengthTolerance",0, ...
        "projectionTolerance",NaN,"usedDefaultAuxiliary",false, ...
        "e1",[1;0;0],"e2",[0;1;0],"e3",[0;0;1]);
end

function formulation = requestedFormulation(section,cfg)
    formulation = "closed_exact";
    if isfield(section,"elementFormulation") && ~isempty(section.elementFormulation)
        formulation = string(section.elementFormulation);
    end
    paths = {{"timoshenko","formulation"}, ...
        {"elements","timoshenkoFormulation"}, ...
        {"elements","formulation"},{"element","formulation"}};
    for k = 1:numel(paths)
        candidate = nested(cfg,paths{k});
        if ~isempty(candidate),formulation = string(candidate);end
    end
    formulation = lower(strtrim(formulation));
    if any(formulation == ["closed","exact","closed_form","closed-form"])
        formulation = "closed_exact";
    elseif any(formulation == ["selective","sri","selective-integration"])
        formulation = "selective_integration";
    end
end

function value = nested(s,path)
    value = [];
    cursor = s;
    for k = 1:numel(path)
        if ~isstruct(cursor) || ~isfield(cursor,path{k}),return,end
        cursor = cursor.(path{k});
    end
    if ~isempty(cursor),value = cursor;end
end

function [K,phiY,phiZ,gaussInfo,recovery] = closedExactStiffness(D,L)
    EA = D(1,1);GAy = D(2,2);GAz = D(3,3);
    GJ = D(4,4);EIy = D(5,5);EIz = D(6,6);
    phiY = shearParameter(EIz,GAy,L); % v and theta_z
    phiZ = shearParameter(EIy,GAz,L); % w and theta_y
    K = zeros(12);
    K([1 7],[1 7]) = (EA/L)*[1 -1;-1 1];
    K([4 10],[4 10]) = (GJ/L)*[1 -1;-1 1];
    K([2 6 8 12],[2 6 8 12]) = bendingStiffness(EIz,L,phiY,1);
    K([3 5 9 11],[3 5 9 11]) = bendingStiffness(EIy,L,phiZ,-1);
    [xi,w] = elements.gauss_rule(2);
    recovery = makeRecovery(xi,w,L,"closed_exact",phiY,phiZ);
    gaussInfo = struct("axialBending",ruleData(xi,w,L), ...
        "shear","embedded_in_closed_exact", ...
        "description","locking-free closed Timoshenko stiffness");
end

function [K,gaussInfo,recovery] = selectiveStiffness(D,L)
    [xiAB,wAB] = elements.gauss_rule(2);
    [xiS,wS] = elements.gauss_rule(1);
    K = zeros(12);
    for k = 1:numel(xiAB)
        [Bab,~,~,shape] = elements.timoshenko_B_matrices(xiAB(k),L);
        K = K + (Bab.'*D*Bab)*(shape.jacobian*wAB(k));
    end
    for k = 1:numel(xiS)
        [Bab,Bs,~,shape] = elements.timoshenko_B_matrices(xiS(k),L);
        shearAndCross = Bs.'*D*Bs + Bab.'*D*Bs + Bs.'*D*Bab;
        K = K + shearAndCross*(shape.jacobian*wS(k));
    end
    recovery = makeRecovery(xiAB,wAB,L,"selective_integration",NaN,NaN);
    gaussInfo = struct("axialBending",ruleData(xiAB,wAB,L), ...
        "shear",ruleData(xiS,wS,L), ...
        "description","2-point axial/torsion/curvature; 1-point shear and cross terms");
end

function [M,rule] = selectiveMass(H,L)
    [xi,w] = elements.gauss_rule(2);
    M = zeros(12);
    for k = 1:numel(xi)
        [~,~,N6,shape] = elements.timoshenko_B_matrices(xi(k),L);
        M = M + (N6.'*H*N6)*(shape.jacobian*w(k));
    end
    rule = ruleData(xi,w,L);
    rule.interpolation = "linear_6_field";
end

function [M,rule] = closedExactMass(H,L,phiY,phiZ)
    [xi,w] = elements.gauss_rule(4);
    M = zeros(12);
    for k = 1:numel(xi)
        N = closedKinematicMatrix(xi(k),L,phiY,phiZ);
        M = M + (N.'*H*N)*(L/2*w(k));
    end
    rule = ruleData(xi,w,L);
    rule.interpolation = "closed_shear_flexible";
end

function N = closedKinematicMatrix(xi,L,phiY,phiZ)
    s = (xi+1)/2;
    powers = [1 s s^2 s^3];
    [CvY,CrY] = bendingInterpolationCoefficients(L,phiY);
    [CvZ,CrZ] = bendingInterpolationCoefficients(L,phiZ);
    signZ = diag([1 -1 1 -1]);
    N = zeros(6,12);
    N(1,[1 7]) = [1-s,s];
    N(4,[4 10]) = [1-s,s];
    N(2,[2 6 8 12]) = powers*CvY;
    N(6,[2 6 8 12]) = powers*CrY;
    N(3,[3 5 9 11]) = powers*CvZ*signZ;
    N(5,[3 5 9 11]) = -powers*CrZ*signZ;
end

function recovery = makeRecovery(xi,weights,L,formulation,phiY,phiZ)
    template = struct("xi",0,"weight",0,"x",0,"BaxialBending",[], ...
        "Bshear",[],"B",[],"N6",[]);
    recovery = repmat(template,numel(xi),1);
    for k = 1:numel(xi)
        if formulation == "closed_exact"
            [B,N6] = closedStrainAndKinematics(xi(k),L,phiY,phiZ);
            Bab = B;
            Bab(2:3,:) = 0;
            Bs = zeros(6,12);
            Bs(2:3,:) = B(2:3,:);
        else
            [Bab,Bs,N6] = elements.timoshenko_B_matrices(xi(k),L);
            B = Bab+Bs;
        end
        recovery(k) = struct("xi",xi(k),"weight",weights(k), ...
            "x",(xi(k)+1)*L/2,"BaxialBending",Bab, ...
            "Bshear",Bs,"B",B,"N6",N6);
    end
end

function [B,N] = closedStrainAndKinematics(xi,L,phiY,phiZ)
    s = (xi+1)/2;
    powers = [1 s s^2 s^3];
    derivative = [0 1 2*s 3*s^2]/L;
    [CvY,CrY] = bendingInterpolationCoefficients(L,phiY);
    [CvZ,CrZ] = bendingInterpolationCoefficients(L,phiZ);
    signZ = diag([1 -1 1 -1]);
    N = closedKinematicMatrix(xi,L,phiY,phiZ);
    B = zeros(6,12);
    B(1,[1 7]) = [-1/L,1/L];
    B(4,[4 10]) = [-1/L,1/L];
    indicesY = [2 6 8 12];
    B(2,indicesY) = derivative*CvY-powers*CrY;
    B(6,indicesY) = derivative*CrY;
    indicesZ = [3 5 9 11];
    B(3,indicesZ) = (derivative*CvZ-powers*CrZ)*signZ;
    B(5,indicesZ) = -derivative*CrZ*signZ;
end

function [Cv,Cr] = bendingInterpolationCoefficients(L,phi)
    d = 1+phi;
    Cv = [1+phi,0,0,0; ...
        -phi,L*(1+phi/2),phi,-L*phi/2; ...
        -3,-L*(2+phi/2),3,-L*(1-phi/2); ...
        2,L,-2,L]/d;
    Cr = [0,1+phi,0,0; ...
        -6/L,-(4+phi),6/L,-(2-phi); ...
        6/L,3,-6/L,3; ...
        0,0,0,0]/d;
end

function phi = shearParameter(EI,GA,L)
    if isinf(GA)
        phi = 0;
    else
        phi = 12*EI/(GA*L^2);
    end
end

function K = bendingStiffness(EI,L,phi,rotationSign)
    a = 12*EI/(L^3*(1+phi));
    b = rotationSign*6*EI/(L^2*(1+phi));
    c = (4+phi)*EI/(L*(1+phi));
    d = (2-phi)*EI/(L*(1+phi));
    K = [a b -a b;b c -b d;-a -b a -b;b d -b c];
end

function diagnostics = validateElementMatrices(K,M,L,cfg)
    if any(~isfinite(K(:))) || any(~isfinite(M(:)))
        error("elements:timoshenko3d_matrices:NonFiniteMatrix", ...
            "Element stiffness and mass matrices must be finite.");
    end
    symmetryTolerance = cfgTolerance(cfg, ...
        ["matrixSymmetry","symmetryTolerance"],1e-12);
    symmetryErrorK = norm(K-K.',"fro")/max(norm(K,"fro"),eps);
    symmetryErrorM = norm(M-M.',"fro")/max(norm(M,"fro"),eps);
    if symmetryErrorK > symmetryTolerance || symmetryErrorM > symmetryTolerance
        error("elements:timoshenko3d_matrices:NonSymmetricMatrix", ...
            "Element symmetry residuals K=%.3e, M=%.3e exceed %.3e.", ...
            symmetryErrorK,symmetryErrorM,symmetryTolerance);
    end
    Ksym = (K+K.')/2;
    Msym = (M+M.')/2;
    stiffnessEigenvalues = eig(Ksym);
    massEigenvalues = eig(Msym);
    minimumStiffnessEigenvalue = min(stiffnessEigenvalues);
    minMassEigenvalue = min(massEigenvalues);
    positiveTolerance = cfgTolerance(cfg,["positiveTolerance"],1e-10);
    if minMassEigenvalue < -positiveTolerance*max(norm(Msym,2),1)
        error("elements:timoshenko3d_matrices:IndefiniteMass", ...
            "Element mass has a negative eigenvalue %.6e.",minMassEigenvalue);
    end
    rigidTolerance = cfgTolerance(cfg,["rigidEnergyRelative"],1e-10);
    rigidMotions = rigidMotionMatrix(L);
    [rigidBasis,~] = qr(rigidMotions,0);
    deformationBasis = null(rigidBasis.');
    deformationStiffness = deformationBasis.'*Ksym*deformationBasis;
    deformationStiffness = (deformationStiffness+deformationStiffness.')/2;
    deformationDiagonal = diag(deformationStiffness);
    [~,deformationCholeskyFailure] = chol(deformationStiffness);
    if deformationCholeskyFailure == 0
        deformationRank = size(deformationStiffness,1);
        diagonalScaling = diag(1./sqrt(deformationDiagonal));
        scaledDeformation = diagonalScaling*deformationStiffness*diagonalScaling;
        scaledDeformation = (scaledDeformation+scaledDeformation.')/2;
        scaledDeformationEigenvalues = eig(scaledDeformation);
    elseif any(deformationDiagonal <= 0)
        deformationRank = nnz(svd(deformationStiffness) > ...
            rigidTolerance*max(norm(deformationStiffness,2),eps));
        scaledDeformationEigenvalues = eig(deformationStiffness);
    else
        diagonalScaling = diag(1./sqrt(deformationDiagonal));
        scaledDeformation = diagonalScaling*deformationStiffness*diagonalScaling;
        scaledDeformation = (scaledDeformation+scaledDeformation.')/2;
        scaledDeformationEigenvalues = eig(scaledDeformation);
        deformationRank = nnz(scaledDeformationEigenvalues > rigidTolerance);
    end
    rigidModeCount = size(Ksym,1)-deformationRank;
    rigidEnergyResidual = norm(Ksym*rigidMotions,"fro") / ...
        max(norm(Ksym,"fro")*norm(rigidMotions,"fro"),eps);
    if rigidEnergyResidual > rigidTolerance
        error("elements:timoshenko3d_matrices:RigidMotionFailure", ...
            "Rigid-motion stiffness residual %.3e exceeds tolerance %.3e.", ...
            rigidEnergyResidual,rigidTolerance);
    end
    if rigidModeCount ~= 6 || deformationCholeskyFailure ~= 0
        error("elements:timoshenko3d_matrices:RigidModeCount", ...
            "A free two-node beam must have exactly six rigid modes; " + ...
            "detected %d after scaled deformational-subspace analysis.", ...
            rigidModeCount);
    end
    singularValues = svd(Ksym);
    diagnostics = struct("symmetryErrorK",symmetryErrorK, ...
        "symmetryErrorM",symmetryErrorM, ...
        "minimumStiffnessEigenvalue",minimumStiffnessEigenvalue, ...
        "minMassEigenvalue",minMassEigenvalue, ...
        "stiffnessSingularValues",singularValues, ...
        "rigidModeCount",rigidModeCount, ...
        "rigidEnergyResidual",rigidEnergyResidual);
end

function Q = rigidMotionMatrix(L)
    Q = zeros(12,6);
    Q([1 7],1) = 1;
    Q([2 8],2) = 1;
    Q([3 9],3) = 1;
    Q([4 10],4) = 1;
    Q([5 11],5) = 1;Q(9,5) = -L;
    Q([6 12],6) = 1;Q(8,6) = L;
end

function data = ruleData(xi,weights,L)
    data = struct("points",xi(:),"weights",weights(:), ...
        "jacobian",L/2,"order",numel(xi));
end

function id = sectionIdentifier(section)
    if isfield(section,"id") && ~isempty(section.id)
        id = section.id;
    else
        id = NaN;
    end
end

function value = cfgTolerance(cfg,names,fallback)
    value = fallback;
    if ~isstruct(cfg),return,end
    if isfield(cfg,"validation") && isstruct(cfg.validation),cfg = cfg.validation;end
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

function result = choose(condition,a,b)
    if condition,result = a;else,result = b;end
end
