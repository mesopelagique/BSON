// Int64 - 64-bit signed integer
// Stored as two 32-bit integers (high and low parts) since 4D Integer is 32-bit
// NOTE: 4D's XOR operator doesn't work correctly for bit inversion, so we use subtraction
property low : Integer  // Lower 32 bits
property high : Integer  // Upper 32 bits

Class extends _Abtract

// Constructor accepts string representation for large values
Class constructor($value : Variant)
	Super:C1705("Int64")
	
	Case of 
		: (Value type:C1509($value)=Is text:K8:3)
			This:C1470._fromString(String:C10($value))
			
		: (Value type:C1509($value)=Is real:K8:4) | (Value type:C1509($value)=Is longint:K8:6)
			This:C1470._fromSmallNumber(Num:C11($value))
			
		Else 
			This:C1470.low:=0
			This:C1470.high:=0
	End case 
	
	
	// Create from high and low 32-bit parts directly
Function fromBits($low : Integer; $high : Integer) : cs:C1710.Int64
	var $result : cs:C1710.Int64
	$result:=cs:C1710.Int64.new(0)
	$result.low:=$low
	$result.high:=$high
	return $result
	
	
	// From small positive number only
Function _fromSmallNumber($value : Real)
	If (($value>=0) & ($value<2147483648))
		This:C1470.low:=Num:C11($value)
		This:C1470.high:=0
	Else 
		This:C1470._fromString(String:C10($value; "&xml"))
	End if 
	
	
	// Combine two 16-bit values into a 32-bit signed integer
Function _combine16($lo16 : Integer; $hi16 : Integer) : Integer
	If ($hi16>=32768)
		return $lo16+(($hi16-65536)*65536)
	Else 
		return $lo16+($hi16*65536)
	End if 
	
	
	// Parse from string using 16-bit chunk arithmetic
Function _fromString($str : Text)
	var $negative : Boolean
	var $pos : Integer
	var $len : Integer
	var $digit : Integer
	var $char : Text
	var $a0; $a1; $a2; $a3 : Integer
	var $r0; $r1; $r2; $r3 : Integer
	var $carry : Integer
	
	// Trim
	While ((Length:C16($str)>0) & (Character code:C91($str[[1]])<=32))
		$str:=Substring:C12($str; 2)
	End while 
	While ((Length:C16($str)>0) & (Character code:C91($str[[Length:C16($str)]])<=32))
		$str:=Substring:C12($str; 1; Length:C16($str)-1)
	End while 
	
	$len:=Length:C16($str)
	If ($len=0)
		This:C1470.low:=0
		This:C1470.high:=0
		return 
	End if 
	
	// Check negative
	$negative:=False:C215
	$pos:=1
	If ($str[[1]]="-")
		$negative:=True:C214
		$pos:=2
	Else 
		If ($str[[1]]="+")
			$pos:=2
		End if 
	End if 
	
	// Initialize 16-bit chunks to zero
	$a0:=0
	$a1:=0
	$a2:=0
	$a3:=0
	
	// Parse each digit: multiply by 10 and add
	While ($pos<=$len)
		$char:=$str[[$pos]]
		If (($char>="0") & ($char<="9"))
			$digit:=Num:C11($char)
			
			// Multiply by 10 and add digit
			$r0:=$a0*10+$digit
			$carry:=Int:C8($r0/65536)
			$r0:=$r0 & 0xFFFF
			
			$r1:=$a1*10+$carry
			$carry:=Int:C8($r1/65536)
			$r1:=$r1 & 0xFFFF
			
			$r2:=$a2*10+$carry
			$carry:=Int:C8($r2/65536)
			$r2:=$r2 & 0xFFFF
			
			$r3:=$a3*10+$carry
			$r3:=$r3 & 0xFFFF
			
			$a0:=$r0
			$a1:=$r1
			$a2:=$r2
			$a3:=$r3
		End if 
		$pos:=$pos+1
	End while 
	
	// Reconstruct
	This:C1470.low:=This:C1470._combine16($a0; $a1)
	This:C1470.high:=This:C1470._combine16($a2; $a3)
	
	If ($negative)
		This:C1470._negate()
	End if 
	
	
	// Split a 32-bit integer into two 16-bit unsigned values
Function _split16($val : Integer; $lo : Pointer; $hi : Pointer)
	If ($val>=0)
		$lo->:=$val & 0xFFFF
		$hi->:=Int:C8($val/65536)
	Else 
		// Negative: treat as unsigned
		// low 16 bits: val & 0xFFFF works
		$lo->:=$val & 0xFFFF
		// high 16 bits: need to handle sign extension
		// val = signed, val + 2^32 = unsigned
		// high16 = ((unsigned val) / 65536) & 0xFFFF
		// In 4D: Int(val/65536) gives signed result, then & 0xFFFF
		$hi->:=Int:C8($val/65536) & 0xFFFF
	End if 
	
	
	// Negate (two's complement) - invert bits and add 1
	// Since XOR doesn't work in 4D, use: invert = 65535 - val for 16-bit
Function _negate()
	var $a0; $a1; $a2; $a3 : Integer
	var $r0; $r1; $r2; $r3 : Integer
	
	// Split into 16-bit chunks
	This:C1470._split16(This:C1470.low; ->$a0; ->$a1)
	This:C1470._split16(This:C1470.high; ->$a2; ->$a3)
	
	// Invert bits using subtraction (65535 - x = ~x for 16-bit)
	$a0:=65535-$a0
	$a1:=65535-$a1
	$a2:=65535-$a2
	$a3:=65535-$a3
	
	// Add 1 with carry propagation
	$r0:=$a0+1
	If ($r0>=65536)
		$r0:=$r0-65536
		$r1:=$a1+1
		If ($r1>=65536)
			$r1:=$r1-65536
			$r2:=$a2+1
			If ($r2>=65536)
				$r2:=$r2-65536
				$r3:=$a3+1
				If ($r3>=65536)
					$r3:=$r3-65536
				End if 
			Else 
				$r3:=$a3
			End if 
		Else 
			$r2:=$a2
			$r3:=$a3
		End if 
	Else 
		$r1:=$a1
		$r2:=$a2
		$r3:=$a3
	End if 
	
	// Reconstruct
	This:C1470.low:=This:C1470._combine16($r0; $r1)
	This:C1470.high:=This:C1470._combine16($r2; $r3)
	
	
	// Get low 32 bits
Function getLow() : Integer
	return This:C1470.low
	
	
	// Get high 32 bits
Function getHigh() : Integer
	return This:C1470.high
	
	
	// Check if zero
Function isZero() : Boolean
	return (This:C1470.low=0) & (This:C1470.high=0)
	
	
	// Check if negative
Function isNegative() : Boolean
	return This:C1470.high<0
	
	
	// Negate (return new instance)
Function negate() : cs:C1710.Int64
	var $result : cs:C1710.Int64
	$result:=cs:C1710.Int64.new(0)
	$result.low:=This:C1470.low
	$result.high:=This:C1470.high
	$result._negate()
	return $result
	
	
	// Add another Int64
Function add($other : cs:C1710.Int64) : cs:C1710.Int64
	var $result : cs:C1710.Int64
	var $a0; $a1; $a2; $a3 : Integer
	var $b0; $b1; $b2; $b3 : Integer
	var $r0; $r1; $r2; $r3 : Integer
	var $carry : Integer
	
	$result:=cs:C1710.Int64.new(0)
	
	This:C1470._split16(This:C1470.low; ->$a0; ->$a1)
	This:C1470._split16(This:C1470.high; ->$a2; ->$a3)
	This:C1470._split16($other.low; ->$b0; ->$b1)
	This:C1470._split16($other.high; ->$b2; ->$b3)
	
	$r0:=$a0+$b0
	$carry:=Int:C8($r0/65536)
	$r0:=$r0 & 0xFFFF
	
	$r1:=$a1+$b1+$carry
	$carry:=Int:C8($r1/65536)
	$r1:=$r1 & 0xFFFF
	
	$r2:=$a2+$b2+$carry
	$carry:=Int:C8($r2/65536)
	$r2:=$r2 & 0xFFFF
	
	$r3:=$a3+$b3+$carry
	$r3:=$r3 & 0xFFFF
	
	$result.low:=This:C1470._combine16($r0; $r1)
	$result.high:=This:C1470._combine16($r2; $r3)
	
	return $result
	
	
	// Subtract another Int64
Function subtract($other : cs:C1710.Int64) : cs:C1710.Int64
	return This:C1470.add($other.negate())
	
	
	// Compare with another Int64
Function compare($other : cs:C1710.Int64) : Integer
	If (This:C1470.high<$other.high)
		return -1
	End if 
	If (This:C1470.high>$other.high)
		return 1
	End if 
	
	// Compare low as unsigned
	var $thisLowNeg : Boolean
	var $otherLowNeg : Boolean
	$thisLowNeg:=(This:C1470.low<0)
	$otherLowNeg:=($other.low<0)
	
	If ($thisLowNeg & Not:C34($otherLowNeg))
		return 1
	End if 
	If (Not:C34($thisLowNeg) & $otherLowNeg)
		return -1
	End if 
	
	If (This:C1470.low<$other.low)
		return -1
	End if 
	If (This:C1470.low>$other.low)
		return 1
	End if 
	
	return 0
	
	
	// Check equality
Function equals($other : Object) : Boolean
	If ($other=Null:C1517)
		return False:C215
	End if 
	If (OB Is defined:C1231($other; "low") & OB Is defined:C1231($other; "high"))
		return (This:C1470.low=$other.low) & (This:C1470.high=$other.high)
	End if 
	return False:C215
	
	
	// Return string representation
Function toString() : Text
	var $negative : Boolean
	var $a0; $a1; $a2; $a3 : Integer
	var $r0; $r1; $r2; $r3 : Integer
	var $borrow; $remainder : Integer
	var $result : Text
	var $temp : Integer
	
	If (This:C1470.isZero())
		return "0"
	End if 
	
	$negative:=This:C1470.isNegative()
	
	// Get 16-bit chunks
	This:C1470._split16(This:C1470.low; ->$a0; ->$a1)
	This:C1470._split16(This:C1470.high; ->$a2; ->$a3)
	
	// If negative, negate to get absolute value using subtraction
	If ($negative)
		$a0:=65535-$a0
		$a1:=65535-$a1
		$a2:=65535-$a2
		$a3:=65535-$a3
		
		// Add 1
		$a0:=$a0+1
		If ($a0>=65536)
			$a0:=$a0-65536
			$a1:=$a1+1
			If ($a1>=65536)
				$a1:=$a1-65536
				$a2:=$a2+1
				If ($a2>=65536)
					$a2:=$a2-65536
					$a3:=$a3+1
					$a3:=$a3 & 0xFFFF
				End if 
			End if 
		End if 
	End if 
	
	// Convert to string by repeated division by 10
	$result:=""
	
	While (($a0#0) | ($a1#0) | ($a2#0) | ($a3#0))
		// Divide by 10 from high to low
		$temp:=$a3
		$r3:=Int:C8($temp/10)
		$borrow:=$temp-($r3*10)
		
		$temp:=$a2+($borrow*65536)
		$r2:=Int:C8($temp/10)
		$borrow:=$temp-($r2*10)
		
		$temp:=$a1+($borrow*65536)
		$r1:=Int:C8($temp/10)
		$borrow:=$temp-($r1*10)
		
		$temp:=$a0+($borrow*65536)
		$r0:=Int:C8($temp/10)
		$remainder:=$temp-($r0*10)
		
		$result:=String:C10($remainder)+$result
		
		$a0:=$r0
		$a1:=$r1
		$a2:=$r2
		$a3:=$r3
	End while 
	
	If ($negative)
		$result:="-"+$result
	End if 
	
	return $result
	
	
	// Return as number (loses precision for large values)
Function toNumber() : Real
	If (This:C1470.isNegative())
		return -(This:C1470.negate().toNumber())
	End if 
	
	var $result : Real
	var $a0; $a1; $a2; $a3 : Integer
	
	This:C1470._split16(This:C1470.low; ->$a0; ->$a1)
	This:C1470._split16(This:C1470.high; ->$a2; ->$a3)
	
	$result:=$a0+($a1*65536)+($a2*4294967296)+($a3*281474976710656)
	return $result
	
	
	// Return JSON representation
Function toJSON() : Object
	return {$numberLong: This:C1470.toString()}
	