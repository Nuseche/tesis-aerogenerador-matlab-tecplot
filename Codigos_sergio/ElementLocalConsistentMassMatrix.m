function [ me ] = ElementLocalConsistentMassMatrix( element )

   me = zeros( 12, 12 );
   
   me_11 = zeros( 6, 6 );
   me_12 = zeros( 6, 6 );
   me_21 = zeros( 6, 6 );
   me_22 = zeros( 6, 6 );
   
   rhoA  = element.rho * element.A;
   rhoIp = element.rho * element.Ip;
   he = element.he;
    
   M1 =   13/35 * rhoA * he;
   M2 =  11/210 * rhoA * he^2;
   M3 =    9/70 * rhoA * he;
   M4 =  13/420 * rhoA * he^2;
   
   M5 =   1/105 * rhoA * he^3;
   M6 =   1/140 * rhoA * he^3;
   
   M7 = 1/3 * rhoA * he;
   M8 = 1/3 * rhoIp * he;
    
   me_11 = [  M7    0    0    0    0    0;
               0   M1    0    0    0   M2;
               0    0   M1    0  -M2    0;
               0    0    0   M8    0    0;
               0    0  -M2    0   M5    0;
               0   M2    0    0    0   M5 ];
          
   me_22 = [  M7    0    0    0    0    0;
               0   M1    0    0    0  -M2;
               0    0   M1    0   M2    0;
               0    0    0   M8    0    0;
               0    0   M2    0   M5    0;
               0  -M2    0    0    0   M5 ];
          
   me_12 = [  M7/2   0    0     0     0    0;
               0    M3    0     0     0  -M4;
               0     0   M3     0    M4    0;
               0     0    0   M8/2    0    0;
               0     0  -M4     0   -M6    0;
               0    M4    0     0     0  -M6 ];
           
   me_21 = transpose( me_12 );
   
   me = [ me_11  me_12;
          me_21  me_22 ];
          
          
          
          
          