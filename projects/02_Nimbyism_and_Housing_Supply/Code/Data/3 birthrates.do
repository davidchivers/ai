


//use birthrates13, clear
//merge m:m statefips using weights
use weights, clear
gen year = 1940
save weightspanel, replace

//1944 1945 1946 1947 1948 1949 1950 1951 1952 1953 1954 1955 1956 1957 1958 1959 1960 1961 1962 1963 1964 1965 1966 1967 1968 1969 1970 1971 1972 1973 1974 1975 1976 1977 1978 1979 1980 1981 1982 1983 1984 1985 1986 1987 1988 1989 1990 1991 1992 1993 1994 1995
quietly{
foreach i in 1944 1945 1946 1947 1948 1949 1950 1951 1952 1953 1954 1955 1956 1957 1958 1959 1960 1961 1962 1963 1964 1965 1966 1967 1968 1969 1970 1971 1972 1973 1974 1975 1976 1977 1978 1979 1980 1981 1982 1983 1984 1985 1986 1987 1988 1989 1990 1991 1992 1993 1994 1995 1996 1997 1998 1999 2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014  {
use weights, clear
gen year = `i'

append using weightspanel
save weightspanel, replace


} 
replace statefips = statefips/100
}
 
numlabel, add
merge m:1 statefips year using birthrates_updated
drop _merge



g weightedbirthrate = birthrate*share
//calculate shares excluding local birthrates in denominator



drop if year == .
drop if metarea == .
drop if statefips == .

collapse (sum) weightedbirthrate , by (metarea  year)

merge m:m metarea  using weights, keepusing(sumcity)
drop _merge

replace weightedbirthrate = . if weightedbirthrate == 0
//replace weightedbirthrate2 = . if weightedbirthrate == 0

merge m:1 metarea  year using tenurerates
drop _merge

tsset metarea year

save merged_birthrates_migrationweights, replace

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

reg own  i.year i.metarea l50_20bw
correlate own l20bw l25bw l30bw l35bw l40bw l45bw l50bw l55bw l60bw
