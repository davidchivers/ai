function Obj = wqregk_eps_age_FE(c)
global tau Matdraw_tot MatAGE_tot Ytot_t Matzeta_tot

Obj=mean((Ytot_t-Matdraw_tot-Matzeta_tot-MatAGE_tot*c).*...
    (tau-(Ytot_t-Matdraw_tot-Matzeta_tot-MatAGE_tot*c<0)));
    
end
