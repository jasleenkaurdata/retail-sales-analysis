-- Data cleaning queries
CREATE TABLE online_retails (
    InvoiceNo VARCHAR(20),
    StockCode VARCHAR(20),
    Description TEXT,
    Quantity INT,
    InvoiceDate VARCHAR(30),
    UnitPrice DECIMAL(10,2),
    CustomerID VARCHAR(20),
    Country VARCHAR(100)
) CHARACTER SET latin1;

LOAD DATA LOCAL INFILE 'C:/Users/USER/Downloads/archive (3)/data.csv'
INTO TABLE online_retails
CHARACTER SET latin1
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
SELECT COUNT(*) FROM online_retails;

SELECT 
SUM(quantity*UnitPrice) AS TotalSales
FROM online_retails;

-- 1.CHECKING DUPLICATES AND REMOVING THEM KEEPING ONE FROM EACH(OBV)
SELECT InvoiceNo,StockCode,Description,Quantity,InvoiceDate,UnitPrice,CustomerID,Country,COUNT(*) AS dupes
FROM online_retails
GROUP BY InvoiceNo,StockCode,Description,Quantity,InvoiceDate,UnitPrice,CustomerID,Country
HAVING COUNT(*)>1;

SELECT SUM(cnt - 1) AS duplicate_rows_to_remove
FROM (
    SELECT COUNT(*) AS cnt
    FROM online_retails
    GROUP BY InvoiceNo, StockCode, Description, Quantity,
             InvoiceDate, UnitPrice, CustomerID, Country
    HAVING COUNT(*) > 1
) t;

CREATE TABLE online_retails_backup AS
SELECT *
FROM online_retails;

CREATE TABLE or_clean AS
SELECT DISTINCT * FROM online_retails;
SELECT COUNT(*) FROM or_clean;  -- sucessfully removed duplicate rows and kept 1.

SELECT * FROM or_clean;

-- CHECKING MISSING VALUES 
SELECT COUNT(*) AS missing_cid
FROM or_clean
WHERE CustomerID IS NULL
   OR CustomerID = '';  -- 1L
SELECT COUNT(*) AS missing_des
FROM or_clean
WHERE Description IS NULL
OR TRIM(Description)='';  -- 1454
SELECT COUNT(*) AS missing_country
FROM or_clean
WHERE Country IS NULL
   OR Country = ''; -- 0
SELECT COUNT(*) AS missing_Invoiceno
FROM or_clean
WHERE InvoiceNo IS NULL
   OR InvoiceNo = '';  -- 0
SELECT COUNT(*) AS missing_stockcode
FROM or_clean
WHERE StockCode IS NULL
   OR StockCode = '';  -- 0
SELECT COUNT(*) AS missing_quantity
FROM or_clean
WHERE Quantity IS NULL;  -- 0
SELECT COUNT(*) AS missing_unitprice
FROM or_clean
WHERE UnitPrice IS NULL;  -- 0

-- how much percentage of customer id missing?
SELECT CONCAT(ROUND(COUNT(*)*100/(SELECT COUNT(*) FROM or_clean),2),"%") AS pcnt_of_missingcid
FROM or_clean
WHERE CustomerId IS NULL
OR CustomerId='';  -- thus 25.16% missing customer ids which is quite a chunk and we know rest of their parameters so we keep it.

-- ANALYZE THE CANCELLATIONS 
SELECT COUNT(*) AS cancellations FROM or_clean
WHERE InvoiceNo LIKE "C%"; -- 9k

SELECT CONCAT(ROUND(100*COUNT(*)/(SELECT COUNT(*) FROM or_clean),2),"%") AS pcnt_cancellations
FROM or_clean
WHERE InvoiceNo LIKE "C%";  -- 1.72 percent cancellations

-- NEGATIVE QUANTITIES PRESENT?
SELECT COUNT(*) AS neg_quantities
FROM or_clean
WHERE Quantity<0; -- 10k (Cancellations usually have negative quantity)

-- NEGATIVE UNIT PRICES?
SELECT COUNT(*) AS neg_unitprices
FROM or_clean
WHERE UnitPrice<=0; -- 2k

-- TOTAL REVENUE (OBV EXCLUDING THE CANCELLATIONS)
SELECT ROUND(SUM(Quantity*UnitPrice),2) AS actual_totalsales
FROM or_clean
WHERE InvoiceNo NOT LIKE 'C%'
AND Quantity>0;

-- ANALYZING?
SELECT * 
FROM or_clean
WHERE UnitPrice<=0
LIMIT 100; 

SELECT
SUM(UnitPrice = 0) AS zero_price,  -- 2514
SUM(UnitPrice < 0) AS negative_price -- 2
FROM or_clean;

SELECT Description,
COUNT(*) AS cnt
FROM or_clean
WHERE UnitPrice <= 0
GROUP BY Description
ORDER BY cnt DESC
LIMIT 50;  -- blanks,adjustments,damaged etc.. so we basically dont need all this in our calculations


SELECT Description,
       SUM(Quantity * UnitPrice) AS revenue,
       COUNT(*) AS rows_count
FROM or_clean
WHERE Description IN (
    'Adjustment',
    'Damaged',
    'damages',
    'damages?',
    'Found',
    'check',
    'amazon',
    'sold as set on dotcom',
    'ebay',
    '?',
    'thrown away',
    'Unsaleable, destroyed.',
    '??',
    'wet damaged',
    'smashed'
)
GROUP BY Description; -- all revenues 0 so they are rubbish for insights
-- trying to find more words to exclude (where is revenue 0?)
SELECT Description,
       SUM(Quantity * UnitPrice) AS revenue,
       COUNT(*) AS cnt
FROM or_clean
GROUP BY Description
HAVING revenue = 0
ORDER BY cnt DESC;

-- NOW CREATING A CLEANER ONLY THINGS I NEED EXCLUDING PRODUCTS I DON'T NEED IN REVENUE ANALYSIS
CREATE TABLE sales_data AS
SELECT *
FROM or_clean
WHERE Quantity > 0
  AND UnitPrice > 0
  AND InvoiceNo NOT LIKE 'C%'
  AND TRIM(Description) <> ''
  AND Description NOT IN (
      'Adjustment',
      'Damaged',
      'damages',
      'damages?',
      'Found',
      'check',
      '?',
      '??',
      'thrown away',
      'Unsaleable, destroyed.',
      'wet damaged',
      'smashed',
      'sold as set on dotcom'
  );
SELECT *
FROM sales_data;


