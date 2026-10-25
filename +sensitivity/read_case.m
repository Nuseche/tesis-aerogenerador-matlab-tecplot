function result=read_case(folder,id)
%READ_CASE Failed/missing cases never become fictitious results.
f=fullfile(folder,string(id)+'.mat');
if ~isfile(f),error('sensitivity:MissingCase','Missing case %s.',id);end
s=load(f,'record');
if s.record.status~="success"
    error('sensitivity:FailedCase','Case %s failed: %s',id,s.record.errorMessage);
end
result=s.record.result;
end
