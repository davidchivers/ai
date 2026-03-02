clear
close all
cepath='/Users/igro0002/Library/CloudStorage/GoogleDrive-isaac.gross@monash.edu/My Drive/code/'; path([cepath 'CEtools;' cepath 'CEdemos'],path);
cepath='/Users/igro0002/Library/CloudStorage/GoogleDrive-isaac.gross@monash.edu/My Drive/Code'; path(cepath,path);

load('/Users/igro0002/Dropbox (Monash Uni Enterprise)/Zac and David/code/steadystate/Mod_IRF/irfs_smoothed.mat','param','glob','boom');

IRF=load('/Users/igro0002/Dropbox (Monash Uni Enterprise)/Zac and David/code/steadystate/Mod_IRF/irfs_smoothed.mat','agevector','homeownership_SS','LiquidAssets','utility_ss','VoteAge','averageage','boom','cons_25_35_smoothed','cons_55_65_smoothed','cons_smoothed','consumption_boom_smoothed','consumption_child_smoothed','consumption_parent_smoothed','ExcessDemand_smoothed','homeownership_25_35_smoothed','homeownership_35_45_smoothed','homeownership_35_smoothed','homeownership_45_55_smoothed','homeownership_45_smoothed','homeownership_55_65_smoothed','homeownership_55_smoothed','homeownership_65_75_smoothed','homeownership_65_smoothed','homeownership_75_smoothed','homeownership_boom_smoothed','homeownership_child_smoothed','homeownership_parent_smoothed','homeownership_Q1_smoothed','homeownership_Q2_smoothed','homeownership_Q3_smoothed','homeownership_Q4_smoothed','homeownership_Q5_smoothed','homeownership_smoothed','HouseQuantity','housing_boom_smoothed','housing_child_smoothed','housing_parent_smoothed','networth_25_35_smoothed','networth_55_65_smoothed','networth_boom_smoothed','networth_child_smoothed','networth_parent_smoothed','networth_smoothed','Pstars','Pstars_smoothed','rent_smoothed','RentQuantity','TotalHouse','utility_aggregate_smoothed','utility_boom_smoothed','utility_child_smoothed','utility_parent_smoothed','VoteBaseline_smoothed','averageage');
IRF_FixedH=load('/Users/igro0002/Dropbox (Monash Uni Enterprise)/Zac and David/code/steadystate/Mod_IRF_FixedH/irfs_smoothed.mat','agevector','homeownership_SS','LiquidAssets','utility_ss','VoteAge','averageage','boom','cons_25_35_smoothed','cons_55_65_smoothed','cons_smoothed','consumption_boom_smoothed','consumption_child_smoothed','consumption_parent_smoothed','ExcessDemand_smoothed','homeownership_25_35_smoothed','homeownership_35_45_smoothed','homeownership_35_smoothed','homeownership_45_55_smoothed','homeownership_45_smoothed','homeownership_55_65_smoothed','homeownership_55_smoothed','homeownership_65_75_smoothed','homeownership_65_smoothed','homeownership_75_smoothed','homeownership_boom_smoothed','homeownership_child_smoothed','homeownership_parent_smoothed','homeownership_Q1_smoothed','homeownership_Q2_smoothed','homeownership_Q3_smoothed','homeownership_Q4_smoothed','homeownership_Q5_smoothed','homeownership_smoothed','HouseQuantity','housing_boom_smoothed','housing_child_smoothed','housing_parent_smoothed','networth_25_35_smoothed','networth_55_65_smoothed','networth_boom_smoothed','networth_child_smoothed','networth_parent_smoothed','networth_smoothed','Pstars','Pstars_smoothed','rent_smoothed','RentQuantity','TotalHouse','utility_aggregate_smoothed','utility_boom_smoothed','utility_child_smoothed','utility_parent_smoothed','VoteBaseline_smoothed','averageage')
IRF_FixedHP=load('/Users/igro0002/Dropbox (Monash Uni Enterprise)/Zac and David/code/steadystate/Mod_IRF_FixedHP/irfs_smoothed.mat','agevector','homeownership_SS','LiquidAssets','utility_ss','VoteAge','averageage','boom','cons_25_35_smoothed','cons_55_65_smoothed','cons_smoothed','consumption_boom_smoothed','consumption_child_smoothed','consumption_parent_smoothed','ExcessDemand_smoothed','homeownership_25_35_smoothed','homeownership_35_45_smoothed','homeownership_35_smoothed','homeownership_45_55_smoothed','homeownership_45_smoothed','homeownership_55_65_smoothed','homeownership_55_smoothed','homeownership_65_75_smoothed','homeownership_65_smoothed','homeownership_75_smoothed','homeownership_boom_smoothed','homeownership_child_smoothed','homeownership_parent_smoothed','homeownership_Q1_smoothed','homeownership_Q2_smoothed','homeownership_Q3_smoothed','homeownership_Q4_smoothed','homeownership_Q5_smoothed','homeownership_smoothed','HouseQuantity','housing_boom_smoothed','housing_child_smoothed','housing_parent_smoothed','networth_25_35_smoothed','networth_55_65_smoothed','networth_boom_smoothed','networth_child_smoothed','networth_parent_smoothed','networth_smoothed','Pstars','Pstars_smoothed','rent_smoothed','RentQuantity','TotalHouse','utility_aggregate_smoothed','utility_boom_smoothed','utility_child_smoothed','utility_parent_smoothed','VoteBaseline_smoothed','averageage')

% 
% uIRF=load('/Users/igro0002/Dropbox (Monash Uni Enterprise)/Zac and David/code/steadystate/Mod_IRF/irfs.mat','averageage','boom','cons_25_35_smoothed','cons_55_65_smoothed','consumption_boom_smoothed','consumption_child_smoothed','consumption_parent_smoothed','ExcessDemand_smoothed','homeownership_25_35_smoothed','homeownership_35_45_smoothed','homeownership_35_smoothed','homeownership_45_55_smoothed','homeownership_45_smoothed','homeownership_55_65_smoothed','homeownership_55_smoothed','homeownership_65_75_smoothed','homeownership_65_smoothed','homeownership_75_smoothed','homeownership_boom_smoothed','homeownership_child_smoothed','homeownership_parent_smoothed','homeownership_Q1_smoothed','homeownership_Q2_smoothed','homeownership_Q3_smoothed','homeownership_Q4_smoothed','homeownership_Q5_smoothed','homeownership_smoothed','HouseQuantity','housing_boom_smoothed','housing_child_smoothed','housing_parent_smoothed','networth_25_35_smoothed','networth_55_65_smoothed','networth_boom_smoothed','networth_child_smoothed','networth_parent_smoothed','networth_smoothed','Pstars','Pstars_smoothed','utility_boom_smoothed','utility_child_smoothed','utilty_parent_smoothed','VoteBaseline_smoothed');
% uIRF_FixedH=load('/Users/igro0002/Dropbox (Monash Uni Enterprise)/Zac and David/code/steadystate/Mod_IRF_FixedH/irfs.mat','averageage','boom','cons_25_35_smoothed','cons_55_65_smoothed','consumption_boom_smoothed','consumption_child_smoothed','consumption_parent_smoothed','ExcessDemand_smoothed','homeownership_25_35_smoothed','homeownership_35_45_smoothed','homeownership_35_smoothed','homeownership_45_55_smoothed','homeownership_45_smoothed','homeownership_55_65_smoothed','homeownership_55_smoothed','homeownership_65_75_smoothed','homeownership_65_smoothed','homeownership_75_smoothed','homeownership_boom_smoothed','homeownership_child_smoothed','homeownership_parent_smoothed','homeownership_Q1_smoothed','homeownership_Q2_smoothed','homeownership_Q3_smoothed','homeownership_Q4_smoothed','homeownership_Q5_smoothed','homeownership_smoothed','HouseQuantity','housing_boom_smoothed','housing_child_smoothed','housing_parent_smoothed','networth_25_35_smoothed','networth_55_65_smoothed','networth_boom_smoothed','networth_child_smoothed','networth_parent_smoothed','networth_smoothed','Pstars','Pstars_smoothed','utility_boom_smoothed','utility_child_smoothed','utilty_parent_smoothed','VoteBaseline_smoothed');
% uIRF_FixedHP=load('/Users/igro0002/Dropbox (Monash Uni Enterprise)/Zac and David/code/steadystate/Mod_IRF_FixedHP/irfs.mat','averageage','boom','cons_25_35_smoothed','cons_55_65_smoothed','consumption_boom_smoothed','consumption_child_smoothed','consumption_parent_smoothed','ExcessDemand_smoothed','homeownership_25_35_smoothed','homeownership_35_45_smoothed','homeownership_35_smoothed','homeownership_45_55_smoothed','homeownership_45_smoothed','homeownership_55_65_smoothed','homeownership_55_smoothed','homeownership_65_75_smoothed','homeownership_65_smoothed','homeownership_75_smoothed','homeownership_boom_smoothed','homeownership_child_smoothed','homeownership_parent_smoothed','homeownership_Q1_smoothed','homeownership_Q2_smoothed','homeownership_Q3_smoothed','homeownership_Q4_smoothed','homeownership_Q5_smoothed','homeownership_smoothed','HouseQuantity','housing_boom_smoothed','housing_child_smoothed','housing_parent_smoothed','networth_25_35_smoothed','networth_55_65_smoothed','networth_boom_smoothed','networth_child_smoothed','networth_parent_smoothed','networth_smoothed','Pstars','Pstars_smoothed','utility_boom_smoothed','utility_child_smoothed','utilty_parent_smoothed','VoteBaseline_smoothed');


%%


figure
% subplot(2,4,1)
set(gcf,'Color','w')
hold on
plot((IRF.Pstars_smoothed/param.Ph_ss-1)*3+1,'linewidth',2)
plot((IRF_FixedH.Pstars_smoothed/param.Ph_ss-1)*3+1,':','linewidth',2)
% plot((IRF_FixedHP.Pstars_smoothed/param.Ph_ss-1)*3+1,'-.','linewidth',2)
%yline(param.Ph_ss)

xlabel('Time (Years)')
title('House Price Deviation from Steady State')
legend('Baseline','Fixed Housing Stock','Fixed Housing Per Capita');legend boxoff;
set(gca,'FontSize',16)
box on
export_fig('SmoothedHousePrice.jpeg','-M5')

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
export_fig('Birth.jpeg','-M5')

% subplot(2,4,3)
figure
set(gcf,'Color','w')
hold on
plot(IRF.homeownership_25_35_smoothed+35/100,'linewidth',2)
plot(IRF_FixedH.homeownership_25_35_smoothed+35/100,':','linewidth',2)
% plot(IRF_FixedHP.homeownership_25_35_smoothed+35/100,'-.','linewidth',2)
xlabel('Time')
title('Young (25-35 years) Home Ownership Rate')
box on;
set(gca,'FontSize',16)
export_fig('Home30.jpeg','-M5')

% subplot(2,4,4)
figure
set(gcf,'Color','w')
hold on
plot(IRF.homeownership_55_65_smoothed,'linewidth',2)
plot(IRF_FixedH.homeownership_55_65_smoothed,':','linewidth',2)
% plot(IRF_FixedHP.homeownership_55_65_smoothed,'-.','linewidth',2)
xlabel('Time')
title('Old (55-66 years) Home Ownership Rate')
box on
set(gca,'FontSize',16)
export_fig('Home60.jpeg','-M5')


% subplot(2,4,4)
figure
set(gcf,'Color','w')
hold on
plot(IRF.homeownership_smoothed,'linewidth',2)
plot(IRF_FixedH.homeownership_smoothed,':','linewidth',2)
% plot(IRF_FixedHP.homeownership_smoothed,'-.','linewidth',2)
xlabel('Time')
title('Home Ownership Rate')
box on
set(gca,'FontSize',16)
export_fig('HomeOwnership.jpeg','-M5')

figure
set(gcf,'Color','w')
hold on
plot(IRF.networth_smoothed,'linewidth',2)
plot(IRF_FixedH.networth_smoothed,':','linewidth',2)
% plot(IRF_FixedHP.networth_smoothed,'-.','linewidth',2)
xlabel('Time')
title('Aggregate Networth')
box on
set(gca,'FontSize',16)
export_fig('networth.jpeg','-M5')


% subplot(2,4,4)
figure
set(gcf,'Color','w')
hold on
plot(IRF.cons_smoothed,'linewidth',2)
plot(IRF_FixedH.cons_smoothed,':','linewidth',2)
% plot(IRF_FixedHP.cons_smoothed,'-.','linewidth',2)
xlabel('Time')
title('Aggregate Non-durable Consumption')
box on
set(gca,'FontSize',16)
export_fig('Consump.jpeg','-M5')



% subplot(2,4,4)
figure
set(gcf,'Color','w')
hold on
plot(IRF.rent_smoothed,'linewidth',2)
plot(IRF_FixedH.rent_smoothed,':','linewidth',2)
% plot(IRF_FixedHP.rent_smoothed,'-.','linewidth',2)
xlabel('Time')
title('Aggregate Rental Expenditure')
box on
set(gca,'FontSize',16)
export_fig('Rent.jpeg','-M5')


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
plot(IRF.cons_25_35_smoothed./IRF.cons_25_35_smoothed(1),'linewidth',2)
plot(IRF.cons_55_65_smoothed./IRF.cons_55_65_smoothed(1),'linewidth',2)

plot(IRF_FixedH.cons_25_35_smoothed./IRF_FixedH.cons_25_35_smoothed(1),'linewidth',2)
plot(IRF_FixedH.cons_55_65_smoothed./IRF_FixedH.cons_55_65_smoothed(1),'linewidth',2)

xlabel('Time')
title('Consumption (normalised)')
legend('Young','Old','Young (Fixed H)','Old Fixed (H)')
legend boxoff
set(gca,'FontSize',16)
box on
export_fig('Consum_age.jpeg','-M5')




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
export_fig('NW_age.jpeg','-M5')


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
export_fig('NW_ageratio.jpeg','-M5')

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
plot(IRF.homeownership_boom_smoothed,'linewidth',2)
plot(IRF.homeownership_child_smoothed,'linewidth',2)
plot(IRF.homeownership_parent_smoothed,'linewidth',2)
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