function [distance,a_price,rbPos,totalvote,debtstock,vote_diagnostics] = SolveSS_iter(x,vote_params)

if nargin < 2 || isempty(vote_params)
    vote_params = struct();
end
vote_params = apply_vote_defaults_local(vote_params);

%%Setting Model Parameters
a_price=x(1); % Relative price of housing

%Calculated parameters
rspread = 0.02; % Spread between positive and negative rates
rbPos = x(2); % Positive real interest rate
rbNeg = rbPos+rspread; % Negative interst Rate
ra    = -0.03; %Return on housing
r_price = (1)*(rbNeg-ra+0.02); %Rental price (last term is a fixed mark up)

omega = 0.5;% Weight on houing in utility
theta_r = 0.9;% Discount on rent utility
beta=0.8; %Discount rate
sigma_crra=1.5; %#ok<NASGU>
eta = 2;


ka=0.07; %Fraction of house price in adjustment costs
bequestweight1=0.9*beta; % Relative weight of bequests 
bequestweight2=0.9*beta; % Relative weight of bequests 
 
CC = 0.9; % Borrowing constraint
 
%Set up HH Grid

agemin=25;
agemax=90;
dage=5;% Age increments
ageline=agemin:dage:agemax;
agepension=60;
age_n=(agemax-agemin)/dage+1;

if 0 %Rerun transition matrix calculation
Code_transition_matrix
end

%Productvitiy
if 0
K=5;
zmin=0.01;
zmax=2;
z=linspace(zmin,zmax,K);
dz=z(2)-z(1);
else
    transition_file = which('TransitionMatrix.mat');
    if isempty(transition_file)
        error('SolveSS_iter:MissingTransitionMatrix','TransitionMatrix.mat is not on the MATLAB path.');
    end
    loaded_transition = load(transition_file,'transitionmatrix','initialdist');
    transitionmatrix = loaded_transition.transitionmatrix;
    initialdist = loaded_transition.initialdist;
    if isfield(loaded_transition,'y_mid')
        y_mid = loaded_transition.y_mid;
    end
    if isfield(loaded_transition,'z_lifecycle')
        z_lifecycle = loaded_transition.z_lifecycle;
    end
    if ~exist('y_mid','var') || ~exist('z_lifecycle','var')
        transition_builder = which('Code_transition_matrix.m');
        if isempty(transition_builder)
            error('SolveSS_iter:MissingTransitionInputs', ...
                'Need y_mid and z_lifecycle, but Code_transition_matrix.m is not on the MATLAB path.');
        end
        run(transition_builder);
    end
    z = y_mid;
    zmin=min(z);
    zmax=max(z);
    K=size(z,2);
    Zlifecycle=z_lifecycle./z_lifecycle(1);
end

%Housing
J   = 20;
housingmin   = 0;
housingmax   = 25;
a  = linspace(housingmin,housingmax,J);
da = a(2)-a(1);

%Liquid Debt
I    = 50;
bmin    = -15;
bmax    = 15;
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
%Ztransition=[0.900000000000000,0.0500000000000000,0.0200000000000000,0.0200000000000000,0.0100000000000000;0.100000000000000,0.700000000000000,0.100000000000000,0.0500000000000000,0.0500000000000000;0.0500000000000000,0.100000000000000,0.700000000000000,0.100000000000000,0.0500000000000000;0.0500000000000000,0.0500000000000000,0.100000000000000,0.700000000000000,0.100000000000000;0.0200000000000000,0.0300000000000000,0.100000000000000,0.150000000000000,0.700000000000000];

% Vector for lifecycle age component, this
% calibration is take from Guvenene
iage=0;

% G_next = Z*G; 

%loop recursively back of all age blocks
for age = agemin:dage:agemax-dage
    iage=iage+1;
    
    Ztransition = transitionmatrix(:,:,iage)';
    
    Ztransition_tmp=sparse(I*J*K,I*J*K);
    for ik=-K+1:1:K-1
        tmp=spdiags(Ztransition,ik);%tmp=[tmp;zeros(abs(ik),1)];
        Ztransition_tmp=Ztransition_tmp+spdiags(repelem(tmp,I*J),ik*I*J,I*J*K*L*M,I*J*K*L*M);
    end
    
    Ztransition_final=sparse(I*J*K*L*M,I*J*K*L*M);
    for ilm=1:L*M
        Ztransition_final((ilm-1)*I*J*K+1:ilm*I*J*K,(ilm-1)*I*J*K+1:ilm*I*J*K) = Ztransition_tmp;
    end
    
    eval(['Ztransition_',int2str(age),' = Ztransition_final;']);
    clear Ztransition_tmp Ztransition_final;
end


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

iage=1;

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
                        
                        
                        consumption_plane(:,2:J,iz,ilm) = max( exp(z(iz))*Zlifecycle(age_n-iage+1)  + Rb_line(ii).*b(ii) + a(ij)*a_price - aaaa(:,2:J,iz,ilm)*a_price.*(1+ka.*(1-(aaaa(:,2:J,iz,ilm)==a(ij)))) + b(ii) - bb(:,2:J) /(1) ,1e-20);
                        consumption_plane(:,1,iz,ilm) = max( ( exp(z(iz))*Zlifecycle(age_n-iage+1)   + (Rb_line(ii)).*b(ii) + a(ij)*a_price - aaaa(:,1,iz,ilm)*a_price.*(1+ka.*(1-(aaaa(:,1,iz,ilm)==a(ij)))) + b(ii) - bb(:,1) )/(1+( (1-omega)/omega*theta_r ) ),1e-20);
                        rent_plane(:,1,iz,ilm) = consumption_plane(:,1,iz,ilm)*((1-omega)/(omega)/r_price*theta_r);
                        bequest_plane(:,:,iz,ilm)=max(1e-20,bb + a_price.*aa);
                        
                        value_plane(:,:,iz,ilm) =  (consumption_plane(:,:,iz,ilm).^omega.*(aaaa(:,:,iz,ilm) + theta_r.*rent_plane(:,:,iz,ilm)).^(1-omega) ).^(1-eta)/(1-eta) - Ipen(:,:,iz,ilm)*Penalty + bequestweight1*(1+bequest_plane(:,:,iz,ilm)./bequestweight2).^(1-eta);
                        
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
                        
                        if Ipricepreferences
                            
                            consumption_plane(:,2:J,iz,ilm) = max( exp(z(iz))*Zlifecycle(age_n-iage+1)  + Rb_line(ii).*b(ii) + a(ij)*(a_price*d_a_price) - aaaa(:,2:J,iz,ilm)*a_price*d_a_price.*(1+ka.*(1-(aaaa(:,2:J,iz,ilm)==a(ij)))) + b(ii) - bb(:,2:J) /(1) ,1e-20);
                            consumption_plane(:,1,iz,ilm) = max( ( exp(z(iz))*Zlifecycle(age_n-iage+1)   + (Rb_line(ii)).*b(ii) + a(ij)*(a_price*d_a_price) - aaaa(:,1,iz,ilm)*a_price*d_a_price.*(1+ka.*(1-(aaaa(:,1,iz,ilm)==a(ij)))) + b(ii) - bb(:,1) )/(1+( (1-omega)/omega*theta_r ) ),1e-20);
                            rent_plane(:,1,iz,ilm) = consumption_plane(:,1,iz,ilm)*((1-omega)/(omega)/(r_price*d_a_price)*theta_r);
                            bequest_plane(:,:,iz,ilm)=max(1e-20,bb + a_price*d_a_price.*aa);
                            
                            value_plane_dp(:,:,iz,ilm) = (consumption_plane(:,:,iz,ilm).^omega.*(aaaa(:,:,iz,ilm) + theta_r*rent_plane(:,:,iz,ilm)).^(1-omega) ).^(1-eta)/(1-eta) - Ipen(:,:,iz,ilm)*Penalty + bequestweight1*(1+bequest_plane(:,:,iz,ilm)./bequestweight2).^(1-eta);
                            
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
        
        iage=iage+1;
        consumption_plane=NaN*ones(size(aaaa));
        value_plane=NaN*ones(size(aaaa));
        index_b=NaN*consumption;
        index_a=NaN*consumption;
        
        eval(['Ztransition = Ztransition_',int2str(age),';']);
        
        for ilm=1:L*M
            for iz=1:K
                expectedvaluefunction_plane=Ztransition(:,1+(iz-1)*I*J+(ilm-1)*I*J*K:I*J+(iz-1)*I*J+(ilm-1)*I*J*K)'*valuefunction_agenext(:);
                expectedvaluefunction_plane=reshape(expectedvaluefunction_plane,I,J);
                
                expectedvaluefunction_plane_dp=Ztransition(:,1+(iz-1)*I*J+(ilm-1)*I*J*K:I*J+(iz-1)*I*J+(ilm-1)*I*J*K)'*valuefunction_agenext_dp(:);
                expectedvaluefunction_plane_dp=reshape(expectedvaluefunction_plane_dp,I,J);
                for ij=1:J
                    for ii=1:I
                        
                        
                        consumption_plane(:,2:J,iz,ilm) = max( exp(z(iz))*Zlifecycle(age_n-iage+1)  + Rb_line(ii).*b(ii) + a(ij)*a_price - aaaa(:,2:J,iz,ilm)*a_price.*(1+ka.*(1-(aaaa(:,2:J,iz,ilm)==a(ij)))) + b(ii) - bb(:,2:J) /(1) ,1e-20);
                        consumption_plane(:,1,iz,ilm) = max( ( exp(z(iz))*Zlifecycle(age_n-iage+1)   + (Rb_line(ii)).*b(ii) + a(ij)*a_price - aaaa(:,1,iz,ilm)*a_price.*(1+ka.*(1-(aaaa(:,1,iz,ilm)==a(ij)))) + b(ii) - bb(:,1) )/(1+( (1-omega)/omega*theta_r ) ),1e-20);
                         rent_plane(:,1,iz,ilm) = consumption_plane(:,1,iz,ilm)*((1-omega)/(omega)/(r_price*d_a_price)*theta_r);
                        
                   value_plane(:,:,iz,ilm) =  (consumption_plane(:,:,iz,ilm).^omega.*(aaaa(:,:,iz,ilm) + theta_r*rent_plane(:,:,iz,ilm)).^(1-omega) ).^(1-eta)/(1-eta) - Ipen(:,:,iz,ilm)*Penalty + beta*expectedvaluefunction_plane;
                        
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
                            
                            consumption_plane(:,2:J,iz,ilm) = max( exp(z(iz))*Zlifecycle(age_n-iage+1)   + (Rb_line(ii)).*b(ii) + a(ij)*a_price*d_a_price - aaaa(:,2:J,iz,ilm)*a_price*d_a_price.*(1+ka.*(1-(aaaa(:,2:J,iz,ilm)==a(ij)))) + b(ii) - bbbb(:,2:J,iz,ilm),1e-20);
                            consumption_plane(:,1,iz,ilm) = max( ( exp(z(iz))*Zlifecycle(age_n-iage+1)   + (Rb_line(ii)).*b(ii)  + a(ij)*a_price*d_a_price - aaaa(:,1,iz,ilm)*a_price*d_a_price.*(1+ka.*(1-(aaaa(:,1,iz,ilm)==a(ij)))) + b(ii) - bbbb(:,1,iz,ilm) )/(1+( (1-omega)/omega*theta_r ) ),1e-20);
                            rent_plane(:,1,iz,ilm) = consumption_plane(:,1,iz,ilm)./(r_price*d_a_price)*theta_r*omega;
                            
                            
                            value_plane_dp(:,:,iz,ilm) = (consumption_plane(:,:,iz,ilm).^omega.*(aaaa(:,:,iz,ilm) + theta_r*rent_plane(:,:,iz,ilm)).^(1-omega) ).^(1-eta)/(1-eta) - Ipen(:,:,iz,ilm)*Penalty + beta*expectedvaluefunction_plane_dp;
                            
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
        utility = (consumption).^omega .* (aaaa + theta_r*rent).^(1-omega) - Ipen*Penalty;
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

%[g,v]=eigs(transitionmatrix(:,:,1),1,'lr');
g0=initialdist;%g./sum(g);
[~,bzero]=min(abs(b));

if b(bzero)<0
    bzero=bzero+1;
end

cohortsize=ones(1,age_n);
%cohortsize=[ones(1,3), linspace(1,2,4), linspace(2,1,4), ones(1,3)];
cohortsize=cohortsize/mean(cohortsize);

density_prev=zeros(I,J,K,L*M);
density=zeros(I,J,K,L*M);
totaldensity=zeros(I,J,K,L*M);
vote=zeros(I,J,K,L*M);
totalvote=zeros(I,J,K,L*M);
pref4_hard=NaN(I,J,K,age_n);
pref4_legacy=NaN(I,J,K,age_n);

vote_age=NaN(age_n);
iage=1;

for age=agemin:dage:agemax
    
    iage=iage+1;
    eval(strcat('index_b = index_b_',int2str(age),';'));
    eval(strcat('index_a = index_a_',int2str(age),';'));
    
    
    eval(strcat('d_valuefunction_dp = d_valuefunction_dp_',int2str(age),';'));
    vote_value_gap_fd = d_valuefunction_dp;
    vote_support = compute_vote_support_local(vote_value_gap_fd,vote_params);
    
    density=zeros(I,J,K,L*M);
    if age==agemin
        
        
        
        for iz=1:K
            density_prev(bzero,1,iz)=g0(iz);
        end
        
        vote=vote_support.*density_prev;
        
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
        
        eval(['Ztransition = Ztransition_',int2str(age-dage),';']);
        
        density_prev=Ztransition*density_prev(:);
        density_prev=reshape(density_prev,I,J,K,L*M);
        
        vote=vote_support.*density_prev;
        
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
    
    density=cohortsize(iage-1)*density;
    
    density_prev=density;
    eval(strcat('density_',int2str(age),' = density;'));
    eval(strcat('vote_',int2str(age),' = vote;'));
    totaldensity=totaldensity+density;
    totalvote=totalvote+vote;
    vote_age(age_n)=[sum(vote,'all')];
    
    rent4(:,:,:,iage-1)=rent;
    cons4(:,:,:,iage-1)=consumption;
    aaaa(:,:,:,iage-1)=aaa;
    bbbb(:,:,:,iage-1)=bbb;
    zzzz(:,:,:,iage-1)=exp(zzz).*Zlifecycle(iage-1); 
    dens4(:,:,:,iage-1)=density/age_n;
    pref4(:,:,:,iage-1)=vote_support;
    pref4_hard(:,:,:,iage-1)=sign(vote_value_gap_fd + vote_params.sigma);
    pref4_legacy(:,:,:,iage-1)=sign(vote_value_gap_fd);
    sum(density,'all');
end

totaldensity=totaldensity./sum(totaldensity(:));
totaldensity_2=sum(totaldensity,3); 

Rent      =zeros(I,J,K,L*M);
HouseStock=zeros(I,J,K,L*M);
Rent      =zeros(I,J,K,L*M);
HouseStock=zeros(I,J,K,L*M);


disp(['House Price  = ',num2str(a_price)])
disp(['Vote for higher prices -1 to 1 =',num2str(sum(dens4.*pref4,'all'))])
% disp(['Price/Income Ratio = ',num2str(a_price*sum(dens4(:,:,:,:).*( zzzz),'all'))])
% disp(['Rent Stock = ',num2str(sum(rent4.*dens4,'all'))])
disp(['Rent Share = ',num2str(sum(dens4(:,1,:,:),'all'))])

squeeze(sum(dens4.*pref4,[1,3]));


% % 
% disp(['Vote for higher prices -1 to 1 =',num2str(sum(dens4.*pref4,'all'))])
% disp(['Price/Income Ratio = ',num2str(a_price/sum(dens4(:,:,:,:).*( zzzz),'all'))])
% disp(['Debt Stock = ',num2str(sum(bbbb.*dens4,'all'))])
% disp(['Rent Share = ',num2str(sum(dens4(:,1,:,:),'all'))])

distance = sum(dens4.*pref4,'all')^2;% + sum(bbbb.*dens4,'all')^2 ;

totalvote=sum(dens4.*pref4,'all');
debtstock=sum(bbbb.*dens4,'all');
vote_diagnostics = struct( ...
    'mode',vote_params.mode, ...
    'sigma',vote_params.sigma, ...
    'tau',vote_params.tau, ...
    'totalvote_active',totalvote, ...
    'totalvote_hard_shifted',sum(dens4.*pref4_hard,'all'), ...
    'totalvote_hard_legacy',sum(dens4.*pref4_legacy,'all'));

save SS_iter
end

function vote_params = apply_vote_defaults_local(vote_params)
if ~isfield(vote_params,'mode') || isempty(vote_params.mode)
    vote_params.mode = 'hard_sign';
end
if ~isfield(vote_params,'sigma') || isempty(vote_params.sigma)
    vote_params.sigma = 0;
end
if ~isfield(vote_params,'tau') || isempty(vote_params.tau)
    vote_params.tau = 0.25;
end
end

function vote_support = compute_vote_support_local(vote_value_gap_fd,vote_params)
shifted_gap = vote_value_gap_fd + vote_params.sigma;
switch lower(char(vote_params.mode))
    case "hard_sign"
        vote_support = sign(shifted_gap);
    case {"smooth_logit","smooth_tanh"}
        vote_tau = max(vote_params.tau,1e-8);
        vote_support = tanh(shifted_gap./(2.*vote_tau));
    otherwise
        error('SolveSS_iter:UnknownVoteMode','Unknown vote mode "%s".',vote_params.mode);
end
end
