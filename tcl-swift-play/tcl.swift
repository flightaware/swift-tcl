//
//  tcl.swift
//  tcl-swift-play
//
//  Created by Karl Lehenbauer on 4/6/16.
//  Copyright © 2016 FlightAware. All rights reserved.
//

import Foundation

class TclInterp {
    var interp: UnsafeMutablePointer<Tcl_Interp>
    
    init() {
        interp = Tcl_CreateInterp()
        Tcl_Init(interp)
    }
    
    deinit {
        Tcl_DeleteInterp (interp)
    }
    
    func eval(code: String) {
        let ret = Tcl_Eval(interp, code.cStringUsingEncoding(NSUTF8StringEncoding)!)
        
        print("eval return code is \(ret)")
    }
    
    func resultString() -> String {
        return(String.fromCString(Tcl_GetString(Tcl_GetObjResult(interp))))!
    }
    
    func resultObj() -> TclObj {
        return TclObj(val: Tcl_GetObjResult(interp))
    }
}

class TclObj {
    var obj: UnsafeMutablePointer<Tcl_Obj>
    
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
    
    deinit {
        DecrRefCount(obj)
    }
    
    func set(val: String) {
        Tcl_SetStringObj (obj, val.cStringUsingEncoding(NSUTF8StringEncoding)!, -1)
    }
    
    func set(val: Int) {
        Tcl_SetLongObj (obj, val)
    }
    
    func set(val: Double) {
        Tcl_SetDoubleObj (obj, val)
    }

    func getString() -> String {
        return(String.fromCString(Tcl_GetString(obj)))!
    }
    
    func getInt() -> Int? {
        var longVal: CLong = 0
        let result = Tcl_GetLongFromObj (nil, obj, &longVal)
        if (result == TCL_ERROR) {
            return nil
        }
        return longVal
    }
    
    func getDouble() -> Double? {
        var doubleVal: CDouble = 0
        let result = Tcl_GetDoubleFromObj (nil, obj, &doubleVal)
        if (result == TCL_ERROR) {
            return nil
        }
        return doubleVal
    }

}
