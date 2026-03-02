% Code for Arellano, Blundell and Bonhomme (2016), "Earnings and Consumption Dynamics: A Nonlinear Panel Data Framework"
% to appear in Econometrica

% This code estimates the consumption model in a model with unobserved heterogeneity

clear all
clc;

global Y C A N T Ntau Vectau b1_eps bL_eps b1 bL  bL_e0 K1 K2 M1 M2 M3 M4 M5 M6 M7 M8 M9 Mxi  R1 R2 R3 R4 R5 R6 ...
    AGE MatAGE_t MatAGE1 meanAGE stdAGE meanY stdY meanA stdA meanC stdC Resqfinal  Resqfinal_eps  Resqfinal_e0 Resinit Resinit_a1 Resinit_a2 Resinit_xi b1_a bL_a b1_xi bL_xi

load('data_hermite2.mat');

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
plot(Vectage,XX1*coeff)

% Regression of assets on a fourth order Hermite polynomial in age
coeff=pinv(XX)*A(:);
kappaA=XX*coeff;
for tt=1:T
    A(:,tt)=A(:,tt)-kappaA((tt-1)*N+1:tt*N);
end

plot(Vectage,XX1*coeff)

meanC=mean(C(:));
stdC=std(C(:));

meanA=mean(A(:));
stdA=std(A(:));


% Degrees Hermite polynomials
K1=3;
K2=2;
K3=2;
K4=2;

M1=2;
M2=2;
M3=1;
M4=1;
Mxi=1;
M5=1;
M6=1;
M7=1;
M8=1;
M9=1;

R1=1;
R2=1;
R3=1;
R4=1;
R5=1;
R6=1;


% Grid of tau's
Ntau=11;
Vectau=(1/(Ntau+1):1/(Ntau+1):Ntau/(Ntau+1))';


MatAGE1=[];
for kk3=0:K3
    MatAGE1=[MatAGE1 hermite(kk3,(AGE(:,1)-meanAGE)/stdAGE)];
end

MatAGE_t=[];
for kk4=0:K4
    MatAGE_t=[MatAGE_t hermite(kk4,(AGE(:)-meanAGE)/stdAGE)];
end




% seeds
rng('shuffle')

% Maximum Iteration
maxiter=50;

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

A1tot_t=kron(ones(Mdraws,1),A(:,1));

A2tot_t=kron(ones(Mdraws,1),A(:,2));
for j=3:T
    A2tot_t=[A2tot_t;kron(ones(Mdraws,1),A(:,j))];
end

A11tot_t=kron(ones(Mdraws,1),A(:,1));
for j=2:T-1
    A11tot_t=[A11tot_t;kron(ones(Mdraws,1),A(:,j))];
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
var_prop7=.10;

count=1;
deltapar=1;


% Initial conditions: consumption given assets, eta_t, epsilon_t

Resinit=zeros((M1+1)*(M2+1)*(M3+1)*(M4+1)*(Mxi+1)+1,1);

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

U=randn(N*T,1);
Y_t1=Y_t+U/2;
Y_t2=Y_t-U/2;

Cinit_t=meanC+stdC*randn(N,1);
Cinit_t=kron(ones(T,1),Cinit_t);


XX=[];
for mm1=0:M1
    for mm2=0:M2
        for mm3=0:M3
            for mm4=0:M4
                for mmxi=0:Mxi
                    XX=[XX hermite(mm1,(A_t-meanA)/stdA).*hermite(mm2,(Y_t1-meanY)/stdY).*hermite(mm3,(Y_t2-meanY)/stdY).*hermite(mm4,(AGE_tt-meanAGE)/stdAGE).*hermite(mmxi,(Cinit_t-meanC)/stdC)];
                end
            end
        end
    end
end



par=pinv(XX)*C_t;
parsig2=mean((C_t-XX*par).^2);
Resinit=[par;parsig2];

% Normalization

Q=kron(ones(1,(M1+1)*(M2+1)*(M3+1)*(M4+1)),eye(Mxi+1));
r=zeros(Mxi+1,1);
r(2)=1;
Resinit(1:(M1+1)*(M2+1)*(M3+1)*(M4+1)*(Mxi+1))=Resinit(1:(M1+1)*(M2+1)*(M3+1)*(M4+1)*(Mxi+1))...
    -Q'*inv(Q*Q')*(Q*Resinit(1:(M1+1)*(M2+1)*(M3+1)*(M4+1)*(Mxi+1))-r);


% Initial conditions: assets_t given assets_t-1, C_t-1, Y_t-1, eta_t-1, xi, AGE_t

Resinit_a2=zeros((R1+1)*(R2+1)*(R3+1)*(R4+1)*(R5+1)*(R6+1)+1,1);

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

C11=C(:,1);
for j=2:T-1
    C11=[C11;C(:,1)];
end



Y1_t=Y(:,1);
for j=2:T-1
    Y1_t=[Y1_t;Y(:,j)];
end

AGE2_t=AGE(:,2);
for j=3:T
    AGE2_t=[AGE2_t;AGE(:,j)];
end

U=randn(N*(T-1),1);
Y1_t1=Y1_t+U/2;

XXA=[];
for mm1=0:R1
    for mm2=0:R2
        for mm3=0:R3
            for mm4=0:R4
                for mm5=0:R5
                    for mm6=0:R6
                        XXA=[XXA hermite(mm1,(A1_t-meanA)/stdA).*hermite(mm2,(C1_t-meanC)/stdC).*hermite(mm3,(Y1_t-meanY)/stdY).*hermite(mm4,(Y1_t1-meanY)/stdY).*hermite(mm5,(C11-meanC)/stdC).*hermite(mm6,(AGE2_t-meanAGE)/stdAGE)];
                    end
                end
            end
        end
    end
end



par=pinv(XXA)*A2_t;
parsig2=mean((A2_t-XXA*par).^2);
Resinit_a2=[par;parsig2];




% Initial conditions: initial assets given eta_1

Resinit_a1=zeros((M5+1)*(M6+1),Ntau);

Mateta1=[]
for mm5=0:M5
    for mm6=0:M6
        Mateta1=[Mateta1 hermite(mm5,(Y(:,1)-meanY)/stdY).*hermite(mm6,(AGE(:,1)-meanAGE)/stdAGE)];
    end
end

for jtau=1:Ntau
    tau=Vectau(jtau);
    beta1=rq(Mateta1,A(:,1),tau);
    Resinit_a1(1:(M5+1)*(M6+1),jtau)=beta1;
end


% Initial conditions: household-specific effects given initial assets and eta_1

Resinit_xi=zeros((M7+1)*(M8+1)*(M9+1),Ntau);

Mata1eta1=[]
for mm7=0:M7
    for mm8=0:M8
        for mm9=0:M9
            Mata1eta1=[Mata1eta1 hermite(mm7,(A(:,1)-meanA)/stdA).*hermite(mm8,(Y(:,1)-meanY)/stdY).*hermite(mm9,(AGE(:,1)-meanAGE)/stdAGE)];
        end
    end
end

for jtau=1:Ntau
    tau=Vectau(jtau);
    beta1=rq(Mata1eta1,C(:,1),tau);
    Resinit_xi(1:(M7+1)*(M8+1)*(M9+1),jtau)=beta1;
end

% Initial conditions: Laplace parameters
b1_a=5;
bL_a=5;

b1_xi=5;
bL_xi=5;


mat_ba=zeros(maxiter,4);


%Resinit=Resinit+.1*randn((M1+1)*(M2+1)*(M3+1)*(M4+1)*(Mxi+1)+1,1);
%Resinit_a1=Resinit_a1+.1*randn((M5+1)*(M6+1),Ntau);
%Resinit_xi=Resinit_xi+.1*randn((M7+1)*(M8+1)*(M9+1),Ntau);


Resnew=zeros((M1+1)*(M2+1)*(M3+1)*(M4+1)*(Mxi+1)+1,maxiter);
Resnew_a1=zeros((M5+1)*(M6+1),Ntau,maxiter);
Resnew_a2=zeros((R1+1)*(R2+1)*(R3+1)*(R4+1)*(R5+1)*(R6+1)+1,maxiter);
Resnew_xi=zeros((M7+1)*(M8+1)*(M9+1),Ntau,maxiter);

init=randn(N,T+1);


Obj_chain = [postr_nonlinear_consumption_age_hermite_FE_predet(init) zeros(N,draws-1)];
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


for iter=1:maxiter
    iter
    
    %E step
    
    %%%%%%%%%%%%%%% Metropolis-Hastings %%%%%%%%%%%%%%%
    j = 2;
    while j <= draws
        
        
        Matdraw=zeros(N,T+1);
        
        Matdraw(:,1)=Nu_chain1(:,j-1);
        Matdraw(:,2)=Nu_chain2(:,j-1);
        Matdraw(:,3)=Nu_chain3(:,j-1);
        Matdraw(:,4)=Nu_chain4(:,j-1);
        Matdraw(:,5)=Nu_chain5(:,j-1);
        Matdraw(:,6)=Nu_chain6(:,j-1);
        Matdraw(:,7)=Nu_chain7(:,j-1);
        
        % eta_0
        Matdraw(:,1)=Nu_chain1(:,j-1)+sqrt(var_prop1)*randn(N,1);
        newObj=postr_nonlinear_consumption_age_hermite_FE_predet(Matdraw);
        r=(min([ones(N,1) newObj./Obj_chain(:,j-1)]'))';
        prob=rand(N,1);
        Obj_chain(:,j)=(prob<=r).*newObj+(prob>r).*Obj_chain(:,j-1);
        Nu_chain1(:,j)=(prob<=r).*Matdraw(:,1)+(prob>r).*Nu_chain1(:,j-1);
        Matdraw(:,1)=Nu_chain1(:,j);
        acc1(:,j)=(prob<=r);
        
        
        
        % eta_t
        Matdraw(:,2)=Nu_chain2(:,j-1)+sqrt(var_prop2)*randn(N,1);
        newObj=postr_nonlinear_consumption_age_hermite_FE_predet(Matdraw);
        r=(min([ones(N,1) newObj./Obj_chain(:,j)]'))';
        prob=rand(N,1);
        Obj_chain(:,j)=(prob<=r).*newObj+(prob>r).*Obj_chain(:,j);
        Nu_chain2(:,j)=(prob<=r).*Matdraw(:,2)+(prob>r).*Nu_chain2(:,j-1);
        Matdraw(:,2)=Nu_chain2(:,j);
        acc2(:,j)=(prob<=r);
        
        Matdraw(:,3)=Nu_chain3(:,j-1)+sqrt(var_prop3)*randn(N,1);
        newObj=postr_nonlinear_consumption_age_hermite_FE_predet(Matdraw);
        r=(min([ones(N,1) newObj./Obj_chain(:,j)]'))';
        prob=rand(N,1);
        Obj_chain(:,j)=(prob<=r).*newObj+(prob>r).*Obj_chain(:,j);
        Nu_chain3(:,j)=(prob<=r).*Matdraw(:,3)+(prob>r).*Nu_chain3(:,j-1);
        Matdraw(:,3)=Nu_chain3(:,j);
        acc3(:,j)=(prob<=r);
        
        Matdraw(:,4)=Nu_chain4(:,j-1)+sqrt(var_prop4)*randn(N,1);
        newObj=postr_nonlinear_consumption_age_hermite_FE_predet(Matdraw);
        r=(min([ones(N,1) newObj./Obj_chain(:,j)]'))';
        prob=rand(N,1);
        Obj_chain(:,j)=(prob<=r).*newObj+(prob>r).*Obj_chain(:,j);
        Nu_chain4(:,j)=(prob<=r).*Matdraw(:,4)+(prob>r).*Nu_chain4(:,j-1);
        Matdraw(:,4)=Nu_chain4(:,j);
        acc4(:,j)=(prob<=r);
        
        Matdraw(:,5)=Nu_chain5(:,j-1)+sqrt(var_prop5)*randn(N,1);
        newObj=postr_nonlinear_consumption_age_hermite_FE_predet(Matdraw);
        r=(min([ones(N,1) newObj./Obj_chain(:,j)]'))';
        prob=rand(N,1);
        Obj_chain(:,j)=(prob<=r).*newObj+(prob>r).*Obj_chain(:,j);
        Nu_chain5(:,j)=(prob<=r).*Matdraw(:,5)+(prob>r).*Nu_chain5(:,j-1);
        Matdraw(:,5)=Nu_chain5(:,j);
        acc5(:,j)=(prob<=r);
        
        Matdraw(:,6)=Nu_chain6(:,j-1)+sqrt(var_prop6)*randn(N,1);
        newObj=postr_nonlinear_consumption_age_hermite_FE_predet(Matdraw);
        r=(min([ones(N,1) newObj./Obj_chain(:,j)]'))';
        prob=rand(N,1);
        Obj_chain(:,j)=(prob<=r).*newObj+(prob>r).*Obj_chain(:,j);
        Nu_chain6(:,j)=(prob<=r).*Matdraw(:,6)+(prob>r).*Nu_chain6(:,j-1);
        Matdraw(:,6)=Nu_chain6(:,j);
        acc6(:,j)=(prob<=r);
        
        % Household-specific effect
        
        Matdraw(:,7)=Nu_chain7(:,j-1)+sqrt(var_prop7)*randn(N,1);
        newObj=postr_nonlinear_consumption_age_hermite_FE_predet(Matdraw);
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
    
    Matdraw1=Matdraw(:,1:T);
    Matdraw_t=Matdraw1(:);
    
    Matdraw2=Matdraw(:,T+1);
    Matdraw_FE_t=kron(ones(T,1),Matdraw2);
    
    
    Matdraw11=Matdraw(:,1:T-1);
    Matdraw1_t=Matdraw11(:);
    Matdraw1_FE_t=kron(ones(T-1,1),Matdraw2);
    
    
    % Consumption rule
    
    XX=[];
    for mm1=0:M1
        for mm2=0:M2
            for mm3=0:M3
                for mm4=0:M4
                    for mmxi=0:Mxi
                        XX=[XX hermite(mm1,(Atot_t-meanA)/stdA).*hermite(mm2,(Matdraw_t-meanY)/stdY).*hermite(mm3,(Ytot_t-Matdraw_t-meanY)/stdY)...
                            .*hermite(mm4,(AGEtot_t-meanAGE)/stdAGE).*hermite(mmxi,(Matdraw_FE_t-meanC)/stdC)];
                    end
                end
            end
        end
    end
    
    
    
    Resnew(1:(M1+1)*(M2+1)*(M3+1)*(M4+1)*(Mxi+1),iter)=pinv(XX)*Ctot_t;
    
    %  Normalization: constrained least squares
    Q=kron(ones(1,(M1+1)*(M2+1)*(M3+1)*(M4+1)),eye(Mxi+1));
    
    Vect_norm=[];
    for mm1=0:M1
        for mm2=0:M2
            for mm3=0:M3
                for mm4=0:M4
                    
                    Vect_norm=[Vect_norm hermite(mm1,0).*hermite(mm2,0).*hermite(mm3,0)...
                        .*hermite(mm4,0)];
                end
            end
        end
    end
    
    Q=Q.*(kron(Vect_norm,eye(Mxi+1)));
    
    r=zeros(Mxi+1,1);
    r(2)=1;
    Resnew(1:(M1+1)*(M2+1)*(M3+1)*(M4+1)*(Mxi+1),iter)=Resnew(1:(M1+1)*(M2+1)*(M3+1)*(M4+1)*(Mxi+1),iter)...
        -inv(XX'*XX)*Q'*inv(Q*inv(XX'*XX)*Q')*(Q*Resnew(1:(M1+1)*(M2+1)*(M3+1)*(M4+1)*(Mxi+1),iter)-r);
    
    Q*Resnew(1:(M1+1)*(M2+1)*(M3+1)*(M4+1)*(Mxi+1),iter)
    
    
   
    Resnew((M1+1)*(M2+1)*(M3+1)*(M4+1)*(Mxi+1)+1,iter)=mean((Ctot_t-XX*Resnew(1:(M1+1)*(M2+1)*(M3+1)*(M4+1)*(Mxi+1),iter)).^2);
    
    % Predetermined assets
    
    XXA=[];
    for mm1=0:R1
        for mm2=0:R2
            for mm3=0:R3
                for mm4=0:R4
                    for mm5=0:R5
                        for mm6=0:R6
                            XXA=[XXA hermite(mm1,(A11tot_t-meanA)/stdA).*hermite(mm2,(C1tot_t-meanC)/stdC).*hermite(mm3,(Y1tot_t-meanY)/stdY)...
                                .*hermite(mm4,(Matdraw1_t-meanY)/stdY).*hermite(mm5,(Matdraw1_FE_t-meanC)/stdC).*hermite(mm6,(AGE2tot_t-meanAGE)/stdAGE)];
                        end
                    end
                end
            end
        end
    end
    
    
    
    Resnew_a2(1:(R1+1)*(R2+1)*(R3+1)*(R4+1)*(R5+1)*(R6+1),iter)=pinv(XXA)*A2tot_t;
    Resnew_a2((R1+1)*(R2+1)*(R3+1)*(R4+1)*(R5+1)*(R6+1)+1,iter)=mean((A2tot_t-XXA*Resnew_a2(1:(R1+1)*(R2+1)*(R3+1)*(R4+1)*(R5+1)*(R6+1),iter)).^2);
    
    
    
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
    
    % Household-specific fixed-effects
    
    Mata1eta1=[]
    for mm7=0:M7
        for mm8=0:M8
            for mm9=0:M9
                Mata1eta1=[Mata1eta1 hermite(mm7,(A1tot_t-meanA)/stdA).*hermite(mm8,(Matdraw(:,1)-meanY)/stdY).*hermite(mm9,(AGEtot_t(1:N*Mdraws,1)-meanAGE)/stdAGE)];
            end
        end
    end
    
    
    
   
    
    for jtau=1:Ntau
        tau=Vectau(jtau);
        beta1=rq(Mata1eta1,Matdraw2,tau);
        Resnew_xi(1:(M7+1)*(M8+1)*(M9+1),jtau,iter)=beta1;
    end
    
    
    % Initial assets: Laplace parameters
    
    Vect1=Matdraw2-Mata1eta1*Resnew_xi(:,1,iter);
    Vect2=Matdraw2-Mata1eta1*Resnew_xi(:,Ntau,iter);
    b1_xi=-sum(Vect1<=0)/sum(Vect1.*(Vect1<=0));
    bL_xi=sum(Vect2>=0)/sum(Vect2.*(Vect2>=0));
    
    
    mat_ba(iter,1)=b1_a;
    mat_ba(iter,2)=bL_a;
    
    mat_ba(iter,3)=b1_xi;
    mat_ba(iter,4)=bL_xi;
    
    b1_a
    bL_a
    
    b1_xi
    bL_xi
    
    
   
    % complete likelihood
    mat_lik(iter)=nanmean(log(postr_nonlinear_consumption_age_hermite_FE_predet(Matdraw)));
    
    disp('FE')
    mean(Matdraw2)
    std(Matdraw2)
    
    
    
    % Criterion
    
    
    Resinit=Resnew(:,iter)
    Resinit_a1=Resnew_a1(:,:,iter)
    Resinit_a2=Resnew_a2(:,iter)
    Resinit_xi=Resnew_xi(:,:,iter)
  
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



Resfinal=zeros((M1+1)*(M2+1)*(M3+1)*(M4+1)*(Mxi+1)+1,1);
for p=1:(M1+1)*(M2+1)*(M3+1)*(M4+1)*(Mxi+1)+1
    Resfinal(p,1)=mean(Resnew(p,(maxiter/2):maxiter));
end

Resfinal_a1=zeros((M5+1)*(M6+1),Ntau);
for jtau=1:Ntau
    for p=1:(M5+1)*(M6+1)
        Resfinal_a1(p,jtau)=mean(Resnew_a1(p,jtau,(maxiter/2):maxiter));
    end
end

Resfinal_a2=zeros((R1+1)*(R2+1)*(R3+1)*(R4+1)*(R5+1)*(R6+1)+1,1);
for p=1:(R1+1)*(R2+1)*(R3+1)*(R4+1)*(R5+1)*(R6+1)+1
    Resfinal_a2(p,1)=mean(Resnew_a2(p,(maxiter/2):maxiter));
end

Resfinal_xi=zeros((M7+1)*(M8+1)*(M9+1),Ntau);
for jtau=1:Ntau
    for p=1:(M7+1)*(M8+1)*(M9+1)
        Resfinal_xi(p,jtau)=mean(Resnew_xi(p,jtau,(maxiter/2):maxiter));
    end
end


b1_a=mean(mat_ba((maxiter/2):maxiter,1));
bL_a=mean(mat_ba((maxiter/2):maxiter,2));
b1_xi=mean(mat_ba((maxiter/2):maxiter,3));
bL_xi=mean(mat_ba((maxiter/2):maxiter,4));

%save('data_hermite_cons_FE_newnorm.mat');


