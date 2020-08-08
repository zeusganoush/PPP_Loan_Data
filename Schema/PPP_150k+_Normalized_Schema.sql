USE [database]
GO

/* Use this to clean up/normalize the loan data of 150k+ */

SELECT DISTINCT SUBSTRING(loanrange, CHARINDEX('$',LoanRange) + 1, CHARINDEX('-',LoanRange) - CHARINDEX('$',LoanRange) -1) as min_loan_range
, SUBSTRING(loanrange, CHARINDEX('-',LoanRange) + 1,LEN(LoanRange) - CHARINDEX('-',LoanRange)) as max_loan_range
, substring(loanrange,1,1) as loan_range_letter
, REPLACE(substring(loanrange,patindex('%[0-9]%',loanrange),2),'-','0')
, patindex('%[0-9]%',loanrange)
, LoanRange
  FROM [database].[dbo].[tableName]

DROP TABLE IF EXISTS dbo.PPP_Loan_Range
GO

CREATE TABLE dbo.PPP_Loan_Range
( loan_range_id INT IDENTITY(1,1) PRIMARY KEY
, min_loan_range DECIMAL(19,4)
, max_loan_range DECIMAL(19,4)
, loan_range_letter VARCHAR(1)
)
GO

INSERT INTO dbo.PPP_Loan_Range (min_loan_range, max_loan_range, loan_range_letter)
VALUES
 (150000,	350000,	'e')
,(350000,	1000000,'d')
,(2000000,	5000000,'b')
,(1000000,	2000000,'c')
,(5000000,	10000000,'a')

GO

/*This is a work in progress because getting the python integration to work wasn't as straightforward as I thought.*/
DROP TABLE IF EXISTS dbo.PPP_Business_Fuzzy 
GO

CREATE TABLE dbo.PPP_Business_Fuzzy
( business_fuzzy_id INT IDENTITY(1,1) PRIMARY KEY
, business_fuzzy_name VARCHAR(200)
, confidence_percentage DECIMAL(10,7)
)

DROP TABLE IF EXISTS dbo.PPP_Business

CREATE TABLE dbo.PPP_Business
( business_id INT IDENTITY(1,1) PRIMARY KEY
, business_name VARCHAR(200)
, NAICS_code VARCHAR(10)
, business_type VARCHAR(100)
, is_nonprofit BIT
)

GO

INSERT INTO dbo.PPP_Business (business_name, NAICS_code, is_nonprofit, business_type)
SELECT DISTINCT BusinessName, NAICSCode, CASE WHEN NonProfit = 'Y' THEN 1 ELSE 0 END, BusinessType
FROM [database].[dbo].[tableName]

GO

DROP TABLE IF EXISTS dbo.PPP_Business_Address

CREATE TABLE dbo.PPP_Business_Address
( business_address_id INT IDENTITY(1,1) PRIMARY KEY
, business_address VARCHAR(400)
, business_city VARCHAR(250)
, business_state VARCHAR(10)
, business_zip VARCHAR(15)
)

GO

INSERT INTO dbo.PPP_Business_Address (business_address, business_city, business_state, business_zip)
SELECT DISTINCT Address, City, State, Zip
FROM [database].[dbo].[tableName]

GO

DROP TABLE IF EXISTS dbo.PPP_Business_Address_Link 
GO

CREATE TABLE dbo.PPP_Business_Address_Link
( business_address_link_id INT IDENTITY(1,1)
, business_id INT
, business_address_id INT
)

GO

INSERT INTO dbo.PPP_Business_Address_Link (business_id, business_address_id)
SELECT DISTINCT business_id, business_address_id
FROM [database].[dbo].[tableName]
INNER JOIN dbo.PPP_Business ON business_name = BusinessName
	   AND NAICS_code = NAICSCode
	   AND BusinessType = business_type
INNER JOIN dbo.PPP_Business_Address ON business_address = Address
and business_city = City
and business_state = state 
and business_zip = Zip

DROP TABLE IF EXISTS dbo.PPP_Lender 

CREATE TABLE dbo.PPP_Lender
( lender_id INT IDENTITY(1,1) PRIMARY KEY
, lender_name VARCHAR(250)
)

GO

INSERT INTO dbo.PPP_Lender (lender_name)
SELECT DISTINCT Lender
FROM [database].[dbo].[tableName]

DROP TABLE IF EXISTS dbo.PPP_Loan

CREATE TABLE dbo.PPP_Loan
( loan_id INT IDENTITY(1,1) PRIMARY KEY
, loan_range_id INT
, business_address_link_id INT
, lender_id INT
, employee_retained_count INT
, loan_approval_date DATE
)

SELECT ROW_NUMBER() OVER (ORDER BY businessname) as loan_id, *
INTO #Loan_with_Key
FROM [database].[dbo].[tableName]

GO

CREATE OR ALTER VIEW dbo.PPP_Business_Address_View
AS

select bal.business_address_link_id, b.*, ba.*
from dbo.PPP_Business_Address_Link as bal
INNER JOIN dbo.PPP_Business as b on b.business_id = bal.business_id
INNER JOIN dbo.PPP_Business_Address as ba on ba.business_address_id = bal.business_address_id

GO


;WITH loan_breakdown AS (SELECT DISTINCT SUBSTRING(loanrange, CHARINDEX('$',LoanRange) + 1, CHARINDEX('-',LoanRange) - CHARINDEX('$',LoanRange) -1) as min_loan_range
, SUBSTRING(loanrange, CHARINDEX('-',LoanRange) + 1,LEN(LoanRange) - CHARINDEX('-',LoanRange)) as max_loan_range
, substring(loanrange,1,1) as loan_range_letter
, loan_id
  FROM #Loan_with_Key)

INSERT INTO dbo.PPP_Loan (loan_range_id, business_address_link_id, lender_id, employee_retained_count, loan_approval_date)
SELECT loan_range_id, business_address_link_id, lender_id, JobsRetained, CAST(dateapproved AS DATE)
FROM #Loan_with_Key
INNER JOIN dbo.PPP_Loan_Range ON REPLACE(substring(loanrange,patindex('%[0-9]%',loanrange),2),'-','0') = substring(CAST(min_loan_range AS VARCHAR(20)),1,2)
INNER JOIN dbo.PPP_Business_Address_View AS business_address ON 
business_name = BusinessName
AND NAICS_code = NAICSCode
AND business_type = BusinessType
AND business_address = Address
and business_city = City
and business_state = state 
and business_zip = Zip
INNER JOIN dbo.PPP_Lender ON lender_name = Lender

GO