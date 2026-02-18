clear; close all;
pmin=0.01;
pmax=5;
ppoints=10000;

ymin=0.1;
ymax=10;
ypoints=5;

%Discount on bequests
B=1;

%Grid spaces
p=linspace(pmin,pmax,ppoints);
y=linspace(ymin,ymax,ypoints);
OptimalPrice=nan*ones(ypoints,3,3);

pp=repmat(p,ypoints,1);
yy=repmat(y',1,ppoints);


%Young households
u0=3*log(yy/3);
u1=3*log(max((yy-pp),1e-10)/3)+3+pp*B;
u2=3*log(max((yy-2*pp),1e-10)/3)+5+2*pp*B;
u3=3*log(max((yy-3*pp),1e-10)/3)+6+3*pp*B;

UtilityYoung=max(u0,max(u1,max(u2,u3)));

HOptimalYoung=nan*ones(ypoints,ppoints);
HOptimalYoung(UtilityYoung==u0)=0;
HOptimalYoung(UtilityYoung==u1)=1;
HOptimalYoung(UtilityYoung==u2)=2;
HOptimalYoung(UtilityYoung==u3)=3;

f1=figure
title('Young Households')
plot(p,UtilityYoung')
hold on

title('Young HHs')
[umax,ind]=max(UtilityYoung')
scatter(p(ind),umax,'filled','k')

xlabel('Prices')
ylabel('Utility')

OptimalPrice(:,1,1)=p(ind);

%% Next period. You may own 1 house or zero houses. Asssuming you were following the Nash equilbirum what are your current options?

h=[0,1];

ppp=repmat(pp,1,1,2);
%yyy=repmat(yy,1,1,2);
yyy(:,:,1)=yy;
yyy(:,:,2)=yy;


u0=2*log(yy/3);
u0(:,:,2)=nan ;

u1(:,:,1)=2*log(max((yy*2/3-pp),1e-20)/2)+2+pp*B;
u1(:,:,2)=2*log(max((yy-pp),1e-10)/3)+2+pp*B;
u1(ppp>yyy)=nan;

u2(:,:,1)=2*log(max((yy*2/3-2*pp),1e-10)/2)+3+2*pp*B;
u2(:,:,2)=2*log(max((yy-2*pp),1e-10)/3)+4+2*pp*B;
u2(2*ppp>yyy)=nan;

u3(:,:,1)=nan;
u3(:,:,2)=2*log(max((yy-3*pp),1e-10)/3)+5+3*pp*B;
u3(3*ppp>yyy)=nan;

UtilityMiddle=max(u0,max(u1,max(u2,u3)));

HOptimalMiddle=nan*ones(ypoints,ppoints,2);
HOptimalMiddle(UtilityMiddle==u0)=0;
HOptimalMiddle(UtilityMiddle==u1)=1;
HOptimalMiddle(UtilityMiddle==u2)=2;
HOptimalMiddle(UtilityMiddle==u3)=3;

f2=figure
plot(p,UtilityMiddle(:,:,1)')
hold on
title('Middle Aged HH with 0 Homes')
[umax,ind]=max(UtilityMiddle(:,:,1)');
scatter(p(ind),umax,'filled','k')
xlabel('Prices')
ylabel('Utility')
OptimalPrice(:,1,2)=p(ind);

f3=figure
plot(p,UtilityMiddle(:,:,2)')
hold on

title('Middle Aged HH with 1 Home')
[umax,ind]=max(UtilityMiddle(:,:,2)');
scatter(p(ind),umax,'filled','k')

xlabel('Prices')
ylabel('Utility')

OptimalPrice(:,2,2)=p(ind);

%%

h=[0,1,2];

ppp=repmat(pp,1,1,3);
yyy=repmat(yy,1,1,3);

u0=log(yy/3);
u0(:,:,2)=nan*ones(ypoints,ppoints);
u0(:,:,3)=nan*ones(ypoints,ppoints);

u1(:,:,1)=log(max((yy*1/3-pp),1e-20))+1+pp*B;
u1(:,:,2)=log(max((yy-pp),1e-10)/3)+1+pp*B;
u1(:,:,3)=nan*ones(ypoints,ppoints);
u1(ppp>yyy)=nan;

u2(:,:,1)=nan*ones(ypoints,ppoints);
u2(:,:,2)=log(max((yy-pp)*1/3-pp,1e-10))+2+2*pp*B;
u2(:,:,3)=log(max((yy-2*pp),1e-10)/3)+2+2*pp*B;
u2(2*ppp>yyy)=nan;

u3(:,:,1)=nan*ones(ypoints,ppoints);
u3(:,:,2)=nan*ones(ypoints,ppoints);
u3(:,:,3)=log(max((yy-3*pp),1e-10)/3)+3+3*pp*B;
u3(3*ppp>yyy)=nan;


UtilityOld=max(u0,max(u1,max(u2,u3)));

HOptimalOld=nan*ones(ypoints,ppoints,3);
HOptimalOld(UtilityOld==u0)=0;
HOptimalOld(UtilityOld==u1)=1;
HOptimalOld(UtilityOld==u2)=2;
HOptimalOld(UtilityOld==u3)=3;

f4=figure
plot(p,UtilityOld(:,:,1)')
title('Old HH with 0 Homes')
hold on
[umax,ind]=max(UtilityOld(:,:,1)');
scatter(p(ind),umax,'filled','k')
xlabel('Prices')
ylabel('Utility')
OptimalPrice(:,1,3)=p(ind);

f5=figure
plot(p,UtilityOld(:,:,2)')
title('Old HH with 1 Home')
hold on
[umax,ind]=max(UtilityOld(:,:,2)');
scatter(p(ind),umax,'filled','k')

xlabel('Prices')
ylabel('Utility')
OptimalPrice(:,2,3)=p(ind);

f6=figure
plot(p,UtilityOld(:,:,3)')
title('Old HH with 2 Homes')
hold on
[umax,ind]=max(UtilityOld(:,:,3)');
scatter(p(ind),umax,'filled','k')

xlabel('Prices')
ylabel('Utility')
OptimalPrice(:,3,3)=p(ind);

TotalHousingDemand = mean(HOptimalYoung);

f7=figure
plot(p,TotalHousingDemand)
title('Total Housing Demand')


xlabel('Prices')
ylabel('Units of Housing')


%% What does the distribution of hh look like
g=1;

G=zeros(ypoints,3,3);
%assume that young households are uniformly
%distrbuted.
G(1:ypoints,1,1)=g;


p_eq=5;
[~,pind]=min([p_eq-p].^2);
for iy=1:ypoints
    G(iy,1,2)=g*(HOptimalYoung(iy,pind)==0);
    G(iy,2,2)=g*(HOptimalYoung(iy,pind)>0);

    
    G(iy,1,3)=g*(HOptimalYoung(iy,pind)==0);
    G(iy,2,3)=g*(HOptimalYoung(iy,pind)==1);
    G(iy,3,3)=g*(HOptimalYoung(iy,pind)>1);
end

OptimalOutcome=HOptimalYoung(:,pind)
MedianVotedPrice=median(OptimalPrice(G==1))


%% Map demand for housing


