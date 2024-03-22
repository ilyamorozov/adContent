clear all


program main

	make_item_dictionary
	prepare_chronology
	build_clicks_type1
	build_clicks_type2
	build_clicks_all
	build_visibility
	build_add_to_cart
	
end


program make_item_dictionary

	import delimited "../input/website_design/product_sorting_full_store.csv", varnames(1) clear 
	rename url_name short_name
	rename name full_name
	rename id item_id
	keep item_id short_name full_name
	replace short_name = "dont-lie-to-me"                        if short_name == "donÂt-lie-to-me"
	replace short_name = "the-almanack-of-naval-ravikant"        if short_name == "almanack-naval-ravikant-wealth"
	replace short_name = "the-ghost"                             if short_name == "ghost-secret-spymaster-james"
	replace short_name = "hieronymus-bosch-a-mysterious-profile" if short_name == "hieronymous-bosch-a-mysterious-profile"
	count
	assert r(N) == 100
	save "../temp/item_dict.dta", replace

end


program prepare_chronology

	use "../temp/user_chronology_all.dta", clear
	format %40s action
	format %40s label
	
	bysort user_id (time_stamp): gen time_sec = (time_stamp - time_stamp[_n-1]) / 1000

	drop if action        == "begin_checkout"
	drop if lower(action) == "remove_from_cart"
	drop if lower(action) == "remove from cart"
	drop if action        == "Started Checkout"
	drop if action        == "Completed Checkout"
	drop if action        == "Page Back"
	drop if action        == "Page Reload"
	drop if action        == "Tab ID"                        // revisit this -> see some book names (check if losing something)
	drop if category      == "form" & action == "impression" // temporarily used this for plugin testing
	drop if category      == "ifso_tracking"                 // temporarily used this for plugin testing
	drop if category      == "outbound-link"                 // users clicked on the "woocommerce" promo button
	
	gen event_type = ""
	replace event_type = "coupon_use"   if category == "Coupon"
	replace event_type = "banner_view"  if action == "Viewed" & strpos(label,"Banner") > 0
	replace event_type = "banner_view"  if action == "Viewed" & strpos(label,"Tracker Bar") > 0
	replace event_type = "banner_view"  if action == "Viewed" & strpos(label,"Banner Tracker") > 0
	replace event_type = "banner_click" if action == "Ad Banner Click"
	replace event_type = "banner_click" if action == "Click"  & strpos(label,"Banner") > 0
	replace event_type = "add_to_cart"  if lower(action) == "add_to_cart" 
	replace event_type = "add_to_cart"  if lower(action) == "add to cart"
	replace event_type = "checkout"     if lower(action) == "checkout"
	replace event_type = "checkout"     if lower(action) == "payment"
	replace event_type = "click"        if action == "CLICK"              // note: different event types for clicks
	replace event_type = "click"        if action == "Page View - Custom" // note: different event types for clicks
	replace event_type = "visibility"   if action == "Saw Container"
	sort action label
	count if event_type == ""
	assert r(N) == 0 // assert: all events are classified
	save "../temp/parsed_data/interim_chronology.dta", replace

end


program build_clicks_type1

	* Load and process clicks *
	use "../temp/parsed_data/interim_chronology.dta", clear
	keep if event_type == "click" 
	keep if action == "Page View - Custom"
	keep if strpos(label,"/product/") > 0
	
	* Look up book IDs (clicked books) *
	gen short_name = substr(label,10,strlen(label)-10)
	merge m:1 short_name using "../temp/item_dict.dta"
	assert _merge ~= 2 // assert: found all 100 books
	keep if _merge == 3
	drop _merge
	rename short_name short_name_click
	rename item_id item_id_click

	* Save clicks *
	keep user_id time_stamp item_id_click source_page time_sec
	save "../temp/table_search_type1.dta", replace

end


program build_clicks_type2

	* Load and process clicks *
	use "../temp/parsed_data/interim_chronology.dta", clear
	keep if event_type == "click" 
	keep if action == "CLICK"
	
	* Lookup book IDs (clicked books) *
	replace label = subinstr(label, "&#8217;", "'", .)
	rename label full_name
	recast str500 full_name, force
	merge m:1 full_name using "../temp/item_dict.dta", keep(match) keepusing(full_name item_id) nogenerate
	rename item_id item_id_click
	
	* Save clicks *
	keep user_id time_stamp item_id_click source_page time_sec
	save "../temp/table_search_type2.dta", replace
	
end


program build_clicks_all

	use "../temp/table_search_type1.dta", clear
	append using "../temp/table_search_type2.dta"
	define_source_pages
	rename item_id_click item_id
	sort user_id time_stamp
	keep user_id time_stamp item_id source_type source_genre source_sort source_npage source_id time_sec
	save "../temp/parsed_data/user_clicks_all.dta", replace
	
end


program build_visibility

	* Load visibility events *
	use "../temp/parsed_data/interim_chronology.dta", clear
	keep if event_type == "visibility"

	* Extract books from visibility boxes *
	replace label = subinstr(label, "https://shopper915963729.wpcomstaging.com", "", .)
	replace label = subinstr(label, "Storepage <*>", "", .)
	replace label = subinstr(label, "Related <*>", "", .)
	split label, p("/*/")
	drop label
	forvalues c = 1/10 {
	replace label`c' = subinstr(label`c', "/product", "", .)
	replace label`c' = subinstr(label`c', "/", "", .)
	}
	
	* Wide to long *
	duplicates drop user_id time_stamp source_page, force
	reshape long label, i(user_id time_stamp source_page) j(num)
	rename label short_name
	replace short_name = strtrim(short_name)
	merge m:1 short_name using "../temp/item_dict.dta", keep(match) nogenerate
	keep user_id time_stamp item_id source_page
	rename item_id item_id_view
	
	* Define source page *
	define_source_pages
	rename item_id_view item_id
	keep user_id time_stamp item_id source_type source_genre source_sort source_npage source_id
	save "../temp/parsed_data/user_scrolls_recommendations.dta", replace

end


program build_add_to_cart
	
	* Load add to cart events *
	use "../temp/parsed_data/interim_chronology.dta", clear
	keep if event_type == "add_to_cart"
	
	* Extract item IDs *
	gen flag_string = strpos(source_page,"/product/")
	gen short_name = substr(source_page,flag_string+9,strlen(source_page)-flag_string-9) if flag_string > 0
	merge m:1 short_name using "../temp/item_dict.dta", keepusing(short_name item_id)
	
	* Fillin missing item IDs (encoding errors in raw data) *
	bysort label (item_id): replace item_id = item_id[_n-1] if item_id == . & label == label[_n-1]
	assert item_id ~= . // assert: matched all events to item IDs
	
	* Save add to cart events *
	keep user_id time_stamp item_id
	save "../temp/parsed_data/user_add_to_cart_all.dta", replace

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





