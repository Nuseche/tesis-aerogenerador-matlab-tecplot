function result=harmonic_balance(M,D,K,omega,order,B,halfWidth)
%HARMONIC_BALANCE Periodic structural response to B*cos(order*omega*t).
% M,D,K: n-by-n-by-N uniform azimuth samples (endpoint excluded).
% Keeps coefficient convolution and sidebands; a Campbell crossing alone is
% not a resonance test. A periodic solution need not be a stable attractor.
n=size(M,1);N=size(M,3);H=halfWidth;assert(N>4*H&&order<=H,'Insufficient angular sampling or harmonic width.');
Mf=fft(M,[],3)/N;Df=fft(D,[],3)/N;Kf=fft(K,[],3)/N;
indices=-H:H;A=sparse(n*numel(indices),n*numel(indices));rhs=zeros(size(A,1),size(B,2));
scaleM=max(norm(Mf(:,:,1),'fro'),eps);scaleD=max(norm(Df(:,:,1),'fro'),eps);scaleK=max(norm(Kf(:,:,1),'fro'),eps);
for h=indices
    rr=(h+H)*n+(1:n);
    if abs(h)==order,rhs(rr,:)=B/2;end
    for k=indices
        l=h-k;idx=mod(l,N)+1;
        if l~=0&&max([norm(Mf(:,:,idx),'fro')/scaleM,norm(Df(:,:,idx),'fro')/scaleD,norm(Kf(:,:,idx),'fro')/scaleK])<1e-12,continue,end
        cc=(k+H)*n+(1:n);
        A(rr,cc)=sparse(-(k*omega)^2*Mf(:,:,idx)+1i*k*omega*Df(:,:,idx)+Kf(:,:,idx));
    end
end
z=A\rhs;residual=norm(A*z-rhs,'fro')/max(norm(rhs,'fro'),eps);
result=struct('coefficients',reshape(z,n,numel(indices),[]),'orders',indices, ...
    'residual',residual,'halfWidth',H,'angularSamples',N,'stableAttractorEstablished',false);
end
