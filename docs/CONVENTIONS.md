# Convenciones matemáticas y físicas

El solver usa exclusivamente unidades SI coherentes: metro, kilogramo, segundo,
newton, pascal y radián. Los seis grados de libertad de cada nodo se almacenan
en el orden

`[u_x, u_y, u_z, theta_x, theta_y, theta_z]`.

Las traslaciones positivas siguen los ejes globales derechos. Las rotaciones
positivas obedecen la regla de la mano derecha. Para un vector `r`,

```text
       [  0   -rz    ry ]
S(r) = [ rz     0   -rx ]
       [-ry    rx     0 ]
```

y por tanto `S(r)*a = r x a`. La restricción rígida usa
`u_s = u_m - S(r_sm)*theta_m`, que equivale a
`u_s = u_m + theta_m x r_sm`, y `theta_s = theta_m`.

En cada viga el eje local 1 va de I a J. El **eje local 3** se obtiene
proyectando el vector nodo-I/punto-auxiliar sobre el plano normal al eje 1 y
el eje local 2 se define como `e3 x e1`. Esta es la convención de los datos
heredados y evita intercambiar `EIy/EIz`, `GAy/GAz` o `Jy/Jz`. La matriz de
rotación contiene los ejes locales por filas y transforma un vector global a
local. Para las palas se usan, sin intercambio, `coorP1aux`, `coorP2aux` y
`coorP3aux`.

El vector elemental local se ordena como
`[u1 v1 w1 rx1 ry1 rz1 u2 v2 w2 rx2 ry2 rz2]`. Las deformaciones son
`epsilon_x=du/dx`, `gamma_y=dv/dx-rz`, `gamma_z=dw/dx+ry`,
`kappa_x=drx/dx`, `kappa_y=dry/dx` y `kappa_z=drz/dx`. Por ello una rotación
rígida positiva alrededor de local 2 exige `w2-w1=-ry*L`, mientras una
rotación rígida positiva alrededor de local 3 exige `v2-v1=rz*L`.

Ejemplos semánticos de orientación:

- Viga global X con auxiliar global Y: `e1=X`, `e3=Y`, `e2=-Z`.
- Viga global Y con auxiliar global Z: `e1=Y`, `e3=Z`, `e2=X`.
- Viga global Z con auxiliar global X: `e1=Z`, `e3=X`, `e2=Y`.

La transformación elemental es `Te=blkdiag(R,R,R,R)` y cumple
`q_local=Te*q_global`, `K_global=Te'*K_local*Te` y la relación análoga para
la masa.

## Masa seccional de las palas

`AXIALD` se usa exclusivamente como dato de masa lineal y nunca como área ni
para obtener un módulo `EA/AXIALD`. El valor heredado `TORDEN` es cero. La
inercia longitudinal distribuida se completa únicamente cuando la
configuración declara `cfg.sections.blade.torsionalInertiaRule =
"perpendicular_axis"`; entonces `Jx=Jy+Jz` a partir de los campos documentados
`INERT2/INERT3`. No se deriva de `EA`, `GJ` ni de un módulo efectivo.

El eje nominal del rotor se toma de góndola (nodo 129) a cubo (nodo 130). La
velocidad positiva obedece la regla de la mano derecha alrededor de ese eje.
El azimut cero es el definido por la pala 1 en la geometría de referencia y el
azimut positivo crece con la velocidad positiva. Los azimuts de las palas 2 y
3 están separados `2*pi/3`. Pitch positivo es una rotación de mano derecha
alrededor del eje longitudinal de cada pala. Todos los ángulos internos están
en radianes; cualquier dato heredado en grados se convierte explícitamente.

MBC usa los armónicos colectivo, coseno y seno normalizados. Como `T` depende
del azimut, las transformaciones de amortiguamiento y rigidez incluyen `Tdot`
y `Tddot`. La respuesta sísmica se integra en coordenadas relativas; la
aceleración absoluta se recupera agregando `Gamma*a_g`.

## Separación de términos centrífugos

`Kg` se ensambla exclusivamente con las fuerzas axiales recuperadas del estado
de equilibrio. `KOmega` contiene solamente contribuciones rotacionales que no
están representadas por dichas fuerzas. La configuración predeterminada no
activa ambas representaciones para el mismo efecto. `Kaero` y `Caero` se
mantienen separados y no se simetrizan.
