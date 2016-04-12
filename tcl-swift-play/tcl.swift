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

typealias SwiftTclFuncType = (TclInterp, [TclObj]) -> Int

class TclCommandBlock {
    var swiftTclFunc: SwiftTclFuncType
    var interp: TclInterp
    
    init(myInterp: TclInterp, function: SwiftTclFuncType) {
        swiftTclFunc = function
        interp = myInterp
    }
    
    func invoke(objv: [TclObj]) {
        swiftTclFunc(interp, objv)
    }
}

func swift_tcl_bridger (clientData: ClientData, interp: UnsafeMutablePointer<Tcl_Interp>, objc: Int32, objv: UnsafePointer<UnsafeMutablePointer<Tcl_Obj>>) -> Int32 {
    // here should go the code to call a Swift function
    // with an argument being the TclInterp object and
    // a variadic argument containing TclObj objects
    print("swift_tcl_bridger called")
    
    
    let tcb = UnsafeMutablePointer<TclCommandBlock>(clientData)
    let tcc = tcb.memory
    
    var objvec = [TclObj]()

    for i in 1..<Int(objc) {
        objvec.append(TclObj(val: objv[i]))
    }
    
    tcc.invoke(objvec)
    
    return 0
}

// TclObj - Tcl object class

class TclObj {
    var obj: UnsafeMutablePointer<Tcl_Obj>
    
    // various initializers to create a Tcl object from nothing, an int,
    // double, string, Tcl_Obj *, etc
    
    init() {
        obj = Tcl_NewObj()
    }
    
    init(val: Int) {
        obj = Tcl_NewLongObj(val)
    }
    
    init(val: String) {
        let string = val.cStringUsingEncoding(NSUTF8StringEncoding) ?? []
        obj = Tcl_NewStringObj (string, -1)
    }
    
    init(val: Double) {
        obj = Tcl_NewDoubleObj (val)
    }
    
    init(val: UnsafeMutablePointer<Tcl_Obj>) {
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
    
    func getObj() -> UnsafeMutablePointer<Tcl_Obj> {
        return obj
    }
    
}


// TclInterp - Tcl Interpreter class

class TclInterp {
    var interp: UnsafeMutablePointer<Tcl_Interp>
    
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
    
    var resultObj: TclObj {
        get {
            return TclObj(val: Tcl_GetObjResult(interp))
        }
        set {
            Tcl_SetObjResult(interp,resultObj.getObj())
        }
    }
    
    func setResult(val: Double) {
        Tcl_SetDoubleObj (Tcl_GetObjResult(interp), val)
    }
    
    func setResult(val: Int) {
        Tcl_SetLongObj (Tcl_GetObjResult(interp), val)
    }

    
    // create_command - create a new Tcl command that will be handled by the specified Swift function
    func create_command(name: String, SwiftTclFunction:(TclInterp, [TclObj]) -> Int) {
        let cname = name.cStringUsingEncoding(NSUTF8StringEncoding)!
        
        let cmdBlock = TclCommandBlock(myInterp: self, function: SwiftTclFunction)
        var unmanaged = Unmanaged.passRetained(cmdBlock)
        // let ptr = unmanaged.toOpaque()
        let ptr = UnsafeMutablePointer<TclCommandBlock>.alloc(1)
        ptr.memory = cmdBlock
        
        Tcl_CreateObjCommand(interp, cname, swift_tcl_bridger, ptr, nil)
    }
}


