function suite = run_rigid_body_mass_suite(modelData,Mdistributed,M,Ke,Tc, ...
    reduced,constraintInfo,bodyReport,massProperties,cfg)
%RUN_RIGID_BODY_MASS_SUITE Specialized acceptance checks for Action 04.

arguments
    modelData (1,1) struct
    Mdistributed
    M
    Ke
    Tc
    reduced (1,1) struct
    constraintInfo (1,1) struct
    bodyReport struct
    massProperties (1,1) struct
    cfg (1,1) struct
end

tol = localCfg(cfg,{'validation','massConservationTolerance'},1e-10);
symTol = localCfg(cfg,{'validation','matrixSymmetry'},1e-12);
checks = repmat(localCheck("",true,0,0,"",false),0,1);
bodies = modelData.rigidBodies.bodies(:);

checks(end+1,1)=localCheck("bodies.count",numel(bodies)==2,numel(bodies),2, ...
    "The traced dataset contains nacelle and hub.",true);
checks(end+1,1)=localCheck("bodies.masterNodes", ...
    isequal([bodies.masterNode].',[129;130]),numel(unique([bodies.masterNode])),2, ...
    "Bodies are added once at distinct masters 129 and 130.",true);
expectedBodyMass=1.1845e6+1.9600e5;
bodyMass=sum([bodies.mass]);
checks(end+1,1)=localCheck("bodies.massSum",bodyMass==expectedBodyMass, ...
    bodyMass,expectedBodyMass,"Version 0 concentrated-body mass.",true);
checks(end+1,1)=localCheck("bodies.datasetVersion", ...
    all(string({bodies.dataVersion})=="legacy_rigid_bodies_v0"), ...
    nnz(string({bodies.dataVersion})=="legacy_rigid_bodies_v0"),2, ...
    "Every body identifies the versioned source artifact.",true);

angleUnit=string(bodies(1).orientationAngleUnit);
anglesInput=double(bodies(1).orientationAnglesInput);
anglesRad=double(bodies(1).orientationAnglesRad);
checks(end+1,1)=localCheck("orientation.explicitDegreeInput", ...
    angleUnit=="deg",double(angleUnit~="deg"),0, ...
    "Inherited angle values carry an explicit degree unit.",true);
conversionError=norm(anglesRad-deg2rad(anglesInput),inf);
checks(end+1,1)=localCheck("orientation.degreeToRadianConversion", ...
    conversionError<=symTol,conversionError,symTol, ...
    "Internal angles equal deg2rad(input), never raw numeric values.",true);
R=bodies(1).orientationBodyToGlobal;
orthogonality=norm(R*R.'-eye(3),'fro');
checks(end+1,1)=localCheck("orientation.orthogonality", ...
    orthogonality<=symTol,orthogonality,symTol,"R*R'=I.",true);
checks(end+1,1)=localCheck("orientation.rightHanded", ...
    abs(det(R)-1)<=symTol,abs(det(R)-1),symTol,"det(R)=1.",true);
rawR=localPassiveZXZ(anglesInput);
rawRadiansDistance=norm(R-rawR,'fro');
checks(end+1,1)=localCheck("orientation.notRawDegreesAsRadians", ...
    rawRadiansDistance>1e-3,rawRadiansDistance,1e-3, ...
    "Corrected rotation is distinguishable from the legacy unit error.",true);

minimumSpatialEigenvalue=inf(numel(bodies),1);
triangleResidual=zeros(numel(bodies),1);
couplingNorm=zeros(numel(bodies),1);
for bodyIndex=1:numel(bodies)
    [MR,details]=rigid.rigid_body_mass_matrix(bodies(bodyIndex));
    label="body."+string(bodies(bodyIndex).name);
    finite=all(isfinite(MR),'all');
    checks(end+1,1)=localCheck(label+".finite",finite,double(~finite),0, ...
        "Spatial mass coefficients are finite.",true); %#ok<AGROW>
    symmetry=norm(MR-MR.','fro')/max(norm(MR,'fro'),eps);
    checks(end+1,1)=localCheck(label+".symmetry",symmetry<=symTol, ...
        symmetry,symTol,"Spatial mass is symmetric.",true); %#ok<AGROW>
    minimumSpatialEigenvalue(bodyIndex)=min(details.spatialMassEigenvalues);
    checks(end+1,1)=localCheck(label+".positive", ...
        minimumSpatialEigenvalue(bodyIndex)>0, ...
        minimumSpatialEigenvalue(bodyIndex),0, ...
        "Current body data produce a positive-definite spatial mass.",true); %#ok<AGROW>
    triangleResidual(bodyIndex)=details.inertiaTriangleResidual;
    checks(end+1,1)=localCheck(label+".inertiaTriangle", ...
        triangleResidual(bodyIndex)<=details.inertiaTriangleTolerance, ...
        triangleResidual(bodyIndex),details.inertiaTriangleTolerance, ...
        "Principal mass moments satisfy physical triangle inequalities.",true); %#ok<AGROW>
    couplingNorm(bodyIndex)=norm(MR(1:3,4:6),'fro');
end
productInertiaNorm=norm(bodyReport(1).inertiaGlobalCG- ...
    diag(diag(bodyReport(1).inertiaGlobalCG)),'fro');
checks(end+1,1)=localCheck("nacelle.rotatedProductsOfInertia", ...
    productInertiaNorm>0,productInertiaNorm,0, ...
    "The oriented anisotropic nacelle tensor retains global products.",true);

expectedDelta=sparse(size(M,1),size(M,2));
for bodyIndex=1:numel(bodyReport)
    dofs=bodyReport(bodyIndex).dofs;
    expectedDelta(dofs,dofs)=expectedDelta(dofs,dofs)+ ...
        sparse(bodyReport(bodyIndex).spatialMassMatrix);
end
deltaError=norm((M-Mdistributed)-expectedDelta,'fro')/ ...
    max(norm(expectedDelta,'fro'),1);
checks(end+1,1)=localCheck("assembly.bodyBlocksAddedOnce",deltaError<=symTol, ...
    deltaError,symTol,"M-Mdistributed equals exactly the two spatial blocks.",true);

distributedProperties=rigid.compute_mass_properties(modelData,Mdistributed,Tc);
massIncrement=massProperties.totalMassKg-distributedProperties.totalMassKg;
massIncrementError=abs(massIncrement-bodyMass)/bodyMass;
checks(end+1,1)=localCheck("assembly.noBodyMassDoubleCount", ...
    massIncrementError<=tol,massIncrementError,tol, ...
    "Global rigid-translation mass increases by the body mass exactly once.",true);
checks(end+1,1)=localCheck("mass.constraintCompatibility", ...
    massProperties.constraintCompatibilityError<=tol, ...
    massProperties.constraintCompatibilityError,tol, ...
    "Rigid velocity fields lie in the range of Tc.",true);
checks(end+1,1)=localCheck("mass.constraintConservation", ...
    massProperties.constraintConservationError<=tol, ...
    massProperties.constraintConservationError,tol, ...
    "Spatial mass properties are conserved by Tc congruence.",true);

expectedTotal=modelData.summary.approximateTotalMassKg;
totalMassError=abs(massProperties.totalMassKg-expectedTotal)/expectedTotal;
checks(end+1,1)=localCheck("mass.totalFromDistributedAndBodies", ...
    totalMassError<=tol,totalMassError,tol, ...
    "Rigid-field total mass equals distributed plus concentrated input mass.",true);
checks=[checks;localMatrixChecks(M,"full.M",symTol); ...
    localMatrixChecks(Ke,"full.Ke",symTol); ...
    localMatrixChecks(reduced.M,"reduced.M",symTol); ...
    localMatrixChecks(reduced.Ke,"reduced.Ke",symTol)]; %#ok<AGROW>
[~,massCholeskyFlag]=chol((reduced.M+reduced.M.')/2);
checks(end+1,1)=localCheck("reduced.M.positiveDefinite", ...
    massCholeskyFlag==0,massCholeskyFlag,0, ...
    "Cholesky factorization confirms a positive-definite reduced mass.",true);

z=sin((1:size(Tc,2)).'/19)+cos((1:size(Tc,2)).'/31);
energyError=localRelative(z.'*reduced.M*z,(Tc*z).'*M*(Tc*z));
checks(end+1,1)=localCheck("congruence.massEnergy",energyError<=symTol, ...
    energyError,symTol,"Mass quadratic form is conserved by Tc.",true);
checks=[checks;validation.check_rigid_constraints( ...
    Tc,modelData,modelData.rigidBodies,cfg)]; %#ok<AGROW>
checks(end+1,1)=localCheck("constraints.sameAcceptedMap", ...
    isequal(constraintInfo.slaveNodeIds,[21;57;93]), ...
    numel(constraintInfo.slaveNodeIds),3, ...
    "Action 04 reuses the accepted Action 03 constraint map.",true);

bodyTable=localBodyTable(bodies,bodyReport,minimumSpatialEigenvalue, ...
    triangleResidual,couplingNorm);
massPropertiesTable=localMassPropertiesTable(massProperties, ...
    distributedProperties,bodyMass);

suite=struct();
suite.schemaVersion="1.0.0";
suite.scope="distributed_mass_plus_spatial_nacelle_and_hub_before_Tc";
suite.checks=checks;
suite.checkTable=struct2table(checks);
suite.bodyTable=bodyTable;
suite.massPropertiesTable=massPropertiesTable;
suite.bodyReports=bodyReport;
suite.massProperties=massProperties;
suite.metrics=struct('bodyMassKg',bodyMass,'totalMassKg', ...
    massProperties.totalMassKg,'centerOfMassGlobalM', ...
    massProperties.centerOfMassGlobalM,'constraintConservationError', ...
    massProperties.constraintConservationError,'bodyAdditionError',deltaError, ...
    'massEnergyError',energyError,'rawRadiansRotationDistance',rawRadiansDistance);
suite.passed=all([checks.pass] | ~[checks.critical]);
suite.criticalFailures=checks(~[checks.pass] & [checks.critical]);
if logical(localCfg(cfg,{'validation','failOnCritical'},1)) && ~suite.passed
    names=strjoin(string({suite.criticalFailures.name}),', ');
    error('validation:run_rigid_body_mass_suite:CriticalFailure', ...
        'Action 04 critical checks failed: %s',names);
end
end

function checks=localMatrixChecks(A,label,tol)
checks=repmat(localCheck("",true,0,0,"",false),0,1);
checks(end+1,1)=localCheck(label+".sparse",issparse(A),double(~issparse(A)),0, ...
    "Matrix remains sparse.",true);
finite=all(isfinite(nonzeros(A)));
checks(end+1,1)=localCheck(label+".finite",finite,double(~finite),0, ...
    "Stored entries are finite.",true);
symmetry=norm(A-A.','fro')/max(norm(A,'fro'),eps);
checks(end+1,1)=localCheck(label+".symmetry",symmetry<=tol,symmetry,tol, ...
    "Relative Frobenius symmetry residual.",true);
end

function tableValue=localBodyTable(bodies,reports,minEigen,triangle,coupling)
name=string({bodies.name}).';
masterNode=reshape([bodies.masterNode],[],1);
massKg=reshape([bodies.mass],[],1);
cgX=zeros(numel(bodies),1);cgY=cgX;cgZ=cgX;
Jxx=cgX;Jyy=cgX;Jzz=cgX;Jxy=cgX;Jxz=cgX;Jyz=cgX;
offsetStatus=strings(numel(bodies),1);
for index=1:numel(bodies)
    r=reports(index).cgOffsetGlobal;J=reports(index).inertiaGlobalCG;
    cgX(index)=r(1);cgY(index)=r(2);cgZ(index)=r(3);
    Jxx(index)=J(1,1);Jyy(index)=J(2,2);Jzz(index)=J(3,3);
    Jxy(index)=J(1,2);Jxz(index)=J(1,3);Jyz(index)=J(2,3);
    offsetStatus(index)=string(bodies(index).offsetStatus);
end
minimumSpatialEigenvalue=minEigen;
inertiaTriangleResidual=triangle;
translationRotationCouplingNorm=coupling;
tableValue=table(name,masterNode,massKg,cgX,cgY,cgZ,Jxx,Jyy,Jzz, ...
    Jxy,Jxz,Jyz,minimumSpatialEigenvalue,inertiaTriangleResidual, ...
    translationRotationCouplingNorm,offsetStatus);
end

function tableValue=localMassPropertiesTable(total,distributed,bodyMass)
metric=["distributed_mass_kg";"body_mass_kg";"total_mass_kg"; ...
    "cg_x_m";"cg_y_m";"cg_z_m";"constraint_compatibility_error"; ...
    "constraint_conservation_error"];
value=[distributed.totalMassKg;bodyMass;total.totalMassKg; ...
    total.centerOfMassGlobalM(:);total.constraintCompatibilityError; ...
    total.constraintConservationError];
tableValue=table(metric,value);
end

function R=localPassiveZXZ(angles)
Rz1=localPassiveZ(angles(1));Rx=localPassiveX(angles(2));
Rz3=localPassiveZ(angles(3));R=Rz3*Rx*Rz1;
end

function R=localPassiveZ(angle)
R=[cos(angle) sin(angle) 0;-sin(angle) cos(angle) 0;0 0 1];
end

function R=localPassiveX(angle)
R=[1 0 0;0 cos(angle) sin(angle);0 -sin(angle) cos(angle)];
end

function value=localRelative(a,b)
value=abs(a-b)/max([abs(a),abs(b),1]);
end

function check=localCheck(name,pass,value,tolerance,message,critical)
check=struct('name',string(name),'pass',logical(pass),'value',value, ...
    'tolerance',tolerance,'message',string(message),'critical',logical(critical));
end

function value=localCfg(cfg,path,fallback)
value=fallback;cursor=cfg;
for index=1:numel(path)
    if ~isstruct(cursor)||~isfield(cursor,path{index}),return;end
    cursor=cursor.(path{index});
end
if isnumeric(cursor)&&isscalar(cursor)&&isfinite(cursor),value=double(cursor);end
end
