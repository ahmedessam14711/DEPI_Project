CREATE DATABASE SupplyChain
USE SupplyChain
GO

--Exploring the data
SELECT * FROM DataCo

--Checking for duplicate values
SELECT COUNT (*) FROM DataCo AS duplicate_count
SELECT DISTINCT COUNT (*) FROM DataCo AS duplicate_count

--Checking for null values (Repeat for each column)
SELECT * FROM DataCo
WHERE Shipping_Mode iS NULL

--Replacing missing values in Customer_Lname column
UPDATE DataCo
SET Customer_Lname = Customer_Fname
WHERE Customer_Lname IS NULL 

--Replacing missing values in Customer_Zipcode column
UPDATE DataCo
SET Customer_City = 'Elk Grove',
Customer_State = 'CA',
Customer_Zipcode = '95758'
WHERE Customer_Zipcode IS NULL AND Customer_State = '95758'	
UPDATE DataCo
SET Customer_City = 'El Monte',
Customer_State = 'CA',
Customer_Zipcode = '91732'
WHERE Customer_Zipcode IS NULL AND Customer_State = '91732' 

--Handling null values
SELECT
    COUNT(*) AS total_rows,
	SUM(CASE WHEN Order_Zipcode IS NULL THEN 1 ELSE 0 END) AS Order_Zipcode_nulls,
    SUM(CASE WHEN Product_Description IS NULL THEN 1 ELSE 0 END) AS Product_Description_nulls
FROM DataCo

--Replacing missing values in Order_Zipcode column
SELECT Order_City, Order_State, Order_Zipcode 
FROM DataCo
WHERE Order_Zipcode IS NULL

WITH ZipcodeInference AS (
	SELECT Order_State, Order_City ,Order_Zipcode, COUNT(*) AS Zipcode_Count,
	ROW_NUMBER() OVER (PARTITION BY Order_State, Order_City ORDER BY COUNT(*) DESC) AS RN
	FROM DataCo
	WHERE Order_Zipcode IS NOT  NULL
	GROUP BY Order_State, Order_City ,Order_Zipcode
)
UPDATE DataCo
SET Order_Zipcode = (
	SELECT Order_Zipcode FROM ZipcodeInference
	WHERE ZipcodeInference.Order_State = DataCo.Customer_State
	AND ZipcodeInference.Order_City = DataCo.Customer_City
	AND RN = 1
	)
WHERE Order_Zipcode IS NULL

--Deleting (Benefit_per_order) column as it hse the same values in (Order_Profit_Per_Order) column
SELECT * FROM DataCo
WHERE Order_Profit_Per_Order <> Benefit_per_order
ALTER TABLE DataCo
DROP COLUMN Benefit_per_order

--Deleting (Sales_per_customer) column as it has the same values in (Order_Item_Total) column
SELECT * FROM DataCo
WHERE Order_Item_Total <> Sales_per_customer
ALTER TABLE DataCo
DROP COLUMN Sales_per_customer

--Deleting columns with no data or useless
ALTER TABLE DataCo
DROP COLUMN Customer_Email, Customer_Password, Product_Description, Product_Image 

----------------------------------------------------------------

-----------------------*Listing the KPIs*-----------------------

--1. Order Accuracy Rate
SELECT 
CONCAT(COUNT(DISTINCT Order_Id) * 100 / (SELECT COUNT(DISTINCT Order_Id) FROM DataCo),'%') AS "Order Accuracy Rate"
FROM DataCo
WHERE Order_Status IN ('COMPLETE', 'CLOSED')

--2. On-time Delivery Rate
SELECT
CONCAT(COUNT(DISTINCT Order_Id) * 100 / (SELECT COUNT(DISTINCT Order_Id) FROM DataCo),'%') AS "On-time Delivery Rate"
FROM DataCo
WHERE Days_for_shipping_real <= Days_for_shipment_scheduled

--3. Perfect Order Rate
SELECT 
CONCAT(COUNT(DISTINCT Order_Id) * 100 / (SELECT COUNT(DISTINCT Order_Id) FROM DataCo), '%') AS "Perfect Order Rate"
FROM DataCo
WHERE Order_Status IN ('COMPLETE', 'CLOSED')
AND Days_for_shipping_real <= Days_for_shipment_scheduled

--4. Order Lead Time
SELECT 
AVG(DATEDIFF(DAY, order_date_DateOrders, shipping_date_DateOrders)) AS "Lead Time" 
FROM DataCo

--5. Order Cycle Time
SELECT
AVG(DATEDIFF(DAY, order_date_DateOrders, DATEADD(DAY, Days_for_shipping_real, shipping_date_DateOrders))) AS "Real Cycle Time" 
FROM DataCo

--Cycle time with schedualed date
SELECT
AVG(DATEDIFF(DAY, order_date_DateOrders, DATEADD(DAY, Days_for_shipment_scheduled, shipping_date_DateOrders))) AS "Scheduled Cycle time"
FROM DataCo

--Real vs Scheduled Shipping Days per Shipping Mode
SELECT Shipping_Mode,
AVG(Days_for_shipment_scheduled) AS "Average Scheduled Shipping Days",
AVG(Days_for_shipping_real) AS "Average Real Shipping Days"
FROM DataCo
GROUP BY Shipping_Mode
ORDER BY "Average Scheduled Shipping Days"

--Real vs Scheduled Cycle time per Shipping mode
SELECT
Shipping_Mode,
AVG(DATEDIFF(DAY, order_date_DateOrders, DATEADD(DAY, Days_for_shipment_scheduled, shipping_date_DateOrders))) AS "Scheduled Cycle time",
AVG(DATEDIFF(DAY, order_date_DateOrders, DATEADD(DAY, Days_for_shipping_real, shipping_date_DateOrders))) AS "Real Cycle time"
FROM DataCo
GROUP BY Shipping_Mode
ORDER BY "Scheduled Cycle time"

--Real vs Scheduled Cycle time per Customer City
SELECT
Customer_City,
AVG(DATEDIFF(DAY, order_date_DateOrders, DATEADD(DAY, Days_for_shipment_scheduled, shipping_date_DateOrders))) AS "Scheduled Cycle time",
AVG(DATEDIFF(DAY, order_date_DateOrders, DATEADD(DAY, Days_for_shipping_real, shipping_date_DateOrders))) AS "Real Cycle time"
FROM DataCo
GROUP BY Customer_City
ORDER BY "Real Cycle time"

--Late Orders
SELECT Department_Name,  
COUNT(Late_delivery_risk) as "Late Delivery"
FROM DataCo
WHERE Late_delivery_risk = 1
GROUP BY Department_Name
ORDER BY "Late Delivery" DESC
 
--6. Important KPIs 
SELECT
SUM(Order_Item_Quantity) as "Total Order Quantity",
COUNT(DISTINCT Order_Id) AS "Number of Orders",
FORMAT(SUM(Sales), 'C', 'en-US') AS "Total Sales without Discount",
FORMAT(SUM(Order_Item_Discount), 'C', 'en_US') AS "Total Discount",
FORMAT(SUM(Order_Item_Total), 'C', 'en_US') AS "Total Sales with Discount",
FORMAT(SUM(Order_Profit_Per_Order), 'C', 'en_US') AS "Total Profit"
FROM DataCo

--KPIs per Type
SELECT Type,
SUM(Order_Item_Quantity) as "Total Order Quantity",
COUNT(DISTINCT Order_Id) AS "Number of Orders",
FORMAT(SUM(Sales), 'C', 'en-US') AS "Total Sales without Discount",
FORMAT(SUM(Order_Item_Discount), 'C', 'en_US') AS "Total Discount",
FORMAT(SUM(Order_Item_Total), 'C', 'en_US') AS "Total Sales with Discount",
FORMAT(SUM(Order_Profit_Per_Order), 'C', 'en_US') AS "Total Profit"
FROM DataCo
GROUP BY Type
ORDER BY SUM(Order_Item_Total) DESC

--KPIs per Customer Segment
SELECT Customer_Segment,
SUM(Order_Item_Quantity) as "Total Order Quantity",
COUNT(DISTINCT Order_Id) AS "Number of Orders",
FORMAT(SUM(Sales), 'C', 'en-US') AS "Total Sales without Discount",
FORMAT(SUM(Order_Item_Discount), 'C', 'en_US') AS "Total Discount",
FORMAT(SUM(Order_Item_Total), 'C', 'en_US') AS "Total Sales with Discount",
FORMAT(SUM(Order_Profit_Per_Order), 'C', 'en_US') AS "Total Profit"
FROM DataCo
GROUP BY Customer_Segment
ORDER BY SUM(Order_Item_Total) DESC

--KPIs per Department
SELECT Department_Name,
SUM(Order_Item_Quantity) as "Total Order Quantity",
COUNT(DISTINCT Order_Id) AS "Number of Orders",
FORMAT(SUM(Sales), 'C', 'en-US') AS "Total Sales without Discount",
FORMAT(SUM(Order_Item_Discount), 'C', 'en_US') AS "Total Discount",
FORMAT(SUM(Order_Item_Total), 'C', 'en_US') AS "Total Sales with Discount",
FORMAT(SUM(Order_Profit_Per_Order), 'C', 'en_US') AS "Total Profit"
FROM DataCo
GROUP BY Department_Name
ORDER BY SUM(Order_Item_Total) DESC

--KPIs per Category Name
SELECT Category_Name,
SUM(Order_Item_Quantity) as "Total Order Quantity",
COUNT(DISTINCT Order_Id) AS "Number of Orders",
FORMAT(SUM(Sales), 'C', 'en-US') AS "Total Sales without Discount",
FORMAT(SUM(Order_Item_Discount), 'C', 'en_US') AS "Total Discount",
FORMAT(SUM(Order_Item_Total), 'C', 'en_US') AS "Total Sales with Discount",
FORMAT(SUM(Order_Profit_Per_Order), 'C', 'en_US') AS "Total Profit"
FROM DataCo
GROUP BY Category_Name
ORDER BY SUM(Order_Item_Total) DESC

--KPIs per Region
SELECT Order_Region,
SUM(Order_Item_Quantity) as "Total Order Quantity",
COUNT(DISTINCT Order_Id) AS "Number of Orders",
FORMAT(SUM(Sales), 'C', 'en-US') AS "Total Sales without Discount",
FORMAT(SUM(Order_Item_Discount), 'C', 'en_US') AS "Total Discount",
FORMAT(SUM(Order_Item_Total), 'C', 'en_US') AS "Total Sales with Discount",
FORMAT(SUM(Order_Profit_Per_Order), 'C', 'en_US') AS "Total Profit"
FROM DataCo
GROUP BY Order_Region
ORDER BY SUM(Order_Item_Total) DESC

--7.Average Order Value (AOV)
SELECT 
FORMAT(SUM(Order_Item_Total) / COUNT(Order_Item_Id), 'C', 'en-US') AS "Average Order Value"
FROM DataCo

--8.Lost Sales
SELECT FORMAT(SUM(Order_Item_Total), 'C', 'en-US') AS "Lost Sales"
FROM DataCo
WHERE Order_Status = 'CANCELED'

--9.Return Rate
SELECT
COUNT(DISTINCT Order_Id) AS "Total Returned Orders",
FORMAT(SUM(Order_Profit_Per_Order), 'C', 'en-US') AS "Total Returned Money",
CONCAT(COUNT(DISTINCT Order_Id) * 100 / (SELECT COUNT(DISTINCT Order_Id) FROM DataCo), '%') AS "Return Rate"
FROM DataCo
WHERE Order_Profit_Per_Order < 0 
AND Delivery_Status <> 'Shipping Canceled'

--Return Rate per Category Name
SELECT TOP(5)
Category_Name,
FORMAT(SUM(Order_Profit_Per_Order), 'C', 'en-US') AS "Total Returned Money",
CONCAT(COUNT(DISTINCT Order_Id) * 100 / (SELECT COUNT(DISTINCT Order_Id) FROM DataCo), '%') AS "Return Rate"
FROM DataCo
WHERE Order_Profit_Per_Order < 0 
AND Delivery_Status <> 'Shipping Canceled'
GROUP BY Category_Name
ORDER BY "Return Rate" DESC

--Return Rate per Shipping Mode
SELECT 
Shipping_Mode,
FORMAT(SUM(Order_Profit_Per_Order), 'C', 'en-US') AS "Total Returned Money",
CONCAT(COUNT(DISTINCT Order_Id) * 100 / (SELECT COUNT(DISTINCT Order_Id) FROM DataCo), '%') AS "Return Rate"
FROM DataCo
WHERE Order_Profit_Per_Order < 0 
AND Delivery_Status <> 'Shipping Canceled'
GROUP BY Shipping_Mode
ORDER BY SUM(Order_Profit_Per_Order) 