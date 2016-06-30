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
    public func rawEval(code: String, caller: String = #function) throws {
        let ret = Tcl_Eval(interp, code)
        
        switch ret {
        case TCL_RETURN:
            throw TclControlFlow.return
        case TCL_BREAK:
            throw TclControlFlow.break
        case TCL_CONTINUE:
            throw TclControlFlow.continue
        case TCL_ERROR:
            self.addErrorInfo(" called from Swift '\(caller)'")
            if printErrors {
                print("Error: \(self.result)")
                let errorInfo: String = try self.getVar("errorInfo")
                print(errorInfo)
            }
            
            let errorCode = self.getVar("errorCode") ?? ""
            throw TclError.errorMessage(message: self.result, errorCode: errorCode)
        case TCL_OK:
            break
        default:
            throw TclError.unknownReturnCode(code:ret)
        }
    }

    // Utility function to concatenate a list of strings into a Tcl list.
    public func list(from list: [String]) throws -> String {
        let obj: TclObj = self.newObject(list)
        return try obj.get()
    }
    
    // Safer way to call rawEval, passing a list of strings
    public func rawEval(list: [String], caller: String = #function) throws {
        try rawEval(code: self.list(from: list), caller: caller)
    }
    
    // eval - evaluate the string via the Tcl Interpreter, return the Tcl result of the
    // evaluation. Throws TclError or TclControlFlow.
    public func eval(_ code: String, caller: String = #function) throws -> String {
        try self.rawEval(code: code, caller: caller)
        return try self.getResult()
    }
    
    public func eval(_ code: String, caller: String = #function) throws -> Int {
        try self.rawEval(code: code, caller: caller)
        return try self.getResult()
    }
    
    public func eval(_ code: String, caller: String = #function) throws -> Double {
        try self.rawEval(code: code, caller: caller)
        return try self.getResult()
    }
    
    public func eval(_ code: String, caller: String = #function) throws -> Bool {
        try self.rawEval(code: code, caller: caller)
        return try self.getResult()
    }
    
    public func eval(_ code: String, caller: String = #function) throws -> TclObj {
        try self.rawEval(code: code, caller: caller)
        return self.resultObj
    }
    
    // resultString - grab the interpreter result as a string
    public var result: String {
        get {
            return (String(cString: Tcl_GetString(Tcl_GetObjResult(interp)))) ?? ""
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
    
    // getVar - return a Tcl variable or array element as an
    // UnsafeMutablePointer<Tcl_Obj> (i.e. a Tcl_Obj *), or nil if it doesn't exist.
    // if elementName is specified, var is an element of an array, otherwise var is a variable
    
    private func getVar(_ varName: String, elementName: String? = nil, flags: VariableFlags = []) -> UnsafeMutablePointer<Tcl_Obj> {
        if (elementName == nil) {
            return Tcl_GetVar2Ex(interp, varName, nil, flags.rawValue)
        } else {
            return Tcl_GetVar2Ex(interp, varName, elementName!, flags.rawValue)
        }
    }
    
    // getVar - return a Tcl variable or  in a TclObj object, or nil
    public func getVar(_ varName: String, elementName: String? = nil, flags: VariableFlags = []) -> TclObj? {
        let obj: UnsafeMutablePointer<Tcl_Obj>? = self.getVar(varName, elementName: elementName, flags: flags)
        
        guard (obj != nil) else {return nil}
        
        return TclObj(obj!, Interp: self)
    }
    
    // getVar - return Tcl variable or array element as an Int or throw an error
    public func getVar(_ varName: String, elementName: String? = nil, flags: VariableFlags = []) throws -> Int {
        let obj: UnsafeMutablePointer<Tcl_Obj> = self.getVar(varName, elementName: elementName, flags: flags)
        
        return try tclobjp_to_Int(obj)
    }
    
    // getVar - return a var as a Double, or throw an error if unable
    public func getVar(_ arrayName: String, elementName: String? = nil) throws -> Double {
        let objp: UnsafeMutablePointer<Tcl_Obj> = self.getVar(arrayName, elementName: elementName)
        
        return try tclobjp_to_Double(objp)
    }
    
    // getVar - return a TclObj containing var as a String or throw an error if unable
    // the error seems unlikely but could be like a UTF-8 conversion error or something.
    public func getVar(_ arrayName: String, elementName: String? = nil) throws -> String {
        let objp: UnsafeMutablePointer<Tcl_Obj> = self.getVar(arrayName, elementName: elementName)
        
        return try tclobjp_to_String(objp)
    }
    
    // getVar - return a TclObj containing var as a String, or nil
    public func getVar(_ arrayName: String, elementName: String? = nil)  -> String? {
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
    func setVar(_ varName: String, elementName: String? = nil, value: UnsafeMutablePointer<Tcl_Obj>, flags: VariableFlags = []) throws {
        let ret = Tcl_SetVar2Ex(interp, varName, elementName!, value, flags.rawValue)
        if ret == nil {
            throw TclError.error
        }
    }
    
    // setVar - set a variable or array element in the Tcl interpreter to the specified TclObj
    public func setVar(_ varName: String, elementName: String? = nil, value: TclObj, flags: VariableFlags = []) throws {
        return try self.setVar(varName, elementName: elementName, value: value.obj, flags: flags)
    }
    
    // setVar - set a variable or array element in the Tcl interpreter to the specified String
    public func setVar(_ varName: String, elementName: String? = nil, value: String, flags: VariableFlags = []) throws {
        let obj = try tclobjp(string: value)
        return try self.setVar(varName, elementName: elementName, value: obj, flags: flags)
    }
    
    // setVar - set a variable or array element in the Tcl interpreter to the specified Int
    public func setVar(_ varName: String, elementName: String? = nil, value: Int, flags: VariableFlags = []) throws {
        let obj = Tcl_NewIntObj(Int32(value))
        return try self.setVar(varName, elementName: elementName, value: obj!, flags: flags)
    }
    
    // setVar - set a variable or array element in the Tcl interpreter to the specified Bool
    public func setVar(_ varName: String, elementName: String? = nil, value: Bool, flags: VariableFlags = []) throws {
        let obj = Tcl_NewBooleanObj(value ? 1 : 0)
        return try self.setVar(varName, elementName: elementName, value: obj!, flags: flags)
    }
    
    // setVar - set a variable or array element in the Tcl interpreter to the specified Double
    public func setVar(_ varName: String, elementName: String? = nil, value: Double, flags: VariableFlags = []) throws {
        let obj = Tcl_NewDoubleObj(value)
        return try self.setVar(varName, elementName: elementName, value: obj!, flags: flags)
    }
    
    // setVar - set a variable or array element in the Tcl interpreter to the specified TclObj
    public func setVar(_ varName: String, elementName: String? = nil, obj: TclObj, flags: VariableFlags = []) throws {
        return try self.setVar(varName, elementName: elementName, value: obj.get() as UnsafeMutablePointer<Tcl_Obj>, flags: flags)
    }
    
    // dictionaryToArray - set a String/TclObj dictionary into a Tcl array
    public func dictionaryToArray (_ arrayName: String, dictionary: [String: TclObj], flags: VariableFlags = []) throws {
        try dictionary.forEach {
            try setVar(arrayName, elementName: $0.0, value: $0.1, flags: flags)
        }
    }
    
    // dictionaryToArray - set a String/String dictionary into a Tcl array
    public func dictionaryToArray (_ arrayName: String, dictionary: [String: String], flags: VariableFlags = []) throws {
        try dictionary.forEach {
            try setVar(arrayName, elementName: $0.0, value: $0.1, flags: flags)
        }
    }
    
    // dictionaryToArray - set a String/Int dictionary into a Tcl array
    public func dictionaryToArray (_ arrayName: String, dictionary: [String: Int], flags: VariableFlags = []) throws {
        try dictionary.forEach {
            try setVar(arrayName, elementName: $0.0, value: $0.1, flags: flags)
        }
    }
    
    // dictionaryToArray - set a String/Double dictionary into a Tcl array
    public func dictionaryToArray (_ arrayName: String, dictionary: [String: Double], flags: VariableFlags = []) throws {
        try dictionary.forEach {
            try setVar(arrayName, elementName: $0.0, value: $0.1, flags: flags)
        }
    }
    
    // create_command - create a new Tcl command that will be handled by the specified Swift function
    // NB - this is kludgey, too much replication with variants
    public func create_command(_ name: String, _ swiftTclFunction:SwiftTclFuncReturningTclReturn) {
        let cmdBlock = TclCommandBlock(myInterp: self, function: swiftTclFunction)
        let _ = Unmanaged.passRetained(cmdBlock) // keep Swift from deleting the object
        let ptr = UnsafeMutablePointer<TclCommandBlock>(allocatingCapacity: 1)
        ptr.pointee = cmdBlock
        
        Tcl_CreateObjCommand(interp, name, swift_tcl_bridger, ptr, nil)
    }
    
    // create_command - create a new Tcl command that will be handled by the specified Swift function
    public func create_command(_ name: String, _ swiftTclFunction:SwiftTclFuncReturningDouble) {
        let cmdBlock = TclCommandBlock(myInterp: self, function: swiftTclFunction)
        let _ = Unmanaged.passRetained(cmdBlock) // keep Swift from deleting the object
        let ptr = UnsafeMutablePointer<TclCommandBlock>(allocatingCapacity: 1)
        ptr.pointee = cmdBlock
        
        Tcl_CreateObjCommand(interp, name, swift_tcl_bridger, ptr, nil)
    }
    
    // create_command - create a new Tcl command that will be handled by the specified Swift function
    public func create_command(_ name: String, _ swiftTclFunction:SwiftTclFuncReturningString) {
        let cmdBlock = TclCommandBlock(myInterp: self, function: swiftTclFunction)
        let _ = Unmanaged.passRetained(cmdBlock) // keep Swift from deleting the object
        let ptr = UnsafeMutablePointer<TclCommandBlock>(allocatingCapacity: 1)
        ptr.pointee = cmdBlock
        
        Tcl_CreateObjCommand(interp, name, swift_tcl_bridger, ptr, nil)
    }
    
    func subst (_ substInTclObj: TclObj, flags: SubstFlags = [.All]) throws -> TclObj {
        let substOutObj = Tcl_SubstObj (interp, substInTclObj.obj, flags.rawValue)
        guard substOutObj != nil else {
            throw TclError.error
        }
        return TclObj(substOutObj!, Interp: self)
    }
    
    public func subst (_ substIn: String, flags: SubstFlags = [.All]) throws -> String {
        let substOutObj: TclObj = try self.subst (TclObj(substIn, Interp: self), flags: flags)
        return try substOutObj.get()
    }
    
    // Wrappers for TclObj
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
