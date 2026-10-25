root='/Users/nuseche/Desktop/Tesis_codigos';docs=fullfile(root,'docs/entradas_reales_20261020');
folder=fullfile(root,'runs/sensitivity/real_inputs_20261020/refined_tangent');
source=readtable(fullfile(docs,'tables/local_sensitivities.csv'),'TextType','string');
names=unique(source.response,'stable');units=strings(size(names));
for j=1:numel(names),units(j)=source.unit(find(source.response==names(j),1));end
parameters=["blade_density" "blade_stiffness" "rotor_speed"];rows=cell(0,19);nomRows=cell(0,7);
for kind=["earthquake" "wind"]
    base=readr(folder,kind+"_nominal_k20_dt02500");other=readr(folder,kind+"_nominal_k40_dt02500");
    fine=readr(folder,kind+"_nominal_k20_dt01250");
    y0=metric(base);yOther=metric(other);yFine=metric(fine);
    nominalHessian=abs(y0-yOther)./max(yOther,eps);nominalDt=abs(y0-yFine)./max(yFine,eps);
    temporal=zeros(size(y0));for k=1:numel(names),temporal(k)=historyError(base,fine,k);end
    for k=1:numel(names),nomRows(end+1,:)={kind,names(k),units(k),y0(k),nominalHessian(k),nominalDt(k),temporal(k)};end
    for parameter=parameters
        lo=variation(folder,kind,parameter,20,.0025,-1,.0025);hi=variation(folder,kind,parameter,20,.0025,1,.0025);
        loH=variation(folder,kind,parameter,20,.005,-1,.0025);hiH=variation(folder,kind,parameter,20,.005,1,.0025);
        loD=variation(folder,kind,parameter,20,.0025,-1,.005);hiD=variation(folder,kind,parameter,20,.0025,1,.005);
        loK=variation(folder,kind,parameter,40,.0025,-1,.0025);hiK=variation(folder,kind,parameter,40,.0025,1,.0025);
        yl=metric(lo);yh=metric(hi);yLK=metric(loK);yHK=metric(hiK);
        S=(yh-yl)/.005./y0;
        SH=(metric(hiH)-metric(loH))/.01./y0;
        SD=(metric(hiD)-metric(loD))/.005./y0;
        SK=(yHK-yLK)/.005./y0;
        deltaH=abs(S-SH)./max(abs(S),eps);deltaD=abs(S-SD)./max(abs(S),eps);deltaK=abs(S-SK)./max(abs(S),eps);
        noise=(abs(yl-yLK)+abs(yh-yHK))/.005./y0;
        stable=deltaH<=.02&deltaD<=.02&deltaK<=.02&nominalHessian<=.01&nominalDt<=.01&temporal<=.01;
        ok=stable&abs(S)>=10*noise;
        for k=1:numel(names)
            rows(end+1,:)={kind,parameter,names(k),units(k),y0(k),S(k),SH(k),SD(k),SK(k), ...
                deltaH(k),deltaD(k),deltaK(k),noise(k),nominalHessian(k),nominalDt(k),temporal(k),ok(k), ...
                "same energy and original equilibrium; refined internal Hessian only",stable(k)};
        end
    end
end
t=cell2table(rows,'VariableNames',{'input','parameter','response','unit','nominal','S','S_twiceH','S_dt005','S_hessian40', ...
    'relativeHChange','relativeDtChange','relativeHessianChange','empiricalNoiseS','nominalHessianChange', ...
    'nominalDtChange','nominalHistoryL2Change','accepted','scope','stepConverged'});
writetable(t,fullfile(docs,'tables/refined_local_sensitivities.csv'));
writetable(cell2table(nomRows,'VariableNames',{'input','response','unit','nominal','relativeHessianChange','relativeDtChange','relativeHistoryL2'}),fullfile(docs,'tables/refined_nominal_verification.csv'));
status=readtable(fullfile(folder,'case_status.csv'),'TextType','string');assert(all(startsWith(status.status,'success')));
summary=struct('successfulCases',height(status),'accepted',sum(t.accepted),'stepConverged',sum(t.stepConverged),'total',height(t), ...
    'energyHessianStepScale',20,'comparisonHessianStepScale',40, ...
    'translationStep',"4e-5 * max(elementLength,1 m)",'rotationStepRad',4e-5, ...
    'h',.0025,'twiceH',.005,'originalEquilibriumPreserved',true,'physicalEnergyPreserved',true, ...
    'productionSourcesChanged',false,'maximumNominalHessianRelativeChange',max(cell2mat(nomRows(:,5))), ...
    'scope',"numerical tangent refinement; does not revalidate historical Morris or periodic operation");
fid=fopen(fullfile(docs,'refined_tangent_summary.json'),'w');fprintf(fid,'%s',jsonencode(summary,PrettyPrint=true));fclose(fid);
disp(summary);disp(t(ismember(t.response,["gondola_qH_RMS" "gondola_aH_RMS"]),:));

function r=readr(folder,id)
z=load(fullfile(folder,id+".mat"),'r');r=z.r;
end
function r=variation(folder,kind,p,scale,h,sg,dt)
id=string(sprintf('%s_%s_k%d_h%03d_s%+d_dt%05d',kind,p,scale,round(h*1e4),sg,round(dt*1e6)));
r=readr(folder,id);
end
function y=metric(r)
q=r.historyQ;a=r.historyA;R=r.historyR;
v=[vecnorm(q(1:2,:));vecnorm(q(4:5,:));vecnorm(q(7:9,:));abs(q(10:11,:)); ...
    vecnorm(a(1:2,:));vecnorm(a(4:5,:));vecnorm(a(7:9,:));abs(a(10:11,:));vecnorm(R(1:2,:));vecnorm(R(4:5,:))];
y=max(v,[],2).';T=r.t(end)-r.t(1);
y=[y sqrt(trapz(r.t,sum(q(1:2,:).^2,1).')/T) sqrt(trapz(r.t,sum(a(1:2,:).^2,1).')/T) sqrt(trapz(r.t,sum(R(4:5,:).^2,1).')/T)];
end
function e=historyError(a,b,k)
aa=components(a,k);bb=components(b,k);v=interp1(a.t,aa,b.t,'linear');
e=sqrt(trapz(b.t,sum((v-bb).^2,2)))/max(sqrt(trapz(b.t,sum(bb.^2,2))),eps);
end
function y=components(r,k)
q=r.historyQ;a=r.historyA;R=r.historyR;
c={q(1:2,:),q(4:5,:),q(7:9,:),q(10,:),q(11,:),a(1:2,:),a(4:5,:),a(7:9,:),a(10,:),a(11,:),R(1:2,:),R(4:5,:),q(1:2,:),a(1:2,:),R(4:5,:)};y=c{k}.';
end
