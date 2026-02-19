% Code for Arellano, Blundell and Bonhomme (2016), "Earnings and Consumption Dynamics: A Nonlinear Panel Data Framework"
% to appear in Econometrica

% This code processes the results of the nonparametric bootstrap for consumption

clear all
clc;

close all

load('Results_consumption_bootstrap_nonparametric.mat')

Nboot=200;
ind=(1:200);

Res_fit_eta_down=zeros(Ntau,Ntau);
Res_fit_eta_up=zeros(Ntau,Ntau);

for jtau1=1:Ntau
    for jtau2=1:Ntau
        
        Vect=reshape(Resboot_cons_eta(jtau1,jtau2,ind),Nboot,1);
        Res_fit_eta_down(jtau1,jtau2)=quantile(Vect,.025);
        Res_fit_eta_up(jtau1,jtau2)=quantile(Vect,.975);
        
    end
end

% Figure S22a bottom
figure
surf(Vectau,Vectau,Res_fit_eta_down)
hold on
surf(Vectau,Vectau,Res_fit_eta_up)
hold off
xlabel('percentile \tau_{age}','FontSize',14)
ylabel('percentile \tau_{assets}','FontSize',14)
zlabel('consumption response','FontSize',14)
set(gca,'xlim',[0 1])
set(gca,'ylim',[0 1])
set(gca,'zlim',[0 .8])
set(gca,'xtick',(0:0.2:1))
set(gca,'ytick',(0:0.2:1))
set(gca,'ztick',(0:0.2:.8))

% Uniform probability

lambda=1.45;
Res_fit_eta_down2=(Res_fit_eta_down+Res_fit_eta_up)/2-lambda*(Res_fit_eta_up-Res_fit_eta_down)/2;
Res_fit_eta_up2=(Res_fit_eta_down+Res_fit_eta_up)/2+lambda*(Res_fit_eta_up-Res_fit_eta_down)/2;

prod=ones(Nboot,1);

for jtau1=1:Ntau
    for jtau2=1:Ntau
        
        Vect=reshape(Resboot_cons_eta(jtau1,jtau2,ind),Nboot,1);
        prod=prod.*(Vect>=Res_fit_eta_down2(jtau1,jtau2)).*(Vect<=Res_fit_eta_up2(jtau1,jtau2));
        
    end
end
sum(prod)/Nboot

% Figure S23a
figure
surf(Vectau,Vectau,Res_fit_eta_down2)
hold on
surf(Vectau,Vectau,Res_fit_eta_up2)
hold off
xlabel('percentile \tau_{age}','FontSize',14)
ylabel('percentile \tau_{assets}','FontSize',14)
zlabel('consumption response','FontSize',14)
set(gca,'xlim',[0 1])
set(gca,'ylim',[0 1])
set(gca,'zlim',[0 .8])
set(gca,'xtick',(0:0.2:1))
set(gca,'ytick',(0:0.2:1))
set(gca,'ztick',(0:0.2:.8))


Res_fit_eps_down=zeros(Ntau,Ntau);
Res_fit_eps_up=zeros(Ntau,Ntau);

for jtau1=1:Ntau
    for jtau2=1:Ntau
        
        Vect=reshape(Resboot_cons_eps(jtau1,jtau2,ind),Nboot,1);
        Res_fit_eps_down(jtau1,jtau2)=quantile(Vect,.025);
        Res_fit_eps_up(jtau1,jtau2)=quantile(Vect,.975);
        
    end
end

% Figure S22b bottom
figure
surf(Vectau,Vectau,Res_fit_eps_down)
hold on
surf(Vectau,Vectau,Res_fit_eps_up)
hold off
xlabel('percentile \tau_{age}','FontSize',14)
ylabel('percentile \tau_{assets}','FontSize',14)
zlabel('consumption response','FontSize',14)
set(gca,'xlim',[0 1])
set(gca,'ylim',[0 1])
set(gca,'zlim',[-.5 .5])
set(gca,'xtick',(0:0.2:1))
set(gca,'ytick',(0:0.2:1))
set(gca,'ztick',(-.5:.2:.5))

% Uniform probability

lambda=1.57;
Res_fit_eps_down2=(Res_fit_eps_down+Res_fit_eps_up)/2-lambda*(Res_fit_eps_up-Res_fit_eps_down)/2;
Res_fit_eps_up2=(Res_fit_eps_down+Res_fit_eps_up)/2+lambda*(Res_fit_eps_up-Res_fit_eps_down)/2;

prod=ones(Nboot,1);

for jtau1=1:Ntau
    for jtau2=1:Ntau
        
        Vect=reshape(Resboot_cons_eps(jtau1,jtau2,ind),Nboot,1);
        prod=prod.*(Vect>=Res_fit_eps_down2(jtau1,jtau2)).*(Vect<=Res_fit_eps_up2(jtau1,jtau2));
        
    end
end
sum(prod)/Nboot

% Figure S23b
figure
surf(Vectau,Vectau,Res_fit_eps_down2)
hold on
surf(Vectau,Vectau,Res_fit_eps_up2)
hold off
xlabel('percentile \tau_{age}','FontSize',14)
ylabel('percentile \tau_{assets}','FontSize',14)
zlabel('consumption response','FontSize',14)
set(gca,'xlim',[0 1])
set(gca,'ylim',[0 1])
set(gca,'zlim',[-.5 .5])
set(gca,'xtick',(0:0.2:1))
set(gca,'ytick',(0:0.2:1))
set(gca,'ztick',(-.5:.2:.5))



