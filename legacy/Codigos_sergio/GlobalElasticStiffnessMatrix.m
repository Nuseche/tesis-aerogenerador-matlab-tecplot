function [ KE, element ] = GlobalElasticStiffnessMatrix( ndof, element )

kEe = zeros( 12, 12 );     % Element Elastic Stiffness Matrix (Local)
KEe = zeros( 12, 12 );     % Element Elastic Stiffness Matrix (Global)

KE = zeros( ndof, ndof );

nel = size( element, 2 );

for e = 1:nel

    % ----- Element Local Elastic Stiffness Matrix [kEe] -----
    
      kEe = ElementLocalElasticStiffnessMatrix( element( e ) );
      
      element( e ).kEe = kEe;
    
    % ----- Rotation Matrix -----     
                  
      Ce = element( e ).Ce;
                        
    % ----- Element Global Elastic Stiffness Matrix [KEe] -----
   
      C = kron( eye(4), Ce );  
  
      KEe = transpose( C ) * kEe * C;
     
      element( e ).KEe = KEe;
   
    % ----- Assemble Global Elastic Stiffness Matrix [KE] -----
    
      for a = 1:12
      
          A = element( e ).dof( a );
      
          for b = 1:12
          
              B = element( e ).dof( b );
           
              KE( A, B ) = KE( A, B ) + KEe( a, b );
        
          end
      
      end
  
end
