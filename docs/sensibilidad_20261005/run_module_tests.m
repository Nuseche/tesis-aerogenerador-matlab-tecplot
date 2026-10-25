addpath('/Users/nuseche/Desktop/Tesis_codigos'); addpath('/Users/nuseche/Desktop/Tesis_codigos/cases');
files=dir('/Users/nuseche/Desktop/Tesis_codigos/+sensitivity/*.m');
for k=1:numel(files)
  messages=checkcode(fullfile(files(k).folder,files(k).name),'-id');
  for j=1:numel(messages)
    fprintf('%s:%d %s %s\n',files(k).name,messages(j).line,messages(j).id,messages(j).message);
  end
end
results=runtests('/Users/nuseche/Desktop/Tesis_codigos/tests/test_sensitivity.m');
save('/Users/nuseche/Desktop/Tesis_codigos/docs/sensibilidad_20261005/module_tests.mat','results');
assertSuccess(results);
