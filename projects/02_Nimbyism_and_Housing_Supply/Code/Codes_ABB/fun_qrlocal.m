function fval=fun_qrlocal(b)
global Vect Vect_dep xx bdw tau

fval=sum(normpdf((Vect_dep(:)-xx)/bdw).*(tau-(Vect(:)<b(1)+b(2).*Vect_dep(:))).*(Vect(:)-b(1)-b(2).*Vect_dep(:)));

end


