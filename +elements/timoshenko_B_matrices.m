function [BaxialBending,Bshear,N6,info] = timoshenko_B_matrices(xi,L)
%TIMOSHENKO_B_MATRICES Linear 3-D Timoshenko kinematics.
%   Generalized strain order is
%   [epsilon_x gamma_y gamma_z kappa_x kappa_y kappa_z].
%   Nodal DOFs are [u v w theta_x theta_y theta_z] at nodes 1 and 2.
%   The signs implement gamma_y=dv/dx-theta_z and
%   gamma_z=dw/dx+theta_y.

    [N,dNdx,jacobian] = elements.shape_functions_linear(xi,L);
    BaxialBending = zeros(6,12);
    Bshear = zeros(6,12);

    BaxialBending(1,[1 7]) = dNdx;  % epsilon_x
    BaxialBending(4,[4 10]) = dNdx; % kappa_x
    BaxialBending(5,[5 11]) = dNdx; % kappa_y
    BaxialBending(6,[6 12]) = dNdx; % kappa_z

    Bshear(2,[2 8]) = dNdx;
    Bshear(2,[6 12]) = -N;
    Bshear(3,[3 9]) = dNdx;
    Bshear(3,[5 11]) = N;

    N6 = [N(1)*eye(6),N(2)*eye(6)];
    info = struct("N",N,"dNdx",dNdx,"jacobian",jacobian, ...
        "B",BaxialBending+Bshear);
end
