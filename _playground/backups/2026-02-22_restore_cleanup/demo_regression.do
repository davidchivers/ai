* Demo: Regression and Graph in Stata
* Date: 2026-02-20

* Load built-in auto dataset
sysuse auto, clear

* Run OLS regression: price on weight and mpg
regress price weight mpg

* Scatter plot with fitted regression line (price vs weight)
twoway ///
    (scatter price weight, mcolor(navy) msymbol(circle) msize(small)) ///
    (lfit price weight, lcolor(red) lwidth(medium)), ///
    title("Car Price vs Weight") ///
    subtitle("with OLS Fitted Line") ///
    xtitle("Weight (lbs)") ///
    ytitle("Price (USD)") ///
    legend(order(1 "Observed" 2 "OLS Fit")) ///
    scheme(s2color)
