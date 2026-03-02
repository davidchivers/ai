% Code for Arellano, Blundell and Bonhomme (2016), "Earnings and Consumption Dynamics: A Nonlinear Panel Data Framework"
% to appear in Econometrica

% This code produces the impulse responses in the model with unobserved heterogeneity in consumption, for old and young households, by assets levels. 
% Linear assets rule is acc=2, nonlinear assets rule is acc=1.
% Different graphs are obtained by varying tau_init and tau_shock.


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




% seeds
rng('shuffle')

% Number of individuals
N=100000;

% un-comment if "young"
%  aa_ref=35;
%  nage=13;

% un-commment if "old"
 aa_ref=51;
 nage=5;

tau_init=.9;
tau_shock=.1;

% Assets accumulation: 1 means predetermined assets, 2 means standard
% linear assets accumulation rule with r=3/% and assets >=0
acc=2;

% floor on assets (=1 in the results in the paper)
floor_par=1;
% optional: vary the floor on assets
% Note: in this case some results are more sensitive to variation in the floor
% floor_par=.01;


% Keep only tau1-percentile of initial eta ("tau_init")

tau1=tau_init;

% Proposal, eta_1
V_draw=unifrnd(0,1,N,1);

MatAGE1=[];
for kk3=0:K3
    MatAGE1=[MatAGE1 hermite(kk3,(aa_ref-meanAGE)/stdAGE)];
end

Mateta_true=zeros(N,nage);
Mateps_true=zeros(N,nage);
Y=zeros(N,nage);
C=zeros(N,nage);
A=zeros(N,nage);



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

% Initial eta

eta_1=quantile(Mateta_true(:,1),tau1);

Mateta_true(:,1)=eta_1;

% Initial assets


Mateta1=[];
for mm5=0:M5
    for mm6=0:M6
        Mateta1=[Mateta1 hermite(mm5,(Mateta_true(:,1)-meanY)/stdY).*hermite(mm6,(aa_ref-meanAGE)/stdAGE)];
    end
end



% Percentile initial assets
tau3=.10;
V_draw=tau3;

% Proposal, a1


%First quantile
A(:,1)=(Mateta1*Restrue_a1(:,1)).*(V_draw<=Vectau(1));
for jtau=2:Ntau
    A(:,1)=A(:,1)+((Mateta1*(Restrue_a1(:,jtau)-Restrue_a1(:,jtau-1)))/(Vectau(jtau)-Vectau(jtau-1)).*...
        (V_draw-Vectau(jtau-1))+Mateta1*Restrue_a1(:,jtau-1)).*(V_draw>Vectau(jtau-1)).*(V_draw<=Vectau(jtau));
end
%Last quantile.
A(:,1)=A(:,1)+(Mateta1*Restrue_a1(:,Ntau)).*(V_draw>Vectau(Ntau));

% Laplace tails
A(:,1)=A(:,1)+((1/(b1true_a)*log(V_draw/Vectau(1))).*(V_draw<=Vectau(1))...
    -(1/bLtrue_a*log((1-V_draw)/(1-Vectau(Ntau)))).*(V_draw>Vectau(Ntau)));


% Fix household-specific effect
Indiv=0*ones(N,1);


%%%% FIRST SIMULATION

% percentile of initial shock
tau0=.50;

for jj=1:nage
    
    aa=aa_ref+(jj-1)*2;
    
    MatAGE1=[];
    for kk3=0:K3
        MatAGE1=[MatAGE1 hermite(kk3,(aa-meanAGE)/stdAGE)];
    end
    
    % epsilons
    
    MatAGE_t=[];
    for kk4=0:K4
        MatAGE_t=[MatAGE_t hermite(kk4,(aa-meanAGE)/stdAGE)];
    end
    
    
    
    % Proposal, eta_0
    V_draw=unifrnd(0,1,N,1);
    
    %First quantile
    Mateps_true(:,jj)=(MatAGE_t*Resqtrue_eps(:,1)).*(V_draw<=Vectau(1));
    for jtau=2:Ntau
        Mateps_true(:,jj)=Mateps_true(:,jj)+((MatAGE_t*(Resqtrue_eps(:,jtau)-Resqtrue_eps(:,jtau-1)))/(Vectau(jtau)-Vectau(jtau-1)).*...
            (V_draw-Vectau(jtau-1))+MatAGE_t*Resqtrue_eps(:,jtau-1)).*(V_draw>Vectau(jtau-1)).*(V_draw<=Vectau(jtau));
    end
    %Last quantile.
    Mateps_true(:,jj)=Mateps_true(:,jj)+(MatAGE_t*Resqtrue_eps(:,Ntau)).*(V_draw>Vectau(Ntau));
    
    % Laplace tails
    Mateps_true(:,jj)=Mateps_true(:,jj)+((1/(b1true_eps)*log(V_draw/Vectau(1))).*(V_draw<=Vectau(1))...
        -(1/bLtrue_eps*log((1-V_draw)/(1-Vectau(Ntau)))).*(V_draw>Vectau(Ntau)));
    
    
    
    % Earnings
    
    Y(:,jj)=Mateta_true(:,jj)+Mateps_true(:,jj);
    
    
    
    
    % Assets and consumption
    
    
    XX=[];
    for mm1=0:M1
        for mm2=0:M2
            for mm3=0:M3
                for mm4=0:M4
                    for mmxi=0:Mxi
                        XX=[XX hermite(mm1,(A(:,jj)-meanA)/stdA).*hermite(mm2,(Mateta_true(:,jj)-meanY)/stdY).*hermite(mm3,(Y(:,jj)-Mateta_true(:,jj)-meanY)/stdY)...
                            .*hermite(mm4,(aa-meanAGE)/stdAGE).*hermite(mmxi,(Indiv-meanC)/stdC)];
                    end
                end
            end
        end
    end
    
    C(:,jj)=XX*Restrue(1:(M1+1)*(M2+1)*(M3+1)*(M4+1)*(Mxi+1),1)+sqrt(Restrue((M1+1)*(M2+1)*(M3+1)*(M4+1)*(Mxi+1)+1))*randn(N,1);
    
    
    
    % Restrict support of simulated consumption
    rmax=5;
    rmin=-5;
    C(:,jj)=C(:,jj).*(C(:,jj)<=rmax).*(C(:,jj)>=rmin)+...
        rmax*(C(:,jj)>rmax)+rmin*(C(:,jj)<rmin);
    
    if jj<=nage-1
        
        
 
        % standard asset accumulation rule, r=3. Assets >=0
        if acc==2
            A(:,jj+1)=log(max((1+.03)*exp(A(:,jj))+exp(Y(:,jj))-exp(C(:,jj)),floor_par*ones(N,1)));
        end
        
        % Predetermined assets
        if acc==1
            XXA=[];
            for mm1=0:R1
                for mm2=0:R2
                    for mm3=0:R3
                        for mm4=0:R4
                            for mm5=0:R5
                                for mm6=0:R6
                                    XXA=[XXA hermite(mm1,(A(:,jj)-meanA)/stdA).*hermite(mm2,(C(:,jj)-meanC)/stdC).*hermite(mm3,(Y(:,jj)-meanY)/stdY)...
                                        .*hermite(mm4,(Mateta_true(:,jj)-meanY)/stdY).*hermite(mm5,(Indiv-meanC)/stdC).*hermite(mm6,(aa-meanAGE)/stdAGE)];
                                end
                            end
                        end
                    end
                end
            end
            
            
            A(:,jj+1)=XXA*Restrue_a2(1:(R1+1)*(R2+1)*(R3+1)*(R4+1)*(R5+1)*(R6+1),1)+sqrt(Restrue_a2((R1+1)*(R2+1)*(R3+1)*(R4+1)*(R5+1)*(R6+1)+1,1))*randn(N,1);
            
            % Restrict support of simulated assets
            mmax=10;
            mmin=-10;
            A(:,jj+1)=A(:,jj+1).*(A(:,jj+1)<=mmax).*(A(:,jj+1)>=mmin)+...
                mmax*(A(:,jj+1)>mmax)+mmin*(A(:,jj+1)<mmin);
        end
        
        Mat=zeros(N,(K1+1)*(K2+1));
        for kk1=0:K1
            for kk2=0:K2
                Mat(:,kk1*(K2+1)+kk2+1)=hermite(kk1,(Mateta_true(:,jj)-meanY)/stdY).*hermite(kk2,((aa+2)-meanAGE)/stdAGE);
            end
        end
        
        % age 37 receives shock tau0
        if jj==1
            V_draw=tau0*ones(N,1);
        else
            V_draw=unifrnd(0,1,N,1);
        end
        
        %First quantile
        
        Mateta_true(:,jj+1)=(Mat*Resqtrue(:,1)).*(V_draw<=Vectau(1));
        for jtau=2:Ntau
            Mateta_true(:,jj+1)=Mateta_true(:,jj+1)+...
                ((Mat*Resqtrue(:,jtau)-Mat*Resqtrue(:,jtau-1))/...
                (Vectau(jtau)-Vectau(jtau-1)).*...
                (V_draw-Vectau(jtau-1))+Mat*Resqtrue(:,jtau-1)).*...
                (V_draw>Vectau(jtau-1)).*(V_draw<=Vectau(jtau));
        end
        %Last quantile.
        Mateta_true(:,jj+1)=Mateta_true(:,jj+1)+(Mat*Resqtrue(:,Ntau)).*...
            (V_draw>Vectau(Ntau));
        
        % Laplace tails
        Mateta_true(:,jj+1)=Mateta_true(:,jj+1)+((1/(b1true)*log(V_draw/Vectau(1))).*(V_draw<=Vectau(1))...
            -(1/bLtrue*log((1-V_draw)/(1-Vectau(Ntau)))).*(V_draw>Vectau(Ntau)));
        
        % Restrict support of simulated eta's
        pmax=10;
        pmin=-10;
        Mateta_true(:,jj+1)=Mateta_true(:,jj+1).*(Mateta_true(:,jj+1)<=pmax).*(Mateta_true(:,jj+1)>=pmin)+...
            pmax*(Mateta_true(:,jj+1)>pmax)+pmin*(Mateta_true(:,jj+1)<pmin);
        
        
    end
end

Y1=Y;
C1=C;
A1=A;
Mateta_true1=Mateta_true;

%%%% SECOND SIMULATION

% percentile of initial shock ("tau_shock")
tau0=tau_shock;

for jj=1:nage
    
    aa=aa_ref+(jj-1)*2;
    
   
    
    MatAGE1=[];
    for kk3=0:K3
        MatAGE1=[MatAGE1 hermite(kk3,(aa-meanAGE)/stdAGE)];
    end
    
    % epsilons
    
    MatAGE_t=[];
    for kk4=0:K4
        MatAGE_t=[MatAGE_t hermite(kk4,(aa-meanAGE)/stdAGE)];
    end
    
    
    
    % Proposal, eta_0
    V_draw=unifrnd(0,1,N,1);
    
    %First quantile
    Mateps_true(:,jj)=(MatAGE_t*Resqtrue_eps(:,1)).*(V_draw<=Vectau(1));
    for jtau=2:Ntau
        Mateps_true(:,jj)=Mateps_true(:,jj)+((MatAGE_t*(Resqtrue_eps(:,jtau)-Resqtrue_eps(:,jtau-1)))/(Vectau(jtau)-Vectau(jtau-1)).*...
            (V_draw-Vectau(jtau-1))+MatAGE_t*Resqtrue_eps(:,jtau-1)).*(V_draw>Vectau(jtau-1)).*(V_draw<=Vectau(jtau));
    end
    %Last quantile.
    Mateps_true(:,jj)=Mateps_true(:,jj)+(MatAGE_t*Resqtrue_eps(:,Ntau)).*(V_draw>Vectau(Ntau));
    
    % Laplace tails
    Mateps_true(:,jj)=Mateps_true(:,jj)+((1/(b1true_eps)*log(V_draw/Vectau(1))).*(V_draw<=Vectau(1))...
        -(1/bLtrue_eps*log((1-V_draw)/(1-Vectau(Ntau)))).*(V_draw>Vectau(Ntau)));
    
    
    
    % Earnings
    
    Y(:,jj)=Mateta_true(:,jj)+Mateps_true(:,jj);
    
    
    % Assets and consumption
    
    
    XX=[];
    for mm1=0:M1
        for mm2=0:M2
            for mm3=0:M3
                for mm4=0:M4
                    for mmxi=0:Mxi
                        XX=[XX hermite(mm1,(A(:,jj)-meanA)/stdA).*hermite(mm2,(Mateta_true(:,jj)-meanY)/stdY).*hermite(mm3,(Y(:,jj)-Mateta_true(:,jj)-meanY)/stdY)...
                            .*hermite(mm4,(aa-meanAGE)/stdAGE).*hermite(mmxi,(Indiv-meanC)/stdC)];
                    end
                end
            end
        end
    end
    
    C(:,jj)=XX*Restrue(1:(M1+1)*(M2+1)*(M3+1)*(M4+1)*(Mxi+1),1)+sqrt(Restrue((M1+1)*(M2+1)*(M3+1)*(M4+1)*(Mxi+1)+1))*randn(N,1);
    
    
    
    % Restrict support of simulated consumption
    rmax=5;
    rmin=-5;
    C(:,jj)=C(:,jj).*(C(:,jj)<=rmax).*(C(:,jj)>=rmin)+...
        rmax*(C(:,jj)>rmax)+rmin*(C(:,jj)<rmin);
    
    if jj<=nage-1
        
        
     
         % standard asset accumulation rule, r=3. Assets >=0
        if acc==2
            A(:,jj+1)=log(max((1+.03)*exp(A(:,jj))+exp(Y(:,jj))-exp(C(:,jj)),floor_par*ones(N,1)));
        end
        
        % Predetermined assets
        if acc==1
            XXA=[];
            for mm1=0:R1
                for mm2=0:R2
                    for mm3=0:R3
                        for mm4=0:R4
                            for mm5=0:R5
                                for mm6=0:R6
                                    XXA=[XXA hermite(mm1,(A(:,jj)-meanA)/stdA).*hermite(mm2,(C(:,jj)-meanC)/stdC).*hermite(mm3,(Y(:,jj)-meanY)/stdY)...
                                        .*hermite(mm4,(Mateta_true(:,jj)-meanY)/stdY).*hermite(mm5,(Indiv-meanC)/stdC).*hermite(mm6,(aa-meanAGE)/stdAGE)];
                                end
                            end
                        end
                    end
                end
            end
            
            
            A(:,jj+1)=XXA*Restrue_a2(1:(R1+1)*(R2+1)*(R3+1)*(R4+1)*(R5+1)*(R6+1),1)+sqrt(Restrue_a2((R1+1)*(R2+1)*(R3+1)*(R4+1)*(R5+1)*(R6+1)+1,1))*randn(N,1);
            
            % Restrict support of simulated assets
            mmax=10;
            mmin=-10;
            A(:,jj+1)=A(:,jj+1).*(A(:,jj+1)<=mmax).*(A(:,jj+1)>=mmin)+...
                mmax*(A(:,jj+1)>mmax)+mmin*(A(:,jj+1)<mmin);
        end
     
        Mat=zeros(N,(K1+1)*(K2+1));
        for kk1=0:K1
            for kk2=0:K2
                Mat(:,kk1*(K2+1)+kk2+1)=hermite(kk1,(Mateta_true(:,jj)-meanY)/stdY).*hermite(kk2,((aa+2)-meanAGE)/stdAGE);
            end
        end
        
        % age 37 receives shock tau0
        if jj==1
            V_draw=tau0*ones(N,1);
        else
            V_draw=unifrnd(0,1,N,1);
        end
        
        %First quantile
        
        Mateta_true(:,jj+1)=(Mat*Resqtrue(:,1)).*(V_draw<=Vectau(1));
        for jtau=2:Ntau
            Mateta_true(:,jj+1)=Mateta_true(:,jj+1)+...
                ((Mat*Resqtrue(:,jtau)-Mat*Resqtrue(:,jtau-1))/...
                (Vectau(jtau)-Vectau(jtau-1)).*...
                (V_draw-Vectau(jtau-1))+Mat*Resqtrue(:,jtau-1)).*...
                (V_draw>Vectau(jtau-1)).*(V_draw<=Vectau(jtau));
        end
        %Last quantile.
        Mateta_true(:,jj+1)=Mateta_true(:,jj+1)+(Mat*Resqtrue(:,Ntau)).*...
            (V_draw>Vectau(Ntau));
        
        % Laplace tails
        Mateta_true(:,jj+1)=Mateta_true(:,jj+1)+((1/(b1true)*log(V_draw/Vectau(1))).*(V_draw<=Vectau(1))...
            -(1/bLtrue*log((1-V_draw)/(1-Vectau(Ntau)))).*(V_draw>Vectau(Ntau)));
        
        % Restrict support of simulated eta's
        pmax=10;
        pmin=-10;
        Mateta_true(:,jj+1)=Mateta_true(:,jj+1).*(Mateta_true(:,jj+1)<=pmax).*(Mateta_true(:,jj+1)>=pmin)+...
            pmax*(Mateta_true(:,jj+1)>pmax)+pmin*(Mateta_true(:,jj+1)<pmin);
        
    end
end

figure
plot((aa_ref:2:59)',[nanmedian(Y)'-nanmedian(Y1)'])
figure
plot((aa_ref:2:59)',[nanmedian(C)'-nanmedian(C1)'])
figure
plot((aa_ref:2:59)',[nanmedian(A)'-nanmedian(A1)'])

fig_Y=nanmedian(Y)'-nanmedian(Y1)';
fig_C=nanmedian(C)'-nanmedian(C1)';



% Percentile initial assets
tau3=.90;
V_draw=tau3;

% Proposal, a1


%First quantile
A(:,1)=(Mateta1*Restrue_a1(:,1)).*(V_draw<=Vectau(1));
for jtau=2:Ntau
    A(:,1)=A(:,1)+((Mateta1*(Restrue_a1(:,jtau)-Restrue_a1(:,jtau-1)))/(Vectau(jtau)-Vectau(jtau-1)).*...
        (V_draw-Vectau(jtau-1))+Mateta1*Restrue_a1(:,jtau-1)).*(V_draw>Vectau(jtau-1)).*(V_draw<=Vectau(jtau));
end
%Last quantile.
A(:,1)=A(:,1)+(Mateta1*Restrue_a1(:,Ntau)).*(V_draw>Vectau(Ntau));

% Laplace tails
A(:,1)=A(:,1)+((1/(b1true_a)*log(V_draw/Vectau(1))).*(V_draw<=Vectau(1))...
    -(1/bLtrue_a*log((1-V_draw)/(1-Vectau(Ntau)))).*(V_draw>Vectau(Ntau)));

% Fix household-specific effect
Indiv=0*ones(N,1);




%%%% FIRST SIMULATION

% percentile of initial shock
tau0=.50;

for jj=1:nage
    
    aa=aa_ref+(jj-1)*2;
    
    MatAGE1=[];
    for kk3=0:K3
        MatAGE1=[MatAGE1 hermite(kk3,(aa-meanAGE)/stdAGE)];
    end
    
    % epsilons
    
    MatAGE_t=[];
    for kk4=0:K4
        MatAGE_t=[MatAGE_t hermite(kk4,(aa-meanAGE)/stdAGE)];
    end
    
    
    
    % Proposal, eta_0
    V_draw=unifrnd(0,1,N,1);
    
    %First quantile
    Mateps_true(:,jj)=(MatAGE_t*Resqtrue_eps(:,1)).*(V_draw<=Vectau(1));
    for jtau=2:Ntau
        Mateps_true(:,jj)=Mateps_true(:,jj)+((MatAGE_t*(Resqtrue_eps(:,jtau)-Resqtrue_eps(:,jtau-1)))/(Vectau(jtau)-Vectau(jtau-1)).*...
            (V_draw-Vectau(jtau-1))+MatAGE_t*Resqtrue_eps(:,jtau-1)).*(V_draw>Vectau(jtau-1)).*(V_draw<=Vectau(jtau));
    end
    %Last quantile.
    Mateps_true(:,jj)=Mateps_true(:,jj)+(MatAGE_t*Resqtrue_eps(:,Ntau)).*(V_draw>Vectau(Ntau));
    
    % Laplace tails
    Mateps_true(:,jj)=Mateps_true(:,jj)+((1/(b1true_eps)*log(V_draw/Vectau(1))).*(V_draw<=Vectau(1))...
        -(1/bLtrue_eps*log((1-V_draw)/(1-Vectau(Ntau)))).*(V_draw>Vectau(Ntau)));
    
    
    
    % Earnings
    
    Y(:,jj)=Mateta_true(:,jj)+Mateps_true(:,jj);
    
    
    
    
    % Assets and consumption
    
    
    XX=[];
    for mm1=0:M1
        for mm2=0:M2
            for mm3=0:M3
                for mm4=0:M4
                    for mmxi=0:Mxi
                        XX=[XX hermite(mm1,(A(:,jj)-meanA)/stdA).*hermite(mm2,(Mateta_true(:,jj)-meanY)/stdY).*hermite(mm3,(Y(:,jj)-Mateta_true(:,jj)-meanY)/stdY)...
                            .*hermite(mm4,(aa-meanAGE)/stdAGE).*hermite(mmxi,(Indiv-meanC)/stdC)];
                    end
                end
            end
        end
    end
    
    C(:,jj)=XX*Restrue(1:(M1+1)*(M2+1)*(M3+1)*(M4+1)*(Mxi+1),1)+sqrt(Restrue((M1+1)*(M2+1)*(M3+1)*(M4+1)*(Mxi+1)+1))*randn(N,1);
    
    
    
    % Restrict support of simulated consumption
    rmax=5;
    rmin=-5;
    C(:,jj)=C(:,jj).*(C(:,jj)<=rmax).*(C(:,jj)>=rmin)+...
        rmax*(C(:,jj)>rmax)+rmin*(C(:,jj)<rmin);
    
    if jj<=nage-1
        
        
   
        % standard asset accumulation rule, r=3. Assets >=0
        if acc==2
            A(:,jj+1)=log(max((1+.03)*exp(A(:,jj))+exp(Y(:,jj))-exp(C(:,jj)),floor_par*ones(N,1)));
        end
        
        % Predetermined assets
        if acc==1
            XXA=[];
            for mm1=0:R1
                for mm2=0:R2
                    for mm3=0:R3
                        for mm4=0:R4
                            for mm5=0:R5
                                for mm6=0:R6
                                    XXA=[XXA hermite(mm1,(A(:,jj)-meanA)/stdA).*hermite(mm2,(C(:,jj)-meanC)/stdC).*hermite(mm3,(Y(:,jj)-meanY)/stdY)...
                                        .*hermite(mm4,(Mateta_true(:,jj)-meanY)/stdY).*hermite(mm5,(Indiv-meanC)/stdC).*hermite(mm6,(aa-meanAGE)/stdAGE)];
                                end
                            end
                        end
                    end
                end
            end
            
            
            A(:,jj+1)=XXA*Restrue_a2(1:(R1+1)*(R2+1)*(R3+1)*(R4+1)*(R5+1)*(R6+1),1)+sqrt(Restrue_a2((R1+1)*(R2+1)*(R3+1)*(R4+1)*(R5+1)*(R6+1)+1,1))*randn(N,1);
            
            % Restrict support of simulated assets
            mmax=10;
            mmin=-10;
            A(:,jj+1)=A(:,jj+1).*(A(:,jj+1)<=mmax).*(A(:,jj+1)>=mmin)+...
                mmax*(A(:,jj+1)>mmax)+mmin*(A(:,jj+1)<mmin);
        end
       
        Mat=zeros(N,(K1+1)*(K2+1));
        for kk1=0:K1
            for kk2=0:K2
                Mat(:,kk1*(K2+1)+kk2+1)=hermite(kk1,(Mateta_true(:,jj)-meanY)/stdY).*hermite(kk2,((aa+2)-meanAGE)/stdAGE);
            end
        end
        
        % age 37 receives shock tau0
        if jj==1
            V_draw=tau0*ones(N,1);
        else
            V_draw=unifrnd(0,1,N,1);
        end
        
        %First quantile
        
        Mateta_true(:,jj+1)=(Mat*Resqtrue(:,1)).*(V_draw<=Vectau(1));
        for jtau=2:Ntau
            Mateta_true(:,jj+1)=Mateta_true(:,jj+1)+...
                ((Mat*Resqtrue(:,jtau)-Mat*Resqtrue(:,jtau-1))/...
                (Vectau(jtau)-Vectau(jtau-1)).*...
                (V_draw-Vectau(jtau-1))+Mat*Resqtrue(:,jtau-1)).*...
                (V_draw>Vectau(jtau-1)).*(V_draw<=Vectau(jtau));
        end
        %Last quantile.
        Mateta_true(:,jj+1)=Mateta_true(:,jj+1)+(Mat*Resqtrue(:,Ntau)).*...
            (V_draw>Vectau(Ntau));
        
        % Laplace tails
        Mateta_true(:,jj+1)=Mateta_true(:,jj+1)+((1/(b1true)*log(V_draw/Vectau(1))).*(V_draw<=Vectau(1))...
            -(1/bLtrue*log((1-V_draw)/(1-Vectau(Ntau)))).*(V_draw>Vectau(Ntau)));
        
        % Restrict support of simulated eta's
        pmax=10;
        pmin=-10;
        Mateta_true(:,jj+1)=Mateta_true(:,jj+1).*(Mateta_true(:,jj+1)<=pmax).*(Mateta_true(:,jj+1)>=pmin)+...
            pmax*(Mateta_true(:,jj+1)>pmax)+pmin*(Mateta_true(:,jj+1)<pmin);
        
        
    end
end

Y1=Y;
C1=C;
A1=A;
Mateta_true1=Mateta_true;

%%%% SECOND SIMULATION

% percentile of initial shock ("tau_shock")
tau0=tau_shock;

for jj=1:nage
    
    aa=aa_ref+(jj-1)*2;
    
   
    
    MatAGE1=[];
    for kk3=0:K3
        MatAGE1=[MatAGE1 hermite(kk3,(aa-meanAGE)/stdAGE)];
    end
    
    % epsilons
    
    MatAGE_t=[];
    for kk4=0:K4
        MatAGE_t=[MatAGE_t hermite(kk4,(aa-meanAGE)/stdAGE)];
    end
    
    
    
    % Proposal, eta_0
    V_draw=unifrnd(0,1,N,1);
    
    %First quantile
    Mateps_true(:,jj)=(MatAGE_t*Resqtrue_eps(:,1)).*(V_draw<=Vectau(1));
    for jtau=2:Ntau
        Mateps_true(:,jj)=Mateps_true(:,jj)+((MatAGE_t*(Resqtrue_eps(:,jtau)-Resqtrue_eps(:,jtau-1)))/(Vectau(jtau)-Vectau(jtau-1)).*...
            (V_draw-Vectau(jtau-1))+MatAGE_t*Resqtrue_eps(:,jtau-1)).*(V_draw>Vectau(jtau-1)).*(V_draw<=Vectau(jtau));
    end
    %Last quantile.
    Mateps_true(:,jj)=Mateps_true(:,jj)+(MatAGE_t*Resqtrue_eps(:,Ntau)).*(V_draw>Vectau(Ntau));
    
    % Laplace tails
    Mateps_true(:,jj)=Mateps_true(:,jj)+((1/(b1true_eps)*log(V_draw/Vectau(1))).*(V_draw<=Vectau(1))...
        -(1/bLtrue_eps*log((1-V_draw)/(1-Vectau(Ntau)))).*(V_draw>Vectau(Ntau)));
    
    
    
    % Earnings
    
    Y(:,jj)=Mateta_true(:,jj)+Mateps_true(:,jj);
    
    
    % Assets and consumption
    
    
    XX=[];
    for mm1=0:M1
        for mm2=0:M2
            for mm3=0:M3
                for mm4=0:M4
                    for mmxi=0:Mxi
                        XX=[XX hermite(mm1,(A(:,jj)-meanA)/stdA).*hermite(mm2,(Mateta_true(:,jj)-meanY)/stdY).*hermite(mm3,(Y(:,jj)-Mateta_true(:,jj)-meanY)/stdY)...
                            .*hermite(mm4,(aa-meanAGE)/stdAGE).*hermite(mmxi,(Indiv-meanC)/stdC)];
                    end
                end
            end
        end
    end
    
    C(:,jj)=XX*Restrue(1:(M1+1)*(M2+1)*(M3+1)*(M4+1)*(Mxi+1),1)+sqrt(Restrue((M1+1)*(M2+1)*(M3+1)*(M4+1)*(Mxi+1)+1))*randn(N,1);
    
    
    
    % Restrict support of simulated consumption
    rmax=5;
    rmin=-5;
    C(:,jj)=C(:,jj).*(C(:,jj)<=rmax).*(C(:,jj)>=rmin)+...
        rmax*(C(:,jj)>rmax)+rmin*(C(:,jj)<rmin);
    
    if jj<=nage-1
        
        
   
        % standard asset accumulation rule, r=3. Assets >=0
        if acc==2
            A(:,jj+1)=log(max((1+.03)*exp(A(:,jj))+exp(Y(:,jj))-exp(C(:,jj)),floor_par*ones(N,1)));
        end
        
        % Predetermined assets
        if acc==1
            XXA=[];
            for mm1=0:R1
                for mm2=0:R2
                    for mm3=0:R3
                        for mm4=0:R4
                            for mm5=0:R5
                                for mm6=0:R6
                                    XXA=[XXA hermite(mm1,(A(:,jj)-meanA)/stdA).*hermite(mm2,(C(:,jj)-meanC)/stdC).*hermite(mm3,(Y(:,jj)-meanY)/stdY)...
                                        .*hermite(mm4,(Mateta_true(:,jj)-meanY)/stdY).*hermite(mm5,(Indiv-meanC)/stdC).*hermite(mm6,(aa-meanAGE)/stdAGE)];
                                end
                            end
                        end
                    end
                end
            end
            
            
            A(:,jj+1)=XXA*Restrue_a2(1:(R1+1)*(R2+1)*(R3+1)*(R4+1)*(R5+1)*(R6+1),1)+sqrt(Restrue_a2((R1+1)*(R2+1)*(R3+1)*(R4+1)*(R5+1)*(R6+1)+1,1))*randn(N,1);
            
            % Restrict support of simulated assets
            mmax=10;
            mmin=-10;
            A(:,jj+1)=A(:,jj+1).*(A(:,jj+1)<=mmax).*(A(:,jj+1)>=mmin)+...
                mmax*(A(:,jj+1)>mmax)+mmin*(A(:,jj+1)<mmin);
        end
     
        Mat=zeros(N,(K1+1)*(K2+1));
        for kk1=0:K1
            for kk2=0:K2
                Mat(:,kk1*(K2+1)+kk2+1)=hermite(kk1,(Mateta_true(:,jj)-meanY)/stdY).*hermite(kk2,((aa+2)-meanAGE)/stdAGE);
            end
        end
        
        % age 37 receives shock tau0
        if jj==1
            V_draw=tau0*ones(N,1);
        else
            V_draw=unifrnd(0,1,N,1);
        end
        
        %First quantile
        
        Mateta_true(:,jj+1)=(Mat*Resqtrue(:,1)).*(V_draw<=Vectau(1));
        for jtau=2:Ntau
            Mateta_true(:,jj+1)=Mateta_true(:,jj+1)+...
                ((Mat*Resqtrue(:,jtau)-Mat*Resqtrue(:,jtau-1))/...
                (Vectau(jtau)-Vectau(jtau-1)).*...
                (V_draw-Vectau(jtau-1))+Mat*Resqtrue(:,jtau-1)).*...
                (V_draw>Vectau(jtau-1)).*(V_draw<=Vectau(jtau));
        end
        %Last quantile.
        Mateta_true(:,jj+1)=Mateta_true(:,jj+1)+(Mat*Resqtrue(:,Ntau)).*...
            (V_draw>Vectau(Ntau));
        
        % Laplace tails
        Mateta_true(:,jj+1)=Mateta_true(:,jj+1)+((1/(b1true)*log(V_draw/Vectau(1))).*(V_draw<=Vectau(1))...
            -(1/bLtrue*log((1-V_draw)/(1-Vectau(Ntau)))).*(V_draw>Vectau(Ntau)));
        
        % Restrict support of simulated eta's
        pmax=10;
        pmin=-10;
        Mateta_true(:,jj+1)=Mateta_true(:,jj+1).*(Mateta_true(:,jj+1)<=pmax).*(Mateta_true(:,jj+1)>=pmin)+...
            pmax*(Mateta_true(:,jj+1)>pmax)+pmin*(Mateta_true(:,jj+1)<pmin);
        
    end
end


% modify axes depending of the values of "tau_shock" and "tau_init", and
% whether the shock was received while "old" or "young" 


figure
plot((aa_ref:2:59)',[nanmedian(Y)'-nanmedian(Y1)'])
figure
plot((aa_ref:2:59)',[nanmedian(C)'-nanmedian(C1)'])
figure
plot((aa_ref:2:59)',[nanmedian(A)'-nanmedian(A1)'])

fig_Y1=nanmedian(Y)'-nanmedian(Y1)';
fig_C1=nanmedian(C)'-nanmedian(C1)';

close all

figure 
plot((aa_ref:2:59)',[fig_Y])
%axis([35 59 0 .30])
axis([53 59 0 .30])
%axis([35 59 -.30 0])
%axis([53 59 -.60 0])
figure 
plot((aa_ref:2:59)',[fig_C fig_C1])
%axis([35 59 0 .15])
axis([53 59 0 .15])
%axis([35 59 -.15 0])
%axis([53 59 -.30 0])

close all

figure 
plot((aa_ref:2:59)',[fig_Y])
%axis([35 59 0 .30])
%axis([53 59 0 .30])
%axis([35 59 -.30 0])
axis([53 59 -.60 0])
figure 
plot((aa_ref:2:59)',[fig_C fig_C1])
%axis([35 59 0 .15])
%axis([53 59 0 .15])
%axis([35 59 -.15 0])
axis([53 59 -.30 0])


if tau_shock==.1
    figure
    plot((aa_ref:2:59)',fig_Y,'-','Linewidth',3,'Color','b')
    xlabel('age','FontSize',20)
    set(gca,'xlim',[aa_ref 59])
    set(gca,'xtick',(aa_ref:2:59))
    ylabel('log-earnings','FontSize',20)
    set(gca,'ylim',[-.4 0])
    set(gca,'ytick',(-.4:.1:0))
    figure
    plot((aa_ref:2:59)',fig_C,'--','Linewidth',3,'Color','b')
    xlabel('age','FontSize',20)
    set(gca,'xlim',[aa_ref 59])
    set(gca,'xtick',(aa_ref:2:59))
    ylabel('log-consumption','FontSize',20)
    set(gca,'ylim',[-.2 0])
    set(gca,'ytick',(-.2:.05:0))
    hold on 
    plot((aa_ref:2:59)',fig_C1,'-','Linewidth',3,'Color','g')
    xlabel('age','FontSize',20)
    set(gca,'xlim',[aa_ref 59])
    set(gca,'xtick',(aa_ref:2:59))
    ylabel('log-consumption','FontSize',20)
    set(gca,'ylim',[-.2 0])
    set(gca,'ytick',(-.2:.05:0))
    hold off
elseif tau_shock==.9
       figure
    plot((aa_ref:2:59)',fig_Y,'-','Linewidth',3,'Color','b')
    xlabel('age','FontSize',20)
    set(gca,'xlim',[aa_ref 59])
    set(gca,'xtick',(aa_ref:2:59))
    ylabel('log-earnings','FontSize',20)
    set(gca,'ylim',[0 .4])
    set(gca,'ytick',(0:.1:0.4))
    figure
    plot((aa_ref:2:59)',fig_C,'--','Linewidth',3,'Color','b')
    xlabel('age','FontSize',20)
    set(gca,'xlim',[aa_ref 59])
    set(gca,'xtick',(aa_ref:2:59))
    ylabel('log-consumption','FontSize',20)
    set(gca,'ylim',[0 .2])
    set(gca,'ytick',(0:.05:0.2))
    hold on 
    plot((aa_ref:2:59)',fig_C1,'-','Linewidth',3,'Color','g')
    xlabel('age','FontSize',20)
    set(gca,'xlim',[aa_ref 59])
    set(gca,'xtick',(aa_ref:2:59))
    ylabel('log-consumption','FontSize',20)
    set(gca,'ylim',[0 .2])
    set(gca,'ytick',(0:.05:0.2))
    hold off
end









