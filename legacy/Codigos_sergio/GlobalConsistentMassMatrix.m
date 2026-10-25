function [ M, element ] = GlobalConsistentMassMatrix( ndof, element )

me = zeros( 12, 12 );
Me = zeros( 12, 12 );

M = zeros( ndof, ndof );

nel = size( element, 2 );

for e = 1:nel

    % ----- Element Local Consistent Mass Matrix [me] -----
    
      [ me ] = ElementLocalConsistentMassMatrix( element(e) );
    
      element( e ).me = me;
          
    % ----- Rotation Matrix [Ce] -----     
                  
      Ce = element( e ).Ce;
            
    % ----- Element Global Consistent Mass Matrix [Me] -----
    
      C = kron( eye(4), Ce );  
  
      Me = transpose( C ) * me * C;
     
      element( e ).Me = Me;
  
    % ----- Assemble Global Consistent Mass Matrix [M] -----   
    
      for a = 1:12
      
          A = element( e ).dof( a );
      
          for b = 1:12
          
              B = element( e ).dof( b );
          
              M( A, B ) = M( A, B ) + Me( a, b );
                
          end
      
      end
  
end
