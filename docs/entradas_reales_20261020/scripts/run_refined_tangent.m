% Same energy and converged equilibrium; verify a refined dynamic Hessian.
root=fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));docs=fullfile(root,'docs/entradas_reales_20261020');
folder=fullfile(root,'runs/sensitivity/real_inputs_20261020/refined_tangent');if ~isfolder(folder),mkdir(folder);end
addpath(fullfile(docs,'scripts'));started=tic;maximumSeconds=600;
design=struct('id',{},'kind',{},'scale',{},'factors',{},'h',{},'dt',{},'last',{});
for kind=["earthquake" "wind"]
    for scale=[20 40]
        design(end+1)=struct('id',string(sprintf('%s_nominal_k%d_dt02500',kind,scale)), ...
            'kind',kind,'scale',scale,'factors',struct(),'h',0,'dt',.0025,'last',39.98);
    end
    design(end+1)=struct('id',kind+"_nominal_k20_dt01250",'kind',kind,'scale',20,'factors',struct(),'h',0,'dt',.00125,'last',39.98);
    for parameter=["blade_density" "blade_stiffness" "rotor_speed"]
        % Same h at two internal Hessian steps; two h at the selected step;
        % repeat the smaller h at coarser Newmark dt.
        for spec=[20 .005 .0025;20 .0025 .0025;20 .0025 .005;40 .0025 .0025].'
            scale=spec(1);h=spec(2);dt=spec(3);
            for sg=[-1 1]
                f=struct();f.(parameter)=1+sg*h;
                id=string(sprintf('%s_%s_k%d_h%03d_s%+d_dt%05d',kind,parameter,scale,round(h*1e4),sg,round(dt*1e6)));
                design(end+1)=struct('id',id,'kind',kind,'scale',scale,'factors',f,'h',h,'dt',dt,'last',39.98);
            end
        end
    end
end
status=cell(0,4);
for j=1:numel(design)
    d=design(j);path=fullfile(folder,d.id+".mat");
    if isfile(path),status(end+1,:)={d.id,"success_reused",NaN,""};continue,end
    if toc(started)>maximumSeconds,status(end+1,:)={d.id,"pending_budget",NaN,""};continue,end
    if d.kind=="earthquake",file=fullfile(docs,'tables/ARL360_SI.csv');else,file=fullfile(docs,'tables/wind_DTU_s70u_SI.csv');end
    fprintf('REFINED TANGENT %d/%d %s\n',j,numel(design),d.id);
    try
        r=snapshot_input_case(file,d.factors,d.dt,d.kind,1000,d.last,1,d.scale);
        assert(r.dynamicResidual<1e-8);save(path,'r','-v7.3');
        status(end+1,:)={d.id,"success",r.elapsedSeconds,""};
    catch e
        status(end+1,:)={d.id,"failed",NaN,string(getReport(e,'extended','hyperlinks','off'))};
    end
    writetable(cell2table(status,'VariableNames',{'caseId','status','seconds','message'}),fullfile(folder,'case_status.csv'));
end
writetable(cell2table(status,'VariableNames',{'caseId','status','seconds','message'}),fullfile(folder,'case_status.csv'));
save(fullfile(folder,'design.mat'),'design','maximumSeconds');
