% Code for Arellano, Blundell and Bonhomme (2016), "Earnings and Consumption Dynamics: A Nonlinear Panel Data Framework"
% to appear in Econometrica

% This code processes the results of the life-cycle model of consumption
% and saving


clear all
clc;

% Grid of tau's
Ntau=9;
Vectau=(1/(Ntau+1):1/(Ntau+1):Ntau/(Ntau+1))';


% Borrowing limit: Const=0 is zero borrowing limit, Const=1 is natural
% borrowing limit
Const=0;

% Nonlinear earnings process 
if Const==1
    load('nl_nbl.mat')
else
    load('nl_zbl.mat')
end
age_ref=37-24;
Vect=quantile(zsim(:,age_ref),Vectau);

% Average consumption
meanC_nl=zeros(Ntau,1);
meanC_nl(1)=sum(csim(:,age_ref).*(zsim(:,age_ref)<=Vect(1)))/sum((zsim(:,age_ref)<=Vect(1)));
for jtau=2:Ntau-1
     meanC_nl(jtau)=sum(csim(:,age_ref).*(zsim(:,age_ref)<=Vect(jtau+1)).*(zsim(:,age_ref)>Vect(jtau-1)))/sum((zsim(:,age_ref)<=Vect(jtau+1)).*(zsim(:,age_ref)>Vect(jtau-1)));
end
meanC_nl(Ntau)=sum(csim(:,age_ref).*(zsim(:,age_ref)>Vect(Ntau)))/sum((zsim(:,age_ref)>Vect(Ntau)));

% Average consumption by assets
ql_a=quantile(asim(:,age_ref),.20);
qh_a=quantile(asim(:,age_ref),.80);
meanC_a_nl=zeros(Ntau,2);
meanC_a_nl(1,1)=sum(csim(:,age_ref).*(zsim(:,age_ref)<=Vect(1)).*(asim(:,age_ref)<=ql_a))/sum((zsim(:,age_ref)<=Vect(1)).*(asim(:,age_ref)<=ql_a));
for jtau=2:Ntau-1
     meanC_a_nl(jtau,1)=sum(csim(:,age_ref).*(zsim(:,age_ref)<=Vect(jtau+1)).*(asim(:,age_ref)<=ql_a).*(zsim(:,age_ref)>Vect(jtau-1)))/sum((zsim(:,age_ref)<=Vect(jtau+1)).*(zsim(:,age_ref)>Vect(jtau-1)).*(asim(:,age_ref)<=ql_a));
end
meanC_a_nl(Ntau,1)=sum(csim(:,age_ref).*(zsim(:,age_ref)>Vect(Ntau)).*(asim(:,age_ref)<=ql_a))/sum((zsim(:,age_ref)>Vect(Ntau)).*(asim(:,age_ref)<=ql_a));
meanC_a_nl(1,2)=sum(csim(:,age_ref).*(zsim(:,age_ref)<=Vect(1)).*(asim(:,age_ref)>qh_a))/sum((zsim(:,age_ref)<=Vect(1)).*(asim(:,age_ref)>qh_a));
for jtau=2:Ntau-1
     meanC_a_nl(jtau,2)=sum(csim(:,age_ref).*(zsim(:,age_ref)<=Vect(jtau+1)).*(asim(:,age_ref)>qh_a).*(zsim(:,age_ref)>Vect(jtau-1)))/sum((zsim(:,age_ref)<=Vect(jtau+1)).*(zsim(:,age_ref)>Vect(jtau-1)).*(asim(:,age_ref)>qh_a));
end
meanC_a_nl(Ntau,2)=sum(csim(:,age_ref).*(zsim(:,age_ref)>Vect(Ntau)).*(asim(:,age_ref)>qh_a))/sum((zsim(:,age_ref)>Vect(Ntau)).*(asim(:,age_ref)>qh_a));


% Canonical earnings process 
if Const==1
    load('rw_nbl.mat')
else
    load('rw_zbl.mat')
end
Vect=quantile(zsim(:,age_ref),Vectau);

% Average consumption
meanC_rw=zeros(Ntau,1);
meanC_rw(1)=sum(csim(:,age_ref).*(zsim(:,age_ref)<=Vect(1)))/sum((zsim(:,age_ref)<=Vect(1)));
for jtau=2:Ntau-1
     meanC_rw(jtau)=sum(csim(:,age_ref).*(zsim(:,age_ref)<=Vect(jtau+1)).*(zsim(:,age_ref)>Vect(jtau-1)))/sum((zsim(:,age_ref)<=Vect(jtau+1)).*(zsim(:,age_ref)>Vect(jtau-1)));
end
meanC_rw(Ntau)=sum(csim(:,age_ref).*(zsim(:,age_ref)>Vect(Ntau)))/sum((zsim(:,age_ref)>Vect(Ntau)));

% Average consumption by assets
ql_a=quantile(asim(:,age_ref),.20);
qh_a=quantile(asim(:,age_ref),.80);
meanC_a_rw=zeros(Ntau,2);
meanC_a_rw(1,1)=sum(csim(:,age_ref).*(zsim(:,age_ref)<=Vect(1)).*(asim(:,age_ref)<=ql_a))/sum((zsim(:,age_ref)<=Vect(1)).*(asim(:,age_ref)<=ql_a));
for jtau=2:Ntau-1
     meanC_a_rw(jtau,1)=sum(csim(:,age_ref).*(zsim(:,age_ref)<=Vect(jtau+1)).*(asim(:,age_ref)<=ql_a).*(zsim(:,age_ref)>Vect(jtau-1)))/sum((zsim(:,age_ref)<=Vect(jtau+1)).*(zsim(:,age_ref)>Vect(jtau-1)).*(asim(:,age_ref)<=ql_a));
end
meanC_a_rw(Ntau,1)=sum(csim(:,age_ref).*(zsim(:,age_ref)>Vect(Ntau)).*(asim(:,age_ref)<=ql_a))/sum((zsim(:,age_ref)>Vect(Ntau)).*(asim(:,age_ref)<=ql_a));
meanC_a_rw(1,2)=sum(csim(:,age_ref).*(zsim(:,age_ref)<=Vect(1)).*(asim(:,age_ref)>qh_a))/sum((zsim(:,age_ref)<=Vect(1)).*(asim(:,age_ref)>qh_a));
for jtau=2:Ntau-1
     meanC_a_rw(jtau,2)=sum(csim(:,age_ref).*(zsim(:,age_ref)<=Vect(jtau+1)).*(asim(:,age_ref)>qh_a).*(zsim(:,age_ref)>Vect(jtau-1)))/sum((zsim(:,age_ref)<=Vect(jtau+1)).*(zsim(:,age_ref)>Vect(jtau-1)).*(asim(:,age_ref)>qh_a));
end
meanC_a_rw(Ntau,2)=sum(csim(:,age_ref).*(zsim(:,age_ref)>Vect(Ntau)).*(asim(:,age_ref)>qh_a))/sum((zsim(:,age_ref)>Vect(Ntau)).*(asim(:,age_ref)>qh_a));

% Graph average consumption
figure
Dectau=10*Vectau;
plot(Dectau,[meanC_nl],'--','Linewidth',3,'Color','b')
hold on 
plot(Dectau,[meanC_rw],'-','Linewidth',3,'Color','g')
axis([1 9 5000 65000])
xlabel('decile of \eta_{t-1}','FontSize',20)
ylabel('consumption','FontSize',20)
hold off


% Life-cycle evolution: mean, variance, quantiles
if Const==1
    load('nl_nbl.mat')
else
    load('nl_zbl.mat')
end
vect_meany_nl=mean(ypresim);
vect_vary_nl=var(ypresim);
vect_quanty_nl=quantile(ypresim,(.1:.1:.9));
vect_meaneta_nl=mean(zsim);
vect_vareta_nl=var(zsim);
vect_meanc_nl=mean(csim);
vect_varc_nl=var(csim);
vect_quantc_nl=quantile(csim,(.1:.1:.9));
vect_meana_nl=mean(asim);
vect_vara_nl=var(asim);
N=50000;
vect_ginia_nl=(N+1)/N-2*sum(sort(asim).*(N+1-(1:1:N)'*ones(1,71)))./(N*sum(asim));
vect_quanta_nl=quantile(asim,(.1:.1:.9));
Mat_nl=cov(ypresim(:,1:20));
if Const==1
    load('rw_nbl.mat')
else
    load('rw_zbl.mat')
end
vect_meany_rw=mean(ypresim);
vect_vary_rw=var(ypresim);
vect_quanty_rw=quantile(ypresim,(.1:.1:.9));
vect_meaneta_rw=mean(zsim);
vect_vareta_rw=var(zsim);
vect_meanc_rw=mean(csim);
vect_varc_rw=var(csim);
vect_quantc_rw=quantile(csim,(.1:.1:.9));
vect_meana_rw=mean(asim);
vect_vara_rw=var(asim);
vect_ginia_rw=(N+1)/N-2*sum(sort(asim).*(N+1-(1:1:N)'*ones(1,71)))./(N*sum(asim));
vect_quanta_rw=quantile(asim,(.1:.1:.9));
Mat_rw=cov(ypresim(:,1:20));


figure
plot((25:1:94),vect_meanc_nl(1:70),'--','Linewidth',3,'Color','b');
hold on
plot((25:1:94),vect_meanc_rw(1:70),'-','Linewidth',3,'Color','g');
axis([25 94 20000 34000])
xlabel('age','FontSize',20)
ylabel('consumption','FontSize',20)
hold off



figure
plot((25:1:94),vect_varc_nl(1:70),'--','Linewidth',3,'Color','b')
hold on
plot((25:1:94),vect_varc_rw(1:70),'-','Linewidth',3,'Color','g')
axis([25 94 0 400000000])
xlabel('age','FontSize',20)
ylabel('consumption variance','FontSize',20)
hold off



% assets variance
figure
plot((25:1:94),vect_vara_nl(1:70),'--','Linewidth',3,'Color','b')
hold on
plot((25:1:94),vect_vara_rw(1:70),'-','Linewidth',3,'Color','g')
axis([25 94 0 45000000000])
xlabel('age','FontSize',20)
ylabel('assets variance','FontSize',20)
hold off

% Consumption response to earnings

% Grid of tau's
Ntau=11;
Vectau=(1/(Ntau+1):1/(Ntau+1):Ntau/(Ntau+1))';

if Const==0
    load('zbl');
end
if Const==1
    load('nbl');
end

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
set(gca,'ztick',(0:0.2:.8))

