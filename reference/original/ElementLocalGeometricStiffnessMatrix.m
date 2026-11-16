function [ kGe ] = ElementLocalGeometricStiffnessMatrix( element )

   kGe = zeros( 12, 12 );
   
   he = element.he;
   Ne = element.Ne;
    
    K1 = 6/5;
    K2 = he/10;
    K3 = 2*he^2/15;
    K4 = he^2/30;
         
   kGe(  2,  2 ) =  K1; 
   kGe(  2,  6 ) =  K2;
   kGe(  2,  8 ) = -K1;
   kGe(  2, 12 ) =  K2;
   
   kGe(  3,  3 ) =  K1;
   kGe(  3,  5 ) = -K2;
   kGe(  3,  9 ) = -K1;
   kGe(  3, 11 ) = -K2;
   
   kGe(  5,  3 ) = -K2;
   kGe(  5,  5 ) =  K3;
   kGe(  5,  9 ) =  K2;
   kGe(  5, 11 ) = -K4;
   
   kGe(  6,  2 ) =  K2;
   kGe(  6,  6 ) =  K3;
   kGe(  6,  8 ) = -K2;
   kGe(  6, 12 ) = -K4;
   
   kGe(  8,  2 ) = -K1; 
   kGe(  8,  6 ) = -K2;
   kGe(  8,  8 ) =  K1;
   kGe(  8, 12 ) = -K2;
   
   kGe(  9,  3 ) = -K1;
   kGe(  9,  5 ) =  K2;
   kGe(  9,  9 ) =  K1;
   kGe(  9, 11 ) =  K2;
   
   kGe( 11,  3 ) = -K2;
   kGe( 11,  5 ) = -K4;
   kGe( 11,  9 ) =  K2;
   kGe( 11, 11 ) =  K3;
   
   kGe( 12,  2 ) =  K2;
   kGe( 12,  6 ) = -K4;
   kGe( 12,  8 ) = -K2;
   kGe( 12, 12 ) =  K3;
   
   kGe = (Ne/he) * kGe;
   
   
   
   
   
                        

         