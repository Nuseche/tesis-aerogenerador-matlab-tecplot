root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fileparts(fileparts(fileparts(mfilename('fullpath'))))); addpath(fullfile(root,'cases'));
files=dir(fullfile(root,'+sensitivity/*.m'));
for k=1:numel(files)
  messages=checkcode(fullfile(files(k).folder,files(k).name),'-id');
  for j=1:numel(messages)
    fprintf('%s:%d %s %s\n',files(k).name,messages(j).line,messages(j).id,messages(j).message);
  end
end
results=runtests(fullfile(root,'tests/test_sensitivity.m'));
save(fullfile(root,'docs/sensibilidad_20261005/module_tests.mat'),'results');
assertSuccess(results);
