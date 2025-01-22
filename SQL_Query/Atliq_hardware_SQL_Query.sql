/*gdb023.... (Atliq Hardware)------>
This file provides a comprehensive overview of the tables found in the 'gdb023' (atliq_hardware_db) database. It 
includes information for six main tables:

1. dim_customer: contains customer-related data
2. dim_product: contains product-related data
3. fact_gross_price: contains gross price information for each product
4. fact_manufacturing_cost: contains the cost incurred in the production of each product
5. fact_pre_invoice_deductions: contains pre-invoice deductions information for each product
6. fact_sales_monthly: contains monthly sales data for each product.
*/
-- ---------------------------------------------------------------------------------------------------------
 -- Query Title: Ad-Hoc Request
-- Author: ANSHIKA PORWAL
-- Date: JAN 2025
-- ------------------------------------------------------------------------------------------------------------

-- Purpose:
-- This query identifies all the distinct markets in which the customer "Atliq Exclusive"
-- operates within the APAC region. This helps the business understand the geographical
-- spread of "Atliq Exclusive" and plan targeted strategies for this customer.
-- -----------------------------------------------------------------------------------------------------------------------------


-- 1--Ad-hoc query.....*****Fetch markets for "Atliq Exclusive" in the APAC region********

SELECT DISTINCT market
FROM dim_customer
WHERE customer = 'Atliq Exclusive'
  AND region = 'APAC';


-- 2--Ad-hoc query--***** Calculate percentage change in unique products between 2020 and 2021****
WITH unique_products AS (
    SELECT
        fiscal_year,
        COUNT(DISTINCT product_code) AS unique_products
    FROM fact_gross_price
    GROUP BY fiscal_year
)
SELECT
    (SELECT unique_products FROM unique_products WHERE fiscal_year = 2020) AS unique_products_2020,
    (SELECT unique_products FROM unique_products WHERE fiscal_year = 2021) AS unique_products_2021,
    ROUND(
        ((SELECT unique_products FROM unique_products WHERE fiscal_year = 2021) -
         (SELECT unique_products FROM unique_products WHERE fiscal_year = 2020)) * 100.0 /
        (SELECT unique_products FROM unique_products WHERE fiscal_year = 2020),
        2
    ) AS percentage_chg;
    
    
    -- Ad-hoc Query 3:- Count unique products by segment and sort by descending order
SELECT
    segment,
    COUNT(DISTINCT product_code) AS product_count
FROM dim_product
GROUP BY segment
ORDER BY product_count DESC;


-- Ad-hoc -Query 4:- ******Find segments with the largest increase in unique products between 2020 and 2021*****
WITH product_counts AS (
    SELECT
        fiscal_year,
        segment,
        COUNT(DISTINCT product_code) AS product_count
    FROM fact_gross_price
    JOIN dim_product USING (product_code)
    GROUP BY fiscal_year, segment
)
SELECT
    segment,
    MAX(CASE WHEN fiscal_year = 2020 THEN product_count ELSE 0 END) AS product_count_2020,
    MAX(CASE WHEN fiscal_year = 2021 THEN product_count ELSE 0 END) AS product_count_2021,
    MAX(CASE WHEN fiscal_year = 2021 THEN product_count ELSE 0 END) -
    MAX(CASE WHEN fiscal_year = 2020 THEN product_count ELSE 0 END) AS difference
FROM product_counts
GROUP BY segment
ORDER BY difference DESC
;

-- Ad-hoc query -5 ******Get products with the lowest and highest manufacturing costs*****
SELECT product_code, product, manufacturing_cost
FROM fact_manufacturing_cost
JOIN dim_product USING (product_code)
WHERE manufacturing_cost = (SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost)
   OR manufacturing_cost = (SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost);
   
   
   -- Ad-hoc query --6******  Top 5 customers in India with the highest average pre-invoice discount in 2021****
SELECT
    d.customer_code,
    d.customer,
    ROUND(AVG(p.pre_invoice_discount_pct), 2) AS average_discount_percentage
FROM fact_pre_invoice_deductions p
JOIN dim_customer d ON p.customer_code = d.customer_code
WHERE p.fiscal_year = 2021 AND d.market = 'India'
GROUP BY d.customer_code, d.customer
ORDER BY average_discount_percentage DESC
LIMIT 5;


-- Ad-hoc SQL query -7*********Monthly gross sales for "Atliq Exclusive"******
SELECT
    EXTRACT(MONTH FROM date) AS Month,
    EXTRACT(YEAR FROM date) AS Year,
    SUM(gross_price * sold_quantity) AS Gross_sales_Amount
FROM fact_sales_monthly
JOIN dim_customer USING (customer_code)
JOIN fact_gross_price USING (product_code, fiscal_year)
WHERE customer = 'Atliq Exclusive'
GROUP BY Month, Year
ORDER BY Year, Month;



-- Ad-hoc query8**************** Quarter with the maximum sold quantity in 2020*************

WITH QuarterData AS (
    SELECT 
        CASE 
            WHEN MONTH(date) IN (9, 10, 11) THEN 'Q1'
            WHEN MONTH(date) IN (12, 1, 2) THEN 'Q2'
            WHEN MONTH(date) IN (3, 4, 5) THEN 'Q3'
            WHEN MONTH(date) IN (6, 7, 8) THEN 'Q4'
        END AS Quarter,
        SUM(sold_quantity) AS total_sold_quantity
    FROM fact_sales_monthly
    WHERE fiscal_year = 2020
    GROUP BY 
        CASE 
            WHEN MONTH(date) IN (9, 10, 11) THEN 'Q1'
            WHEN MONTH(date) IN (12, 1, 2) THEN 'Q2'
            WHEN MONTH(date) IN (3, 4, 5) THEN 'Q3'
            WHEN MONTH(date) IN (6, 7, 8) THEN 'Q4'
        END
)
SELECT Quarter, total_sold_quantity
FROM QuarterData
ORDER BY total_sold_quantity DESC;



-- 8 ****Channel contributing most to gross sales in 2021
WITH channel_sales AS (
    SELECT
        channel,
        SUM(gross_price * sold_quantity) AS gross_sales
    FROM fact_sales_monthly
    JOIN dim_customer USING (customer_code)
    JOIN fact_gross_price USING (product_code, fiscal_year)
    WHERE fiscal_year = 2021
    GROUP BY channel
)
SELECT
    channel,
    gross_sales,
    ROUND((gross_sales * 100.0) / SUM(gross_sales) OVER(), 2) AS percentage
FROM channel_sales
ORDER BY gross_sales DESC;



-- Ad-hoc sql query -10  ***************Top 3 products in each division by sold quantity in 2021***************

WITH ranked_products AS (
    SELECT
        division,
        product_code,
        product,
        SUM(sold_quantity) AS total_sold_quantity,
        RANK() OVER (PARTITION BY division ORDER BY SUM(sold_quantity) DESC) AS rank_order
    FROM fact_sales_monthly
    JOIN dim_product USING (product_code)
    WHERE fiscal_year = 2021
    GROUP BY division, product_code, product
)
SELECT division, product_code, product, total_sold_quantity, rank_order
FROM ranked_products
WHERE rank_order <= 3;
