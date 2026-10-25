function [ ke ] = ElementLocalElasticStiffnessMatrix( element )

   ke = zeros( 12, 12 );
   
   ke_11 = zeros( 6, 6 );
   ke_12 = zeros( 6, 6 );
   ke_21 = zeros( 6, 6 );
   ke_22 = zeros( 6, 6 );
   
    EA  = element.E * element.A ;
    EI2 = element.E * element.I2;
    EI3 = element.E * element.I3;
    GJ  = element.G * element.JJ;
    he  = element.he;
    
    K1 = EA/he;
    
    K2 = 12*EI3/he^3;
    K3 = 6*EI3/he^2;
    K4 = 4*EI3/he;
    
    K5 = 12*EI2/he^3;
    K6 = 6*EI2/he^2;
    K7 = 4*EI2/he;
    
    K8 = GJ/he; 
    
    ke_11 = [  K1    0    0    0    0    0;
                0   K2    0    0    0   K3;
                0    0   K5    0  -K6    0;
                0    0    0   K8    0    0;
                0    0  -K6    0   K7    0;
                0   K3    0    0    0   K4  ];
            
    ke_22 = [  K1    0    0    0    0    0;
                0   K2    0    0    0  -K3;
                0    0   K5    0   K6    0;
                0    0    0   K8    0    0;
                0    0   K6    0   K7    0;
                0  -K3    0    0    0   K4  ];
            
    ke_12 = [ -K1    0    0    0     0     0;
                0  -K2    0    0     0    K3;
                0    0  -K5    0   -K6     0;
                0    0    0  -K8     0     0;
                0    0   K6    0   K7/2    0;
                0  -K3    0    0     0   K4/2  ];
            
    ke_21 = transpose( ke_12 );
    
    ke = [ ke_11  ke_12;
           ke_21  ke_22 ];
                     

         