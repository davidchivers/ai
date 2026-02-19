% Code for Arellano, Blundell and Bonhomme (2016), "Earnings and Consumption Dynamics: A Nonlinear Panel Data Framework"
% to appear in Econometrica

% This code simulates the consumption model in a model with unobserved heterogeneity

clear all
clc;

close all

load('data_hermite_cons_FE_newnorm.mat');

Resqtrue=Resqfinal;

Resqtrue_e0=Resqfinal_e0;

Resqtrue_eps=Resqfinal_eps;

b1true=b1;
bLtrue=bL;
b1true_e0=b1_e0;
bLtrue_e0=bL_e0;
b1true_eps=b1_eps;
bLtrue_eps=bL_eps;

Restrue=Resfinal;

Restrue_a1=Resfinal_a1;
Restrue_a2=Resfinal_a2;

b1true_a=b1_a;
bLtrue_a=bL_a;

Restrue_xi=Resfinal_xi;

b1true_xi=b1_xi;
bLtrue_xi=bL_xi;

% Expand the sample
Nsim=20;

% version 2.0
MatAGE_t=reshape(MatAGE_t,N,T,K4+1);
%

N=N*Nsim;
MatAGE1=kron(ones(Nsim,1),MatAGE1);
AGE=kron(ones(Nsim,1),AGE);

% version 2.0
Inter=[];
for kk4=0:K4

   Inter=[Inter kron(ones(Nsim,1),MatAGE_t(:,:,kk4+1))];
    
end

MatAGE_t=reshape(Inter,N*T,K4+1);
%

% version 1.0
%MatAGE_t=kron(ones(Nsim,1),MatAGE_t);
%

% check
%plot(AGE(:),MatAGE_t(:,2))

Mateta1=kron(ones(Nsim,1),Mateta1);
Y=kron(ones(Nsim,1),Y);
A=kron(ones(Nsim,1),A);
C=kron(ones(Nsim,1),C);



% Draws from the prior distribution of eta's and epsilon's

% seeds
rng('shuffle')

Mateta_true=zeros(N,T+1);

% Proposal, eta_1
V_draw=unifrnd(0,1,N,1);

%First quantile
Mateta_true(:,1)=(MatAGE1*Resqtrue_e0(:,1)).*(V_draw<=Vectau(1));
for jtau=2:Ntau
    Mateta_true(:,1)=Mateta_true(:,1)+((MatAGE1*(Resqtrue_e0(:,jtau)-Resqtrue_e0(:,jtau-1)))/(Vectau(jtau)-Vectau(jtau-1)).*...
        (V_draw-Vectau(jtau-1))+MatAGE1*Resqtrue_e0(:,jtau-1)).*(V_draw>Vectau(jtau-1)).*(V_draw<=Vectau(jtau));
end
%Last quantile.
Mateta_true(:,1)=Mateta_true(:,1)+(MatAGE1*Resqtrue_e0(:,Ntau)).*(V_draw>Vectau(Ntau));

% Laplace tails
Mateta_true(:,1)=Mateta_true(:,1)+((1/(b1true_e0)*log(V_draw/Vectau(1))).*(V_draw<=Vectau(1))...
    -(1/bLtrue_e0*log((1-V_draw)/(1-Vectau(Ntau)))).*(V_draw>Vectau(Ntau)));

% Proposal, eta_t
for tt=1:T-1
    Mat=zeros(N,(K1+1)*(K2+1));
    for kk1=0:K1
        for kk2=0:K2            
            Mat(:,kk1*(K2+1)+kk2+1)=hermite(kk1,(Mateta_true(:,tt)-meanY)/stdY).*hermite(kk2,(AGE(:,tt+1)-meanAGE)/stdAGE);
        end
    end
    V_draw=unifrnd(0,1,N,1);
    %First quantile
    Mateta_true(:,tt+1)=(Mat*Resqtrue(:,1)).*(V_draw<=Vectau(1));
    for jtau=2:Ntau
        Mateta_true(:,tt+1)=Mateta_true(:,tt+1)+...
            ((Mat*Resqtrue(:,jtau)-Mat*Resqtrue(:,jtau-1))/...
            (Vectau(jtau)-Vectau(jtau-1)).*...
            (V_draw-Vectau(jtau-1))+Mat*Resqtrue(:,jtau-1)).*...
            (V_draw>Vectau(jtau-1)).*(V_draw<=Vectau(jtau));
    end
    %Last quantile.
    Mateta_true(:,tt+1)=Mateta_true(:,tt+1)+(Mat*Resqtrue(:,Ntau)).*...
        (V_draw>Vectau(Ntau));
    
    % Laplace tails
    Mateta_true(:,tt+1)=Mateta_true(:,tt+1)+((1/(b1true)*log(V_draw/Vectau(1))).*(V_draw<=Vectau(1))...
        -(1/bLtrue*log((1-V_draw)/(1-Vectau(Ntau)))).*(V_draw>Vectau(Ntau)));
    
    % Restrict support of simulated eta's
    pmax=3*max(Y(:,tt+1));
    pmin=3*min(Y(:,tt+1));
    Mateta_true(:,tt+1)=Mateta_true(:,tt+1).*(Mateta_true(:,tt+1)<=pmax).*(Mateta_true(:,tt+1)>=pmin)+...
        pmax*(Mateta_true(:,tt+1)>pmax)+pmin*(Mateta_true(:,tt+1)<pmin);
    
end



Mateps_true=zeros(N,T);

for tt=1:T
    % Proposal, eta_0
    V_draw=unifrnd(0,1,N,1);
    
    %First quantile
    Mateps_true(:,tt)=(MatAGE_t((tt-1)*N+1:tt*N,:)*Resqtrue_eps(:,1)).*(V_draw<=Vectau(1));
    for jtau=2:Ntau
        Mateps_true(:,tt)=Mateps_true(:,tt)+((MatAGE_t((tt-1)*N+1:tt*N,:)*(Resqtrue_eps(:,jtau)-Resqtrue_eps(:,jtau-1)))/(Vectau(jtau)-Vectau(jtau-1)).*...
            (V_draw-Vectau(jtau-1))+MatAGE_t((tt-1)*N+1:tt*N,:)*Resqtrue_eps(:,jtau-1)).*(V_draw>Vectau(jtau-1)).*(V_draw<=Vectau(jtau));
    end
    %Last quantile.
    Mateps_true(:,tt)=Mateps_true(:,tt)+(MatAGE_t((tt-1)*N+1:tt*N,:)*Resqtrue_eps(:,Ntau)).*(V_draw>Vectau(Ntau));
    
    % Laplace tails
    Mateps_true(:,tt)=Mateps_true(:,tt)+((1/(b1true_eps)*log(V_draw/Vectau(1))).*(V_draw<=Vectau(1))...
        -(1/bLtrue_eps*log((1-V_draw)/(1-Vectau(Ntau)))).*(V_draw>Vectau(Ntau)));
    
end

% Earnings

Ytilde=Mateta_true(:,1:T)+Mateps_true;


% Initial assets

Mateta1=[];
for mm5=0:M5
    for mm6=0:M6
        Mateta1=[Mateta1 hermite(mm5,(Mateta_true(:,1)-meanY)/stdY).*hermite(mm6,(AGE(:,1)-meanAGE)/stdAGE)];
    end
end

Atilde=zeros(N,T);

% Proposal, a1
V_draw=unifrnd(0,1,N,1);

%First quantile
Atilde(:,1)=(Mateta1*Restrue_a1(:,1)).*(V_draw<=Vectau(1));
for jtau=2:Ntau
    Atilde(:,1)=Atilde(:,1)+((Mateta1*(Restrue_a1(:,jtau)-Restrue_a1(:,jtau-1)))/(Vectau(jtau)-Vectau(jtau-1)).*...
        (V_draw-Vectau(jtau-1))+Mateta1*Restrue_a1(:,jtau-1)).*(V_draw>Vectau(jtau-1)).*(V_draw<=Vectau(jtau));
end
%Last quantile.
Atilde(:,1)=Atilde(:,1)+(Mateta1*Restrue_a1(:,Ntau)).*(V_draw>Vectau(Ntau));

% Laplace tails
Atilde(:,1)=Atilde(:,1)+((1/(b1true_a)*log(V_draw/Vectau(1))).*(V_draw<=Vectau(1))...
    -(1/bLtrue_a*log((1-V_draw)/(1-Vectau(Ntau)))).*(V_draw>Vectau(Ntau)));


% Household-specific effects

Mata1eta1=[]
for mm7=0:M7
    for mm8=0:M8
        for mm9=0:M9
            Mata1eta1=[Mata1eta1 hermite(mm7,(Atilde(:,1)-meanA)/stdA).*hermite(mm8,(Mateta_true(:,1)-meanY)/stdY).*hermite(mm9,(AGE(:,1)-meanAGE)/stdAGE)];
        end
    end
end

% Proposal
V_draw=unifrnd(0,1,N,1);

%First quantile
Mateta_true(:,T+1)=(Mata1eta1*Restrue_xi(:,1)).*(V_draw<=Vectau(1));
for jtau=2:Ntau
    Mateta_true(:,T+1)=Mateta_true(:,T+1)+((Mata1eta1*(Restrue_xi(:,jtau)-Restrue_xi(:,jtau-1)))/(Vectau(jtau)-Vectau(jtau-1)).*...
        (V_draw-Vectau(jtau-1))+Mata1eta1*Restrue_xi(:,jtau-1)).*(V_draw>Vectau(jtau-1)).*(V_draw<=Vectau(jtau));
end
%Last quantile.
Mateta_true(:,T+1)=Mateta_true(:,T+1)+(Mata1eta1*Restrue_xi(:,Ntau)).*(V_draw>Vectau(Ntau));

% Laplace tails
Mateta_true(:,T+1)=Mateta_true(:,T+1)+((1/(b1true_xi)*log(V_draw/Vectau(1))).*(V_draw<=Vectau(1))...
    -(1/bLtrue_xi*log((1-V_draw)/(1-Vectau(Ntau)))).*(V_draw>Vectau(Ntau)));





% Assets and consumption

Ctilde=zeros(N,T);
for tt=1:T
    XX=[];
    for mm1=0:M1
        for mm2=0:M2
            for mm3=0:M3
                for mm4=0:M4
                    for mmxi=0:Mxi
                        XX=[XX hermite(mm1,(Atilde(:,tt)-meanA)/stdA).*hermite(mm2,(Mateta_true(:,tt)-meanY)/stdY).*hermite(mm3,(Ytilde(:,tt)-Mateta_true(:,tt)-meanY)/stdY)...
                            .*hermite(mm4,(AGE(:,tt)-meanAGE)/stdAGE).*hermite(mmxi,(Mateta_true(:,T+1)-meanC)/stdC)];
              
                    end
                end
            end
        end
    end
    
    Ctilde(:,tt)=XX*Restrue(1:(M1+1)*(M2+1)*(M3+1)*(M4+1)*(Mxi+1),1)+sqrt(Restrue((M1+1)*(M2+1)*(M3+1)*(M4+1)*(Mxi+1)+1))*randn(N,1);
    
    % Restrict support of simulated consumption
    rmax=max(C(:,tt));
    rmin=min(C(:,tt));
    Ctilde(:,tt)=Ctilde(:,tt).*(Ctilde(:,tt)<=rmax).*(Ctilde(:,tt)>=rmin)+...
        rmax*(Ctilde(:,tt)>rmax)+rmin*(Ctilde(:,tt)<rmin);
    
    if tt<=T-1
        
        XXA=[];
        for mm1=0:R1
            for mm2=0:R2
                for mm3=0:R3
                    for mm4=0:R4
                        for mm5=0:R5
                            for mm6=0:R6
                                XXA=[XXA hermite(mm1,(Atilde(:,tt)-meanA)/stdA).*hermite(mm2,(Ctilde(:,tt)-meanC)/stdC).*hermite(mm3,(Ytilde(:,tt)-meanY)/stdY)...
                                    .*hermite(mm4,(Mateta_true(:,tt)-meanY)/stdY).*hermite(mm5,(Mateta_true(:,T+1)-meanC)/stdC).*hermite(mm6,(AGE(:,tt+1)-meanAGE)/stdAGE)];
                            end
                        end
                    end
                end
            end
        end
        
        
        Atilde(:,tt+1)=XXA*Restrue_a2(1:(R1+1)*(R2+1)*(R3+1)*(R4+1)*(R5+1)*(R6+1),1)+sqrt(Restrue_a2((R1+1)*(R2+1)*(R3+1)*(R4+1)*(R5+1)*(R6+1)+1,1))*randn(N,1);
        
        % Restrict support of simulated assets
        mmax=max(A(:,tt+1));
        mmin=min(A(:,tt+1));
        Atilde(:,tt+1)=Atilde(:,tt+1).*(Atilde(:,tt+1)<=mmax).*(Atilde(:,tt+1)>=mmin)+...
            mmax*(Atilde(:,tt+1)>mmax)+mmin*(Atilde(:,tt+1)<mmin);
        
    end
end

% Persistence in the data

Vect=Y(:,1:T-1);
Vect_dep=Y(:,2:T);

Mat1=[];
for kk1=0:K1
    
        Mat1=[Mat1 hermite(kk1,(Vect(:)-meanY)/stdY)];
    
end

ResP_data=zeros((K1+1),Ntau);

for jtau=1:Ntau
    
    tau=Vectau(jtau);
    
    ResP_data(:,jtau)=rq(Mat1,Vect_dep(:),tau);
    
end

Mat2=zeros(N*(T-1),1);
for kk1=1:K1
    
        Mat2=[Mat2 kk1*hermite(kk1-1,(Vect(:)-meanY)/stdY)./stdY];
    
end

mean(Mat2*ResP_data)

Vect=quantile(Vect(:),Vectau);
Mat3=zeros(Ntau,1);
for kk1=1:K1
    
        Mat3=[Mat3 kk1*hermite(kk1-1,(Vect(:)-meanY)/stdY)./stdY];
   
end

Mat3*ResP_data
    
% Persistence in the simulated data

VectS=Ytilde(:,1:T-1);
VectS_dep=Ytilde(:,2:T);

MatS1=[];
for kk1=0:K1
    
        MatS1=[MatS1 hermite(kk1,(VectS(:)-meanY)/stdY)];
    
end

ResP_Sdata=zeros((K1+1),Ntau);

for jtau=1:Ntau
    
    tau=Vectau(jtau);
    
    ResP_Sdata(:,jtau)=rq(MatS1,VectS_dep(:),tau);
    
end

MatS2=zeros(N*(T-1),1);
for kk1=1:K1
    
        MatS2=[MatS2 kk1*hermite(kk1-1,(VectS(:)-meanY)/stdY)./stdY];
    
end

mean(MatS2*ResP_Sdata)

VectS=quantile(VectS(:),Vectau);
MatS3=zeros(Ntau,1);
for kk1=1:K1
    
        MatS3=[MatS3 kk1*hermite(kk1-1,(VectS(:)-meanY)/stdY)./stdY];
   
end

MatS3*ResP_Sdata



%  Computation of insurance (eta)

Vec1=quantile(Atilde(:),Vectau);
Vec2=quantile(AGE(:),Vectau);

Vecteta_true=Mateta_true(:,1:T);
Vecteta_true=Vecteta_true(:);

Vectxi_true=kron(ones(T,1),Mateta_true(:,T+1));

Mat_insurance=zeros(Ntau,Ntau);

for jtau1=1:Ntau
    for jtau2=1:Ntau
        XX1=[];
        for mm1=0:M1
            for mm2=0:M2
                if mm2==0
                    XX1=[XX1 zeros(N*Mdraws*T,(M3+1)*(M4+1)*(Mxi+1))];
                else
                    for mm3=0:M3
                        for mm4=0:M4
                            for mmxi=0:Mxi
                                XX1=[XX1 hermite(mm1,(Vec1(jtau1)-meanA)/stdA).*mm2./stdY.*hermite(mm2-1,(Vecteta_true-meanY)/stdY).*hermite(mm3,(Mateps_true(:)-meanY)/stdY)...
                                    .*hermite(mm4,(Vec2(jtau2)-meanAGE)/stdAGE).*hermite(mmxi,(Vectxi_true-meanC)/stdC)];
                            end
                        end
                    end
                end
            end
        end
        
        Mat_insurance(jtau1,jtau2)=mean(XX1*Restrue(1:(M1+1)*(M2+1)*(M3+1)*(M4+1)*(Mxi+1),1));
    end
end

% Figure S24c
figure
surf(Vectau,Vectau,Mat_insurance)
xlabel('percentile \tau_{age}','FontSize',14)
ylabel('percentile \tau_{assets}','FontSize',14)
zlabel('consumption response','FontSize',14)
set(gca,'xlim',[0 1])
set(gca,'ylim',[0 1])
set(gca,'zlim',[0 .5])
set(gca,'xtick',(0:0.2:1))
set(gca,'ytick',(0:0.2:1))
set(gca,'ztick',(0:.1:.5))




%  Computation of insurance (eps)

Vec1=quantile(Atilde(:),Vectau);
Vec2=quantile(AGE(:),Vectau);

Mat_insurance2=zeros(Ntau,Ntau);

for jtau1=1:Ntau
    for jtau2=1:Ntau
        
        XX2=[];
        for mm1=0:M1
            for mm2=0:M2
                for mm3=0:M3
                    if mm3==0
                        XX2=[XX2 zeros(N*Mdraws*T,(M4+1)*(Mxi+1))];
                    else
                        for mm4=0:M4
                            for mmxi=0:Mxi
                            XX2=[XX2 hermite(mm1,(Vec1(jtau1)-meanA)/stdA).*hermite(mm2,(Vecteta_true-meanY)/stdY).*mm3./stdY.*hermite(mm3-1,(Mateps_true(:)-meanY)/stdY)...
                                .*hermite(mm4,(Vec2(jtau2)-meanAGE)/stdAGE).*hermite(mmxi,(Vectxi_true-meanC)/stdC)];
                            end
                        end
                    end
                end
                
            end
        end
     
        
        Mat_insurance2(jtau1,jtau2)=mean(XX2*Restrue(1:(M1+1)*(M2+1)*(M3+1)*(M4+1)*(Mxi+1),1));
    end
end

% Figure S21b
figure
surf(Vectau,Vectau,Mat_insurance2)
xlabel('percentile \tau_{age}','FontSize',14)
ylabel('percentile \tau_{assets}','FontSize',14)
zlabel('consumption response','FontSize',14)
set(gca,'xlim',[0 1])
set(gca,'ylim',[0 1])
set(gca,'zlim',[-1 1])
set(gca,'xtick',(0:0.2:1))
set(gca,'ytick',(0:0.2:1))
set(gca,'ztick',(-1:.2:1))

% Consumption regression in the data

XX=[];
for mm1=0:M1
    for mm2=0:M2
        for mm4=0:M4
            XX=[XX hermite(mm1,(A(:)-meanA)/stdA).*hermite(mm2,(Y(:)-meanY)/stdY).*hermite(mm4,(AGE(:)-meanAGE)/stdAGE)];
        end
    end
end

par_C=pinv(XX)*C(:);

Vec1=quantile(A(:),Vectau);
Vec2=quantile(AGE(:),Vectau);

Mat_consreg=zeros(Ntau,Ntau);

for jtau1=1:Ntau
    for jtau2=1:Ntau
        XX1=[];
        for mm1=0:M1
            for mm2=0:M2
                if mm2==0
                    XX1=[XX1 zeros(N*T,(M4+1))];
                else
                  
                        for mm4=0:M4
                            XX1=[XX1 hermite(mm1,(Vec1(jtau1)-meanA)/stdA).*mm2./stdY.*hermite(mm2-1,(Y(:)-meanY)/stdY).*hermite(mm4,(Vec2(jtau2)-meanAGE)/stdAGE)];
                        end
                  end
            end
        end
        
        Mat_consreg(jtau1,jtau2)=mean(XX1*par_C);
    end
end

figure
surf(Vectau,Vectau,Mat_consreg)
xlabel('percentile \tau_{age}','FontSize',14)
ylabel('percentile \tau_{assets}','FontSize',14)
zlabel('consumption response','FontSize',14)
set(gca,'xlim',[0 1])
set(gca,'ylim',[0 1])
set(gca,'zlim',[0 .8])
set(gca,'xtick',(0:0.2:1))
set(gca,'ytick',(0:0.2:1))
set(gca,'ztick',(0:.2:.8))


% Consumption regression in the simulated data

XX=[];
for mm1=0:M1
    for mm2=0:M2
        for mm4=0:M4
            XX=[XX hermite(mm1,(Atilde(:)-meanA)/stdA).*hermite(mm2,(Ytilde(:)-meanY)/stdY).*hermite(mm4,(AGE(:)-meanAGE)/stdAGE)];
        end
    end
end

par_C=pinv(XX)*Ctilde(:);

Vec1=quantile(Atilde(:),Vectau);
Vec2=quantile(AGE(:),Vectau);

Mat_consreg2=zeros(Ntau,Ntau);

for jtau1=1:Ntau
    for jtau2=1:Ntau
        XX1=[];
        for mm1=0:M1
            for mm2=0:M2
                if mm2==0
                    XX1=[XX1 zeros(N*T,(M4+1))];
                else
                  
                        for mm4=0:M4
                            XX1=[XX1 hermite(mm1,(Vec1(jtau1)-meanA)/stdA).*mm2./stdY.*hermite(mm2-1,(Ytilde(:)-meanY)/stdY).*hermite(mm4,(Vec2(jtau2)-meanAGE)/stdAGE)];
                        end
                  end
            end
        end
        
        Mat_consreg2(jtau1,jtau2)=mean(XX1*par_C);
    end
end

% Figure S24b
figure
surf(Vectau,Vectau,Mat_consreg2)
xlabel('percentile \tau_{age}','FontSize',14)
ylabel('percentile \tau_{assets}','FontSize',14)
zlabel('consumption response','FontSize',14)
set(gca,'xlim',[0 1])
set(gca,'ylim',[0 1])
set(gca,'zlim',[.1 .4])
set(gca,'xtick',(0:0.2:1))
set(gca,'ytick',(0:0.2:1))
set(gca,'ztick',(.1:.1:.4))





%  Marginal propensity to consume out of assets

Vec1=quantile(Atilde(:),Vectau);
Vec2=quantile(AGE(:),Vectau);

Mat_MPC=zeros(Ntau,Ntau);

for jtau1=1:Ntau
    for jtau2=1:Ntau
        XX1=[];
        for mm1=0:M1
            if mm1==0
                    XX1=[XX1 zeros(N*Mdraws*T,(M2+1)*(M3+1)*(M4+1)*(Mxi+1))];
                else
            for mm2=0:M2
                
                    for mm3=0:M3
                        for mm4=0:M4
                            for mmxi=0:Mxi
                                XX1=[XX1 (mm1./stdA).*hermite(mm1-1,(Vec1(jtau1)-meanA)/stdA).*hermite(mm2,(Vecteta_true(:)-meanY)/stdY).*hermite(mm3,(Mateps_true(:)-meanY)/stdY)...
                                    .*hermite(mm4,(Vec2(jtau2)-meanAGE)/stdAGE).*hermite(mmxi,(Vectxi_true-meanC)/stdC)];
                            end
                        end
                    end
                end
            end
        end
        
        Mat_MPC(jtau1,jtau2)=mean(XX1*Restrue(1:(M1+1)*(M2+1)*(M3+1)*(M4+1)*(Mxi+1),1));
    end
end

% Figure S25c
figure
surf(Vectau,Vectau,Mat_MPC)
xlabel('percentile \tau_{age}','FontSize',14)
ylabel('percentile \tau_{assets}','FontSize',14)
zlabel('consumption response','FontSize',14)
set(gca,'xlim',[0 1])
set(gca,'ylim',[0 1])
set(gca,'zlim',[0 .3])
set(gca,'xtick',(0:0.2:1))
set(gca,'ytick',(0:0.2:1))
set(gca,'ztick',(0:0.1:.3))

% Consumption regression on assets in the data

XX=[];
for mm1=0:M1
    for mm2=0:M2
        for mm4=0:M4
            XX=[XX hermite(mm1,(A(:)-meanA)/stdA).*hermite(mm2,(Y(:)-meanY)/stdY).*hermite(mm4,(AGE(:)-meanAGE)/stdAGE)];
        end
    end
end

par_C=pinv(XX)*C(:);

Vec1=quantile(A(:),Vectau);
Vec2=quantile(AGE(:),Vectau);

Mat_consreg3=zeros(Ntau,Ntau);

for jtau1=1:Ntau
    for jtau2=1:Ntau
        XX1=[];
        for mm1=0:M1
            if mm1==0
                XX1=[XX1 zeros(N*T,(M2+1)*(M4+1))];
            else
                for mm2=0:M2
                    
                    
                    for mm4=0:M4
                        XX1=[XX1 mm1./stdY.*hermite(mm1-1,(Vec1(jtau1)-meanA)/stdA).*hermite(mm2,(Y(:)-meanY)/stdY).*hermite(mm4,(Vec2(jtau2)-meanAGE)/stdAGE)];
                    end
                end
            end
        end
        
        Mat_consreg3(jtau1,jtau2)=mean(XX1*par_C);
    end
end


figure
surf(Vectau,Vectau,Mat_consreg3)
xlabel('percentile \tau_{age}','FontSize',14)
ylabel('percentile \tau_{assets}','FontSize',14)
zlabel('consumption response','FontSize',14)
set(gca,'xlim',[0 1])
set(gca,'ylim',[0 1])
set(gca,'zlim',[0 .5])
set(gca,'xtick',(0:0.2:1))
set(gca,'ytick',(0:0.2:1))
set(gca,'ztick',(0:.1:.5))

% Consumption regression on assets in the simulated data

XX=[];
for mm1=0:M1
    for mm2=0:M2
        for mm4=0:M4
            XX=[XX hermite(mm1,(Atilde(:)-meanA)/stdA).*hermite(mm2,(Ytilde(:)-meanY)/stdY).*hermite(mm4,(AGE(:)-meanAGE)/stdAGE)];
        end
    end
end

par_C=pinv(XX)*Ctilde(:);

Vec1=quantile(Atilde(:),Vectau);
Vec2=quantile(AGE(:),Vectau);

Mat_consreg4=zeros(Ntau,Ntau);

for jtau1=1:Ntau
    for jtau2=1:Ntau
        XX1=[];
        for mm1=0:M1
             if mm1==0
                XX1=[XX1 zeros(N*T,(M2+1)*(M4+1))];
            else
            for mm2=0:M2
              
                  
                        for mm4=0:M4
                            XX1=[XX1 mm1./stdY.*hermite(mm1-1,(Vec1(jtau1)-meanA)/stdA).*hermite(mm2,(Ytilde(:)-meanY)/stdY).*hermite(mm4,(Vec2(jtau2)-meanAGE)/stdAGE)];
                        end
                  end
            end
        end
        
        Mat_consreg4(jtau1,jtau2)=mean(XX1*par_C);
    end
end

% Figure S25b
figure
surf(Vectau,Vectau,Mat_consreg4)
xlabel('percentile \tau_{age}','FontSize',14)
ylabel('percentile \tau_{assets}','FontSize',14)
zlabel('consumption response','FontSize',14)
set(gca,'xlim',[0 1])
set(gca,'ylim',[0 1])
set(gca,'zlim',[0 .5])
set(gca,'xtick',(0:0.2:1))
set(gca,'ytick',(0:0.2:1))
set(gca,'ztick',(0:.1:.5))


% Density of consumption in the data
[f,aa]=ksdensity(C(:));
muC=mean(C(:));
sigmaC=std(C(:));

figure
plot(aa,f,'-','Linewidth',3,'Color','b')
hold on 
plot(aa,normpdf((aa-muC)/sigmaC)/sigmaC,'--','Linewidth',2,'Color','g')
hold off
xlabel('log-consumption','FontSize',14)
ylabel('density','FontSize',14)
set(gca,'xlim',[-1.5 1.5])
set(gca,'ylim',[0 1.5])
set(gca,'xtick',(-1.5:.3:1.5))
set(gca,'ytick',(0:.3:1.5))


% Density of consumption in the simulated data

[f,aa]=ksdensity(Ctilde(:));
muC=mean(Ctilde(:));
sigmaC=std(Ctilde(:));

% Figure S20c
figure
plot(aa,f,'-','Linewidth',3,'Color','b')
hold on 
plot(aa,normpdf((aa-muC)/sigmaC)/sigmaC,'--','Linewidth',2,'Color','g')
hold off
xlabel('log-consumption','FontSize',14)
ylabel('density','FontSize',14)
set(gca,'xlim',[-1.5 1.5])
set(gca,'ylim',[0 1.5])
set(gca,'xtick',(-1.5:.3:1.5))
set(gca,'ytick',(0:.3:1.5))

