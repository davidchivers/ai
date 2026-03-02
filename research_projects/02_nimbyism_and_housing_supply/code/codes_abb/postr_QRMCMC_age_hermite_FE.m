function fval=postr_QRMCMC_age_hermite_FE(Matdraw)
global Y N T Ntau Vectau Resqinit_eps Resqinit Resqinit_e0 Resqinit_zeta b1_eps bL_eps b1 bL b1_e0 bL_e0 b1_zeta bL_zeta K1 K2 K3 K3zeta AGE MatAGE_t MatAGE1  meanAGE stdAGE meanY stdY

Mat=Y(:,1:T)-Matdraw(:,1:T)-Matdraw(:,T+1)*ones(1,T);
Vect=Mat(:);

%Likelihood of the Data
dens=zeros(N*T,1);
for jtau=1:Ntau-1 
    dens=dens+(Vectau(jtau+1)-Vectau(jtau))./((Resqinit_eps(:,jtau+1)-Resqinit_eps(:,jtau))'*MatAGE_t')'.*...
        (Vect>(Resqinit_eps(:,jtau)'*MatAGE_t')').*(Vect<=(Resqinit_eps(:,jtau+1)'*MatAGE_t')');
end

dens=dens+Vectau(1)*b1_eps*exp(b1_eps*(Vect-(Resqinit_eps(:,1)'*MatAGE_t')')).*...
    (Vect<=(Resqinit_eps(:,1)'*MatAGE_t')')+...
    (1-Vectau(Ntau))*bL_eps*exp(-bL_eps*(Vect-(Resqinit_eps(:,Ntau)'*MatAGE_t')')).*...
    (Vect>(Resqinit_eps(:,Ntau)'*MatAGE_t')');

denstot=ones(N,1);
for tt=1:T
    denstot=denstot.*dens((tt-1)*N+1:tt*N);
end


% prior, zeta
denszeta=zeros(N,1);
for jtau=1:Ntau-1
    denszeta=denszeta+(Vectau(jtau+1)-Vectau(jtau))./((Resqinit_zeta(:,jtau+1)-Resqinit_zeta(:,jtau))'*MatAGE1')'.*...
        (Matdraw(:,T+1)>(Resqinit_zeta(:,jtau)'*MatAGE1')').*(Matdraw(:,T+1)<=(Resqinit_zeta(:,jtau+1)'*MatAGE1')');
end

denszeta=denszeta+Vectau(1)*b1_zeta*exp(b1_zeta*(Matdraw(:,T+1)-(Resqinit_zeta(:,1)'*MatAGE1')')).*...
    (Matdraw(:,T+1)<=(Resqinit_zeta(:,1)'*MatAGE1')')+...
    (1-Vectau(Ntau))*bL_zeta*exp(-bL_zeta*(Matdraw(:,T+1)-(Resqinit_zeta(:,Ntau)'*MatAGE1')')).*...
    (Matdraw(:,T+1)>(Resqinit_zeta(:,Ntau)'*MatAGE1')');


% prior, eta_0
dens2=zeros(N,T);

MatzetaAGE1=[];
for kk3zeta=0:K3zeta
    for kk3=0:K3
        MatzetaAGE1=[MatzetaAGE1 hermite(kk3zeta,(Matdraw(:,T+1)-meanY)/stdY).*hermite(kk3,(AGE(:,1)-meanAGE)/stdAGE)];
    end
end

for jtau=1:Ntau-1
    dens2(:,1)=dens2(:,1)+(Vectau(jtau+1)-Vectau(jtau))./((Resqinit_e0(:,jtau+1)-Resqinit_e0(:,jtau))'*MatzetaAGE1')'.*...
        (Matdraw(:,1)>(Resqinit_e0(:,jtau)'*MatzetaAGE1')').*(Matdraw(:,1)<=(Resqinit_e0(:,jtau+1)'*MatzetaAGE1')');
end

dens2(:,1)=dens2(:,1)+Vectau(1)*b1_e0*exp(b1_e0*(Matdraw(:,1)-(Resqinit_e0(:,1)'*MatzetaAGE1')')).*...
    (Matdraw(:,1)<=(Resqinit_e0(:,1)'*MatzetaAGE1')')+...
    (1-Vectau(Ntau))*bL_e0*exp(-bL_e0*(Matdraw(:,1)-(Resqinit_e0(:,Ntau)'*MatzetaAGE1')')).*...
    (Matdraw(:,1)>(Resqinit_e0(:,Ntau)'*MatzetaAGE1')');



% prior, eta_t
for tt=1:T-1
    Mat=zeros(N,(K1+1)*(K2+1));
    for kk1=0:K1
        for kk2=0:K2            
            Mat(:,kk1*(K2+1)+kk2+1)=hermite(kk1,(Matdraw(:,tt)-meanY)/stdY).*hermite(kk2,(AGE(:,tt+1)-meanAGE)/stdAGE);
        end
    end

    for jtau=1:Ntau-1
        dens2(:,tt+1)=dens2(:,tt+1)+(Vectau(jtau+1)-Vectau(jtau))./((Resqinit(:,jtau+1)-Resqinit(:,jtau))'*Mat')'.*...
            (Matdraw(:,tt+1)>(Resqinit(:,jtau)'*Mat')').*(Matdraw(:,tt+1)<=(Resqinit(:,jtau+1)'*Mat')');
    end
    
    dens2(:,tt+1)=dens2(:,tt+1)+Vectau(1)*b1*exp(b1*(Matdraw(:,tt+1)-(Resqinit(:,1)'*Mat')')).*...
        (Matdraw(:,tt+1)<=(Resqinit(:,1)'*Mat')')+...
        (1-Vectau(Ntau))*bL*exp(-bL*(Matdraw(:,tt+1)-(Resqinit(:,Ntau)'*Mat')')).*...
        (Matdraw(:,tt+1)>(Resqinit(:,Ntau)'*Mat')');
    
end

dens2tot=denszeta;
for tt=1:T
    dens2tot=dens2tot.*dens2(:,tt);
end




fval=denstot.*dens2tot;



end


