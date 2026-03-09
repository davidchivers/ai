clear all
set more off

capture log close
log using "gem_2021_microdata_inspection.log", text replace

display "Starting GEM 2021 APS microdata inspection"
display c(current_date) " " c(current_time)

import spss using ///
    "C:\Users\Dave_\AppData\Local\Temp\gem_2021_aps_individual\GEM 2021 APS Global Individual Level Data_8Dec2025.sav", ///
    clear

display "Observations: " _N
display "Variables: " c(k)

display "=== Country candidates ==="
lookfor country nation economy usa united states

display "=== Motive candidates ==="
lookfor motive motivation opportunity necessity scarce jobs living

display "=== Key candidate variables ==="
capture describe ID COUNTRY COUNTRY1 ECONOMY GEMLOC APSCOUNTRY
capture describe SUMOTIV4 OMMOTIV4 V315_A V319_A V323_A V327_A V331_A V335_A V339_A

display "=== Country tabulations for likely variables ==="
capture noisily tab COUNTRY if !missing(COUNTRY)
capture noisily tab COUNTRY1 if !missing(COUNTRY1)
capture noisily tab GEMLOC if !missing(GEMLOC)
capture noisily tab APSCOUNTRY if !missing(APSCOUNTRY)

display "=== Motive tabulations for likely variables ==="
capture noisily tab SUMOTIV4 if !missing(SUMOTIV4)
capture noisily tab OMMOTIV4 if !missing(OMMOTIV4)
capture noisily tab V315_A if !missing(V315_A)
capture noisily tab V319_A if !missing(V319_A)
capture noisily tab V323_A if !missing(V323_A)
capture noisily tab V327_A if !missing(V327_A)
capture noisily tab V331_A if !missing(V331_A)
capture noisily tab V335_A if !missing(V335_A)
capture noisily tab V339_A if !missing(V339_A)

display "Finished GEM 2021 APS microdata inspection"
log close
