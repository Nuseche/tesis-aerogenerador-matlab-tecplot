function study=config_morris()
%CONFIG_MORRIS Author-approved exploratory domain, 6 October 2026.
study=sensitivity.config_local();
names=["blade_density";"blade_stiffness";"rotor_speed"];
[~,ix]=ismember(names,study.parameters.name);study.parameters=study.parameters(ix,:);
study.parameters.localMinimum(:)=0.90;study.parameters.localMaximum(:)=1.10;
study.parameters.rangeStatus(:)="author_approved_exploratory_domain";
study.schemaVersion="morris_1.0";study.globalEnabled=true;
study.morris=struct('levels',4,'trajectories',40,'prefixes',[10 20 40], ...
    'lower',0.90*ones(3,1),'upper',1.10*ones(3,1),'seed',6706, ...
    'estimatorTolerance',0.10,'physicalInputMeasure',"not_defined", ...
    'domainStatus',"exploratory_not_experimental_uncertainty", ...
    'approvalDate',"2026-10-06",'approvalEvidence',"Author: Apruebo");
study.maxCases=170;study.maximumWallSeconds=1800;
study.checkpointCases=[50 90 170];
study.checkpointFunction="sensitivity.summarize_morris";
study.rangeStatus="author_approved_exploratory_domain";
end
