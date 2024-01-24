CREATE PROCEDURE [dbo].[ProcGetFundHoldingAnalytics]
(
@CompanyIds NVARCHAR(MAX)=NULL,
@SubPageIds NVARCHAR(1000) = NULL,
@FieldIds NVARCHAR(MAX) =NULL
)
AS
BEGIN
SET NOCOUNT ON;
	DECLARE @trAliasColumns NVARCHAR(MAX), @trCustomAliasColumns NVARCHAR(MAX), @sql NVARCHAR(MAX),@columnsDealStaticWithAliases NVARCHAR(MAX),@columnsPcWithAliases NVARCHAR(MAX),@columnsFundWithAliases NVARCHAR(MAX),@columnsCustom NVARCHAR(MAX);
 
-- Get the column names and their aliases from the settings table
	SELECT @trAliasColumns = STRING_AGG(Name + ' AS ' + QUOTENAME(AliasName), ', ')
	FROM M_SubPageFields
	WHERE SubPageID = 6 AND IsCustom = 0 AND isDeleted = 0;
 
	SELECT @trCustomAliasColumns = STRING_AGG(QUOTENAME(AliasName), ', ')
	FROM M_SubPageFields
	WHERE SubPageID = 6 AND isActive = 1 AND isDeleted = 0 AND IsCustom = 1;
 
	 SELECT @columnsDealStaticWithAliases = STRING_AGG(Name + ' AS ' + QUOTENAME(AliasName), ', ')
		FROM M_SubPageFields
		WHERE SubPageID = 5 AND IsCustom = 0 AND isDeleted = 0 AND Name!='DealCustomID';
 
	SELECT @columnsPcWithAliases = STRING_AGG(Name + ' AS ' + QUOTENAME(AliasName), ', ')
		FROM M_SubPageFields
		WHERE SubPageID = 1 AND IsCustom = 0 AND isDeleted = 0 AND Name NOT IN ('DealId','FundId','CompanyLogo');
 
	SELECT @columnsFundWithAliases = STRING_AGG(Name + ' AS ' + QUOTENAME(AliasName), ', ')
		FROM M_SubPageFields
		WHERE SubPageID in (7,8,12) AND IsCustom = 0 AND isDeleted = 0;
 
	SELECT   @columnsCustom = STRING_AGG(QUOTENAME(AliasName), ', ')
	FROM M_SubPageFields
	WHERE SubPageID IN (1,5,7,8,10,11,12) AND isActive = 1 AND isDeleted = 0 AND IsCustom = 1 and AliasName!='Custom %';
	-- Construct the SQL query using a CTE
	SET @sql = '
	WITH cteCustomTrackRecord AS (
		SELECT FieldValue, Quarter, Year, PageFeatureId, F.AliasName
		FROM PageConfigurationTrackRecordFieldValue V
		INNER JOIN M_SubPageFields F ON V.FieldID = F.FieldID
		WHERE FieldValue IS NOT NULL AND V.IsDeleted = 0 AND V.IsActive = 1
			AND V.FieldID IN (
				SELECT FieldID
				FROM M_SubPageFields
				WHERE SubPageID = 6 AND isActive = 1 AND isDeleted = 0 AND IsCustom = 1
			)
		GROUP BY FieldValue, Quarter, Year, PageFeatureId, F.AliasName
	)
 
	SELECT Tr.*, ' + @trCustomAliasColumns + ',ST.*,PC.*,F.*,'+@columnsCustom+'
	FROM (
		SELECT PortfolioCompanyId, FundId, DealId, Year, ' + @trAliasColumns + '
		FROM view_GetAnalyticsDealTradingConsolidatedDetails
	) AS Tr
	LEFT JOIN (
		SELECT *
		FROM cteCustomTrackRecord
		PIVOT (
			MAX(FieldValue) FOR AliasName IN (' + @trCustomAliasColumns + ')
		) AS PivotTable
	) AS cTR ON Tr.DealId = cTR.PageFeatureId AND Tr.Quarter = cTR.Quarter AND Tr.Year = cTR.Year
	LEFT JOIN (SELECT DealId,' + @columnsDealStaticWithAliases + ' FROM view_GetDealConsolidatedDetails Cons INNER JOIN FundDetails Fd ON Fd.FundID = Cons.FundId 
	INNER JOIN PortfolioCompanyDetails Comp ON Comp.PortfolioCompanyID = Cons.PortfolioCompanyId WHERE Comp.IsDeleted = 0 AND Fd.IsDeleted = 0) as ST ON Tr.DealId=ST.DealId
	LEFT JOIN (SELECT PortfolioCompanyId,' + @columnsPcWithAliases + ' FROM view_GetAnalyticsPortfolioCompanyDetails) AS PC ON PC.PortfolioCompanyId = Tr.PortfolioCompanyId
	LEFT JOIN (SELECT FundID,' + @columnsFundWithAliases + ' FROM view_ConsolidatedFundDetails) AS F ON F.FundID = Tr.FundId
	LEFT JOIN (SELECT *
	FROM (
	  SELECT FieldValue,PageFeatureId, F.AliasName 
	  FROM PageConfigurationFieldValue V
	  INNER JOIN M_SubPageFields F ON V.FieldID = F.FieldID
	  WHERE FieldValue IS NOT NULL AND FieldValue!=''NA''  AND V.IsDeleted = 0 AND V.IsActive = 1 
		AND V.FieldID IN (
		  SELECT FieldID
		  FROM M_SubPageFields
		  WHERE SubPageID IN (1,5,7,8,10,11,12) AND isActive = 1 AND isDeleted = 0 AND IsCustom = 1 and AliasName!=''Custom %''
		)
	  GROUP BY FieldValue, PageFeatureId, F.AliasName
	) AS A
	PIVOT (
	  MAX(FieldValue) FOR AliasName IN (' + @columnsCustom + ')
	) AS PivotTable) AS STA ON STA.PageFeatureId = Tr.DealId OR  STA.PageFeatureId = Tr.PortfolioCompanyId OR STA.PageFeatureId = Tr.FundId;';
 
	-- Execute the dynamic SQL query
	EXEC sp_executesql @sql;
SET NOCOUNT ON;
END