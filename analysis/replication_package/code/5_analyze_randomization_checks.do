clear all


program main

	demographics_summary
	attrition_analysis
	randomization_checks
	
end
	
* Table A1
program demographics_summary	   
	
	use "../output/dataset_merged.dta", clear
	local row = 1
	matrix TABLE_DEMOS = J(23,7,.)
	foreach demo_variable in "fantasy_rank" "mystery_rank" "romance_rank" "scifi_rank" "memoirs_rank" "printbooks" "ebooks" "female" "black" "hispanic" "asian" "income1" "income2" "income3" "income4" "income5" "income6" "bachelor" "master" "some_college" "married" "divorced" "age_years" {
		summarize `demo_variable', detail
		matrix TABLE_DEMOS[`row',1] = r(mean)
		matrix TABLE_DEMOS[`row',2] = r(sd)
		matrix TABLE_DEMOS[`row',3] = r(min)
		matrix TABLE_DEMOS[`row',4] = r(p5)
		matrix TABLE_DEMOS[`row',5] = r(p50)
		matrix TABLE_DEMOS[`row',6] = r(p95)
		matrix TABLE_DEMOS[`row',7] = r(max)
		local row = `row' + 1
		}	
	matrix list TABLE_DEMOS

	frmttable using "../output/tables/tableA1_demographics.tex", statmat(TABLE_DEMOS) sdec(2, 2, 1) fragment  ///
																 ctitle("" "Mean" "Std.dev" "Min" "P5" "P50" "P95" "Max")  ///
																 rtitle("Ranked fantasy genre (1-5)"  \ ///
																		"Ranked mystery genre (1-5)"  \ ///
																		"Ranked romance genre (1-5)"  \ ///
																		"Ranked sci-fi genre (1-5)"   \ ///
																		"Ranked memoirs genre (1-5)"  \ ///
																		"Reads books per month"     \ ///
																		"Reads e-books per month"   \ ///
																		"Female"                    \ ///
																		"Black"                     \ ///
																		"Hispanic"                  \ ///
																		"Asian"                     \ ///
																		"Income $<$20K"             \ ///
																		"Income 20-50K"             \ ///
																		"Income 50-75K"             \ ///
																		"Income 75-100K"            \ ///
																		"Income 100-150K"           \ ///
																		"Income $>$150K"            \ ///
																		"Education: Bachelor"       \ ///
																		"Education: Master"         \ ///
																		"Education: Some College"   \ ///
																		"Marital status: Married"   \ ///
																		"Marital status: Divorced"  \ ///
																		"Age") tex replace
																		
end

	
* Table A2
program attrition_analysis

	* Test for the balance of experiment assignments (dropped vs included) *
	use "../temp/qualtrics_long.dta", clear

	gen indicator_included = (book_code ~= "")  // we kept people whose purchases we know from qualtrics
	keep if length(unique_code)==7
	gen ad_condition = substr(unique_code,1,1)
	destring ad_condition, replace

	gen lostgirls_ad_plain = (ad_condition == 2)
	gen lostgirls_ad_genre = (ad_condition == 1)
	gen lostgirls_ad_price = (ad_condition == 3)
	gen stateline_ad_plain = (ad_condition == 5)
	gen stateline_ad_genre = (ad_condition == 4)
	gen stateline_ad_price = (ad_condition == 6)

	reg indicator_included lostgirls_ad_plain lostgirls_ad_genre lostgirls_ad_price ///
		stateline_ad_plain stateline_ad_genre stateline_ad_price
	test lostgirls_ad_plain lostgirls_ad_genre lostgirls_ad_price ///
		stateline_ad_plain stateline_ad_genre stateline_ad_price

	reg indicator_included lostgirls_ad_plain lostgirls_ad_genre lostgirls_ad_price ///
		stateline_ad_plain stateline_ad_genre stateline_ad_price

	matrix list r(table)
	matrix TABLE = J(7,3,.)
		scalar col = 1
		local row = 1
	foreach x_var in "lostgirls_ad_plain" "lostgirls_ad_genre" "lostgirls_ad_price" "stateline_ad_plain" "stateline_ad_genre" "stateline_ad_price" "_cons" {
			matrix TABLE[`row',col]     = r(table)[1,`row']
			matrix TABLE[`row',col+1]   = r(table)[2,`row']
			matrix TABLE[`row',col+2]   = r(table)[4,`row']
			local row = `row'+1
	}
	matrix list TABLE

	frmttable using "../output/tables/tableA2_attrition.tex", statmat(TABLE) sdec(3) fragment  ///
			ctitle("" "Est." "S.E." "P-value")                                               ///
			rtitle("\hspace{5pt} Lost Girls Plain Ad"                                      \ ///
				   "\hspace{5pt} Lost Girls Genre Ad"                                      \ ///
				   "\hspace{5pt} Lost Girls Price Ad"                                      \ ///
				   "\hspace{5pt} Stateline Plain Ad"                                       \ ///
				   "\hspace{5pt} Stateline Genre Ad"                                       \ ///
				   "\hspace{5pt} Stateline Price Ad"                                       \ ///
				   "\hspace{5pt} Constant") tex replace

end
		

* Table A3
program randomization_checks																
																
	local row = 1
	matrix TABLE_DEMOS = J(24,8,.)
	foreach demo_variable in "fantasy_rank" "mystery_rank" "romance_rank" "scifi_rank" "memoirs_rank" "printbooks" "ebooks" "female" "black" "hispanic" "asian" "income1" "income2" "income3" "income4" "income5" "income6" "age_years" "bachelor" "master" "some_college" "married" "divorced" {
		forvalues condition = 0/6 {
			sum `demo_variable' if ad_condition == `condition'
			matrix TABLE_DEMOS[`row',`condition'+1] = r(mean)	
		}
		reg `demo_variable' i.ad_condition
		matrix TABLE_DEMOS[`row',8] = Ftail(e(df_m), e(df_r), e(F))
		local row = `row' + 1
	}

	forvalues condition = 0/6 {
			sum female if ad_condition == `condition'
			matrix TABLE_DEMOS[`row',`condition'+1] = r(N)	
		}
				
	matrix list TABLE_DEMOS

	frmttable using "../output/tables/tableA3_randomization_checks.tex", statmat(TABLE_DEMOS) sdec(3\3\3\3\3\3\3\3\3\3\3\3\3\3\3\3\3\3\3\3\3\3\3\0) fragment  ///
																 ctitle("" "No" "Book 1" "Book 1" "Book 1" "Book 2" "Book 2" "Book 2" "\emph{F}-test" \ "" "Ads" "Genre" "Plain" "Price" "Genre" "Plain" "Price" "\emph{p}-val")  ///
																 rtitle("Fantasy rank"     \ ///
																		"Mystery rank"     \ ///
																		"Romance rank"     \ ///
																		"Scifi rank"       \ ///
																		"Memoirs rank"     \ ///
																		"BooksPerMonth"    \ ///
																		"EbooksPerMonth"   \ ///
																		"Female"           \ ///
																		"Black"            \ ///
																		"Hispanic"         \ ///
																		"Asian"            \ ///
																		"Income $<$20K"    \ ///
																		"Income 20-50K"    \ ///
																		"Income 50-75K"    \ ///
																		"Income 75-100K"   \ ///
																		"Income 100-150K"  \ ///
																		"Income $>$150K"   \ ///
																		"Age"              \ ///
																		"Bachelor"         \ ///
																		"Master"           \ ///
																		"Some College"     \ ///
																		"Married"          \ ///
																		"Divorced"		   \ ///
																		"N Participants") tex replace
					

					
	* Randomization test using SUR *
	dummieslab ad_condition
	sureg (fantasy_rank mystery_rank romance_rank scifi_rank printbooks ebooks female black hispanic asian income2 income3 income4 income5 income6 age_years bachelor master some_college married divorced = ad_condition_1 ad_condition_2 ad_condition_3 ad_condition_4 ad_condition_5 ad_condition_6)
	test [fantasy_rank]ad_condition_1=[fantasy_rank]ad_condition_2=[fantasy_rank]ad_condition_3=[fantasy_rank]ad_condition_4=[fantasy_rank]ad_condition_5=[fantasy_rank]ad_condition_6= ///
		 [mystery_rank]ad_condition_1=[mystery_rank]ad_condition_2=[mystery_rank]ad_condition_3=[mystery_rank]ad_condition_4=[mystery_rank]ad_condition_5=[mystery_rank]ad_condition_6= ///
		 [romance_rank]ad_condition_1=[romance_rank]ad_condition_2=[romance_rank]ad_condition_3=[romance_rank]ad_condition_4=[romance_rank]ad_condition_5=[romance_rank]ad_condition_6= ///
		 [scifi_rank]ad_condition_1  =[scifi_rank]ad_condition_2  =[scifi_rank]ad_condition_3  =[scifi_rank]ad_condition_4  =[scifi_rank]ad_condition_5  =[scifi_rank]ad_condition_6=   ///
		 [female]ad_condition_1      =[female]ad_condition_2      =[female]ad_condition_3      =[female]ad_condition_4      =[female]ad_condition_5      =[female]ad_condition_6=       ///
		 [asian]ad_condition_1       =[asian]ad_condition_2       =[asian]ad_condition_3       =[asian]ad_condition_4       =[asian]ad_condition_5       =[asian]ad_condition_6=        ///
		 [black]ad_condition_1       =[black]ad_condition_2       =[black]ad_condition_3       =[black]ad_condition_4       =[black]ad_condition_5       =[black]ad_condition_6=        ///
		 [hispanic]ad_condition_1    =[hispanic]ad_condition_2    =[hispanic]ad_condition_3    =[hispanic]ad_condition_4    =[hispanic]ad_condition_5    =[hispanic]ad_condition_6=     ///
		 [age_years]ad_condition_1   =[age_years]ad_condition_2   =[age_years]ad_condition_3   =[age_years]ad_condition_4   =[age_years]ad_condition_5   =[age_years]ad_condition_6=    ///
		 [married]ad_condition_1     =[married]ad_condition_2     =[married]ad_condition_3     =[married]ad_condition_4     =[married]ad_condition_5     =[married]ad_condition_6=      ///
		 [bachelor]ad_condition_1    =[bachelor]ad_condition_2    =[bachelor]ad_condition_3    =[bachelor]ad_condition_4    =[bachelor]ad_condition_5    =[bachelor]ad_condition_6=     ///
		 [some_college]ad_condition_1=[some_college]ad_condition_2=[some_college]ad_condition_3=[some_college]ad_condition_4=[some_college]ad_condition_5=[some_college]ad_condition_6= ///
		 [ebooks]ad_condition_1      =[ebooks]ad_condition_2      =[ebooks]ad_condition_3      =[ebooks]ad_condition_4      =[ebooks]ad_condition_5      =[ebooks]ad_condition_6=       ///
		 [printbooks]ad_condition_1  =[printbooks]ad_condition_2  =[printbooks]ad_condition_3  =[printbooks]ad_condition_4  =[printbooks]ad_condition_5  =[printbooks]ad_condition_6=   ///
		 [income2]ad_condition_1     =[income2]ad_condition_2     =[income2]ad_condition_3     =[income2]ad_condition_4     =[income2]ad_condition_5     =[income2]ad_condition_6=      ///
		 [income3]ad_condition_1     =[income3]ad_condition_2     =[income3]ad_condition_3	   =[income3]ad_condition_4     =[income3]ad_condition_5     =[income3]ad_condition_6=      ///
		 [income4]ad_condition_1     =[income4]ad_condition_2     =[income4]ad_condition_3	   =[income4]ad_condition_4     =[income4]ad_condition_5     =[income4]ad_condition_6=      ///
		 [income5]ad_condition_1     =[income5]ad_condition_2     =[income5]ad_condition_3	   =[income5]ad_condition_4     =[income5]ad_condition_5     =[income5]ad_condition_6=      ///
		 [income6]ad_condition_1     =[income6]ad_condition_2     =[income6]ad_condition_3	   =[income6]ad_condition_4     =[income6]ad_condition_5     =[income6]ad_condition_6=0

end

	 
main


