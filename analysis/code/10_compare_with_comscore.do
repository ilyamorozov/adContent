clear all


program main

	build_lookup_books
	build_transactions
	describe_searches_comscore
	describe_purchases_comscore
	
end


program build_lookup_books

	use "../input/comscore/category_lookup.dta", clear
	merge m:1 cat_code1 cat_code2 cat_code3 cat_code4 using "../input/comscore/dictionary_categories.dta", keep(match) nogenerate
	keep if category1 == "'Books'"
	gen     genre = "Other"
	replace genre = "Romance"                          if strpos(category3, "Romance")         > 0
	replace genre = "Biographies and Memoirs"          if strpos(category3, "Biographies")     > 0
	replace genre = "Biographies and Memoirs"          if strpos(category3, "Memoirs")         > 0
	replace genre = "Biographies and Memoirs"          if strpos(category4, "Historical")      > 0
	replace genre = "Mystery, Thriller and Suspense"   if strpos(category3, "Mystery")         > 0
	replace genre = "Mystery, Thriller and Suspense"   if strpos(category3, "Thriller")        > 0
	replace genre = "Mystery, Thriller and Suspense"   if strpos(category3, "Suspense")        > 0
	replace genre = "Science Fiction"                  if strpos(category4, "Science Fiction") > 0
	replace genre = "Science Fiction"                  if strpos(category4, "Time Travel")     > 0
	replace genre = "Fantasy"                          if strpos(category4, "Fantasy")         > 0
	replace genre = "Fantasy"                          if strpos(category4, "Fantasy")         > 0
	keep asin_code genre
	sort asin_code
	save "../temp/lookup_books_comscore.dta", replace

end


program build_transactions

	use "../input/comscore/amazon_crosswalk.dta", clear
	rename product_asin asin_code
	merge m:1 asin_code using "../temp/lookup_books_comscore.dta", keep(match) nogenerate
	gen date = date(substr(event_time, 1, 10), "YMD")
	format %d date
	duplicates drop machine_id date asin_code, force
	keep machine_id date asin_code
	save "../temp/transactions_comscore.dta", replace
	
end


program describe_searches_comscore

	* Load search data from comscore *
	use "../input/comscore/searches_amazon_clean.dta", clear
	merge m:1 asin_code using "../temp/lookup_books_comscore.dta", keep(match) nogenerate

	* Compute number of (unique) searched books *
	duplicates drop machine_id date asin_code, force                            // unique products per genre category
	gen num_unique_books = 1
	collapse (sum) num_unique_books, by(machine_id date genre)
	
	* Merge with demographics *
	merge m:1 machine_id using "../input/comscore/demographics_machine.dta", keep(match) nogenerate
	
	* Remove outliers (implausibly large number of searches) *
	bysort machine_id date: egen total_searches = sum(num_unique_books)
	drop if total_searches > 100
	drop total_searches

	* Long to wide *
	gen genre_short = ""
	replace genre_short = "other"    if genre == "Other"
	replace genre_short = "romance"  if genre == "Romance" 
	replace genre_short = "biomem"   if genre == "Biographies and Memoirs"
	replace genre_short = "mysthril" if genre == "Mystery, Thriller and Suspense"
	replace genre_short = "scifi"    if genre == "Science Fiction"
	replace genre_short = "fantasy"  if genre == "Fantasy"
	drop genre
	rename num_unique_books num_
	reshape wide num_, i(machine_id date) j(genre_short) string // long to wide
	
	* Fill in zeros if no searches *
	foreach var in "num_biomem" "num_fantasy" "num_mysthril" "num_other" "num_romance" "num_scifi" {
		replace `var' = 0 if `var' == .
	}
	gen total_five_genres = num_biomem + num_fantasy + num_mysthril + num_romance + num_scifi
	gen total_all_books   = num_biomem + num_fantasy + num_mysthril + num_romance + num_scifi + num_other
	sum num_biomem num_fantasy num_mysthril num_romance num_scifi total_five_genres if total_five_genres > 0
	sum num_*

	* Summary statistics: number of searches by genre *
	matrix TABLE = J(6,6,.)
	sum num_romance if total_five_genres > 0
	matrix TABLE[1,1] = round(r(mean),0.01)
	sum num_mysthril if total_five_genres > 0
	matrix TABLE[2,1] = round(r(mean),0.01)
	sum num_biomem if total_five_genres > 0
	matrix TABLE[3,1] = round(r(mean),0.01)
	sum num_fantasy if total_five_genres > 0
	matrix TABLE[4,1] = round(r(mean),0.01)
	sum num_scifi if total_five_genres > 0
	matrix TABLE[5,1] = round(r(mean),0.01)
	sum total_five_genres if total_five_genres > 0
	matrix TABLE[6,1] = round(r(mean),0.01)
	matrix TABLE[1,2] = round(100 * TABLE[1,1] / TABLE[6,1],0.1)
	matrix TABLE[2,2] = round(100 * TABLE[2,1] / TABLE[6,1],0.1)
	matrix TABLE[3,2] = round(100 * TABLE[3,1] / TABLE[6,1],0.1)
	matrix TABLE[4,2] = round(100 * TABLE[4,1] / TABLE[6,1],0.1)
	matrix TABLE[5,2] = round(100 * TABLE[5,1] / TABLE[6,1],0.1)
	matrix TABLE[6,2] = 100
	matrix list TABLE
	
	* Build histogram of searches per day *
	replace total_five_genres = 10 if total_five_genres > 10
	histogram total_five_genres if (total_five_genres >=1 & total_five_genres <= 10), yscale(range(0 80)) ylabel(0(20)80) discrete percent fcolor(maroon) lcolor(maroon) lwidth(vvvthin) gap(20) xtitle(# unique books searched) xlabel(1(1)10) title(No. books searched (Comscore data)) graphregion(fcolor(white) lcolor(white) ifcolor(white))
	graph export "../output/graphs/comscore/figA5b_histogram_unique_books.pdf", replace
	graph close

end


main

