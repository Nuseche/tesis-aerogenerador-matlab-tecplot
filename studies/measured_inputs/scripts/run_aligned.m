function run_aligned(campaignFolder)
%RUN_ALIGNED Postprocess or verify the measured inputs study.
% Follow-up within the same cumulative 900 s solver budget, no core changes.
root=fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));studyDir=fullfile(root,'studies/measured_inputs');

if nargin<1 || strlength(string(campaignFolder))==0
    campaignFolder=fullfile(root,'runs','studies','measured_inputs');
end
folder=fullfile(campaignFolder);addpath(fullfile(studyDir,'scripts'));
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
    r=snapshot_input_case(fullfile(studyDir,'tables/ARL360_SI.csv'),struct(),.0025,"earthquake",500,39.98,1);
    save(path,'r','-v7.3');
end
end
