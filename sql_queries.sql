USE online_retail;

CREATE TABLE sales_clean (
    InvoiceNo VARCHAR(20),
    StockCode VARCHAR(20),
    Description VARCHAR(255),
    Quantity INT,
    InvoiceDate VARCHAR(20),
    UnitPrice DECIMAL(10,2),
    CustomerID INT,
    Country VARCHAR(50),
    TotalPrice DECIMAL(12,2)
);

CREATE TABLE cancellations (
    InvoiceNo VARCHAR(20),
    StockCode VARCHAR(20),
    Description VARCHAR(255),
    Quantity INT,
    InvoiceDate VARCHAR(20),
    UnitPrice DECIMAL(10,2),
    CustomerID INT,
    Country VARCHAR(50),
    TotalPrice DECIMAL(12,2)
);
SET GLOBAL local_infile = 1;

LOAD DATA LOCAL INFILE "C:/Users/Asus/Downloads/projects/filtered sales.csv"
INTO TABLE sales_clean
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SHOW VARIABLES LIKE 'local_infile';

LOAD DATA LOCAL INFILE "C:/Users/Asus/Downloads/projects/cancellation.csv"
INTO TABLE cancellations
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

ALTER TABLE cancellations ADD COLUMN InvoiceDate_fixed DATETIME;

UPDATE cancellations
SET InvoiceDate_fixed = STR_TO_DATE(InvoiceDate, '%m/%d/%Y %H:%i');

ALTER TABLE cancellations DROP COLUMN InvoiceDate;
ALTER TABLE cancellations CHANGE InvoiceDate_fixed InvoiceDate DATETIME;
SET SQL_SAFE_UPDATES = 0;

SELECT 
    YEAR(InvoiceDate) AS Year,
    MONTH(InvoiceDate) AS Month,
    ROUND(SUM(TotalPrice), 2) AS MonthlyRevenue,
    COUNT(DISTINCT InvoiceNo) AS NumOrders
FROM sales_clean
GROUP BY YEAR(InvoiceDate), MONTH(InvoiceDate)
ORDER BY Year, Month;

SET SQL_SAFE_UPDATES = 0;

UPDATE cancellations
SET TotalPrice = Quantity * UnitPrice;
select customerid , sum(totalprice) as revenue from sales_clean group by customerid order by revenue Desc limit 10;

SELECT CustomerID, COUNT(DISTINCT InvoiceNo) AS OrderCount, SUM(TotalPrice) AS Revenue
FROM sales_clean
GROUP BY CustomerID;

SELECT 
    CASE 
        WHEN OrderCount > 1 THEN 'Repeat'
        ELSE 'One-time'
    END AS CustomerType,
    SUM(Revenue) AS TotalRevenue
FROM (
    SELECT 
        CustomerID, 
        COUNT(DISTINCT InvoiceNo) AS OrderCount, 
        SUM(TotalPrice) AS Revenue
    FROM sales_clean
    GROUP BY CustomerID
) AS customer_summary
GROUP BY CustomerType;


SELECT StockCode, Description, SUM(TotalPrice) AS Revenue
FROM sales_clean
WHERE StockCode NOT IN ('DOT', 'M', 'POST')
GROUP BY StockCode, Description
ORDER BY Revenue DESC
LIMIT 10;

select country , sum(totalprice) as revenue from sales_clean group by country order by revenue desc limit 10;

SELECT COUNT(*) 
FROM sales_clean 
WHERE Country REGEXP '^[0-9]+$';

SELECT 
    (SELECT COUNT(DISTINCT InvoiceNo) FROM cancellations) AS CancelledOrders,
    (SELECT COUNT(DISTINCT InvoiceNo) FROM sales_clean) AS CompletedOrders,
    ROUND(
        (SELECT COUNT(DISTINCT InvoiceNo) FROM cancellations) /
        (
            (SELECT COUNT(DISTINCT InvoiceNo) FROM cancellations) + 
            (SELECT COUNT(DISTINCT InvoiceNo) FROM sales_clean)
        ) * 100
    , 2) AS CancellationRatePercent;

    SELECT StockCode, Description, COUNT(DISTINCT InvoiceNo) AS TimesCancelled
FROM cancellations
WHERE stockcode not in ('M','D','POST') 
GROUP BY StockCode, Description
ORDER BY TimesCancelled DESC
LIMIT 10;


