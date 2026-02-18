function Obj = wqregk_pt_age(c)
global tau Matdraw_t Matdraw_lag 

Obj=mean((Matdraw_t-Matdraw_lag*c).*...
    (tau-(Matdraw_t-Matdraw_lag*c<0)));
    
end
