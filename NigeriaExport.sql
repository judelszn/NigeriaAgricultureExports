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
WITH Mean AS (
	SELECT E.UnitPrice
		, E.ProfitPerUnit
		, AVG(E.UnitPrice) OVER() AS UnitPriceMean
		, AVG(E.ProfitPerUnit) OVER() AS ProfitMean 
	FROM NGE.ExportStage E
	),
Variance AS (
	SELECT AVG(POWER(M.UnitPrice - M.UnitPriceMean, 2)) AS VarUnitPrice
		, AVG(POWER(M.ProfitPerUnit - M.ProfitMean, 2)) AS VarProfit
	FROM Mean M
	),
StandardDeviation AS (
	SELECT POWER(V.VarUnitPrice, 0.5) AS UnitPriceSTD
		, POWER(V.VarProfit, 0.5) AS ProfitSTD 
	FROM Variance V
	),
Covariance AS (
	SELECT AVG((M.UnitPrice - M.UnitPriceMean) * (M.ProfitPerUnit - M.ProfitMean)) AS CovPP
	FROM Mean M
	) 
SELECT ROUND(CV.CovPP / (STD.ProfitSTD * STD.UnitPriceSTD), 3) AS CorrCoeff
FROM Covariance CV
CROSS JOIN StandardDeviation STD
;


-- Sales variation over time
-- Monthly
SELECT E.ExportMonth
	, AVG(E.ExportValue) AS AverageSalesValuePerMonth
	, SUM(E.UnitsSold) AS TotalUnitsSoldPerMonth
FROM NGE.ExportStage E
GROUP BY E.ExportMonth
ORDER BY AVG(E.ExportValue) DESC, SUM(E.UnitsSold) DESC
;


-- Quarterly
SELECT E.ExportQuarter
	, AVG(E.ExportValue) AS AverageSalesValuePerQuarter
	, SUM(E.UnitsSold) AS TotalUnitsSoldPerQuarter
FROM NGE.ExportStage E
GROUP BY E.ExportQuarter
ORDER BY AVG(E.ExportValue) DESC, SUM(E.UnitsSold) DESC
;


-- Annually 
SELECT E.ExportYear
	, AVG(E.ExportValue) AS AverageSalesValuePerYear
	, SUM(E.UnitsSold) AS TotalUnitsSoldPerYear
FROM NGE.ExportStage E
GROUP BY E.ExportYear
ORDER BY AVG(E.ExportValue) DESC, SUM(E.UnitsSold) DESC
;


-- Relationship between date of purchase and profit margin
SELECT DATEPART(MONTH, E.ExportDate) AS PurchaseMonth
	, SUM(E.ProfitPerUnit) AS TotalProfit
FROM NGE.ExportStage E
GROUP BY DATEPART(MONTH, E.ExportDate)
;


-- Cost of goods sold as a percentage of revenue



-- Destination Port with highest volume of exports
SELECT E.DestinationPort
	, SUM(E.UnitsSold) AS EcportsVolume
FROM NGE.ExportStage E
GROUP BY E.DestinationPort
ORDER BY SUM(E.UnitsSold) DESC
OFFSET 0 ROWS
FETCH NEXT 1 ROWS ONLY
;


-- Common Transportation mode
SELECT E.TransportationMode
	, COUNT(*) AS TransportationModeCount
FROM NGE.ExportStage E
GROUP BY E.TransportationMode
ORDER BY COUNT(*) DESC
;


-- Rank of destination port by export value
WITH DestinationPortDetails AS (
	SELECT E.DestinationPort
		, ROUND(SUM(E.ExportValue), 2) AS TotalExportValue
	FROM NGE.ExportStage E
	GROUP BY E.DestinationPort
	)
SELECT *
	, RANK() OVER(ORDER BY DD.TotalExportValue) AS Ranked
FROM DestinationPortDetails DD
;


-- Top export product for each port
WITH ProductsDetail AS (
	SELECT E.ProductName
		, E.DestinationPort
		, COUNT(E.ProductName) AS ProductsCount
	FROM NGE.ExportStage E
	GROUP BY E.ProductName, E.DestinationPort
	),
ExportProducts AS (
	SELECT *
		, RANK() OVER(PARTITION BY PD.DestinationPort ORDER BY PD.ProductsCount DESC) AS Ranked
	FROM ProductsDetail PD)
SELECT EP.DestinationPort
	, EP.ProductName
	, EP.ProductsCount
--	, EP.Ranked
FROM ExportProducts EP
WHERE EP.Ranked < 2
;


-- Performance comparism
-- Product performance in terms of profit margin
SELECT E.ProductName
	, ROUND(SUM(E.ProfitPerUnit), 2) AS TotalProfitMargin
	, ROUND(AVG(E.ProfitPerUnit), 2) AS AverageProfitMargin
FROM NGE.ExportStage E
GROUP BY E.ProductName
ORDER BY SUM(E.ProfitPerUnit) DESC
;


-- Company performance based on units sold and profit
SELECT E.Company
	, SUM(E.UnitsSold) AS TotalUnitsSold
	, SUM(E.UnitsSold * E.ProfitPerUnit) AS TotalProfit
FROM NGE.ExportStage E
GROUP BY E.Company
ORDER BY SUM(E.UnitsSold) DESC
;





SELECT *
FROM NGE.ExportStage;