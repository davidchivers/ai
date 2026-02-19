
import delimited  using "/Users/igro0002/Dropbox/Zac and David/Data/Buildings/Metarea to MSA crosswalk.csv", clear

rename ïyear year

//There is a duplicate city here in Oklahoma
drop if metarea == 36420

keep year metarea metareano total

sort  year metareano

save "/Users/igro0002/Dropbox/Zac and David/Data/buildingcrosswalk.dta", replace

