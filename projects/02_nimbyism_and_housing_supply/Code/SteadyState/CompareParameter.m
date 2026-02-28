clear
close all
cepath='/Users/igro0002/Library/CloudStorage/GoogleDrive-isaac.gross@monash.edu/My Drive/code/compecon2011/'; path([cepath 'CEtools;' cepath 'CEdemos'],path);
%cepath='/Users/igro0002/Library/CloudStorage/GoogleDrive-isaac.gross@monash.edu/My Drive/Code'; path(cepath,path);



baseline=load('/Users/igro0002/Dropbox (Monash Uni Enterprise)/Zac and David/code/steadystate/Mod_IRF/irfs_smoothed.mat','Pstars_smoothed','param','ageimpulse','TargetVote','options','ss_eq','agevector','boom','glob');
param1=load('/Users/igro0002/Dropbox (Monash Uni Enterprise)/Zac and David/code/steadystate/Mod_IRF_Param1/irfs_smoothed.mat','Pstars_smoothed','param','ageimpulse','TargetVote','options','ss_eq','agevector','boom','glob');
param2=load('/Users/igro0002/Dropbox (Monash Uni Enterprise)/Zac and David/code/steadystate/Mod_IRF_Param2/irfs_smoothed.mat','Pstars_smoothed','param','ageimpulse','TargetVote','options','ss_eq','agevector','boom','glob');


baseline=load('/Users/igro0002/Dropbox (Monash Uni Enterprise)/Zac and David/code/steadystate/Mod_IRF/irfs_smoothed.mat');
param1=load('/Users/igro0002/Dropbox (Monash Uni Enterprise)/Zac and David/code/steadystate/Mod_IRF_Param1/irfs_smoothed.mat');
param2=load('/Users/igro0002/Dropbox (Monash Uni Enterprise)/Zac and David/code/steadystate/Mod_IRF_Param2/irfs_smoothed.m);


%%

% subplot(2,4,2)
figure
set(gcf,'Color','w')
hold on
plot(flip(boom),'linewidth',2)
xlabel('Time')
title('Birthrate (lag 25 years)')
ylim([0.98 1.12])
set(gca,'FontSize',16)
box on
export_fig('Bith.jpeg','-M5')

% subplot(2,4,3)
figure
set(gcf,'Color','w')
hold on
plot(homeownership_25_35_smoothed+35/100,'linewidth',2)
xlabel('Time')
title('Young (25-35 years) Home Ownership Rate')
box on;
set(gca,'FontSize',16)
export_fig('Home30.jpeg','-M5')

% subplot(2,4,4)
figure
set(gcf,'Color','w')
hold on
plot(homeownership_55_65_smoothed,'linewidth',2)
xlabel('Time')
title('Old (55-66 years) Home Ownership Rate')
box on
set(gca,'FontSize',16)
export_fig('Home60.jpeg','-M5')


% subplot(2,4,5)
figure
set(gcf,'Color','w')
hold on
plot(averageage,'linewidth',2)
xlabel('Time')
title('Average Age')

box on
set(gca,'FontSize',16)
export_fig('AverageAge.jpeg','-M5')

% subplot(2,4,6)
figure
set(gcf,'Color','w')
hold on
plot(cons_25_35_smoothed./cons_25_35_smoothed(1),'linewidth',2)
plot(cons_55_65_smoothed./cons_55_65_smoothed(1),'linewidth',2)
xlabel('Time')
title('Consumption (normalised)')
legend('Young','Old')
legend boxoff
set(gca,'FontSize',16)
box on
export_fig('Consum.jpeg','-M5')


% subplot(2,4,7)
figure
set(gcf,'Color','w')
hold on
plot(networth_25_35_smoothed./networth_25_35_smoothed(1),'linewidth',2)
plot(networth_55_65_smoothed./networth_55_65_smoothed(1),'linewidth',2)
xlabel('Time')
title('Networth Deviation from Steady State')
legend('Young','Old')
legend boxoff
set(gca,'FontSize',16)
box on
export_fig('NW1.jpeg','-M5')


% subplot(2,4,8)
figure
set(gcf,'Color','w')
hold on
plot(networth_55_65_smoothed./networth_25_35_smoothed,'linewidth',2)
xlabel('Time')
title('Average Networth Ratio')
legend('Old/Young')
legend boxoff
set(gca,'FontSize',16)
box on
export_fig('NW2.jpeg','-M5')

figure
set(gcf,'Color','w')
% subplot(2,2,1)
hold on
plot(networth_boom_smoothed,'linewidth',2)
plot(networth_child_smoothed,'linewidth',2)
plot(networth_parent_smoothed,'linewidth',2)
yline(1)
xlabel('Time')
title('Networth Deviation from Steady State')
legend('Boom Generation','Child (25 years younger)','Parents (25 years older)','')
legend boxoff
set(gca,'FontSize',16)
box on
export_fig('Generations1.jpeg','-M5')

% subplot(2,2,2)
figure
set(gcf,'Color','w')
hold on
plot(homeownership_boom_smoothed,'linewidth',2)
plot(homeownership_child_smoothed,'linewidth',2)
plot(homeownership_parent_smoothed,'linewidth',2)
yline(1)
xlabel('Time')
title('Homeownership Deviation from Steady State')
legend('Boom Generation','Child (25 years younger)','Parents (25 years older)','')
legend boxoff
set(gca,'FontSize',16)
box on
export_fig('Generations2.jpeg','-M5')

% subplot(2,2,3)
figure
set(gcf,'Color','w')
hold on
plot(consumption_boom_smoothed,'linewidth',2)
plot(consumption_child_smoothed,'linewidth',2)
plot(consumption_parent_smoothed,'linewidth',2)
yline(1)
xlabel('Time')
title('Consumption Deviation from Steady State')
legend('Boom','Child','Parents','')
box on
set(gca,'FontSize',16)
legend boxoff
export_fig('Generations3.jpeg','-M5')

% subplot(2,2,4)
figure
set(gcf,'Color','w')
hold on
plot(housing_boom_smoothed,'linewidth',2)
plot(housing_child_smoothed,'linewidth',2)
plot(housing_parent_smoothed,'linewidth',2)
yline(1)
xlabel('Time')
title('Homeownership Deviation from Steady State')
set(gca,'FontSize',16)
legend('Boom','Child','Parents','','location','best')
legend boxoff
box on
export_fig('Generations4.jpeg','-M5')




drawnow
%%

%save('irfs_smoothed.mat','-v7.3')

