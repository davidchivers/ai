function fval=covariance_cm(par)
global Sigma T

sig2eta1=par(1)^2;
sig2v=par(2)^2;
sig2eps=par(3)^2;

Sig=zeros(T,T);

for tt=1:T
    Sig(tt,tt)=sig2eta1+(tt-1)*sig2v+sig2eps;
end

for tt=1:T
    for ttt=tt+1:T
        Sig(tt,ttt)=sig2eta1+(tt-1)*sig2v;
        Sig(ttt,tt)=sig2eta1+(tt-1)*sig2v;
    end
    
end


fval=sum(sum((Sigma-Sig).^2));



end


