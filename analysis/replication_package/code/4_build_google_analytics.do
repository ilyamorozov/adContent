clear all


// 	Experimental conditions:
// 	1 - lostgirls_genre.jpg
// 	2 - lostgirls_noinfo.jpg
// 	3 - lostgirls_price.jpg
// 	4 - stateline_genre.jpg
// 	5 - stateline_noinfo.jpg
// 	6 - stateline_price.jpg


program main

	build_books
	build_ad_assignments
	build_banner_clicks
	build_duration
	build_add_to_cart
	build_search
	build_woocommerce_orders
	build_checkout_orders
	build_purchases
	build_views
	build_sorting
	build_unique_searches
	build_time_use
	build_recom_views

	organize_unredeemed_books
	merge_tables
	export_data_to_R
	
end


program build_books

	* Product list (ID <-> Amazon URLs) *
	import delimited "../input/website_design/product_sorting_full_store.csv", varnames(1) clear
	rename latest_price price
	rename id item_id
	gen name_to_links = name
	replace name_to_links = substr(name_to_links,1,strpos(name_to_links,":")-1)  if strpos(name_to_links,":") > 0
	replace name_to_links = upper(name_to_links)
	keep item_id name amazon_name name_to_links amazon_url price
	recast str500 amazon_name, force
	format %25s amazon_name
	format %25s amazon_url
	duplicates report item_id
	assert r(unique_value) == r(N) // assert item_id values are unique
	save "../temp/product_list.dta", replace

	* Prices *
	use "../temp/product_list.dta", clear
	keep item_id price
	save "../temp/prices.dta", replace

	* Genres + Positions *
	import delimited "../input/website_design/product_sorting_full_store.csv", varnames(1) clear
	rename categories category
	rename id item_id
	rename position store_position
	gen store_page = 1 + floor((store_position-1) / 10)
	gen store_position_on_page = store_position - 10*(store_page-1)
	keep item_id name category store_position store_page store_position_on_page
	save "../temp/positions.dta", replace
	
	* Build lookup for book codes *
	import delimited "../input/website_design/product_attr_pos.csv", varnames(1) clear
	keep sku id name
	rename sku book_code
	rename id item_id
	save "../temp/lookup_book_codes.dta", replace

end


program build_ad_assignments

	* Extract ad exposures from visibility events *
	use "../temp/parsed_data/interim_chronology.dta", clear
	keep if event_type == "banner_view"
	gen ad_condition = .
	replace ad_condition = 0 if strpos(label,"WHITEOUT") > 0
	replace ad_condition = 0 if strpos(label,"White")    > 0
	replace ad_condition = 1 if strpos(label,"1")        > 0
	replace ad_condition = 2 if strpos(label,"2")        > 0
	replace ad_condition = 3 if strpos(label,"3")        > 0
	replace ad_condition = 4 if strpos(label,"4")        > 0
	replace ad_condition = 5 if strpos(label,"5")        > 0
	replace ad_condition = 6 if strpos(label,"6")        > 0
	assert ad_condition ~= . // assert: all ad exposures coded
	bysort user_id: egen min_ad_condition = min(ad_condition)                   // flag users exposed to multiple ads
	bysort user_id: egen max_ad_condition = max(ad_condition)
	gen multiple_assignments = (min_ad_condition ~= max_ad_condition)
	bysort user_id (time_stamp): keep if _n == 1                                // keep the first ad the user was exposed to
	keep user_id ad_condition multiple_assignments
	rename ad_condition ad_condition_from_visibility
	save "../temp/user_data/ad_condition_from_visibility.dta", replace
	
	* Extract intended ad assignments from coupon codes *
	use "../temp/parsed_data/interim_chronology.dta", clear
	gen unique_code = upper(label)
	keep if category=="Coupon" & length(unique_code)==7
	drop if unique_code == "TEST_C"
	recast str10 unique_code, force
	bysort user_id (time): keep if _n == 1
	gen ad_condition_from_code = substr(unique_code,1,1)
	destring ad_condition_from_code, replace force
	keep user_id ad_condition_from_code
	save "../temp/user_data/ad_condition_from_code.dta", replace
	
	* Final table of ad assignments for analysis *
	use "../temp/crosswalk_userids.dta", clear
	merge 1:1 user_id using "../temp/user_data/ad_condition_from_visibility.dta", keep(1 3) nogenerate
	merge 1:1 user_id using "../temp/user_data/ad_condition_from_code.dta", keep(1 3) nogenerate
	drop if multiple_assignments == 1                                           // drop users exposed to multiple ads
	gen assign_expose_mismatch = (ad_condition_from_code != ad_condition_from_visibility) & ad_condition_from_code != . & ad_condition_from_visibility != .
	drop if assign_expose_mismatch == 1                                         // drop users whose assignment disagrees with their exposure in the data
	gen     ad_condition = ad_condition_from_code                               // prioritize assignment over recorder rxposure
	replace ad_condition = ad_condition_from_visibility if ad_condition == .    // fill in missings from visibility events (actual exposures)
	tab ad_condition                                                    	    // verify that assignments are roughly 4%-16%
	count if ad_condition == . 													// 16 people still missing ad condition. will drop them later.
	keep user_id ad_condition
	save "../temp/user_data/table_ab_assignments.dta", replace

end


program build_banner_clicks

	* Inferred banner clicks (searched ID=203 or ID=303 from front page) *
	use "../temp/parsed_data/user_clicks_all.dta", clear
	gen clicked_ad_banner = 1 if (item_id == 203 | item_id == 303) & source_type == "list" & source_genre ~= "default" & source_sort ~= "default" & source_npage == 1
	collapse (max) clicked_ad_banner, by(user_id)
	save "../temp/inferred_banner_clicks.dta", replace

	* Tracked banner clicks (user chronology custom events) *
	use "../temp/parsed_data/interim_chronology.dta", clear
	gen clicked_ad_banner = 1 if event_type == "banner_click"
	append using "../temp/inferred_banner_clicks.dta"
	collapse (max) clicked_ad_banner, by(user_id)
	replace clicked_ad_banner = 0 if clicked_ad_banner == .
	save "../temp/user_data/table_banner_clicks.dta", replace

end


program build_duration // revisit this once we truncate GA sequences
	
	use "../temp/parsed_data/interim_chronology.dta", clear
	bysort user_id (time_stamp): gen time_diff = time_stamp - time_stamp[_n-1]
	collapse (min) start_time = time_stamp (max) end_time = time_stamp, by(user_id)
	gen session_duration = (end_time - start_time) / 60000 // this gives duration in minutes
	keep user_id session_duration
	save "../temp/user_data/table_time_durations.dta", replace
	
end


program build_add_to_cart
	
	use "../temp/parsed_data/user_add_to_cart_all.dta", clear
	duplicates drop
	gen added_to_cart203 = (item_id == 203)
	gen added_to_cart303 = (item_id == 303)
	collapse (max) added_to_cart203 added_to_cart303, by(user_id)
	save "../temp/user_data/table_addtocarts.dta", replace

end


program build_search

	* Load search data *
	use "../temp/parsed_data/user_clicks_all.dta", clear
	
	* Clicks on advertised books (will convert into indicators) *
	gen clicked_203             = (item_id == 203)
	gen clicked_303             = (item_id == 303)
	gen clicked_203_organic     = 0
	gen clicked_303_organic     = 0
	replace clicked_203_organic = 1 if (item_id == 203) & source_type == "list" & source_genre == "default" & source_sort == "default" & source_npage == 2
	replace clicked_303_organic = 1 if (item_id == 303) & source_type == "list" & source_genre == "default" & source_sort == "default" & source_npage == 2
	replace clicked_203_organic = 1 if (item_id == 203) & source_type == "list" & source_genre ~= "default"
	replace clicked_303_organic = 1 if (item_id == 303) & source_type == "list" & source_genre ~= "default"
	replace clicked_203_organic = 1 if (item_id == 203) & source_type == "list" & source_sort  ~= "default"
	replace clicked_303_organic = 1 if (item_id == 303) & source_type == "list" & source_sort  ~= "default"
	gen clicked_203_recom       = (item_id == 203) & source_type == "product_page" & source_id ~= 203
	gen clicked_303_recom       = (item_id == 303) & source_type == "product_page" & source_id ~= 303

	* Add prices + positions *
	merge m:1 item_id using "../temp/prices.dta",    keep(1 3) nogenerate
	merge m:1 item_id using "../temp/positions.dta", keep(1 3) keepusing(store_page store_position category name) nogenerate
	
	* Clicks general *
	gen clicked_recom         = source_type == "product_page"  & item_id ~= source_id
	gen clicked_banner = 0
	replace clicked_banner = 1 if (item_id == 203) & source_type == "list" & source_genre == "default" & source_sort == "default" & source_npage == 1
	replace clicked_banner = 1 if (item_id == 303) & source_type == "list" & source_genre == "default" & source_sort == "default" & source_npage == 1
	gen clicked_organic       = 1 - clicked_recom - clicked_banner

	* Clicks by location *
	gen clicked_near_203      = (store_position == 11 | store_position == 13 | store_position == 17)
	gen clicked_near_303      = (store_position == 13 | store_position == 15 | store_position == 19)
	gen clicked_page1         = (store_page == 1)
	gen clicked_page2         = (store_page == 2)
	gen clicked_page2_other   = (store_page == 2) & (item_id ~= 203) & (item_id ~= 303)
	gen clicked_romance_other = (category == "Romance")              & (item_id ~= 203)
	gen clicked_mystery_other = (category == "Mystery/Thriller")     & (item_id ~= 303)
	gen clicked_cheap_other   = (price <= 1.00) & (item_id ~= 203)   & (item_id ~= 303)
	
	* Attributes of clicked items (price and position) *
	gen clicked_price         = price
	gen clicked_position      = store_position

	* Collapse to user level *
	collapse (max) clicked_203 clicked_303 clicked_203_organic clicked_303_organic clicked_203_recom clicked_303_recom clicked_near_203 clicked_near_303 ///
				   clicked_page1 clicked_page2 clicked_page2_other clicked_romance_other clicked_mystery_other clicked_cheap_other                       ///
			 (sum) clicked_recom clicked_organic                                                                                                         ///
			 (mean) clicked_price clicked_position, by(user_id)
	 
	* Save *
	save "../temp/user_data/table_search.dta", replace

end


program build_woocommerce_orders

	* Merge the two Woocommerce order tables *
	import delimited "../input/woocommerce/order_exp_july5_aug3.csv", varnames(1) clear
	keep order_date book_purchased coupon_code
	save "../temp/user_data/all_orders.dta", replace
	import delimited "../input/woocommerce/order_exp_may19_july4.csv", varnames(1) clear
	keep order_date book_purchased coupon_code
	append using "../temp/user_data/all_orders.dta"
	
	* Clean data *
	drop if coupon_code == "test_coupon" | coupon_code == "test_c"
	replace coupon_code = upper(coupon_code)
	gen date = date(substr(order_date,1,10), "YMD")
	format %d date
	bysort coupon_code date (book_purchased): keep if _n == 1 // 2 cases of same code used on same day to buy two books (investigate)
	drop order_date
	rename book_purchased name
	sort coupon_code date
	order coupon_code date
	
	* Look up book IDs *
	merge m:1 name using "../temp/lookup_book_codes.dta"
	assert _merge == 3
	drop _merge
	
	* Save coupon_code x date to item_id crosswalk *
	keep coupon_code date item_id
	rename coupon_code unique_code
	save "../temp/user_data/woocommerce_orders.dta", replace

end


program build_checkout_orders

	use "../temp/user_chronology_all.dta", clear
	keep if action == "CHECKOUT" | action == "PAYMENT"
	rename label name
	keep user_id name
	gen name_len = length(name)
	bysort user_id (name_len): keep if _n == 1
	drop name_len
	format %40s name
	sort name
	replace name = subinstr(name,"&#8217;","'",.)
	recast str500 name, force
	merge m:1 name using "../temp/lookup_book_codes.dta"
	assert _merge == 3
	drop _merge
	keep user_id item_id
	save "../temp/user_data/ga_orders.dta", replace

end


program build_purchases

	* Extract purchases from book codes in Qualtrics (everyone has to submit one to finish survey) *
	use "../temp/qualtrics.dta", clear
	keep mturk_id unique_code book_code
	drop if book_code == ""
	replace book_code = lower(book_code)
	merge m:1 book_code using "../temp/lookup_book_codes.dta", keep(match) nogenerate
	save "../temp/purchases_qualtrics.dta", replace
	
	* Fill in missings using purchases from WooCommerce *
	use "../temp/qualtrics.dta", clear
	keep if book_code == ""                // still unmatched
	gen date = dofc(start_time_cst)
	format %d date
	keep mturk_id unique_code date user_id
	bysort unique_code date (mturk_id): keep if _n == 1                          // 1 case of same code assigned twice on same day in qualtrics
	merge 1:1 unique_code date using "../temp/user_data/woocommerce_orders.dta"  // salvaged 425 purchases
	save "../temp/user_data/leftovers.dta", replace
	keep if _merge == 3
	keep mturk_id unique_code item_id
	save "../temp/purchases_woocommerce.dta", replace
	
	* Fill in missings using purchases from Google Analytics *
	use "../temp/user_data/leftovers.dta", clear
	keep if _merge == 1
	drop _merge
	merge 1:1 user_id using "../temp/user_data/ga_orders.dta", keep(match) nogenerate // salvaged 286 more purchases
	keep mturk_id unique_code item_id
	save "../temp/purchases_google.dta", replace

	* Merge tables *
	use "../temp/purchases_qualtrics.dta", clear
	//append using "../temp/purchases_woocommerce.dta"
	//append using "../temp/purchases_google.dta"
	
	* Add prices + positions *
	merge m:1 item_id using "../temp/prices.dta",    keep(1 3) nogenerate
	merge m:1 item_id using "../temp/positions.dta", keep(1 3) keepusing(store_page store_position category) nogenerate

	* Create outcome variables *
	gen purchased_203         = (item_id == 203)
	gen purchased_303         = (item_id == 303)
	
	* Spatial spillvers *
	summ store_position if item_id == 203
	gen store_position_203 = r(mean)
	summ store_position if item_id == 303
	gen store_position_303 = r(mean)
	gen purchased_near_203    = ((store_position == (store_position_203 - 1)) |  ///
							   (store_position == (store_position_203 + 1)) |    ///
							   (store_position == (store_position_203 + 5)) )
	gen purchased_near_303    = ((store_position == (store_position_303 - 1)) |  ///
							   (store_position == (store_position_303 + 1)) |    ///
							   (store_position == (store_position_303 + 5)) )
	drop store_position_203 store_position_303
	
	* Other outcomes *
	gen purchased_page1       = (store_page == 1)
	gen purchased_page2       = (store_page == 2)
	gen purchased_page2_other = (store_page == 2) & (item_id ~= 203) & (item_id ~= 303)
	gen purchased_romance     = (category == "Romance")
	gen purchased_mystery     = (category == "Mystery/Thriller")
	gen purchased_romance_other = purchased_romance - purchased_203
	gen purchased_mystery_other = purchased_mystery - purchased_303
	gen purchased_price       = price
	gen purchased_position    = store_position
	
	* Save *
	keep mturk_id unique_code purchased_*
	save "../temp/user_data/table_purchases.dta", replace
	
end


program build_views

	* Build variable "number of pages opened" *
	use "../temp/parsed_data/user_scrolls_recommendations.dta", clear
	append using "../temp/parsed_data/user_clicks_all.dta"
	keep if source_type == "list"
	duplicates drop user_id source_npage source_type source_genre source_sort, force
	gen pages_opened = 1
	gen pages_opened_default = 1 if source_genre == "default" & source_sort == "default"
	collapse (sum) pages_opened pages_opened_default, by(user_id)
	replace pages_opened_default = 1 if pages_opened_default == 0
	save "../temp/pages_opened.dta", replace

	* Load visibility data -> add prices & positions *
	use "../temp/parsed_data/user_scrolls_recommendations.dta", clear
	merge m:1 item_id using "../temp/prices.dta",    keep(1 3) nogenerate
	merge m:1 item_id using "../temp/positions.dta", keep(1 3) keepusing(store_page store_position category) nogenerate

	* Create outcome variables *
	gen viewed_203         = (item_id == 203)
	gen viewed_303         = (item_id == 303)
	gen view_organic       = item_id if source_type == "list"
	gen view_recom         = item_id if source_type == "product_page"
	egen viewed_total      = nvals(item_id),      by(user_id)
	egen viewed_organic    = nvals(view_organic), by(user_id)
	egen viewed_recom      = nvals(view_recom),   by(user_id)
	replace store_position = . if source_type == "product_page"
	collapse (sum) viewed_203_times=viewed_203 viewed_303_times=viewed_303 ///
			 (mean) price_viewed=price ///
			 (max) max_position=store_position viewed_203 viewed_303 ///
			 (firstnm) viewed_total viewed_organic viewed_recom, by(user_id)
	replace viewed_recom = 0 if viewed_recom == .
	merge 1:1 user_id using "../temp/pages_opened.dta", keep(1 3) nogenerate
	replace pages_opened = 1 if pages_opened == .
	order user_id viewed_203 viewed_303 viewed_total viewed_organic viewed_recom
	save "../temp/user_data/table_views.dta", replace

end


program build_sorting

	use "../temp/parsed_data/interim_chronology.dta", clear
	define_source_pages
	gen sorted_by_price_asc  = (source_sort == "price: asc")
	gen sorted_by_price_desc = (source_sort == "price: desc")
	gen used_search_query    = (source_sort == "search query")
	gen filtered_to_genre    = (source_genre ~= "default")
	gen filtered_to_romance  = (source_genre == "romance")
	gen filtered_to_thriller = (source_genre == "mystery")
	collapse (max) sorted_by_price* filtered* used_search_query, by(user_id)
	save "../temp/user_data/table_sorts.dta", replace
	
end


program build_unique_searches

	* Remove repeat clicks *
	use "../temp/parsed_data/user_clicks_all.dta", clear
	bysort user_id (time_stamp): drop if user_id == user_id[_n-1] & item_id == item_id[_n-1] & item ~= .
	
	* Count all searches *
	bysort user_id: gen num_nonunique = _N
	
	* Count unique searches *
	duplicates drop user_id item_id, force
	gen num_unique = 1
	gen num_unique_nonad = 1 if item_id ~= 203 & item_id ~= 303
	gen num_unique_adban = 1 if (item_id == 203 | item_id == 303) & source_genre == "default" & source_sort == "default" & source_npage == 1
	gen num_unique_organ = 1 if source_type ~= "product_page" & num_unique_adban ~= 1
	gen num_unique_recom = 1 if source_type == "product_page" & num_unique_adban ~= 1
	collapse (sum) num_unique* (first) num_nonunique, by(user_id)
	save "../temp/user_data/table_unique_searches.dta", replace

end


program build_time_use

	use "../temp/parsed_data/user_clicks_all.dta", clear
	collapse (sum) time_sec, by(user_id item_id)
	gen time_203   = time_sec if item_id == 203
	gen time_303   = time_sec if item_id == 303
	gen time_other = time_sec if item_id ~= 203 & item ~= 303
	collapse (firstnm) time_203 time_303 (sum) time_other, by(user_id)
	save "../temp/user_data/table_time_use.dta", replace

end


program build_recom_views

	use "../temp/parsed_data/user_scrolls_recommendations.dta", clear
	keep if source_type == "product_page"
	gen viewed_recommendations = 1
	collapse (sum) viewed_recommendations, by(user_id)
	save "../temp/user_data/table_recom_views.dta", replace

end


program organize_unredeemed_books

	* List of unredeemed books *
	set more off
	local satafiles: dir "../input/books_unredeemed/10july2022/" files "*.csv"
	local satafiles2: dir "../input/books_unredeemed/12july2022/" files "*.csv"
	local satafiles3: dir "../input/books_unredeemed/12aug2022/" files "*.csv"
	local counter = 1
	foreach file of local satafiles {
		insheet using "../input/books_unredeemed/10july2022/`file'", comma clear
		if `counter'>1 append using "../temp/books_unredeemed.dta"
		save "../temp/books_unredeemed.dta", replace
		local counter = `counter' + 1
	}
	foreach file of local satafiles2 {
		insheet using "../input/books_unredeemed/12july2022/`file'", comma clear
		if `counter'>1 append using "../temp/books_unredeemed.dta"
		save "../temp/books_unredeemed.dta", replace
		local counter = `counter' + 1
	}
	foreach file of local satafiles3 {
		insheet using "../input/books_unredeemed/12aug2022/`file'", comma clear
		if `counter'>1 append using "../temp/books_unredeemed.dta"
		save "../temp/books_unredeemed.dta", replace
		local counter = `counter' + 1
	}
	keep redemptionlink
	duplicates drop
	save "../temp/books_unredeemed.dta", replace
	
	* List of redemption links we sent *
	local counter = 1
	forvalues i = 1/14 {
		import delimited "../input/books_sent/redemption_links_to_send`i'.csv", varnames(1) clear
		if `counter'>1 append using "../temp/books_sent.dta"
		save "../temp/books_sent.dta", replace
		local counter = `counter' + 1
	}
	
	* Merge sent links with unredeemed links *
	duplicates drop mid redemption_link, force // duplicate observations
	rename redemption_link redemptionlink
	merge m:1 redemptionlink using "../temp/books_unredeemed.dta", keep(1 3)
	gen redeemed_book = (_merge == 1)
	collapse (max) redeemed_book, by(mid)
	rename mid mturk_id
	save "../temp/redeemed_dummy.dta", replace

end


program merge_tables

	use "../temp/qualtrics.dta", clear
	merge 1:1 mturk_id using "../temp/crosswalk_userids.dta",              keep(match) nogenerate
	merge 1:1 mturk_id using "../temp/user_data/table_purchases.dta",      keep(1 3) nogenerate
	merge 1:1 user_id using "../temp/user_data/table_ab_assignments.dta",  keep(1 3) nogenerate
	merge 1:1 user_id using "../temp/user_data/table_views.dta",           keep(1 3) nogenerate
	merge 1:1 user_id using "../temp/user_data/table_search.dta",          keep(1 3) nogenerate
	merge 1:1 user_id using "../temp/user_data/table_sorts.dta",           keep(1 3) nogenerate
	merge 1:1 user_id using "../temp/user_data/table_time_durations.dta",  keep(1 3) nogenerate
	merge 1:1 user_id using "../temp/user_data/table_addtocarts.dta",      keep(1 3) nogenerate
	merge 1:1 user_id using "../temp/user_data/table_banner_clicks.dta",   keep(1 3) nogenerate
	merge 1:1 user_id using "../temp/user_data/table_unique_searches.dta", keep(1 3) nogenerate
	merge 1:1 user_id using "../temp/user_data/table_time_use.dta",        keep(1 3) nogenerate
	merge 1:1 user_id using "../temp/user_data/table_recom_views.dta",     keep(1 3) nogenerate
	merge 1:1 mturk_id using "../temp/redeemed_dummy.dta",                 keep(1 3) nogenerate

	* Drop users for whom we can't infer an ad condition from any source
	drop if ad_condition == .
	
	* Build 'kept book' and 'redeemed book' variables *
	gen kept_203     = dual_response * purchased_203
	gen kept_303     = dual_response * purchased_303
	gen redeemed_203 = redeemed_book * dual_response * purchased_203
	gen redeemed_303 = redeemed_book * dual_response * purchased_303
	
	* Fill missings with zeros in search variables (unconditional search probabilities) *
	foreach var of varlist viewed_203 viewed_303                                                                 ///
						   viewed_total           viewed_organic      viewed_recom  viewed_recommendations       ///
						   clicked_203            clicked_303         clicked_near_203     clicked_near_303      ///
						   clicked_203_organic    clicked_303_organic clicked_203_recom    clicked_303_recom     ///
						   clicked_page1          clicked_page2       clicked_page2_other  clicked_romance_other ///
						   clicked_mystery_other  clicked_cheap_other                                            ///
						   clicked_recom          clicked_ad_banner                                              ///
						   added_to_cart203       added_to_cart303                                               ///
						   num_unique num_unique_adban num_unique_organ num_unique_recom num_unique_nonad {
	replace `var' = 0 if `var' == .
	}
	
	* Fill missings with one in pages opened variable
	replace pages_opened = 1 if pages_opened == .
	
	* Create attribute importance variables *
	foreach var in "importance_price" "importance_genre" "importance_plot" {
		gen `var'_num = .
		replace `var'_num = 1 if `var' == "Not at all important"
		replace `var'_num = 2 if `var' == "Slightly Important"
		replace `var'_num = 3 if `var' == "Fairly Important"
		replace `var'_num = 4 if `var' == "Important"
		replace `var'_num = 5 if `var' == "Very Important"
		drop `var'
	}

	* Force expected relationships between variables *
	replace clicked_203 = 1 if clicked_ad_banner == 1 & (ad_condition == 1 | ad_condition == 2 | ad_condition == 3)
	replace clicked_303 = 1 if clicked_ad_banner == 1 & (ad_condition == 4 | ad_condition == 5 | ad_condition == 6)
	replace added_to_cart203 = 1 if purchased_203 == 1
	replace added_to_cart303 = 1 if purchased_303 == 1
	replace clicked_203 = 1 if added_to_cart203 == 1
	replace clicked_303 = 1 if added_to_cart303 == 1
	replace viewed_203 = 1 if pages_opened >= 2 & pages_opened ~= . // revisit this (need better way to impute)
	replace viewed_303 = 1 if pages_opened >= 2 & pages_opened ~= . // revisit this (need better way to impute)

	* Additional variables *
	gen opened_second_page = (pages_opened > 1)
	gen only_front_page = (pages_opened == 1)
	gen clicked = clicked_recom + clicked_organic
	gen sorted_by_price = max(sorted_by_price_asc,sorted_by_price_desc)
	
	* Did this person purchase their favorite genre? *
	replace book_code = lower(book_code)
	merge m:1 book_code using "../temp/lookup_book_codes.dta", keep(1 3) nogenerate
	count if book_code ~= "" & item_id == .
	assert r(N) == 0 // assert that all book codes are matched
	merge m:1 item_id using "../temp/positions.dta", keep(1 3) keepusing(category) nogenerate
	gen genre_rank_purchased = 0
	replace genre_rank_purchased = fantasy_rank if category == "Fantasy"
	replace genre_rank_purchased = mystery_rank if category == "Mystery/Thriller"
	replace genre_rank_purchased = scifi_rank   if category == "Science Fiction"
	replace genre_rank_purchased = romance_rank if category == "Romance"
	replace genre_rank_purchased = memoirs_rank if category == "Biography/Memoir"
	replace genre_rank_purchased = . if genre_rank_purchased == 0
	gen purchased_fav_genre = (genre_rank_purchased == 1)
	
	* Process time use variables *
	gen time_session_sec      = session_duration * 60
	gen time_203_uncond       = time_203
	gen time_303_uncond       = time_303
	gen time_other_uncond     = time_other
	replace time_203_uncond   = 0 if time_203_uncond == .
	replace time_303_uncond   = 0 if time_303_uncond == .
	replace time_other_uncond = 0 if time_other_uncond == .
	gen time_list             = time_session_sec - time_203_uncond - time_303_uncond - time_other_uncond
	
	* Selection criteria (+ save initial sample to analyze attrition) *
	save "../temp/attrition_analysis.dta", replace
	drop if purchased_203 == . | purchased_303 == .
	
	* Label ad conditions *
	gen ad_condition_labeled = ""
	replace ad_condition_labeled = "no ad"           if ad_condition == 0
	replace ad_condition_labeled = "lostgirls genre" if ad_condition == 1
	replace ad_condition_labeled = "lostgirls plain" if ad_condition == 2
	replace ad_condition_labeled = "lostgirls price" if ad_condition == 3
	replace ad_condition_labeled = "stateline genre" if ad_condition == 4
	replace ad_condition_labeled = "stateline plain" if ad_condition == 5
	replace ad_condition_labeled = "stateline price" if ad_condition == 6
	
	* Save *
	order mturk_id user_id
	save "../output/dataset_merged.dta", replace

end


program export_data_to_R

	use "../output/dataset_merged.dta", clear
	keep ad_condition clicked_203 clicked_303 purchased_203 purchased_303 session_duration num_unique num_unique_nonad opened_second_page pages_opened dual_response genre_rank_purchased
	order ad_condition
	gen ad_type = ""
	replace ad_type = "1ad" if ad_condition == 0
	replace ad_type = "2ad" if ad_condition == 2 | ad_condition == 5
	replace ad_type = "3ad" if ad_condition == 1 | ad_condition == 4
	replace ad_type = "4ad" if ad_condition == 3 | ad_condition == 6
	export delimited using "../temp/data_choices_for_R.csv", replace
	
end


program define_source_pages

	gen source_npage  = .
	gen source_type   = ""
	gen source_genre  = ""
	gen source_sort   = ""

	replace source_genre = "mystery"     if strpos(lower(source_page),"product-category/mystery-thriller") > 0
	replace source_genre = "fantasy"     if strpos(lower(source_page),"product-category/fantasy") > 0
	replace source_genre = "sci-fi"      if strpos(lower(source_page),"product-category/science-fiction") > 0
	replace source_genre = "romance"     if strpos(lower(source_page),"product-category/romance") > 0
	replace source_genre = "biography"   if strpos(lower(source_page),"product-category/biography-memoir") > 0
	replace source_genre = "default"     if source_genre == ""

	replace source_sort = "price: desc"  if strpos(lower(source_page),"?orderby=price-desc") > 0
	replace source_sort = "price: asc"   if strpos(lower(source_page),"?orderby=price") > 0 & strpos(lower(source_page),"?orderby=price-desc") == 0
	replace source_sort = "search query" if strpos(lower(source_page),"?s=") > 0
	replace source_sort = "default"      if source_sort == ""

	replace source_type = "product_page" if strpos(lower(source_page),"/product/") > 0
	replace source_type = "list"         if source_type == ""

	forvalues p = 1/10 {
		replace source_npage = `p' if strpos(lower(source_page),"/page/`p'/") > 0
	}
	replace source_npage = 1 if source_npage == .

	gen flag_string = strpos(source_page,"/product/")
	gen short_name = substr(source_page,flag_string+9,strlen(source_page)-flag_string-9) if flag_string > 0
	replace short_name = subinstr(short_name, "/?s=&orderby", "", .)
	merge m:1 short_name using "../temp/item_dict.dta", keep(1 3) nogenerate
	rename item_id source_id
	
end


main

