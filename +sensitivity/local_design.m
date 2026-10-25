function design=local_design(study)
%LOCAL_DESIGN Central perturbations + independent numerical verification.
design=struct('id',"nominal",'factors',struct(),'options',struct());
design(end+1)=struct('id',"repeat",'factors',struct(),'options',struct());
design(end+1)=struct('id',"strict",'factors',struct(),'options',struct('strict',true));
design(end+1)=struct('id',"continuation",'factors',struct(), ...
    'options',struct('continuationGrid',(0:1.5:12).'));
for p=1:height(study.parameters)
    name=study.parameters.name(p);
    for j=1:numel(study.steps)
        for sign=[-1 1]
            factors=struct();factors.(name)=1+sign*study.steps(j);
            if sign<0,suffix="minus";else,suffix="plus";end
            id=name+"_h"+j+"_"+suffix;
            design(end+1)=struct('id',id,'factors',factors,'options',struct()); %#ok<AGROW>
        end
    end
end
end
