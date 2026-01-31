// Decimal128 - 128-bit decimal floating point (IEEE 754-2008)
// Provides exact decimal representation for financial/scientific data
// Stores string for full precision, bytes for BSON encoding
property bytes : Blob
property _string : Text

Class extends _Abtract

Class constructor($value : Variant)
	Super:C1705("Decimal128")

	Case of
		: (Value type:C1509($value)=Is BLOB:K8:12)
			// Direct bytes from BSON decoding
			This:C1470.bytes:=$value
			This:C1470._string:=This:C1470._bytesToString($value)

		: (Value type:C1509($value)=Is text:K8:3)
			// Parse from string - preserves full precision
			This:C1470._string:=String:C10($value)
			This:C1470.bytes:=This:C1470._stringToBytes(This:C1470._string)

		: (Value type:C1509($value)=Is real:K8:4)
			// Convert from number (may lose precision)
			This:C1470._string:=String:C10($value; "&xml")
			This:C1470.bytes:=This:C1470._stringToBytes(This:C1470._string)

		Else
			// Default to zero
			This:C1470._string:="0"
			This:C1470.bytes:=This:C1470._stringToBytes("0")
	End case


// Convert string to IEEE 754-2008 Decimal128 bytes (16 bytes, little-endian)
// Format: sign (1 bit) + combination (5 bits) + exponent continuation (12 bits) + coefficient continuation (110 bits)
Function _stringToBytes($str : Text) : Blob
	var $bytes : Blob
	var $i : Integer
	var $negative : Boolean
	var $exponent : Integer
	var $coefficient : Text
	var $decimalPos : Integer
	var $expPos : Integer
	var $expSign : Integer
	var $expValue : Integer

	SET BLOB SIZE:C606($bytes; 16)
	For ($i; 0; 15)
		$bytes{$i}:=0
	End for

	// Trim whitespace
	$str:=This:C1470._trim($str)

	If (Length:C16($str)=0)
		return $bytes
	End if

	// Handle special values
	If (($str="NaN") | ($str="nan"))
		// NaN: high byte = 0x7C
		$bytes{15}:=0x7C
		return $bytes
	End if

	If (($str="Infinity") | ($str="inf") | ($str="+Infinity") | ($str="+inf"))
		// Positive Infinity: high byte = 0x78
		$bytes{15}:=0x78
		return $bytes
	End if

	If (($str="-Infinity") | ($str="-inf"))
		// Negative Infinity: high byte = 0xF8
		$bytes{15}:=0xF8
		return $bytes
	End if

	// Parse sign
	$negative:=False:C215
	If ($str[[1]]="-")
		$negative:=True:C214
		$str:=Substring:C12($str; 2)
	Else
		If ($str[[1]]="+")
			$str:=Substring:C12($str; 2)
		End if
	End if

	// Check for scientific notation (e or E)
	$expPos:=Position:C15("e"; $str)
	If ($expPos=0)
		$expPos:=Position:C15("E"; $str)
	End if

	$expValue:=0
	If ($expPos>0)
		// Parse exponent
		var $expStr : Text
		$expStr:=Substring:C12($str; $expPos+1)
		$str:=Substring:C12($str; 1; $expPos-1)
		$expSign:=1
		If (Length:C16($expStr)>0)
			If ($expStr[[1]]="-")
				$expSign:=-1
				$expStr:=Substring:C12($expStr; 2)
			Else
				If ($expStr[[1]]="+")
					$expStr:=Substring:C12($expStr; 2)
				End if
			End if
		End if
		$expValue:=$expSign*Num:C11($expStr)
	End if

	// Find decimal point and build coefficient string (digits only)
	$decimalPos:=Position:C15("."; $str)
	$coefficient:=""

	If ($decimalPos>0)
		// Has decimal point
		var $intPart : Text
		var $fracPart : Text
		$intPart:=Substring:C12($str; 1; $decimalPos-1)
		$fracPart:=Substring:C12($str; $decimalPos+1)
		$coefficient:=$intPart+$fracPart
		// Adjust exponent for decimal position
		$expValue:=$expValue-(Length:C16($fracPart))
	Else
		$coefficient:=$str
	End if

	// Remove leading zeros (but keep at least one digit)
	While ((Length:C16($coefficient)>1) & ($coefficient[[1]]="0"))
		$coefficient:=Substring:C12($coefficient; 2)
	End while

	// Decimal128 can store up to 34 significant digits
	// Truncate if necessary
	If (Length:C16($coefficient)>34)
		$expValue:=$expValue+(Length:C16($coefficient)-34)
		$coefficient:=Substring:C12($coefficient; 1; 34)
	End if

	// Encode using simplified BID (Binary Integer Decimal) format
	// For simplicity, we encode the coefficient as a 113-bit integer
	// and combine with biased exponent (bias = 6176)

	var $biasedExp : Integer
	$biasedExp:=$expValue+6176  // Decimal128 exponent bias

	// Clamp exponent to valid range [0, 12287]
	If ($biasedExp<0)
		$biasedExp:=0
	End if
	If ($biasedExp>12287)
		$biasedExp:=12287
	End if

	// Build the 128-bit value
	// We'll use a simplified encoding that stores coefficient digits as BCD-like
	// For proper BSON compatibility, we encode coefficient as binary integer

	// Convert coefficient string to array of 16-bit chunks (like Int64 but bigger)
	var $c0; $c1; $c2; $c3; $c4; $c5; $c6; $c7 : Integer  // 8 x 16-bit = 128 bits
	var $digit : Integer
	var $carry : Integer
	var $pos : Integer
	var $r0; $r1; $r2; $r3; $r4; $r5; $r6; $r7 : Integer

	$c0:=0
	$c1:=0
	$c2:=0
	$c3:=0
	$c4:=0
	$c5:=0
	$c6:=0
	$c7:=0

	// Parse coefficient digits
	For ($pos; 1; Length:C16($coefficient))
		$digit:=Num:C11($coefficient[[$pos]])

		// Multiply by 10 and add digit
		$r0:=$c0*10+$digit
		$carry:=Int:C8($r0/65536)
		$r0:=$r0 & 0xFFFF

		$r1:=$c1*10+$carry
		$carry:=Int:C8($r1/65536)
		$r1:=$r1 & 0xFFFF

		$r2:=$c2*10+$carry
		$carry:=Int:C8($r2/65536)
		$r2:=$r2 & 0xFFFF

		$r3:=$c3*10+$carry
		$carry:=Int:C8($r3/65536)
		$r3:=$r3 & 0xFFFF

		$r4:=$c4*10+$carry
		$carry:=Int:C8($r4/65536)
		$r4:=$r4 & 0xFFFF

		$r5:=$c5*10+$carry
		$carry:=Int:C8($r5/65536)
		$r5:=$r5 & 0xFFFF

		$r6:=$c6*10+$carry
		$carry:=Int:C8($r6/65536)
		$r6:=$r6 & 0xFFFF

		$r7:=$c7*10+$carry
		$r7:=$r7 & 0x0001  // Only 1 bit for coefficient MSB (113 bits total)

		$c0:=$r0
		$c1:=$r1
		$c2:=$r2
		$c3:=$r3
		$c4:=$r4
		$c5:=$r5
		$c6:=$r6
		$c7:=$r7
	End for

	// Pack into bytes (little-endian)
	// Bytes 0-13: coefficient (lower 112 bits)
	// Bytes 14-15: combination field with sign, exponent, and coefficient MSB

	$bytes{0}:=$c0 & 0xFF
	$bytes{1}:=Int:C8($c0/256) & 0xFF
	$bytes{2}:=$c1 & 0xFF
	$bytes{3}:=Int:C8($c1/256) & 0xFF
	$bytes{4}:=$c2 & 0xFF
	$bytes{5}:=Int:C8($c2/256) & 0xFF
	$bytes{6}:=$c3 & 0xFF
	$bytes{7}:=Int:C8($c3/256) & 0xFF
	$bytes{8}:=$c4 & 0xFF
	$bytes{9}:=Int:C8($c4/256) & 0xFF
	$bytes{10}:=$c5 & 0xFF
	$bytes{11}:=Int:C8($c5/256) & 0xFF
	$bytes{12}:=$c6 & 0xFF
	$bytes{13}:=Int:C8($c6/256) & 0xFF

	// Byte 14: lower 8 bits of exponent + upper bit of c6
	var $byte14; $byte15 : Integer
	$byte14:=($biasedExp & 0xFF)

	// Byte 15: sign (1 bit) + combination (5 bits) + exponent high (2 bits)
	$byte15:=Int:C8($biasedExp/256) & 0x3F  // 6 bits of exponent high
	If ($negative)
		$byte15:=$byte15 | 0x80  // Set sign bit
	End if

	$bytes{14}:=$byte14
	$bytes{15}:=$byte15

	return $bytes


// Convert bytes to string representation
Function _bytesToString($bytes : Blob) : Text
	var $byte15 : Integer
	var $negative : Boolean
	var $biasedExp : Integer
	var $result : Text

	If (BLOB size:C605($bytes)#16)
		return "0"
	End if

	$byte15:=$bytes{15}

	// Check for special values
	If (($byte15 & 0x7C)=0x7C)
		// NaN or Infinity
		If (($byte15 & 0x02)#0)
			return "NaN"
		End if
		If (($byte15 & 0x80)#0)
			return "-Infinity"
		Else
			return "Infinity"
		End if
	End if

	// Extract sign
	$negative:=(($byte15 & 0x80)#0)

	// Extract exponent (simplified - assumes standard encoding)
	$biasedExp:=$bytes{14}+(($byte15 & 0x3F)*256)

	// Extract coefficient from bytes 0-13
	var $c0; $c1; $c2; $c3; $c4; $c5; $c6 : Integer
	$c0:=$bytes{0}+($bytes{1}*256)
	$c1:=$bytes{2}+($bytes{3}*256)
	$c2:=$bytes{4}+($bytes{5}*256)
	$c3:=$bytes{6}+($bytes{7}*256)
	$c4:=$bytes{8}+($bytes{9}*256)
	$c5:=$bytes{10}+($bytes{11}*256)
	$c6:=$bytes{12}+($bytes{13}*256)

	// Convert coefficient to string by repeated division
	var $a0; $a1; $a2; $a3; $a4; $a5; $a6 : Integer
	var $r0; $r1; $r2; $r3; $r4; $r5; $r6 : Integer
	var $temp; $borrow; $remainder : Integer
	var $coeffStr : Text

	$a0:=$c0
	$a1:=$c1
	$a2:=$c2
	$a3:=$c3
	$a4:=$c4
	$a5:=$c5
	$a6:=$c6

	$coeffStr:=""

	While (($a0#0) | ($a1#0) | ($a2#0) | ($a3#0) | ($a4#0) | ($a5#0) | ($a6#0))
		// Divide by 10
		$temp:=$a6
		$r6:=Int:C8($temp/10)
		$borrow:=$temp-($r6*10)

		$temp:=$a5+($borrow*65536)
		$r5:=Int:C8($temp/10)
		$borrow:=$temp-($r5*10)

		$temp:=$a4+($borrow*65536)
		$r4:=Int:C8($temp/10)
		$borrow:=$temp-($r4*10)

		$temp:=$a3+($borrow*65536)
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

		$coeffStr:=String:C10($remainder)+$coeffStr

		$a0:=$r0
		$a1:=$r1
		$a2:=$r2
		$a3:=$r3
		$a4:=$r4
		$a5:=$r5
		$a6:=$r6
	End while

	If ($coeffStr="")
		$coeffStr:="0"
	End if

	// Calculate actual exponent
	var $exponent : Integer
	$exponent:=$biasedExp-6176

	// Format result
	If ($exponent=0)
		$result:=$coeffStr
	Else
		If (($exponent>0) & ($exponent<Length:C16($coeffStr)))
			// Insert decimal point
			var $intPart : Text
			var $fracPart : Text
			$intPart:=Substring:C12($coeffStr; 1; Length:C16($coeffStr)-$exponent)
			$fracPart:=Substring:C12($coeffStr; Length:C16($coeffStr)-$exponent+1)
			$result:=$intPart+"."+$fracPart
		Else
			// Use scientific notation
			$result:=$coeffStr+"E"+String:C10($exponent)
		End if
	End if

	If ($negative)
		$result:="-"+$result
	End if

	return $result


// Trim whitespace
Function _trim($str : Text) : Text
	While ((Length:C16($str)>0) & (Character code:C91($str[[1]])<=32))
		$str:=Substring:C12($str; 2)
	End while
	While ((Length:C16($str)>0) & (Character code:C91($str[[Length:C16($str)]])<=32))
		$str:=Substring:C12($str; 1; Length:C16($str)-1)
	End while
	return $str


// Get raw bytes for BSON encoding
Function getBytes() : Blob
	return This:C1470.bytes


// Return string representation
Function toString() : Text
	If (This:C1470._string#"")
		return This:C1470._string
	End if
	return This:C1470._bytesToString(This:C1470.bytes)


// Return JSON representation (Extended JSON v2)
Function toJSON() : Object
	return {$numberDecimal: This:C1470.toString()}


// Check for special values
Function isNaN() : Boolean
	var $byte15 : Integer
	If (BLOB size:C605(This:C1470.bytes)=16)
		$byte15:=This:C1470.bytes[15]
		If (($byte15 & 0x7C)=0x7C)
			If (($byte15 & 0x02)#0)
				return True:C214
			End if
		End if
	End if
	return False:C215


Function isInfinite() : Boolean
	var $byte15 : Integer
	If (BLOB size:C605(This:C1470.bytes)=16)
		$byte15:=This:C1470.bytes[15]
		If (($byte15 & 0x7C)=0x78)
			return True:C214
		End if
	End if
	return False:C215


Function isNegative() : Boolean
	var $byte15 : Integer
	If (BLOB size:C605(This:C1470.bytes)=16)
		$byte15:=This:C1470.bytes[15]
		If (($byte15 & 0x80)#0)
			return True:C214
		End if
	End if
	return False:C215


// Check equality
Function equals($other : Object) : Boolean
	var $otherBytes : Blob
	var $i : Integer

	If ($other=Null:C1517)
		return False:C215
	End if

	// Compare by string for precision
	If (OB Is defined:C1231($other; "_string"))
		return This:C1470._string=$other._string
	End if

	If (OB Is defined:C1231($other; "bytes"))
		$otherBytes:=$other.bytes
		If (BLOB size:C605(This:C1470.bytes)#BLOB size:C605($otherBytes))
			return False:C215
		End if
		For ($i; 0; 15)
			If (This:C1470.bytes[$i]#$otherBytes{$i})
				return False:C215
			End if
		End for
		return True:C214
	End if

	return False:C215
