% Solves the household problem in the model with a liquid and an illiquid
% asset with Poisson shocks using the finite difference upwind method with
% implicit updating.
% written by Julia Fernandes Araujo da Fonseca and Ben Moll
%--------------------------------------------------------------------------

clear all; clc; close all;
tic

loadfile = 'initialise.mat';
savefile = 'results_ss.mat';

%%Setting Model Parameters
a_price=1.1;

HOwn=64;
s = 2;
s_h = 2;
theta_r = 0.75;
h_bar = 0.0001;
frisch=0.8;

rspread = 0.00;
ra    = 0;
ka=0.05;
rho   = 0.0572;
lamda =  5*1/180;

theta_h=5;
CC = 0.9;
rbPos = 0.00;

HouseStock = 1;

a_annuity = HouseStock*a_price*lamda;

%Setting the Search Parameters
rupdate = 0.001;

%Calculated parameters
rbNeg = rbPos+rspread;
r_price = (a_price)*(rbNeg-ra+0.10);

%Set up HH Grid
J   = 6;
amin   = 0;
amax   = 10;
a  = linspace(amin,amax,J);
da = a(2)-a(1);


I    = 11;
bmin    = -5;
bmax    = 10;
b = linspace(bmin,bmax,I);
db=b(2)-b(1);

bb = b'*ones(1,J);
aa = ones(I,1)*a;

aah=aa(:,2:end);
bbh=bb(:,2:end);

%Run this to set up the matrixes from the income process, Z
IncomeProcess_KMZ

bbb = zeros(I,J,K); aaa = zeros(I,J,K); zzz = zeros(I,J,K);
for k=1:K
    bbb(:,:,k) = bb;
    aaa(:,:,k) = aa;
    zzz(:,:,k) = z(k);
end

%allow for HH Penalty if debt > assets, or underwater
Ipen = 0*(-bbb<=aaa*a_price*CC)+(1).*(-bbb>aaa*a_price*CC);
Iunderwater = 0*(-bbb<=aaa*a_price)+(1).*(-bbb>aaa*a_price);

%allow for differential borrowing and lending rates (only matters when bmin<0)
Rb = rbPos.*(bbb>=0) + rbNeg.*(bbb<0) ;%+Ipen*0.1;

M = I*J*K;


phia      = -0.08;
phib      = 0.01;
for k=1:K
    V1(:,:,k) = (1-s)^(-1)*(mean(z) + phia*ra.*aa + phib.*bb).^(1-s)/rho;
end
v=V1;
rent=zeros(I,J,K);rentOp=rent;
rent(:,1,:)=aaa(:,2,:)/50;

% Code to initialise the Value function
if 1
    load(loadfile,'v','V','rent','c')
    if sum(size(v)==size(V1))<3
        
        tmp=load(loadfile,'bbb','aaa','b','z','zzz','a');
        
        [zprime,zorder]=sort(tmp.z);
        v0=V(:,:,zorder)+1;
        rent0=rent(:,:,zorder);
        
        for k=1:size(tmp.z,2)
            tmp.zzz(:,:,k) = zprime(k);
        end
        
        GV = griddedInterpolant(tmp.bbb(:,:,1),tmp.aaa(:,:,1),v0(:,:,1));
        GR = griddedInterpolant(tmp.bbb(:,:,1),tmp.aaa(:,:,1),rent0(:,:,1));
        v=GV(bbb,aaa);
        rent = zeros(I,J,K);
        rent=GR(bbb,aaa);
        
    end
    clear tmp
end

h = aaa + rent;

% Iteration set-up:
Delta     = 0.25;
maxit   = 10000;
tol       = 1e-3 ;
iter      = 0;
dist      = 1;

% Adjustment decision set-up:
Nx      = 120;
NaP     = 120;
Nk      = 120;
xmin      = min(min((aa*a_price + bb))) + ka;
xmax      = amax*a_price + bmax;
x     = linspace(xmin,xmax,Nx);

sumGrid   = aa*a_price + bb;
sumGrid   = sumGrid(:);

for nr = 1:maxit
    for n=1:maxit
        
        
        V = v;
        
        % forward difference
        Vbf(1:I-1,:,:) = (V(2:I,:,:)-V(1:I-1,:,:))./(bbb(2:I,:,:)-bbb(1:I-1,:,:));
        % backward difference
        Vbb(2:I,:,:) = (V(2:I,:,:)-V(1:I-1,:,:))./(bbb(2:I,:,:)-bbb(1:I-1,:,:));
        
        Vbf(I,:,:) = (zzz(I,:,:) + Rb(I,:,:).*bmax-r_price.*rent(I,:,:)).^(-s);
        Vbb(1,:,:) = (zzz(1,:,:) + Rb(1,:,:).*bmin-r_price.*rent(1,:,:)).^(-s);
        
        I_concave = (Vbb > Vbf); %indicator whether value function is concave (problems arise if this is not the case)
        
        Vbf = min(max(Vbf,10^(-5)),10^5);
        Vbb = min(max(Vbb,10^(-5)),10^5);
        
        rentf = (Vbf/theta_h/theta_r).^(-1/s);
        rentb = (Vbb/theta_h/theta_r).^(-1/s);
        
        hf=theta_r*rentf+aaa+h_bar;
        hb=theta_r*rentb+aaa+h_bar;
        
        cf = Vbf.^(-1/s);
        cb = Vbb.^(-1/s);
        
        cb0=cb;
        
        
        %consumption and savings with forward difference
        sf = zzz + Rb.*bbb - cf - r_price.*rent;
        
        %consumption and savings with backward difference
        sb = zzz + Rb.*bbb - cb - r_price.*rent;
        
        if min(min(sb(1,:,:)))<-1e-3;
            Iedge = zeros(I,J,K);
            Iedge = (sb(1,:,:)<0);
        end
        
        %consumption and derivative of value function at steady state
        c0 = zzz + Rb.*bbb - r_price.*(rent);
        %    Vb0 = (1-s_h)*(c0).^(-s*(1-s_h)-s_h) + h0.^(s_h+s_h);
        
        Vb0 = (c0).^(-s);
        % dV_upwind makes a choice of forward or backward differences based on
        % the sign of the drift
        If = sf > 0; %positive drift --> forward difference
        Ib = sb < 0; %negative drift --> backward difference
        I0 = (1-If-Ib); %at steady state
        
        Vb_Upwind = Vbf.*If + Vbb.*Ib + Vb0.*I0; %important to include third term
        
        h=theta_r*rent+aaa+h_bar;
        
        c = Vb_Upwind.^(-1/s);
        
        u = c.^(1-s)/(1-s)+theta_h*(h).^(1-s_h)/(1-s_h)-20.*(Ipen);%
        
        if ~isreal(u)
            disp('Error Imaginary Utility')
        end
        
        %CONSTRUCT MATRIX A
        X = - min(sb,0)./db;
        Y = - max(sf,0)./db + min(sb,0)./db;
        Z = max(sf,0)./db;
        
        X(1,:,:) = zeros(1,J,K);
        Z(I,:,:) = zeros(1,J,K);
        
        updiag = zeros(I*J,K);%sparse(I*J,K);
        lowdiag = zeros(I*J,K);%sparse(I*J,K);
        centdiag = zeros(I*J,K);
        
        centdiag = reshape(Y(:,:,:),K*I*J,1);
        lowdiag = reshape(X(:,:,:),K*I*J,1);
        updiag = reshape(Z(:,:,:),K*I*J,1);
        
        AA = spdiags(centdiag,0,K*I*J,K*I*J)+spdiags([0;updiag],1,I*J*K,I*J*K)+spdiags(lowdiag(2:end),-1,I*J*K,I*J*K);
        
        A = AA + Bswitch;
        B = (1/Delta + rho)*speye(I*J*K) - A;
        
        u_stacked = [reshape(u(:,:,:),I*J*K,1)];
        V_stacked = [reshape(V(:,:,:),I*J*K,1)];
        
        vec = u_stacked + V_stacked/Delta;
        %IMPLICIT UPDATING
        V_stacked_12 = B\vec; %SOLVE SYSTEM OF EQUATIONS
        %EXPLICIT UPDATING
        %V_stacked_12 = V_stacked + Delta*(u_stacked + A*V_stacked - rho*V_stacked);
        
        Vprev=V;
        V(:,:,:) = reshape(V_stacked_12(1:I*J*K),I,J,K);    %V(:,:,2) = reshape(V_stacked_12(I*J+1:I*J*Nz),I,J,K);
        
        %%%%% Adjustment decision for x grid:
        bAdjAux  = zeros(Nx,K);
        aAdjAux  = zeros(Nx,K);
        vAdj = zeros(Nx,K);
        aPmin = amin;
        VstarAux=zeros(Nx,K);
        Vstar=V_stacked_12;
        
        zP = linspace(zmin,zmax,Nk);
        for iz=1:K
            Vz=V(:,2:end,iz);
            GZ = scatteredInterpolant(bbh(:),aah(:),Vz(:),'linear','none');
            
            Vz=V(:,1,iz);
            GR = griddedInterpolant(bb(:,1),Vz(:),'linear','none');
            for i = 1:Nx
                aPmax = min((x(i) - ka - bmin)/a_price,amax); %CONSTRAINT a'<=aMax
                aP = linspace(aPmin,aPmax,NaP);
                aP = max(aP,(x(i)-ka-bmax)/a_price); %CONSTRAINT b'<=bMax
                
                bP = (x(i) - ka - aP*a_price);
                
                bind = (max((-bP/CC/a_price),0)>aP); %Constraint a' >= -b/C/Price
                
                aP = (1-bind).*aP + (bind).*max(aP.*(1-bind));
                bP = (x(i) - ka - aP*a_price);
                
                vAdjH = GZ(bP',aP');
                vAdjR = GR(bP');
                
                vAdj = (vAdjH).*(aP'>0) + (vAdjR).*(aP'==0);
                
                cP = (bP<-aP/CC/a_price);
                [VstarAux(i,iz),idx(i)] = max(vAdj);
                aAdjAux(i,iz) = aP(idx(i));
                bAdjAux(i,iz) = bP(idx(i));
            end
            Gaux = griddedInterpolant(x',VstarAux(:,iz));
            %%%%% Interpolate for all possible values of a+b:
            Vstar((iz-1)*I*J+1:iz*I*J,1) = Gaux(sumGrid);%lininterp1(x',VstarAux(2,:)',sumGrid)];
        end
        
        
        V_stacked = max(V_stacked_12,Vstar);
        V = reshape(V_stacked,I,J,K);
        adj = V_stacked==Vstar;
        
        Vchange = V - v;
        v = V;
        
        ss = zzz + Rb.*bbb - c - rent*r_price;
        
        v=V;
        
        diff_Valuefunction(n) = max(max(max(abs(Vchange))));
        disp(strcat('Value Function Converged, Iteration = ',int2str(n),' Distance = ',num2str(diff_Valuefunction(n))));
        
        if diff_Valuefunction(n)<tol && n>2
            break
        end
    end
    prev_rent=rent;
    optimal_rent(:,1,:) = (Vb_Upwind(:,1,:)/theta_r/theta_h).^(-1/s);
    
    if nr==2
        rent(:,1,:) = optimal_rent(:,1,:);
    elseif nr<10
        rent(:,1,:) = (1-rupdate^0.1)*rent(:,1,:) + (rupdate^0.1)*optimal_rent;
    else
        rent(:,1,:) = (1-rupdate)*rent(:,1,:) + (rupdate)*optimal_rent;
    end
    
    
    rent_change = rent - prev_rent;
    diff_rent(nr) = max(max(max(abs(rent_change))));
    disp(strcat('Rent Converged, Iteration = ',int2str(nr),' Distance = ',num2str(diff_rent(nr))));
    
    if diff_rent(nr)<tol
        break
    end
end

adj = V_stacked==Vstar; %INDICATOR FOR ADJUSTING
adjRegion = reshape(adj(1:I*J*K),I,J,K).*1;


clearvars AA B Bswitch

ss = zzz + Rb.*bbb - c - rent*r_price;


b_stacked = bbb(:);
a_stacked = aaa(:);
z_stacked = zzz(:);

db_stacked = db*ones(I*J*K,1);
da_stacked = da*ones(I*J*K,1);

for iz=1:K
    aAux = griddedInterpolant(x',aAdjAux(:,iz));
    bAux = griddedInterpolant(x',bAdjAux(:,iz));
    
    %AJUSTMENT TARGETS
    bAdj(:,iz) = bAux(sumGrid);%lininterp1(x',bAdjAux(1,:)',sumGrid);
    aAdj(:,iz) = aAux(sumGrid);%lininterp1(x',aAdjAux(1,:)',sumGrid);
end

% Approximate bAdj,aAdj by points in the grid:
bAdj_stacked = bAdj(:);
aAdj_stacked = aAdj(:);
b_diff = abs(repmat(bAdj_stacked,1,I) - repmat(b,K*I*J,1));
a_diff = abs(repmat(aAdj_stacked,1,J) - repmat(a,K*I*J,1));
[~,bAdjIdx] = min(b_diff,[],2);
[~,aAdjIdx] = min(a_diff,[],2);

bAdjIdx_ =  reshape(bAdjIdx,I,J,K);
aAdjIdx_ = reshape(aAdjIdx,I,J,K);

% Map bAdjIdx,aAdjIdx into stacked state space:
adj_target = zeros(I*J*K,1);
for k=1:K
    zIdx = I*J*(k-1)+1:I*J*k;
    adj_target(zIdx) = (aAdjIdx(zIdx)-1)*I + bAdjIdx(zIdx) + I*J*(k-1);
end



lp=sum(adj(adj_target(adj)));

adjIdx = find(adj);
lpn=0;
while lp>0 && lpn < 100
    for ai=1:size(adjIdx,1)
        i=adjIdx(ai);
        t=adj_target(i);
        if adj(t)==1
            adj_target(i)=adj_target(t);
        end
    end
    lp=sum(adj(adj_target(adj)));
    lpn=lpn+1;
end

adj(adj_target == cumsum(ones(size(adj)))) = 0;

for ai=1:size(find(adj))
    i=adjIdx(ai);
    t=adj_target(i);
    if a_stacked(i)==a_stacked(t)
        adj(i)=0;
    end
end


adjRegion = reshape(adj(1:I*J*K),I,J,K).*1;
adjRegion_check = 1-adj;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% COMPUTE STATIONARY DISTRIBUTION %
%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%
% Correct matrix for adjustment:
%   C = A;
O=A;OA=zeros(size(O));
adjIdx = find(adj);
adjNum = size(adjIdx);


O = O - speye(M)*lamda;

[b_born,tmp]=min(abs(b));
R=(I*J)*(floor(K/2)-1)+I*(1-1)+tmp;

if adj(R)
    R=adj_target(R);
end
if b_stacked(R)<0
    R=R+1;
end
%   CR =sparse(1:M,R,lamda*Delta*ones(1,M),M,M);
OR =sparse(1:M,R,lamda*ones(1,M),M,M);

O = O + OR;

Adjust=sparse(zeros(M));Sell=sparse(zeros(M));Buy=sparse(zeros(M));AdjustZ=sparse(zeros(M));
AdjustA=sparse(zeros(M));SellA=sparse(zeros(M));BuyA=sparse(zeros(M));
O2=O;
for ai=1:adjNum
    i=adjIdx(ai);
    t=adj_target(i);
    
    Adjust(:,t)=max(O2(:,i),0)+Adjust(:,t);
    AdjustZ(:,t)=max(O2(:,i),0)*abs(z_stacked(i)-z_stacked(t))+AdjustZ(:,t);
    AdjustA(:,t)=max(O2(:,i),0)*abs(a_stacked(i)-a_stacked(t))+AdjustA(:,t);
    if a_stacked(i)>a_stacked(t)
        Sell(:,t)=max(O2(:,i),0)+Sell(:,t);
        SellA(:,t)=max(O2(:,i),0)*abs(a_stacked(i)-a_stacked(t))+SellA(:,t);
    elseif a_stacked(i)<a_stacked(t)
        Buy(:,t)=max(O2(:,i),0)+Buy(:,t);
        BuyA(:,t)=max(O2(:,i),0)*abs(a_stacked(t)-a_stacked(i))+BuyA(:,t);
    else
        adj(i)=0;
        
    end
    
    if adj(i)==1
        OA(:,t) = O(:,i);
        O(:,t) = O(:,t)+O(:,i);
        O(:,i) = zeros(M,1);
    end
end
O3=O;
Buy=Buy';BuyA=BuyA';
Sell=Sell';SellA=SellA';
Adjust=Adjust';
AdjustZ=AdjustZ';
AdjustA=AdjustA';

for i = 1:adjNum
    % C(adjIdx(i),adjIdx(i)) = -1/Delta;
    O(adjIdx(i),adjIdx(i)) = -0.00001;
end

%    CT = C_';
OT = O';

Ipen_stacked=Ipen(:);

Fixes = intersect(find(adjRegion_check),find(~Ipen_stacked));
check = 0;
checki=0;
while ~check
    checki=checki+1;
    OT=O';
    % Fix one value so matrix isn't singular:
    vec = zeros(M,1);
    iFix = Fixes(checki); %iFix NEEDS TO BE IN NON-ADJUSTMENT REGION THIS MATTERS!
    vec(iFix)=.1;
    OT(iFix,:) = [zeros(1,iFix-1),1,zeros(1,K*I*J-iFix)];
    
    % Solve system:
    g_stacked = OT\vec;
    g_sum  = sum(g_stacked.*da_stacked.*db_stacked);
    g_stacked  = g_stacked ./g_sum ;
    
    
    [g_stacked2,val] = eigs(OT,1,'lr');
    g_sum2  = sum(g_stacked2*da*db);
    g_stacked2  = g_stacked2 ./g_sum2 ;
    
    
    if min(g_stacked2) < -1e-02
        check =0;
    else
        check=1;
    end
    
    % g = reshape(g_stacked(1:I*J*K),I,J,K);
    
    %         if ~isnan(g_stacked'*ones(I*J*K,1).*da_stacked.*db_stacked)
    %             check = g_stacked'*ones(I*J*K,1).*da_stacked.*db_stacked;
    %         end
    %         g_calc(:,checki) = O'*g_stacked;
end
%     tic
OT=O';


g_stacked = g_stacked2;

g = reshape(g_stacked(1:I*J*K),I,J,K);
gweight_stacked=g_stacked.*da_stacked.*db_stacked;


gAdjustA=ones(size(b_stacked))'*(AdjustA*gweight_stacked)*Delta;
gAdjust=ones(size(b_stacked))'*Adjust*gweight_stacked*Delta;
gAdjustZ=ones(size(b_stacked))'*AdjustZ*gweight_stacked*Delta;


gBuy=ones(size(b_stacked))'*(Buy*Delta)*gweight_stacked;
gSell=ones(size(b_stacked))'*Sell*gweight_stacked*Delta;

gBuyA=ones(size(b_stacked))'*BuyA*gweight_stacked*Delta;
gSellA=ones(size(b_stacked))'*SellA*gweight_stacked*Delta;


rent_stacked = reshape(rent,1,I*J*K);
c_stacked =c(:);
Cons = c_stacked'*(g_stacked.*da_stacked.*db_stacked);
% LInc = z_stacked'*(g_stacked.*da_stacked.*db_stacked)*;
% EffLab = z_stacked'*(g_stacked.*da_stacked.*db_stacked)*labour_ss;
Rent = rent_stacked*(g_stacked.*da_stacked.*db_stacked);
HouseStock = a_stacked'*(g_stacked.*da_stacked.*db_stacked);
DebtStock = b_stacked'*(g_stacked.*da_stacked.*db_stacked);

Tech=1;

gb = sum(sum(g(:,:,:),2),3);
ga = sum(sum(g(:,:,:),1),3);
gz = squeeze(sum(sum(g(:,:,:),1),2)*(zmax-zmin)/K);

Gb = cumsum(gb); gb=gb/Gb(end);Gb = cumsum(gb);
Ga = cumsum(ga');ga=ga/Ga(end);Ga = cumsum(ga);
Gz = cumsum(gz); gz=gz/Gz(end);Gz = cumsum(gz);

xxx = aaa*a_price + bbb;
x_stacked=xxx(:);
xaxis = linspace(min(x_stacked),max(x_stacked),1000);
Gx(1) = 0;
for x1 = 1:1000
    Gx(x1) = sum((x_stacked<xaxis(x1)).*da_stacked.*db_stacked);
end
HTotalStock=HouseStock+Rent;

HInvest = (-ra*HTotalStock);

KA = (gBuy+gSell)*ka;
KI = 0;
LD=Cons+(gBuy+gSell)*ka;


thresh = 50/15000;
ind(:,1) = (a_stacked<thresh);
ind(:,2) = (a_stacked>thresh).*(b_stacked<-thresh);
ind(:,3) = (a_stacked>thresh).*(b_stacked>-thresh);


frac = sum((g_stacked.*da_stacked.*db_stacked)*ones(1,3).*ind,1)*100;
HOwn=frac(2)+frac(3);

Pop_z=squeeze(sum(sum(g*da*db,1),2))*100;
HOwn_z=squeeze(sum(sum(g(:,2:end,:)*da*db,1),2))*100;
C_z=squeeze(sum(sum((g*da*db).*c,1),2))*100;

Hrate=HOwn_z./Pop_z;
[z_sort,zind]=sort(z);
Pop_zsort=Pop_z(zind);

Popcumsum=cumsum(Pop_zsort);

Ibind=zeros(I,J,K);
Ibind(2:end,:,:) = ((1-Ipen(2:end,:,:)).*(Ipen(1:end-1,:,:))==1);

Decile=zeros(K,10);tmp=Pop_zsort;
for d=1:9
    for k=1:K
        if sum(tmp(1:k))>=10
            for kk=1:k-1
                Decile(kk,d)=tmp(kk);
                tmp(kk)=0;
            end
            Decile(k,d)=10-sum(Decile(1:k-1,d));
            tmp(k)=tmp(k)-sum(Decile(k,d));
            break
        end
    end
end
Decile(:,10)=tmp;

AggDebt = DebtStock - Rent*a_price;

if HOwn<0 || ~isreal(HOwn) || HOwn>100
    %  break
end

%eval(horzcat('save ',savefile,' v V g_stacked R HouseStock Rent gBuy gSell gBuyA gSellA gAdjust gAdjustA gAdjustZ NaP M aPmin aPmax xmin xmax Nx AAA amax bmax a_price a_stacked a aa aaa adj adj_target adjRegion AggDebt zeta_i gam_1 amin b bmin b_stacked bb bbb z  zzz r_price wage_ss HouseStock Rent Bswitch_a Bswitch_Z I J K rbPos rspread phi_l frisch ra CC db_stacked da_stacked  s s_h lamda Beta1 Beta2 Cons DebtStock Decile Delta EL frac g h_bar HInvest HOwn Hrate HOwn_z ka ka_share labour_ss LabGoods LabHouse c rent rho ss theta_r theta_z1 theta_z2 tol Var1 Var2 x_ap x_el x_rb x_sh z_sort z_stacked zmin zmean zmax Nk'));
toc

%%%%%%%%%%%%%%%%%%%%
%% STATISTICS:
%%%%%%%%%%%%%%%%%%%%

thresh = 50/15000;
ind(:,1) = (a_stacked<thresh);
ind(:,2) = (a_stacked>thresh).*(b_stacked<-thresh);
ind(:,3) = (a_stacked>thresh).*(b_stacked>-thresh);

frac = sum(g_stacked*ones(1,3).*ind.*da_stacked.*db_stacked,1)*100;

dc=zeros(I,J,K);
dc(1:I-1,:,:)=(c(2:I,:,:)-c(1:I-1,:,:))/db.*(1-adjRegion(1:I-1,:,:));
disp('[Renters (36%), Mortgagers (40%), Ourtight (23%)] =')
disp(frac)
time=toc;
eval(horzcat('save ',savefile,' g Cons c u rent aaa bbb adjRegion '));
