// Code - JavaScript code string with optional scope
// Used for storing functions code
Class extends _Abtract

property code : Text
property scope : Object


Class constructor($code : Text; $scope : Object)
	Super:C1705("Code")
	This:C1470.code:=$code
	This:C1470.scope:=$scope  // Can be Null for code without scope
	
	
	// Check if code has scope
Function hasScope() : Boolean
	return This:C1470.scope#Null:C1517
	
	
	// Return string representation
Function toString() : Text
	If (This:C1470.hasScope())
		return "Code(\""+This:C1470.code+"\", "+JSON Stringify:C1217(This:C1470.scope)+")"
	Else 
		return "Code(\""+This:C1470.code+"\")"
	End if 
	
	
	// Return JSON representation (Extended JSON v2)
Function toJSON() : Object
	If (This:C1470.hasScope())
		return {$code: This:C1470.code; $scope: This:C1470.scope}
	Else 
		return {$code: This:C1470.code}
	End if 
	