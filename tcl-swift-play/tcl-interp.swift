//
//  tcl-interp.swift
//  tcl-swift-bridge
//
//  Created by Peter da Silva on 5/17/16.
//  Copyright © 2016 FlightAware. All rights reserved.
//
// Free under the Berkeley license.
//

import Foundation

// TclInterp - Tcl Interpreter class


public class TclInterp {
    let interp: UnsafeMutablePointer<Tcl_Interp>
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
    
    // getRawInterpPtr - return Tcl_Interp *
    private func getRawInterpPtr() -> UnsafeMutablePointer<Tcl_Interp> {
        return interp
    }
    
    // rawEval - evaluate a string with the Tcl interpreter
    //
    // Returns void, throws a TclError or TclResultCode
    //
    public func rawEval(code: TclObj, caller: String = #function) throws {
        let ret = Tcl_EvalObj(interp, code.obj)
        
        switch ret {
        case TCL_RETURN:
            throw TclControlFlow.tcl_return
        case TCL_BREAK:
            throw TclControlFlow.tcl_break
        case TCL_CONTINUE:
            throw TclControlFlow.tcl_continue
        case TCL_ERROR:
            self.addErrorInfo(" called from Swift '\(caller)'")
            if printErrors {
                print("Error: \(self.result)")
                let errorInfo: String = try self.get(variable: "errorInfo")
                print(errorInfo)
            }
            
            let errorCode = self.get(variable: "errorCode") ?? ""
            throw TclError.errorMessage(message: self.result, errorCode: errorCode)
        case TCL_OK:
            break
        default:
            throw TclError.unknownReturnCode(code:ret)
        }
    }
    
    // Safer way to call rawEval, passing a list of strings
    public func rawEval(list: [String], caller: String = #function) throws {
        try rawEval(code: TclObj(list, Interp: self), caller: caller)
    }

    // Usual way to call rawEval, passing a string
    public func rawEval(code: String, caller: String = #function) throws {
        try rawEval(code: TclObj(code, Interp: self), caller: caller)
    }
    
    // eval - evaluate the string via the Tcl Interpreter, return the Tcl result of the
    // evaluation. Throws TclError or TclControlFlow.
    public func eval(code: String, caller: String = #function) throws -> String {
        try self.rawEval(code: code, caller: caller)
        return try self.getResult()
    }
    
    public func eval(code: String, caller: String = #function) throws -> Int {
        try self.rawEval(code: code, caller: caller)
        return try self.getResult()
    }
    
    public func eval(code: String, caller: String = #function) throws -> Double {
        try self.rawEval(code: code, caller: caller)
        return try self.getResult()
    }
    
    public func eval(code: String, caller: String = #function) throws -> Bool {
        try self.rawEval(code: code, caller: caller)
        return try self.getResult()
    }
    
    public func eval(code: String, caller: String = #function) throws -> TclObj {
        try self.rawEval(code: code, caller: caller)
        return self.resultObj
    }
    
    // eval - evaluate a TclObj via the Tcl Interpreter, return the Tcl result of the
    // evaluation. Throws TclError or TclControlFlow.
    public func eval(code: TclObj, caller: String = #function) throws -> String {
        try self.rawEval(code: code, caller: caller)
        return try self.getResult()
    }
    
    public func eval(code: TclObj, caller: String = #function) throws -> Int {
        try self.rawEval(code: code, caller: caller)
        return try self.getResult()
    }
    
    public func eval(code: TclObj, caller: String = #function) throws -> Double {
        try self.rawEval(code: code, caller: caller)
        return try self.getResult()
    }
    
    public func eval(code: TclObj, caller: String = #function) throws -> Bool {
        try self.rawEval(code: code, caller: caller)
        return try self.getResult()
    }
    
    public func eval(code: TclObj, caller: String = #function) throws -> TclObj {
        try self.rawEval(code: code, caller: caller)
        return self.resultObj
    }
    
    // result - grab the interpreter result as a string
    public var result: String {
        get {
            guard let rawString = Tcl_GetString(Tcl_GetObjResult(interp)) else { return "" }
            return (String(cString: rawString))
        }
        set {
            let obj: UnsafeMutablePointer<Tcl_Obj> = Tcl_NewStringObj(newValue, -1)
            Tcl_SetObjResult(interp, obj)
        }
    }
    
    // resultObj - set the interpreter result to the TclObj or return a TclObj based on the interpreter result
    public var resultObj: TclObj {
        get {
            return TclObj(Tcl_GetObjResult(interp), Interp: self)
        }
        set {
            Tcl_SetObjResult(interp,resultObj.get())
        }
    }
    
    public func getResult() throws -> String {
        let obj: UnsafeMutablePointer<Tcl_Obj> = Tcl_GetObjResult(interp)
        return try tclobjp_to_String(obj)
    }
    
    public func getResult() throws -> Int {
        let obj: UnsafeMutablePointer<Tcl_Obj> = Tcl_GetObjResult(interp)
        return try tclobjp_to_Int(obj)
    }
    
    public func getResult() throws -> Double {
        let obj: UnsafeMutablePointer<Tcl_Obj> = Tcl_GetObjResult(interp)
        return try tclobjp_to_Double(obj)
    }
    
    public func getResult() throws -> Bool {
        let obj: UnsafeMutablePointer<Tcl_Obj> = Tcl_GetObjResult(interp)
        return try tclobjp_to_Bool(obj)
    }
    
    // setResult - set the interpreter result from a Double
    func setResult(_ val: Double) {
        Tcl_SetDoubleObj (Tcl_GetObjResult(interp), val)
    }
    
    // setResult - set the interpreter result from an Int
    public func setResult(_ val: Int) {
        Tcl_SetLongObj (Tcl_GetObjResult(interp), val)
    }
    
    // setResult - set the interpreter result from a Bool
    public func setResult(_ val: Bool) {
        Tcl_SetBooleanObj (Tcl_GetObjResult(interp), val ? 1 : 0)
    }
    
    // setErrorCode - set the Tcl error code
    
    public func setErrorCode(_ val: String) throws {
        Tcl_SetObjErrorCode (interp, try tclobjp(string: val))
    }
    
    // addErrorInfo() - append a message to the error information
    
    public func addErrorInfo(_ message: String) {
        Tcl_AddObjErrorInfo (interp, message, -1)
    }
    
    // get(variable:...) - return a Tcl variable or array element as an
    // UnsafeMutablePointer<Tcl_Obj> (i.e. a Tcl_Obj *), or nil if it doesn't exist.
    // if elementName is specified, var is an element of an array, otherwise var is a variable
    
    private func get(variable varName: String, element elementName: String? = nil, flags: VariableFlags = []) -> UnsafeMutablePointer<Tcl_Obj> {
        if (elementName == nil) {
            return Tcl_GetVar2Ex(interp, varName, nil, flags.rawValue)
        } else {
            return Tcl_GetVar2Ex(interp, varName, elementName!, flags.rawValue)
        }
    }
    
    // get(variable:...) - return a Tcl variable or  in a TclObj object, or nil
    public func get(variable varName: String, element elementName: String? = nil, flags: VariableFlags = []) -> TclObj? {
        let obj: UnsafeMutablePointer<Tcl_Obj>? = self.get(variable: varName, element: elementName, flags: flags)
        
        guard (obj != nil) else {return nil}
        
        return TclObj(obj!, Interp: self)
    }
    
    // get(variable:...) - return Tcl variable or array element as an Int or throw an error
    public func get(variable varName: String, element elementName: String? = nil, flags: VariableFlags = []) throws -> Int {
        let obj: UnsafeMutablePointer<Tcl_Obj> = self.get(variable: varName, element: elementName, flags: flags)
        
        return try tclobjp_to_Int(obj)
    }
    
    // get(variable:...) - return a var as a Double, or throw an error if unable
    public func get(variable arrayName: String, element elementName: String? = nil) throws -> Double {
        let objp: UnsafeMutablePointer<Tcl_Obj> = self.get(variable: arrayName, element: elementName)
        
        return try tclobjp_to_Double(objp)
    }
    
    // get(variable:...) - return a TclObj containing var as a String or throw an error if unable
    // the error seems unlikely but could be like a UTF-8 conversion error or something.
    public func get(variable arrayName: String, element elementName: String? = nil) throws -> String {
        let objp: UnsafeMutablePointer<Tcl_Obj> = self.get(variable: arrayName, element: elementName)
        
        return try tclobjp_to_String(objp)
    }
    
    // get(variable:...) - return a TclObj containing var as a String, or nil
    public func get(variable arrayName: String, element elementName: String? = nil)  -> String? {
        let objp: UnsafeMutablePointer<Tcl_Obj> = self.get(variable: arrayName, element: elementName)
        
        do {
            return try tclobjp_to_String(objp)
        } catch {
            return nil
        }
    }
    
    // set(variable:...) - set a variable or array element in the Tcl interpreter
    // from an UnsafeMutablePointer<Tcl_Obj> (i.e. a Tcl_Obj *)
    // returns true or false based on whether it succeeded or not
    func set(variable varName: String, element elementName: String? = nil, value: UnsafeMutablePointer<Tcl_Obj>, flags: VariableFlags = []) throws {
        let ret = Tcl_SetVar2Ex(interp, varName, elementName!, value, flags.rawValue)
        if ret == nil {
            throw TclError.error
        }
    }
    
    // set(variable:...) - set a variable or array element in the Tcl interpreter to the specified TclObj
    public func set(variable varName: String, element elementName: String? = nil, value: TclObj, flags: VariableFlags = []) throws {
        return try self.set(variable: varName, element: elementName, value: value.obj, flags: flags)
    }
    
    // set(variable:...) - set a variable or array element in the Tcl interpreter to the specified String
    public func set(variable varName: String, element elementName: String? = nil, value: String, flags: VariableFlags = []) throws {
        let obj = try tclobjp(string: value)
        return try self.set(variable: varName, element: elementName, value: obj, flags: flags)
    }
    
    // set(variable:...) - set a variable or array element in the Tcl interpreter to the specified Int
    public func set(variable varName: String, element elementName: String? = nil, value: Int, flags: VariableFlags = []) throws {
        let obj = Tcl_NewIntObj(Int32(value))
        return try self.set(variable: varName, element: elementName, value: obj!, flags: flags)
    }
    
    // set(variable:...) - set a variable or array element in the Tcl interpreter to the specified Bool
    public func set(variable varName: String, element elementName: String? = nil, value: Bool, flags: VariableFlags = []) throws {
        let obj = Tcl_NewBooleanObj(value ? 1 : 0)
        return try self.set(variable: varName, element: elementName, value: obj!, flags: flags)
    }
    
    // set(variable:...) - set a variable or array element in the Tcl interpreter to the specified Double
    public func set(variable varName: String, element elementName: String? = nil, value: Double, flags: VariableFlags = []) throws {
        let obj = Tcl_NewDoubleObj(value)
        return try self.set(variable: varName, element: elementName, value: obj!, flags: flags)
    }
    
    // set(variable:...) - set a variable or array element in the Tcl interpreter to the specified TclObj
    public func set(variable varName: String, element elementName: String? = nil, obj: TclObj, flags: VariableFlags = []) throws {
        return try self.set(variable: varName, element: elementName, value: obj.get() as UnsafeMutablePointer<Tcl_Obj>, flags: flags)
    }
    
    // set(array:..., from:...) - set a String/TclObj dictionary into a Tcl array
    public func set (array arrayName: String, from dictionary: [String: TclObj], flags: VariableFlags = []) throws {
        try dictionary.forEach {
            try self.set(variable: arrayName, element: $0.0, value: $0.1, flags: flags)
        }
    }
    
    // set(array:..., from:...) - set a String/String dictionary into a Tcl array
    public func set(array arrayName: String, from dictionary: [String: String], flags: VariableFlags = []) throws {
        try dictionary.forEach {
            try self.set(variable: arrayName, element: $0.0, value: $0.1, flags: flags)
        }
    }
    
    // set(array:..., from:...) - set a String/Int dictionary into a Tcl array
    public func set(array arrayName: String, from dictionary: [String: Int], flags: VariableFlags = []) throws {
        try dictionary.forEach {
            try self.set(variable: arrayName, element: $0.0, value: $0.1, flags: flags)
        }
    }
    
    // set(array:..., from:...) - set a String/Double dictionary into a Tcl array
    public func set (array arrayName: String, dictionary: [String: Double], flags: VariableFlags = []) throws {
        try dictionary.forEach {
            try self.set(variable: arrayName, element: $0.0, value: $0.1, flags: flags)
        }
    }
    
    // create_command - create a new Tcl command that will be handled by the specified Swift function
    // NB - this is kludgey, too much replication with variants
    public func createCommand(named name: String, using swiftTclFunction: @escaping SwiftTclFuncReturningTclReturn) {
        let cmdBlock = TclCommandBlock(myInterp: self, function: swiftTclFunction)
        let clientData = Unmanaged.passRetained(cmdBlock).toOpaque()
        Tcl_CreateObjCommand(interp, name, swift_tcl_bridger, clientData, nil)
    }
    
    // create_command - create a new Tcl command that will be handled by the specified Swift function
    public func createCommand(named name: String, using swiftTclFunction: @escaping SwiftTclFuncReturningDouble) {
        let cmdBlock = TclCommandBlock(myInterp: self, function: swiftTclFunction)
        let clientData = Unmanaged.passRetained(cmdBlock).toOpaque()
        Tcl_CreateObjCommand(interp, name, swift_tcl_bridger, clientData, nil)
    }
    
    // create_command - create a new Tcl command that will be handled by the specified Swift function
    public func createCommand(named name: String, using swiftTclFunction: @escaping SwiftTclFuncReturningString) {
        let cmdBlock = TclCommandBlock(myInterp: self, function: swiftTclFunction)
        let clientData = Unmanaged.passRetained(cmdBlock).toOpaque()
        Tcl_CreateObjCommand(interp, name, swift_tcl_bridger, clientData, nil)
    }
    
    func subst (_ substInTclObj: TclObj, flags: SubstFlags = [.All]) throws -> TclObj {
        let substOutObj = Tcl_SubstObj (interp, substInTclObj.obj, flags.rawValue)
        guard let result = substOutObj else {
            throw TclError.error
        }
        return TclObj(result, Interp: self)
    }
    
    public func subst (_ substIn: String, flags: SubstFlags = [.All]) throws -> String {
        let substOutObj: TclObj = try self.subst (TclObj(substIn, Interp: self), flags: flags)
        return try substOutObj.get()
    }
    
    // Wrappers for TclObj - this is kludgey
    public func newObject() -> TclObj { return TclObj(Interp: self) }
    public func newObject(_ value: Int) -> TclObj { return TclObj(value, Interp: self) }
    public func newObject(_ value: String) -> TclObj { return TclObj(value, Interp: self) }
    public func newObject(_ value: Double) -> TclObj { return TclObj(value, Interp: self) }
    public func newObject(_ value: Bool) -> TclObj { return TclObj(value, Interp: self) }
    public func newObject(_ value: Set<Int>) -> TclObj { return TclObj(value, Interp: self) }
    public func newObject(_ value: Set<String>) -> TclObj { return TclObj(value, Interp: self) }
    public func newObject(_ value: Set<Double>) -> TclObj { return TclObj(value, Interp: self) }
//  public func newObject(value: Set<Bool>) -> TclObj { return TclObj(value, Interp: self) }
    public func newObject(_ value: [Int]) -> TclObj { return TclObj(value, Interp: self) }
    public func newObject(_ value: [String]) -> TclObj { return TclObj(value, Interp: self) }
    public func newObject(_ value: [Double]) -> TclObj { return TclObj(value, Interp: self) }
//  public func newObject(value: [Bool]) -> TclObj { return TclObj(value, Interp: self) }
    public func newObject(_ value: [String: Int]) -> TclObj { return TclObj(value, Interp: self) }
    public func newObject(_ value: [String: String]) -> TclObj { return TclObj(value, Interp: self) }
    public func newObject(_ value: [String: Double]) -> TclObj { return TclObj(value, Interp: self) }
//  public func newObject(value: [String: Bool]) -> TclObj { return TclObj(value, Interp: self) }

    // Wrappers for TclArray
    public func newArray(_ name: String) -> TclArray { return TclArray(name, Interp: self) }
    public func newArray(_ name: String, namespace: String) -> TclArray { return TclArray(name, Interp: self, namespace: namespace) }
    public func newArray(_ name: String, dict: [String: String]) throws -> TclArray {
        return try TclArray(name, Interp: self, dict: dict)
    }
    public func newArray(_ name: String, dict: [String: String], namespace: String) throws -> TclArray {
        return try TclArray(name, Interp: self, namespace: namespace, dict: dict)
    }
    public func newArray(_ name: String, dict: [String: TclObj]) throws -> TclArray {
        return try TclArray(name, Interp: self, dict: dict)
    }
    public func newArray(_ name: String, dict: [String: TclObj], namespace: String) throws -> TclArray {
        return try TclArray(name, Interp: self, namespace: namespace, dict: dict)
    }
    public func newArray(_ name: String, string: String) throws -> TclArray {
        return try TclArray(name, Interp: self,  string: string)
    }
    public func newArray(_ name: String, string: String, namespace: String) throws -> TclArray {
        return try TclArray(name, Interp: self, namespace: namespace, string: string)
    }
}
