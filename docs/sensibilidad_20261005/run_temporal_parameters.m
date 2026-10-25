% Mechanical parameters selected from accepted modal ranking, existing sismo.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));addpath(root);addpath(fullfile(root,'cases'));
folder=fullfile(root,'runs','sensitivity','initial_20261005');
s=sensitivity.config_local();s.parameters=s.parameters(ismember(s.parameters.name,["blade_density" "blade_stiffness"]),:);
s.steps=[0.01 0.005];design=sensitivity.local_design(s);
for k=1:numel(design),design(k).options.seismic=true;design(k).options.dt=0.00125;end
c=sensitivity.run_campaign(s,design,fullfile(folder,'temporal_parameters'));
ref=sensitivity.read_case(c.folder,'nominal');rep=sensitivity.read_case(c.folder,'repeat');
strict=sensitivity.read_case(c.folder,'strict');cont=sensitivity.read_case(c.folder,'continuation');
rows=cell(0,13);
for p=1:height(s.parameters)
    name=s.parameters.name(p);
    for j=1:numel(s.steps)
        h=s.steps(j);a=sensitivity.read_case(c.folder,name+"_h"+j+"_minus");
        b=sensitivity.read_case(c.folder,name+"_h"+j+"_plus");
        y0=[ref.time.peakQ ref.time.peakAbsoluteA];ym=[a.time.peakQ a.time.peakAbsoluteA];yp=[b.time.peakQ b.time.peakAbsoluteA];
        noise=max(abs(y0-[rep.time.peakQ rep.time.peakAbsoluteA]),abs(y0-[strict.time.peakQ strict.time.peakAbsoluteA]));
        noise=max(noise,abs(y0-[cont.time.peakQ cont.time.peakAbsoluteA]));noise=max(noise,100*eps(max(y0,1)));
        for ch=1:size(y0,1)
            for metric=1:2
                types=["peak_relative_displacement" "peak_absolute_acceleration"];units=["m" "m/s^2"];
                d=sensitivity.central_difference(y0(ch,metric),ym(ch,metric),yp(ch,metric),h,y0(ch,metric));
                rows(end+1,:)={name,h,ref.channels(ch,1),ref.channels(ch,2),types(metric),units(metric), ...
                    y0(ch,metric),ym(ch,metric),yp(ch,metric),d.derivative,d.sensitivity,noise(ch,metric), ...
                    d.signal>=s.signalToNoise*noise(ch,metric)}; %#ok<SAGROW>
            end
        end
    end
end
T=cell2table(rows,'VariableNames',{'parameter','step','nodeId','component','response','unit', ...
    'nominal','minus','plus','derivative','sensitivity','numericalNoise','signalResolved'});
T.stepRelativeDifference=nan(height(T),1);T.stepConverged=false(height(T),1);
for k=1:height(T)
    other=find(T.parameter==T.parameter(k)&T.nodeId==T.nodeId(k)&T.component==T.component(k)& ...
        T.response==T.response(k)&T.step>T.step(k));
    if isempty(other),continue,end
    T.stepRelativeDifference(k)=abs(T.derivative(k)-T.derivative(other(1)))/max(abs(T.derivative(k)),1e-3*T.nominal(k));
    T.stepConverged(k)=T.stepRelativeDifference(k)<=s.derivativeTolerance;
end
writetable(T,fullfile(c.folder,'temporal_sensitivity.csv'));
