CREATE DATABASE IF NOT EXISTS superstore_campaign_response;
USE superstore_campaign_response;

-- DDL

CREATE TABLE IF NOT EXISTS customers (
	id INTEGER PRIMARY KEY NOT NULL,
    if_accepted_offer INTEGER CHECK (if_accepted_offer IN (0, 1)),
    enrollment_date TEXT,
    birth_yr INTEGER,
    edu TEXT,
    marital_status TEXT CHECK (marital_status IN ('Absurd', 'Alone', 'Single','Married','Together', 'Divorced', 'Widow', 'YOLO')),
    income INTEGER,
    kids_in_home INTEGER,
    teens_in_home INTEGER,
    amnt_spent_on_fish INTEGER,
    amnt_spent_on_meat INTEGER,
    amnt_spent_on_fruit INTEGER,
    amnt_spent_on_sweets INTEGER,
    amnt_spent_on_wine INTEGER,
    amnt_spent_on_gold INTEGER,
    discounted_purchases INTEGER,
    catalog_purchases INTEGER,
    store_purchases INTEGER,
    web_purchases INTEGER,
    web_visits_last_month INTEGER,
    days_since_last_purchase INTEGER,
    if_complained INTEGER CHECK (if_complained IN (0, 1))
);

-- DML

-- Update enrollment_date from text to date column
SET SQL_SAFE_UPDATES = 0;
UPDATE customers 
	SET enrollment_date = CAST(STR_TO_DATE(enrollment_date, '%m/%d/%Y') AS DATE);
ALTER TABLE customers MODIFY enrollment_date DATE;
SET SQL_SAFE_UPDATES = 1;


-- Where are the bulk of our customers making their purchases (catalog, store, online)? alter
CREATE VIEW main_source AS
SELECT id, catalog_purchases, store_purchases, web_purchases,
CASE 
	WHEN catalog_purchases > store_purchases AND catalog_purchases > web_purchases
        THEN 'Catalog'
	WHEN store_purchases > catalog_purchases AND store_purchases > web_purchases
        THEN 'Store'
	WHEN web_purchases > catalog_purchases AND web_purchases > store_purchases
        THEN 'Web'
	WHEN catalog_purchases = store_purchases AND catalog_purchases > web_purchases
		THEN 'Catalog + Store'
	WHEN catalog_purchases = web_purchases AND catalog_purchases > store_purchases
		THEN 'Catalog + Web'
	WHEN web_purchases = store_purchases AND web_purchases > catalog_purchases
		THEN 'Web + Store'
	WHEN catalog_purchases = store_purchases AND catalog_purchases = web_purchases AND store_purchases = web_purchases
		THEN 'All'
	ELSE 'Inconclusive'
END AS main_source_of_purchases
FROM customers;

SELECT 
'Catalog' AS main_source_of_purchases, 
COUNT(id) AS customers_count
FROM main_source
WHERE main_source_of_purchases LIKE '%Catalog%'
UNION
SELECT 
'Web' AS main_source_of_purchases,
COUNT(id) AS customers_count
FROM main_source
WHERE main_source_of_purchases LIKE '%Web%'
UNION 
SELECT 
'Store' AS main_source_of_purchases,
COUNT(id) AS customers_count
FROM main_source
WHERE main_source_of_purchases LIKE '%Store%'
ORDER BY 2 DESC;

-- Looks like customers mostly shop at the store 

-- Now lets look at the rate that which customers accepted the offer in the last campaign
SELECT 
ROUND(SUM(if_accepted_offer) / COUNT(id), 2) * 100 AS acceptance_rate
FROM customers;

-- Lets pull the acceptance rates by customers' main source of purchases (catalog, store, online)
SELECT 
main_source_of_purchases, 
ROUND(SUM(if_accepted_offer) / COUNT(id), 2) * 100 AS acceptance_rate
FROM
	(SELECT 
	c.id, ms.main_source_of_purchases, c.if_accepted_offer
	FROM customers c
	JOIN main_source ms ON c.id = ms.id) joined
GROUP BY 1
ORDER BY 2 DESC;

-- Customers whose main source of purchases are made both using the catalog and in store
-- had the highest rate of accepting the offer in the last campaign.

-- Lets look the campaign acceptance rates by other categories

-- Campaign acceptance rates by education level
SELECT 
edu, 
ROUND(SUM(if_accepted_offer) / COUNT(id), 2) * 100 AS acceptance_rate
FROM customers
GROUP BY 1
ORDER BY 2 DESC;

-- Campaign acceptance rates by number of kids living in home
SELECT 
kids_in_home, 
ROUND(SUM(if_accepted_offer) / COUNT(id), 2) * 100 AS acceptance_rate
FROM customers
GROUP BY 1
ORDER BY 2 DESC;

-- Campaign acceptance rates by marital status type
SELECT 
marital_status, 
ROUND(SUM(if_accepted_offer) / COUNT(id), 2) * 100 AS acceptance_rate
FROM customers
GROUP BY 1
ORDER BY 2 DESC;

-- Campaign acceptance rates by age

-- Extract age using birth_yr col and find min (27) and max age (130)
SELECT
MIN(age), MAX(age)
FROM
(SELECT YEAR(CURDATE()) - birth_yr AS age
FROM customers) temp;

-- Create age groups column
CREATE VIEW add_age_groups AS
SELECT 
*, 
CASE
	WHEN YEAR(CURDATE()) - birth_yr BETWEEN 19 AND 35 THEN 'Young Adult'
    WHEN YEAR(CURDATE()) - birth_yr BETWEEN 36 AND 55 THEN 'Middle-Aged Adult'
    WHEN YEAR(CURDATE()) - birth_yr BETWEEN 56 AND 64 THEN 'Older Adult'
    WHEN YEAR(CURDATE()) - birth_yr >= 65 THEN 'Senior'
END AS age_group
FROM customers;

-- Campaign acceptance rates by age
SELECT age_group, ROUND(SUM(if_accepted_offer) / COUNT(id), 2) * 100 AS acceptance_rate
FROM add_age_groups
GROUP BY 1
ORDER BY 2 DESC;