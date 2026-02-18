function fval=covariance_cm_consumption_twostep(par)
global Sigma T sig2eta1 sig2v sig2eps

phi_eta=par(1);
phi_eps=par(2);
sig2xi=par(3)^2;

Sig=zeros(2*T,2*T);

% (Y,Y)
for tt=1:T
    Sig(tt,tt)=sig2eta1+(tt-1)*sig2v+sig2eps;
end

for tt=1:T
    for ttt=tt+1:T
        Sig(tt,ttt)=sig2eta1+(tt-1)*sig2v;
        Sig(ttt,tt)=sig2eta1+(tt-1)*sig2v;
    end
    
end

% (Y,C)
for tt=1:T
    Sig(tt,T+tt)=phi_eta*(sig2eta1+(tt-1)*sig2v)+phi_eps*sig2eps;
end

for tt=1:T
    for ttt=tt+1:T
        Sig(tt,T+ttt)=phi_eta*(sig2eta1+(tt-1)*sig2v);
        Sig(ttt,T+tt)=phi_eta*(sig2eta1+(tt-1)*sig2v);
    end
    
end

% (C,Y)
for tt=1:T
    Sig(T+tt,tt)=phi_eta*(sig2eta1+(tt-1)*sig2v)+phi_eps*sig2eps;
end

for tt=1:T
    for ttt=tt+1:T
        Sig(T+tt,ttt)=phi_eta*(sig2eta1+(tt-1)*sig2v);
        Sig(T+ttt,tt)=phi_eta*(sig2eta1+(tt-1)*sig2v);
    end
    
end

% (C,C)
for tt=1:T
    Sig(T+tt,T+tt)=phi_eta^2*(sig2eta1+(tt-1)*sig2v)+phi_eps^2*sig2eps+sig2xi;
end

for tt=1:T
    for ttt=tt+1:T
        Sig(T+tt,T+ttt)=phi_eta^2*(sig2eta1+(tt-1)*sig2v);
        Sig(T+ttt,T+tt)=phi_eta^2*(sig2eta1+(tt-1)*sig2v);
    end
    
end



fval=sum(sum((Sigma-Sig).^2));



end


