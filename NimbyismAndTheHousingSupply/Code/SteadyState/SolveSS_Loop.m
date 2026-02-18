clear all;   clc;
tic

iloop=0;
for a_price=0.94
iloop=iloop+1;
    
%%Setting Model Parameters
%a_price=1.75; % Relative price of housing

%Calculated parameters
rspread = 0.03; % Spread between positive and negative rates
rbPos = 0.03; % Positive real interest rate
rbNeg = rbPos+rspread; % Negative interst Rate
ra    = 0; %Return on housing
r_price = (1)*(rbNeg-ra+0.0); %Rental price (last term is a fixed mark up)

s_h = 1;% Weight on houing in utility
theta_r = 0.85;% Discount on rent utility
beta=0.8; %Discount rate

ka=0.09; %Fraction of house price in adjustment costs
bequestweight=1; % Relative weight of bequests

CC = 0.9; % Borrowing constraint

%Set up HH Grid

agemin=20;
agemax=80;
dage=5;% Age increments
ageline=agemin:dage:agemax;
agepension=60;
age_n=(agemax-agemin)/dage+1;

%Productvitiy
K=5;
zmin=-7;
zmax=-1;
z=linspace(zmin,zmax,K);
dz=z(2)-z(1);

%Housing
J   = 20;
housingmin   = 0;
housingmax   = 30;
a  = linspace(housingmin,housingmax,J);
da = a(2)-a(1);

%Liquid Debt
I    = 60;
bmin    = -15;
bmax    = 40;
b = linspace(bmin,bmax,I);
db=b(2)-b(1);


%Aggregate Prod Shock
L=1;
Techmin=1;
Techmax=5;
Tech=linspace(Techmin,Techmax,L);
%dTech=Tech(2)-Tech(1);

%Aggregate Capital Shock
M=1;
Capitalmin=1;
Capitalmax=5;
Capital=linspace(Capitalmin,Capitalmax,M);
%dCapital=Capital(2)-Capital(1);

Tech=repmat(Tech,1,M);
Capital=repelem(Capital,L);

bb = b'*ones(1,J);
aa = ones(I,1)*a;

aah=aa(:,2:end);
bbh=bb(:,2:end);

% Set up the matrixes from the income process, Z

% Ztransition=eye(K,K);
% Ztransition=[0.75,0.25;0.25,0.75];
Ztransition=[0.900000000000000,0.0500000000000000,0.0200000000000000,0.0200000000000000,0.0100000000000000;0.100000000000000,0.700000000000000,0.100000000000000,0.0500000000000000,0.0500000000000000;0.0500000000000000,0.100000000000000,0.700000000000000,0.100000000000000,0.0500000000000000;0.0500000000000000,0.0500000000000000,0.100000000000000,0.700000000000000,0.100000000000000;0.0200000000000000,0.0300000000000000,0.100000000000000,0.150000000000000,0.700000000000000];

% Vector for lifecycle age component, this
% calibration is take from Guvenen
t_ageline=([1:agemax]-24)./10;% Transform the age to Guvenen's defintion of age.
Zlifecyle=exp(2.5 + 0.5*t_ageline - 0.15*t_ageline.^2);
Zlifecyle(agepension+1:end)=0;

Pension=zeros(1,agemax);
Pension(agepension+1:end)=exp(z(round(K/2)));

Income=NaN(K,age_n);
for ik=1:K
    for age=agemin:dage:agemax
        Income(ik,age)=exp(z(ik))*Zlifecyle(age) + Pension(age);
    end
end

Ztransition_3=sparse(I*J*K,I*J*K);
for ik=-K+1:1:K-1
    tmp=spdiags(Ztransition,ik);%tmp=[tmp;zeros(abs(ik),1)];
    Ztransition_3=Ztransition_3+spdiags(repelem(tmp,I*J),ik*I*J,I*J*K*L*M,I*J*K*L*M);
end

Ztransition_4=sparse(I*J*K*L*M,I*J*K*L*M);
for ilm=1:L*M
    Ztransition_4((ilm-1)*I*J*K+1:ilm*I*J*K,(ilm-1)*I*J*K+1:ilm*I*J*K) = Ztransition_3;
end

clear Ztransition_3;


bbb = zeros(I,J,K); aaa = zeros(I,J,K); zzz = zeros(I,J,K);
for k=1:K
    bbb(:,:,k) = bb;
    aaa(:,:,k) = aa;
    zzz(:,:,k) = z(k);
end


for lm=1:L*M
    bbbb(:,:,:,lm) = bbb;
    aaaa(:,:,:,lm) = aaa;
    zzzz(:,:,:,lm) = zzz;
end


% Allow for HH Penalty if debt > assets, or underwater
Ipen = 0*(-bbb<=aaa*a_price*CC)+(1).*(-bbb>aaa*a_price*CC);
Penalty=1*1e6;
Iunderwater = 0*(-bbb<=aaa*a_price)+(1).*(-bbb>aaa*a_price);

Ipricepreferences=1;%Should we calculate preferences over a_price?
d_a_price=1.01; %Multiply a_price by

%allow for differential borrowing and lending rates (only matters when bmin<0)
Rb = rbPos.*(bbbb>=0) + rbNeg.*(bbbb<0) ;%+Ipen*0.1;
Rb_line = rbPos.*(b>=0) + rbNeg.*(b<0) ;%+Ipen*0.1;

N = I*J*K*L*M;

rent = zeros(size(aaaa));

hhhhh = aaaa + rent;
rent_plane=zeros(I,J,K,L*M);
selected=zeros(I,J,K,L*M);

%loop recursively back of all age blocks
for age = agemax:-dage:agemin
    
    if age==agemax
        %At the oldest age you will consume
        %your wealth or bequest it.
        
        consumption=NaN(I,J,K,L*M);
        bequest=NaN(I,J,K,L*M);
        index_b=NaN(I,J,K,L*M);
        index_a=NaN(I,J,K,L*M);
        selected=NaN(I,J,K,L*M);
        
        if Ipricepreferences
            consumption_dp=NaN(I,J,K,L*M);
            bequest_dp=NaN(I,J,K,L*M);
            index_b_dp=NaN(I,J,K,L*M);
            index_a_dp=NaN(I,J,K,L*M);
            selected_dp=NaN(I,J,K,L*M);
        end
        
        %For each grid point, search of the
        %portfolio plane to find the optimal
        %allocation.
        for ilm=1:L*M
            for iz=1:K
                for ij=1:J
                    for ii=1:I
                        
                        
                        consumption_plane(:,2:J,iz,ilm) = max( exp(z(iz))*Zlifecyle(age) + Pension(age) + Rb_line(ii).*b(ii) + a(ij)*a_price - aaaa(:,2:J,iz,ilm)*a_price.*(1+ka*(1-(aaaa(:,2:J,iz,ilm)==a(ij)))) + b(ii) - bb(:,2:J) /(1) ,1e-20);
                        consumption_plane(:,1,iz,ilm) = max( ( exp(z(iz))*Zlifecyle(age) + Pension(age)   + (Rb_line(ii)).*b(ii) + a(ij)*a_price - aaaa(:,1,iz,ilm)*a_price.*(1+ka*(1-(aaaa(:,1,iz,ilm)==a(ij)))) + b(ii) - bb(:,1) )/(1+s_h*theta_r),1e-20);
                        rent_plane(:,1,iz,ilm) = consumption_plane(:,1,iz,ilm)./r_price*theta_r*s_h;
                        bequest_plane(:,:,iz,ilm)=max(1e-20,bb + a_price.*aa);
                        
                        value_plane(:,:,iz,ilm) = log(consumption_plane(:,:,iz,ilm)) +  s_h*log(aaaa(:,:,iz,ilm) + theta_r*rent_plane(:,:,iz,ilm)) - Ipen(:,:,iz,ilm)*Penalty + bequestweight*log(bequest_plane(:,:,iz,ilm));
                        
                        [maxvalue]=max(value_plane(:,:,iz,ilm),[],'all');
                        
                        [ind_b,ind_a]=find((value_plane(:,:,iz,ilm)==maxvalue));
                        
                        if length(ind_b)>1
                            ind_b=ind_b(1);
                            ind_a=ind_a(1);
                        end
                        
                        index_b(ii,ij,iz,ilm)=ind_b;
                        index_a(ii,ij,iz,ilm)=ind_a;
                        
                        consumption(ii,ij,iz,ilm)=consumption_plane(ind_b,ind_a,iz,ilm);
                        
                        bequest(ii,ij,iz,ilm)=bequest_plane(ind_b,ind_a,iz,ilm);
                        rent(ii,ij,iz,ilm)=rent_plane(ind_b,ind_a,iz,ilm);
                        valuefunction(ii,ij,iz,ilm)=maxvalue;
                        
                        if Ipen(ii,ij,iz,ilm)==0
                            selected(index_b(ii,ij,iz,ilm),index_a(ii,ij,iz,ilm),iz,ilm)=1;
                        end
                        
                        % Now let's solve
                        % everything againg for a
                        % slightly high house
                        % price.
                        if Ipricepreferences
                            
                            consumption_plane(:,2:J,iz,ilm) = max( exp(z(iz))*Zlifecyle(age) + Pension(age)  + Rb_line(ii).*b(ii) + a(ij)*(a_price*d_a_price) - aaaa(:,2:J,iz,ilm)*a_price*d_a_price.*(1+ka*(1-(aaaa(:,2:J,iz,ilm)==a(ij)))) + b(ii) - bb(:,2:J) /(1) ,1e-20);
                            consumption_plane(:,1,iz,ilm) = max( ( exp(z(iz))*Zlifecyle(age) + Pension(age)   + (Rb_line(ii)).*b(ii) + a(ij)*(a_price*d_a_price) - aaaa(:,1,iz,ilm)*a_price*d_a_price.*(1+ka*(1-(aaaa(:,1,iz,ilm)==a(ij)))) + b(ii) - bb(:,1) )/(1+s_h*theta_r),1e-20);
                            rent_plane(:,1,iz,ilm) = consumption_plane(:,1,iz,ilm)./(r_price*d_a_price)*theta_r*s_h;
                            bequest_plane(:,:,iz,ilm)=max(1e-20,bb + a_price*d_a_price.*aa);
                            
                            value_plane_dp(:,:,iz,ilm) = log(consumption_plane(:,:,iz,ilm)) +  s_h*log(aaaa(:,:,iz,ilm) + theta_r*rent_plane(:,:,iz,ilm)) - Ipen(:,:,iz,ilm)*Penalty + bequestweight*log(bequest_plane(:,:,iz,ilm));
                            
                            [maxvalue_dp]=max(value_plane_dp(:,:,iz,ilm),[],'all');
                            
                            [ind_b,ind_a]=find((value_plane_dp(:,:,iz,ilm)==maxvalue_dp));
                            
                            if length(ind_b)>1
                                ind_b=ind_b(1);
                                ind_a=ind_a(1);
                            end
                            
                            index_b_dp(ii,ij,iz,ilm)=ind_b;
                            index_a_dp(ii,ij,iz,ilm)=ind_a;
                            
                            consumption_dp(ii,ij,iz,ilm)=consumption_plane(ind_b,ind_a,iz,ilm);
                            bequest_dp(ii,ij,iz,ilm)=bequest_plane(ind_b,ind_a,iz,ilm);
                            rent_dp(ii,ij,iz,ilm)=rent_plane(ind_b,ind_a,iz,ilm);
                            valuefunction_dp(ii,ij,iz,ilm)=maxvalue_dp;
                        end
                        
                    end
                end
            end
        end
        
        adjRegion=(1-(a(index_a)==aaaa));
        valuefunction_agenext=valuefunction;
        valuefunction_agenext_dp=valuefunction_dp;
        
    else %younger ages
        
        consumption_plane=NaN*ones(size(aaaa));
        value_plane=NaN*ones(size(aaaa));
        index_b=NaN*consumption;
        index_a=NaN*consumption;
        
        
        for ilm=1:L*M
            for iz=1:K
                expectedvaluefunction_plane=Ztransition_4(1+(iz-1)*I*J+(ilm-1)*I*J*K:I*J+(iz-1)*I*J+(ilm-1)*I*J*K,:)*valuefunction_agenext(:);
                expectedvaluefunction_plane=reshape(expectedvaluefunction_plane,I,J);
                
                expectedvaluefunction_plane_dp=Ztransition_4(1+(iz-1)*I*J+(ilm-1)*I*J*K:I*J+(iz-1)*I*J+(ilm-1)*I*J*K,:)*valuefunction_agenext_dp(:);
                expectedvaluefunction_plane_dp=reshape(expectedvaluefunction_plane_dp,I,J);
                for ij=1:J
                    for ii=1:I
                        
                        
                        consumption_plane(:,2:J,iz,ilm) = max( exp(z(iz))*Zlifecyle(age) + Pension(age)  + (Rb_line(ii)).*b(ii) + a(ij)*a_price - aaaa(:,2:J,iz,ilm)*a_price.*(1+ka*(1-(aaaa(:,2:J,iz,ilm)==a(ij)))) + b(ii) - bbbb(:,2:J,iz,ilm),1e-20);
                        consumption_plane(:,1,iz,ilm) = max( ( exp(z(iz))*Zlifecyle(age) + Pension(age)   + (Rb_line(ii)).*b(ii)  + a(ij)*a_price - aaaa(:,1,iz,ilm)*a_price.*(1+ka*(1-(aaaa(:,1,iz,ilm)==a(ij)))) + b(ii) - bbbb(:,1,iz,ilm) )/(1+s_h*theta_r),1e-20);
                        rent_plane(:,1,iz,ilm) = consumption_plane(:,1,iz,ilm)./r_price*theta_r*s_h;
                        
                        value_plane(:,:,iz,ilm) = log(consumption_plane(:,:,iz,ilm)) +  s_h*log(aaaa(:,:,iz,ilm) + theta_r*rent_plane(:,:,iz,ilm)) - Ipen(:,:,iz,ilm)*Penalty + beta*expectedvaluefunction_plane;
                        
                        [maxvalue]=max(value_plane(:,:,iz,ilm),[],'all');
                        
                        [ind_b,ind_a]=find((value_plane(:,:,iz,ilm)==maxvalue));
                        
                        if length(ind_b)>1
                            ind_b=ind_b(1);
                            ind_a=ind_a(1);
                        end
                        index_b(ii,ij,iz,ilm)=ind_b;
                        index_a(ii,ij,iz,ilm)=ind_a;
                        consumption(ii,ij,iz,ilm)=consumption_plane(ind_b,ind_a,iz,ilm);
                        rent(ii,ij,iz,ilm)=rent_plane(ind_b,ind_a,iz,ilm);
                        valuefunction(ii,ij,iz,ilm)=maxvalue;
                        
                        if Ipen(ii,ij,iz,ilm)==0
                            selected(index_b(ii,ij,iz,ilm),index_a(ii,ij,iz,ilm),iz,ilm)=1;
                        end
                        
                        
                        if Ipricepreferences
                            
                            consumption_plane(:,2:J,iz,ilm) = max( exp(z(iz))*Zlifecyle(age) + Pension(age)  + (Rb_line(ii)).*b(ii) + a(ij)*a_price*d_a_price - aaaa(:,2:J,iz,ilm)*a_price*d_a_price.*(1+ka*(1-(aaaa(:,2:J,iz,ilm)==a(ij)))) + b(ii) - bbbb(:,2:J,iz,ilm),1e-20);
                            consumption_plane(:,1,iz,ilm) = max( ( exp(z(iz))*Zlifecyle(age) + Pension(age)   + (Rb_line(ii)).*b(ii)  + a(ij)*a_price*d_a_price - aaaa(:,1,iz,ilm)*a_price*d_a_price.*(1+ka*(1-(aaaa(:,1,iz,ilm)==a(ij)))) + b(ii) - bbbb(:,1,iz,ilm) )/(1+s_h*theta_r),1e-20);
                            rent_plane(:,1,iz,ilm) = consumption_plane(:,1,iz,ilm)./(r_price*d_a_price)*theta_r*s_h;
                            
                            
                            value_plane_dp(:,:,iz,ilm) = log(consumption_plane(:,:,iz,ilm)) +  s_h*log(aaaa(:,:,iz,ilm) + theta_r*rent_plane(:,:,iz,ilm)) - Ipen(:,:,iz,ilm)*Penalty + beta*expectedvaluefunction_plane_dp;
                            
                            [maxvalue_dp]=max(value_plane_dp(:,:,iz,ilm),[],'all');
                            
                            [ind_b,ind_a]=find((value_plane_dp(:,:,iz,ilm)==maxvalue_dp));
                            
                            if length(ind_b)>1
                                ind_b=ind_b(1);
                                ind_a=ind_a(1);
                            end
                            
                            index_b_dp(ii,ij,iz,ilm)=ind_b;
                            index_a_dp(ii,ij,iz,ilm)=ind_a;
                            
                            consumption_dp(ii,ij,iz,ilm)=consumption_plane(ind_b,ind_a,iz,ilm);
                            bequest_dp(ii,ij,iz,ilm)=bequest_plane(ind_b,ind_a,iz,ilm);
                            rent_dp(ii,ij,iz,ilm)=rent_plane(ind_b,ind_a,iz,ilm);
                            valuefunction_dp(ii,ij,iz,ilm)=maxvalue_dp;
                        end
                        
                        
                    end
                end
            end
        end
        
        adjRegion=(1-(a(index_a)==aaaa));
        utility = log(consumption) +  s_h*log(aaaa + theta_r*rent) - Ipen*Penalty;
        valuefunction_agenext = valuefunction;
        valuefunction_agenext_dp = valuefunction_dp;
        consumption_nextage=consumption;
        d_valuefunction_dp = (valuefunction_dp - valuefunction);
        
    end
    
    
    
    eval(strcat('rent_',int2str(age),' = rent;'));
    eval(strcat('consumption_',int2str(age),' = consumption;'));
    eval(strcat('consumption_dp_',int2str(age),' = consumption_dp;'));
    eval(strcat('valuefunction_',int2str(age),' = valuefunction;'));
    eval(strcat('valuefunction_dp_',int2str(age),' = valuefunction_dp;'));
    eval(strcat('d_valuefunction_dp_',int2str(age),' = (valuefunction_dp - valuefunction);'));
    eval(strcat('selected_',int2str(age),' = selected;'));
    eval(strcat('index_a_',int2str(age),' = index_a;'));
    eval(strcat('index_b_',int2str(age),' = index_b;'));
    
    if 1
        eval(strcat('adjRegion_',int2str(age),' = adjRegion;'));
    else
        eval(strcat('adjRegion_',int2str(age),' = 0*consumption;'));
    end
    %  eval(strcat('save output_age',int2str(age)))
    
    
    
end

%% Now let's calculate the distribution

[g,v]=eigs(Ztransition,1,'lr');
g0=g./sum(g);

[~,bzero]=min(abs(b));
density_prev=zeros(I,J,K,L*M);
density=zeros(I,J,K,L*M);
totaldensity=zeros(I,J,K,L*M);
vote=zeros(I,J,K,L*M);
totalvote=zeros(I,J,K,L*M);

vote_age=NaN(1,age_n);
iage=0;

for age=agemin:dage:agemax
    iage=1+iage;
    eval(strcat('index_b = index_b_',int2str(age),';'));
    eval(strcat('index_a = index_a_',int2str(age),';'));
    
    eval(strcat('d_valuefunction_dp = d_valuefunction_dp_',int2str(age),';'));
    
    density=zeros(I,J,K,L*M);
    if age==agemin
                
        for iz=1:K
            density_prev(bzero,1,iz)=g0(K);
        end
                      
        for ilm=1:L*M
            for iz=1:K
                for ii=1:I
                    for ij=1:J
                        density(index_b(ii,ij,iz,ilm),index_a(ii,ij,iz,ilm),iz,ilm)=density(index_b(ii,ij,iz,ilm),index_a(ii,ij,iz,ilm),iz,ilm)+density_prev(ii,ij,iz,ilm);
                    end
                end
            end
        end
        
        
    else
        
        density_prev=Ztransition_4*density_prev(:);
        density_prev=reshape(density_prev,I,J,K,L*M);
        
        vote=sign(d_valuefunction_dp).*density_prev;
        
        for ilm=1:L*M
            for iz=1:K
                for ii=1:I
                    for ij=1:J
                        density(index_b(ii,ij,iz,ilm),index_a(ii,ij,iz,ilm),iz,ilm)=density(index_b(ii,ij,iz,ilm),index_a(ii,ij,iz,ilm),iz,ilm)+density_prev(ii,ij,iz,ilm);
                    end
                end
            end
        end
        
        
    end
    density_prev=density;
    eval(strcat('density_',int2str(age),' = density;'));
    eval(strcat('vote_',int2str(age),' = vote;'));
    totaldensity=totaldensity+density;
    totalvote=totalvote+vote;
    vote_age(1,iage)=[sum(vote,'all')];
end

totalvote=totalvote/age_n;

totaldensity=totaldensity./sum(totaldensity(:));

totaldensity_2=sum(totaldensity,3);

disp(['Vote for higher prices ',num2str(sum(totalvote,'all'))])
%disp(['Age Breakdown Vote is ',num2str(vote_age),''])
disp(['House Stock = ',num2str(sum(totaldensity(:,2:J,:,:).*aaaa(:,2:J,:,:)*da,'all'))])
disp(['Rent Stock = ',num2str(sum(density_20.*rent_20 + density_40.*rent_40 + density_60.*rent_60 + density_80.*rent_80,'all'))])
disp(['Rent Share = ',num2str(sum(totaldensity(:,1,:),'all'))])

RESULTS(iloop,:)=[a_price, ...                  
                  sum(totalvote,'all'), ...
                  sum(totaldensity(:,2:J,:,:).*aaaa(:,2:J,:,:)*da,'all'), ...
                  sum(density_20.*rent_20 + density_40.*rent_40 + density_60.*rent_60 + density_80.*rent_80,'all'), ...
                  sum(totaldensity(:,1,:),'all') ];


end