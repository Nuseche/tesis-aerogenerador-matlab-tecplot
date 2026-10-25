function [xi,weights] = gauss_rule(order)
%GAUSS_RULE Gauss-Legendre points and weights on [-1,1].
%   Orders one through four cover reduced shear, standard stiffness,
%   variable sectional mass, and exact integration of the closed-element
%   polynomial mass interpolation.

    arguments
        order (1,1) double {mustBeInteger,mustBePositive}
    end
    switch order
        case 1
            xi = 0;
            weights = 2;
        case 2
            xi = [-1;1]/sqrt(3);
            weights = [1;1];
        case 3
            xi = [-sqrt(3/5);0;sqrt(3/5)];
            weights = [5/9;8/9;5/9];
        case 4
            a = sqrt((3-2*sqrt(6/5))/7);
            b = sqrt((3+2*sqrt(6/5))/7);
            wa = (18+sqrt(30))/36;
            wb = (18-sqrt(30))/36;
            xi = [-b;-a;a;b];
            weights = [wb;wa;wa;wb];
        otherwise
            error("elements:gauss_rule:UnsupportedOrder", ...
                "Gauss-Legendre order %d is unsupported; use 1, 2, 3, or 4.",order);
    end
end
