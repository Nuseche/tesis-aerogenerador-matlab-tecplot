function [assignment,totalScore,pairs] = optimal_assignment(score)
%OPTIMAL_ASSIGNMENT Global one-to-one maximum-score assignment.

score=double(score);
if isempty(score)||any(~isfinite(score),'all')
    error('modal:Assignment:InvalidScore', ...
        'Score must be a nonempty finite matrix.');
end
[nRows,nColumns]=size(score);
if nRows>nColumns
    error('modal:Assignment:FewerCandidates', ...
        'At least one candidate column is required per tracked row.');
end
maximum=max(score,[],'all');cost=maximum-score;
pairs=matchpairs(cost,1e9,'min');
if size(pairs,1)~=nRows
    error('modal:Assignment:Incomplete', ...
        'The global assignment did not cover every tracked row.');
end
[~,order]=sort(pairs(:,1));pairs=pairs(order,:);
assignment=pairs(:,2).';
totalScore=sum(score(sub2ind(size(score),pairs(:,1),pairs(:,2))));
end
