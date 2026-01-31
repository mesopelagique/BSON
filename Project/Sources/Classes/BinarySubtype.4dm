// BinarySubtype - BSON Binary subtype constants (enum-like singleton)
// Reference: https://bsonspec.org/spec.html

property generic : Integer
property function : Integer
property oldBinary : Integer
property oldUUID : Integer
property uuid : Integer
property md5 : Integer
property encrypted : Integer
property column : Integer
property sensitive : Integer
property vector : Integer
property userDefined : Integer

singleton Class constructor()

// Generic binary data
This.generic:=0x00

// Function data
This.function:=0x01

// Old binary format (deprecated)
This.oldBinary:=0x02

// Old UUID format (deprecated)
This.oldUUID:=0x03

// UUID (RFC 4122)
This.uuid:=0x04

// MD5 hash
This.md5:=0x05

// Encrypted data
This.encrypted:=0x06

// Compressed column data
This.column:=0x07

// Sensitive data
This.sensitive:=0x08

// Vector data
This.vector:=0x09

// User-defined (0x80-0xFF)
This.userDefined:=0x80
