function result=periodic_stability(M,D,K,omega,timeSamples)
%PERIODIC_STABILITY Midpoint-exponential Floquet check of a periodic ROM.
% Repeat with more timeSamples and retained modes before interpreting stability.
n=size(M,1);N=size(M,3);orders=[0:floor(N/2),-ceil(N/2)+1:-1];
Mf=fft(M,[],3)/N;Df=fft(D,[],3)/N;Kf=fft(K,[],3)/N;
period=2*pi/abs(omega);h=period/timeSamples;Phi=eye(2*n);
for j=1:timeSamples
    psi=2*pi*(j-.5)/timeSamples;weights=reshape(exp(1i*orders*psi),1,1,[]);
    m=real(sum(Mf.*weights,3));d=real(sum(Df.*weights,3));k=real(sum(Kf.*weights,3));
    A=[zeros(n) eye(n);-m\k -m\d];Phi=expm(A*h)*Phi;
end
multipliers=eig(Phi);result=struct('spectralRadius',max(abs(multipliers)), ...
    'multipliers',multipliers,'growthRates',log(abs(multipliers))/period, ...
    'timeSamples',timeSamples,'retainedModes',n,'period',period);
end
