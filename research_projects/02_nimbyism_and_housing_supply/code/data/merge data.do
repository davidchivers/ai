//////////////Merge birthrates data/////////////////

/// Note: .dta files appended with 13 are stata13 compatiable///

clear all
global dir1 "C:\Users\Dave_\Dropbox\Zac and David\Data"
cd "C:\Users\Dave_\Dropbox\Zac and David\Data"

use state, clear
merge m:m statefips using birthrates13
drop _merge
rename stateicpsr stateicp
sort stateicp
merge m:m stateicp using data13

////Check here merge went ok///

drop _merge
drop if birthrate==.
drop if city ==.
drop statefips stateicp statepa sample statenamecaps metaread bpl

save merged_data, replace




///merge wharton data///
///decode city, generate(cit)
///drop city
///rename cit city
///merge m:m city using wharton1

