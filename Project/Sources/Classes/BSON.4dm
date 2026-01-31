// BSON Encoder/Decoder for 4D
// Implements the BSON specification for Object serialization
// Reference: https://bsonspec.org/spec.html

//  Type Constants
property _TYPE_DOUBLE : Integer
property _TYPE_STRING : Integer
property _TYPE_OBJECT : Integer
property _TYPE_ARRAY : Integer
property _TYPE_BINARY : Integer
property _TYPE_UNDEFINED : Integer
property _TYPE_OBJECTID : Integer
property _TYPE_BOOLEAN : Integer
property _TYPE_DATE : Integer
property _TYPE_NULL : Integer
property _TYPE_REGEX : Integer
property _TYPE_DBPOINTER : Integer
property _TYPE_CODE : Integer
property _TYPE_SYMBOL : Integer
property _TYPE_CODE_WITH_SCOPE : Integer
property _TYPE_INT32 : Integer
property _TYPE_TIMESTAMP : Integer
property _TYPE_INT64 : Integer
property _TYPE_DECIMAL128 : Integer
property _TYPE_MINKEY : Integer
property _TYPE_MAXKEY : Integer

// Binary subtypes
property _BINARY_GENERIC : Integer
property _BINARY_FUNCTION : Integer
property _BINARY_OLD : Integer
property _BINARY_UUID_OLD : Integer
property _BINARY_UUID : Integer
property _BINARY_MD5 : Integer
property _BINARY_ENCRYPTED : Integer
property _BINARY_COLUMN : Integer
property _BINARY_SENSITIVE : Integer
property _BINARY_VECTOR : Integer
property _BINARY_USER_DEFINED : Integer


singleton Class constructor()
	//  Type Constants
	This:C1470._TYPE_DOUBLE:=0x0001
	This:C1470._TYPE_STRING:=0x0002
	This:C1470._TYPE_OBJECT:=0x0003
	This:C1470._TYPE_ARRAY:=0x0004
	This:C1470._TYPE_BINARY:=0x0005
	This:C1470._TYPE_UNDEFINED:=0x0006  // Deprecated
	This:C1470._TYPE_OBJECTID:=0x0007
	This:C1470._TYPE_BOOLEAN:=0x0008
	This:C1470._TYPE_DATE:=0x0009
	This:C1470._TYPE_NULL:=0x000A
	This:C1470._TYPE_REGEX:=0x000B
	This:C1470._TYPE_DBPOINTER:=0x000C  // Deprecated
	This:C1470._TYPE_CODE:=0x000D
	This:C1470._TYPE_SYMBOL:=0x000E  // Deprecated
	This:C1470._TYPE_CODE_WITH_SCOPE:=0x000F
	This:C1470._TYPE_INT32:=0x0010
	This:C1470._TYPE_TIMESTAMP:=0x0011
	This:C1470._TYPE_INT64:=0x0012
	This:C1470._TYPE_DECIMAL128:=0x0013
	This:C1470._TYPE_MINKEY:=0x00FF
	This:C1470._TYPE_MAXKEY:=0x007F
	
	// Binary subtypes
	This:C1470._BINARY_GENERIC:=0x0000
	This:C1470._BINARY_FUNCTION:=0x0001
	This:C1470._BINARY_OLD:=0x0002  // Deprecated
	This:C1470._BINARY_UUID_OLD:=0x0003  // Deprecated
	This:C1470._BINARY_UUID:=0x0004
	This:C1470._BINARY_MD5:=0x0005
	This:C1470._BINARY_ENCRYPTED:=0x0006
	This:C1470._BINARY_COLUMN:=0x0007
	This:C1470._BINARY_SENSITIVE:=0x0008
	This:C1470._BINARY_VECTOR:=0x0009
	This:C1470._BINARY_USER_DEFINED:=0x0080
	
	
	// ============================================================================
	// PUBLIC API
	// ============================================================================
	
	// Encode an object to BSON bytes
Function encode($object : Object) : Blob
	var $buffer : Blob
	SET BLOB SIZE:C606($buffer; 0)
	This:C1470._encodeDocument($object; ->$buffer)
	return $buffer
	
	
	// Decode BSON bytes to an object
Function decode($bytes : Blob) : Object
	var $ctx : Object:={offset: 0}
	return This:C1470._decodeDocument($bytes; $ctx)
	
	
	// Calculate the size of an object when encoded as BSON
Function calculateSize($object : Object) : Integer
	return This:C1470._calculateDocumentSize($object)
	
	
	// ============================================================================
	// ENCODING METHODS
	// ============================================================================
	
Function _encodeDocument($object : Object; $buffer : Pointer)
	var $startPos : Integer
	var $docSize : Integer
	var $key : Text
	var $value : Variant
	
	// Reserve 4 bytes for document size
	$startPos:=BLOB size:C605($buffer->)
	This:C1470._writeInt32(0; $buffer)
	
	// Encode each key-value pair
	For each ($key; $object)
		$value:=$object[$key]
		This:C1470._encodeElement($key; $value; $buffer)
	End for each 
	
	// Write EOO (End Of Object) marker
	This:C1470._writeByte(0x0000; $buffer)
	
	// Update document size at the beginning
	$docSize:=BLOB size:C605($buffer->)-$startPos
	This:C1470._writeInt32At($docSize; $buffer; $startPos)
	
	
Function _encodeElement($key : Text; $value : Variant; $buffer : Pointer)
	var $valueType : Integer
	$valueType:=Value type:C1509($value)
	
	Case of 
		: ($valueType=Is null:K8:31)
			This:C1470._writeByte(This:C1470._TYPE_NULL; $buffer)
			This:C1470._writeCString($key; $buffer)
			
		: ($valueType=Is boolean:K8:9)
			This:C1470._writeByte(This:C1470._TYPE_BOOLEAN; $buffer)
			This:C1470._writeCString($key; $buffer)
			This:C1470._writeByte(Bool:C1537($value) ? 0x0001 : 0x0000; $buffer)
			
		: ($valueType=Is real:K8:4)
			// Check if it's an integer that fits in Int32
			If (($value=Round:C94($value; 0)) & ($value>=-2147483648) & ($value<=2147483647))
				This:C1470._writeByte(This:C1470._TYPE_INT32; $buffer)
				This:C1470._writeCString($key; $buffer)
				This:C1470._writeInt32(Num:C11($value); $buffer)
			Else 
				// Use double for floating point or large integers
				This:C1470._writeByte(This:C1470._TYPE_DOUBLE; $buffer)
				This:C1470._writeCString($key; $buffer)
				This:C1470._writeDouble($value; $buffer)
			End if 
			
		: ($valueType=Is longint:K8:6)
			This:C1470._writeByte(This:C1470._TYPE_INT32; $buffer)
			This:C1470._writeCString($key; $buffer)
			This:C1470._writeInt32(Num:C11($value); $buffer)
			
		: ($valueType=Is integer:K8:5)
			This:C1470._writeByte(This:C1470._TYPE_INT32; $buffer)
			This:C1470._writeCString($key; $buffer)
			This:C1470._writeInt32(Num:C11($value); $buffer)
			
		: ($valueType=Is text:K8:3)
			This:C1470._writeByte(This:C1470._TYPE_STRING; $buffer)
			This:C1470._writeCString($key; $buffer)
			This:C1470._writeString(String:C10($value); $buffer)
			
		: ($valueType=Is date:K8:7)
			This:C1470._writeByte(This:C1470._TYPE_DATE; $buffer)
			This:C1470._writeCString($key; $buffer)
			This:C1470._writeDate(Date:C102($value); $buffer)
			
		: ($valueType=Is time:K8:8)
			// Convert time to milliseconds and store as Int64
			This:C1470._writeByte(This:C1470._TYPE_INT64; $buffer)
			This:C1470._writeCString($key; $buffer)
			This:C1470._writeInt64(Time:C179($value)*1000; $buffer)
			
		: ($valueType=Is object:K8:27)
			// Check for 4D.Blob first (Blob stored in Object becomes 4D.Blob)
			If (OB Instance of:C1731($value; 4D:C1709.Blob))
				This:C1470._writeByte(This:C1470._TYPE_BINARY; $buffer)
				This:C1470._writeCString($key; $buffer)
				This:C1470._writeBinary($value; This:C1470._BINARY_GENERIC; $buffer)
			Else
				If (This:C1470._isSpecialType($value))
					This:C1470._encodeSpecialType($key; $value; $buffer)
				Else
					This:C1470._writeByte(This:C1470._TYPE_OBJECT; $buffer)
					This:C1470._writeCString($key; $buffer)
					This:C1470._encodeDocument($value; $buffer)
				End if
			End if
			
		: ($valueType=Is collection:K8:32)
			This:C1470._writeByte(This:C1470._TYPE_ARRAY; $buffer)
			This:C1470._writeCString($key; $buffer)
			This:C1470._encodeArray($value; $buffer)
			
		: ($valueType=Is BLOB:K8:12)
			This:C1470._writeByte(This:C1470._TYPE_BINARY; $buffer)
			This:C1470._writeCString($key; $buffer)
			This:C1470._writeBinary($value; This:C1470._BINARY_GENERIC; $buffer)
			
		Else 
			// Unsupported type - encode as null
			This:C1470._writeByte(This:C1470._TYPE_NULL; $buffer)
			This:C1470._writeCString($key; $buffer)
	End case 
	
	
Function _encodeArray($array : Collection; $buffer : Pointer)
	var $startPos : Integer
	var $docSize : Integer
	var $i : Integer
	var $value : Variant
	
	// Reserve 4 bytes for document size
	$startPos:=BLOB size:C605($buffer->)
	This:C1470._writeInt32(0; $buffer)
	
	// Arrays are encoded as documents with string indices
	For ($i; 0; $array.length-1)
		$value:=$array[$i]
		This:C1470._encodeElement(String:C10($i); $value; $buffer)
	End for 
	
	// Write EOO marker
	This:C1470._writeByte(0x0000; $buffer)
	
	// Update document size
	$docSize:=BLOB size:C605($buffer->)-$startPos
	This:C1470._writeInt32At($docSize; $buffer; $startPos)
	
	
Function _encodeSpecialType($key : Text; $value : Object; $buffer : Pointer)
	var $bsonType : Text
	$bsonType:=String:C10($value._bsontype)
	
	Case of 
		: ($bsonType="ObjectId")
			This:C1470._writeByte(This:C1470._TYPE_OBJECTID; $buffer)
			This:C1470._writeCString($key; $buffer)
			This:C1470._writeObjectId($value; $buffer)
			
		: ($bsonType="Binary")
			This:C1470._writeByte(This:C1470._TYPE_BINARY; $buffer)
			This:C1470._writeCString($key; $buffer)
			This:C1470._writeBinary($value.data; Num:C11($value.subtype); $buffer)
			
		: ($bsonType="Timestamp")
			This:C1470._writeByte(This:C1470._TYPE_TIMESTAMP; $buffer)
			This:C1470._writeCString($key; $buffer)
			This:C1470._writeUInt32(Num:C11($value.increment); $buffer)
			This:C1470._writeUInt32(Num:C11($value.timestamp); $buffer)
			
		: ($bsonType="Int64")
			This:C1470._writeByte(This:C1470._TYPE_INT64; $buffer)
			This:C1470._writeCString($key; $buffer)
			This:C1470._writeInt64FromParts($value.low; $value.high; $buffer)
			
		: ($bsonType="Double")
			This:C1470._writeByte(This:C1470._TYPE_DOUBLE; $buffer)
			This:C1470._writeCString($key; $buffer)
			This:C1470._writeDouble(Num:C11($value.value); $buffer)
			
		: ($bsonType="Decimal128")
			This:C1470._writeByte(This:C1470._TYPE_DECIMAL128; $buffer)
			This:C1470._writeCString($key; $buffer)
			This:C1470._writeDecimal128($value; $buffer)
			
		: ($bsonType="MinKey")
			This:C1470._writeByte(This:C1470._TYPE_MINKEY; $buffer)
			This:C1470._writeCString($key; $buffer)
			
		: ($bsonType="MaxKey")
			This:C1470._writeByte(This:C1470._TYPE_MAXKEY; $buffer)
			This:C1470._writeCString($key; $buffer)
			
		: ($bsonType="Code")
			If ($value.scope#Null:C1517)
				This:C1470._writeByte(This:C1470._TYPE_CODE_WITH_SCOPE; $buffer)
				This:C1470._writeCString($key; $buffer)
				This:C1470._writeCodeWithScope($value; $buffer)
			Else 
				This:C1470._writeByte(This:C1470._TYPE_CODE; $buffer)
				This:C1470._writeCString($key; $buffer)
				This:C1470._writeString(String:C10($value.code); $buffer)
			End if 
			
		: ($bsonType="Regex")
			This:C1470._writeByte(This:C1470._TYPE_REGEX; $buffer)
			This:C1470._writeCString($key; $buffer)
			This:C1470._writeCString(String:C10($value.pattern); $buffer)
			This:C1470._writeCString(String:C10($value.flags); $buffer)
			
		Else 
			// Unknown special type - encode as regular object
			This:C1470._writeByte(This:C1470._TYPE_OBJECT; $buffer)
			This:C1470._writeCString($key; $buffer)
			This:C1470._encodeDocument($value; $buffer)
	End case 
	
	
Function _isSpecialType($value : Object) : Boolean
	return OB Is defined:C1231($value; "_bsontype")
	
	
	// ============================================================================
	// DECODING METHODS
	// ============================================================================
	
Function _decodeDocument($buffer : Blob; $ctx : Object) : Object
	var $result : Object:={}
	var $docSize : Integer
	var $endPos : Integer
	var $elementType : Integer
	var $key : Text
	var $value : Variant
	
	// Read document size
	$docSize:=This:C1470._readInt32($buffer; $ctx)
	$endPos:=$ctx.offset+$docSize-4  // -4 because we already read the size
	
	// Read elements until EOO marker
	While ($ctx.offset<($endPos-1))
		$elementType:=This:C1470._readByte($buffer; $ctx)
		
		If ($elementType=0x0000)
			// EOO marker
			return $result
		End if 
		
		$key:=This:C1470._readCString($buffer; $ctx)
		$value:=This:C1470._decodeValue($elementType; $buffer; $ctx)
		
		$result[$key]:=$value
	End while 
	
	// Skip final EOO byte
	$ctx.offset:=$ctx.offset+1
	
	return $result
	
	
Function _decodeValue($elementType : Integer; $buffer : Blob; $ctx : Object) : Variant
	var $value : Variant
	
	Case of 
		: ($elementType=This:C1470._TYPE_DOUBLE)
			$value:=This:C1470._readDouble($buffer; $ctx)
			
		: ($elementType=This:C1470._TYPE_STRING)
			$value:=This:C1470._readString($buffer; $ctx)
			
		: ($elementType=This:C1470._TYPE_OBJECT)
			$value:=This:C1470._decodeDocument($buffer; $ctx)
			
		: ($elementType=This:C1470._TYPE_ARRAY)
			$value:=This:C1470._decodeArray($buffer; $ctx)
			
		: ($elementType=This:C1470._TYPE_BINARY)
			$value:=This:C1470._readBinary($buffer; $ctx)
			
		: ($elementType=This:C1470._TYPE_UNDEFINED)
			$value:=Null:C1517
			
		: ($elementType=This:C1470._TYPE_OBJECTID)
			$value:=This:C1470._readObjectId($buffer; $ctx)
			
		: ($elementType=This:C1470._TYPE_BOOLEAN)
			$value:=(This:C1470._readByte($buffer; $ctx)#0x0000)
			
		: ($elementType=This:C1470._TYPE_DATE)
			$value:=This:C1470._readDate($buffer; $ctx)
			
		: ($elementType=This:C1470._TYPE_NULL)
			$value:=Null:C1517
			
		: ($elementType=This:C1470._TYPE_REGEX)
			$value:=This:C1470._readRegex($buffer; $ctx)
			
		: ($elementType=This:C1470._TYPE_DBPOINTER)
			// Deprecated - but still read
			$value:=This:C1470._readDBPointer($buffer; $ctx)
			
		: ($elementType=This:C1470._TYPE_CODE)
			$value:=This:C1470._readCode($buffer; $ctx)
			
		: ($elementType=This:C1470._TYPE_SYMBOL)
			// Deprecated - read as string
			$value:=This:C1470._readString($buffer; $ctx)
			
		: ($elementType=This:C1470._TYPE_CODE_WITH_SCOPE)
			$value:=This:C1470._readCodeWithScope($buffer; $ctx)
			
		: ($elementType=This:C1470._TYPE_INT32)
			$value:=This:C1470._readInt32($buffer; $ctx)
			
		: ($elementType=This:C1470._TYPE_TIMESTAMP)
			$value:=This:C1470._readTimestamp($buffer; $ctx)
			
		: ($elementType=This:C1470._TYPE_INT64)
			$value:=This:C1470._readInt64($buffer; $ctx)
			
		: ($elementType=This:C1470._TYPE_DECIMAL128)
			$value:=This:C1470._readDecimal128($buffer; $ctx)
			
		: ($elementType=This:C1470._TYPE_MINKEY)
			$value:={_bsontype: "MinKey"}
			
		: ($elementType=This:C1470._TYPE_MAXKEY)
			$value:={_bsontype: "MaxKey"}
			
		Else 
			// Unknown type
			$value:=Null:C1517
	End case 
	
	return $value
	
	
Function _decodeArray($buffer : Blob; $ctx : Object) : Collection
	var $result : Collection:=[]
	var $docSize : Integer
	var $endPos : Integer
	var $elementType : Integer
	var $key : Text
	var $value : Variant
	
	// Read document size
	$docSize:=This:C1470._readInt32($buffer; $ctx)
	$endPos:=$ctx.offset+$docSize-4
	
	// Read elements until EOO marker
	While ($ctx.offset<($endPos-1))
		$elementType:=This:C1470._readByte($buffer; $ctx)
		
		If ($elementType=0x0000)
			return $result
		End if 
		
		$key:=This:C1470._readCString($buffer; $ctx)  // Index as string (ignored)
		$value:=This:C1470._decodeValue($elementType; $buffer; $ctx)
		
		$result.push($value)
	End while 
	
	// Skip final EOO byte
	$ctx.offset:=$ctx.offset+1
	
	return $result
	
	
	// ============================================================================
	// SIZE CALCULATION
	// ============================================================================
	
Function _calculateDocumentSize($object : Object) : Integer
	var $size : Integer
	var $key : Text
	var $value : Variant
	
	// 4 bytes for size + 1 byte for EOO
	$size:=5
	
	For each ($key; $object)
		$value:=$object[$key]
		$size:=$size+This:C1470._calculateElementSize($key; $value)
	End for each 
	
	return $size
	
	
Function _calculateElementSize($key : Text; $value : Variant) : Integer
	var $size : Integer
	var $valueType : Integer
	var $utf8Bytes : Blob
	
	// Convert key to UTF-8 to get actual byte length
	CONVERT FROM TEXT:C1011($key; "UTF-8"; $utf8Bytes)
	
	// 1 byte for type + key byte length + 1 byte for null terminator
	$size:=1+BLOB size:C605($utf8Bytes)+1
	
	$valueType:=Value type:C1509($value)
	
	Case of 
		: ($valueType=Is null:K8:31)
			// No additional bytes
			
		: ($valueType=Is boolean:K8:9)
			$size:=$size+1
			
		: ($valueType=Is real:K8:4)
			If (($value=Round:C94($value; 0)) & ($value>=-2147483648) & ($value<=2147483647))
				$size:=$size+4  // Int32
			Else 
				$size:=$size+8  // Double
			End if 
			
		: ($valueType=Is longint:K8:6)
			$size:=$size+4
			
		: ($valueType=Is integer:K8:5)
			$size:=$size+4
			
		: ($valueType=Is text:K8:3)
			// 4 bytes for length + string bytes + 1 for null
			CONVERT FROM TEXT:C1011(String:C10($value); "UTF-8"; $utf8Bytes)
			$size:=$size+4+BLOB size:C605($utf8Bytes)+1
			
		: ($valueType=Is date:K8:7)
			$size:=$size+8  // Int64 milliseconds
			
		: ($valueType=Is time:K8:8)
			$size:=$size+8  // Int64
			
		: ($valueType=Is object:K8:27)
			// Check for 4D.Blob first
			If (OB Instance of:C1731($value; 4D:C1709.Blob))
				// 4 bytes for size + 1 byte subtype + blob size
				$size:=$size+5+BLOB size:C605($value)
			Else
				If (This:C1470._isSpecialType($value))
					$size:=$size+This:C1470._calculateSpecialTypeSize($value)
				Else
					$size:=$size+This:C1470._calculateDocumentSize($value)
				End if
			End if
			
		: ($valueType=Is collection:K8:32)
			$size:=$size+This:C1470._calculateArraySize($value)
			
		: ($valueType=Is BLOB:K8:12)
			// 4 bytes for size + 1 byte subtype + blob size
			$size:=$size+5+BLOB size:C605($value)
			
	End case 
	
	return $size
	
	
Function _calculateArraySize($array : Collection) : Integer
	var $size : Integer
	var $i : Integer
	var $value : Variant
	
	// 4 bytes for size + 1 byte for EOO
	$size:=5
	
	For ($i; 0; $array.length-1)
		$value:=$array[$i]
		$size:=$size+This:C1470._calculateElementSize(String:C10($i); $value)
	End for 
	
	return $size
	
	
Function _calculateSpecialTypeSize($value : Object) : Integer
	var $size : Integer
	var $bsonType : Text
	var $utf8Bytes : Blob
	
	$bsonType:=String:C10($value._bsontype)
	
	Case of 
		: ($bsonType="ObjectId")
			$size:=12
			
		: ($bsonType="Binary")
			$size:=5+BLOB size:C605($value.data)
			
		: ($bsonType="Timestamp")
			$size:=8
			
		: ($bsonType="Int64")
			$size:=8
			
		: ($bsonType="Double")
			$size:=8
			
		: ($bsonType="Decimal128")
			$size:=16
			
		: ($bsonType="MinKey")
			$size:=0
			
		: ($bsonType="MaxKey")
			$size:=0
			
		: ($bsonType="Code")
			If ($value.scope#Null:C1517)
				// 4 bytes total size + string + scope document
				CONVERT FROM TEXT:C1011(String:C10($value.code); "UTF-8"; $utf8Bytes)
				$size:=4+4+BLOB size:C605($utf8Bytes)+1+This:C1470._calculateDocumentSize($value.scope)
			Else 
				CONVERT FROM TEXT:C1011(String:C10($value.code); "UTF-8"; $utf8Bytes)
				$size:=4+BLOB size:C605($utf8Bytes)+1
			End if 
			
		: ($bsonType="Regex")
			CONVERT FROM TEXT:C1011(String:C10($value.pattern); "UTF-8"; $utf8Bytes)
			$size:=BLOB size:C605($utf8Bytes)+1
			CONVERT FROM TEXT:C1011(String:C10($value.flags); "UTF-8"; $utf8Bytes)
			$size:=$size+BLOB size:C605($utf8Bytes)+1
			
		Else 
			$size:=This:C1470._calculateDocumentSize($value)
	End case 
	
	return $size
	
	
	// ============================================================================
	// LOW-LEVEL WRITE METHODS
	// ============================================================================
	
Function _writeByte($byte : Integer; $buffer : Pointer)
	var $pos : Integer
	$pos:=BLOB size:C605($buffer->)
	SET BLOB SIZE:C606($buffer->; $pos+1)
	$buffer->{$pos}:=$byte
	
	
Function _writeInt32($value : Integer; $buffer : Pointer)
	var $pos : Integer
	$pos:=BLOB size:C605($buffer->)
	SET BLOB SIZE:C606($buffer->; $pos+4)
	
	// Little-endian
	$buffer->{$pos}:=$value & 0x00FF
	$buffer->{$pos+1}:=($value >> 8) & 0x00FF
	$buffer->{$pos+2}:=($value >> 16) & 0x00FF
	$buffer->{$pos+3}:=($value >> 24) & 0x00FF
	
	
Function _writeInt32At($value : Integer; $buffer : Pointer; $pos : Integer)
	// Little-endian
	$buffer->{$pos}:=$value & 0x00FF
	$buffer->{$pos+1}:=($value >> 8) & 0x00FF
	$buffer->{$pos+2}:=($value >> 16) & 0x00FF
	$buffer->{$pos+3}:=($value >> 24) & 0x00FF
	
	
Function _writeUInt32($value : Real; $buffer : Pointer)
	var $pos : Integer
	var $intVal : Integer
	$pos:=BLOB size:C605($buffer->)
	SET BLOB SIZE:C606($buffer->; $pos+4)
	$intVal:=Num:C11($value)
	
	// Little-endian
	$buffer->{$pos}:=$intVal & 0x00FF
	$buffer->{$pos+1}:=($intVal >> 8) & 0x00FF
	$buffer->{$pos+2}:=($intVal >> 16) & 0x00FF
	$buffer->{$pos+3}:=($intVal >> 24) & 0x00FF
	
	
Function _writeInt64($value : Real; $buffer : Pointer)
	var $pos : Integer
	var $low : Real
	var $high : Real
	var $lowInt : Integer
	var $highInt : Integer
	
	$pos:=BLOB size:C605($buffer->)
	SET BLOB SIZE:C606($buffer->; $pos+8)
	
	// Split into low and high 32-bit parts
	$low:=Mod:C98($value; 4294967296)  // 2^32
	If ($low<0)
		$low:=$low+4294967296
	End if 
	$high:=Int:C8(($value-$low)/4294967296)
	
	$lowInt:=Num:C11($low)
	$highInt:=Num:C11($high)
	
	// Write low part (little-endian)
	$buffer->{$pos}:=$lowInt & 0x00FF
	$buffer->{$pos+1}:=($lowInt >> 8) & 0x00FF
	$buffer->{$pos+2}:=($lowInt >> 16) & 0x00FF
	$buffer->{$pos+3}:=($lowInt >> 24) & 0x00FF
	
	// Write high part (little-endian)
	$buffer->{$pos+4}:=$highInt & 0x00FF
	$buffer->{$pos+5}:=($highInt >> 8) & 0x00FF
	$buffer->{$pos+6}:=($highInt >> 16) & 0x00FF
	$buffer->{$pos+7}:=($highInt >> 24) & 0x00FF
	
	
Function _writeInt64FromParts($low : Integer; $high : Integer; $buffer : Pointer)
	var $pos : Integer

	$pos:=BLOB size:C605($buffer->)
	SET BLOB SIZE:C606($buffer->; $pos+8)

	// Write low part (little-endian)
	$buffer->{$pos}:=$low & 0x00FF
	$buffer->{$pos+1}:=($low >> 8) & 0x00FF
	$buffer->{$pos+2}:=($low >> 16) & 0x00FF
	$buffer->{$pos+3}:=($low >> 24) & 0x00FF

	// Write high part (little-endian)
	$buffer->{$pos+4}:=$high & 0x00FF
	$buffer->{$pos+5}:=($high >> 8) & 0x00FF
	$buffer->{$pos+6}:=($high >> 16) & 0x00FF
	$buffer->{$pos+7}:=($high >> 24) & 0x00FF


Function _writeDouble($value : Real; $buffer : Pointer)
	var $pos : Integer
	var $tempBlob : Blob
	
	$pos:=BLOB size:C605($buffer->)
	SET BLOB SIZE:C606($buffer->; $pos+8)
	
	// Use 4D's native real to blob conversion (IEEE 754)
	SET BLOB SIZE:C606($tempBlob; 8)
	REAL TO BLOB:C552($value; $tempBlob; PC byte ordering:K22:3)
	
	// Copy bytes
	COPY BLOB:C558($tempBlob; $buffer->; 0; $pos; 8)
	
	
Function _writeCString($str : Text; $buffer : Pointer)
	var $pos : Integer
	var $bytes : Blob
	var $bytesSize : Integer
	
	CONVERT FROM TEXT:C1011($str; "UTF-8"; $bytes)
	$bytesSize:=BLOB size:C605($bytes)
	$pos:=BLOB size:C605($buffer->)
	SET BLOB SIZE:C606($buffer->; $pos+$bytesSize+1)
	
	If ($bytesSize>0)
		COPY BLOB:C558($bytes; $buffer->; 0; $pos; $bytesSize)
	End if 
	$buffer->{$pos+$bytesSize}:=0x0000  // Null terminator
	
	
Function _writeString($str : Text; $buffer : Pointer)
	var $pos : Integer
	var $bytes : Blob
	var $strLen : Integer
	var $bytesSize : Integer
	
	CONVERT FROM TEXT:C1011($str; "UTF-8"; $bytes)
	$bytesSize:=BLOB size:C605($bytes)
	$strLen:=$bytesSize+1  // Include null terminator
	
	// Write length (4 bytes)
	This:C1470._writeInt32($strLen; $buffer)
	
	// Write string bytes
	$pos:=BLOB size:C605($buffer->)
	SET BLOB SIZE:C606($buffer->; $pos+$strLen)
	If ($bytesSize>0)
		COPY BLOB:C558($bytes; $buffer->; 0; $pos; $bytesSize)
	End if 
	$buffer->{$pos+$bytesSize}:=0x0000  // Null terminator
	
	
Function _writeDate($date : Date; $buffer : Pointer)
	var $timestamp : Real
	
	// Convert date to milliseconds since Unix epoch
	$timestamp:=(($date-!1970-01-01!)*86400)*1000
	This:C1470._writeInt64($timestamp; $buffer)
	
	
Function _writeBinary($data : Blob; $subtype : Integer; $buffer : Pointer)
	var $pos : Integer
	var $dataSize : Integer
	
	$dataSize:=BLOB size:C605($data)
	
	// Write size
	This:C1470._writeInt32($dataSize; $buffer)
	
	// Write subtype
	This:C1470._writeByte($subtype; $buffer)
	
	// Write data
	If ($dataSize>0)
		$pos:=BLOB size:C605($buffer->)
		SET BLOB SIZE:C606($buffer->; $pos+$dataSize)
		COPY BLOB:C558($data; $buffer->; 0; $pos; $dataSize)
	End if 
	
	
Function _writeObjectId($objectId : Object; $buffer : Pointer)
	var $pos : Integer
	var $hexStr : Text
	var $i : Integer
	var $byte : Integer
	
	$hexStr:=String:C10($objectId.id)
	$pos:=BLOB size:C605($buffer->)
	SET BLOB SIZE:C606($buffer->; $pos+12)
	
	// Convert hex string to 12 bytes
	For ($i; 0; 11)
		$byte:=This:C1470._hexToByte(Substring:C12($hexStr; ($i*2)+1; 2))
		$buffer->{$pos+$i}:=$byte
	End for 
	
	
Function _writeDecimal128($decimal : Object; $buffer : Pointer)
	var $pos : Integer
	var $bytes : Blob
	var $i : Integer
	
	$pos:=BLOB size:C605($buffer->)
	SET BLOB SIZE:C606($buffer->; $pos+16)
	
	// If bytes are provided directly, use them
	If (OB Is defined:C1231($decimal; "bytes"))
		$bytes:=$decimal.bytes
		COPY BLOB:C558($bytes; $buffer->; 0; $pos; 16)
	Else 
		// Zero fill for unsupported decimal values
		For ($i; 0; 15)
			$buffer->{$pos+$i}:=0x0000
		End for 
	End if 
	
	
Function _writeCodeWithScope($code : Object; $buffer : Pointer)
	var $startPos : Integer
	var $totalSize : Integer
	var $scopeBuffer : Blob
	var $scopePos : Integer
	
	// Reserve 4 bytes for total size
	$startPos:=BLOB size:C605($buffer->)
	This:C1470._writeInt32(0; $buffer)
	
	// Write code string
	This:C1470._writeString(String:C10($code.code); $buffer)
	
	// Write scope document
	SET BLOB SIZE:C606($scopeBuffer; 0)
	This:C1470._encodeDocument($code.scope; ->$scopeBuffer)
	
	$scopePos:=BLOB size:C605($buffer->)
	SET BLOB SIZE:C606($buffer->; $scopePos+BLOB size:C605($scopeBuffer))
	COPY BLOB:C558($scopeBuffer; $buffer->; 0; $scopePos; BLOB size:C605($scopeBuffer))
	
	// Update total size
	$totalSize:=BLOB size:C605($buffer->)-$startPos
	This:C1470._writeInt32At($totalSize; $buffer; $startPos)
	
	
	// ============================================================================
	// LOW-LEVEL READ METHODS
	// ============================================================================
	
Function _readByte($buffer : Blob; $ctx : Object) : Integer
	var $byte : Integer:=$buffer{Num:C11($ctx.offset)}
	$ctx.offset:=$ctx.offset+1
	return $byte
	
	
Function _readInt32($buffer : Blob; $ctx : Object) : Integer
	var $value : Integer
	var $offset : Integer
	$offset:=$ctx.offset
	
	// Little-endian
	$value:=$buffer{$offset}
	$value:=$value | ($buffer{$offset+1} << 8)
	$value:=$value | ($buffer{$offset+2} << 16)
	$value:=$value | ($buffer{$offset+3} << 24)
	
	$ctx.offset:=$offset+4
	return $value
	
	
Function _readUInt32($buffer : Blob; $ctx : Object) : Real
	var $value : Real
	var $offset : Integer
	$offset:=$ctx.offset
	
	// Little-endian (use Real for unsigned)
	$value:=$buffer{$offset}
	$value:=$value+($buffer{$offset+1}*256)
	$value:=$value+($buffer{$offset+2}*65536)
	$value:=$value+($buffer{$offset+3}*16777216)
	
	$ctx.offset:=$offset+4
	return $value
	
	
Function _readInt64($buffer : Blob; $ctx : Object) : Object
	var $low : Integer
	var $high : Integer
	var $offset : Integer
	$offset:=$ctx.offset

	// Read low 32 bits (little-endian)
	$low:=$buffer{$offset}
	$low:=$low | ($buffer{$offset+1} << 8)
	$low:=$low | ($buffer{$offset+2} << 16)
	$low:=$low | ($buffer{$offset+3} << 24)

	// Read high 32 bits (little-endian)
	$high:=$buffer{$offset+4}
	$high:=$high | ($buffer{$offset+5} << 8)
	$high:=$high | ($buffer{$offset+6} << 16)
	$high:=$high | ($buffer{$offset+7} << 24)

	$ctx.offset:=$offset+8

	// Return an Int64 object using fromBits
	return cs:C1710.Int64.new().fromBits($low; $high)
	
	
Function _readDouble($buffer : Blob; $ctx : Object) : Real
	var $value : Real
	var $tempBlob : Blob
	
	SET BLOB SIZE:C606($tempBlob; 8)
	COPY BLOB:C558($buffer; $tempBlob; $ctx.offset; 0; 8)
	
	$value:=BLOB to real:C553($tempBlob; PC byte ordering:K22:3)
	$ctx.offset:=$ctx.offset+8
	return $value
	
	
Function _readCString($buffer : Blob; $ctx : Object) : Text
	var $str : Text
	var $startPos : Integer
	var $len : Integer
	var $strBytes : Blob
	
	$startPos:=$ctx.offset
	
	// Find null terminator
	While ($buffer{Num:C11($ctx.offset)}#0x0000)
		$ctx.offset:=$ctx.offset+1
	End while 
	
	$len:=$ctx.offset-$startPos
	
	If ($len>0)
		SET BLOB SIZE:C606($strBytes; $len)
		COPY BLOB:C558($buffer; $strBytes; $startPos; 0; $len)
		$str:=Convert to text:C1012($strBytes; "UTF-8")
	Else 
		$str:=""
	End if 
	
	$ctx.offset:=$ctx.offset+1  // Skip null terminator
	return $str
	
	
Function _readString($buffer : Blob; $ctx : Object) : Text
	var $str : Text
	var $strLen : Integer
	var $strBytes : Blob
	
	// Read length
	$strLen:=This:C1470._readInt32($buffer; $ctx)
	
	If ($strLen>1)
		SET BLOB SIZE:C606($strBytes; $strLen-1)  // Exclude null terminator
		COPY BLOB:C558($buffer; $strBytes; $ctx.offset; 0; $strLen-1)
		$str:=Convert to text:C1012($strBytes; "UTF-8")
	Else 
		$str:=""
	End if 
	
	$ctx.offset:=$ctx.offset+$strLen
	return $str
	
	
Function _readDate($buffer : Blob; $ctx : Object) : Object
	var $timestamp : Real
	var $result : Object

	$timestamp:=This:C1470._readInt64Raw($buffer; $ctx)

	// Return as BSON Date object with timestamp for precision
	$result:={_bsontype: "Date"; timestamp: $timestamp}
	return $result


Function _readInt64Raw($buffer : Blob; $ctx : Object) : Real
	// Read Int64 as a Real value (for dates, times, etc.)
	var $value : Real
	var $low : Real
	var $high : Real
	var $offset : Integer
	$offset:=$ctx.offset

	// Read low 32 bits
	$low:=$buffer{$offset}
	$low:=$low+($buffer{$offset+1}*256)
	$low:=$low+($buffer{$offset+2}*65536)
	$low:=$low+($buffer{$offset+3}*16777216)

	// Read high 32 bits
	$high:=$buffer{$offset+4}
	$high:=$high+($buffer{$offset+5}*256)
	$high:=$high+($buffer{$offset+6}*65536)
	$high:=$high+($buffer{$offset+7}*16777216)

	// Combine (handle signed)
	If ($high>=2147483648)  // Negative number
		$value:=-(4294967296-$low)-($high-2147483648)*4294967296-2147483648*4294967296
	Else
		$value:=$low+($high*4294967296)
	End if

	$ctx.offset:=$offset+8
	return $value
	
	
Function _readBinary($buffer : Blob; $ctx : Object) : Variant
	var $size : Integer
	var $subtype : Integer
	var $data : Blob

	$size:=This:C1470._readInt32($buffer; $ctx)
	$subtype:=This:C1470._readByte($buffer; $ctx)

	SET BLOB SIZE:C606($data; $size)
	If ($size>0)
		COPY BLOB:C558($buffer; $data; $ctx.offset; 0; $size)
	End if
	$ctx.offset:=$ctx.offset+$size

	// Return raw Blob for generic subtype (becomes 4D.Blob in object)
	// Keep Binary class for other subtypes to preserve subtype info
	If ($subtype=This:C1470._BINARY_GENERIC)
		return $data
	Else
		return {_bsontype: "Binary"; subtype: $subtype; data: $data}
	End if
	
	
Function _readObjectId($buffer : Blob; $ctx : Object) : Object
	var $hexStr : Text
	var $i : Integer
	
	$hexStr:=""
	For ($i; 0; 11)
		$hexStr+=This:C1470._byteToHex($buffer{Num:C11($ctx.offset+$i)})
	End for 
	$ctx.offset:=$ctx.offset+12
	
	return {_bsontype: "ObjectId"; id: $hexStr}
	
	
Function _readRegex($buffer : Blob; $ctx : Object) : Object
	var $pattern : Text
	var $flags : Text
	
	$pattern:=This:C1470._readCString($buffer; $ctx)
	$flags:=This:C1470._readCString($buffer; $ctx)
	
	return {_bsontype: "Regex"; pattern: $pattern; flags: $flags}
	
	
Function _readCode($buffer : Blob; $ctx : Object) : Object
	var $codeStr : Text
	$codeStr:=This:C1470._readString($buffer; $ctx)
	return {_bsontype: "Code"; code: $codeStr}
	
	
Function _readCodeWithScope($buffer : Blob; $ctx : Object) : Object
	var $totalSize : Integer
	var $codeStr : Text
	var $scope : Object
	
	$totalSize:=This:C1470._readInt32($buffer; $ctx)
	$codeStr:=This:C1470._readString($buffer; $ctx)
	$scope:=This:C1470._decodeDocument($buffer; $ctx)
	
	return {_bsontype: "Code"; code: $codeStr; scope: $scope}
	
	
Function _readTimestamp($buffer : Blob; $ctx : Object) : Object
	var $increment : Real
	var $time : Real
	
	$increment:=This:C1470._readUInt32($buffer; $ctx)
	$time:=This:C1470._readUInt32($buffer; $ctx)
	
	return {_bsontype: "Timestamp"; increment: $increment; timestamp: $time}
	
	
Function _readDBPointer($buffer : Blob; $ctx : Object) : Object
	var $ns : Text
	var $oid : Object
	
	$ns:=This:C1470._readString($buffer; $ctx)
	$oid:=This:C1470._readObjectId($buffer; $ctx)
	
	return {_bsontype: "DBPointer"; namespace: $ns; oid: $oid}
	
	
Function _readDecimal128($buffer : Blob; $ctx : Object) : Object
	var $bytes : Blob
	
	SET BLOB SIZE:C606($bytes; 16)
	COPY BLOB:C558($buffer; $bytes; $ctx.offset; 0; 16)
	$ctx.offset:=$ctx.offset+16
	
	return {_bsontype: "Decimal128"; bytes: $bytes}
	
	
	// ============================================================================
	// UTILITY METHODS
	// ============================================================================
	
Function _byteToHex($byte : Integer) : Text
	var $hexChars : Text:="0123456789abcdef"
	var $highNibble : Integer:=($byte >> 4) & 0x000F
	var $lowNibble : Integer:=$byte & 0x000F
	return Substring:C12($hexChars; $highNibble+1; 1)+Substring:C12($hexChars; $lowNibble+1; 1)
	
	
Function _hexToByte($hex : Text) : Integer
	var $hi : Integer
	var $lo : Integer
	
	$hi:=This:C1470._hexCharToInt($hex[[1]])
	$lo:=This:C1470._hexCharToInt($hex[[2]])
	return ($hi*16)+$lo
	
	
Function _hexCharToInt($char : Text) : Integer
	Case of 
		: (($char>="0") & ($char<="9"))
			return Character code:C91($char)-Character code:C91("0")
		: (($char>="a") & ($char<="f"))
			return Character code:C91($char)-Character code:C91("a")+10
		: (($char>="A") & ($char<="F"))
			return Character code:C91($char)-Character code:C91("A")+10
		Else 
			return 0
	End case 
	