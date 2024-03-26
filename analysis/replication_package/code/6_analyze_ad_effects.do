clear all


// 	Experimental conditions:
// 	1 - lostgirls_genre.jpg
// 	2 - lostgirls_noinfo.jpg
// 	3 - lostgirls_price.jpg
// 	4 - stateline_genre.jpg
// 	5 - stateline_noinfo.jpg
// 	6 - stateline_price.jpg


program main

	* Advertising effect estimates *
	forvalues i = 0/1 {
		
		global controls = `i'

		* Main text *
		ate_all_ads_summary
		ate_match_value
		ate_spillovers_info_ads_pool
		
		
		* Appendix *
		ate_both_books
		ate_match_price

	}
	
	* Additional analyses *
	value_of_targeting
	ate_general_search
	
end

* Table 1 and Table A8
program ate_all_ads_summary

	use "../output/dataset_merged.dta", clear
	
	matrix TABLE = J(18,6,.)
	
	if $controls == 1 {
		local demographics "i.fantasy_rank i.mystery_rank i.romance_rank i.scifi_rank female black hispanic age_years married divorced bachelor master some_college income1 income2 income3 income4 income5 income6 i.ebooks i.printbooks"
		}

	* Part I: Lost Girls ATE different ads *
	use "../output/dataset_merged.dta", clear
	gen ad_plain = (ad_condition == 2 | ad_condition == 5)
	gen ad_genre = (ad_condition == 1 | ad_condition == 4)
	gen ad_price = (ad_condition == 3 | ad_condition == 6)
	scalar col = 1
	scalar row = 2
	foreach outcome_variable in "clicked_203" "purchased_203" {
		reg `outcome_variable' ad_plain ad_genre ad_price `demographics' if ad_condition == 1 | ad_condition == 2 | ad_condition == 3 | ad_condition == 0, robust
		matrix TABLE[row,col]     = r(table)[1,4]
		matrix TABLE[row,col+1]   = r(table)[2,4]
		matrix TABLE[row,col+2]   = r(table)[4,4]
		matrix TABLE[row+1,col]   = r(table)[1,1]
		matrix TABLE[row+1,col+1] = r(table)[2,1]
		matrix TABLE[row+1,col+2] = r(table)[4,1]
		matrix TABLE[row+2,col]   = r(table)[1,2]
		matrix TABLE[row+2,col+1] = r(table)[2,2]
		matrix TABLE[row+2,col+2] = r(table)[4,2]
		matrix TABLE[row+3,col]   = r(table)[1,3]
		matrix TABLE[row+3,col+1] = r(table)[2,3]
		matrix TABLE[row+3,col+2] = r(table)[4,3]
		lincom ad_genre - ad_plain
		matrix TABLE[row+5,col]   = r(estimate)
		matrix TABLE[row+5,col+1] = r(se)
		matrix TABLE[row+5,col+2] = r(p)
		lincom ad_price - ad_plain
		matrix TABLE[row+6,col]   = r(estimate)
		matrix TABLE[row+6,col+1] = r(se)
		matrix TABLE[row+6,col+2] = r(p)
		lincom ad_price - ad_genre
		matrix TABLE[row+7,col]   = r(estimate)
		matrix TABLE[row+7,col+1] = r(se)
		matrix TABLE[row+7,col+2] = r(p)
		scalar col = col + 3
	}

	* Part II: Stateline ATE different ads *
	scalar col = 1
	scalar row = 11
	foreach outcome_variable in "clicked_303" "purchased_303" {
		reg `outcome_variable' ad_plain ad_genre ad_price `demographics' if ad_condition == 4 | ad_condition == 5 | ad_condition == 6 | ad_condition == 0, robust
		matrix TABLE[row,col]     = r(table)[1,4]
		matrix TABLE[row,col+1]   = r(table)[2,4]
		matrix TABLE[row,col+2]   = r(table)[4,4]
		matrix TABLE[row+1,col]   = r(table)[1,1]
		matrix TABLE[row+1,col+1] = r(table)[2,1]
		matrix TABLE[row+1,col+2] = r(table)[4,1]
		matrix TABLE[row+2,col]   = r(table)[1,2]
		matrix TABLE[row+2,col+1] = r(table)[2,2]
		matrix TABLE[row+2,col+2] = r(table)[4,2]
		matrix TABLE[row+3,col]   = r(table)[1,3]
		matrix TABLE[row+3,col+1] = r(table)[2,3]
		matrix TABLE[row+3,col+2] = r(table)[4,3]
		lincom ad_genre - ad_plain
		matrix TABLE[row+5,col]   = r(estimate)
		matrix TABLE[row+5,col+1] = r(se)
		matrix TABLE[row+5,col+2] = r(p)
		lincom ad_price - ad_plain
		matrix TABLE[row+6,col]   = r(estimate)
		matrix TABLE[row+6,col+1] = r(se)
		matrix TABLE[row+6,col+2] = r(p)
		lincom ad_price - ad_genre
		matrix TABLE[row+7,col]   = r(estimate)
		matrix TABLE[row+7,col+1] = r(se)
		matrix TABLE[row+7,col+2] = r(p)
		scalar col = col + 3
	}

	matselrc TABLE TABLE2, row(1,3,4,5,6,7,8,9,10,12,13,14,15,16,17,18) col(1,2,3,4,5,6)
	matrix list TABLE2
	
	local controls = $controls
	frmttable using "../output/tables/ate_estimates/table1_all_ate_c`controls'.tex", statmat(TABLE2) sdec(3) fragment                      ///
		ctitle("" "Search" "Search" "Search" "Purch." "Purch." "Purch." \ "" "Est." "S.E." "P-value" "Est." "S.E." "P-value")  ///
		rtitle("\textbf{ATE Regression Estimates (Lost Girls):}" \ ///
			   "\hspace{5pt} $\beta$ Plain ad"                                    \ ///
			   "\hspace{5pt} $\beta$ Genre ad"                                    \ ///
			   "\hspace{5pt} $\beta$ Price ad"                                    \ ///
			   "Implied ATE differences:"               \ ///
			   "\hspace{5pt} $\beta$ Genre $-$ $\beta$ Plain"                            \ ///
			   "\hspace{5pt} $\beta$ Price $-$ $\beta$ Plain"                            \ ///
			   "\hspace{5pt} $\beta$ Price $-$ $\beta$ Genre"                            \ ///
			   "\textbf{ATE Regression Estimates (Stateline):}"  \ ///
			   "\hspace{5pt} $\beta$ Plain ad"                                    \ ///
			   "\hspace{5pt} $\beta$ Genre ad"                                    \ ///
			   "\hspace{5pt} $\beta$ Price ad"                                    \ ///
			   "Implied ATE differences:"               \ ///
			   "\hspace{5pt} $\beta$ Genre $-$ $\beta$ Plain"                             \ ///
			   "\hspace{5pt} $\beta$ Price $-$ $\beta$ Plain"                            \ ///
			   "\hspace{5pt} $\beta$ Price $-$ $\beta$ Genre") tex replace

end

* Table 2 and Table A9
program ate_match_value

	use "../output/dataset_merged.dta", clear
	
	matrix TABLE = J(15,5,.)
	
	gen treatment = .	
	replace treatment = 1 if ad_condition == 1    // genre ad lost girls                         
	replace treatment = 0 if ad_condition == 2    // plain ad lost girls
	gen romance_group = 1 * (romance_rank <= 1) + 2 * (romance_rank >= 2)
	
	if $controls == 1 {
		local demographics "i.fantasy_rank i.mystery_rank i.romance_rank i.scifi_rank female black hispanic age_years married divorced bachelor master some_college income1 income2 income3 income4 income5 income6 i.ebooks i.printbooks"
		}
	
	local row = 2
	foreach outcome_variable in "clicked_203" "purchased_203" {
		forvalues g = 1/2 {
			sum `outcome_variable' if treatment == 0 & romance_group == `g'
			matrix TABLE[`row',1] = r(mean)
			sum `outcome_variable' if treatment == 1 & romance_group == `g'
			matrix TABLE[`row',2] = r(mean)
			reg `outcome_variable' treatment `demographics' if romance_group == `g', robust
			matrix TABLE[`row',3] = _b[treatment]
			matrix TABLE[`row',4] = r(table)[2,1]
			matrix TABLE[`row',5] = r(table)[4,1]
			local row = `row' + 1
		}
	}
	local row = `row' + 1
	
	drop treatment
	gen treatment = .	
	replace treatment = 1 if ad_condition == 4   // genre ad stateline                          
	replace treatment = 0 if ad_condition == 5   // plain ad stateline
	gen mystery_group = 1 * (mystery_rank <= 1) + 2 * (mystery_rank >= 2)   
	
	foreach outcome_variable in "clicked_303" "purchased_303" {
		forvalues g = 1/2 {
			sum `outcome_variable' if treatment == 0 & mystery_group == `g'
			matrix TABLE[`row',1] = r(mean)
			sum `outcome_variable' if treatment == 1 & mystery_group == `g'
			matrix TABLE[`row',2] = r(mean)
			reg `outcome_variable' treatment `demographics' if mystery_group == `g', robust
			matrix TABLE[`row',3] = _b[treatment]
			matrix TABLE[`row',4] = r(table)[2,1]
			matrix TABLE[`row',5] = r(table)[4,1]
			local row = `row' + 1
		}
	}
	local row = `row' + 1
	
	drop treatment
	gen treatment = .
	replace treatment = 1 if ad_condition == 1 | ad_condition == 4  // genre ad (any book)
	replace treatment = 0 if ad_condition == 2 | ad_condition == 5  // plain ad (any book)	
	
	gen     ad_genre_rank     = romance_rank if (ad_condition == 1 | ad_condition == 2)
	replace ad_genre_rank     = mystery_rank if (ad_condition == 4 | ad_condition == 5)
	gen     genre_group       = 1 * (ad_genre_rank <= 1) + 2 * (ad_genre_rank >= 2)

	gen     clicked_ad_book   = clicked_203   if (ad_condition == 1 | ad_condition == 2)
	replace clicked_ad_book   = clicked_303   if (ad_condition == 4 | ad_condition == 5)
	gen     purchased_ad_book = purchased_203 if (ad_condition == 1 | ad_condition == 2)
	replace purchased_ad_book = purchased_303 if (ad_condition == 4 | ad_condition == 5)
	
	foreach outcome_variable in "clicked_ad_book" "purchased_ad_book" {
		forvalues g = 1/2 {
			sum `outcome_variable' if treatment == 0 & genre_group == `g'
			matrix TABLE[`row',1] = r(mean)
			sum `outcome_variable' if treatment == 1 & genre_group == `g'
			matrix TABLE[`row',2] = r(mean)
			reg `outcome_variable' treatment `demographics' if genre_group == `g', robust
			matrix TABLE[`row',3] = _b[treatment]
			matrix TABLE[`row',4] = r(table)[2,1]
			matrix TABLE[`row',5] = r(table)[4,1]
			local row = `row' + 1
		}
	}
	drop treatment ad_genre_rank clicked_ad_book purchased_ad_book
	drop romance_group mystery_group genre_group
	
	matrix PANEL_ALL = (J(2,5,.) \ TABLE[2..3,1..5] \ J(1,5,.) \ TABLE[4..5,1..5] \ J(3,5,.) \ TABLE[7..8,1..5] \ J(1,5,.) \ TABLE[9..10,1..5] \ J(3,5,.) \ TABLE[12..13,1..5] \ J(1,5,.) \ TABLE[14..15,1..5])
	matrix list PANEL_ALL

	local controls = $controls
	frmttable using "../output/tables/ate_estimates/table2_match_value_c`controls'.tex", statmat(PANEL_ALL) sdec(3) fragment ///
		ctitle("" "Plain Ad" "Genre Ad" "$\hat{\beta}$" "S.E." "\emph{p}-value")  ///
		rtitle("\textbf{\emph{Panel A. Advertising for Lost Girls}}"                  \ ///
			   "\hspace{5pt} Prob. search Lost Girls:"                     \ ///
			   "\hspace{5pt} Consumers who ranked romance 1st"                     \ ///
			   "\hspace{5pt} Consumers who ranked romance 2nd-5th"                  \ ///
			   "\hspace{5pt} Prob. buy Lost Girls:"                     \ ///
			   "\hspace{5pt} Consumers who ranked romance 1st"                        \ ///
			   "\hspace{5pt} Consumers who ranked romance 2nd-5th"                     \ ///
			   " "                     \ ///
			   "\textbf{\emph{Panel B. Advertising for Stateline}}"                   \ ///
			   "\hspace{5pt} Prob. search Stateline:"                     \ ///
			   "\hspace{5pt} Consumers who ranked mystery 1st"                     \ ///
			   "\hspace{5pt} Consumers who ranked mystery 2nd-5th"                  \ ///
			   "\hspace{5pt} Prob. buy Stateline:"                     \ ///
			   "\hspace{5pt} Consumers who ranked mystery 1st"                        \ ///
			   "\hspace{5pt} Consumers who ranked mystery 2nd-5th"                     \ ///
			   " "                     \ ///
			   "\textbf{\emph{Panel C. Pooling Both Books}}"             \ ///
			   "\hspace{5pt} Prob. search advertised book:"                     \ ///
			   "\hspace{5pt} Consumers who ranked ad genre 1st"    \ ///
			   "\hspace{5pt} Consumers who ranked ad genre 2nd-5th" \ ///
			   "\hspace{5pt} Prob. buy advertised book:"                     \ ///
			   "\hspace{5pt} Consumers who ranked ad genre 1st"       \ ///
			   "\hspace{5pt} Consumers who ranked ad genre 2nd-5th") tex replace
	
end


* Table 3 and Table A10
program ate_spillovers_info_ads_pool

	use "../output/dataset_merged.dta", clear

	if $controls == 1 {
		local demographics "i.fantasy_rank i.mystery_rank i.romance_rank i.scifi_rank female black hispanic age_years married divorced bachelor master some_college income1 income2 income3 income4 income5 income6 i.ebooks i.printbooks"
		}

	gen purchased_cheap_other = (purchased_price <= 1.00 & purchased_203==0 & purchased_303==0)
	
	gen     filtered_to_focal_genre     = filtered_to_romance     if (ad_condition == 1 | ad_condition == 2)
	replace filtered_to_focal_genre     = filtered_to_thriller    if (ad_condition == 4 | ad_condition == 5)
	gen     clicked_focal_genre_other   = clicked_romance_other   if (ad_condition == 1 | ad_condition == 2)
	replace clicked_focal_genre_other   = clicked_mystery_other   if (ad_condition == 4 | ad_condition == 5)
	gen     purchased_focal_genre_other = purchased_romance_other if (ad_condition == 1 | ad_condition == 2)
	replace purchased_focal_genre_other = purchased_mystery_other if (ad_condition == 4 | ad_condition == 5)

	* Panel A1: Price Advertising *
	gen treatment = .	
	replace treatment = 1 if ad_condition == 3 | ad_condition == 6 // price ad lost girls or stateline    
	replace treatment = 0 if ad_condition == 2 | ad_condition == 5 // plain ad lost girls or stateline
	
	matrix TABLE_A1 = J(5,5,.)
	local counter = 1
	foreach outcome_variable in "sorted_by_price_asc" "sorted_by_price_desc" "clicked_cheap_other" "purchased_cheap_other" "importance_price_num"  {
		sum `outcome_variable' if treatment == 0
		matrix TABLE_A1[`counter',1] = r(mean)
		sum `outcome_variable' if treatment == 1
		matrix TABLE_A1[`counter',2] = r(mean)
		reg `outcome_variable' treatment `demographics', robust
		matrix TABLE_A1[`counter',3] = _b[treatment]
		matrix TABLE_A1[`counter',4] = r(table)[2,1]
		matrix TABLE_A1[`counter',5] = r(table)[4,1]
		local counter = `counter' + 1
		}	
	drop treatment
	
	* Panel A2: Genre Advertising *
	gen treatment = .	
	replace treatment = 1 if ad_condition == 1 | ad_condition == 4 // genre ad lost girls or stateline    
	replace treatment = 0 if ad_condition == 2 | ad_condition == 5 // plain ad lost girls or stateline
	
	matrix TABLE_A2 = J(5,5,.)
	local counter = 1
	foreach outcome_variable in "filtered_to_focal_genre" "filtered_to_genre" "clicked_focal_genre_other" "purchased_focal_genre_other" "importance_genre_num" {

		sum `outcome_variable' if treatment == 0
		matrix TABLE_A2[`counter',1] = r(mean)
		sum `outcome_variable' if treatment == 1
		matrix TABLE_A2[`counter',2] = r(mean)
		reg `outcome_variable' treatment `demographics', robust
		matrix TABLE_A2[`counter',3] = _b[treatment]
		matrix TABLE_A2[`counter',4] = r(table)[2,1]
		matrix TABLE_A2[`counter',5] = r(table)[4,1]
		local counter = `counter' + 1
		}	
	drop treatment
	drop purchased_cheap_other

	matrix list TABLE_A1
	matrix list TABLE_A2


	matrix PANEL_ALL = (J(1,5,.) \ TABLE_A1[1..5,1..5] \ J(2,5,.) \ TABLE_A2[1..5,1..5])
	matrix list PANEL_ALL
	
	local controls = $controls
	frmttable using "../output/tables/ate_estimates/table3_spillovers_info_ads_pool_c`controls'.tex", statmat(PANEL_ALL) sdec(3) fragment ///
	ctitle("\textbf{\emph{Pooling Both Books}}" "Plain Ad" "Attribute Ad" "$\hat{\beta}$" "S.E." "\emph{p}-value")  ///
	rtitle("\textbf{\emph{Panel A. Spillovers from price ads:}}"                \ ///
		   "\hspace{5pt} Sorted by price low-to-high"                           \ ///
		   "\hspace{5pt} Sorted by price high-to-low"                           \ ///
		   "\hspace{5pt} Searched other cheap books"                            \ ///
		   "\hspace{5pt} Bought another cheap book"                             \ ///
		   "\hspace{5pt} Self-reported price importance"                        \ ///
		   " "                                                                  \ ///
		   "\textbf{\emph{Panel B. Spillovers from genre ads:}}"                \ ///
		   "\hspace{5pt} Filtered to advertised genre"                          \ ///
		   "\hspace{5pt} Filtered to any genre"                                 \ ///
		   "\hspace{5pt} Searched other books of advertised genre"              \ ///
		   "\hspace{5pt} Bought another book of advertised genre"               \ ///
		   "\hspace{5pt} Self-reported genre importance") tex replace

end

* Table A7
program ate_both_books

	use "../output/dataset_merged.dta", clear

	gen treatment = .
	replace treatment = 1 if ad_condition == 2 // plain ad lost girls
	replace treatment = 0 if ad_condition == 0 // no ads
	
	if $controls == 1 {
		local demographics "i.fantasy_rank i.mystery_rank i.romance_rank i.scifi_rank female black hispanic age_years married divorced bachelor master some_college income1 income2 income3 income4 income5 income6 i.ebooks i.printbooks"
		}
		
	matrix TABLE_A = J(9,5,.)
	local counter = 1
	foreach outcome_variable in "viewed_203" "clicked_203" "clicked_ad_banner" "clicked_203_organic" "clicked_203_recom" "added_to_cart203" "purchased_203" "kept_203" "redeemed_203" {
		sum `outcome_variable' if treatment == 0
		matrix TABLE_A[`counter',1] = r(mean)
		sum `outcome_variable' if treatment == 1
		matrix TABLE_A[`counter',2] = r(mean)
		reg `outcome_variable' treatment `demographics', robust
		matrix TABLE_A[`counter',3] = _b[treatment]
		matrix TABLE_A[`counter',4] = r(table)[2,1]
		matrix TABLE_A[`counter',5] = r(table)[4,1]
		local counter = `counter' + 1
		}	
	drop treatment
	
	gen treatment = .
	replace treatment = 1 if ad_condition == 5  // plain ad stateline
	replace treatment = 0 if ad_condition == 0  // no ads

	matrix TABLE_B = J(9,5,.)
	local counter = 1
	foreach outcome_variable in "viewed_303" "clicked_303" "clicked_ad_banner" "clicked_303_organic" "clicked_303_recom" "added_to_cart303" "purchased_303" "kept_303" "redeemed_303" {
		sum `outcome_variable' if treatment == 0
		matrix TABLE_B[`counter',1] = r(mean)
		sum `outcome_variable' if treatment == 1
		matrix TABLE_B[`counter',2] = r(mean)
		reg `outcome_variable' treatment `demographics', robust
		matrix TABLE_B[`counter',3] = _b[treatment]
		matrix TABLE_B[`counter',4] = r(table)[2,1]
		matrix TABLE_B[`counter',5] = r(table)[4,1]
		local counter = `counter' + 1
		}	
	drop treatment

	matrix PANEL_ALL = (J(1,5,.) \ TABLE_A \ J(1,5,.) \ TABLE_B)
	matrix list PANEL_ALL
	
	local controls = $controls
	frmttable using "../output/tables/ate_estimates/tableA7_c`controls'.tex", statmat(PANEL_ALL) sdec(3) fragment ///
	ctitle(" " "No Ad" "Plain Ad" "$\hat{\beta}$" "S.E." "\emph{p}-value")  ///
	rtitle("\textbf{\emph{Panel A. Plain advertising for Lost Girls}}"  \ ///
		   "Prob. viewed organic listing"                           \ ///
	       "Prob. searched"                                       \ ///
		   "\hspace{15pt} (1) Via ad banner"                         \ ///
		   "\hspace{15pt} (2) Organic"                                \ ///
		   "\hspace{15pt} (3) Recommended"                                \ ///
		   "Prob. added to cart"                                  \ ///
		   "Prob. purchased book"	                                  \ ///
		   "Prob. kept the book"	                              \ ///
		   "Prob. redeemed book"	                              \ ///
		   "\textbf{\emph{Panel B. Plain advertising for Stateline}}"   \ ///
		   "Prob. viewed organic listing"                           \ ///
	       "Prob. searched"                                       \ ///
		   "\hspace{15pt} (1) Via ad banner"                         \ ///
		   "\hspace{15pt} (2) Organic"                                \ ///
		   "\hspace{15pt} (3) Recommended"                                \ ///
		   "Prob. added to cart"                                  \ ///
		   "Prob. purchased book"	                                  \ ///
		   "Prob. kept the book"	                              \ ///
		   "Prob. redeemed book") tex replace

	display "lift in search rate = "                         TABLE_A[2,2]/TABLE_A[2,1]-1
	display "share of treated consumers searching via ad = " TABLE_A[3,2]/TABLE_A[2,2]
	display "lift in purchase rate = "                       TABLE_A[7,2]/TABLE_A[7,1]-1	   
	display "lift in keeping the book = "                    TABLE_A[8,2]/TABLE_A[8,1]-1	
	
	display "lift in search rate = "                         TABLE_B[2,2]/TABLE_B[2,1]-1
	display "share of treated consumers searching via ad = " TABLE_B[3,2]/TABLE_B[2,2]
	display "lift in purchase rate = "                       TABLE_B[7,2]/TABLE_B[7,1]-1	   
	display "lift in keeping the book = "                    TABLE_B[8,2]/TABLE_B[8,1]-1	

end


* Table A6
program ate_match_price

	use "../output/dataset_merged.dta", clear

	matrix TABLE = J(15,5,.)
	
	gen treatment = .	
	replace treatment = 1 if ad_condition == 3    // price ad lost girls                         
	replace treatment = 0 if ad_condition == 2    // plain ad lost girls
	gen romance_group = 1 * (romance_rank <= 1) + 2 * (romance_rank >= 2)
	
	if $controls == 1 {
		local demographics "i.fantasy_rank i.mystery_rank i.romance_rank i.scifi_rank female black hispanic age_years married divorced bachelor master some_college income1 income2 income3 income4 income5 income6 i.ebooks i.printbooks"
		}
	
	local row = 2
	foreach outcome_variable in "clicked_203" "purchased_203" {
		forvalues g = 1/2 {
			sum `outcome_variable' if treatment == 0 & romance_group == `g'
			matrix TABLE[`row',1] = r(mean)
			sum `outcome_variable' if treatment == 1 & romance_group == `g'
			matrix TABLE[`row',2] = r(mean)
			reg `outcome_variable' treatment `demographics' if romance_group == `g', robust
			matrix TABLE[`row',3] = _b[treatment]
			matrix TABLE[`row',4] = r(table)[2,1]
			matrix TABLE[`row',5] = r(table)[4,1]
			local row = `row' + 1
		}
	}
	local row = `row' + 1
	
	drop treatment
	gen treatment = .	
	replace treatment = 1 if ad_condition == 6   // price ad stateline                          
	replace treatment = 0 if ad_condition == 5   // plain ad stateline
	gen mystery_group = 1 * (mystery_rank <= 1) + 2 * (mystery_rank >= 2)   
	
	foreach outcome_variable in "clicked_303" "purchased_303" {
		forvalues g = 1/2 {
			sum `outcome_variable' if treatment == 0 & mystery_group == `g'
			matrix TABLE[`row',1] = r(mean)
			sum `outcome_variable' if treatment == 1 & mystery_group == `g'
			matrix TABLE[`row',2] = r(mean)
			reg `outcome_variable' treatment `demographics' if mystery_group == `g', robust
			matrix TABLE[`row',3] = _b[treatment]
			matrix TABLE[`row',4] = r(table)[2,1]
			matrix TABLE[`row',5] = r(table)[4,1]
			local row = `row' + 1
		}
	}
	local row = `row' + 1
	
	drop treatment
	gen treatment = .
	replace treatment = 1 if ad_condition == 3 | ad_condition == 6  // price ad (any book)
	replace treatment = 0 if ad_condition == 2 | ad_condition == 5  // plain ad (any book)	
	
	gen     ad_genre_rank     = romance_rank if (ad_condition == 3 | ad_condition == 2)
	replace ad_genre_rank     = mystery_rank if (ad_condition == 6 | ad_condition == 5)
	gen     genre_group       = 1 * (ad_genre_rank <= 1) + 2 * (ad_genre_rank >= 2)

	gen     clicked_ad_book   = clicked_203   if (ad_condition == 3 | ad_condition == 2)
	replace clicked_ad_book   = clicked_303   if (ad_condition == 6 | ad_condition == 5)
	gen     purchased_ad_book = purchased_203 if (ad_condition == 3 | ad_condition == 2)
	replace purchased_ad_book = purchased_303 if (ad_condition == 6 | ad_condition == 5)
	
	foreach outcome_variable in "clicked_ad_book" "purchased_ad_book" {
		forvalues g = 1/2 {
			sum `outcome_variable' if treatment == 0 & genre_group == `g'
			matrix TABLE[`row',1] = r(mean)
			sum `outcome_variable' if treatment == 1 & genre_group == `g'
			matrix TABLE[`row',2] = r(mean)
			reg `outcome_variable' treatment `demographics' if genre_group == `g', robust
			matrix TABLE[`row',3] = _b[treatment]
			matrix TABLE[`row',4] = r(table)[2,1]
			matrix TABLE[`row',5] = r(table)[4,1]
			local row = `row' + 1
		}
	}
	drop treatment ad_genre_rank clicked_ad_book purchased_ad_book
	
	matrix PANEL_ALL = (J(2,5,.) \ TABLE[2..3,1..5] \ J(1,5,.) \ TABLE[4..5,1..5] \ J(3,5,.) \ TABLE[7..8,1..5] \ J(1,5,.) \ TABLE[9..10,1..5] \ J(3,5,.) \ TABLE[12..13,1..5] \ J(1,5,.) \ TABLE[14..15,1..5])
	matrix list PANEL_ALL

	local controls = $controls
	frmttable using "../output/tables/ate_estimates/tableA6_match_price_c`controls'.tex", statmat(PANEL_ALL) sdec(3) fragment ///
		ctitle("" "Plain Ad" "Price Ad" "$\hat{\beta}$" "S.E." "\emph{p}-value")  ///
		rtitle("\textbf{\emph{Panel A. Advertising for Lost Girls}}"                  \ ///
			   "\hspace{5pt} Prob. search Lost Girls:"                     \ ///
			   "\hspace{5pt} Consumers who ranked romance 1st"                     \ ///
			   "\hspace{5pt} Consumers who ranked romance 2nd-5th"                  \ ///
			   "\hspace{5pt} Prob. buy Lost Girls:"                     \ ///
			   "\hspace{5pt} Consumers who ranked romance 1st"                        \ ///
			   "\hspace{5pt} Consumers who ranked romance 2nd-5th"                     \ ///
			   " "                     \ ///
			   "\textbf{\emph{Panel B. Advertising for Stateline}}"                   \ ///
			   "\hspace{5pt} Prob. search Stateline:"                     \ ///
			   "\hspace{5pt} Consumers who ranked mystery 1st"                     \ ///
			   "\hspace{5pt} Consumers who ranked mystery 2nd-5th"                  \ ///
			   "\hspace{5pt} Prob. buy Stateline:"                     \ ///
			   "\hspace{5pt} Consumers who ranked mystery 1st"                        \ ///
			   "\hspace{5pt} Consumers who ranked mystery 2nd-5th"                     \ ///
			   " "                     \ ///
			   "\textbf{\emph{Panel C. Pooling Both Books}}"             \ ///
			   "\hspace{5pt} Prob. search advertised book:"                     \ ///
			   "\hspace{5pt} Consumers who ranked ad genre 1st"    \ ///
			   "\hspace{5pt} Consumers who ranked ad genre 2nd-5th" \ ///
			   "\hspace{5pt} Prob. buy advertised book:"                     \ ///
			   "\hspace{5pt} Consumers who ranked ad genre 1st"       \ ///
			   "\hspace{5pt} Consumers who ranked ad genre 2nd-5th") tex replace
	
end


* Calculations reported in Introduction and Section 6
program value_of_targeting
	
	log using "../output/estimates/gains_from_targeting", text
	log off
	
	*** Lost Girls Search ***
	* Compute ATE for three ads*
	use "../output/dataset_merged.dta", clear
	matrix TABLE_TARG = J(5,11,.)
	gen treatment_plain = .
	gen treatment_genre = .
	gen treatment_price = .
	replace treatment_plain = 0 if ad_condition_labeled == "no ad"
	replace treatment_plain = 1 if ad_condition_labeled == "lostgirls plain"
	replace treatment_genre = 0 if ad_condition_labeled == "no ad"
	replace treatment_genre = 1 if ad_condition_labeled == "lostgirls genre"
	replace treatment_price = 0 if ad_condition_labeled == "no ad"
	replace treatment_price = 1 if ad_condition_labeled == "lostgirls price"
	forvalues g = 1/5 {
		matrix TABLE_TARG[`g',1] = `g'
		gen flag_rankg = (romance_rank == `g')
		reg clicked_203 treatment_plain if romance_rank == `g'
		matrix TABLE_TARG[`g',2] = _b[treatment_plain]
		matrix TABLE_TARG[`g',3] = sqrt(e(V)[1,1])
		sum flag_rankg if treatment_plain ~= .
		matrix TABLE_TARG[`g',4] = r(mean)
		reg clicked_203 treatment_genre if romance_rank == `g'
		matrix TABLE_TARG[`g',5] = _b[treatment_genre]
		matrix TABLE_TARG[`g',6] = sqrt(e(V)[1,1])
		sum flag_rankg if treatment_genre ~= .
		matrix TABLE_TARG[`g',7] = r(mean)
		reg clicked_203 treatment_price if romance_rank == `g'
		matrix TABLE_TARG[`g',8] = _b[treatment_price]
		matrix TABLE_TARG[`g',9] = sqrt(e(V)[1,1])
		sum flag_rankg if treatment_price ~= .
		matrix TABLE_TARG[`g',10] = r(mean)
		sum flag_rankg if treatment_plain ~= . | treatment_genre ~= . | treatment_price ~= .
		matrix TABLE_TARG[`g',11] = r(mean)
		drop flag_rankg
	}
	drop treatment*
	matrix list TABLE_TARG
	
	* Organize ATE results *
	svmat TABLE_TARG, names(ate)
	drop if ate1 == .
	keep ate*
	rename ate1 genre_rank
	rename ate2 ate_plain
	rename ate3 se_plain
	rename ate4 share_plain
	rename ate5 ate_genre
	rename ate6 se_genre
	rename ate7 share_genre
	rename ate8 ate_price
	rename ate9 se_price
	rename ate10 share_price
	rename ate11 share_all
	
	* Compute ATE from uniform ad content choice (no targeting) *
	gen ate_plain_x_share  = ate_plain * share_all
	egen ate_plain_uniform = sum(ate_plain_x_share)
	gen ate_genre_x_share  = ate_genre * share_all
	egen ate_genre_uniform = sum(ate_genre_x_share)
	gen ate_price_x_share  = ate_price * share_all
	egen ate_price_uniform = sum(ate_price_x_share)
	drop *x_share
	egen ate_best_uniform = rowmax(ate_plain_uniform ate_genre_uniform ate_price_uniform)
	
	* For each group compute ATE from the best targeted ad *
	gen ate_targ = .
	replace ate_targ = ate_plain if ate_plain >= ate_genre & ate_plain >= ate_price
	replace ate_targ = ate_genre if ate_genre >= ate_plain & ate_genre >= ate_price
	replace ate_targ = ate_price if ate_price >= ate_genre & ate_price >= ate_plain
	gen ate_x_share  = ate_targ * share_all
	egen ate_best_targeted = sum(ate_x_share)
	drop ate_x_share
	gen lift_choose_content      = ate_best_uniform - ate_plain_uniform
	gen lift_target_content      = ate_best_targeted - ate_best_uniform
	gen lift_choose_content_perc = (ate_best_uniform - ate_plain_uniform) / ate_plain_uniform
	gen lift_target_content_perc = (ate_best_targeted - ate_best_uniform) / ate_best_uniform
	gen choose_content_factor      = ate_best_uniform / ate_plain_uniform
	gen target_content_factor      = ate_best_targeted / ate_plain_uniform // AT: above comparison is to best uniform. here we compare to plain uniform
	local lift_choose_content      = round(lift_choose_content[1], 0.01)
	local lift_target_content      = round(lift_target_content[1], 0.001)
	local lift_choose_content_perc = round(lift_choose_content_perc[1], 0.01)
	local lift_target_content_perc = round(lift_target_content_perc[1], 0.01)
	local choose_content_factor    = round(choose_content_factor[1], 0.01)
	local target_content_factor    = round(target_content_factor[1], 0.01)
	log on
	display " "
	display " "
	display "For book #1: Lost Girls"
	display "Optimize content: increases click rate by `lift_choose_content' (by `lift_choose_content_perc' percent) relative to plain ads"
	display "Targeting content: increases click rate `lift_target_content'  (by `lift_target_content_perc' percent)  relative to uniform optimized content "
	display "Optimizing content makes ads `choose_content_factor' stronger and targeting content makes ads `target_content_factor' stronger"
	display " "
	display " "
	log off


	*** Stateline Search ***
	* Compute ATE for three ads*
	use "../output/dataset_merged.dta", clear
	matrix TABLE_TARG = J(5,11,.)
	gen treatment_plain = .
	gen treatment_genre = .
	gen treatment_price = .
	replace treatment_plain = 0 if ad_condition_labeled == "no ad"
	replace treatment_plain = 1 if ad_condition_labeled == "stateline plain"
	replace treatment_genre = 0 if ad_condition_labeled == "no ad"
	replace treatment_genre = 1 if ad_condition_labeled == "stateline genre"
	replace treatment_price = 0 if ad_condition_labeled == "no ad"
	replace treatment_price = 1 if ad_condition_labeled == "stateline price"
	forvalues g = 1/5 {
		matrix TABLE_TARG[`g',1] = `g'
		gen flag_rankg = (romance_rank == `g')
		reg clicked_303 treatment_plain if mystery_rank == `g'
		matrix TABLE_TARG[`g',2] = _b[treatment_plain]
		matrix TABLE_TARG[`g',3] = sqrt(e(V)[1,1])
		sum flag_rankg if treatment_plain ~= .
		matrix TABLE_TARG[`g',4] = r(mean)
		reg clicked_303 treatment_genre if mystery_rank == `g'
		matrix TABLE_TARG[`g',5] = _b[treatment_genre]
		matrix TABLE_TARG[`g',6] = sqrt(e(V)[1,1])
		sum flag_rankg if treatment_genre ~= .
		matrix TABLE_TARG[`g',7] = r(mean)
		reg clicked_303 treatment_price if mystery_rank == `g'
		matrix TABLE_TARG[`g',8] = _b[treatment_price]
		matrix TABLE_TARG[`g',9] = sqrt(e(V)[1,1])
		sum flag_rankg if treatment_price ~= .
		matrix TABLE_TARG[`g',10] = r(mean)
		sum flag_rankg if treatment_plain ~= . | treatment_genre ~= . | treatment_price ~= .
		matrix TABLE_TARG[`g',11] = r(mean)
		drop flag_rankg
	}
	drop treatment*
	matrix list TABLE_TARG
	
	* Organize ATE results *
	svmat TABLE_TARG, names(ate)
	drop if ate1 == .
	keep ate*
	rename ate1 genre_rank
	rename ate2 ate_plain
	rename ate3 se_plain
	rename ate4 share_plain
	rename ate5 ate_genre
	rename ate6 se_genre
	rename ate7 share_genre
	rename ate8 ate_price
	rename ate9 se_price
	rename ate10 share_price
	rename ate11 share_all
	
	* Compute ATE from uniform ad content choice (no targeting) *
	gen ate_plain_x_share  = ate_plain * share_all
	egen ate_plain_uniform = sum(ate_plain_x_share)
	gen ate_genre_x_share  = ate_genre * share_all
	egen ate_genre_uniform = sum(ate_genre_x_share)
	gen ate_price_x_share  = ate_price * share_all
	egen ate_price_uniform = sum(ate_price_x_share)
	drop *x_share
	egen ate_best_uniform = rowmax(ate_plain_uniform ate_genre_uniform ate_price_uniform)
	
	* For each group compute ATE from the best targeted ad *
	gen ate_targ = .
	replace ate_targ = ate_plain if ate_plain >= ate_genre & ate_plain >= ate_price
	replace ate_targ = ate_genre if ate_genre >= ate_plain & ate_genre >= ate_price
	replace ate_targ = ate_price if ate_price >= ate_genre & ate_price >= ate_plain
	gen ate_x_share  = ate_targ * share_all
	egen ate_best_targeted = sum(ate_x_share)
	drop ate_x_share
	gen lift_choose_content        = ate_best_uniform - ate_plain_uniform
	gen lift_target_content        = ate_best_targeted - ate_best_uniform
	gen lift_choose_content_perc   = (ate_best_uniform - ate_plain_uniform) / ate_plain_uniform
	gen lift_target_content_perc   = (ate_best_targeted - ate_best_uniform) / ate_best_uniform
	gen choose_content_factor      = ate_best_uniform / ate_plain_uniform
	gen target_content_factor      = ate_best_targeted / ate_plain_uniform
	local lift_choose_content      = round(lift_choose_content[1], 0.01)
	local lift_target_content      = round(lift_target_content[1], 0.01)
	local lift_choose_content_perc = round(lift_choose_content_perc[1], 0.01)
	local lift_target_content_perc = round(lift_target_content_perc[1], 0.01)
	local choose_content_factor    = round(choose_content_factor[1], 0.01)
	local target_content_factor    = round(target_content_factor[1], 0.01)
	log on
	display " "
	display " "
	display "For book #2: Stateline"
	display "Optimize content: increases click rate by `lift_choose_content' (by `lift_choose_content_perc' percent) relative to plain ads"
	display "Targeting content: increases click rate `lift_target_content'  (by `lift_target_content_perc' percent)  relative to uniform optimized content "
	display "Optimizing content makes ads `choose_content_factor' stronger and targeting content makes ads `target_content_factor' stronger"
	display " "
	display " "
	log off
	log close

end

* Calculations reported in Section 5.5
 program ate_general_search
 
	use "../output/dataset_merged.dta", clear
	
 	gen treatment = .
 	replace treatment = 1 if ad_condition == 2 | ad_condition == 5 // plain ads
 	replace treatment = 0 if ad_condition == 0 // no ads
	
 	if $controls == 1 {
 		local demographics "i.fantasy_rank i.mystery_rank i.romance_rank i.scifi_rank female black hispanic age_years married divorced bachelor master some_college income1 income2 income3 income4 income5 income6 i.ebooks i.printbooks"
 		}
	
 	matrix TABLE = J(4,5,.)
 	local counter = 1
	foreach outcome_variable in "num_unique" "opened_second_page" "session_duration" "dual_response"  {
 		sum `outcome_variable' if treatment == 0
 		matrix TABLE[`counter',1] = r(mean)
 		sum `outcome_variable' if treatment == 1
 		matrix TABLE[`counter',2] = r(mean)
 		reg `outcome_variable' treatment `demographics', robust
 		matrix TABLE[`counter',3] = _b[treatment]
 		matrix TABLE[`counter',4] = r(table)[2,1]
 		matrix TABLE[`counter',5] = r(table)[4,1]
 		local counter = `counter' + 1
 		}	
	
 	count if treatment == 1
 	local num_obs = `r(N)'
 	count if treatment == 0
 	local num_obs_control = `r(N)'
	
 	drop treatment
	
 	matrix PANEL_A = TABLE[1..3,1..5]
 	matrix PANEL_B = TABLE[4,1..5]
 	matrix PANEL_ALL = (J(1,5,.) \ PANEL_A \ J(1,5,.) \ PANEL_B)

 	local controls = $controls
 	frmttable using "../output/tables/ate_estimates/intensity_satisfaction_c`controls'.tex", statmat(PANEL_ALL) sdec(3) fragment ///
 		ctitle("" "No Ad" "Plain Ad" "$\hat{\beta}$" "S.E." "\emph{p}-value")  ///
 		rtitle("\textbf{Panel A. Search intensity:}"             \ ///
 		       "Number of searched books"    \ ///
 			   "Opened multiple assortment pages"        \ ///
 			   "Session duration (minutes)"    \ ///
 			   "\textbf{Panel B. Satisfaction:}"           \ ///
 			   "Kept book after checkout") tex replace
	
 end


main

