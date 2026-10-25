function T=verify_historical_nominal(study,result,folder)
%VERIFY_HISTORICAL_NOMINAL Regression against September corrected evidence.
f=fullfile(study.nominal.paths.projectRoot,'runs', ...
    'run_20260919_182410_438_gyro_energy_corrected_20260919','results.mat');
old=load(f,'results');i=find(old.results.modal.speedRPMGrid==study.nominal.rotor.speedRPM,1);
if isempty(i),error('sensitivity:ReferenceSpeed','Historical nominal speed missing.');end
historical=struct('solution',old.results.modal.solutions{i},'fullMass',result.fullMass);
tr=sensitivity.track_modes(result,historical,study);
n=study.branches;new=result.solution.dampedFrequencyHz(1:n);prior=tr.matchedFrequencyHz;
relative=abs(new-prior)./max(abs(prior),eps);
T=table((1:n).',new,prior,relative,tr.individualMAC,tr.subspaceMAC,tr.individualValid, ...
    'VariableNames',{'mode','newFrequencyHz','historicalFrequencyHz','relativeDifference', ...
    'individualMAC','subspaceMAC','individualValid'});
writetable(T,fullfile(folder,'historical_nominal_regression.csv'));
end
