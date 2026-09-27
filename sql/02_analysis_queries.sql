-- ============================================================
-- Retail SQL Business Case Study
-- 35 Business Questions + Solutions
-- ============================================================
USE retail_case_study;

-- -------------------- BASICS & FILTERING --------------------

-- Q1: How many completed orders are there?
SELECT COUNT(*) AS completed_orders
FROM orders
WHERE OrderStatus = 'Completed';

-- Q2: List distinct product categories.
SELECT DISTINCT Category FROM products ORDER BY Category;

-- Q3: Customers who joined in 2023.
SELECT CustomerID, CustomerName, JoinDate
FROM customers
WHERE YEAR(JoinDate) = 2023
ORDER BY JoinDate;

-- Q4: Orders in January 2024.
SELECT OrderID, OrderDate, CustomerID, StoreID
FROM orders
WHERE OrderDate BETWEEN '2024-01-01' AND '2024-01-31'
ORDER BY OrderDate;

-- -------------------- AGGREGATIONS --------------------

-- Q5: Total revenue (sum of line totals) for completed orders.
SELECT ROUND(SUM(oi.LineTotal), 2) AS total_revenue
FROM order_items oi
JOIN orders o ON oi.OrderID = o.OrderID
WHERE o.OrderStatus = 'Completed';

-- Q6: Average order value (completed orders).
SELECT ROUND(AVG(order_rev), 2) AS avg_order_value
FROM (
    SELECT o.OrderID, SUM(oi.LineTotal) AS order_rev
    FROM orders o
    JOIN order_items oi ON o.OrderID = oi.OrderID
    WHERE o.OrderStatus = 'Completed'
    GROUP BY o.OrderID
) t;

-- Q7: Revenue by category.
SELECT p.Category,
       ROUND(SUM(oi.LineTotal), 2) AS revenue,
       SUM(oi.Quantity) AS units_sold
FROM order_items oi
JOIN products p ON oi.ProductID = p.ProductID
JOIN orders o ON oi.OrderID = o.OrderID
WHERE o.OrderStatus = 'Completed'
GROUP BY p.Category
ORDER BY revenue DESC;

-- Q8: Orders by status count.
SELECT OrderStatus, COUNT(*) AS cnt
FROM orders
GROUP BY OrderStatus
ORDER BY cnt DESC;

-- -------------------- JOINS --------------------

-- Q9: Top 10 customers by revenue.
SELECT c.CustomerID, c.CustomerName, c.Segment,
       ROUND(SUM(oi.LineTotal), 2) AS revenue
FROM customers c
JOIN orders o ON c.CustomerID = o.CustomerID
JOIN order_items oi ON o.OrderID = oi.OrderID
WHERE o.OrderStatus = 'Completed'
GROUP BY c.CustomerID, c.CustomerName, c.Segment
ORDER BY revenue DESC
LIMIT 10;

-- Q10: Revenue by store and city.
SELECT s.StoreID, s.StoreName, s.City, s.Region,
       ROUND(SUM(oi.LineTotal), 2) AS revenue,
       COUNT(DISTINCT o.OrderID) AS orders
FROM stores s
JOIN orders o ON s.StoreID = o.StoreID
JOIN order_items oi ON o.OrderID = oi.OrderID
WHERE o.OrderStatus = 'Completed'
GROUP BY s.StoreID, s.StoreName, s.City, s.Region
ORDER BY revenue DESC;

-- Q11: Revenue by region.
SELECT s.Region,
       ROUND(SUM(oi.LineTotal), 2) AS revenue,
       COUNT(DISTINCT o.OrderID) AS orders
FROM stores s
JOIN orders o ON s.StoreID = o.StoreID
JOIN order_items oi ON o.OrderID = oi.OrderID
WHERE o.OrderStatus = 'Completed'
GROUP BY s.Region
ORDER BY revenue DESC;

-- Q12: Payment method mix (amount and count).
SELECT PaymentMethod,
       COUNT(*) AS payments,
       ROUND(SUM(Amount), 2) AS total_amount
FROM payments
GROUP BY PaymentMethod
ORDER BY total_amount DESC;

-- Q13: Employee sales leaderboard (completed orders).
SELECT e.EmployeeID, e.EmployeeName, e.Role, e.StoreID,
       COUNT(DISTINCT o.OrderID) AS orders,
       ROUND(SUM(oi.LineTotal), 2) AS revenue
FROM employees e
JOIN orders o ON e.EmployeeID = o.EmployeeID
JOIN order_items oi ON o.OrderID = oi.OrderID
WHERE o.OrderStatus = 'Completed'
GROUP BY e.EmployeeID, e.EmployeeName, e.Role, e.StoreID
ORDER BY revenue DESC
LIMIT 15;

-- -------------------- HAVING / FILTER AGGREGATES --------------------

-- Q14: Categories with revenue above 50,000.
SELECT p.Category, ROUND(SUM(oi.LineTotal), 2) AS revenue
FROM order_items oi
JOIN products p ON oi.ProductID = p.ProductID
JOIN orders o ON oi.OrderID = o.OrderID
WHERE o.OrderStatus = 'Completed'
GROUP BY p.Category
HAVING SUM(oi.LineTotal) > 50000
ORDER BY revenue DESC;

-- Q15: Customers with 5 or more completed orders.
SELECT c.CustomerID, c.CustomerName, COUNT(DISTINCT o.OrderID) AS orders
FROM customers c
JOIN orders o ON c.CustomerID = o.CustomerID
WHERE o.OrderStatus = 'Completed'
GROUP BY c.CustomerID, c.CustomerName
HAVING COUNT(DISTINCT o.OrderID) >= 5
ORDER BY orders DESC;

-- -------------------- CASE --------------------

-- Q16: Discount band analysis.
SELECT 
    CASE 
        WHEN Discount = 0 THEN 'No Discount'
        WHEN Discount <= 0.05 THEN 'Low (1-5%)'
        WHEN Discount <= 0.10 THEN 'Medium (6-10%)'
        ELSE 'High (10%+)'
    END AS discount_band,
    COUNT(*) AS line_items,
    ROUND(SUM(LineTotal), 2) AS revenue
FROM order_items
GROUP BY discount_band
ORDER BY revenue DESC;

-- Q17: Customer segment revenue.
SELECT c.Segment,
       COUNT(DISTINCT o.OrderID) AS orders,
       ROUND(SUM(oi.LineTotal), 2) AS revenue
FROM customers c
JOIN orders o ON c.CustomerID = o.CustomerID
JOIN order_items oi ON o.OrderID = oi.OrderID
WHERE o.OrderStatus = 'Completed'
GROUP BY c.Segment
ORDER BY revenue DESC;

-- -------------------- SUBQUERIES --------------------

-- Q18: Products never sold.
SELECT ProductID, ProductName, Category
FROM products
WHERE ProductID NOT IN (
    SELECT DISTINCT ProductID FROM order_items
);

-- Q19: Orders above average order value.
SELECT o.OrderID, o.OrderDate, ROUND(SUM(oi.LineTotal), 2) AS order_value
FROM orders o
JOIN order_items oi ON o.OrderID = oi.OrderID
WHERE o.OrderStatus = 'Completed'
GROUP BY o.OrderID, o.OrderDate
HAVING SUM(oi.LineTotal) > (
    SELECT AVG(ov) FROM (
        SELECT SUM(LineTotal) AS ov
        FROM order_items oi2
        JOIN orders o2 ON oi2.OrderID = o2.OrderID
        WHERE o2.OrderStatus = 'Completed'
        GROUP BY oi2.OrderID
    ) x
)
ORDER BY order_value DESC
LIMIT 20;

-- Q20: Store with highest revenue.
SELECT StoreID, StoreName, City
FROM stores
WHERE StoreID = (
    SELECT o.StoreID
    FROM orders o
    JOIN order_items oi ON o.OrderID = oi.OrderID
    WHERE o.OrderStatus = 'Completed'
    GROUP BY o.StoreID
    ORDER BY SUM(oi.LineTotal) DESC
    LIMIT 1
);

-- -------------------- CTEs --------------------

-- Q21: Monthly revenue trend (CTE).
WITH monthly AS (
    SELECT DATE_FORMAT(o.OrderDate, '%Y-%m') AS YearMonth,
           ROUND(SUM(oi.LineTotal), 2) AS revenue,
           COUNT(DISTINCT o.OrderID) AS orders
    FROM orders o
    JOIN order_items oi ON o.OrderID = oi.OrderID
    WHERE o.OrderStatus = 'Completed'
    GROUP BY DATE_FORMAT(o.OrderDate, '%Y-%m')
)
SELECT * FROM monthly ORDER BY YearMonth;

-- Q22: Repeat vs one-time customers.
WITH cust_orders AS (
    SELECT CustomerID, COUNT(DISTINCT OrderID) AS order_cnt
    FROM orders
    WHERE OrderStatus = 'Completed'
    GROUP BY CustomerID
)
SELECT 
    CASE WHEN order_cnt = 1 THEN 'One-time' ELSE 'Repeat' END AS customer_type,
    COUNT(*) AS customers
FROM cust_orders
GROUP BY customer_type;

-- Q23: Category margin proxy (price - cost) * qty.
WITH lines AS (
    SELECT p.Category,
           oi.Quantity,
           oi.LineTotal,
           (p.UnitPrice - p.UnitCost) * oi.Quantity AS est_margin
    FROM order_items oi
    JOIN products p ON oi.ProductID = p.ProductID
    JOIN orders o ON oi.OrderID = o.OrderID
    WHERE o.OrderStatus = 'Completed'
)
SELECT Category,
       ROUND(SUM(LineTotal), 2) AS revenue,
       ROUND(SUM(est_margin), 2) AS est_margin
FROM lines
GROUP BY Category
ORDER BY est_margin DESC;

-- -------------------- WINDOW FUNCTIONS --------------------

-- Q24: Rank stores by revenue.
WITH store_rev AS (
    SELECT s.StoreID, s.StoreName, s.City,
           ROUND(SUM(oi.LineTotal), 2) AS revenue
    FROM stores s
    JOIN orders o ON s.StoreID = o.StoreID
    JOIN order_items oi ON o.OrderID = oi.OrderID
    WHERE o.OrderStatus = 'Completed'
    GROUP BY s.StoreID, s.StoreName, s.City
)
SELECT *, RANK() OVER (ORDER BY revenue DESC) AS revenue_rank
FROM store_rev
ORDER BY revenue_rank;

-- Q25: Rank products by units sold within category.
WITH prod_sales AS (
    SELECT p.Category, p.ProductID, p.ProductName,
           SUM(oi.Quantity) AS units
    FROM products p
    JOIN order_items oi ON p.ProductID = oi.ProductID
    JOIN orders o ON oi.OrderID = o.OrderID
    WHERE o.OrderStatus = 'Completed'
    GROUP BY p.Category, p.ProductID, p.ProductName
)
SELECT *,
       RANK() OVER (PARTITION BY Category ORDER BY units DESC) AS rank_in_category
FROM prod_sales
ORDER BY Category, rank_in_category;

-- Q26: Running monthly revenue.
WITH monthly AS (
    SELECT DATE_FORMAT(o.OrderDate, '%Y-%m') AS YearMonth,
           SUM(oi.LineTotal) AS revenue
    FROM orders o
    JOIN order_items oi ON o.OrderID = oi.OrderID
    WHERE o.OrderStatus = 'Completed'
    GROUP BY DATE_FORMAT(o.OrderDate, '%Y-%m')
)
SELECT YearMonth,
       ROUND(revenue, 2) AS revenue,
       ROUND(SUM(revenue) OVER (ORDER BY YearMonth), 2) AS running_revenue
FROM monthly
ORDER BY YearMonth;

-- Q27: YoY monthly comparison (if data spans years).
WITH monthly AS (
    SELECT YEAR(o.OrderDate) AS yr,
           MONTH(o.OrderDate) AS mon,
           SUM(oi.LineTotal) AS revenue
    FROM orders o
    JOIN order_items oi ON o.OrderID = oi.OrderID
    WHERE o.OrderStatus = 'Completed'
    GROUP BY YEAR(o.OrderDate), MONTH(o.OrderDate)
)
SELECT a.yr, a.mon, ROUND(a.revenue, 2) AS revenue,
       ROUND(b.revenue, 2) AS prev_year_revenue,
       ROUND((a.revenue - b.revenue) / NULLIF(b.revenue, 0) * 100, 1) AS yoy_pct
FROM monthly a
LEFT JOIN monthly b ON a.mon = b.mon AND a.yr = b.yr + 1
ORDER BY a.yr, a.mon;

-- -------------------- BUSINESS SCENARIOS --------------------

-- Q28: Return rate by store.
SELECT s.StoreName, s.City,
       COUNT(*) AS total_orders,
       SUM(CASE WHEN o.OrderStatus = 'Returned' THEN 1 ELSE 0 END) AS returned,
       ROUND(SUM(CASE WHEN o.OrderStatus = 'Returned' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS return_rate_pct
FROM stores s
JOIN orders o ON s.StoreID = o.StoreID
GROUP BY s.StoreName, s.City
ORDER BY return_rate_pct DESC;

-- Q29: Top 15 products by revenue.
SELECT p.ProductID, p.ProductName, p.Category,
       SUM(oi.Quantity) AS units,
       ROUND(SUM(oi.LineTotal), 2) AS revenue
FROM products p
JOIN order_items oi ON p.ProductID = oi.ProductID
JOIN orders o ON oi.OrderID = o.OrderID
WHERE o.OrderStatus = 'Completed'
GROUP BY p.ProductID, p.ProductName, p.Category
ORDER BY revenue DESC
LIMIT 15;

-- Q30: City-level customer count vs revenue.
SELECT c.City AS customer_city,
       COUNT(DISTINCT c.CustomerID) AS customers,
       ROUND(SUM(oi.LineTotal), 2) AS revenue
FROM customers c
JOIN orders o ON c.CustomerID = o.CustomerID
JOIN order_items oi ON o.OrderID = oi.OrderID
WHERE o.OrderStatus = 'Completed'
GROUP BY c.City
ORDER BY revenue DESC;

-- Q31: Average discount by category.
SELECT p.Category,
       ROUND(AVG(oi.Discount) * 100, 2) AS avg_discount_pct,
       ROUND(SUM(oi.LineTotal), 2) AS revenue
FROM order_items oi
JOIN products p ON oi.ProductID = p.ProductID
JOIN orders o ON oi.OrderID = o.OrderID
WHERE o.OrderStatus = 'Completed'
GROUP BY p.Category
ORDER BY avg_discount_pct DESC;

-- Q32: Orders with no payment match check (should be 0 if consistent).
SELECT o.OrderID
FROM orders o
LEFT JOIN payments p ON o.OrderID = p.OrderID
WHERE p.PaymentID IS NULL
LIMIT 20;

-- Q33: Best day of week for sales.
SELECT DAYNAME(o.OrderDate) AS day_name,
       COUNT(DISTINCT o.OrderID) AS orders,
       ROUND(SUM(oi.LineTotal), 2) AS revenue
FROM orders o
JOIN order_items oi ON o.OrderID = oi.OrderID
WHERE o.OrderStatus = 'Completed'
GROUP BY DAYNAME(o.OrderDate), DAYOFWEEK(o.OrderDate)
ORDER BY DAYOFWEEK(o.OrderDate);

-- Q34: Customers who bought Electronics and Clothing.
SELECT c.CustomerID, c.CustomerName
FROM customers c
WHERE c.CustomerID IN (
    SELECT o.CustomerID
    FROM orders o
    JOIN order_items oi ON o.OrderID = oi.OrderID
    JOIN products p ON oi.ProductID = p.ProductID
    WHERE p.Category = 'Electronics' AND o.OrderStatus = 'Completed'
)
AND c.CustomerID IN (
    SELECT o.CustomerID
    FROM orders o
    JOIN order_items oi ON o.OrderID = oi.OrderID
    JOIN products p ON oi.ProductID = p.ProductID
    WHERE p.Category = 'Clothing' AND o.OrderStatus = 'Completed'
);

-- Q35: Executive KPI snapshot.
SELECT
    (SELECT COUNT(*) FROM orders WHERE OrderStatus = 'Completed') AS completed_orders,
    (SELECT ROUND(SUM(oi.LineTotal), 2)
     FROM order_items oi
     JOIN orders o ON oi.OrderID = o.OrderID
     WHERE o.OrderStatus = 'Completed') AS total_revenue,
    (SELECT COUNT(DISTINCT CustomerID) FROM orders WHERE OrderStatus = 'Completed') AS active_customers,
    (SELECT COUNT(*) FROM products) AS product_count,
    (SELECT COUNT(*) FROM stores) AS store_count;
