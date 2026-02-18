% Code for Arellano, Blundell and Bonhomme (2016), "Earnings and Consumption Dynamics: A Nonlinear Panel Data Framework"
% to appear in Econometrica

% This code estimates the earnings model with unobserved heterogeneity.

clear all
clc;

global Y Ytot_t tau Matdraw Matdraw_t Matdraw_tot Matdraw_lag MatAGE1_tot MatAGE_tot N T Ntau Vectau Resqinit_eps b1_eps bL_eps b1 bL b1_e0 bL_e0 Resqinit Resqinit_e0 K1 K2  K3 K3zeta...
    meanAGE stdAGE meanY stdY AGE MatAGE_t MatAGE1 b1_zeta bL_zeta Resqinit_zeta MatzetaAGE1_tot Matzeta_tot

data=load('first_stage_regs.out');

Y=data(:,1);

T=6;
N = size(Y,1)/T;

MatY=zeros(N,T);
for tt=1:T
    MatY(:,tt)=Y(tt:T:N*T);
end

Y=MatY;

AGE=data(:,4);
MatAGE=zeros(N,T);
for tt=1:T
    MatAGE(:,tt)=AGE(tt:T:N*T);
end

AGE=MatAGE;

meanAGE=mean(AGE(:));
stdAGE=std(AGE(:));



% Regression of earnings on a fourth order Hermite polynomial in age
XX=[];
for mm=0:4
    XX=[XX hermite(mm,(AGE(:)-meanAGE)/stdAGE)];
end
coeff=pinv(XX)*Y(:);
kappa=XX*coeff;
for tt=1:T
    Y(:,tt)=Y(:,tt)-kappa((tt-1)*N+1:tt*N);
end

Vectage=(25:1:60)';
XX1=[];
for mm=0:4
    XX1=[XX1 hermite(mm,(Vectage-meanAGE)/stdAGE)];
end
plot(Vectage,XX1*coeff)

meanY=mean(Y(:));
stdY=std(Y(:));


% seeds
rng('shuffle')

% Maximum Iteration
maxiter=100;

% Number of draws within the chain.
draws=200;

% Number of draws kept for computation.
Mdraws=1;


% Grid of tau's
Ntau=11;
Vectau=(1/(Ntau+1):1/(Ntau+1):Ntau/(Ntau+1))';

% Degree Hermite polynomials
K1=3;
K2=2;
K3zeta=1;
K3=1;
K4=1;
K5zeta=1;

% variance RW proposals
var_prop1=.08;
var_prop2=.03;
var_prop3=.03;
var_prop4=.03;
var_prop5=.03;
var_prop6=.05;
var_prop7=.02;


count=1;
deltapar=1;


% Initial conditions: eta_t given eta_t-1 and age

Resqinit=zeros((K1+1)*(K2+1),Ntau);
Y_t=Y(:,2);
for j=3:T
    Y_t=[Y_t;Y(:,j)];
end

AGE_t=AGE(:,2);
for j=3:T
    AGE_t=[AGE_t;AGE(:,j)];
end

Ylag=Y(:,1:T-1);
MatYlag=[];
for kk1=0:K1
    for kk2=0:K2
        MatYlag=[MatYlag hermite(kk1,(Ylag(:)-meanY)/stdY).*hermite(kk2,(AGE_t-meanAGE)/stdAGE)];
    end
end


    




for jtau=1:Ntau
    tau=Vectau(jtau);
    beta1=rq(MatYlag,Y_t+randn(N*(T-1),1),tau);
    Resqinit(1:(K1+1)*(K2+1),jtau)=beta1;
end

Resqinit0=Resqinit;

%plot(Vectau,[Resqinit(2,:)' Resqinit(3,:)'])

Ytot_t=kron(ones(Mdraws,1),Y(:,1));
for j=2:T
    Ytot_t=[Ytot_t;kron(ones(Mdraws,1),Y(:,j))];
end

MatAGE_t_tot=kron(ones(Mdraws,1),AGE_t(1:N,:));
for j=2:T-1
    MatAGE_t_tot=[MatAGE_t_tot;kron(ones(Mdraws,1),AGE_t((j-1)*N+1:j*N,:))];
end


% Initial conditions: eta1 given zeta and age1

Resqinit_e0=zeros((K3zeta+1)*(K3+1),Ntau);

MatzetaAGE1=[];
for kk3zeta=0:K3zeta
    for kk3=0:K3
        MatzetaAGE1=[MatzetaAGE1 hermite(kk3zeta,(mean(Y')'-meanY)/stdY).*hermite(kk3,(AGE(:,1)-meanAGE)/stdAGE)];
    end
end

for jtau=1:Ntau
    tau=Vectau(jtau);
    beta1=rq(MatzetaAGE1,Y(:,1)+randn(N,1),tau);
    Resqinit_e0(1:(K3zeta+1)*(K3+1),jtau)=beta1;
end



% Initial conditions: epsilon given AGE

Resqinit_eps=zeros(K4+1,Ntau);


MatAGE_t=[];
for kk4=0:K4
    MatAGE_t=[MatAGE_t hermite(kk4,(AGE(:)-meanAGE)/stdAGE)];
end

for jtau=1:Ntau
    tau=Vectau(jtau);
    beta1=rq(MatAGE_t,Y(:)+randn(N*T,1),tau);
    Resqinit_eps(1:K4+1,jtau)=beta1;
end


MatAGE_tot=kron(ones(Mdraws,1),MatAGE_t(1:N,:));
for j=2:T
    MatAGE_tot=[MatAGE_tot;kron(ones(Mdraws,1),MatAGE_t((j-1)*N+1:j*N,:))];
end


% Initial conditions: zeta (household fixed-effect) given age1
Resqinit_zeta=zeros(K5zeta+1,Ntau);

MatAGE1=[];
for kk5zeta=0:K5zeta
    MatAGE1=[MatAGE1 hermite(kk5zeta,(AGE(:,1)-meanAGE)/stdAGE)];
end

for jtau=1:Ntau
    tau=Vectau(jtau);
    beta1=rq(MatAGE1,mean(Y')',tau);
    Resqinit_zeta(1:K5zeta+1,jtau)=beta1;
end


MatAGE1_tot=kron(ones(Mdraws,1),MatAGE1);

Resqnew=zeros((K1+1)*(K2+1),Ntau,maxiter);
Resqnew_e0=zeros((K3zeta+1)*(K3+1),Ntau,maxiter);
Resqnew_eps=zeros(K4+1,Ntau,maxiter);
Resqnew_zeta=zeros(K5zeta+1,Ntau,maxiter);

init=randn(N,T+1);

b1=10*rand(1);
bL=10*rand(1);
b1_e0=10*rand(1);
bL_e0=10*rand(1);
b1_eps=10*rand(1);
bL_eps=10*rand(1);
b1_zeta=10*rand(1);
bL_zeta=10*rand(1);


b1init=b1;
bLinit=bL;
b1init_e0=b1_e0;
bLinit_e0=bL_e0;
b1init_eps=b1_eps;
bLinit_eps=bL_eps;
b1init_zeta=b1_zeta;
bLinit_zeta=bL_zeta;


Obj_chain = [postr_QRMCMC_age_hermite_FE(init) zeros(N,draws-1)];
Nu_chain1=ones(N,draws).*((init(:,1))*ones(1,draws));
Nu_chain2=ones(N,draws).*((init(:,2))*ones(1,draws));
Nu_chain3=ones(N,draws).*((init(:,3))*ones(1,draws));
Nu_chain4=ones(N,draws).*((init(:,4))*ones(1,draws));
Nu_chain5=ones(N,draws).*((init(:,5))*ones(1,draws));
Nu_chain6=ones(N,draws).*((init(:,6))*ones(1,draws));
Nu_chain7=ones(N,draws).*((init(:,7))*ones(1,draws));
acc1=zeros(N,draws);
acc2=zeros(N,draws);
acc3=zeros(N,draws);
acc4=zeros(N,draws);
acc5=zeros(N,draws);
acc6=zeros(N,draws);
acc7=zeros(N,draws);
acceptrate1=zeros(draws,1);
acceptrate2=zeros(draws,1);
acceptrate3=zeros(draws,1);
acceptrate4=zeros(draws,1);
acceptrate5=zeros(draws,1);
acceptrate6=zeros(draws,1);
acceptrate7=zeros(draws,1);
mat_b=zeros(maxiter,8);
mat_lik=zeros(maxiter,1);

for iter=1:maxiter
    iter
    
    %E step
    
    %%%%%%%%%%%%%%% Metropolis-Hastings %%%%%%%%%%%%%%%
    j = 2;
    while j <= draws
        
        
        Matdraw=zeros(N,T);
        
        Matdraw(:,1)=Nu_chain1(:,j-1);
        Matdraw(:,2)=Nu_chain2(:,j-1);
        Matdraw(:,3)=Nu_chain3(:,j-1);
        Matdraw(:,4)=Nu_chain4(:,j-1);
        Matdraw(:,5)=Nu_chain5(:,j-1);
        Matdraw(:,6)=Nu_chain6(:,j-1);
        Matdraw(:,7)=Nu_chain7(:,j-1);
        
        % eta_0
        Matdraw(:,1)=Nu_chain1(:,j-1)+sqrt(var_prop1)*randn(N,1);
        newObj=postr_QRMCMC_age_hermite_FE(Matdraw);
        r=(min([ones(N,1) newObj./Obj_chain(:,j-1)]'))';
        prob=rand(N,1);
        Obj_chain(:,j)=(prob<=r).*newObj+(prob>r).*Obj_chain(:,j-1);
        Nu_chain1(:,j)=(prob<=r).*Matdraw(:,1)+(prob>r).*Nu_chain1(:,j-1);
        Matdraw(:,1)=Nu_chain1(:,j);
        acc1(:,j)=(prob<=r);
        
        
        
        % eta_t
        Matdraw(:,2)=Nu_chain2(:,j-1)+sqrt(var_prop2)*randn(N,1);
        newObj=postr_QRMCMC_age_hermite_FE(Matdraw);
        r=(min([ones(N,1) newObj./Obj_chain(:,j)]'))';
        prob=rand(N,1);
        Obj_chain(:,j)=(prob<=r).*newObj+(prob>r).*Obj_chain(:,j);
        Nu_chain2(:,j)=(prob<=r).*Matdraw(:,2)+(prob>r).*Nu_chain2(:,j-1);
        Matdraw(:,2)=Nu_chain2(:,j);
        acc2(:,j)=(prob<=r);
        
        Matdraw(:,3)=Nu_chain3(:,j-1)+sqrt(var_prop3)*randn(N,1);
        newObj=postr_QRMCMC_age_hermite_FE(Matdraw);
        r=(min([ones(N,1) newObj./Obj_chain(:,j)]'))';
        prob=rand(N,1);
        Obj_chain(:,j)=(prob<=r).*newObj+(prob>r).*Obj_chain(:,j);
        Nu_chain3(:,j)=(prob<=r).*Matdraw(:,3)+(prob>r).*Nu_chain3(:,j-1);
        Matdraw(:,3)=Nu_chain3(:,j);
        acc3(:,j)=(prob<=r);
        
        Matdraw(:,4)=Nu_chain4(:,j-1)+sqrt(var_prop4)*randn(N,1);
        newObj=postr_QRMCMC_age_hermite_FE(Matdraw);
        r=(min([ones(N,1) newObj./Obj_chain(:,j)]'))';
        prob=rand(N,1);
        Obj_chain(:,j)=(prob<=r).*newObj+(prob>r).*Obj_chain(:,j);
        Nu_chain4(:,j)=(prob<=r).*Matdraw(:,4)+(prob>r).*Nu_chain4(:,j-1);
        Matdraw(:,4)=Nu_chain4(:,j);
        acc4(:,j)=(prob<=r);
        
        Matdraw(:,5)=Nu_chain5(:,j-1)+sqrt(var_prop5)*randn(N,1);
        newObj=postr_QRMCMC_age_hermite_FE(Matdraw);
        r=(min([ones(N,1) newObj./Obj_chain(:,j)]'))';
        prob=rand(N,1);
        Obj_chain(:,j)=(prob<=r).*newObj+(prob>r).*Obj_chain(:,j);
        Nu_chain5(:,j)=(prob<=r).*Matdraw(:,5)+(prob>r).*Nu_chain5(:,j-1);
        Matdraw(:,5)=Nu_chain5(:,j);
        acc5(:,j)=(prob<=r);
        
        Matdraw(:,6)=Nu_chain6(:,j-1)+sqrt(var_prop6)*randn(N,1);
        newObj=postr_QRMCMC_age_hermite_FE(Matdraw);
        r=(min([ones(N,1) newObj./Obj_chain(:,j)]'))';
        prob=rand(N,1);
        Obj_chain(:,j)=(prob<=r).*newObj+(prob>r).*Obj_chain(:,j);
        Nu_chain6(:,j)=(prob<=r).*Matdraw(:,6)+(prob>r).*Nu_chain6(:,j-1);
        Matdraw(:,6)=Nu_chain6(:,j);
        acc6(:,j)=(prob<=r);
        
        % zeta (household-specific fixed-effect)
        
        Matdraw(:,7)=Nu_chain7(:,j-1)+sqrt(var_prop7)*randn(N,1);
        newObj=postr_QRMCMC_age_hermite_FE(Matdraw);
        r=(min([ones(N,1) newObj./Obj_chain(:,j)]'))';
        prob=rand(N,1);
        Obj_chain(:,j)=(prob<=r).*newObj+(prob>r).*Obj_chain(:,j);
        Nu_chain7(:,j)=(prob<=r).*Matdraw(:,7)+(prob>r).*Nu_chain7(:,j-1);
        Matdraw(:,7)=Nu_chain7(:,j);
        acc7(:,j)=(prob<=r);
        
        
        acceptrate1(j)=mean(acc1(:,j));
        acceptrate2(j)=mean(acc2(:,j));
        acceptrate3(j)=mean(acc3(:,j));
        acceptrate4(j)=mean(acc4(:,j));
        acceptrate5(j)=mean(acc5(:,j));
        acceptrate6(j)=mean(acc6(:,j));
        acceptrate7(j)=mean(acc7(:,j));
        prtfrc = j/draws;
        j = j+1;
    end
    
    mean(acceptrate1)
    mean(acceptrate2)
    mean(acceptrate3)
    mean(acceptrate4)
    mean(acceptrate5)
    mean(acceptrate6)
    mean(acceptrate7)
    
    %Last draws of the chain will be the fixed associated with our data.
    Matdraw=[Nu_chain1(:,draws-20*(Mdraws-1)) Nu_chain2(:,draws-20*(Mdraws-1))...
        Nu_chain3(:,draws-20*(Mdraws-1)) Nu_chain4(:,draws-20*(Mdraws-1))...
        Nu_chain5(:,draws-20*(Mdraws-1)) Nu_chain6(:,draws-20*(Mdraws-1))...
        Nu_chain7(:,draws-20*(Mdraws-1))];
    
    for jj=2:Mdraws
        Matdraw=[Matdraw;[Nu_chain1(:,draws-20*(Mdraws-jj)) Nu_chain2(:,draws-20*(Mdraws-jj))...
            Nu_chain3(:,draws-20*(Mdraws-jj)) Nu_chain4(:,draws-20*(Mdraws-jj))...
            Nu_chain5(:,draws-20*(Mdraws-jj)) Nu_chain6(:,draws-20*(Mdraws-jj))...
            Nu_chain7(:,draws-20*(Mdraws-jj))]];
    end
    
    options.Display ='off';
    warning off
    
    Matdraw_t=Matdraw(:,2);
    for j=3:T
        Matdraw_t=[Matdraw_t;Matdraw(:,j)];
    end
    
    Matdraw_t_lag=Matdraw(:,1);
    for j=2:T-1
        Matdraw_t_lag=[Matdraw_t_lag;Matdraw(:,j)];
    end
    
    Matdraw_lag=[];
    for kk1=0:K1
        for kk2=0:K2
            Matdraw_lag=[Matdraw_lag hermite(kk1,(Matdraw_t_lag-meanY)/stdY).*hermite(kk2,(MatAGE_t_tot-meanAGE)/stdAGE)];
        end
    end
    
    
    Matdraw_tot=Matdraw(:,1);
    for j=2:T
        Matdraw_tot=[Matdraw_tot;Matdraw(:,j)];
    end
    
    Matzeta_tot=Matdraw(:,T+1);
    for j=2:T
        Matzeta_tot=[Matzeta_tot;Matdraw(:,T+1)];
    end  
    
    MatzetaAGE1_tot=[];
    for kk3zeta=0:K3zeta
        for kk3=0:K3
            MatzetaAGE1_tot=[MatzetaAGE1_tot hermite(kk3zeta,(Matdraw(:,T+1)-meanY)/stdY).*hermite(kk3,(kron(ones(Mdraws,1),AGE(:,1))-meanAGE)/stdAGE)];
        end
    end
    
    
    
    
    for jtau=1:Ntau
        
        tau=Vectau(jtau);
        
        Resqnew_zeta(:,jtau,iter)=fminunc(@wqregk_zeta_age,Resqinit_zeta(:,jtau),options);
        
        Resqnew_e0(:,jtau,iter)=fminunc(@wqregk_e0_age_FE,Resqinit_e0(:,jtau),options);
        
        Resqnew(:,jtau,iter)=fminunc(@wqregk_pt_age,Resqinit(:,jtau),options);
        
        Resqnew_eps(:,jtau,iter)=fminunc(@wqregk_eps_age_FE,Resqinit_eps(:,jtau),options);
        
    end
    
    % Normalization
    Resqnew_eps(:,:,iter)=Resqnew_eps(:,:,iter)-mean(Resqnew_eps(:,:,iter)')'*ones(1,Ntau);
    Resqnew_eps(1,:,iter)=Resqnew_eps(1,:,iter)-((1-Vectau(Ntau))/bL_eps-Vectau(1)/b1_eps)*ones(1,Ntau);
    Resqnew_zeta(:,:,iter)=Resqnew_zeta(:,:,iter)-mean(Resqnew_zeta(:,:,iter)')'*ones(1,Ntau);
    Resqnew_zeta(1,:,iter)=Resqnew_zeta(1,:,iter)-((1-Vectau(Ntau))/bL_zeta-Vectau(1)/b1_zeta)*ones(1,Ntau);  
    
    warning on
    
    % Laplace parameters: draws
    Vect1=Ytot_t-Matdraw_tot-Matzeta_tot-MatAGE_tot*Resqnew_eps(:,1,iter);
    Vect2=Ytot_t-Matdraw_tot-Matzeta_tot-MatAGE_tot*Resqnew_eps(:,Ntau,iter);
    b1_eps=-sum(Vect1<=0)/sum(Vect1.*(Vect1<=0));
    bL_eps=sum(Vect2>=0)/sum(Vect2.*(Vect2>=0));
    
    
    Vect1=Matdraw(:,1)-MatzetaAGE1_tot*Resqnew_e0(:,1,iter);
    Vect2=Matdraw(:,1)-MatzetaAGE1_tot*Resqnew_e0(:,Ntau,iter);
    b1_e0=-sum(Vect1<=0)/sum(Vect1.*(Vect1<=0));
    bL_e0=sum(Vect2>=0)/sum(Vect2.*(Vect2>=0));
    
    Vect1=Matdraw_t-Matdraw_lag*Resqnew(:,1,iter);
    Vect2=Matdraw_t-Matdraw_lag*Resqnew(:,Ntau,iter);
    b1=-sum(Vect1<=0)/sum(Vect1.*(Vect1<=0));
    bL=sum(Vect2>=0)/sum(Vect2.*(Vect2>=0));
    
    
    Vect1=Matdraw(:,T+1)-MatAGE1_tot*Resqnew_zeta(:,1,iter);
    Vect2=Matdraw(:,T+1)-MatAGE1_tot*Resqnew_zeta(:,Ntau,iter);
    b1_zeta=-sum(Vect1<=0)/sum(Vect1.*(Vect1<=0));
    bL_zeta=sum(Vect2>=0)/sum(Vect2.*(Vect2>=0));
    
      
    
    % Criterion
    
    
    Resqinit_e0=Resqnew_e0(:,:,iter)
    Resqinit_eps=Resqnew_eps(:,:,iter)
    Resqinit=Resqnew(:,:,iter)
    Resqinit_zeta=Resqnew_zeta(:,:,iter)
    
    mat_b(iter,1)=b1;
    mat_b(iter,2)=bL;
    mat_b(iter,3)=b1_e0;
    mat_b(iter,4)=bL_e0;
    mat_b(iter,5)=b1_eps;
    mat_b(iter,6)=bL_eps;
    mat_b(iter,7)=b1_zeta;
    mat_b(iter,8)=bL_zeta;
    
    
    % quick computation of persistence
    Vect=Matdraw(:,1:T-1);
    
    Mat=zeros(N*(T-1),K2+1);
    for kk1=1:K1
        for kk2=0:K2
            Mat=[Mat kk1*hermite(kk1-1,(Vect(:)-meanY)/stdY)./stdY.*hermite(kk2,(AGE_t-meanAGE)/stdAGE)];
        end
    end
    
    mean(Mat*Resqinit)
    
    Vect=Matdraw(:,1:T-1);
    Vect=quantile(Vect(:),Vectau);
    age_ref=meanAGE;
    Mat=zeros(Ntau,K2+1);
    for kk1=1:K1
        for kk2=0:K2
            Mat=[Mat kk1*hermite(kk1-1,(Vect(:)-meanY)/stdY)./stdY.*hermite(kk2,(age_ref-meanAGE)/stdAGE)];
        end
    end
    
    
    Mat*Resqinit
    
    % Complete-data likelihood
    
    mat_lik(iter)=mean(log(postr_QRMCMC_age_hermite_FE(Matdraw)));
    mat_lik(iter)
    
    Obj_chain= [Obj_chain(:,draws) zeros(N,draws-1)];
    Nu_chain1 = [Nu_chain1(:,draws) zeros(N,draws-1)];
    Nu_chain2 = [Nu_chain2(:,draws) zeros(N,draws-1)];
    Nu_chain3 = [Nu_chain3(:,draws) zeros(N,draws-1)];
    Nu_chain4 = [Nu_chain4(:,draws) zeros(N,draws-1)];
    Nu_chain5 = [Nu_chain5(:,draws) zeros(N,draws-1)];
    Nu_chain6 = [Nu_chain6(:,draws) zeros(N,draws-1)];
    Nu_chain7 = [Nu_chain7(:,draws) zeros(N,draws-1)];
    acc=zeros(N,draws);
    acceptrate=zeros(draws,1);
end






Resqfinal=zeros((K1+1)*(K2+1),Ntau);
for jtau=1:Ntau
    for p=1:(K1+1)*(K2+1)
        Resqfinal(p,jtau)=mean(Resqnew(p,jtau,(maxiter/2):maxiter));
    end
end

Resqfinal_e0=zeros((K3zeta+1)*(K3+1),Ntau);
for jtau=1:Ntau
    for p=1:(K3zeta+1)*(K3+1)
        Resqfinal_e0(p,jtau)=mean(Resqnew_e0(p,jtau,(maxiter/2):maxiter));
    end
end

Resqfinal_eps=zeros(K4+1,Ntau);
for jtau=1:Ntau
    for p=1:K4+1
        Resqfinal_eps(p,jtau)=mean(Resqnew_eps(p,jtau,(maxiter/2):maxiter));
    end
end

Resqfinal_zeta=zeros(K5zeta+1,Ntau);
for jtau=1:Ntau
    for p=1:K5zeta+1
        Resqfinal_zeta(p,jtau)=mean(Resqnew_zeta(p,jtau,(maxiter/2):maxiter));
    end
end

Resqfinal
Resqfinal_e0
Resqfinal_eps
Resqfinal_zeta

b1=mean(mat_b((maxiter/2):maxiter,1))
bL=mean(mat_b((maxiter/2):maxiter,2))
b1_e0=mean(mat_b((maxiter/2):maxiter,3))
bL_e0=mean(mat_b((maxiter/2):maxiter,4))
b1_eps=mean(mat_b((maxiter/2):maxiter,5))
bL_eps=mean(mat_b((maxiter/2):maxiter,6))
b1_zeta=mean(mat_b((maxiter/2):maxiter,7))
bL_zeta=mean(mat_b((maxiter/2):maxiter,8))

mean(mat_lik((maxiter/2):maxiter))

%save data_hermite_FE.mat
