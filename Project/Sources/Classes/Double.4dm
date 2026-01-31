// Double - IEEE 754 64-bit floating point
// Wrapper to explicitly mark a value as BSON Double type
property value : Real

Class extends _Abtract

Class constructor($value : Real)
	Super:C1705("Double")
	This:C1470.value:=$value
	
	
	// Check for special values
Function isNaN() : Boolean
	return This:C1470.value#This:C1470.value  // NaN is the only value not equal to itself
	
	
Function isInfinite() : Boolean
	return (This:C1470.value=1/0) | (This:C1470.value=-1/0)
	
	
Function isPositiveInfinity() : Boolean
	return This:C1470.value=1/0
	
	
Function isNegativeInfinity() : Boolean
	return This:C1470.value=-1/0
	
	
Function isFinite() : Boolean
	return (Not:C34(This:C1470.isNaN())) & (Not:C34(This:C1470.isInfinite()))
	
	
	// Return as number
Function toNumber() : Real
	return This:C1470.value
	
	
	// Return string representation
Function toString() : Text
	If (This:C1470.isNaN())
		return "NaN"
	End if 
	If (This:C1470.isPositiveInfinity())
		return "Infinity"
	End if 
	If (This:C1470.isNegativeInfinity())
		return "-Infinity"
	End if 
	return String:C10(This:C1470.value)
	
	
	// Return JSON representation (Extended JSON v2)
Function toJSON() : Object
	If (This:C1470.isNaN())
		return {$numberDouble: "NaN"}
	End if 
	If (This:C1470.isPositiveInfinity())
		return {$numberDouble: "Infinity"}
	End if 
	If (This:C1470.isNegativeInfinity())
		return {$numberDouble: "-Infinity"}
	End if 
	return {$numberDouble: This:C1470.toString()}
	
	
	// Check equality
Function equals($other : Object) : Boolean
	If ($other=Null:C1517)
		return False:C215
	End if 
	If (OB Is defined:C1231($other; "value"))
		return This:C1470.value=$other.value
	End if 
	return False:C215
	