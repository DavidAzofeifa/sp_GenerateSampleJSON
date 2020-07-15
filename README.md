# sp_GenerateSampleJSON
This T-SQL stored procedure takes a JSON document and generates a minimal sample that preserves the schema of the original file. The resulting file can be used when developing Azure Data Factory pipelines, to ensure the data types are detected properly. This can also be used when the original JSON file contains sensitive information that cannot be shared with developers.
