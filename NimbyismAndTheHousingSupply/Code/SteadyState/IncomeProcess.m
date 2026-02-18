


updiag_z1=zeros(1,1); %This is necessary because of the peculiar way spdiags is defined.
updiag_z2=zeros(1,1);
for k1=1:K1
    if z1(k1)>0
        updiag_z1=[updiag_z1;repmat(zeta_z1p(k1),1,1)];
    elseif z1(k1)<0
        updiag_z1=[updiag_z1;repmat(zeta_z1n(k1),1,1)];
    else
        updiag_z1=[updiag_z1;repmat(0,1,1)];
    end
end
for k2=1:K2
    if z2(k2)>0
        updiag_z2=[updiag_z2;repmat(zeta_z2p(k2),1,1)];
    elseif z2(k2)<0
        updiag_z2=[updiag_z2;repmat(zeta_z2n(k2),1,1)];
    else
        updiag_z2=[updiag_z2;repmat(0,1,1)];
    end
end

%This will be the center diagonal of the B_switch
if z1(1)>0
    centdiag_z1=repmat(chi_z1p(1)+yy_z1p(1),1,1);
elseif z1(1)<=0 && z1(2)>0
    centdiag_z1=repmat(chi_z1n(1)+yy_z1p(1),1,1);
else
    centdiag_z1=repmat(chi_z1n(1)+yy_z1n(1),1,1);
end

if z2(1)>0
    centdiag_z2=repmat(chi_z2p(1)+yy_z2p(1),1,1);
elseif z2(1)<=0 && z2(2)>0
    centdiag_z2=repmat(chi_z2n(1)+yy_z2p(1),1,1);
else
    centdiag_z2=repmat(chi_z2n(1)+yy_z2n(1),1,1);
end
%    centdiag_z2=repmat(chi_z2n(1)+yy_z2n(1),1,1);


for k1=2:K1-1
    if z1(k1)>0
        centdiag_z1=[centdiag_z1;repmat(yy_z1p(k1),1,1)];
    elseif z1(k1)<0
        centdiag_z1=[centdiag_z1;repmat(yy_z1n(k1),1,1)];
    else
        centdiag_z1=[centdiag_z1;repmat(0,1,1)];
    end
    
end
for k2=2:K2-1
    if z2(k2)>0
        centdiag_z2=[centdiag_z2;repmat(yy_z2p(k2),1,1)];
    elseif z2(k2)<0
        centdiag_z2=[centdiag_z2;repmat(yy_z2n(k2),1,1)];
        
    else
        centdiag_z2=[centdiag_z2;repmat(0,1,1)];
    end
    
end

centdiag_z1=[centdiag_z1;repmat(yy_z1p(K1)+zeta_z1p(K1),1,1)];
centdiag_z2=[centdiag_z2;repmat(yy_z2p(K2)+zeta_z2p(K2),1,1)];

%This will be the lower diagonal of the B_switch
if z2(2)>0
    lowdiag_z2=repmat(chi_z2p(2),1,1);
elseif z2(2)<0
    lowdiag_z2=repmat(chi_z2n(2),1,1);
else
    lowdiag_z2=repmat(0,1,1);
end
if z1(2)>0
    lowdiag_z1=repmat(chi_z1p(2),1,1);
elseif z1(2)<0
    lowdiag_z1=repmat(chi_z1n(2),1,1);
else
    lowdiag_z1=repmat(0,1,1);
end

for k1=3:K1
    if z1(k1)>0
        lowdiag_z1 =[lowdiag_z1;repmat(chi_z1p(k1),1,1)];
    elseif z1(k1)<0
        lowdiag_z1 =[lowdiag_z1;repmat(chi_z1n(k1),1,1)];
    else
        lowdiag_z1 =[lowdiag_z1;repmat(0,1,1)];
    end
    
    %    lowdiag_z2 =[lowdiag_z2;repmat(chi_z2(k),I*J,1)];
end
for k2=3:K2
    if z2(k2)>0
        lowdiag_z2 =[lowdiag_z2;repmat(chi_z2p(k2),1,1)];
    elseif z2(k2)<0
        lowdiag_z2 =[lowdiag_z2;repmat(chi_z2n(k2),1,1)];
    else
        lowdiag_z2 =[lowdiag_z2;repmat(0,1,1)];
    end
end