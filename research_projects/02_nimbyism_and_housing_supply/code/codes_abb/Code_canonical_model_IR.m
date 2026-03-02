% Code for Arellano, Blundell and Bonhomme (2016), "Earnings and Consumption Dynamics: A Nonlinear Panel Data Framework"
% to appear in Econometrica

% This code produces the impulse responses based on the canonical linear
% model of earnings and consumption
% Different graphs are obtained by varying tau_shock

clear all
clc;

global Sigma T sig2eta1 sig2v sig2eps

load('data_hermite_cons2.mat');

% Earnings
Sigma=zeros(T,T);
for tt=1:T
    for ttt=1:T
        Sigma(tt,ttt)=mean(Y(:,tt).*Y(:,ttt))-mean(Y(:,tt))*mean(Y(:,ttt));
    end
end

par0=[.2;.2;.2]+randn(3,1);

[par fval]=fminunc(@covariance_cm,par0);

sig2eta1=par(1)^2;
sig2v=par(2)^2;
sig2eps=par(3)^2;

fval
par


% Covariance matrix
Sigma=zeros(2*T,2*T);
for tt=1:T
    for ttt=1:T
        Sigma(tt,ttt)=mean(Y(:,tt).*Y(:,ttt))-mean(Y(:,tt))*mean(Y(:,ttt));
    end
    for ttt=T+1:2*T
        Sigma(tt,ttt)=mean(Y(:,tt).*C(:,ttt-T))-mean(Y(:,tt))*mean(C(:,ttt-T));
    end
end

for tt=T+1:2*T
    for ttt=1:T
        Sigma(tt,ttt)=mean(C(:,tt-T).*Y(:,ttt))-mean(C(:,tt-T))*mean(Y(:,ttt));
    end
    for ttt=T+1:2*T
        Sigma(tt,ttt)=mean(C(:,tt-T).*C(:,ttt-T))-mean(C(:,tt-T))*mean(C(:,ttt-T));
    end
end


par0=[0;0;.2]+randn(3,1);

[par fval]=fminunc(@covariance_cm_consumption_twostep,par0);

phi_eta=par(1);
phi_eps=par(2);
sig2xi=par(3)^2;

fval
par

Sig=zeros(2*T,2*T);

% (Y,Y)
for tt=1:T
    Sig(tt,tt)=sig2eta1+(tt-1)*sig2v+sig2eps;
end

for tt=1:T
    for ttt=tt+1:T
        Sig(tt,ttt)=sig2eta1+(tt-1)*sig2v;
        Sig(ttt,tt)=sig2eta1+(tt-1)*sig2v;
    end
    
end

% (Y,C)
for tt=1:T
    Sig(tt,T+tt)=phi_eta*(sig2eta1+(tt-1)*sig2v)+phi_eps*sig2eps;
end

for tt=1:T
    for ttt=tt+1:T
        Sig(tt,T+ttt)=phi_eta*(sig2eta1+(tt-1)*sig2v);
        Sig(ttt,T+tt)=phi_eta*(sig2eta1+(tt-1)*sig2v);
    end
    
end

% (C,Y)
for tt=1:T
    Sig(T+tt,tt)=phi_eta*(sig2eta1+(tt-1)*sig2v)+phi_eps*sig2eps;
end

for tt=1:T
    for ttt=tt+1:T
        Sig(T+tt,ttt)=phi_eta*(sig2eta1+(tt-1)*sig2v);
        Sig(T+ttt,tt)=phi_eta*(sig2eta1+(tt-1)*sig2v);
    end
    
end

% (C,C)
for tt=1:T
    Sig(T+tt,T+tt)=phi_eta^2*(sig2eta1+(tt-1)*sig2v)+phi_eps^2*sig2eps+sig2xi;
end

for tt=1:T
    for ttt=tt+1:T
        Sig(T+tt,T+ttt)=phi_eta^2*(sig2eta1+(tt-1)*sig2v);
        Sig(T+ttt,T+tt)=phi_eta^2*(sig2eta1+(tt-1)*sig2v);
    end
    
end

Sigma

Sig

% Consumption response to permanent income shocks

Ntau2=30;
Vectau2=(1/(Ntau2+1):1/(Ntau2+1):Ntau2/(Ntau2+1))';

Vect_impact=phi_eta*sqrt(sig2v)./normpdf(norminv(Vectau2));
plot(Vectau2,Vect_impact)


% SIMULATION

N=100000;

% age

aa=35;
aa_ref=aa;

nage=13;

tau_init=.1;%results do not depend on tau_init 
tau_shock=.9;



tau1=tau_init;

% eta_1

eta1=sqrt(sig2eta1)*norminv(tau1);

% First simulation

tau0=.5;

Mateta_true=zeros(N,nage);
Y=zeros(N,nage);
C=zeros(N,nage);

Mateta_true(:,1)=eta1*ones(N,1);

Mateps_true=sqrt(sig2eps)*randn(N,nage);



for jj=1:nage
    aa=35+(jj-1)*2;
    Y(:,jj)=Mateta_true(:,jj)+Mateps_true(:,jj);
    
    C(:,jj)=phi_eta*Mateta_true(:,jj)+phi_eps*Mateps_true(:,jj)+sqrt(sig2xi)*randn(N,1);
    
    if jj<=nage-1
        if jj==1
            vv=norminv(tau0);
        else
            vv=randn(N,1);
        end
        Mateta_true(:,jj+1)=Mateta_true(:,jj)+sqrt(sig2v)*vv;
        
    end
end

Y1=Y;
C1=C;


% Second simulation

tau0=tau_shock;

Mateta_true=zeros(N,nage);
Y=zeros(N,nage);
C=zeros(N,nage);

Mateta_true(:,1)=eta1*ones(N,1);

Mateps_true=sqrt(sig2eps)*randn(N,nage);



for jj=1:nage
    aa=35+(jj-1)*2;
    Y(:,jj)=Mateta_true(:,jj)+Mateps_true(:,jj);
    
    C(:,jj)=phi_eta*Mateta_true(:,jj)+phi_eps*Mateps_true(:,jj)+sqrt(sig2xi)*randn(N,1);
    
    if jj<=nage-1
        if jj==1
            vv=norminv(tau0);
        else
            vv=randn(N,1);
        end
        Mateta_true(:,jj+1)=Mateta_true(:,jj)+sqrt(sig2v)*vv;
        
    end
end



if tau_shock==.1
    figure
    plot((aa_ref:2:59)',[nanmedian(Y)'-nanmedian(Y1)'],'-','Linewidth',3,'Color','b')
    xlabel('age','FontSize',20)
    set(gca,'xlim',[35 59])
    set(gca,'xtick',(35:2:59))
    ylabel('log-earnings','FontSize',20)
    set(gca,'ylim',[-.3 0])
    set(gca,'ytick',(-.3:.05:0))
    figure
    plot((aa_ref:2:59)',[nanmedian(C)'-nanmedian(C1)'],'-','Linewidth',3,'Color','b')
    xlabel('age','FontSize',20)
    set(gca,'xlim',[35 59])
    set(gca,'xtick',(35:2:59))
    ylabel('log-consumption','FontSize',20)
    set(gca,'ylim',[-.15 0])
    set(gca,'ytick',(-.15:.05:0))
elseif tau_shock==.9
    figure
    plot((aa_ref:2:59)',[nanmedian(Y)'-nanmedian(Y1)'],'-','Linewidth',3,'Color','b')
    xlabel('age','FontSize',20)
    set(gca,'xlim',[35 59])
    set(gca,'xtick',(35:2:59))
    ylabel('log-earnings','FontSize',20)
    set(gca,'ylim',[0 .3])
    set(gca,'ytick',(0:.05:0.3))
    figure
    plot((aa_ref:2:59)',[nanmedian(C)'-nanmedian(C1)'],'-','Linewidth',3,'Color','b')
    xlabel('age','FontSize',20)
    set(gca,'xlim',[35 59])
    set(gca,'xtick',(35:2:59))
    ylabel('log-consumption','FontSize',20)
    set(gca,'ylim',[0 .15])
    set(gca,'ytick',(0:.05:0.15))
end





