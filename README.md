# Replication Codes and Experimental Data

This repository contains experiment data and replication codes from the paper titled "Where Does Advertising Content Lead You? We Created a Bookstore to Find Out" by Ilya Morozov and Anna Tuchman (Forthcoming in Marketing Science). The SSRN version of this paper can be accessed using this [link](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4308400).

## Codes

The folder "replication_package/code" contains all Stata and R codes necessary to replicate all tables and figures from the paper. This folder contains a batch file "run_code.bat" that runs Stata and R codes in the right sequence, produces data tables, and outputs results in "replication_package/output." The simplest way to replicate the results in the paper is to run the batch file directly (possible on Windows). Alternatively, one can manually clear the contents of the "output" and "temp" folders and run the codes in "analysis/code" in their natural order (1_build_qualtrics.do, 2_perform_matching.do, and so on). To ease replication efforts, we permanently keep our own results in "analysis/output" and "analysis/temp" so that code users can compare their own results to ours. All codes in this repository were tested on Stata 17 and R 4.2.2.

In addition to data analysis codes, we provide the .lyx version of the manuscript in "paper/main_clean.lyx." To replicate the paper from scratch, the user can first run all replication codes and then compile the manuscript in LyX to produce the pdf version of the paper. Doing so will help the user verify that the tables and graphs produced by our replication codes generate a compiled draft that matches the published version of the paper exactly.

## Data

We welcome other researchers to use our experimental data, both for replication purposes and for empirical analyses in their own research projects. Users of our dataset are asked to cite the Marketing Science paper as indicated at the end of this document.

All data files are stored in the folder "replication_package/input", which contains the following data tables:
1. Qualtrics. Contains the raw data pull from Qualtrics (we removed IP addresses and hashed MTurk IDs to protect participants' privacy).
2. Google Analytics. Contains the raw logs of events (product views, clicks, etc.) we pulled from Google Analytics API using our Google account.
3. Woocommerce. Contains the dataset of all purchases submitted through the checkout page of our WooCommerce bookstore.
4. Books unredeemed. The table of all books that were not yet redeemed two weeks after we sent them to participants. We downloaded these lists directly from Kellogg's Amazon Business Account.
5. Books sent. The list of all books and redemption links we sent to study participants during our main study.
6. Website design. The dataset of books that were listed in the store during our main study and their attributes (prices, rankings, etc.).

The only dataset that is not published in this replication package is the Comscore dataset of book purchases on Amazon.com. We only use this dataset to produce Figure A5 in Appendix D2. The users who are interested in replicating this graph should directly contact Comscore to request access to this dataset for replication purposes. Once the access is granted, we can share the dataset by providing secure access to the raw .csv and .dta tables. The users can then replicate Figure A5 by placing the Comscore data tables in "replication_code/input/comscore" and running the code "replication_package/code/10_compare_with_comscore.do," which is also included (but is currently commented out of) the batch file run_code.bat.

Researchers who wish to work with a dataset that has already been processed and cleaned may find it helpful to first run the replication codes as detailed above. One of the codes will produce the .dta dataset "replication_package/output/dataset_merged.dta", which is the dataset we use to produce most of the tables and figures in the paper. Alternatively, researchers can work with the dataset "replication_package/temp/parsed_data/interim_chronology.dta" (produced by code "3_parse_google_analytics.do"), which contains more disaggregated search data. In particular, unlike "dataset_merged.dta" where the data are at the consumer level, "interim_chronology.dta" contains a list of all relevant search events, so the data are at the event level.

## References 

Morozov, Ilya, and Anna Tuchman. "Where Does Advertising Content Lead You? We Created a Bookstore to Find Out." Marketing Science, 2004, 43(5), pp. 986–1001.
