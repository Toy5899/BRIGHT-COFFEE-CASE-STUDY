-- Databricks notebook source
-- The column name in the table is "Unit_price_standardized", not "unit_price"
WITH cleaned_data AS (
    SELECT
        transaction_id,
        CAST(REPLACE(Unit_price_standardized, ',', '.') AS DECIMAL(10,2)) AS unit_price,
        CASE
            WHEN product_category IS NULL THEN 'unknown'
            WHEN TRIM(product_category) = '' THEN 'unknown'
            ELSE product_category
        END AS product_category,
        CASE
            WHEN product_type IS NULL THEN 'Unknown'
            WHEN TRIM(product_type) = '' THEN 'Unknown'
            ELSE product_type
        END AS product_type,
        CASE
            WHEN product_detail IS NULL THEN 'Unknown'
            WHEN TRIM(product_detail) = '' THEN 'Unknown'
            ELSE product_detail
        END AS product_detail,
        store_location,
        transaction_date,
        transaction_time,
        transaction_qty
    FROM `bright-tv`.default.brightcoffeeshop
),

valid_data AS (
    SELECT *
    FROM cleaned_data
    WHERE transaction_id IS NOT NULL
      AND transaction_date IS NOT NULL
      AND transaction_time IS NOT NULL
      AND transaction_qty IS NOT NULL
      AND unit_price IS NOT NULL
      AND transaction_qty > 0
      AND unit_price > 0
),

sales_data AS (
    SELECT
        *,
        ROUND(unit_price * transaction_qty, 2) AS total_amount
    FROM valid_data
),

time_data AS (
 SELECT
        *,
        HOUR(transaction_time) AS transaction_hour,
        CASE
            WHEN HOUR(transaction_time) BETWEEN 6 AND 8 THEN '06:00 - 08:59'
            WHEN HOUR(transaction_time) BETWEEN 9 AND 11 THEN '09:00 - 11:59'
            WHEN HOUR(transaction_time) BETWEEN 12 AND 14 THEN '12:00 - 14:59'
            WHEN HOUR(transaction_time) BETWEEN 15 AND 17 THEN '15:00 - 17:59'
            WHEN HOUR(transaction_time) BETWEEN 18 AND 20 THEN '18:00 - 20:59'
            ELSE 'Other'
        END AS transaction_time_bucket,
        CASE
            WHEN HOUR(transaction_time) BETWEEN 6 AND 11 THEN 'Morning'
            WHEN HOUR(transaction_time) BETWEEN 12 AND 17 THEN 'Afternoon'
            WHEN HOUR(transaction_time) BETWEEN 18 AND 20 THEN 'Evening'
            ELSE 'Other'
        END AS time_of_day
    FROM sales_data
),

transaction_date AS (
    SELECT
        *,
        YEAR(transaction_date) AS transaction_year,
        MONTH(transaction_date) AS transaction_month_number,
        DATE_FORMAT(transaction_date, 'MMMM') AS transaction_month,
        DAYOFMONTH(transaction_date) AS transaction_day,
        CASE
            WHEN DAYOFWEEK(transaction_date) = 1 THEN 'Sunday'
            WHEN DAYOFWEEK(transaction_date) = 2 THEN 'Monday'
            WHEN DAYOFWEEK(transaction_date) = 3 THEN 'Tuesday'
            WHEN DAYOFWEEK(transaction_date) = 4 THEN 'Wednesday'
            WHEN DAYOFWEEK(transaction_date) = 5 THEN 'Thursday'
            WHEN DAYOFWEEK(transaction_date) = 6 THEN 'Friday'
            WHEN DAYOFWEEK(transaction_date) = 7 THEN 'Saturday'
        END AS day_of_week
    FROM time_data
)

SELECT
    transaction_id,
    transaction_date,
    transaction_year,
    transaction_month_number,
    transaction_month,
    transaction_day,
    day_of_week,
    transaction_time_bucket,
    transaction_hour,
    transaction_time_bucket,
    time_of_day,
    transaction_qty,
    unit_price,
    total_amount,
    product_category,
    product_type,
    product_detail,
    store_location
FROM transaction_date