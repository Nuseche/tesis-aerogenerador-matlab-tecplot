function [ element ] = ElementProperties( material, section, node, element )

nel = size( element, 2 );

for e = 1:nel
       
   mnum = element( e ).MaterialNumber;
      
       E   = material( mnum ).E;
       G   = material( mnum ).G;
       rho = material( mnum ).rho;
   
      element( e ).E    = E;
      element( e ).G    = G;
      element( e ).rho = rho;
       
   snum = element( e ).SectionNumber;
   
      A   = section( snum ).A;
      I2  = section( snum ).I2;
      I3  = section( snum ).I3;
      J   = section( snum ).J;
      Ip  = section( snum ).Ip;
        
      element( e ).A  = A;
      element( e ).I2 = I2;
      element( e ).I3 = I3;
      element( e ).JJ = J;
      element( e ).Ip = Ip;
   
      % element( k ).P0   = P0;
            
      RI = [ node( element( e ).I ).X; ...
             node( element( e ).I ).Y; ...
             node( element( e ).I ).Z ];
      
      RJ = [ node( element( e ).J ).X; ... 
             node( element( e ).J ).Y; ...
             node( element( e ).J ).Z ]; 
                  
      RK = [ node( element( e ).K ).X; ...
             node( element( e ).K ).Y; ... 
             node( element( e ).K ).Z ]; 
       
      l_1 =  RJ - RI;
      
      he = norm( l_1, 2 );
   
      l_1 = l_1 / he;
   
      l_3 = RK - RI;
      
      l_2 = cross( l_3, l_1 );
      
      l_2 = l_2 / norm( l_2 );
      
      l_3 = cross( l_1, l_2 );   
      
      Ce = transpose( [ l_1 l_2 l_3 ] );
           
      element( e ).he = he;
      element( e ).Ce = Ce;
   
end