function Obj = wqregk_zeta_age(c)
global tau Matdraw MatAGE1_tot T

Obj=mean((Matdraw(:,T+1)-MatAGE1_tot*c).*...
    (tau-(Matdraw(:,T+1)-MatAGE1_tot*c<0)));
    
end
