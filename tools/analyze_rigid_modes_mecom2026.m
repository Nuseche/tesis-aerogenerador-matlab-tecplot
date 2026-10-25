function summary = analyze_rigid_modes_mecom2026(action)
%ANALYZE_RIGID_MODES_MECOM2026 Raw, scaled and analytic rigid-mode evidence.
% No eigenvalue is rounded to zero in the raw spectra. Exact zeros in the
% explicitly separated model are labelled as analytically imposed, not as
% output of an unmodified generalized eigensolver.
projectRoot = fileparts(fileparts(mfilename('fullpath')));
outputFolder = fullfile(projectRoot,'runs','run_20260914_mecom_rigid_modes');
if ~isfolder(outputFolder), mkdir(outputFolder); end
if nargin > 0 && string(action)=="figures"
    stored=load(fullfile(outputFolder,'rigid_mode_evidence.mat'), ...
        'summary','spectra','singular');
    makeFigures(outputFolder,stored.spectra,stored.singular);
    summary=stored.summary;
    return
end
addpath(projectRoot,fullfile(projectRoot,'cases'));
warningState = warning('query','MATLAB:eigs:IllConditionedA');
cleanup = onCleanup(@() warning(warningState.state,warningState.identifier)); %#ok<NASGU>
warning('off','MATLAB:eigs:IllConditionedA');
rng(20260914,'twister');

section = struct('id',1,'EA',2.1e9,'GAy',4e8,'GAz',3e8, ...
    'GJ',1.5e8,'EIy',8e7,'EIz',6e7,'m',25,'Jx',2, ...
    'Jy',1.2,'Jz',1.4,'ycg',0,'zcg',0);
[Kp,Mp,primitiveInfo] = elements.timoshenko3d_matrices(5,section);
Rp = rigidMotions([0 0 0;5 0 0],reshape(1:12,6,2).');

cfg = config_action06_equilibrium();
cfg.base.type = "free";
cfg.base.fixedNodeIds = zeros(0,1);
cfg.gravity.enabled = false;
cfg.rotor.speedRPM = 0;
cfg.rotor.speedRPMGrid = 0;
cfg.output.makeFigures = false;
cfg.output.plotGeometry = false;
data = io.load_model_data(cfg);
modelData = model.build_model(data,cfg);
model.validate_model(modelData,cfg);
[Ma,Ka] = assembly.assemble_structural_matrices(modelData,cfg);
[Md,~] = assembly.apply_mass_formulation(Ma,cfg,modelData);
Ma = rigid.add_body_masses(Md,modelData,modelData.rigidBodies);
Tc = rigid.rigid_constraint_matrix(modelData,modelData.rigidBodies,cfg);
reduced = rigid.reduce_system(Tc,Ma,Ka,modelData,cfg);
Mf = reduced.M; Kf = reduced.Ke;
Rfull = rigidMotions(modelData.mesh.nodes.xyz,modelData.dofs.node);
Rf = Tc\Rfull;
compatibility = norm(Tc*Rf-Rfull,'fro')/norm(Rfull,'fro');
fixedFull = modelData.dofs.node(1,:).';
fixedReduced = zeros(6,1);
for j = 1:6
    [~,column,value] = find(Tc(fixedFull(j),:));
    assert(numel(column)==1 && abs(value-1)<100*eps);
    fixedReduced(j) = column;
end
active = setdiff((1:size(Tc,2)).',fixedReduced,'stable');
Mb = Mf(active,active); Kb = Kf(active,active);

models = {struct('name',"primitive_12",'M',Mp,'K',Kp,'R',Rp), ...
    struct('name',"global_free_810",'M',Mf,'K',Kf,'R',Rf), ...
    struct('name',"global_fixed_804",'M',Mb,'K',Kb,'R',[])};
spectra = table(); singular = table(); summaries = struct([]);
subspaces = struct();
for c = 1:numel(models)
    item = models{c}; M = full(item.M); K = full(item.K); n = size(K,1);
    [V,lambda] = eig(K,M,'vector');
    spectra = [spectra;spectrumRows(item.name,"raw_generalized_eig", ...
        K,M,V,lambda)]; %#ok<AGROW>

    S = diag(1./sqrt(diag(K)));
    Keq = S*K*S; Meq = S*M*S;
    [Veq,lambdaEq] = eig((Keq+Keq.')/2,(Meq+Meq.')/2,'vector');
    spectra = [spectra;spectrumRows(item.name,"stiffness_diagonal_equilibrated", ...
        K,M,S*Veq,lambdaEq)]; %#ok<AGROW>

    L = chol(M,'lower');
    A = L\K/L.'; A = (A+A.')/2;
    [Vm,lambdaM] = eig(A,'vector');
    spectra = [spectra;spectrumRows(item.name,"mass_whitened_eig", ...
        K,M,L.'\Vm,lambdaM)]; %#ok<AGROW>
    if n > 40
        options = struct('tol',1e-11,'maxit',5000,'isreal',true);
        [Vs,Ds] = eigs(sparse(K),sparse(M),18,'smallestabs',options);
        spectra = [spectra;spectrumRows(item.name,"raw_sparse_eigs", ...
            K,M,Vs,diag(Ds))]; %#ok<AGROW>
    end

    rawS = sort(svd(K),'ascend');
    eqS = sort(svd(Keq),'ascend');
    massS = sort(svd(A),'ascend');
    for scaleName = ["raw_stiffness","diagonal_equilibrated","mass_whitened"]
        if scaleName == "raw_stiffness", s = rawS; end
        if scaleName == "diagonal_equilibrated", s = eqS; end
        if scaleName == "mass_whitened", s = massS; end
        singular = [singular;table(repmat(item.name,n,1), ...
            repmat(scaleName,n,1),(1:n).',s,s/max(s), ...
            'VariableNames',{'caseName','scaling','ascendingIndex', ...
            'singularValue','normalizedSingularValue'})]; %#ok<AGROW>
    end

    info = struct('caseName',item.name,'coordinates',n, ...
        'expectedRigidDimension',size(item.R,2),'normwiseRigidResidual',NaN, ...
        'compatibilityResidual',NaN,'massWhitenedRigidResidual',NaN, ...
        'rigidMassOrthogonalityError',NaN,'smallestComplementEigenvalue',NaN, ...
        'firstComplementFrequencyHz',NaN,'complementCholeskyFailure',NaN, ...
        'exactRigidBlockDimension',0,'explicitSeparationRelativePerturbation',NaN, ...
        'normalizedSingularValueSix',eqS(6)/max(eqS), ...
        'normalizedSingularValueSeven',eqS(7)/max(eqS), ...
        'seventhToSixthSingularValueRatio',eqS(7)/max(eqS(6),realmin), ...
        'massWhitenedNorm2',norm(A,2),'machineEpsilon',eps);
    if ~isempty(item.R)
        R = item.R;
        info.normwiseRigidResidual = norm(K*R,'fro')/(norm(K,'fro')*norm(R,'fro'));
        if c==2, info.compatibilityResidual = compatibility; else, info.compatibilityResidual=0; end
        [Q,~] = qr(L.'*R);
        Qr = Q(:,1:6); Qe = Q(:,7:end);
        info.massWhitenedRigidResidual = norm(A*Qr,'fro')/(norm(A,'fro')*norm(Qr,'fro'));
        info.rigidMassOrthogonalityError = norm(Qr.'*Qr-eye(6),'fro');
        Ae = Qe.'*A*Qe; Ae = (Ae+Ae.')/2;
        [~,cholFailure] = chol(Ae);
        [Ve,lambdaE] = eig(Ae,'vector');
        info.smallestComplementEigenvalue = min(lambdaE);
        info.firstComplementFrequencyHz = sqrt(min(lambdaE))/(2*pi);
        info.complementCholeskyFailure = cholFailure;
        info.exactRigidBlockDimension = 6;
        Aideal = Qe*Ae*Qe.';
        info.explicitSeparationRelativePerturbation = norm(A-Aideal,'fro')/norm(A,'fro');
        Vseparated = L.'\[Qr,Qe*Ve];
        spectra = [spectra;spectrumRows(item.name, ...
            "analytic_rigid_block_explicitly_imposed",K,M,Vseparated,[zeros(6,1);lambdaE])]; %#ok<AGROW>
        subspaces.(char(item.name)) = struct('R',R,'Qr',Qr,'Qe',Qe, ...
            'Aelastic',Ae,'elasticEigenvalues',lambdaE,'Araw',A);
    else
        [~,cholFailure] = chol(K);
        info.complementCholeskyFailure = cholFailure;
        info.smallestComplementEigenvalue = min(lambda);
        info.firstComplementFrequencyHz = sqrt(min(lambda))/(2*pi);
    end
    summaries = [summaries;info]; %#ok<AGROW>
    fprintf('%s: n=%d; rigid residual %.17g; first elastic f %.17g Hz; chol=%d\n', ...
        item.name,n,info.normwiseRigidResidual,info.firstComplementFrequencyHz, ...
        info.complementCholeskyFailure);
end
summary = struct2table(summaries);
writetable(summary,fullfile(outputFolder,'rigid_subspace_summary.csv'));
writetable(spectra,fullfile(outputFolder,'all_raw_and_separated_spectra.csv'));
writetable(singular,fullfile(outputFolder,'all_stiffness_singular_values.csv'));

% Direct solver API diagnostics are kept separate from the eig experiments.
solverDiagnostics = table();
for c = 1:numel(models)
    item = models{c};
    r = modal.solve_conservative_modes(item.M,item.K, ...
        struct('number',min(18,size(item.K,1)),'rigidToleranceHz',1e-4));
    count = numel(r.eigenvalues);
    solverDiagnostics = [solverDiagnostics;table(repmat(item.name,count,1), ...
        (1:count).',r.eigenvalues,r.signedFrequencyHz,r.classification, ...
        r.residual,r.normwiseResidual, ...
        'VariableNames',{'caseName','modeIndex','rawEigenvalue', ...
        'signedFrequencyHz','classification','actionScaledResidual', ...
        'normwiseResidual'})]; %#ok<AGROW>
end
writetable(solverDiagnostics,fullfile(outputFolder,'solver_api_diagnostics.csv'));

precision = symbolicPrimitive(outputFolder,Mp,Kp,Rp);
save(fullfile(outputFolder,'rigid_mode_evidence.mat'),'models','cfg','section', ...
    'primitiveInfo','summary','spectra','singular','subspaces','precision', ...
    'Tc','Rfull','Rf','compatibility','active','solverDiagnostics','-v7.3');
makeFigures(outputFolder,spectra,singular);
fprintf('Evidence output: %s\n',outputFolder);
end

function rows = spectrumRows(caseName,method,K,M,V,lambda)
lambda = real(lambda(:));
[~,order] = sort(abs(lambda),'ascend'); lambda = lambda(order); V = V(:,order);
n = numel(lambda); residual = zeros(n,1); actionResidual = zeros(n,1);
normK = norm(K,'fro'); normM = norm(M,'fro');
for j = 1:n
    v = V(:,j); r = K*v-lambda(j)*(M*v);
    residual(j) = norm(r)/max((normK+abs(lambda(j))*normM)*norm(v),realmin);
    actionResidual(j) = norm(r)/max(norm(K*v)+abs(lambda(j))*norm(M*v),realmin);
end
signedFrequency = sign(lambda).*sqrt(abs(lambda))/(2*pi);
rows = table(repmat(caseName,n,1),repmat(method,n,1),(1:n).',lambda, ...
    signedFrequency,abs(signedFrequency),residual,actionResidual, ...
    'VariableNames',{'caseName','method','absoluteSortedIndex', ...
    'rawEigenvalueRad2PerS2','signedFrequencyHz','absoluteFrequencyHz', ...
    'normwiseEigenpairResidual','actionScaledEigenpairResidual'});
end

function R = rigidMotions(xyz,dofs)
R = zeros(6*size(xyz,1),6);
for j=1:size(xyz,1)
    x=xyz(j,:).'; d=dofs(j,:);
    S=[0 -x(3) x(2);x(3) 0 -x(1);-x(2) x(1) 0];
    R(d(1:3),1:3)=eye(3);
    R(d(1:3),4:6)=-S;
    R(d(4:6),4:6)=eye(3);
end
end

function precision = symbolicPrimitive(outputFolder,Mdouble,Kdouble,R)
precision = struct('symbolicAvailable',false,'exactRank',NaN, ...
    'exactKernelResidualZero',false,'precisionDigits',50);
if exist('sym','file') ~= 2 || ~license('test','Symbolic_Toolbox')
    fprintf('Symbolic Math Toolbox unavailable: no high-precision claim made.\n');
    writetable(struct2table(precision),fullfile(outputFolder,'precision_summary.csv'));
    return
end
oldDigits=digits(50); cleanup=onCleanup(@() digits(oldDigits)); %#ok<NASGU>
L=sym(5); K=sym(zeros(12));
K([1 7],[1 7])=sym(2100000000)/L*[1 -1;-1 1];
K([4 10],[4 10])=sym(150000000)/L*[1 -1;-1 1];
K([2 6 8 12],[2 6 8 12])=exactBending(sym(60000000),sym(400000000),L,1);
K([3 5 9 11],[3 5 9 11])=exactBending(sym(80000000),sym(300000000),L,-1);
precision.symbolicAvailable=true;
precision.exactRank=double(rank(K));
precision.exactKernelResidualZero=all(isAlways(K*sym(R)==0),'all');
% Exact binary mass is positive and leaves the analytic K kernel unchanged.
% This isolates stiffness-roundoff from mass integration; it is not a new
% structural discretization or a claim about extra mass accuracy.
Ms=sym(Mdouble,'f');
lambdaHigh=double(eig(vpa(Ms,50)\vpa(K,50)));
lambdaBinary=double(eig(vpa(Ms,50)\vpa(sym(Kdouble,'f'),50)));
strategy=[repmat("exact_rational_K_binary_M_50_digits",12,1); ...
    repmat("binary_K_binary_M_50_digits",12,1)];
[~,i]=sort(abs(lambdaHigh));lambdaHigh=lambdaHigh(i);
[~,i]=sort(abs(lambdaBinary));lambdaBinary=lambdaBinary(i);
lambda=[lambdaHigh;lambdaBinary];
frequency=sign(lambda).*sqrt(abs(lambda))/(2*pi);
rows=table(strategy,repmat((1:12).',2,1),lambda,frequency, ...
    'VariableNames',{'strategy','absoluteSortedIndex','eigenvalueRad2PerS2','signedFrequencyHz'});
writetable(rows,fullfile(outputFolder,'primitive_high_precision_spectra.csv'));
writetable(struct2table(precision),fullfile(outputFolder,'precision_summary.csv'));
end

function K=exactBending(EI,GA,L,sgn)
phi=12*EI/(GA*L^2);
a=12*EI/(L^3*(1+phi));b=sgn*6*EI/(L^2*(1+phi));
c=(4+phi)*EI/(L*(1+phi));d=(2-phi)*EI/(L*(1+phi));
K=[a b -a b;b c -b d;-a -b a -b;b d -b c];
end

function makeFigures(outputFolder,spectra,singular)
% MECOM-ready styling: white backgrounds, Times typography and redundant
% monochrome encodings. Re-export via analyze_rigid_modes_mecom2026('figures')
% to reuse saved data without running any eigensolutions or changing tables.
fontName='Times New Roman';
lineStyles={'-','--',':'};
markers={'o','s','^'};
grayLevels=[0.05 0.32 0.55];
f=figure('Visible','off','Color','w','Units','centimeters', ...
    'Position',[2 2 18 7.5]);
t=tiledlayout(f,1,3,'TileSpacing','compact','Padding','compact');
names=["primitive_12","global_free_810","global_fixed_804"];
labels={'Elemento libre: 12 GDL','Conjunto libre: 810 GDL','Base fija: 804 GDL'};
methods=["raw_generalized_eig","stiffness_diagonal_equilibrated","mass_whitened_eig"];
for c=1:3
    ax=nexttile(t); hold(ax,'on');
    for j=1:numel(methods)
        method=methods(j);
        data=spectra(spectra.caseName==names(c)&spectra.method==method,:);
        use=1:min(12,height(data));
        plot(ax,data.absoluteSortedIndex(use),data.absoluteFrequencyHz(use), ...
            'LineStyle',lineStyles{j},'Marker',markers{j}, ...
            'Color',grayLevels(j)*ones(1,3),'MarkerFaceColor','w', ...
            'LineWidth',1.0,'MarkerSize',3.5);
    end
    set(ax,'YScale','log','FontName',fontName,'FontSize',8.5, ...
        'Color','w','XColor','k','YColor','k','GridColor',[.65 .65 .65], ...
        'MinorGridColor',[.8 .8 .8],'LabelFontSizeMultiplier',1, ...
        'TitleFontSizeMultiplier',1,'TitleFontWeight','normal');
    xlabel(ax,'Índice por |\lambda|','FontName',fontName,'Color','k');
    ylabel(ax,'|\lambda|^{1/2}/(2\pi) [Hz]', ...
        'Interpreter','tex','FontName',fontName,'Color','k');
    title(ax,labels{c},'Color','k','FontName',fontName);grid(ax,'on');
    if c==1
        ylim(ax,[1e-7 2e3]);yticks(ax,[1e-6 1e-3 1 1e3]);
    elseif c==2
        ylim(ax,[1e-6 1.2]);yticks(ax,[1e-6 1e-4 1e-2 1]);
    end
end
legend(ax,{'Generalizado','Equilibrado diagonal','Masa blanqueada'}, ...
    'Location','northwest','FontSize',6.5,'FontName',fontName, ...
    'Color','w','TextColor','k','EdgeColor',[.7 .7 .7]);
title(t,'Espectros crudos: sin redondear autovalores a cero', ...
    'Color','k','FontName',fontName,'FontWeight','normal','FontSize',10);
exportgraphics(f,fullfile(outputFolder,'raw_rigid_frequency_comparison.png'), ...
    'Resolution',300,'BackgroundColor','white');
exportgraphics(f,fullfile(outputFolder,'raw_rigid_frequency_comparison.pdf'), ...
    'ContentType','vector','BackgroundColor','white');close(f);

f=figure('Visible','off','Color','w','Units','centimeters', ...
    'Position',[2 2 18 8]);
ax=axes(f);hold(ax,'on');
for c=1:3
    data=singular(singular.caseName==names(c)&singular.scaling=="diagonal_equilibrated",:);
    use=1:min(15,height(data));
    plot(ax,data.ascendingIndex(use),data.normalizedSingularValue(use), ...
        'LineStyle',lineStyles{c},'Marker',markers{c}, ...
        'Color',grayLevels(c)*ones(1,3),'MarkerFaceColor','w', ...
        'LineWidth',1.1,'MarkerSize',4);
end
set(ax,'YScale','log','FontName',fontName,'FontSize',9, ...
    'Color','w','XColor','k','YColor','k','GridColor',[.65 .65 .65], ...
    'MinorGridColor',[.8 .8 .8],'LabelFontSizeMultiplier',1, ...
    'TitleFontSizeMultiplier',1,'TitleFontWeight','normal');
xline(ax,6.5,'--k');
yline(ax,eps,':k','\epsilon de doble precisión', ...
    'FontName',fontName,'FontSize',8,'LabelVerticalAlignment','bottom', ...
    'LabelHorizontalAlignment','left');
xlabel(ax,'Índice ascendente','FontName',fontName,'Color','k');
ylabel(ax,'\sigma_i/\sigma_{max}','Interpreter','tex', ...
    'FontName',fontName,'Color','k');grid(ax,'on');
legend(ax,labels,'Location','southeast','FontName',fontName,'FontSize',8, ...
    'Color','w','TextColor','k','EdgeColor',[.7 .7 .7]);
title(ax,'Valores singulares: rigidez con equilibrado diagonal', ...
    'Color','k','FontName',fontName,'FontSize',10);
exportgraphics(f,fullfile(outputFolder,'rigid_singular_value_gap.png'), ...
    'Resolution',300,'BackgroundColor','white');
exportgraphics(f,fullfile(outputFolder,'rigid_singular_value_gap.pdf'), ...
    'ContentType','vector','BackgroundColor','white');close(f);
end
