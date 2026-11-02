#!/usr/bin/env python3
"""Algebraic checks of the stated energy identity and upper bound.
These checks supplement the derivation; they are not a convergence proof.
"""
import numpy as np
rng=np.random.default_rng(20261102)
worst_identity=0.;worst_excess=-np.inf
for _ in range(500):
 n=7
 def spd():
  R=rng.normal(size=(n,n));return R.T@R+np.eye(n)
 def sym():
  R=rng.normal(size=(n,n));return (R+R.T)/2
 def invsqrt(X):
  w,V=np.linalg.eigh(X);return (V/np.sqrt(w))@V.T
 M,H=spd(),spd();Md,Hd=sym(),sym();D=rng.normal(size=(n,n));K=rng.normal(size=(n,n));z,v,f=rng.normal(size=(3,n));acc=np.linalg.solve(M,f-D@v-K@z)
 E=.5*(v@M@v+z@H@z)
 direct=v@M@acc+.5*v@Md@v+z@H@v+.5*z@Hd@z
 A=.5*Md-.5*(D+D.T);B=K-H
 identity=v@f+v@A@v-v@B@z+.5*z@Hd@z
 im,ih=invsqrt(M),invsqrt(H)
 c=2*np.linalg.norm(im@A@im,2)+np.linalg.norm(im@B@ih,2)+np.linalg.norm(ih@Hd@ih,2)+.7
 rhs=c*E+np.linalg.norm(im@f)**2/(2*.7)
 worst_identity=max(worst_identity,abs(direct-identity));worst_excess=max(worst_excess,direct-rhs)
assert worst_identity<1e-10 and worst_excess<=1e-10
print(f'500 nonsymmetric/time-varying cases: identity error {worst_identity:.3g}; bound satisfied.')
