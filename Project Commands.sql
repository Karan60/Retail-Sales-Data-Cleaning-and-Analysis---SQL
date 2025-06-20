CREATE TABLE sales_store(
transaction_id	VARCHAR(15),
customer_id	VARCHAR(15),
customer_name	VARCHAR(30),
customer_age	INT,
gender	VARCHAR(15),
product_id	VARCHAR(15),
product_name	VARCHAR(15),
product_category	VARCHAR(15),
quantiy	INT,
prce	FLOAT,
payment_mode	VARCHAR(15),
purchase_date	DATE,
time_of_purchase	TIME,
status	VARCHAR(15)
);

COPY sales_store(transaction_id, customer_id, customer_name, customer_age, gender, product_id, product_name, product_category, quantiy, prce, payment_mode, purchase_date, time_of_purchase, status)
FROM 'C:\SQL\Project 2-Retail Store Sales\Retail Store Sales Data.csv'
DELIMITER ','
CSV HEADER;

SELECT * FROM sales_store

--copy data into new table
SELECT * INTO sales FROM sales_store

SELECT * FROM sales

--data cleaning 
--step 1: to check for duplicate
SELECT transaction_id, COUNT(*)
FROM sales
GROUP BY transaction_id
HAVING COUNT(transaction_id) >1;

"TXN745076"
"TXN855235"
"TXN626832"
"TXN240646"
"TXN342128"
"TXN981773"
"TXN832908"

WITH duplicates AS (
    SELECT ctid,
           ROW_NUMBER() OVER (PARTITION BY transaction_id ORDER BY ctid) AS row_num
    FROM sales
)
DELETE FROM sales
WHERE ctid IN (
    SELECT ctid FROM duplicates WHERE row_num > 1
);

SELECT * FROM sales
WHERE transaction_id IN ('TXN745076', 'TXN855235', 'TXN626832', 'TXN240646', 'TXN342128', 'TXN981773', 'TXN832908');

--step 2: correction of headers
ALTER TABLE sales rename column quantiy to quantity;
ALTER TABLE sales rename column prce to price;

SELECT * FROM sales

--step 3: to check data types
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME='sales';

--step 4: to count null valus
SELECT COUNT(*) AS null_count
FROM sales
WHERE transaction_id IS NULL;

--step 5: to check null valus
SELECT *
FROM sales
WHERE transaction_id IS NULL
OR
transaction_id IS NULL
OR
customer_id IS NULL
OR
customer_name IS NULL
OR
customer_age IS NULL
OR
gender IS NULL
OR
product_id IS NULL
OR
product_name IS NULL
OR
product_category IS NULL
OR
quantity IS NULL
OR
price IS NULL
OR
payment_mode IS NULL
OR
purchase_date IS NULL
OR
time_of_purchase IS NULL
OR
status IS NULL;

-- it is outlier so best option is remove this row
DELETE FROM SALES 
WHERE transaction_id IS NULL;

--step 6: treating null values
SELECT * FROM SALES
WHERE customer_id ='CUST1003'

--addind values
UPDATE SALES
SET customer_name ='Mahika Saini', customer_age=35, gender='Male'
WHERE customer_id ='CUST1003';

SELECT * FROM SALES
WHERE customer_name='Ehsaan Ram';

UPDATE SALES
SET customer_id='CUST9494'
WHERE customer_name='Ehsaan Ram';

SELECT * FROM SALES
WHERE customer_name='Damini Raju';

UPDATE SALES
SET customer_id='CUST1401'
WHERE customer_name='Damini Raju';

SELECT * FROM sales

--step 7: data cleaning
SELECT DISTINCT gender
FROM SALES;

UPDATE SALES
SET gender='M'
WHERE gender='Male'

UPDATE SALES
SET gender='F'
WHERE gender='Female'

SELECT DISTINCT payment_mode
FROM SALES;

UPDATE SALES
SET payment_mode='Credit Card'
WHERE payment_mode='CC'

--Data Analysis--

--1.what are the top 5 most selling products by quantity?
SELECT DISTINCT status
from sales

SELECT product_name, SUM(quantity) AS total_quantity_sold
FROM sales
WHERE status='delivered'
GROUP BY product_name
ORDER BY total_quantity_sold DESC
limit 5

--business problem: we don't know which products are most in demand.
--business impact: helps priortize stock and boost sales through targeted promotions.

--2. which product are most frequently canceled?
SELECT product_name, COUNT(*) AS total_cancelled
FROM sales
WHERE status='cancelled'
GROUP BY product_name
ORDER BY total_cancelled DESC
limit 5

--business problem: frequently cancellations affect revenue and customer trust
--business impact: identify poor-performing products to improve quality or remove from catelog.

--3. what time of the day has highest number of purchases ?
SELECT  
  CASE 
    WHEN EXTRACT(HOUR FROM time_of_purchase) BETWEEN 0 AND 5 THEN 'NIGHT'
    WHEN EXTRACT(HOUR FROM time_of_purchase) BETWEEN 6 AND 11 THEN 'MORNING'
    WHEN EXTRACT(HOUR FROM time_of_purchase) BETWEEN 12 AND 17 THEN 'AFTERNOON'
    WHEN EXTRACT(HOUR FROM time_of_purchase) BETWEEN 18 AND 23 THEN 'EVENING'
  END AS time_of_day,
  	COUNT(*) AS total_order
	FROM sales
	GROUP BY  
  CASE 
    WHEN EXTRACT(HOUR FROM time_of_purchase) BETWEEN 0 AND 5 THEN 'NIGHT'
    WHEN EXTRACT(HOUR FROM time_of_purchase) BETWEEN 6 AND 11 THEN 'MORNING'
    WHEN EXTRACT(HOUR FROM time_of_purchase) BETWEEN 12 AND 17 THEN 'AFTERNOON'
    WHEN EXTRACT(HOUR FROM time_of_purchase) BETWEEN 18 AND 23 THEN 'EVENING'
  END
  ORDER BY total_order DESC;

--business problem solved: find the peak sales times
--business impact:optimize staffing, promotions and server loads

--4. who are the top 5 highest spending customers?
SELECT customer_name, 
  TO_CHAR(SUM(price * quantity), 'FM₹99,99,99,999') AS total_spend
FROM sales
GROUP BY customer_name
ORDER BY SUM(price * quantity) DESC
LIMIT 5;

--business problem solved: identify VIP customers
--business impact: personalized offers, loyality rewards, and retention.

SELECT * FROM sales

--5. which product category generate the highest revenue?
SELECT product_category, 
  TO_CHAR(SUM(price * quantity), 'FM₹9,99,99,999') AS highest_revenue
FROM sales
GROUP BY product_category
ORDER BY SUM(price * quantity) DESC --if we write direct name as highest_revenue , it not work because 'FM₹9,99,99,999' it consider this as a string
LIMIT 1                             --so we need to write SUM(price * quantity), this

--business problem solved: identify top-performing product categories.
--business impact: refine product category, supply chain, and promotions.
--allowing the business to invest more in high-margin or high-demand categories.

--6. what is the return/cancellation rate per product category?
--cancellation
SELECT product_category,
  CONCAT(ROUND(COUNT(CASE WHEN status = 'cancelled' THEN 1 END) * 100.0 / COUNT(*), 2),' %') AS cancelled_percent
FROM sales
GROUP BY product_category
ORDER BY cancelled_percent DESC;

--return
SELECT product_category,
  CONCAT(ROUND(COUNT(CASE WHEN status = 'returned' THEN 1 END) * 100.0 / COUNT(*), 2),' %') AS returned_percent
FROM sales
GROUP BY product_category
ORDER BY cancelled_percent DESC;

--bussiness problem solved: monitor dissatisfaction trends per category
--bussiness impact: reduce returns, improve product descriptions/expections,
--helps indentify and fix product or logistics issues.

--7. what is most preferred payment mode?
SELECT payment_mode, COUNT(payment_mode) AS total_count
FROM sales
GROUP BY payment_mode
ORDER BY total_count desc;

--business problem: know which payment options customer prefer
--business impact: streamline payment processing, prioritizw popular modes.

--8. how does age group affect purchasing behaviour?
SELECT  
  CASE 
    WHEN customer_age BETWEEN 18 AND 25 THEN '18-25'
    WHEN customer_age BETWEEN 26 AND 35 THEN '26-35'
    WHEN customer_age BETWEEN 36 AND 50 THEN '36-50'
    ELSE '51+'
  END AS customer_Age,
  TO_CHAR(SUM(price * quantity), 'FM₹99,99,99,999') AS total_purchase
FROM sales
GROUP BY CASE 
    WHEN customer_age BETWEEN 18 AND 25 THEN '18-25'
    WHEN customer_age BETWEEN 26 AND 35 THEN '26-35'
    WHEN customer_age BETWEEN 36 AND 50 THEN '36-50'
    ELSE '51+'
END
ORDER BY total_purchase DESC;

--business problem solved: understand customer demographics.
--business impact: targeted marketing and product recommendations by age group.

--9. what is the monthly sales trend?
--method 1
SELECT 
	TO_CHAR(purchase_date, 'YYYY-MM') AS month_year,
	TO_CHAR(SUM(price * quantity) , 'FM₹9,99,99,999') AS total_sales,
	SUM(quantity) AS total_quantity
FROM sales
GROUP BY TO_CHAR(purchase_date, 'YYYY-MM')
ORDER BY TO_CHAR(purchase_date, 'YYYY-MM') 

--method 2
SELECT 
  EXTRACT(YEAR FROM purchase_date) AS years,
  EXTRACT(MONTH FROM purchase_date) AS months,
  TO_CHAR(SUM(price * quantity), 'FM₹99,99,99,990') AS total_sales,
  SUM(quantity) AS total_quantity
FROM sales
GROUP BY EXTRACT(YEAR FROM purchase_date), EXTRACT(MONTH FROM purchase_date)
ORDER BY years, months;

--business problem solved: sales fluctuations go unnoticed.
--business impact: plan inventory and marketing according to seasonal trends.

--10. are certain gender buying more specific product categories?
--method 1:
SELECT gender, product_category, COUNT(product_category) AS total_purchase
FROM sales
GROUP BY gender, product_category
ORDER BY gender

--method 2:
SELECT 
  product_category,
  COUNT(*) FILTER (WHERE gender = 'M') AS male_count,
  COUNT(*) FILTER (WHERE gender = 'F') AS female_count
FROM sales
GROUP BY product_category
ORDER BY product_category;

--business problem solved: gender-based product preferences.
--business impact: personalized ads, gender-focused campaigns.