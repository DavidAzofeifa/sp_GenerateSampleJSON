# sp_GenerateSampleJSON
This T-SQL stored procedure takes a JSON document and generates a minimal sample that preserves the schema of the original file. The resulting file can be used as a template when developing Azure Data Factory pipelines, to ensure the data types are detected properly by ADF. This can also be used when the original JSON file contains sensitive information that cannot be shared with developers.

For example, executing the stored procedure with an inline JSON document:

```TSQL
EXEC sp_GenerateSampleJSON '
{
	"first name": "John",
	"last name": "Smith",
	"birth date": "1990-01-01",
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

returns this sample JSON with dummy values (but respecting the data types):

```JSON
[{
	"address": [{
		"city": "abcdefghijklmnopqrstuvwxyz",
		"postal code": "abcdefghijklmnopqrstuvwxyz",
		"state": "abcdefghijklmnopqrstuvwxyz",
		"street address": "abcdefghijklmnopqrstuvwxyz"
	}],
	"birth date": "2020-01-01T12:34:56.789Z",
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

The stored procedure currently encloses objects `{ }` within an array `[ ]`.
