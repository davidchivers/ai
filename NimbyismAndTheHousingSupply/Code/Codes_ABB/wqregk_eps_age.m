function Obj = wqregk_eps_age(c)
global tau Matdraw_tot MatAGE_tot Ytot_t

Obj=mean((Ytot_t-Matdraw_tot-MatAGE_tot*c).*...
    (tau-(Ytot_t-Matdraw_tot-MatAGE_tot*c<0)));
    
end
