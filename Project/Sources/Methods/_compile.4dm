//%attributes = {}

var $options:=New object:C1471
$options.targets:=[]
$options.generateSymbols:=False:C215
$options.generateSyntaxFile:=True:C214
$options.generateTypingMethods:=False:C215

var $components:=Folder:C1567(fk database folder:K87:14).folders().filter(Formula:C1597($1.value.extension=".4dbase"))
var $lock:=Folder:C1567(fk database folder:K87:14).folder("userPreferences."+Current system user:C484).file("dependencies-lock.json")
If ($lock.exists)
	var $lockData:=JSON Parse:C1218($lock.getText())
	$lockData.dependencies:=$lockData.dependencies || {}
	var $key : Text
	For each ($key; $lockData.dependencies)
		If (Length:C16(String:C10($lockData.dependencies[$key].path))>0)
			
			var $folder:=Try(Folder:C1567(String:C10($lockData.dependencies[$key].path); fk platform path:K87:2))
			If ($folder=Null:C1517)
				$folder:=Try(Folder:C1567(String:C10($lockData.dependencies[$key].path); fk posix path:K87:1))
			End if 
			If ($folder#Null:C1517)
				$components.push($folder)
			End if 
			
		End if 
	End for each 
End if 

// Find component project files, prefer .4DProject over .4DZ to avoid duplicates
// .4DProject is in Component.4dbase/Project/Component.4DProject
// .4DZ is in Component.4dbase/Component.4DZ
var $projectFiles : Collection:=$components.flatMap(Formula:C1597($1.value.files(fk recursive:K87:7).filter(Formula:C1597($1.value.extension=".4DProject"))))
var $zFiles : Collection:=$components.flatMap(Formula:C1597($1.value.files(fk recursive:K87:7).filter(Formula:C1597($1.value.extension=".4DZ"))))
// Get component names that have .4DProject files
var $projectNames : Collection:=$projectFiles.map(Formula:C1597($1.value.parent.parent.name))
// Keep only .4DZ files for components without .4DProject
$zFiles:=$zFiles.filter(Formula:C1597(Not:C34($projectNames.includes($1.value.parent.name))))
$components:=$projectFiles.combine($zFiles)
$options.components:=$components

var $result : Object:=Compile project:C1760($options)

ALERT:C41(JSON Stringify:C1217($result))