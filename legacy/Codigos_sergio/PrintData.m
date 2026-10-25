function PrintData( fid, InputFileName, OutputFileName, ProgramName, ...
                    nnp, nen, nel, nmat, nsec, nload, neq, nspv, ...
                    ID, IEN, LM, ...
                    node, element, material, section, load )

% nnp   = number of nodal points (Number of Nodes in the Mesh)
% nen   = number of element nodes (Number of Nodes per Element)
% nel   = number of elements (Number of Elements in the Mesh)
% ndf   = Number of Primary DOF per Node
% nmat  = number of materials
% nsec  = number of sections
% nload = number of concentrated loads applied in this load case 
% ID    = destination array 
% IEN   = element nodes array
% LM    = location matrix
% SPV   = Specified Primary Variables (0, unspecified; 1, specified)

% 
% 
% Element type: 


ndf = 6;

fprintf( fid, [ '  OUTPUT FROM PROGRAM  *' ProgramName '*  by Sergio Preidikman\n\n\n' ] );

fprintf( fid, [ '   INPUT FILE NAME:  ' InputFileName  '\n' ] );   
fprintf( fid, [ '  OUTPUT FILE NAME:  ' OutputFileName '\n\n\n' ] );   


fprintf( fid, '  F I N I T E   E L E M E N T   M E S H   I N F O R M A T I O N:\n\n' );   
fprintf( fid, '  Number of Nodes in the Mesh:            %5u\n', nnp   );
fprintf( fid, '  Number of Elements in the Mesh:         %5u\n', nel   );
fprintf( fid, '  Number of Nodes per Element:            %5u\n', nen   );
fprintf( fid, '  Number of Primary DOF per Node:         %5u\n', ndf   );
fprintf( fid, '  Number of Equations to be Solved:       %5u\n', neq   );
fprintf( fid, '  Number of Specified Primary Variables:  %5u\n', nspv  );
fprintf( fid, '  Number of Materials:                    %5u\n', nmat  );
fprintf( fid, '  Number of Sections:                     %5u\n', nsec  );
fprintf( fid, '  Number of Concentrated Loads:           %5u\n', nload );
fprintf( fid, '\n\n\n' );

fprintf( fid, '  Node      Global Coordinates of the Nodes       Specification of primary variables         Global Degrees of Freedom\n' );
fprintf( fid, '   ID      X-coord.     Y-coord.     Z-coord.       (0, unspecified; 1, specified)        1     2     3     4     5     6\n\n' );

for k = 1:nnp
   
    fprintf( fid, ...
             '%5u %12.4f %12.4f %12.4f %7u %5u %5u %5u %5u %5u %8u %5u %5u %5u %5u %5u \n', ...
             node(k).number, ...
             node(k).X, ...
             node(k).Y, ...
             node(k).Z, ...
             node(k).SPV(1:6), ...
             node(k).dof(1:6) );
    
end

fprintf( fid, '\n\n' );

fprintf( fid, '  D I S P L A C E M E N T   D E G R E E S   O F   F R E E D O M\n\n' );
fprintf( fid, '          (A) = Active DOF, equilibrium equation\n' ); 
fprintf( fid, '          (-) = Restrained DOF, reaction computed\n' );
fprintf( fid, '          (+) = Constrained DOF\n' );
fprintf( fid, '          ( ) = Null DOF\n\n' );
fprintf( fid, '  Node        DISPLACEMENT DOF\n' );
fprintf( fid, '   ID      UX  UY  UZ  RX  RY  RZ\n' );

for k = 1:nnp
   
    for i = 1:6
       
      switch node(k).SPV(i)
          
          case 0
          
             temp(i) = 'A';
          
          case 1
              
             temp(i) = '-';
          
          otherwise
              
            disp('Unknown displacement dof.')
        
      end
              
    end
    
    fprintf( fid, ...
             '%5u %7s %3s %3s %3s %3s %3s \n', ...
             node(k).number, ...
             temp(1), temp(2), temp(3), temp(4), temp(5), temp(6) );
    
end

fprintf( fid, '\n\n' );

fprintf( fid, '  A P P L I E D   L O A D S\n\n' );
fprintf( fid, '  FORCES AND MOMENTS ACTING ON NODES, IN GLOBAL COORDINATES\n\n' );
fprintf( fid, '  Node                          Force(s)                      and                      Moment(s)\n' );
fprintf( fid, '   ID             FX               FY               FZ                   MX               MY               MZ\n' ); 

for k = 1:nload

    fprintf( fid, ...
             '%5u %14.3f %16.3f %16.3f %20.3f %16.3f %16.3f\n', ...
             load( k ).node, ...
             load( k ).F(1:3), ...
             load( k ).M(1:3) );
        
end






% -------------------------------------------------------------------------

fprintf( fid, '\n\n' );

fprintf( fid, 'S O L U T I O N:\n\n\n' );

fprintf( fid, '  N O D A L   D I S P L A C E M E N T S\n\n' );
fprintf( fid, '  TRANSLATIONS AND ROTATIONS, IN GLOBAL COORDINATES\n\n' );

fprintf( fid, '  Node                          Displacement(s)                  and                     Rotation(s) \n' ); 
fprintf( fid, '   ID                UX               UY               UZ                   RX               RY               RZ\n' ); 

for k = 1:max(max(IEN))

    fprintf( fid, ...
             '%5u %17.5e %16.5e %16.5e %20.5e %16.5e %16.5e \n', ...
             k, ...
             node(k).U(1:6) );
    
end

fprintf( fid, '\n\n' );


fprintf( fid, '  R E S T R A I N T   F O R C E S    ( R E A C T I O N S )\n\n' );
fprintf( fid, '  FORCES AND MOMENTS ACTING ON NODES, IN GLOBAL COORDINATES\n\n' );
fprintf( fid, '  Node                          Force(s)                      and                      Moment(s)\n' );
fprintf( fid, '   ID             FX               FY               FZ                   MX               MY               MZ\n' ); 

fprintf( fid, '\n\n' );

% -------------------------------------------------------------------------

fprintf( fid, 'D A T A   P R O C E S S I N G   A R R A Y S:\n\n\n' );
 
fprintf( fid, '  ID array:\n\n' );   

fprintf( fid, '  Global Node       Global Degrees of Freedom \n' );
fprintf( fid, '   Numbers       1     2     3     4     5     6 \n\n' );

for k = 1:nnp
    
    fprintf( fid, ...
             '%7u %10u %5u %5u %5u %5u %5u \n', ...
             k, ...
             ID( 1:6, k ) );
         
end

fprintf( fid, '\n\n' );
 
fprintf( fid, '  IEN array:\n\n' );   

fprintf( fid, '  Element     Local Node Numbers \n' );
fprintf( fid, '  Numbers         1       2 \n\n' );

for k = 1:nel
    
    fprintf( fid, ...
             '%7u %11u %7u \n', ...
             k, ...
             IEN( 1:2, k ) );
         
end

fprintf( fid, '\n\n' );
 
fprintf( fid, '  LM array:\n\n' ); 

fprintf( fid, '  Element        1     2     3     4     5     6        7     8     9    10    11    12  (Local equation numbers)\n' );
fprintf( fid, '  Numbers                       1                                      2                 (Local node numbers)\n\n' );

for k = 1:nel
    
    fprintf( fid, ...
             '%7u %10u %5u %5u %5u %5u %5u %8u %5u %5u %5u %5u %5u \n', ..., ...
             k, ...
             LM( 1:12, k ) );
         
end

fprintf( fid, 'Element    Bend-Moment   End-A    Bend-Moment   End-B           Shear              Axial \n' );
fprintf( fid, '  ID       Plane 1     Plane 2    Plane 1     Plane 2    Plane 1     Plane 2       Force       Torque \n' );

%-	Poisson's ratio of the material#
%-	Young's modulus of the material
%-	Length of the element
%-	Cross-ectional area of the element
%-	Moment of inertia of the element
% G = Shear Modulus
% Point force at point other than nodes
% Cross-Section Properties
% element internal forces and moments
% Orientation for Bar and Beam elements
% Display of element cross section

%Element coefficient matrix: ',/) 620 FORMAT (/,5X,'Element mass matrix: ',/) 
%630 FORMAT (/,5X,'Element source vector:',/) 
%640 FORMAT (/,5X,'Global coefficient matrix:',/) 650 FORMAT (/,SX,'Global source vector:',/) 
%660 FORMAT (/,SX,'S O LU TI O N :',/) 

%Node x-coord. y-coord. deflec. w' x-rotation y-rotation
%Connectivity Matrix, [NOD]

