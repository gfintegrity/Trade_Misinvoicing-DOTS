# Trade_Misinvoicing-DOTS Project

## Project Introduction
Trade misinvoicing is a main source of global illicit flows. GFI uses data from Comtrade database to analyze trade misinvoicing between countries. Comtrade database provides detailed information including trade invoicing value, report country, partner country, year, trade direction as well as commodity type in HS code. But some countries are unavailable in Comtrade. So GFI set up a back up project, using DOTS database to analyze trade misinvoicing between countries. Although DOTS doesn't include commodity infomation, it includes more countries than Comtrade. 

Besides analyzing trade misinvoicing values, this project has two other highlights: 

(1) It adjusts re-import and re-export data in Hong Kong and reduces the overestimating trade misinvoicing value especially for China. (What's re-import and re-export? Hong Kong, as a major transfer city, sometimes is recorded as export country or import destination in international trade. It consequently leads to trade misinvoicing which is actually not true. Values generated this way is called re-export or re-import.)

(2) We gained lists of 'orphaned' and 'lost' countries. If a report country reported a trade to partner country while the partner didn't report it, we define the reporter as an 'orphaned' country. On the other hand, we define the partner as a 'lost' country under circumstance that it reported a trade while the report country didn't.


## Summary of files
### R code
  1. DOTS_trdmisin.R: R code for organizing trade records in pairs as well as calculating trade misinvoicing between countries.
  
  2. HK adjust 15-16.R: R code for cleaning up re-import and re-export data published by Hong Kong government and reducing them from trade misinvoicing.
  
### CSV files
  1. DOTS_trdmisin_15&16.csv.zip: adjusted trade misinvoicing results between countries for year 2015 and 2016.
  
  2. DOTS_orphaned&lost_15-16.csv: orphaned and lost records for 2015 and 2016.
  
  3. dot_export.csv: adjusted trade misinvoicing between countries for all years in export direction.
  
  4. dot_import.csv: adjusted trade misinvoicing between countries for all years in import direction.
  
### DOC files
  1. Data Processing for DOTS back up plan: decribe specific data processing for this project.


## Future work
I'm now working on updating yearly exchange rate automatically from website using web scraping and applying the values into project.
