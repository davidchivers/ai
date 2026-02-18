function Obj = wqregk_e0_age(c)
global tau Matdraw MatAGE1_tot

Obj=mean((Matdraw(:,1)-MatAGE1_tot*c).*...
    (tau-(Matdraw(:,1)-MatAGE1_tot*c<0)));
    
end
