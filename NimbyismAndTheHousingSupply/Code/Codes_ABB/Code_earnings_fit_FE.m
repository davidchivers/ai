% Code for Arellano, Blundell and Bonhomme (2016), "Earnings and Consumption Dynamics: A Nonlinear Panel Data Framework"
% to appear in Econometrica

% This code simulates the earnings model with unobserved heterogeneity.

clear all
clc;

close all

global Vect Vect_dep xx bdw tau

load('data_hermite_FE.mat');

Resqtrue=Resqfinal;

Resqtrue_e0=Resqfinal_e0;

Resqtrue_eps=Resqfinal_eps;

Resqtrue_zeta=Resqfinal_zeta;

b1true=b1;
bLtrue=bL;
b1true_e0=b1_e0;
bLtrue_e0=bL_e0;
b1true_eps=b1_eps;
bLtrue_eps=bL_eps;
b1true_zeta=b1_zeta;
bLtrue_zeta=bL_zeta;

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


Y=kron(ones(Nsim,1),Y);

% Draws from the prior distribution of eta's and epsilon's

% seeds
rng('shuffle')

Mateta_true=zeros(N,T);

% zeta (household fixed-effect)

V_draw=unifrnd(0,1,N,1);

%First quantile
zeta_true=(MatAGE1*Resqtrue_zeta(:,1)).*(V_draw<=Vectau(1));
for jtau=2:Ntau
    zeta_true=zeta_true+((MatAGE1*(Resqtrue_zeta(:,jtau)-Resqtrue_zeta(:,jtau-1)))/(Vectau(jtau)-Vectau(jtau-1)).*...
        (V_draw-Vectau(jtau-1))+MatAGE1*Resqtrue_zeta(:,jtau-1)).*(V_draw>Vectau(jtau-1)).*(V_draw<=Vectau(jtau));
end
%Last quantile.
zeta_true=zeta_true+(MatAGE1*Resqtrue_zeta(:,Ntau)).*(V_draw>Vectau(Ntau));

% Laplace tails
zeta_true=zeta_true+((1/(b1true_zeta)*log(V_draw/Vectau(1))).*(V_draw<=Vectau(1))...
    -(1/bLtrue_zeta*log((1-V_draw)/(1-Vectau(Ntau)))).*(V_draw>Vectau(Ntau)));


% Proposal, eta_1
V_draw=unifrnd(0,1,N,1);

MatzetaAGE1=[];
for kk3zeta=0:K3zeta
    for kk3=0:K3
        MatzetaAGE1=[MatzetaAGE1 hermite(kk3zeta,(zeta_true-meanY)/stdY).*hermite(kk3,(kron(ones(Mdraws,1),AGE(:,1))-meanAGE)/stdAGE)];
    end
end

%First quantile
Mateta_true(:,1)=(MatzetaAGE1*Resqtrue_e0(:,1)).*(V_draw<=Vectau(1));
for jtau=2:Ntau
    Mateta_true(:,1)=Mateta_true(:,1)+((MatzetaAGE1*(Resqtrue_e0(:,jtau)-Resqtrue_e0(:,jtau-1)))/(Vectau(jtau)-Vectau(jtau-1)).*...
        (V_draw-Vectau(jtau-1))+MatzetaAGE1*Resqtrue_e0(:,jtau-1)).*(V_draw>Vectau(jtau-1)).*(V_draw<=Vectau(jtau));
end
%Last quantile.
Mateta_true(:,1)=Mateta_true(:,1)+(MatzetaAGE1*Resqtrue_e0(:,Ntau)).*(V_draw>Vectau(Ntau));

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

Ytilde=zeta_true*ones(1,T)+Mateta_true+Mateps_true;

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

% Persistence in the data (local quantile regression)

options.Display ='off';
warning off


Vect=Y(:,1:T-1);
Vect_dep=Y(:,2:T);
Vect0=quantile(Vect(:),Vectau);

bdw=(N*(T-1))^(-1/5);

Mat_loc=zeros(Ntau,Ntau);

for jtau=1:Ntau
    
    tau=Vectau(jtau);
    
    for jxx=1:Ntau
        xx=Vect0(jxx);
        
        res=fminunc(@fun_qrlocal,[0;0],options);
        Mat_loc(jxx,jtau)=res(2);
        
        
    end
    
end



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

VectS=quantile(VectS(:),Vectau);
MatS3=zeros(Ntau,1);
for kk1=1:K1
    
    mean(MatS2*ResP_Sdata)
    
    
    MatS3=[MatS3 kk1*hermite(kk1-1,(VectS(:)-meanY)/stdY)./stdY];
    
end

MatS3*ResP_Sdata

figure
surf(Vectau,Vectau,Mat3*ResP_data)
xlabel('percentile \tau_{shock}','FontSize',14)
ylabel('percentile \tau_{init}','FontSize',14)
zlabel('persistence','FontSize',14)
set(gca,'xlim',[0 1])
set(gca,'ylim',[0 1])
set(gca,'zlim',[0 1.2])
set(gca,'xtick',(0:0.2:1))
set(gca,'ytick',(0:0.2:1))
set(gca,'ztick',(0:0.2:1.2))



figure
surf(Vectau,Vectau,MatS3*ResP_Sdata)
xlabel('percentile \tau_{shock}','FontSize',14)
ylabel('percentile \tau_{init}','FontSize',14)
zlabel('persistence','FontSize',14)
set(gca,'xlim',[0 1])
set(gca,'ylim',[0 1])
set(gca,'zlim',[0 1.2])
set(gca,'xtick',(0:0.2:1))
set(gca,'ytick',(0:0.2:1))
set(gca,'ztick',(0:0.2:1.2))

figure
surf(Vectau,Vectau,Mat_loc)
axis([0 1 0 1 0 1.2])
xlabel('percentile \tau_{init}')
ylabel('percentile \tau_{shock}')
zlabel('persistence')




% Persistence of eta

Vect=Mateta_true(:,1:T-1);
    

Vect=quantile(Vect(:),Vectau);
age_ref=meanAGE;
Mat=zeros(Ntau,K2+1);
for kk1=1:K1
    for kk2=0:K2
        Mat=[Mat kk1*hermite(kk1-1,(Vect(:)-meanY)/stdY)./stdY.*hermite(kk2,(age_ref-meanAGE)/stdAGE)];
    end
end


Mat*Resqtrue

% Figure S15a
figure
surf(Vectau,Vectau,Mat*Resqtrue)
xlabel('percentile \tau_{shock}','FontSize',14)
ylabel('percentile \tau_{init}','FontSize',14)
zlabel('persistence','FontSize',14)
set(gca,'xlim',[0 1])
set(gca,'ylim',[0 1])
set(gca,'zlim',[0 1.2])
set(gca,'xtick',(0:0.2:1))
set(gca,'ytick',(0:0.2:1))
set(gca,'ztick',(0:0.2:1.2))

% Conditional skewness of eta

Vect=Mateta_true(:,1:T-1);
    

Vect=quantile(Vect(:),Vectau);
age_ref=meanAGE;
Matq=zeros(Ntau,0);
for kk1=0:K1
    for kk2=0:K2
        Matq=[Matq hermite(kk1,(Vect(:)-meanY)/stdY).*hermite(kk2,(age_ref-meanAGE)/stdAGE)];
    end
end

MM=Matq*Resqtrue

skew2=(MM(:,Ntau)+MM(:,1)-2*MM(:,(Ntau+1)/2))./(MM(:,Ntau)-MM(:,1))

% Conditional skewness of log-earnings (real data)

Vect_dep=Y(:,2:T);

Vect=Y(:,1:T-1);
Vect=quantile(Vect(:),Vectau);

Matqd=[];
for kk1=0:K1
    
        Matqd=[Matqd hermite(kk1,(Vect(:)-meanY)/stdY)];
    
end

MMd=Matqd*ResP_data

skew1=(MMd(:,Ntau)+MMd(:,1)-2*MMd(:,(Ntau+1)/2))./(MMd(:,Ntau)-MMd(:,1))


figure
plot(Vectau,skew1,'-','Linewidth',3,'Color','b')
xlabel('percentile y_{i,t-1}','FontSize',14)
ylabel('conditional skewness','FontSize',14)
set(gca,'xlim',[1/12 11/12])
set(gca,'ylim',[-.6 .6])
set(gca,'xtick',(.1:.1:.9))
set(gca,'ytick',(-.6:.2:.6))

% Figure S15b
figure
plot(Vectau,skew2,'-','Linewidth',3,'Color','b')
xlabel('percentile \eta_{i,t-1}','FontSize',14)
ylabel('conditional skewness','FontSize',14)
set(gca,'xlim',[1/12 11/12])
set(gca,'ylim',[-.6 .6])
set(gca,'xtick',(.1:.1:.9))
set(gca,'ytick',(-.6:.2:.6))







% Densities
[f_eta,xi]=ksdensity(Mateta_true(:));
figure
plot(xi,f_eta,'-','Linewidth',3,'Color','b')
set(gca,'xlim',[-2 2])
set(gca,'ylim',[0 1.4])
set(gca,'xtick',(-2:.4:2))
set(gca,'ytick',(0:.2:1.4))
xlabel('\eta component','FontSize',20)
ylabel('density','FontSize',20)




[f_eps,xi2]=ksdensity(Mateps_true(:));
figure
plot(xi2,f_eps,'-','Linewidth',3,'Color','b')
set(gca,'xlim',[-1 1])
set(gca,'ylim',[0 7])
set(gca,'xtick',(-1:.2:1))
set(gca,'ytick',(0:1:7))
xlabel('\epsilon component','FontSize',20)
ylabel('density','FontSize',20)


