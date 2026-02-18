
clear all
clc;

close all

%%3d plot consumption response conditional on asset and age

load('persis_nl_nbl_eps80_parallel.mat')
load('data_hermite_cons2.mat')

figure
surf(Vectau,Vectau,persis)
xlabel('percentile \tau_{age}','FontSize',14)
ylabel('percentile \tau_{assets}','FontSize',14)
zlabel('consumption response','FontSize',14)
set(gca,'xlim',[0 1])
set(gca,'ylim',[0 1])
set(gca,'zlim',[0 .8])
set(gca,'xtick',(0:0.2:1))
set(gca,'ytick',(0:0.2:1))
set(gca,'ztick',(0:.2:.8))
colormap(jet)
