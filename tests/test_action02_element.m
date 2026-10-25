function tests = test_action02_element
%TEST_ACTION02_ELEMENT Focused acceptance tests for PLAN_ACCION_02.
tests = functiontests(localfunctions);
end

function testAuxiliaryDefinesLocalE3AndAnisotropicPlanes(testCase)
    xI = [0 0 0];xJ = [5 0 0];aux = [0 0 2];
    [R,Te,L,frame] = elements.element_rotation_matrix(xI,xJ,aux);
    verifyEqual(testCase,R,eye(3),"AbsTol",5e-15);
    verifyEqual(testCase,Te,eye(12),"AbsTol",5e-15);
    verifyEqual(testCase,L,5,"AbsTol",0);
    verifyLessThan(testCase,frame.orthogonalityError,1e-14);
    verifyEqual(testCase,frame.determinant,1,"AbsTol",5e-15);
    verifyEqual(testCase,frame.e3,[0;0;1],"AbsTol",5e-15);

    s = baseSection();
    K = elements.timoshenko3d_matrices(xI,xJ,aux,s);
    tip = K(7:12,7:12)\[0;1000;0;0;0;0];
    expectedY = 1000*L^3/(3*s.EIz)+1000*L/s.GAy;
    verifyEqual(testCase,tip(2),expectedY,"RelTol",2e-12);
    tip = K(7:12,7:12)\[0;0;700;0;0;0];
    expectedZ = 700*L^3/(3*s.EIy)+700*L/s.GAz;
    verifyEqual(testCase,tip(3),expectedZ,"RelTol",2e-12);
end

function testCoordinateEnergyAndFrequencyInvariance(testCase)
    s = baseSection();L = 4.3;
    xI = [0 0 0];xJ = [L 0 0];aux = [0 0 1];
    angleZ = deg2rad(37);angleY = deg2rad(-21);
    Rz = [cos(angleZ) -sin(angleZ) 0;sin(angleZ) cos(angleZ) 0;0 0 1];
    Ry = [cos(angleY) 0 sin(angleY);0 1 0;-sin(angleY) 0 cos(angleY)];
    Q = Rz*Ry;
    xJrot = (Q*xJ.').';auxRot = (Q*aux.').';
    [K0,M0] = elements.timoshenko3d_matrices(xI,xJ,aux,s);
    [K1,M1] = elements.timoshenko3d_matrices(xI,xJrot,auxRot,s);
    P = blkdiag(Q,Q,Q,Q);
    verifyLessThan(testCase,norm(K1-P*K0*P.',"fro")/norm(K0,"fro"),2e-14);
    verifyLessThan(testCase,norm(M1-P*M0*P.',"fro")/norm(M0,"fro"),2e-14);
    q = sin((1:12).'/7);qRot = P*q;
    verifyEqual(testCase,qRot.'*K1*qRot,q.'*K0*q,"RelTol",3e-14);
    f0 = fixedEndFrequencies(K0,M0,3);
    f1 = fixedEndFrequencies(K1,M1,3,P);
    verifyEqual(testCase,f1,f0,"RelTol",2e-12);
end

function testBMatricesAnnihilateSixRigidMotions(testCase)
    L = 3.7;Q = rigidMotions(L);
    for xi = [-1/sqrt(3),0,1/sqrt(3)]
        [Bab,Bs,N6,info] = elements.timoshenko_B_matrices(xi,L);
        verifyLessThan(testCase,norm((Bab+Bs)*Q,"fro"),2e-15);
        verifySize(testCase,N6,[6 12]);
        verifyEqual(testCase,info.B,Bab+Bs,"AbsTol",0);
    end
end

function testDefaultClosedExactAndExplicitSelectiveResponses(testCase)
    s = baseSection();L = 8;P = 1000;
    [Kdefault,~,defaultData] = elements.timoshenko3d_matrices(L,s);
    cfg.element.formulation = "closed_exact";
    [Kclosed,~,closedData] = elements.timoshenko3d_matrices(L,s,cfg);
    verifyEqual(testCase,Kdefault,Kclosed,"AbsTol",0);
    verifyEqual(testCase,defaultData.formulation,"closed_exact");
    verifyEqual(testCase,closedData.rigidModeCount,6);
    q = Kclosed(7:12,7:12)\[0;P;0;0;0;0];
    verifyEqual(testCase,q(2),P*L^3/(3*s.EIz)+P*L/s.GAy,"RelTol",2e-12);

    cfg.element.formulation = "selective_integration";
    [Ks,~,selectiveData] = elements.timoshenko3d_matrices(L,s,cfg);
    q = Ks(7:12,7:12)\[0;P;0;0;0;0];
    % Linear rotations plus one-point shear: one-element bending coefficient 1/4.
    verifyEqual(testCase,q(2),P*L^3/(4*s.EIz)+P*L/s.GAy,"RelTol",2e-12);
    verifyEqual(testCase,selectiveData.formulation,"selective_integration");
    verifyEqual(testCase,selectiveData.rigidModeCount,6);
    verifyEqual(testCase,selectiveData.gauss.axialBending.order,2);
    verifyEqual(testCase,selectiveData.gauss.shear.order,1);
    verifyEqual(testCase,selectiveData.gauss.mass.order,2);
    verifyLessThan(testCase,selectiveData.rigidEnergyResidual,1e-13);
end

function testSelectiveIntegrationAcceptsCoupledK6AndPreservesCoupledM6(testCase)
    s0 = baseSection();
    K6 = diag([s0.EA s0.GAy s0.GAz s0.GJ s0.EIy s0.EIz]);
    K6(1,4) = 0.03*sqrt(K6(1,1)*K6(4,4));K6(4,1) = K6(1,4);
    K6(2,6) = 0.02*sqrt(K6(2,2)*K6(6,6));K6(6,2) = K6(2,6);
    K6(5,6) = -0.04*sqrt(K6(5,5)*K6(6,6));K6(6,5) = K6(5,6);
    m = 31;r = [0;0.18;-0.11];S = skew(r);
    Jc = [2.4 .08 -.04;.08 1.25 .03;-.04 .03 1.45];
    M6 = [m*eye(3),-m*S;m*S,Jc-m*S*S];
    s = struct("id",42,"K6",K6,"M6",M6);
    cfg.element.formulation = "selective_integration";
    [K,M,data] = elements.timoshenko3d_matrices(2.4,s,cfg);
    verifyTrue(testCase,data.sectionStiffness.isCoupled);
    verifyEqual(testCase,data.K6,K6,"AbsTol",1e-8);
    verifyEqual(testCase,data.M6,M6,"AbsTol",1e-12);
    verifyEqual(testCase,data.sectionMass.offset,r,"AbsTol",2e-15);
    verifyLessThan(testCase,norm(K-K.',"fro")/norm(K,"fro"),2e-15);
    verifyLessThan(testCase,norm(M-M.',"fro")/norm(M,"fro"),2e-15);
    verifyEqual(testCase,data.rigidModeCount,6);
    verifyError(testCase,@() elements.timoshenko3d_matrices(2.4,s), ...
        "elements:timoshenko3d_matrices:CoupledClosedStiffness");
end

function testEccentricM6RecoversMassAndInertialMoment(testCase)
    s = baseSection();s.m = 29;s.ycg = 0.24;s.zcg = -0.13;
    L = 3.2;cfg.element.formulation = "selective_integration";
    [~,M,data] = elements.timoshenko3d_matrices(L,s,cfg);
    acceleration = [0.7;-1.1;2.3];
    nodalAcceleration = [acceleration;zeros(3,1);acceleration;zeros(3,1)];
    inertia = M*nodalAcceleration;
    force = inertia(1:3)+inertia(7:9);
    moment = inertia(4:6)+inertia(10:12);
    expectedForce = s.m*L*acceleration;
    expectedMoment = cross([0;s.ycg;s.zcg],expectedForce);
    verifyEqual(testCase,force,expectedForce,"RelTol",2e-14);
    verifyEqual(testCase,moment,expectedMoment,"AbsTol",2e-13);
    verifyEqual(testCase,data.sectionMass.offset,[0;s.ycg;s.zcg],"AbsTol",2e-15);
end

function testSectionMassPhysicalValidationAndDocumentedRule(testCase)
    s = baseSection();s.Jx = s.Jy+s.Jz;
    [M6,info] = elements.section_mass(s);
    verifyEqual(testCase,M6(1:3,1:3),s.m*eye(3),"AbsTol",0);
    verifyLessThanOrEqual(testCase,info.inertiaTriangleResidual, ...
        info.inertiaTriangleTolerance*max([1;info.inertiaEigenvalues]));

    unresolved = s;unresolved.Jx = NaN;
    verifyError(testCase,@() elements.section_mass(unresolved), ...
        "elements:section_mass:MissingTorsionalInertia");
    unresolved.torsionalInertiaRule = "perpendicular_axis";
    [~,resolved] = elements.section_mass(unresolved);
    verifyEqual(testCase,resolved.centroidalInertia(1,1),s.Jy+s.Jz,"AbsTol",1e-14);

    invalid = s;invalid.Jx = 5*(s.Jy+s.Jz);
    verifyError(testCase,@() elements.section_mass(invalid), ...
        "elements:section_mass:InvalidInertia");
end

function testGaussRulesAndLinearShapeFunctions(testCase)
    for order = 1:4
        [xi,w] = elements.gauss_rule(order);
        verifyEqual(testCase,sum(w),2,"AbsTol",5e-15);
        for power = 0:(2*order-1)
            numerical = sum(w.*xi.^power);
            if mod(power,2),exact = 0;else,exact = 2/(power+1);end
            verifyEqual(testCase,numerical,exact,"AbsTol",2e-14);
        end
    end
    [N,dNdx,J] = elements.shape_functions_linear(0.37,5);
    verifyEqual(testCase,sum(N),1,"AbsTol",0);
    verifyEqual(testCase,sum(dNdx),0,"AbsTol",0);
    verifyEqual(testCase,J,2.5,"AbsTol",0);
end

function testSelectiveStaticMeshConvergence(testCase)
    s = baseSection();
    cfg.element.formulation = "selective_integration";
    counts = [1 2 4 8 16 32];Ltotal = 12;P = 1000;
    slenderShear = 1e6*max(s.EIy,s.EIz)/Ltotal^2;
    s.GAy = slenderShear;s.GAz = slenderShear;
    tip = zeros(size(counts));
    for k = 1:numel(counts)
        n = counts(k);[K,~] = bendingMesh(n,Ltotal,s,cfg);
        loadVector = zeros(2*(n+1)-2,1);loadVector(end-1) = P;
        q = K\loadVector;tip(k) = q(end-1);
    end
    staticReference = P*Ltotal^3/(3*s.EIz)+P*Ltotal/s.GAy;
    staticError = abs(tip-staticReference);
    verifyTrue(testCase,all(diff(staticError)<0));
    verifyLessThan(testCase,staticError(end)/staticReference,3e-4);
end

function [Kfree,Mfree] = bendingMesh(n,Ltotal,s,cfg)
    ndof = 2*(n+1);K = sparse(ndof,ndof);M = sparse(ndof,ndof);
    [Ke,Me] = elements.timoshenko3d_matrices(Ltotal/n,s,cfg);
    indices = [2 6 8 12];Ke = Ke(indices,indices);Me = Me(indices,indices);
    for e = 1:n
        dofs = [2*e-1 2*e 2*e+1 2*e+2];
        K(dofs,dofs) = K(dofs,dofs)+Ke;
        M(dofs,dofs) = M(dofs,dofs)+Me;
    end
    Kfree = K(3:end,3:end);Mfree = M(3:end,3:end);
end

function frequencies = fixedEndFrequencies(K,M,count,P)
    if nargin < 4
        Kfree = K(7:12,7:12);Mfree = M(7:12,7:12);
    else
        free = 7:12;globalFree = [free(1:3) free(4:6)]; %#ok<NASGU>
        % P maps the original global components to the rotated components.
        Tfree = P(:,7:12);
        Kfree = Tfree.'*K*Tfree;Mfree = Tfree.'*M*Tfree;
    end
    lambda = sort(real(eig(Kfree,Mfree)));
    frequencies = sqrt(lambda(1:count))/(2*pi);
end

function Q = rigidMotions(L)
    Q = zeros(12,6);
    Q([1 7],1) = 1;Q([2 8],2) = 1;Q([3 9],3) = 1;
    Q([4 10],4) = 1;
    Q([5 11],5) = 1;Q(9,5) = -L;
    Q([6 12],6) = 1;Q(8,6) = L;
end

function S = skew(r)
    S = [0 -r(3) r(2);r(3) 0 -r(1);-r(2) r(1) 0];
end

function s = baseSection()
    s = struct("id",1,"EA",2.1e9,"GAy",4e8,"GAz",3e8, ...
        "GJ",1.5e8,"EIy",8e7,"EIz",6e7,"m",25, ...
        "Jx",2.6,"Jy",1.2,"Jz",1.4,"ycg",0,"zcg",0);
end
