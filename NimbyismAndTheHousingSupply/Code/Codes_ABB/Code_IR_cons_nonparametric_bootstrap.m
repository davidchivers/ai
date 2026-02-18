% Code for Arellano, Blundell and Bonhomme (2016), "Earnings and Consumption Dynamics: A Nonlinear Panel Data Framework"
% to appear in Econometrica

% This code performs a bootstrap of impulse responses

% Due to time constraints the number of iterations and draws is lower than
% in the main estimation

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

ResbootIRY_1_1=zeros(Nboot,13);
ResbootIRY_1_9=zeros(Nboot,13);
ResbootIRY_5_1=zeros(Nboot,13);
ResbootIRY_5_9=zeros(Nboot,13);
ResbootIRY_9_1=zeros(Nboot,13);
ResbootIRY_9_9=zeros(Nboot,13);


ResbootIR_1_1_1=zeros(Nboot,13);
ResbootIR_1_1_9=zeros(Nboot,13);
ResbootIR_1_5_1=zeros(Nboot,13);
ResbootIR_1_5_9=zeros(Nboot,13);
ResbootIR_1_9_1=zeros(Nboot,13);
ResbootIR_1_9_9=zeros(Nboot,13);
ResbootIR_2_1_1=zeros(Nboot,13);
ResbootIR_2_1_9=zeros(Nboot,13);
ResbootIR_2_5_1=zeros(Nboot,13);
ResbootIR_2_5_9=zeros(Nboot,13);
ResbootIR_2_9_1=zeros(Nboot,13);
ResbootIR_2_9_9=zeros(Nboot,13);

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
    
    aa_ref=35;
    
    nage=13;
    
    
    
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
    
    %CHECK
    RDRaw=(1:1:N)';
    
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
        
        
        
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Simulate and compute  impulse responses
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        
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
        
        
        % Number of individuals
        NB=100000;
        
        
        % Assets accumulation: 1 means predetermined assets, 2 means standard
        % linear assets accumulation rule with r=3/% and assets >=0
        for acc=1:2
            for jjtau_init=1:3
                if jjtau_init==1
                    tau_init=.1;
                elseif jjtau_init==2
                    tau_init=.5;
                elseif jjtau_init==3
                    tau_init=.9;
                end
                
                for jjtau_shock=1:2
                    
                    if jjtau_shock==1
                        tau_shock=.1;
                    else
                        tau_shock=.9;
                    end
                    
                    
                    
                    
                    % Keep only tau1-percentile of initial eta ("tau_init")
                    
                    tau1=tau_init;
                    
                    % Proposal, eta_1
                    V_draw=unifrnd(0,1,NB,1);
                    
                    MatAGE1B=[];
                    for kk3=0:K3
                        MatAGE1B=[MatAGE1B hermite(kk3,(aa_ref-meanAGE)/stdAGE)];
                    end
                    
                    Mateta_trueB=zeros(NB,nage);
                    Mateps_trueB=zeros(NB,nage);
                    YB=zeros(NB,nage);
                    CB=zeros(NB,nage);
                    AB=zeros(NB,nage);
                    
                    
                    
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
                    
                    % Initial eta
                    
                    eta_1=quantile(Mateta_trueB(:,1),tau1);
                    
                    Mateta_trueB(:,1)=eta_1;
                    
                    % Initial assets
                    
                    
                    Mateta1=[];
                    for mm5=0:M5
                        for mm6=0:M6
                            Mateta1=[Mateta1 hermite(mm5,(Mateta_trueB(:,1)-meanY)/stdY).*hermite(mm6,(aa_ref-meanAGE)/stdAGE)];
                        end
                    end
                    
                    
                    % Proposal, a1
                    V_draw=unifrnd(0,1,NB,1);
                    
                    %First quantile
                    AB(:,1)=(Mateta1*RestrueB_a1(:,1)).*(V_draw<=Vectau(1));
                    for jtau=2:Ntau
                        AB(:,1)=AB(:,1)+((Mateta1*(RestrueB_a1(:,jtau)-RestrueB_a1(:,jtau-1)))/(Vectau(jtau)-Vectau(jtau-1)).*...
                            (V_draw-Vectau(jtau-1))+Mateta1*RestrueB_a1(:,jtau-1)).*(V_draw>Vectau(jtau-1)).*(V_draw<=Vectau(jtau));
                    end
                    %Last quantile.
                    AB(:,1)=AB(:,1)+(Mateta1*RestrueB_a1(:,Ntau)).*(V_draw>Vectau(Ntau));
                    
                    % Laplace tails
                    AB(:,1)=AB(:,1)+((1/(b1trueB_a)*log(V_draw/Vectau(1))).*(V_draw<=Vectau(1))...
                        -(1/bLtrueB_a*log((1-V_draw)/(1-Vectau(Ntau)))).*(V_draw>Vectau(Ntau)));
                    
                    
                    
                    
                    
                    %%%% FIRST SIMULATION
                    
                    % percentile of initial shock
                    tau0=.50;
                    
                    for jj=1:nage
                        
                        aa=aa_ref+(jj-1)*2;
                        
                        MatAGE1B=[];
                        for kk3=0:K3
                            MatAGE1B=[MatAGE1B hermite(kk3,(aa-meanAGE)/stdAGE)];
                        end
                        
                        % epsilons
                        
                        MatAGE_tB=[];
                        for kk4=0:K4
                            MatAGE_tB=[MatAGE_tB hermite(kk4,(aa-meanAGE)/stdAGE)];
                        end
                        
                        
                        
                        % Proposal, eta_0
                        V_draw=unifrnd(0,1,NB,1);
                        
                        %First quantile
                        Mateps_trueB(:,jj)=(MatAGE_tB*ResqtrueB_eps(:,1)).*(V_draw<=Vectau(1));
                        for jtau=2:Ntau
                            Mateps_trueB(:,jj)=Mateps_trueB(:,jj)+((MatAGE_tB*(ResqtrueB_eps(:,jtau)-ResqtrueB_eps(:,jtau-1)))/(Vectau(jtau)-Vectau(jtau-1)).*...
                                (V_draw-Vectau(jtau-1))+MatAGE_tB*ResqtrueB_eps(:,jtau-1)).*(V_draw>Vectau(jtau-1)).*(V_draw<=Vectau(jtau));
                        end
                        %Last quantile.
                        Mateps_trueB(:,jj)=Mateps_trueB(:,jj)+(MatAGE_tB*ResqtrueB_eps(:,Ntau)).*(V_draw>Vectau(Ntau));
                        
                        % Laplace tails
                        Mateps_trueB(:,jj)=Mateps_trueB(:,jj)+((1/(b1trueB_eps)*log(V_draw/Vectau(1))).*(V_draw<=Vectau(1))...
                            -(1/bLtrueB_eps*log((1-V_draw)/(1-Vectau(Ntau)))).*(V_draw>Vectau(Ntau)));
                        
                        
                        
                        % Earnings
                        
                        YB(:,jj)=Mateta_trueB(:,jj)+Mateps_trueB(:,jj);
                        
                        
                        
                        
                        % Assets and consumption
                        
                        
                        XX=[];
                        for mm1=0:M1
                            for mm2=0:M2
                                for mm3=0:M3
                                    for mm4=0:M4
                                        XX=[XX hermite(mm1,(AB(:,jj)-meanA)/stdA).*hermite(mm2,(Mateta_trueB(:,jj)-meanY)/stdY).*hermite(mm3,(YB(:,jj)-Mateta_trueB(:,jj)-meanY)/stdY).*hermite(mm4,(aa-meanAGE)/stdAGE)];
                                    end
                                end
                            end
                        end
                        
                        CB(:,jj)=XX*RestrueB(1:(M1+1)*(M2+1)*(M3+1)*(M4+1),1)+sqrt(RestrueB((M1+1)*(M2+1)*(M3+1)*(M4+1)+1))*randn(NB,1);
                        
                        % Restrict support of simulated consumption
                        rmax=5;
                        rmin=-5;
                        CB(:,jj)=CB(:,jj).*(CB(:,jj)<=rmax).*(CB(:,jj)>=rmin)+...
                            rmax*(CB(:,jj)>rmax)+rmin*(CB(:,jj)<rmin);
                        
                        if jj<=nage-1
                            
                            
                            % A(:,jj+1)=[ones(N,1) A(:,jj) Y(:,jj) C(:,jj)]*Res_assets+sqrt(sig_assets)*randn(N,1);
                            %A(:,jj+1)=log((1+.03)*exp(A(:,jj))+exp(Y(:,jj))-exp(C(:,jj)));
                            
                            
                            % standard asset accumulation rule, r=3%. Assets >=0
                            if acc==2
                                AB(:,jj+1)=log(max((1+.03)*exp(AB(:,jj))+exp(YB(:,jj))-exp(CB(:,jj)),ones(NB,1)));
                            end
                            
                            % Predetermined assets
                            if acc==1
                                XXA=[];
                                for mm1=0:R1
                                    for mm2=0:R2
                                        for mm3=0:R3
                                            for mm4=0:R4
                                                for mm5=0:R5
                                                    XXA=[XXA hermite(mm1,(AB(:,jj)-meanA)/stdA).*hermite(mm2,(CB(:,jj)-meanC)/stdC).*hermite(mm3,(YB(:,jj)-meanY)/stdY)...
                                                        .*hermite(mm4,(Mateta_trueB(:,jj)-meanY)/stdY).*hermite(mm5,(aa-meanAGE)/stdAGE)];
                                                end
                                            end
                                        end
                                    end
                                end
                                
                                
                                AB(:,jj+1)=XXA*RestrueB_a2(1:(R1+1)*(R2+1)*(R3+1)*(R4+1)*(R5+1),1)+sqrt(RestrueB_a2((R1+1)*(R2+1)*(R3+1)*(R4+1)*(R5+1)+1,1))*randn(NB,1);
                                
                                % Restrict support of simulated assets
                                mmax=10;
                                mmin=-10;
                                AB(:,jj+1)=AB(:,jj+1).*(AB(:,jj+1)<=mmax).*(AB(:,jj+1)>=mmin)+...
                                    mmax*(AB(:,jj+1)>mmax)+mmin*(AB(:,jj+1)<mmin);
                            end
                            
                            
                            Mat=zeros(NB,(K1+1)*(K2+1));
                            for kk1=0:K1
                                for kk2=0:K2
                                    Mat(:,kk1*(K2+1)+kk2+1)=hermite(kk1,(Mateta_trueB(:,jj)-meanY)/stdY).*hermite(kk2,((aa+2)-meanAGE)/stdAGE);
                                end
                            end
                            
                            % age 37 receives shock tau0
                            if jj==1
                                V_draw=tau0*ones(NB,1);
                            else
                                V_draw=unifrnd(0,1,NB,1);
                            end
                            
                            %First quantile
                            
                            Mateta_trueB(:,jj+1)=(Mat*ResqtrueB(:,1)).*(V_draw<=Vectau(1));
                            for jtau=2:Ntau
                                Mateta_trueB(:,jj+1)=Mateta_trueB(:,jj+1)+...
                                    ((Mat*ResqtrueB(:,jtau)-Mat*ResqtrueB(:,jtau-1))/...
                                    (Vectau(jtau)-Vectau(jtau-1)).*...
                                    (V_draw-Vectau(jtau-1))+Mat*ResqtrueB(:,jtau-1)).*...
                                    (V_draw>Vectau(jtau-1)).*(V_draw<=Vectau(jtau));
                            end
                            %Last quantile.
                            Mateta_trueB(:,jj+1)=Mateta_trueB(:,jj+1)+(Mat*ResqtrueB(:,Ntau)).*...
                                (V_draw>Vectau(Ntau));
                            
                            % Laplace tails
                            Mateta_trueB(:,jj+1)=Mateta_trueB(:,jj+1)+((1/(b1trueB)*log(V_draw/Vectau(1))).*(V_draw<=Vectau(1))...
                                -(1/bLtrueB*log((1-V_draw)/(1-Vectau(Ntau)))).*(V_draw>Vectau(Ntau)));
                            
                            % Restrict support of simulated eta's
                            pmax=10;
                            pmin=-10;
                            Mateta_trueB(:,jj+1)=Mateta_trueB(:,jj+1).*(Mateta_trueB(:,jj+1)<=pmax).*(Mateta_trueB(:,jj+1)>=pmin)+...
                                pmax*(Mateta_trueB(:,jj+1)>pmax)+pmin*(Mateta_trueB(:,jj+1)<pmin);
                            
                            
                        end
                    end
                    
                    YB1=YB;
                    CB1=CB;
                    AB1=AB;
                    Mateta_trueB1=Mateta_trueB;
                    
                    %%%% SECOND SIMULATION
                    
                    % percentile of initial shock ("tau_shock")
                    tau0=tau_shock;
                    
                    for jj=1:nage
                        
                        aa=aa_ref+(jj-1)*2;
                        
                        
                        
                        MatAGE1B=[];
                        for kk3=0:K3
                            MatAGE1B=[MatAGE1B hermite(kk3,(aa-meanAGE)/stdAGE)];
                        end
                        
                        % epsilons
                        
                        MatAGE_tB=[];
                        for kk4=0:K4
                            MatAGE_tB=[MatAGE_tB hermite(kk4,(aa-meanAGE)/stdAGE)];
                        end
                        
                        
                        
                        % Proposal, eta_0
                        V_draw=unifrnd(0,1,NB,1);
                        
                        %First quantile
                        Mateps_trueB(:,jj)=(MatAGE_tB*ResqtrueB_eps(:,1)).*(V_draw<=Vectau(1));
                        for jtau=2:Ntau
                            Mateps_trueB(:,jj)=Mateps_trueB(:,jj)+((MatAGE_tB*(ResqtrueB_eps(:,jtau)-ResqtrueB_eps(:,jtau-1)))/(Vectau(jtau)-Vectau(jtau-1)).*...
                                (V_draw-Vectau(jtau-1))+MatAGE_tB*ResqtrueB_eps(:,jtau-1)).*(V_draw>Vectau(jtau-1)).*(V_draw<=Vectau(jtau));
                        end
                        %Last quantile.
                        Mateps_trueB(:,jj)=Mateps_trueB(:,jj)+(MatAGE_tB*ResqtrueB_eps(:,Ntau)).*(V_draw>Vectau(Ntau));
                        
                        % Laplace tails
                        Mateps_trueB(:,jj)=Mateps_trueB(:,jj)+((1/(b1trueB_eps)*log(V_draw/Vectau(1))).*(V_draw<=Vectau(1))...
                            -(1/bLtrueB_eps*log((1-V_draw)/(1-Vectau(Ntau)))).*(V_draw>Vectau(Ntau)));
                        
                        
                        
                        % Earnings
                        
                        YB(:,jj)=Mateta_trueB(:,jj)+Mateps_trueB(:,jj);
                        
                        
                        
                        
                        % Assets and consumption
                        
                        
                        XX=[];
                        for mm1=0:M1
                            for mm2=0:M2
                                for mm3=0:M3
                                    for mm4=0:M4
                                        XX=[XX hermite(mm1,(AB(:,jj)-meanA)/stdA).*hermite(mm2,(Mateta_trueB(:,jj)-meanY)/stdY).*hermite(mm3,(YB(:,jj)-Mateta_trueB(:,jj)-meanY)/stdY).*hermite(mm4,(aa-meanAGE)/stdAGE)];
                                    end
                                end
                            end
                        end
                        
                        CB(:,jj)=XX*RestrueB(1:(M1+1)*(M2+1)*(M3+1)*(M4+1),1)+sqrt(RestrueB((M1+1)*(M2+1)*(M3+1)*(M4+1)+1))*randn(NB,1);
                        
                        % Restrict support of simulated consumption
                        rmax=5;
                        rmin=-5;
                        CB(:,jj)=CB(:,jj).*(CB(:,jj)<=rmax).*(CB(:,jj)>=rmin)+...
                            rmax*(CB(:,jj)>rmax)+rmin*(CB(:,jj)<rmin);
                        
                        if jj<=nage-1
                            
                            
                            %A(:,jj+1)=[ones(N,1) A(:,jj) Y(:,jj) C(:,jj)]*Res_assets+sqrt(sig_assets)*randn(N,1);
                            %A(:,jj+1)=log((1+.03)*exp(A(:,jj))+exp(Y(:,jj))-exp(C(:,jj)));
                            
                            
                            % standard asset accumulation rule, r=3. Assets >=0
                            if acc==2
                                AB(:,jj+1)=log(max((1+.03)*exp(AB(:,jj))+exp(YB(:,jj))-exp(CB(:,jj)),ones(NB,1)));
                            end
                            
                            % Predetermined assets
                            if acc==1
                                XXA=[];
                                for mm1=0:R1
                                    for mm2=0:R2
                                        for mm3=0:R3
                                            for mm4=0:R4
                                                for mm5=0:R5
                                                    XXA=[XXA hermite(mm1,(AB(:,jj)-meanA)/stdA).*hermite(mm2,(CB(:,jj)-meanC)/stdC).*hermite(mm3,(YB(:,jj)-meanY)/stdY)...
                                                        .*hermite(mm4,(Mateta_trueB(:,jj)-meanY)/stdY).*hermite(mm5,(aa-meanAGE)/stdAGE)];
                                                end
                                            end
                                        end
                                    end
                                end
                                
                                
                                AB(:,jj+1)=XXA*RestrueB_a2(1:(R1+1)*(R2+1)*(R3+1)*(R4+1)*(R5+1),1)+sqrt(RestrueB_a2((R1+1)*(R2+1)*(R3+1)*(R4+1)*(R5+1)+1,1))*randn(NB,1);
                                
                                % Restrict support of simulated assets
                                mmax=10;
                                mmin=-10;
                                AB(:,jj+1)=AB(:,jj+1).*(AB(:,jj+1)<=mmax).*(AB(:,jj+1)>=mmin)+...
                                    mmax*(AB(:,jj+1)>mmax)+mmin*(AB(:,jj+1)<mmin);
                                
                            end
                            
                            Mat=zeros(NB,(K1+1)*(K2+1));
                            for kk1=0:K1
                                for kk2=0:K2
                                    Mat(:,kk1*(K2+1)+kk2+1)=hermite(kk1,(Mateta_trueB(:,jj)-meanY)/stdY).*hermite(kk2,((aa+2)-meanAGE)/stdAGE);
                                end
                            end
                            
                            % age 37 receives shock tau0
                            if jj==1
                                V_draw=tau0*ones(NB,1);
                            else
                                V_draw=unifrnd(0,1,NB,1);
                            end
                            
                            %First quantile
                            
                            Mateta_trueB(:,jj+1)=(Mat*ResqtrueB(:,1)).*(V_draw<=Vectau(1));
                            for jtau=2:Ntau
                                Mateta_trueB(:,jj+1)=Mateta_trueB(:,jj+1)+...
                                    ((Mat*ResqtrueB(:,jtau)-Mat*ResqtrueB(:,jtau-1))/...
                                    (Vectau(jtau)-Vectau(jtau-1)).*...
                                    (V_draw-Vectau(jtau-1))+Mat*ResqtrueB(:,jtau-1)).*...
                                    (V_draw>Vectau(jtau-1)).*(V_draw<=Vectau(jtau));
                            end
                            %Last quantile.
                            Mateta_trueB(:,jj+1)=Mateta_trueB(:,jj+1)+(Mat*ResqtrueB(:,Ntau)).*...
                                (V_draw>Vectau(Ntau));
                            
                            % Laplace tails
                            Mateta_trueB(:,jj+1)=Mateta_trueB(:,jj+1)+((1/(b1trueB)*log(V_draw/Vectau(1))).*(V_draw<=Vectau(1))...
                                -(1/bLtrueB*log((1-V_draw)/(1-Vectau(Ntau)))).*(V_draw>Vectau(Ntau)));
                            
                            % Restrict support of simulated eta's
                            pmax=10;
                            pmin=-10;
                            Mateta_trueB(:,jj+1)=Mateta_trueB(:,jj+1).*(Mateta_trueB(:,jj+1)<=pmax).*(Mateta_trueB(:,jj+1)>=pmin)+...
                                pmax*(Mateta_trueB(:,jj+1)>pmax)+pmin*(Mateta_trueB(:,jj+1)<pmin);
                            
                        end
                    end
                    
                    
                    if jjtau_init==1 & jjtau_shock==1
                        ResbootIRY_1_1(jboot,:)=nanmedian(YB)-nanmedian(YB1);
                    elseif jjtau_init==1 & jjtau_shock==2
                        ResbootIRY_1_9(jboot,:)=nanmedian(YB)-nanmedian(YB1);
                    elseif jjtau_init==2 & jjtau_shock==1
                        ResbootIRY_5_1(jboot,:)=nanmedian(YB)-nanmedian(YB1);
                    elseif jjtau_init==2 & jjtau_shock==2
                        ResbootIRY_5_9(jboot,:)=nanmedian(YB)-nanmedian(YB1);
                    elseif jjtau_init==3 & jjtau_shock==1
                        ResbootIRY_9_1(jboot,:)=nanmedian(YB)-nanmedian(YB1);
                    elseif jjtau_init==3 & jjtau_shock==2
                        ResbootIRY_9_9(jboot,:)=nanmedian(YB)-nanmedian(YB1);
                    end
                    
                    
                    if acc==1
                        if jjtau_init==1 & jjtau_shock==1
                            ResbootIR_1_1_1(jboot,:)=nanmedian(CB)-nanmedian(CB1);
                        elseif jjtau_init==1 & jjtau_shock==2
                            ResbootIR_1_1_9(jboot,:)=nanmedian(CB)-nanmedian(CB1);
                        elseif jjtau_init==2 & jjtau_shock==1
                            ResbootIR_1_5_1(jboot,:)=nanmedian(CB)-nanmedian(CB1);
                        elseif jjtau_init==2 & jjtau_shock==2
                            ResbootIR_1_5_9(jboot,:)=nanmedian(CB)-nanmedian(CB1);
                        elseif jjtau_init==3 & jjtau_shock==1
                            ResbootIR_1_9_1(jboot,:)=nanmedian(CB)-nanmedian(CB1);
                        elseif jjtau_init==3 & jjtau_shock==2
                            ResbootIR_1_9_9(jboot,:)=nanmedian(CB)-nanmedian(CB1);
                        end
                    end
                    
                    if acc==2
                        if jjtau_init==1 & jjtau_shock==1
                            ResbootIR_2_1_1(jboot,:)=nanmedian(CB)-nanmedian(CB1);
                        elseif jjtau_init==1 & jjtau_shock==2
                            ResbootIR_2_1_9(jboot,:)=nanmedian(CB)-nanmedian(CB1);
                        elseif jjtau_init==2 & jjtau_shock==1
                            ResbootIR_2_5_1(jboot,:)=nanmedian(CB)-nanmedian(CB1);
                        elseif jjtau_init==2 & jjtau_shock==2
                            ResbootIR_2_5_9(jboot,:)=nanmedian(CB)-nanmedian(CB1);
                        elseif jjtau_init==3 & jjtau_shock==1
                            ResbootIR_2_9_1(jboot,:)=nanmedian(CB)-nanmedian(CB1);
                        elseif jjtau_init==3 & jjtau_shock==2
                            ResbootIR_2_9_9(jboot,:)=nanmedian(CB)-nanmedian(CB1);
                        end
                    end
                    
                    
                    
                end
            end
        end
        
        jboot=jboot+1;
        jboot
    end
    
end


            


toc

%save('Res_IR_npbootstrap1.mat')
