function fval=postr_nonlinear_consumption_age_hermite_FE_predet(Matdraw)
global Y C A N T Ntau Vectau b1_eps bL_eps b1 bL b1_e0 bL_e0 K1 K2 M1 M2 M3 M4 M5 M6 M7 M8 M9 R1 R2 R3 R4 R5 R6 Mxi AGE MatAGE_t MatAGE1 meanAGE stdAGE...
    meanY stdY meanA stdA meanC stdC Resqfinal_eps Resqfinal Resqfinal_e0 Resinit Resinit_a1 Resinit_a2 Resinit_xi b1_a bL_a b1_xi bL_xi

Mat=Y(:,1:T)-Matdraw(:,1:T);
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
                    for mmxi=0:Mxi
                        XX=[XX hermite(mm1,(A(:,tt)-meanA)/stdA).*hermite(mm2,(Matdraw(:,tt)-meanY)/stdY).*hermite(mm3,(Y(:,tt)-Matdraw(:,tt)-meanY)/stdY)...
                            .*hermite(mm4,(AGE(:,tt)-meanAGE)/stdAGE).*hermite(mmxi,(Matdraw(:,T+1)-meanC)/stdC)];
                    end
                end
            end
        end
    end
    
  
    
    Mat(:,tt)=C(:,tt)-XX*Resinit(1:(M1+1)*(M2+1)*(M3+1)*(M4+1)*(Mxi+1),1);
end

dens3tot=ones(N,1);
for tt=1:T
    inter=1/sqrt(Resinit((M1+1)*(M2+1)*(M3+1)*(M4+1)*(Mxi+1)+1))*normpdf(Mat(:,tt)/sqrt(Resinit((M1+1)*(M2+1)*(M3+1)*(M4+1)*(Mxi+1)+1)));
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
                        for mm6=0:R6
                            XXA=[XXA hermite(mm1,(A(:,tt-1)-meanA)/stdA).*hermite(mm2,(C(:,tt-1)-meanC)/stdC).*hermite(mm3,(Y(:,tt-1)-meanY)/stdY).*...
                                hermite(mm4,(Matdraw(:,tt-1)-meanY)/stdY).*hermite(mm5,(Matdraw(:,T+1)-meanC)/stdC).*hermite(mm6,(AGE(:,tt)-meanAGE)/stdAGE)];
                        end
                    end
                end
            end
        end
    end
    
   Mat3(:,tt-1)=A(:,tt)-XXA*Resinit_a2(1:(R1+1)*(R2+1)*(R3+1)*(R4+1)*(R5+1)*(R6+1),1);
end

dens5tot=ones(N,1);
for tt=1:T-1
    inter=1/sqrt(Resinit_a2((R1+1)*(R2+1)*(R3+1)*(R4+1)*(R5+1)*(R6+1)+1))*normpdf(Mat3(:,tt)/sqrt(Resinit_a2((R1+1)*(R2+1)*(R3+1)*(R4+1)*(R5+1)*(R6+1)+1)));
    dens5tot=dens5tot.*inter;
end



% Likelihood of the household-specific effects

dens6=zeros(N,1);
Mat3=[];
for mm7=0:M7
    for mm8=0:M8
        for mm9=0:M9
            Mat3=[Mat3 hermite(mm7,(A(:,1)-meanA)/stdA).*hermite(mm8,(Matdraw(:,1)-meanY)/stdY).*hermite(mm9,(AGE(:,1)-meanAGE)/stdAGE)];
        end
    end
end


for jtau=1:Ntau-1
    dens6=dens6+(Vectau(jtau+1)-Vectau(jtau))./((Resinit_xi(:,jtau+1)-Resinit_xi(:,jtau))'*Mat3')'.*...
        (Matdraw(:,T+1)>(Resinit_xi(:,jtau)'*Mat3')').*(Matdraw(:,T+1)<=(Resinit_xi(:,jtau+1)'*Mat3')');
end

dens6=dens6+Vectau(1)*b1_xi*exp(b1_xi*(Matdraw(:,T+1)-(Resinit_xi(:,1)'*Mat3')')).*...
    (Matdraw(:,T+1)<=(Resinit_xi(:,1)'*Mat3')')+...
    (1-Vectau(Ntau))*bL_xi*exp(-bL_xi*(Matdraw(:,T+1)-(Resinit_xi(:,Ntau)'*Mat3')')).*...
    (Matdraw(:,T+1)>(Resinit_xi(:,Ntau)'*Mat3')');

dens6tot=dens6;



fval=denstot.*dens2tot.*dens3tot.*dens4tot.*dens5tot.*dens6tot;

end


