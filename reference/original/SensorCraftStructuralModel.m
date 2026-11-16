%      Program SensorCraftStructuralModel.m
%      Version 3.0
%      Does not include Rigid Links
%      University of Maryland at College Park
%      December 29, 2015
%      by Sergio Preidikman

clc;
clear all;
close all;

ti = cputime;

ProgramName = 'SensorCraftStructuralModel.m (Version 3.0)';

% -------------------- Input/Output Files --------------------

InputFileName  = 'FEMESH.DAT';
%InputFileName  = 'GERADIN.DAT';

k = strfind( InputFileName, '.' );
OutputFileName = strcat( InputFileName(1:k), 'OUT' );

InputFileID  = fopen(  InputFileName, 'r' );
OutputFileID = fopen( OutputFileName, 'w' );

% ------------------------ Nodal Data ------------------------
%
% nnp = number of nodal points

nnp = fscanf( InputFileID, '%d', 1 );                       

fprintf( '************************************************\n\n' );
fprintf( '  G E N E R A L   D A T A\n\n' );   
fprintf( '  Number of Nodes:                        %g\n', nnp );

A = fscanf( InputFileID, '%d %g %g %g %d %d %d %d %d %d', [ 10 nnp ] );

A = transpose( A );

for k = 1:nnp
   
    n = A( k, 1 ); 
    
    node( n ).number   = n;
    node( n ).X        = A( k, 2 );
    node( n ).Y        = A( k, 3 );
    node( n ).Z        = A( k, 4 );
    node( n ).SPV(1:6) = A( k, 5:10 ); % SPV = Specified Primary Variables (0, unspecified; 1, specified)

end

%NSPV

% ---------- DATA PROCESSING ARRAYS: ID, IEN, and LM ---------- 
%
% ID  = Destination array 
% IEN = Element nodes array
% LM  = Location matrix
% neq = Number of equations
% nspv = Number of specified PRIMARY variables

[ ID, neq, nspv ] = DestinationArrayID( nnp, A );

for k = 1:nnp

    node( k ).dof = ID( 1:6, k );
    
end

% ---------- Material Properties ----------
%
% nmat = number of materials

[ material, nmat ] = MaterialProperties( InputFileID );

% ---------- Section Properties ----------
%
% nsec = number of sections

[ section, nsec ] = SectionProperties( InputFileID );

% ---------- Element Data ----------
%
% nen = number of element nodes
% nel = number of elements

nen = 2;                                        % 2-node Beam Elements

nel = fscanf( InputFileID, '%d', 1 );

fprintf( '  Number of Elements:                     %g\n', nel );

A = fscanf( InputFileID, '%d %d %d %d %d %d', [ 6 nel ] );

A = transpose( A );

for k = 1:nel

    n = A( k, 1 );

    element( n ).number         = n;
    element( n ).I              = A( k, 2 );
    element( n ).J              = A( k, 3 );
    element( n ).K              = A( k, 4 );
    element( n ).MaterialNumber = A( k, 5 );
    element( n ).SectionNumber  = A( k, 6 );
    
    element( n ).Ne             = 1;             % Ne = 1 for now

    IEN( 1:2, n ) = A( k, 2:3 );                 % IEN = Element nodes array  
    
end

fprintf( '  Number of Active Nodes:                 %g\n', max(max(IEN)) );

% ---------- DATA PROCESSING ARRAYS: ID, IEN, and LM ---------- 
% 
% LM  = Location matrix
%

[ LM, ndof ] = LocationMatrixLM( nen, nel, ID, IEN );

for e = 1:nel

    element( e ).dof = LM( 1:12, e );

end

fprintf( '  Number of Degrees of Freedom:           %g\n', ndof );

% ---------- Load Data ----------
%
% nload = number of concentrated loads applied in this load case 

nload = fscanf( InputFileID, '%d', 1 );

fprintf( '  Number of concentrated loads:           %g\n', nload );
fprintf( '\n' );
fprintf( '************************************************\n\n' );

A = fscanf( InputFileID, '%d %g %g %g %g %g %g', [ 7  nload ] );

A = transpose( A );

for k = 1:nload

    load( k ).node   = A( k, 1 );
    load( k ).F(1:3) = A( k, 2:4 );
    load( k ).M(1:3) = A( k, 5:7 );
        
end

status = fclose( InputFileID );

% ---------- Generate Element Properties ----------

fprintf( '  Generating Element Properties ... \n\n' );

[ element ] = ElementProperties( material, section, node, element );

% ---------- Global Elastic Stiffness Matrix ----------

fprintf( '  Assembling Structure Elastic Stiffness Matrix ... \n' ); 

[ KE, element ] = GlobalElasticStiffnessMatrix( ndof, element );

KE11 = KE(     1:neq ,      1:neq  );
KE12 = KE(     1:neq ,  neq+1:ndof );
KE21 = KE( neq+1:ndof,      1:neq  );
KE22 = KE( neq+1:ndof,  neq+1:ndof );

% ---------- Global Mass Matrix ----------

fprintf( '  Assembling Structure Consistent Mass Matrix ... \n' ); 

[ M, element ] = GlobalConsistentMassMatrix( ndof, element );

M11 = M(     1:neq ,      1:neq  );
M12 = M(     1:neq ,  neq+1:ndof );
M21 = M( neq+1:ndof,      1:neq  );
M22 = M( neq+1:ndof,  neq+1:ndof );

% ---------- Global Geometric Stiffness Matrix ----------

fprintf( '  Assembling Structure Geometric Stiffness Matrix ... \n' ); 

[ KG, element ] = GlobalGeometricStiffnessMatrix( ndof, element );

KG11 = KG(     1:neq ,      1:neq  );
KG12 = KG(     1:neq ,  neq+1:ndof );
KG21 = KG( neq+1:ndof,      1:neq  );
KG22 = KG( neq+1:ndof,  neq+1:ndof );

% ---------- Global Load Vector ----------

fprintf( '  Assembling Global Load Vector ... \n' );

% Calculate and store load vector 

  [ F ] = GlobalLoadVector( ndof, ID, load );

  F1 = F(    1:neq );
  F2 = F(neq+1:ndof);

% ---------- Static Problem ----------

fprintf( '  Solving the Static Problem ... \n\n' );



  U1 = KE11\F1;                      % Calculate nodal point displacements
  U2 = zeros( ndof-neq, 1 );

  U = [ U1; U2 ];
  
  F2 = KE21 * U1;                    % Calculate restraint forces (reactions)
  
for k = 1:max(max(IEN))

   node( k ).U = U( node( k ).dof  );
    
end

for e = 1:nel
    
    element(e).Ue = U( element(e).dof );
    
    element(e).ue = kron( eye(4), element(e).Ce ) * element(e).Ue; 
    
    element(e).fe = element(e).kEe * element(e).ue;
    
end




% Calculate element stresses 





% ---------- Generalized Eigenvalue Problem ----------

fprintf( '  Solving Generalized Eigenvalue Problem ... \n\n' );

opts.disp = 0;      % Diagnostic information display level. [ 0 | {1} | 2 ]

% Critical Loads

nmodes = 2;         %Number of Buckling Modes

%[ V, D ] = eigs( KE11, KG11, nmodes, 0, opts ); 

%[ V, D ] = eigs( KE11, KG11 ); 

%D = diag( D );

%[ D, I ] = sort( D );

%V = V( :, I );

% Natural Frequencies

nmodes = 20;         %Number of Vibration Modes

[ V, D ] = eigs( KE11, M11, nmodes, 0, opts ); 

%D = sqrt( diag( D ) );

D = diag(D);

[ D, I ] = sort( D );

V = V( :, I );

Eigenvalue = D;
CircularFrequency = sqrt( D );
Frequency = CircularFrequency/(2*pi);
GeneralizedMass = diag( transpose( V ) * M11 * V );

fprintf( '\n\n' ); 
fprintf( '  E I G E N V A L U E    O U T P U T\n\n' );     
fprintf( '  MODE NO      EIGENVALUE            FREQUENCY         GENERALIZED MASS   COMPOSITE MODAL DAMPING\n' );            
fprintf( '                             (RAD/TIME)   (CYCLES/TIME)\n' );

for k = 1:nmodes
  
    fprintf( '%7u %15.5f %14.5f %13.5f %14.5f \n', ...
              k, ...
              Eigenvalue(k), ...
              CircularFrequency(k), ...
              Frequency(k), ...
              GeneralizedMass(k) );
    
end

fprintf( '\n\n' );     

%[ V, D ] = eig( KE11, M11 );

% -------------------- Print Results to OutputFileName --------------------

PrintData( OutputFileID, InputFileName, OutputFileName, ProgramName, ...
           nnp, nen, nel, nmat, nsec, nload, neq, nspv, ...
           ID, IEN, LM, ...
           node, element, material, section, load );

status = fclose( OutputFileID );

tf = cputime;

e = tf - ti;

fprintf( '************************************************\n' );
fprintf( '  Elapsed CPU time (in seconds):         %g\n', e );
fprintf( '************************************************\n' );

