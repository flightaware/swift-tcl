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
        guard let cCode = code.cStringUsingEncoding(NSUTF8StringEncoding) else {
            throw TclError.NotString(string: code)
        }
        let ret = Tcl_Eval(interp, cCode)
        
        switch ret {
        case TCL_RETURN:
            throw TclControlFlow.Return
        case TCL_BREAK:
            throw TclControlFlow.Break
        case TCL_CONTINUE:
            throw TclControlFlow.Continue
        case TCL_ERROR:
            self.addErrorInfo(" called from Swift '(caller)'")
            if printErrors {
                print("Error: \(self.result)")
                let errorInfo: String = try self.getVar("errorInfo")
                print(errorInfo)
            }
            
            let errorCode = self.getVar("errorCode") ?? ""
            throw TclError.ErrorMessage(message: self.result, errorCode: errorCode)
        case TCL_OK:
            break
        default:
            throw TclError.UnknownReturnCode(code:ret)
        }
    }
    
    // eval - evaluate the string via the Tcl Interpreter, return the Tcl result of the
    // evaluation. Throws TclError or TclControlFlow.
    public func eval(code: String, caller: String = #function) throws -> String {
        try self.rawEval(code, caller: caller)
        return try self.getResult()
    }
    
    public func eval(code: String, caller: String = #function) throws -> Int {
        try self.rawEval(code, caller: caller)
        return try self.getResult()
    }
    
    public func eval(code: String, caller: String = #function) throws -> Double {
        try self.rawEval(code, caller: caller)
        return try self.getResult()
    }
    
    public func eval(code: String, caller: String = #function) throws -> Bool {
        try self.rawEval(code, caller: caller)
        return try self.getResult()
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
    
    public func setErrorCode(val: String) throws {
        Tcl_SetObjErrorCode (interp, try string_to_tclobjp(val))
    }
    
    // addErrorInfo() - append a message to the error information
    
    public func addErrorInfo(message: String) {
        guard let cMessage = message.cStringUsingEncoding(NSUTF8StringEncoding) else {return}
        Tcl_AddObjErrorInfo (interp, cMessage, -1)
    }
    
    // getVar - return a Tcl variable or array element as an
    // UnsafeMutablePointer<Tcl_Obj> (i.e. a Tcl_Obj *), or nil if it doesn't exist.
    // if elementName is specified, var is an element of an array, otherwise var is a variable
    
    private func getVar(varName: String, elementName: String? = nil, flags: VariableFlags = [.None]) -> UnsafeMutablePointer<Tcl_Obj> {
        
        guard let cVarName = varName.cStringUsingEncoding(NSUTF8StringEncoding) else {return nil}
        
        let cElementName = elementName?.cStringUsingEncoding(NSUTF8StringEncoding)
        
        if (cElementName == nil) {
            return Tcl_GetVar2Ex(interp, cVarName, nil, flags.rawValue)
        } else {
            return Tcl_GetVar2Ex(interp, cVarName, cElementName!, flags.rawValue)
        }
    }
    
    // getVar - return a Tcl variable or  in a TclObj object, or nil
    public func getVar(varName: String, elementName: String? = nil, flags: VariableFlags = [.None]) -> TclObj? {
        let obj: UnsafeMutablePointer<Tcl_Obj> = self.getVar(varName, elementName: elementName, flags: flags)
        
        guard (obj != nil) else {return nil}
        
        return TclObj(obj)
    }
    
    // getVar - return Tcl variable or array element as an Int or throw an error
    public func getVar(varName: String, elementName: String? = nil, flags: VariableFlags = [.None]) throws -> Int {
        let obj: UnsafeMutablePointer<Tcl_Obj> = self.getVar(varName, elementName: elementName, flags: flags)
        
        return try tclobjp_to_Int(obj)
    }
    
    // getVar - return a var as a Double, or throw an error if unable
    public func getVar(arrayName: String, elementName: String? = nil) throws -> Double {
        let objp: UnsafeMutablePointer<Tcl_Obj> = self.getVar(arrayName, elementName: elementName)
        
        return try tclobjp_to_Double(objp)
    }
    
    // getVar - return a TclObj containing var as a String or throw an error if unable
    // the error seems unlikely but could be like a UTF-8 conversion error or something.
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
    func setVar(varName: String, elementName: String? = nil, value: UnsafeMutablePointer<Tcl_Obj>, flags: VariableFlags = [.None]) throws {
        guard let cVarName = varName.cStringUsingEncoding(NSUTF8StringEncoding) else {throw TclError.Error}
        let cElementName = elementName!.cStringUsingEncoding(NSUTF8StringEncoding)
        
        let ret = Tcl_SetVar2Ex(interp, cVarName, cElementName!, value, flags.rawValue)
        if ret == nil {
            throw TclError.Error
        }
    }
    
    // setVar - set a variable or array element in the Tcl interpreter to the specified Int
    public func setVar(varName: String, elementName: String? = nil, value: String, flags: VariableFlags = [.None]) throws {
        let obj = try string_to_tclobjp(value)
        return try self.setVar(varName, elementName: elementName, value: obj, flags: flags)
    }
    
    // setVar - set a variable or array element in the Tcl interpreter to the specified Int
    public func setVar(varName: String, elementName: String? = nil, value: Int, flags: VariableFlags = [.None]) throws {
        let obj = Tcl_NewIntObj(Int32(value))
        return try self.setVar(varName, elementName: elementName, value: obj, flags: flags)
    }
    
    // setVar - set a variable or array element in the Tcl interpreter to the specified Bool
    public func setVar(varName: String, elementName: String? = nil, value: Bool, flags: VariableFlags = [.None]) throws {
        let obj = Tcl_NewBooleanObj(value ? 1 : 0)
        return try self.setVar(varName, elementName: elementName, value: obj, flags: flags)
    }
    
    // setVar - set a variable or array element in the Tcl interpreter to the specified Double
    public func setVar(varName: String, elementName: String? = nil, value: Double, flags: VariableFlags = [.None]) throws {
        let obj = Tcl_NewDoubleObj(value)
        return try self.setVar(varName, elementName: elementName, value: obj, flags: flags)
    }
    
    // setVar - set a variable or array element in the Tcl interpreter to the specified TclObj
    public func setVar(varName: String, elementName: String? = nil, obj: TclObj, flags: VariableFlags = [.None]) throws {
        return try self.setVar(varName, elementName: elementName, value: obj.getObj(), flags: flags)
    }
    
    // dictionaryToArray - set a String/String dictionary into a Tcl array
    public func dictionaryToArray (arrayName: String, dictionary: [String: String], flags: VariableFlags = [.None]) throws {
        try dictionary.forEach {
            try setVar(arrayName, elementName: $0.0, value: $0.1, flags: flags)
        }
    }
    
    // dictionaryToArray - set a String/Int dictionary into a Tcl array
    public func dictionaryToArray (arrayName: String, dictionary: [String: Int], flags: VariableFlags = [.None]) throws {
        try dictionary.forEach {
            try setVar(arrayName, elementName: $0.0, value: $0.1, flags: flags)
        }
    }
    
    // dictionaryToArray - set a String/Double dictionary into a Tcl array
    public func dictionaryToArray (arrayName: String, dictionary: [String: Double], flags: VariableFlags = [.None]) throws {
        try dictionary.forEach {
            try setVar(arrayName, elementName: $0.0, value: $0.1, flags: flags)
        }
    }
    
    // create_command - create a new Tcl command that will be handled by the specified Swift function
    // NB - this is kludgey, too much replication with variants
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
    
    // create_command - create a new Tcl command that will be handled by the specified Swift function
    public func create_command(name: String, _ swiftTclFunction:SwiftTclFuncReturningString) {
        let cname = name.cStringUsingEncoding(NSUTF8StringEncoding)!
        
        let cmdBlock = TclCommandBlock(myInterp: self, function: swiftTclFunction)
        let _ = Unmanaged.passRetained(cmdBlock) // keep Swift from deleting the object
        let ptr = UnsafeMutablePointer<TclCommandBlock>.alloc(1)
        ptr.memory = cmdBlock
        
        Tcl_CreateObjCommand(interp, cname, swift_tcl_bridger, ptr, nil)
    }
    
    func subst (substInObj: UnsafeMutablePointer<Tcl_Obj>, flags: SubstFlags = [.All]) throws -> UnsafeMutablePointer<Tcl_Obj>? {
        guard let substOutObj: UnsafeMutablePointer<Tcl_Obj> = Tcl_SubstObj (interp, substInObj, flags.rawValue) else {throw TclError.Error}
        return substOutObj
    }
    
    func subst (substInObj: UnsafeMutablePointer<Tcl_Obj>, flags: SubstFlags = [.All]) throws -> TclObj {
        let substOutObj: UnsafeMutablePointer<Tcl_Obj>?
        do {
            substOutObj = try self.subst (substInObj, flags: flags)
        } catch {
            throw TclError.Error
        }
        return TclObj(substOutObj!)
    }
    
    func subst (substIn: String, flags: SubstFlags = [.All]) throws -> UnsafeMutablePointer<Tcl_Obj>? {
        return try self.subst (string_to_tclobjp(substIn), flags: flags)
    }
    
    func subst (substInTclObj: TclObj, flags: SubstFlags = [.All]) throws -> UnsafeMutablePointer<Tcl_Obj>? {
        return try self.subst (substInTclObj.getObj(), flags: flags)
    }
    
    public func subst (substIn: String, flags: SubstFlags = [.All]) throws -> String {
        let substOutObj: UnsafeMutablePointer<Tcl_Obj>?
        do {
            substOutObj = try self.subst (substIn, flags: flags)
        }
        return try tclobjp_to_String (substOutObj)
    }
}

