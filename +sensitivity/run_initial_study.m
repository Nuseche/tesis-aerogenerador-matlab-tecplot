function outputs=run_initial_study(folder,phase)
%RUN_INITIAL_STUDY Execute only bounded campaigns; resume by explicit folder.
if nargin<2,phase="local";end
study=sensitivity.config_local();
if nargin<1||strlength(string(folder))==0
    folder=fullfile(study.outputRoot,"initial_"+string(datetime('now','Format','yyyyMMdd_HHmmss_SSS')));
end
if ~isfolder(folder),mkdir(folder);end
switch string(phase)
    case "local"
        campaign=sensitivity.run_campaign(study,sensitivity.local_design(study),fullfile(folder,'local'));
        sensitivity.export_nominal_properties(study,campaign.folder);
        outputs=sensitivity.summarize_local(campaign);
    case "interactions"
        loaded=load(fullfile(folder,'local','summary.mat'),'summary');rank=loaded.summary.ranking;
        rank=rank(isfinite(rank.maxAbsResolvedFrequencySensitivity),:);
        if height(rank)<2,error('sensitivity:NoDominantParameters','Two accepted factors required.');end
        selected=rank.parameter(1:2);h=0.01;design=struct('id',{},'factors',{},'options',{});
        for a=[-1 1]
            for b=[-1 1]
                factors=struct();factors.(selected(1))=1+a*h;factors.(selected(2))=1+b*h;
                design(end+1)=struct('id',"comb_"+(a+2)+"_"+(b+2), ...
                    'factors',factors,'options',struct()); %#ok<AGROW>
            end
        end
        campaign=sensitivity.run_campaign(study,design,fullfile(folder,'interactions'));
        outputs=sensitivity.summarize_interactions(loaded.summary,campaign,selected,h);
    case "foundation"
        foundation=config_flexible_foundation();
        study.nominal.base=foundation.base;study.nominal.foundation=foundation.foundation;
        % Use identical rotor, structural damping and material data; only support changes.
        study.parameters=table(["foundation_stiffness";"foundation_damping"], ...
            'VariableNames',{'name'});study.steps=[0.01 0.005];
        campaign=sensitivity.run_campaign(study,sensitivity.local_design(study),fullfile(folder,'foundation'));
        sensitivity.export_nominal_properties(study,campaign.folder);
        outputs=sensitivity.summarize_local(campaign);
    case "verification"
        stopped=study;stopped.nominal.rotor.speedRPM=0;stopped.nominal.rotor.speedRPMGrid=0;
        stopped.nominal.rotor.mbc.enabled=false;stopped.nominal.modal.number=16;stopped.nominal.modes.number=16;
        design=struct('id',{},'factors',{},'options',{});
        for n=[1 2 4]
            design(end+1)=struct('id',"mesh_"+n,'factors',struct(),'options',struct('refinement',n)); %#ok<AGROW>
        end
        campaign=sensitivity.run_campaign(stopped,design,fullfile(folder,'mesh'));
        outputs=sensitivity.summarize_mesh(campaign);
    case "seismic"
        design=struct('id',{},'factors',{},'options',{});
        for dt=[0.01 0.005 0.0025 0.00125]
            design(end+1)=struct('id',"dt_"+round(dt*1e6),'factors',struct(), ...
                'options',struct('seismic',true,'dt',dt)); %#ok<AGROW>
        end
        for sign=[-1 1]
            design(end+1)=struct('id',"amplitude_"+(sign+2), ...
                'factors',struct('seismic_amplitude',1+sign*0.01), ...
                'options',struct('seismic',true,'dt',0.00125)); %#ok<AGROW>
        end
        campaign=sensitivity.run_campaign(study,design,fullfile(folder,'seismic'));
        outputs=sensitivity.summarize_time(campaign);
    otherwise
        error('sensitivity:UnknownPhase','Unknown initial phase %s.',phase);
end
end
