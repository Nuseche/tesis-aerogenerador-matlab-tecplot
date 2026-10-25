function stats=morris_statistics(effects,noiseBound,valid,prefixes,tolerance,signalToNoise)
%MORRIS_STATISTICS No omission of invalid or unresolved effects.
rows=cell(0,13);previous=NaN;previousSigma=NaN;
for n=prefixes(:).'
    if n>numel(effects),continue,end
    e=effects(1:n);b=noiseBound(1:n);v=valid(1:n);
    complete=all(v)&all(isfinite(e))&all(isfinite(b));
    mu=NaN;muStar=NaN;sigma=NaN;muNoise=NaN;sigmaNoise=NaN;change=NaN;sigChange=NaN;
    if complete
        mu=mean(e);muStar=mean(abs(e));sigma=std(e,0);
        muNoise=mean(b);sigmaNoise=sqrt(sum(b.^2)/max(n-1,1));
        if isfinite(previous)
            change=abs(muStar-previous)/max([muStar,muNoise,eps]);
            sigChange=abs(sigma-previousSigma)/max([sigma,sigmaNoise,eps]);
        end
    end
    resolved=complete&&muStar>=signalToNoise*muNoise;
    converged=complete&&isfinite(change)&&change<=tolerance;
    sigmaResolved=complete&&sigma>=signalToNoise*sigmaNoise;
    rows(end+1,:)={n,nnz(v),mu,muStar,sigma,muNoise,sigmaNoise,change,sigChange, ...
        complete,resolved,converged,sigmaResolved}; %#ok<AGROW>
    previous=muStar;previousSigma=sigma;
end
stats=cell2table(rows,'VariableNames',{'trajectories','validEffects','mu','muStar','sigma', ...
    'muNoiseBound','sigmaNoiseBound','muStarRelativeChange','sigmaRelativeChange', ...
    'allEffectsValid','meanEffectResolved','muStarConverged','dispersionResolved'});
stats.sigmaConverged=stats.dispersionResolved&stats.sigmaRelativeChange<=tolerance;
stats.acceptedMean=stats.meanEffectResolved&stats.muStarConverged;
stats.acceptedDispersion=stats.dispersionResolved&stats.sigmaConverged;
end
