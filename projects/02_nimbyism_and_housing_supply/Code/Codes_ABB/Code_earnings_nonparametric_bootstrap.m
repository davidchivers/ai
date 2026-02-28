% Code for Arellano, Blundell and Bonhomme (2016), "Earnings and Consumption Dynamics: A Nonlinear Panel Data Framework"
% to appear in Econometrica

% This code estimates the nonparametric bootstrap for earnings


clear all
clc;

global Y Ytot_t tau Matdraw Matdraw_t Matdraw_tot Matdraw_lag MatAGE1_tot MatAGE_tot N T Ntau Vectau Resqinit_eps b1_eps bL_eps b1 bL b1_e0 bL_e0 Resqinit Resqinit_e0 K1 K2 meanAGE stdAGE meanY stdY AGE MatAGE_t MatAGE1


Nboot=500;

% Grid of tau's
Ntau=11;
Vectau=(1/(Ntau+1):1/(Ntau+1):Ntau/(Ntau+1))';

% Degree Hermite polynomials
K1=3;
K2=2;
K3=2;
K4=2;


% True parameter values
load('data_hermite2.mat');
Resqtrue=Resqfinal;

Resqtrue_e0=Resqfinal_e0;

Resqtrue_eps=Resqfinal_eps;

b1true=b1;
bLtrue=bL;
b1true_e0=b1_e0;
bLtrue_e0=bL_e0;
b1true_eps=b1_eps;
bLtrue_eps=bL_eps;

Resqboot=zeros((K1+1)*(K2+1),Ntau,Nboot);
Resqboot_e0=zeros(K3+1,Ntau,Nboot);
Resqboot_eps=zeros(K4+1,Ntau,Nboot);
matb_boot=zeros(Nboot,6);

Resboot_fit=zeros(Ntau,Ntau,Nboot);
Resboot_fit_simul=zeros(Ntau,Ntau,Nboot);
Resboot_eta=zeros(Ntau,Ntau,Nboot);
Resboot_skew_y=zeros(Ntau,Nboot);
Resboot_skew_eta=zeros(Ntau,Nboot);

jboot=1;

while jboot<=Nboot
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Draw a sample from the data, sampling entire sequence of household
    % observations %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    data=load('C:\Dfile\Dossiers\matlab\Qpanel\QPanel_raffaele\first_stage_regs.out');
    
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
    
    
    RDraw=floor(N*rand(N,1))+1;
    Y=Y(RDraw,:);
    AGE=AGE(RDraw,:);
    
    
    
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
    
   
    
    %%%%%%%%%%%%%%%%%%%%
    % Estimate the model
    %%%%%%%%%%%%%%%%%%%%
    
    % Maximum Iteration
    maxiter=60;
    
    % Number of draws within the chain.
    draws=100;
    
    % Number of draws kept for computation.
    Mdraws=1;
    
    
   
    
    % variance RW proposals
    var_prop1=.08;
    var_prop2=.03;
    var_prop3=.03;
    var_prop4=.03;
    var_prop5=.03;
    var_prop6=.05;
    
    
    count=1;
    deltapar=1;
    
    
    % Initial conditions: eta_t given eta_t-1 and age
    
    Resqinit=Resqtrue.*(1+.05*(2*rand((K1+1)*(K2+1),Ntau)-1));
    
    Ytot_t=kron(ones(Mdraws,1),Y(:,1));
    for j=2:T
        Ytot_t=[Ytot_t;kron(ones(Mdraws,1),Y(:,j))];
    end
    
    MatAGE_t_tot=kron(ones(Mdraws,1),AGE_t(1:N,:));
    for j=2:T-1
        MatAGE_t_tot=[MatAGE_t_tot;kron(ones(Mdraws,1),AGE_t((j-1)*N+1:j*N,:))];
    end
    
    
    % Initial conditions: eta1 given age1
    
    Resqinit_e0=Resqtrue_e0.*(1+.05*(2*rand(K3+1,Ntau)-1));
    
    MatAGE1=[];
    for kk3=0:K3
        MatAGE1=[MatAGE1 hermite(kk3,(AGE(:,1)-meanAGE)/stdAGE)];
    end
    
    
    MatAGE1_tot=kron(ones(Mdraws,1),MatAGE1);
    
    % Initial conditions: epsilon given AGE
    
    Resqinit_eps=Resqtrue_eps.*(1+.05*(2*rand(K4+1,Ntau)-1));
    
    
    MatAGE_t=[];
    for kk4=0:K4
        MatAGE_t=[MatAGE_t hermite(kk4,(AGE(:)-meanAGE)/stdAGE)];
    end
    
    
    
    MatAGE_tot=kron(ones(Mdraws,1),MatAGE_t(1:N,:));
    for j=2:T
        MatAGE_tot=[MatAGE_tot;kron(ones(Mdraws,1),MatAGE_t((j-1)*N+1:j*N,:))];
    end
    
    
    
    Resqnew=zeros((K1+1)*(K2+1),Ntau,maxiter);
    Resqnew_e0=zeros(K3+1,Ntau,maxiter);
    Resqnew_eps=zeros(K4+1,Ntau,maxiter);
    
    init=randn(N,T);
    
    b1=b1true*(1+.2*(2*rand(1,1)-1));
    bL=bLtrue*(1+.2*(2*rand(1,1)-1));
    b1_e0=b1true_e0*(1+.2*(2*rand(1,1)-1));
    bL_e0=bLtrue_e0*(1+.2*(2*rand(1,1)-1));
    b1_eps=b1true_eps*(1+.2*(2*rand(1,1)-1));
    bL_eps=bLtrue_eps*(1+.2*(2*rand(1,1)-1));
    
    
    
    b1init=b1;
    bLinit=bL;
    b1init_e0=b1_e0;
    bLinit_e0=bL_e0;
    b1init_eps=b1_eps;
    bLinit_eps=bL_eps;
    
    
    
    
    
    Obj_chain = [postr_QRMCMC_age_hermite(init) zeros(N,draws-1)];
    Nu_chain1=ones(N,draws).*((init(:,1))*ones(1,draws));
    Nu_chain2=ones(N,draws).*((init(:,2))*ones(1,draws));
    Nu_chain3=ones(N,draws).*((init(:,3))*ones(1,draws));
    Nu_chain4=ones(N,draws).*((init(:,4))*ones(1,draws));
    Nu_chain5=ones(N,draws).*((init(:,5))*ones(1,draws));
    Nu_chain6=ones(N,draws).*((init(:,6))*ones(1,draws));
    acc1=zeros(N,draws);
    acc2=zeros(N,draws);
    acc3=zeros(N,draws);
    acc4=zeros(N,draws);
    acc5=zeros(N,draws);
    acc6=zeros(N,draws);
    acceptrate1=zeros(draws,1);
    acceptrate2=zeros(draws,1);
    acceptrate3=zeros(draws,1);
    acceptrate4=zeros(draws,1);
    acceptrate5=zeros(draws,1);
    acceptrate6=zeros(draws,1);
    mat_b=zeros(maxiter,6);
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
            
            % eta_0
            Matdraw(:,1)=Nu_chain1(:,j-1)+sqrt(var_prop1)*randn(N,1);
            newObj=postr_QRMCMC_age_hermite(Matdraw);
            r=(min([ones(N,1) newObj./Obj_chain(:,j-1)]'))';
            prob=rand(N,1);
            Obj_chain(:,j)=(prob<=r).*newObj+(prob>r).*Obj_chain(:,j-1);
            Nu_chain1(:,j)=(prob<=r).*Matdraw(:,1)+(prob>r).*Nu_chain1(:,j-1);
            Matdraw(:,1)=Nu_chain1(:,j);
            acc1(:,j)=(prob<=r);
            
            
            
            % eta_t
            Matdraw(:,2)=Nu_chain2(:,j-1)+sqrt(var_prop2)*randn(N,1);
            newObj=postr_QRMCMC_age_hermite(Matdraw);
            r=(min([ones(N,1) newObj./Obj_chain(:,j)]'))';
            prob=rand(N,1);
            Obj_chain(:,j)=(prob<=r).*newObj+(prob>r).*Obj_chain(:,j);
            Nu_chain2(:,j)=(prob<=r).*Matdraw(:,2)+(prob>r).*Nu_chain2(:,j-1);
            Matdraw(:,2)=Nu_chain2(:,j);
            acc2(:,j)=(prob<=r);
            
            Matdraw(:,3)=Nu_chain3(:,j-1)+sqrt(var_prop3)*randn(N,1);
            newObj=postr_QRMCMC_age_hermite(Matdraw);
            r=(min([ones(N,1) newObj./Obj_chain(:,j)]'))';
            prob=rand(N,1);
            Obj_chain(:,j)=(prob<=r).*newObj+(prob>r).*Obj_chain(:,j);
            Nu_chain3(:,j)=(prob<=r).*Matdraw(:,3)+(prob>r).*Nu_chain3(:,j-1);
            Matdraw(:,3)=Nu_chain3(:,j);
            acc3(:,j)=(prob<=r);
            
            Matdraw(:,4)=Nu_chain4(:,j-1)+sqrt(var_prop4)*randn(N,1);
            newObj=postr_QRMCMC_age_hermite(Matdraw);
            r=(min([ones(N,1) newObj./Obj_chain(:,j)]'))';
            prob=rand(N,1);
            Obj_chain(:,j)=(prob<=r).*newObj+(prob>r).*Obj_chain(:,j);
            Nu_chain4(:,j)=(prob<=r).*Matdraw(:,4)+(prob>r).*Nu_chain4(:,j-1);
            Matdraw(:,4)=Nu_chain4(:,j);
            acc4(:,j)=(prob<=r);
            
            Matdraw(:,5)=Nu_chain5(:,j-1)+sqrt(var_prop5)*randn(N,1);
            newObj=postr_QRMCMC_age_hermite(Matdraw);
            r=(min([ones(N,1) newObj./Obj_chain(:,j)]'))';
            prob=rand(N,1);
            Obj_chain(:,j)=(prob<=r).*newObj+(prob>r).*Obj_chain(:,j);
            Nu_chain5(:,j)=(prob<=r).*Matdraw(:,5)+(prob>r).*Nu_chain5(:,j-1);
            Matdraw(:,5)=Nu_chain5(:,j);
            acc5(:,j)=(prob<=r);
            
            Matdraw(:,6)=Nu_chain6(:,j-1)+sqrt(var_prop6)*randn(N,1);
            newObj=postr_QRMCMC_age_hermite(Matdraw);
            r=(min([ones(N,1) newObj./Obj_chain(:,j)]'))';
            prob=rand(N,1);
            Obj_chain(:,j)=(prob<=r).*newObj+(prob>r).*Obj_chain(:,j);
            Nu_chain6(:,j)=(prob<=r).*Matdraw(:,6)+(prob>r).*Nu_chain6(:,j-1);
            Matdraw(:,6)=Nu_chain6(:,j);
            acc6(:,j)=(prob<=r);
            
            
            
            acceptrate1(j)=mean(acc1(:,j));
            acceptrate2(j)=mean(acc2(:,j));
            acceptrate3(j)=mean(acc3(:,j));
            acceptrate4(j)=mean(acc4(:,j));
            acceptrate5(j)=mean(acc5(:,j));
            acceptrate6(j)=mean(acc6(:,j));
            prtfrc = j/draws;
            j = j+1;
        end
        
        mean(acceptrate1)
        mean(acceptrate2)
        mean(acceptrate3)
        mean(acceptrate4)
        mean(acceptrate5)
        mean(acceptrate6)
        
        if min([mean(acceptrate1);mean(acceptrate2);mean(acceptrate3);mean(acceptrate4);mean(acceptrate5);mean(acceptrate6)])>.95
            
            jboot=jboot+1;
            
        else
            
            %Last draws of the chain will be the fixed associated with our data.
            Matdraw=[Nu_chain1(:,draws-20*(Mdraws-1)) Nu_chain2(:,draws-20*(Mdraws-1))...
                Nu_chain3(:,draws-20*(Mdraws-1)) Nu_chain4(:,draws-20*(Mdraws-1))...
                Nu_chain5(:,draws-20*(Mdraws-1)) Nu_chain6(:,draws-20*(Mdraws-1))];
            
            for jj=2:Mdraws
                Matdraw=[Matdraw;[Nu_chain1(:,draws-20*(Mdraws-jj)) Nu_chain2(:,draws-20*(Mdraws-jj))...
                    Nu_chain3(:,draws-20*(Mdraws-jj)) Nu_chain4(:,draws-20*(Mdraws-jj))...
                    Nu_chain5(:,draws-20*(Mdraws-jj)) Nu_chain6(:,draws-20*(Mdraws-jj))]];
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
            
            
            
            for jtau=1:Ntau
                
                tau=Vectau(jtau);
                
                Resqnew_e0(:,jtau,iter)=fminunc(@wqregk_e0_age,Resqinit_e0(:,jtau),options);
                
                Resqnew(:,jtau,iter)=fminunc(@wqregk_pt_age,Resqinit(:,jtau),options);
                
                Resqnew_eps(:,jtau,iter)=fminunc(@wqregk_eps_age,Resqinit_eps(:,jtau),options);
                
            end
            
            % Normalization
            Resqnew_eps(:,:,iter)=Resqnew_eps(:,:,iter)-mean(Resqnew_eps(:,:,iter)')'*ones(1,Ntau);
            Resqnew_eps(1,:,iter)=Resqnew_eps(1,:,iter)-((1-Vectau(Ntau))/bL_eps-Vectau(1)/b1_eps)*ones(1,Ntau);
            
            
            warning on
            
            % Laplace parameters: draws
            Vect1=Ytot_t-Matdraw_tot-MatAGE_tot*Resqnew_eps(:,1,iter);
            Vect2=Ytot_t-Matdraw_tot-MatAGE_tot*Resqnew_eps(:,Ntau,iter);
            b1_eps=-sum(Vect1<=0)/sum(Vect1.*(Vect1<=0));
            bL_eps=sum(Vect2>=0)/sum(Vect2.*(Vect2>=0));
            
            
            Vect1=Matdraw(:,1)-MatAGE1_tot*Resqnew_e0(:,1,iter);
            Vect2=Matdraw(:,1)-MatAGE1_tot*Resqnew_e0(:,Ntau,iter);
            b1_e0=-sum(Vect1<=0)/sum(Vect1.*(Vect1<=0));
            bL_e0=sum(Vect2>=0)/sum(Vect2.*(Vect2>=0));
            
            Vect1=Matdraw_t-Matdraw_lag*Resqnew(:,1,iter);
            Vect2=Matdraw_t-Matdraw_lag*Resqnew(:,Ntau,iter);
            b1=-sum(Vect1<=0)/sum(Vect1.*(Vect1<=0));
            bL=sum(Vect2>=0)/sum(Vect2.*(Vect2>=0));
            
            
            
            
            
            % Criterion
            
            
            Resqinit_e0=Resqnew_e0(:,:,iter)
            Resqinit_eps=Resqnew_eps(:,:,iter)
            Resqinit=Resqnew(:,:,iter)
            
            mat_b(iter,1)=b1;
            mat_b(iter,2)=bL;
            mat_b(iter,3)=b1_e0;
            mat_b(iter,4)=bL_e0;
            mat_b(iter,5)=b1_eps;
            mat_b(iter,6)=bL_eps;
            
            
            
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
            
            mat_lik(iter)=mean(log(postr_QRMCMC_age_hermite(Matdraw)));
            mat_lik(iter)
            
            
            
            Obj_chain= [Obj_chain(:,draws) zeros(N,draws-1)];
            Nu_chain1 = [Nu_chain1(:,draws) zeros(N,draws-1)];
            Nu_chain2 = [Nu_chain2(:,draws) zeros(N,draws-1)];
            Nu_chain3 = [Nu_chain3(:,draws) zeros(N,draws-1)];
            Nu_chain4 = [Nu_chain4(:,draws) zeros(N,draws-1)];
            Nu_chain5 = [Nu_chain5(:,draws) zeros(N,draws-1)];
            Nu_chain6 = [Nu_chain6(:,draws) zeros(N,draws-1)];
            acc=zeros(N,draws);
            acceptrate=zeros(draws,1);
        end
    end
    
    
    
    
    
    
    Resqfinal=zeros((K1+1)*(K2+1),Ntau);
    for jtau=1:Ntau
        for p=1:(K1+1)*(K2+1)
            Resqfinal(p,jtau)=mean(Resqnew(p,jtau,(maxiter/2):maxiter));
        end
    end
    
    Resqfinal_e0=zeros(K3+1,Ntau);
    for jtau=1:Ntau
        for p=1:K3+1
            Resqfinal_e0(p,jtau)=mean(Resqnew_e0(p,jtau,(maxiter/2):maxiter));
        end
    end
    
    Resqfinal_eps=zeros(K4+1,Ntau);
    for jtau=1:Ntau
        for p=1:K4+1
            Resqfinal_eps(p,jtau)=mean(Resqnew_eps(p,jtau,(maxiter/2):maxiter));
        end
    end
    
    Resqfinal
    Resqfinal_e0
    Resqfinal_eps
    
    b1=mean(mat_b((maxiter/2):maxiter,1))
    bL=mean(mat_b((maxiter/2):maxiter,2))
    b1_e0=mean(mat_b((maxiter/2):maxiter,3))
    bL_e0=mean(mat_b((maxiter/2):maxiter,4))
    b1_eps=mean(mat_b((maxiter/2):maxiter,5))
    bL_eps=mean(mat_b((maxiter/2):maxiter,6))
    
    mean(mat_lik((maxiter/2):maxiter))
    
    
    Resqboot(:,:,jboot)=Resqfinal;
    Resqboot_e0(:,:,jboot)=Resqfinal_e0;
    Resqboot_eps(:,:,jboot)=Resqfinal_eps;
    matb_boot(jboot,:)=[b1 bL b1_e0 bL_e0 b1_eps bL_eps];
    
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Simulate and compute fit
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    ResqtrueB=Resqfinal;
    
    ResqtrueB_e0=Resqfinal_e0;
    
    ResqtrueB_eps=Resqfinal_eps;
    
    b1trueB=b1;
    bLtrueB=bL;
    b1trueB_e0=b1_e0;
    bLtrueB_e0=bL_e0;
    b1trueB_eps=b1_eps;
    bLtrueB_eps=bL_eps;
    
    % Expand the sample
    Nsim=20;
    NB=N*Nsim;
    MatAGE1B=kron(ones(Nsim,1),MatAGE1);
    AGEB=kron(ones(Nsim,1),AGE);
    MatAGE_tB=kron(ones(Nsim,1),MatAGE_t);
    YB=kron(ones(Nsim,1),Y);
    
    
    % Draws from the prior distribution of eta's and epsilon's
    
    % seeds
    rng('shuffle')
    
    Mateta_trueB=zeros(NB,T);
    
    % Proposal, eta_1
    V_draw=unifrnd(0,1,NB,1);
    
    %First quantile
    Mateta_trueB(:,1)=(MatAGE1B*ResqtrueB_e0(:,1)).*(V_draw<=Vectau(1));
    for jtau=2:Ntau
        Mateta_trueB(:,1)=Mateta_trueB(:,1)+((MatAGE1B*(ResqtrueB_e0(:,jtau)-ResqtrueB_e0(:,jtau-1)))/(Vectau(jtau)-Vectau(jtau-1)).*...
            (V_draw-Vectau(jtau-1))+MatAGE1B*ResqtrueB_e0(:,jtau-1)).*(V_draw>Vectau(jtau-1)).*(V_draw<=Vectau(jtau));
    end
    %Last quantile.
    Mateta_trueB(:,1)=Mateta_trueB(:,1)+(MatAGE1B*ResqtrueB_e0(:,Ntau)).*(V_draw>Vectau(Ntau));
    
    % Laplace tails
    Mateta_trueB(:,1)=Mateta_trueB(:,1)+((1/(b1trueB_e0)*log(V_draw/Vectau(1))).*(V_draw<=Vectau(1))...
        -(1/bLtrueB_e0*log((1-V_draw)/(1-Vectau(Ntau)))).*(V_draw>Vectau(Ntau)));
    
    % Proposal, eta_t
    for tt=1:T-1
        Mat=zeros(NB,(K1+1)*(K2+1));
        for kk1=0:K1
            for kk2=0:K2
                Mat(:,kk1*(K2+1)+kk2+1)=hermite(kk1,(Mateta_trueB(:,tt)-meanY)/stdY).*hermite(kk2,(AGEB(:,tt+1)-meanAGE)/stdAGE);
            end
        end
        V_draw=unifrnd(0,1,NB,1);
        %First quantile
        Mateta_trueB(:,tt+1)=(Mat*ResqtrueB(:,1)).*(V_draw<=Vectau(1));
        for jtau=2:Ntau
            Mateta_trueB(:,tt+1)=Mateta_trueB(:,tt+1)+...
                ((Mat*ResqtrueB(:,jtau)-Mat*ResqtrueB(:,jtau-1))/...
                (Vectau(jtau)-Vectau(jtau-1)).*...
                (V_draw-Vectau(jtau-1))+Mat*ResqtrueB(:,jtau-1)).*...
                (V_draw>Vectau(jtau-1)).*(V_draw<=Vectau(jtau));
        end
        %Last quantile.
        Mateta_trueB(:,tt+1)=Mateta_trueB(:,tt+1)+(Mat*ResqtrueB(:,Ntau)).*...
            (V_draw>Vectau(Ntau));
        
        % Laplace tails
        Mateta_trueB(:,tt+1)=Mateta_trueB(:,tt+1)+((1/(b1trueB)*log(V_draw/Vectau(1))).*(V_draw<=Vectau(1))...
            -(1/bLtrueB*log((1-V_draw)/(1-Vectau(Ntau)))).*(V_draw>Vectau(Ntau)));
        
        % Restrict support of simulated eta's
        pmax=3*max(YB(:,tt+1));
        pmin=3*min(YB(:,tt+1));
        Mateta_trueB(:,tt+1)=Mateta_trueB(:,tt+1).*(Mateta_trueB(:,tt+1)<=pmax).*(Mateta_trueB(:,tt+1)>=pmin)+...
            pmax*(Mateta_trueB(:,tt+1)>pmax)+pmin*(Mateta_trueB(:,tt+1)<pmin);
        
    end
    
    
    
    Mateps_trueB=zeros(NB,T);
    
    for tt=1:T
        % Proposal, eta_0
        V_draw=unifrnd(0,1,NB,1);
        
        %First quantile
        Mateps_trueB(:,tt)=(MatAGE_tB((tt-1)*NB+1:tt*NB,:)*ResqtrueB_eps(:,1)).*(V_draw<=Vectau(1));
        for jtau=2:Ntau
            Mateps_trueB(:,tt)=Mateps_trueB(:,tt)+((MatAGE_tB((tt-1)*NB+1:tt*NB,:)*(ResqtrueB_eps(:,jtau)-ResqtrueB_eps(:,jtau-1)))/(Vectau(jtau)-Vectau(jtau-1)).*...
                (V_draw-Vectau(jtau-1))+MatAGE_tB((tt-1)*NB+1:tt*NB,:)*ResqtrueB_eps(:,jtau-1)).*(V_draw>Vectau(jtau-1)).*(V_draw<=Vectau(jtau));
        end
        %Last quantile.
        Mateps_trueB(:,tt)=Mateps_trueB(:,tt)+(MatAGE_tB((tt-1)*NB+1:tt*NB,:)*ResqtrueB_eps(:,Ntau)).*(V_draw>Vectau(Ntau));
        
        % Laplace tails
        Mateps_trueB(:,tt)=Mateps_trueB(:,tt)+((1/(b1trueB_eps)*log(V_draw/Vectau(1))).*(V_draw<=Vectau(1))...
            -(1/bLtrueB_eps*log((1-V_draw)/(1-Vectau(Ntau)))).*(V_draw>Vectau(Ntau)));
        
    end
    
    Ytilde=Mateta_trueB+Mateps_trueB;
    
    % Persistence in the data
    
    Vect=YB(:,1:T-1);
    Vect_dep=YB(:,2:T);
    
    Mat1=[];
    for kk1=0:K1
        
        Mat1=[Mat1 hermite(kk1,(Vect(:)-meanY)/stdY)];
        
    end
    
    ResP_data=zeros((K1+1),Ntau);
    
    for jtau=1:Ntau
        
        tau=Vectau(jtau);
        
        ResP_data(:,jtau)=rq(Mat1,Vect_dep(:),tau);
        
    end
    
    Mat2=zeros(NB*(T-1),1);
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
    
    Resboot_fit(:,:,jboot)=Mat3*ResP_data;
    
    
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
    
    MatS2=zeros(NB*(T-1),1);
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
    
    Resboot_fit_simul(:,:,jboot)=MatS3*ResP_Sdata;
    
    
    
    % Persistence of eta
    
    Vect=Mateta_trueB(:,1:T-1);
    
    
    Vect=quantile(Vect(:),Vectau);
    age_ref=meanAGE;
    Mat=zeros(Ntau,K2+1);
    for kk1=1:K1
        for kk2=0:K2
            Mat=[Mat kk1*hermite(kk1-1,(Vect(:)-meanY)/stdY)./stdY.*hermite(kk2,(age_ref-meanAGE)/stdAGE)];
        end
    end
    
    
    Mat*ResqtrueB
    
    Resboot_eta(:,:,jboot)=Mat*ResqtrueB;
    
    
    
    
    % Conditional skewness of eta
    
    Vect=Mateta_trueB(:,1:T-1);
    
    
    Vect=quantile(Vect(:),Vectau);
    age_ref=meanAGE;
    Matq=zeros(Ntau,0);
    for kk1=0:K1
        for kk2=0:K2
            Matq=[Matq hermite(kk1,(Vect(:)-meanY)/stdY).*hermite(kk2,(age_ref-meanAGE)/stdAGE)];
        end
    end
    
    MM=Matq*ResqtrueB
    
    skew2=(MM(:,Ntau)+MM(:,1)-2*MM(:,(Ntau+1)/2))./(MM(:,Ntau)-MM(:,1))
    
    
    Resboot_skew_eta(:,jboot)=skew2;
    
    
    
    % Conditional skewness of log-earnings (real data)
    
    Vect_dep=YB(:,2:T);
    Vect=quantile(Vect(:),Vectau);
    
    Matqd=[];
    for kk1=0:K1
        
        Matqd=[Matqd hermite(kk1,(Vect(:)-meanY)/stdY)];
        
    end
    
    MMd=Matqd*ResP_data
    
    skew1=(MMd(:,Ntau)+MMd(:,1)-2*MMd(:,(Ntau+1)/2))./(MMd(:,Ntau)-MMd(:,1))
    
    Resboot_skew_y(:,jboot)=skew1;
    
    jboot=jboot+1;
    
    if isnan(mean(mat_lik((maxiter/2):maxiter)))
        jboot=jboot-1;
    end
    
    jboot
    
    
end

%save('Results_bootstrap_nonparametric.mat')


