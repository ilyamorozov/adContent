clear all


program main

	demand_rotation_genre
	demand_rotation_price
	descriptive_histograms
	plot_spatial_spillovers
	
end


program demand_rotation_genre

	use "../output/dataset_merged.dta", clear

	gen treatment = .
	replace treatment = 1 if ad_condition == 1 | ad_condition == 4  // genre ad (any book)
	replace treatment = 0 if ad_condition == 2 | ad_condition == 5  // plain ad (any book)	
	
	gen     ad_genre_rank     = romance_rank if (ad_condition == 1 | ad_condition == 2)
	replace ad_genre_rank     = mystery_rank if (ad_condition == 4 | ad_condition == 5)

	gen     clicked_ad_book   = clicked_203   if (ad_condition == 1 | ad_condition == 2)
	replace clicked_ad_book   = clicked_303   if (ad_condition == 4 | ad_condition == 5)
	gen     purchased_ad_book = purchased_203 if (ad_condition == 1 | ad_condition == 2)
	replace purchased_ad_book = purchased_303 if (ad_condition == 4 | ad_condition == 5)
	
	forvalues g = 1/5 {
		gen ad_genre_rank`g' = (ad_genre_rank == `g')
	}
	forvalues g = 1/5 {
		gen ad_genre_rank`g'_treatment = ad_genre_rank`g' * treatment
	}
	drop ad_genre_rank
	
	* Visualize averages *
	regress clicked_ad_book ad_genre_rank1 ad_genre_rank2 ad_genre_rank3 ad_genre_rank4 ad_genre_rank5 if treatment==0, noconstant
	estimates store D
	regress clicked_ad_book ad_genre_rank1 ad_genre_rank2 ad_genre_rank3 ad_genre_rank4 ad_genre_rank5 if treatment==1, noconstant
	estimates store F
	coefplot (D, offset(-0.00)) (F, msymbol(S) offset(0.00)  lpattern(dash) lcolor(maroon) mcolor(maroon)), vertical recast(connected)  ylabel(, nogrid labsize(medlarge)) legend(label(1 "Plain Ad") label(2 "Genre Ad") size(medium) col(1) ring(0) position (2)) xlabel(1 "1st" 2 "2nd" 3 "3rd" 4 "4th" 5 "5th", labsize(medlarge)) noci msize(1) title("(A) Genre Ads Polarize Search Probabilities") ytitle("Search rate (advertised book)", size(medlarge)) xtitle("Stated taste for the advertised genre (rank)", size(medlarge)) graphregion(fcolor(white) lcolor(white) ifcolor(white))
	graph export "../output/graphs/demand_rotation/rotation_levels_genre.png", replace
	graph close
	
	* Visualize ATE on search rates *
	reg clicked_ad_book ad_genre_rank*, noconstant robust
	coefplot, keep(ad_genre_rank1_treatment ad_genre_rank2_treatment ad_genre_rank3_treatment ad_genre_rank4_treatment ad_genre_rank5_treatment) ci(90 myci) vertical yline(0, lpattern(dash) lcolor(black)) ylabel(, nogrid labsize(medlarge)) xlabel(1 "1st" 2 "2nd" 3 "3rd" 4 "4th" 5 "5th", labsize(medlarge)) title("Estimated ATE of Genre Ads") ytitle("ATE on search rate (advertised book)", size(medlarge)) xtitle("Stated taste for the advertised genre (rank)", size(medlarge)) graphregion(fcolor(white) lcolor(white) ifcolor(white))
	graph export "../output/graphs/demand_rotation/rotation_ate_genre.png", replace
	graph close
	
end


program demand_rotation_price
	
	use "../output/dataset_merged.dta", clear

	gen treatment = .
	replace treatment = 1 if ad_condition == 3 | ad_condition == 6  // price ad (any book)
	replace treatment = 0 if ad_condition == 2 | ad_condition == 5  // plain ad (any book)	
	
	gen     ad_genre_rank     = romance_rank if (ad_condition == 3 | ad_condition == 2)
	replace ad_genre_rank     = mystery_rank if (ad_condition == 6 | ad_condition == 5)

	gen     clicked_ad_book   = clicked_203   if (ad_condition == 3 | ad_condition == 2)
	replace clicked_ad_book   = clicked_303   if (ad_condition == 6 | ad_condition == 5)
	gen     purchased_ad_book = purchased_203 if (ad_condition == 3 | ad_condition == 2)
	replace purchased_ad_book = purchased_303 if (ad_condition == 6 | ad_condition == 5)
	
	forvalues g = 1/5 {
		gen ad_genre_rank`g' = (ad_genre_rank == `g')
	}
	forvalues g = 1/5 {
		gen ad_genre_rank`g'_treatment = ad_genre_rank`g' * treatment
	}
	drop ad_genre_rank
	
	* Visualize averages *
	regress clicked_ad_book ad_genre_rank1 ad_genre_rank2 ad_genre_rank3 ad_genre_rank4 ad_genre_rank5 if treatment==0, noconstant
	estimates store D
	regress clicked_ad_book ad_genre_rank1 ad_genre_rank2 ad_genre_rank3 ad_genre_rank4 ad_genre_rank5 if treatment==1, noconstant
	estimates store F
	coefplot (D, offset(-0.00)) (F, msymbol(S) offset(0.00)  lpattern(dash) lcolor(maroon) mcolor(maroon)), vertical recast(connected) ylabel(, nogrid labsize(medlarge)) legend(label(1 "Plain Ad") label(2 "Price Ad") size(medium) col(1) ring(0) position(2)) xlabel(1 "1st" 2 "2nd" 3 "3rd" 4 "4th" 5 "5th", labsize(medlarge)) noci msize(1) title("(B) Price Ads Increase Search Probabilities") ytitle("Search rate (advertised book)", size(medlarge)) xtitle("Stated taste for the advertised genre (rank)", size(medlarge)) graphregion(fcolor(white) lcolor(white) ifcolor(white))
	graph export "../output/graphs/demand_rotation/rotation_levels_price.png", replace
	graph close
	
	* Visualize ATE on search rates *
	reg clicked_ad_book ad_genre_rank*, noconstant robust
	coefplot, keep(ad_genre_rank1_treatment ad_genre_rank2_treatment ad_genre_rank3_treatment ad_genre_rank4_treatment ad_genre_rank5_treatment) ci(90 myci) vertical yline(0, lpattern(dash) lcolor(black)) ylabel(, nogrid labsize(medlarge)) xlabel(1 "1st" 2 "2nd" 3 "3rd" 4 "4th" 5 "5th", labsize(medlarge)) title("Estimated ATE of Price Ads") ytitle("ATE on search rate (advertised book)", size(medlarge)) xtitle("Stated taste for the advertised genre (rank)", size(medlarge)) graphregion(fcolor(white) lcolor(white) ifcolor(white))
	graph export "../output/graphs/demand_rotation/rotation_ate_price.png", replace
	graph close

end


program descriptive_histograms

	* Time spent in the store *
	use "../output/dataset_merged.dta", clear
	sum session_duration
	local mean_duration = round(r(mean), 0.01)
	histogram session_duration if session_duration <= 15, percent fcolor(navy) lcolor(navy) lwidth(vvvthin) gap(20) xtitle(Session duration (minutes)) xlabel(#10) title("Time spent shopping in the book store") subtitle("(Average = `mean_duration' minutes)") graphregion(fcolor(white) lcolor(white) ifcolor(white))
	graph export "../output/graphs/descriptives/histogram_duration.png", replace

	* Pages opened *
	sum pages_opened
	local mean_pages_opened = round(r(mean), 0.01)
	replace pages_opened = 10 if pages_opened > 10
	histogram pages_opened if pages_opened >=1 & pages_opened <= 10, discrete percent fcolor(navy) lcolor(navy) lwidth(vvvthin) gap(20) xtitle("# opened product list pages") xlabel(1(1)10) title("Number of opened pages in the product list") subtitle("(Average = `mean_pages_opened' pages)") xlabel(1 "1" 2 "2" 3 "3" 4 "4" 5 "5" 6 "6" 7 "7" 8 "8" 9 "9" 10 "10+") graphregion(fcolor(white) lcolor(white) ifcolor(white))
	graph export "../output/graphs/descriptives/histogram_pages.png", replace
	graph close

end


program plot_spatial_spillovers	   
		   
	* Prepare click data at item-level *
	use "../temp/parsed_data/user_clicks_all.dta", clear
	keep user_id item_id
	duplicates drop user_id item_id, force   
	gen clicked = 1
	save "../temp/clicks_item_level.dta", replace 
	
	* Load purchase data and create balanced panel *
	use "../output/dataset_merged.dta", clear
	keep user_id item_id ad_condition
	drop if item_id == .
	gen purchased = 1
	fillin user_id item_id   // create balanced panel
	replace purchased = 0 if purchased == .
	bysort user_id: egen condition = max(ad_condition)
	drop ad_condition _fillin
	
	* Add clicks *
	merge 1:1 user_id item_id using "../temp/clicks_item_level.dta", keep(1 3) nogenerate
	replace clicked = 0 if clicked == .

	* Merge with prices and ranks *
	gen num = _n
	merge m:1 item_id using "../temp/prices.dta", keep(1 3) nogenerate
	merge m:1 item_id using "../temp/positions.dta", keep(1 3) keepusing(store_page store_position category name) nogenerate   
	save "../temp/analysis_sample_merged.dta", replace

	* Define treatment "Lost Girls" *
	gen treatment = .
	replace treatment = 1 if condition == 1 | condition == 2 | condition == 3
	replace treatment = 0 if condition == 0
 
	* ATE spillovers (lost girls + purchases) *
	gen outcome = purchased
	quietly run_spillover_regression
	coefplot, keep(ad_position*) ci(90 myci) legend(order(3 "ATE on purchase rate" 1 "90% CI")) text(13.3 0.041 "Advertised Book", size(.2cm)) coeflabels(, labsize(small)) xline(0) yline(10.5, lpattern(dash) lcolor(black) lwidth(thin)) title("Spillovers from advertising 'Lost Girls' to other books", size(medsmall)) xscale(range(0.08)) xlabel(-0.02(0.02)0.08) graphregion(fcolor(white) lcolor(white) ifcolor(white))
	graph export "../output/graphs/spillovers_by_rank1.png", replace
	graph close
	drop position* ad_position* ad_other outcome
	
	* ATE spillovers (lost girls + clicks) *
	gen outcome = clicked
	quietly run_spillover_regression
	coefplot, keep(ad_position*) ci(90 myci) legend(order(3 "ATE on search rate" 1 "90% CI")) text(13.3 0.070 "Advertised Book", size(.2cm)) mcolor(maroon) ciopts(color(maroon)) coeflabels(, labsize(small)) xline(0) yline(10.5, lpattern(dash) lcolor(black) lwidth(thin)) title("Spillovers from advertising 'Lost Girls' to other books", size(medsmall)) xscale(range(0.08)) xlabel(-0.04(0.02)0.08) graphregion(fcolor(white) lcolor(white) ifcolor(white))
	graph export "../output/graphs/spillovers_by_rank1_clicks.png", replace
	graph close
	drop position* ad_position* ad_other outcome

	* Define treatment "Stateline" *
	drop treatment
	gen treatment = .
	replace treatment = 1 if condition == 4 | condition == 5 | condition == 6
	replace treatment = 0 if condition == 0
 
	* ATE spillovers (stateline + purchases) *
	gen outcome = purchased
	quietly run_spillover_regression
	coefplot, keep(ad_position*) ci(90 myci) legend(order(3 "ATE on purchase rate" 1 "90% CI")) text(11.3 0.063 "Advertised Book", size(.2cm)) coeflabels(, labsize(small)) xline(0) yline(10.5, lpattern(dash) lcolor(black) lwidth(thin)) title("Spillovers from advertising 'Stateline' to other books", size(medsmall)) xscale(range(0.08)) xlabel(-0.02(0.02)0.08) graphregion(fcolor(white) lcolor(white) ifcolor(white))
	graph export "../output/graphs/spillovers_by_rank2.png", replace
	graph close
	drop position* ad_position* ad_other outcome
	
	* ATE spillovers (stateline + clicks) *
	gen outcome = clicked
	quietly run_spillover_regression
	coefplot, keep(ad_position*) ci(90 myci) legend(order(3 "ATE on search rate" 1 "90% CI")) text(11.3 0.080 "Advertised Book", size(.2cm)) mcolor(maroon) ciopts(color(maroon)) coeflabels(, labsize(small)) xline(0) yline(10.5, lpattern(dash) lcolor(black) lwidth(thin)) title("Spillovers from advertising 'Stateline' to other books", size(medsmall)) xscale(range(0.08)) xlabel(-0.04(0.02)0.08) graphregion(fcolor(white) lcolor(white) ifcolor(white))
	graph export "../output/graphs/spillovers_by_rank2_clicks.png", replace
	graph close
	drop position* ad_position* ad_other outcome
	
	* Define treatment TWO BOOKS POOLED*
	drop treatment
	gen treatment = .
	replace treatment = 1 if condition  > 0
	replace treatment = 0 if condition == 0
 
	* ATE spillovers TWO BOOKS POOLED (purchases) *
	gen outcome = purchased
	quietly run_spillover_regression
	coefplot, keep(ad_position*) ci(90 myci) legend(order(3 "ATE on purchase rate" 1 "90% CI")) coeflabels(, labsize(small)) xline(0) yline(10.5, lpattern(dash) lcolor(black) lwidth(thin)) title("Advertising spillovers to other books", size(medsmall))  xscale(range(0.08)) xlabel(-0.02(0.02)0.08) graphregion(fcolor(white) lcolor(white) ifcolor(white))
	graph export "../output/graphs/spillovers_pooled.png", replace
	graph close
	drop position* ad_position* ad_other outcome
	
	* ATE spillovers TWO BOOKS POOLED (clicks) *
	gen outcome = clicked
	quietly run_spillover_regression
	coefplot, keep(ad_position*) ci(90 myci) legend(order(3 "ATE on search rate" 1 "90% CI")) mcolor(maroon) ciopts(color(maroon)) coeflabels(, labsize(small)) xline(0) yline(10.5, lpattern(dash) lcolor(black) lwidth(thin)) title("Advertising spillovers to other books", size(medsmall)) xscale(range(0.08)) xlabel(-0.04(0.02)0.08) graphregion(fcolor(white) lcolor(white) ifcolor(white))
	graph export "../output/graphs/spillovers_pooled_clicks.png", replace
	graph close
	drop position* ad_position* ad_other outcome
	
	* Make table of averages (all conditions & all books) *
	collapse (mean) purchased (firstnm) name, by(store_position condition)
	reshape wide purchased, i(store_position) j(condition)
	order store_position name
	forvalues k = 1/6 {
		gen diff`k' = purchased`k' - purchased0
	}
	gen ate_anyad = (purchased1 + purchased2 + purchased3 + purchased4 + purchased5 + purchased6)/6 - purchased0

end


program run_spillover_regression

	* Define position dummies and interactions with treatment *
	forvalues k = 1/20 {
		gen position`k' = (store_position == `k')
		gen ad_position`k' = treatment * position`k'
	}
	gen ad_other = treatment * (store_position > 20)

	* Extract book labels *
	forvalues k = 1/20 {
		gen name_extract = name if store_position == `k'
		gsort -name_extract
		local label_extracted = name_extract[1]
		label variable ad_position`k' "`label_extracted'"
		drop name_extract
	}

	* Run regression *
	gen position_other = (store_position > 20)
	reg outcome position* ad_position* position_other ad_other

end


main
 
