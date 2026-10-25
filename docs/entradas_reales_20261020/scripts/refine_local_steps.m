% Targeted refinement after failed h-dependence checks; no domain expansion.
root=fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));docs=fullfile(root,'docs/entradas_reales_20261020');
folder=fullfile(root,'runs/sensitivity/real_inputs_20261020');addpath(fullfile(docs,'scripts'));
started=tic;spent=0;files=dir(fullfile(folder,'*.mat'));
for j=1:numel(files)
    vars=whos('-file',fullfile(files(j).folder,files(j).name));
    if any(strcmp({vars.name},'r')),a=load(fullfile(files(j).folder,files(j).name),'r');spent=spent+a.r.elapsedSeconds;end
end
totalOperationalBudgetSeconds=1200;status=cell(0,5);
for kind=["earthquake" "wind"]
    if kind=="earthquake",file=fullfile(docs,'tables/ARL360_SI.csv');pre="aligned_";
    else,file=fullfile(docs,'tables/wind_DTU_s70u_SI.csv');pre="";end
    for parameter=["blade_density" "blade_stiffness" "rotor_speed"]
        for pair=[.0025 .00125 .00125;.0025 .0025 .005]
            h=pair(1);dt=pair(2);
            for sg=[-1 1]
                id=pre+string(sprintf('%s_%s_h%03d_s%+d_dt%05d',kind,parameter,round(h*1e4),sg,round(dt*1e6)));
                path=fullfile(folder,id+".mat");
                if isfile(path),status(end+1,:)={id,"success_reused",h,dt,NaN};continue,end
                if spent+toc(started)>totalOperationalBudgetSeconds
                    status(end+1,:)={id,"pending_budget",h,dt,NaN};continue
                end
                f=struct();f.(parameter)=1+sg*h;fprintf('REFINE %s, h=%.6g\n',id,h);
                r=snapshot_input_case(file,f,dt,kind,1000,39.98,1);
                assert(r.dynamicResidual<1e-8);save(path,'r','-v7.3');
                status(end+1,:)={id,"success",h,dt,r.elapsedSeconds};
                writetable(cell2table(status,'VariableNames',{'caseId','status','h','dt','seconds'}),fullfile(folder,'refinement_status.csv'));
            end
        end
    end
end
writetable(cell2table(status,'VariableNames',{'caseId','status','h','dt','seconds'}),fullfile(folder,'refinement_status.csv'));
save(fullfile(folder,'refinement_budget.mat'),'totalOperationalBudgetSeconds','spent');
