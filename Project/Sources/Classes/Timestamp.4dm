// Timestamp - timestamp type
// Used for replication oplog and change streams
// Format: 32-bit timestamp (seconds) + 32-bit increment (ordinal)

property timestamp : Real
property increment : Real

Class extends _Abtract

Class constructor($timestamp : Real; $increment : Real)
	Super:C1705("Timestamp")
	This:C1470.timestamp:=$timestamp ? $timestamp : 0
	This:C1470.increment:=$increment ? $increment : 0
	
	
	// Create timestamp from current time
Function now() : cs:C1710.Timestamp
	var $seconds : Real
	$seconds:=(Current date:C33-!1970-01-01!)*86400+Current time:C178
	return cs:C1710.Timestamp.new($seconds; 0)
	
	
	// Get date from timestamp
Function getDate() : Date
	var $days : Integer
	$days:=This:C1470.timestamp/86400
	return Add to date:C393(!1970-01-01!; 0; 0; $days)
	
	
	// Get time from timestamp
Function getTime() : Time
	var $seconds : Integer
	$seconds:=Mod:C98(This:C1470.timestamp; 86400)
	return Time:C179(String:C10($seconds))
	
	
	// Compare timestamps
Function compare($other : cs:C1710.Timestamp) : Integer
	If (This:C1470.timestamp<$other.timestamp)
		return -1
	End if 
	If (This:C1470.timestamp>$other.timestamp)
		return 1
	End if 
	If (This:C1470.increment<$other.increment)
		return -1
	End if 
	If (This:C1470.increment>$other.increment)
		return 1
	End if 
	return 0
	
	
	// Check equality
Function equals($other : Object) : Boolean
	If ($other=Null:C1517)
		return False:C215
	End if 
	If (Not:C34(OB Is defined:C1231($other; "timestamp")) | Not:C34(OB Is defined:C1231($other; "increment")))
		return False:C215
	End if 
	return (This:C1470.timestamp=$other.timestamp) & (This:C1470.increment=$other.increment)
	
	
	// Return string representation
Function toString() : Text
	return "Timestamp("+String:C10(This:C1470.timestamp)+", "+String:C10(This:C1470.increment)+")"
	
	
	// Return JSON representation
Function toJSON() : Object
	return {$timestamp: {t: This:C1470.timestamp; i: This:C1470.increment}}
	