root='/Users/nuseche/Desktop/Tesis_codigos';docs=fullfile(root,'docs/entradas_reales_20261020');
folder=fullfile(root,'runs/sensitivity/real_inputs_20261020/numerical_diagnostic');if ~isfolder(folder),mkdir(folder);end
addpath(fullfile(docs,'scripts'));file=fullfile(docs,'tables/ARL360_SI.csv');
design=struct('id',{},'scale',{},'factor',{});
for scale=[5 10 20]
    design(end+1)=struct('id',string(sprintf('nominal_scale%d',scale)),'scale',scale,'factor',1);
end
for h=[.005 .0025]
    for sg=[-1 1]
        design(end+1)=struct('id',string(sprintf('mass_scale20_h%03d_s%+d',round(h*1e4),sg)),'scale',20,'factor',1+sg*h);
    end
end
rows=cell(0,9);
for j=1:numel(design)
    d=design(j);path=fullfile(folder,d.id+".mat");
    try
        if isfile(path),z=load(path,'r');r=z.r;
        else
            fprintf('TANGENT DIAGNOSTIC %s\n',d.id);
            r=snapshot_input_case(file,struct('blade_density',d.factor),.005,"earthquake",1000,39.98,1,-d.scale);
            save(path,'r','-v7.3');
        end
        q=vecnorm(r.historyQ(1:2,:));rmsQ=sqrt(trapz(r.t,(q.^2).')/(r.t(end)-r.t(1)));
        rows(end+1,:)={d.id,d.scale,d.factor,max(q),rmsQ,r.dynamicResidual,r.equilibriumResidual,r.elapsedSeconds,"success"};
    catch e
        rows(end+1,:)={d.id,d.scale,d.factor,NaN,NaN,NaN,NaN,NaN,string(e.message)};
    end
    writetable(cell2table(rows,'VariableNames',{'caseId','derivativeScale','massFactor','peakQ','rmsQ','dynamicResidual','equilibriumResidual','seconds','status'}),fullfile(docs,'tables/tangent_diagnostic.csv'));
end
disp(cell2table(rows,'VariableNames',{'caseId','derivativeScale','massFactor','peakQ','rmsQ','dynamicResidual','equilibriumResidual','seconds','status'}));
