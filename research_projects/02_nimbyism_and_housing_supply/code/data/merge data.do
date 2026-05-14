//////////////Merge birthrates data/////////////////

/// Note: .dta files appended with 13 are stata13 compatiable///

clear all

local external_root : environment ZAC_DAVID_EXTERNAL_ROOT

if `"`external_root'"' != "" {
    capture confirm file `"`external_root'\Data\state.dta"'
    if _rc != 0 {
        display as error "ZAC_DAVID_EXTERNAL_ROOT is set but Data\state.dta was not found under it: `external_root'"
        exit 601
    }
}

if `"`external_root'"' == "" {
    capture confirm file "D:\research_data\zac_and_david\Data\state.dta"
    if _rc == 0 local external_root "D:\research_data\zac_and_david"
}

if `"`external_root'"' == "" {
    local userprofile : environment USERPROFILE
    if `"`userprofile'"' != "" {
        capture confirm file `"`userprofile'\Dropbox\Zac and David\Data\state.dta"'
        if _rc == 0 local external_root `"`userprofile'\Dropbox\Zac and David"'
    }
}

if `"`external_root'"' == "" {
    capture confirm file "C:\Users\Dave_\Dropbox\Zac and David\Data\state.dta"
    if _rc == 0 local external_root "C:\Users\Dave_\Dropbox\Zac and David"
}

if `"`external_root'"' == "" {
    display as error "Could not find Zac and David data. Set ZAC_DAVID_EXTERNAL_ROOT to the folder containing Data\state.dta, or sync Dropbox to %USERPROFILE%\Dropbox\Zac and David."
    exit 601
}

global dir1 `"`external_root'\Data"'
cd "$dir1"

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

