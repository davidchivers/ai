use merged_birthrates_migrationweights, clear

merge m:1 year metarea using buildingcrosswalk.dta

drop _merge

drop if metarea == 0
drop if metarea == .

sort  metarea year
 
quietly{
g l1bw = l1.weightedbirthrate
g l2bw = l2.weightedbirthrate
g l3bw = l3.weightedbirthrate
g l4bw = l4.weightedbirthrate
g l5bw = l5.weightedbirthrate
g l6bw = l6.weightedbirthrate
g l7bw = l7.weightedbirthrate
g l8bw = l8.weightedbirthrate
g l9bw = l9.weightedbirthrate
g l10bw = l10.weightedbirthrate
g l11bw = l11.weightedbirthrate
g l12bw = l12.weightedbirthrate
g l13bw = l13.weightedbirthrate
g l14bw = l14.weightedbirthrate
g l15bw = l15.weightedbirthrate
g l16bw = l16.weightedbirthrate
g l17bw = l17.weightedbirthrate
g l18bw = l18.weightedbirthrate
g l19bw = l19.weightedbirthrate
g l20bw = l20.weightedbirthrate
g l21bw = l21.weightedbirthrate
g l22bw = l22.weightedbirthrate
g l23bw = l23.weightedbirthrate
g l24bw = l24.weightedbirthrate
g l25bw = l25.weightedbirthrate
g l26bw = l26.weightedbirthrate
g l27bw = l27.weightedbirthrate
g l28bw = l28.weightedbirthrate
g l29bw = l29.weightedbirthrate
g l30bw = l30.weightedbirthrate
g l31bw = l31.weightedbirthrate
g l32bw = l32.weightedbirthrate
g l33bw = l33.weightedbirthrate
g l34bw = l34.weightedbirthrate
g l35bw = l35.weightedbirthrate
g l36bw = l36.weightedbirthrate
g l37bw = l37.weightedbirthrate
g l38bw = l38.weightedbirthrate
g l39bw = l39.weightedbirthrate
g l40bw = l40.weightedbirthrate
g l41bw = l41.weightedbirthrate
g l42bw = l42.weightedbirthrate
g l43bw = l43.weightedbirthrate
g l44bw = l44.weightedbirthrate
g l45bw = l45.weightedbirthrate
g l46bw = l46.weightedbirthrate
g l47bw = l47.weightedbirthrate
g l48bw = l48.weightedbirthrate
g l49bw = l49.weightedbirthrate
g l50bw = l50.weightedbirthrate
g l51bw = l51.weightedbirthrate
g l52bw = l52.weightedbirthrate
g l53bw = l53.weightedbirthrate
g l54bw = l54.weightedbirthrate
g l55bw = l55.weightedbirthrate
g l56bw = l56.weightedbirthrate
g l57bw = l57.weightedbirthrate
g l58bw = l58.weightedbirthrate
g l59bw = l59.weightedbirthrate
g l60bw = l60.weightedbirthrate
g l61bw = l61.weightedbirthrate
g l62bw = l62.weightedbirthrate
g l63bw = l63.weightedbirthrate
g l64bw = l64.weightedbirthrate
g l65bw = l65.weightedbirthrate
}

g l50_20bw = l50bw -l20bw

correlate own l20bw l25bw l30bw l35bw l40bw l45bw l50bw l55bw l60bw

reg own  i.year i.metareano l20bw l25bw l30bw l35bw l40bw l45bw l50bw l55bw l60bw
correlate own l20bw l25bw l30bw l35bw l40bw l45bw l50bw l55bw l60bw

gen unitspercapita = totalunits/sumcity

save addedpermits, replace

gen totalunits2yeargrowth = (totalunits - l2.totalunits)/l2.totalunits
gen totalunits1yeargrowth = (totalunits - l1.totalunits)/l1.totalunits
gen totalunits5yeargrowth = (totalunits - l5.totalunits)/l5.totalunits

gen totalunits2yearmean = (totalunits + l1.totalunits)/2
gen totalunits5yearmean = (totalunits + l1.totalunits+ l2.totalunits+ l3.totalunits+ l4.totalunits)/5

reg own i.year i.metareano l50_20bw
predict own_predicted if  e(sample)

estimates clear

forvalues i=1/5 {
forvalues j=1/10 {

quietly{
ivreg2 totalunits5yeargrowth i.year i.metareano ( L(`i'/`i').own = L(`j'/`j').l50_20bw) if abs(totalunits5yeargrowth)<2 
estimate store model_5yr_`i'_`j'

ivreg2 totalunits2yeargrowth i.year i.metareano ( L(`i'/`i').own = L(`j'/`j').l50_20bw) if abs(totalunits2yeargrowth)<2 
estimate store model_2yr_`i'_`j'


ivreg2 totalunits1yeargrowth i.year i.metareano ( L(`i'/`i').own = L(`j'/`j').l50_20bw) if abs(totalunits1yeargrowth)<2
estimate store model_1yr_`i'_`j'
}
}
}



esttab * using "Regressions.csv", replace style(tab) cells(b(star fmt(3))) stats(r2 bic N) drop( *.metareano *.year) mtitles
