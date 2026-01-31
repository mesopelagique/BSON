// Regex - Regular expression pattern with flags
//  stores regex as pattern + flags strings (not compiled)

property pattern : Text
property flags : Text

Class extends _Abtract

Class constructor($pattern : Text; $flags : Text)
	Super:C1705("Regex")
	This:C1470.pattern:=$pattern
	This:C1470.flags:=This:C1470._sortFlags($flags)  // Flags must be alphabetically sorted
	
	
	// Sort flags alphabetically (BSON spec requirement)
Function _sortFlags($flags : Text) : Text
	var $result : Text
	var $validFlags : Text
	var $i : Integer
	var $char : Text
	
	$validFlags:="ilmsux"  // Valid BSON regex flags
	$result:=""
	
	// Add flags in alphabetical order
	For ($i; 1; Length:C16($validFlags))
		$char:=$validFlags[[$i]]
		If (Position:C15($char; $flags)>0)
			$result:=$result+$char
		End if 
	End for 
	
	return $result
	
	
	// Return string representation (JavaScript-like)
Function toString() : Text
	return "/"+This:C1470.pattern+"/"+This:C1470.flags
	
	
	// Return JSON representation (Extended JSON v2)
Function toJSON() : Object
	return {$regularExpression: {pattern: This:C1470.pattern; options: This:C1470.flags}}
	
	
	// Check equality
Function equals($other : Object) : Boolean
	If ($other=Null:C1517)
		return False:C215
	End if 
	If (Not:C34(OB Is defined:C1231($other; "pattern")) | Not:C34(OB Is defined:C1231($other; "flags")))
		return False:C215
	End if 
	return (This:C1470.pattern=$other.pattern) & (This:C1470.flags=$other.flags)
	