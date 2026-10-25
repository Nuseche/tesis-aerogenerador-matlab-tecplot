function r=central_difference(y0,ym,yp,h,referenceScale,forceScale)
%CENTRAL_DIFFERENCE Use relative normalization only for nonzero same-sign data.
if nargin<6,forceScale=false;end
if ~isscalar(h)||~isfinite(h)||h<=0||any(~isfinite([y0 ym yp referenceScale]))||referenceScale<=0
    error('sensitivity:InvalidDifference','Finite data, positive step and scale required.');
end
d=(yp-ym)/(2*h);sameSign=(sign(y0)==sign(ym))&&(sign(y0)==sign(yp));
relative=~forceScale&&sameSign&&abs(y0)>1e-8*referenceScale;
if relative
    scale=y0;method="relative_y0";
else
    scale=referenceScale;method="fixed_reference_scale";
end
r=struct('derivative',d,'sensitivity',d/scale,'scale',scale,'normalization',method, ...
    'curvature',(yp-2*y0+ym)/h^2,'signal',abs(yp-ym));
end
