function ops = rotating_section_operators(m,J,r,omega,position)
%ROTATING_SECTION_OPERATORS Physical energy linearization in rotating axes.
%   OPS = elements.rotating_section_operators(M,J,R,OMEGA[,POSITION])
%   uses q=[u;theta], x=R0*(position+u+exp(skew(theta))*r), and
%   R=R0*exp(skew(theta)), where R0dot=R0*skew(omega), omega is constant,
%   and J is the centroidal inertia in the nominal body axes. All vector
%   arguments use those axes. POSITION defaults to zero and is measured
%   from the origin of the rotating frame to the nominal reference point.
%   Properties may be total or per unit length, provided units are coherent.
%
%   M = T_vv; A = T_vq; G = A-A'; Kcentrifugal = -T_qq at q=v=0.
%   forceCentrifugal = T_q at q=v=0, so its first-order continuation is
%   forceCentrifugal-Kcentrifugal*q. Elastic/prestress and external-load
%   tangents are NOT included. Nonprincipal steady spin requires a holding
%   torque, whose load tangent depends on how that torque is applied.
%
%   The centrifugal Hessian includes the second-order rotation of r and
%   of the centroidal inertia. A linear CG interpolation alone misses it.
%   These are rotating-coordinate operators: a later time-dependent change
%   to inertial nodal coordinates must transport M, G, and K together.

    if nargin<5 || isempty(position),position=zeros(3,1);end
    if ~isnumeric(m)||~isreal(m)||~isscalar(m)||~isfinite(m)||m<=0
        error('elements:rotating_section_operators:InvalidMass', ...
            'Mass must be a real, positive, finite scalar.');
    end
    m=double(m);
    if ~isnumeric(J)||~isreal(J)||~isequal(size(J),[3 3])||any(~isfinite(J(:)))
        error('elements:rotating_section_operators:InvalidInertia', ...
            'Centroidal inertia must be a real, finite 3-by-3 matrix.');
    end
    J=double(J);jScale=max(norm(J,'fro'),realmin);
    if norm(J-J.','fro')>1e-11*jScale
        error('elements:rotating_section_operators:InvalidInertia', ...
            'Centroidal inertia must be symmetric.');
    end
    J=(J+J.')/2;principal=sort(eig(J));
    if principal(1)<-1e-12*jScale
        error('elements:rotating_section_operators:InvalidInertia', ...
            'Centroidal inertia must be positive semidefinite.');
    end
    if principal(3)>principal(1)+principal(2)+1e-10*jScale
        error('elements:rotating_section_operators:NonPhysicalInertia', ...
            'Principal mass moments must satisfy the triangle inequalities.');
    end
    r=vector3(r,'InvalidOffset','CG offset');
    omega=vector3(omega,'InvalidAngularVelocity','Angular velocity');
    position=vector3(position,'InvalidPosition','Reference position');
    W=skew(omega);Sr=skew(r);B=[eye(3),-Sr];E=[zeros(3),eye(3)];
    center=position+r;v0=W*center;a0=W*v0;h=J*omega;

    Mtranslation=m*(B.'*B);Mrotation=E.'*J*E;
    Atranslation=m*(B.'*W*B);
    % This symmetric term is a total time derivative for constant omega,
    % but belongs in the actual mixed Hessian A=T_vq.
    Aoffset=E.'*(m*bilinearHessian(v0,r))*E;
    Arotation=E.'*(J*W-skew(h)/2)*E;
    A=Atranslation+Aoffset+Arotation;
    Gtranslation=2*Atranslation;
    Grotation=E.'*(J*W+W*J-skew(h))*E;

    Ktranslation=m*(B.'*(W*W)*B);
    Koffset=E.'*(m*bilinearHessian(a0,r))*E;
    Krotation=E.'*(W*J*W-bilinearHessian(h,omega))*E;
    Kcentrifugal=Ktranslation+Koffset+Krotation;
    requiredTorque=cross(omega,h);
    forceCentrifugal=-B.'*(m*a0)-E.'*requiredTorque;

    ops=struct('M',Mtranslation+Mrotation,'A',A, ...
        'G',Gtranslation+Grotation,'Kcentrifugal',Kcentrifugal, ...
        'forceCentrifugal',forceCentrifugal,'mass',m, ...
        'inertiaCentroidal',J,'inertiaAboutReference',J-m*Sr*Sr, ...
        'offset',r,'omega',omega,'position',position, ...
        'nominalCentripetalAcceleration',a0, ...
        'centroidalHoldingTorque',requiredTorque);
    ops.parts=struct('gyroscopicTranslation',Gtranslation, ...
        'gyroscopicRotation',Grotation, ...
        'centrifugalTranslation',Ktranslation, ...
        'centrifugalOffsetCurvature',Koffset, ...
        'centrifugalRotation',Krotation);
    ops.metadata=struct('coordinates',"nominal rotating frame", ...
        'coordinateOrder',"[ux uy uz theta_x theta_y theta_z]", ...
        'orientation',"R=R0*exp(skew(theta))", ...
        'position',"x=R0*(position+u+exp(skew(theta))*r)", ...
        'constantAngularVelocity',true, ...
        'centrifugalSign',"force(q)=forceCentrifugal-Kcentrifugal*q", ...
        'externalLoadTangentsIncluded',false, ...
        'elasticAndPrestressTangentsIncluded',false, ...
        'principalMoments',principal);
end

function v=vector3(v,suffix,label)
    if ~isnumeric(v)||~isreal(v)||numel(v)~=3||any(~isfinite(v(:)))
        error(['elements:rotating_section_operators:' suffix], ...
            '%s must contain three real finite components.',label);
    end
    v=double(v(:));
end

function H=bilinearHessian(a,b)
    H=(a*b.'+b*a.')/2-(a.'*b)*eye(3);
end

function S=skew(v)
    S=[0 -v(3) v(2);v(3) 0 -v(1);-v(2) v(1) 0];
end
