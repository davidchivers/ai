% This code processes the results of the
% life-cycle simulation of income.

close all;
clear all
clc;
load('nl_zbl.mat')
n=size(ysim,1);

%Transform Y
y_lifecycle=mean(ysim);
y_idiosyn=ysim./y_lifecycle;
y_transformed=log(y_idiosyn);

% Discrete matrices

age_disvec=[25:5:90];
y_vector=[-1e2, linspace(-1.5,1,5) ,1e2];

% Calculate the midpoint of the discretised vector
% - extrolpolate for endpoints.
y_mid(2:size(y_vector,2)-2)=mean([y_vector(3:end-1);y_vector(2:end-2)]);
%Enxtend ednpoints
y_mid(1)=2*y_mid(2)-1*y_mid(3);
y_mid(size(y_vector,2)-1)=2*y_mid(size(y_vector,2)-2)-1*y_mid(size(y_vector,2)-3);

gridsize=size(y_mid,2);

%Find the closest age for the simulations
[~,age_mapping] = min((age_disvec'-[25:94]).^2);
age_bucket = ones(size(ysim,1),1)*age_mapping;



%Average the income outcomes for each age bucket
average_y=zeros(size(ysim,1),size(age_disvec,2));
z_lifecycle = zeros(1,size(age_disvec,2));
for  i=1:size(age_disvec,2)
    average_y(:,i)=mean(y_transformed(:,age_mapping==i),2);
    z_lifecycle(i)=mean(y_lifecycle(:,age_mapping==i),2);
end
%Discretise these average incomes.
y_discrete = discretize(average_y,y_vector);

%Count up up the transitions between discretised
%points.
transitioncount=zeros(gridsize,gridsize,size(age_disvec,2)-1);
for  i=1:size(age_disvec,2)-1
    for j=1:n
        transitioncount(y_discrete(j,i),y_discrete(j,i+1),i)=transitioncount(y_discrete(j,i),y_discrete(j,i+1),i)+1;
    end
end
%Caluclate Probabilities from the transition
%count.
transitionmatrix=transitioncount./sum(transitioncount,2);
transitionmatrix(isnan(transitionmatrix))=0;
hist(y_mid(y_discrete(:)));
figure
hist(y_transformed(:));

save TransitionMatrix
save('/Users/igro0002/Dropbox/Zac and David/code/steadystate/TransitionMatrix')