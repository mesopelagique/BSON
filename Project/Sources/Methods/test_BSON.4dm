//%attributes = {}
// Test method for BSON encoder/decoder

// Test 1: Simple object
var $original:={\
name: "John Doe"; \
age: 30; \
active: True:C214; \
score: 95.5; \
tags: ["developer"; "designer"]; \
address: {city: "New York"; zip: "10001"}\
}

var $encoded:=cs:C1710.BSON.me.encode($original)
var $decoded:=cs:C1710.BSON.me.decode($encoded)

ASSERT:C1129($decoded.name="John Doe"; "String encoding/decoding failed")
ASSERT:C1129($decoded.age=30; "Integer encoding/decoding failed")
ASSERT:C1129($decoded.active=True:C214; "Boolean encoding/decoding failed")
ASSERT:C1129($decoded.score=95.5; "Double encoding/decoding failed")
ASSERT:C1129($decoded.tags.length=2; "Array encoding/decoding failed")
ASSERT:C1129($decoded.address.city="New York"; "Nested object encoding/decoding failed")


// Test 2: ObjectId
var $objectId:=cs:C1710.ObjectId.new("")  // Generate new

ASSERT:C1129(Length:C16($objectId.id)=24; "ObjectId generation failed")

$original:={_id: $objectId}
$encoded:=cs:C1710.BSON.me.encode($original)
$decoded:=cs:C1710.BSON.me.decode($encoded)

ASSERT:C1129($decoded._id.id=$objectId.id; "ObjectId encoding/decoding failed")


// Test 3: Binary data with non-generic subtype (keeps Binary class)
var $testData : Blob
SET BLOB SIZE:C606($testData; 10)
var $i : Integer
For ($i; 0; 9)
	$testData{$i}:=$i
End for

var $binary:=cs:C1710.Binary.new($testData; cs:C1710.BinarySubtype.me.userDefined)
$original:={data: $binary}
$encoded:=cs:C1710.BSON.me.encode($original)
$decoded:=cs:C1710.BSON.me.decode($encoded)

ASSERT:C1129($decoded.data._bsontype="Binary"; "Binary type check failed")
ASSERT:C1129($decoded.data.subtype=cs:C1710.BinarySubtype.me.userDefined; "Binary subtype failed")
ASSERT:C1129(BLOB size:C605($decoded.data.data)=10; "Binary data size failed")

// Test 4: Timestamp
var $timestamp:=cs:C1710.Timestamp.new(1234567890; 1)

$original:={ts: $timestamp}
$encoded:=cs:C1710.BSON.me.encode($original)
$decoded:=cs:C1710.BSON.me.decode($encoded)

ASSERT:C1129($decoded.ts.timestamp=1234567890; "Timestamp encoding/decoding failed")
ASSERT:C1129($decoded.ts.increment=1; "Timestamp increment failed")


// Test 5: Int64 - use string for precise large numbers
var $int64:=cs:C1710.Int64.new("9007199254740993")  // Beyond JS MAX_SAFE_INTEGER

$original:={bigNum: $int64}
$encoded:=cs:C1710.BSON.me.encode($original)
$decoded:=cs:C1710.BSON.me.decode($encoded)

// Check Int64 round-trip via toString()
ASSERT:C1129($decoded.bigNum._bsontype="Int64"; "Int64 type check failed")
ASSERT:C1129($decoded.bigNum.toString()="9007199254740993"; "Int64 encoding/decoding failed")


// Test 6: Null values
$original:={value: Null:C1517}
$encoded:=cs:C1710.BSON.me.encode($original)
$decoded:=cs:C1710.BSON.me.decode($encoded)

ASSERT:C1129($decoded.value=Null:C1517; "Null encoding/decoding failed")


// Test 7: MinKey and MaxKey
var $minKey:=cs:C1710.MinKey.new()
var $maxKey:=cs:C1710.MaxKey.new()

$original:={min: $minKey; max: $maxKey}
$encoded:=cs:C1710.BSON.me.encode($original)
$decoded:=cs:C1710.BSON.me.decode($encoded)

ASSERT:C1129($decoded.min._bsontype="MinKey"; "MinKey encoding/decoding failed")
ASSERT:C1129($decoded.max._bsontype="MaxKey"; "MaxKey encoding/decoding failed")


// Test 8: Regex
var $regex:=cs:C1710.Regex.new("^test.*$"; "im")

$original:={pattern: $regex}
$encoded:=cs:C1710.BSON.me.encode($original)
$decoded:=cs:C1710.BSON.me.decode($encoded)

ASSERT:C1129($decoded.pattern.pattern="^test.*$"; "Regex pattern failed")
ASSERT:C1129($decoded.pattern.flags="im"; "Regex flags failed")


// Test 9: Code
var $code:=cs:C1710.Code.new("function() { return 1; }"; Null:C1517)

$original:={fn: $code}
$encoded:=cs:C1710.BSON.me.encode($original)
$decoded:=cs:C1710.BSON.me.decode($encoded)

ASSERT:C1129($decoded.fn.code="function() { return 1; }"; "Code encoding/decoding failed")


// Test 10: Calculate size
$original:={name: "test"; value: 42}
var $size:=cs:C1710.BSON.me.calculateSize($original)

ASSERT:C1129($size>0; "Calculate size failed")
$encoded:=cs:C1710.BSON.me.encode($original)
var $encodeSize:=BLOB size:C605($encoded)
ASSERT:C1129($size=$encodeSize; "Size calculation mismatch")


// Test 11: Decimal128
var $dec:=cs:C1710.Decimal128.new("123.456789012345678901234567890123")

$original:={price: $dec}
$encoded:=cs:C1710.BSON.me.encode($original)
$decoded:=cs:C1710.BSON.me.decode($encoded)

ASSERT:C1129($decoded.price._bsontype="Decimal128"; "Decimal128 type check failed")


// Test 12: Negative Int64
var $negInt64:=cs:C1710.Int64.new("-9223372036854775808")  // Min Int64

$original:={minInt: $negInt64}
$encoded:=cs:C1710.BSON.me.encode($original)
$decoded:=cs:C1710.BSON.me.decode($encoded)

ASSERT:C1129($decoded.minInt._bsontype="Int64"; "Negative Int64 type check failed")
ASSERT:C1129($decoded.minInt.toString()="-9223372036854775808"; "Negative Int64 encoding/decoding failed")


// Test 13: Native 4D Blob round-trip (Blob -> BSON Binary -> 4D.Blob)
var $nativeBlob : Blob
SET BLOB SIZE:C606($nativeBlob; 5)
$nativeBlob{0}:=0x0048  // H
$nativeBlob{1}:=0x0065  // e
$nativeBlob{2}:=0x006C  // l
$nativeBlob{3}:=0x006C  // l
$nativeBlob{4}:=0x006F  // o

$original:={rawData: $nativeBlob}
$encoded:=cs:C1710.BSON.me.encode($original)
$decoded:=cs:C1710.BSON.me.decode($encoded)

// Generic binary (subtype 0) decodes back to 4D.Blob
ASSERT:C1129(OB Instance of:C1731($decoded.rawData; 4D:C1709.Blob); "Generic binary should decode as 4D.Blob")
ASSERT:C1129(BLOB size:C605($decoded.rawData)=5; "4D.Blob size mismatch")
ASSERT:C1129($decoded.rawData[0]=0x0048; "4D.Blob content mismatch")


ALERT:C41("All BSON tests passed!")
