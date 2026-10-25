function tests=test_fem_core
tests=functiontests(localfunctions);
end

function testClosedTimoshenkoAndMass(testCase)
    s=section();L=5;
    [K,M]=elements.timoshenko3d_matrices(L,s);
    verifyLessThan(testCase,norm(K-K.',"fro"),1e-10*norm(K,"fro"));
    verifyLessThan(testCase,norm(M-M.',"fro"),1e-12*norm(M,"fro"));
    verifyEqual(testCase,sum(eig(K)<-1e-7*max(eig(K))),0);
    verifyEqual(testCase,sum(eig(K)<1e-7*max(eig(K))),6);
    verifyGreaterThan(testCase,min(eig(M)),0);
    qx=zeros(12,1);qx([1 7])=1;
    qy=zeros(12,1);qy([2 8])=1;
    verifyEqual(testCase,qx.'*M*qx,s.m*L,"RelTol",1e-12);
    verifyEqual(testCase,qy.'*M*qy,s.m*L,"RelTol",1e-12);
end

function testCantileverTimoshenkoAnalytic(testCase)
    s=section();L=8;[K,~]=elements.timoshenko3d_matrices(L,s);
    f=zeros(6,1);f(2)=1000;q=K(7:12,7:12)\f;
    expected=f(2)*L^3/(3*s.EIz)+f(2)*L/s.GAy;
    verifyEqual(testCase,q(2),expected,"RelTol",5e-13);
    f=zeros(6,1);f(3)=700;q=K(7:12,7:12)\f;
    expected=f(3)*L^3/(3*s.EIy)+f(3)*L/s.GAz;
    verifyEqual(testCase,q(3),expected,"RelTol",5e-13);
end

function testEulerBernoulliLimit(testCase)
    s=section();s.GAy=1e20;s.GAz=1e20;L=3;
    [K,~]=elements.timoshenko3d_matrices(L,s);f=zeros(6,1);f(2)=10;
    q=K(7:12,7:12)\f;expected=10*L^3/(3*s.EIz);
    verifyEqual(testCase,q(2),expected,"RelTol",1e-8);
end

function testAxialAndTorsionalCompliance(testCase)
    s=section();L=6;[K,~]=elements.timoshenko3d_matrices(L,s);
    force=3500;tip=K(7:12,7:12)\[force;0;0;0;0;0];
    verifyEqual(testCase,tip(1),force*L/s.EA,"RelTol",2e-13);
    torque=800;tip=K(7:12,7:12)\[0;0;0;torque;0;0];
    verifyEqual(testCase,tip(4),torque*L/s.GJ,"RelTol",2e-13);
end

function testLocalGlobalTransformation(testCase)
    s=section();xI=[1 2 3];xJ=[1 7 3];aux=[2 2 3];
    [K,M,info]=elements.timoshenko3d_matrices(xI,xJ,aux,s);
    verifyEqual(testCase,K,info.transformation.'*info.Klocal*info.transformation, ...
        "AbsTol",1e-8);
    verifyEqual(testCase,M,info.transformation.'*info.Mlocal*info.transformation, ...
        "AbsTol",1e-12);
    verifyEqual(testCase,info.transformation.'*info.transformation,eye(12), ...
        "AbsTol",5e-15);
end

function testUniformBeamMeshConvergence(testCase)
    s=section();s.GAy=1e22;s.GAz=1e22;
    s.Jy=1e-9;s.Jz=1e-9;s.Jx=s.Jy+s.Jz;
    elementCounts=[1 2 4 8];frequencies=zeros(size(elementCounts));Ltotal=12;
    for index=1:numel(elementCounts)
        n=elementCounts(index);K=sparse(2*(n+1),2*(n+1));M=K;
        [Ke,Me]=elements.timoshenko3d_matrices(Ltotal/n,s);
        bending=[2 6 8 12];Ke=Ke(bending,bending);Me=Me(bending,bending);
        for element=1:n
            dofs=[2*element-1 2*element 2*element+1 2*element+2];
            K(dofs,dofs)=K(dofs,dofs)+Ke;M(dofs,dofs)=M(dofs,dofs)+Me;
        end
        lambda=eigs(K(3:end,3:end),M(3:end,3:end),1,'smallestabs');
        frequencies(index)=sqrt(lambda)/(2*pi);
    end
    beta1=1.875104068711961;reference=beta1^2/(2*pi)* ...
        sqrt(s.EIz/(s.m*Ltotal^4));
    errors=abs(frequencies-reference);
    verifyTrue(testCase,all(diff(errors)<0));
    verifyLessThan(testCase,errors(end)/reference,2e-5);
end

function testSparseAssemblyFoundationAndDrivetrain(testCase)
    model=twoElementModel();cfg=struct();cfg.base.type="flexible";
    cfg.foundation.M=diag(1:6);cfg.foundation.K=diag(11:16);
    cfg.drivetrain.stiffness=[1 2 3 4 5 6]*1e5;
    [M,K,cache,d]=assembly.assemble_structural_matrices(model,cfg);
    verifyTrue(testCase,issparse(M));verifyTrue(testCase,issparse(K));
    verifyEqual(testCase,numel(cache),2);verifyTrue(testCase,all([cache.assembled]));
    verifyTrue(testCase,d.foundation.enabled);verifyTrue(testCase,d.drivetrain.stiffnessProvided);
    verifyEqual(testCase,full(diag(d.components.Mfoundation(1:6,1:6))),(1:6).');
    q=zeros(18,1);q(7:9)=1;q(13:15)=1;
    verifyEqual(testCase,q.'*d.components.Kdrivetrain*q,0,"AbsTol",1e-6);
end

function testGeometricGyroscopicAndLoads(testCase)
    Kg=elements.geometric_stiffness(4,100);
    verifyLessThan(testCase,norm(Kg-Kg.',"fro"),1e-12);
    verifyGreaterThanOrEqual(testCase,min(eig(Kg)),-1e-12);
    model=twoElementModel();model.rigidBodies.bodies=struct("name","hub", ...
        "masterNode",130,"mass",20,"cgOffsetBody",zeros(3,1), ...
        "inertiaBody",diag([5 6 7]),"orientationBodyToGlobal",eye(3),"rotating",true);
    cfg.rotor.speedRPM=12;[G,~]=assembly.assemble_gyroscopic_matrix(model,struct(),cfg);
    verifyLessThan(testCase,norm(G+G.',"fro"),1e-12);
    cfg.rotor.speedRPM=-12;Gminus=assembly.assemble_gyroscopic_matrix(model,struct(),cfg);
    verifyEqual(testCase,Gminus,-G,"AbsTol",1e-12);
end

function testNonsymmetricAerodynamicLinearization(testCase)
    cfg.aerodynamics.loadFcn=@aeroLoad;
    cfg.aerodynamics.dofIndices=[1 2];state.qFull=[.2;-.1];state.qdFull=[.3;.4];
    [Kaero,Caero,report]=assembly.linearize_aerodynamic_loads(struct(),state,cfg,2);
    verifyEqual(testCase,full(Kaero),-[2 3;-1 4],"AbsTol",2e-10);
    verifyEqual(testCase,full(Caero),-[.5 -.2;.7 .9],"AbsTol",2e-10);
    verifyGreaterThan(testCase,norm(Kaero-Kaero.','fro'),0);
    verifyEqual(testCase,report.method,"central_finite_difference_refined");
end

function testStaticEquilibrium(testCase)
    model=oneBeamModel();cfg.gravity.enabled=false;
    [M,K]=assembly.assemble_structural_matrices(model,cfg);
    Tc=speye(12);reduced=rigid.reduce_system(Tc,M,K,model,cfg);
    cfg.loads.vector=zeros(12,1);cfg.loads.vector(8)=100;
    state=equilibrium.solve_static_equilibrium(model,reduced,cfg);
    verifyTrue(testCase,state.converged);verifyLessThan(testCase,state.residualRelative,1e-8);
    verifyGreaterThan(testCase,state.qFull(8),0);
end

function s=section()
    s=struct("id",1,"EA",2.1e9,"GAy",4e8,"GAz",3e8,"GJ",1.5e8, ...
        "EIy",8e7,"EIz",6e7,"m",25,"Jx",2,"Jy",1.2,"Jz",1.4,"ycg",0,"zcg",0);
end
function model=oneBeamModel()
    model.mesh.nodes=struct("id",[1;2],"xyz",[0 0 0;4 0 0]);
    model.mesh.elements=struct("id",1,"nodeI",1,"nodeJ",2,"section",1, ...
        "blade",0,"type","tower","auxPoint",[0 1 0]);
    model.sections=section();model.dofs.node=reshape(1:12,6,2).';model.dofs.element=1:12;model.dofs.number=12;
    model.dofs.fixed=(1:6).';model.boundaryConditions.fixedNodeIds=1;model.boundaryConditions.fixedDofs=1:6;
end
function model=twoElementModel()
    model.mesh.nodes=struct("id",[1;129;130],"xyz",[0 0 0;2 0 0;3 0 0]);
    model.mesh.elements=struct("id",[1;2],"nodeI",[1;129],"nodeJ",[129;130], ...
        "section",[1;1],"blade",[0;0],"type",["tower";"transition"],"auxPoint",[0 1 0;2 1 0]);
    model.sections=section();model.dofs.node=reshape(1:18,6,3).';
    model.dofs.element=[model.dofs.node(1,:) model.dofs.node(2,:);model.dofs.node(2,:) model.dofs.node(3,:)];
    model.dofs.number=18;model.dofs.fixed=(1:6).';model.boundaryConditions.fixedNodeIds=1;model.boundaryConditions.fixedDofs=1:6;
end
function f=aeroLoad(q,qd,~,~,~)
f=[2 3;-1 4]*q+[.5 -.2;.7 .9]*qd;
end
