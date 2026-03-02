%Clear markets
clear all
clc

% options = optimoptions('fmincon','Display','iter-detailed','FinDiffRelStep',1e-3);
% 
% A = [];
% b = [];
% Aeq = [];
% beq = [];
% lb = [0,0];
% ub = [10,0.06];

% x_opt = fmincon(@SolveSS_function,[2.3,0.04],A,b,Aeq,beq,lb,ub,[],options);
% % x_opt
% 
% 
% x_opt_search =  fminsearch(@SolveSS_function,[2,0.03]);
% x_opt_search_boom =  fminsearch(@SolveSS_function_boom,[2,0.03]);

%% Search by grid
tic
ix=0;
% X1=linspace(-0.02,0.02,5)+2.235;
% X2=linspace(-0.001,0.001,5)+0.03;
% 
% X1_boom=linspace(-0.1,+0.1,5)+2.2;
% X2_boom=linspace(-0.01,0.01,5)+0.052;

X1=linspace(-1,1,30)*0.2+2;
X2=0.03;%linspace(-0.001,0.001,5)+0.03;

X1_boom=linspace(-1,1,1)*0.3+1.3;
X2_boom=0.03;%linspace(-0.01,0.01,5)+0.052;


for x1=1:length(X1)
    for x2=1:length(X2)
        ix=1+ix;
        [distance,a_price,rbPos,totalvote,debtstock]=SolveSS_iter([X1(x1),X2(x2)]);
        Results(:,ix)=[distance,a_price,rbPos,totalvote,debtstock];
%         [distance,a_price,rbPos,totalvote,debtstock]=SolveSS_iter_boom([X1_boom(x1),X2_boom(x2)]);
%         Results_boom(:,ix)=[distance,a_price,rbPos,totalvote,debtstock];
    end
end
disp('Done')

% close all;
% subplot(1,2,1)
% surf(X1,X2,reshape(Results(1,:),length(X1),length(X2)))
% subplot(1,2,2)
% surf(X1_boom,X2_boom,reshape(Results_boom(1,:),length(X1),length(X2)))

figure
plot(X1,(Results(4,:)))
hold on
% plot(X1_boom,(Results_boom(1,:)))

toc
%%
%Optimise by Line


