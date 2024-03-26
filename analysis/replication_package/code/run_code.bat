REM ****************************************************
REM * run_code.bat: double-click to run all scripts
REM ****************************************************

RMDIR ..\temp /S /Q
RMDIR ..\output /S /Q
MKDIR ..\temp
MKDIR ..\output

%STATAEXE% /e do 1_build_qualtrics.do
%STATAEXE% /e do 2_perform_matching.do
%STATAEXE% /e do 3_parse_google_analytics.do
%STATAEXE% /e do 4_build_google_analytics.do
%STATAEXE% /e do 5_analyze_randomization_checks.do
%STATAEXE% /e do 6_analyze_ad_effects.do
%STATAEXE% /e do 7_visualize_results.do
%STATAEXE% /e do 8_validate_choices.do
%REXE% CMD BATCH 9_ate_bar_charts.R
REM %STATAEXE% /e do 10_compare_with_comscore.do

PAUSE
