function [N,dNdx,jacobian] = shape_functions_linear(xi,L)
%SHAPE_FUNCTIONS_LINEAR Two-node interpolation on an element of length L.

    arguments
        xi (1,1) double {mustBeFinite,mustBeGreaterThanOrEqual(xi,-1),mustBeLessThanOrEqual(xi,1)}
        L (1,1) double {mustBeFinite,mustBePositive}
    end
    N = [(1-xi)/2,(1+xi)/2];
    dNdx = [-1/L,1/L];
    jacobian = L/2;
end
