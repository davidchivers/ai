

clear all
use "/Users/igro0002/Dropbox/Zac and David/data/dataslim.dta"
numlabel, add

gen count=1
collapse (count) count, by (metarea bpl)

by metarea: egen sumcity=total(count)
 
gen share = count / sumcity

drop if bpl == .
drop if metarea == .

/*
drop if metarea == 4 & bpl == 48
drop if metarea == 8 & bpl == 39
drop if metarea == 12 & bpl == 13
drop if metarea == 16 & bpl == 36
drop if metarea == 20 & bpl == 35
drop if metarea == 22 & bpl == 22
drop if metarea == 24 & bpl == 34 & bpl == 42
drop if metarea == 28 & bpl == 42
drop if metarea == 32 & bpl == 48
drop if metarea == 38 & bpl == 2
drop if metarea == 40 & bpl == 18
drop if metarea == 44 & bpl == 26
drop if metarea == 45 & bpl == 1
drop if metarea == 46 & bpl == 55
drop if metarea == 48 & bpl == 37
drop if metarea == 50 & bpl == 13
drop if metarea == 52 & bpl == 13
drop if metarea == 56 & bpl == 34
drop if metarea == 58 & bpl == 1
drop if metarea == 60 & bpl == 13 & bpl == 45
drop if metarea == 64 & bpl == 48
drop if metarea == 68 & bpl == 6
drop if metarea == 72 & bpl == 24
drop if metarea == 74 & bpl == 25
drop if metarea == 76 & bpl == 22
drop if metarea == 78 & bpl == 26
drop if metarea == 84 & bpl == 48
drop if metarea == 86 & bpl == 53
drop if metarea == 87 & bpl == 26
drop if metarea == 88 & bpl == 30
drop if metarea == 92 & bpl == 28
drop if metarea == 96 & bpl == 36
drop if metarea == 100 & bpl == 1
drop if metarea == 102 & bpl == 18
drop if metarea == 104 & bpl == 17
drop if metarea == 108 & bpl == 16
drop if metarea == 112 & bpl == 25 & bpl == 33
drop if metarea == 114 & bpl == 12
drop if metarea == 115 & bpl == 53
drop if metarea == 116 & bpl == 9
drop if metarea == 120 & bpl == 25
drop if metarea == 124 & bpl == 48
drop if metarea == 126 & bpl == 48
drop if metarea == 128 & bpl == 36
drop if metarea == 130 & bpl == 37
drop if metarea == 132 & bpl == 39
drop if metarea == 136 & bpl == 19
drop if metarea == 140 & bpl == 17
drop if metarea == 144 & bpl == 45
drop if metarea == 148 & bpl == 54
drop if metarea == 152 & bpl == 37 & bpl == 45
drop if metarea == 154 & bpl == 51
drop if metarea == 156 & bpl == 13 & bpl == 47
drop if metarea == 158 & bpl == 56
drop if metarea == 160 & bpl == 17
drop if metarea == 162 & bpl == 6
drop if metarea == 164 & bpl == 18 & bpl == 21 & bpl == 39
drop if metarea == 166 & bpl == 21 & bpl == 47
drop if metarea == 168 & bpl == 39
drop if metarea == 172 & bpl == 8
drop if metarea == 174 & bpl == 29
drop if metarea == 176 & bpl == 45
drop if metarea == 180 & bpl == 1 & bpl == 13
drop if metarea == 184 & bpl == 39
drop if metarea == 188 & bpl == 48
drop if metarea == 192 & bpl == 48
drop if metarea == 193 & bpl == 9
drop if metarea == 195 & bpl == 51
drop if metarea == 196 & bpl == 17 & bpl == 19
drop if metarea == 200 & bpl == 39
drop if metarea == 202 & bpl == 12
drop if metarea == 203 & bpl == 1
drop if metarea == 204 & bpl == 17
drop if metarea == 208 & bpl == 8
drop if metarea == 212 & bpl == 19
drop if metarea == 216 & bpl == 26
drop if metarea == 218 & bpl == 1
drop if metarea == 219 & bpl == 10
drop if metarea == 224 & bpl == 27 & bpl == 55
drop if metarea == 228 & bpl == 36
drop if metarea == 229 & bpl == 55
drop if metarea == 231 & bpl == 48
drop if metarea == 232 & bpl == 18
drop if metarea == 236 & bpl == 42
drop if metarea == 240 & bpl == 41
drop if metarea == 244 & bpl == 18 & bpl == 21
drop if metarea == 252 & bpl == 27 & bpl == 38
drop if metarea == 256 & bpl == 37
drop if metarea == 258 & bpl == 5
drop if metarea == 260 & bpl == 25
drop if metarea == 262 & bpl == 4 & bpl == 49
drop if metarea == 264 & bpl == 26
drop if metarea == 265 & bpl == 1
drop if metarea == 266 & bpl == 45
drop if metarea == 267 & bpl == 8
drop if metarea == 268 & bpl == 12
drop if metarea == 270 & bpl == 12
drop if metarea == 271 & bpl == 12
drop if metarea == 272 & bpl == 5 & bpl == 40
drop if metarea == 275 & bpl == 12
drop if metarea == 276 & bpl == 18
drop if metarea == 284 & bpl == 6
drop if metarea == 288 & bpl == 1
drop if metarea == 290 & bpl == 12
drop if metarea == 292 & bpl == 48
drop if metarea == 297 & bpl == 36
drop if metarea == 298 & bpl == 37
drop if metarea == 300 & bpl == 26
drop if metarea == 301 & bpl == 8
drop if metarea == 304 & bpl == 30
drop if metarea == 306 & bpl == 8
drop if metarea == 308 & bpl == 55
drop if metarea == 312 & bpl == 37
drop if metarea == 315 & bpl == 37
drop if metarea == 316 & bpl == 45
drop if metarea == 318 & bpl == 24
drop if metarea == 320 & bpl == 39
drop if metarea == 324 & bpl == 42
drop if metarea == 328 & bpl == 9
drop if metarea == 329 & bpl == 37
drop if metarea == 330 & bpl == 28
drop if metarea == 332 & bpl == 15
drop if metarea == 335 & bpl == 22
drop if metarea == 336 & bpl == 48
drop if metarea == 340 & bpl == 21 & bpl == 39 & bpl == 54
drop if metarea == 344 & bpl == 1
drop if metarea == 348 & bpl == 18
drop if metarea == 350 & bpl == 19
drop if metarea == 352 & bpl == 26
drop if metarea == 356 & bpl == 28
drop if metarea == 358 & bpl == 47
drop if metarea == 359 & bpl == 12
drop if metarea == 360 & bpl == 37
drop if metarea == 361 & bpl == 36
drop if metarea == 362 & bpl == 55
drop if metarea == 366 & bpl == 37 & bpl == 47 & bpl == 54
drop if metarea == 368 & bpl == 42
drop if metarea == 371 & bpl == 29
drop if metarea == 372 & bpl == 26
drop if metarea == 374 & bpl == 17
drop if metarea == 376 & bpl == 20 & bpl == 29
drop if metarea == 380 & bpl == 55
drop if metarea == 381 & bpl == 48
drop if metarea == 384 & bpl == 47
drop if metarea == 385 & bpl == 18
drop if metarea == 387 & bpl == 55
drop if metarea == 388 & bpl == 22
drop if metarea == 392 & bpl == 18
drop if metarea == 396 & bpl == 22
drop if metarea == 398 & bpl == 12
drop if metarea == 400 & bpl == 42
drop if metarea == 404 & bpl == 26
drop if metarea == 408 & bpl == 48
drop if metarea == 410 & bpl == 35
drop if metarea == 412 & bpl == 32
drop if metarea == 420 & bpl == 40
drop if metarea == 428 & bpl == 21
drop if metarea == 432 & bpl == 39
drop if metarea == 436 & bpl == 31
drop if metarea == 440 & bpl == 2
drop if metarea == 441 & bpl == 34
drop if metarea == 442 & bpl == 48
drop if metarea == 444 & bpl == 39
drop if metarea == 448 & bpl == 6
drop if metarea == 452 & bpl == 18 & bpl == 21
drop if metarea == 460 & bpl == 48
drop if metarea == 464 & bpl == 51
drop if metarea == 468 & bpl == 13
drop if metarea == 472 & bpl == 55
drop if metarea == 476 & bpl == 33
drop if metarea == 480 & bpl == 39
drop if metarea == 488 & bpl == 48
drop if metarea == 489 & bpl == 41
drop if metarea == 490 & bpl == 12
drop if metarea == 492 & bpl == 5 & bpl == 28 & bpl == 47
drop if metarea == 494 & bpl == 6
drop if metarea == 500 & bpl == 12
drop if metarea == 504 & bpl == 48
drop if metarea == 508 & bpl == 55
drop if metarea == 512 & bpl == 27
drop if metarea == 514 & bpl == 30
drop if metarea == 516 & bpl == 1
drop if metarea == 517 & bpl == 6
drop if metarea == 519 & bpl == 34
drop if metarea == 520 & bpl == 22
drop if metarea == 524 & bpl == 1
drop if metarea == 528 & bpl == 18
drop if metarea == 532
drop if metarea == 533 & bpl == 45
drop if metarea == 534 & bpl == 12
drop if metarea == 535 & bpl == 33
drop if metarea == 536 & bpl == 47
drop if metarea == 540 & bpl == 25
drop if metarea == 546 & bpl == 34 & bpl == 36
drop if metarea == 548 & bpl == 9
drop if metarea == 552 & bpl == 9 & bpl == 44
drop if metarea == 556 & bpl == 22
drop if metarea == 560 & bpl == 34
drop if metarea == 564 & bpl == 39
drop if metarea == 566 & bpl == 36
drop if metarea == 572 & bpl == 51
drop if metarea == 576 & bpl == 9
drop if metarea == 579 & bpl == 12
drop if metarea == 580 & bpl == 48
drop if metarea == 588 & bpl == 40
drop if metarea == 591 & bpl == 53
drop if metarea == 592 & bpl == 19 & bpl == 31
drop if metarea == 595 & bpl == 36
drop if metarea == 596 & bpl == 12
drop if metarea == 601 & bpl == 12
drop if metarea == 603 & bpl == 28
drop if metarea == 608 & bpl == 12
drop if metarea == 612 & bpl == 17
drop if metarea == 616 & bpl == 34 & bpl == 42
drop if metarea == 620 & bpl == 4
drop if metarea == 628 & bpl == 42
drop if metarea == 640 & bpl == 23
drop if metarea == 644 & bpl == 41 & bpl == 53
drop if metarea == 645 & bpl == 23 & bpl == 33
drop if metarea == 648 & bpl == 25 & bpl == 44
drop if metarea == 652 & bpl == 49
drop if metarea == 656 & bpl == 8
drop if metarea == 658 & bpl == 12
drop if metarea == 660 & bpl == 55
drop if metarea == 664 & bpl == 37
drop if metarea == 668 & bpl == 42
drop if metarea == 669 & bpl == 6
drop if metarea == 672 & bpl == 32
drop if metarea == 674 & bpl == 53
drop if metarea == 676 & bpl == 51
drop if metarea == 678 & bpl == 6
drop if metarea == 680 & bpl == 51
drop if metarea == 682 & bpl == 27
drop if metarea == 684 & bpl == 36
drop if metarea == 688 & bpl == 17
drop if metarea == 689 & bpl == 37
drop if metarea == 692 & bpl == 6
drop if metarea == 696 & bpl == 26
drop if metarea == 698 & bpl == 27
drop if metarea == 700 & bpl == 29
drop if metarea == 704 & bpl == 17 & bpl == 29
drop if metarea == 708 & bpl == 41
drop if metarea == 712 & bpl == 6
drop if metarea == 714 & bpl == 37
drop if metarea == 716 & bpl == 49
drop if metarea == 724 & bpl == 48
drop if metarea == 732 & bpl == 6
drop if metarea == 736 & bpl == 6
drop if metarea == 740 & bpl == 6
drop if metarea == 746 & bpl == 6
drop if metarea == 747 & bpl == 6
drop if metarea == 748 & bpl == 6
drop if metarea == 749 & bpl == 35
drop if metarea == 750 & bpl == 6
drop if metarea == 751 & bpl == 12
drop if metarea == 752 & bpl == 13
drop if metarea == 756 & bpl == 42
drop if metarea == 760 & bpl == 53
drop if metarea == 761 & bpl == 42
drop if metarea == 762 & bpl == 55
drop if metarea == 768 & bpl == 22
drop if metarea == 772 & bpl == 19 & bpl == 31
drop if metarea == 776 & bpl == 46
drop if metarea == 780 & bpl == 18
drop if metarea == 784 & bpl == 53
drop if metarea == 788 & bpl == 17
drop if metarea == 792 & bpl == 29
drop if metarea == 800 & bpl == 25
drop if metarea == 804 & bpl == 9
drop if metarea == 805 & bpl == 42
drop if metarea == 812 & bpl == 6
drop if metarea == 814 & bpl == 45
drop if metarea == 816 & bpl == 36
drop if metarea == 820 & bpl == 53
drop if metarea == 824 & bpl == 12
drop if metarea == 828 & bpl == 12
drop if metarea == 832 & bpl == 18
drop if metarea == 840 & bpl == 26 & bpl == 39
drop if metarea == 844 & bpl == 20
drop if metarea == 848 & bpl == 34
drop if metarea == 852 & bpl == 4
drop if metarea == 856 & bpl == 40
drop if metarea == 860 & bpl == 1
drop if metarea == 864 & bpl == 48
drop if metarea == 868 & bpl == 36
drop if metarea == 873 & bpl == 6
drop if metarea == 876 & bpl == 34
drop if metarea == 878 & bpl == 6
drop if metarea == 880 & bpl == 48
drop if metarea == 884 & bpl == 11 & bpl == 24 & bpl == 51
drop if metarea == 888 & bpl == 9
drop if metarea == 892 & bpl == 19
drop if metarea == 894 & bpl == 55
drop if metarea == 896 & bpl == 12
drop if metarea == 904 & bpl == 20
drop if metarea == 908 & bpl == 48
drop if metarea == 914 & bpl == 42
drop if metarea == 916 & bpl == 10 & bpl == 24 & bpl == 34
drop if metarea == 920 & bpl == 37
drop if metarea == 924 & bpl == 25
drop if metarea == 926 & bpl == 53
drop if metarea == 927 & bpl == 6
drop if metarea == 928 & bpl == 42
drop if metarea == 932 & bpl == 39 & bpl == 42
drop if metarea == 934 & bpl == 6
drop if metarea == 936 & bpl == 4

drop if metarea == 10420 & bpl == 39
drop if metarea == 10580 & bpl == 36
drop if metarea == 10740 & bpl == 35
drop if metarea == 10780 & bpl == 22
drop if metarea == 10900 & bpl == 34 & bpl == 42
drop if metarea == 11020 & bpl == 42
drop if metarea == 11100 & bpl == 48
drop if metarea == 11460 & bpl == 26
drop if metarea == 11500 & bpl == 1
drop if metarea == 11700 & bpl == 37
drop if metarea == 12020 & bpl == 13
drop if metarea == 12060 & bpl == 13
drop if metarea == 12100 & bpl == 34
drop if metarea == 12220 & bpl == 1
drop if metarea == 12260 & bpl == 13 & bpl == 45
drop if metarea == 12420 & bpl == 48
drop if metarea == 12540 & bpl == 6
drop if metarea == 12580 & bpl == 24
drop if metarea == 12620 & bpl == 23
drop if metarea == 12700 & bpl == 25
drop if metarea == 12940 & bpl == 22
drop if metarea == 12980 & bpl == 26
drop if metarea == 13140 & bpl == 48
drop if metarea == 13380 & bpl == 53
drop if metarea == 13460 & bpl == 41
drop if metarea == 13740 & bpl == 30
drop if metarea == 13780 & bpl == 36
drop if metarea == 13820 & bpl == 1
drop if metarea == 13900 & bpl == 38
drop if metarea == 13980 & bpl == 51
drop if metarea == 14010 & bpl == 17
drop if metarea == 14020 & bpl == 18
drop if metarea == 14260 & bpl == 16
drop if metarea == 14460 & bpl == 25 & bpl == 33
drop if metarea == 14740 & bpl == 53
drop if metarea == 14860 & bpl == 9
drop if metarea == 15180 & bpl == 48
drop if metarea == 15380 & bpl == 36
drop if metarea == 15500 & bpl == 37
drop if metarea == 15540 & bpl == 50
drop if metarea == 15940 & bpl == 39
drop if metarea == 15980 & bpl == 12
drop if metarea == 16580 & bpl == 17
drop if metarea == 16620 & bpl == 54
drop if metarea == 16700 & bpl == 45
drop if metarea == 16740 & bpl == 37
drop if metarea == 16820 & bpl == 51
drop if metarea == 16860 & bpl == 13 & bpl == 47
drop if metarea == 16980 & bpl == 17 & bpl == 18
drop if metarea == 17020 & bpl == 6
drop if metarea == 17140 & bpl == 18 & bpl == 21 & bpl == 39
drop if metarea == 17300 & bpl == 21 & bpl == 47
drop if metarea == 17460 & bpl == 39
drop if metarea == 17660 & bpl == 16
drop if metarea == 17780 & bpl == 48
drop if metarea == 17820 & bpl == 8
drop if metarea == 17860 & bpl == 29
drop if metarea == 17900 & bpl == 45
drop if metarea == 18140 & bpl == 39
drop if metarea == 18580 & bpl == 48
drop if metarea == 19100 & bpl == 48
drop if metarea == 19300 & bpl == 1
drop if metarea == 19340 & bpl == 19
drop if metarea == 19380 & bpl == 39
drop if metarea == 19460 & bpl == 1
drop if metarea == 19500 & bpl == 17
drop if metarea == 19660 & bpl == 12
drop if metarea == 19740 & bpl == 8
drop if metarea == 19780 & bpl == 19
drop if metarea == 19820 & bpl == 26
drop if metarea == 20100 & bpl == 10
drop if metarea == 20500 & bpl == 37
drop if metarea == 20700 & bpl == 42
drop if metarea == 20740 & bpl == 55
drop if metarea == 20940 & bpl == 6
drop if metarea == 21060 & bpl == 21
drop if metarea == 21140 & bpl == 18
drop if metarea == 21340 & bpl == 48
drop if metarea == 21500 & bpl == 42
drop if metarea == 21660 & bpl == 41
drop if metarea == 21780 & bpl == 18 & bpl == 21
drop if metarea == 22140 & bpl == 35
drop if metarea == 22180 & bpl == 37
drop if metarea == 22220 & bpl == 2
drop if metarea == 22380 & bpl == 4
drop if metarea == 22420 & bpl == 26
drop if metarea == 22500 & bpl == 45
drop if metarea == 22520 & bpl == 1
drop if metarea == 22660 & bpl == 8
drop if metarea == 23060 & bpl == 18
drop if metarea == 23420 & bpl == 6
drop if metarea == 23460 & bpl == 1
drop if metarea == 23540 & bpl == 12
drop if metarea == 23580 & bpl == 13
drop if metarea == 24020 & bpl == 36
drop if metarea == 24140 & bpl == 37
drop if metarea == 24300 & bpl == 8
drop if metarea == 24340 & bpl == 26
drop if metarea == 24540 & bpl == 8
drop if metarea == 24660 & bpl == 37
drop if metarea == 24780 & bpl == 37
drop if metarea == 24860 & bpl == 45
drop if metarea == 25060 & bpl == 28
drop if metarea == 25220 & bpl == 22
drop if metarea == 25260 & bpl == 6
drop if metarea == 25420 & bpl == 42
drop if metarea == 25500 & bpl == 51
drop if metarea == 25540 & bpl == 9
drop if metarea == 25620 & bpl == 28
drop if metarea == 25860 & bpl == 37
drop if metarea == 25940 & bpl == 45
drop if metarea == 26140 & bpl == 12
drop if metarea == 26380 & bpl == 22
drop if metarea == 26420 & bpl == 48
drop if metarea == 26620 & bpl == 1
drop if metarea == 26900 & bpl == 18
drop if metarea == 26980 & bpl == 19
drop if metarea == 27060 & bpl == 36
drop if metarea == 27100 & bpl == 26
drop if metarea == 27140 & bpl == 28
drop if metarea == 27180 & bpl == 47
drop if metarea == 27260 & bpl == 12
drop if metarea == 27340 & bpl == 37
drop if metarea == 27500 & bpl == 55
drop if metarea == 27620 & bpl == 29
drop if metarea == 27780 & bpl == 42
drop if metarea == 27900 & bpl == 29
drop if metarea == 28020 & bpl == 26
drop if metarea == 28100 & bpl == 17
drop if metarea == 28140 & bpl == 20 & bpl == 29
drop if metarea == 28420 & bpl == 53
drop if metarea == 28660 & bpl == 48
drop if metarea == 28700 & bpl == 47 & bpl == 51
drop if metarea == 28940 & bpl == 47
drop if metarea == 29100 & bpl == 27 & bpl == 55
drop if metarea == 29180 & bpl == 22
drop if metarea == 29200 & bpl == 18
drop if metarea == 29340 & bpl == 22
drop if metarea == 29420 & bpl == 4
drop if metarea == 29460 & bpl == 12
drop if metarea == 29540 & bpl == 42
drop if metarea == 29620 & bpl == 26
drop if metarea == 29700 & bpl == 48
drop if metarea == 29740 & bpl == 35
drop if metarea == 29820 & bpl == 32
drop if metarea == 29940 & bpl == 20
drop if metarea == 30140 & bpl == 42
drop if metarea == 30340 & bpl == 23
drop if metarea == 30620 & bpl == 39
drop if metarea == 30700 & bpl == 31
drop if metarea == 30780 & bpl == 2
drop if metarea == 31080 & bpl == 6
drop if metarea == 31140 & bpl == 21
drop if metarea == 31180 & bpl == 48
drop if metarea == 31340 & bpl == 51
drop if metarea == 31460 & bpl == 6
drop if metarea == 31700 & bpl == 33
drop if metarea == 31900 & bpl == 39
drop if metarea == 32580 & bpl == 48
drop if metarea == 32780 & bpl == 41
drop if metarea == 32820 & bpl == 5 & bpl == 28 & bpl == 47
drop if metarea == 32900 & bpl == 6
drop if metarea == 33100 & bpl == 12
drop if metarea == 33140 & bpl == 18
drop if metarea == 33260 & bpl == 48
drop if metarea == 33340 & bpl == 55
drop if metarea == 33460 & bpl == 27
drop if metarea == 33660 & bpl == 1
drop if metarea == 33700 & bpl == 6
drop if metarea == 33740 & bpl == 22
drop if metarea == 33780 & bpl == 26
drop if metarea == 33860 & bpl == 1
drop if metarea == 34060 & bpl == 54
drop if metarea == 34620 & bpl == 18
drop if metarea == 34740 & bpl == 26
drop if metarea == 34820 & bpl == 45
drop if metarea == 34900 & bpl == 6
drop if metarea == 34940 & bpl == 12
drop if metarea == 34980 & bpl == 47
drop if metarea == 35300 & bpl == 9
drop if metarea == 35380 & bpl == 22
drop if metarea == 35620 & bpl == 36
drop if metarea == 35660 & bpl == 26
drop if metarea == 35840 & bpl == 12
drop if metarea == 35980 & bpl == 9
drop if metarea == 36100 & bpl == 12
drop if metarea == 36140 & bpl == 34
drop if metarea == 36220 & bpl == 48
drop if metarea == 36260 & bpl == 49
drop if metarea == 36420 & bpl == 40
drop if metarea == 36500 & bpl == 53
drop if metarea == 36540 & bpl == 19 & bpl == 31
drop if metarea == 36740 & bpl == 12
drop if metarea == 36780 & bpl == 55
drop if metarea == 36980 & bpl == 21
drop if metarea == 37100 & bpl == 6
drop if metarea == 37340 & bpl == 12
drop if metarea == 37460 & bpl == 12
drop if metarea == 37620 & bpl == 54
drop if metarea == 37860 & bpl == 12
drop if metarea == 37900 & bpl == 17
drop if metarea == 37980 & bpl == 34 & bpl == 42
drop if metarea == 38060 & bpl == 4
drop if metarea == 38300 & bpl == 42
drop if metarea == 38340 & bpl == 25
drop if metarea == 38860 & bpl == 23
drop if metarea == 38900 & bpl == 41
drop if metarea == 38940 & bpl == 12
drop if metarea == 39140 & bpl == 4
drop if metarea == 39300 & bpl == 25 & bpl == 44
drop if metarea == 39340 & bpl == 49
drop if metarea == 39380 & bpl == 8
drop if metarea == 39460 & bpl == 12
drop if metarea == 39540 & bpl == 55
drop if metarea == 39580 & bpl == 37
drop if metarea == 39740 & bpl == 42
drop if metarea == 39820 & bpl == 6
drop if metarea == 39900 & bpl == 32
drop if metarea == 40060 & bpl == 51
drop if metarea == 40140 & bpl == 6
drop if metarea == 40220 & bpl == 51
drop if metarea == 40380 & bpl == 36
drop if metarea == 40420 & bpl == 17
drop if metarea == 40580 & bpl == 37
drop if metarea == 40900 & bpl == 6
drop if metarea == 40980 & bpl == 26
drop if metarea == 41060 & bpl == 27
drop if metarea == 41100 & bpl == 49
drop if metarea == 41140 & bpl == 20 & bpl == 29
drop if metarea == 41180 & bpl == 17 & bpl == 29
drop if metarea == 41500 & bpl == 6
drop if metarea == 41540 & bpl == 10 & bpl == 24
drop if metarea == 41620 & bpl == 49
drop if metarea == 41660 & bpl == 48
drop if metarea == 41700 & bpl == 48
drop if metarea == 41740 & bpl == 6
drop if metarea == 41860 & bpl == 6
drop if metarea == 41940 & bpl == 6
drop if metarea == 42020 & bpl == 6
drop if metarea == 42100 & bpl == 6
drop if metarea == 42140 & bpl == 35
drop if metarea == 42200 & bpl == 6
drop if metarea == 42220 & bpl == 6
drop if metarea == 42540 & bpl == 42
drop if metarea == 42660 & bpl == 53
drop if metarea == 42680 & bpl == 12
drop if metarea == 43100 & bpl == 55
drop if metarea == 43340 & bpl == 22
drop if metarea == 43900 & bpl == 45
drop if metarea == 44060 & bpl == 53
drop if metarea == 44100 & bpl == 17
drop if metarea == 44140 & bpl == 25
drop if metarea == 44180 & bpl == 29
drop if metarea == 44220 & bpl == 39
drop if metarea == 44300 & bpl == 42
drop if metarea == 44700 & bpl == 6
drop if metarea == 44940 & bpl == 45
drop if metarea == 45060 & bpl == 36
drop if metarea == 45220 & bpl == 12
drop if metarea == 45300 & bpl == 12
drop if metarea == 45460 & bpl == 18
drop if metarea == 45780 & bpl == 39
drop if metarea == 45820 & bpl == 20
drop if metarea == 45940 & bpl == 34
drop if metarea == 46060 & bpl == 4
drop if metarea == 46220 & bpl == 1
drop if metarea == 46340 & bpl == 48
drop if metarea == 46540 & bpl == 36
drop if metarea == 46660 & bpl == 13
drop if metarea == 46700 & bpl == 6
drop if metarea == 47220 & bpl == 34
drop if metarea == 47260 & bpl == 51
drop if metarea == 47300 & bpl == 6
drop if metarea == 47380 & bpl == 48
drop if metarea == 47900 & bpl == 11 & bpl == 24 & bpl == 51
drop if metarea == 48140 & bpl == 55
drop if metarea == 48300 & bpl == 53
drop if metarea == 48620 & bpl == 20
drop if metarea == 48660 & bpl == 48
drop if metarea == 48700 & bpl == 42
drop if metarea == 48900 & bpl == 37
drop if metarea == 49180 & bpl == 37
drop if metarea == 49340 & bpl == 9 & bpl == 25
drop if metarea == 49420 & bpl == 53
drop if metarea == 49620 & bpl == 42
drop if metarea == 49660 & bpl == 39 & bpl == 42
drop if metarea == 49700 & bpl == 6
drop if metarea == 49740 & bpl == 4
*/

replace share = 0 if metarea == 4 & (  bpl == 4800 )
replace share = 0 if metarea == 8 & (  bpl == 3900 )
replace share = 0 if metarea == 12 & (  bpl == 1300 )
replace share = 0 if metarea == 16 & (  bpl == 3600 )
replace share = 0 if metarea == 20 & (  bpl == 3500 )
replace share = 0 if metarea == 22 & (  bpl == 2200 )
replace share = 0 if metarea == 24 & (  bpl == 3400 | bpl == 4200 )
replace share = 0 if metarea == 28 & (  bpl == 4200 )
replace share = 0 if metarea == 32 & (  bpl == 4800 )
replace share = 0 if metarea == 38 & (  bpl == 200 )
replace share = 0 if metarea == 40 & (  bpl == 1800 )
replace share = 0 if metarea == 44 & (  bpl == 2600 )
replace share = 0 if metarea == 45 & (  bpl == 100 )
replace share = 0 if metarea == 46 & (  bpl == 5500 )
replace share = 0 if metarea == 48 & (  bpl == 3700 )
replace share = 0 if metarea == 50 & (  bpl == 1300 )
replace share = 0 if metarea == 52 & (  bpl == 1300 )
replace share = 0 if metarea == 56 & (  bpl == 3400 )
replace share = 0 if metarea == 58 & (  bpl == 100 )
replace share = 0 if metarea == 60 & (  bpl == 1300 | bpl == 4500 )
replace share = 0 if metarea == 64 & (  bpl == 4800 )
replace share = 0 if metarea == 68 & (  bpl == 600 )
replace share = 0 if metarea == 72 & (  bpl == 2400 )
replace share = 0 if metarea == 74 & (  bpl == 2500 )
replace share = 0 if metarea == 76 & (  bpl == 2200 )
replace share = 0 if metarea == 78 & (  bpl == 2600 )
replace share = 0 if metarea == 84 & (  bpl == 4800 )
replace share = 0 if metarea == 86 & (  bpl == 5300 )
replace share = 0 if metarea == 87 & (  bpl == 2600 )
replace share = 0 if metarea == 88 & (  bpl == 3000 )
replace share = 0 if metarea == 92 & (  bpl == 2800 )
replace share = 0 if metarea == 96 & (  bpl == 3600 )
replace share = 0 if metarea == 100 & (  bpl == 100 )
replace share = 0 if metarea == 102 & (  bpl == 1800 )
replace share = 0 if metarea == 104 & (  bpl == 1700 )
replace share = 0 if metarea == 108 & (  bpl == 1600 )
replace share = 0 if metarea == 112 & (  bpl == 2500  | bpl == 3300 )
replace share = 0 if metarea == 114 & (  bpl == 1200 )
replace share = 0 if metarea == 115 & (  bpl == 5300 )
replace share = 0 if metarea == 116 & (  bpl == 900 )
replace share = 0 if metarea == 120 & (  bpl == 2500 )
replace share = 0 if metarea == 124 & (  bpl == 4800 )
replace share = 0 if metarea == 126 & (  bpl == 4800 )
replace share = 0 if metarea == 128 & (  bpl == 3600 )
replace share = 0 if metarea == 130 & (  bpl == 3700 )
replace share = 0 if metarea == 132 & (  bpl == 3900 )
replace share = 0 if metarea == 136 & (  bpl == 1900 )
replace share = 0 if metarea == 140 & (  bpl == 1700 )
replace share = 0 if metarea == 144 & (  bpl == 4500 )
replace share = 0 if metarea == 148 & (  bpl == 5400 )
replace share = 0 if metarea == 152 & (  bpl == 3700  | bpl == 4500 )
replace share = 0 if metarea == 154 & (  bpl == 5100 )
replace share = 0 if metarea == 156 & (  bpl == 1300  | bpl == 4700 )
replace share = 0 if metarea == 158 & (  bpl == 5600 )
replace share = 0 if metarea == 160 & (  bpl == 1700 )
replace share = 0 if metarea == 162 & (  bpl == 600 )
replace share = 0 if metarea == 164 & (  bpl == 1800  | bpl == 2100  | bpl == 3900 )
replace share = 0 if metarea == 166 & (  bpl == 2100  | bpl == 4700 )
replace share = 0 if metarea == 168 & (  bpl == 3900 )
replace share = 0 if metarea == 172 & (  bpl == 800 )
replace share = 0 if metarea == 174 & (  bpl == 2900 )
replace share = 0 if metarea == 176 & (  bpl == 4500 )
replace share = 0 if metarea == 180 & (  bpl == 100  | bpl == 1300 )
replace share = 0 if metarea == 184 & (  bpl == 3900 )
replace share = 0 if metarea == 188 & (  bpl == 4800 )
replace share = 0 if metarea == 192 & (  bpl == 4800 )
replace share = 0 if metarea == 193 & (  bpl == 900 )
replace share = 0 if metarea == 195 & (  bpl == 5100 )
replace share = 0 if metarea == 196 & (  bpl == 1700  | bpl == 1900 )
replace share = 0 if metarea == 200 & (  bpl == 3900 )
replace share = 0 if metarea == 202 & (  bpl == 1200 )
replace share = 0 if metarea == 203 & (  bpl == 100 )
replace share = 0 if metarea == 204 & (  bpl == 1700 )
replace share = 0 if metarea == 208 & (  bpl == 800 )
replace share = 0 if metarea == 212 & (  bpl == 1900 )
replace share = 0 if metarea == 216 & (  bpl == 2600 )
replace share = 0 if metarea == 218 & (  bpl == 100 )
replace share = 0 if metarea == 219 & (  bpl == 1000 )
replace share = 0 if metarea == 224 & (  bpl == 2700  | bpl == 5500 )
replace share = 0 if metarea == 228 & (  bpl == 3600 )
replace share = 0 if metarea == 229 & (  bpl == 5500 )
replace share = 0 if metarea == 231 & (  bpl == 4800 )
replace share = 0 if metarea == 232 & (  bpl == 1800 )
replace share = 0 if metarea == 236 & (  bpl == 4200 )
replace share = 0 if metarea == 240 & (  bpl == 4100 )
replace share = 0 if metarea == 244 & (  bpl == 1800  | bpl == 2100 )
replace share = 0 if metarea == 252 & (  bpl == 2700  | bpl == 3800 )
replace share = 0 if metarea == 256 & (  bpl == 3700 )
replace share = 0 if metarea == 258 & (  bpl == 500 )
replace share = 0 if metarea == 260 & (  bpl == 2500 )
replace share = 0 if metarea == 262 & (  bpl == 400  | bpl == 4900 )
replace share = 0 if metarea == 264 & (  bpl == 2600 )
replace share = 0 if metarea == 265 & (  bpl == 100 )
replace share = 0 if metarea == 266 & (  bpl == 4500 )
replace share = 0 if metarea == 267 & (  bpl == 800 )
replace share = 0 if metarea == 268 & (  bpl == 1200 )
replace share = 0 if metarea == 270 & (  bpl == 1200 )
replace share = 0 if metarea == 271 & (  bpl == 1200 )
replace share = 0 if metarea == 272 & (  bpl == 500  | bpl == 4000 )
replace share = 0 if metarea == 275 & (  bpl == 1200 )
replace share = 0 if metarea == 276 & (  bpl == 1800 )
replace share = 0 if metarea == 284 & (  bpl == 600 )
replace share = 0 if metarea == 288 & (  bpl == 100 )
replace share = 0 if metarea == 290 & (  bpl == 1200 )
replace share = 0 if metarea == 292 & (  bpl == 4800 )
replace share = 0 if metarea == 297 & (  bpl == 3600 )
replace share = 0 if metarea == 298 & (  bpl == 3700 )
replace share = 0 if metarea == 300 & (  bpl == 2600 )
replace share = 0 if metarea == 301 & (  bpl == 800 )
replace share = 0 if metarea == 304 & (  bpl == 3000 )
replace share = 0 if metarea == 306 & (  bpl == 800 )
replace share = 0 if metarea == 308 & (  bpl == 5500 )
replace share = 0 if metarea == 312 & (  bpl == 3700 )
replace share = 0 if metarea == 315 & (  bpl == 3700 )
replace share = 0 if metarea == 316 & (  bpl == 4500 )
replace share = 0 if metarea == 318 & (  bpl == 2400 )
replace share = 0 if metarea == 320 & (  bpl == 3900 )
replace share = 0 if metarea == 324 & (  bpl == 4200 )
replace share = 0 if metarea == 328 & (  bpl == 900 )
replace share = 0 if metarea == 329 & (  bpl == 3700 )
replace share = 0 if metarea == 330 & (  bpl == 2800 )
replace share = 0 if metarea == 332 & (  bpl == 1500 )
replace share = 0 if metarea == 335 & (  bpl == 2200 )
replace share = 0 if metarea == 336 & (  bpl == 4800 )
replace share = 0 if metarea == 340 & (  bpl == 2100  | bpl == 3900  | bpl == 5400 )
replace share = 0 if metarea == 344 & (  bpl == 100 )
replace share = 0 if metarea == 348 & (  bpl == 1800 )
replace share = 0 if metarea == 350 & (  bpl == 1900 )
replace share = 0 if metarea == 352 & (  bpl == 2600 )
replace share = 0 if metarea == 356 & (  bpl == 2800 )
replace share = 0 if metarea == 358 & (  bpl == 4700 )
replace share = 0 if metarea == 359 & (  bpl == 1200 )
replace share = 0 if metarea == 360 & (  bpl == 3700 )
replace share = 0 if metarea == 361 & (  bpl == 3600 )
replace share = 0 if metarea == 362 & (  bpl == 5500 )
replace share = 0 if metarea == 366 & (  bpl == 3700  | bpl == 4700 | bpl == 5400 )
replace share = 0 if metarea == 368 & (  bpl == 4200 )
replace share = 0 if metarea == 371 & (  bpl == 2900 )
replace share = 0 if metarea == 372 & (  bpl == 2600 )
replace share = 0 if metarea == 374 & (  bpl == 1700 )
replace share = 0 if metarea == 376 & (  bpl == 2000  | bpl == 2900 )
replace share = 0 if metarea == 380 & (  bpl == 5500 )
replace share = 0 if metarea == 381 & (  bpl == 4800 )
replace share = 0 if metarea == 384 & (  bpl == 4700 )
replace share = 0 if metarea == 385 & (  bpl == 1800 )
replace share = 0 if metarea == 387 & (  bpl == 5500 )
replace share = 0 if metarea == 388 & (  bpl == 2200 )
replace share = 0 if metarea == 392 & (  bpl == 1800 )
replace share = 0 if metarea == 396 & (  bpl == 2200 )
replace share = 0 if metarea == 398 & (  bpl == 1200 )
replace share = 0 if metarea == 400 & (  bpl == 4200 )
replace share = 0 if metarea == 404 & (  bpl == 2600 )
replace share = 0 if metarea == 408 & (  bpl == 4800 )
replace share = 0 if metarea == 410 & (  bpl == 3500 )
replace share = 0 if metarea == 412 & (  bpl == 3200 )
replace share = 0 if metarea == 420 & (  bpl == 4000 )
replace share = 0 if metarea == 428 & (  bpl == 2100 )
replace share = 0 if metarea == 432 & (  bpl == 3900 )
replace share = 0 if metarea == 436 & (  bpl == 3100 )
replace share = 0 if metarea == 440 & (  bpl == 200 )
replace share = 0 if metarea == 441 & (  bpl == 3400 )
replace share = 0 if metarea == 442 & (  bpl == 4800 )
replace share = 0 if metarea == 444 & (  bpl == 3900 )
replace share = 0 if metarea == 448 & (  bpl == 600 )
replace share = 0 if metarea == 452 & (  bpl == 1800  | bpl == 2100 )
replace share = 0 if metarea == 460 & (  bpl == 4800 )
replace share = 0 if metarea == 464 & (  bpl == 5100 )
replace share = 0 if metarea == 468 & (  bpl == 1300 )
replace share = 0 if metarea == 472 & (  bpl == 5500 )
replace share = 0 if metarea == 476 & (  bpl == 3300 )
replace share = 0 if metarea == 480 & (  bpl == 3900 )
replace share = 0 if metarea == 488 & (  bpl == 4800 )
replace share = 0 if metarea == 489 & (  bpl == 4100 )
replace share = 0 if metarea == 490 & (  bpl == 1200 )
replace share = 0 if metarea == 492 & (  bpl == 500  | bpl == 2800  | bpl == 4700 )
replace share = 0 if metarea == 494 & (  bpl == 600 )
replace share = 0 if metarea == 500 & (  bpl == 1200 )
replace share = 0 if metarea == 504 & (  bpl == 4800 )
replace share = 0 if metarea == 508 & (  bpl == 5500 )
replace share = 0 if metarea == 512 & (  bpl == 2700 )
replace share = 0 if metarea == 514 & (  bpl == 3000 )
replace share = 0 if metarea == 516 & (  bpl == 100 )
replace share = 0 if metarea == 517 & (  bpl == 600 )
replace share = 0 if metarea == 519 & (  bpl == 3400 )
replace share = 0 if metarea == 520 & (  bpl == 2200 )
replace share = 0 if metarea == 524 & (  bpl == 100 )
replace share = 0 if metarea == 528 & (  bpl == 1800 )
replace share = 0 if metarea == 532 & ( bpl == 2600 )
replace share = 0 if metarea == 533 & (  bpl == 4500 )
replace share = 0 if metarea == 534 & (  bpl == 1200 )
replace share = 0 if metarea == 535 & (  bpl == 3300 )
replace share = 0 if metarea == 536 & (  bpl == 4700 )
replace share = 0 if metarea == 540 & (  bpl == 2500 )
replace share = 0 if metarea == 546 & (  bpl == 3400 | bpl == 3600 )
replace share = 0 if metarea == 548 & (  bpl == 900 )
replace share = 0 if metarea == 552 & (  bpl == 900 | bpl == 4400 )
replace share = 0 if metarea == 556 & (  bpl == 2200 )
replace share = 0 if metarea == 560 & (  bpl == 3400 )
replace share = 0 if metarea == 564 & (  bpl == 3900 )
replace share = 0 if metarea == 566 & (  bpl == 3600 )
replace share = 0 if metarea == 572 & (  bpl == 5100 )
replace share = 0 if metarea == 576 & (  bpl == 900 )
replace share = 0 if metarea == 579 & (  bpl == 1200 )
replace share = 0 if metarea == 580 & (  bpl == 4800 )
replace share = 0 if metarea == 588 & (  bpl == 4000 )
replace share = 0 if metarea == 591 & (  bpl == 5300 )
replace share = 0 if metarea == 592 & (  bpl == 1900 | bpl == 3100 )
replace share = 0 if metarea == 595 & (  bpl == 3600 )
replace share = 0 if metarea == 596 & (  bpl == 1200 )
replace share = 0 if metarea == 601 & (  bpl == 1200 )
replace share = 0 if metarea == 603 & (  bpl == 2800 )
replace share = 0 if metarea == 608 & (  bpl == 1200 )
replace share = 0 if metarea == 612 & (  bpl == 1700 )
replace share = 0 if metarea == 616 & (  bpl == 3400 |  bpl == 4200 )
replace share = 0 if metarea == 620 & (  bpl == 400 )
replace share = 0 if metarea == 628 & (  bpl == 4200 )
replace share = 0 if metarea == 640 & (  bpl == 2300 )
replace share = 0 if metarea == 644 & (  bpl == 4100 |  bpl == 5300 )
replace share = 0 if metarea == 645 & (  bpl == 2300 |  bpl == 3300 )
replace share = 0 if metarea == 648 & (  bpl == 2500 |  bpl == 4400 )
replace share = 0 if metarea == 652 & (  bpl == 4900 )
replace share = 0 if metarea == 656 & (  bpl == 800 )
replace share = 0 if metarea == 658 & (  bpl == 1200 )
replace share = 0 if metarea == 660 & (  bpl == 5500 )
replace share = 0 if metarea == 664 & (  bpl == 3700 )
replace share = 0 if metarea == 668 & (  bpl == 4200 )
replace share = 0 if metarea == 669 & (  bpl == 600 )
replace share = 0 if metarea == 672 & (  bpl == 3200 )
replace share = 0 if metarea == 674 & (  bpl == 5300 )
replace share = 0 if metarea == 676 & (  bpl == 5100 )
replace share = 0 if metarea == 678 & (  bpl == 600 )
replace share = 0 if metarea == 680 & (  bpl == 5100 )
replace share = 0 if metarea == 682 & (  bpl == 2700 )
replace share = 0 if metarea == 684 & (  bpl == 3600 )
replace share = 0 if metarea == 688 & (  bpl == 1700 )
replace share = 0 if metarea == 689 & (  bpl == 3700 )
replace share = 0 if metarea == 692 & (  bpl == 600 )
replace share = 0 if metarea == 696 & (  bpl == 2600 )
replace share = 0 if metarea == 698 & (  bpl == 2700 )
replace share = 0 if metarea == 700 & (  bpl == 2900 )
replace share = 0 if metarea == 704 & (  bpl == 1700  | bpl == 2900 )
replace share = 0 if metarea == 708 & (  bpl == 4100 )
replace share = 0 if metarea == 712 & (  bpl == 600 )
replace share = 0 if metarea == 714 & (  bpl == 3700 )
replace share = 0 if metarea == 716 & (  bpl == 4900 )
replace share = 0 if metarea == 724 & (  bpl == 4800 )
replace share = 0 if metarea == 732 & (  bpl == 600 )
replace share = 0 if metarea == 736 & (  bpl == 600 )
replace share = 0 if metarea == 740 & (  bpl == 600 )
replace share = 0 if metarea == 746 & (  bpl == 600 )
replace share = 0 if metarea == 747 & (  bpl == 600 )
replace share = 0 if metarea == 748 & (  bpl == 600 )
replace share = 0 if metarea == 749 & (  bpl == 3500 )
replace share = 0 if metarea == 750 & (  bpl == 600 )
replace share = 0 if metarea == 751 & (  bpl == 1200 )
replace share = 0 if metarea == 752 & (  bpl == 1300 )
replace share = 0 if metarea == 756 & (  bpl == 4200 )
replace share = 0 if metarea == 760 & (  bpl == 5300 )
replace share = 0 if metarea == 761 & (  bpl == 4200 )
replace share = 0 if metarea == 762 & (  bpl == 5500 )
replace share = 0 if metarea == 768 & (  bpl == 2200 )
replace share = 0 if metarea == 772 & (  bpl == 1900  | bpl == 3100 )
replace share = 0 if metarea == 776 & (  bpl == 4600 )
replace share = 0 if metarea == 780 & (  bpl == 1800 )
replace share = 0 if metarea == 784 & (  bpl == 5300 )
replace share = 0 if metarea == 788 & (  bpl == 1700 )
replace share = 0 if metarea == 792 & (  bpl == 2900 )
replace share = 0 if metarea == 800 & (  bpl == 2500 )
replace share = 0 if metarea == 804 & (  bpl == 900 )
replace share = 0 if metarea == 805 & (  bpl == 4200 )
replace share = 0 if metarea == 812 & (  bpl == 600 )
replace share = 0 if metarea == 814 & (  bpl == 4500 )
replace share = 0 if metarea == 816 & (  bpl == 3600 )
replace share = 0 if metarea == 820 & (  bpl == 5300 )
replace share = 0 if metarea == 824 & (  bpl == 1200 )
replace share = 0 if metarea == 828 & (  bpl == 1200 )
replace share = 0 if metarea == 832 & (  bpl == 1800 )
replace share = 0 if metarea == 840 & (  bpl == 2600  | bpl == 3900 )
replace share = 0 if metarea == 844 & (  bpl == 2000 )
replace share = 0 if metarea == 848 & (  bpl == 3400 )
replace share = 0 if metarea == 852 & (  bpl == 400 )
replace share = 0 if metarea == 856 & (  bpl == 4000 )
replace share = 0 if metarea == 860 & (  bpl == 100 )
replace share = 0 if metarea == 864 & (  bpl == 4800 )
replace share = 0 if metarea == 868 & (  bpl == 3600 )
replace share = 0 if metarea == 873 & (  bpl == 600 )
replace share = 0 if metarea == 876 & (  bpl == 3400 )
replace share = 0 if metarea == 878 & (  bpl == 600 )
replace share = 0 if metarea == 880 & (  bpl == 4800 )
replace share = 0 if metarea == 884 & (  bpl == 1100 |  bpl == 2400 |  bpl == 5100 )
replace share = 0 if metarea == 888 & (  bpl == 900 )
replace share = 0 if metarea == 892 & (  bpl == 1900 )
replace share = 0 if metarea == 894 & (  bpl == 5500 )
replace share = 0 if metarea == 896 & (  bpl == 1200 )
replace share = 0 if metarea == 904 & (  bpl == 2000 )
replace share = 0 if metarea == 908 & (  bpl == 4800 )
replace share = 0 if metarea == 914 & (  bpl == 4200 )
replace share = 0 if metarea == 916 & (  bpl == 1000  | bpl == 2400  | bpl == 3400 )
replace share = 0 if metarea == 920 & (  bpl == 3700 )
replace share = 0 if metarea == 924 & (  bpl == 2500 )
replace share = 0 if metarea == 926 & (  bpl == 5300 )
replace share = 0 if metarea == 927 & (  bpl == 600 )
replace share = 0 if metarea == 928 & (  bpl == 4200 )
replace share = 0 if metarea == 932 & (  bpl == 3900  | bpl == 4200 )
replace share = 0 if metarea == 934 & (  bpl == 600 )
replace share = 0 if metarea == 936 & (  bpl == 400 )

replace share = 0 if metarea == 10420 & (  bpl == 3900 )
replace share = 0 if metarea == 10580 & (  bpl == 3600 )
replace share = 0 if metarea == 10740 & (  bpl == 3500 )
replace share = 0 if metarea == 10780 & (  bpl == 2200 )
replace share = 0 if metarea == 10900 & (  bpl == 3400 | bpl == 4200 )
replace share = 0 if metarea == 11020 & (  bpl == 4200 )
replace share = 0 if metarea == 11100 & (  bpl == 4800 )
replace share = 0 if metarea == 11460 & (  bpl == 2600 )
replace share = 0 if metarea == 11500 & (  bpl == 100 )
replace share = 0 if metarea == 11700 & (  bpl == 3700 )
replace share = 0 if metarea == 12020 & (  bpl == 1300 )
replace share = 0 if metarea == 12060 & (  bpl == 1300 )
replace share = 0 if metarea == 12100 & (  bpl == 3400 )
replace share = 0 if metarea == 12220 & (  bpl == 100 )
replace share = 0 if metarea == 12260 & (  bpl == 1300 | bpl == 4500 )
replace share = 0 if metarea == 12420 & (  bpl == 4800 )
replace share = 0 if metarea == 12540 & (  bpl == 600 )
replace share = 0 if metarea == 12580 & (  bpl == 2400 )
replace share = 0 if metarea == 12620 & (  bpl == 2300 )
replace share = 0 if metarea == 12700 & (  bpl == 2500 )
replace share = 0 if metarea == 12940 & (  bpl == 2200 )
replace share = 0 if metarea == 12980 & (  bpl == 2600 )
replace share = 0 if metarea == 13140 & (  bpl == 4800 )
replace share = 0 if metarea == 13380 & (  bpl == 5300 )
replace share = 0 if metarea == 13460 & (  bpl == 4100 )
replace share = 0 if metarea == 13740 & (  bpl == 3000 )
replace share = 0 if metarea == 13780 & (  bpl == 3600 )
replace share = 0 if metarea == 13820 & (  bpl == 100 )
replace share = 0 if metarea == 13900 & (  bpl == 3800 )
replace share = 0 if metarea == 13980 & (  bpl == 5100 )
replace share = 0 if metarea == 14010 & (  bpl == 1700 )
replace share = 0 if metarea == 14020 & (  bpl == 1800 )
replace share = 0 if metarea == 14260 & (  bpl == 1600 )
replace share = 0 if metarea == 14460 & (  bpl == 2500 | bpl == 3300 )
replace share = 0 if metarea == 14740 & (  bpl == 5300 )
replace share = 0 if metarea == 14860 & (  bpl == 900 )
replace share = 0 if metarea == 15180 & (  bpl == 4800 )
replace share = 0 if metarea == 15380 & (  bpl == 3600 )
replace share = 0 if metarea == 15500 & (  bpl == 3700 )
replace share = 0 if metarea == 15540 & (  bpl == 5000 )
replace share = 0 if metarea == 15940 & (  bpl == 3900 )
replace share = 0 if metarea == 15980 & (  bpl == 1200 )
replace share = 0 if metarea == 16580 & (  bpl == 1700 )
replace share = 0 if metarea == 16620 & (  bpl == 5400 )
replace share = 0 if metarea == 16700 & (  bpl == 4500 )
replace share = 0 if metarea == 16740 & (  bpl == 3700 )
replace share = 0 if metarea == 16820 & (  bpl == 5100 )
replace share = 0 if metarea == 16860 & (  bpl == 1300 | bpl == 4700 )
replace share = 0 if metarea == 16980 & (  bpl == 1700 | bpl == 1800 )
replace share = 0 if metarea == 17020 & (  bpl == 600 )
replace share = 0 if metarea == 17140 & (  bpl == 1800 | bpl == 2100 | bpl == 3900 )
replace share = 0 if metarea == 17300 & (  bpl == 2100 | bpl == 4700 )
replace share = 0 if metarea == 17460 & (  bpl == 3900 )
replace share = 0 if metarea == 17660 & (  bpl == 1600 )
replace share = 0 if metarea == 17780 & (  bpl == 4800 )
replace share = 0 if metarea == 17820 & (  bpl == 800 )
replace share = 0 if metarea == 17860 & (  bpl == 2900 )
replace share = 0 if metarea == 17900 & (  bpl == 4500 )
replace share = 0 if metarea == 18140 & (  bpl == 3900 )
replace share = 0 if metarea == 18580 & (  bpl == 4800 )
replace share = 0 if metarea == 19100 & (  bpl == 4800 )
replace share = 0 if metarea == 19300 & (  bpl == 100 )
replace share = 0 if metarea == 19340 & (  bpl == 1900 )
replace share = 0 if metarea == 19380 & (  bpl == 3900 )
replace share = 0 if metarea == 19460 & (  bpl == 100 )
replace share = 0 if metarea == 19500 & (  bpl == 1700 )
replace share = 0 if metarea == 19660 & (  bpl == 1200 )
replace share = 0 if metarea == 19740 & (  bpl == 800 )
replace share = 0 if metarea == 19780 & (  bpl == 1900 )
replace share = 0 if metarea == 19820 & (  bpl == 2600 )
replace share = 0 if metarea == 20100 & (  bpl == 1000 )
replace share = 0 if metarea == 20500 & (  bpl == 3700 )
replace share = 0 if metarea == 20700 & (  bpl == 4200 )
replace share = 0 if metarea == 20740 & (  bpl == 5500 )
replace share = 0 if metarea == 20940 & (  bpl == 600 )
replace share = 0 if metarea == 21060 & (  bpl == 2100 )
replace share = 0 if metarea == 21140 & (  bpl == 1800 )
replace share = 0 if metarea == 21340 & (  bpl == 4800 )
replace share = 0 if metarea == 21500 & (  bpl == 4200 )
replace share = 0 if metarea == 21660 & (  bpl == 4100 )
replace share = 0 if metarea == 21780 & (  bpl == 1800 | bpl == 2100 )
replace share = 0 if metarea == 22140 & (  bpl == 3500 )
replace share = 0 if metarea == 22180 & (  bpl == 3700 )
replace share = 0 if metarea == 22220 & (  bpl == 200 )
replace share = 0 if metarea == 22380 & (  bpl == 400 )
replace share = 0 if metarea == 22420 & (  bpl == 2600 )
replace share = 0 if metarea == 22500 & (  bpl == 4500 )
replace share = 0 if metarea == 22520 & (  bpl == 100 )
replace share = 0 if metarea == 22660 & (  bpl == 800 )
replace share = 0 if metarea == 23060 & (  bpl == 1800 )
replace share = 0 if metarea == 23420 & (  bpl == 600 )
replace share = 0 if metarea == 23460 & (  bpl == 100 )
replace share = 0 if metarea == 23540 & (  bpl == 1200 )
replace share = 0 if metarea == 23580 & (  bpl == 1300 )
replace share = 0 if metarea == 24020 & (  bpl == 3600 )
replace share = 0 if metarea == 24140 & (  bpl == 3700 )
replace share = 0 if metarea == 24300 & (  bpl == 800 )
replace share = 0 if metarea == 24340 & (  bpl == 2600 )
replace share = 0 if metarea == 24540 & (  bpl == 800 )
replace share = 0 if metarea == 24660 & (  bpl == 3700 )
replace share = 0 if metarea == 24780 & (  bpl == 3700 )
replace share = 0 if metarea == 24860 & (  bpl == 4500 )
replace share = 0 if metarea == 25060 & (  bpl == 2800 )
replace share = 0 if metarea == 25220 & (  bpl == 2200 )
replace share = 0 if metarea == 25260 & (  bpl == 600 )
replace share = 0 if metarea == 25420 & (  bpl == 4200 )
replace share = 0 if metarea == 25500 & (  bpl == 5100 )
replace share = 0 if metarea == 25540 & (  bpl == 900 )
replace share = 0 if metarea == 25620 & (  bpl == 2800 )
replace share = 0 if metarea == 25860 & (  bpl == 3700 )
replace share = 0 if metarea == 25940 & (  bpl == 4500 )
replace share = 0 if metarea == 26140 & (  bpl == 1200 )
replace share = 0 if metarea == 26380 & (  bpl == 2200 )
replace share = 0 if metarea == 26420 & (  bpl == 4800 )
replace share = 0 if metarea == 26620 & (  bpl == 100 )
replace share = 0 if metarea == 26900 & (  bpl == 1800 )
replace share = 0 if metarea == 26980 & (  bpl == 1900 )
replace share = 0 if metarea == 27060 & (  bpl == 3600 )
replace share = 0 if metarea == 27100 & (  bpl == 2600 )
replace share = 0 if metarea == 27140 & (  bpl == 2800 )
replace share = 0 if metarea == 27180 & (  bpl == 4700 )
replace share = 0 if metarea == 27260 & (  bpl == 1200 )
replace share = 0 if metarea == 27340 & (  bpl == 3700 )
replace share = 0 if metarea == 27500 & (  bpl == 5500 )
replace share = 0 if metarea == 27620 & (  bpl == 2900 )
replace share = 0 if metarea == 27780 & (  bpl == 4200 )
replace share = 0 if metarea == 27900 & (  bpl == 2900 )
replace share = 0 if metarea == 28020 & (  bpl == 2600 )
replace share = 0 if metarea == 28100 & (  bpl == 1700 )
replace share = 0 if metarea == 28140 & (  bpl == 2000 | bpl == 2900 )
replace share = 0 if metarea == 28420 & (  bpl == 5300 )
replace share = 0 if metarea == 28660 & (  bpl == 4800 )
replace share = 0 if metarea == 28700 & (  bpl == 4700 | bpl == 5100 )
replace share = 0 if metarea == 28940 & (  bpl == 4700 )
replace share = 0 if metarea == 29100 & (  bpl == 2700 | bpl == 5500 )
replace share = 0 if metarea == 29180 & (  bpl == 2200 )
replace share = 0 if metarea == 29200 & (  bpl == 1800 )
replace share = 0 if metarea == 29340 & (  bpl == 2200 )
replace share = 0 if metarea == 29420 & (  bpl == 400 )
replace share = 0 if metarea == 29460 & (  bpl == 1200 )
replace share = 0 if metarea == 29540 & (  bpl == 4200 )
replace share = 0 if metarea == 29620 & (  bpl == 2600 )
replace share = 0 if metarea == 29700 & (  bpl == 4800 )
replace share = 0 if metarea == 29740 & (  bpl == 3500 )
replace share = 0 if metarea == 29820 & (  bpl == 3200 )
replace share = 0 if metarea == 29940 & (  bpl == 2000 )
replace share = 0 if metarea == 30140 & (  bpl == 4200 )
replace share = 0 if metarea == 30340 & (  bpl == 2300 )
replace share = 0 if metarea == 30620 & (  bpl == 3900 )
replace share = 0 if metarea == 30700 & (  bpl == 3100 )
replace share = 0 if metarea == 30780 & (  bpl == 200 )
replace share = 0 if metarea == 31080 & (  bpl == 600 )
replace share = 0 if metarea == 31140 & (  bpl == 2100 )
replace share = 0 if metarea == 31180 & (  bpl == 4800 )
replace share = 0 if metarea == 31340 & (  bpl == 5100 )
replace share = 0 if metarea == 31460 & (  bpl == 600 )
replace share = 0 if metarea == 31700 & (  bpl == 3300 )
replace share = 0 if metarea == 31900 & (  bpl == 3900 )
replace share = 0 if metarea == 32580 & (  bpl == 4800 )
replace share = 0 if metarea == 32780 & (  bpl == 4100 )
replace share = 0 if metarea == 32820 & (  bpl == 500 | bpl == 2800 | bpl == 4700 )
replace share = 0 if metarea == 32900 & (  bpl == 600 )
replace share = 0 if metarea == 33100 & (  bpl == 1200 )
replace share = 0 if metarea == 33140 & (  bpl == 1800 )
replace share = 0 if metarea == 33260 & (  bpl == 4800 )
replace share = 0 if metarea == 33340 & (  bpl == 5500 )
replace share = 0 if metarea == 33460 & (  bpl == 2700 )
replace share = 0 if metarea == 33660 & (  bpl == 100 )
replace share = 0 if metarea == 33700 & (  bpl == 600 )
replace share = 0 if metarea == 33740 & (  bpl == 2200 )
replace share = 0 if metarea == 33780 & (  bpl == 2600 )
replace share = 0 if metarea == 33860 & (  bpl == 100 )
replace share = 0 if metarea == 34060 & (  bpl == 5400 )
replace share = 0 if metarea == 34620 & (  bpl == 1800 )
replace share = 0 if metarea == 34740 & (  bpl == 2600 )
replace share = 0 if metarea == 34820 & (  bpl == 4500 )
replace share = 0 if metarea == 34900 & (  bpl == 600 )
replace share = 0 if metarea == 34940 & (  bpl == 1200 )
replace share = 0 if metarea == 34980 & (  bpl == 4700 )
replace share = 0 if metarea == 35300 & (  bpl == 900 )
replace share = 0 if metarea == 35380 & (  bpl == 2200 )
replace share = 0 if metarea == 35620 & (  bpl == 3600 )
replace share = 0 if metarea == 35660 & (  bpl == 2600 )
replace share = 0 if metarea == 35840 & (  bpl == 1200 )
replace share = 0 if metarea == 35980 & (  bpl == 900 )
replace share = 0 if metarea == 36100 & (  bpl == 1200 )
replace share = 0 if metarea == 36140 & (  bpl == 3400 )
replace share = 0 if metarea == 36220 & (  bpl == 4800 )
replace share = 0 if metarea == 36260 & (  bpl == 4900 )
replace share = 0 if metarea == 36420 & (  bpl == 4000 )
replace share = 0 if metarea == 36500 & (  bpl == 5300 )
replace share = 0 if metarea == 36540 & (  bpl == 1900 | bpl == 3100 )
replace share = 0 if metarea == 36740 & (  bpl == 1200 )
replace share = 0 if metarea == 36780 & (  bpl == 5500 )
replace share = 0 if metarea == 36980 & (  bpl == 2100 )
replace share = 0 if metarea == 37100 & (  bpl == 600 )
replace share = 0 if metarea == 37340 & (  bpl == 1200 )
replace share = 0 if metarea == 37460 & (  bpl == 1200 )
replace share = 0 if metarea == 37620 & (  bpl == 5400 )
replace share = 0 if metarea == 37860 & (  bpl == 1200 )
replace share = 0 if metarea == 37900 & (  bpl == 1700 )
replace share = 0 if metarea == 37980 & (  bpl == 3400 | bpl == 4200 )
replace share = 0 if metarea == 38060 & (  bpl == 400 )
replace share = 0 if metarea == 38300 & (  bpl == 4200 )
replace share = 0 if metarea == 38340 & (  bpl == 2500 )
replace share = 0 if metarea == 38860 & (  bpl == 2300 )
replace share = 0 if metarea == 38900 & (  bpl == 4100 )
replace share = 0 if metarea == 38940 & (  bpl == 1200 )
replace share = 0 if metarea == 39140 & (  bpl == 400 )
replace share = 0 if metarea == 39300 & (  bpl == 2500 | bpl == 4400 )
replace share = 0 if metarea == 39340 & (  bpl == 4900 )
replace share = 0 if metarea == 39380 & (  bpl == 800 )
replace share = 0 if metarea == 39460 & (  bpl == 1200 )
replace share = 0 if metarea == 39540 & (  bpl == 5500 )
replace share = 0 if metarea == 39580 & (  bpl == 3700 )
replace share = 0 if metarea == 39740 & (  bpl == 4200 )
replace share = 0 if metarea == 39820 & (  bpl == 600 )
replace share = 0 if metarea == 39900 & (  bpl == 3200 )
replace share = 0 if metarea == 40060 & (  bpl == 5100 )
replace share = 0 if metarea == 40140 & (  bpl == 600 )
replace share = 0 if metarea == 40220 & (  bpl == 5100 )
replace share = 0 if metarea == 40380 & (  bpl == 3600 )
replace share = 0 if metarea == 40420 & (  bpl == 1700 )
replace share = 0 if metarea == 40580 & (  bpl == 3700 )
replace share = 0 if metarea == 40900 & (  bpl == 600 )
replace share = 0 if metarea == 40980 & (  bpl == 2600 )
replace share = 0 if metarea == 41060 & (  bpl == 2700 )
replace share = 0 if metarea == 41100 & (  bpl == 4900 )
replace share = 0 if metarea == 41140 & (  bpl == 2000 | bpl == 2900 )
replace share = 0 if metarea == 41180 & (  bpl == 1700 | bpl == 2900 )
replace share = 0 if metarea == 41500 & (  bpl == 600 )
replace share = 0 if metarea == 41540 & (  bpl == 1000 | bpl == 2400 )
replace share = 0 if metarea == 41620 & (  bpl == 4900 )
replace share = 0 if metarea == 41660 & (  bpl == 4800 )
replace share = 0 if metarea == 41700 & (  bpl == 4800 )
replace share = 0 if metarea == 41740 & (  bpl == 600 )
replace share = 0 if metarea == 41860 & (  bpl == 600 )
replace share = 0 if metarea == 41940 & (  bpl == 600 )
replace share = 0 if metarea == 42020 & (  bpl == 600 )
replace share = 0 if metarea == 42100 & (  bpl == 600 )
replace share = 0 if metarea == 42140 & (  bpl == 3500 )
replace share = 0 if metarea == 42200 & (  bpl == 600 )
replace share = 0 if metarea == 42220 & (  bpl == 600 )
replace share = 0 if metarea == 42540 & (  bpl == 4200 )
replace share = 0 if metarea == 42660 & (  bpl == 5300 )
replace share = 0 if metarea == 42680 & (  bpl == 1200 )
replace share = 0 if metarea == 43100 & (  bpl == 5500 )
replace share = 0 if metarea == 43340 & (  bpl == 2200 )
replace share = 0 if metarea == 43900 & (  bpl == 4500 )
replace share = 0 if metarea == 44060 & (  bpl == 5300 )
replace share = 0 if metarea == 44100 & (  bpl == 1700 )
replace share = 0 if metarea == 44140 & (  bpl == 2500 )
replace share = 0 if metarea == 44180 & (  bpl == 2900 )
replace share = 0 if metarea == 44220 & (  bpl == 3900 )
replace share = 0 if metarea == 44300 & (  bpl == 4200 )
replace share = 0 if metarea == 44700 & (  bpl == 600 )
replace share = 0 if metarea == 44940 & (  bpl == 4500 )
replace share = 0 if metarea == 45060 & (  bpl == 3600 )
replace share = 0 if metarea == 45220 & (  bpl == 1200 )
replace share = 0 if metarea == 45300 & (  bpl == 1200 )
replace share = 0 if metarea == 45460 & (  bpl == 1800 )
replace share = 0 if metarea == 45780 & (  bpl == 3900 )
replace share = 0 if metarea == 45820 & (  bpl == 2000 )
replace share = 0 if metarea == 45940 & (  bpl == 3400 )
replace share = 0 if metarea == 46060 & (  bpl == 400 )
replace share = 0 if metarea == 46220 & (  bpl == 100 )
replace share = 0 if metarea == 46340 & (  bpl == 4800 )
replace share = 0 if metarea == 46540 & (  bpl == 3600 )
replace share = 0 if metarea == 46660 & (  bpl == 1300 )
replace share = 0 if metarea == 46700 & (  bpl == 600 )
replace share = 0 if metarea == 47220 & (  bpl == 3400 )
replace share = 0 if metarea == 47260 & (  bpl == 5100 )
replace share = 0 if metarea == 47300 & (  bpl == 600 )
replace share = 0 if metarea == 47380 & (  bpl == 4800 )
replace share = 0 if metarea == 47900 & (  bpl == 1100 | bpl == 2400 | bpl == 5100 )
replace share = 0 if metarea == 48140 & (  bpl == 5500 )
replace share = 0 if metarea == 48300 & (  bpl == 5300 )
replace share = 0 if metarea == 48620 & (  bpl == 2000 )
replace share = 0 if metarea == 48660 & (  bpl == 4800 )
replace share = 0 if metarea == 48700 & (  bpl == 4200 )
replace share = 0 if metarea == 48900 & (  bpl == 3700 )
replace share = 0 if metarea == 49180 & (  bpl == 3700 )
replace share = 0 if metarea == 49340 & (  bpl == 900 | bpl == 2500 )
replace share = 0 if metarea == 49420 & (  bpl == 5300 )
replace share = 0 if metarea == 49620 & (  bpl == 4200 )
replace share = 0 if metarea == 49660 & (  bpl == 3900 | bpl == 4200 )
replace share = 0 if metarea == 49700 & (  bpl == 600 )
replace share = 0 if metarea == 49740 & (  bpl == 400 )


replace share = 0 if metarea == 646 & (  bpl == 3600 )
replace share = 0 if metarea == 101 & (  bpl == 3800 )
replace share = 0 if metarea == 632 & (  bpl == 2500 )
replace share = 0 if metarea == 440 & (  bpl == 500 )
replace share = 0 if metarea == 30780 & (  bpl == 500 )
replace share = 0 if metarea == 131 & (  bpl == 5000 )
replace share = 0 if metarea == 808 & (  bpl == 3900 )
replace share = 0 if metarea == 560 & (  bpl == 3600 )
replace share = 0 if metarea == 190 & (  bpl == 2400 )
replace share = 0 if metarea == 602 & (  bpl == 5400 )
replace share = 0 if metarea == 836 & (  bpl == 4800 )
replace share = 0 if metarea == 900 & (  bpl == 5400 )
replace share = 0 if metarea == 22220 & (  bpl == 500 )
replace share = 0 if metarea == 900 & (  bpl == 3900 )
replace share = 0 if metarea == 36140 & (  bpl == 4200 )
replace share = 0 if metarea == 535 & (  bpl == 2500 )

replace share = 0 if metarea == 836 & (  bpl == 500 )
replace share = 0 if metarea == 602 & (  bpl == 3900 )

replace share = 0 if metarea == 39900 & (  bpl == 600 )
replace share = 0 if metarea == 31700 & (  bpl == 2500 )


rename bpl statefips

//replace share = 0 count sumcity

save weights, replace

