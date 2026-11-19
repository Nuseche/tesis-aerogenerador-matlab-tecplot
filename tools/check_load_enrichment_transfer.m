function check_load_enrichment_transfer(folder)
% Reuse the previously selected spatial bases for independent support records.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(root,fullfile(root,'cases'));
if nargin<1, folder=fullfile(root,'runs','load_enrichment_20261118'); end
maxNumCompThreads(1);
a=load(fullfile(root,'runs','run_20260914_mecom_comparison','global_raw_data.mat'),'M','D','K','T','Mfull','Dfull','Kfull','Pg','t');
b=load(fullfile(folder,'enrichment_data.mat'),'specs','bases');
modelNames=string({b.specs.name});
selected=["full804","modal48","modal50","enriched48plus2","enriched96plus2"];
cfg=config_seismic_verification();cfg.rotor.speedRPM=0;cfg.gravity.enabled=false;
md=model.build_model(io.load_model_data(cfg),cfg);node=md.dofs.node;
translation=zeros(size(a.Mfull,1),2);translation(node(:,1),1)=1;translation(node(:,2),2)=1;
outputDofs=[node(129,1),node(129,2),node(56,1),node(92,1),node(128,1),node(129,1),node(56,1)];
H=a.T(outputDofs,:);base=node(1,5);Bfull=a.Mfull*translation;
RA=a.Mfull(base,:)*a.T;RV=a.Dfull(base,:)*a.T;RU=a.Kfull(base,:)*a.T;
t=a.t;freq=[.4,.7;.8,1.1];rows={};
for j=1:size(freq,1)
    omega=2*pi*freq(j,:);s=sin(t*omega);c=cos(t*omega);
    ag=3*(2*s.*c.^2-s.^3).*([.003,.0018].*omega.^2);
    for name=selected
        Q=b.bases{modelNames==name};F=-(Q'*a.Pg)*ag';
        r=dynamics.newmark_integrate(Q'*a.M*Q,Q'*a.D*Q,Q'*a.K*Q,t,F,struct('beta',.25,'gamma',.5));
        Y=[(H(1:5,:)*Q)*r.q;(H(6:7,:)*Q)*r.qdd+translation(outputDofs(6:7),:)*ag'; ...
           (RA*Q)*r.qdd+(RV*Q)*r.qd+(RU*Q)*r.q+Bfull(base,:)*ag'];
        if name=="full804", ref=Y;end
        for k=1:8
            error=100*sqrt(trapz(t,(Y(k,:)-ref(k,:)).^2)/trapz(t,ref(k,:).^2));
            rows(end+1,:)={freq(j,1),freq(j,2),name,k,error,max(abs(Y(k,:))),max(abs(ref(k,:)))}; %#ok<AGROW>
        end
    end
end
writetable(cell2table(rows,'VariableNames',{'frequencyXHz','frequencyYHz','model','outputIndex','historyErrorPercent','peak','referencePeak'}),fullfile(folder,'heldout_errors.csv'));
% Resolve the two residual Ritz poles of the 14-coordinate enriched system.
Q=b.bases{modelNames=="enriched12plus2"};[U,L]=eig(Q'*a.K*Q,Q'*a.M*Q);
[f,ix]=sort(sqrt(real(diag(L)))/(2*pi));U=Q*U(:,ix);B=-a.Pg;
[refU,refL]=eig(full(a.K),full(a.M));[ff,ix]=sort(sqrt(real(diag(refL)))/(2*pi));refU=refU(:,ix);
rows={};
for j=13:14
   u=U(:,j)/sqrt(U(:,j)'*a.M*U(:,j)); [df,k]=min(abs(ff-f(j)));
   v=refU(:,k);mac=abs(v'*a.M*u)^2/(v'*a.M*v);
   for direction=1:2
       for excitation=[.65, .9, 1.95, 2.7]
         w=2*pi*excitation;
         contribution=((RU+1i*w*RV-w^2*RA)*u)*(u'*B(:,direction))/((2*pi*f(j))^2-w^2+1i*w*u'*a.D*u);
         rows(end+1,:)={j,f(j),ff(k),df,mac,direction,excitation,real(contribution),imag(contribution),abs(contribution)}; %#ok<AGROW>
       end
   end
end
writetable(cell2table(rows,'VariableNames',{'reducedMode','ritzFrequencyHz','nearestFullFrequencyHz','frequencyDifferenceHz','massMACNearest','inputDirection','forcingFrequencyHz','realMoment','imagMoment','momentAbs'}),fullfile(folder,'enriched12_pole_check.csv'));
end
