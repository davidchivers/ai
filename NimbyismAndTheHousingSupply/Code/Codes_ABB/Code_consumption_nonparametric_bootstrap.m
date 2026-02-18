% Code for Arellano, Blundell and Bonhomme (2016), "Earnings and Consumption Dynamics: A Nonlinear Panel Data Framework"
% to appear in Econometrica

% This code estimates the nonparametric bootstrap for consumption


clear all
clc;

global Y Ytot_t tau Matdraw Matdraw_t Matdraw_tot Matdraw_lag MatAGE1_tot MatAGE_tot N T Ntau Vectau Resqinit_eps b1_eps bL_eps b1 bL b1_e0 bL_e0 Resqinit Resqinit_e0...
    K1 K2 meanAGE stdAGE meanY stdY AGE MatAGE_t MatAGE1 C A M1 M2 M3 M4 M5 M6 R1 R2 R3 R4 R5 ...
    meanA stdA meanC stdC  Resqfinal_eps Resqfinal Resqfinal_e0 Resinit Resinit_a1 Resinit_a2 b1_a bL_a


load('data_hermite_cons2.mat');

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

b1true_a=b1_a;
bLtrue_a=bL_a;

Restrue_a2=Resfinal_a2;

Nboot=200;

Resqboot=zeros((K1+1)*(K2+1),Ntau,Nboot);
Resqboot_e0=zeros(K3+1,Ntau,Nboot);
Resqboot_eps=zeros(K4+1,Ntau,Nboot);
Resboot=zeros((M1+1)*(M2+1)*(M3+1)*(M4+1)+1,Nboot);
Resboot_a1=zeros((M5+1)*(M6+1),Ntau,Nboot);
Resboot_a2=zeros((R1+1)*(R2+1)*(R3+1)*(R4+1)*(R5+1)+1,Nboot);

matb_boot=zeros(Nboot,8);

Resboot_fit=zeros(Ntau,Ntau,Nboot);
Resboot_fit_simul=zeros(Ntau,Ntau,Nboot);
Resboot_eta=zeros(Ntau,Ntau,Nboot);
Resboot_skew_y=zeros(Ntau,Nboot);
Resboot_skew_eta=zeros(Ntau,Nboot);
Resboot_cons=zeros(Ntau,Ntau,Nboot);
Resboot_cons_simul=zeros(Ntau,Ntau,Nboot);
Resboot_cons_eta=zeros(Ntau,Ntau,Nboot);
Resboot_cons_eps=zeros(Ntau,Ntau,Nboot);


tic

jboot=1;

while jboot<=Nboot
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Draw a sample from the model
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
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
    
    C=data(:,2);
    
    MatC=zeros(N,T);
    for tt=1:T
        MatC(:,tt)=C(tt:T:N*T);
    end
    
    C=MatC;
    
    A=data(:,3);
    
    MatA=zeros(N,T);
    for tt=1:T
        MatA(:,tt)=A(tt:T:N*T);
    end
    
    A=MatA;
    
    C=C(RDraw,:);
    A=A(RDraw,:);
    
    % Regression of consumption on a fourth order Hermite polynomial in age
    XX=[];
    for mm=0:4
        XX=[XX hermite(mm,(AGE(:)-meanAGE)/stdAGE)];
    end
    coeff=pinv(XX)*C(:);
    kappaC=XX*coeff;
    for tt=1:T
        C(:,tt)=C(:,tt)-kappaC((tt-1)*N+1:tt*N);
    end
    
    Vectage=(25:1:60)';
    XX1=[];
    for mm=0:4
        XX1=[XX1 hermite(mm,(Vectage-meanAGE)/stdAGE)];
    end
    
    
    % Regression of assets on a fourth order Hermite polynomial in age
    coeff=pinv(XX)*A(:);
    kappaA=XX*coeff;
    for tt=1:T
        A(:,tt)=A(:,tt)-kappaA((tt-1)*N+1:tt*N);
    end
    
    
    
  
    
    meanC=mean(C(:));
    stdC=std(C(:));
    
    meanA=mean(A(:));
    stdA=std(A(:));
    
    
    
    % seeds
    rng('shuffle')
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Estimate the earnings model
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Maximum Iteration
    maxiter=60;
    
    % Number of draws within the chain.
    draws=50;
    
    % Number of draws kept for computation.
    Mdraws=1;
    
    
    % Grid of tau's
    Ntau=11;
    Vectau=(1/(Ntau+1):1/(Ntau+1):Ntau/(Ntau+1))';
    
    % Degree Hermite polynomials
    K1=3;
    K2=2;
    K3=2;
    K4=2;
    
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
            
            mistake=1;
            
            
        else
            mistake=0;
            
            
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
    
    
    
    if mistake==0
        
        
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
        
        
        
        Resqboot(:,:,jboot)=Resqfinal;
        Resqboot_e0(:,:,jboot)=Resqfinal_e0;
        Resqboot_eps(:,:,jboot)=Resqfinal_eps;
        matb_boot(jboot,1:6)=[b1 bL b1_e0 bL_e0 b1_eps bL_eps];
        
        
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Estimate the consumption model
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        
        % Maximum Iteration
        maxiter=30;
        
        
        % Number of draws within the chain.
        draws=50;
        
        % Number of draws kept for computation.
        Mdraws=1;
        
        Ytot_t=kron(ones(Mdraws,1),Y(:,1));
        for j=2:T
            Ytot_t=[Ytot_t;kron(ones(Mdraws,1),Y(:,j))];
        end
        
        Ctot_t=kron(ones(Mdraws,1),C(:,1));
        for j=2:T
            Ctot_t=[Ctot_t;kron(ones(Mdraws,1),C(:,j))];
        end
        
        Atot_t=kron(ones(Mdraws,1),A(:,1));
        for j=2:T
            Atot_t=[Atot_t;kron(ones(Mdraws,1),A(:,j))];
        end
        
        AGEtot_t=kron(ones(Mdraws,1),AGE(:,1));
        for j=2:T
            AGEtot_t=[AGEtot_t;kron(ones(Mdraws,1),AGE(:,j))];
        end
        
        A2tot_t=kron(ones(Mdraws,1),A(:,2));
        for j=3:T
            A2tot_t=[A2tot_t;kron(ones(Mdraws,1),A(:,j))];
        end
        
        A1tot_t=kron(ones(Mdraws,1),A(:,1));
        for j=2:T-1
            A1tot_t=[A1tot_t;kron(ones(Mdraws,1),A(:,j))];
        end
        
        C1tot_t=kron(ones(Mdraws,1),C(:,1));
        for j=2:T-1
            C1tot_t=[C1tot_t;kron(ones(Mdraws,1),C(:,j))];
        end
        
        Y1tot_t=kron(ones(Mdraws,1),Y(:,1));
        for j=2:T-1
            Y1tot_t=[Y1tot_t;kron(ones(Mdraws,1),Y(:,j))];
        end
        
        AGE2tot_t=kron(ones(Mdraws,1),AGE(:,2));
        for j=3:T
            AGE2tot_t=[AGE2tot_t;kron(ones(Mdraws,1),AGE(:,j))];
        end
        
        % variance RW proposals
        var_prop1=.05;
        var_prop2=.05;
        var_prop3=.05;
        var_prop4=.05;
        var_prop5=.05;
        var_prop6=.05;
        
        
        count=1;
        deltapar=1;
        
        
        % Initial conditions: consumption given assets, eta_t, epsilon_t
        
        Resinit=Restrue.*(1+.05*(2*rand((M1+1)*(M2+1)*(M3+1)*(M4+1)+1,1)-1));
        
        
        
        C_t=C(:,1);
        for j=2:T
            C_t=[C_t;C(:,j)];
        end
        
        A_t=A(:,1);
        for j=2:T
            A_t=[A_t;A(:,j)];
        end
        
        Y_t=Y(:,1);
        for j=2:T
            Y_t=[Y_t;Y(:,j)];
        end
        
        AGE_tt=AGE(:,1);
        for j=2:T
            AGE_tt=[AGE_tt;AGE(:,j)];
        end
        
        
        
        % Initial conditions: assets_t given assets_t-1, C_t-1, Y_t-1, eta_t-1, AGE_t
        
        
        Resinit_a2=Restrue_a2.*(1+.05*(2*rand((R1+1)*(R2+1)*(R3+1)*(R4+1)*(R5+1)+1,1)-1));
        
        
        A2_t=A(:,2);
        for j=3:T
            A2_t=[A2_t;A(:,j)];
        end
        
        A1_t=A(:,1);
        for j=2:T-1
            A1_t=[A1_t;A(:,j)];
        end
        
        C1_t=C(:,1);
        for j=2:T-1
            C1_t=[C1_t;C(:,j)];
        end
        
        Y1_t=Y(:,1);
        for j=2:T-1
            Y1_t=[Y1_t;Y(:,j)];
        end
        
        AGE2_t=AGE(:,2);
        for j=3:T
            AGE2_t=[AGE2_t;AGE(:,j)];
        end
        
        
        
        % Initial conditions: initial assets given eta_1
        
        
        
        Resinit_a1=Restrue_a1.*(1+.05*(2*rand((M5+1)*(M6+1),Ntau)-1));
        
        
        % Initial conditions: Laplace parameters
        b1_a=b1true_a*(1+.2*(2*rand(1,1)-1));
        bL_a=bLtrue_a*(1+.2*(2*rand(1,1)-1));
        
        mat_ba=zeros(maxiter,2);
        
        Resnew=zeros((M1+1)*(M2+1)*(M3+1)*(M4+1)+1,maxiter);
        Resnew_a2=zeros((R1+1)*(R2+1)*(R3+1)*(R4+1)*(R5+1)+1,maxiter);
        Resnew_a1=zeros((M5+1)*(M6+1),Ntau,maxiter);
        
        init=randn(N,T);
        
        
        Obj_chain = [postr_nonlinear_consumption_age_hermite_predet(init) zeros(N,draws-1)];
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
                newObj=postr_nonlinear_consumption_age_hermite_predet(Matdraw);
                r=(min([ones(N,1) newObj./Obj_chain(:,j-1)]'))';
                prob=rand(N,1);
                Obj_chain(:,j)=(prob<=r).*newObj+(prob>r).*Obj_chain(:,j-1);
                Nu_chain1(:,j)=(prob<=r).*Matdraw(:,1)+(prob>r).*Nu_chain1(:,j-1);
                Matdraw(:,1)=Nu_chain1(:,j);
                acc1(:,j)=(prob<=r);
                
                
                
                % eta_t
                Matdraw(:,2)=Nu_chain2(:,j-1)+sqrt(var_prop2)*randn(N,1);
                newObj=postr_nonlinear_consumption_age_hermite_predet(Matdraw);
                r=(min([ones(N,1) newObj./Obj_chain(:,j)]'))';
                prob=rand(N,1);
                Obj_chain(:,j)=(prob<=r).*newObj+(prob>r).*Obj_chain(:,j);
                Nu_chain2(:,j)=(prob<=r).*Matdraw(:,2)+(prob>r).*Nu_chain2(:,j-1);
                Matdraw(:,2)=Nu_chain2(:,j);
                acc2(:,j)=(prob<=r);
                
                Matdraw(:,3)=Nu_chain3(:,j-1)+sqrt(var_prop3)*randn(N,1);
                newObj=postr_nonlinear_consumption_age_hermite_predet(Matdraw);
                r=(min([ones(N,1) newObj./Obj_chain(:,j)]'))';
                prob=rand(N,1);
                Obj_chain(:,j)=(prob<=r).*newObj+(prob>r).*Obj_chain(:,j);
                Nu_chain3(:,j)=(prob<=r).*Matdraw(:,3)+(prob>r).*Nu_chain3(:,j-1);
                Matdraw(:,3)=Nu_chain3(:,j);
                acc3(:,j)=(prob<=r);
                
                Matdraw(:,4)=Nu_chain4(:,j-1)+sqrt(var_prop4)*randn(N,1);
                newObj=postr_nonlinear_consumption_age_hermite_predet(Matdraw);
                r=(min([ones(N,1) newObj./Obj_chain(:,j)]'))';
                prob=rand(N,1);
                Obj_chain(:,j)=(prob<=r).*newObj+(prob>r).*Obj_chain(:,j);
                Nu_chain4(:,j)=(prob<=r).*Matdraw(:,4)+(prob>r).*Nu_chain4(:,j-1);
                Matdraw(:,4)=Nu_chain4(:,j);
                acc4(:,j)=(prob<=r);
                
                Matdraw(:,5)=Nu_chain5(:,j-1)+sqrt(var_prop5)*randn(N,1);
                newObj=postr_nonlinear_consumption_age_hermite_predet(Matdraw);
                r=(min([ones(N,1) newObj./Obj_chain(:,j)]'))';
                prob=rand(N,1);
                Obj_chain(:,j)=(prob<=r).*newObj+(prob>r).*Obj_chain(:,j);
                Nu_chain5(:,j)=(prob<=r).*Matdraw(:,5)+(prob>r).*Nu_chain5(:,j-1);
                Matdraw(:,5)=Nu_chain5(:,j);
                acc5(:,j)=(prob<=r);
                
                Matdraw(:,6)=Nu_chain6(:,j-1)+sqrt(var_prop6)*randn(N,1);
                newObj=postr_nonlinear_consumption_age_hermite_predet(Matdraw);
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
            
            Matdraw_t=Matdraw(:);
            
            Matdraw1=Matdraw(:,1:T-1);
            Matdraw1_t=Matdraw1(:);
            
            
            % Consumption rule
            
            XX=[];
            for mm1=0:M1
                for mm2=0:M2
                    for mm3=0:M3
                        for mm4=0:M4
                            XX=[XX hermite(mm1,(Atot_t-meanA)/stdA).*hermite(mm2,(Matdraw_t-meanY)/stdY).*hermite(mm3,(Ytot_t-Matdraw_t-meanY)/stdY).*hermite(mm4,(AGEtot_t-meanAGE)/stdAGE)];
                        end
                    end
                end
            end
            
            
            
            Resnew(1:(M1+1)*(M2+1)*(M3+1)*(M4+1),iter)=pinv(XX)*Ctot_t;
            Resnew((M1+1)*(M2+1)*(M3+1)*(M4+1)+1,iter)=mean((Ctot_t-XX*Resnew(1:(M1+1)*(M2+1)*(M3+1)*(M4+1),iter)).^2);
            
            
            % Predetermined assets
            
            XXA=[];
            for mm1=0:R1
                for mm2=0:R2
                    for mm3=0:R3
                        for mm4=0:R4
                            for mm5=0:R5
                                XXA=[XXA hermite(mm1,(A1tot_t-meanA)/stdA).*hermite(mm2,(C1tot_t-meanC)/stdC).*hermite(mm3,(Y1tot_t-meanY)/stdY)...
                                    .*hermite(mm4,(Matdraw1_t-meanY)/stdY).*hermite(mm5,(AGE2tot_t-meanAGE)/stdAGE)];
                            end
                        end
                    end
                end
            end
            
            
            
            Resnew_a2(1:(R1+1)*(R2+1)*(R3+1)*(R4+1)*(R5+1),iter)=pinv(XXA)*A2tot_t;
            Resnew_a2((R1+1)*(R2+1)*(R3+1)*(R4+1)*(R5+1)+1,iter)=mean((A2tot_t-XXA*Resnew_a2(1:(R1+1)*(R2+1)*(R3+1)*(R4+1)*(R5+1),iter)).^2);
            
            % Initial assets
            
            Mateta1=[];
            for mm5=0:M5
                for mm6=0:M6
                    Mateta1=[Mateta1 hermite(mm5,(Matdraw(:,1)-meanY)/stdY).*hermite(mm6,(AGEtot_t(1:N*Mdraws,1)-meanAGE)/stdAGE)];
                end
            end
            
            
            
            for jtau=1:Ntau
                tau=Vectau(jtau);
                beta1=rq(Mateta1,Atot_t(1:N*Mdraws),tau);
                Resnew_a1(1:(M5+1)*(M6+1),jtau,iter)=beta1;
            end
            
            
            % Initial assets: Laplace parameters
            
            Vect1=Atot_t(1:N*Mdraws)-Mateta1*Resnew_a1(:,1,iter);
            Vect2=Atot_t(1:N*Mdraws)-Mateta1*Resnew_a1(:,Ntau,iter);
            b1_a=-sum(Vect1<=0)/sum(Vect1.*(Vect1<=0));
            bL_a=sum(Vect2>=0)/sum(Vect2.*(Vect2>=0));
            
            mat_ba(iter,1)=b1_a;
            mat_ba(iter,2)=bL_a;
            
            b1_a
            bL_a
            
            
            % complete likelihood
            mat_lik(iter)=mean(log(postr_nonlinear_consumption_age_hermite_predet(Matdraw)));
            mat_lik(iter)
            
            
            
            % Criterion
            
            Resinit=Resnew(:,iter)
            Resinit_a1=Resnew_a1(:,:,iter)
            Resinit_a2=Resnew_a2(:,iter)
            
            
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
        
        
        
        Resfinal=zeros((M1+1)*(M2+1)*(M3+1)*(M4+1)+1,1);
        for p=1:(M1+1)*(M2+1)*(M3+1)*(M4+1)+1
            Resfinal(p,1)=mean(Resnew(p,(maxiter/2):maxiter));
        end
        
        Resfinal_a2=zeros((R1+1)*(R2+1)*(R3+1)*(R4+1)*(R5+1)+1,1);
        for p=1:(R1+1)*(R2+1)*(R3+1)*(R4+1)*(R5+1)+1
            Resfinal_a2(p,1)=mean(Resnew_a2(p,(maxiter/2):maxiter));
        end
        
        Resfinal_a1=zeros((M5+1)*(M6+1),Ntau);
        for jtau=1:Ntau
            for p=1:(M5+1)*(M6+1)
                Resfinal_a1(p,jtau)=mean(Resnew_a1(p,jtau,(maxiter/2):maxiter));
            end
        end
        
        
        b1_a=mean(mat_ba((maxiter/2):maxiter,1));
        bL_a=mean(mat_ba((maxiter/2):maxiter,2));
        
        
        Resboot(:,jboot)=Resfinal;
        Resboot_a1(:,:,jboot)=Resfinal_a1;
        Resboot_a2(:,jboot)=Resfinal_a2;
        matb_boot(jboot,7:8)=[b1_a bL_a];
        
        
        
        
        
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
        
        
        
        RestrueB=Resfinal;
        
        RestrueB_a1=Resfinal_a1;
        
        b1trueB_a=b1_a;
        bLtrueB_a=bL_a;
        
        RestrueB_a2=Resfinal_a2;
        
        
        
        
        % Expand the sample
        Nsim=20;
        NB=N*Nsim;
        MatAGE1B=kron(ones(Nsim,1),MatAGE1);
        AGEB=kron(ones(Nsim,1),AGE);
        MatAGE_tB=kron(ones(Nsim,1),MatAGE_t);
        YB=kron(ones(Nsim,1),Y);
        CB=kron(ones(Nsim,1),C);
        AB=kron(ones(Nsim,1),A);
        
        
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
        
        
        % Assets
        
        Mateta1=[];
        for mm5=0:M5
            for mm6=0:M6
                Mateta1=[Mateta1 hermite(mm5,(Mateta_trueB(:,1)-meanY)/stdY).*hermite(mm6,(AGEB(:,1)-meanAGE)/stdAGE)];
            end
        end
        
        Atilde=zeros(NB,T);
        
        % Proposal, a1
        V_draw=unifrnd(0,1,NB,1);
        
        %First quantile
        Atilde(:,1)=(Mateta1*RestrueB_a1(:,1)).*(V_draw<=Vectau(1));
        for jtau=2:Ntau
            Atilde(:,1)=Atilde(:,1)+((Mateta1*(RestrueB_a1(:,jtau)-RestrueB_a1(:,jtau-1)))/(Vectau(jtau)-Vectau(jtau-1)).*...
                (V_draw-Vectau(jtau-1))+Mateta1*RestrueB_a1(:,jtau-1)).*(V_draw>Vectau(jtau-1)).*(V_draw<=Vectau(jtau));
        end
        %Last quantile.
        Atilde(:,1)=Atilde(:,1)+(Mateta1*RestrueB_a1(:,Ntau)).*(V_draw>Vectau(Ntau));
        
        % Laplace tails
        Atilde(:,1)=Atilde(:,1)+((1/(b1trueB_a)*log(V_draw/Vectau(1))).*(V_draw<=Vectau(1))...
            -(1/bLtrueB_a*log((1-V_draw)/(1-Vectau(Ntau)))).*(V_draw>Vectau(Ntau)));
        
        % Assets and consumption
        
        Ctilde=zeros(NB,T);
        for tt=1:T
            XX=[];
            for mm1=0:M1
                for mm2=0:M2
                    for mm3=0:M3
                        for mm4=0:M4
                            XX=[XX hermite(mm1,(Atilde(:,tt)-meanA)/stdA).*hermite(mm2,(Mateta_trueB(:,tt)-meanY)/stdY).*hermite(mm3,(Ytilde(:,tt)-Mateta_trueB(:,tt)-meanY)/stdY).*hermite(mm4,(AGEB(:,tt)-meanAGE)/stdAGE)];
                        end
                    end
                end
            end
            
            Ctilde(:,tt)=XX*RestrueB(1:(M1+1)*(M2+1)*(M3+1)*(M4+1),1)+sqrt(RestrueB((M1+1)*(M2+1)*(M3+1)*(M4+1)+1))*randn(NB,1);
            
            % Restrict support of simulated consumption
            rmax=max(CB(:,tt));
            rmin=min(CB(:,tt));
            Ctilde(:,tt)=Ctilde(:,tt).*(Ctilde(:,tt)<=rmax).*(Ctilde(:,tt)>=rmin)+...
                rmax*(Ctilde(:,tt)>rmax)+rmin*(Ctilde(:,tt)<rmin);
            
            
            if tt<=T-1
                
                XXA=[];
                for mm1=0:R1
                    for mm2=0:R2
                        for mm3=0:R3
                            for mm4=0:R4
                                for mm5=0:R5
                                    XXA=[XXA hermite(mm1,(Atilde(:,tt)-meanA)/stdA).*hermite(mm2,(Ctilde(:,tt)-meanC)/stdC).*hermite(mm3,(Ytilde(:,tt)-meanY)/stdY)...
                                        .*hermite(mm4,(Mateta_trueB(:,tt)-meanY)/stdY).*hermite(mm5,(AGEB(:,tt+1)-meanAGE)/stdAGE)];
                                end
                            end
                        end
                    end
                end
                
                
                Atilde(:,tt+1)=XXA*RestrueB_a2(1:(R1+1)*(R2+1)*(R3+1)*(R4+1)*(R5+1),1)+sqrt(RestrueB_a2((R1+1)*(R2+1)*(R3+1)*(R4+1)*(R5+1)+1,1))*randn(NB,1);
                
                % Restrict support of simulated assets
                mmax=max(AB(:,tt+1));
                mmin=min(AB(:,tt+1));
                Atilde(:,tt+1)=Atilde(:,tt+1).*(Atilde(:,tt+1)<=mmax).*(Atilde(:,tt+1)>=mmin)+...
                    mmax*(Atilde(:,tt+1)>mmax)+mmin*(Atilde(:,tt+1)<mmin);
                
            end
        end
        
        
        %  Computation of insurance (eta)
        
        Vec1=quantile(Atilde(:),Vectau);
        Vec2=quantile(AGEB(:),Vectau);
        
        Mat_insurance=zeros(Ntau,Ntau);
        
        for jtau1=1:Ntau
            for jtau2=1:Ntau
                XX1=[];
                for mm1=0:M1
                    for mm2=0:M2
                        if mm2==0
                            XX1=[XX1 zeros(NB*Mdraws*T,(M3+1)*(M4+1))];
                        else
                            for mm3=0:M3
                                for mm4=0:M4
                                    XX1=[XX1 hermite(mm1,(Vec1(jtau1)-meanA)/stdA).*mm2./stdY.*hermite(mm2-1,(Mateta_trueB(:)-meanY)/stdY).*hermite(mm3,(Mateps_trueB(:)-meanY)/stdY).*hermite(mm4,(Vec2(jtau2)-meanAGE)/stdAGE)];
                                end
                            end
                        end
                    end
                end
                
                Mat_insurance(jtau1,jtau2)=mean(XX1*RestrueB(1:(M1+1)*(M2+1)*(M3+1)*(M4+1),1));
            end
        end
        
        Resboot_cons_eta(:,:,jboot)=Mat_insurance;
        
        
        %  Computation of insurance (eps)
        
        Vec1=quantile(Atilde(:),Vectau);
        Vec2=quantile(AGEB(:),Vectau);
        
        Mat_insurance2=zeros(Ntau,Ntau);
        
        for jtau1=1:Ntau
            for jtau2=1:Ntau
                
                XX2=[];
                for mm1=0:M1
                    for mm2=0:M2
                        for mm3=0:M3
                            if mm3==0
                                XX2=[XX2 zeros(NB*Mdraws*T,M4+1)];
                            else
                                for mm4=0:M4
                                    XX2=[XX2 hermite(mm1,(Vec1(jtau1)-meanA)/stdA).*hermite(mm2,(Mateta_trueB(:)-meanY)/stdY).*mm3./stdY.*hermite(mm3-1,(Mateps_trueB(:)-meanY)/stdY).*hermite(mm4,(Vec2(jtau2)-meanAGE)/stdAGE)];
                                end
                            end
                        end
                        
                    end
                end
                
                
                Mat_insurance2(jtau1,jtau2)=mean(XX2*RestrueB(1:(M1+1)*(M2+1)*(M3+1)*(M4+1),1));
            end
        end
        
        
        Resboot_cons_eps(:,:,jboot)=Mat_insurance2;
        
        
        % Consumption regression in the data
        
        XX=[];
        for mm1=0:M1
            for mm2=0:M2
                for mm4=0:M4
                    XX=[XX hermite(mm1,(AB(:)-meanA)/stdA).*hermite(mm2,(YB(:)-meanY)/stdY).*hermite(mm4,(AGEB(:)-meanAGE)/stdAGE)];
                end
            end
        end
        
        par_C=pinv(XX)*CB(:);
        
        Vec1=quantile(AB(:),Vectau);
        Vec2=quantile(AGEB(:),Vectau);
        
        Mat_consreg=zeros(Ntau,Ntau);
        
        for jtau1=1:Ntau
            for jtau2=1:Ntau
                XX1=[];
                for mm1=0:M1
                    for mm2=0:M2
                        if mm2==0
                            XX1=[XX1 zeros(NB*T,(M4+1))];
                        else
                            
                            for mm4=0:M4
                                XX1=[XX1 hermite(mm1,(Vec1(jtau1)-meanA)/stdA).*mm2./stdY.*hermite(mm2-1,(YB(:)-meanY)/stdY).*hermite(mm4,(Vec2(jtau2)-meanAGE)/stdAGE)];
                            end
                        end
                    end
                end
                
                Mat_consreg(jtau1,jtau2)=mean(XX1*par_C);
            end
        end
        
        Resboot_cons(:,:,jboot)=Mat_consreg;
        
        
        
        % Consumption regression in the simulated data
        
        XX=[];
        for mm1=0:M1
            for mm2=0:M2
                for mm4=0:M4
                    XX=[XX hermite(mm1,(Atilde(:)-meanA)/stdA).*hermite(mm2,(Ytilde(:)-meanY)/stdY).*hermite(mm4,(AGEB(:)-meanAGE)/stdAGE)];
                end
            end
        end
        
        par_C=pinv(XX)*Ctilde(:);
        
        Vec1=quantile(Atilde(:),Vectau);
        Vec2=quantile(AGEB(:),Vectau);
        
        Mat_consreg2=zeros(Ntau,Ntau);
        
        for jtau1=1:Ntau
            for jtau2=1:Ntau
                XX1=[];
                for mm1=0:M1
                    for mm2=0:M2
                        if mm2==0
                            XX1=[XX1 zeros(NB*T,(M4+1))];
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
        
        Resboot_cons_simul(:,:,jboot)=Mat_consreg2;
        
        
        
        
        
        Mat_insurance
        Mat_insurance2
        
        
        
        jboot=jboot+1;
        jboot
    end
    
end





toc

%save('Results_consumption_bootstrap_nonparametric.mat')
