# PPP_Loan_Data
Cleaned up and aggregated CSVs of the data available here: https://home.treasury.gov/policy-issues/cares-act/assistance-for-small-businesses/sba-paycheck-protection-program-loan-level-data

# Important Notes Concerning CSVs

The government is currently capturing the loan data in two different ways based on how much money was asked for. The first way is for any loans under 150k you will know the exact amount, but you will not know the name or address of the business. This is why there is a file capturing the NAISC definitions for a small business. These definitions will be accurate until they are redefined in 2027. The second set of loan data is anyone who asked for more than 150k you will know the business + address information of that business but you will not know the exact amount they asked for. This also contains the NAISC code so it is highly recommended you use that to join/understand both data sets.

# Important Notes Concerning Schema

The schema is a WIP and for now thrown into a single script. It is only focused on the 150+ loan dataset due to trying to solve the problem of identifying a business that applied for multiple loans (with slightly different names).

# Important Notes Concerning Source Data + Documentation

For the rebels who want to start from scratch, but don't want to download each file individually I've put the untouched versions + documentation around (allthethings).