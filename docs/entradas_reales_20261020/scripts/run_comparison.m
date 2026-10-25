% Reproducible, restartable comparison. Existing campaigns are read only.
root=fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));docs=fullfile(root,'docs/entradas_reales_20261020');
addpath(root);addpath(fullfile(docs,'scripts'));
out=fullfile(root,'runs/sensitivity/real_inputs_20261020');
started=tic;maximumWallSeconds=900;
eqFile=fullfile(docs,'tables/ARL360_SI.csv');windFile=fullfile(docs,'tables/wind_DTU_s70u_SI.csv');
cases=struct('id',{},'file',{},'factors',{},'dt',{},'kind',{},'limit',{});
% Independent reference comparison against run_seismic_analysis + full recovery.
cases(end+1)=struct('id',"ARL360_optimized_dt010",'file',eqFile,'factors',struct(), ...
    'dt',.01,'kind',"earthquake",'limit',Inf);
for dt=[.005 .0025 .00125]
    cases(end+1)=struct('id',string(sprintf('ARL360_nominal_dt%05d',round(dt*1e6))), ...
        'file',eqFile,'factors',struct(),'dt',dt,'kind',"earthquake",'limit',Inf);
end
for dt=[.01 .005]
    cases(end+1)=struct('id',string(sprintf('wind_full_dt%05d',round(dt*1e6))), ...
        'file',windFile,'factors',struct(),'dt',dt,'kind',"wind",'limit',Inf);
end
for dt=[.0025 .00125]
    cases(end+1)=struct('id',string(sprintf('wind_prefix_dt%05d',round(dt*1e6))), ...
        'file',windFile,'factors',struct(),'dt',dt,'kind',"wind",'limit',39.98);
end
for record=["CHY023-W" "TCU052-N"]
    for dt=[.005 .0025]
        cases(end+1)=struct('id',string(sprintf('%s_nominal_dt%05d',record,round(dt*1e6))), ...
            'file',fullfile(docs,'tables',record+"_SI.csv"),'factors',struct(), ...
            'dt',dt,'kind',"earthquake",'limit',Inf);
    end
end
for kind=["earthquake" "wind"]
    if kind=="earthquake",file=eqFile;else,file=windFile;end
    for parameter=["blade_density" "blade_stiffness" "rotor_speed"]
        for h=[.01 .005]
            if h==.005,steps=[.005 .0025];else,steps=.0025;end
            for dt=steps
                for sign=[-1 1]
                    factors=struct();factors.(parameter)=1+sign*h;
                    id=string(sprintf('%s_%s_h%03d_s%+d_dt%05d',kind,parameter,round(h*1e4),sign,round(dt*1e6)));
                    cases(end+1)=struct('id',id,'file',file,'factors',factors, ...
                        'dt',dt,'kind',kind,'limit',39.98);
                end
            end
        end
    end
end
status=repmat(struct('id',"",'status',"pending",'seconds',NaN,'message',""),numel(cases),1);
for j=1:numel(cases)
    c=cases(j);status(j).id=c.id;path=fullfile(out,c.id+".mat");
    if isfile(path)
        z=load(path,'r');assert(isequal(z.r.factors,c.factors)&&z.r.dt==c.dt);
        status(j).status="success_reused";status(j).seconds=z.r.elapsedSeconds;continue
    end
    if toc(started)>maximumWallSeconds,break,end
    fprintf('CASE %d/%d %s\n',j,numel(cases),c.id);
    try
        r=snapshot_input_case(c.file,c.factors,c.dt,c.kind,1000,c.limit);
        assert(r.dynamicResidual<1e-8,'Dynamic residual failed');
        save(path,'r','-v7.3');status(j).status="success";status(j).seconds=r.elapsedSeconds;
        fprintf('SUCCESS %.2f s; residual %.3g\n',r.elapsedSeconds,r.dynamicResidual);
    catch exception
        status(j).status="failed";status(j).message=string(getReport(exception,'extended','hyperlinks','off'));
        fprintf('FAILED %s\n',status(j).message);
    end
    writetable(struct2table(status),fullfile(out,'case_status.csv'));
end
writetable(struct2table(status),fullfile(out,'case_status.csv'));
save(fullfile(out,'comparison_design.mat'),'cases','maximumWallSeconds');
% Validate independently implemented selected-output extraction and chunking.
a=load(fullfile(out,'ARL360_nominal_dt010.mat'),'r');
b=load(fullfile(out,'ARL360_optimized_dt010.mat'),'r');
checks=struct();
for name=["historyQ" "historyA" "historyR"]
    checks.(name)=norm(a.r.(name)-b.r.(name),'fro')/max(norm(a.r.(name),'fro'),eps);
end
assert(max(struct2array(checks))<1e-7,'Selected recovery differs from existing seismic routine');
fid=fopen(fullfile(out,'recovery_verification.json'),'w');fprintf(fid,'%s',jsonencode(checks,PrettyPrint=true));fclose(fid);
disp(struct2table(status));disp(checks);
% Independent repetition at a different chunk boundary, same physical case.
controlFiles=["ARL360_nominal_dt02500" "wind_prefix_dt02500"];
for j=1:2
    path=fullfile(out,controlFiles(j)+"_repeat.mat");
    if isfile(path),continue,end
    if j==1,file=eqFile;kind="earthquake";else,file=windFile;kind="wind";end
    r=snapshot_input_case(file,struct(),.0025,kind,500,39.98);
    assert(r.dynamicResidual<1e-8);save(path,'r','-v7.3');
end
