/* ========================================
Script:         WindowFunctions.sql

Run it in:      Whole script

What it does:   Demonstrates window functions

Limitations:    SQL Server 2012+ only.
  
Safe for Prod:  NO
                Use for test/demo purposes only.

==========================================*/

USE AdventureWorks2012
GO

SELECT
CustomerID
, DueDate
, TotalDue
/* ROW_NUMBER will list the number of the row, ordered by CustomerID.
   The counter will reset with every new combination of CustomerID */
, ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY CustomerID) AS CustomerOrderSeq

/* SUM will add up the totaldue values.*/
, SUM(TotalDue) OVER () AS GrandTotalDue
, SUM(TotalDue) OVER (PARTITION BY DueDate) AS DateTotalDue
, SUM(TotalDue) OVER (PARTITION BY DueDate, CustomerID) AS CustomerTotalDue

/* AVG will show the average due. */
, AVG(TotalDue) OVER (PARTITION BY DueDate) AS DateAvgDue
, AVG(TotalDue) OVER (PARTITION BY DueDate, CustomerID) AS CustomerDateAvgDue

/* LAG and LEAD allow the current row to report on data in rows behind or ahead of it.*/
, LAG(TotalDue, 1, 0) OVER (ORDER BY CustomerID) AS PrevDue
, LEAD(TotalDue, 3) OVER (ORDER BY CustomerID) AS Ahead3Due

/* FIRST_VALUE AND LAST_VALUE will return the specified column's first and last value in the result set.
   ***WARNING: without the ROWS BETWEEN in the LAST_VALUE, you may get unexpected results.***
*/
, FIRST_VALUE(TotalDue) OVER (ORDER BY DueDate) AS FirstDue
, LAST_VALUE(TotalDue) OVER (ORDER BY DueDate ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS LastDue

/* SUM using ROWS BETWEEN will narrow the scope evaluated by the window function.
   The function will begin and end where the ROWS BETWEEN specify.
*/
, SUM(TotalDue) OVER (ORDER BY DueDate ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS DueRunningTotal
, SUM(TotalDue) OVER (ORDER BY DueDate ROWS BETWEEN 3 PRECEDING AND CURRENT ROW) AS TotalDueLast4
FROM Sales.SalesOrderHeader
order by CustomerID, DueDate


/*
	Another example of various groupings of data in a database and calculations performed on them.
*/

USE AdventureWorks2012
GO

SELECT customerID, CalendarMonth, CalendarQuarter, CalendarYear, TotalDue
, SUM(TotalDue) OVER (PARTITION BY CustomerID, CalendarYear, CalendarQuarter ORDER BY CalendarMonth ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS QTDTotalDue
, SUM(TotalDue) OVER (PARTITION BY CustomerID, CalendarYear ORDER BY CalendarMonth ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS YTDTotalDue
, SUM(TotalDue) OVER (PARTITION BY CustomerID) AS AllTimeTotalDue
, SUM(TotalDue) OVER (PARTITION BY CustomerID ORDER BY CalendarYear, CalendarMonth ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS RunningTotalTotalDue
, SUM(TotalDue) OVER (PARTITION BY CustomerID ORDER BY CalendarYear, CalendarMonth ROWS BETWEEN 1 FOLLOWING AND UNBOUNDED FOLLOWING) AS RemainingFutureTotalDue
, SUM(TotalDue) OVER (PARTITION BY CustomerID ORDER BY CalendarYear, CalendarMonth ROWS BETWEEN 1 FOLLOWING AND UNBOUNDED FOLLOWING)
	/SUM(TotalDue) OVER (PARTITION BY CustomerID) AS PctRemainingFutureTotalDue
, SUM(TotalDue) OVER (PARTITION BY CustomerID, CalendarYear, CalendarQuarter ORDER BY CalendarMonth) AS ThisQtrTotalDue
, SUM(TotalDue) OVER (PARTITION BY CustomerID, CalendarYear ORDER BY CalendarMonth) AS ThisYearTotalDue
, SUM(TotalDue) OVER (PARTITION BY CustomerID ORDER BY CalendarYear, CalendarMonth ROWS BETWEEN 11 PRECEDING AND CURRENT ROW) AS Rolling12TotalDue
, TotalDue/SUM(TotalDue) OVER (PARTITION BY CustomerID, CalendarYear, CalendarQuarter) AS PctOfThisQtrTotalDue
, TotalDue/SUM(TotalDue) OVER (PARTITION BY CustomerID, CalendarYear) AS PctOfThisYearTotalDue
, LAG(TotalDue, 1) OVER (PARTITION BY CustomerID ORDER BY CalendarYear, CalendarMonth) AS PrevMonthTotalDue
, LAG(TotalDue, 3) OVER (PARTITION BY CustomerID ORDER BY CalendarYear, CalendarMonth) AS SameMonthPrevQtrTotalDue
, LAG(TotalDue, 12) OVER (PARTITION BY CustomerID ORDER BY CalendarYear, CalendarMonth) AS SameMonthPrevYearTotalDue
, AVG(TotalDue) OVER (PARTITION BY CustomerID, CalendarYear ORDER BY CalendarMonth ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS YTDAvgTotalDue
FROM Sales.SalesOrderHeader AS soh
JOIN dbo.DimDate AS dd on dd.CalendarDate = soh.DueDate
WHERE CustomerID = 11091
ORDER BY CustomerID, CalendarYear, CalendarMonth