use "/Users/igro0002/Dropbox/Zac and David/data/usa_00009.dta", clear
numlabel, add
drop race raced
drop bpl gq cbserial serial sample
drop ownershpd
drop metaread
drop pernum perwt hhwt

drop if stateicp == 81 //drop Alaska and Hawaii
drop if stateicp == 82

drop if metarea == .  & met2013 == .
drop if metarea == 0  & met2013 == 0
drop if metarea == .  & met2013 == 0
drop if metarea == 0  & met2013 == .

drop if bpld > 6000

replace metarea = met2013 if metarea == . & year>2011

replace metarea = 188 if met2013 == 18580

drop met2013
/*drop if metarea == 101
replace metarea = 188 if city == 1520 & metarea == 0
replace metarea = 804 if city == 6730 & metarea == 0
replace metarea = 560 if city == 4610 & metarea == 0
replace metarea = 112 if city == 810 & metarea == 0
drop if city == 2575
drop if city == 650

replace metarea = 64 if city == 490 & metarea == .
replace metarea = 72 if city == 530 & metarea == .
replace metarea = 112 if city == 810 & metarea == .
replace metarea = 128 if city == 890 & metarea == .
replace metarea = 160 if city == 1190 & metarea == .
replace metarea = 168 if city == 1330 & metarea == .
replace metarea = 192 if city == 1590 & metarea == .
replace metarea = 208 if city == 1710 & metarea == .
replace metarea = 216 if city == 1750 & metarea == .
replace metarea = 231 if city == 2010 & metarea == .
replace metarea = 192 if city == 2350 & metarea == .
replace metarea = 284 if city == 2370 & metarea == .
replace metarea = 336 if city == 2890 & metarea == .
replace metarea = 348 if city == 2990 & metarea == .
replace metarea = 448 if city == 3690 & metarea == .
replace metarea = 448 if city == 3730 & metarea == .
replace metarea = 492 if city == 4010 & metarea == .
replace metarea = 500 if city == 4110 & metarea == .
replace metarea = 508 if city == 4130 & metarea == .
replace metarea = 512 if city == 4150 & metarea == .
replace metarea = 536 if city == 4410 & metarea == .
replace metarea = 556 if city == 4570 & metarea == .
replace metarea = 560 if city == 4610 & metarea == .
replace metarea = 560 if city == 4630 & metarea == .
replace metarea = 736 if city == 4930 & metarea == .
replace metarea = 616 if city == 5330 & metarea == .
replace metarea = 620 if city == 5350 & metarea == .
replace metarea = 644 if city == 5530 & metarea == .
replace metarea = 692 if city == 6030 & metarea == .
replace metarea = 704 if city == 6090 & metarea == .
replace metarea = 724 if city == 6230 & metarea == .
replace metarea = 732 if city == 6270 & metarea == .
replace metarea = 736 if city == 6290 & metarea == .
replace metarea = 448 if city == 6330 & metarea == .
replace metarea = 760 if city == 6430 & metarea == .
replace metarea = 572 if city == 7130 & metarea == .
replace metarea = 884 if city == 7230 & metarea == .
*/

save dataslim, replace
use dataslim, clear

g rent = .
replace rent = 1 if ownershp == 2
replace rent = 0 if ownershp==1

g own = .
replace own = 1 if ownershp == 1
replace own = 0 if ownershp == 2

g unemp = .
replace unemp = 1 if empstat == 2
replace unemp = 0 if empstat == 0
replace unemp = 0 if empstat == 1
replace unemp = 0 if empstat == 3

g age20_30 = .
replace age20_30 = 1 if age >=20 & age <=30
replace age20_30 = 0 if age <20
replace age20_30 = 0 if age >30

g age30_40 = .
replace age30_40 = 1 if age >=30 & age <=40
replace age30_40 = 0 if age <30
replace age30_40 = 0 if age >40

g age40_50 = .
replace age40_50 = 1 if age >=40 & age <=50
replace age40_50 = 0 if age <40
replace age40_50 = 0 if age >50

g age50_60 = .
replace age50_60 = 1 if age >=50 & age <=60
replace age50_60 = 0 if age <50
replace age50_60 = 0 if age >60

collapse (mean) age rent own age50_60 age40_50 age30_40  age20_30 citypop unemp , by (year metarea )

sort  metarea year

save tenurerates, replace 



