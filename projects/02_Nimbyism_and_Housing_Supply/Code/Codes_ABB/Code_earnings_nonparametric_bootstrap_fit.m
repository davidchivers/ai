% Code for Arellano, Blundell and Bonhomme (2016), "Earnings and Consumption Dynamics: A Nonlinear Panel Data Framework"
% to appear in Econometrica

% This code processes the nonparametric bootstrap results for earnings


clear all
clc;

close all

load('Results_bootstrap_nonparametric.mat')


Nboot=500;

Res_fit_down=zeros(Ntau,Ntau);
Res_fit_up=zeros(Ntau,Ntau);

Vect=Resboot_skew_eta(1,1:Nboot)';
ind=(Vect~=0).*(isnan(Vect)==0);
ind=(ind==1);

for jtau1=1:Ntau
    for jtau2=1:Ntau
        
        Vect=reshape(Resboot_fit(jtau1,jtau2,1:Nboot),Nboot,1);
        Vect=Vect(ind);
        Res_fit_down(jtau1,jtau2)=quantile(Vect,.025);
        Res_fit_up(jtau1,jtau2)=quantile(Vect,.975);
        
    end
end

% Figure S9a bottom
figure
surf(Vectau,Vectau,Res_fit_down)
hold on
surf(Vectau,Vectau,Res_fit_up)
hold off
xlabel('percentile \tau_{shock}','FontSize',14)
ylabel('percentile \tau_{init}','FontSize',14)
zlabel('persistence','FontSize',14)
set(gca,'xlim',[0 1])
set(gca,'ylim',[0 1])
set(gca,'zlim',[0 1.2])
set(gca,'xtick',(0:0.2:1))
set(gca,'ytick',(0:0.2:1))


% Uniform probability

lambda=1.76;
Res_fit_down2=(Res_fit_down+Res_fit_up)/2-lambda*(Res_fit_up-Res_fit_down)/2;
Res_fit_up2=(Res_fit_down+Res_fit_up)/2+lambda*(Res_fit_up-Res_fit_down)/2;


prod=ones(Nboot,1);

for jtau1=1:Ntau
    for jtau2=1:Ntau
        
        Vect=reshape(Resboot_fit(jtau1,jtau2,1:Nboot),Nboot,1);
        Vect=Vect(ind);
        prod=prod.*(Vect>=Res_fit_down2(jtau1,jtau2)).*(Vect<=Res_fit_up2(jtau1,jtau2));
        
    end
end


sum(prod)/Nboot

% uniform confidence band

% Figure S10a
figure
surf(Vectau,Vectau,Res_fit_down2)
hold on
surf(Vectau,Vectau,Res_fit_up2)
hold off
xlabel('percentile \tau_{shock}','FontSize',14)
ylabel('percentile \tau_{init}','FontSize',14)
zlabel('persistence','FontSize',14)
set(gca,'xlim',[0 1])
set(gca,'ylim',[0 1])
set(gca,'zlim',[0 1.2])
set(gca,'xtick',(0:0.2:1))
set(gca,'ytick',(0:0.2:1))





set(gca,'ztick',(0:0.2:1.2))


Res_fit_simul_down=zeros(Ntau,Ntau);
Res_fit_simul_up=zeros(Ntau,Ntau);

for jtau1=1:Ntau
    for jtau2=1:Ntau
        Vect=reshape(Resboot_fit_simul(jtau1,jtau2,1:Nboot),Nboot,1);
        Vect=Vect(ind);
        Res_fit_simul_down(jtau1,jtau2)=quantile(Vect,.025);
        Res_fit_simul_up(jtau1,jtau2)=quantile(Vect,.975);
        
    end
end
        
% Figure S9b bottom
figure
surf(Vectau,Vectau,Res_fit_simul_down)
hold on
surf(Vectau,Vectau,Res_fit_simul_up)
hold off
xlabel('percentile \tau_{shock}','FontSize',14)
ylabel('percentile \tau_{init}','FontSize',14)
zlabel('persistence','FontSize',14)
set(gca,'xlim',[0 1])
set(gca,'ylim',[0 1])
set(gca,'zlim',[0 1.2])
set(gca,'xtick',(0:0.2:1))
set(gca,'ytick',(0:0.2:1))
set(gca,'ztick',(0:0.2:1.2))


% Uniform probability

lambda=1.60;
Res_fit_simul_down2=(Res_fit_simul_down+Res_fit_simul_up)/2-lambda*(Res_fit_simul_up-Res_fit_simul_down)/2;
Res_fit_simul_up2=(Res_fit_simul_down+Res_fit_simul_up)/2+lambda*(Res_fit_simul_up-Res_fit_simul_down)/2;


prod=ones(Nboot,1);

for jtau1=1:Ntau
    for jtau2=1:Ntau
        
        Vect=reshape(Resboot_fit_simul(jtau1,jtau2,1:Nboot),Nboot,1);
        Vect=Vect(ind);
        prod=prod.*(Vect>=Res_fit_simul_down2(jtau1,jtau2)).*(Vect<=Res_fit_simul_up2(jtau1,jtau2));
        
    end
end


sum(prod)/Nboot

% uniform confidence band

% Figure S10b
figure
surf(Vectau,Vectau,Res_fit_simul_down2)
hold on
surf(Vectau,Vectau,Res_fit_simul_up2)
hold off
xlabel('percentile \tau_{shock}','FontSize',14)
ylabel('percentile \tau_{init}','FontSize',14)
zlabel('persistence','FontSize',14)
set(gca,'xlim',[0 1])
set(gca,'ylim',[0 1])
set(gca,'zlim',[0 1.2])
set(gca,'xtick',(0:0.2:1))
set(gca,'ytick',(0:0.2:1))





Res_eta_down=zeros(Ntau,Ntau);
Res_eta_up=zeros(Ntau,Ntau);

for jtau1=1:Ntau
    for jtau2=1:Ntau
        Vect=reshape(Resboot_eta(jtau1,jtau2,1:Nboot),Nboot,1);
        Vect=Vect(ind);
        Res_eta_down(jtau1,jtau2)=quantile(Vect,.025);
        Res_eta_up(jtau1,jtau2)=quantile(Vect,.975);
        
    end
end

% Figure S11b
figure
surf(Vectau,Vectau,Res_eta_down)
hold on
surf(Vectau,Vectau,Res_eta_up)
hold off
xlabel('percentile \tau_{shock}','FontSize',14)
ylabel('percentile \tau_{init}','FontSize',14)
zlabel('persistence','FontSize',14)
set(gca,'xlim',[0 1])
set(gca,'ylim',[0 1])
set(gca,'zlim',[0 1.2])
set(gca,'xtick',(0:0.2:1))
set(gca,'ytick',(0:0.2:1))
set(gca,'ztick',(0:0.2:1.2))


% Uniform probability

lambda=1.69;
Res_eta_down2=(Res_eta_down+Res_eta_up)/2-lambda*(Res_eta_up-Res_eta_down)/2;
Res_eta_up2=(Res_eta_down+Res_eta_up)/2+lambda*(Res_eta_up-Res_eta_down)/2;


prod=ones(Nboot,1);

for jtau1=1:Ntau
    for jtau2=1:Ntau
        
        Vect=reshape(Resboot_eta(jtau1,jtau2,1:Nboot),Nboot,1);
        Vect=Vect(ind);
        prod=prod.*(Vect>=Res_eta_down2(jtau1,jtau2)).*(Vect<=Res_eta_up2(jtau1,jtau2));
        
    end
end


sum(prod)/Nboot

% uniform confidence band

% Figure S12
figure
surf(Vectau,Vectau,Res_eta_down2)
hold on
surf(Vectau,Vectau,Res_eta_up2)
hold off
xlabel('percentile \tau_{shock}','FontSize',14)
ylabel('percentile \tau_{init}','FontSize',14)
zlabel('persistence','FontSize',14)
set(gca,'xlim',[0 1])
set(gca,'ylim',[0 1])
set(gca,'zlim',[0 1.2])
set(gca,'xtick',(0:0.2:1))
set(gca,'ytick',(0:0.2:1))






Res_skew_y_down=zeros(Ntau,1);
Res_skew_y_up=zeros(Ntau,1);
for jtau=1:Ntau
    Vect=Resboot_skew_y(jtau,1:Nboot)';
    Vect=Vect(ind);
    Res_skew_y_down(jtau)=quantile(Vect,.025);
    Res_skew_y_up(jtau)=quantile(Vect,.975);
    
end

Res_skew_eta_down=zeros(Ntau,1);
Res_skew_eta_up=zeros(Ntau,1);
for jtau=1:Ntau
    Vect=Resboot_skew_eta(jtau,1:Nboot)';
    Vect=Vect(ind);
    Res_skew_eta_down(jtau)=quantile(Vect,.025);
    Res_skew_eta_up(jtau)=quantile(Vect,.975);
    
end

% Figure S13a bottom
figure
plot(Vectau,Res_skew_y_down,'-','Linewidth',3,'Color','b')
hold on
plot(Vectau,Res_skew_y_up,'-','Linewidth',3,'Color','b')
hold off
xlabel('percentile y_{i,t-1}','FontSize',14)
ylabel('conditional skewness','FontSize',14)
set(gca,'xlim',[1/12 11/12])
set(gca,'ylim',[-.6 .6])
set(gca,'xtick',(.1:.1:.9))
set(gca,'ytick',(-.6:.2:.6))

% Figure S13b bottom
figure
plot(Vectau,Res_skew_eta_down,'-','Linewidth',3,'Color','b')
hold on
plot(Vectau,Res_skew_eta_up,'-','Linewidth',3,'Color','b')
hold off
xlabel('percentile \eta_{i,t-1}','FontSize',14)
ylabel('conditional skewness','FontSize',14)
set(gca,'xlim',[1/12 11/12])
set(gca,'ylim',[-.6 .6])
set(gca,'xtick',(.1:.1:.9))
set(gca,'ytick',(-.6:.2:.6))



% Uniform probability

lambda=1.26;
Res_skew_y_down2=(Res_skew_y_down+Res_skew_y_up)/2-lambda*(Res_skew_y_up-Res_skew_y_down)/2;
Res_skew_y_up2=(Res_skew_y_down+Res_skew_y_up)/2+lambda*(Res_skew_y_up-Res_skew_y_down)/2;


prod=ones(Nboot,1);

for jtau=1:Ntau
        
        Vect=Resboot_skew_y(jtau,1:Nboot)';
        Vect=Vect(ind);
        prod=prod.*(Vect>=Res_skew_y_down2(jtau)).*(Vect<=Res_skew_y_up2(jtau));
         
end


sum(prod)/Nboot

% uniform confidence band

% Figure S14a
figure
plot(Vectau,Res_skew_y_down2,'-','Linewidth',3,'Color','b')
hold on
plot(Vectau,Res_skew_y_up2,'-','Linewidth',3,'Color','b')
hold off
xlabel('percentile y_{i,t-1}','FontSize',14)
ylabel('conditional skewness','FontSize',14)
set(gca,'xlim',[1/12 11/12])
set(gca,'ylim',[-.6 .6])
set(gca,'xtick',(.1:.1:.9))
set(gca,'ytick',(-.6:.2:.6))

% Uniform probability

lambda=1.32;
Res_skew_eta_down2=(Res_skew_eta_down+Res_skew_eta_up)/2-lambda*(Res_skew_eta_up-Res_skew_eta_down)/2;
Res_skew_eta_up2=(Res_skew_eta_down+Res_skew_eta_up)/2+lambda*(Res_skew_eta_up-Res_skew_eta_down)/2;


prod=ones(Nboot,1);

for jtau=1:Ntau
        
        Vect=Resboot_skew_eta(jtau,1:Nboot)';
        Vect=Vect(ind);
        prod=prod.*(Vect>=Res_skew_eta_down2(jtau)).*(Vect<=Res_skew_eta_up2(jtau));
         
end


sum(prod)/Nboot

% uniform confidence band

% Figure S14b
figure
plot(Vectau,Res_skew_eta_down2,'-','Linewidth',3,'Color','b')
hold on
plot(Vectau,Res_skew_eta_up2,'-','Linewidth',3,'Color','b')
hold off
xlabel('percentile y_{i,t-1}','FontSize',14)
ylabel('conditional skewness','FontSize',14)
set(gca,'xlim',[1/12 11/12])
set(gca,'ylim',[-.6 .6])
set(gca,'xtick',(.1:.1:.9))
set(gca,'ytick',(-.6:.2:.6))
