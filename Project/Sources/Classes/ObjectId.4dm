// ObjectId - 12-byte unique identifier for documents
// Format: 4-byte timestamp + 5-byte random + 3-byte counter
property id : Text

Class extends _Abtract

Class constructor($id : Text)
	Super:C1705("ObjectId")
	
	If ($id#"")
		// Validate and use provided hex string
		If (Length:C16($id)=24)
			This:C1470.id:=Lowercase:C14($id)
		Else 
			throw:C1805({message: "Invalid ObjectId: must be 24 hex characters"})
		End if 
	Else 
		// Generate new ObjectId
		This:C1470.id:=This:C1470._generate()
	End if 
	
	
	// Generate a new ObjectId
Function _generate() : Text
	var $timestamp : Integer
	var $random : Text
	var $counter : Text
	var $result : Text
	var $i : Integer
	var $byte : Integer
	
	// 4 bytes: Unix timestamp in seconds
	$timestamp:=(Current date:C33-!1970-01-01!)*86400+Current time:C178
	$result:=This:C1470._int32ToHex($timestamp)
	
	// 5 bytes: Random value
	$random:=""
	For ($i; 1; 5)
		$byte:=Random:C100%256
		$random:=$random+cs:C1710.BSON.me._byteToHex($byte)
	End for 
	$result:=$result+$random
	
	// 3 bytes: Counter (using random for simplicity)
	$counter:=""
	For ($i; 1; 3)
		$byte:=Random:C100%256
		$counter:=$counter+cs:C1710.BSON.me._byteToHex($byte)
	End for 
	$result:=$result+$counter
	
	return Lowercase:C14($result)
	
	
	// Get timestamp from ObjectId
Function getTimestamp() : Integer
	var $hex : Text
	$hex:=Substring:C12(This:C1470.id; 1; 8)
	return This:C1470._hexToInt32($hex)
	
	
	// Get date from ObjectId
Function getDate() : Date
	var $timestamp : Integer
	var $days : Integer
	
	$timestamp:=This:C1470.getTimestamp()
	$days:=$timestamp/86400
	return Add to date:C393(!1970-01-01!; 0; 0; $days)
	
	
	// Check equality
Function equals($other : Object) : Boolean
	If ($other=Null:C1517)
		return False:C215
	End if 
	If (OB Is defined:C1231($other; "id"))
		return (Lowercase:C14(This:C1470.id)=Lowercase:C14(String:C10($other.id)))
	End if 
	return False:C215
	
	
	// Return hex string representation
Function toString() : Text
	return This:C1470.id
	
	
	// Return JSON representation
Function toJSON() : Object
	return {$oid: This:C1470.id}
	
	
	// ============================================================================
	// UTILITY METHODS
	// ============================================================================
	
Function _int32ToHex($value : Integer) : Text
	var $result : Text
	$result:=""
	// Big-endian for timestamp display
	$result:=$result+cs:C1710.BSON.me._byteToHex(($value >> 24) & 0x00FF)
	$result:=$result+cs:C1710.BSON.me._byteToHex(($value >> 16) & 0x00FF)
	$result:=$result+cs:C1710.BSON.me._byteToHex(($value >> 8) & 0x00FF)
	$result:=$result+cs:C1710.BSON.me._byteToHex($value & 0x00FF)
	return $result
	
	
Function _hexToInt32($hex : Text) : Integer
	var $result : Integer
	var $i : Integer
	var $char : Text
	var $val : Integer
	
	$result:=0
	For ($i; 1; 8)
		$char:=$hex[[$i]]
		Case of 
			: (($char>="0") & ($char<="9"))
				$val:=Character code:C91($char)-Character code:C91("0")
			: (($char>="a") & ($char<="f"))
				$val:=Character code:C91($char)-Character code:C91("a")+10
			: (($char>="A") & ($char<="F"))
				$val:=Character code:C91($char)-Character code:C91("A")+10
			Else 
				$val:=0
		End case 
		$result:=($result << 4)+$val
	End for 
	
	return $result
	