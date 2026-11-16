function [ material, nmat ] = MaterialProperties( fid )

nmat = fscanf( fid, '%d', 1 );

fprintf( '  Number of Materials:                    %g\n', nmat );

A = fscanf( fid, '%d %g %g %g', [ 4  nmat ] );

A = transpose( A );

for k = 1:nmat

    n   = A( k, 1 );
    E   = A( k, 2 );                 
    nu  = A( k, 3 );
    rho = A( k, 4 );                 
          
    G   = E / ( 2 * ( 1 + nu ) );
    
    material( n ).number = n;
    material( n ).E      = E; 
    material( n ).G      = G;
    material( n ).nu     = nu;
    material( n ).rho    = rho;     
        
end