CREATE OR ALTER PROCEDURE [dbo].[sp_GenerateSampleJSON] (@inputjson NVARCHAR(MAX)) AS 

BEGIN

-- Ensures the input JSON is enclosed within []
IF NOT EXISTS (SELECT TOP 1 [key] FROM OPENJSON(@inputjson, '$[0]')) SET @inputjson = '[' + @inputjson + ']';

-- Recursive CTE to process all JSON nesting levels 
WITH
	CTE([path], [value], [type])
AS
	(
	SELECT
		[path] = [key], -- The path matches the key for the root level
		[value],
		[type]
	FROM
		OPENJSON(@inputjson, '$[0]') A
	UNION ALL
	SELECT
		[path] = CASE WHEN CTE.[type] = 4 THEN CTE.[path] ELSE CONCAT(CTE.[path], '.', B.[key]) END, -- The path separates the levels with a '.'
		B.[value],
		B.[type]
	FROM CTE
	OUTER APPLY OPENJSON(CTE.[value]) B
	WHERE CTE.[type] > 3 -- This ensures the recursion only applies to arrays and objects
	)

SELECT DISTINCT
	[key] = [path],
	[value] =
		CASE
			WHEN [type] = 1 AND ISDATE([value]) = 1 AND ISNUMERIC([value]) = 0 THEN '2020-01-01T12:34:56.789Z' -- This is the sample value for dates
			WHEN [type] = 2 THEN '***NUMBER***' -- This will be later replaced by a sample value for numbers
			WHEN [type] = 3 THEN '***BOOLEAN***' -- This will be later replaced by a sample value for booleans
			ELSE 'abcdefghijklmnopqrstuvwxyz' -- This is the sample value for strings
		END
INTO #JSON -- The result of this query is stored in a temp table
FROM CTE WHERE [type] < 4 -- This ensures only the leaves are returned
ORDER BY [key] -- Orders the keys alphabetically

-- Declare variables
DECLARE @cols NVARCHAR(MAX), @query NVARCHAR(MAX)

-- The @cols variable contains all output column names concatenated, and it will be used in the PIVOT operation later
SET @cols = STUFF((SELECT DISTINCT ',' + QUOTENAME([key]) FROM #JSON FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 1, '')

-- The @query variable contains dynamic SQL code that will be later executed
SET @query = 'SELECT @outputjson = (
	SELECT
		' + @cols + '
	FROM
		(SELECT * FROM #JSON) X
		PIVOT (MAX([value]) FOR [key] IN ('+ @cols +')) P -- This transposes rows into columns
	FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
)'

-- Declares the output variable for the dynamic query execution
DECLARE @outputjson NVARCHAR(MAX)

-- Executes the dynamic SQL code in the @query variable, and stores the result in the @outputjson variable
EXECUTE sp_executesql @query, N'@outputjson NVARCHAR(MAX) OUTPUT', @outputjson = @outputjson OUTPUT

-- This replace the number and boolean placeholders with sample values
SET @outputjson = REPLACE(REPLACE(@outputjson, '"***NUMBER***"', '1234567890'), '"***BOOLEAN***"', 'true')

-- This ensures all objects are returned as arrays (this is a simplification to make it easier to handle in Azure Data Factory)
SET @outputjson = REPLACE(REPLACE(@outputjson, '{', '[{'), '}', '}]')

-- Outputs the result
SELECT @outputjson AS [outputjson]

END
GO
