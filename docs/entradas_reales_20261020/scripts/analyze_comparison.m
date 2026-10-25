% Scalar indicators, empirical numerical gates, and parameterized combination.
root='/Users/nuseche/Desktop/Tesis_codigos';docs=fullfile(root,'docs/entradas_reales_20261020');
folder=fullfile(root,'runs/sensitivity/real_inputs_20261020');addpath(fullfile(docs,'scripts'));
tables=fullfile(docs,'tables');
names=["gondola_qH" "hub_qH" "punta56_qXYZ" "punta92_qZ" "punta128_qZ" ...
    "gondola_aH" "hub_aH" "punta56_aXYZ" "punta92_aZ" "punta128_aZ" "base_VH" "base_MH" ...
    "gondola_qH_RMS" "gondola_aH_RMS" "base_MH_RMS"];
units=[repmat("m",1,5) repmat("m/s^2",1,5) "N" "N m" "m" "m/s^2" "N m"];
summary=struct('date',"2026-10-20",'maximumDynamicResidual',0,'caseCount',0, ...
    'scope',"frozen operating point; mean thrust parameter; independent records; no aeroelastic feedback");
files=dir(fullfile(folder,'*.mat'));caseRows=cell(0,7);
for j=1:numel(files)
    vars=whos('-file',fullfile(files(j).folder,files(j).name));
    if ~any(strcmp({vars.name},'r')),continue,end
    z=load(fullfile(files(j).folder,files(j).name),'r');
    r=z.r;summary.caseCount=summary.caseCount+1;
    summary.maximumDynamicResidual=max(summary.maximumDynamicResidual,r.dynamicResidual);
    caseRows(end+1,:)={string(files(j).name),r.dt,r.t(end),r.elapsedSeconds,r.dynamicResidual,r.equilibriumResidual,string(r.sourceCsv)};
end
writetable(cell2table(caseRows,'VariableNames',{'caseId','dt','lastTime','seconds','dynamicResidual','equilibriumResidual','sourceCsv'}),fullfile(tables,'case_audit.csv'));
summary.recoveryVerification=jsondecode(fileread(fullfile(folder,'recovery_verification.json')));
summary.authorizedAssumptions=["independent measured wind and earthquake records", ...
    "uniform inflow proxy; prescribed axial hub thrust proportional to U squared", ...
    "mean thrust left as parameter; no thrust coefficient or air density assumed"];

% Nominal comparison among records; each full supplied duration is retained.
records=["ARL360" "CHY023-W" "TCU052-N"];
nominalRows=cell(0,7);timeRows=cell(0,7);
for rec=records
    a=readcase(folder,rec+"_nominal_dt05000");b=readcase(folder,rec+"_nominal_dt02500");
    ya=metrics(a);yb=metrics(b);
    for k=1:numel(names)
        nominalRows(end+1,:)={rec,names(k),units(k),yb(k),ya(k),abs(yb(k)-ya(k))/max(yb(k),eps),b.t(end)};
    end
    timeRows=[timeRows;compare(a,b,rec,names,units)]; %#ok<AGROW>
end
writetable(cell2table(nominalRows,'VariableNames',{'record','response','unit','finePeak','coarsePeak','relativePeakDifference','lastTime'}),fullfile(tables,'nominal_earthquakes.csv'));
eq=readcase(folder,"ARL360_nominal_dt02500");eq2=readcase(folder,"ARL360_nominal_dt01250");
wf=readcase(folder,"wind_full_dt05000");wc=readcase(folder,"wind_full_dt10000");
w=readcase(folder,"wind_prefix_dt02500");w2=readcase(folder,"wind_prefix_dt01250");
timeRows=[timeRows;compare(eq,eq2,"ARL360_fine",names,units); ...
    compare(wc,wf,"wind_full",names,units);compare(w,w2,"wind_prefix_fine",names,units)];
writetable(cell2table(timeRows,'VariableNames',{'casePair','response','unit','coarseDt','fineDt','relativePeakDifference','relativeHistoryL2'}),fullfile(tables,'time_convergence.csv'));
summary.windFullPeak=metrics(wf);summary.windPrefixPeak=metrics(w);summary.earthquakePeak=metrics(eq);
summary.responseNames=names;summary.responseUnits=units;
summary.rotorAxis=eq.rotorAxis;summary.maxGeometryZ=eq.height;
summary.mainSeismicDirection="global X; axial wind follows rotor 129-130";
directionRows=cell(0,6);
for rec=records
    a=readcase(folder,rec+"_nominal_dt02500");
    z=load(fullfile(folder,rec+"_nominal_dt02500.mat"),'r');b=z.r;
    ya=metrics(a);yb=metrics(b);
    for k=1:numel(names)
        directionRows(end+1,:)={rec,names(k),units(k),ya(k),yb(k),ya(k)/max(yb(k),eps)};
    end
end
writetable(cell2table(directionRows,'VariableNames',{'record','response','unit','globalXPeak','globalYPeak','ratioXoverY'}),fullfile(tables,'direction_comparison.csv'));
% Fref only normalizes the comparison: it is not a wind estimate or a limit.
Fref=summary.earthquakePeak(1)/summary.windPrefixPeak(1); % kN
summary.referenceMeanThrustKN=Fref;

% Repetition controls at identical dt with different chunk boundaries.
eta=struct();
for kind=["earthquake" "wind"]
    if kind=="earthquake",base=eq;id="ARL360_nominal_dt02500";else,base=w;id="wind_prefix_dt02500";end
    repeat=readcase(folder,id+"_repeat");
    eta.(kind)=abs(metrics(repeat)-metrics(base));
end
summary.empiricalRepeatNoise=eta;
summary.noiseInterpretation="observed nominal repetition, not rigorous parameter-domain error bound";

parameters=["blade_density" "blade_stiffness" "rotor_speed"];
localRows=cell(0,14);combinedRows=cell(0,10);
for kind=["earthquake" "wind"]
    if kind=="earthquake",base=eq;coarse=readcase(folder,"ARL360_nominal_dt05000");refined=eq2;
    else,base=w;coarse=prefix(wf,39.98);refined=w2;end
    y0=metrics(base);yFine=metrics(refined);
    for parameter=parameters
        h=.00125;
        lo=readvariation(folder,kind,parameter,h,-1,.0025);
        hi=readvariation(folder,kind,parameter,h,1,.0025);
        loH=readvariation(folder,kind,parameter,2*h,-1,.0025);
        hiH=readvariation(folder,kind,parameter,2*h,1,.0025);
        loDt=readvariation(folder,kind,parameter,h,-1,.005);
        hiDt=readvariation(folder,kind,parameter,h,1,.005);
        derivative=(metrics(hi)-metrics(lo))/(2*h);
        S=derivative./y0;
        Slarge=(metrics(hiH)-metrics(loH))/(4*h)./y0;
        Scoarse=(metrics(hiDt)-metrics(loDt))/(2*h)./y0;
        hChange=abs(S-Slarge)./max(abs(S),eps);
        dtChange=abs(S-Scoarse)./max(abs(S),eps);
        noiseS=eta.(kind)/h./y0;
        nominalDt=abs(y0-yFine)./max(yFine,eps);
        nominalHistory=zeros(size(y0));
        for k=1:numel(names),nominalHistory(k)=historyError(base,refined,k);end
        accepted=hChange<=.02&dtChange<=.02&nominalDt<=.01&nominalHistory<=.01&abs(S)>=10*noiseS;
        for k=1:numel(names)
            localRows(end+1,:)={kind,parameter,names(k),units(k),y0(k),S(k),Slarge(k),Scoarse(k), ...
                hChange(k),dtChange(k),noiseS(k),nominalDt(k),nominalHistory(k),accepted(k)};
        end
    end
end
local=cell2table(localRows,'VariableNames',{'input','parameter','response','unit','nominal','S', ...
    'S_twiceH','S_dt005','relativeHChange','relativeDtChange','empiricalNoiseS','nominalDtChange','nominalHistoryL2Change','accepted'});
writetable(local,fullfile(tables,'local_sensitivities.csv'));
summary.acceptedLocalCount=sum(local.accepted);summary.totalLocalCount=height(local);
summary.finalDifferentiationStep=.00125;summary.comparisonDifferentiationStep=.0025;
refinementRows=cell(0,8);peakTimeRows=cell(0,7);
for kind=["earthquake" "wind"]
    if kind=="earthquake",base=eq;else,base=w;end
    y0=metrics(base);
    for parameter=parameters
        for h=[.01 .005 .0025 .00125]
            lo=readvariation(folder,kind,parameter,h,-1,.0025);
            hi=readvariation(folder,kind,parameter,h,1,.0025);
            yl=metrics(lo);yh=metrics(hi);S=(yh-yl)/(2*h)./y0;
            for k=1:numel(names)
                refinementRows(end+1,:)={kind,parameter,names(k),h,S(k),yl(k),yh(k),y0(k)};
            end
            for k=[1 6 12]
                vl=metricComponents(lo,k);vh=metricComponents(hi,k);
                [~,il]=max(sum(vl.^2,2));[~,ih]=max(sum(vh.^2,2));
                peakTimeRows(end+1,:)={kind,parameter,names(k),h,lo.t(il),hi.t(ih),hi.t(ih)-lo.t(il)};
            end
        end
    end
end
writetable(cell2table(refinementRows,'VariableNames',{'input','parameter','response','h','S','minusPeak','plusPeak','nominalPeak'}),fullfile(tables,'differentiation_refinement.csv'));
writetable(cell2table(peakTimeRows,'VariableNames',{'input','parameter','response','h','minusPeakTime','plusPeakTime','peakTimeShiftSeconds'}),fullfile(tables,'peak_time_switches.csv'));

% Combined sensitivity: earthquake arrival at zero, same 39.98 s window.
ratios=[0 .25 .5 1 2];interesting=[1 6 12 13 14 15];
for ratio=ratios
    base=combine(eq,w,ratio*Fref);y0=metrics(base);
    for parameter=parameters
        cases=cell(2,3);
        for signIndex=1:2
            sign=2*signIndex-3;
            cases{signIndex,1}=combine(readvariation(folder,"earthquake",parameter,.00125,sign,.0025),readvariation(folder,"wind",parameter,.00125,sign,.0025),ratio*Fref);
            cases{signIndex,2}=combine(readvariation(folder,"earthquake",parameter,.0025,sign,.0025),readvariation(folder,"wind",parameter,.0025,sign,.0025),ratio*Fref);
            cases{signIndex,3}=combine(readvariation(folder,"earthquake",parameter,.00125,sign,.005),readvariation(folder,"wind",parameter,.00125,sign,.005),ratio*Fref);
        end
        S=(metrics(cases{2,1})-metrics(cases{1,1}))/.0025./y0;
        Sh=(metrics(cases{2,2})-metrics(cases{1,2}))/.005./y0;
        Sd=(metrics(cases{2,3})-metrics(cases{1,3}))/.0025./y0;
        changeH=abs(S-Sh)./max(abs(S),eps);changeDt=abs(S-Sd)./max(abs(S),eps);
        for k=interesting
            combinedRows(end+1,:)={ratio,ratio*Fref,parameter,names(k),S(k),Sh(k),Sd(k),changeH(k),changeDt(k),changeH(k)<=.02&&changeDt(k)<=.02};
        end
    end
end
writetable(cell2table(combinedRows,'VariableNames',{'thrustOverReference','meanThrustKN','parameter','response','S','S_twiceH','S_dt005','relativeHChange','relativeDtChange','stepChecksPassed'}),fullfile(tables,'combined_sensitivities.csv'));

% Input amplitude sensitivity in the SAME conditional linear problem.
% At zero mean thrust its normalized sensitivity is deliberately undefined.
inputRows=cell(0,9);
for ratio=linspace(0,2,41)
    F=ratio*Fref;y0=metrics(combine(eq,w,F));
    for h=[.01 .005]
        ga=eq;gb=eq;
        for field=["historyQ" "historyA" "historyR"]
            ga.(field)=(1-h)*eq.(field);gb.(field)=(1+h)*eq.(field);
        end
        Sa=(metrics(combine(gb,w,F))-metrics(combine(ga,w,F)))/(2*h)./y0;
        if ratio>0
            Sf=(metrics(combine(eq,w,F*(1+h)))-metrics(combine(eq,w,F*(1-h))))/(2*h)./y0;
        else,Sf=NaN(size(y0));end
        for k=interesting
            inputRows(end+1,:)={ratio,F,names(k),h,Sa(k),Sf(k),Sa(k)+Sf(k),ratio>0, ...
                "fixed operators; relative amplitudes; not measured uncertainty"};
        end
    end
end
writetable(cell2table(inputRows,'VariableNames',{'thrustOverReference','meanThrustKN','response','step','S_seismicAmplitude', ...
    'S_meanThrust','sumOfSensitivities','thrustNormalizationDefined','scope'}),fullfile(tables,'input_amplitude_sensitivities.csv'));

% Arrival timing is an exploratory grid, not a probability distribution.
arrivalTimes=[0:20:540 wf.t(end)-eq.t(end)];gridRatios=linspace(0,2,41);phaseRows=cell(0,9);
for ratio=gridRatios
    for arrival=arrivalTimes
        windAtEarthquake=wf;windAtEarthquake.t=eq.t;
        for field=["historyQ" "historyA" "historyR"]
            query=arrival+eq.t;assert(query(end)<=wf.t(end)+1e-9);
            query=min(query,wf.t(end)); % endpoint round-off only; no extrapolation
            windAtEarthquake.(field)=interp1(wf.t,wf.(field).',query,'linear').';
            assert(all(isfinite(windAtEarthquake.(field)),'all'),'Wind window outside measured support');
        end
        rr=combine(eq,windAtEarthquake,ratio*Fref);yy=metrics(rr);
        yw=metrics(windAtEarthquake)*ratio*Fref;yg=metrics(eq);
        for k=interesting
            bound=yw(k)+yg(k);
            assert(yy(k)<=bound*(1+1e-12),'Triangle bound violated');
            phaseRows(end+1,:)={ratio,ratio*Fref,arrival,names(k),units(k),yy(k),yy(k)/yg(k),yw(k),bound};
        end
    end
end
phase=cell2table(phaseRows,'VariableNames',{'thrustOverReference','meanThrustKN','earthquakeArrivalSeconds','response','unit','combinedPeak','overEarthquakePeak','windOnlyPeakInSameWindow','sumOfSeparatePeaks'});
writetable(phase,fullfile(tables,'arrival_phase_comparison.csv'));
summary.arrivalGridSeconds=arrivalTimes;summary.thrustRatios=gridRatios;
summary.combinationWindowSeconds=[0 39.98];
summary.combinationInterpretation="exact superposition for the same frozen linear operators and prescribed force; not validation of nonlinear aeroelastic superposition";
summary.elapsedSolveSeconds=sum(cell2mat(caseRows(:,4)));
fid=fopen(fullfile(docs,'analysis_summary.json'),'w');fprintf(fid,'%s',jsonencode(summary,PrettyPrint=true));fclose(fid);
save(fullfile(folder,'comparison_summary.mat'),'summary','local','phase');
disp(summary);disp(local(local.response=="gondola_qH"|local.response=="gondola_aH",:));

function r=readcase(folder,id)
if startsWith(id,["ARL360" "CHY023-W" "TCU052-N" "earthquake_"])
    id="aligned_"+id;
end
z=load(fullfile(folder,id+".mat"),'r');r=z.r;
end
function r=readvariation(folder,kind,parameter,h,sign,dt)
id=string(sprintf('%s_%s_h%03d_s%+d_dt%05d',kind,parameter,round(h*1e4),sign,round(dt*1e6)));
r=readcase(folder,id);
end
function r=prefix(r,last)
ix=r.t<=last+1e-9;r.t=r.t(ix);
for f=["historyQ" "historyA" "historyR"],r.(f)=r.(f)(:,ix);end
end
function y=metrics(r)
q=r.historyQ;a=r.historyA;R=r.historyR;
v=[vecnorm(q(1:2,:));vecnorm(q(4:5,:));vecnorm(q(7:9,:));abs(q(10:11,:)); ...
    vecnorm(a(1:2,:));vecnorm(a(4:5,:));vecnorm(a(7:9,:));abs(a(10:11,:)); ...
    vecnorm(R(1:2,:));vecnorm(R(4:5,:))];
y=max(v,[],2).';span=r.t(end)-r.t(1);
y=[y sqrt(trapz(r.t,sum(q(1:2,:).^2,1).')/span) ...
    sqrt(trapz(r.t,sum(a(1:2,:).^2,1).')/span) sqrt(trapz(r.t,sum(R(4:5,:).^2,1).')/span)];
end
function r=combine(a,b,scale)
assert(numel(a.t)==numel(b.t)&&max(abs(a.t-b.t))<1e-8);r=a;
for field=["historyQ" "historyA" "historyR"],r.(field)=a.(field)+scale*b.(field);end
end
function rows=compare(a,b,label,names,units)
ya=metrics(a);yb=metrics(b);rows=cell(0,7);
for k=1:numel(names)
    e=historyError(a,b,k);
    rows(end+1,:)={label,names(k),units(k),a.dt,b.dt,abs(ya(k)-yb(k))/max(yb(k),eps),e};
end
end
function y=metricComponents(r,k)
q=r.historyQ;a=r.historyA;R=r.historyR;
c={q(1:2,:),q(4:5,:),q(7:9,:),q(10,:),q(11,:), ...
    a(1:2,:),a(4:5,:),a(7:9,:),a(10,:),a(11,:),R(1:2,:),R(4:5,:),q(1:2,:),a(1:2,:),R(4:5,:)};
y=c{k}.';
end
function e=historyError(a,b,k)
va=metricComponents(a,k);vb=metricComponents(b,k);
v=interp1(a.t,va,b.t,'linear');
e=sqrt(trapz(b.t,sum((v-vb).^2,2)))/max(sqrt(trapz(b.t,sum(vb.^2,2))),eps);
end
