function result=check_3p_response_orders(F,ne,out,mode)
% Axial hub load; retain a prescribed subset of response orders in the full
% spatial system. Dynamic, load and output Fourier coefficients are unchanged.
if nargin==0
    root=fileparts(fileparts(mfilename('fullpath')));
    out=fullfile(root,'runs','periodic_loads_20261118');
    data=load(fullfile(out,'operators64.mat'),'F'); F=data.F; ne=133;
end
maxNumCompThreads(1);
if nargin==4 && mode=="timing"
    omega=3.4445*pi/30;
    orders={-12:12,1:5};
    labels=["H12","C2"];
    for j=1:2,solution(F,omega,orders{j},j==2);end
    rows={};
    for rep=1:5
        sequence=[1,2];
        if mod(rep,2)==0,sequence=fliplr(sequence);end
        for j=sequence
            clock=tic;
            [~,residual,nz]=solution(F,omega,orders{j},j==2);
            rows(end+1,:)={ne,3.4445,rep,labels(j),toc(clock),nz,residual};
        end
    end
    result=cell2table(rows,'VariableNames',{'elements','rpm','repetition','orders','seconds','nonzeros','residual'});
    writetable(result,fullfile(out,sprintf('correction_carrier_timing_%d.csv',ne)));
    return
end
if nargin==4 && mode=="sweep"
    bench=readtable(fullfile(out,'rotating_mesh_sweep.csv'));
    result=bench(bench.elements==ne & bench.channel==4,{'rpm','periodicAbs','periodicPhase'});
    result.correctedAbs=zeros(height(result),1);
    result.correctedPhase=zeros(height(result),1);
    for i=1:height(result)
        Y=solution(F,result.rpm(i)*pi/30,1:5,true);
        value=2*Y(4,28);
        result.correctedAbs(i)=abs(value);
        result.correctedPhase(i)=angle(value)*180/pi;
    end
    result.amplitudeErrorPct=100*(result.correctedAbs./result.periodicAbs-1);
    result.phaseErrorDeg=mod(result.correctedPhase-result.periodicPhase+180,360)-180;
    writetable(result,fullfile(out,sprintf('correction_carrier_sweep_%d.csv',ne)));
    return
end
orders={-12:12,[-3,3],[-4,-3,-2,2,3,4],[-6,-3,0,3,6], ...
        [-5:-1,1:5],-3:3,-4:4,-5:5,-6:6,3,2:4,1:5,0:6,-1:7,-2:8};
labels=["H12","pair3","near3","multiples3","bands1to5","H3","H4","H5","H6","C0","C1","C2","C3","C4","C5"];
speeds=[3.35,3.394,3.42,3.4445,3.49,3.52,3.55];
if ne==532,speeds=[3.394,3.4445];end
rows={};
for rpm=speeds
    omega=pi*rpm/30;
    for j=1:numel(orders)
        clock=tic;
        [Y,residual,nz]=solution(F,omega,orders{j},startsWith(labels(j),"C"));
        seconds=toc(clock);
        if j==1, reference=Y; end
        for c=[1,4,6]
            ref=reference(c,:);test=Y(c,:);
            error=100*norm(test-ref)/norm(ref);
            phaseError=angle(test(28)/ref(28))*180/pi;
            rows(end+1,:)={ne,rpm,labels(j),numel(orders{j}),c,error, ...
                2*abs(test(28)),angle(test(28))*180/pi,phaseError,seconds,nz,residual};
        end
    end
    fprintf('Response-order sweep, elements %d, rpm %g\n',ne,rpm);
end
result=cell2table(rows,'VariableNames',{'elements','rpm','orders','blocks','channel', ...
    'historyErrorPct','amplitude3P','phase3PDeg','phaseDifferenceDeg','assemblySolveRecoverySeconds','nonzeros','residual'});
writetable(result,fullfile(out,sprintf('correction_response_orders_%d.csv',ne)));
end

function [Y,residual,nz]=solution(F,omega,orders,carrier)
n=size(F.M{F.L+1},1); count=numel(orders);
blocks=cell(count); rhs=zeros(n*count,1); zero=sparse(n,n);
for j=1:count
    h=orders(j); rows=(j-1)*n+(1:n);
    forceOrders=[3,-3];
    if carrier,forceOrders=3;end
    for ell=h-forceOrders
        if abs(ell)<=F.L,rhs(rows)=rhs(rows)+0.5*F.B{ell+F.L+1}(:,1);end
    end
    for m=1:count
        k=orders(m);ell=h-k;
        if abs(ell)>F.L,blocks{j,m}=zero;continue,end
        i=ell+F.L+1;
        blocks{j,m}=F.K0{i}+omega*F.K1{i}+omega^2*F.K2{i} ...
            +1i*k*omega*(F.D0{i}+omega*F.D1{i})-(k*omega)^2*F.M{i};
    end
end
A=cell2mat(blocks);clear blocks
x=A\rhs;residual=norm(A*x-rhs)/norm(rhs);nz=nnz(A);
x=reshape(x,n,count);Y=zeros(7,2*F.outputH+1);
for m=1:count
    k=orders(m);
    for ell=-F.L:F.L
        h=k+ell;
        if abs(h)>F.outputH,continue,end
        i=ell+F.L+1;
        O=F.O00{i}+omega*F.O01{i}+omega^2*F.O02{i} ...
            +1i*k*omega*(F.O10{i}+omega*F.O11{i})-(k*omega)^2*F.O2{i};
        Y(:,h+F.outputH+1)=Y(:,h+F.outputH+1)+O*x(:,m);
    end
end
% For real coefficients, conjugating the +3 solution generates the -3
% response. Sum Fourier coefficients before evaluating output amplitudes.
if carrier,Y=Y+conj(fliplr(Y));end
end
