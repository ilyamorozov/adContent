clear all


/// Time zones:
/// Qualtrics data: MDT = Chicago Time -1h
/// Google Analytics data: GMT = Chicago Time +5h
/// Cloud Research data: EST = Chicago Time +1h


program main

	create_directories
	build_qualtrics
	who_guessed_the_purpose

end


program create_directories

	mkdir "../temp/user_data/"
	mkdir "../temp/parsed_data/"
	mkdir "../output/tables/"
	mkdir "../output/tables/ate_estimates/"
	mkdir "../output/tables/ate_estimates/appendix/"
	mkdir "../output/tables/comscore/"
	mkdir "../output/tables/orders_summary/"
	mkdir "../output/graphs/"
	mkdir "../output/graphs/descriptives/"
	mkdir "../output/graphs/genre_choices/"
	mkdir "../output/graphs/genre_preferences/"
	mkdir "../output/graphs/demand_rotation/"
	mkdir "../output/graphs/main_ate/"
	mkdir "../output/estimates/"

end


program build_qualtrics

	* Load data *
	use "../input/qualtrics/qualtrics_hashed.dta", clear

	* Organize time stamps *
	gen double start_time_mdt = clock(startdate, "MD20Y hm")
	gen double end_time_mdt   = clock(enddate, "MD20Y hm")
	gen double start_time_cst = start_time_mdt + 3600000 // to chicago time
	gen double end_time_cst   = end_time_mdt + 3600000   // to chicago time
	format start_time_mdt end_time_mdt start_time_cst end_time_cst %tc

	* Drop test runs *
	drop if hitid == ""
	drop if distributionchannel == "preview"

	* Passed comprehension checks? *
	gen passed_comprehension = (complottery == 2 | secondchancelottery == 2)
	keep if passed_comprehension == 1
	
	* Finished survey? *
	gen finished_survey = (lostgirlsliking ~= "" & statelineliking ~= "") // answered WTP questions
	
	* Drop attempts after the person has been exposed to WTP questions *
	bysort mturk_id (start_time_cst responseid): gen finished_survey_before = 0 if _n == 1
	bysort mturk_id (start_time_cst responseid): replace finished_survey_before = (finished_survey_before[_n-1]==1 | finished_survey[_n-1]==1) if _n > 1
	drop if finished_survey_before == 1

	* Decipher the dual response answer (no purchase decision) *
	gen dual_response = .
	foreach var of varlist q67-q167 {	
		capture replace dual_response = 1 if `var' == "Yes"
		capture replace dual_response = 0 if `var' == "No"
	}

	* Encode purchase likelihood responses *
	gen lostgirls_likelytobuy = (lostgirlsliking == "Very likely" | lostgirlsliking == "Somewhat likely")
	gen stateline_likelytobuy = (statelineliking == "Very likely" | statelineliking == "Somewhat likely")

	* Encode book preference responses *
	replace ebooks = ""   if ebooks == "I have never read an e-book"
	replace ebooks = "4"  if ebooks == "4 or more"
	destring ebooks, replace
	replace printbooks = "4" if printbooks == "4 or more"
	destring printbooks, replace

	* Encode genre ranking responses *
	rename genrepreferences_1 fantasy_rank
	rename genrepreferences_2 mystery_rank
	rename genrepreferences_3 romance_rank
	rename genrepreferences_4 scifi_rank
	rename genrepreferences_5 memoirs_rank

	* Encode other useful responses *
	rename q561_1 importance_price
	rename q561_2 importance_genre
	rename q561_3 importance_plot
	rename q66 book_code
	
	* Save response time for WTP questions *
	rename t10a_pagesubmit duration_statelinewtp
	rename t10b_pagesubmit duration_lostgirlswtp
	
	* Encode demographic responses *
	gen age_years    = 2022 - age
	gen female       = (gender == "Female") if gender ~= ""
	gen black        = (race == "Black or African American") if race ~= ""
	gen white        = (race == "White, non-Hispanic or Latino" & race ~= "")
	gen hispanic     = (race == "Hispanic or Latino (e.g. Mexican, Puerto Rican, Cuban, etc.)" & race ~= "")
	gen asian        = (race == "Asian Pacific or South-East Asian (e.g. Japanese, Korean, Chinese, Thai, Vietnamese, etc.)") if race ~= ""
	gen income1      = (income == "Less than $10,000" | income == "$10,000 - $20,000") if income ~= ""
	gen income2      = (income == "$20,001 - $50,000") if income ~= ""
	gen income3      = (income == "$50,001- $75,000") if income ~= ""
	gen income4      = (income == "$75,001-$100,000") if income ~= ""
	gen income5      = (income == "$100,001 - $150,000") if income ~= ""
	gen income6      = (income == "$150,001-$250,000" | income == "$250,001-$350,000" | income == "More than $350,000") if income ~= ""
	gen single       = (maritalstatus == "Single, never married") if maritalstatus ~= ""
	gen married      = (maritalstatus == "Married") if maritalstatus ~= ""
	gen partner      = (maritalstatus == "Living with a partner") if maritalstatus ~= ""
	gen divorced     = (maritalstatus == "Divorced") if maritalstatus ~= ""
	gen high_school  = (education == "High school graduate (high school diploma or equivalent including GED)") if education ~= ""
	gen bachelor     = (education == "Bachelor's degree in college (4-year)") if education ~= ""
	gen master       = (education == "Master's degree") if education ~= ""
	gen some_college = (education == "Some college but no degree") if education ~= ""

	* Keep relevant variables *
	order mturk_id unique_code hitid assignmentid start_time_cst end_time_cst zipcode                      ///
		 printbooks ebooks fantasy_rank mystery_rank scifi_rank romance_rank memoirs_rank                  ///
		 female black hispanic asian income1 income2 income3 income4 income5 income6                       ///
		 age_years bachelor master some_college married divorced                                           ///
		 statelinewtp_1 lostgirlswtp_1 statelineliking lostgirlsliking                                     ///
		 duration_statelinewtp duration_lostgirlswtp                                                       ///
		 lostgirls_likelytobuy stateline_likelytobuy                                                       ///
		 book_code dual_response importance_price importance_genre importance_plot purposeofstudy
	keep mturk_id-importance_plot finished_survey responseid purposeofstudy
	sort start_time_cst end_time_cst
	format %15s mturk_id assignmentid
	format %30s hitid assignmentid
	sort mturk_id start_time_cst responseid // last variable added for unique sort
	gen num_i = _n
	
	save "../temp/qualtrics_long.dta", replace
	
	count

end


program who_guessed_the_purpose

	use "../temp/qualtrics_long.dta", clear
	replace purposeofstudy = lower(purposeofstudy)
	gen flag_guessed_ads = (strpos(purposeofstudy, " ads ") + strpos(purposeofstudy, " advertising ") + strpos(purposeofstudy, " advertisements "))>0
	browse if flag_guessed_ads == 1
	browse if flag_guessed_ads == 0
	tab flag_guessed_ads

end


main

