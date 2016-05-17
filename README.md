## Overview

This is Swift Tcl, a bridge between Swift and Tcl, providing deep interoperability between the two languages.

Swift developers can use Tcl to make new and powerful ways to interact with, debug, construct automated testing for, and orchestrate the high level activities of their applications.

Tcl developers can use Swift to gets its sweet, expressive, high performance, scripting-language-like capabilities wherever they would like while retaining all of their existing code.

Either can go in for a lot or a little.

Developers can extend Tcl by writing new commands in Swift and extend Swift by writing new commands in Tcl.  Tcl commands written in Swift are tiny and simple compared to those written in C.  They are a joy.

Soon, the bridge will be able to automatically generate Tcl interfaces to existing Swift functions and classes through automated scanning of Swift source.

Likewise through introspection, automation and a bit of static hinting, Tcl procedures appear as native Swift functions, with argument names, default values and "normal" native Swift argument and return data types.

Users of either language invoke functions written in the other indistinguishably from those written in the one they're using.

Likewise errors are handled naturally across both languages in both directions.  Errors thrown from Swift code called by Tcl come back as Tcl errors with proper errorInfo, errorCode, etc.  Closing the loop, uncaught errors occuring in Tcl code called from Swift are thrown back to the caller as Swift errors.

Swift Tcl defines a *TclInterp* class in Swift that provides methods for creating and managing Tcl interpreters, executing Tcl code in them, etc.  Creating a Tcl interpreter and doing something with it in Swift is as easy as:

```swift
let interp = TclInterp()

interp.eval("puts {Hello, World.}")
```

It also defines a *TclObj* class that can convert between Swift data types such as Int, Double, String, Swift Arrays, Sets, and Dictionaries and Tcl object representations of equivalent types.

New Tcl commands written in Swift and are far more compact and generally simpler than their counterparts in C.

Real work can be done with the Tcl interpeter without using TclObj objects at all.

The TclInterp object has methods for accessing and manipulating variables, arrays, evaluating code, etc.  In the examples below a String and a Double are obtained from variables in the Tcl interpreter:

```swift
var autoPath: String = try interp.getVar("auto_path")
print("auto_path is '\(autoPath)'")

let tclVersion: Double = try interp.getVar("tcl_version")
print("Tcl version is \(tclVersion)")
```

Y'see how getVar just gave you the data type you asked for with no funny business?  How cool is that?  Also note how we use *try* because getVar will fail if the variable doesn't exist.

Likewise TclInterp's getVar can fetch elements out of an array:

```swift
var machine: String = try interp.getVar("tcl_platform", elementName: "machine")
```

In this example we import Tcl's global _tcl_platform_ array into a Swift dictionary:

```swift
try interp.eval("array get tcl_platform")
var dict: [String:String] = try interp.resultObj.toDictionary()
```

We can then access the imported Tcl array in the usual Swift way:

```swift
print("Your OS is \(dict["os"]!), running version \(dict["osVersion"]!)")
```

## Writing Tcl extensions in Swift

You can extend Tcl with new commands written in Swift.

Swift functions implementing Tcl commands are invoked with arguments comprising a TclInterp object and an array of TclObj objects corresponding to the arguments to the function (although unlike with C, objv[0] is the first argument to the function, not the function itself.)

Below is a function that will average all of its arguments that are numbers and return the result:

To report errors back to Tcl, Swift functions throw them, and because of this and due to included support your function can directly return a String, Int, Double, Bool, TclObj or TclReturn without all that tedious mucking about with the interpreter result and distinct explicit return of a Tcl return code (ok, return, break, continue, error).

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

Errors trying to convert Tcl objects to a data type such as trying to convert an alphanumeric string to a Double are thrown by the underlying helper functions and caught by Swift Tcl if you don't catch them in your Swift code.  You get nice native error messages.

TclObj methods like *getDoubleArg* make it a bit easier by tacking on appropriate bits to Tcl's *errorInfo* traceback, making error messages from Swift conformant to the Tcl style.

```swift
func fa_latlongs_to_distance_cmd (interp: TclInterp, objv: [TclObj]) throws -> Double {
	if (objv.count != 4) {
		throw TclError.WrongNumArgs(nLeadingArguments: 0, message: "lat0 lon0 lat1 lon1")
	}
	
	let lat1 = try objv[0].getDoubleArg("lat1")
	let lon1 = try objv[1].getDoubleArg("lon1")
	let lat2 = try objv[2].getDoubleArg("lat2")
	let lon2 = try objv[3].getDoubleArg("lon2")
		
	let distance = fa_latlongs_to_distance(lat1, lon1: lon1, lat2: lat2, lon2: lon2)
	return distance
}
```

In the above example invoking `try interp.eval("puts \"distance from KIAH to KSEA is [fa_latlongs_to_distance  29.9844444 -95.3414444 47.4498889 -122.3117778]\"")` emits **distance from KIAH to KSEA is 1874.5897193432174** while `try interp.eval("puts \"distance from KIAH to KSEA is [fa_latlongs_to_distance  29.9844444 -95.3414444 crash -122.3117778]\"")` produces a Tcl traceback that looks like

```
expected floating-point number but got "crash" while converting "lat2" argument
    invoked from within
"fa_latlongs_to_distance  29.9844444 -95.3414444 crash -122.3117778"
    invoked from within
"puts "distance from KIAH to KSEA is [fa_latlongs_to_distance  29.9844444 -95.3414444 crash -122.3117778]""
```

## Methods of the TclInterp class

* `var interp = TclInterp()`

Create a new Tcl interpreter.  You can create as many as you like.

* `try interp.eval(code: String) -> Type`

Evaluate Tcl code in the Tcl interpreter. Return value is the result of the code, can be any of String, Int, Double, or Bool.

* `try interp.RawEval(code: String)`

Evaluate the code, don't return anything.

You can control whether or not error are printed by manipulating the *printErrors* variable, which currently defaults to true and will include the traceback.

### Accessing the interpreter result.

There are a number of interfaces here, which will be trimmed down with experience:

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

* `interp.getResult() -> String`
* `interp.getResult() -> Double`
* `interp.getResult() -> Int`
* `interp.getResult() -> Bool`

Get the Interpreter result as the corresponding type.

### Registering commands

* `interp.create_command(name: String, SwiftTclFunction:SwiftTclFuncType)`

Create a new command in the Tcl interpreter with the specified name: when the name is invoked from Tcl the corresponding Swift function will be invoked to perform the command. The Swift function should be of type (tclInterp, [TclObj]) -> Type, where Type can be String, Double, Int, or Bool. Eg:

* `func swiftFunction (interp: TclInterp, objv: [TclObj]) throws -> Type`

### Handling variables.

* `var val: UnsafeMutablePointer<TclObj> = interp.getVar(varName: String, elementName: String?, flags: VariableFlags = [])`

Get a variable or array element out of the Tcl interpreter and return it as a Tcl\_Obj \*.  This is internal and you shouldn't really ever need it.

* `var val: TclObj = try interp.getVar(varName: String, elementName: String?, flags: VariableFlags = [])`

Get a variable or array element out of the Tcl interpreter and return it as a string or throw an error.

* `var val: Int = try interp.getVar(varName: String, elementName: String?, flags: VariableFlags = [])`

Get a variable or array element out of the Tcl interpreter and return it as an Int.  An error is thrown if the object's contents aren't a valid list or if the element can't be converted to an Int.

* `var val: Double = try interp.getVar(varName: String, elementName: String?, flags: VariableFlags = [])`
* `var val: String = try interp.getVar(varName: String, elementName: String?, flags: VariableFlags = [])`
* `var val: Bool = try interp.getVar(varName: String, elementName: String?, flags: VariableFlags = [])`

Get a variable or array element out of the Tcl interpeter and return it as a Double, String or Bool et al or throw an error.

* `interp.setVar(varName: String, elementName: String?, value: String, flags: VariableFlags = [])`
* `interp.setVar(varName: String, elementName: String?, value: Int, flags: VariableFlags = [])`
* `interp.setVar(varName: String, elementName: String?, value: Double, flags: VariableFlags = [])`
* `interp.setVar(varName: String, elementName: String?, value: Bool, flags: VariableFlags = [])`
* `interp.setVar(varName: String, elementName: String?, value: TclObj, flags: VariableFlags = [])`

Set a variable or array element in the Tcl interpeter to be the String, Int, Double, Bool or TclObj that was passed or throw an error if unable.  For instance you might be unable to set an array element when the variable name is a scalar.

* `interp.dictionaryToArray (arrayName: String, dictionary: [String: String], flags: VariableFlags = [])`
* `interp.dictionaryToArray (arrayName: String, dictionary: [String: Int], flags: VariableFlags = [])`
* `interp.dictionaryToArray (arrayName: String, dictionary: [String: Double], flags: VariableFlags = [])`

Import a Swift Dictionary into a Tcl array.

Flags are an OptionSet. Values are:
* `.GlobalOnly         = TCL_GLOBAL_ONLY`
* `.NamespaceOnly      = TCL_NAMESPACE_ONLY`
* `.LeaveErroMsg       = TCL_LEAVE_ERR_MSG`
* `.AppendValue        = TCL_APPEND_VALUE`
* `.ListElement        = TCL_LIST_ELEMENT`
* `.TraceReads         = TCL_TRACE_READS`
* `.TraceWrites        = TCL_TRACE_WRITES`
* `.TraceUnsets        = TCL_TRACE_UNSETS`
* `.TraceDestroyed     = TCL_TRACE_DESTROYED`
* `.InterpDestroyed    = TCL_INTERP_DESTROYED`
* `.TraceArray         = TCL_TRACE_ARRAY`
* `.TraceResultDynamic = TCL_TRACE_RESULT_DYNAMIC`
* `.TraceResultObject  = TCL_TRACE_RESULT_OBJECT`

###String substitution

* `interp.subst (substIn: String, flags: SubstFlags) -> String`
* `interp.subst (substIn: String, flags: SubstFlags) -> TclObj`

Perform substitution on String in the fashion of the Tcl *subst* command, performing variable substitution, evaluating square-bracketed stuff as embedded Tcl commands and substituting their result, and performing backslash substitution and return the result.

Flags are an OptionSet of one or more of [.Commands, .Variables, .Backslashes, .All].  [.All] is the default.
 
### Errors

* `setErrorCode(val: String) throws`
    
Set the Tcl error code
    
* `addErrorInfo(message: String)`

Append a message to the error information

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

* `var val: Int = try obj.getInt()`

Set val to contain the Int representation of the TclObj, or throws an error if object cannot be represented as an Int.

* `var val: Double = try obj.getDouble()`
* `var valBool Double = try obj.getBool()`

Same as the above but for Double and Bool.

* `var nativeObj: UnsafeMutablePointer<Tcl_Obj> = obj.getObj()`

Obtain a pointer to the native C Tcl object from a TclObj

* `try obj.lappend(value: UnsafeMootablePointer<Tcl_Obj>)`

Append a Tcl\_Obj \* to a list contained in a TclObj.

* `try obj.lappend(value: Int)`
* `try obj.lappend(value: Double)`
* `try obj.lappend(value: String)`
* `try obj.lappend(value: Bool)`
* `try obj.lappend(value: TclObj)`

Append an Int, Double, String, Bool or TclObj to a list contained in a TclObj.

* `try obj.lappend(array: [Int])`
* `try obj.lappend(array: [Double])`
* `try obj.lappend(array: [String])`

Append an array of Int, Double, or String to a list contained in a TclObj.  Each element is appended.

* `var val: Int = try obj.lindex(index)`
* `var val: Double = try obj.lindex(index)`
* `var val: String = try obj.lindex(index)`
* `var val: Bool = try obj.lindex(index)`
* `var val: TclObj = try obj.lindex(index)`

Return the nth element of the obj as a list, if possible, according to the specified data type, else throws an error.

* `var val: [Int] = try obj.lrange(start, end)`
* `var val: [Double] = try obj.lrange(start, end)`
* `var val: [String] = try obj.lrange(start, end)`
* `var val: [Bool] = try obj.lrange(start, end)`

Return the start...end range of object as a list

* `var count: Int = try obj.llength()`

Return the number of elements in the list contained in the TclObj or throws an error if the value in the TclObj cannot be represented as a list.

* `var String? s = obj[index]`
* `var [String]? s = obj[start, end]`

Subscripting the object treats it as a list, exactly like lindex and lrange.

* `var array: [Double] = obj.toArray()`
* `var array: [Int] = obj.toArray()`
* `var array: [String] = obj.toArray()`
* `var array: [TclObj] = obj.toArray()`

Treating TclObj obj as a Tcl list, if it is a valid list and the data types are OK the elements are imported into an array of the corresponding type.

* `var dictionary: [String:String] = try obj.toDictionary()`
* `var dictionary: [String:Int] = try obj.toDictionary()`
* `var dictionary: [String:Double] = try obj.toDictionary()`
* `var dictionary: [String:TclObj] = try obj.toDictionary()`

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

* linking Tcl variables to Swift variables using Tcl_LinkVar
* Shadowing Tcl arrays in Swift
* Tcl dictionary interface
* lrange and stuff
* automatically generating interfaces between The [TclObj] call trampoline and functions with native types
