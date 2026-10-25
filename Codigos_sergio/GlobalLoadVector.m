function [ F ] = GlobalLoadVector( ndof, ID, load )

F = zeros( ndof, 1 );     % Global Load Vector

nload = length( load );

for k = 1:nload

    n  = load(k).node;
    Fn = load(k).F;
    Mn = load(k).M;
    
    index = transpose( ID( 1:6, n ) );   
    
    F( index ) = F( index ) + transpose( [ Fn Mn ] );
      
end