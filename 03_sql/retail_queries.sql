CREATE database retail_project;
USE retail_project;

-- Initial one-time setup
-- RENAME TABLE retail_customer_intelligence_cleaned TO customer_data;

SELECT * FROM customer_data LIMIT 10;
DESCRIBE customer_data;

-- Q1. Which customer segments contribute the highest total revenue?

SELECT
    CASE
        WHEN Age BETWEEN 18 AND 25 THEN '18-25'
        WHEN Age BETWEEN 26 AND 35 THEN '26-35'
        WHEN Age BETWEEN 36 AND 45 THEN '36-45'
        ELSE '46+'
    END AS Age_Group,
    SUM(Purchase_Amount) AS Total_Revenue
FROM customer_data
GROUP BY
    CASE
        WHEN Age BETWEEN 18 AND 25 THEN '18-25'
        WHEN Age BETWEEN 26 AND 35 THEN '26-35'
        WHEN Age BETWEEN 36 AND 45 THEN '36-45'
        ELSE '46+'
    END
ORDER BY Total_Revenue DESC;

-- Q2. Do subscribed customers spend more than non-subscribed customers?

SELECT
    Subscription_Status,
    COUNT(Customer_ID) AS Total_Customers,
    AVG(Purchase_Amount) AS Average_Spend,
    SUM(Purchase_Amount) AS Total_Revenue
FROM customer_data
GROUP BY Subscription_Status;

-- Q3. Which products generate the highest revenue within each category?

WITH product_sales AS (
    SELECT
        Category,
        Item_Purchased,
        SUM(Purchase_Amount) AS Revenue
    FROM customer_data
    GROUP BY Category, Item_Purchased
),
ranked_products AS (
    SELECT
        Category,
        Item_Purchased,
        Revenue,
        DENSE_RANK() OVER (
            PARTITION BY Category
            ORDER BY Revenue DESC
        ) AS Product_Rank
    FROM product_sales
)
SELECT
    Category,
    Item_Purchased,
    Revenue,
    Product_Rank
FROM ranked_products
WHERE Product_Rank <= 3;

-- Q4. How can customers be segmented into new, returning, and loyal groups based on previous purchases?

WITH customer_lifecycle AS (
    SELECT
        Customer_ID,
        CASE
            WHEN Previous_Purchases = 1 THEN 'New'
            WHEN Previous_Purchases BETWEEN 2 AND 10 THEN 'Returning'
            ELSE 'Loyal'
        END AS Customer_Segment
    FROM customer_data
)
SELECT
    Customer_Segment,
    COUNT(Customer_ID) AS Total_Customers
FROM customer_lifecycle
GROUP BY Customer_Segment
ORDER BY Total_Customers DESC;

-- Q5. Does discount usage increase average order value and total revenue?

SELECT
    Discount_Applied,
    AVG(Purchase_Amount) AS Avg_Order_Value,
    SUM(Purchase_Amount) AS Total_Revenue
FROM customer_data
GROUP BY Discount_Applied;

-- Q6. Do higher product review ratings lead to increased purchase frequency and revenue?

SELECT
    CASE
        WHEN Review_Rating >= 4.5 THEN 'Excellent (4.5-5)'
        WHEN Review_Rating >= 4.0 THEN 'Good (4.0-4.49)'
        WHEN Review_Rating >= 3.0 THEN 'Average (3.0-3.99)'
        ELSE 'Low (<3)'
    END AS Rating_Group,
    COUNT(*) AS Purchase_Frequency,
    AVG(Purchase_Amount) AS Avg_Purchase_Value,
    SUM(Purchase_Amount) AS Revenue
FROM customer_data
GROUP BY
    CASE
        WHEN Review_Rating >= 4.5 THEN 'Excellent (4.5-5)'
        WHEN Review_Rating >= 4.0 THEN 'Good (4.0-4.49)'
        WHEN Review_Rating >= 3.0 THEN 'Average (3.0-3.99)'
        ELSE 'Low (<3)'
    END
ORDER BY Revenue DESC;

-- Q7. Identify customers with strong repeat purchase behavior

WITH loyalty_score AS (
    SELECT
        Customer_ID,
        Previous_Purchases,
        Subscription_Status,
        Purchase_Amount,
        CASE
            WHEN Previous_Purchases BETWEEN 5 AND 10
                 AND Subscription_Status = 'Yes'
                 AND Purchase_Amount > (
                     SELECT AVG(Purchase_Amount)
                     FROM customer_data
                 )
            THEN 'High Potential Loyal'
            ELSE 'Low Potential'
        END AS Loyalty_Prediction
    FROM customer_data
)
SELECT
    Loyalty_Prediction,
    COUNT(Customer_ID) AS Total_Customers
FROM loyalty_score
GROUP BY Loyalty_Prediction;

-- Q8. Which customers are at high risk of churn?

WITH churn_analysis AS (
    SELECT
        Customer_ID,
        CASE
            WHEN Previous_Purchases <= 1
                 AND Subscription_Status = 'No'
            THEN 'High Churn Risk'
            ELSE 'Low Churn Risk'
        END AS Churn_Risk
    FROM customer_data
)
SELECT
    Churn_Risk,
    COUNT(Customer_ID) AS Total_Customers
FROM churn_analysis
GROUP BY Churn_Risk;

-- Q9. Which product categories contribute the most to overall revenue performance?

SELECT
    Category,
    COUNT(*) AS Total_Orders,
    SUM(Purchase_Amount) AS Revenue,
    ROUND(AVG(Review_Rating), 1) AS Avg_Rating 
FROM customer_data
GROUP BY Category
ORDER BY Revenue DESC;

-- Q10. Which customer segments should be targeted for discount campaigns and subscription conversion?

SELECT
    Customer_ID,
    Gender,
    Age,
    Previous_Purchases,
    Subscription_Status
FROM customer_data
WHERE Previous_Purchases BETWEEN 1 AND 3
  AND Subscription_Status = 'No';

-- Q11. Which products should be prioritized for promotion and inventory planning?

WITH inventory_insights AS (
    SELECT
        Category,
        Item_Purchased,
        COUNT(*) AS Demand_Frequency,
        SUM(Purchase_Amount) AS Revenue
    FROM customer_data
    GROUP BY Category, Item_Purchased
),
ranked_inventory AS (
    SELECT
        Category,
        Item_Purchased,
        Demand_Frequency,
        Revenue,
        RANK() OVER (
            PARTITION BY Category
            ORDER BY Demand_Frequency DESC
        ) AS Demand_Rank
    FROM inventory_insights
)
SELECT
    Category,
    Item_Purchased,
    Demand_Frequency,
    Revenue,
    Demand_Rank
FROM ranked_inventory
WHERE Demand_Rank <= 3;
