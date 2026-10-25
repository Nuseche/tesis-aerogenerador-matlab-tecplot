# Referencia modal heredada

Las primeras veinte frecuencias fueron generadas el 25 de agosto de 2026
con MATLAB R2026a ejecutando sin modificar
`legacy/Codigos_sergio/[Diego Turello Version 0]/FrecuenciasTorreCompleta.m`
en base fija. Se guardan con precisión completa en MAT y CSV.

Esta referencia caracteriza únicamente al programa antiguo: incluye
Euler--Bernoulli, conectores tipo 3 penalizados y la diagonalización
`abs(diag(sum(M,2)))`. No es un objetivo físico que el solver Timoshenko
nuevo deba igualar exactamente; sirve para regresión y trazabilidad.
