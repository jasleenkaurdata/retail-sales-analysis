-- Business analysis queries
/*
10 QUESTIONS TO ANSWER:
Total Revenue
Monthly Revenue Trend
Top 10 Products by Revenue
Top 10 Products by Quantity Sold
Revenue by Country
Top 10 Customers by Revenue
Percentage of Revenue from Top 10 Customers (Pareto)
Cancellation Rate
Most Returned Products
Sales by Hour of Day (or Day of Week) */


-- QUESTION 1
SELECT ROUND(SUM(Quantity*UnitPrice),2) AS Total_revenue
FROM sales_data;

-- 	QUESTION 2
SELECT *,MONTHNAME(InvoiceDate) AS month_name
FROM sales_data;  -- null cauz Invoicedate is in text form

SELECT YEAR(STR_TO_DATE(InvoiceDate, '%m/%d/%Y %H:%i')
)AS year,
MONTH(
STR_TO_DATE(InvoiceDate, '%m/%d/%Y %H:%i')
)AS month_number,
MONTHNAME(
STR_TO_DATE(InvoiceDate, '%m/%d/%Y %H:%i')
)AS month_name,
ROUND(SUM(Quantity*UnitPrice),2) AS monthly_revenue
FROM sales_data
GROUP BY year, month_number,month_name
ORDER BY year,month_number ASC;


WITH t AS (SELECT YEAR(STR_TO_DATE(InvoiceDate, '%m/%d/%Y %H:%i')
)AS year,
MONTH(
STR_TO_DATE(InvoiceDate, '%m/%d/%Y %H:%i')
)AS month_number,
MONTHNAME(
STR_TO_DATE(InvoiceDate, '%m/%d/%Y %H:%i')
)AS month_name,
ROUND(SUM(Quantity*UnitPrice),2) AS monthly_revenue
FROM sales_data
GROUP BY year, month_number,month_name
ORDER BY year,month_number ASC
)
SELECT * FROM t 
ORDER BY monthly_revenue DESC
LIMIT 1;  -- month which generated max revenue(november 15L)

WITH t AS (SELECT YEAR(STR_TO_DATE(InvoiceDate, '%m/%d/%Y %H:%i')
)AS year,
MONTH(
STR_TO_DATE(InvoiceDate, '%m/%d/%Y %H:%i')
)AS month_number,
MONTHNAME(
STR_TO_DATE(InvoiceDate, '%m/%d/%Y %H:%i')
)AS month_name,
ROUND(SUM(Quantity*UnitPrice),2) AS monthly_revenue
FROM sales_data
GROUP BY year, month_number,month_name
ORDER BY year,month_number ASC
)
SELECT * FROM t 
ORDER BY monthly_revenue ASC
LIMIT 1 ; --  -- month which generated least revenue(feb 5L)

WITH t AS (SELECT YEAR(STR_TO_DATE(InvoiceDate, '%m/%d/%Y %H:%i')
)AS year,
MONTH(
STR_TO_DATE(InvoiceDate, '%m/%d/%Y %H:%i')
)AS month_number,
MONTHNAME(
STR_TO_DATE(InvoiceDate, '%m/%d/%Y %H:%i')
)AS month_name,
ROUND(SUM(Quantity*UnitPrice),2) AS monthly_revenue
FROM sales_data
GROUP BY year, month_number,month_name
ORDER BY year,month_number ASC
)
SELECT *,
LAG(monthly_revenue) OVER(ORDER BY year,month_number,month_name) AS prev_revenue,
CONCAT(ROUND
(100*(monthly_revenue - LAG(monthly_revenue) OVER(ORDER BY year,month_number,month_name))/
(LAG(monthly_revenue) OVER(ORDER BY year,month_number,month_name)),2),"%") AS pcnt_change,
CASE
           WHEN monthly_revenue >
                LAG(monthly_revenue) OVER(ORDER BY year,month_number)
                THEN 'Increase'
           WHEN monthly_revenue <
                LAG(monthly_revenue) OVER(ORDER BY year,month_number)
                THEN 'Decrease'
           ELSE 'No Change'
       END AS trend
FROM t;  --  extracted he previous month sales,perecnt change and wheater its inc or dec


WITH a AS 
(WITH t AS (SELECT YEAR(STR_TO_DATE(InvoiceDate, '%m/%d/%Y %H:%i')
)AS year,
MONTH(
STR_TO_DATE(InvoiceDate, '%m/%d/%Y %H:%i')
)AS month_number,
MONTHNAME(
STR_TO_DATE(InvoiceDate, '%m/%d/%Y %H:%i')
)AS month_name,
ROUND(SUM(Quantity*UnitPrice),2) AS monthly_revenue
FROM sales_data
GROUP BY year, month_number,month_name
ORDER BY year,month_number ASC
)
SELECT *,
LAG(monthly_revenue) OVER(ORDER BY year,month_number,month_name) AS prev_revenue,
ROUND
(100*(monthly_revenue - LAG(monthly_revenue) OVER(ORDER BY year,month_number,month_name))/
(LAG(monthly_revenue) OVER(ORDER BY year,month_number,month_name)),2) AS pcnt_change,
CASE
           WHEN monthly_revenue >
                LAG(monthly_revenue) OVER(ORDER BY year,month_number)
                THEN 'Increase'
           WHEN monthly_revenue <
                LAG(monthly_revenue) OVER(ORDER BY year,month_number)
                THEN 'Decrease'
           ELSE 'No Change'
       END AS trend
FROM t)
SELECT * FROM a 
ORDER BY pcnt_change DESC
LIMIT 1; -- highest pcnt change of 43.27 in may

WITH a AS 
(WITH t AS (SELECT YEAR(STR_TO_DATE(InvoiceDate, '%m/%d/%Y %H:%i')
)AS year,
MONTH(
STR_TO_DATE(InvoiceDate, '%m/%d/%Y %H:%i')
)AS month_number,
MONTHNAME(
STR_TO_DATE(InvoiceDate, '%m/%d/%Y %H:%i')
)AS month_name,
ROUND(SUM(Quantity*UnitPrice),2) AS monthly_revenue
FROM sales_data
GROUP BY year, month_number,month_name
ORDER BY year,month_number ASC
)
SELECT *,
LAG(monthly_revenue) OVER(ORDER BY year,month_number,month_name) AS prev_revenue,
ROUND
(100*(monthly_revenue - LAG(monthly_revenue) OVER(ORDER BY year,month_number,month_name))/
(LAG(monthly_revenue) OVER(ORDER BY year,month_number,month_name)),2) AS pcnt_change,
CASE
           WHEN monthly_revenue >
                LAG(monthly_revenue) OVER(ORDER BY year,month_number)
                THEN 'Increase'
           WHEN monthly_revenue <
                LAG(monthly_revenue) OVER(ORDER BY year,month_number)
                THEN 'Decrease'
           ELSE 'No Change'
       END AS trend
FROM t)
SELECT * FROM a 
WHERE pcnt_change IS NOT NULL
ORDER BY pcnt_change ASC
LIMIT 1; -- Lowest pcnt change of -53.59 in december

-- QUESTION 3/4
SELECT StockCode,Description,
SUM(Quantity*UnitPrice) AS revenue
FROM sales_data
WHERE Description NOT IN ("DOTCOM POSTAGE","POSTAGE","Manual")
GROUP BY StockCode,Description
ORDER BY revenue DESC
LIMIT 10;

-- comparing if top 10 products by revenue are also the ones that are top 10 sold quantity wise?
SELECT StockCode,Description,
SUM(Quantity) AS revenue
FROM sales_data
WHERE Description NOT IN ("DOTCOM POSTAGE","POSTAGE","Manual")
GROUP BY StockCode,Description
ORDER BY revenue DESC
LIMIT 10;  

SELECT Description,
       ROUND(AVG(UnitPrice),2) AS avg_price
FROM sales_data
WHERE Description = 'REGENCY CAKESTAND 3 TIER' -- isnt in top 10 quantity and has higher avg price of 13rs
GROUP BY Description;
SELECT Description,
       ROUND(AVG(UnitPrice),2) AS avg_price
FROM sales_data
WHERE Description = 'PAPER CRAFT , LITTLE BIRDIE'
GROUP BY Description;  -- is in both top 10 revenue and quantity and has lower avg price 2rs
-- so products that only gave higher revenue and were not sold that much have higher price thats why it contirbutes to revenue 

-- QUESTION 5
SELECT Country,SUM(Quantity*UnitPrice) AS revenue
FROM sales_data
GROUP BY Country
ORDER BY revenue DESC
LIMIT 1;-- UK at top with 90L of revenue
-- how dominating is uk in the total revenue?
SELECT Country,
revenue,
ROUND(100*revenue/(SELECT SUM(UnitPrice*Quantity) FROM sales_data),2) AS pcnt_contri
FROM(SELECT Country,
SUM(Quantity*UnitPrice) AS revenue
FROM sales_data
GROUP BY Country
ORDER BY revenue DESC
LIMIT 1) t ; -- UK is contributing 84 percent in total revenue generated

SELECT * FROM sales_data;
-- QUESTION 6
SELECT CustomerID,
SUM(Quantity*UnitPrice) AS rev
FROM sales_data
WHERE CustomerID IS NOT NULL
AND CustomerID <> ''
GROUP BY CustomerID
ORDER BY rev DESC
LIMIT 10; -- got it
-- how many orders did these customers have?Avg order value?
SELECT CustomerID,
ROUND(SUM(Quantity*UnitPrice)) AS rev,
COUNT(DISTINCT(InvoiceNo)) AS orders,
ROUND(SUM(Quantity*UnitPrice) / COUNT(DISTINCT InvoiceNo),2) AS avg_order_value
FROM sales_data
WHERE CustomerID IS NOT NULL
AND CustomerID <> ''
GROUP BY CustomerID
ORDER BY rev DESC
LIMIT 10;

-- QUESTION 7
WITH customer_revenue AS (
    SELECT CustomerID,
           SUM(Quantity * UnitPrice) AS revenue
    FROM sales_data
    WHERE CustomerID IS NOT NULL
      AND CustomerID <> ''
    GROUP BY CustomerID
)
SELECT ROUND(
    100 * SUM(revenue) /
    (SELECT SUM(revenue) FROM customer_revenue),  -- denominator is imp customer id not null like the numerator
    2
) AS pct_revenue_top10
FROM (
    SELECT revenue
    FROM customer_revenue
    ORDER BY revenue DESC
    LIMIT 10
) t; -- 17% (Pareto analysis)

-- QUESTION 8
SELECT
    COUNT(*) AS cancelled_transactions, -- 9251 cancellations
    ROUND(
        100 * COUNT(*) /
        (SELECT COUNT(*) FROM or_clean),
        2
    ) AS cancellation_rate
FROM or_clean
WHERE InvoiceNo LIKE 'C%'; -- 1.72% rate

-- QUESTION 9
SELECT
    StockCode,
    Description,
    ABS(SUM(Quantity)) AS returned_units
FROM or_clean
WHERE InvoiceNo LIKE 'C%'
AND Description NOT IN ("DOTCOM POSTAGE","POSTAGE","Manual")
GROUP BY StockCode, Description
ORDER BY returned_units DESC
LIMIT 10;

-- QUESTION 10
SELECT
    HOUR(
        STR_TO_DATE(InvoiceDate, '%m/%d/%Y %H:%i')
    ) AS hour_of_day,

    ROUND(SUM(Quantity * UnitPrice),2) AS revenue

FROM sales_data

GROUP BY hour_of_day

ORDER BY revenue DESC;  -- 10AM maximum revenue
