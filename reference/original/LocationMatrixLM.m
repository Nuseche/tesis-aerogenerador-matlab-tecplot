function [ LM, ndof ] = LocationMatrixLM( nen, nel, ID, IEN )

LM = zeros( 6*nen, nel );

for k = 1:nel

   I = IEN( 1, k );
   J = IEN( 2, k );

   LM( 1:12, k ) = [ ID( 1:6, I ) ; ID( 1:6, J ) ];

end
    
ndof = max( max( LM ) );

