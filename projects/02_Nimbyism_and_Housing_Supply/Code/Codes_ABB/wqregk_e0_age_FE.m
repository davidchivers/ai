function Obj = wqregk_e0_age_FE(c)
global tau Matdraw MatzetaAGE1_tot

Obj=mean((Matdraw(:,1)-MatzetaAGE1_tot*c).*...
    (tau-(Matdraw(:,1)-MatzetaAGE1_tot*c<0)));
    
end
