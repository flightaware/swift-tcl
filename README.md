## Overview

This is Swift Tcl, a bridge between Swift and Tcl, providing deep integration between the two languages.

Developers can extend Tcl by writing new commands in Swift and extend Swift by writing new commands in Tcl.  Tcl commands written in Swift are smaller and cleaner and require far less scaffolding, argument handling and code interpreter result management than those written in C.  They are a joy.

Likewise through introspection, automation and a bit of hinting, Tcl procedures appear as native Swift functions, with argument names, default values and "normal" native Swift argument and return data types.

Users of either language invoke functions written in the other indistinguishably from those written in the one they're using.

Swift Tcl defines a TclInterp class in Swift that provides methods for creating and managing Tcl interpreters, executing Tcl code in them, etc.

It also defines a TclObj class that can convert between Swift data types such as Int, Double, String, Swift Arrays, Sets, and Dictionaries and Tcl object representations of equivalent types.

New Tcl commands can be written in Swift and are far more compact and generally simpler than their counterparts in C.

Real work can be done with the Tcl interpeter without using TclObj objects at all.

```swift
let interp = TclInterp()

interp.eval("puts {Hello, World.}")
```

The TclInterp object has methods for accessing and manipulating variables, arrays, evaluating code, etc.  In the exsamples below a String and a Double are obtained from variables in the Tcl interpreter:

```swift
var autoPath: String = interp.getVar("auto_path")!
print("auto_path is '\(autoPath)'")

var tclVersion: Double = interp.getVar("tcl_version")!
print("Tcl version is \(tclVersion)")
```
Likewise TclInterp's getVar can fetch elements out of an array:

```swift
var machine: String = interp.getVar("tcl_platform", elementName: "machine")!
```

In this example we import an "array get" of Tcl's global _tcl_platform_ array into a Swift dictionary:

```swift
do {try interp.eval("array get tcl_platform")}
var dict: [String:String]? = interp.resultObj.toDictionary()
```

We can then access the array we've imported into a Swift dictionary in the usual Swift way:

```swift
print("Your OS is \(dict["os"]!), running version \(dict["osVersion"]!)")
```

## Writing Tcl extensions in Swift

You can create new commands in Tcl that are implemented as Swift functions.  

Swift functions implementing Tcl commands are invoked with a TclInterp object and an array of TclObj objects corresponding to the arguments to the function, although unlike with C objv[0] is the first argument to the function, not the function itself.

Below is a function that will average all of its arguments that are numbers and return the result:

To report errors, functions throw them and because of this and due to included support can directly return a String, Int, Double, Bool, TclObj or TclReturn without all that tedious mucking about with the interpreter result and distinct explicit return of a Tcl return code (ok, error, break, continue, return).

```swift
func avg (interp: TclInterp, objv: [TclObj]) -> Double {
	var sum = 0.0
	for obj in objv {
		guard let val = obj.doubleValue else {continue}
		sum += val
	}
	return(sum / Double(objv.count))
}

interp.create_command("avg", avg)
```

## Methods of the TclInterp class

* `var interp = TclInterp()`

Create a new Tcl interpreter.  You can create as many as you like.

* `var result: Int = interp.eval(code: String)`

Evaluate Tcl code in the Tcl interpreter and return the interpreter result as an Int.

You can control whether or not errors resulting from invoking eval throw Swift errors by setting the *throwErrors* boolean to true.  Otherwise Tcl errors are not thrown and it is up to the caller to examine the return code if they want to see if there was an error.  It currently defaults to false.

You can control whether or not errors are printed by manipulating the *printErrors* variable, which currently defaults to true and will include the traceback.

* `var result: String = interp.result`

Obtain the interpreter result as a string.

* `var resultObj: TclObj = interp.resultObj`

Obtain the interpreter result as a TclObj object.

* `interp.result = String`

Set the interpreter result to be the specified string.

* `interp.resultObj = TclObj`

Set the interpreter result to the specified TclObj object.

* `interp.setResult(Double)`
* `interp.setResult(Int)`
* `interp.setResult(Bool)`

Set the interpreter result to the specified Double, Int, or Bool, respectively.

* interp.create_command(name: String, SwiftTclFunction:SwiftTclFuncType)`

Create a new command in Tcl of the specified name that when the name is invoked from Tcl the corresponding Swift function will be invoked to perform the command.

* `var val: UnsafeMutablePointer<TclObj> = interp.getVar(varName: String, elementName: String?, flags: Int = 0)`

Get a variable or array element out of the Tcl interpreter and return it as a Tcl\_Obj \*.

* `var val: TclObj? = interp.getVar(varName: String, elementName: String?, flags: Int = 0)`

Get a variable or array element out of the Tcl interpreter and return it as an optional string.

* `var val: Int? = interp.getVar(varName: String, elementName: String?, flags: Int = 0)`

Get a variable or array element out of the Tcl interpreter and return it as an optional Int.  nil is returned if the object's contents aren't a valid list or if the element can't be converted to an Int.

* `var val: Double? = interp.getVar(varName: String, elementName: String?, flags: Int = 0)`
* `var val: String? = interp.getVar(varName: String, elementName: String?, flags: Int = 0)`
* `var val: Bool? = interp.getVar(varName: String, elementName: String?, flags: Int = 0)`

Get a variable or array element out of the Tcl interpeter and return it as an optional Double, String or Bool.

* `var success: Bool = interp.setVar(varName: String, elementName: String?, value: UnsafeMutablePointer<Tcl_Obj>, flags: Int = 0)`

Set a variable or array element in the Tcl interpreter to be the Tcl\_Obj \* that was passed.

* `var success: Bool = interp.setVar(varName: String, elementName: String?, value: String, flags: Int = 0)`
* `var success: Bool = interp.setVar(varName: String, elementName: String?, value: Int, flags: Int = 0)`
* `var success: Bool = interp.setVar(varName: String, elementName: String?, value: Double, flags: Int = 0)`
* `var success: Bool = interp.setVar(varName: String, elementName: String?, value: Bool, flags: Int = 0)`
* `var success: Bool = interp.setVar(varName: String, elementName: String?, value: TclObj, flags: Int = 0)`

Set a variable or array element in the Tcl interpeter to be the String, Int, Double, Bool or TclObj that was passed.

* `interp.dictionaryToArray (arrayName: String, dictionary: [String: String], flags: Int = 0)`
* `interp.dictionaryToArray (arrayName: String, dictionary: [String: Int], flags: Int = 0)`
* `interp.dictionaryToArray (arrayName: String, dictionary: [String: Double], flags: Int = 0)`

Import a Swift Dictionary into a Tcl array.

* `interp.subst (substIn: String, flags: Int32 = TCL_SUBST_ALL) -> String
* `interp.subst (substIn: String, flags: Int32 = TCL_SUBST_ALL) -> TclObj

Perform substitution on String in the fashion of the Tcl *subst* command, performing variable substitution, evaluating square-bracketed stuff as embedded Tcl commands and substituting their result, and performing backslash substitution and return the result.

Flags can be a logical OR of any of the following: TCL_SUBST_COMMANDS, TCL_SUBST_VARIABLES, TCL_SUBST_BACKSLASHES, TCL_SUBST_ALL.  TCL_SUBST_ALL is the default.


## The TclObj class

The TclObj class gives Swift access to Tcl objects.  A TclObj can be wrapped around any C-level Tcl Object (Tcl\_Obj \*) and its methods use to access and manipulate the object.

The object can be new or existing.  For example `var obj = TclObj(5)` creates a new Tcl object with an integer representation and a value of 5 while `var obj = interp.resultObj` wraps an existing Tcl\_Obj object as a Swift TclObj.

The TclObj object manages Tcl reference counts so that all this will work.  For example, setting a Tcl array element to a TclObj using `interp.setVar(arrayName, elementName: element, value: obj)`, the element will continue to hold the object even if the TclObj is deleted on the Swift side.

* `var obj = TclObj()`
* `var obj = TclObj(String)`
* `var obj = TclObj(Int)`
* `var obj = TclObj(Double)`
* `var obj = TclObj(Bool)`

Create a Swift TclObj object that's empty, contains a String, an Int, Double or Bool.

* `var obj = TclObj(UnsafeMutablePointer<Tcl_Obj>)`

Create a TclObj object encapsulating a <UnsafeMutablePointer<Tcl_Obj> aka a Tcl\_Obj \*.

* `obj.set(Set<String>)`
* `obj.set(Set<Int>)`
* `obj.set(Set<Double>)`

Set the TclObj object to contain a String, Int or Double.

* `obj.set([String])`
* `obj.set([Int])`
* `obj.set([Double])`

Set a TclObj object to be a Tcl list containing a Swift array of either String, Int or Double.

* `obj.set([String:String])`
* `obj.set([String:Int])`
* `obj.set([String:Double])`

Set a TclObj object to contain a Tcl list of key-value pairs from the contents of a Swift Dictionary having names of String and values of String, Int or Double

* `obj = String`
* `obj = Int`
* `obj = Double`
* `obj = Bool`

Assign TclObj to contain a String, Int, Double or Bool.

* `var val: String = obj`

Set String to contain the String representation of whatever TclObj has in it

* `var val: Int? = obj.getInt()`

Set Int to contain the Int representation of the TclObj, or nil if it cannot be represented as an Int.

* `var val: Double? = obj.getDouble()`
* `var valBool Double? = obj.getBool()`

Same as the above but for Double and Bool.

*  `do {var val: Int = obj.getInt()}`

Return the TclObj's value as an Int or throw an error if it cannot be represented as one.

*  `do {var val: Int = obj.getDouble()}`

Same as the above but for Double.

* `var nativeObj: UnsafeMutablePointer<Tcl_Obj> = obj.getObj()`

Obtain a pointer to the native C Tcl object from a TclObj

* `var status: Bool = obj.lappend(value: UnsafeMootablePointer<Tcl_Obj>)`

Append a Tcl\_Obj \* to a list contained in a TclObj

* `var status: Bool = obj.lappend(value: Int)`
* `var status: Bool = obj.lappend(value: Double)`
* `var status: Bool = obj.lappend(value: String)`
* `var status: Bool = obj.lappend(value: Bool)`
* `var status: Bool = obj.lappend(value: TclObj)`

Append an Int, Double, String, Bool or TclObj to a list contained in a TclObj

* `var status: Bool = obj.lappend(array: [Int])`
* `var status: Bool = obj.lappend(array: [Double])`
* `var status: Bool = obj.lappend(array: [String])`

Append an array of Int, Double, or String to a list contained in a TclObj.  Each element is appended.

* `var val: Int? = obj.lindex(index)
* `var val: Double? = obj.lindex(index)
* `var val: String? = obj.lindex(index)
* `var val: Bool? = obj.lindex(index)
* `var val: TclObj? = obj.lindex(index)

Return the nth element of the obj as a list, if possible, according to the specified data type, else nil.

* `var count: Int? = obj.llength()`

Return the number of elements in the list contained in the TclObj or nil if the value in the TclObj cannot be represented as a list

Return the number of elements 

* `var array: [Double] = obj.toArray()`
* `var array: [Int] = obj.toArray()`
* `var array: [String] = obj.toArray()`
* `var array: [TclObj] = obj.toArray()`

Treating TclObj obj as a Tcl list, if it is a valid list and the data types are OK the elements are imported into an array of the corresponding type.

* `var dictionary: [String:String]? = obj.toDictionary()`
* `var dictionary: [String:Int]? = obj.toDictionary()`
* `var dictionary: [String:Double]? = obj.toDictionary()`
* `var dictionary: [String:TclObj]? = obj.toDictionary()`

Import a Tcl list of key-value pairs contained in a TclObj to a dictionary having a key of a String type and values of String, Int, Double or TclObjs.

## Building

Right now this is on the Mac and requires Xcode and the included Xcode project looks to Tcl as installed by macports (https://www.macports.org/) with the include file in /opt/local/include and the tcl dylib in /opt/local/lib.

To go this way make sure Xcode and macports are installed and install Tcl with "sudo port install tcl".

The code can also be built against the Tcl that gets installed in /usr/include, /usr/lib, etc, as installed by the Xcode command line tools if you change the targets in the project.

## Running it

I'm currently just running it from within Xcode.  The TclInterp and TclObj classes are defined in tcl.swift while main.swift defines a TclInterp and messes around with it a bit.

## Stuff it has

* A Swift TclInterp that wraps Tcl interpreters and provides methods to do stuff with them such as evaluate Tcl code, get and set the Interpreter result, etc.
* A way to create new Tcl commands that invoke Swift functions
* A Swift TclObj that wraps TclObj's and provides methods to do stuff with them
* Methods to convert between Swift Lists, Sets and Dictionaries and Tcl lists, arrays and dicts
* Additional methods of the TclInterp class to get and set Tcl variables (including array elements) and additional ways to interact with the Tcl interpreter that are useful

## Stuff it needs

* proc aliasing (generated scaffolding makes procs indistinguishable from other Swift functions)
* tcl object system class aliasing

## Stuff that would be nice eventually

* Support for safe interpreters
* Support for setting resource limits on interpreters using Tcl\_Limit\*

## Stuff that would be cool if it's even possible

* The ability to introspect Swift from Tcl to find objects and invoke methods on them (Swift seems to be moving away from even providing a way to do that.  I still think bridging is useful even if it can't do this.)

## Stuff that might be interesting to try

* linking Tcl variables to Swift variables using Tcl\_LinkVar
* Shadowing Tcl arrays in Swift
* Tcl dictionary interface
* lrange and stuff

