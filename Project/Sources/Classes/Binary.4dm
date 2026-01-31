// Binary - Binary data with subtype
// Use cs.BinarySubtype.me for subtype constants
property data : Blob
property subtype : Integer

Class extends _Abtract

Class constructor($data : Blob; $subtype : Integer)
	Super:C1705("Binary")
	This:C1470.data:=$data
	This:C1470.subtype:=$subtype ? $subtype : cs:C1710.BinarySubtype.me.generic


	// Get the length of the binary data
Function length() : Integer
	return BLOB size:C605(This:C1470.data)
	
	
	// Get binary data as Base64 string
Function toBase64() : Text
	var $base64 : Text
	BASE64 ENCODE:C895(This:C1470.data; $base64)
	return $base64
	
	// Create from Base64 string
Function fromBase64($base64 : Text; $subtype : Integer) : cs:C1710.Binary
	var $data : Blob
	BASE64 DECODE:C896($base64; $data)
	return cs:C1710.Binary.new($data; $subtype)
	
	
	// Create UUID binary
Function createUUID() : cs:C1710.Binary
	var $uuid : Text
	var $data : Blob
	var $cleanUUID : Text
	var $i : Integer
	var $byte : Integer
	
	$uuid:=Generate UUID:C1066
	// Remove hyphens
	$cleanUUID:=Replace string:C233($uuid; "-"; "")
	
	// Convert hex string to bytes
	SET BLOB SIZE:C606($data; 16)
	For ($i; 0; 15)
		$byte:=This:C1470._hexToByte(Substring:C12($cleanUUID; ($i*2)+1; 2))
		$data{$i}:=$byte
	End for 
	
	return cs:C1710.Binary.new($data; cs:C1710.BinarySubtype.me.uuid)
	
	
	// Get UUID as string (if subtype is UUID)
Function toUUID() : Text
	var $result : Text
	var $i : Integer
	
	If ((This:C1470.subtype#cs:C1710.BinarySubtype.me.uuid) & (This:C1470.subtype#cs:C1710.BinarySubtype.me.oldUUID))
		return ""
	End if 
	
	If (BLOB size:C605(This:C1470.data)#16)
		return ""
	End if 
	
	$result:=""
	var $blobCopy : Blob:=This:C1470.data  // TODO: try to remove copy
	For ($i; 0; 15)
		$result:=$result+cs:C1710.BSON.me._byteToHex($blobCopy{$i})
		// Add hyphens at standard positions
		If (($i=3) | ($i=5) | ($i=7) | ($i=9))
			$result:=$result+"-"
		End if 
	End for 
	
	return $result
	
	
	// Return JSON representation
Function toJSON() : Object
	return {$binary: {base64: This:C1470.toBase64(); subType: This:C1470._subtypeToHex()}}
	
	
	// ============================================================================
	// UTILITY METHODS
	// ============================================================================
	
	
	
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
	
	
Function _subtypeToHex() : Text
	return cs:C1710.BSON.me._byteToHex(This:C1470.subtype)
	