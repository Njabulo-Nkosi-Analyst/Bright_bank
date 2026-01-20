select * from workspace.fnb.sales; ---1000 rows
--checking data type
 describe workspace.fnb.sales;
 ---checking null value
 SELECT *
FROM workspace.fnb.sales
WHERE Date IS NULL
   OR Sales IS NULL
   OR `Cost Of Sales` IS NULL
   OR `Quantity Sold` IS NULL;---no null value

   select count(*) from workspace.fnb.sales;--1053
 
 select distinct year (Date) as year
 from workspace.fnb.sales;---2013-2016
 
 SELECT month (Date) as month
FROM workspace.fnb.sales;

--------------------------------------END DATE COLUMN

---------
SELECT  DATE,
SUM(Sales) AS `TOTAL SALES`,
SUM(`Cost Of Sales`) AS `TOTAL COST OF SALES`,
SUM(`Quantity Sold`) AS `TOTAL QUANTITY SOLD`
from workspace.fnb.sales
GROUP BY ALL;
 --------

select
---QUESTION 1 
      DATE,ROUND(SALES/`Quantity Sold`,0) AS `SALES PER UNIT`,

 ---QUESTION 2
      month (Date) as month,
      year (date) as year,
      ROUND( SUM(Sales) / SUM(`Quantity Sold`),0) AS `Avg unit sold`,

---Question 3 
      Sales AS Daily_Revenue, 
      Sales - `Cost Of Sales` AS `Daily Gross Profit`,
      round( ((Sales - `Cost Of Sales`) / Sales),3)* 100 AS `daily Gross Profit Percentage`,

 --Question 4
-- 1. Daily Sales Price Per Unit (Metric #1)
      ROUND(Sales / `Quantity Sold`, 2) AS Daily_Sales_Price_Per_Unit,
     
-- 2. Cost of Sales Per Unit 
      ROUND(`Cost Of Sales` / `Quantity Sold`, 2) AS Daily_Cost_Per_Unit, 

    -- 3. Gross Profit Per Unit
     ROUND((Sales - `Cost Of Sales`) / `Quantity Sold`, 2) AS Gross_Profit_Per_Unit,

    -- 4. Daily % Gross Profit (Metric #3) / Daily % Gross Profit Per Unit (Metric #4)
    ROUND(((Sales - `Cost Of Sales`) / Sales) * 100, 2) AS Gross_Profit_Percentage,

----Aggregation 
    sum(`cost of sales`) as `total cost of sales`,
    sum(sales) as `total sales`,
    sum(`quantity sold`) as `total quantity sold`

--date
  ,date_format(Date, 'E') AS `DAY OF WEEK`
 
    from workspace.fnb.sales
    group by date, month,year, Sales, `Cost Of Sales`, `Quantity Sold`,`DAY OF WEEK`
    order by date;

------Question 5 
--checking PED for promo & normal price
WITH AvgData AS (
    SELECT '1_Normal' AS Period,
        AVG(Sales / `Quantity Sold`) AS Avg_Price,
        AVG(`Quantity Sold`) AS Avg_Quantity,
        AVG(Sales - `Cost Of Sales`) AS Avg_Daily_Gross_Profit
    FROM workspace.fnb.sales
    WHERE Date BETWEEN '2014-06-22' AND '2014-07-14'

    UNION ALL

    SELECT '1_Promo' AS Period,
        AVG(Sales / `Quantity Sold`) AS Avg_Price,
        AVG(`Quantity Sold`) AS Avg_Quantity,
        AVG(Sales - `Cost Of Sales`) AS Avg_Daily_Gross_Profit
    FROM workspace.fnb.sales
    WHERE Date BETWEEN '2014-08-26' AND '2014-09-08'

    UNION ALL

    SELECT '2_Normal' AS Period,
        AVG(Sales / `Quantity Sold`) AS Avg_Price,
        AVG(`Quantity Sold`) AS Avg_Quantity,
        AVG(Sales - `Cost Of Sales`) AS Avg_Daily_Gross_Profit
    FROM workspace.fnb.sales
    WHERE Date BETWEEN '2014-11-22' AND '2014-12-03'

    UNION ALL

    SELECT '2_Promo' AS Period,
        AVG(Sales / `Quantity Sold`) AS Avg_Price,
        AVG(`Quantity Sold`) AS Avg_Quantity,
        AVG(Sales - `Cost Of Sales`) AS Avg_Daily_Gross_Profit
    FROM workspace.fnb.sales
    WHERE Date BETWEEN '2015-09-25' AND '2015-10-06'

    UNION ALL

    SELECT '3_Normal' AS Period,
        AVG(Sales / `Quantity Sold`) AS Avg_Price,
        AVG(`Quantity Sold`) AS Avg_Quantity,
        AVG(Sales - `Cost Of Sales`) AS Avg_Daily_Gross_Profit
    FROM workspace.fnb.sales
    WHERE Date BETWEEN '2016-05-07' AND '2016-05-23'

    UNION ALL

    SELECT '3_Promo' AS Period,
        AVG(Sales / `Quantity Sold`) AS Avg_Price,
        AVG(`Quantity Sold`) AS Avg_Quantity,
        AVG(Sales - `Cost Of Sales`) AS Avg_Daily_Gross_Profit
    FROM workspace.fnb.sales
    WHERE Date BETWEEN '2016-06-21' AND '2016-07-02'
),
 ----combining all 3days normal total price,quantity, daily gross profit
PED_Calc AS (
    SELECT
        SUBSTRING(T1.Period, 1, 1) AS Promo_Set,
        T1.Avg_Price AS Normal_price,
        T1.Avg_Quantity AS Normal_quantity,
        T1.Avg_Daily_Gross_Profit AS Normal_daily_gross_profit,
 
--- combining all 3 days promo total price,quantity, daily gross profit
        T2.Avg_Price AS Promo_price,
        T2.Avg_Quantity AS Promo_quantity,
        T2.Avg_Daily_Gross_Profit AS Promo_daily_gross_profit
 
    FROM AvgData as  T1
    INNER JOIN AvgData as T2
        ON SUBSTRING(T1.Period, 1, 1) = SUBSTRING(T2.Period, 1, 1)
        AND T1.Period LIKE '%Normal'
        AND T2.Period LIKE '%Promo'
)
SELECT
    Promo_Set,
    ROUND(Normal_price, 2) AS Avg_Price_Normal, 
    ROUND(Promo_price, 2) AS Avg_Price_Promo, 
    ROUND(Normal_quantity, 0) AS Avg_Qty_Normal, 
    ROUND(Promo_quantity, 0) AS Avg_Qty_Promo, 
    ROUND(
        (
            ((Promo_quantity - Normal_quantity) / ((Promo_quantity + Normal_quantity) / 2)) 
            /
            ((Promo_price - Normal_price) / ((Promo_price + Normal_price) / 2))
        ), 2
    ) AS Final_PED,
    CASE
        WHEN (Promo_daily_gross_profit > Normal_daily_gross_profit) THEN 'BETTER (Higher Total Profit)'
        WHEN (Promo_daily_gross_profit < Normal_daily_gross_profit) THEN 'WORSE (Lower Total Profit)'
        ELSE 'SAME'
    END AS Performance_Conclusion
FROM PED_Calc
ORDER BY Promo_Set;
