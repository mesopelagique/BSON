# BSON Encoder/Decoder for 4D

A complete BSON (Binary JSON) encoder/decoder implementation for 4D.

## Usage

The `BSON` class is a singleton. Access it via `cs.bson.BSON.me`.

### Encoding Objects to BSON

```4d
var $data:={name: "John"; age: 30; active: True}
var $encoded: Blob:=cs.bson.BSON.me.encode($data)
```

### Decoding BSON to Objects

```4d
var $decoded:=cs.bson.BSON.me.decode($encoded)
// $decoded.name = "John"
// $decoded.age = 30
```

### Calculate Document Size

```4d
var $size:=cs.bson.BSON.me.calculateSize($data)
```

## Supported Types

| 4D Type | BSON Type |
|---------|-----------|
| Text | String |
| Integer/Real | Int32/Double |
| Boolean | Boolean |
| Date | Date (UTC datetime) |
| Null | Null |
| Object | Document |
| Collection | Array |
| Blob | Binary |

## Special BSON Types

### ObjectId

12-byte unique identifier for documents.

```4d
// Generate new ObjectId
var $oid:=cs.bson.ObjectId.new("")

// Use existing ObjectId
var $oid2:=cs.bson.ObjectId.new("507f1f77bcf86cd799439011")

// Get timestamp and date
var $timestamp:=$oid.getTimestamp()
var $date:=$oid.getDate()

// Use in document
var $encoded:=cs.bson.BSON.me.encode({_id: $oid; name: "Document"})
```

### Binary

Binary data with subtype.

```4d
var $data : Blob

// Create binary with generic subtype (0) or UUID subtype (4)
var $bin:=cs.bson.Binary.new($data; 0)

// Get as Base64
var $b64:=$bin.toBase64()
```

Binary subtypes: 0=Generic, 4=UUID, 5=MD5, 6=Encrypted

### Timestamp

Internal timestamp (for replication).

```4d
// Create with timestamp and increment
var $ts:=cs.bson.Timestamp.new(1234567890; 1)

// Access values
var $time:=$ts.timestamp
var $inc:=$ts.increment
```

### Int64

64-bit signed integer.

```4d
var $big:=cs.bson.Int64.new(9007199254740993)

// Arithmetic
var $sum:=$big.add(cs.bson.Int64.new(100))
```

### Double

Explicit double wrapper.

```4d
var $dbl:=cs.bson.Double.new(3.14159)
```

### Regex

Regular expression pattern.

```4d
var $regex:=cs.bson.Regex.new("^test.*$"; "im")

// Access pattern and flags
var $pattern:=$regex.pattern
var $flags:=$regex.flags
```

### Code

JavaScript code with optional scope.

```4d
// Without scope
var $code:=cs.bson.Code.new("function() { return 1; }"; Null)

// With scope
var $code2:=cs.bson.Code.new("function() { return x; }"; {x: 42})
```

### MinKey / MaxKey

Special comparison values for queries.

```4d
var $min:=cs.bson.MinKey.new()
var $max:=cs.bson.MaxKey.new()

var $query:={field: {$gte: $min; $lte: $max}}
```

### Decimal128

128-bit decimal floating point.

```4d
var $dec:=cs.bson.Decimal128.new("123.456")
```

## Complete Example

```4d
// Create a complex document
var $doc:={ \
    _id: cs.bson.ObjectId.new(""); \
    name: "Example Document"; \
    count: 42; \
    price: 19.99; \
    active: True; \
    created: Current date; \
    tags: ["binary"; "bson"; "4d"]; \
    metadata: {version: 1; author: "Developer"} \
}

// Encode to BSON
var $encoded:=cs.bson.BSON.me.encode($doc)

// Decode back to object
var $decoded:=cs.bson.BSON.me.decode($encoded)

// Verify
ASSERT($decoded.name=$doc.name)
ASSERT($decoded.count=$doc.count)
ASSERT($decoded.tags.length=3)
```
