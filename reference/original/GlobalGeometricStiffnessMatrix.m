function [ KG, element ] = GlobalGeometricStiffnessMatrix( ndof, element )

kGe = zeros( 12, 12 );
KGe = zeros( 12, 12 );

KG = zeros( ndof, ndof );

nel = size( element, 2 );

for e = 1:nel
    
     % ----- Element Local Geometric Stiffness Matrix [kGe] -----
   
      [ kGe ] = ElementLocalGeometricStiffnessMatrix( element( e ) );
    
      element( e ).kGe = kGe;
       
    % ----- Rotation Matrix -----     
                  
      Ce = element( e ).Ce;
            
    % ----- Element Global Geometric Stiffness Matrix [KGe] ----- 
    
      C = kron( eye(4), Ce );  
  
      KGe = transpose( C ) * kGe * C;
     
      element( e ).KGe = KGe;
  
    % ----- Assemble Global Geometric Stiffness Matrix [KG] -----   
    
      for a = 1:12
      
          A = element( e ).dof( a );
      
          for b = 1:12
          
              B = element( e ).dof( b );
          
              KG( A, B ) = KG( A, B ) + KGe( a, b );
                
          end
      
      end
  
end

%fprintf( '  Number of Nonzero Elements: %g\n\n', NNZ );
