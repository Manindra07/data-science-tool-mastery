-- Case File 05: The Records Office
-- Database: Chinook (SQLite). Each query is labelled with the business question it answers.

-- 1. Which countries bring in the most money, and how much per customer?
SELECT c.Country,
       COUNT(DISTINCT c.CustomerId)  AS customers,
       ROUND(SUM(i.Total), 2)        AS revenue,
       ROUND(SUM(i.Total) / COUNT(DISTINCT c.CustomerId), 2) AS revenue_per_customer
FROM Customer c
JOIN Invoice  i ON i.CustomerId = c.CustomerId
GROUP BY c.Country
ORDER BY revenue DESC
LIMIT 10;

-- 2. Which genres drive revenue, and what share of the total is each? (window over whole result)
SELECT g.Name AS genre,
       ROUND(SUM(il.UnitPrice * il.Quantity), 2) AS revenue,
       ROUND(100.0 * SUM(il.UnitPrice * il.Quantity)
             / SUM(SUM(il.UnitPrice * il.Quantity)) OVER (), 1) AS pct_of_total
FROM InvoiceLine il
JOIN Track t ON t.TrackId = il.TrackId
JOIN Genre g ON g.GenreId = t.GenreId
GROUP BY g.GenreId
ORDER BY revenue DESC;

-- 3. How is revenue trending month to month? (CTE + LAG + running total)
WITH monthly AS (
    SELECT strftime('%Y-%m', InvoiceDate) AS month,
           SUM(Total)                      AS revenue
    FROM Invoice
    GROUP BY month
)
SELECT month,
       ROUND(revenue, 2) AS revenue,
       ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY month))
             / LAG(revenue) OVER (ORDER BY month), 1) AS mom_growth_pct,
       ROUND(SUM(revenue) OVER (ORDER BY month), 2)    AS running_total
FROM monthly
ORDER BY month;

-- 4. Who is the best customer in each country? (RANK within a partition)
WITH customer_totals AS (
    SELECT c.Country,
           c.FirstName || ' ' || c.LastName AS customer,
           SUM(i.Total)                     AS lifetime_value
    FROM Customer c
    JOIN Invoice i ON i.CustomerId = c.CustomerId
    GROUP BY c.CustomerId
)
SELECT Country, customer, ROUND(lifetime_value, 2) AS lifetime_value
FROM (
    SELECT *, RANK() OVER (PARTITION BY Country ORDER BY lifetime_value DESC) AS rnk
    FROM customer_totals
)
WHERE rnk = 1
ORDER BY lifetime_value DESC;

-- 5. Which parts of the catalogue never sell? (anti-join, grouped by genre)
SELECT g.Name AS genre, COUNT(*) AS unsold_tracks
FROM Track t
LEFT JOIN InvoiceLine il ON il.TrackId = t.TrackId
JOIN Genre g ON g.GenreId = t.GenreId
WHERE il.TrackId IS NULL
GROUP BY g.GenreId
ORDER BY unsold_tracks DESC;
