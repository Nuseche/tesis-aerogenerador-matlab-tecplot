function [design,vertices,edges]=morris_design(study)
%MORRIS_DESIGN Random OAT trajectories; nested prefixes, signed directions.
m=study.morris;k=height(study.parameters);p=m.levels;
if p<4||mod(p,2)~=0||numel(m.lower)~=k||numel(m.upper)~=k|| ...
        any(m.upper<=m.lower)||m.trajectories<1
    error('sensitivity:MorrisDesign','Invalid grid or domain.');
end
delta=p/(2*(p-1));old=rng;cleanup=onCleanup(@()rng(old)); %#ok<NASGU>
rng(m.seed,'twister');names=study.parameters.name;
design=struct('id',"nominal",'factors',struct(),'options',struct());
design(end+1)=struct('id',"repeat",'factors',struct(),'options',struct());
design(end+1)=struct('id',"strict",'factors',struct(),'options',struct('strict',true));
design(end+1)=struct('id',"continuation",'factors',struct(), ...
    'options',struct('continuationGrid',(0:1.5:12).'));
% Two opposite corners; no assertion that these rigorously bound error.
corners=[1.10 0.90 1.10;0.90 1.10 0.90];
for corner=1:2
    f=cell2struct(num2cell(corners(corner,:).'),cellstr(names),1);
    for method=["direct" "strict" "continuation"]
        opts=struct();
        if method=="strict",opts.strict=true;end
        if method=="continuation"
            opts.continuationGrid=linspace(0,12*f.rotor_speed,9).';
        end
        design(end+1)=struct('id',"corner"+corner+"_"+method,'factors',f,'options',opts); %#ok<AGROW>
    end
end
vr=cell(0,5);er=cell(0,7);
for trajectory=1:m.trajectories
    directions=2*randi([0 1],1,k)-1;
    base=randi([0 p/2-1],1,k)/(p-1);
    x=base+(directions<0)*delta;order=randperm(k);
    previous="";
    for vertex=0:k
        if vertex>0,j=order(vertex);dx=directions(j)*delta;x(j)=x(j)+dx;end
        f=m.lower(:).'+x.*(m.upper(:)-m.lower(:)).';
        id=string(sprintf('t%03d_v%d',trajectory,vertex));
        factors=cell2struct(num2cell(f.'),cellstr(names),1);
        design(end+1)=struct('id',id,'factors',factors,'options',struct()); %#ok<AGROW>
        vr(end+1,:)={trajectory,vertex,id,x,f}; %#ok<AGROW>
        if vertex>0
            er(end+1,:)={trajectory,vertex,names(j),previous,id,dx,dx*(m.upper(j)-m.lower(j))}; %#ok<AGROW>
        end
        previous=id;
    end
end
vertices=cell2table(vr,'VariableNames',{'trajectory','vertex','caseId','unitCoordinate','factor'});
edges=cell2table(er,'VariableNames',{'trajectory','edge','parameter','fromCase','toCase','deltaX','deltaFactor'});
end
