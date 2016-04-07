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
    
    // eval - evaluate a string with the Tcl interpreter
    //
    // the Tcl result code (1 == error is the big one) is returned
    // this should probably be mapped to an enum in Swift
    func eval(code: String) -> Int {
        let ret = Tcl_Eval(interp, code.cStringUsingEncoding(NSUTF8StringEncoding)!)
        
        print("eval return code is \(ret)")
        return Int(ret)
    }
    
    // resultString - grab the interpreter result as a string
    func resultString() -> String {
        return(String.fromCString(Tcl_GetString(Tcl_GetObjResult(interp))))!
    }
    
    // resultObj - return a new TclObj object containing the interpreter result
    func resultObj() -> TclObj {
        return TclObj(val: Tcl_GetObjResult(interp))
    }
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
        obj = Tcl_NewStringObj (val.cStringUsingEncoding(NSUTF8StringEncoding)!, -1)
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
    func set(val: String) {
        Tcl_SetStringObj (obj, val.cStringUsingEncoding(NSUTF8StringEncoding)!, -1)
    }
    
    func set(val: Int) {
        Tcl_SetLongObj (obj, val)
    }
    
    func set(val: Double) {
        Tcl_SetDoubleObj (obj, val)
    }

    // getString - return the Tcl object as a Swift String
    func getString() -> String {
        return(String.fromCString(Tcl_GetString(obj)))!
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

}