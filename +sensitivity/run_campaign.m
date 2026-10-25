function campaign=run_campaign(study,design,folder)
%RUN_CAMPAIGN Batch/resume with immutable code/config/data fingerprint.
% design: struct array with id, factors, options; failures remain explicit.
if nargin<3||strlength(string(folder))==0
    folder=fullfile(study.outputRoot,"study_"+string(datetime('now','Format','yyyyMMdd_HHmmss_SSS')));
end
folder=char(folder);root=char(study.nominal.paths.projectRoot);
p=sensitivity.provenance(root);
key=sensitivity.sha256(jsonencode(struct('study',study,'design',design, ...
    'source',p.fingerprint,'matlab',p.matlabVersion)));
manifestPath=fullfile(folder,'campaign.mat');
if numel(design)>study.maxCases
    error('sensitivity:BudgetExceeded','%d cases exceed explicit budget %d.',numel(design),study.maxCases);
end
if isfile(manifestPath)
    old=load(manifestPath,'campaign');
    if old.campaign.key~=key,error('sensitivity:ResumeMismatch', ...
            'Code, data or configuration changed; use a new folder.');end
    campaign=old.campaign;
else
    if isfolder(folder)&&~isempty(dir(fullfile(folder,'*.mat')))
        error('sensitivity:ExistingResults','Existing MAT files require an identical campaign manifest.');
    end
    if ~isfolder(folder),mkdir(folder);end
    campaign=struct('key',key,'study',study,'design',design,'folder',string(folder), ...
        'provenance',p,'startedUTC',string(datetime('now','TimeZone','UTC')), ...
        'completed',false);
    save(manifestPath,'campaign','-v7.3');
    writetable(p.files,fullfile(folder,'source_hashes.csv'));
    writetable(study.parameters,fullfile(folder,'parameters.csv'));
    fid=fopen(fullfile(folder,'campaign.json'),'w');fprintf(fid,'%s', ...
        jsonencode(struct('key',key,'study',study,'design',design,'source',p.fingerprint),PrettyPrint=true));fclose(fid);
end
ids=string({design.id}).';status=repmat("pending",numel(design),1);
elapsed=nan(numel(design),1);messages=strings(numel(design),1);
progress=table(ids,status,elapsed,messages,'VariableNames',{'caseId','status','seconds','error'});
budgetStopped=false;
for k=1:numel(design)
    id=string(design(k).id);
    if isempty(regexp(id,'^[A-Za-z0-9_]+$','once'))
        error('sensitivity:UnsafeCaseId','Use simple alphanumeric case IDs.');
    end
    ids(k)=id;casePath=fullfile(folder,id+'.mat');
    if isfile(casePath)
        saved=load(casePath,'record');record=saved.record;
        if record.campaignKey~=key,error('sensitivity:CaseMismatch','Cached case fingerprint mismatch.');end
        fprintf('[%d/%d] %s: cached %s\n',k,numel(design),id,record.status);
    else
        if isfield(study,'maximumWallSeconds')
            if isfield(study,'budgetStartUTC'),budgetStart=study.budgetStartUTC;
            else,budgetStart=campaign.startedUTC;end
            spent=seconds(datetime('now','TimeZone','UTC')-datetime(budgetStart,'TimeZone','UTC'));
            if spent>=study.maximumWallSeconds
                budgetStopped=true;
                progress=table(ids,status,elapsed,messages,'VariableNames',{'caseId','status','seconds','error'});
                fprintf('Wall budget reached; remaining cases stay pending.\n');break
            end
        end
        started=tic;
        record=struct('campaignKey',key,'id',id,'factors',design(k).factors, ...
            'options',design(k).options,'status',"running",'result',[], ...
            'errorIdentifier',"",'errorMessage',"",'errorReport',"", ...
            'createdUTC',string(datetime('now','TimeZone','UTC')));
        try
            record.result=sensitivity.evaluate_case(study,design(k).factors,design(k).options);
            record.status="success";
        catch ME
            record.status="failed";record.errorIdentifier=string(ME.identifier);
            record.errorMessage=string(ME.message);record.errorReport=string(getReport(ME,'extended','hyperlinks','off'));
        end
        record.elapsedSeconds=toc(started);
        % Save to a temporary name then move; an interrupted partial write is not a cache.
        tempPath=[tempname(folder) '.mat'];save(tempPath,'record','-v7.3');
        movefile(tempPath,casePath);
        fprintf('[%d/%d] %s: %s (%.2f s) %s\n',k,numel(design),id,record.status,record.elapsedSeconds,record.errorMessage);
    end
    status(k)=record.status;elapsed(k)=record.elapsedSeconds;messages(k)=record.errorMessage;
    progress=table(ids(1:k),status(1:k),elapsed(1:k),messages(1:k), ...
        'VariableNames',{'caseId','status','seconds','error'});
    writetable(progress,fullfile(folder,'case_status.csv'));
    if isfield(study,'checkpointCases')&&any(k==study.checkpointCases)
        campaign.status=progress;
        try
            feval(study.checkpointFunction,campaign);
        catch ME
            warning('sensitivity:CheckpointFailed','%s',ME.message);
            fid=fopen(fullfile(folder,sprintf('checkpoint_%d_error.txt',k)),'w');
            fprintf(fid,'%s',getReport(ME,'extended','hyperlinks','off'));fclose(fid);
        end
    end
end
campaign.completed=~budgetStopped;campaign.budgetStopped=budgetStopped;
campaign.finishedUTC=string(datetime('now','TimeZone','UTC'));
campaign.status=progress;save(manifestPath,'campaign','-v7.3');
writetable(progress,fullfile(folder,'case_status.csv'));
end
