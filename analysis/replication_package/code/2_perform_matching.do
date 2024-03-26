clear all


program main

	merge_raw_data
	build_coupon_usages
	perform_matching
	organize_matches
	define_search_sessions
	
end


program merge_raw_data

	import delimited "../input/google_analytics/wave1/user_chronology.csv", varnames(1) clear
	save "../temp/user_chronology_all.dta", replace
	import delimited "../input/google_analytics/wave2/user_chronology.csv", varnames(1) clear
	append using "../temp/user_chronology_all.dta"
	clean_time_and_ids
	save "../temp/user_chronology_all.dta", replace

end


program clean_time_and_ids

	format client_id %12.0g
	rename client_id user_id
	gen double time_stamp = clock(substr(time, 1, 19), "YMD hms")  - 5*3600000 // to chicago time
	format time_stamp %tc

end


program build_coupon_usages

	* Merge and extract used coupons *
	use "../temp/user_chronology_all.dta", clear
	gen unique_code = upper(label)
	keep if (category=="Coupon") & (length(unique_code)==6 | length(unique_code)==7)
	drop if unique_code == "TEST_C"
	recast str10 unique_code, force

	* Enumerate different uses of the same code (useful for matching below) *
	gen double time_code_used = time_stamp
	bysort unique_code (time): gen num_j = _n
	keep user_id unique_code time_code_used num_j
	order user_id unique_code time_code_used num_j
	save "../temp/all_used_codes.dta", replace

end


program perform_matching

	* How many observations do we need to match? *
	use "../temp/qualtrics_long.dta", clear
	count
	local n_obs = `r(N)'

	* Perform matching *
	local counter = 1
	forvalues i = 1/`n_obs' {
		
		local percent_done = round(100 * `i' /`n_obs',1)
		if mod(`i',100)==0 display "Matching participant `i' out of `n_obs' (progress: `percent_done' percent done)"
		
		* Take one observation and look for the event when someone uses that code *
		use "../temp/qualtrics_long.dta", clear
		quietly keep if num_i == `i'
		quietly keep mturk_id unique_code start_time_cst end_time_cst num_i
		quietly expand 25
		quietly gen num_j = _n
		quietly merge 1:1 unique_code num_j using "../temp/all_used_codes.dta", keep(match) nogenerate
		
		* Do not consider candidate user_id's that have already been matched *
		if `counter' > 1 {
		quietly merge m:1 user_id using "../temp/matched_userids.dta", keep(1) nogenerate
		}
		
		* Match if code was used during the appropriate qualtrics session *
		quietly keep if time_code_used >= start_time_cst & time_code_used <= end_time_cst
		quietly egen users_enumerate = group(user_id)
		quietly sum users_enumerate
		quietly gen num_user_candidates = r(max)
		
		* Keep the first code use instance *
		quietly bysort unique_code (time_code_used): keep if _n == 1
		keep mturk_id unique_code user_id start_time_cst end_time_cst num_i num_user_candidates
		
		* Append to the table of results if nonempty (match found) *
		capture assert _N == 0
		if _rc ~= 0 {
			
			* Add the new match to the crosswalk table *
			quietly if `counter'>1 append using "../temp/crosswalk_userids.dta"
			quietly save "../temp/crosswalk_userids.dta", replace
			
			* Update the list of already matched users *
			quietly use "../temp/crosswalk_userids.dta", clear
			quietly keep user_id
			quietly save "../temp/matched_userids.dta", replace
			
		}
		local counter = `counter' + 1
		
	}

end


program organize_matches

	* How many MTurk IDs did we try to match? *
	use "../temp/qualtrics_long.dta", clear
	duplicates drop mturk_id, force
	count
	local n_obs = `r(N)'
	
	* Select first match for each MTurk ID *
	use "../temp/crosswalk_userids.dta", clear
	bysort mturk_id (start_time_cst): keep if _n == 1
	
	* Analyze the results of matching *
	quietly count
	local n_matched = `r(N)'
	quietly count if num_user_candidates == 1
	local n_matched_unambiguous = `r(N)'
	quietly count if num_user_candidates > 1
	local n_matched_ambiguous = `r(N)'
	local n_unmatched = `n_obs' - `n_matched'
	
	* Report *
	display "Matching outcomes:"
	display "Unmatched participants: `n_unmatched' out of `n_obs'"
	display "Matched participants: `n_matched' out of `n_obs'"
	display "Matched unambiguously: `n_matched_unambiguous' out of `n_obs'"
	display "Matched ambiguously `n_matched_ambiguous' out of `n_obs' (more than one potential match): "
	
	* Save the crosswalk *
	duplicates report user_id
	assert(r(unique_value)==r(N))
	keep mturk_id user_id num_i
	save "../temp/crosswalk_userids.dta", replace
	
	* Update Qualtrics data (keep one survey per person) *
	use "../temp/qualtrics_long.dta", clear
	merge 1:1 num_i using "../temp/crosswalk_userids.dta", keep(match) nogenerate
	drop num_i
	save "../temp/qualtrics.dta", replace

end


program define_search_sessions

	* Limit to observations during qualtrics attempt *
	use "../temp/qualtrics.dta", clear
	keep user_id start_time_cst end_time_cst
	save "../temp/search_sessions.dta", replace
	
	* Truncate search sequences accordingly *
	use "../temp/user_chronology_all.dta", clear
	merge m:1 user_id using "../temp/search_sessions.dta", keep(match) nogenerate
	keep if time_stamp >= start_time_cst & time_stamp <= end_time_cst
	save "../temp/user_chronology_all.dta", replace

end


main

