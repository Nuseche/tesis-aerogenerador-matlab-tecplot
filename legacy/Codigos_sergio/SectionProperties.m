function [ section, nsec ] = SectionProperties( fid )

nsec = fscanf( fid, '%d', 1 );

fprintf( '  Number of Sections:                     %g\n', nsec );

A = fscanf( fid, '%d %g %g %g %g %g', [ 6  nsec ] );

A = transpose( A );

for k = 1:nsec
    
    n   = A( k, 1 );
    
    section( n ).number = n;
    section( n ).A      = A( k, 2 );
    section( n ).I2     = A( k, 3 );
    section( n ).I3     = A( k, 4 );
    section( n ).J      = A( k, 5 );  
    section( n ).Ip     = A( k, 6 );
     
end
