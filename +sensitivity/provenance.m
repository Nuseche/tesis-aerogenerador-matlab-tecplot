function p=provenance(root)
%PROVENANCE Content hashes replace unavailable Git history; include tests/data.
files=[dir(fullfile(root,'+*','**','*.m'));dir(fullfile(root,'cases','*.m')); ...
    dir(fullfile(root,'tests','*.m'));dir(fullfile(root,'data','**','*.mat')); ...
    dir(fullfile(root,'data','**','*.json'));dir(fullfile(root,'config_default.m')); ...
    dir(fullfile(root,'main.m'))];
paths=strings(numel(files),1);hashes=paths;
for k=1:numel(files)
    f=fullfile(files(k).folder,files(k).name);
    paths(k)=extractAfter(string(f),strlength(string(root))+1);
    fid=fopen(f,'rb');cleanup=onCleanup(@()fclose(fid));bytes=fread(fid,Inf,'*uint8');
    clear cleanup
    hashes(k)=sensitivity.sha256(bytes);
end
[paths,order]=sort(paths);hashes=hashes(order);
p=struct('root',string(root),'files',table(paths,hashes), ...
    'fingerprint',sensitivity.sha256(join(paths+":"+hashes,newline)), ...
    'matlabVersion',string(version),'gitStatus',"unavailable_no_repository", ...
    'createdUTC',string(datetime('now','TimeZone','UTC')));
end
