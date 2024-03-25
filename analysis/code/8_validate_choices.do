clear all


program main

	genre_preferences_bar_charts
	genre_choice_bar_charts
	table_summary_of_choices
	keep_books_if_read_books
	describe_searches_shopper
	describe_purchases_shopper
	make_comparison_table
	
end

* Figure A4
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
	graph export "../output/graphs/genre_choices/figA4_fantasy.pdf", replace
	graph bar (mean) purchased_scifi, over(favorite_genre, label(labsize(small))) title(Likelihood of choosing a sci-fi book) ytitle(Prob. chose sci-fi book) bargap(50) b1title(Self-reported preference, size(small) margin(medium)) graphregion(fcolor(white) lcolor(white) ifcolor(white))
	graph export "../output/graphs/genre_choices/figA4_scifi.pdf", replace
	graph bar (mean) purchased_memoir, over(favorite_genre, label(labsize(small))) title(Likelihood of choosing a memoir book) ytitle(Prob. chose memoir book) bargap(50) b1title(Self-reported preference, size(small) margin(medium)) graphregion(fcolor(white) lcolor(white) ifcolor(white))
	graph export "../output/graphs/genre_choices/figA4_memoir.pdf", replace
	graph bar (mean) purchased_romance, over(favorite_genre, label(labsize(small))) title(Likelihood of choosing a romance book) ytitle(Prob. chose romance book) bargap(50) b1title(Self-reported preference, size(small) margin(medium)) graphregion(fcolor(white) lcolor(white) ifcolor(white))
	graph export "../output/graphs/genre_choices/figA4_romance.pdf", replace
	graph bar (mean) purchased_mystery, over(favorite_genre, label(labsize(small))) title(Likelihood of choosing a mystery book) ytitle(Prob. chose mystery book) bargap(50) b1title(Self-reported preference, size(small) margin(medium)) graphregion(fcolor(white) lcolor(white) ifcolor(white))
	graph export "../output/graphs/genre_choices/figA4_mystery.pdf", replace
	graph close
	
end

* Table A4
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
	frmttable using "../output/tables/orders_summary/tableA4_orders_summary.tex", statmat(TABLE) sdec(3,0) fragment hlines(1001000000000000001) ///
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



* Figure 5 and Figure A1
program genre_preferences_bar_charts

	* Load and prepare data *
	use "../output/dataset_merged.dta", clear
	
	* Make genre choice bar charts *
	graph bar, over(fantasy_rank, label(labsize(small))) title(Preference for fantasy genre) ytitle(Percent of participants) bargap(50) b1title(Self-reported preference, size(small) margin(medium)) graphregion(fcolor(white) lcolor(white) ifcolor(white))
	graph export "../output/graphs/genre_preferences/figA1_fantasy.pdf", replace
	graph bar, over(scifi_rank, label(labsize(small))) title(Preference for sci-fi genre) ytitle(Percent of participants) bargap(50) b1title(Self-reported preference, size(small) margin(medium)) graphregion(fcolor(white) lcolor(white) ifcolor(white))
	graph export "../output/graphs/genre_preferences/figA1_scifi.pdf", replace
	graph bar, over(memoirs_rank, label(labsize(small))) title(Preference for memoirs genre) ytitle(Percent of participants) bargap(50) b1title(Self-reported preference, size(small) margin(medium)) graphregion(fcolor(white) lcolor(white) ifcolor(white))
	graph export "../output/graphs/genre_preferences/figA1_memoir.pdf", replace
	graph bar, over(romance_rank, label(labsize(small))) title(Preference for romance genre) ytitle(Percent of participants) bargap(50) b1title(Self-reported preference, size(small) margin(medium)) graphregion(fcolor(white) lcolor(white) ifcolor(white))
	graph export "../output/graphs/genre_preferences/figA1_romance.pdf", replace
**# Bookmark #1
	graph bar, over(mystery_rank, label(labsize(small))) title(Preference for mystery genre) ytitle(Percent of participants) bargap(50) b1title(Self-reported preference, size(small) margin(medium)) graphregion(fcolor(white) lcolor(white) ifcolor(white))
	graph export "../output/graphs/genre_preferences/figA1_mystery.pdf", replace
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
	graph export "../output/graphs/genre_preferences/fig5_romance_and_mystery.pdf", replace
	graph close


	
end


program describe_purchases_comscore

	use "../temp/transactions_comscore.dta", clear
	merge m:1 asin_code using "../temp/lookup_books_comscore.dta", keep(match) nogenerate
	drop if genre == "Other"
	gen num_transactions = 1
	collapse (sum) num_transactions, by(genre)
	egen total_purchases = total(num_transactions)
	gen share_purchases = num_transactions / total_purchases
	sum share_purchases if genre == "Romance"
	matrix TABLE[1,3] = round(100 * r(mean),0.1)
	sum share_purchases if genre == "Mystery, Thriller and Suspense"
	matrix TABLE[2,3] = round(100 * r(mean),0.1)
	sum share_purchases if genre == "Biographies and Memoirs"
	matrix TABLE[3,3] = round(100 * r(mean),0.1)
	sum share_purchases if genre == "Fantasy"
	matrix TABLE[4,3] = round(100 * r(mean),0.1)
	sum share_purchases if genre == "Science Fiction"
	matrix TABLE[5,3] = round(100 * r(mean),0.1)
	matrix TABLE[6,3] = 100
	matrix list TABLE
	
end

	
program describe_searches_shopper

	* Load search data from our bookstore *
	use "../temp/parsed_data/user_clicks_all.dta", clear
	merge m:1 item_id using "../temp/positions.dta", keep(1 3) keepusing(category name) nogenerate
	rename category genre
	
	* Compute number of (unique) searched books *
	duplicates drop user_id item_id, force   
	gen num_unique_books = 1
	collapse (sum) num_unique_books, by(user_id genre)
	
	* Limit to the same sample as in the main analysis *
	merge m:1 user_id using "../temp/crosswalk_userids.dta", keep(match) nogenerate

	* Long to wide *
	gen genre_short = ""
	replace genre_short = "other"    if genre == "Other"
	replace genre_short = "romance"  if genre == "Romance" 
	replace genre_short = "biomem"   if genre == "Biography/Memoir"
	replace genre_short = "mysthril" if genre == "Mystery/Thriller"
	replace genre_short = "scifi"    if genre == "Science Fiction"
	replace genre_short = "fantasy"  if genre == "Fantasy"
	drop genre
	rename num_unique_books num_
	reshape wide num_, i(user_id) j(genre_short) string // long to wide
		
	* Fill in zeros if no searches *
	foreach var in "num_biomem" "num_fantasy" "num_mysthril" "num_romance" "num_scifi" {
		replace `var' = 0 if `var' == .
	}
	gen total_five_genres = num_biomem + num_fantasy + num_mysthril + num_romance + num_scifi
	sum num_biomem num_fantasy num_mysthril num_romance num_scifi total_five_genres if total_five_genres > 0
		
	* Summary statistics: number of searches by genre *
	sum num_romance if total_five_genres > 0
	matrix TABLE[1,4] = round(r(mean),0.01)
	sum num_mysthril if total_five_genres > 0
	matrix TABLE[2,4] = round(r(mean),0.01)
	sum num_biomem if total_five_genres > 0
	matrix TABLE[3,4] = round(r(mean),0.01)
	sum num_fantasy if total_five_genres > 0
	matrix TABLE[4,4] = round(r(mean),0.01)
	sum num_scifi if total_five_genres > 0
	matrix TABLE[5,4] = round(r(mean),0.01)
	sum total_five_genres if total_five_genres > 0
	matrix TABLE[6,4] = round(r(mean),0.01)
	matrix TABLE[1,5] = round(100 * TABLE[1,4] / TABLE[6,4],0.1)
	matrix TABLE[2,5] = round(100 * TABLE[2,4] / TABLE[6,4],0.1)
	matrix TABLE[3,5] = round(100 * TABLE[3,4] / TABLE[6,4],0.1)
	matrix TABLE[4,5] = round(100 * TABLE[4,4] / TABLE[6,4],0.1)
	matrix TABLE[5,5] = round(100 * TABLE[5,4] / TABLE[6,4],0.1)
	matrix TABLE[6,5] = 100
	matrix list TABLE

	* Build histogram of searches per day *
	replace total_five_genres = 10 if total_five_genres > 10
	histogram total_five_genres if (total_five_genres >=1 & total_five_genres <= 10), discrete percent fcolor(navy) lcolor(navy) lwidth(vvvthin) gap(20) xtitle(# unique books searched) xlabel(1(1)10) title(No. books searched (our store)) graphregion(fcolor(white) lcolor(white) ifcolor(white))
	graph export "../output/graphs/descriptives/figA5a_histogram_unique_books.pdf", replace
	graph close

end


program describe_purchases_shopper

	use "../output/dataset_merged.dta", clear
	keep user_id item_id ad_condition
	drop if item_id == .
	merge m:1 item_id using "../temp/positions.dta", keep(1 3) keepusing(store_page store_position category name) nogenerate   
	gen num_transactions = 1
	rename category genre
	collapse (sum) num_transactions, by(genre)
	egen total_purchases = total(num_transactions)
	gen share_purchases = num_transactions / total_purchases
	sum share_purchases if genre == "Romance"
	matrix TABLE[1,6] = round(100 * r(mean),0.1)
	sum share_purchases if genre == "Mystery/Thriller"
	matrix TABLE[2,6] = round(100 * r(mean),0.1)
	sum share_purchases if genre == "Biography/Memoir"
	matrix TABLE[3,6] = round(100 * r(mean),0.1)
	sum share_purchases if genre == "Fantasy"
	matrix TABLE[4,6] = round(100 * r(mean),0.1)
	sum share_purchases if genre == "Science Fiction"
	matrix TABLE[5,6] = round(100 * r(mean),0.1)
	matrix TABLE[6,6] = 100
	matrix list TABLE

end


program make_comparison_table

	frmttable using "../output/tables/comscore/comscore_comparison.tex", statmat(TABLE) sdec(2) fragment ///
	ctitle("" "Comscore" "Comscore" "Comscore" "Our Store" "Our Store" "Our Store" \ "Book Genre" "Searches" "Searches" "Purch." "Searches" "Searches" "Purch." \ "" "No." "Perc." "Perc." "No." "Perc." "Perc.")  ///
	rtitle("Romance"          \ ///
		   "Myst/Thril"       \ ///
		   "Bio/Memoir"       \ ///
		   "Fantasy"          \ ///
		   "Sci-fi"           \ ///
		   "All Genres") tex replace

end


main

