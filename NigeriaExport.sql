CREATE DATABASE Projects;

USE Projects
GO

CREATE SCHEMA NGE;
GO


SELECT *
FROM.NGE.Exports;

SELECT *
INTO NGE.ExportStage
FROM NGE.Exports
WHERE 1 = 0;

SELECT *
FROM NGE.ExportStage;

INSERT NGE.ExportStage
SELECT *
FROM NGE.Exports;

EXEC sp_rename 'NGE.ExportStage.Product_Name', 'ProductName'
EXEC sp_rename 'NGE.ExportStage.Export_Country', 'ExportCountry'
EXEC sp_rename 'NGE.ExportStage.Date', 'ExportDate'
EXEC sp_rename 'NGE.ExportStage.Units_Sold', 'UnitsSold'
EXEC sp_rename 'NGE.ExportStage.unit_price', 'UnitPrice'
EXEC sp_rename 'NGE.ExportStage.Profit_per_unit', 'ProfitPerUnit'
EXEC sp_rename 'NGE.ExportStage.Export_Value', 'ExportValue'
EXEC sp_rename 'NGE.ExportStage.Destination_Port', 'DestinationPort'
EXEC sp_rename 'NGE.ExportStage.Transportation_Mode', 'TransportationMode'



SELECT *
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'ExportStage';


SELECT DISTINCT ES.ProductName
FROM NGE.ExportStage ES
ORDER BY 1;

SELECT DISTINCT ES.Company
FROM NGE.ExportStage ES
ORDER BY 1;

SELECT DISTINCT ES.ExportCountry
FROM NGE.ExportStage ES
ORDER BY 1;


SELECT DISTINCT ES.DestinationPort
FROM NGE.ExportStage ES
ORDER BY 1;


SELECT DISTINCT ES.TransportationMode
FROM NGE.ExportStage ES
ORDER BY 1;


SELECT *
	, ROW_NUMBER() OVER(
		PARTITION BY E.ProductName, E.Company, E.ExportCountry, E.ExportDate, E.UnitsSold, E.UnitPrice, E.ProfitPerUnit, E.ExportValue, E.DestinationPort, E.TransportationMode
		ORDER BY E.ProductName) AS RowNumber
FROM NGE.ExportStage E;


WITH CheckDuplicate AS (
	SELECT *
	 , ROW_NUMBER() OVER(
		PARTITION BY E.ProductName, E.Company, E.ExportCountry, E.ExportDate, E.UnitsSold, E.UnitPrice, E.ProfitPerUnit, E.ExportValue, E.DestinationPort, E.TransportationMode
		ORDER BY E.ProductName) AS RowNumber
	FROM NGE.ExportStage E
	)
SELECT *
FROM CheckDuplicate
WHERE CheckDuplicate.RowNumber > 1
;



ALTER TABLE NGE.ExportStage
ADD ExportMonth CHAR(20)
; 

ALTER TABLE NGE.ExportStage
ADD ExportQuarter CHAR(20)
;

ALTER TABLE NGE.ExportStage
ADD ExportYear CHAR(20)
;


UPDATE NGE.ExportStage
SET ExportMonth = MONTH(ExportDate)
;

UPDATE NGE.ExportStage
SET ExportQuarter = DATEPART(QUARTER, ExportDate)
;

UPDATE NGE.ExportStage
SET ExportYear = YEAR(ExportDate)
;


SELECT *
FROM NGE.ExportStage;


-- Top-selling products
SELECT E.ProductName
	, ROUND(SUM(E.ExportValue), 2) AS TotalValue
FROM NGE.ExportStage E
GROUP BY E.ProductName
ORDER BY SUM(E.ExportValue) DESC
;


-- Company with highest sales revenue
SELECT E.Company
	, SUM(E.ExportValue) AS SalesRevenue
FROM NGE.ExportStage E
GROUP BY E.Company
ORDER BY SUM(E.ExportValue) DESC
OFFSET 0 ROWS
FETCH NEXT 1 ROWS ONLY
;


-- Sales variation across different countries
-- Top product per total sales
WITH SalesDetails AS (
	SELECT E.ProductName
		, E.ExportCountry
		, SUM(E.ExportValue) AS TotalSales
	FROM NGE.ExportStage E
	GROUP BY E.ProductName, E.ExportCountry
	),
RankedSalesDetails AS (
	SELECT *
		, RANK() OVER(PARTITION BY SD.ExportCountry ORDER BY SD.TotalSales DESC) AS Ranked
	FROM SalesDetails SD
	)
SELECT RD.ExportCountry
	, RD.ProductName
	, RD.TotalSales
FROM RankedSalesDetails RD
WHERE RD.Ranked <= 1
;

-- Average revenue
SELECT E.ExportCountry
	, AVG(E.ExportValue) AS AverageRevenue
FROM NGE.ExportStage E
GROUP BY E.ExportCountry
ORDER BY AVG(E.ExportValue) DESC
;

-- Total units sold
SELECT E.ExportCountry
	, E.ProductName
	, SUM(E.UnitsSold) AS TotalUnitsSold
FROM NGE.ExportStage E
GROUP BY E.ExportCountry, E.ProductName 
ORDER BY SUM(E.UnitsSold) DESC
;


-- Correlation between UnitsSold and Profit
SELECT CORR()
FROM NGE.ExportStage E
;