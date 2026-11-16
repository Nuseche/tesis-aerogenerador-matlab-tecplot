function [ ID, neq, nspv ] = DestinationArrayID( nnp, A )

ID = zeros( 6, nnp );

for k = 1:nnp
    
    j = A( k, 1 );
    
    ID( 1:6, j ) = A( k, 5:10 );

end

nspv = nnz( ID );

k = 0;

for j = 1:nnp

    for i = 1:6
    
      if ID( i, j ) == 1
    
         ID( i, j ) = 0;
         
      else
    
         k = k + 1;
          
         ID( i, j ) = k;
             
      end
    
   end

end

neq = k;

for j = 1:nnp

    for i = 1:6
    
      if ID( i, j ) == 0
    
         k = k + 1;
          
         ID( i, j ) = k;
             
      end
    
   end

end

fprintf( '  Number of Equations:                    %g\n', neq );

