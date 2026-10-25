% Follow-up within the same cumulative 900 s solver budget, no core changes.
root='/Users/nuseche/Desktop/Tesis_codigos';docs=fullfile(root,'docs/entradas_reales_20261020');
folder=fullfile(root,'runs/sensitivity/real_inputs_20261020');addpath(fullfile(docs,'scripts'));
z=load(fullfile(folder,'comparison_design.mat'),'cases');cases=z.cases;
cases=cases([cases.kind]=="earthquake");
started=tic;spent=0;files=dir(fullfile(folder,'*.mat'));
for j=1:numel(files)
    a=load(fullfile(files(j).folder,files(j).name),'r');
    if isfield(a,'r'),spent=spent+a.r.elapsedSeconds;end
end
status=cell(0,4);
for j=1:numel(cases)
    c=cases(j);id="aligned_"+c.id;path=fullfile(folder,id+".mat");
    if isfile(path),status(end+1,:)={id,"success_reused",NaN,""};continue,end
    if spent+toc(started)>900,status(end+1,:)={id,"pending_budget",NaN,""};continue,end
    fprintf('ALIGNED %d/%d %s\n',j,numel(cases),id);
    try
        r=snapshot_input_case(c.file,c.factors,c.dt,c.kind,1000,c.limit,1);
        assert(r.dynamicResidual<1e-8);save(path,'r','-v7.3');
        status(end+1,:)={id,"success",r.elapsedSeconds,""};fprintf('SUCCESS %.2f s\n',r.elapsedSeconds);
    catch e
        status(end+1,:)={id,"failed",NaN,string(getReport(e,'extended','hyperlinks','off'))};
    end
    writetable(cell2table(status,'VariableNames',{'caseId','status','seconds','message'}),fullfile(folder,'aligned_status.csv'));
end
writetable(cell2table(status,'VariableNames',{'caseId','status','seconds','message'}),fullfile(folder,'aligned_status.csv'));
path=fullfile(folder,'aligned_ARL360_nominal_dt02500_repeat.mat');
if ~isfile(path)&&spent+toc(started)<=900
    r=snapshot_input_case(fullfile(docs,'tables/ARL360_SI.csv'),struct(),.0025,"earthquake",500,39.98,1);
    save(path,'r','-v7.3');
end
