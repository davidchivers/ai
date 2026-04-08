clear all
set more off

display "Creating tiny fake AI-productivity dataset..."
set obs 40
set seed 12345

gen AI = runiform()
gen productivity = 50 + 30*AI + rnormal(0,5)

label variable AI "AI adoption"
label variable productivity "Productivity"

display "Making graph..."
twoway ///
    (scatter productivity AI, mcolor(navy%60) msymbol(circle_hollow)) ///
    (lfit productivity AI, lcolor(maroon)), ///
    title("Tiny Stata demo") ///
    subtitle("Fake AI and productivity data") ///
    name(tiny_stata_demo, replace)

display "Running regression..."
reg productivity AI

display "Keeping graph visible..."
graph display tiny_stata_demo

display "Done."
