function coefficients=polar_coefficients(data,alpha,thickness)
%POLAR_COEFFICIENTS Periodic angle lookup and explicit thickness interpolation.
alpha=mod(alpha(:)*180/pi+180,360)-180;thickness=thickness(:);
if numel(alpha)~=numel(thickness)||any(~isfinite(alpha))||any(~isfinite(thickness))||any(thickness<.18|thickness>1)
    error('aero:PolarInput','Angles and thickness fractions must be finite and in range.');
end
coefficients=zeros(numel(alpha),3);
for k=1:numel(data.thickness)-1
    use=thickness>=data.thickness(k)&thickness<=data.thickness(k+1);
    w=(thickness(use)-data.thickness(k))/(data.thickness(k+1)-data.thickness(k));
    coefficients(use,:)=(1-w).*data.lookup{k}(alpha(use))+w.*data.lookup{k+1}(alpha(use));
end
if any(~isfinite(coefficients),'all'),error('aero:PolarRange','Polar lookup returned nonfinite values.');end
end
