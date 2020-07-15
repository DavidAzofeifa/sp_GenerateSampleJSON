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
		[path] = [key],
		[value],
		[type]
    FROM
		OPENJSON(@inputjson, '$[0]') A
    UNION ALL
    SELECT
		[path] = CASE WHEN CTE.[type] = 4 THEN CTE.[path] ELSE CONCAT(CTE.[path], '.', B.[key]) END,
        B.[value],
		B.[type]
    FROM CTE
	OUTER APPLY OPENJSON(CTE.[value]) B
    WHERE CTE.[type] > 3
    )

SELECT DISTINCT
	[key] = [path],
	[value] =
		CASE
			WHEN [type] = 1 AND ISDATE([value]) = 1 AND ISNUMERIC([value]) = 0 THEN '2020-01-01T12:34:56.789Z'
			WHEN [type] = 2 THEN '***NUMBER***'
			WHEN [type] = 3 THEN '***BOOLEAN***'
			ELSE 'abcdefghijklmnopqrstuvwxyz'
		END
INTO #JSON
FROM CTE WHERE [type] < 4
ORDER BY [key]


DECLARE @cols NVARCHAR(MAX), @query NVARCHAR(MAX)

SET @cols = STUFF((SELECT DISTINCT ',' + QUOTENAME([key]) FROM #JSON FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 1, '')

SET @query = 'SELECT @outputjson = (
	SELECT
		' + @cols + '
	FROM
		(SELECT * FROM #JSON) X
		PIVOT (MAX([value]) FOR [key] IN ('+ @cols +')) P
	FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
)'

DECLARE @outputjson NVARCHAR(MAX)

EXECUTE sp_executesql @query, N'@outputjson NVARCHAR(MAX) OUTPUT', @outputjson = @outputjson OUTPUT

SET @outputjson = REPLACE(REPLACE(@outputjson, '"***NUMBER***"', '1234567890'), '"***BOOLEAN***"', 'true')
SET @outputjson = REPLACE(REPLACE(@outputjson, '{', '[{'), '}', '}]')

SELECT @outputjson AS [outputjson]

END
GO
