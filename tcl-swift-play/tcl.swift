//
//  tcl.swift
//  tcl-swift-play
//
//  Created by Karl Lehenbauer on 4/6/16.
//  Copyright © 2016 FlightAware. All rights reserved.
//
// Free under the Berkeley license.
//

import Foundation

public enum TclReturn: Int32 {
    case OK = 0
    case ERROR = 1
    case RETURN = 2
    case BREAK = 3
    case CONTINUE = 4
}

// Tcl commands functions written in Swift can return Int, Double, String, Bool, TclObj or a TCL_RETURN-type code

public typealias SwiftTclFuncReturningTclReturn = (TclInterp, [TclObj]) throws -> TclReturn
public typealias SwiftTclFuncReturningInt = (TclInterp, [TclObj]) throws -> Int
public typealias SwiftTclFuncReturningDouble = (TclInterp, [TclObj]) throws -> Double
public typealias SwiftTclFuncReturningString = (TclInterp, [TclObj]) throws -> String
public typealias SwiftTclFuncReturningBool = (TclInterp, [TclObj]) throws -> Bool
public typealias SwiftTclFuncReturningTclObj = (TclInterp, [TclObj]) throws -> TclObj

public enum SwiftTclFunctionType {
    case TclReturn(SwiftTclFuncReturningTclReturn)
    case Int(SwiftTclFuncReturningInt)
    case Double(SwiftTclFuncReturningDouble)
    case String(SwiftTclFuncReturningString)
    case Bool(SwiftTclFuncReturningBool)
    case TclObj(SwiftTclFuncReturningTclObj)
}

enum TclError: ErrorType {
    case WrongNumArgs(nLeadingArguments: Int, message: String)
    case ErrorMessage(message: String, errorCode: String) // set error message in interpreter result
    case Error // error already set in interpreter result
}

// TclCommandBlock - when creating a Tcl command -> Swift
class TclCommandBlock {
    let swiftTclCallFunction: SwiftTclFunctionType
    let Interp: TclInterp
    
    init(myInterp: TclInterp, function: SwiftTclFuncReturningTclReturn) {
        Interp = myInterp
        swiftTclCallFunction = .TclReturn(function)
    }
    
    init(myInterp: TclInterp, function: SwiftTclFuncReturningInt) {
        Interp = myInterp
        swiftTclCallFunction = .Int(function)
    }

    init(myInterp: TclInterp, function: SwiftTclFuncReturningDouble) {
        Interp = myInterp
        swiftTclCallFunction = .Double(function)
    }

    init(myInterp: TclInterp, function: SwiftTclFuncReturningString) {
        Interp = myInterp
        swiftTclCallFunction = .String(function)
    }

    init(myInterp: TclInterp, function: SwiftTclFuncReturningBool) {
        Interp = myInterp
        swiftTclCallFunction = .Bool(function)
    }
    
    init(myInterp: TclInterp, function: SwiftTclFuncReturningTclObj) {
        Interp = myInterp
        swiftTclCallFunction = .TclObj(function)
    }

    func invoke(objv: [TclObj]) throws -> TclReturn {
        switch swiftTclCallFunction {
        case .TclReturn(let function):
            return try function(Interp, objv)
        default:
            abort()
        }
    }
    
    func invoke(objv: [TclObj]) throws -> Int {
        switch swiftTclCallFunction {
        case .Int(let function):
            return try function(Interp, objv)
        default:
            abort()
        }
    }
    
    func invoke(objv: [TclObj]) throws -> Double {
        switch swiftTclCallFunction {
        case .Double(let function):
            return try function(Interp, objv)
        default:
            abort()
        }
    }
    
    func invoke(objv: [TclObj]) throws -> String {
        switch swiftTclCallFunction {
        case .String(let function):
            return try function(Interp, objv)
        default:
            abort()
        }
    }
    
    func invoke(objv: [TclObj]) throws -> Bool {
        switch swiftTclCallFunction {
        case .Bool(let function):
            return try function(Interp, objv)
        default:
            abort()
        }
    }
    
    func invoke(objv: [TclObj]) throws -> TclObj {
        switch swiftTclCallFunction {
        case .TclObj(let function):
            return try function(Interp, objv)
        default:
            abort()
        }
    }
}

// tclobjp_to_String - return the value of a Tcl_Obj * as a String or nil

func tclobjp_to_String (tclObjP: UnsafeMutablePointer<Tcl_Obj>?) throws -> String {
    return String.fromCString(Tcl_GetString(tclObjP!))!
}

// tclobjp_to_Int - return the value of a Tcl_Obj * as an Int or nil

func tclobjp_to_Int (tclObjP: UnsafeMutablePointer<Tcl_Obj>?, interp: UnsafeMutablePointer<Tcl_Interp> = nil) throws -> Int {
    var longVal: CLong = 0
    
    let result = Tcl_GetLongFromObj (interp, tclObjP!, &longVal)
    if (result == TCL_ERROR) {
        if (interp == nil) {
            throw TclError.ErrorMessage(message: "expected integer", errorCode: "TCL VALUE NUMBER")
        } else {
            throw TclError.Error
        }
    }
    return longVal
}

// tclobjp_to_Double - return the value of a Tcl_Obj * as a Double or nil

func tclobjp_to_Double (tclObjP: UnsafeMutablePointer<Tcl_Obj>?, interp: UnsafeMutablePointer<Tcl_Interp> = nil) throws -> Double {
    var doubleVal: Double = 0
    
    let result = Tcl_GetDoubleFromObj (interp, tclObjP!, &doubleVal)
    if (result == TCL_ERROR) {
        if (interp == nil) {
            throw TclError.ErrorMessage(message: "expected double", errorCode: "TCL VALUE NUMBER")
        } else {
            throw TclError.Error
        }

    }
    return doubleVal
}

// tclobjp_to_Bool - return the value of a Tcl_Obj * as a Bool or nil

func tclobjp_to_Bool (tclObjP: UnsafeMutablePointer<Tcl_Obj>?, interp: UnsafeMutablePointer<Tcl_Interp> = nil) throws -> Bool {
    var boolVal: Int32 = 0
    
    let result = Tcl_GetBooleanFromObj (interp, tclObjP!, &boolVal)
    if (result == TCL_ERROR) {
        if (interp == nil) {
            throw TclError.ErrorMessage(message: "expected boolean", errorCode: "TCL VALUE NUMBER")
        } else {
            throw TclError.Error
        }

    }
    return boolVal == 0 ? true : false
}

// string_to_tclobjp - create a Tcl_Obj * from a Swift String

func string_to_tclobjp (string: String) -> UnsafeMutablePointer<Tcl_Obj> {
    guard let cString = string.cStringUsingEncoding(NSUTF8StringEncoding) else {return nil}
    return Tcl_NewStringObj (cString, -1)
}

// omg this is so cool

// extend Swift's String object

extension String {
    // initialize string straight from a TclObj!
    public init (_ obj: TclObj) {
        self.init(obj.stringValue)
    }
    
    func toTclObj() -> TclObj? {
        return TclObj(self)
    }
    
    mutating func fromTclObj(obj: TclObj) {
        self = obj.stringValue
    }
}

extension Int {
    // var foo: Int = someTclObj; failable initializer
    public init? (_ obj: TclObj) {
        guard obj.intValue != nil else {return nil}
        self.init(obj.intValue!)
    }

    func toTclObj() -> TclObj {
        return TclObj(self)
    }
    
    mutating func fromTclObj(obj: TclObj) {
        self = obj.intValue!
    }
}

extension Double {
    public init (_ obj: TclObj) {
        self.init(obj.doubleValue!)
    }


    func toTclObj() -> TclObj {
        return TclObj(self)
    }
    
    mutating func fromTclObj(obj: TclObj) {
        self = obj.doubleValue!
    }
}

extension Bool {
    public init? (_ obj: TclObj) {
        guard obj.boolValue != nil else {return nil}
        self.init(obj.boolValue!)
    }

    func toTclObj() -> TclObj {
        return TclObj(self)
    }
    
    mutating func fromTclObj(obj: TclObj) {
        self = obj.boolValue!
    }
}


// swift_tcl_bridger - this is the trampoline that gets called by Tcl when invoking a created Swift command
//   this declaration is the Swift equivalent of Tcl_ObjCmdProc *proc
func swift_tcl_bridger (clientData: ClientData, interp: UnsafeMutablePointer<Tcl_Interp>, objc: Int32, objv: UnsafePointer<UnsafeMutablePointer<Tcl_Obj>>) -> Int32 {
    let tcb = UnsafeMutablePointer<TclCommandBlock>(clientData).memory
    
    // construct an array containing the arguments
    // (go from 1 not 0 because we don't include the obj containing the command name)
    var objvec = [TclObj]()
    for i in 1..<Int(objc) {
        objvec.append(TclObj(objv[i], Interp: tcb.Interp))
    }
    
    // invoke the Swift implementation of the Tcl command and return the value it returns
    do {
        switch tcb.swiftTclCallFunction {
        case .TclReturn:
            let ret: TclReturn = try tcb.invoke(objvec)
            return ret.rawValue
            
        case .String:
            let result: String = try tcb.invoke(objvec)
            tcb.Interp.result = result
            
            
        case .Double:
            let result: Double = try tcb.invoke(objvec)
            tcb.Interp.setResult(result)
            
        case .Int:
            let result: Int = try tcb.invoke(objvec)
            tcb.Interp.setResult(result)
            
        case .Bool:
            let result: Bool = try tcb.invoke(objvec)
            tcb.Interp.setResult(result)
            
        case .TclObj:
            let result: TclObj = try tcb.invoke(objvec)
            tcb.Interp.resultObj = result

        }
    } catch TclError.Error {
        return TCL_ERROR
    } catch TclError.ErrorMessage(let message) {
        tcb.Interp.result = message.message
        tcb.Interp.setErrorCode(message.errorCode)
        return TCL_ERROR
    } catch TclError.WrongNumArgs(let nLeadingArguments, let message) {
        Tcl_WrongNumArgs(interp, Int32(nLeadingArguments), objv, message.cStringUsingEncoding(NSUTF8StringEncoding) ?? [])
    } catch (let error) {
        tcb.Interp.result = "unknown error type \(error)"
        return TCL_ERROR
    }
    return TCL_OK
}


// TclObj - Tcl object class

public class TclObj {
    let obj: UnsafeMutablePointer<Tcl_Obj>
    let Interp: TclInterp?
    let interp: UnsafeMutablePointer<Tcl_Interp>
    
    // various initializers to create a Tcl object from nothing, an int,
    // double, string, Tcl_Obj *, etc
    
    // init - initialize from nothing, get an empty Tcl object
    public init(Interp: TclInterp? = nil) {
        self.Interp = Interp; self.interp = Interp?.interp ?? nil
        obj = Tcl_NewObj()
		IncrRefCount(obj)
    }
    
    // init - initialize from a Swift Int
    public init(_ val: Int, Interp: TclInterp? = nil) {
        self.Interp = Interp; self.interp = Interp?.interp ?? nil
        obj = Tcl_NewLongObj(val)
		IncrRefCount(obj)
    }
    
    // init - initialize from a Swift String
    public init(_ val: String, Interp: TclInterp? = nil) {
        self.Interp = Interp; self.interp = Interp?.interp ?? nil
        let string = val.cStringUsingEncoding(NSUTF8StringEncoding) ?? []
        obj = Tcl_NewStringObj (string, -1)
		IncrRefCount(obj)
    }
    
    // init - initialize from a Swift Double
    public init(_ val: Double, Interp: TclInterp? = nil) {
        self.Interp = Interp; self.interp = Interp?.interp ?? nil
        obj = Tcl_NewDoubleObj (val)
		IncrRefCount(obj)
    }
    
    // init - initialize from a Swift Bool
    public init(_ val: Bool, Interp: TclInterp? = nil) {
        self.Interp = Interp; self.interp = Interp?.interp ?? nil
        obj = Tcl_NewBooleanObj(val ? 1 : 0)
        IncrRefCount(obj)
    }
    
    // init - Initialize from a Tcl_Obj *
    init(_ val: UnsafeMutablePointer<Tcl_Obj>, Interp: TclInterp? = nil) {
        self.Interp = Interp; self.interp = Interp?.interp ?? nil
        obj = val
        IncrRefCount(val)
    }
    
    // init - init from a set of Strings to a list
    public init(_ set: Set<String>, Interp: TclInterp? = nil) {
        self.Interp = Interp; self.interp = Interp?.interp ?? nil
        obj = Tcl_NewObj()
		IncrRefCount(obj)

        for element in set {
            let string = element.cStringUsingEncoding(NSUTF8StringEncoding) ?? []
            Tcl_ListObjAppendElement (interp, obj, Tcl_NewStringObj (string, -1))
        }
    }
    
    // init from a set of Ints to a list
    public init(_ set: Set<Int>, Interp: TclInterp? = nil) {
        self.Interp = Interp; self.interp = Interp?.interp ?? nil
        obj = Tcl_NewObj()
		IncrRefCount(obj)
        
        for element in set {
            Tcl_ListObjAppendElement (interp, obj, Tcl_NewLongObj (element))
        }
    }
    
    // init from a Set of doubles to a list
    public init(_ set: Set<Double>, Interp: TclInterp? = nil) {
        self.Interp = Interp; self.interp = Interp?.interp ?? nil
        obj = Tcl_NewObj()
		IncrRefCount(obj)
        
        for element in set {
            Tcl_ListObjAppendElement (nil, obj, Tcl_NewDoubleObj (element))
        }
    }
    
    // init from an Array of Strings to a Tcl list
    public init(_ array: [String], Interp: TclInterp? = nil) {
        self.Interp = Interp; self.interp = Interp?.interp ?? nil
        obj = Tcl_NewObj()
		IncrRefCount(obj)
        
        for element in array {
            let string = element.cStringUsingEncoding(NSUTF8StringEncoding) ?? []
            Tcl_ListObjAppendElement (nil, obj, Tcl_NewStringObj (string, -1))
        }
    }
    
    // Init from an Array of Int to a Tcl list
    public init (_ array: [Int], Interp: TclInterp? = nil) {
        self.Interp = Interp; self.interp = Interp?.interp ?? nil
        obj = Tcl_NewObj()
		IncrRefCount(obj)
        
        array.forEach {
            Tcl_ListObjAppendElement (nil, obj, Tcl_NewLongObj($0))
        }
    }
    
    // Init from an Array of Double to a Tcl list
    public init (_ array: [Double], Interp: TclInterp? = nil) {
        self.Interp = Interp; self.interp = Interp?.interp ?? nil
        obj = Tcl_NewObj()
		IncrRefCount(obj)

        array.forEach {
            Tcl_ListObjAppendElement(nil, obj, Tcl_NewDoubleObj($0))
        }
    }

    // init from a String/String dictionary to a list
    public init (_ dictionary: [String: String], Interp: TclInterp? = nil) {
        self.Interp = Interp; self.interp = Interp?.interp ?? nil
        obj = Tcl_NewObj()
		IncrRefCount(obj)

        dictionary.forEach {
            let keyString = $0.0.cStringUsingEncoding(NSUTF8StringEncoding) ?? []
            Tcl_ListObjAppendElement (nil, obj, Tcl_NewStringObj (keyString, -1))
            let valueString = $0.1.cStringUsingEncoding(NSUTF8StringEncoding) ?? []
            Tcl_ListObjAppendElement (nil, obj, Tcl_NewStringObj (valueString, -1))
        }
    }
    
    // init from a String/Int dictionary to a list
    public init (_ dictionary: [String: Int], Interp: TclInterp? = nil) {
        self.Interp = Interp; self.interp = Interp?.interp ?? nil
        obj = Tcl_NewObj()
		IncrRefCount(obj)
        
        dictionary.forEach {
            let keyString = $0.0.cStringUsingEncoding(NSUTF8StringEncoding) ?? []
            Tcl_ListObjAppendElement (nil, obj, Tcl_NewStringObj (keyString, -1))
            Tcl_ListObjAppendElement (nil, obj, Tcl_NewLongObj ($0.1))
        }
    }
   
    // init from a String/Double dictionary to a list
    public init (_ dictionary: [String: Double], Interp: TclInterp? = nil) {
        self.Interp = Interp; self.interp = Interp?.interp ?? nil
        obj = Tcl_NewObj()
		IncrRefCount(obj)
        
        dictionary.forEach {
            let keyString = $0.0.cStringUsingEncoding(NSUTF8StringEncoding) ?? []
            Tcl_ListObjAppendElement (nil, obj, Tcl_NewStringObj (keyString, -1))
            Tcl_ListObjAppendElement (nil, obj, Tcl_NewDoubleObj ($0.1))
        }
    }
    
    // deinit - decrement the object's reference count.  if it goes below one
    // the object will be freed.  if not then something else has it and it will
    // be freed after the last use
    deinit {
        DecrRefCount(obj)
    }
    
    // various set functions to set the Tcl object from a string, Int, Double, etc
    public var stringValue: String {
        get {
            do {
                return try tclobjp_to_String(obj)
            } catch {
                return ""
            }
        }
        set {
            Tcl_SetStringObj (obj, newValue.cStringUsingEncoding(NSUTF8StringEncoding) ?? [], -1)
        }
    }

    // getInt - return the Tcl object as an Int or nil
    // if in-object Tcl type conversion fails
    public var intValue: Int? {
        get {
            do {
                return try tclobjp_to_Int(obj)
            } catch {
                return nil
            }
        }
        set {
            guard let val = newValue else {return}
            Tcl_SetLongObj (obj, val)
        }
    }
    
    // getDouble - return the Tcl object as a Double or nil
    // if in-object Tcl type conversion fails
    public var doubleValue: Double? {
        get {
            return try? tclobjp_to_Double(obj)
        }
        set {
            guard let val = newValue else {return}
            Tcl_SetDoubleObj (obj, val)
        }
    }
    
    // getBool - return the Tcl object as a Bool or nil
    public var boolValue: Bool? {
        get {
            return try? tclobjp_to_Bool(obj)
        }
        set {
            guard let val = newValue else {return}
            Tcl_SetBooleanObj (obj, val ? 1 : 0)
        }
    }

    // getObj - return the Tcl object pointer (Tcl_Obj *)
    func getObj() -> UnsafeMutablePointer<Tcl_Obj> {
        return obj
    }
    
    func getInt() throws -> Int {
        return try tclobjp_to_Int(obj, interp: interp)
    }
    
    func getDouble() throws -> Double {
        return try tclobjp_to_Double(obj, interp: interp)
    }
    
    func getBool() throws -> Bool {
        return try tclobjp_to_Bool(obj, interp: interp)
    }
    
    // lappend - append a Tcl_Obj * to the Tcl object list
    func lappend (value: UnsafeMutablePointer<Tcl_Obj>) throws {
        guard (Tcl_ListObjAppendElement (interp, obj, value) != TCL_ERROR) else {throw TclError.Error}
    }
    
    // lappend - append an Int to the Tcl object list
    public func lappend (value: Int) throws {
        try self.lappend (Tcl_NewLongObj (value))
    }
    
    // lappend - append a Double to the Tcl object list
    public func lappend (value: Double) throws {
        try self.lappend (Tcl_NewDoubleObj (value))
    }
    
    // lappend - append a String to the Tcl object list
    public func lappend (value: String) throws {
        let cString = value.cStringUsingEncoding(NSUTF8StringEncoding) ?? []
        try self.lappend(Tcl_NewStringObj (cString, -1))
    }
    
    // lappend - append a Bool to the Tcl object list
    public func lappend (value: Bool) throws {
        try self.lappend (Tcl_NewBooleanObj (value ? 1 : 0))
    }
    
    // lappend - append a tclObj to the Tcl object list
    public func lappend (value: TclObj) throws {
        try self.lappend(value)
    }
    
    // lappend - append an array of Int to the Tcl object list
    // (flattens them out)
    public func lappend (array: [Int]) throws {
        try array.forEach {
            try self.lappend($0)
        }
    }
    
    // lappend - append an array of Double to the Tcl object list
    // (flattens them out)
    public func lappend (array: [Double]) throws {
        try array.forEach {
            try self.lappend($0)
        }
    }
    
    // lappend - append an array of String to the Tcl object list
    // (flattens them out)
    public func lappend (array: [String]) throws {
        try array.forEach {
            try self.lappend($0)
        }
    }
    
    // llength - return the number of elements in the list if the contents of our obj can be interpreted as a list
    public func llength () throws -> Int {
        var count: Int32 = 0
        if (Tcl_ListObjLength(interp, obj, &count) == TCL_ERROR) {
            throw TclError.Error
        }
        return Int(count)
    }
    
    // lindex - return the nth element treating obj as a list, if possible, and return a Tcl_Obj *
    func lindex (index: Int) throws -> UnsafeMutablePointer<Tcl_Obj>? {
        var tmpObj: UnsafeMutablePointer<Tcl_Obj> = nil
        if Tcl_ListObjIndex(interp, obj, Int32(index), &tmpObj) == TCL_ERROR {throw TclError.Error}
        return tmpObj
    }
    
    // lindex returning a TclObj object or nil
    public func lindex (index: Int) throws -> TclObj? {
        let tmpObj: UnsafeMutablePointer<Tcl_Obj>? = try self.lindex(index)
        return TclObj(tmpObj!, Interp: Interp)
    }
    
    // lindex returning an Int or nil
    func lindex (index: Int) throws -> Int {
        let tmpObj: UnsafeMutablePointer<Tcl_Obj>? = try self.lindex(index)
        
        return try tclobjp_to_Int(tmpObj, interp: interp)
    }
    
    // lindex returning a Double or nil
    public func lindex (index: Int) throws -> Double {
        let tmpObj: UnsafeMutablePointer<Tcl_Obj>? = try self.lindex(index)
        
        return try tclobjp_to_Double(tmpObj, interp: interp)
    }
    
    // lindex returning a String or nil
    public func lindex (index: Int) throws -> String {
        let tmpObj: UnsafeMutablePointer<Tcl_Obj>? = try self.lindex(index)
        
        return try tclobjp_to_String(tmpObj)
    }
    
    // lindex returning a Bool or nil
    public func lindex (index: Int) throws -> Bool {
        let tmpObj: UnsafeMutablePointer<Tcl_Obj>? = try self.lindex(index)
        
        return try tclobjp_to_Bool(tmpObj, interp: interp)
    }
    
    // toDictionary - copy the tcl object as a list into a String/TclObj dictionary
    public func toDictionary () throws -> [String: TclObj] {
        var dictionary: [String: TclObj] = [:]
        
        var objc: Int32 = 0
        var objv: UnsafeMutablePointer<UnsafeMutablePointer<Tcl_Obj>> = nil
        
        if Tcl_ListObjGetElements(interp, obj, &objc, &objv) == TCL_ERROR {throw TclError.Error}

        for i in 0.stride(to: objc-1, by: 2) {
            let keyString = try tclobjp_to_String(objv[i])
            dictionary[keyString] = TclObj(objv[i+1], Interp: Interp)
        }
        return dictionary
    }
    
    // toArray - create a String array from the tcl object as a list
    public func toArray () throws -> [String] {
        var array: [String] = []
        
        var objc: Int32 = 0
        var objv: UnsafeMutablePointer<UnsafeMutablePointer<Tcl_Obj>> = nil
        
        if Tcl_ListObjGetElements(interp, obj, &objc, &objv) == TCL_ERROR {throw TclError.Error}
        
        for i in 0..<Int(objc) {
            try array.append(tclobjp_to_String(objv[i]))
        }
        
        return array
    }
    
    // toArray - create an Int array from the tcl object as a list
    public func toArray () throws -> [Int] {
        var array: [Int] = []
        
        var objc: Int32 = 0
        var objv: UnsafeMutablePointer<UnsafeMutablePointer<Tcl_Obj>> = nil
        
        if Tcl_ListObjGetElements(interp, obj, &objc, &objv) == TCL_ERROR {throw TclError.Error}
        
        for i in 0..<Int(objc) {
            let longVal = try tclobjp_to_Int(objv[i], interp: interp)
            array.append(longVal)

        }
        
        return array
    }
    
    // toArray - create a Double array from the tcl object as a list
    public func toArray () throws ->  [Double] {
        var array: [Double] = []
        
        var objc: Int32 = 0
        var objv: UnsafeMutablePointer<UnsafeMutablePointer<Tcl_Obj>> = nil
        
        if Tcl_ListObjGetElements(interp, obj, &objc, &objv) == TCL_ERROR {throw TclError.Error}
        
        for i in 0..<Int(objc) {
            let doubleVal = try tclobjp_to_Double(objv[i], interp: interp)
            array.append(doubleVal)
            
        }
        
        return array
    }
    
    // toArray - create a TclObj array from the tcl object as a list,
    // each element becomes its own TclObj
    
    public func toArray () throws -> [TclObj] {
        var array: [TclObj] = []
        
        var objc: Int32 = 0
        var objv: UnsafeMutablePointer<UnsafeMutablePointer<Tcl_Obj>> = nil
        
        if Tcl_ListObjGetElements(interp, obj, &objc, &objv) == TCL_ERROR {throw TclError.Error}
        
        for i in 0..<Int(objc) {
            array.append(TclObj(objv[i]))
        }
        
        return array
    }

    // toDictionary - copy the tcl object as a list into a String/String dictionary
    public func toDictionary () throws -> [String: String] {
        var dictionary: [String: String] = [:]
        
        var objc: Int32 = 0
        var objv: UnsafeMutablePointer<UnsafeMutablePointer<Tcl_Obj>> = nil
        
        if Tcl_ListObjGetElements(interp, obj, &objc, &objv) == TCL_ERROR {throw TclError.Error}

        for i in 0.stride(to: Int(objc-1), by: 2) {
            let keyString = try tclobjp_to_String(objv[i])
            let valueString = try tclobjp_to_String(objv[i+1])

            dictionary[keyString] = valueString
        }
        return dictionary
    }
    
    // toDictionary - copy the tcl object as a list into a String/String dictionary
    public func toDictionary () throws -> [String: Int] {
        var dictionary: [String: Int] = [:]
        
        var objc: Int32 = 0
        var objv: UnsafeMutablePointer<UnsafeMutablePointer<Tcl_Obj>> = nil
        
        if Tcl_ListObjGetElements(interp, obj, &objc, &objv) == TCL_ERROR {throw TclError.Error}
        
        for i in 0.stride(to: Int(objc-1), by: 2) {
            let keyString = try tclobjp_to_String(objv[i])
            let val = try tclobjp_to_Int(objv[i+1])
            dictionary[keyString] = val
        }
        return dictionary
    }

    // toDictionary - copy the tcl object as a list into a String/String dictionary
    public func toDictionary () throws -> [String: Double] {
        var dictionary: [String: Double] = [:]
        
        var objc: Int32 = 0
        var objv: UnsafeMutablePointer<UnsafeMutablePointer<Tcl_Obj>> = nil
        
        if Tcl_ListObjGetElements(interp, obj, &objc, &objv) == TCL_ERROR {throw TclError.Error}
        
        for i in 0.stride(to: Int(objc-1), by: 2) {
            let keyString = try tclobjp_to_String(objv[i])
            let val = try tclobjp_to_Double(objv[i+1])
            
            dictionary[keyString] = val
        }
        return dictionary
    }

}


// TclInterp - Tcl Interpreter class


public class TclInterp {
    let interp: UnsafeMutablePointer<Tcl_Interp>
    public var throwErrors = false
    public var printErrors = true
    
    // init - create and initialize a full Tcl interpreter
    public init() {
        interp = Tcl_CreateInterp()
        Tcl_Init(interp)
    }
    
    // deinit - upon deletion of this object, delete the corresponding
    // Tcl interpreter
    deinit {
        Tcl_DeleteInterp (interp)
    }

    enum InterpErrors: ErrorType {
        case NotString(String)
        case EvalError(Int)
    }
    
    // getRawInterpPtr - return Tcl_Interp *
    func getRawInterpPtr() -> UnsafeMutablePointer<Tcl_Interp> {
        return interp
    }
    
    // eval - evaluate a string with the Tcl interpreter
    //
    // the Tcl result code (1 == error is the big one) is returned
    // this should probably be mapped to an enum in Swift
    //
    public func eval(code: String) throws -> Int {
        guard let cCode = code.cStringUsingEncoding(NSUTF8StringEncoding) else {
            throw InterpErrors.NotString(code)
        }
        let ret = Tcl_Eval(interp, cCode)
        
        if ret == TCL_ERROR {
            if printErrors {
                print("Error: \(self.result)")
                let errorInfo: String = try self.getVar("errorInfo")
                print(errorInfo)
            }
            if throwErrors {
                throw TclError.ErrorMessage(message: self.result, errorCode: try self.getVar("errorCode"))
            }
        }

        return Int(ret)
    }
    
    // resultString - grab the interpreter result as a string
    public var result: String {
        get {
            return (String.fromCString(Tcl_GetString(Tcl_GetObjResult(interp)))) ?? ""
        }
        set {
            guard let cCode = newValue.cStringUsingEncoding(NSUTF8StringEncoding) else {return}
            let obj: UnsafeMutablePointer<Tcl_Obj> = Tcl_NewStringObj(cCode, -1)
            Tcl_SetObjResult(interp, obj)
        }
    }
    
    // resultObj - set the interpreter result to the TclObj or return a TclObj based on the interpreter result
    public var resultObj: TclObj {
        get {
            return TclObj(Tcl_GetObjResult(interp))
        }
        set {
            Tcl_SetObjResult(interp,resultObj.getObj())
        }
    }
    
    // setResult - set the interpreter result from a Double
    func setResult(val: Double) {
        Tcl_SetDoubleObj (Tcl_GetObjResult(interp), val)
    }
    
    // setResult - set the interpreter result from an Int
    public func setResult(val: Int) {
        Tcl_SetLongObj (Tcl_GetObjResult(interp), val)
    }
    
    // setResult - set the interpreter result from a Bool
    public func setResult(val: Bool) {
        Tcl_SetBooleanObj (Tcl_GetObjResult(interp), val ? 1 : 0)
    }
    
    // setErrorCode - set the Tcl error code
    
    public func setErrorCode(val: String) {
        Tcl_SetObjErrorCode (interp, string_to_tclobjp(val))
    }
    
    // addErrorInfo() - append a message to the error information
    
    public func addErrorInfo(message: String) {
        guard let cMessage = message.cStringUsingEncoding(NSUTF8StringEncoding) else {return}
        Tcl_AddObjErrorInfo (interp, cMessage, -1)
    }
    
    // getVar - return var as an UnsafeMutablePointer<Tcl_Obj> (i.e. a Tcl_Obj *), or nil
    // if elementName is specified, var is an array, otherwise var is a variable
    // NB still need to handle FLAGS
    
    func getVar(varName: String, elementName: String? = nil, flags: Int32 = 0) -> UnsafeMutablePointer<Tcl_Obj> {
        
        guard let cVarName = varName.cStringUsingEncoding(NSUTF8StringEncoding) else {return nil}
        
        let cElementName = elementName?.cStringUsingEncoding(NSUTF8StringEncoding)
        
        if (cElementName == nil) {
            return Tcl_GetVar2Ex(interp, cVarName, nil, Int32(flags))
        } else {
            return Tcl_GetVar2Ex(interp, cVarName, cElementName!, Int32(flags))
        }
    }
    
    // getVar - return a TclObj containing var in a TclObj object, or nil
    public func getVar(varName: String, elementName: String? = nil, flags: Int32 = 0) -> TclObj? {
        let obj: UnsafeMutablePointer<Tcl_Obj> = self.getVar(varName, elementName: elementName, flags: flags)
        
        guard (obj != nil) else {return nil}
        
        return TclObj(obj)
    }
    
    // getVar - return a TclObj containing var as an Int, or nil
    public func getVar(varName: String, elementName: String? = nil, flags: Int32 = 0) throws -> Int {
        let obj: UnsafeMutablePointer<Tcl_Obj> = self.getVar(varName, elementName: elementName, flags: flags)
        
        return try tclobjp_to_Int(obj)
    }
    
    // getVar - return a TclObj containing var as a Double, or nil
    public func getVar(arrayName: String, elementName: String? = nil) throws -> Double {
        let objp: UnsafeMutablePointer<Tcl_Obj> = self.getVar(arrayName, elementName: elementName)
        
        return try tclobjp_to_Double(objp)
    }
    
    // getVar - return a TclObj containing var as a String, or nil
    public func getVar(arrayName: String, elementName: String? = nil) throws -> String {
        let objp: UnsafeMutablePointer<Tcl_Obj> = self.getVar(arrayName, elementName: elementName)
        
        return try tclobjp_to_String(objp)
    }
    
    // getVar - return a TclObj containing var as a String, or nil
    public func getVar(arrayName: String, elementName: String? = nil)  -> String? {
        let objp: UnsafeMutablePointer<Tcl_Obj> = self.getVar(arrayName, elementName: elementName)
        
        do {
            return try tclobjp_to_String(objp)
        } catch {
            return nil
        }
    }

    
    
    // setVar - set a variable or array element in the Tcl interpreter
    // from an UnsafeMutablePointer<Tcl_Obj> (i.e. a Tcl_Obj *)
    // returns true or false based on whether it succeeded or not
    func setVar(varName: String, elementName: String? = nil, value: UnsafeMutablePointer<Tcl_Obj>, flags: Int = 0) -> Bool {
        guard let cVarName = varName.cStringUsingEncoding(NSUTF8StringEncoding) else {return false}
        let cElementName = elementName!.cStringUsingEncoding(NSUTF8StringEncoding)
        
        let ret = Tcl_SetVar2Ex(interp, cVarName, cElementName!, value, Int32(flags))
        
        return (ret != nil)
    }
    
    // setVar - set a variable or array element in the Tcl interpreter to the specified Int
    public func setVar(varName: String, elementName: String? = nil, value: String, flags: Int = 0) -> Bool {
        guard let cString = value.cStringUsingEncoding(NSUTF8StringEncoding) else {return false}
        let obj = Tcl_NewStringObj(cString, -1)
        return self.setVar(varName, elementName: elementName, value: obj, flags: flags)
    }
    
    // setVar - set a variable or array element in the Tcl interpreter to the specified Int
    public func setVar(varName: String, elementName: String? = nil, value: Int, flags: Int = 0) -> Bool {
        let obj = Tcl_NewIntObj(Int32(value))
        return self.setVar(varName, elementName: elementName, value: obj, flags: flags)
    }
    
    // setVar - set a variable or array element in the Tcl interpreter to the specified Bool
    public func setVar(varName: String, elementName: String? = nil, value: Bool, flags: Int = 0) -> Bool {
        let obj = Tcl_NewBooleanObj(value ? 1 : 0)
        return self.setVar(varName, elementName: elementName, value: obj, flags: flags)
    }
    
    // setVar - set a variable or array element in the Tcl interpreter to the specified Double
    public func setVar(varName: String, elementName: String? = nil, value: Double, flags: Int = 0) -> Bool {
        let obj = Tcl_NewDoubleObj(value)
        return self.setVar(varName, elementName: elementName, value: obj, flags: flags)
    }
    
    // setVar - set a variable or array element in the Tcl interpreter to the specified TclObj
    public func setVar(varName: String, elementName: String? = nil, obj: TclObj, flags: Int = 0) -> Bool {
        return self.setVar(varName, elementName: elementName, value: obj.getObj(), flags: flags)
    }
    
    // dictionaryToArray - set a String/String dictionary into a Tcl array
    public func dictionaryToArray (arrayName: String, dictionary: [String: String], flags: Int = 0) {
        dictionary.forEach {
            setVar(arrayName, elementName: $0.0, value: $0.1, flags: flags)
        }
    }

    // dictionaryToArray - set a String/Int dictionary into a Tcl array
    public func dictionaryToArray (arrayName: String, dictionary: [String: Int], flags: Int = 0) {
        dictionary.forEach {
            setVar(arrayName, elementName: $0.0, value: $0.1, flags: flags)
        }
    }

    // dictionaryToArray - set a String/Double dictionary into a Tcl array
    public func dictionaryToArray (arrayName: String, dictionary: [String: Double], flags: Int = 0) {
        dictionary.forEach {
            setVar(arrayName, elementName: $0.0, value: $0.1, flags: flags)
        }
    }

    // create_command - create a new Tcl command that will be handled by the specified Swift function
    public func create_command(name: String, _ swiftTclFunction:SwiftTclFuncReturningTclReturn) {
        let cname = name.cStringUsingEncoding(NSUTF8StringEncoding)!
        
        let cmdBlock = TclCommandBlock(myInterp: self, function: swiftTclFunction)
        let _ = Unmanaged.passRetained(cmdBlock) // keep Swift from deleting the object
        let ptr = UnsafeMutablePointer<TclCommandBlock>.alloc(1)
        ptr.memory = cmdBlock
        
        Tcl_CreateObjCommand(interp, cname, swift_tcl_bridger, ptr, nil)
    }

    // create_command - create a new Tcl command that will be handled by the specified Swift function
    public func create_command(name: String, _ swiftTclFunction:SwiftTclFuncReturningDouble) {
        let cname = name.cStringUsingEncoding(NSUTF8StringEncoding)!
        
        let cmdBlock = TclCommandBlock(myInterp: self, function: swiftTclFunction)
        let _ = Unmanaged.passRetained(cmdBlock) // keep Swift from deleting the object
        let ptr = UnsafeMutablePointer<TclCommandBlock>.alloc(1)
        ptr.memory = cmdBlock
        
        Tcl_CreateObjCommand(interp, cname, swift_tcl_bridger, ptr, nil)
    }

    
    func subst (substInObj: UnsafeMutablePointer<Tcl_Obj>, flags: Int32 = TCL_SUBST_ALL) throws -> UnsafeMutablePointer<Tcl_Obj>? {
        guard let substOutObj: UnsafeMutablePointer<Tcl_Obj> = Tcl_SubstObj (interp, substInObj, flags) else {throw TclError.Error}
        return substOutObj
    }
    
    func subst (substInObj: UnsafeMutablePointer<Tcl_Obj>, flags: Int32 = TCL_SUBST_ALL) throws -> TclObj {
        let substOutObj: UnsafeMutablePointer<Tcl_Obj>?
        do {
            substOutObj = try self.subst (substInObj, flags: flags)
        } catch {
            throw TclError.Error
        }
        return TclObj(substOutObj!)
    }
    
    func subst (substIn: String, flags: Int32 = TCL_SUBST_ALL) throws -> UnsafeMutablePointer<Tcl_Obj>? {
        return try self.subst (string_to_tclobjp(substIn), flags: flags)
    }

    func subst (substInTclObj: TclObj, flags: Int32 = TCL_SUBST_ALL) throws -> UnsafeMutablePointer<Tcl_Obj>? {
        return try self.subst (substInTclObj.getObj(), flags: flags)
    }
    
    public func subst (substIn: String, flags: Int32 = TCL_SUBST_ALL) throws -> String {
        let substOutObj: UnsafeMutablePointer<Tcl_Obj>?
        do {
            substOutObj = try self.subst (substIn, flags: flags)
        }
        return try tclobjp_to_String (substOutObj)
    }
}


