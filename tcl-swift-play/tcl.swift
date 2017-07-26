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
    case tcl_ok = 0
    case tcl_error = 1
    case tcl_return = 2
    case tcl_break = 3
    case tcl_continue = 4
}

// Tcl commands functions written in Swift can return Int, Double, String, Bool, TclObj or a TCL_RETURN-type code

public typealias SwiftTclFuncReturningTclReturn = (TclInterp, [TclObj]) throws -> TclReturn
public typealias SwiftTclFuncReturningInt = (TclInterp, [TclObj]) throws -> Int
public typealias SwiftTclFuncReturningDouble = (TclInterp, [TclObj]) throws -> Double
public typealias SwiftTclFuncReturningString = (TclInterp, [TclObj]) throws -> String
public typealias SwiftTclFuncReturningBool = (TclInterp, [TclObj]) throws -> Bool
public typealias SwiftTclFuncReturningTclObj = (TclInterp, [TclObj]) throws -> TclObj
//public typealias Tcl_ObjP = UnsafeMutablePointer<Tcl_Obj>

public enum SwiftTclFunctionType {
    case tclReturn(SwiftTclFuncReturningTclReturn)
    case int(SwiftTclFuncReturningInt)
    case double(SwiftTclFuncReturningDouble)
    case string(SwiftTclFuncReturningString)
    case bool(SwiftTclFuncReturningBool)
    case tclObj(SwiftTclFuncReturningTclObj)
}

enum TclError: Error {
    case wrongNumArgs(nLeadingArguments: Int, message: String)
    case errorMessage(message: String, errorCode: String) // set error message in interpreter result
    case unknownReturnCode(code: Int32)
    case notString(string: String)
    case nullPointer // Object or string passed to a handler is a null pointer
    case error // error already set in interpreter result
}

enum TclControlFlow: Error {
    case tcl_return
    case tcl_break
    case tcl_continue
}

public struct VariableFlags : OptionSet {
    public let rawValue: Int32;
    public init(rawValue : Int32) { self.rawValue = rawValue }
    
    static let GlobalOnly         = VariableFlags(rawValue: TCL_GLOBAL_ONLY)
    static let NamespaceOnly      = VariableFlags(rawValue: TCL_NAMESPACE_ONLY)
    static let LeaveErroMsg       = VariableFlags(rawValue: TCL_LEAVE_ERR_MSG)
    static let AppendValue        = VariableFlags(rawValue: TCL_APPEND_VALUE)
    static let ListElement        = VariableFlags(rawValue: TCL_LIST_ELEMENT)
    static let TraceReads         = VariableFlags(rawValue: TCL_TRACE_READS)
    static let TraceWrites        = VariableFlags(rawValue: TCL_TRACE_WRITES)
    static let TraceUnsets        = VariableFlags(rawValue: TCL_TRACE_UNSETS)
    static let TraceDestroyed     = VariableFlags(rawValue: TCL_TRACE_DESTROYED)
    static let InterpDestroyed    = VariableFlags(rawValue: TCL_INTERP_DESTROYED)
    static let TraceArray         = VariableFlags(rawValue: TCL_TRACE_ARRAY)
    static let TraceResultDynamic = VariableFlags(rawValue: TCL_TRACE_RESULT_DYNAMIC)
    static let TraceResultObject  = VariableFlags(rawValue: TCL_TRACE_RESULT_OBJECT)

    //static let None               = VariableFlags(rawValue: 0)
}

public struct SubstFlags : OptionSet {
    public let rawValue: Int32;
    public init(rawValue : Int32) { self.rawValue = rawValue }
    
    static let Commands    = SubstFlags(rawValue:TCL_SUBST_COMMANDS)
    static let Variables   = SubstFlags(rawValue:TCL_SUBST_VARIABLES)
    static let Backslashes = SubstFlags(rawValue:TCL_SUBST_BACKSLASHES)
    static let All         = SubstFlags(rawValue:TCL_SUBST_ALL)
}

// TclCommandBlock - when creating a Tcl command -> Swift
class TclCommandBlock {
    let swiftTclCallFunction: SwiftTclFunctionType
    
    init(function: @escaping SwiftTclFuncReturningTclReturn) {
        swiftTclCallFunction = .tclReturn(function)
    }
    
    init(function: @escaping SwiftTclFuncReturningInt) {
        swiftTclCallFunction = .int(function)
    }

    init(function: @escaping SwiftTclFuncReturningDouble) {
        swiftTclCallFunction = .double(function)
    }

    init(function: @escaping SwiftTclFuncReturningString) {
        swiftTclCallFunction = .string(function)
    }

    init(function: @escaping SwiftTclFuncReturningBool) {
        swiftTclCallFunction = .bool(function)
    }
    
    init(function: @escaping SwiftTclFuncReturningTclObj) {
        swiftTclCallFunction = .tclObj(function)
    }

    func invoke(Interp: TclInterp, objv: [TclObj]) throws -> TclReturn {
        switch swiftTclCallFunction {
        case .tclReturn(let function):
            return try function(Interp, objv)
        default:
            abort()
        }
    }
    
    func invoke(Interp: TclInterp, objv: [TclObj]) throws -> Int {
        switch swiftTclCallFunction {
        case .int(let function):
            return try function(Interp, objv)
        default:
            abort()
        }
    }
    
    func invoke(Interp: TclInterp, objv: [TclObj]) throws -> Double {
        switch swiftTclCallFunction {
        case .double(let function):
            return try function(Interp, objv)
        default:
            abort()
        }
    }
    
    func invoke(Interp: TclInterp, objv: [TclObj]) throws -> String {
        switch swiftTclCallFunction {
        case .string(let function):
            return try function(Interp, objv)
        default:
            abort()
        }
    }
    
    func invoke(Interp: TclInterp, objv: [TclObj]) throws -> Bool {
        switch swiftTclCallFunction {
        case .bool(let function):
            return try function(Interp, objv)
        default:
            abort()
        }
    }
    
    func invoke(Interp: TclInterp, objv: [TclObj]) throws -> TclObj {
        switch swiftTclCallFunction {
        case .tclObj(let function):
            return try function(Interp, objv)
        default:
            abort()
        }
    }
}

// tclobjp_to_String - return the value of a Tcl_Obj * as a String or nil

func tclobjp_to_String (_ tclObjP: UnsafeMutablePointer<Tcl_Obj>?) throws -> String {
    guard let tclObjP = tclObjP else { throw TclError.nullPointer }

    return String(cString: Tcl_GetString(tclObjP))
}

// tclobjp_to_Int - return the value of a Tcl_Obj * as an Int or nil

func tclobjp_to_Int (_ tclObjP: UnsafeMutablePointer<Tcl_Obj>?, interp: UnsafeMutablePointer<Tcl_Interp>? = nil) throws -> Int {
    var longVal: CLong = 0
    guard let tclObjP = tclObjP else { throw TclError.nullPointer }

    let result = Tcl_GetLongFromObj (interp, tclObjP, &longVal)
    if (result == TCL_ERROR) {
        if (interp == nil) {
            throw TclError.errorMessage(message: "expected integer", errorCode: "TCL VALUE NUMBER")
        } else {
            throw TclError.error
        }
    }
    return longVal
}

// tclobjp_to_Double - return the value of a Tcl_Obj * as a Double or nil

func tclobjp_to_Double (_ tclObjP: UnsafeMutablePointer<Tcl_Obj>?, interp: UnsafeMutablePointer<Tcl_Interp>? = nil) throws -> Double {
    var doubleVal: Double = 0
    guard let tclObjP = tclObjP else { throw TclError.nullPointer }
    
    let result = Tcl_GetDoubleFromObj (interp, tclObjP, &doubleVal)
    if (result == TCL_ERROR) {
        if (interp == nil) {
            throw TclError.errorMessage(message: "expected double", errorCode: "TCL VALUE NUMBER")
        } else {
            throw TclError.error
        }

    }
    return doubleVal
}

// tclobjp_to_Bool - return the value of a Tcl_Obj * as a Bool or nil

func tclobjp_to_Bool (_ tclObjP: UnsafeMutablePointer<Tcl_Obj>?, interp: UnsafeMutablePointer<Tcl_Interp>? = nil) throws -> Bool {
    var boolVal: Int32 = 0
    guard let tclObjP = tclObjP else { throw TclError.nullPointer }
    
    let result = Tcl_GetBooleanFromObj (interp, tclObjP, &boolVal)
    if (result == TCL_ERROR) {
        if (interp == nil) {
            throw TclError.errorMessage(message: "expected boolean", errorCode: "TCL VALUE NUMBER")
        } else {
            throw TclError.error
        }

    }
    return boolVal == 0 ? true : false
}

// tclobjp(string:) - create a Tcl_Obj * from a Swift String

func tclobjp (string: String) throws -> UnsafeMutablePointer<Tcl_Obj> {
    return Tcl_NewStringObj (string, -1)
}

// Protocol for types that Tcl knows
protocol TclType {
    init? (_ obj: TclObj)
    mutating func fromTclObj(_ obj: TclObj)
}

// extend Swift objects to satisfy protocol TclType
extension String: TclType {
    public init? (_ obj: TclObj) {
        guard let value: String = try? obj.get() else {return nil}
        self.init(value)
    }
    
    mutating func fromTclObj(_ obj: TclObj) {
        self = obj.stringValue!
    }
}

extension Int: TclType {
    public init? (_ obj: TclObj) {
        guard let value: Int = try? obj.get() else {return nil}
        self.init(value)
    }
    
    mutating func fromTclObj(_ obj: TclObj) {
        self = obj.intValue!
    }
}

extension Double: TclType {
    public init? (_ obj: TclObj) {
        guard let value: Double = try? obj.get() else {return nil}
        self.init(value)
    }
    
    mutating func fromTclObj(_ obj: TclObj) {
        self = obj.doubleValue!
    }
}

extension Bool: TclType {
    public init? (_ obj: TclObj) {
        guard let value: Bool = try? obj.get() else {return nil}
        self.init(value)
    }
    
    mutating func fromTclObj(_ obj: TclObj) {
        self = obj.boolValue!
    }
}


// swift_tcl_bridger - this is the trampoline that gets called by Tcl when invoking a created Swift command
//   this declaration is the Swift equivalent of Tcl_ObjCmdProc *proc
func swift_tcl_bridger (clientData: ClientData?, interp: UnsafeMutablePointer<Tcl_Interp>?, objc: Int32, objv: UnsafePointer<UnsafeMutablePointer<Tcl_Obj>?>?) -> Int32 {
    let Interp = TclInterp(interp: interp!, printErrors: false)
    let tcb = Unmanaged<TclCommandBlock>.fromOpaque(clientData!).takeUnretainedValue()
    
    // construct an array containing the arguments
    var objvec = [TclObj]()
    if let objv = objv {
        for i in 0..<Int(objc) {
            objvec.append(TclObj(objv[i]!, Interp: Interp))
        }
    }
    
    // invoke the Swift implementation of the Tcl command and return the value it returns
    do {
        switch tcb.swiftTclCallFunction {
        case .tclReturn:
            let ret: TclReturn = try tcb.invoke(Interp: Interp, objv: objvec)
            return ret.rawValue
            
        case .string:
            let result: String = try tcb.invoke(Interp: Interp, objv: objvec)
            Interp.result = result
            
        case .double:
            let result: Double = try tcb.invoke(Interp: Interp, objv: objvec)
            Interp.setResult(result)
            
        case .int:
            let result: Int = try tcb.invoke(Interp: Interp, objv: objvec)
            Interp.setResult(result)
            
        case .bool:
            let result: Bool = try tcb.invoke(Interp: Interp, objv: objvec)
            Interp.setResult(result)
            
        case .tclObj:
            let result: TclObj = try tcb.invoke(Interp: Interp, objv: objvec)
            Interp.resultObj = result

        }
    } catch TclError.error {
        return TCL_ERROR
    } catch TclError.errorMessage(let message) {
        Interp.result = message.message
        try! Interp.setErrorCode(message.errorCode)
        return TCL_ERROR
    } catch TclError.wrongNumArgs(let nLeadingArguments, let message) {
        Tcl_WrongNumArgs(interp, Int32(nLeadingArguments), objv, message)
        return TCL_ERROR
    } catch TclControlFlow.tcl_break {
        return TCL_BREAK
    } catch TclControlFlow.tcl_continue {
        return TCL_CONTINUE
    } catch TclControlFlow.tcl_return {
        return TCL_RETURN
    } catch (let error) {
        Interp.result = "unknown error type \(error)"
        return TCL_ERROR
    }
    return TCL_OK
}

