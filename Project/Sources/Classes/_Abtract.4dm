// _Abtract - Abstract base class for all BSON types
// Provides common _bsontype property for type identification

property _bsontype : Text

Class constructor($bsontype : Text)
	This:C1470._bsontype:=$bsontype
	
	// Return the BSON type name
Function get bsonType() : Text
	return This:C1470._bsontype
	
	
	// Check if this is a valid BSON type
Function isValid() : Boolean
	return This:C1470._bsontype#""
	
	
	// Abstract methods - subclasses should override
Function toString() : Text
	return "BSONValue("+This:C1470._bsontype+")"
	
	
Function toJSON() : Object
	return {_bsontype: This:C1470._bsontype}
	