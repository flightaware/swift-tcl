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

enum TclReturn: Int32 {
    case OK = 0
    case ERROR = 1
    case RETURN = 2
    case BREAK = 3
    case CONTINUE = 4
}

typealias SwiftTclFuncType = (TclInterp, [TclObj]) throws -> TclReturn

enum TclError: ErrorType {
    case WrongNumArgs(nLeadingArguments: Int, message: String)
    case ErrorMessage(message: String) // set error message in interpreter result
    case Error // error already set in interpreter result
}

// TclCommandBlock - when creating a Tcl command -> Swift
class TclCommandBlock {
    let swiftTclFunc: SwiftTclFuncType
    let interp: TclInterp
    
    init(myInterp: TclInterp, function: SwiftTclFuncType) {
        swiftTclFunc = function
        interp = myInterp
    }
    
    func invoke(objv: [TclObj]) throws -> TclReturn {
        do {
            let ret = try swiftTclFunc(interp, objv)
            return ret
        }
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
        objvec.append(TclObj(objv[i]))
    }
    
    // invoke the Swift implementation of the Tcl command and return the value it returns
    do {
        let ret = try tcb.invoke(objvec).rawValue
        return ret
    } catch TclError.Error {
        return TCL_ERROR
    } catch TclError.ErrorMessage(let message) {
        tcb.interp.result = message
        return TCL_ERROR
    } catch TclError.WrongNumArgs(let nLeadingArguments, let message) {
        Tcl_WrongNumArgs(interp, Int32(nLeadingArguments), objv, message.cStringUsingEncoding(NSUTF8StringEncoding) ?? [])
    } catch (let error) {
        tcb.interp.result = "unknown error type \(error)"
        return TCL_ERROR
    }
    return TCL_ERROR
}

// TclObj - Tcl object class

class TclObj {
    let obj: UnsafeMutablePointer<Tcl_Obj>
    
    // various initializers to create a Tcl object from nothing, an int,
    // double, string, Tcl_Obj *, etc
    
    init() {
        obj = Tcl_NewObj()
    }
    
    init(_ val: Int) {
        obj = Tcl_NewLongObj(val)
    }
    
    init(_ val: String) {
        let string = val.cStringUsingEncoding(NSUTF8StringEncoding) ?? []
        obj = Tcl_NewStringObj (string, -1)
    }
    
    init(_ val: Double) {
        obj = Tcl_NewDoubleObj (val)
    }
    
    init(_ val: UnsafeMutablePointer<Tcl_Obj>) {
        obj = val
        IncrRefCount(val)
    }
    
    // deinit - decrement the object's reference count.  if it goes below one
    // the object will be freed.  if not then something else has it and it will
    // be freed after the last use
    deinit {
        DecrRefCount(obj)
    }
    
    // various set functions to set the Tcl object from a string, Int, Double, etc
    var stringValue: String {
        get {
            return String.fromCString(Tcl_GetString(obj)) ?? ""
        }
        set {
            Tcl_SetStringObj (obj, newValue.cStringUsingEncoding(NSUTF8StringEncoding) ?? [], -1)
        }
    }
    
    func set(val: Int) {
        Tcl_SetLongObj (obj, val)
    }
    
    func set(val: Double) {
        Tcl_SetDoubleObj (obj, val)
    }
    
    // getInt - return the Tcl object as an Int or nil
    // if in-object Tcl type conversion fails
    func getInt() -> Int? {
        var longVal: CLong = 0
        let result = Tcl_GetLongFromObj (nil, obj, &longVal)
        if (result == TCL_ERROR) {
            return nil
        }
        return longVal
    }
    
    // getDouble - return the Tcl object as a Double or nil
    // if in-object Tcl type conversion fails
    func getDouble() -> Double? {
        var doubleVal: CDouble = 0
        let result = Tcl_GetDoubleFromObj (nil, obj, &doubleVal)
        if (result == TCL_ERROR) {
            return nil
        }
        return doubleVal
    }
    
    // getInt - version of getInt that throws an error if object isn't an int
    // if interp is specified then a Tcl-generated message will be used
    func getInt(interp: TclInterp?) throws ->  Int {
        var longVal: CLong = 0
        let result = Tcl_GetLongFromObj (nil, obj, &longVal)
        if (result == TCL_ERROR) {
            if (interp == nil) {
                throw TclError.ErrorMessage(message: "conversion error")
            } else {
                throw TclError.Error
            }
        }
        return longVal
    }
    
    // getDouble - version of getDouble that throws an error if object can't
    // be read as a double.  if interp is specified then a Tcl-generated
    // message will be used
    func getDouble(interp: TclInterp?) throws -> Double {
        var doubleVal: CDouble = 0
        let result = Tcl_GetDoubleFromObj (interp!.interp, obj, &doubleVal)
        if (result == TCL_ERROR) {
            if (interp == nil) {
                throw TclError.ErrorMessage(message: "conversion error")
            } else {
                throw TclError.Error
            }
        }
        return doubleVal
    }
    

    // getObj - return the Tcl object pointer (Tcl_Obj *)
    func getObj() -> UnsafeMutablePointer<Tcl_Obj> {
        return obj
    }
}

// TclInterp - Tcl Interpreter class

class TclInterp {
    let interp: UnsafeMutablePointer<Tcl_Interp>
    
    // init - create and initialize a full Tcl interpreter
    init() {
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
    
    // eval - evaluate a string with the Tcl interpreter
    //
    // the Tcl result code (1 == error is the big one) is returned
    // this should probably be mapped to an enum in Swift
    func eval(code: String) throws -> Int {
        guard let cCode = code.cStringUsingEncoding(NSUTF8StringEncoding) else {
            throw InterpErrors.NotString(code)
        }
        let ret = Tcl_Eval(interp, cCode)
        defer {
            print("eval return code is \(ret)")
        }
        if ret != 0 {
            throw InterpErrors.EvalError(Int(ret))
        }

        return Int(ret)
    }
    
    // resultString - grab the interpreter result as a string
    var result: String {
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
    var resultObj: TclObj {
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
    func setResult(val: Int) {
        Tcl_SetLongObj (Tcl_GetObjResult(interp), val)
    }
    
    // getvar - return an UnsafeMUtablePointer<Tcl_Obj> (i.e. a Tcl_Obj *) containing a Tcl var, or nil
    
    func getVar(varName: String) -> UnsafeMutablePointer<Tcl_Obj> {
        guard let cVarName = varName.cStringUsingEncoding(NSUTF8StringEncoding) else {return nil}
        
        return Tcl_GetVar2Ex(interp, cVarName, nil, 0)
    }
    
    
    // getArrayElement - return an UnsafeMUtablePointer<Tcl_Obj> (i.e. a Tcl_Obj *) containing var, or nil
    
    func getArrayElement(arrayName: String, elementName: String) -> UnsafeMutablePointer<Tcl_Obj> {
        guard let cArrayName = arrayName.cStringUsingEncoding(NSUTF8StringEncoding) else {return nil}
        guard let cElementName = elementName.cStringUsingEncoding(NSUTF8StringEncoding) else {return nil}
        
        return Tcl_GetVar2Ex(interp, cArrayName, cElementName, 0)
    }
    
    // getVar - return a TclObj object containing var from interpreter, or nil
    func getVar(varName: String) -> TclObj? {
        let obj: UnsafeMutablePointer<Tcl_Obj> = self.getVar(varName)
        
        if (obj == UnsafeMutablePointer<Tcl_Obj>(nil)) {
            return nil
        }
        
        return TclObj(obj)
    }
    
    // getVar - return an Int object containing var from interpreter, or nil
    func getVar(varName: String) -> Int? {
        let obj: UnsafeMutablePointer<Tcl_Obj> = self.getVar(varName)
        
        if (obj == UnsafeMutablePointer<Tcl_Obj>(nil)) {
            return nil
        }
        
        var longVal: CLong = 0
        let result = Tcl_GetLongFromObj (nil, obj, &longVal)
        
        if result == TCL_ERROR {
            return nil
        }
        
        return longVal
    }
    


    // getArrayElement - return a TclObj containing var, or nil
    func getArrayElement(arrayName: String, elementName: String) -> TclObj? {
        let obj: UnsafeMutablePointer<Tcl_Obj> = self.getArrayElement(arrayName, elementName: elementName)
        
        if (obj == nil) {
            return nil
        }
        
        return TclObj(obj)
    }

    // create_command - create a new Tcl command that will be handled by the specified Swift function
    func create_command(name: String, SwiftTclFunction:SwiftTclFuncType) {
        let cname = name.cStringUsingEncoding(NSUTF8StringEncoding)!
        
        let cmdBlock = TclCommandBlock(myInterp: self, function: SwiftTclFunction)
        let _ = Unmanaged.passRetained(cmdBlock) // keep Swift from deleting the object
        // let ptr = unmanaged.toOpaque()
        let ptr = UnsafeMutablePointer<TclCommandBlock>.alloc(1)
        ptr.memory = cmdBlock
        
        Tcl_CreateObjCommand(interp, cname, swift_tcl_bridger, ptr, nil)
    }
}


