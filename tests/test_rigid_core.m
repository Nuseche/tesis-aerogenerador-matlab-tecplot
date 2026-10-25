function tests=test_rigid_core
tests=functiontests(localfunctions);
end

function testExactLegacyRotorConstraint(testCase)
    model=constraintModel();bodies.constraints=struct("masterNode",130,"slaveNodes",[21;57;93]);
    [Tc,info]=rigid.rigid_constraint_matrix(model,bodies,struct());
    verifyTrue(testCase,issparse(Tc));verifyEqual(testCase,sprank(Tc),size(Tc,2));
    qbar=zeros(size(Tc,2),1);masterDofs=model.dofs.node(2,:);
    qMaster=[1;2;3;.1;-.2;.3];
    for k=1:6,qbar(info.fullToReduced(masterDofs(k)))=qMaster(k);end
    q=Tc*qbar;
    for id=[21 57 93]
        sr=find(model.mesh.nodes.id==id);r=(model.mesh.nodes.xyz(sr,:)-model.mesh.nodes.xyz(2,:)).';
        S=[0 -r(3) r(2);r(3) 0 -r(1);-r(2) r(1) 0];expected=[eye(3) -S;zeros(3) eye(3)]*qMaster;
        verifyEqual(testCase,q(model.dofs.node(sr,:)),expected,"AbsTol",2e-15);
    end
    % Master 129 remains an independent six-DOF node.
    verifyTrue(testCase,all(info.fullToReduced(model.dofs.node(1,:))>0));
end

function testSpatialMassOffset(testCase)
    b=struct("mass",10,"cgOffsetBody",[0;2;0],"inertiaBody",diag([3 4 5]),"orientationBodyToGlobal",eye(3));
    [M,d]=rigid.rigid_body_mass_matrix(b);
    verifyLessThan(testCase,norm(M-M.',"fro"),1e-13);
    verifyGreaterThan(testCase,min(eig(M)),0);
    verifyEqual(testCase,d.cgOffsetGlobal,[0;2;0]);
    verifyNotEqual(testCase,M(1,6),0);
end

function testAddAndReduce(testCase)
    model=constraintModel();M=sparse(30,30);K=speye(30);
    bodies.bodies=struct("name","hub","masterNode",130,"mass",10, ...
        "cgOffsetBody",zeros(3,1),"inertiaBody",eye(3),"orientationBodyToGlobal",eye(3));
    bodies.constraints=struct("masterNode",130,"slaveNodes",[21;57;93]);
    [Madded,report]=rigid.add_body_masses(M,model,bodies);
    verifyEqual(testCase,report.mass,10);verifyEqual(testCase,full(Madded(model.dofs.node(2,1),model.dofs.node(2,1))),10);
    Tc=rigid.rigid_constraint_matrix(model,bodies,struct());reduced=rigid.reduce_system(Tc,Madded,K,model,struct());
    verifyEqual(testCase,size(reduced.M,1),12);verifyTrue(testCase,issparse(reduced.M));
end

function testMassPropertiesArePreservedByConstraint(testCase)
    model=constraintModel();M=sparse(30,30);
    for node=1:5,M(model.dofs.node(node,1:3),model.dofs.node(node,1:3))=2*speye(3);end
    bodies.constraints=struct("masterNode",130,"slaveNodes",[21;57;93]);
    Tc=rigid.rigid_constraint_matrix(model,bodies,struct());
    p=rigid.compute_mass_properties(model,M,Tc);
    verifyEqual(testCase,p.totalMassKg,10,'AbsTol',1e-14);
    verifyLessThan(testCase,p.constraintConservationError,1e-14);
    verifyLessThan(testCase,p.constraintCompatibilityError,1e-14);
end

function model=constraintModel()
    ids=[129;130;21;57;93];xyz=[-1 0 0;0 0 0;0 2 0;0 -1 1;0 -1 -1];
    model.mesh.nodes=struct("id",ids,"xyz",xyz);model.mesh.elements=struct("nodeI",[],"nodeJ",[]);
    model.dofs.node=reshape(1:30,6,5).';model.dofs.number=30;model.dofs.fixed=zeros(0,1);
end
