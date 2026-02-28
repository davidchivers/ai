function fval=postr_nonlinear_consumption_age_hermite_predet(Matdraw)
global Y C A N T Ntau Vectau b1_eps bL_eps b1 bL b1_e0 bL_e0 K1 K2 M1 M2 M3 M4 M5 M6 R1 R2 R3 R4 R5 AGE MatAGE_t MatAGE1 meanAGE stdAGE...
    meanY stdY meanA stdA meanC stdC Resqfinal_eps Resqfinal Resqfinal_e0 Resinit Resinit_a1 Resinit_a2 b1_a bL_a 

Mat=Y(:,1:T)-Matdraw;
Vect=Mat(:);

%Likelihood of the Data
dens=zeros(N*T,1);
for jtau=1:Ntau-1 
    dens=dens+(Vectau(jtau+1)-Vectau(jtau))./((Resqfinal_eps(:,jtau+1)-Resqfinal_eps(:,jtau))'*MatAGE_t')'.*...
        (Vect>(Resqfinal_eps(:,jtau)'*MatAGE_t')').*(Vect<=(Resqfinal_eps(:,jtau+1)'*MatAGE_t')');
end

dens=dens+Vectau(1)*b1_eps*exp(b1_eps*(Vect-(Resqfinal_eps(:,1)'*MatAGE_t')')).*...
    (Vect<=(Resqfinal_eps(:,1)'*MatAGE_t')')+...
    (1-Vectau(Ntau))*bL_eps*exp(-bL_eps*(Vect-(Resqfinal_eps(:,Ntau)'*MatAGE_t')')).*...
    (Vect>(Resqfinal_eps(:,Ntau)'*MatAGE_t')');

denstot=ones(N,1);
for tt=1:T
    denstot=denstot.*dens((tt-1)*N+1:tt*N);
end


% prior, eta_0
dens2=zeros(N,T);
for jtau=1:Ntau-1
    dens2(:,1)=dens2(:,1)+(Vectau(jtau+1)-Vectau(jtau))./((Resqfinal_e0(:,jtau+1)-Resqfinal_e0(:,jtau))'*MatAGE1')'.*...
        (Matdraw(:,1)>(Resqfinal_e0(:,jtau)'*MatAGE1')').*(Matdraw(:,1)<=(Resqfinal_e0(:,jtau+1)'*MatAGE1')');
end

dens2(:,1)=dens2(:,1)+Vectau(1)*b1_e0*exp(b1_e0*(Matdraw(:,1)-(Resqfinal_e0(:,1)'*MatAGE1')')).*...
    (Matdraw(:,1)<=(Resqfinal_e0(:,1)'*MatAGE1')')+...
    (1-Vectau(Ntau))*bL_e0*exp(-bL_e0*(Matdraw(:,1)-(Resqfinal_e0(:,Ntau)'*MatAGE1')')).*...
    (Matdraw(:,1)>(Resqfinal_e0(:,Ntau)'*MatAGE1')');

% prior, eta_t
for tt=1:T-1
    Mat=zeros(N,(K1+1)*(K2+1));
    for kk1=0:K1
        for kk2=0:K2            
            Mat(:,kk1*(K2+1)+kk2+1)=hermite(kk1,(Matdraw(:,tt)-meanY)/stdY).*hermite(kk2,(AGE(:,tt+1)-meanAGE)/stdAGE);
        end
    end

    for jtau=1:Ntau-1
        dens2(:,tt+1)=dens2(:,tt+1)+(Vectau(jtau+1)-Vectau(jtau))./((Resqfinal(:,jtau+1)-Resqfinal(:,jtau))'*Mat')'.*...
            (Matdraw(:,tt+1)>(Resqfinal(:,jtau)'*Mat')').*(Matdraw(:,tt+1)<=(Resqfinal(:,jtau+1)'*Mat')');
    end
    
    dens2(:,tt+1)=dens2(:,tt+1)+Vectau(1)*b1*exp(b1*(Matdraw(:,tt+1)-(Resqfinal(:,1)'*Mat')')).*...
        (Matdraw(:,tt+1)<=(Resqfinal(:,1)'*Mat')')+...
        (1-Vectau(Ntau))*bL*exp(-bL*(Matdraw(:,tt+1)-(Resqfinal(:,Ntau)'*Mat')')).*...
        (Matdraw(:,tt+1)>(Resqfinal(:,Ntau)'*Mat')');
    
end

dens2tot=ones(N,1);
for tt=1:T
    dens2tot=dens2tot.*dens2(:,tt);
end



% Likelihood of the Consumption data

Mat=zeros(N,T);

for tt=1:T
    XX=[];
    for mm1=0:M1
        for mm2=0:M2
            for mm3=0:M3
                for mm4=0:M4
                    XX=[XX hermite(mm1,(A(:,tt)-meanA)/stdA).*hermite(mm2,(Matdraw(:,tt)-meanY)/stdY).*hermite(mm3,(Y(:,tt)-Matdraw(:,tt)-meanY)/stdY).*hermite(mm4,(AGE(:,tt)-meanAGE)/stdAGE)];
                end
            end
        end
    end
    
  
    
    Mat(:,tt)=C(:,tt)-XX*Resinit(1:(M1+1)*(M2+1)*(M3+1)*(M4+1),1);
end

dens3tot=ones(N,1);
for tt=1:T
    inter=1/sqrt(Resinit((M1+1)*(M2+1)*(M3+1)*(M4+1)+1))*normpdf(Mat(:,tt)/sqrt(Resinit((M1+1)*(M2+1)*(M3+1)*(M4+1)+1)));
    dens3tot=dens3tot.*inter;
end

% Likelihood of the initial assets

dens4=zeros(N,1);
Mat2=[];
for mm5=0:M5
    for mm6=0:M6
        Mat2=[Mat2 hermite(mm5,(Matdraw(:,1)-meanY)/stdY).*hermite(mm6,(AGE(:,1)-meanAGE)/stdAGE)];
    end
end


for jtau=1:Ntau-1
    dens4=dens4+(Vectau(jtau+1)-Vectau(jtau))./((Resinit_a1(:,jtau+1)-Resinit_a1(:,jtau))'*Mat2')'.*...
        (A(:,1)>(Resinit_a1(:,jtau)'*Mat2')').*(A(:,1)<=(Resinit_a1(:,jtau+1)'*Mat2')');
end

dens4=dens4+Vectau(1)*b1_a*exp(b1_a*(A(:,1)-(Resinit_a1(:,1)'*Mat2')')).*...
    (A(:,1)<=(Resinit_a1(:,1)'*Mat2')')+...
    (1-Vectau(Ntau))*bL_a*exp(-bL_a*(A(:,1)-(Resinit_a1(:,Ntau)'*Mat2')')).*...
    (A(:,1)>(Resinit_a1(:,Ntau)'*Mat2')');

dens4tot=dens4;

% Likelihood of the predetermined assets

Mat3=zeros(N,T-1);

for tt=2:T
    XXA=[];
    for mm1=0:R1
        for mm2=0:R2
            for mm3=0:R3
                for mm4=0:R4
                    for mm5=0:R5
                        XXA=[XXA hermite(mm1,(A(:,tt-1)-meanA)/stdA).*hermite(mm2,(C(:,tt-1)-meanC)/stdC).*hermite(mm3,(Y(:,tt-1)-meanY)/stdY)...
                            .*hermite(mm4,(Matdraw(:,tt-1)-meanY)/stdY).*hermite(mm5,(AGE(:,tt)-meanAGE)/stdAGE)];
                    end
                end
            end
        end
    end
    
    
    
    Mat3(:,tt-1)=A(:,tt)-XXA*Resinit_a2(1:(R1+1)*(R2+1)*(R3+1)*(R4+1)*(R5+1),1);
end

dens5tot=ones(N,1);
for tt=1:T-1
    inter=1/sqrt(Resinit_a2((R1+1)*(R2+1)*(R3+1)*(R4+1)*(R5+1)+1))*normpdf(Mat3(:,tt)/sqrt(Resinit_a2((R1+1)*(R2+1)*(R3+1)*(R4+1)*(R5+1)+1)));
    dens5tot=dens5tot.*inter;
end

fval=denstot.*dens2tot.*dens3tot.*dens4tot.*dens5tot;

end


