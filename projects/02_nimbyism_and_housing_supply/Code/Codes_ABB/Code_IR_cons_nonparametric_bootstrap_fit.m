% Code for Arellano, Blundell and Bonhomme (2016), "Earnings and Consumption Dynamics: A Nonlinear Panel Data Framework"
% to appear in Econometrica

% This code produces the bootstrap results for impulse responses
% There are pointwise and uniform confidence bands
% 'IRY' corresponds to earnings
% 'IR_1' to consumption in the model with a nonlinear assets rule (not reported in the paper)
% 'IR_2' to consumption in the model with a linear assets rule


clear all
clc;

close all

Nboot1=100;
Nboot_tot=300;

A1=[];
A2=[];
A3=[];
A4=[];
A5=[];
A6=[];
A7=[];
A8=[];
A9=[];
A10=[];
A11=[];
A12=[];
A13=[];
A14=[];
A15=[];
A16=[];
A17=[];
A18=[];

load('Res_IR_npbootstrap1.mat')

A1=[A1;ResbootIRY_1_1(1:Nboot1,:)];
A2=[A2;ResbootIRY_1_9(1:Nboot1,:)];
A3=[A3;ResbootIRY_5_1(1:Nboot1,:)];
A4=[A4;ResbootIRY_5_9(1:Nboot1,:)];
A5=[A5;ResbootIRY_9_1(1:Nboot1,:)];
A6=[A6;ResbootIRY_9_9(1:Nboot1,:)];

A7=[A7;ResbootIR_1_1_1(1:Nboot1,:)];
A8=[A8;ResbootIR_1_1_9(1:Nboot1,:)];
A9=[A9;ResbootIR_1_5_1(1:Nboot1,:)];
A10=[A10;ResbootIR_1_5_9(1:Nboot1,:)];
A11=[A11;ResbootIR_1_9_1(1:Nboot1,:)];
A12=[A12;ResbootIR_1_9_9(1:Nboot1,:)];

A13=[A13;ResbootIR_2_1_1(1:Nboot1,:)];
A14=[A14;ResbootIR_2_1_9(1:Nboot1,:)];
A15=[A15;ResbootIR_2_5_1(1:Nboot1,:)];
A16=[A16;ResbootIR_2_5_9(1:Nboot1,:)];
A17=[A17;ResbootIR_2_9_1(1:Nboot1,:)];
A18=[A18;ResbootIR_2_9_9(1:Nboot1,:)];

load('Res_IR_npbootstrap2.mat')

A1=[A1;ResbootIRY_1_1(1:Nboot1,:)];
A2=[A2;ResbootIRY_1_9(1:Nboot1,:)];
A3=[A3;ResbootIRY_5_1(1:Nboot1,:)];
A4=[A4;ResbootIRY_5_9(1:Nboot1,:)];
A5=[A5;ResbootIRY_9_1(1:Nboot1,:)];
A6=[A6;ResbootIRY_9_9(1:Nboot1,:)];

A7=[A7;ResbootIR_1_1_1(1:Nboot1,:)];
A8=[A8;ResbootIR_1_1_9(1:Nboot1,:)];
A9=[A9;ResbootIR_1_5_1(1:Nboot1,:)];
A10=[A10;ResbootIR_1_5_9(1:Nboot1,:)];
A11=[A11;ResbootIR_1_9_1(1:Nboot1,:)];
A12=[A12;ResbootIR_1_9_9(1:Nboot1,:)];

A13=[A13;ResbootIR_2_1_1(1:Nboot1,:)];
A14=[A14;ResbootIR_2_1_9(1:Nboot1,:)];
A15=[A15;ResbootIR_2_5_1(1:Nboot1,:)];
A16=[A16;ResbootIR_2_5_9(1:Nboot1,:)];
A17=[A17;ResbootIR_2_9_1(1:Nboot1,:)];
A18=[A18;ResbootIR_2_9_9(1:Nboot1,:)];

load('Res_IR_npbootstrap3.mat')

A1=[A1;ResbootIRY_1_1(1:Nboot1,:)];
A2=[A2;ResbootIRY_1_9(1:Nboot1,:)];
A3=[A3;ResbootIRY_5_1(1:Nboot1,:)];
A4=[A4;ResbootIRY_5_9(1:Nboot1,:)];
A5=[A5;ResbootIRY_9_1(1:Nboot1,:)];
A6=[A6;ResbootIRY_9_9(1:Nboot1,:)];

A7=[A7;ResbootIR_1_1_1(1:Nboot1,:)];
A8=[A8;ResbootIR_1_1_9(1:Nboot1,:)];
A9=[A9;ResbootIR_1_5_1(1:Nboot1,:)];
A10=[A10;ResbootIR_1_5_9(1:Nboot1,:)];
A11=[A11;ResbootIR_1_9_1(1:Nboot1,:)];
A12=[A12;ResbootIR_1_9_9(1:Nboot1,:)];

A13=[A13;ResbootIR_2_1_1(1:Nboot1,:)];
A14=[A14;ResbootIR_2_1_9(1:Nboot1,:)];
A15=[A15;ResbootIR_2_5_1(1:Nboot1,:)];
A16=[A16;ResbootIR_2_5_9(1:Nboot1,:)];
A17=[A17;ResbootIR_2_9_1(1:Nboot1,:)];
A18=[A18;ResbootIR_2_9_9(1:Nboot1,:)];



% point estimates

A1_est=[0.0002   -0.0627   -0.0577   -0.0497   -0.0428   -0.0385   -0.0326   -0.0306   -0.0275   -0.0259   -0.0223   -0.0227   -0.0201];
A7_est=[-0.0016   -0.0250   -0.0276   -0.0247   -0.0260   -0.0207   -0.0188   -0.0154   -0.0161   -0.0141   -0.0112   -0.0106   -0.0056];
A13_est=[-0.0003   -0.0238   -0.0231   -0.0213   -0.0186   -0.0131   -0.0128   -0.0108   -0.0077   -0.0101   -0.0111   -0.0111   -0.0107];

A2_est=[-0.0002    0.2787    0.2556    0.2277    0.2001    0.1809    0.1633    0.1500    0.1347    0.1220    0.1110    0.0990    0.0862];
A8_est=[-0.0007    0.1157    0.1200    0.1129    0.1029    0.0949    0.0863    0.0791    0.0758    0.0684    0.0622    0.0557    0.0439];
A14_est=[0.0024    0.1072    0.0960    0.0903    0.0834    0.0760    0.0727    0.0660    0.0635    0.0591    0.0564    0.0535    0.0477];

A3_est=[-0.0008   -0.0964   -0.0893   -0.0792   -0.0719   -0.0663   -0.0599   -0.0536   -0.0522   -0.0484   -0.0434   -0.0374   -0.0309];
A9_est=[-0.0009   -0.0402   -0.0433   -0.0406   -0.0399   -0.0348   -0.0341   -0.0288   -0.0270   -0.0287   -0.0235   -0.0208   -0.0151];
A15_est=[0.0011   -0.0395   -0.0353   -0.0352   -0.0349   -0.0336   -0.0289   -0.0317   -0.0274   -0.0303   -0.0269   -0.0250   -0.0242];

A4_est=[-0.0004    0.1771    0.1667    0.1527    0.1426    0.1311    0.1246    0.1147    0.1094    0.1010    0.0882    0.0782    0.0685];
A10_est=[-0.0018    0.0737    0.0778    0.0799    0.0737    0.0734    0.0664    0.0625    0.0610    0.0536    0.0476    0.0423    0.0375];
A16_est=[ 0.0032    0.0720    0.0674    0.0675    0.0656    0.0632    0.0654    0.0666    0.0623    0.0625    0.0629    0.0627    0.0583];

A5_est=[0.0005   -0.1906   -0.1827   -0.1738   -0.1681   -0.1606   -0.1552   -0.1479   -0.1433   -0.1316   -0.1211   -0.1015   -0.0827];
A11_est=[0.0015   -0.0800   -0.0856   -0.0880   -0.0863   -0.0857   -0.0847   -0.0785   -0.0790   -0.0747   -0.0617   -0.0613   -0.0524];
A17_est=[-0.0007   -0.0783   -0.0778   -0.0781   -0.0814   -0.0798   -0.0819   -0.0837   -0.0876   -0.0840   -0.0835   -0.0849   -0.0820];

A6_est=[-0.0003    0.1266    0.1195    0.1160    0.1141    0.1106    0.1112    0.1084    0.1064    0.0960    0.0893    0.0774    0.0605];
A12_est=[0.0012    0.0525    0.0557    0.0564    0.0591    0.0573    0.0601    0.0599    0.0574    0.0552    0.0500    0.0446    0.0399];
A18_est=[0.0012    0.0519    0.0512    0.0570    0.0572    0.0565    0.0575    0.0597    0.0558    0.0639    0.0597    0.0614    0.0585];



% Pointwise bands (recentered bands from nonparametric bootstrap)


figure
plot((aa_ref:2:59)',A1_est,'-','Linewidth',3,'Color','b')
hold on
plot((aa_ref:2:59)',A1_est-mean(A1)+quantile(A1,.025),'--','Linewidth',3,'Color','g')
hold on
plot((aa_ref:2:59)',A1_est-mean(A1)+quantile(A1,.975),'--','Linewidth',3,'Color','g')
hold off
xlabel('age','FontSize',20)
set(gca,'xlim',[35 59])
set(gca,'xtick',(35:2:59))
ylabel('log-earnings','FontSize',20)
set(gca,'ylim',[-.3 0])
set(gca,'ytick',(-.3:.05:0))

figure
plot((aa_ref:2:59)',A2_est,'-','Linewidth',3,'Color','b')
hold on
plot((aa_ref:2:59)',A2_est-mean(A2)+quantile(A2,.025),'--','Linewidth',3,'Color','g')
hold on
plot((aa_ref:2:59)',A2_est-mean(A2)+quantile(A2,.975),'--','Linewidth',3,'Color','g')
hold off
xlabel('age','FontSize',20)
set(gca,'xlim',[35 59])
set(gca,'xtick',(35:2:59))
ylabel('log-earnings','FontSize',20)
set(gca,'ylim',[0 .3])
set(gca,'ytick',(0:.05:0.3))

figure
plot((aa_ref:2:59)',A3_est,'-','Linewidth',3,'Color','b')
hold on
plot((aa_ref:2:59)',A3_est-mean(A3)+quantile(A3,.025),'--','Linewidth',3,'Color','g')
hold on
plot((aa_ref:2:59)',A3_est-mean(A3)+quantile(A3,.975),'--','Linewidth',3,'Color','g')
hold off  xlabel('age','FontSize',20)
set(gca,'xlim',[35 59])
set(gca,'xtick',(35:2:59))
ylabel('log-earnings','FontSize',20)
set(gca,'ylim',[-.3 0])
set(gca,'ytick',(-.3:.05:0))

figure
plot((aa_ref:2:59)',A4_est,'-','Linewidth',3,'Color','b')
hold on
plot((aa_ref:2:59)',A4_est-mean(A4)+quantile(A4,.025),'--','Linewidth',3,'Color','g')
hold on
plot((aa_ref:2:59)',A4_est-mean(A4)+quantile(A4,.975),'--','Linewidth',3,'Color','g')
hold off
xlabel('age','FontSize',20)
set(gca,'xlim',[35 59])
set(gca,'xtick',(35:2:59))
ylabel('log-earnings','FontSize',20)
set(gca,'ylim',[0 .3])
set(gca,'ytick',(0:.05:0.3))

figure
plot((aa_ref:2:59)',A5_est,'-','Linewidth',3,'Color','b')
hold on
plot((aa_ref:2:59)',A5_est-mean(A5)+quantile(A5,.025),'--','Linewidth',3,'Color','g')
hold on
plot((aa_ref:2:59)',A5_est-mean(A5)+quantile(A5,.975),'--','Linewidth',3,'Color','g')
hold off
xlabel('age','FontSize',20)
set(gca,'xlim',[35 59])
set(gca,'xtick',(35:2:59))
ylabel('log-earnings','FontSize',20)
set(gca,'ylim',[-.3 0])
set(gca,'ytick',(-.3:.05:0))

figure
plot((aa_ref:2:59)',A6_est,'-','Linewidth',3,'Color','b')
hold on
plot((aa_ref:2:59)',A6_est-mean(A6)+quantile(A6,.025),'--','Linewidth',3,'Color','g')
hold on
plot((aa_ref:2:59)',A6_est-mean(A6)+quantile(A6,.975),'--','Linewidth',3,'Color','g')
hold off
xlabel('age','FontSize',20)
set(gca,'xlim',[35 59])
set(gca,'xtick',(35:2:59))
ylabel('log-earnings','FontSize',20)
set(gca,'ylim',[0 .3])
set(gca,'ytick',(0:.05:0.3))


figure
plot((aa_ref:2:59)',A7_est,'-','Linewidth',3,'Color','b')
hold on
plot((aa_ref:2:59)',A7_est-mean(A7)+quantile(A7,.025),'--','Linewidth',3,'Color','g')
hold on
plot((aa_ref:2:59)',A7_est-mean(A7)+quantile(A7,.975),'--','Linewidth',3,'Color','g')
hold off
xlabel('age','FontSize',20)
set(gca,'xlim',[35 59])
set(gca,'xtick',(35:2:59))
ylabel('log-consumption','FontSize',20)
set(gca,'ylim',[-.15 0])
set(gca,'ytick',(-.15:.05:0))

figure
plot((aa_ref:2:59)',A8_est,'-','Linewidth',3,'Color','b')
hold on
plot((aa_ref:2:59)',A8_est-mean(A8)+quantile(A8,.025),'--','Linewidth',3,'Color','g')
hold on
plot((aa_ref:2:59)',A8_est-mean(A8)+quantile(A8,.975),'--','Linewidth',3,'Color','g')
hold off
xlabel('age','FontSize',20)
set(gca,'xlim',[35 59])
set(gca,'xtick',(35:2:59))
ylabel('log-consumption','FontSize',20)
set(gca,'ylim',[0 .15])
set(gca,'ytick',(0:.05:0.15))

figure
plot((aa_ref:2:59)',A9_est,'-','Linewidth',3,'Color','b')
hold on
plot((aa_ref:2:59)',A9_est-mean(A9)+quantile(A9,.025),'--','Linewidth',3,'Color','g')
hold on
plot((aa_ref:2:59)',A9_est-mean(A9)+quantile(A9,.975),'--','Linewidth',3,'Color','g')
hold off
xlabel('age','FontSize',20)
set(gca,'xlim',[35 59])
set(gca,'xtick',(35:2:59))
ylabel('log-consumption','FontSize',20)
set(gca,'ylim',[-.15 0])
set(gca,'ytick',(-.15:.05:0))

figure
plot((aa_ref:2:59)',A10_est,'-','Linewidth',3,'Color','b')
hold on
plot((aa_ref:2:59)',A10_est-mean(A10)+quantile(A10,.025),'--','Linewidth',3,'Color','g')
hold on
plot((aa_ref:2:59)',A10_est-mean(A10)+quantile(A10,.975),'--','Linewidth',3,'Color','g')
hold off
xlabel('age','FontSize',20)
set(gca,'xlim',[35 59])
set(gca,'xtick',(35:2:59))
ylabel('log-consumption','FontSize',20)
set(gca,'ylim',[0 .15])
set(gca,'ytick',(0:.05:0.15))

figure
plot((aa_ref:2:59)',A11_est,'-','Linewidth',3,'Color','b')
hold on
plot((aa_ref:2:59)',A11_est-mean(A11)+quantile(A11,.025),'--','Linewidth',3,'Color','g')
hold on
plot((aa_ref:2:59)',A11_est-mean(A11)+quantile(A11,.975),'--','Linewidth',3,'Color','g')
hold off
xlabel('age','FontSize',20)
set(gca,'xlim',[35 59])
set(gca,'xtick',(35:2:59))
ylabel('log-consumption','FontSize',20)
set(gca,'ylim',[-.15 0])
set(gca,'ytick',(-.15:.05:0))

figure
plot((aa_ref:2:59)',A12_est,'-','Linewidth',3,'Color','b')
hold on
plot((aa_ref:2:59)',A12_est-mean(A12)+quantile(A12,.025),'--','Linewidth',3,'Color','g')
hold on
plot((aa_ref:2:59)',A12_est-mean(A12)+quantile(A12,.975),'--','Linewidth',3,'Color','g')
hold off
xlabel('age','FontSize',20)
set(gca,'xlim',[35 59])
set(gca,'xtick',(35:2:59))
ylabel('log-consumption','FontSize',20)
set(gca,'ylim',[0 .15])
set(gca,'ytick',(0:.05:0.15))

figure
plot((aa_ref:2:59)',A13_est,'-','Linewidth',3,'Color','b')
hold on
plot((aa_ref:2:59)',A13_est-mean(A13)+quantile(A13,.025),'--','Linewidth',3,'Color','g')
hold on
plot((aa_ref:2:59)',A13_est-mean(A13)+quantile(A13,.975),'--','Linewidth',3,'Color','g')
hold off
xlabel('age','FontSize',20)
set(gca,'xlim',[35 59])
set(gca,'xtick',(35:2:59))
ylabel('log-consumption','FontSize',20)
set(gca,'ylim',[-.15 0])
set(gca,'ytick',(-.15:.05:0))

figure
plot((aa_ref:2:59)',A14_est,'-','Linewidth',3,'Color','b')
hold on
plot((aa_ref:2:59)',A14_est-mean(A14)+quantile(A14,.025),'--','Linewidth',3,'Color','g')
hold on
plot((aa_ref:2:59)',A14_est-mean(A14)+quantile(A14,.975),'--','Linewidth',3,'Color','g')
hold off
xlabel('age','FontSize',20)
set(gca,'xlim',[35 59])
set(gca,'xtick',(35:2:59))
ylabel('log-consumption','FontSize',20)
set(gca,'ylim',[0 .15])
set(gca,'ytick',(0:.05:0.15))

figure
plot((aa_ref:2:59)',A15_est,'-','Linewidth',3,'Color','b')
hold on
plot((aa_ref:2:59)',A15_est-mean(A15)+quantile(A15,.025),'--','Linewidth',3,'Color','g')
hold on
plot((aa_ref:2:59)',A15_est-mean(A15)+quantile(A15,.975),'--','Linewidth',3,'Color','g')
hold off
xlabel('age','FontSize',20)
set(gca,'xlim',[35 59])
set(gca,'xtick',(35:2:59))
ylabel('log-consumption','FontSize',20)
set(gca,'ylim',[-.15 0])
set(gca,'ytick',(-.15:.05:0))

figure
plot((aa_ref:2:59)',A16_est,'-','Linewidth',3,'Color','b')
hold on
plot((aa_ref:2:59)',A16_est-mean(A16)+quantile(A16,.025),'--','Linewidth',3,'Color','g')
hold on
plot((aa_ref:2:59)',A16_est-mean(A16)+quantile(A16,.975),'--','Linewidth',3,'Color','g')
hold off
xlabel('age','FontSize',20)
set(gca,'xlim',[35 59])
set(gca,'xtick',(35:2:59))
ylabel('log-consumption','FontSize',20)
set(gca,'ylim',[0 .15])
set(gca,'ytick',(0:.05:0.15))

figure
plot((aa_ref:2:59)',A17_est,'-','Linewidth',3,'Color','b')
hold on
plot((aa_ref:2:59)',A17_est-mean(A17)+quantile(A17,.025),'--','Linewidth',3,'Color','g')
hold on
plot((aa_ref:2:59)',A17_est-mean(A17)+quantile(A17,.975),'--','Linewidth',3,'Color','g')
hold off
xlabel('age','FontSize',20)
set(gca,'xlim',[35 59])
set(gca,'xtick',(35:2:59))
ylabel('log-consumption','FontSize',20)
set(gca,'ylim',[-.15 0])
set(gca,'ytick',(-.15:.05:0))

figure
plot((aa_ref:2:59)',A18_est,'-','Linewidth',3,'Color','b')
hold on
plot((aa_ref:2:59)',A18_est-mean(A18)+quantile(A18,.025),'--','Linewidth',3,'Color','g')
hold on
plot((aa_ref:2:59)',A18_est-mean(A18)+quantile(A18,.975),'--','Linewidth',3,'Color','g')
hold off
xlabel('age','FontSize',20)
set(gca,'xlim',[35 59])
set(gca,'xtick',(35:2:59))
ylabel('log-consumption','FontSize',20)
set(gca,'ylim',[0 .15])
set(gca,'ytick',(0:.05:0.15))




% Uniform probability

p=.0050;
A=A1;
A_est=A1_est;
q_down=quantile(A,p);
q_up=quantile(A,1-p);

prod=ones(Nboot_tot,1);

for aa=1:13
    
        Vect=A(:,aa);
        prod=prod.*(Vect>=q_down(aa)).*(Vect<=q_up(aa));
        
end
sum(prod)/Nboot_tot

figure
plot((aa_ref:2:59)',A_est,'-','Linewidth',3,'Color','b')
hold on
plot((aa_ref:2:59)',A_est-mean(A)+quantile(A,p),'--','Linewidth',3,'Color','g')
hold on
plot((aa_ref:2:59)',A_est-mean(A)+quantile(A,1-p),'--','Linewidth',3,'Color','g')
hold off
xlabel('age','FontSize',20)
set(gca,'xlim',[35 59])
set(gca,'xtick',(35:2:59))
ylabel('log-earnings','FontSize',20)
set(gca,'ylim',[-.3 0])
set(gca,'ytick',(-.3:.05:0))

p=.005;
A=A2;
A_est=A2_est;
q_down=quantile(A,p);
q_up=quantile(A,1-p);

prod=ones(Nboot_tot,1);

for aa=1:13
    
        Vect=A(:,aa);
        prod=prod.*(Vect>=q_down(aa)).*(Vect<=q_up(aa));
        
end
sum(prod)/Nboot_tot

figure
plot((aa_ref:2:59)',A_est,'-','Linewidth',3,'Color','b')
hold on
plot((aa_ref:2:59)',A_est-mean(A)+quantile(A,p),'--','Linewidth',3,'Color','g')
hold on
plot((aa_ref:2:59)',A_est-mean(A)+quantile(A,1-p),'--','Linewidth',3,'Color','g')
hold off
xlabel('age','FontSize',20)
set(gca,'xlim',[35 59])
set(gca,'xtick',(35:2:59))
ylabel('log-earnings','FontSize',20)
set(gca,'ylim',[0 .3])
set(gca,'ytick',(0:.05:0.3))

p=.0050;
A=A3;
A_est=A3_est;
q_down=quantile(A,p);
q_up=quantile(A,1-p);

prod=ones(Nboot_tot,1);

for aa=1:13
    
        Vect=A(:,aa);
        prod=prod.*(Vect>=q_down(aa)).*(Vect<=q_up(aa));
        
end
sum(prod)/Nboot_tot

figure
plot((aa_ref:2:59)',A_est,'-','Linewidth',3,'Color','b')
hold on
plot((aa_ref:2:59)',A_est-mean(A)+quantile(A,p),'--','Linewidth',3,'Color','g')
hold on
plot((aa_ref:2:59)',A_est-mean(A)+quantile(A,1-p),'--','Linewidth',3,'Color','g')
hold off
xlabel('age','FontSize',20)
set(gca,'xlim',[35 59])
set(gca,'xtick',(35:2:59))
ylabel('log-earnings','FontSize',20)
set(gca,'ylim',[-.3 0])
set(gca,'ytick',(-.3:.05:0))

p=.005;
A=A4;
A_est=A4_est;
q_down=quantile(A,p);
q_up=quantile(A,1-p);

prod=ones(Nboot_tot,1);

for aa=1:13
    
        Vect=A(:,aa);
        prod=prod.*(Vect>=q_down(aa)).*(Vect<=q_up(aa));
        
end
sum(prod)/Nboot_tot

figure
plot((aa_ref:2:59)',A_est,'-','Linewidth',3,'Color','b')
hold on
plot((aa_ref:2:59)',A_est-mean(A)+quantile(A,p),'--','Linewidth',3,'Color','g')
hold on
plot((aa_ref:2:59)',A_est-mean(A)+quantile(A,1-p),'--','Linewidth',3,'Color','g')
hold off
xlabel('age','FontSize',20)
set(gca,'xlim',[35 59])
set(gca,'xtick',(35:2:59))
ylabel('log-earnings','FontSize',20)
set(gca,'ylim',[0 .3])
set(gca,'ytick',(0:.05:0.3))


p=.0050;
A=A5;
A_est=A5_est;
q_down=quantile(A,p);
q_up=quantile(A,1-p);

prod=ones(Nboot_tot,1);

for aa=1:13
    
        Vect=A(:,aa);
        prod=prod.*(Vect>=q_down(aa)).*(Vect<=q_up(aa));
        
end
sum(prod)/Nboot_tot

figure
plot((aa_ref:2:59)',A_est,'-','Linewidth',3,'Color','b')
hold on
plot((aa_ref:2:59)',A_est-mean(A)+quantile(A,p),'--','Linewidth',3,'Color','g')
hold on
plot((aa_ref:2:59)',A_est-mean(A)+quantile(A,1-p),'--','Linewidth',3,'Color','g')
hold off
xlabel('age','FontSize',20)
set(gca,'xlim',[35 59])
set(gca,'xtick',(35:2:59))
ylabel('log-earnings','FontSize',20)
set(gca,'ylim',[-.3 0])
set(gca,'ytick',(-.3:.05:0))

p=.005;
A=A6;
A_est=A6_est;
q_down=quantile(A,p);
q_up=quantile(A,1-p);

prod=ones(Nboot_tot,1);

for aa=1:13
    
        Vect=A(:,aa);
        prod=prod.*(Vect>=q_down(aa)).*(Vect<=q_up(aa));
        
end
sum(prod)/Nboot_tot

figure
plot((aa_ref:2:59)',A_est,'-','Linewidth',3,'Color','b')
hold on
plot((aa_ref:2:59)',A_est-mean(A)+quantile(A,p),'--','Linewidth',3,'Color','g')
hold on
plot((aa_ref:2:59)',A_est-mean(A)+quantile(A,1-p),'--','Linewidth',3,'Color','g')
hold off
xlabel('age','FontSize',20)
set(gca,'xlim',[35 59])
set(gca,'xtick',(35:2:59))
ylabel('log-earnings','FontSize',20)
set(gca,'ylim',[0 .3])
set(gca,'ytick',(0:.05:0.3))

p=.0050;
A=A7;
A_est=A7_est;
q_down=quantile(A,p);
q_up=quantile(A,1-p);

prod=ones(Nboot_tot,1);

for aa=1:13
    
        Vect=A(:,aa);
        prod=prod.*(Vect>=q_down(aa)).*(Vect<=q_up(aa));
        
end
sum(prod)/Nboot_tot

figure
plot((aa_ref:2:59)',A_est,'-','Linewidth',3,'Color','b')
hold on
plot((aa_ref:2:59)',A_est-mean(A)+quantile(A,p),'--','Linewidth',3,'Color','g')
hold on
plot((aa_ref:2:59)',A_est-mean(A)+quantile(A,1-p),'--','Linewidth',3,'Color','g')
hold off
xlabel('age','FontSize',20)
set(gca,'xlim',[35 59])
set(gca,'xtick',(35:2:59))
ylabel('log-consumption','FontSize',20)
set(gca,'ylim',[-.15 0])
set(gca,'ytick',(-.15:.05:0))

p=.005;
A=A8;
A_est=A8_est;
q_down=quantile(A,p);
q_up=quantile(A,1-p);

prod=ones(Nboot_tot,1);

for aa=1:13
    
        Vect=A(:,aa);
        prod=prod.*(Vect>=q_down(aa)).*(Vect<=q_up(aa));
        
end
sum(prod)/Nboot_tot

figure
plot((aa_ref:2:59)',A_est,'-','Linewidth',3,'Color','b')
hold on
plot((aa_ref:2:59)',A_est-mean(A)+quantile(A,p),'--','Linewidth',3,'Color','g')
hold on
plot((aa_ref:2:59)',A_est-mean(A)+quantile(A,1-p),'--','Linewidth',3,'Color','g')
hold off
xlabel('age','FontSize',20)
set(gca,'xlim',[35 59])
set(gca,'xtick',(35:2:59))
ylabel('log-consumption','FontSize',20)
set(gca,'ylim',[0 .15])
set(gca,'ytick',(0:.05:0.15))

p=.0050;
A=A9;
A_est=A9_est;
q_down=quantile(A,p);
q_up=quantile(A,1-p);

prod=ones(Nboot_tot,1);

for aa=1:13
    
        Vect=A(:,aa);
        prod=prod.*(Vect>=q_down(aa)).*(Vect<=q_up(aa));
        
end
sum(prod)/Nboot_tot

figure
plot((aa_ref:2:59)',A_est,'-','Linewidth',3,'Color','b')
hold on
plot((aa_ref:2:59)',A_est-mean(A)+quantile(A,p),'--','Linewidth',3,'Color','g')
hold on
plot((aa_ref:2:59)',A_est-mean(A)+quantile(A,1-p),'--','Linewidth',3,'Color','g')
hold off
xlabel('age','FontSize',20)
set(gca,'xlim',[35 59])
set(gca,'xtick',(35:2:59))
ylabel('log-consumption','FontSize',20)
set(gca,'ylim',[-.15 0])
set(gca,'ytick',(-.15:.05:0))

p=.005;
A=A10;
A_est=A10_est;
q_down=quantile(A,p);
q_up=quantile(A,1-p);

prod=ones(Nboot_tot,1);

for aa=1:13
    
        Vect=A(:,aa);
        prod=prod.*(Vect>=q_down(aa)).*(Vect<=q_up(aa));
        
end
sum(prod)/Nboot_tot

figure
plot((aa_ref:2:59)',A_est,'-','Linewidth',3,'Color','b')
hold on
plot((aa_ref:2:59)',A_est-mean(A)+quantile(A,p),'--','Linewidth',3,'Color','g')
hold on
plot((aa_ref:2:59)',A_est-mean(A)+quantile(A,1-p),'--','Linewidth',3,'Color','g')
hold off
xlabel('age','FontSize',20)
set(gca,'xlim',[35 59])
set(gca,'xtick',(35:2:59))
ylabel('log-consumption','FontSize',20)
set(gca,'ylim',[0 .15])
set(gca,'ytick',(0:.05:0.15))



p=.0050;
A=A11;
A_est=A11_est;
q_down=quantile(A,p);
q_up=quantile(A,1-p);

prod=ones(Nboot_tot,1);

for aa=1:13
    
        Vect=A(:,aa);
        prod=prod.*(Vect>=q_down(aa)).*(Vect<=q_up(aa));
        
end
sum(prod)/Nboot_tot

figure
plot((aa_ref:2:59)',A_est,'-','Linewidth',3,'Color','b')
hold on
plot((aa_ref:2:59)',A_est-mean(A)+quantile(A,p),'--','Linewidth',3,'Color','g')
hold on
plot((aa_ref:2:59)',A_est-mean(A)+quantile(A,1-p),'--','Linewidth',3,'Color','g')
hold off
xlabel('age','FontSize',20)
set(gca,'xlim',[35 59])
set(gca,'xtick',(35:2:59))
ylabel('log-consumption','FontSize',20)
set(gca,'ylim',[-.15 0])
set(gca,'ytick',(-.15:.05:0))

p=.005;
A=A12;
A_est=A12_est;
q_down=quantile(A,p);
q_up=quantile(A,1-p);

prod=ones(Nboot_tot,1);

for aa=1:13
    
        Vect=A(:,aa);
        prod=prod.*(Vect>=q_down(aa)).*(Vect<=q_up(aa));
        
end
sum(prod)/Nboot_tot

figure
plot((aa_ref:2:59)',A_est,'-','Linewidth',3,'Color','b')
hold on
plot((aa_ref:2:59)',A_est-mean(A)+quantile(A,p),'--','Linewidth',3,'Color','g')
hold on
plot((aa_ref:2:59)',A_est-mean(A)+quantile(A,1-p),'--','Linewidth',3,'Color','g')
hold off
xlabel('age','FontSize',20)
set(gca,'xlim',[35 59])
set(gca,'xtick',(35:2:59))
ylabel('log-consumption','FontSize',20)
set(gca,'ylim',[0 .15])
set(gca,'ytick',(0:.05:0.15))




p=.0050;
A=A13;
A_est=A13_est;
q_down=quantile(A,p);
q_up=quantile(A,1-p);

prod=ones(Nboot_tot,1);

for aa=1:13
    
        Vect=A(:,aa);
        prod=prod.*(Vect>=q_down(aa)).*(Vect<=q_up(aa));
        
end
sum(prod)/Nboot_tot

figure
plot((aa_ref:2:59)',A_est,'-','Linewidth',3,'Color','b')
hold on
plot((aa_ref:2:59)',A_est-mean(A)+quantile(A,p),'--','Linewidth',3,'Color','g')
hold on
plot((aa_ref:2:59)',A_est-mean(A)+quantile(A,1-p),'--','Linewidth',3,'Color','g')
hold off
xlabel('age','FontSize',20)
set(gca,'xlim',[35 59])
set(gca,'xtick',(35:2:59))
ylabel('log-consumption','FontSize',20)
set(gca,'ylim',[-.15 0])
set(gca,'ytick',(-.15:.05:0))

p=.005;
A=A14;
A_est=A14_est;
q_down=quantile(A,p);
q_up=quantile(A,1-p);

prod=ones(Nboot_tot,1);

for aa=1:13
    
        Vect=A(:,aa);
        prod=prod.*(Vect>=q_down(aa)).*(Vect<=q_up(aa));
        
end
sum(prod)/Nboot_tot

figure
plot((aa_ref:2:59)',A_est,'-','Linewidth',3,'Color','b')
hold on
plot((aa_ref:2:59)',A_est-mean(A)+quantile(A,p),'--','Linewidth',3,'Color','g')
hold on
plot((aa_ref:2:59)',A_est-mean(A)+quantile(A,1-p),'--','Linewidth',3,'Color','g')
hold off
xlabel('age','FontSize',20)
set(gca,'xlim',[35 59])
set(gca,'xtick',(35:2:59))
ylabel('log-consumption','FontSize',20)
set(gca,'ylim',[0 .15])
set(gca,'ytick',(0:.05:0.15))



p=.0050;
A=A15;
A_est=A15_est;
q_down=quantile(A,p);
q_up=quantile(A,1-p);

prod=ones(Nboot_tot,1);

for aa=1:13
    
        Vect=A(:,aa);
        prod=prod.*(Vect>=q_down(aa)).*(Vect<=q_up(aa));
        
end
sum(prod)/Nboot_tot

figure
plot((aa_ref:2:59)',A_est,'-','Linewidth',3,'Color','b')
hold on
plot((aa_ref:2:59)',A_est-mean(A)+quantile(A,p),'--','Linewidth',3,'Color','g')
hold on
plot((aa_ref:2:59)',A_est-mean(A)+quantile(A,1-p),'--','Linewidth',3,'Color','g')
hold off
xlabel('age','FontSize',20)
set(gca,'xlim',[35 59])
set(gca,'xtick',(35:2:59))
ylabel('log-consumption','FontSize',20)
set(gca,'ylim',[-.15 0])
set(gca,'ytick',(-.15:.05:0))

p=.005;
A=A16;
A_est=A16_est;
q_down=quantile(A,p);
q_up=quantile(A,1-p);

prod=ones(Nboot_tot,1);

for aa=1:13
    
        Vect=A(:,aa);
        prod=prod.*(Vect>=q_down(aa)).*(Vect<=q_up(aa));
        
end
sum(prod)/Nboot_tot

figure
plot((aa_ref:2:59)',A_est,'-','Linewidth',3,'Color','b')
hold on
plot((aa_ref:2:59)',A_est-mean(A)+quantile(A,p),'--','Linewidth',3,'Color','g')
hold on
plot((aa_ref:2:59)',A_est-mean(A)+quantile(A,1-p),'--','Linewidth',3,'Color','g')
hold off
xlabel('age','FontSize',20)
set(gca,'xlim',[35 59])
set(gca,'xtick',(35:2:59))
ylabel('log-consumption','FontSize',20)
set(gca,'ylim',[0 .15])
set(gca,'ytick',(0:.05:0.15))







p=.0050;
A=A17;
A_est=A17_est;
q_down=quantile(A,p);
q_up=quantile(A,1-p);

prod=ones(Nboot_tot,1);

for aa=1:13
    
        Vect=A(:,aa);
        prod=prod.*(Vect>=q_down(aa)).*(Vect<=q_up(aa));
        
end
sum(prod)/Nboot_tot

figure
plot((aa_ref:2:59)',A_est,'-','Linewidth',3,'Color','b')
hold on
plot((aa_ref:2:59)',A_est-mean(A)+quantile(A,p),'--','Linewidth',3,'Color','g')
hold on
plot((aa_ref:2:59)',A_est-mean(A)+quantile(A,1-p),'--','Linewidth',3,'Color','g')
hold off
xlabel('age','FontSize',20)
set(gca,'xlim',[35 59])
set(gca,'xtick',(35:2:59))
ylabel('log-consumption','FontSize',20)
set(gca,'ylim',[-.15 0])
set(gca,'ytick',(-.15:.05:0))

p=.001;
A=A18;
A_est=A18_est;
q_down=quantile(A,p);
q_up=quantile(A,1-p);

prod=ones(Nboot_tot,1);

for aa=1:13
    
        Vect=A(:,aa);
        prod=prod.*(Vect>=q_down(aa)).*(Vect<=q_up(aa));
        
end
sum(prod)/Nboot_tot

figure
plot((aa_ref:2:59)',A_est,'-','Linewidth',3,'Color','b')
hold on
plot((aa_ref:2:59)',A_est-mean(A)+quantile(A,p),'--','Linewidth',3,'Color','g')
hold on
plot((aa_ref:2:59)',A_est-mean(A)+quantile(A,1-p),'--','Linewidth',3,'Color','g')
hold off
xlabel('age','FontSize',20)
set(gca,'xlim',[35 59])
set(gca,'xtick',(35:2:59))
ylabel('log-consumption','FontSize',20)
set(gca,'ylim',[0 .15])
set(gca,'ytick',(0:.05:0.15))






































































