%**************************************************************************
%* Interacción suelo-estructura
%* Torre eolica
%* Diego Turello. 2021
%**************************************************************************

clear all; close all; clc;

%**************************************************************************

%* Calculo de frecuencias y modos turbina con efectos de interacion
%* suelo-estructura
%**************************************************************************
% Datos
% Geometria
  GeoTorre; % coor y conect de la torre y palas
  YOUNG =  2.100e+11 ; %/ Módulo de young
  POISS =  3.000e-01 ; %/ módulo de poisson
  DENS  =  7.850e+03 ; %! densidad
% Secciones torre y pala
  Secciones;
% TORRE: AREA   SHEAR2   SHEAR3     TORINE   INERT2   INERT3
% PALA: EA GAY GAZ GJ EIY EIZ
  nelemv = length( conect(:,1) );
  nnodos = length( coor(:,1) );
  dofpn  = 6;
%************************************************************************
% Ensamble K, M y P
%************************************************************************
% Inicializa los ensambles
  K = zeros( nnodos*dofpn, nnodos*dofpn );
  M = zeros( nnodos*dofpn, nnodos*dofpn );
  F = zeros( nnodos*dofpn, 1 );
  U = zeros( nnodos*dofpn, 1 );
% Loop por los elementos
  for i = 1:(nelemv)

      coord = [ coor( conect( i, 3:4 ), 1 )'; ...
                coor( conect( i, 3:4 ), 2 )'; ...
                coor( conect( i, 3:4 ), 3 )' ] ;

      if conect(i,2) == 1

         EA   = YOUNG*secc_torre(i,1);
         EI33 = YOUNG*secc_torre(i,6);
         EI22 = YOUNG*secc_torre(i,5);
         GIt  = YOUNG/2/(1+POISS)*secc_torre(i,4);
         A    = secc_torre(i,1);
         Ac   = secc_torre(i,2);
         I33  = secc_torre(i,6);
         I22  = secc_torre(i,5);
         It   = secc_torre(i,4);
         rho  = DENS;
         [R,L] = rotacion(coord);

      elseif conect(i,2) == 2

         if i < 55

            EA   = secc_pala(i-19,1);
            EI33 = secc_pala(i-19,6);
            EI22 = secc_pala(i-19,5);
            GIt  = secc_pala(i-19,4);
            %   AXIALD   TORDEN    INERT2     INERT3
            E = EA/inercia_pala(i-19,1);
            A    = inercia_pala(i-19,1);
            Ac   = secc_pala(i-19,2)/E*2.3;  % Adopto nu = 0.15;
            I33  = inercia_pala(i-19,4);
            I22  = inercia_pala(i-19,3);
            It   = GIt/E*2.3;% Adopto nu=0.15
            rho  = rho_pala;
            [R,L] = rotacion(coord,coorP1aux(i-19,:));

         elseif i < 90

            EA   = secc_pala(i-54,1);
            EI33 = secc_pala(i-54,6);
            EI22 = secc_pala(i-54,5);
            GIt  = secc_pala(i-54,4);
            %   AXIALD   TORDEN    INERT2     INERT3
            E = EA/inercia_pala(i-54,1);
            A    = inercia_pala(i-54,1);
            Ac   = secc_pala(i-54,2)/E*2.3;  % Adopto nu = 0.15;
            I33  = inercia_pala(i-54,4);
            I22  = inercia_pala(i-54,3);
            It   = GIt/E*2.3;% Adopto nu=0.15
            rho  = rho_pala;
            [R,L] = rotacion(coord,coorP1aux(i-54,:));

         else

            EA   = secc_pala(i-89,1);
            EI33 = secc_pala(i-89,6);
            EI22 = secc_pala(i-89,5);
            GIt  = secc_pala(i-89,4);
            %   AXIALD   TORDEN    INERT2     INERT3
            E = EA/inercia_pala(i-89,1);
            A    = inercia_pala(i-89,1);
            Ac   = secc_pala(i-89,2)/E*2.3;  % Adopto nu = 0.15;
            I33  = inercia_pala(i-89,4);
            I22  = inercia_pala(i-89,3);
            It   = GIt/E*2.3;% Adopto nu=0.15
            rho  = rho_pala;
           [R,L] = rotacion(coord,coorP1aux(i-89,:));

         end

      elseif conect(i,2) == 3 % Conector rigido

         EA   = YOUNG*1e3;
         EI33 = YOUNG*1e4;
         EI22 = YOUNG*1e4;
         GIt  = YOUNG/2/(1+POISS)*1e4;
         A    = 1e3;
         Ac   = 0.01;
         I33  = 1e4;
         I22  = 1e4;
         It   = 1e4;
         rho  = 1; % este es impuesto
         [R,L] = rotacion(coord);

      elseif conect(i,2) == 4 % Conector torre-gondola con seccion de torre

         EA   = YOUNG*secc_torre(20,1);
         EI33 = YOUNG*secc_torre(20,6);
         EI22 = YOUNG*secc_torre(20,5);
         GIt  = YOUNG/2/(1+POISS)*secc_torre(20,4);
         A    = secc_torre(20,1);
         Ac   = secc_torre(20,2);
         I33  = secc_torre(20,6);
         I22  = secc_torre(20,5);
         It   = secc_torre(20,4);
         rho  = DENS;
         [R,L] = rotacion(coord);

      end

      ke  = stiff_V2( EA, EI33, EI22, GIt, L );
      me  = mass_V2( rho, L, A, It, I22, I33 );

      indi  = [ dofpn*conect(i,3)-5:dofpn*conect(i,3) dofpn*conect(i,4)-5:dofpn*conect(i,4) ];

      K( indi, indi ) = K( indi, indi ) + R'*ke*R ;
      M( indi, indi ) = M( indi, indi ) + R'*me*R ;

  end

%************************************************************************
% Diagonaliza la matriz de masa
%************************************************************************
% La siguiente linea comentala o descomentala

  M  = abs(diag(sum(M,2)));

%************************************************************************
% Suma la contribucin de la fundacion
%************************************************************************
% Opciones = fix - soft - stiff

base = 'fix' ;
% base = 'soft';
% base = 'stiff';

indi = 1:6;
% kf = [ 3.3882e10             0             0             0             0             0  ; ...
                 0     3.3882e10             0             0             0             0  ; ...
                 0             0     4.1143e10             0             0             0  ; ...
                 0             0             0     2.7429e12             0             0  ; ...
                 0             0             0             0     2.7429e12             0  ; ...
                 0             0             0             0             0     3.8400e12 ]; % en coordenadas globales

% mf = [  8.9412e5            0            0            0            0            0  ; ...
                 0     8.9412e5            0            0            0            0  ; ...
                 0            0     3.0857e6            0            0            0  ; ...
                 0            0            0     1.8286e8            0            0  ; ...
                 0            0            0            0     1.8286e8            0  ; ...
                 0            0            0            0            0     4.8000e7 ];

if strcmpi( base, 'stiff' ) == 1   % Version stiff
    Kf = diag( [ 3.558e+10   3.558e+10   4.320e+10   6.480e+12   6.480e+12   9.072e+12 ] );
    Mf = diag( [ 9.181e+06   9.181e+06   1.436e+07   1.370e+09   1.370e+09   4.540e+08 ] );
    Cf = diag( [ 5.159e+08   5.159e+08   9.180e+08   4.547e+10   4.547e+10   3.298e+10 ] );
elseif strcmpi( base, 'soft' ) == 1   % Version Soft
    Kf = diag( [ 2.635e+09   2.635e+09   3.200e+09   2.133e+11   2.133e+11   2.987e+11 ] );
    Mf = diag( [ 3.767e+06   3.767e+06   5.302e+06   2.065e+08   2.065e+08   7.287e+07 ] );
    Cf = diag( [ 7.642e+07   7.642e+07   1.360e+08   2.901e+09   2.901e+09   2.270e+09 ] );
elseif strcmpi(base,'fix') == 1
    Kf = 0.0 *diag([ 1 1 1 1 1 1 ] );
    Mf = 0.0 *diag([ 1 1 1 1 1 1 ] );
end

K( indi, indi )=  K( indi, indi ) + Kf ;
M( indi, indi )=  M( indi, indi ) + Mf ;

%************************************************************************
% Suma la contribucion de la gondola y el cubo
%************************************************************************
% Euler angles of hub and nacelle
  EA = [ 9.0000e+01  -5.0000e+00  -9.0000e+01 ];
  ROT_EA = rotmat(EA);
% gondola
  indi = dofpn*129-5:dofpn*129;
  MT_G = [ 1.1845e+006   1.1845e+006   1.1845e+006 ];
  MR_G = [ 1.4806e+007   3.2672e+007   3.2672e+007 ];
  MR_G = diag( ROT_EA*diag(MR_G)*ROT_EA' )';
  M( indi, indi ) = M( indi, indi ) + diag([ MT_G MR_G ]) ;
% cubo
  indi = dofpn*130-5:dofpn*130 ;
  MT_C = [ 1.9600e+005   1.9600e+005   1.9600e+005 ];
  MR_C = [ 2.8224e+006   2.8224e+006   2.8224e+006 ];
  MR_C = diag( ROT_EA*diag(MR_C)*ROT_EA' )';
  M( indi, indi ) = M( indi, indi ) + diag([ MT_C MR_C ]) ;
% Matriz de massa lumped de simpact
%   ! Nodo   M_x           M_y           M_z           In_x          In_y          In_z
%       1    1.9600e+05    1.9600e+05    1.9600e+05    2.8224e+06    2.8224e+06    2.8224e+06 ! masa concentrada del cubo
%       2    1.1845e+06    1.1845e+06    1.1845e+06    1.4806e+07    3.2672e+07    3.2672e+07 ! masa concentrada de la góndola
%
%************************************************************************
% Pone las restricciones cinematicas
%************************************************************************
  dofl = 1:nnodos*dofpn;
  doft = dofl;
  doft =reshape(doft,[3 2*nnodos]);
  doft( :, (2:2:end) ) = [];
  doft = reshape( doft, [1 3*nnodos] );

if strcmpi(base,'fix') == 1
    dofr = [ 1 2 3 4 5 6 ];
    dofl( dofr ) = [];     %
end

%************************************************************************
% Modos y frecuencias sin la fundacion
%************************************************************************
  [Phi,omega2] = eigs( K(dofl,dofl), M(dofl,dofl), 20, 'sm' );
  omega = diag( sqrt(omega2) );
  f     = omega/2/pi;
  T     = f.^(-1);

% Frecuencias fundamentales delta Hz
frecDelta = [ 0.167
              0.169
              0.360
              0.403
              0.429
              0.556
              0.652
              0.688
              0.921
              1.045 ];

[ frecDelta  f(1:10) frecDelta./f(1:10) ]

%************************************************************************
% Plotea geometria indeformada
%************************************************************************
  figure(100); hold on; grid on; box on; axis equal;
  plotea_geometria( nelemv, nnodos, coor, conect, dofpn )
  view(135,20)
  xlabel( '$x$ (m)', 'Interpreter', 'latex' )
  ylabel( '$y$ (m)', 'Interpreter', 'latex' )
  zlabel( '$z$ (m)', 'Interpreter', 'latex' )
  zlim( [0 250] )
  xlim( [-100 100] )
  ylim( [-100 100] )
  title( ['Geometria y numero de nodos extremos'], 'Interpreter', 'latex' )

%************************************************************************
% Plotea Modos
%************************************************************************
if strcmpi(base,'fix') == 1
    Phi = [zeros(6,20);Phi];
end

nm = 1;
figure(nm);hold on;grid on;box on;axis equal;
plotea_def(Phi(:,nm),50,nelemv,nnodos,coor,conect,dofpn)
view(135,20)
zlabel('$H$ (m)','Interpreter','latex')
zlim([0 250])
xlim([-100 100])
ylim([-100 100])
title(['Modo ' num2str(nm) ' - $f$ = ' num2str(round(f(nm),3)) 'Hz'],'Interpreter','latex')
% savefig(['Modo_' num2str(nm) '_MC_' base '_2024.fig'])
% print(figure(nm), '-dpdf', '-r600', ['Modo_' num2str(nm) '_MC_' base '_2024.pdf']);

nm = 2;
figure(nm);hold on;grid on;box on;axis equal
plotea_def(Phi(:,nm),50,nelemv,nnodos,coor,conect,dofpn)
view(135,20)
zlabel('$H$ (m)','Interpreter','latex')
zlim([0 250])
xlim([-100 100])
ylim([-100 100])
title(['Modo ' num2str(nm) ' - $f$ = ' num2str(round(f(nm),3)) 'Hz'],'Interpreter','latex')
% savefig(['Modo_' num2str(nm) '_MC_' base '_2024.fig'])
% print(figure(nm), '-dpdf', '-r600', ['Modo_' num2str(nm) '_MC_' base '_2024.pdf']);

% nm = 3;
% figure(nm);hold on;grid on;box on;axis equal
% plotea_def(Phi(:,nm),50,nelemv,nnodos,coor,conect,dofpn)
% view(135,20)
% zlabel('$H$ (m)','Interpreter','latex')
% zlim([0 250])
% xlim([-100 100])
% ylim([-100 100])
% title(['Modo ' num2str(nm) ' - $f$ = ' num2str(round(f(nm),3)) 'Hz'],'Interpreter','latex')
% % savefig(['Modo_' num2str(nm) '_MC_' base '_2024.fig'])
% % print(figure(nm), '-dpdf', '-r600', ['Modo_' num2str(nm) '_MC_' base '_2024.pdf']);
%
% nm = 4;
% figure(nm);hold on;grid on;box on;axis equal
% plotea_def(Phi(:,nm),50,nelemv,nnodos,coor,conect,dofpn)
% view(135,20)
% zlabel('$H$ (m)','Interpreter','latex')
% zlim([0 250])
% xlim([-100 100])
% ylim([-100 100])
% title(['Modo ' num2str(nm) ' - $f$ = ' num2str(round(f(nm),3)) 'Hz'],'Interpreter','latex')
% % savefig(['Modo_' num2str(nm) '_MC_' base '_2024.fig'])
% % print(figure(nm), '-dpdf', '-r600', ['Modo_' num2str(nm) '_MC_' base '_2024.pdf']);
%
% nm = 5;
% figure(nm);hold on;grid on;box on;axis equal
% plotea_def(Phi(:,nm),50,nelemv,nnodos,coor,conect,dofpn)
% view(135,20)
% zlabel('$H$ (m)','Interpreter','latex')
% zlim([0 250])
% xlim([-100 100])
% ylim([-100 100])
% title(['Modo ' num2str(nm) ' - $f$ = ' num2str(round(f(nm),3)) 'Hz'],'Interpreter','latex')
% % savefig(['Modo_' num2str(nm) '_MC_' base '_2024.fig'])
% % print(figure(nm), '-dpdf', '-r600', ['Modo_' num2str(nm) '_MC_' base '_2024.pdf']);
%
% nm = 6;
% figure(nm);hold on;grid on;box on;axis equal
% plotea_def(Phi(:,nm),50,nelemv,nnodos,coor,conect,dofpn)
% view(135,20)
% zlabel('$H$ (m)','Interpreter','latex')
% zlim([0 250])
% xlim([-100 100])
% ylim([-100 100])
% title(['Modo ' num2str(nm) ' - $f$ = ' num2str(round(f(nm),3)) 'Hz'],'Interpreter','latex')
% % savefig(['Modo_' num2str(nm) '_MC_' base '_2024.fig'])
% % print(figure(nm), '-dpdf', '-r600', ['Modo_' num2str(nm) '_MC_' base '_2024.pdf']);
%
% nm = 9;
% figure(nm);hold on;grid on;box on;axis equal
% plotea_def(Phi(:,nm),50,nelemv,nnodos,coor,conect,dofpn)
% view(135,20)
% zlabel('$H$ (m)','Interpreter','latex')
% zlim([0 250])
% xlim([-100 100])
% ylim([-100 100])
% title(['Modo ' num2str(nm) ' - $f$ = ' num2str(round(f(nm),3)) 'Hz'],'Interpreter','latex')
% % savefig(['Modo_' num2str(nm) '_MC_' base '_2024.fig'])
% % print(figure(nm), '-dpdf', '-r600', ['Modo_' num2str(nm) '_MC_' base '_2024.pdf']);
%
% nm = 12;
% figure(nm);hold on;grid on;box on;axis equal
% plotea_def(Phi(:,nm),50,nelemv,nnodos,coor,conect,dofpn)
% view(135,20)
% zlabel('$H$ (m)','Interpreter','latex')
% zlim([0 250])
% xlim([-100 100])
% ylim([-100 100])
% title(['Modo ' num2str(nm) ' - $f$ = ' num2str(round(f(nm),3)) 'Hz'],'Interpreter','latex')
% % savefig(['Modo_' num2str(nm) '_MC_' base '_2024.fig'])
% % print(figure(nm), '-dpdf', '-r600', ['Modo_' num2str(nm) '_MC_' base '_2024.pdf']);
%
% nm = 13;
% figure(nm);hold on;grid on;box on;axis equal
% plotea_def(Phi(:,nm),50,nelemv,nnodos,coor,conect,dofpn)
% view(135,20)
% zlabel('$H$ (m)','Interpreter','latex')
% zlim([0 250])
% xlim([-100 100])
% ylim([-100 100])
% title(['Modo ' num2str(nm) ' - $f$ = ' num2str(round(f(nm),3)) 'Hz'],'Interpreter','latex')
% % savefig(['Modo_' num2str(nm) '_MC_' base '_2024.fig'])
% % print(figure(nm), '-dpdf', '-r600', ['Modo_' num2str(nm) '_MC_' base '_2024.pdf']);
%
% nm = 18;
% figure(nm);hold on;grid on;box on;axis equal
% plotea_def(Phi(:,nm),50,nelemv,nnodos,coor,conect,dofpn)
% view(135,20)
% zlabel('$H$ (m)','Interpreter','latex')
% zlim([0 250])
% xlim([-100 100])
% ylim([-100 100])
% title(['Modo ' num2str(nm) ' - $f$ = ' num2str(round(f(nm),3)) 'Hz'],'Interpreter','latex')
% % savefig(['Modo_' num2str(nm) '_MC_' base '_2024.fig'])
% % print(figure(nm), '-dpdf', '-r600', ['Modo_' num2str(nm) '_MC_' base '_2024.pdf']);
%
% nm = 19;
% figure(nm);hold on;grid on;box on;axis equal
% plotea_def(Phi(:,nm),50,nelemv,nnodos,coor,conect,dofpn)
% view(135,20)
% zlabel('$H$ (m)','Interpreter','latex')
% zlim([0 250])
% xlim([-100 100])
% ylim([-100 100])
% title(['Modo ' num2str(nm) ' - $f$ = ' num2str(round(f(nm),3)) 'Hz'],'Interpreter','latex')
% % savefig(['Modo_' num2str(nm) '_MC_' base '_2024.fig'])
% % print(figure(nm), '-dpdf', '-r600', ['Modo_' num2str(nm) '_MC_' base '_2024.pdf']);

%**************************************************************************
%  Funciones auxiliares
%**************************************************************************

%**************************************************************************
function [ ke ] = stiff_V2( EA, EI33, EI22, GIt, L )
% MAtriz de rigidez para la barra con eje 1 segun eje x
ke = [  EA/L,              0,              0,      0,             0,             0, -EA/L,              0,              0,      0,             0,             0
     0,  (12*EI33)/L^3,              0,      0,             0,  (6*EI33)/L^2,     0, -(12*EI33)/L^3,              0,      0,             0,  (6*EI33)/L^2
     0,              0,  (12*EI22)/L^3,      0, -(6*EI22)/L^2,             0,     0,              0, -(12*EI22)/L^3,      0, -(6*EI22)/L^2,             0
     0,              0,              0,  GIt/L,             0,             0,     0,              0,              0, -GIt/L,             0,             0
     0,              0,  -(6*EI22)/L^2,      0,    (4*EI22)/L,             0,     0,              0,   (6*EI22)/L^2,      0,    (2*EI22)/L,             0
     0,   (6*EI33)/L^2,              0,      0,             0,    (4*EI33)/L,     0,  -(6*EI33)/L^2,              0,      0,             0,    (2*EI33)/L
 -EA/L,              0,              0,      0,             0,             0,  EA/L,              0,              0,      0,             0,             0
     0, -(12*EI33)/L^3,              0,      0,             0, -(6*EI33)/L^2,     0,  (12*EI33)/L^3,              0,      0,             0, -(6*EI33)/L^2
     0,              0, -(12*EI22)/L^3,      0,  (6*EI22)/L^2,             0,     0,              0,  (12*EI22)/L^3,      0,  (6*EI22)/L^2,             0
     0,              0,              0, -GIt/L,             0,             0,     0,              0,              0,  GIt/L,             0,             0
     0,              0,  -(6*EI22)/L^2,      0,    (2*EI22)/L,             0,     0,              0,   (6*EI22)/L^2,      0,    (4*EI22)/L,             0
     0,   (6*EI33)/L^2,              0,      0,             0,    (2*EI33)/L,     0,  -(6*EI33)/L^2,              0,      0,             0,    (4*EI33)/L];

end

%**************************************************************************
function [ me ] = mass_V2( rho, L, A, It, I22, I33 )
% Matriz de masa para la barra con eje 1 segun eje x
 me = (A*L*rho) * [   1/3,           0,           0,        0,           0,          0, 1/6,           0,           0,        0,          0,           0
                        0,       13/35,           0,        0,           0, (11*L)/210,   0,        9/70,           0,        0,          0, -(13*L)/420
                        0,           0,       13/35,        0, -(11*L)/210,          0,   0,           0,        9/70,        0, (13*L)/420,           0
                        0,           0,           0, It/(3*A),           0,          0,   0,           0,           0, It/(6*A),          0,           0
                        0,           0, -(11*L)/210,        0,     L^2/105,          0,   0,           0, -(13*L)/420,        0,   -L^2/140,           0
                        0,  (11*L)/210,           0,        0,           0,    L^2/105,   0,  (13*L)/420,           0,        0,          0,    -L^2/140
                      1/6,           0,           0,        0,           0,          0, 1/3,           0,           0,        0,          0,           0
                        0,        9/70,           0,        0,           0, (13*L)/420,   0,       13/35,           0,        0,          0, -(11*L)/210
                        0,           0,        9/70,        0, -(13*L)/420,          0,   0,           0,       13/35,        0, (11*L)/210,           0
                        0,           0,           0, It/(6*A),           0,          0,   0,           0,           0, It/(3*A),          0,           0
                        0,           0,  (13*L)/420,        0,    -L^2/140,          0,   0,           0,  (11*L)/210,        0,    L^2/105,           0
                        0, -(13*L)/420,           0,        0,           0,   -L^2/140,   0, -(11*L)/210,           0,        0,          0,     L^2/105];
end

%************************************************************************
function [ R, L ] = rotacion( coord_n, naux )
% Matriz de rotacion
dx   = coord_n(1,2) - coord_n(1,1);
dy   = coord_n(2,2) - coord_n(2,1);
dz   = coord_n(3,2) - coord_n(3,1);
L    = sqrt(dx^2+dy^2+dz^2);

t1   = 1/L*[dx dy dz]';
if nargin == 1
    L_2  = sqrt(dx^2+dy^2);
    if (dx==0 && dy==0)
        t2=[0 1 0]';
    else
        t2   = 1/L_2*[-dy +dx 0]';
    end
    t3   = cross(t1,t2);
else
    va1 = naux'-coord_n(:,1);
    t3  = (va1-dot(va1,t1)*t1)/norm(va1-dot(va1,t1)*t1);
    t2   = -cross(t1,t3);
end

A = [t1 t2 t3];
Bb = zeros(3,3);
R     = [A Bb Bb Bb;Bb A Bb Bb;Bb Bb A Bb;Bb Bb Bb A];
end

%************************************************************************
function [] = plotea_modos( Phi )
figure(1);hold on;grid on;box on;
np = 10;
ngdl = length(Phi(:,1));
l    =1;
Phi_a = [zeros(1,ngdl);Phi];

for i = 1:ngdl
    subplot(1,3,i);hold on;grid on;box on;
    for j = 1:ngdl
        x     = (0:l/np:1)';
        u_int = [2*x.^3/l^3-3*x.^2/l^2+1 +(x.^3/l^2-2*x.^2/l+x) -2*x.^3/l^3+3*x.^2/l^2 +(x.^3/l^2-x.^2/l)]*[Phi_a(j,i) 0 Phi_a(j+1,i) 0]';
        plot(u_int,x+1*(j-1),'-b','linewidth',2)
        plot(u_int(end),1+1*(j-1),'or','linewidth',2)
    end
end
subplot(1,3,1);
plot([0 0],[0 ngdl],'-k')
title('Modo 1')
subplot(1,3,2);
plot([0 0],[0 ngdl],'-k')
title('Modo 2')
subplot(1,3,3);
plot([0 0],[0 ngdl],'-k')
title('Modo 3')
end

%************************************************************************
function [] = plotea_def( u, esc, nelemv, nnodos, coor, conect, dofpn )
% figure(1);hold on;grid on;box on;
% trabaja para calcular la escala de forma de obtener un desplazamiento
% unitario en el nudo de maximo desplazamiento

ut  = reshape(u,3,2*nnodos)';
utn = (ut(:,1).^2+ut(:,2).^2+ut(:,3).^2).^(0.5);
esc = esc/max(utn);
np = 10;
for i = 1:nelemv
    coorx = coor(conect(i,3:4),1);
    coory = coor(conect(i,3:4),2);
    coorz = coor(conect(i,3:4),3);
    % Calcula los desplazamientos interpolados
    coord = [coor(conect(i,3:4),1)';coor(conect(i,3:4),2)';coor(conect(i,3:4),3)'] ;
    [R,L] = rotacion(coord);

    indi  = [dofpn*conect(i,3)-5:dofpn*conect(i,3)  dofpn*conect(i,4)-5:dofpn*conect(i,4)]; %

%     indi   = [dofpn*conect(i,2)-5:dofpn*conect(i,2)  dofpn*conect(i,3)-5:dofpn*conect(i,3)];
    % rota los desplazaminetos a coor locales
    u_loc  = R*u(indi);
    % interpola las coordenadas locales
    coor_loc = R(1:3,1:3)*[coorx coory coorz]';
    cx_loc = coor_loc(1,:)';
    cy_loc = coor_loc(2,:)';
    cz_loc = coor_loc(3,:)';
    x      = (cx_loc(1):(cx_loc(2)-cx_loc(1))/np:cx_loc(2))';

    cx_loc_int = interp1(cx_loc,cx_loc,x);
    cy_loc_int = interp1(cx_loc,cy_loc,x);
    cz_loc_int = interp1(cx_loc,cz_loc,x);
    % interpola los desplazamientos en coor locales
    %     u1_int = interp1(cx_loc,u_loc([1 7]),x);
    x      = (0:L/np:L)';
    u1_int = [1-x/L x/L] * u_loc([1 7]);
    u2_int = [2*x.^3/L^3-3*x.^2/L^2+1 +(x.^3/L^2-2*x.^2/L+x) -2*x.^3/L^3+3*x.^2/L^2 +(x.^3/L^2-x.^2/L)] * u_loc([2 6 8 12]);
    u3_int = [2*x.^3/L^3-3*x.^2/L^2+1 -(x.^3/L^2-2*x.^2/L+x) -2*x.^3/L^3+3*x.^2/L^2 -(x.^3/L^2-x.^2/L)] * u_loc([3 5 9 11]);
    % rota los desplazaminetos interp a coor fisicas
    u_int  = (R(1:3,1:3)'*[u1_int u2_int u3_int]')';
    coor_int   = (R(1:3,1:3)'*[cx_loc_int cy_loc_int cz_loc_int]')' ;
    % Calcula la geometria deformada
    coor_def = coor_int + esc * u_int;
    % plotea geo indeformada
    plot3(coorx,coory,coorz,'--k')
    % plotea geo deformada
    plot3(coor_def(:,1),coor_def(:,2),coor_def(:,3),'-b','linewidth',2)

end

end

%************************************************************************
function [] = plotea_geometria( nelemv, nnodos, coor, conect, dofpn )
% plotea la geometria indeformada

% plotea los elementos de vigas
for i = 1:nelemv
    coorx = coor(conect(i,3:4),1);
    coory = coor(conect(i,3:4),2);
    coorz = coor(conect(i,3:4),3);

    % plotea geo indeformada
    switch conect(i,2)
        case 1 % torre
            plot3(coorx,coory,coorz,'o-b','markersize',2,'linewidth',2)
        case 2 % pala
            plot3(coorx,coory,coorz,'d-r','markersize',2,'linewidth',2)
        case 3 % conector rigido
            plot3(coorx,coory,coorz,'o-b','markersize',1,'linewidth',1)
        case 4 % Conector torre - gondola
            plot3(coorx,coory,coorz,'s-g','markersize',2,'linewidth',2)
    end
end

% plotea los nodos con masas concentradas
nnodos_mc = [129 130];

for i = 1:2
    coorx = coor(nnodos_mc(i),1);
    coory = coor(nnodos_mc(i),2);
    coorz = coor(nnodos_mc(i),3);

    % plotea geo indeformada
    plot3(coorx,coory,coorz,'ob','markersize',7,'markerfacecolor','k')

end
% plotea los numeros de nodos seleccionados
nodos_plot = [1 20 21 56 57 92 93 128 129 130]';
dir        = [1 -1 1 1 1 1 1 1 -1 1]';
delta = 10;
for i = 1:length(nodos_plot)
    coorx = coor(nodos_plot(i),1);
    coory = coor(nodos_plot(i),2);
    coorz = coor(nodos_plot(i),3);

    % plotea geo indeformada
    if dir(i)<0
        quiver3(coorx+delta*dir(i),coory,coorz,-delta*dir(i),0,0,'-k','linewidth',1);
        text(coorx+delta*1.8*dir(i),coory,coorz,num2str(nodos_plot(i)))
    elseif nodos_plot(i)==130
        quiver3(coorx+2*delta*dir(i),coory,coorz,-2*delta*dir(i),0,0,'-k','linewidth',1);
        text(coorx+delta*2*1.2*dir(i),coory,coorz,num2str(nodos_plot(i)))
    else
        quiver3(coorx+delta*dir(i),coory,coorz,-delta*dir(i),0,0,'-k','linewidth',1);
        text(coorx+delta*1.2*dir(i),coory,coorz,num2str(nodos_plot(i)))
    end

end
end

%************************************************************************
function R = rotmat( AE )

   psi   = AE(1);   %*pi/180;
   theta = AE(2);   %*pi/180;
   phi   = AE(3);   %*pi/180;

   Rz1 = [  cos(psi)  sin(psi)  0; ...
           -sin(psi)  cos(psi)  0; ...
               0         0      1 ];

   Rx2 = [ 1      0           0      ; ...
           0  cos(theta)  sin(theta) ; ...
           0 -sin(theta)  cos(theta) ];

   Rz3 = [  cos(phi)  sin(phi)  0; ...
           -sin(phi)  cos(phi)  0; ...
                0         0  1   ];
   R =Rz3*Rx2*Rz1;

end
