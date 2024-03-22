clear all


program main

	genre_preferences_bar_charts
	genre_choice_bar_charts
	table_summary_of_choices
	keep_books_if_read_books
	purchases_by_store_page
	
end


program genre_choice_bar_charts

	* Load and prepare data *
	use "../output/dataset_merged.dta", clear
	gen purchased_fantasy = category == "Fantasy"
	gen purchased_scifi   = category == "Science Fiction"
	gen purchased_memoir  = category == "Biography/Memoir"
	gen favorite_genre = ""
	replace favorite_genre = "Prefers Fantasy" if fantasy_rank == 1
	replace favorite_genre = "Prefers Mystery" if mystery_rank == 1
	replace favorite_genre = "Prefers Sci-fi"  if scifi_rank   == 1
	replace favorite_genre = "Prefers Romance" if romance_rank == 1
	replace favorite_genre = "Prefers Memoirs" if memoirs_rank == 1
	keep if book_code ~= ""
	
	* Make genre choice bar charts *
	graph bar (mean) purchased_fantasy, over(favorite_genre, label(labsize(small))) title(Likelihood of choosing a fantasy book) ytitle(Prob. chose fantasy book) bargap(50) b1title(Self-reported preference, size(small) margin(medium)) graphregion(fcolor(white) lcolor(white) ifcolor(white))
	graph export "../output/graphs/genre_choices/fantasy.png", replace
	graph bar (mean) purchased_scifi, over(favorite_genre, label(labsize(small))) title(Likelihood of choosing a sci-fi book) ytitle(Prob. chose sci-fi book) bargap(50) b1title(Self-reported preference, size(small) margin(medium)) graphregion(fcolor(white) lcolor(white) ifcolor(white))
	graph export "../output/graphs/genre_choices/scifi.png", replace
	graph bar (mean) purchased_memoir, over(favorite_genre, label(labsize(small))) title(Likelihood of choosing a memoir book) ytitle(Prob. chose memoir book) bargap(50) b1title(Self-reported preference, size(small) margin(medium)) graphregion(fcolor(white) lcolor(white) ifcolor(white))
	graph export "../output/graphs/genre_choices/memoir.png", replace
	graph bar (mean) purchased_romance, over(favorite_genre, label(labsize(small))) title(Likelihood of choosing a romance book) ytitle(Prob. chose romance book) bargap(50) b1title(Self-reported preference, size(small) margin(medium)) graphregion(fcolor(white) lcolor(white) ifcolor(white))
	graph export "../output/graphs/genre_choices/romance.png", replace
	graph bar (mean) purchased_mystery, over(favorite_genre, label(labsize(small))) title(Likelihood of choosing a mystery book) ytitle(Prob. chose mystery book) bargap(50) b1title(Self-reported preference, size(small) margin(medium)) graphregion(fcolor(white) lcolor(white) ifcolor(white))
	graph export "../output/graphs/genre_choices/mystery.png", replace
	graph close
	
end


program table_summary_of_choices

	* Load purchase data and create balanced panel *
	use "../output/dataset_merged.dta", clear
	merge m:1 item_id using "../temp/prices.dta", keep(match) nogenerate
	merge m:1 item_id using "../temp/positions.dta", keep(match) keepusing(store_page store_position category name) nogenerate
	
	* Define relevant subcategories *
	gen price_cat = ""
	replace price_cat = "1 Price <$1.00" if price < 1.00
	replace price_cat = "2 Price $1.00-2.00" if price >= 1.00 & price <= 2.00
	replace price_cat = "3 Price >$2.00" if price > 2.00
	tab price_cat
	
	* Collapse to item level *
	gen num_purchases = 1
	gen purch_share = 1 / _N
	collapse (sum) num_purchases purch_share (firstnm) price_cat category, by(item_id)
	
	* Compute relevant stats for each subcategory *
	gen num_books = 1
	bysort category price_cat: egen total_purchases   = total(num_purchases)
	bysort category price_cat: egen books_offered     = total(num_books)
	bysort category price_cat: egen cat_purchase_rate = total(purch_share)
	gsort category price_cat -purch_share
	by category price_cat: gen num = _n
	gen top1_npurchases = num_purchases if num == 1
	gen top2_npurchases = num_purchases if num == 2
	gen top3_npurchases = num_purchases if num == 3
	gen top4_npurchases = num_purchases if num == 4
	gen top5_npurchases = num_purchases if num == 5
	collapse (firstnm) cat_purchase_rate total_purchases books_offered top1_npurchases top2_npurchases top3_npurchases top4_npurchases top5_npurchases, by(category price_cat)
	gen books_no_purch = 0
	
	* Make table *
	sort category price_cat
	gen num = _n
	matrix TABLE = J(16,9,.)
	forvalues row = 1/15 {
		local col = 1
		foreach outcome_variable in "cat_purchase_rate" "books_offered" " books_no_purch" "total_purchases" "top1_npurchases" "top2_npurchases" "top3_npurchases" "top4_npurchases" "top5_npurchases" {
			sum `outcome_variable' if num == `row'
			matrix TABLE[`row',`col'] = r(mean)
			local col = `col' + 1
		}
	}
	local col = 1
	foreach outcome_variable in "cat_purchase_rate" "books_offered" " books_no_purch" "total_purchases" "top1_npurchases" "top2_npurchases" "top3_npurchases" "top4_npurchases" "top5_npurchases" {
		egen `outcome_variable'_total = total(`outcome_variable')
		sum `outcome_variable'_total
		matrix TABLE[16,`col'] = r(mean)
		drop `outcome_variable'_total
		local col = `col' + 1
	}
	
	forvalues i = 1/`=rowsof(TABLE)' {
		forvalues j = 1/`=colsof(TABLE)' {
			if missing(TABLE[`i', `j']) {
				matrix TABLE[`i', `j'] = 0
			}
		}
	}
	matrix list TABLE
	
	* Save tables *
	frmttable using "../output/tables/orders_summary/orders_summary.tex", statmat(TABLE) sdec(3,0) fragment hlines(1001000000000000001) ///
	ctitle("Price/Genre" "Category" "Num" "Books" "Orders" "Orders" "Orders" "Orders" "Orders" "Orders" \ "" "Purch." "Books" "Without" "Total" "Top 1" "Top 2" "Top 3" "Top 4" "Top 5" \ "" "Share" "Offered" "Orders" "" "Book" "Book" "Book" "Book" "Book")  ///
	rtitle("0.00-0.99 Bio,Memoir"    \ ///
		   "1.00-1.99 Bio,Memoir"    \ ///
		   "2.00-3.00 Bio,Memoir"    \ ///
		   "0.00-0.99 Fantasy"       \ ///
		   "1.00-1.99 Fantasy"       \ ///
		   "2.00-3.00 Fantasy"       \ ///
		   "0.00-0.99 Myst,Thriller" \ ///
		   "1.00-1.99 Myst,Thriller" \ ///
		   "2.00-3.00 Myst,Thriller" \ ///
		   "0.00-0.99 Romance"       \ ///
		   "1.00-1.99 Romance"       \ ///
		   "2.00-3.00 Romance"       \ ///
		   "0.00-0.99 Sci-Fi"        \ ///
		   "1.00-1.99 Sci-Fi"        \ ///
		   "2.00-3.00 Sci-Fi"        \ ///
		   "Total All Categories") tex replace

end


program keep_books_if_read_books

	* Did they actually take the book? *
	use "../output/dataset_merged.dta", clear
	sum dual_response if printbooks == 0
	sum dual_response if printbooks >  0
	sum dual_response if ebooks == 0
	sum dual_response if ebooks >  0
	
end


program purchases_by_store_page

	* Which store pages did they buy books from? *
	use "../output/dataset_merged.dta", clear
	keep ad_condition item_id
	drop if item_id == .
	merge m:1 item_id using "../temp/positions.dta", keep(1 3) keepusing(store_page store_position category) nogenerate
	histogram store_page if ad_condition == 0, discrete fcolor(navy) lcolor(navy) lwidth(vvvthin) gap(10) xtitle(Store page) xlabel(#10) title(Purchases by store page (without ads)) graphregion(fcolor(white) lcolor(white) ifcolor(white))
	graph export "../output/graphs/descriptives/purchases_by_page_control.png", replace
	histogram store_page if ad_condition  > 0, discrete fcolor(navy) lcolor(navy) lwidth(vvvthin) gap(10) xtitle(Store page) xlabel(#10) title(Purchases by store page (with ads)) graphregion(fcolor(white) lcolor(white) ifcolor(white))
	graph export "../output/graphs/descriptives/purchases_by_page_treatment.png", replace

end


program genre_preferences_bar_charts

	* Load and prepare data *
	use "../output/dataset_merged.dta", clear
	
	* Make genre choice bar charts *
	graph bar, over(fantasy_rank, label(labsize(small))) title(Preference for fantasy genre) ytitle(Percent of participants) bargap(50) b1title(Self-reported preference, size(small) margin(medium)) graphregion(fcolor(white) lcolor(white) ifcolor(white))
	graph export "../output/graphs/genre_preferences/fantasy.png", replace
	graph bar, over(scifi_rank, label(labsize(small))) title(Preference for sci-fi genre) ytitle(Percent of participants) bargap(50) b1title(Self-reported preference, size(small) margin(medium)) graphregion(fcolor(white) lcolor(white) ifcolor(white))
	graph export "../output/graphs/genre_preferences/scifi.png", replace
	graph bar, over(memoirs_rank, label(labsize(small))) title(Preference for memoirs genre) ytitle(Percent of participants) bargap(50) b1title(Self-reported preference, size(small) margin(medium)) graphregion(fcolor(white) lcolor(white) ifcolor(white))
	graph export "../output/graphs/genre_preferences/memoir.png", replace
	graph bar, over(romance_rank, label(labsize(small))) title(Preference for romance genre) ytitle(Percent of participants) bargap(50) b1title(Self-reported preference, size(small) margin(medium)) graphregion(fcolor(white) lcolor(white) ifcolor(white))
	graph export "../output/graphs/genre_preferences/romance.png", replace
**# Bookmark #1
	graph bar, over(mystery_rank, label(labsize(small))) title(Preference for mystery genre) ytitle(Percent of participants) bargap(50) b1title(Self-reported preference, size(small) margin(medium)) graphregion(fcolor(white) lcolor(white) ifcolor(white))
	graph export "../output/graphs/genre_preferences/mystery.png", replace
	graph close
	
	* romance and mystery side to side	
	use "../output/dataset_merged.dta", clear
	keep mturk_id romance_rank mystery_rank
	duplicates drop
	expand 5
	bysort mturk_id: gen rank = _n
	gen romance_dummy = romance_rank == rank
	gen mystery_dummy = mystery_rank == rank
	graph bar romance_dummy mystery_dummy, over(rank, gap(*2.75) label(labsize(medlarge))) bar(1, fcolor("255 103 164") lcolor(gs0)) bar(2, fcolor(gs5) lcolor(gs0)) title(Stated preference over romance and mystery genres) ytitle(Percent of participants, size(medlarge)) bargap(50) b1title(Stated taste for the genre (rank),  margin(vsmall) size(medlarge)) graphregion(fcolor(white) lcolor(white) ifcolor(white)) legend(order(1 "Romance" 2 "Mystery") position(12) ring(0) size(medlarge)) 
	graph export "../output/graphs/genre_preferences/romance_and_mystery.png", replace
	graph close


	
end


main

