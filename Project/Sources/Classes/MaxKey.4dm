// MaxKey - Special type that compares higher than all other BSON types
// Used for query boundaries
Class extends _Abtract

Class constructor()
	Super:C1705("MaxKey")
	
	
	// Return string representation
Function toString() : Text
	return "MaxKey()"
	
	
	// Return JSON representation (Extended JSON v2)
Function toJSON() : Object
	return {$maxKey: 1}
	
	
	// Compare with another value - MaxKey is always greater
Function compare($other : Variant) : Integer
	If (Value type:C1509($other)=Is object:K8:27)
		If (OB Is defined:C1231($other; "_bsontype"))
			If (String:C10($other._bsontype)="MaxKey")
				return 0  // Equal to another MaxKey
			End if 
		End if 
	End if 
	return 1  // Greater than everything else
	