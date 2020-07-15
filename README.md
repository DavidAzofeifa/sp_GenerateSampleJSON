# sp_GenerateSampleJSON
This T-SQL stored procedure takes a JSON document and generates a minimal sample that preserves the schema of the original file. The resulting file can be used as a template when developing Azure Data Factory pipelines, to ensure the data types are detected properly by ADF. This can also be used when the original JSON file contains sensitive information that cannot be shared with developers.

For example, executing the stored procedure:

```sql
EXEC sp_GenerateSampleJSON '
{
	"first name": "John",
	"last name": "Smith",
	"age": 25,
	"address": {
		"street address": "21 2nd Street",
		"city": "New York",
		"state": "NY",
		"postal code": "10021"
	},
	"phone numbers": [{
			"type": "home",
			"number": "212 555-1234"
		},
		{
			"type": "fax",
			"number": "646 555-4567"
		}
	],
	"sex": {
		"type": "male"
	}
}
'
```

Returns this sample JSON:

```json
[{
	"address": [{
		"city": "abcdefghijklmnopqrstuvwxyz",
		"postal code": "abcdefghijklmnopqrstuvwxyz",
		"state": "abcdefghijklmnopqrstuvwxyz",
		"street address": "abcdefghijklmnopqrstuvwxyz"
	}],
	"age": 1234567890,
	"first name": "abcdefghijklmnopqrstuvwxyz",
	"last name": "abcdefghijklmnopqrstuvwxyz",
	"phone numbers": [{
		"number": "abcdefghijklmnopqrstuvwxyz",
		"type": "abcdefghijklmnopqrstuvwxyz"
	}],
	"sex": [{
		"type": "abcdefghijklmnopqrstuvwxyz"
	}]
}]
```
