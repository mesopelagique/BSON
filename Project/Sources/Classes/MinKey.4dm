// MinKey - Special type that compares lower than all other BSON types
// Used for query boundaries
Class extends _Abtract

Class constructor()
	Super:C1705("MinKey")
	
	
	// Return string representation
Function toString() : Text
	return "MinKey()"
	
	
	// Return JSON representation (Extended JSON v2)
Function toJSON() : Object
	return {$minKey: 1}
	
	
	// Compare with another value - MinKey is always less
Function compare($other : Variant) : Integer
	If (Value type:C1509($other)=Is object:K8:27)
		If (OB Is defined:C1231($other; "_bsontype"))
			If (String:C10($other._bsontype)="MinKey")
				return 0  // Equal to another MinKey
			End if 
		End if 
	End if 
	return -1  // Less than everything else
	